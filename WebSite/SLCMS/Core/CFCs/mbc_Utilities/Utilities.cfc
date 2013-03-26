<!--- mbc CFCs  --->
<!--- &copy; mort bay communications --->
<!---  --->
<!--- a common code set of utilities for common tasks --->
<!--- this CFC needs to be persistent otherwise Nexts has to reinit itself every call--->
<!---  --->
<!--- Contains:
			Nexts() - an improved nexts function with audit trail to create the "next Free ID" integer/string for IDs/Refs in DBs
			SafeStringEnCode() - takes a string and encodes illegal characters to make a Windows-file-name-safe or XML string
			SafeStringDeCode() - takes a string and decodes coded Windows-file-name-illegal characters to make the original string
			 --->
<!---  --->
<!--- Created:  15th Jan 2007 by Kym K --->
<!--- Modified: 20th Jan 2007 - 21st Jan 2007 by Kym K, working on it --->
<!--- Modified: 20th May 2007 - 20th May 2007 by Kym K, tidying up local declarations in functions, now failing in BD7 --->
<!--- Modified:  7th Sep 2007 -  8th Sep 2007 by Kym K, Nexts - went to DB agnostic code, added code to allow local db as well as to datasource --->
<!--- Modified: 18th Sep 2007 - 18th Sep 2007 by Kym K, Nexts - added null handler for empty databases/new IDs to give correct timestamp --->
<!--- Modified: 11th Oct 2007 - 11th Oct 2007 by Kym K, added string encode/decode functions --->
<!--- Modified: 14th Oct 2007 - 14th Oct 2007 by Kym K, Nexts - added setNextID and getNextsGlobal functions --->
<!--- Modified: 12th Dec 2007 - 12th Dec 2007 by Kym K, Nexts - added a batch of bit manipulation functions, bit pattern to integer related NOT THERE, STUFF HAPPENED --->
<!--- Modified: 13th Feb 2008 - 14th Feb 2008 by Kym K, Maths - added function formatIPv4() to take a random dotted quad IP adress and format as requested --->
<!--- Modified: 30th Mar 2008 - 30th Mar 2008 by Kym K, String - added function tagStripper() to remove html tags from string with exceptions as requested --->
<!--- Modified: 20th May 2008 - 20th May 2008 by Kym K, String - added function IsValidEddress() to check if supplied string is a valid email address --->
<!--- Modified:  2nd Jun 2008 -  2nd Jun 2008 by Kym K, String - IsValidEddress() added check for "@." as we see heaps of them --->
<!--- Modified: 16th Oct 2009 - 16th Oct 2009 by Kym K, String - IsValidEddress() added check for " " as we see heaps of them --->
<!--- Modified: 17th Jan 2011 - 17th Jan 2011 by Kym K, String - added LegaliseFolderName functions --->
<!--- Modified:  3rd Jul 2011 -  6th Jul 2011 by Kym K, Nexts - added string version of Nexts and general tidy up --->
<!--- Modified: 18th Dec 2011 - 21st Dec 2011 by Kym K, Nexts - improved string version of Nexts with a check character --->
<!--- Modified:  4th Feb 2012 -  7th Feb 2012 by Kym K, Nexts - improved the improved string version of Nexts with simpler options, an init method and extended range --->
<!--- modified:  9th Apr 2012 -  9th Apr 2012 by Kym K, mbcomms: V3.0, CFWheels version. All SLCMS in own struct under app scope --->

<cfcomponent 	
	displayname="mbc Standard Utilities" 
	hint="contains standard utilities such as the 'Nexts', maths and string manipulation functionality"
	>
	
	<!--- set up a few persistant things on the way in --->
	<cfset variables.Nexts = StructNew() />	
	<cfset variables.Nexts.Data = StructNew() />	
	<cfset variables.Nexts.DSN = "" />
	<cfset variables.Nexts.NextsTable = "" />
	<cfset variables.Nexts.LastUpdate =  "" />	<!--- date of last update, defaults to null for fresh installs to update --->
	<cfset variables.Nexts.UpdatePeriod = 1 />	<!--- time between date updates, in days --->
	<cfset variables.Nexts.DataFolderPath = "" />	<!--- path to local datastore, if required --->
	<cfset variables.Nexts.Initialized = False />	<!--- path to local datastore, if required --->

<!--- initialise the various thingies, this should only be called after an app scope frefresh --->
<cffunction name="init" access="public" output="No" returntype="struct" hint="sets up the internal structures for this component">
	<cfargument name="DefStructure" type="struct" default="">	<!--- the name of the structure that defines everything --->
	<cfargument name="NextsDSN" type="string" default="">	<!--- the name of the database that has the relevant tables such as "Nexts" --->
	<cfargument name="NextsLocalDSN" type="string" default="">	<!--- the path to the Nexts database if it is local --->
	<cfargument name="NextsTable" type="string" default="Nexts">	<!--- the name of the database table for "Nexts" --->
	<cfargument name="NextsUpdateRate" type="string" default="1">	<!--- time between date updates, in days --->
	<cfargument name="ThreadsDSN" type="string" default="">	<!--- the database dsn name in the config file for where the Threads tables are --->
	<cfargument name="ThreadsLinkTable" type="string" default="theThread_Links">	<!--- the name of the database table for the Thread Links --->
	<cfargument name="ThreadsMatrixTable" type="string" default="theThread_Matrix">	<!--- the name of the database table for the Thread Matrix --->
	<cfargument name="ThreadsSetTable" type="string" default="theThread_Sets">	<!--- the name of the database table for the Thread Sets --->

	<cfset var getThreadSet = "" />	<!--- localise query --->
	<cfset var getThreads = "" />	<!--- localise query --->
	<cfset var thisThreadSetID = "" />	<!--- local var --->
	<cfset var thisThread = "" />	<!--- local var --->
	<cfset var thisSetName = "" />	<!--- local var --->
	
	<!--- dump all of our original data then reinsert the fixed, hard coded stuff --->
	<cfset variables.Nexts = StructNew() />	
	<cfset variables.Nexts.Data = StructNew() />	
	<cfset variables.Nexts.DSN = "" />
	<cfset variables.Nexts.NextsTable = "" />
	<cfset variables.Nexts.LastUpdate =  "" />	<!--- date of last update, defaults to null for fresh installs to update --->
	<cfset variables.Nexts.UpdatePeriod = 1 />	<!--- time between date updates, in days --->
	<cfset variables.Nexts.DataFolderPath = "" />	<!--- path to local datastore, if required --->

	<cfif IsStruct(arguments.DefStructure)>
		<!--- if we have a definition structure use that --->
		<cfif arguments.DefStructure.Nexts_Mode eq "Local">
			<cfset variables.Nexts.DSN = "Local" />
		<cfelse>
			<cfset variables.Nexts.DSN = application.SLCMS.Config.DataSources[arguments.DefStructure.Nexts_Mode] />
		</cfif>
		<cfset variables.Nexts.NextsTable = arguments.DefStructure.Nexts_Table />
		<cfset variables.Nexts.UpdatePeriod = arguments.DefStructure.Nexts_UpdatePeriod />	<!--- time between date updates, in days --->
	<cfelse>
		<cfset variables.Nexts.DSN = arguments.NextsDSN />
		<cfset variables.Nexts.NextsTable = arguments.NextsTable />
		<cfif IsNumeric(arguments.NextsUpdateRate)>
			<cfset variables.Nexts.UpdatePeriod = arguments.NextsUpdateRate />
		</cfif>
	</cfif>
	<cfif variables.Nexts.DSN eq "Local">	<!--- specific case of a local db store not a database dsn --->
		<!--- set up a path to the local database storage area --->
		<cfif arguments.NextsLocalDSN neq "">
			<cfset variables.Nexts.DataFolderPath = arguments.NextsLocalDSN />
		<cfelseif arguments.NextsLocalDSN eq "" and StructKeyExists(application.SLCMS.Config.startup, "DatabaseRootPath")>
			<cfset variables.Nexts.DataFolderPath = application.SLCMS.Config.startup.DatabaseRootPath />
		<cfelse>
			<cfset variables.Nexts.DataFolderPath = "" />
		</cfif>
	</cfif>
	
	<cfset initNexts() />	<!--- initialize the Nexts engine --->

	<cfreturn this />
</cffunction>

<cffunction name="getVariablesScope" output="No" returntype="struct" access="public"  
	displayname="get Variables"
	hint="gets the specified variables structure or the entire variables scope"
	>
	<cfargument name="Struct" type="string" required="No" default="" hint="struct to return, defaults to 'all'">	

	<cfif len(arguments.Struct) and StructKeyExists(variables, "#arguments.Struct#")>
		<cfreturn variables["#arguments.Struct#"] />
	<cfelse>
		<cfreturn variables />
	</cfif>
