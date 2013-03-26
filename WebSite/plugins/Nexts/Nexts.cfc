<cfcomponent output="true" mixin="controller,model,view">
	<!--- set up a few persistant things on the way in --->

<cffunction name="init">
	<cfset this.version = "1.1.8,1.2.0">
	<cfset Nexts_init() />	<!--- load up the Nexts data structures --->
	<cfreturn this>
</cffunction>

<cffunction name="Nexts_init" output="No" returntype="void" access="public" 
	displayname="Initialize Nexts" 
	hint="initializes the Nexts engine, loads hard data from DB "
	>
	<cfargument name="DataSource" type="string" required="no" default="Local" hint="database with persistent data">	
	<cfargument name="NextsTableName" type="string" required="no" default="Nexts" hint="table name of persistent data in database">	

	<cfset var loc = {} />	<!--- local variables --->
	<cfset loc.DSN = trim(arguments.DataSource) />	<!--- specified DSN --->
	<cfif loc.DSN eq "">
		<cfthrow message="Blank Nexts DSN supplied" detail="Blank Nexts DSN supplied" />
	</cfif>
	<cfset loc.NextsTableName = trim(arguments.NextsTableName) />	<!--- specified DSN --->
	<cfif loc.NextsTableName eq "">
		<cfthrow message="Blank Nexts tablename supplied" detail="Blank Nexts tablename supplied" />
	</cfif>

	<cfif not structKeyExists(application, "mbc_Utilities")>
		<cfset application.mbc_Utilities = StructNew() />
	</cfif>
	<!--- force a new data struct --->
	<cfset application.mbc_Utilities.Nexts = StructNew() />	
	<cfset application.mbc_Utilities.Nexts.Data = StructNew() />	<!--- the local persistent data, saved to disk when asked --->
	<cfset application.mbc_Utilities.Nexts.DSN = loc.DSN />	<!--- set source of data --->
	<cfset application.mbc_Utilities.Nexts.NextsTable = loc.NextsTableName />
	<cfset application.mbc_Utilities.Nexts.LastUpdate =  "" />	<!--- date of last update, defaults to null for fresh installs to update --->
	<cfset application.mbc_Utilities.Nexts.UpdatePeriod = 1 />	<!--- time between date updates, in days --->
	<cfset application.mbc_Utilities.Nexts.LocalDataFolderPath = ReplaceNoCase(ExpandPath(application.wheels.pluginPath), "\", "/", "all") & "/Nexts/data/" />	<!--- path to local datastore, if required --->
	<cfset application.mbc_Utilities.Nexts.Initialized = False />	<!--- path to local datastore, if required --->
	<cfif loc.DSN eq "Local" and not directoryExists(application.mbc_Utilities.Nexts.LocalDataFolderPath)>
		<cfdirectory action="create" directory="#application.mbc_Utilities.Nexts.LocalDataFolderPath#" />
	</cfif>
	
	<cfset $initHardData() />	<!--- load up the Nexts hard coded data structures --->
	<cfset $refreshNexts() />	<!--- load up the Nexts structure with the latest data --->
</cffunction>

<cffunction name="Nexts_getNextID" access="public" output="Yes" returntype="string" hint="gets the next free numeric ID for the specified ID name">
	<cfargument name="IDname" type="string" required="yes" hint="name of ID variable to return">	
	<cfargument name="IDFormat" type="string" required="no" default="FL" hint="Format of ID variable to return, integer or various strings, defaults to the 7 character friendly string for most common use (~6M numbers)">	

	<cfset var theIDname = trim(arguments.IDname) />
	<cfset var theIDFormat = trim(arguments.IDFormat) />
	<cfset var thisFreeID = "" />
	<cfset var nextFreeID = "" />
	<cfset var ret = "" />	<!--- temp var for function return values --->

	<cfif theIDname neq "">
		<cflock timeout="10" throwontimeout="No" name="DoingUpdateNext" type="EXCLUSIVE">	<!--- can't have two happening at once --->
			<cfset thisFreeID = Nexts_ChecknSetNextID(IDname=theIDname, IDFormat=theIDFormat, flagNeedToUpdateTables=False) />
			<!--- now we know we have a IDname, set to first value if it was just created or the current NextFreeID --->
			<cfif thisFreeID neq "">
				<!--- load the next var ID and increment for the next one --->
				<cfset nextFreeID = $IncrementNextValue(value="#thisFreeID#", format="#application.mbc_Utilities.Nexts.Data[theIDname].IDFormat#") />
				<cfif nextFreeID neq "">
					<cfset application.mbc_Utilities.Nexts.Data[theIDname].Value = nextFreeID />
					<cfset application.mbc_Utilities.Nexts.Data[theIDname].NextTimeStamp = Now() />
					<cfset ret = $UpdateNextsTable(IDname="#theIDname#") />
				<cfelse>
					<!--- oops! it did not increment --->
					<cfset thisFreeID = "" />
				</cfif>
			<cfelse>
				<!---  we sent in a bad argument, just hop out with a null --->
			</cfif>
		</cflock>
	</cfif>
	<cfreturn thisFreeID />
</cffunction>

<cffunction name="Nexts_ChecknSetNextID" output="No" returntype="string" access="public"
	displayname="Check and Set a NextID" 
	hint="sees if a NextID name exists and if not creates it. Returns nothing if bad arguments, otherwise creates the ID and fills with first value if non-existent, and then returns the current value. Useful for presetting IDnames in an application Init() for example"
	>
	<cfargument name="IDname" type="string" required="yes" hint="name of ID variable to return">	
	<cfargument name="IDFormat" type="string" required="no" default="FL" hint="Format of ID variable to return, integer or various strings">	
	<cfargument name="flagNeedToUpdateTables" type="boolean" required="no" default="True" hint="flags that we need to run the $UpdateNextsTable Routine">	

	<cfset var theIDname = trim(arguments.IDname) />
	<cfset var theIDFormat = trim(arguments.IDFormat) />
	<cfset var theFirstID = "" />
	<cfset var nextFreeID = "no next, theIDname: #theIDname#; theIDFormat: #theIDFormat#" />
	<cfset var ret = "" />

	<cfif theIDname neq "" and len(theIDFormat) eq 2>	<!--- simple validation, get a bit trickier inside if we have to do something --->
		<cflock timeout="10" throwontimeout="No" name="DoingChecknSetNext" type="EXCLUSIVE">	<!--- can't have two happening at once --->
			<!--- first we must see if this ID exists, no need to do anything if its there --->
			<cfif StructKeyExists(application.mbc_Utilities.Nexts.Data, "#theIDname#")>
				<!--- we have this one already so just pass back its value --->
				<cfset nextFreeID = application.mbc_Utilities.Nexts.Data[theIDname].Value />
			<cfelse>
				<!--- we don't have this one yet so let's add it in --->
				<!--- first check that we had a legit format passed in --->
				<cfif StructKeyExists(application.mbc_Utilities.Nexts.FirstValues, theIDFormat)>
					<cfset theFirstID = application.mbc_Utilities.Nexts.FirstValues[theIDFormat] />
			  	<!--- and create the IDname in the Nexts --->
					<cfset application.mbc_Utilities.Nexts.Data[theIDname] = StructNew() />
					<cfset application.mbc_Utilities.Nexts.Data[theIDname].Value = theFirstID />
					<cfset application.mbc_Utilities.Nexts.Data[theIDname].NextTimeStamp = Now() />
					<cfset application.mbc_Utilities.Nexts.Data[theIDname].IDFormat = theIDFormat />
					<cfif arguments.flagNeedToUpdateTables>
						<cfset ret = $UpdateNextsTable(IDname="#theIDname#", mode="NewID") />
					</cfif>
					<cfset nextFreeID = theFirstID />
				</cfif>
			</cfif>	<!--- end: ID already exists test --->
		</cflock>
	</cfif>
	<cfreturn nextFreeID />
</cffunction>

<cffunction name="Nexts_setNextID" output="yes" returntype="string" access="public"
	displayname="set Next ID"
	hint="forces a Next value to something specific. Can take an Integer ID or a string SID"
				>
	<!--- this function needs.... --->
	<cfargument name="IDname" type="string" required="yes" default="" hint="name of ID variable to update">	
	<cfargument name="Value" type="string" required="yes" default="" hint="name of ID variable to update">	

	<!--- now all of the var declarations, first the arguments which need manipulation --->
	<cfset var theIDname = trim(arguments.IDname) />
	<cfset var theValue = trim(arguments.Value) />
	<!--- now vars that will get filled as we go --->
	<cfset var temp = "" />	<!--- temp/throwaway var --->
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = "" />	<!--- this is the return to the caller, null is a bad value --->
	
	<!--- validate the incoming stuff --->
	<cfif theValue neq "">
		<cfif StructKeyExists(application.mbc_Utilities.Nexts.Data, "#theIDname#")>
			<cftry>
				<cfset application.mbc_Utilities.Nexts.Data["#arguments.IDname#"].Value = theValue />
				<cfset temp = $UpdateNextsTable(IDname="#arguments.IDname#") />
				<cfset ret = theValue />	<!--- this is the return to the caller --->
			<cfcatch type="any">
				<cflog text="Nexts_setNextID() Trapped. Error Text: #cfcatch.message# - Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#"  file="UtilitiesErrors" type="Error" application = "yes">
				<cfif application.config.debug.debugmode>
					Nexts_setNextID() trapped - error was:<br>
					<cfdump var="#cfcatch#">
				</cfif>
			</cfcatch>
			</cftry>
		<cfelse>
			<!--- we don't have this one yet so let's add it in --->
			<cfset application.mbc_Utilities.Nexts.Data[theIDname] = StructNew() />
			<cfset application.mbc_Utilities.Nexts.Data[theIDname].Value = theValue />
			<cfset application.mbc_Utilities.Nexts.Data[theIDname].NextTimeStamp = Now() />
			<cfset ret = $UpdateNextsTable(IDname="#theIDname#", mode="NewID") />
		</cfif> <!--- end: incoming parameters new-ness check --->
	</cfif> <!--- end: incoming parameters validation check --->

	<cfreturn ret  />
</cffunction>

<cffunction name="$UpdateNextsTable" access="package" output="No" returntype="void" hint="internal use, updates the 'Nexts' structure in the DB">
	<cfargument name="IDname" type="string" required="yes" hint="name of ID variable to update">	
	<cfargument name="Mode" type="string" default="" hint="flag for if we are adding a new ID">	
	
	<cfset var theMode = trim(arguments.Mode) />	
	<cfset var thePacket = "" />	
	<cfset var temps = StructNew() />	<!--- this is a temp struct for internal use --->
	<cfset var Nexts_setNextID = "" />	<!--- localise the query --->
	<cfset var GoodWriteFlag = True />
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorText = "mbc Utilities - $UpdateNextsTable():-<br>" />
	<cfset ret.Data = "" />
	
	<!--- set the next id in the DB --->
	<cflock timeout="10" throwontimeout="No" name="DoingUpdateNextTable" type="EXCLUSIVE">	<!--- can't have two happening at once --->
		<!--- see whether we are a full DB or the local store and process accordingly --->
		<cfif application.mbc_Utilities.Nexts.DSN eq "Local">	
			<!--- for the local store just put the data into its WDDX packet and save it --->
	 		<cftry>
				<cfwddx action="CFML2WDDX" output="thePacket" input="#application.mbc_Utilities.Nexts.data#" />
				<cffile action="write" file="#application.mbc_Utilities.Nexts.LocalDataFolderPath#Nexts.wddx.cfm" output="#thePacket#" addNewLine="No" />
			<cfcatch type="Any">
				<!--- poo it broke --->
				<cfset GoodWriteFlag = False />
			</cfcatch>
			</cftry>
			<cfif GoodWriteFlag>
			<cfelse>
				<cfset ret.error.ErrorCode = 1 />
				<cfset ret.error.ErrorText = ret.error.ErrorText & "Data Write Failed<br>" />
			</cfif>
		<cfelse>
			<!--- its the database so set the latest data --->
			<cfif theMode eq "NewID">
				<!--- if its a new one we need to do an insert --->			
				<cfquery name="Nexts_setNextID" datasource="#application.mbc_Utilities.Nexts.dsn#">
					Insert	into	#application.mbc_Utilities.Nexts.NextsTable#
									(NextIDValue, IDName, flag_CurrentData, NextTimeStamp, IDformat)
					Values	('#application.mbc_Utilities.Nexts.Data[arguments.IDname].Value#', '#arguments.IDname#', 1, #Now()#, '#application.mbc_Utilities.Nexts.Data[arguments.IDname].IDformat#')
				</cfquery>
			<cfelse>
				<!--- first check date rollover and then update table row --->
				<cfset temps = $UpdateDates(IDname="#arguments.IDname#") />
				<cfquery name="Nexts_setNextID" datasource="#application.mbc_Utilities.Nexts.dsn#">
					Update	#application.mbc_Utilities.Nexts.NextsTable#
						set		NextIDValue = '#application.mbc_Utilities.Nexts.Data[arguments.IDname].Value#',
									NextTimeStamp = #Now()#
						where	IDName = '#arguments.IDname#'
							and	flag_CurrentData = 1
				</cfquery>
			</cfif>
		</cfif>
  </cflock>
</cffunction>

<cffunction name="$UpdateDates" access="package" output="No" returntype="void" hint="internal use, refreshes the date in the DB, makes new row if needed">
	<cfargument name="IDname" type="string" required="yes" default="" hint="name of ID variable to update">	
	
	<!--- get today and see if different to the local timestamp --->	
	<cfset var theNewTimeStamp = DateFormat(Now(), "YYYYMMDD") />
	<cfset var theOldTimeStamp = application.mbc_Utilities.Nexts.LastUpdate />
	<cfset var setFlagOff = "" />	<!--- localise the query --->
	<cfset var Nexts_setNextID = "" />	<!--- localise the query --->

	<cfif  application.mbc_Utilities.Nexts.DSN neq 'Local' and (theNewTimeStamp-theOldTimeStamp) gt application.mbc_Utilities.Nexts.UpdatePeriod>
		<!--- over the threshold and using the database so create a new row --->
		<cflock timeout="10" throwontimeout="No" name="MakeNewNextsRow" type="EXCLUSIVE">
			<cfif arguments.IDname eq "">	<!--- no specific ID so do the lot --->
				<!--- set the current flag off --->
				<cfquery name="setFlagOff" datasource="#application.mbc_Utilities.Nexts.dsn#">
					Update	#application.mbc_Utilities.Nexts.NextsTable#
						set		flag_CurrentData = 0
				</cfquery>
				<!--- then make a new set from our local data --->
				<cfloop collection="#application.mbc_Utilities.Nexts.Data#" item="thisID">
					<cfquery name="Nexts_setNextID" datasource="#application.mbc_Utilities.Nexts.dsn#">
						Insert into	#application.mbc_Utilities.Nexts.NextsTable#
											(flag_CurrentData, NextTimeStamp, IDName, NextIDValue, IDformat)
							Values	(1, #application.mbc_Utilities.Nexts.Data[thisID].NextTimeStamp#, '#arguments.IDname#', '#application.mbc_Utilities.Nexts.Data[thisID].Value#', '#application.mbc_Utilities.Nexts.Data[thisID].IDformat#')
					</cfquery>
				</cfloop>
			<cfelse>
				<!--- ID was specified so just update it --->
				<!--- set the current flag off --->
				<cfquery name="setFlagOff" datasource="#application.mbc_Utilities.Nexts.dsn#">
					Update	#application.mbc_Utilities.Nexts.NextsTable#
						set		flag_CurrentData = 0
						where	IDName = '#arguments.IDname#'
				</cfquery>
				<!--- then make a new set from our local data --->
				<cfquery name="Nexts_setNextID" datasource="#application.mbc_Utilities.Nexts.dsn#">
					Insert into	#application.mbc_Utilities.Nexts.NextsTable#
										(flag_CurrentData, NextTimeStamp, IDName, NextIDValue, IDformat)
						Values	(1, #CreateODBCDateTime(application.mbc_Utilities.Nexts.Data["#arguments.IDname#"].NextTimeStamp)#, '#arguments.IDname#', '#application.mbc_Utilities.Nexts.Data["#arguments.IDname#"].Value#', '#application.mbc_Utilities.Nexts.Data["#arguments.IDname#"].IDformat#')
				</cfquery>
			</cfif>
			<!--- lastly update the day marker --->
			<cfset application.mbc_Utilities.Nexts.LastUpdate = theNewTimeStamp />	
		</cflock>
	</cfif>
</cffunction>

<cffunction name="$initHardData" access="package" output="No" returntype="void" hint="sets up the hard-coded data structures for the Nexts engine">
	<!--- dump then reinsert all of the fixed, hard coded stuff in case the old was contaminated --->
	<!--- friendlySID is the short, human rememberable string --->
	<cfset application.mbc_Utilities.Nexts.FriendlySID = StructNew() />
	<cfset application.mbc_Utilities.Nexts.FriendlySID.CharacterLists = StructNew() />
	<cfset application.mbc_Utilities.Nexts.FriendlySID.CharacterLists.Set1 = ArrayNew(1) />
	<cfset application.mbc_Utilities.Nexts.FriendlySID.CharacterLists.Set1[1] = ["b","z","c","y","d","x","f","w","g","v","h","t","j","s","k","r","m","q","n","p"] />	<!--- the string of consonants that are used in a SID value string --->
	<cfset application.mbc_Utilities.Nexts.FriendlySID.CharacterLists.Set1[2] = ["a","i","e","o","u","y"] />	<!--- the string of 'vowels' that are used in a SID value string, only chars act like vowels --->
	<cfset application.mbc_Utilities.Nexts.FriendlySID.CharacterLists.Set1[3] = ["b","n","p","z","h","t","j","c","m","q","y","d","x","s","k","r","f","w","g","v"] />
	<cfset application.mbc_Utilities.Nexts.FriendlySID.CharacterLists.Set2 = ArrayNew(1) />
	<cfset application.mbc_Utilities.Nexts.FriendlySID.CharacterLists.Set2[1] = ["z","h","t","p","b","n","j","c","m","x","s","k","q","y","d","r","f","g","v","w"] />
	<cfset application.mbc_Utilities.Nexts.FriendlySID.CharacterLists.Set2[2] = ["i","a","y","e","o","u"] />
	<cfset application.mbc_Utilities.Nexts.FriendlySID.CharacterLists.Set2[3] = ["f","g","z","h","t","p","b","r","v","n","j","c","m","x","s","d","w","k","q","y"] />
	<cfset application.mbc_Utilities.Nexts.FriendlySID.CharacterLists.Set3 = ArrayNew(1) />
	<cfset application.mbc_Utilities.Nexts.FriendlySID.CharacterLists.Set3[1] = ["s","k","q","y","d","r","f","g","v","x","w","z","h","t","p","b","n","j","c","m"] />
	<cfset application.mbc_Utilities.Nexts.FriendlySID.CharacterLists.Set3[2] = ["y","e","u","o","i","a"] />
	<cfset application.mbc_Utilities.Nexts.FriendlySID.CharacterLists.Set3[3] = ["s","d","w","k","q","y","f","g","z","h","t","p","b","r","v","n","j","c","m","x"] />
	<cfset application.mbc_Utilities.Nexts.FriendlySID.ConsonantListMax = ArrayLen(application.mbc_Utilities.Nexts.FriendlySID.CharacterLists.Set1[1]) />	<!--- the most chars we will have --->
	<cfset application.mbc_Utilities.Nexts.FriendlySID.VowelListMax = ArrayLen(application.mbc_Utilities.Nexts.FriendlySID.CharacterLists.Set1[2]) />	<!--- the number of chars in the vowel, range --->
	<cfset application.mbc_Utilities.Nexts.FriendlySID.CheckVowelList = ["a","e","i","u","o","y","a","e","o"] />	<!--- the string of 'vowels' that are used in the SID check character, needs to be 9 long to ease calculation --->
	<cfset application.mbc_Utilities.Nexts.FriendlySID.CheckVowelListMax = 9 />
	<cfset application.mbc_Utilities.Nexts.FriendlySID.LegalLengths = "3,7,10" />	<!--- the legit lengths of the various sized strings for each format, ie a multiple of triplets plus check char if more than one --->
	<cfset application.mbc_Utilities.Nexts.FriendlySID.MaxSets = "3" />	<!--- the maximum number of triplets available/legal --->
	<!--- ExtendedSID is the bigger number, not so human rememberable strings --->
	<cfset application.mbc_Utilities.Nexts.ExtendedSID = StructNew() />
	<cfset application.mbc_Utilities.Nexts.ExtendedSID.CharacterLists = StructNew() />
	<cfset application.mbc_Utilities.Nexts.ExtendedSID.CharacterLists.Set1 = ArrayNew(1) />
	<cfset application.mbc_Utilities.Nexts.ExtendedSID.CharacterLists.Set1[1] = ["Z","b","V","z","J","S","d","x","K","R","w","g","v","h","t","M","L","j","s","k","r","m","q","n","p","B","C","Y","D","X","F","W","c","G","H","T","y","N","f","P"] />	<!--- the string of consonants that are used in a SID value string --->
	<cfset application.mbc_Utilities.Nexts.ExtendedSID.CharacterLists.Set1[2] = ["a","U","i","e","u","A","y","E","o"] />	<!--- the string of 'vowels' that are used in a SID value string, only chars act like vowels --->
	<cfset application.mbc_Utilities.Nexts.ExtendedSID.CharacterLists.Set1[3] = ["b","n","p","z","h","t","j","c","m","q","y","d","x","s","k","r","f","w","g","v","B","Z","C","Y","D","X","F","W","G","V","H","T","J","S","K","R","M","L","N","P"] />
	<cfset application.mbc_Utilities.Nexts.ExtendedSID.CharacterLists.Set2 = ArrayNew(1) />
	<cfset application.mbc_Utilities.Nexts.ExtendedSID.CharacterLists.Set2[1] = ["z","h","t","p","b","n","j","c","m","x","s","k","q","y","d","r","f","g","v","w","B","Z","C","Y","D","X","F","W","G","V","H","T","J","S","K","R","M","L","N","P"] />
	<cfset application.mbc_Utilities.Nexts.ExtendedSID.CharacterLists.Set2[2] = ["i","a","e","o","E","u","A","U","y"] />
	<cfset application.mbc_Utilities.Nexts.ExtendedSID.CharacterLists.Set2[3] = ["f","g","z","h","t","p","b","r","v","n","j","c","m","x","s","d","w","k","q","y","B","Z","C","Y","D","X","F","W","G","V","H","T","J","S","K","R","M","L","N","P"] />
	<cfset application.mbc_Utilities.Nexts.ExtendedSID.CharacterLists.Set3 = ArrayNew(1) />
	<cfset application.mbc_Utilities.Nexts.ExtendedSID.CharacterLists.Set3[1] = ["b","c","d","f","g","h","j","k","m","n","p","q","r","s","t","v","w","x","y","z","B","Z","C","Y","D","X","F","W","G","V","H","T","J","S","K","R","M","L","N","P"] />
	<cfset application.mbc_Utilities.Nexts.ExtendedSID.CharacterLists.Set3[2] = ["e","a","y","o","u","i","A","E","U"] />
	<cfset application.mbc_Utilities.Nexts.ExtendedSID.CharacterLists.Set3[3] = ["B","c","T","m","x","s","w","k","z","q","r","v","n","j","y","f","g","h","t","p","b","Z","C","Y","D","X","F","W","G","V","H","d","J","S","K","R","M","L","N","P"] />
	<cfset application.mbc_Utilities.Nexts.ExtendedSID.ConsonantListMax = ArrayLen(application.mbc_Utilities.Nexts.FriendlySID.CharacterLists.Set3[3]) />	<!--- the most chars we will have --->
	<cfset application.mbc_Utilities.Nexts.ExtendedSID.VowelListMax = ArrayLen(application.mbc_Utilities.Nexts.FriendlySID.CharacterLists.Set3[2]) />	<!--- the number of chars in the vowel, range --->
	<cfset application.mbc_Utilities.Nexts.ExtendedSID.CheckVowelList = ["a","e","i","u","o","y","A","E","U"] />	the string of 'vowels' that are used in the SID check character, needs to be 9 long to ease calculation
	<cfset application.mbc_Utilities.Nexts.ExtendedSID.CheckVowelListMax = 9 />
	<cfset application.mbc_Utilities.Nexts.ExtendedSID.LegalLengths = "3,7,10" />	<!--- the legit lengths of the various sized strings for each format --->
	<cfset application.mbc_Utilities.Nexts.ExtendedSID.MaxSets = "3" />	<!--- the maximum number of triplets available/legal --->
	<!--- and the inital values ot save from having to calculate them --->
	<cfset application.mbc_Utilities.Nexts.FirstValues = StructNew() />
	<cfset application.mbc_Utilities.Nexts.FirstValues.NT = "1" />
	<cfset application.mbc_Utilities.Nexts.FirstValues.FS = "bab" />
	<cfset application.mbc_Utilities.Nexts.FirstValues.FL = "fizabab" />
	<cfset application.mbc_Utilities.Nexts.FirstValues.FX = "sysfizabab" />
	<cfset application.mbc_Utilities.Nexts.FirstValues.ES = "baZ" />
	<cfset application.mbc_Utilities.Nexts.FirstValues.EL = "fizabaZ" />
	<cfset application.mbc_Utilities.Nexts.FirstValues.EX = "BebfizabaZ" />
</cffunction>

<cffunction name="$refreshNexts" access="package" output="No" returntype="void" hint="internal use, refreshes the 'Nexts' structure from the DB">
	<cfset var thisTimeStamp = "" />
	<cfset var theItems = "" />
	<cfset var GoodDecodeFlag = True />
	<cfset var thePacket = "" />
	<cfset var theStore = StructNew() />
	<cfset var getNexts = "" />	<!--- localise the query --->
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorText = "$refreshNexts():-<br>" />
	<cfset ret.Data = "" />
	
	<!--- see whether we are a full DB or the local store and process accordingly --->
	<cfif application.mbc_Utilities.Nexts.DSN eq "Local">	
		<!--- for the local store just grab the data in its WDDX packet and decode it --->
		<!--- first see if the file exists, this might be first time in --->
		<cfif FileExists("#application.mbc_Utilities.Nexts.LocalDataFolderPath#Nexts.wddx.cfm")>
			<cftry>
				<cffile action="read" file="#application.mbc_Utilities.Nexts.LocalDataFolderPath#Nexts.wddx.cfm" variable="thePacket" />
				<cfwddx action="WDDX2CFML" output="theStore" input="#thePacket#" />
			<cfcatch type="Any">
				<!--- poo it broke so don't save anything --->
				<cfset GoodDecodeFlag = False />
			</cfcatch>
			</cftry>
			<cfif GoodDecodeFlag>
				<cfset application.mbc_Utilities.Nexts.data = Duplicate(theStore) />
			<cfelse>
				<cfset ret.error.ErrorCode = 1 />
				<cfset ret.error.ErrorText = ret.error.ErrorText & "Data Read Failed<br>" />
			</cfif>
		<cfelse>		
			<!--- it is not there so assume a first hit and leave data structure empty --->
			<cfset application.mbc_Utilities.Nexts.LastUpdate = DateFormat(Now(), "YYYYMMDD") />	
		</cfif>
	<cfelse>
		<!--- its the database so grab the latest data --->
		<cfquery name="getNexts" datasource="#application.mbc_Utilities.Nexts.dsn#">
			select	IDName, NextIDValue, NextTimeStamp, IDFormat
				from	#application.mbc_Utilities.Nexts.NextsTable#
				where	flag_CurrentData = 1
		</cfquery>
		<cfif getNexts.RecordCount>
			<!--- loop over the result and load up the local structure --->	
			<cfloop query="getNexts">
				<cfset application.mbc_Utilities.Nexts.Data["#getNexts.IDName#"] = StructNew() />	
				<cfset application.mbc_Utilities.Nexts.Data["#getNexts.IDName#"].Value = getNexts.NextIDValue />
				<cfset application.mbc_Utilities.Nexts.Data["#getNexts.IDName#"].IDFormat = getNexts.IDFormat />
				<cfif getNexts.NextTimeStamp neq "" and IsDate(getNexts.NextTimeStamp)>	<!--- see if we have a timestamp or a null from an empty db table --->
					<!--- if we have a date then load it --->
					<cfset application.mbc_Utilities.Nexts.Data["#getNexts.IDName#"].NextTimeStamp = getNexts.NextTimeStamp />
					<cfset thisTimeStamp = DateFormat(getNexts.NextTimeStamp, "YYYYMMDD") />
				<cfelse>
					<cfset application.mbc_Utilities.Nexts.Data["#getNexts.IDName#"].NextTimeStamp = Now() />
					<cfset thisTimeStamp = DateFormat(Now(), "YYYYMMDD") />
				</cfif>	
				<!--- we also need to get the latest timestamp for the update rollover --->
				<cfif thisTimeStamp gt application.mbc_Utilities.Nexts.LastUpdate>
					<cfset application.mbc_Utilities.Nexts.LastUpdate = thisTimeStamp />	
				</cfif>
			</cfloop>
		<cfelse>
			<!--- no records yet so make the LastUpdate date current --->
			<cfset application.mbc_Utilities.Nexts.LastUpdate = DateFormat(Now(), "YYYYMMDD") />	
		</cfif>	
	</cfif>
	<cfset application.mbc_Utilities.Nexts.Initialized = True />	<!--- flag that all is running --->
</cffunction>

<cffunction name="$IncrementNextValue" output="No" returntype="string" access="package"
	displayname="Increment NextID"
	hint="Increments the NextID value to the next one depending on its format. Return null if bad input data"
	>
	<cfargument name="value" type="string" required="yes" hint="value to incrment">	
	<cfargument name="format" type="string" required="yes" hint="format of the value">	

	<cfset var newValue = "" />
  
  <cfif arguments.format eq "NT">
  	<!--- its a simple integer we can handle that here --->
		<cfset newValue = arguments.value+1 />
		<cfif newValue gt 4294967295>	<!--- handle roll over of 32bit number --->
			<cfset newValue = 1 />
		</cfif>
  <cfelseif ListFindNoCase("FS,FL,FX,ES,EL,EX", arguments.format)>
  	<!--- its a string so call the string increment engine --->
		<cfset newValue = $IncrementSIDvalue(value="#arguments.value#", format="#arguments.format#") />
  <cfelse>
  	<!--- oops, bad format asked for so return null to flag that --->
		<cfset newValue = "" />
  </cfif>
  
	<cfreturn newValue  />
</cffunction>

<cffunction name="$IncrementSIDvalue" access="package" output="no" returntype="string" hint="increments a string integer of the SID 'babbab' form">
	<cfargument name="Value" type="string" default="" hint="returns new SID string and check character. Input has to be one of the standard 'bab' formats, otherwise returns nulls for values">
	<cfargument name="format" type="string" required="yes" hint="format of the value">	

	<cfset var theResult = "" />	<!--- we are going to return a null if incoming was badly formatted --->
	<cfset var temp = "" />	<!--- temp home for the return of the increment which is a structure --->
	<cfset var theTriplet = "" />	<!--- temp triplet to manipulate --->
	<cfset var Set1Result = "" />	<!--- result for least significant set --->
	<cfset var Set2Result = "" />	<!--- result for mid significant set --->
	<cfset var Set3Result = "" />	<!--- result for most significant set --->
	<cfset var CheckChar = "" />	<!--- the calculated check character --->

	<cfif (arguments.format eq "FS" or arguments.format eq "ES") and len(arguments.value) eq 3>
		<cfset theResult = $IncrementSIDtriplet(value="#arguments.value#", Set="1", format="#arguments.format#").NewSID />
	<cfelseif arguments.format eq "FL" or arguments.format eq "EL" and len(arguments.value) eq 7>
  	<cfset theTriplet = right(arguments.value, 3) />	<!--- grab the three rightmost chars --->
		<cfset temp = $IncrementSIDtriplet(value="#theTriplet#", Set="1", format="#arguments.format#") />
		<cfset Set1Result = temp.NewSID />
		<cfset CheckChar = $getSIDtripletCheckSum(value="#Set1Result#", Set="1", format="#arguments.format#") />
		<cfif temp.Carried>
	  	<cfset theTriplet = left(arguments.value, 3) />	<!--- grab the three leftmost chars --->
			<cfset temp = $IncrementSIDtriplet(value="#theTriplet#", Set="2", format="#arguments.format#") />
			<cfset Set2Result = temp.NewSID />
		<cfelse>
			<cfset Set2Result = left(arguments.value, 3) />
		</cfif>
		<cfset theResult = Set2Result & CheckChar & Set1Result />
	<cfelseif arguments.format eq "FX" or arguments.format eq "EX" and len(arguments.value) eq 10>
  	<!--- three triplets to play with this time --->
  	<cfset theTriplet = right(arguments.value, 3) />	<!--- grab the three rightmost chars --->
		<cfset temp = $IncrementSIDtriplet(value="#theTriplet#", Set="1", format="#arguments.format#") />
		<cfset Set1Result = temp.NewSID />
		<cfset CheckChar = $getSIDtripletCheckSum(value="#theTriplet#", Set="1", format="#arguments.format#") />
		<cfif temp.Carried>
	  	<cfset theTriplet = mid(arguments.value, 4, 3) />	<!--- grab the three middle chars b4 the check char --->
			<cfset temp = $IncrementSIDtriplet(value="#theTriplet#", Set="2", format="#arguments.format#") />
			<cfset Set2Result = temp.NewSID />
			<cfif temp.Carried>
		  	<cfset theTriplet = left(arguments.value, 3) />	<!--- grab the three leftmost chars --->
				<cfset temp = $IncrementSIDtriplet(value="#theTriplet#", Set="3", format="#arguments.format#") />
				<cfset Set3Result = temp.NewSID />
			<cfelse>
				<cfset Set3Result = mid(arguments.value, 4, 3) />
			</cfif>
		<cfelse>
			<!--- no carry from right triplet increment, feed straight out as no carry --->
			<cfset Set2Result = mid(arguments.value, 4, 3) />
	  	<cfset Set3Result = left(arguments.value, 3) />
		</cfif>
		<cfset theResult = Set3Result & Set2Result & CheckChar & Set1Result />
	<cfelse>
		<!--- bad format or something --->
	</cfif>

	<cfreturn theResult>
</cffunction>

<cffunction name="$IncrementSIDtriplet" access="package" output="no" returntype="struct" hint="increments a string integer of the SID 'bab' form">
	<cfargument name="Value" type="string" default="bababab" hint="returns new SID string and carry flag. Input has to be of 'bab' format, otherwise returns nulls for values">
	<cfargument name="Set" type="string" default="1" hint="which set if a multi-triplet SID">
	<cfargument name="format" type="string" required="yes" hint="format of the value">	

	<cfset var theInputValue = trim(arguments.Value) />
	<cfset var theInputSet = trim(arguments.Set) />
	<cfset var theformat = trim(arguments.format) />
	<cfset var FormatStruct = "" />	<!--- will be the structure for the desired format ---> 
	<cfset var theLeastConsonantSetList = 1 /> <!--- will be 1,3,5 for the least sig char --->
	<cfset var theVowelSetList = 1 /> <!--- will be 1,2,3 depending on which triplet --->
	<cfset var theMostConsonantSetList = 1 /> <!--- will be 2,4,6 --->
	<cfset var theTestChar = "" />
	<cfset var theTestCharPos = 0 />
	<cfset var theNewCharPos = 0 />
	<cfset var thisPos = 0 />
	<cfset var CarryOne = False />
	<cfset var theCheckValue = 0 />
	<cfset var theCharPosArray = ArrayNew(1) />
	<cfset var ValidIncrement = True />
	<cfset var ValidParameters = True />
	<cfset var theResult = {NewSID="", Carried=False} />	<!--- we are going to return nulls if incoming was badly formatted --->
  
  <cfif ListFindNoCase("FL,FS,FX", theformat)>
		<cfset FormatStruct = application.mbc_Utilities.Nexts.FriendlySID />	<!--- the friendly string sets, 20 chars ---> 
  <cfelseif ListFindNoCase("EL,ES,EX", theformat)>
		<cfset FormatStruct = application.mbc_Utilities.Nexts.ExtendedSID />	<!--- the Extended string sets, 40 chars ---> 
  <cfelse>
		<cfset ValidParameters = False />
  </cfif>	
	<cfif ValidParameters and len(theInputValue) eq 3 and theInputSet gt 0 and theInputSet lte FormatStruct.MaxSets>
		<!--- grab the last, least significant char and increment it and then look for rollover, etc and carry up as needed --->
		<cfset theTestChar = Right(theInputValue, 1) />
		<cfset theTestCharPos = ListFind(ArrayToList(FormatStruct.CharacterLists["Set#theInputSet#"][1]), theTestChar) />	<!--- should be between 1 & 20 or 1 & 40 and is case sensitive --->
		<cfif theTestCharPos neq 0>
			<cfset theNewCharPos = theTestCharPos+1 />
			<cfset theCheckValue = theNewCharPos />
			<cfif theNewCharPos GT FormatStruct.ConsonantListMax>
				<cfset CarryOne = True />
			</cfif>
			<cfif not CarryOne>
				<!--- no carry so add the new last char in and we are done --->
				<cfset theResult.NewSID = left(theInputValue, 2) & FormatStruct.CharacterLists["Set#theInputSet#"][1][theNewCharPos] />
			<cfelse>
				<!--- we carried so we need to ripple it through --->
				<!--- walk though as only two more things to check, grab the chars first off --->
				<cfset theTestChar = Mid(theInputValue, 2, 1) />
				<cfset theCharPosArray[2] = ListFind(ArrayToList(FormatStruct.CharacterLists["Set#theInputSet#"][2]), theTestChar) />
				<cfset theTestChar = left(theInputValue, 1) />
				<cfset theCharPosArray[3] = ListFind(ArrayToList(FormatStruct.CharacterLists["Set#theInputSet#"][3]), theTestChar) />
				<cfset theCharPosArray[1] = 1 />	<!--- least significant back to one --->
				<!--- then increment #2, rolling over again if needed --->
				<cfset theCharPosArray[2] = theCharPosArray[2]+1 />	<!--- should be between 1 & 6 --->
				<cfif theCharPosArray[2] gt FormatStruct.VowelListMax>
					<!--- it needs to roll over so lets do it again, set this char to 1 and test the next up the pile --->
					<cfset theCharPosArray[2] = 1 />
					<cfset theCharPosArray[3] = theCharPosArray[3]+1 />	<!--- should be between 1 & 20 --->
					<cfif theCharPosArray[3] gt FormatStruct.ConsonantListMax>
						<cfset theCharPosArray[3] = 1 />
						<cfset theResult.Carried = True />
					</cfif>
				</cfif>
				<cfset theResult.NewSID = FormatStruct.CharacterLists["Set#theInputSet#"][3][theCharPosArray[3]] 
																	& FormatStruct.CharacterLists["Set#theInputSet#"][2][theCharPosArray[2]] 
																	& FormatStruct.CharacterLists["Set#theInputSet#"][1][theCharPosArray[1]] />
			</cfif>	<!--- end: carry handling --->
		</cfif>	<!--- end: least sig char was valid --->
	</cfif>	<!--- end: string correct length --->
	
	<cfreturn theResult>
</cffunction>

<cffunction name="$getSIDtripletCheckSum" access="package" output="no" returntype="string" hint="increments a string integer of the SID 'babbab' form">
	<cfargument name="Value" type="string" default="bababab" hint="returns new SID string and carry flag. Input has to be of 'bab' format, otherwise returns nulls for values">
	<cfargument name="Set" type="string" default="1" hint="which set if a multi-triplet SID">
	<cfargument name="format" type="string" required="yes" hint="format of the value">	

	<cfset var theInputValue = trim(arguments.Value) />
	<cfset var theInputSet = trim(arguments.Set) />
	<cfset var theformat = trim(arguments.format) />
	<cfset var FormatStruct = "" />	<!--- will be the structure for the desired format ---> 
	<cfset var theCheckValue = 0 />
	<cfset var ValidParameters = True />
	<cfset var theResult = "" />	<!--- we are going to return a null if incoming was badly formatted --->

  <cfif ListFindNoCase("FL,FS,FX", theformat)>
		<cfset FormatStruct = application.mbc_Utilities.Nexts.FriendlySID />	<!--- the friendly string sets, 20 chars ---> 
  <cfelseif ListFindNoCase("EL,ES,EX", theformat)>
		<cfset FormatStruct = application.mbc_Utilities.Nexts.ExtendedSID />	<!--- the Extended string sets, 40 chars ---> 
  <cfelse>
		<cfset ValidParameters = False />
  </cfif>	
	<cfif ValidParameters and len(theInputValue) eq 3 and theInputSet gt 0 and theInputSet lte FormatStruct.MaxSets>
		<cfset theTestChar = Right(theInputValue, 1) />
		<cfset theCheckValue = ListFind(ArrayToList(FormatStruct.CharacterLists["Set#theInputSet#"][1]), theTestChar) />	<!--- should be between 1 & 20 or 1 & 40 and is case sensitive --->
		<cfif theCheckValue gt 9>	<!--- somewhere between 1 and 40 --->
			<!--- shrink it to be lt 9 --->
			<cfset theCheckValue = left(theCheckValue,1) + right(theCheckValue,1) />	<!--- don't we love typeless languages :-) --->
			<cfif theCheckValue gt 9>	<!--- somewhere between 1 and 12 by now (3+9 is the biggest we can get) --->
				<!--- shrink it to be lt 9 --->
				<cfset theCheckValue = left(theCheckValue,1) + right(theCheckValue,1) />
			</cfif>
		</cfif>
		<!--- now add in the middle char, the vowels so a max of 10 --->
		<cfset theTestChar = mid(theInputValue, 1, 1) />
		<cfset theCheckValue = theCheckValue + ListFind(ArrayToList(FormatStruct.CharacterLists["Set#theInputSet#"][2]), theTestChar) /> 
		<cfif theCheckValue gt 9>	<!--- somewhere between 1 and 19 --->
			<!--- shrink it to be lt 9 --->
			<cfset theCheckValue = left(theCheckValue,1) + right(theCheckValue,1) />
			<cfif theCheckValue gt 9>	<!--- somewhere between 1 and 10 by now --->
				<!--- shrink it to be lt 9 --->
				<cfset theCheckValue = left(theCheckValue,1) + right(theCheckValue,1) />
			</cfif>
		</cfif>
		<!--- the most sig char --->
		<cfset theTestChar = left(theInputValue, 1) />
		<cfset theCheckValue = theCheckValue + ListFind(ArrayToList(FormatStruct.CharacterLists["Set#theInputSet#"][2]), theTestChar) /> 
		<cfif theCheckValue gt 9>	<!--- somewhere between 2 and 49 --->
			<!--- shrink it to be lt 9 --->
			<cfset theCheckValue = left(theCheckValue,1) + right(theCheckValue,1) />
			<cfif theCheckValue gt 9>	<!--- somewhere between 1 and 15 by now --->
				<!--- shrink it to be lt 9 --->
				<cfset theCheckValue = left(theCheckValue,1) + right(theCheckValue,1) />
			</cfif>
		</cfif>
		<!--- we now have a number between 1 and 9 --->
		<cfset theResult = ListGetAt(ArrayToList(FormatStruct.CheckVowelList), theCheckValue) />
  </cfif>	

	<cfreturn theResult>
</cffunction>

<cffunction name="Nexts_getPersistentData" output="No" returntype="struct" access="public"  
	displayname="get Persistent Data"
	hint="gets the specified application.mbc_Utilities.Nexts structure or the data struct"
	>
	<cfargument name="Struct" type="string" required="No" default="" hint="name of struct to return, defaults to 'data'">	

	<cfif len(arguments.Struct) and StructKeyExists(application.mbc_Utilities.Nexts, "#arguments.Struct#")>
		<cfreturn application.mbc_Utilities.Nexts["#arguments.Struct#"] />
	<cfelse>
		<cfreturn application.mbc_Utilities.Nexts.data />
	</cfif>
</cffunction>

</cfcomponent>