</cffunction>

<!--- first the Nexts functions --->
	<!--- 
		we have two types of Nexts, both represent an increasing value up to a defined limit where they roll over. 
		Normally used as a referenceID or similar. Legacy code used just integers so the defaults point to that version if this CFC is dropped into older applications
		GetNextID() supplies the next free value and then in the background increments and updates the database for persistence. The Next value can be:  
		a straight integer, 32bit so max is 4G: 4,294,967,295
		a string representing a value in a human friendly way or less friendly if big numbers are needed and there is no need for being so friendly.
		 all strings except the shortest versions have a check character and can be checked for correct string length so are safer against hacking
		The possible strings are:-
		 Friendly-short,     called "FS", looks like        "bab" max value equivalent to             2,400   ~2K
		 Friendly-long,      called "FL", looks like    "fizabab" max value equivalent to         5,760,000   ~6M
		 Friendly-extralong, called "FX", looks like "sysfizabab" max value equivalent to    13,824,000,000  ~14G
		 Extended-short,     called "ES", looks like        "bAZ" max value equivalent to            14,400  ~14K
		 Extended-long,      called "EL", looks like    "fizabaZ" max value equivalent to       207,360,000 ~207M
		 Extended-extralong, called "EX", looks like "BebfizabaZ" max value equivalent to 2,985,984,000,000   ~3T
	 --->
	<!---
		Public Functions Available:
		 getNextID()			- the main call. 
		 										call it with IDName of existing ID and it will return the next free value (then in background updates system to next value). 
		 										A new ID name will create that ID in the system (then updates database in background so it knows about it).
		 ChecknSetNextID	- ensures an ID exists, creates one if not there, returns the current or initial value, does not increment it internally. 
		 										Used by init code and the like to ensure an ID exists  
		 setNextID()			- forces an ID to a specific value with error checking if appropriate (then in background updates database).
		 initNexts()			- sets up data structures and loads persistent values from database on system initialization
		NB, there is a related function that uses the same code base:
			getFriendlyPassword - returns a random FL-type string for use as easy-to-remember passwords.
														not incremental but the check character is valid
	 --->

<cffunction name="initNexts" output="No" returntype="void" access="public" 
	displayname="Initialize Nexts" 
	hint="initializes the Nexts engine, loads hard data and persistent from DB"
	>
	<cfset initNextsHardData() />	<!--- load up the Nexts structure hard coded data --->
	<cfset refreshNexts() />	<!--- load up the Nexts structure with the latest data --->
</cffunction>

<cffunction name="getNextID" access="public" output="No" returntype="string" hint="gets the next free numeric ID for the specified ID name">
	<cfargument name="IDname" type="string" required="yes" hint="name of ID variable to return">	
	<cfargument name="IDFormat" type="string" required="no" default="NT" hint="Format of ID variable to return, integer or various strings, defaults to integer for legacy code">	

	<cfset var theIDname = trim(arguments.IDname) />
	<cfset var theIDFormat = trim(arguments.IDFormat) />
	<cfset var thisFreeID = "" />
	<cfset var nextFreeID = "" />
	<cfset var ret = "" />	<!--- temp var for function return values --->

	<cfif theIDname neq "">
		<cflock timeout="10" throwontimeout="No" name="DoingUpdateNext" type="EXCLUSIVE">	<!--- can't have two happening at once --->
			<cfset thisFreeID = ChecknSetNextID(IDname=theIDname, IDFormat=theIDFormat, flagNeedToUpdateTables=False) />
			<!--- now we know we have a IDname, set to first value if it was just created or the current NextFreeID --->
			<cfif thisFreeID neq "">
				<!--- load the next var ID and increment for the next one --->
				<cfset nextFreeID = IncrementNextValue(value="#thisFreeID#", format="#variables.Nexts.Data[theIDname].IDFormat#") />
				<cfif nextFreeID neq "">
					<cfset variables.Nexts.Data[theIDname].Value = nextFreeID />
					<cfset variables.Nexts.Data[theIDname].NextTimeStamp = Now() />
					<cfset ret = UpdateNextsTable(IDname="#theIDname#") />
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

<cffunction name="ChecknSetNextID" output="No" returntype="string" access="public"
	displayname="Check and Set a NextID" 
	hint="sees if a NextID name exists and if not creates in persistent structures. Returns nothing if bad arguments, otherwise creates the ID, fills with first value if non-existent, and then returns the current value. useful for presetting IDnames"
	>
	<cfargument name="IDname" type="string" required="yes" hint="name of ID variable to return">	
	<cfargument name="IDFormat" type="string" required="no" default="NT" hint="Format of ID variable to return, integer or various strings, defaults to integer for legacy code">	
	<cfargument name="flagNeedToUpdateTables" type="boolean" required="no" default="True" hint="flags that we need to run the UpdateNextsTable Routine">	

	<cfset var theIDname = trim(arguments.IDname) />
	<cfset var theIDFormat = trim(arguments.IDFormat) />
	<cfset var theFirstID = "" />
	<cfset var nextFreeID = "" />
	<cfset var ret = "" />

	<cfif theIDname neq "" and len(theIDFormat) eq 2>	<!--- simple validation, get a bit trickier inside if we have to do something --->
		<cflock timeout="10" throwontimeout="No" name="DoingChecknSetNext" type="EXCLUSIVE">	<!--- can't have two happening at once --->
			<!--- first we must see if this ID exists, no need to do anything if its there --->
			<cfif not StructKeyExists(variables.Nexts.Data, "#theIDname#")>
				<!--- we don't have this one yet so let's add it in --->
				<!--- first check that we had a legit format passed in --->
				<cfif StructKeyExists(variables.Nexts.FirstValues, theIDFormat)>
					<cfset theFirstID = variables.Nexts.FirstValues[theIDFormat] />
			  	<!--- and make the Nexts system have the next one --->
					<cfset variables.Nexts.Data[theIDname] = StructNew() />
					<cfset variables.Nexts.Data[theIDname].Value = theFirstID />
					<cfset variables.Nexts.Data[theIDname].NextTimeStamp = Now() />
					<cfset variables.Nexts.Data[theIDname].IDFormat = theIDFormat />
					<cfif arguments.flagNeedToUpdateTables>
						<cfset ret = UpdateNextsTable(IDname="#theIDname#", mode="NewID") />
					</cfif>
				</cfif>
			<cfelse>
				<!--- we have this one already so just pass back its value --->
				<cfset nextFreeID = variables.Nexts.Data[theIDname].Value />
			</cfif>	<!--- end: ID already exists test --->
		</cflock>
	</cfif>
	<cfreturn nextFreeID />
</cffunction>
<!---
<cffunction name="getNextSID" access="public" output="No" returntype="string" hint="gets the next free SID string for the specified ID name">
	<cfargument name="IDname" type="string" required="yes" hint="name of ID variable to return">	

	<cfset var thisFreeID = "" />
	<cfset var nextFreeID = "" />
	<cfset var ret = "" />

	<cflock timeout="10" throwontimeout="No" name="DoingUpdateNext" type="EXCLUSIVE">	<!--- can't have two happening at once --->
		<!--- first we must see if this ID exists --->
		<cfif StructKeyExists(variables.Nexts.Data, "#arguments.IDname#")>
			<!--- get the next var ID from the persistent struct --->
			<cfset thisFreeID = variables.Nexts.Data[arguments.IDname].Value />
			<cfset nextFreeID = thisFreeID+1 />
			<!--- and increment --->
			<cfset variables.Nexts.Data[arguments.IDname].Value = nextFreeID />
			<!--- check it into the DB --->
			<cfset ret = UpdateNextsTable(IDname="#arguments.IDname#", value="#nextFreeID#") />
		<cfelse>
			<!--- we don't have this one yet so let's add it in --->
			<cfset thisFreeID = 1 />
	  	<!--- and make the Nexts system have the next one --->
			<cfset variables.Nexts.Data[arguments.IDname] = StructNew() />
			<cfset variables.Nexts.Data[arguments.IDname].Value = "babbac" />
			<cfset variables.Nexts.Data[arguments.IDname].NextTimeStamp = Now() />
			<cfset ret = UpdateNextsTable(IDname="#arguments.IDname#", value="babbac", mode="NewID") />
		</cfif>
	</cflock>

	<cfreturn thisFreeID />
</cffunction>
--->
<cffunction name="setNextID" output="yes" returntype="string" access="public"
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
<!---
		<cfif theValue neq "" and (isNumeric(theValue) or len(theValue) eq 6)>
	--->
		<cfif StructKeyExists(variables.Nexts.Data, "#theIDname#")>
			<cftry>
				<cfset variables.Nexts.Data["#arguments.IDname#"].Value = theValue />
				<cfset temp = UpdateNextsTable(IDname="#arguments.IDname#") />
				<cfset ret = theValue />	<!--- this is the return to the caller --->
			<cfcatch type="any">
				<cflog text="setNextID() Trapped. Error Text: #cfcatch.message# - Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#"  file="UtilitiesErrors" type="Error" application = "yes">
				<cfif application.SLCMS.Config.debug.debugmode>
					setNextID() trapped - error was:<br>
					<cfdump var="#cfcatch#">
				</cfif>
			</cfcatch>
			</cftry>
		<cfelse>
			<!--- we don't have this one yet so let's add it in --->
			<cfset variables.Nexts.Data[theIDname] = StructNew() />
			<cfset variables.Nexts.Data[theIDname].Value = theValue />
			<cfset variables.Nexts.Data[theIDname].NextTimeStamp = Now() />
			<cfset ret = UpdateNextsTable(IDname="#theIDname#", mode="NewID") />
		</cfif> <!--- end: incoming parameters new-ness check --->
	</cfif> <!--- end: incoming parameters validation check --->

	<cfreturn ret  />
</cffunction>

<cffunction name="getNextsGlobal" output="No" returntype="struct" access="public"
	displayname="Gets Nexts Global data"
	hint="returns the whole nexts data structure"
				>
	<cfset var ret = variables.Nexts />
	<cfreturn ret  />
</cffunction>

<cffunction name="UpdateNextsTable" access="private" output="No" returntype="void" hint="internal use, updates the 'Nexts' structure in the DB">
	<cfargument name="IDname" type="string" required="yes" hint="name of ID variable to update">	
	<cfargument name="Mode" type="string" default="" hint="flag for if we are adding a new ID">	
	
	<cfset var theMode = trim(arguments.Mode) />	
	<cfset var thePacket = "" />	
	<cfset var temps = StructNew() />	<!--- this is a temp struct for internal use --->
	<cfset var setNextID = "" />	<!--- localise the query --->
	<cfset var GoodWriteFlag = True />
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorText = "mbc Utilities - UpdateNextsTable():-<br>" />
	<cfset ret.Data = "" />
	
	<!--- set the next id in the DB --->
	<cflock timeout="10" throwontimeout="No" name="DoingUpdateNextTable" type="EXCLUSIVE">	<!--- can't have two happening at once --->
		<!--- see whether we are a full DB or the local store and process accordingly --->
		<cfif variables.Nexts.DSN eq "Local">	
			<!--- for the local store just put the data into its WDDX packet and save it --->
	 		<cftry>
				<cfwddx action="CFML2WDDX" output="thePacket" input="#variables.Nexts#" />
				<cffile action="write" file="#variables.Nexts.DataFolderPath#Nexts.wddx" output="#thePacket#" addNewLine="No" />
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
				<cfquery name="setNextID" datasource="#variables.Nexts.dsn#">
					Insert	into	#variables.Nexts.NextsTable#
									(NextIDValue, IDName, flag_CurrentData, NextTimeStamp, IDformat)
					Values	('#variables.Nexts.Data[arguments.IDname].Value#', '#arguments.IDname#', 1, #Now()#, '#variables.Nexts.Data[arguments.IDname].IDformat#')
				</cfquery>
			<cfelse>
				<!--- first check date rollover and then update table row --->
				<cfset temps = UpdateDates(IDname="#arguments.IDname#") />
				<cfquery name="setNextID" datasource="#variables.Nexts.dsn#">
					Update	#variables.Nexts.NextsTable#
						set		NextIDValue = '#variables.Nexts.Data[arguments.IDname].Value#',
									NextTimeStamp = #Now()#
						where	IDName = '#arguments.IDname#'
							and	flag_CurrentData = 1
				</cfquery>
			</cfif>
		</cfif>
  </cflock>
</cffunction>

<cffunction name="UpdateDates" access="private" output="No" returntype="void" hint="internal use, refreshes the date in the DB, makes new row if needed">
	<cfargument name="IDname" type="string" required="yes" default="" hint="name of ID variable to update">	
	
	<!--- get today and see if different to the local timestamp --->	
	<cfset var theNewTimeStamp = DateFormat(Now(), "YYYYMMDD") />
	<cfset var theOldTimeStamp = variables.Nexts.LastUpdate />
	<cfset var setFlagOff = "" />	<!--- localise the query --->
	<cfset var setNextID = "" />	<!--- localise the query --->

	<cfif  variables.Nexts.DSN neq 'Local' and (theNewTimeStamp-theOldTimeStamp) gt variables.Nexts.UpdatePeriod>
		<!--- over the threshold and using the database so create a new row --->
		<cflock timeout="10" throwontimeout="No" name="MakeNewNextsRow" type="EXCLUSIVE">
			<cfif arguments.IDname eq "">	<!--- no specific ID so do the lot --->
				<!--- set the current flag off --->
				<cfquery name="setFlagOff" datasource="#variables.Nexts.dsn#">
					Update	#variables.Nexts.NextsTable#
						set		flag_CurrentData = 0
				</cfquery>
				<!--- then make a new set from our local data --->
				<cfloop collection="#variables.Nexts.Data#" item="thisID">
					<cfquery name="setNextID" datasource="#variables.Nexts.dsn#">
						Insert into	#variables.Nexts.NextsTable#
											(flag_CurrentData, NextTimeStamp, IDName, NextIDValue, IDformat)
							Values	(1, #variables.Nexts.Data[thisID].NextTimeStamp#, '#arguments.IDname#', '#variables.Nexts.Data[thisID].Value#', '#variables.Nexts.Data[thisID].IDformat#')
					</cfquery>
				</cfloop>
			<cfelse>
				<!--- ID was specified so just update it --->
				<!--- set the current flag off --->
				<cfquery name="setFlagOff" datasource="#variables.Nexts.dsn#">
					Update	#variables.Nexts.NextsTable#
						set		flag_CurrentData = 0
						where	IDName = '#arguments.IDname#'
				</cfquery>
				<!--- then make a new set from our local data --->
				<cfquery name="setNextID" datasource="#variables.Nexts.dsn#">
					Insert into	#variables.Nexts.NextsTable#
										(flag_CurrentData, NextTimeStamp, IDName, NextIDValue, IDformat)
						Values	(1, #CreateODBCDateTime(variables.Nexts.Data["#arguments.IDname#"].NextTimeStamp)#, '#arguments.IDname#', '#variables.Nexts.Data["#arguments.IDname#"].Value#', '#variables.Nexts.Data["#arguments.IDname#"].IDformat#')
				</cfquery>
			</cfif>
			<!--- lastly update the day marker --->
			<cfset variables.Nexts.LastUpdate = theNewTimeStamp />	
		</cflock>
	</cfif>
</cffunction>

<cffunction name="initNextsHardData" access="private" output="No" returntype="void" hint="sets up the hard-coded data structures for the Nexts engine">
	<!--- dump then reinsert all of the fixed, hard coded stuff in case the old was contaminated --->
	<!--- friendlySID is the short, human rememberable string --->
	<cfset variables.Nexts.FriendlySID = StructNew() />
	<cfset variables.Nexts.FriendlySID.CharacterLists = StructNew() />
	<cfset variables.Nexts.FriendlySID.CharacterLists.Set1 = ArrayNew(1) />
	<cfset variables.Nexts.FriendlySID.CharacterLists.Set1[1] = ["b","z","c","y","d","x","f","w","g","v","h","t","j","s","k","r","m","q","n","p"] />	<!--- the string of consonants that are used in a SID value string --->
	<cfset variables.Nexts.FriendlySID.CharacterLists.Set1[2] = ["a","i","e","o","u","y"] />	<!--- the string of 'vowels' that are used in a SID value string, only chars act like vowels --->
	<cfset variables.Nexts.FriendlySID.CharacterLists.Set1[3] = ["b","n","p","z","h","t","j","c","m","q","y","d","x","s","k","r","f","w","g","v"] />
	<cfset variables.Nexts.FriendlySID.CharacterLists.Set2 = ArrayNew(1) />
	<cfset variables.Nexts.FriendlySID.CharacterLists.Set2[1] = ["z","h","t","p","b","n","j","c","m","x","s","k","q","y","d","r","f","g","v","w"] />
	<cfset variables.Nexts.FriendlySID.CharacterLists.Set2[2] = ["i","a","y","e","o","u"] />
	<cfset variables.Nexts.FriendlySID.CharacterLists.Set2[3] = ["f","g","z","h","t","p","b","r","v","n","j","c","m","x","s","d","w","k","q","y"] />
	<cfset variables.Nexts.FriendlySID.CharacterLists.Set3 = ArrayNew(1) />
	<cfset variables.Nexts.FriendlySID.CharacterLists.Set3[1] = ["s","k","q","y","d","r","f","g","v","x","w","z","h","t","p","b","n","j","c","m"] />
	<cfset variables.Nexts.FriendlySID.CharacterLists.Set3[2] = ["y","e","u","o","i","a"] />
	<cfset variables.Nexts.FriendlySID.CharacterLists.Set3[3] = ["s","d","w","k","q","y","f","g","z","h","t","p","b","r","v","n","j","c","m","x"] />
	<cfset variables.Nexts.FriendlySID.ConsonantListMax = ArrayLen(variables.Nexts.FriendlySID.CharacterLists.Set1[1]) />	<!--- the most chars we will have --->
	<cfset variables.Nexts.FriendlySID.VowelListMax = ArrayLen(variables.Nexts.FriendlySID.CharacterLists.Set1[2]) />	<!--- the number of chars in the vowel, range --->
	<cfset variables.Nexts.FriendlySID.CheckVowelList = ["a","e","i","u","o","y","a","e","o"] />	<!--- the string of 'vowels' that are used in the SID check character, needs to be 9 long to ease calculation --->
	<cfset variables.Nexts.FriendlySID.CheckVowelListMax = 9 />
	<cfset variables.Nexts.FriendlySID.LegalLengths = "3,7,10" />	<!--- the legit lengths of the various sized strings for each format, ie a multiple of triplets plus check char if more than one --->
	<cfset variables.Nexts.FriendlySID.MaxSets = "3" />	<!--- the maximum number of triplets available/legal --->
	<!--- ExtendedSID is the bigger number, not so human rememberable strings --->
	<cfset variables.Nexts.ExtendedSID = StructNew() />
	<cfset variables.Nexts.ExtendedSID.CharacterLists = StructNew() />
	<cfset variables.Nexts.ExtendedSID.CharacterLists.Set1 = ArrayNew(1) />
	<cfset variables.Nexts.ExtendedSID.CharacterLists.Set1[1] = ["Z","b","V","z","J","S","d","x","K","R","w","g","v","h","t","M","L","j","s","k","r","m","q","n","p","B","C","Y","D","X","F","W","c","G","H","T","y","N","f","P"] />	<!--- the string of consonants that are used in a SID value string --->
	<cfset variables.Nexts.ExtendedSID.CharacterLists.Set1[2] = ["a","U","i","e","u","A","y","E","o"] />	<!--- the string of 'vowels' that are used in a SID value string, only chars act like vowels --->
	<cfset variables.Nexts.ExtendedSID.CharacterLists.Set1[3] = ["b","n","p","z","h","t","j","c","m","q","y","d","x","s","k","r","f","w","g","v","B","Z","C","Y","D","X","F","W","G","V","H","T","J","S","K","R","M","L","N","P"] />
	<cfset variables.Nexts.ExtendedSID.CharacterLists.Set2 = ArrayNew(1) />
	<cfset variables.Nexts.ExtendedSID.CharacterLists.Set2[1] = ["z","h","t","p","b","n","j","c","m","x","s","k","q","y","d","r","f","g","v","w","B","Z","C","Y","D","X","F","W","G","V","H","T","J","S","K","R","M","L","N","P"] />
	<cfset variables.Nexts.ExtendedSID.CharacterLists.Set2[2] = ["i","a","e","o","E","u","A","U","y"] />
	<cfset variables.Nexts.ExtendedSID.CharacterLists.Set2[3] = ["f","g","z","h","t","p","b","r","v","n","j","c","m","x","s","d","w","k","q","y","B","Z","C","Y","D","X","F","W","G","V","H","T","J","S","K","R","M","L","N","P"] />
	<cfset variables.Nexts.ExtendedSID.CharacterLists.Set3 = ArrayNew(1) />
	<cfset variables.Nexts.ExtendedSID.CharacterLists.Set3[1] = ["b","c","d","f","g","h","j","k","m","n","p","q","r","s","t","v","w","x","y","z","B","Z","C","Y","D","X","F","W","G","V","H","T","J","S","K","R","M","L","N","P"] />
	<cfset variables.Nexts.ExtendedSID.CharacterLists.Set3[2] = ["e","a","y","o","u","i","A","E","U"] />
	<cfset variables.Nexts.ExtendedSID.CharacterLists.Set3[3] = ["B","c","T","m","x","s","w","k","z","q","r","v","n","j","y","f","g","h","t","p","b","Z","C","Y","D","X","F","W","G","V","H","d","J","S","K","R","M","L","N","P"] />
	<cfset variables.Nexts.ExtendedSID.ConsonantListMax = ArrayLen(variables.Nexts.FriendlySID.CharacterLists.Set3[3]) />	<!--- the most chars we will have --->
	<cfset variables.Nexts.ExtendedSID.VowelListMax = ArrayLen(variables.Nexts.FriendlySID.CharacterLists.Set3[2]) />	<!--- the number of chars in the vowel, range --->
	<cfset variables.Nexts.ExtendedSID.CheckVowelList = ["a","e","i","u","o","y","A","E","U"] />	<!--- the string of 'vowels' that are used in the SID check character, needs to be 9 long to ease calculation --->
	<cfset variables.Nexts.ExtendedSID.CheckVowelListMax = 9 />
	<cfset variables.Nexts.ExtendedSID.LegalLengths = "3,7,10" />	<!--- the legit lengths of the various sized strings for each format --->
	<cfset variables.Nexts.ExtendedSID.MaxSets = "3" />	<!--- the maximum number of triplets available/legal --->
	<!--- and the inital values ot save from having to calculate them --->
	<cfset variables.Nexts.FirstValues = StructNew() />
	<cfset variables.Nexts.FirstValues.NT = "1" />
	<cfset variables.Nexts.FirstValues.FS = "bab" />
	<cfset variables.Nexts.FirstValues.FL = "fizabab" />
	<cfset variables.Nexts.FirstValues.FX = "sysfizabab" />
	<cfset variables.Nexts.FirstValues.ES = "baZ" />
	<cfset variables.Nexts.FirstValues.EL = "fizabaZ" />
	<cfset variables.Nexts.FirstValues.EX = "BebfizabaZ" />

</cffunction>

<cffunction name="refreshNexts" access="private" output="No" returntype="void" hint="internal use, refreshes the 'Nexts' structure from the DB">
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
	<cfset ret.error.ErrorText = "refreshNexts():-<br>" />
	<cfset ret.Data = "" />
	
	<!--- see whether we are a full DB or the local store and process accordingly --->
	<cfif variables.Nexts.DSN eq "Local">	
		<!--- for the local store just grab the data in its WDDX packet and decode it --->
		<!--- first see if the file exists, this might be first time in --->
		<cfif FileExists("#variables.Nexts.DataFolderPath#Nexts.wddx")>
			<cftry>
				<cffile action="read" file="#variables.Nexts.DataFolderPath#Nexts.wddx" variable="thePacket" />
				<cfwddx action="WDDX2CFML" output="theStore" input="#thePacket#" />
			<cfcatch type="Any">
				<!--- poo it broke so don't save anything --->
				<cfset GoodDecodeFlag = False />
			</cfcatch>
			</cftry>
			<cfif GoodDecodeFlag>
				<cfset variables.Nexts = Duplicate(theStore) />
			<cfelse>
				<cfset ret.error.ErrorCode = 1 />
				<cfset ret.error.ErrorText = ret.error.ErrorText & "Data Read Failed<br>" />
			</cfif>
		<cfelse>		
			<!--- it is not there so assume a first hit and leave data structure empty --->
			<cfset variables.Nexts.LastUpdate = DateFormat(Now(), "YYYYMMDD") />	
		</cfif>
	<cfelse>
		<!--- its the database so grab the latest data --->
		<cfquery name="getNexts" datasource="#variables.Nexts.dsn#">
			select	IDName, NextIDValue, NextTimeStamp, IDFormat
				from	#variables.Nexts.NextsTable#
				where	flag_CurrentData = 1
		</cfquery>
		<cfif getNexts.RecordCount>
			<!--- loop over the result and load up the local structure --->	
			<cfloop query="getNexts">
				<cfset variables.Nexts.Data["#getNexts.IDName#"] = StructNew() />	
				<cfset variables.Nexts.Data["#getNexts.IDName#"].Value = getNexts.NextIDValue />
				<cfset variables.Nexts.Data["#getNexts.IDName#"].IDFormat = getNexts.IDFormat />
				<cfif getNexts.NextTimeStamp neq "" and IsDate(getNexts.NextTimeStamp)>	<!--- see if we have a timestamp or a null from an empty db table --->
					<!--- if we have a date then load it --->
					<cfset variables.Nexts.Data["#getNexts.IDName#"].NextTimeStamp = getNexts.NextTimeStamp />
					<cfset thisTimeStamp = DateFormat(getNexts.NextTimeStamp, "YYYYMMDD") />
				<cfelse>
					<cfset variables.Nexts.Data["#getNexts.IDName#"].NextTimeStamp = Now() />
					<cfset thisTimeStamp = DateFormat(Now(), "YYYYMMDD") />
				</cfif>	
				<!--- we also need to get the latest timestamp for the update rollover --->
				<cfif thisTimeStamp gt variables.Nexts.LastUpdate>
					<cfset variables.Nexts.LastUpdate = thisTimeStamp />	
				</cfif>
			</cfloop>
		<cfelse>
			<!--- no records yet so make the LastUpdate date current --->
			<cfset variables.Nexts.LastUpdate = DateFormat(Now(), "YYYYMMDD") />	
		</cfif>	
	</cfif>
	<cfset variables.Nexts.Initialized = True />	<!--- flag that all is running --->
</cffunction>

<cffunction name="IncrementNextValue" output="No" returntype="string" access="public"
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
		<cfset newValue = IncrementSIDvalue(value="#arguments.value#", format="#arguments.format#") />
  <cfelse>
  	<!--- oops, bad format asked for so return null to flag that --->
		<cfset newValue = "" />
  </cfif>
  
	<cfreturn newValue  />
</cffunction>

<cffunction name="IncrementSIDvalue" access="private" output="no" returntype="string" hint="increments a string integer of the SID 'babbab' form">
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
		<cfset theResult = IncrementSIDtriplet(value="#arguments.value#", Set="1", format="#arguments.format#").NewSID />
	<cfelseif arguments.format eq "FL" or arguments.format eq "EL" and len(arguments.value) eq 7>
  	<cfset theTriplet = right(arguments.value, 3) />	<!--- grab the three rightmost chars --->
		<cfset temp = IncrementSIDtriplet(value="#theTriplet#", Set="1", format="#arguments.format#") />
		<cfset Set1Result = temp.NewSID />
		<cfset CheckChar = getSIDtripletCheckSum(value="#Set1Result#", Set="1", format="#arguments.format#") />
		<cfif temp.Carried>
	  	<cfset theTriplet = left(arguments.value, 3) />	<!--- grab the three leftmost chars --->
			<cfset temp = IncrementSIDtriplet(value="#theTriplet#", Set="2", format="#arguments.format#") />
			<cfset Set2Result = temp.NewSID />
		<cfelse>
			<cfset Set2Result = left(arguments.value, 3) />
		</cfif>
		<cfset theResult = Set2Result & CheckChar & Set1Result />
	<cfelseif arguments.format eq "FX" or arguments.format eq "EX" and len(arguments.value) eq 10>
  	<!--- three triplets to play with this time --->
  	<cfset theTriplet = right(arguments.value, 3) />	<!--- grab the three rightmost chars --->
		<cfset temp = IncrementSIDtriplet(value="#theTriplet#", Set="1", format="#arguments.format#") />
		<cfset Set1Result = temp.NewSID />
		<cfset CheckChar = getSIDtripletCheckSum(value="#theTriplet#", Set="1", format="#arguments.format#") />
		<cfif temp.Carried>
	  	<cfset theTriplet = mid(arguments.value, 4, 3) />	<!--- grab the three middle chars b4 the check char --->
			<cfset temp = IncrementSIDtriplet(value="#theTriplet#", Set="2", format="#arguments.format#") />
			<cfset Set2Result = temp.NewSID />
			<cfif temp.Carried>
		  	<cfset theTriplet = left(arguments.value, 3) />	<!--- grab the three leftmost chars --->
				<cfset temp = IncrementSIDtriplet(value="#theTriplet#", Set="3", format="#arguments.format#") />
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

<cffunction name="IncrementSIDtriplet" access="private" output="no" returntype="struct" hint="increments a string integer of the SID 'bab' form">
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
		<cfset FormatStruct = variables.Nexts.FriendlySID />	<!--- the friendly string sets, 20 chars ---> 
  <cfelseif ListFindNoCase("EL,ES,EX", theformat)>
		<cfset FormatStruct = variables.Nexts.ExtendedSID />	<!--- the Extended string sets, 40 chars ---> 
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
				<!--- we carried so we need to loop up to ripple it through --->
				<!--- walk though as only two more things to check, no need to loop --->
				<cfset theCharPosArray[1] = 1 />	<!--- least significant back to one --->
				<cfset theTestChar = Mid(theInputValue, 2, 1) />
				<cfset theCharPosArray[2] = ListFindNoCase(ArrayToList(FormatStruct.CharacterLists["Set#theInputSet#"][2]), theTestChar) />	<!--- grab the middle char --->
				<!--- and increment, rolling over again if needed --->
				<cfset theCharPosArray[2] = theCharPosArray[2]+1 />	<!--- should be between 1 & 6 --->
				<cfif theCharPosArray[2] gt FormatStruct.VowelListMax>
					<!--- it needs to roll over so lets do it again, set this char to 1 and test the next up the pile --->
					<cfset theCharPosArray[2] = 1 />
					<cfset theTestChar = left(theInputValue, 1) />
					<cfset theCharPosArray[3] = ListFind(ArrayToList(FormatStruct.CharacterLists["Set#theInputSet#"][3]), theTestChar) />	<!--- grab the most significant char --->
					<cfset theCharPosArray[3] = theCharPosArray[3]+1 />	<!--- should be between 1 & 20 --->
					<cfif theCharPosArray[3] gt FormatStruct.ConsonantListMax>
						<cfset theCharPosArray[3] = 1 />
						<cfset theResult.Carried = True />
					</cfif>
				</cfif>
				<cfset theResult.NewSID = FormatStruct.CharacterLists["Set#theInputSet#"][3][theCharPosArray[3]] 
																	& FormatStruct.CharacterLists["Set#theInputSet#"][2][theCharPosArray[2]] 
																	& FormatStruct.CharacterLists["Set#theInputSet#"][1][theCharPosArray[1]] />
				
<!---
				<!--- first fill an array with the positions, with the least significant already rolled over --->
				<cfloop from="2" to="1" step="1" index="thisPos">
					<cfset theCharPosArray[thisPos][1] = Mid(theInputValue, thisPos, 1) />
					<cfif thisPos eq 5 or thisPos eq 2>
						<cfset theCharPosArray[thisPos][2] = ListFindNoCase(variables.Nexts.SIDVowelList, theCharPosArray[thisPos][1]) />
					<cfelse>
						<cfset theCharPosArray[thisPos][2] = ListFindNoCase(variables.Nexts.SIDConsonantList, theCharPosArray[thisPos][1]) />
					</cfif>
				</cfloop>
				<!--- then loop and increment/carry as needed --->
				<cfloop from="5" to="1" step="1" index="thisPos">
					<cfset theTestCharPos = theCharPosArray[thisPos][2] />
					<cfif theTestCharPos neq 0>
						<cfif CarryOne>
							<cfset CarryOne = False />
							<cfset theNewCharPos = theTestCharPos+1 />
							<cfif thisPos eq 5 or thisPos eq 2>
								<cfif theNewCharPos GT variables.Nexts.SIDVowelListMax>
									<cfset CarryOne = True />
									<cfset theNewCharPos = 1 />
								</cfif>
							<cfelse>
								<cfif theNewCharPos GT variables.Nexts.SIDConsonantListMax>
									<cfset CarryOne = True />
									<cfset theNewCharPos = 1 />
								</cfif>
							</cfif>	<!--- end: vowel or consonant increment rollover --->
						<cfelse>
							<cfset theNewCharPos = theTestCharPos />
						</cfif>	<!--- end: carry inc or not --->
						<!---  we now have a new char position and a carry flag so load char back in and loop round --->
						<cfset theCharPosArray[thisPos][2] = theNewCharPos /> 
						<cfset theCharPosArray[thisPos][1] = ListGetAt(variables.Nexts.SIDConsonantList, theCharPosArray[thisPos][2]) />	<!--- grab the related char --->
					<cfelse>
						<!--- oops! a bad char --->
						<cfset ValidIncrement = False />
						<cfbreak><!--- QUICK AND DIRTY OUT of incrementing loop --->
					</cfif>
				</cfloop>
				<!--- we now have an array of meaningful chars so loop over and make up our new SID string --->
				<cfif ValidIncrement>
					<cfloop from="3" to="1" step="-1" index="thisPos">
						<cfset theResult.NewSID = theResult.NewSID & theCharPosArray[thisPos][1] />
					</cfloop>
				</cfif>
--->
			</cfif>	<!--- end: carry handling --->
		</cfif>	<!--- end: least sig char was valid --->
	</cfif>	<!--- end: string correct length --->
	
	<cfreturn theResult>
</cffunction>

<cffunction name="getSIDtripletCheckSum" access="private" output="no" returntype="string" hint="increments a string integer of the SID 'babbab' form">
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
		<cfset FormatStruct = variables.Nexts.FriendlySID />	<!--- the friendly string sets, 20 chars ---> 
  <cfelseif ListFindNoCase("EL,ES,EX", theformat)>
		<cfset FormatStruct = variables.Nexts.ExtendedSID />	<!--- the Extended string sets, 40 chars ---> 
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
<!--- end of Nexts functions --->

<!--- some formatting thingies --->
<cffunction name="formatIPv4" output="No" returntype="any" access="public"
	displayname="formats a IPv4 address string"
	hint="formats a dotted quad address string, 
				returns requested format in .data or a structure set including:
				padded string [padded], padded string with no dots [paddedNoDots], integer[integer]"
				>
	<!--- this function needs.... --->
	<cfargument name="IPaddress" type="string" default="" />	<!--- the IP address --->
	<cfargument name="Format" type="string" required="false" default="" hint="padded|paddedNoDots|integer|all - blank or missing defaults to 'all'" />	<!--- the requested format --->

	<!--- now all of the var declarations, first the arguments which need manipulation --->
	<cfset var theIPAddress = trim(arguments.IPaddress) />
	<cfset var theFormat = trim(arguments.Format) />
	<!--- now vars that will get filled as we go --->
	<cfset var lcntr = 0 />	<!--- temp loop counter --->
	<cfset var InputQuads = ArrayNew(1) />	<!--- temp/throwaway var --->
	<cfset var temp = "" />	<!--- temp/throwaway var --->
	<cfset var doPadded = False />	<!--- do we do this format --->
	<cfset var doPaddedNoDots = False />	<!--- do we do this format --->
	<cfset var doInteger = False />	<!--- do we do this format --->
	<cfset var retTempall = StructNew() />
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorText = "TheFunctionName()<br>" />
	<cfset ret.Data = "" />

	<!--- validate the incoming stuff --->
	<cfif theFormat eq "">
		<cfset theFormat = "all" />
	</cfif>
	<cfif listLen(theIPAddress, ".") neq 3>	<!--- make sure we have 3 dots, ie a dotted quad of some form --->
		<!--- wrap the whole thing in a try/catch in case something breaks despite the checking above --->
		<cftry>
			<!--- split into its 4 items and check each for value range --->
			<cfset InputQuads = ListToArray(theIPAddress, ".") />
			<cfloop from="1" to="4" index="lcntr">
				<cfif (not IsNumeric(InputQuads[lcntr])) or InputQuads[lcntr] lt 0 or InputQuads[lcntr] gt 255>
					<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, lcntr) />
					<cfset ret.error.ErrorText = ret.error.ErrorText & 'Block #lcntr# of the IP address is not a valid value between 0 &amp; 255, the value was: #InputQuads[lcntr]#<br>' />
				</cfif>
			</cfloop>
			
			<cfif ret.error.ErrorCode eq 0>
				<!--- we have a good input IP address so format it as required --->
				<cfif theFormat eq "padded" or theFormat eq "all">	<!--- make a full padded dotted quad --->
					<cfset doPadded = True />
				</cfif>
				<cfif theFormat eq "paddedNoDots" or theFormat eq "all">	<!--- make a full padded dotless quad, just a string of numbers --->
					<cfset doPaddedNoDots = True />
				</cfif>
				<cfif theFormat eq "integer" or theFormat eq "all">	<!--- make a dirt great big integer, 2^32 --->
					<cfset doInteger = True />
				</cfif>
				<cfif not (doPadded or doPaddedNoDots or doInteger)>
					<!--- oops! invalid format argument --->
					<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 8) />
					<cfset ret.error.ErrorText = ret.error.ErrorText & 'Invalid format argument suppied, the value was: #theFormat#<br>' />
				</cfif>
				
				<cfif ret.error.ErrorCode eq 0>
					<cfif doPadded>	<!--- make a full padded dotted quad --->
						<cfset temp = "" />
						<cfloop from="1" to="4" index="lcntr">
							<cfset temp = ListAppend(temp, NumberFormat(InputQuads[lcntr], "000"), ".") />
						</cfloop>
						<cfset ret.Data = temp />
						<cfset retTempall.padded = temp />
					</cfif>
					<cfif doPaddedNoDots>
						<cfset temp = "" />
						<cfloop from="1" to="4" index="lcntr">
							<cfset temp = temp & NumberFormat(InputQuads[lcntr], "000") />
						</cfloop>
						<cfset ret.Data = temp />
						<cfset retTempall.paddedNoDots = temp />
					</cfif>
					<cfif doInteger>
						<!--- remember its backwards, first quad is biggest --->
						<cfset temp = InputQuads[4] />
						<cfloop from="1" to="3" index="lcntr">
							<cfset temp = temp + InputQuads[lcntr]*(2^((4-lcntr)*8)) />
						</cfloop>
						<cfset ret.Data = temp />
						<cfset retTempall.integer = temp />
					</cfif>
					<cfif theFormat eq "all">
						<!--- we asked for "all" so copy the lot's structure into the return data structure overwriting the unique simple value ones --->
						<cfset ret.Data = retTempall />
						<cfset ret.Data.original = theIPAddress />	<!--- give them back the original as well to make a complete set --->
					</cfif>
				</cfif>
			</cfif>
			<cfcatch type="any">
				<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 128) />
				<cfset ret.error.ErrorText = ret.error.ErrorText & 'Oops! Error Caught, error message was: #cfcatch.message#, error detail was: #cfcatch.detail#<br>' />
				<cfset ret.error.ErrorExtra =  cfcatch.TagContext />
				<cflog text="emptyFunction() Trapped. ret.error.ErrorCode: #ret.error.ErrorCode# - Error Text: #ret.error.ErrorText# - Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#"  file="UtilitiesErrors" type="Error" application = "yes">
				<cfif application.SLCMS.Config.debug.debugmode>
					setNextID() trapped - error was:<br>
					<cfdump var="#ret.error.ErrorExtra#">
				</cfif>
			</cfcatch>
		</cftry>
	<cfelse>
		<!--- oops no meaningful parameters so return nothing --->
		<cfset ret.error.ErrorCode = 64 />
		<cfset ret.error.ErrorText = "Invalid parameters: - IP Address was not dotted quad" />
	</cfif> <!--- end: incoming parameters validation check --->

	<cfreturn ret  />
</cffunction>

<cffunction name="tagStripper" access="public" output="no" returntype="string" hint="removes or keeps HTML tags except specified tags">
    <cfargument name="source" required="YES" type="string">
    <cfargument name="action" required="No" type="string" default="strip" hint="Preserve|strip - what to do with tags not in exception tagList">
    <cfargument name="exceptionTagList" required="no" type="string" default="" hint="List of tags to treat differently, inner chars only, eg 'b,i'">
   
<!---
    source = string variable
        This is the string to be modified
       
    action = "preserve" or "strip"
        This function will either strip all tags except
        those specified in the exceptionTagList argument, or it will
        preserve all tags except those in the taglist argument.
        The default action is "strip"

    exceptionTagList = string variable
        This argument contains a comma separated list of tags to be excluded from
        the action.  If the action is "strip", then these tags won't be stripped.
        If the action os "preserve", then these tags won't be preserved (ie, only
        these tags will be stripped)
       
    EXAMPLE
   
    tagStripper(myString,"strip","b,i")
   
    This invocation will strip all html tags except for
    <b></b> and <i></i>
--->
    <cfscript>
    var str = arguments.source;
    var tag = "";
    var i = 1;
   
    if (trim(lcase(action)) eq "preserve")
    {
        // strip only the exclusions
        for (i=1;i lte listlen(arguments.exceptionTagList); i = i + 1)
        {
            tag = listGetAt(exceptionTagList,i);
            str = REReplaceNoCase(str,"</?#tag#.*?>","","ALL");
        }
    } else {
        // if there are exclusions, mark them with NOSTRIP
        if (exceptionTagList neq "")
        {
            for (i=1;i lte listlen(exceptionTagList); i = i + 1)
            {
                tag = listGetAt(exceptionTagList,i);
                str = REReplaceNoCase(str,"<(/?#tag#.*?)>","___TEMP___NOSTRIP___\1___TEMP___ENDNOSTRIP___","ALL");
            }
        }
        str = reReplaceNoCase(str,"</?[A-Z].*?>","","ALL");
        // convert excluded tags back to normal
        str = replace(str,"___TEMP___NOSTRIP___","<","ALL");
        str = replace(str,"___TEMP___ENDNOSTRIP___",">","ALL");
    }
   
    return str;   
    </cfscript>
</cffunction>

<cffunction name="Bits32ToInt" access="public" output="no" returntype="numeric" hint="converts (up to) 32bit pattern string  to integer">
    <cfargument name="BitPattern" type="string" default="">	<!--- a bit pointless not sending everything, a complicated way to get zero back --->
		<cfset var theBits = RJustify(trim(arguments.BitPattern), 32) />
		<cfset var theResult = 0 />
		<cfset theResult = inputBaseN(Replace(theBits, " ", "0", "all"), 2) />
		<cfreturn theResult>
</cffunction>

<cffunction name="IntTo32Bits" access="public" output="no" returntype="string" hint="converts integer to 32bit pattern string, returns zeros for non-numeric input">
    <cfargument name="Int2Convert" type="string" default="0">	<!--- a bit pointless not sending everything, a complicated way to get a big string of zeroes back :-) --->
		<cfset var theResult = "00000000000000000000000000000000" />
		<cfif IsNumeric(arguments.Int2Convert)>
			<cfset theResult = formatBaseN(arguments.Int2Convert, 2) />
			<cfset theResult = Replace(rjustify(theResult, 32)," ", "0", "all") />
		</cfif>
		<cfreturn theResult>
</cffunction>

<!--- some URL related items --->
<!--- parseUri CF v0.2, by Steven Levithan: http://stevenlevithan.com --->
<cffunction name="parseUri" returntype="struct" output="false" hint="Splits any well-formed URI into its components">
	<cfargument name="sourceUri" type="string" required="no" />
	
	<!--- Create an array containing the names of each key we will add to the uri struct --->
	<cfset var uriPartNames = listToArray("source,protocol,authority,userInfo,user,password,host,port,relative,path,directory,file,query,anchor") />
	<!--- Get arrays named len and pos, containing the lengths and positions of each URI part (all are optional) --->
	<cfset var uriParts = reFind("^(?:(?![^:@]+:[^:@/]*@)([^:/?##.]+):)?(?://)?((?:(([^:@]*):?([^:@]*))?@)?([^:/?##]*)(?::(\d*))?)(((/(?:[^?##](?![^?##/]*\.[^?##/.]+(?:[?##]|$)))*/?)?([^?##/]*))(?:\?([^##]*))?(?:##(.*))?)",
		sourceUri, 1, TRUE) />
	<cfset var uri = structNew() />
	<cfset var i = 1 />
	
	<!--- Add the following keys to the uri struct:
	- source (the full, original URI)
	- protocol (scheme)
	- authority (includes the userInfo, host, and port parts)
		- userInfo (includes the user and password parts)
			- user
			- password
		- host (can be an IP address)
		- port
	- relative (includes the path, query, and anchor parts)
		- path (includes both the directory path and filename)
			- directory (supports directories with periods, and without a trailing backslash)
			- file
		- query (does not include the leading question mark)
		- anchor (fragment)
	--->
	<cfloop index="i" from="1" to="14">
		<!--- If the part was found in the source URI...
		- The arrayLen() check is needed to prevent a CF error when sourceUri is empty, because due to an apparent bug,
		  reFind() does not populate backreferences for zero-length capturing groups when run against an empty string
		  (though it does still populate backreference 0).
		- The pos[i] value check is needed to prevent a CF error when mid() is passed a start value of 0, because of
		  the way reFind() considers an optional capturing group that does not match anything to have a pos of 0. --->
		<cfif (arraylen(Variables.uriParts.pos) GT 1) AND (uriParts.pos[i] GT 0)>
			<!--- Add the part to its corresponding key in the uri struct --->
			<cfset uri[uriPartNames[i]] = mid(sourceUri, uriParts.pos[i], uriParts.len[i]) />
		<!--- Otherwise, set the key value to an empty string --->
		<cfelse>
			<cfset uri[uriPartNames[i]] = "" />
		</cfif>
	</cfloop>
	
	<!--- Always end directory with a trailing backslash if a path was present in the source URI.
	Note that a trailing backslash is NOT automatically inserted within or appended to the relative or path parts --->
	<cfif len(uri.directory) GT 0>
		<cfset uri.directory = reReplace(uri.directory, "/?$", "/") />
	</cfif>
	
	<cfreturn uri />
</cffunction>

<cffunction name="LegaliseFolderName_Web" access="public" output="No" returntype="string" hint="cleans up supplied string so it has no illegal chars for a file name in a URL">
	<cfargument name="source" required="YES" type="string">
	<cfargument name="LoseCommas" type="boolean" default="False">
	<cfset var theReturnString = LegaliseFolderName_OS(arguments.source) />
	<cfset theReturnString = ReplaceNoCase(theReturnString, " ", "_", "all") />
	<cfset theReturnString = ReplaceNoCase(theReturnString, "'", "", "all") />
	<cfif arguments.LoseCommas>
		<cfset theReturnString = ReplaceNoCase(theReturnString, ",", "_", "all") />
	</cfif>
	<cfreturn theReturnString />
</cffunction>

<cffunction name="LegaliseFolderName_OS" access="public" output="No" returntype="string" hint="cleans up supplied string so it has no illegal chars for a file or folder name over all OSes">
    <cfargument name="source" required="YES" type="string">
		<cfset var theSourceString = arguments.source />
		<cfset var theReturnString = "" />
		<cfif IsValidFolderName(theSourceString)>
			<cfset theReturnString = theSourceString />
		<cfelse>
			<cfset theReturnString = ReplaceNoCase(theSourceString, "##", "", "all") />
			<cfset theReturnString = ReplaceNoCase(theReturnString, "@", "", "all") />
			<cfset theReturnString = ReplaceNoCase(theReturnString, ":", "", "all") />
			<cfset theReturnString = ReplaceNoCase(theReturnString, "?", "", "all") />
			<cfset theReturnString = ReplaceNoCase(theReturnString, "*", "", "all") />
			<cfset theReturnString = ReplaceNoCase(theReturnString, "|", "", "all") />
			<cfset theReturnString = ReplaceNoCase(theReturnString, "<", "", "all") />
			<cfset theReturnString = ReplaceNoCase(theReturnString, ">", "", "all") />
			<cfset theReturnString = ReplaceNoCase(theReturnString, '"', "", "all") />
			<cfset theReturnString = ReplaceNoCase(theReturnString, "/", "", "all") />
			<cfset theReturnString = ReplaceNoCase(theReturnString, "\", "", "all") />
		</cfif>
	<cfreturn theReturnString />
</cffunction>

<cffunction name="IsValidFolderName" access="public" output="No" returntype="boolean" hint="Checks supplied string to see if it is viable file or folder name, returns true/false">
	<cfargument name="source" required="YES" type="string">
	<cfset var theString = arguments.source />
	<cfset var theBadNames = "com1,com2,com3,com4,com5,com6,com7,com8,com9,lpt1,lpt2,lpt3,lpt4,lpt5,lpt6,lpt7,lpt8,lpt9,con,nul,prn" />	<!--- mainly the ports in Windows and things like that --->
	<!--- then the return var, not a structure as our standard architecture --->
	<cfset var ret = True />	<!--- this is the return to the caller, False is a bad value --->
	<!--- we have to do two things, look for incompatible chars across the OSes and look for reserved names --->
	<cfif len(theString)>
		<cfif FindNoCase("##", theString) or FindNoCase("@", theString) or FindNoCase(":", theString) 
					or FindNoCase("?", theString) or FindNoCase("*", theString) or FindNoCase("|", theString) 
					or FindNoCase("<", theString) or FindNoCase(">", theString) or FindNoCase('"', theString)
					or FindNoCase("\", theString) or FindNoCase("/", theString)>
			<cfset ret = False />
	  <cfelseif ListFindNoCase(theBadNames, theString)>
			<cfset ret = False />
		</cfif>
	<cfelse>
		<cfset ret = False />
  </cfif>
	<cfreturn ret  />
</cffunction>

<cffunction name="IsValidDomainName" access="public" output="No" returntype="boolean" hint="Checks supplied string to see if it is viable domain name, returns true/false">
    <cfargument name="source" required="YES" type="string">

	<!--- all of the var declarations, first the arguments which need manipulation --->
	<cfset var theString = arguments.source />
	<!--- now vars that will get filled as we go --->
	<cfset var temp = "" />	<!--- temp/throwaway var --->
	<!--- then the return var, not a structure as our standard architecture --->
	<cfset var ret = True />	<!--- this is the return to the caller, False is a bad value --->

	<cfif len(theString)>
	<cfelse>
		<cfset ret = False />
  </cfif>
	<cfreturn ret  />
</cffunction>

<cffunction name="IsValidEddress" access="public" output="no" returntype="boolean" hint="Checks supplied string to see if it is valid email address, returns true/false">
    <cfargument name="source" required="YES" type="string">
   
<!---
    source = string variable
        This is the string to be checked
       
    EXAMPLE
   
    IsValidEddress("sales@mbcomms.net.au")
   
    This invocation will return true
--->

	<!--- all of the var declarations, first the arguments which need manipulation --->
	<cfset var theString = arguments.source />
	<cfset var theShortString = trim(arguments.source) />
	<!--- now vars that will get filled as we go --->
	<cfset var temp = "" />	<!--- temp/throwaway var --->
	<!--- then the return var, not a structure as with our standard architecture --->
	<cfset var ret = True />	<!--- this is the return to the caller, False is a bad value --->

	<cfif len(theString)>
		<cfif ListLen(theString, "@") eq 2>	
			<!--- we have a standard eddress shape so check the name side for minor things that can go wrong --->
			<cfset temp = ListFirst(theString, "@") />
			<cfif Find(" ", temp)>
				<cfset ret = False />
			</cfif>
			<!--- then check the domain side for all the things that can go wrong --->
			<cfset temp = ListLast(theString, "@") />
			<!--- check for one dot at least --->
			<!--- but not the first char ie "@."  --->
			<cfif ListLen(temp, ".") lt 2 or left(temp, 1) eq ".">
				<cfset ret = False />
			<cfelse>
				<!--- check no doubled dots --->
				<cfif Find("..", temp)>
					<cfset ret = False />
				<cfelse>
					<!--- check no comma'd dots --->
					<cfif Find(",", temp)>
						<cfset ret = False />
					<!--- and no spaces --->
					<cfelseif Find(" ", temp)>
						<cfset ret = False />
					<cfelse>
						<!--- no funny chars so now check that its not too long to be a FQDN and the local part is correct as well --->
						<cfif len(temp) gt 255 or len(ListFirst(theString, "@")) gt 64>
							<cfset ret = False />
						<cfelse>
							<!--- looking good so do the big regex that looks at the entire string --->
							<cfif REFindNoCase("^['_a-z0-9-]+(\.['_a-z0-9-]+)*@[a-z0-9-]+(\.[a-z0-9-]+)*\.(([a-z]{2,3})|(aero|asia|biz|cat|coop|info|museum|name|jobs|post|pro|tel|travel|mobi))$", theString)>
								<!--- its a valid shape --->
								<!--- ToDo: add in the big structure lookup of legit second levels --->
							<cfelse>
								<cfset ret = False />
							</cfif>	<!--- end: regex --->
						</cfif>	<!--- end: length tests --->
					</cfif>	<!--- end: comma test --->
				</cfif>	<!--- end: double dot test --->
			</cfif>	<!--- end: at least one dot --->
		<!--- 
		<cfelseif ListLen(theString, "@") gt 2>	
			<!--- we have a eddress shape that could be one with a username pass on the front or a proxy eddress --->
		 --->
		<cfelse>
			<!--- bad format --->
			<cfset ret = False />
		</cfif>
	<cfelse>
		<cfset ret = False />
  </cfif>
	<cfreturn ret  />
</cffunction>

<!--- now the filename en/decode functions --->
<cffunction name="SafeStringEnCode" output="No" returntype="string" access="public"
	displayname="Safe String EnCode"
	hint="takes a string and encodes any chars that are illegal for file names or XML"
				>
	<!--- this function needs.... --->
	<cfargument name="Input" type="string" default="" />	<!--- the name of the database --->

	<cfset var temp = arguments.Input />	<!--- return var --->
	<!--- just do them one at a time, crude but fastest --->
	<cfset temp = replace(temp, "*", "^~01~^", "all") />	
	<cfset temp = replace(temp, "?", "^~02~^", "all") />
	<cfset temp = replace(temp, "[", "^~03~^", "all") />	
	<cfset temp = replace(temp, "]", "^~04~^", "all") />
	<cfset temp = replace(temp, "/", "^~05~^", "all") />	
	<cfset temp = replace(temp, "\", "^~06~^", "all") />
	<cfset temp = replace(temp, "=", "^~07~^", "all") />	
	<cfset temp = replace(temp, "+", "^~08~^", "all") />
	<cfset temp = replace(temp, "<", "^~09~^", "all") />	
	<cfset temp = replace(temp, ">", "^~10~^", "all") />
	<cfset temp = replace(temp, ">", "^~11~^", "all") />
	<cfset temp = replace(temp, ":", "^~12~^", "all") />
	<cfset temp = replace(temp, ";", "^~13~^", "all") />
	<cfset temp = replace(temp, '"', "^~14~^", "all") />
	<cfset temp = replace(temp, ",", "^~15~^", "all") />
	<cfset temp = replace(temp, "'", "^~16~^", "all") />
	<cfset temp = replace(temp, "&", "^~17~^", "all") />
	<cfset temp = replace(temp, " ", "^~18~^", "all") />

	<cfreturn temp  />
</cffunction>

<cffunction name="SafeStringDeCode" output="No" returntype="string" access="public"
	displayname="Safe String DeCode"
	hint="takes a string and decodes any encoded illegal chars that were for file names or XML"
				>
	<!--- this function needs.... --->
	<cfargument name="Input" type="string" default="" />	<!--- the name of the database --->

	<cfset var temp = arguments.Input />	<!--- return var --->
	<!--- just do them one at a time, crude but fastest --->
	<cfset temp = replace(temp, "^~01~^", "*", "all") />	
	<cfset temp = replace(temp, "^~02~^", "?", "all") />
	<cfset temp = replace(temp, "^~03~^", "[", "all") />	
	<cfset temp = replace(temp, "^~04~^", "]", "all") />
	<cfset temp = replace(temp, "^~05~^", "/", "all") />	
	<cfset temp = replace(temp, "^~06~^", "\", "all") />
	<cfset temp = replace(temp, "^~07~^", "=", "all") />	
	<cfset temp = replace(temp, "^~08~^", "+", "all") />
	<cfset temp = replace(temp, "^~09~^", "<", "all") />	
	<cfset temp = replace(temp, "^~10~^", ">", "all") />
	<cfset temp = replace(temp, "^~11~^", ">", "all") />
	<cfset temp = replace(temp, "^~12~^", ":", "all") />
	<cfset temp = replace(temp, "^~13~^", ";", "all") />
	<cfset temp = replace(temp, "^~14~^", '"', "all") />
	<cfset temp = replace(temp, "^~15~^", ",", "all") />
	<cfset temp = replace(temp, "^~16~^", "'", "all") />
	<cfset temp = replace(temp, "^~17~^", "&", "all") />
	<cfset temp = replace(temp, "^~18~^", " ", "all") />

	<cfreturn temp  />
</cffunction>

<cffunction name="emptyFunction" output="No" returntype="struct" access="public"
	displayname="Nothing"
	hint="this is just a shell to copy, 
				can be deleted once coding has finished, 
				and turn off output if we don't need it to save whitespace"
				>
	<!--- this function needs.... --->
	<cfargument name="DatabaseName" type="string" default="" />	<!--- the name of the database --->

	<!--- now all of the var declarations, first the arguments which need manipulation --->
	<cfset var theDataBaseName = XmlFormat(trim(arguments.DatabaseName)) />
	<!--- now vars that will get filled as we go --->
	<cfset var lcntr = 0 />	<!--- temp loop counter --->
	<cfset var temp = "" />	<!--- temp/throwaway var --->
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorText = "TheFunctionName()<br>" />
	<cfset ret.Data = "" />
	
	<!--- validate the incoming stuff --->
	<cfif 1 eq 0>
		<!--- wrap the whole thing in a try/catch in case something breaks despite all the checking above --->
		<cftry>
		<cfcatch type="any">
			<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 128) />
			<cfset ret.error.ErrorText = ret.error.ErrorText & 'Oops! Error Caught, error message was: #cfcatch.message#, error detail was: #cfcatch.detail#<br>' />
			<cfset ret.error.ErrorExtra =  cfcatch.TagContext />
			<cflog text="emptyFunction() Trapped. ret.error.ErrorCode: #ret.error.ErrorCode# - Error Text: #ret.error.ErrorText# - Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#"  file="UtilitiesErrors" type="Error" application = "yes">
			<cfif application.SLCMS.Config.debug.debugmode>
				setNextID() trapped - error was:<br>
				<cfdump var="#ret.error.ErrorExtra#">
			</cfif>
		</cfcatch>
		</cftry>
	<cfelse>
		<!--- oops no meaningful parameters so return nothing --->
		<cfset ret.error.ErrorCode = 1 />
		<cfset ret.error.ErrorText = "Invalid parameters: - DataBaseName - #theDataBaseName#; CounterName - #theCounterName#; TableName - #theTableName#" />
	</cfif> <!--- end: incoming parameters validation check --->

	<cfreturn ret  />
</cffunction>

</cfcomponent>