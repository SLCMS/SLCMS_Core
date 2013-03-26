<!--- RoundRobinDataStorage.cfc --->
<!---  --->
<!--- CFC containing functions that relate to round-robin data stores --->
<!--- Part of the mbcomms Standard Site Architecture toolkit --->
<!---  --->
<!--- copyright: mbcomms 2007 --->
<!---  --->
<!--- Created:  22nd May 2007 by Kym K --->
<!--- Modified: 22nd May 2007 - 29th May 2007 by Kym K - mbcomms, working on it --->
<!--- Modified: 30th May 2007 -  6th Jun 2007 by Kym K - mbcomms, changing the database structure to "counter-first" --->
<!--- Modified: 16th Jun 2007 - 17th Jun 2007 by Kym K - mbcomms, adding getters and setters --->
<!--- Modified: 21st Aug 2007 - 21st Aug 2007 by Kym K - mbcomms, added CreateStatsDatabase() to make a full stats db for test use --->
<!--- Modified:  8th Sep 2007 - 10th Sep 2007 by Kym K - mbcomms, changed clean database name functionality to a simple XMLformat() function and URLencoded filename so can't break for any name --->
<!--- Modified: 29th Sep 2007 - 29th Sep 2007 by Kym K - mbcomms, fixed bug in getTableSet() where rollover check took place after read not before --->
<!--- Modified:  4th Oct 2007 -  4th Oct 2007 by Kym K - mbcomms, BIG OOPS!!!! the time interval for default weekly was 20 mins not 30 as it should be, only got 5 days per week! --->
<!--- Modified:  5th Oct 2007 -  5th Oct 2007 by Kym K - mbcomms, changed delete function to rename file not delete, added custom field structure and status functions --->
<!--- Modified:  7th Oct 2007 -  8th Oct 2007 by Kym K - mbcomms, added try/catch error handling on all functions
																																		"		short init, just read dir to list and CheckNsetDatabase to load store --->
<!--- \/ major change: moved to mapped filenames rather than shortened so can be reversed to DB name. last revision above is 323 /\
			the store list for fast reference is now just the encoded names to allow for commas in names, weird but could happen
			the store names in structures, etc. is the original name for legibility, the encoded name is only used for files names and the store list --->
<!--- Modified: 12th Oct 2007 - 14th Oct 2007 by Kym K - mbcomms, added File Name Filter functions, changed all functions to match  --->
<!--- Modified: 15th Oct 2007 - 15th Oct 2007 by Kym K - mbcomms, changed getFullDatabaseStructure() validation to place CheckNset in better position --->
<!--- Modified: 16th Oct 2007 - 16th Oct 2007 by Kym K - mbcomms, improved init and CheckNset error handling top give more detail in logs --->
<!--- Modified: 17th Oct 2007 - 17th Oct 2007 by Kym K - mbcomms, changed locking on data array writing areas from detail gained from above
																																	it is very occasionally changing a slot array(2) to a timeobject  --->
<!--- Modified: 20th Oct 2007 - 20th Oct 2007 by Kym K - mbcomms, changed checkNsetEmptySlot to handle fact that empty slot has null for time and locked write if it was null
																																	added struct test in save for when just restarted and not all structs loaded --->
<!--- Modified: 23rd Oct 2007 - 23rd Oct 2007 by Kym K - mbcomms, still corrupting structs, added full named lock in AddToCounter() --->
<!--- Modified:  8th Nov 2007 -  8th Nov 2007 by Kym K - mbcomms, still corrupting structs, added array item rebuilder in CheckNsetCurrentSlot() --->
<!---  --->
<!--- Modified: 27th Jan 2008 -  3rd Feb 2008 by Kym K - mbcomms, adding SQL database datastores as a store mode alternative - Part one: incremental mode duplicated --->
<!--- Modified: 12th Feb 2008 - 19th Feb 2008 by Kym K - mbcomms, adding SQL database datastores as a store mode alternative - Part two: adding Block and Auto modes --->
<!--- Modified:  9th Mar 2008 - 12th Mar 2008 by Kym K - mbcomms, adding SQL database datastores as a store mode alternative - Part three: adding converter functions to copy a file store to a SQL one --->
<!--- Modified: 21st Mar 2008 - 21st Mar 2008 by Kym K - mbcomms, adding SQL database datastores as a store mode alternative - Part three: continued --->
<!--- modified:  9th Apr 2012 -  9th Apr 2012 by Kym K, mbcomms: V3.0, CFWheels version. All SLCMS in own struct under app scope --->


<cfcomponent output="no"
	displayname="Round Robin Data Storage Tools"
	hint="set of tools to manage RRD data stores">

	<!--- set up a few persistant things on the way in. --->
	<cfset variables.DataStores = StructNew() />	<!--- this will persistently contain all of the stores as structures --->
<!--- 
	<cfset variables.DataStoreFullNameList = "" />	<!--- this will persistently contain a list of all of the stores' full names for external reference --->
 --->
	<cfset variables.DataStoreFileNameList = "" />	<!--- this will persistently contain a list of the actual store names --->
	<cfset variables.DataStoreCount = 0 />	<!--- a counter of how many stores there are --->
	<cfset variables.Global = StructNew() />
	<cfset variables.Global.DataStoreMode = "File" />	<!--- this is whether to use local files, SQL DB or both in a mixed mode --->
	<cfset variables.Global.DataStorePath = "" />	<!--- this is the path to all of the stores as files or the DSN --->
	<cfset variables.Global.DataSaveMode = "Incremental" />	<!--- defaults to the old way for legacy environments --->
	<cfset variables.Global.SystemStatus = "StartingUp" />
	<cfset variables.Global.SystemOKtoUse = False />
	<cfset variables.Global.Version = "1.0.1.353" />
	<cfset variables.Global.VersionText = "1.0.1 - original code" />
	<cfset variables.Global.VersionRequisites = "none" />
	<cfset variables.Debug = StructNew() />	<!--- used in debugging, etc --->
	<cfset variables.Debug.TestDefaults = "" />	<!--- this will persistently hold a debug parameter --->

<!--- initialise the various thingies, this should only be called after an app scope refresh or similar --->
<cffunction name="init" access="public" output="yes" returntype="struct" 
	description="The Initializer"
	hint="takes path to where the RRD databases live sets up the internal structures for this component">

	<cfargument name="DataStorePath" type="string" default="" hint="full physical path to where the RRD databases live" />	<!--- path to the db directory --->
	<cfargument name="DataSource" type="string" default="" hint="DataSource name" />	<!--- path to the db directory --->
	<cfargument name="DataStoreMode" type="string" default="File" hint="type of datastorage, local files, SQL DB or both in a mixed mode" />	<!--- path to the db directory --->
	<cfargument name="GlobalSaveMode" type="string" default="Auto" hint="method of count storing and saving: Auto, Block or Incremental. If Auto (means it wants to be told) and no argument supplied for a store then defaults to Incremental" />
	<cfargument name="TestDefaults" type="string" default="Yes" hint="flag to load small counter tables not default sizes" />
	<cfargument name="NoFileRead" type="string" default="No" hint="flag to force no file reading" />

	<!--- now all of the var declarations, 
			we have a bunch and some redundant as they all have to be first before we do code --->
	<cfset var qryStoresFiles = "" />	<!--- localize the directory query --->
	<cfset var theStoreFileName = "" />	<!--- the name of an individual file --->
	<cfset var qryGetTables = "" />	<!--- localize the query --->
	<cfset var getStores = "" />	<!--- localize the query --->
	<cfset var thisTableName = "" />	<!--- the name of an individual database table --->
	<cfset var MasterExists = False />	<!--- does the name main, global control table exist? --->
	<cfset var createMasterControlTable = "" />	<!--- localize the query --->
	<cfset var theStoreDBmode = trim(arguments.DataStoreMode) />	<!--- the mode of the databases, file or SQL db --->
	<cfset var theSaveMode = trim(arguments.GlobalSaveMode) />	<!--- the mode to save the counts, incrementally or as the time rolls over --->
	<cfset var theDBnameLen = 0 />	<!--- temp length of file/db name --->
	<cfset var thePacket = "" />	<!--- the read file packet --->
	<cfset var theStore = StructNew() />	<!--- the unpacking result --->
	<cfset var theStoreFullName = "" />	<!--- the unpacking result --->
	<cfset var goodDecodeflag = True />	<!--- local flag to say file read and decode was OK --->
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorText = "init():-<br>" />
	<cfset ret.Data = "" />

	<!--- now we have set up our locals set the CFC-wide variables --->
	<cfset variables.Debug.TestDefaults = trim(arguments.TestDefaults) />	<!--- this will persistently hold a debug parameter --->
	<cfset variables.Global.DataStorePath = trim(arguments.DataStorePath) />	<!--- this is the path to all of the stores as files --->
	<cfset variables.Global.DataSource = trim(arguments.DataSource) />	<!--- this is the DSN --->
	<cfset variables.Global.DataStoreMode = theStoreDBmode />	<!--- this is whether to use local files or SQL DB --->

	<!--- then check them and if OK grab the names of all of the databases we have --->
	<cfif variables.Global.DataStoreMode eq "File" and not DirectoryExists(variables.Global.DataStorePath)>
		<!--- Oops! we've been given a bad path --->
		<cfset variables.Global.SystemStatus = "Initialization Failed" />
		<cfthrow type="Custom" detail="DataStore Path Not Found!" message="Init(): The Datastore Path:- #variables.Global.DataStorePath# does not exist">
	<cfelseif variables.Global.DataStoreMode eq "SQL" and variables.Global.DataSource eq "">
		<!--- test for DB existing in proper version --->
		<cfset variables.Global.SystemStatus = "Initialization Failed" />
		<cfthrow type="Custom" detail="DataStore DSN Not Found!" message="Init(): The Datastore DSN:- #variables.Global.DataStorePath# does not exist">
	</cfif>	<!--- end: path valid OK to initialize --->

	<cfif ListFindNocase("Auto,Block,Incremental", theSaveMode) >
		<cfset variables.Global.DataSaveMode = theSaveMode />	<!--- set up the global default for the way we save --->
	<cfelse>
		<cfset variables.Global.SystemStatus = "Initialization Failed" />
		<cfthrow type="Custom" detail="Invalid DataStore Save Mode Supplied!" message="Init(): The Datastore Save Mode:- #theSaveMode# is not a valid mode, it should be Auto, Block or Incremental">
	</cfif>

	<!--- Paths there so wrap the whole thing in a try/catch in case something breaks and do it --->
	<cftry>
	<cfif variables.Global.SystemStatus neq "Initializing">
		<!--- we are good to read the databases so remove all old data and read in data files --->
		<!--- but first lets do the lock and check again as this should not be hit twice in an app load but lets not take chances --->
		<cflock timeout="20" throwontimeout="No" name="DataStoreWork" type="EXCLUSIVE">
			<cfif variables.Global.SystemStatus neq "Initializing">
				<cfset variables.Global.SystemStatus = "Initializing" />
				<cfset variables.DataStores = StructNew() />
<!--- 
					<cfset variables.DataStoreFullNameList = "" />
 --->
				<cfset variables.DataStoreFileNameList = "" />
				<cfset variables.DataStoreCount = 0 />
				<!--- grab any datastores that exist here and load them in --->
				<cfif arguments.NoFileRead eq "No">
					<!--- processing according to the mode we are in --->	
					<cfif variables.Global.DataStoreMode eq "File">
						<cfdirectory action="list" directory="#variables.Global.DataStorePath#" name="qryStoresFiles" filter="*.RRDB">
						<cfloop query="qryStoresFiles">
							<cfif qryStoresFiles.Type neq "Dir">
								<cfset theStoreFileName = qryStoresFiles.name />
								<cfif right(theStoreFileName, 5) eq ".rrdb">
									<cfset theStoreFileName = left(theStoreFileName, len(theStoreFileName)-5) />
<!--- 									
									<cfset theStoreFullName = FileName_DeCode(theStoreFileName) />
									<cfset variables.DataStoreFullNameList = ListAppend(variables.DataStoreFullNameList, "#theStoreFullName#") />	
 --->
									<cfset variables.DataStoreFileNameList = ListAppend(variables.DataStoreFileNameList, "#theStoreFileName#") />	
									<cfset variables.DataStoreCount = variables.DataStoreCount+1 />
								<cfelse>
									<!--- oops!, how did this file get here, ignore... --->
								</cfif>
							</cfif>
						</cfloop>	<!--- end: loop over files in directory --->
					<cfelseif variables.Global.DataStoreMode eq "SQL" or variables.Global.DataStoreMode eq "Mixed">
						<!--- this is the initialization if we are using a SQL database --->
						<cfquery name="qryGetTables" datasource="#variables.Global.DataSource#">
							sp_tables @table_type="'TABLE'"
						</cfquery>
						<cfloop query="qryGetTables">
							<cfset thisTableName = qryGetTables.Table_Name />
							<cfif thisTableName eq "RRDB_MasterControl">	<!--- this is the global controller, we only need one of these --->
								<cfset MasterExists = True />
								<!--- we have a master table so read it and grab the databases listed --->
								<cfquery name="getStores" datasource="#variables.Global.DataSource#">
									Select 	StoreFullName 
										from	RRDB_MasterControl
								</cfquery>
								<cfset variables.DataStoreFileNameList = ValueList(getStores.StoreFullName) />
								<cfset variables.DataStoreCount = getStores.RecordCount />
							<!--- 
							<cfelseif left(thisTableName, 5) eq "RRDB_" and right(thisTableName, 15) eq "_CounterControl">	<!--- only grab our tables, not anything else there! --->
								<!--- format is "RRDB_storename_counters" or "RRDB_storename_control" --->
								<cfset theDBnameLen = Len(thisTableName) />
								<cfif theDBnameLen gt 20>	<!--- check that the name is long enough --->
									<cfset thisTableName = Mid(thisTableName, 6, theDBnameLen-20) />
									<cfset variables.DataStoreFileNameList = ListAppend(variables.DataStoreFileNameList, "#thisTableName#") />	
									<cfset variables.DataStoreCount = variables.DataStoreCount+1 />
								</cfif>
							 --->
							</cfif>
						</cfloop>	<!--- end: loop over tables in database --->
						<!--- if we don't have a master table make it --->
						<cfif not MasterExists>
							<cfquery name="createMasterControlTable" datasource="#variables.Global.DataSource#">
								CREATE TABLE [dbo].[RRDB_MasterControl] (
									[RepID]  uniqueidentifier ROWGUIDCOL  NOT NULL ,
									[CounterNameList] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
									[CounterCount] [int] NULL ,
									[RefreshRate] [int] NULL ,
									[StoreFullName] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
									[AddMethod] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL, 
									[DataStoreMode] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
									[StoreStatus] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
									[StoreOKtoUse] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
								) ON [PRIMARY]
								
								ALTER TABLE [dbo].[RRDB_MasterControl] WITH NOCHECK ADD 
									CONSTRAINT [PK_RRDB_MasterControl] PRIMARY KEY  CLUSTERED 
									(
										[RepID]
									)  ON [PRIMARY] 
								
								ALTER TABLE [dbo].[RRDB_MasterControl] WITH NOCHECK ADD 
									CONSTRAINT [DF_RRDB_MasterControl_RepID] DEFAULT (newid()) FOR [RepID]
							</cfquery>
						</cfif>
						<!--- and if we are in mixed mode add any existing file stores in that are not there already --->
						<cfif variables.Global.DataStoreMode eq "Mixed">
							<cfdirectory action="list" directory="#variables.Global.DataStorePath#" name="qryStoresFiles" filter="*.RRDB">
							<cfloop query="qryStoresFiles">
								<cfif qryStoresFiles.Type neq "Dir">
									<cfset theStoreFileName = qryStoresFiles.name />
									<cfif right(theStoreFileName, 5) eq ".rrdb">
										<cfset theStoreFileName = left(theStoreFileName, len(theStoreFileName)-5) />
										<cfif not ListFindNoCase(variables.DataStoreFileNameList, theStoreFileName)>
											<!--- if its not in there already add it in, this allows for a a partial set in the DB compared to the fileset --->
											<cfset variables.DataStoreFileNameList = ListAppend(variables.DataStoreFileNameList, "#theStoreFileName#") />	
											<cfset variables.DataStoreCount = variables.DataStoreCount+1 />
											<!--- we have added to our variable now get the master control data into the SQL DB --->
											<cfset GoodDecodeFlag = True />
											<cftry>
												<cffile action="read" file="#variables.Global.DataStorePath##theStoreFileName#.rrdb" variable="thePacket" />
												<cfwddx action="WDDX2CFML" output="theStore" input="#thePacket#" />
											<cfcatch type="Any">
												<!--- poo it broke so don't save anything --->
												<cfset GoodDecodeFlag = False />
													<cfset ret.error.ErrorCode = BitOr(ret.error.ErrorCode, 4) />
													<cfset ret.error.ErrorText = ret.error.ErrorText & "#theFullDatabaseName# has a bad data structure" />
													<cfset ret.error.ErrorExtra1 =  cfcatch.TagContext />
													<cflog text="ChecknSetDatabase() DB file read/decode Trapped. ret.error.ErrorCode: #ret.error.ErrorCode# - Error Text: #ret.error.ErrorText# - Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#"  file="RRDBerrors" type="Error" application = "yes">
													<cfif application.SLCMS.Config.debug.debugmode>
														<cfdump var="#ret.error.ErrorExtra1#">
													</cfif>
											</cfcatch>
											</cftry>
											<cfif GoodDecodeFlag>
												<cftry>
													<cfquery name="setStore" datasource="#variables.Global.DataSource#">
														Insert Into RRDB_MasterControl
																			(StoreFullName, CounternameList, CounterCount, 
																				RefreshRate, AddMethod, DataStoreMode, StoreStatus, StoreOKtoUse)
															Values	('#theStore.control.StoreFullName#', '#theStore.control.CounternameList#', #theStore.control.CounterCount#, 
																				#theStore.control.RefreshRate#, 'Incremental', 'File', 'Running', 'Yes')
													</cfquery>
												<cfcatch type="any">
													<cfset ret.error.ErrorCode = BitOr(ret.error.ErrorCode, 2) />
													<cfset ret.error.ErrorText = ret.error.ErrorText & "#theFullDatabaseName# has a bad data structure" />
													<cfset ret.error.ErrorExtra2 =  cfcatch.TagContext />
													<cflog text="Init() file structure into Master DB Trapped. ret.error.ErrorCode: #ret.error.ErrorCode# - Error Text: #ret.error.ErrorText# - Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#"  file="RRDBerrors" type="Error" application = "yes">
													<cfif application.SLCMS.Config.debug.debugmode>
														<cfdump var="#ret.error.ErrorExtra2#">
													</cfif>
												</cfcatch>
												</cftry>
											<cfelse>
												<cfset ret.error.ErrorCode = BitOr(ret.error.ErrorCode, 4) />
												<cfset ret.error.ErrorText = ret.error.ErrorText & "Failed to decode: #theStorename#" />
											</cfif>
										</cfif>	<!--- end: do it as not in existing store list --->
									<cfelse>
										<!--- oops!, how did this file get here, ignore... --->
									</cfif>	<!--- end: its a datastore file --->
								</cfif>	<!--- end: its a file not a directory --->
							</cfloop>	<!--- end: loop over files in directory --->
						</cfif>
						<!--- 
						<cfdump var="#qryGetTables#">
						<cfabort>
						 --->
					<cfelse>
						<!--- oops! not a valid datastore mode --->
						<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 128) />
						<cfset ret.error.ErrorText = ret.error.ErrorText & 'Oops! Bad database mode supplied<br>' />
					</cfif>
				</cfif>	<!--- end: file read or not --->
				<cfif ret.error.ErrorCode eq 0>
					<cfset variables.Global.SystemStatus = "Running" />
					<cfset variables.Global.SystemOKtoUse = True />
				</cfif>
			</cfif>
		</cflock> <!--- end: lock round initialization --->
	</cfif>
	<cfcatch type="any">
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 128) />
		<cfset ret.error.ErrorText = ret.error.ErrorText & 'Oops! Error Caught, error message was: #cfcatch.message#, error detail was: #cfcatch.detail#<br>' />
		<cfset ret.error.ErrorExtra =  cfcatch.TagContext />
		<cflog text="Init() unhandled error Trapped. Error Text: #ret.error.ErrorText# - Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#"  file="RRDBerrors" type="Error" application = "yes">
		<cfif application.SLCMS.Config.debug.debugmode>
			Init() unhandled error Trapped - cfcatch dump is:<br>
			<cfdump var="#cfcatch#">
		</cfif>
	</cfcatch>
	</cftry>

	<cfreturn ret  />
</cffunction>

<cffunction name="Versioning" output="yes" returntype="struct" access="public"
	displayname="Version Control"
	hint="tweaks things to make sure we are always current"
				>
	<!--- this function needs.... --->
	<cfargument name="NewVersion" type="string" default="" />	<!--- the version this code is --->
	<cfargument name="OldVersion" type="string" default="" />	<!--- the version we have saved in db's or whatever --->

	<!--- now all of the var declarations, first the arguments which need manipulation --->
	<cfset var theNewVersion = trim(arguments.NewVersion) />
	<cfset var theOldVersion = trim(arguments.OldVersion) />
	<!--- now vars that will get filled as we go --->
	<cfset var lcntr = 0 />	<!--- temp loop counter --->
	<cfset var temp = "" />	<!--- temp/throwaway var --->
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorText = "" />
	<cfset ret.Data = "" />

	<cfif len(theNewVersion)>
		<!--- this is the good code --->
	<cfelse>	<!--- this is the error code --->
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 1) />
		<cfset ret.error.ErrorText = ret.error.ErrorText & "Oops! invalid new version supplied<br>" />
	</cfif>
	
	<cfreturn ret  />
</cffunction>

<!--- this first set of functions relate to global stuff --->
<!--- this is called by any input function to see if a datastore is loaded and grab it if not --->
<cffunction name="ChecknSetDatabase" access="public" output="yes" returntype="struct" 
	description="Check and Get Database"
	hint="Checks to see if a datastore is loaded and grab it if not">

	<cfargument name="DatabaseName" type="string" default="" />	<!--- the full name of the database --->

	<!--- now all of the var declarations --->
	<cfset var theFullDatabaseName = trim(arguments.DatabaseName) />	<!--- get the database minus those dreaded fogotten spaces --->
	<cfset var theDatabaseFileName = FileName_EnCode(theFullDatabaseName) />	<!--- this will be the name of the database file --->
	<cfset var thisDataStoreMode = "" />	<!--- the storage mode for this particular datastore --->
	<cfset var getStoreMode = "" />	<!--- query to get above --->
	<cfset var thePacket = "" />	<!--- the read file packet --->
	<cfset var theStore = StructNew() />	<!--- the unpacking result --->
	<cfset var goodDecodeflag = True />	<!--- local flag to say file read and decode was OK --->
	<cfset var lcntr = 0 />	<!--- temp loop counter --->
	<cfset var ocntr = 0 />	<!--- temp loop counter --->
	<cfset var thisCounter = "" />	<!--- temp/throwaway var --->
	<cfset var thisTable = "" />	<!--- temp/throwaway var --->
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorText = "ChecknSetDatabase():-<br>" />
	<cfset ret.Data = "" />

	<!--- wrap the whole thing in a try/catch in case something breaks --->
	<cftry>
	<!--- sort out what database name to use --->
	<cfif len(theFullDatabaseName)>
		<!--- we have a name so see if it exists as a store structure --->
		<cfif not StructKeyExists(variables.DataStores, "#theFullDatabaseName#")>
			<!--- no so lets do the lock and check again as this should not be hit twice in one go --->
			<cflock timeout="20" throwontimeout="No" name="DataStoreWork" type="EXCLUSIVE">
				<cfif not StructKeyExists(variables.DataStores, "#theFullDatabaseName#")>
					<!--- if we have got this far there is no store structure
								so see if it is in our store list read in during the init process
								if it is get it, otherwise flag back no such store --->
					<cfif ListFindNocase(variables.DataStoreFileNameList, theDatabaseFileName)>
						<!--- no data yet loaded but we know it is there in the datastorage so process according to storage mode --->
						<!--- first see what storage mode we are using for this individual store --->
						<cfif variables.Global.DataStoreMode eq "Mixed">
							<!--- mixed mode so grab the mode from our master table --->
							<cfquery name="getStoreMode" datasource="#variables.Global.DataSource#">
								Select 	DataStoreMode 
									from	RRDB_MasterControl
									where	StoreFullName = '#theDatabaseFileName#'
							</cfquery>
							<cfset thisDataStoreMode = getStoreMode.DataStoreMode />
						<cfelse>
							<!--- not mixed so use the global --->
							<cfset thisDataStoreMode = variables.Global.DataStoreMode />
						</cfif>
						<cfif thisDataStoreMode eq "File">
							<!--- it( wa)s there in the directory so grab the file  --->
							<cfif FileExists("#variables.Global.DataStorePath##theDatabaseFileName#.rrdb")>
								<cfset GoodDecodeFlag = True />
								<cftry>
									<cffile action="read" file="#variables.Global.DataStorePath##theDatabaseFileName#.rrdb" variable="thePacket" />
									<cfwddx action="WDDX2CFML" output="theStore" input="#thePacket#" />
								<cfcatch type="Any">
									<!--- poo it broke so don't save anything --->
									<cfset GoodDecodeFlag = False />
										<cfset ret.error.ErrorCode = BitOr(ret.error.ErrorCode, 4) />
										<cfset ret.error.ErrorText = ret.error.ErrorText & "#theFullDatabaseName# has a bad data structure" />
										<cfset ret.error.ErrorExtra1 =  cfcatch.TagContext />
										<cflog text="ChecknSetDatabase() DB file read/decode Trapped. ret.error.ErrorCode: #ret.error.ErrorCode# - Error Text: #ret.error.ErrorText# - Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#"  file="RRDBerrors" type="Error" application = "yes">
										<cfif application.SLCMS.Config.debug.debugmode>
											<cfdump var="#ret.error.ErrorExtra1#">
										</cfif>
								</cfcatch>
								</cftry>
								<cfif GoodDecodeFlag>
									<cftry>
										<cfset variables.DataStores["#theFullDatabaseName#"] = StructNew() />
										<cfset variables.DataStores["#theFullDatabaseName#"] = Duplicate(theStore) />
										<!--- look for legacy stores and add new keys in --->
										<cfif not StructKeyExists(variables.DataStores["#theFullDatabaseName#"].control, "DataSaveMode")>
											<cfset variables.DataStores["#theFullDatabaseName#"].control.DataSaveMode = "Incremental" />
										</cfif>
										<cfif not StructKeyExists(variables.DataStores["#theFullDatabaseName#"].control, "DataStoreMode")>
											<cfset variables.DataStores["#theFullDatabaseName#"].control.DataStoreMode = "File" />
										</cfif>
										<cfif not StructKeyExists(variables.DataStores["#theFullDatabaseName#"].control, "StoreStatus")>
											<cfset variables.DataStores["#theFullDatabaseName#"].control.StoreStatus = "Running" />
										</cfif>
										<cfif not StructKeyExists(variables.DataStores["#theFullDatabaseName#"].control, "StoreOKtoUse")>
											<cfset variables.DataStores["#theFullDatabaseName#"].control.StoreOKtoUse = "File" />
										</cfif>
									<cfcatch type="any">
										<cfset ret.error.ErrorCode = BitOr(ret.error.ErrorCode, 2) />
										<cfset ret.error.ErrorText = ret.error.ErrorText & "#theFullDatabaseName# has a bad data structure" />
										<cfset ret.error.ErrorExtra2 =  cfcatch.TagContext />
										<cflog text="ChecknSetDatabase() duplicate DB structure into Datastores Trapped. ret.error.ErrorCode: #ret.error.ErrorCode# - Error Text: #ret.error.ErrorText# - Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#"  file="RRDBerrors" type="Error" application = "yes">
										<cfif application.SLCMS.Config.debug.debugmode>
											<cfdump var="#ret.error.ErrorExtra2#">
										</cfif>
									</cfcatch>
									</cftry>
								<cfelse>
									<cfset ret.error.ErrorCode = BitOr(ret.error.ErrorCode, 4) />
									<cfset ret.error.ErrorText = ret.error.ErrorText & "Failed to decode: #theStorename#" />
								</cfif>
							</cfif>	<!--- end: file exists --->
						<cfelseif thisDataStoreMode eq "SQL">
							<!--- we need to read in the control data from the database so we know what is what --->
							<!--- first set up our base structure --->
							<cfset variables.DataStores["#theFullDatabaseName#"] = StructNew() />
							<cfquery name="getMaster" datasource="#variables.Global.DataSource#">
								Select  CounterCount, RefreshRate, CounternameList, AddMethod, DataStoreMode, StoreStatus, StoreOKtoUse
									From	RRDB_MasterControl
									Where	StoreFullName = '#theFullDatabaseName#'
							</cfquery>
							<cfset variables.DataStores["#theFullDatabaseName#"].counters = StructNew() />
							<cfset variables.DataStores["#theFullDatabaseName#"].control = StructNew() />
							<cfset variables.DataStores["#theFullDatabaseName#"].control.StoreFullName = theFullDatabaseName />	<!--- full name of this database, so we know what the outside world thinks it is --->
							<cfset variables.DataStores["#theFullDatabaseName#"].control.CounterCount = getMaster.CounterCount />	<!--- global counter count :^) --->
							<cfset variables.DataStores["#theFullDatabaseName#"].control.CounterNameList = getMaster.CounternameList />	<!--- list of counters --->
							<cfset variables.DataStores["#theFullDatabaseName#"].control.RefreshRate = getMaster.RefreshRate />	<!--- how often we refresh this database --->
							<cfset variables.DataStores["#theFullDatabaseName#"].control.DataSaveMode = getMaster.AddMethod />	<!--- what type of incementing we are doing --->
							<cfset variables.DataStores["#theFullDatabaseName#"].control.DataStoreMode = getMaster.DataStoreMode />	<!--- File or SQL database --->
							<cfset variables.DataStores["#theFullDatabaseName#"].control.StoreStatus = getMaster.StoreStatus />	<!--- running, stopped, etc --->
							<cfset variables.DataStores["#theFullDatabaseName#"].control.StoreOKtoUse = getMaster.StoreOKtoUse />	<!--- yes/No --->
							<!--- Then add the individual counters --->
							<cfloop from="1" to="#variables.DataStores["#theFullDatabaseName#"].control.CounterCount#" index="lcntr">
								<cfset thisCounter = ListgetAt(variables.DataStores["#theFullDatabaseName#"].control.CounterNameList, lcntr) />
								<cfset variables.DataStores["#theFullDatabaseName#"].counters["#thisCounter#"] = StructNew() />	<!--- base structure for the counter --->
								<cfset variables.DataStores["#theFullDatabaseName#"].counters["#thisCounter#"].control = StructNew() />	<!--- control structure for the counter --->
								<!--- get the individual counter's control data and insert into structure --->
								<cfquery name="getCounterControl" datasource="#variables.Global.DataSource#">
									Select  FillValueList, TableOrder, TableCount, TableNameList, TableIntervalList, TableSizeList
										From	[dbo].[RRDB_#theFullDatabaseName#_CounterControl]
										Where	Counter = '#thisCounter#'
								</cfquery>
								<cfset variables.DataStores["#theFullDatabaseName#"].counters["#thisCounter#"].control.FillValueList = getCounterControl.FillValueList />
								<cfset variables.DataStores["#theFullDatabaseName#"].counters["#thisCounter#"].control.TableOrder = getCounterControl.TableOrder />
								<cfset variables.DataStores["#theFullDatabaseName#"].counters["#thisCounter#"].control.TableCount = getCounterControl.TableCount />
								<cfset variables.DataStores["#theFullDatabaseName#"].counters["#thisCounter#"].control.TableNameList = getCounterControl.TableNameList />
								<cfset variables.DataStores["#theFullDatabaseName#"].counters["#thisCounter#"].control.TableIntervalList = getCounterControl.TableIntervalList />
								<cfset variables.DataStores["#theFullDatabaseName#"].counters["#thisCounter#"].control.TableSizeList = getCounterControl.TableSizeList />
								<!--- create the table ordered array as that is not in the db, bit tricky that one :-) --->
								<cfset variables.DataStores["#theFullDatabaseName#"].counters["#thisCounter#"].control.OrderedTableNames = ArrayNew(1) />
								<cfloop list="#variables.DataStores["#theFullDatabaseName#"].counters["#thisCounter#"].control.TableOrder#" index="ocntr">
									<cfset thisTable = ListGetAt(variables.DataStores["#theFullDatabaseName#"].counters["#thisCounter#"].control.TableNameList, ocntr) />
									<cfset variables.DataStores["#theFullDatabaseName#"].counters["#thisCounter#"].control.OrderedTableNames[ListGetAt(getCounterControl.TableOrder, ocntr)] = thisTable />
									<!--- and while we looping over the table drop in their control structures --->
									<cfset variables.DataStores["#theFullDatabaseName#"].counters["#thisCounter#"]["#thisTable#"] = StructNew() />	<!--- structure for the table --->
									<cfset variables.DataStores["#theFullDatabaseName#"].counters["#thisCounter#"]["#thisTable#"].control = StructNew() />	<!--- control structure for the table --->
									<cfquery name="getTableControl" datasource="#variables.Global.DataSource#">
										Select  CurrentSlot, TableSize, SlotInterval, FillValue, TableOrder
											From	[dbo].[RRDB_#theFullDatabaseName#_TableControl]
											Where	Counter = '#thisCounter#'
												and	DataSet = '#thisTable#'
									</cfquery>
									<cfset variables.DataStores["#theFullDatabaseName#"].counters["#thisCounter#"]["#thisTable#"].control.CurrentSlot = getTableControl.CurrentSlot />
									<cfset variables.DataStores["#theFullDatabaseName#"].counters["#thisCounter#"]["#thisTable#"].control.TableSize = getTableControl.TableSize />
									<cfset variables.DataStores["#theFullDatabaseName#"].counters["#thisCounter#"]["#thisTable#"].control.Interval = getTableControl.SlotInterval />
									<cfset variables.DataStores["#theFullDatabaseName#"].counters["#thisCounter#"]["#thisTable#"].control.FillValue = getTableControl.FillValue />
									<cfset variables.DataStores["#theFullDatabaseName#"].counters["#thisCounter#"]["#thisTable#"].control.TableOrder = getTableControl.TableOrder />
								</cfloop>	<!--- end: loop over tables --->
							</cfloop>	<!--- end: loop over counters --->
						</cfif>	<!--- end: what storage mode to use --->
					<cfelse>
						<!--- it wasn't in the list so it must be a new store --->
						<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 1) />
						<cfset ret.error.ErrorText = ret.error.ErrorText & "DataStore name not found<br>" />
					</cfif>	<!--- end: test to see if in store name list --->
				</cfif>	<!--- end: test to see if structure already exists --->
			</cflock> <!--- end: lock round initilization --->
		</cfif>	<!--- end: test to see if structure already exists --->
	<cfelse>	<!--- no database name --->
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 8) />
		<cfset ret.error.ErrorText = ret.error.ErrorText & "DataStore name not supplied<br>" />
	</cfif>
	<cfcatch type="any">
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 128) />
		<cfset ret.error.ErrorText = ret.error.ErrorText & 'Oops! Error Caught, error message was: #cfcatch.message#, error detail was: #cfcatch.detail#<br>' />
		<cfset ret.error.ErrorExtra =  cfcatch.TagContext />
		<cflog text="ChecknSetDatabase() unhandled error Trapped. ret.error.ErrorCode: #ret.error.ErrorCode# - Error Text: #ret.error.ErrorText# - Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#"  file="RRDBerrors" type="Error" application = "yes">
		<cfif application.SLCMS.Config.debug.debugmode>
			ChecknSetDatabase() unhandled error Trapped - error was:<br>
			<cfdump var="#ret.error.ErrorExtra#">
		</cfif>
	</cfcatch>
	</cftry>

	<cfreturn ret  />
</cffunction>

<cffunction name="FileName_EnCode" output="yes" returntype="string" access="private"
	displayname="EnCode FileName"
	hint="encodes string to filename-safe string, no error handling, try/catch returns a null string">

	<!--- this function needs.... --->
	<cfargument name="Input" type="string" default="" />	<!--- the string to encode --->

	<cfset var ret = "" />	<!--- this is the return to the caller --->
	
	<cftry>
		<cfset ret = application.mbc_utility.utilities.SafeStringEnCode("#arguments.Input#") />
	<cfcatch type="any">
		<cflog text="FileName_EnCode() Trapped. ret.error.ErrorCode: #ret.error.ErrorCode# - Error Text: #ret.error.ErrorText# - Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#"  file="RRDBerrors" type="Error" application = "yes">
		<cfif application.SLCMS.Config.debug.debugmode>
			<cfdump var="#cfcatch.TagContext#">
		</cfif>
	</cfcatch>
	</cftry>

	<cfreturn ret  />
</cffunction>

<cffunction name="FileName_DeCode" output="yes" returntype="string" access="private"
	displayname="DeCode FileName"
	hint="decodes string from filename-safe string to original, no error handling, try/catch returns a null string">

	<!--- this function needs.... --->
	<cfargument name="Input" type="string" default="" />	<!--- the string to encode --->

	<cfset var ret = "" />	<!--- this is the return to the caller --->
	
	<cftry>
		<cfset ret = application.mbc_utility.utilities.SafeStringDeCode("#arguments.Input#") />
	<cfcatch type="any">
		<cflog text="FileName_EnCode() Trapped. ret.error.ErrorCode: #ret.error.ErrorCode# - Error Text: #ret.error.ErrorText# - Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#"  file="RRDBerrors" type="Error" application = "yes">
		<cfif application.SLCMS.Config.debug.debugmode>
			<cfdump var="#cfcatch.TagContext#">
		</cfif>
	</cfcatch>
	</cftry>

	<cfreturn ret  />
</cffunction>

<cffunction name="getSystemStatus" output="yes" returntype="struct" access="public"
	displayname="get System Status"
	hint="returns System Status structure: SystemStatus-text; SystemOKtoUse-Boolean"
				>
	<!--- this function needs.... no arguments --->

	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorText = "" />
	<cfset ret.Data = StructNew() />
	<cfset ret.Data.SystemStatus = variables.Global.SystemStatus />
	<cfset ret.Data.SystemOKtoUse = variables.Global.SystemOKtoUse />

	<cfreturn ret  />
</cffunction>

<cffunction name="CreateBlankRRDB" output="yes" returntype="struct" access="public"
	displayname="RRDB Creator"
	hint="creates a RoundRobin Database with the supplied name, empty control structure there, nothing else">
	<!--- this function needs.... --->
	<cfargument name="DatabaseName" type="string" default="" />	<!--- the name of the database --->
	<cfargument name="AddMethod" type="string" default="Incremental" hint="Block or Incremental, whether to treat each addition as a complete datavalue or add incrementally to existing values" />	<!--- the way to treat "adds" --->
	<cfargument name="DataStoreMode" type="string" default="" hint="File or SQL, what sort of DB we are storing this dataset in" />	<!--- the way to treat "adds" --->
	<cfargument name="RefreshRate" type="string" default="4" hint="for Files: interval to write database to disk, in minutes - for SQL the local storage time before flush to DB" />	<!--- its refresh rate --->
	<cfargument name="CreationMode" type="string" default="New" hint="New|File2SQL : whether we are migrating an existing file DB or making a brand new DB" />	<!--- its refresh rate --->

	<cfset var theFullDatabaseName = trim(arguments.DatabaseName) />	<!--- get the database minus those dreaded fogotten spaces --->
	<cfset var theDatabaseFileName = FileName_EnCode(theFullDatabaseName) />	<!--- this will be the actual name of the database --->
	<cfset var theRefreshRate = trim(arguments.RefreshRate) />	<!--- the refresh rate --->
	<cfset var theAddMethod = trim(arguments.AddMethod) />	<!--- the Method of adding values to counters, block or incremetal --->
	<cfset var theDataStoreMode = trim(arguments.DataStoreMode) />	<!--- the Method of adding values to counters, block or incremetal --->
	<cfset var theCreationMode = trim(arguments.CreationMode) />	<!--- the Method of creation, if new add everything, if migrating then update master db not insert --->
	<cfset var theDatastructure = Structnew() />	<!--- temp struct for the creation --->
	<cfset var l = 0 />	<!--- temp loop counter --->
	<cfset var lcntr = 0 />	<!--- temp loop counter --->
	<cfset var temp = "" />	<!--- temp/throwaway var --->
	<cfset var createTablesTable = "" />	<!--- temp query --->
	<cfset var createTableControlTable = "" />	<!--- temp query --->
	<cfset var createCounterControlTable = "" />	<!--- temp query --->
	<cfset var setMaster = "" />	<!--- temp query --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorText = "CreateBlankRRDB():-<br>" />
	<cfset ret.Data = "" />

	<!--- validate and work out our names and things --->
	<cftry>
		<cfif not len(theFullDatabaseName)>
			<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 1) />
			<cfset ret.error.ErrorText = ret.error.ErrorText & "DataStore name not supplied or all invalid characters<br>" />
		</cfif>
		<cfif theCreationMode eq "New">
			<cfif ListFindNoCase(variables.DataStoreFileNameList, "#theDatabaseFileName#")>
				<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 2) />
				<cfset ret.error.ErrorText = ret.error.ErrorText & "A DataStore with the name of:- #theFullDatabaseName# already exists<br>" />
			</cfif>
		<cfelseif theCreationMode eq "File2SQL">
			<cfif not ListFindNoCase(variables.DataStoreFileNameList, "#theDatabaseFileName#")>
				<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 2) />
				<cfset ret.error.ErrorText = ret.error.ErrorText & "A DataStore with the name of:- #theFullDatabaseName# doesn't exist<br>" />
			</cfif>
		</cfif>
		<cfif theDataStoreMode eq "" and theCreationMode eq "New">
			<cfset theDataStoreMode = variables.Global.DataStoreMode />
		<cfelseif theDataStoreMode eq "" and theCreationMode eq "File2SQL">
			<cfset theDataStoreMode = "SQL" />
		<cfelseif not (theDataStoreMode eq "File" or theDataStoreMode eq "SQL")>
			<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 4) />
			<cfset ret.error.ErrorText = ret.error.ErrorText & "Invalid datastore mode supplied was given: #theDataStoreMode#<br>" />
		</cfif>
		<cfif ret.error.ErrorCode eq 0>
			<!--- all OK so do the work, do check/lock/check so we don't double up --->
			<cfif (StructKeyExists(variables.DataStores, "#theFullDatabaseName#") and theCreationMode eq "File2SQL") or (not StructKeyExists(variables.DataStores, "#theFullDatabaseName#") and theCreationMode eq "New")>
				<!--- lock it in case, with MX no issues with overwrite but code could possibly call it twice --->
				<cflock timeout="20" throwontimeout="No" name="DataStoreWork" type="EXCLUSIVE">
					<cfif (StructKeyExists(variables.DataStores, "#theFullDatabaseName#") and theCreationMode eq "File2SQL") or (not StructKeyExists(variables.DataStores, "#theFullDatabaseName#") and theCreationMode eq "New")>
						<cfif theCreationMode eq "New" and not StructKeyExists(variables.DataStores, "#theFullDatabaseName#")>
							<!--- now we have clean params so make the database structure --->
							<cfset variables.DataStores["#theFullDatabaseName#"] = StructNew() />
							<!--- it has a structure for the counters themselves and a control structure for the whole database --->
							<!--- set up the full data structure locally --->
							<cfset variables.DataStores["#theFullDatabaseName#"].counters = StructNew() />
							<cfset variables.DataStores["#theFullDatabaseName#"].custom = StructNew() />
							<cfset variables.DataStores["#theFullDatabaseName#"].control = StructNew() />
							<cfset variables.DataStores["#theFullDatabaseName#"].control.CounterCount = 0 />	<!--- global counter count :^) --->
							<cfset variables.DataStores["#theFullDatabaseName#"].control.CounterNameList = "" />	<!--- list of counters --->
							<cfset variables.DataStores["#theFullDatabaseName#"].control.StoreFullName = theFullDatabaseName />	<!--- full name of this database, so we know what the outside world thinks it is --->
							<cfset variables.DataStores["#theFullDatabaseName#"].control.RefreshRate = theRefreshRate />	<!--- how often we refresh this database --->
							<cfset variables.DataStores["#theFullDatabaseName#"].control.AddMethod = theAddMethod />	<!--- the add value mode, block or incremental --->
							<cfset variables.DataStores["#theFullDatabaseName#"].control.DataStoreMode = theDataStoreMode />	<!--- the database mode, file or SQL --->
							<cfset variables.DataStores["#theFullDatabaseName#"].control.StoreStatus = "Initializing" />	<!--- the store's running status --->
							<cfset variables.DataStores["#theFullDatabaseName#"].control.StoreOKtoUse = "No" />	<!--- the store's running status --->
							<cfset variables.DataStoreFileNameList = ListAppend(variables.DataStoreFileNameList, "#theDatabaseFileName#") />	
							<cfset variables.DataStoreCount = variables.DataStoreCount+1 />
						</cfif>
						<cfif theDataStoreMode eq "File">
							<!--- don't forget to save the bare structure to disk as a first off --->
							<cfset temp = SaveDatabaseFile(DatabaseName="#theFullDatabaseName#")/>
						<cfelseif theDataStoreMode eq "SQL">
							<!--- here we only need a temp store for the minimum interval ticks for this before adding to db
							<cfset variables.DataStores["#theFullDatabaseName#"].control.StoreFullName = "RRDB_#theFullDatabaseName#_Counters" />	<!--- full name of this database, so we know what the outside world thinks it is --->
							<cfset variables.DataStores["#theFullDatabaseName#"].control.StoreControlName = "RRDB_#theFullDatabaseName#_Control" />	<!--- full name of this database, so we know what the outside world thinks it is --->
							 --->
							<!--- and we need a database table set for this one --->
							<cfquery name="createTablesTable" datasource="#variables.Global.DataSource#">
								CREATE TABLE [dbo].[RRDB_#theFullDatabaseName#_Tables] (
									[RepID]  uniqueidentifier ROWGUIDCOL  NOT NULL ,
									[Slot] [int] NULL 
									<!--- 
									[Counter] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
									[DataSet] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
									[DataValue] [int] NOT NULL ,
									[DataTimeStamp] [datetime] NULL 
									 --->
								) ON [PRIMARY]
								
								ALTER TABLE [dbo].[RRDB_#theFullDatabaseName#_Tables] WITH NOCHECK ADD 
									CONSTRAINT [PK_RRDB_#theFullDatabaseName#_Tables] PRIMARY KEY  CLUSTERED 
									(
										[RepID]
									)  ON [PRIMARY] 
								
								ALTER TABLE [dbo].[RRDB_#theFullDatabaseName#_Tables] WITH NOCHECK ADD 
									CONSTRAINT [DF_RRDB_#theFullDatabaseName#_Tables_RepID] DEFAULT (newid()) FOR [RepID]
									<!--- 
									CONSTRAINT [DF_RRDB_#theFullDatabaseName#_Tables_Slot] DEFAULT (0) FOR [Slot],
									CONSTRAINT [DF_RRDB_#theFullDatabaseName#_Tables_DataValue] DEFAULT (0) FOR [DataValue]
								 CREATE  INDEX [IX_RRDB_#theFullDatabaseName#_Tables] ON [dbo].[RRDB_#theFullDatabaseName#_Tables]([Counter], [DataSet]) ON [PRIMARY]
								
								 CREATE  INDEX [IX_RRDB_#theFullDatabaseName#_Tables_1] ON [dbo].[RRDB_#theFullDatabaseName#_Tables]([Counter]) ON [PRIMARY]
									 --->
							</cfquery>
							<cfquery name="createTableControlTable" datasource="#variables.Global.DataSource#">
								CREATE TABLE [dbo].[RRDB_#theFullDatabaseName#_TableControl] (
									[RepID]  uniqueidentifier ROWGUIDCOL  NOT NULL ,
									[Counter] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
									[DataSet] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
									[CurrentSlot] [int] NULL ,
									[TableSize] [int] NULL ,
									[SlotInterval] [int] NULL ,
									[FillValue] [int] NULL ,
									[TableOrder] [int] NULL ,
									[ControlKey] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
									[ControlValue] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL 
								) ON [PRIMARY]
								
								ALTER TABLE [dbo].[RRDB_#theFullDatabaseName#_TableControl] WITH NOCHECK ADD 
									CONSTRAINT [PK_RRDB_#theFullDatabaseName#_TableControl] PRIMARY KEY  CLUSTERED 
									(
										[RepID]
									)  ON [PRIMARY] 
								
								ALTER TABLE [dbo].[RRDB_#theFullDatabaseName#_TableControl] WITH NOCHECK ADD 
									CONSTRAINT [DF_RRDB_#theFullDatabaseName#_TableControl_RepID] DEFAULT (newid()) FOR [RepID],
									CONSTRAINT [DF_RRDB_#theFullDatabaseName#_TableControl_FillValue] DEFAULT (0) FOR [FillValue]
								
								 CREATE  INDEX [IX_RRDB_#theFullDatabaseName#_TableControl] ON [dbo].[RRDB_#theFullDatabaseName#_TableControl]([Counter]) ON [PRIMARY]
								 CREATE  INDEX [IX_RRDB_#theFullDatabaseName#_TableControl_1] ON [dbo].[RRDB_#theFullDatabaseName#_TableControl]([Counter], [DataSet]) ON [PRIMARY]
								 CREATE  INDEX [IX_RRDB_#theFullDatabaseName#_TableControl_2] ON [dbo].[RRDB_#theFullDatabaseName#_TableControl]([DataSet]) ON [PRIMARY]
							</cfquery>
							<cfquery name="createCounterControlTable" datasource="#variables.Global.DataSource#">
								CREATE TABLE [dbo].[RRDB_#theFullDatabaseName#_CounterControl] (
									[RepID]  uniqueidentifier ROWGUIDCOL  NULL ,
									[Counter] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
									[FillValueList] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
									[TableOrder] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
									[TableCount] [int] NULL ,
									[TableIntervalList] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
									[TableNameList] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
									[TableSizeList] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL 
								) ON [PRIMARY]
								
								ALTER TABLE [dbo].[RRDB_#theFullDatabaseName#_CounterControl] WITH NOCHECK ADD 
									CONSTRAINT [DF_RRDB_#theFullDatabaseName#_CounterControl1_RepID] DEFAULT (newid()) FOR [RepID]
							</cfquery>
							<!--- now we have a set of database tables put the master data in --->
							<cfif theCreationMode eq "New">
								<cfquery name="setMaster" datasource="#variables.Global.DataSource#">
									Insert into RRDB_MasterControl
														(StoreFullName, CounterCount, RefreshRate, CounternameList, AddMethod, DataStoreMode, StoreStatus, StoreOKtoUse)
										Values	('#theFullDatabaseName#', 0, #theRefreshRate#, '', '#theAddMethod#', '#DataStoreMode#', 'Blank DB created', 'No')
								</cfquery>
							<cfelseif theCreationMode eq "File2SQL">
								<cfquery name="setMaster" datasource="#variables.Global.DataSource#">
									Update	RRDB_MasterControl
										set		DataStoreMode = 'SQL',
													StoreStatus = 'Blank DB created',
													StoreOKtoUse = 'No'
										where	StoreFullName = '#theFullDatabaseName#'
								</cfquery>
								<cfset variables.DataStores["#theFullDatabaseName#"].control.DataStoreMode = "SQL" />	<!--- the database mode, file or SQL --->
								<cfset variables.DataStores["#theFullDatabaseName#"].control.StoreStatus = "Blank DB created" />	<!--- the store's running status --->
								<cfset variables.DataStores["#theFullDatabaseName#"].control.StoreOKtoUse = "No" />	<!--- the store's running status --->
							</cfif>
						</cfif>	<!--- end: store mode file or SQL --->
					</cfif>	<!--- end: store exists test and lock --->
				</cflock>	<!--- end: store exists test and lock --->
			</cfif>	<!--- end: store exists test and lock --->
		</cfif>	<!--- end: parameters passed in are OK --->
	<cfcatch type="any">
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 128) />
		<cfset ret.error.ErrorText = ret.error.ErrorText & 'Oops! Error Caught, error message was: #cfcatch.message#, error detail was: #cfcatch.detail#<br>' />
		<cfset ret.error.ErrorExtra =  cfcatch.TagContext />
		<cflog text="CreateBlankRRDB() unhandled error Trapped. ret.error.ErrorCode: #ret.error.ErrorCode# - Error Text: #ret.error.ErrorText# - Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#"  file="RRDBerrors" type="Error" application = "yes">
		<cfif application.SLCMS.Config.debug.debugmode>
			CreateBlankRRDB() unhandled error Trapped - error dump:<br>
			<cfdump var="#ret.error.ErrorExtra#">
		</cfif>
	</cfcatch>
	</cftry>

	<cfreturn ret  />
</cffunction>

<cffunction name="AddEmptyCounter" output="yes" returntype="struct" access="public"
	displayname="Counter Creator"
	hint="creates an empty counter structure with no tables to the supplied counter and database names">
	<!--- this function needs.... --->
	<cfargument name="DatabaseName" type="string" default="" />	<!--- the name of the database --->
	<cfargument name="CounterName" type="string" default="" />	<!--- the name of the counter --->
	<cfargument name="CreationMode" type="string" default="New" hint="New|File2SQL : whether we are migrating an existing file DB or making a brand new DB" />	<!--- its refresh rate --->

	<cfset var theCounterName = trim(arguments.CounterName) />	
	<cfset var theFullDatabaseName = trim(arguments.DatabaseName) />	<!--- get the database minus those dreaded fogotten spaces --->
	<cfset var theDatabaseFileName = FileName_EnCode(theFullDatabaseName) />	<!--- this will be the actual name of the database --->
	<cfset var theCreationMode = trim(arguments.CreationMode) />	<!--- the Method of creation, if new add everything, if migrating then update master db not insert --->

	<cfset var temps = StructNew() />	<!--- temp structure --->
	<cfset var setCounterController = "" />	<!--- localise the query --->
	<cfset var setMasterController = "" />	<!--- localise the query --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorText = "AddEmptyCounter():-<br>" />
	<cfset ret.Data = "" />

	<!--- validate and work out our names and things --->
	<cftry>
		<cfif len(theFullDatabaseName)>
			<cfif ListFindNoCase(variables.DataStoreFileNameList, "#theDatabaseFileName#")>
				<!--- make sure we have a database structure --->
				<cfset temps = ChecknSetDatabase(DatabaseName="#theFullDatabaseName#") />
				<cfif temps.error.ErrorCode eq 0>
					<!--- it is there correctly so make sure this counter does not already exist --->
					<cfif theCreationMode eq "New">
						<cfif ListFindNoCase(variables.DataStores["#theFullDatabaseName#"].control.CounterNameList, "#theCounterName#")>
							<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 4) />
							<cfset ret.error.ErrorText = ret.error.ErrorText & "The Counter with the name of:- #theCounterName# already exists<br>" />
						</cfif>
					<cfelseif theCreationMode eq "File2SQL">
						<cfif not ListFindNoCase(variables.DataStores["#theFullDatabaseName#"].control.CounterNameList, "#theCounterName#")>
							<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 4) />
							<cfset ret.error.ErrorText = ret.error.ErrorText & "The Counter with the name of:- #theCounterName# doesn't exist in the master<br>" />
						</cfif>
					</cfif>
				<cfelseif temps.error.ErrorCode eq 1>
					<!--- flag for new DB, how come we got here, bad logic in caller --->
					<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 2) />
					<cfset ret.error.ErrorText = ret.error.ErrorText & "That DataStore with the name of:- #theFullDatabaseName# does not exist, must be a new name<br>" />
				<cfelse>
					<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 2) />
					<cfset ret.error.ErrorText = ret.error.ErrorText & "That DataStore with the name of:- #theFullDatabaseName# existed on disk but could not be read, error reported was: #temps.error.Errortext#<br>" />
				</cfif>
				<cfif ret.error.ErrorCode eq 0>
					<!--- all OK so do the work --->	
					<!--- wrap the whole thing in a try/catch in case something breaks --->
					<cftry>
						<!--- lock it in case, with MX no issues with overwrite but code could call it twice --->
						<cfif (theCreationMode eq "File2SQL" and StructKeyExists(variables.DataStores["#theFullDatabaseName#"].counters, "#theCounterName#")) or (theCreationMode eq "New" and not StructKeyExists(variables.DataStores["#theFullDatabaseName#"].counters, "#theCounterName#"))>
							<cflock timeout="20" throwontimeout="No" name="DataStoreWork_#theFullDatabaseName#" type="EXCLUSIVE">
								<cfif (theCreationMode eq "File2SQL" and StructKeyExists(variables.DataStores["#theFullDatabaseName#"].counters, "#theCounterName#")) or (theCreationMode eq "New" and not StructKeyExists(variables.DataStores["#theFullDatabaseName#"].counters, "#theCounterName#"))>
									<cfif theCreationMode eq "New" and not StructKeyExists(variables.DataStores["#theFullDatabaseName#"].counters, "#theCounterName#")>
										<!--- now we have clean params we can make the counter structure --->
										<cfset variables.DataStores["#theFullDatabaseName#"].counters["#theCounterName#"] = StructNew() />	<!--- make the base structure --->
										<cfset variables.DataStores["#theFullDatabaseName#"].counters["#theCounterName#"].control = StructNew() />	<!--- and the control structure --->
										<cfset variables.DataStores["#theFullDatabaseName#"].counters["#theCounterName#"].control.TableNameList = "" />	<!--- which is empty --->
										<cfset variables.DataStores["#theFullDatabaseName#"].counters["#theCounterName#"].control.TableOrder = "" />	<!--- which is empty --->
										<cfset variables.DataStores["#theFullDatabaseName#"].counters["#theCounterName#"].control.TableSizeList = "" />	<!--- which is empty --->
										<cfset variables.DataStores["#theFullDatabaseName#"].counters["#theCounterName#"].control.TableIntervalList = "" />	<!--- which is empty --->
										<cfset variables.DataStores["#theFullDatabaseName#"].counters["#theCounterName#"].control.FillValueList = "" />	<!--- which is empty --->
										<cfset variables.DataStores["#theFullDatabaseName#"].counters["#theCounterName#"].control.TableCount = 0 />	<!--- which is empty --->
										<cfset variables.DataStores["#theFullDatabaseName#"].counters["#theCounterName#"].control.OrderedTableNames = ArrayNew(1) />	<!--- which is empty --->
										<!--- this structure is only used when we are in block mode and storing counts on a temp basis --->
										<cfset variables.DataStores["#theFullDatabaseName#"].counters["#theCounterName#"].BlockCounts = StructNew() />	<!--- the struct of counters we use to add up to do a block addition --->
										<!--- now save it and return it --->
										<cfset variables.DataStores["#theFullDatabaseName#"].control.CounterNameList = ListAppend(variables.DataStores["#theFullDatabaseName#"].control.CounterNameList, "#theCounterName#") />	
										<cfset variables.DataStores["#theFullDatabaseName#"].control.CounterCount = variables.DataStores["#theFullDatabaseName#"].control.CounterCount+1 />
									</cfif>	
									<cfif variables.DataStores["#theFullDataBaseName#"].control.DataStoreMode eq "File">
										<!--- don't forget to save the new structure --->
										<cfset temp = SaveDatabaseFile(DatabaseName="#theFullDatabaseName#")/>
									<cfelseif variables.DataStores["#theFullDataBaseName#"].control.DataStoreMode eq "SQL">
										<cfquery name="setCounterController" datasource="#variables.Global.DataSource#">
											Insert into [dbo].[RRDB_#theFullDatabaseName#_CounterControl]
																(Counter, FillValueList, TableOrder, TableCount, TableIntervalList, TableNameList, TableSizeList)
												Values	('#theCounterName#', '', '', 0, '', '', '')
										</cfquery>
										<cfif theCreationMode eq "New">
											<cfquery name="setMasterController" datasource="#variables.Global.DataSource#">
												Update	RRDB_MasterControl
													set		CounterCount = #variables.DataStores["#theFullDatabaseName#"].control.CounterCount#, 
																CounternameList = '#variables.DataStores["#theFullDatabaseName#"].control.CounterNameList#'
													where	StoreFullName = '#theFullDatabaseName#'
											</cfquery>
										</cfif>
									</cfif>
								</cfif>
							</cflock>
						</cfif>
					<cfcatch type="any">
						<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 128) />
						<cfset ret.error.ErrorText = ret.error.ErrorText & 'Oops! Error Caught, error message was: #cfcatch.message#, error detail was: #cfcatch.detail#<br>' />
						<cfset ret.error.ErrorExtra =  cfcatch.TagContext />
						<cflog text="AddEmptyCounter() counter structure creation Trapped. ret.error.ErrorCode: #ret.error.ErrorCode# - Error Text: #ret.error.ErrorText# - Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#"  file="RRDBerrors" type="Error" application = "yes">
						<cfif application.SLCMS.Config.debug.debugmode>
							AddEmptyCounter() counter structure creation Trapped - error dump:<br>
							<cfdump var="#ret.error.ErrorExtra#">
						</cfif>
					</cfcatch>
					</cftry>
				</cfif>
			<cfelse>
				<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 2) />
				<cfset ret.error.ErrorText = ret.error.ErrorText & "The DataStore with the name of:- #theFullDatabaseName# cannot be found<br>" />
			</cfif>
		<cfelse>
			<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 1) />
			<cfset ret.error.ErrorText = ret.error.ErrorText & "DataStore name not supplied<br>" />
		</cfif>
	<cfcatch type="any">
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 128) />
		<cfset ret.error.ErrorText = ret.error.ErrorText & 'Oops! Error Caught, error message was: #cfcatch.message#, error detail was: #cfcatch.detail#<br>' />
		<cfset ret.error.ErrorExtra =  cfcatch.TagContext />
		<cflog text="AddEmptyCounter() unhandled error Trapped. ret.error.ErrorCode: #ret.error.ErrorCode# - Error Text: #ret.error.ErrorText# - Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#"  file="RRDBerrors" type="Error" application = "yes">
		<cfif application.SLCMS.Config.debug.debugmode>
			AddEmptyCounter() unhandled error Trapped - error dump:<br>
			<cfdump var="#ret.error.ErrorExtra#">
		</cfif>
	</cfcatch>
	</cftry>
		
	<cfreturn ret  />
</cffunction>

<cffunction name="AddTables" output="yes" returntype="struct" access="public"
	displayname="Adds tables to Counter"
	hint="Adds a set of tables to a Counter in the specified database with the specified name with the specified value (defaults to zero)">
	<!--- this function needs.... --->
	<cfargument name="CounterName" type="string" default="" />	<!--- the name of the counter to add --->
	<cfargument name="DataBaseName" type="string" default="" />	<!--- the name of the database to add the counter to --->
	<cfargument name="TableNameList" type="string" default="Daily,Weekly,Monthly,Yearly,8Yearly" />	<!--- list of tables in the database --->
	<cfargument name="TableOrderList" type="string" default="1,2,3,4,5" />	<!--- order of tables for updating counts --->
	<cfargument name="TableSizeList" type="string" default="400,400,400,400,400" />	<!--- number of slots in the tables --->
	<cfargument name="TableIntervalList" type="string" default="4,30,120,1440,10080" />	<!--- interval to change slot, in minutes --->
	<cfargument name="FillValueList" type="string" default="0,0,0,0,0" />	<!--- the values to put in the tables --->
	<cfargument name="SetTime" type="any" default="" />	<!--- the time value to load, as a datetime object --->

	<!--- now all of the var declarations, first the arguments which need manipulation --->
	<cfset var theCounterName = trim(arguments.CounterName) />	
	<cfset var theFullDatabaseName = trim(arguments.DatabaseName) />	<!--- get the database minus those dreaded fogotten spaces --->
	<cfset var theDatabaseFileName = FileName_EnCode(theFullDatabaseName) />	<!--- this will be the file name of the database --->
	<cfset var theTableNameList = trim(arguments.TableNameList) />	<!--- the list of tables --->
	<cfset var theTableOrderList = trim(arguments.TableOrderList) />	<!--- the tables' pecking order --->
	<cfset var theTableSizeList = trim(arguments.TableSizeList) />	<!--- the list of table sizes --->
	<cfset var theTableIntervalList = trim(arguments.TableIntervalList) />	<!--- the list of table intervals --->
	<cfset var theFillValueList = trim(arguments.FillValueList) />	
	<cfset var theSetTime = trim(arguments.SetTime) />	
	<!--- now vars that will get filled as we go --->
	<cfset var theTableCount = ListLen(theTableNameList) />	<!--- how many tables to process in the database --->
	<cfset var theMaxTableSize = 0 />	<!--- temp - size of largest table in the code --->
	<cfset var thisTableSize = 0 />	<!--- temp - size of current table in the code --->
	<cfset var thisTableName = "" />	<!--- temp name of table in the code --->
	<cfset var thisTableInterval = 0 />	<!--- temp interval of table in the code --->
	<cfset var thisTableOrder = 0 />	<!--- temp order of table in the code --->
	<cfset var thisFillValue = 0 />	<!--- the value to fill the data array --->
	<cfset var setCounterController = "" />	<!--- localise the query --->
	<cfset var setTableData = "" />	<!--- localise the query --->
	<cfset var getTableColumns = "" />	<!--- localise the query --->
	<cfset var getMaxSlot = "" />	<!--- localise the query --->
	<cfset var acntr = 0 />	<!--- temp loop counter --->
	<cfset var lcntr = 0 />	<!--- temp loop counter --->
	<cfset var temps = StructNew() />	<!--- temp/throwaway var --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorText = "AddTables():-<br>" />
	<cfset ret.Data = "" />

	<!--- after all that we can do stuff --->
	<!--- first is a tad of validation --->
	<!--- change - make empty slots have a null time to indicate that fact 
	<cfif theSetTime eq "">
		<cfset theSetTime = Now() />
	</cfif>
	 --->
	<!--- validate and work out our names and things --->
	<cftry>
		<cfif len(theFullDatabaseName)>
			<cfif ListFindNoCase(variables.DataStoreFileNameList, "#theDatabaseFileName#")>
				<cfif len(theCounterName)>
					<!--- make sure we have a database structure --->
					<cfset temps = ChecknSetDatabase(DatabaseName="#theFullDatabaseName#") />
					<cfif temps.error.ErrorCode eq 0>
						<!--- it is there correctly so make sure this counter does not already exist --->
						<cfif not ListFindNoCase(variables.DataStores["#theFullDatabaseName#"].control.CounterNameList, "#theCounterName#")>
							<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 4) />
							<cfset ret.error.ErrorText = ret.error.ErrorText & "The Counter with the name of:- #theCounterName# didn't exist<br>" />
						</cfif>
					<cfelseif temps.error.ErrorCode eq 1>
						<!--- flag for new DB, how come we got here, bad logic in caller --->
						<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 2) />
						<cfset ret.error.ErrorText = ret.error.ErrorText & "That DataStore with the name of:- #theFullDatabaseName# does not exist, must be a new name<br>" />
					<cfelse>
						<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 2) />
						<cfset ret.error.ErrorText = ret.error.ErrorText & "That DataStore with the name of:- #theFullDatabaseName# existed on disk but could not be read, error reported was: #temps.error.Errortext#<br>" />
					</cfif>
					<cfif ret.error.ErrorCode eq 0>
						<!--- all OK so do the work --->	
						<cfif theSetTime eq "">
							<cfset theSetTime = Now() />	<!--- if no base time specified make it now --->
						</cfif>
						<!--- calculate the biggest slotcount in our set in case they are uneven --->
						<cfset theMaxTableSize = ArrayMax(ListToArray(theTableSizeList)) />
						<!--- wrap the whole thing in a try/catch in case something breaks --->
						<cftry>
							<!--- lock it in case, with MX should be no issues with overwrite but it is happening! --->
							<cflock timeout="20" throwontimeout="No" name="DataStoreWork" type="EXCLUSIVE">
									<!--- now we are clean set the control data for this database
												remembering that we are adding so there could be stuff there already
												so what we do is loop over the new tables and add to the pile --->
									<cfloop from="1" to="#theTableCount#" index="lcntr">
										<cfset thisTableName = trim(ListGetAt(theTableNameList, lcntr)) />
										<!--- make sure we are not adding an existing table --->
										<cfif not StructKeyExists(variables.DataStores["#theFullDatabaseName#"].counters["#theCounterName#"], "#thisTableName#")>
											<cfset thisTableInterval = trim(ListGetAt(theTableIntervalList, lcntr)) />
											<cfset thisTableSize = trim(ListGetAt(theTableSizeList, lcntr)) />
											<cfset thisTableOrder = trim(ListGetAt(theTableOrderList, lcntr)) />
											<cfset thisFillValue = trim(ListGetAt(theFillValueList, lcntr)) />
											<cfset variables.DataStores["#theFullDatabaseName#"].counters["#theCounterName#"].control.TableNameList = ListAppend(variables.DataStores["#theFullDatabaseName#"].counters["#theCounterName#"].control.TableNameList, thisTableName) />	<!--- add to the list of tables --->
											<cfset variables.DataStores["#theFullDatabaseName#"].counters["#theCounterName#"].control.TableOrder = ListAppend(variables.DataStores["#theFullDatabaseName#"].counters["#theCounterName#"].control.TableOrder, thisTableOrder) />	<!--- this is the order --->
											<cfset variables.DataStores["#theFullDatabaseName#"].counters["#theCounterName#"].control.TableSizeList = ListAppend(variables.DataStores["#theFullDatabaseName#"].counters["#theCounterName#"].control.TableSizeList, thisTableSize) />	<!--- ditto table sizes --->
											<cfset variables.DataStores["#theFullDatabaseName#"].counters["#theCounterName#"].control.TableIntervalList = ListAppend(variables.DataStores["#theFullDatabaseName#"].counters["#theCounterName#"].control.TableIntervalList, thisTableInterval) />	<!--- ditto table intervals --->
											<cfset variables.DataStores["#theFullDatabaseName#"].counters["#theCounterName#"].control.FillValueList = ListAppend(variables.DataStores["#theFullDatabaseName#"].counters["#theCounterName#"].control.FillValueList, thisFillValue) />	<!--- ditto fill values --->
											<cfset variables.DataStores["#theFullDatabaseName#"].counters["#theCounterName#"].control.OrderedTableNames[thisTableOrder] = thisTableName />	<!--- put the name in the right spot according to the ordering spec --->
											<!--- this structure is only used when we are in block mode and storing counts on a temp basis --->
											<cfset variables.DataStores["#theFullDatabaseName#"].counters["#theCounterName#"].BlockCounts["#thisTableName#"] = 0 />	<!--- the counter as we add up to do a block addition --->
											<!--- now we have the control structure updated add in the new table with its control structure and data array --->
											<cfset variables.DataStores["#theFullDatabaseName#"].counters["#theCounterName#"]["#thisTableName#"] = StructNew() />
											<cfset variables.DataStores["#theFullDatabaseName#"].counters["#theCounterName#"]["#thisTableName#"].control = StructNew() />
											<cfset variables.DataStores["#theFullDatabaseName#"].counters["#theCounterName#"]["#thisTableName#"].control.TableSize = thisTableSize />
											<cfset variables.DataStores["#theFullDatabaseName#"].counters["#theCounterName#"]["#thisTableName#"].control.TableOrder = thisTableOrder />
											<cfset variables.DataStores["#theFullDatabaseName#"].counters["#theCounterName#"]["#thisTableName#"].control.Interval = thisTableInterval />
											<cfset variables.DataStores["#theFullDatabaseName#"].counters["#theCounterName#"]["#thisTableName#"].control.FillValue = thisFillValue />
											<cfset variables.DataStores["#theFullDatabaseName#"].counters["#theCounterName#"]["#thisTableName#"].control.CurrentSlot = 1 />
											<cfset variables.DataStores["#theFullDatabaseName#"].counters["#theCounterName#"].control.TableCount = variables.DataStores["#theFullDatabaseName#"].counters["#theCounterName#"].control.TableCount+1 />	<!--- set the number of tables --->
											<!--- now we have the base memory structure fill in the data as per the mode --->
											<cfif variables.DataStores["#theFullDataBaseName#"].control.DataStoreMode eq "File">
												<cfset variables.DataStores["#theFullDatabaseName#"].counters["#theCounterName#"]["#thisTableName#"].data = ArrayNew(2) />
												<!--- and fill the array with our default value --->
												<cfloop index="acntr" from="1" to="#thisTableSize#">
													<cfset variables.DataStores["#theFullDatabaseName#"].counters["#theCounterName#"]["#thisTableName#"].Data[acntr][1] = theSetTime />	<!--- timestamp of slot --->
													<cfset variables.DataStores["#theFullDatabaseName#"].counters["#theCounterName#"]["#thisTableName#"].Data[acntr][2] = thisFillValue />	<!--- specified fill value --->
												</cfloop>
											<cfelseif variables.DataStores["#theFullDataBaseName#"].control.DataStoreMode eq "SQL">
												<!--- get the table columns to see if this is a new table --->
												<cfquery name="getTableColumns" datasource="#variables.Global.DataSource#">
													sp_columns @table_name = 'RRDB_#theFullDatabaseName#_Tables'
												</cfquery>
<!--- 												
												<cfdump var="#getTableColumns#">
												<cfabort>
 --->												
												<cfif getTableColumns.RecordCount eq 2>
													<!--- yes so make a blank one with the needed rows --->
													<cfquery name="setTableData" datasource="#variables.Global.DataSource#">
														<cfloop index="acntr" from="1" to="#theMaxTableSize#">
															Insert into [dbo].[RRDB_#theFullDatabaseName#_Tables]
																				(Slot)
																Values	(#acntr#)
														</cfloop>
													</cfquery>
												<cfelse>
													<!--- there is already stuff there so check that the slotcount will fit --->
													<cfquery name="getMaxSlot" datasource="#variables.Global.DataSource#">
															Select	Max(Slot) as theMaxSlot
															from		[dbo].[RRDB_#theFullDatabaseName#_Tables]
													</cfquery>
													<cfif thisTableSize gt getMaxSlot.theMaxSlot>
														<!--- the slotcount is greater than existing so we need to add a few --->
														<cfquery name="setTableData" datasource="#variables.Global.DataSource#">
															<cfloop index="acntr" from="#getMaxSlot.theMaxSlot#" to="#thisTableSize#">
																Insert into [dbo].[RRDB_#theFullDatabaseName#_Tables]
																					(Slot)
																	Values	(#acntr#)
															</cfloop>
														</cfquery>
													</cfif>
												</cfif>
												<!--- then work out if we need to add in the columns for this table --->
												<cfloop query="getTableColumns">
													<cfif getTableColumns.Column_Name eq "#theCounterName#_#thisTableName#_Value">
														<!--- Oops! it already exists --->
														<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 8) />
														<cfset ret.error.ErrorText = ret.error.ErrorText & "dataset already there in DB table<br>" />
													</cfif>
												</cfloop>
												<cfif ret.error.ErrorCode eq 0>
													<!--- we need to so do it --->
													<cfquery name="createTableDatasetColumns" datasource="#variables.Global.DataSource#">
														Alter TABLE [dbo].[RRDB_#theFullDatabaseName#_Tables]
															ADD #theCounterName#_#thisTableName#_Value [int] NOT NULL DEFAULT (0)
<!--- 
															CONSTRAINT [DF_RRDB_#theFullDatabaseName#_Tables_#theCounterName#_#thisTableName#_Value]
 --->
														Alter TABLE [dbo].[RRDB_#theFullDatabaseName#_Tables]
															ADD #theCounterName#_#thisTableName#_TimeStamp [datetime] NULL
													</cfquery>
												</cfif>
												<!--- add in the table's control set --->
												<cfquery name="setTableController" datasource="#variables.Global.DataSource#">
													Insert into [dbo].[RRDB_#theFullDatabaseName#_TableControl]
																		(Counter, Dataset, CurrentSlot, TableSize, SlotInterval, FillValue, TableOrder)
														Values	('#theCounterName#', '#thisTableName#', 1, #thisTableSize#, #thisTableInterval#, '#thisFillValue#', #thisTableOrder#)
												</cfquery>
<!--- 
												<!--- and then the dataset itself (remember can't call it a table in the database, very confusing :-))) --->
												<cfquery name="setTableData" datasource="#variables.Global.DataStorePath#">
													<cfloop index="acntr" from="1" to="#thisTableSize#">
														Insert into RRDB_#theFullDatabaseName#_Tables
																			(Slot, Counter, Dataset, DataValue, DataTimeStamp)
															Values	(#acntr#, '#theCounterName#', '#thisTableName#', '#thisFillValue#', #CreateODBCDateTime(theSetTime)#)
													</cfloop>
												</cfquery>
 --->
											</cfif>
										</cfif>
									</cfloop>
									<!--- now save the updated structure --->
									<cfif variables.DataStores["#theFullDataBaseName#"].control.DataStoreMode eq "File">
										<cfset temps = SaveDatabaseFile(DatabaseName="#theFullDatabaseName#")/>
									<cfelseif variables.DataStores["#theFullDataBaseName#"].control.DataStoreMode eq "SQL">
										<!--- update the Counter Controller and add in the table --->
										<cfquery name="setCounterController" datasource="#variables.Global.DataSource#">
											Update	[dbo].[RRDB_#theFullDatabaseName#_CounterControl]
												Set		FillValueList = '#variables.DataStores["#theFullDatabaseName#"].counters["#theCounterName#"].control.FillValueList#',
															TableOrder = '#variables.DataStores["#theFullDatabaseName#"].counters["#theCounterName#"].control.TableOrder#',
															TableCount = '#variables.DataStores["#theFullDatabaseName#"].counters["#theCounterName#"].control.TableCount#',
															TableIntervalList = '#variables.DataStores["#theFullDatabaseName#"].counters["#theCounterName#"].control.TableIntervalList#',
															TableNameList = '#variables.DataStores["#theFullDatabaseName#"].counters["#theCounterName#"].control.TableNameList#',
															TableSizeList = '#variables.DataStores["#theFullDatabaseName#"].counters["#theCounterName#"].control.TableSizeList#'
												Where	Counter = '#theCounterName#'
										</cfquery>
									</cfif>
							</cflock>
						<cfcatch type="any">
							<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 128) />
							<cfset ret.error.ErrorText = ret.error.ErrorText & 'Table Creation Error Caught, error message was: #cfcatch.message#, error detail was: #cfcatch.detail#<br>' />
							<cfset ret.error.ErrorExtra =  cfcatch.TagContext />
							<cflog text="AddTables() unhandled error Trapped. ret.error.ErrorCode: #ret.error.ErrorCode# - Error Text: #ret.error.ErrorText# - Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#"  file="RRDBerrors" type="Error" application = "yes">
							<cfif application.SLCMS.Config.debug.debugmode>
								AddTables() Table Creation Trapped - error dump:<br>
								<cfdump var="#ret.error.ErrorExtra#">
							</cfif>
						</cfcatch>
						</cftry>
					</cfif>
				<cfelse>
					<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 4) />
					<cfset ret.error.ErrorText = ret.error.ErrorText & "Counter name not supplied or counter structure not there<br>" />
				</cfif>
			<cfelse>
				<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 2) />
				<cfset ret.error.ErrorText = ret.error.ErrorText & "The DataStore with the name of:- #theFullDatabaseName# cannot be found<br>" />
			</cfif>
		<cfelse>
			<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 1) />
			<cfset ret.error.ErrorText = ret.error.ErrorText & "DataStore name not supplied<br>" />
		</cfif>
	<cfcatch type="any">
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 128) />
		<cfset ret.error.ErrorText = ret.error.ErrorText & 'Oops! Error Caught, error message was: #cfcatch.message#, error detail was: #cfcatch.detail#<br>' />
		<cfset ret.error.ErrorExtra =  cfcatch.TagContext />
		<cflog text="AddTables() unhandled error Trapped. ret.error.ErrorCode: #ret.error.ErrorCode# - Error Text: #ret.error.ErrorText# - Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#"  file="RRDBerrors" type="Error" application = "yes">
		<cfif application.SLCMS.Config.debug.debugmode>
			AddTables() unhandled error Trapped - error dump:<br>
			<cfdump var="#ret.error.ErrorExtra#">
		</cfif>
	</cfcatch>
	</cftry>
	
	<cfreturn ret  />
</cffunction>

<cffunction name="SaveDatabaseFile" output="yes" returntype="struct" access="public"
	displayname="Save a Database"
	hint="Saves the specified Database or all of them">
	<!--- this function needs.... --->
	<cfargument name="DataBaseName" type="string" default="" />	<!--- the name of the database to add the counter to --->

	<cfset var theDataBaseName = trim(arguments.DatabaseName) />
	<cfset var theDataBaseList = "" />
	<cfset var thisDataBase = "" />
	<cfset var thisCounter = "" />
	<cfset var theTableList = "" />
	<cfset var thisTable = "" />
	<cfset var thePacket = "" />
	<cfset var setCounterControl = "" />	<!--- localise the queries --->
	<cfset var setTableControl = "" />	<!--- localise the queries --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorText = "" />
	<cfset ret.Data = "" />

	<cftry>
		<cfif theDataBaseName eq "">
			<!--- null means save all of them --->
			<cfset theDataBaseList = variables.DataStoreFileNameList />
		<cfelse>	<!--- just save the specified --->
			<cfset theDataBaseList = FileName_EnCode(theDatabaseName) />	<!--- this will be the actual name of the database, doesn't matter if the fed-in name was encoded already --->
		</cfif>
		
		<cfloop index="thisDatabase" list="#theDataBaseList#">
			<!--- lock it in case, we could call it twice and mess up files..... --->
			<cflock timeout="20" throwontimeout="No" name="DataStoreFileWork" type="EXCLUSIVE">
				<cfif StructKeyExists(variables.DataStores, thisDatabase)>
					<cfif variables.DataStores["#theDataBaseName#"].control.DataStoreMode eq "File">
						<cftry>
							<cfwddx action="CFML2WDDX" input="#variables.DataStores['#thisDatabase#']#" output="thePacket" />
						<cfcatch type="any">
							<cfset ret.error.ErrorCode = 1 />
							<cfset ret.error.ErrorText = "File save failed. Database was: #thisDatabase#<br>" />
							<cfset ret.error.ErrorExtra =  cfcatch.TagContext />
							<cflog text="SaveDatabaseFile() wddx-encode Trapped. ret.error.ErrorCode: #ret.error.ErrorCode# - Error Text: #ret.error.ErrorText# - Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#"  file="RRDBerrors" type="Error" application = "yes">
							<cfif application.SLCMS.Config.debug.debugmode>
								SaveDatabaseFile() wddx-encode Trapped error dump:<br>
								<cfdump var="#cfcatch#">
							</cfif>
						</cfcatch>
						</cftry>
						<cftry>
							<cffile action="write" file="#variables.Global.DataStorePath##thisDatabase#.rrdb" output="#thePacket#" addnewline="No" />
						<cfcatch type="any">
							<cfset ret.error.ErrorCode = 1 />
							<cfset ret.error.ErrorText = "File save failed. Database was: #thisDatabase#<br>" />
							<cfset ret.error.ErrorExtra =  cfcatch.TagContext />
							<cflog text="SaveDatabaseFile() file-save Trapped. ret.error.ErrorCode: #ret.error.ErrorCode# - Error Text: #ret.error.ErrorText# - Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#"  file="RRDBerrors" type="Error" application = "yes">
							<cfif application.SLCMS.Config.debug.debugmode>
								SaveDatabaseFile() file-save Trapped error dump:<br>
								<cfdump var="#cfcatch#">
							</cfif>
						</cfcatch>
						</cftry>
					<cfelseif variables.DataStores["#theDataBaseName#"].control.DataStoreMode eq "SQL">
						<!--- if database mode then we need to save all of the control tables, the actual data is being saved on the fly --->
						<!--- loop over the counters (outer) and the tables (inner) --->
						<cftry>
						<cfloop list="#variables.DataStores["#theDataBaseName#"].control.CounterNameList#" index="thisCounter">
							<cfset theTableList = variables.DataStores["#theDataBaseName#"].counters["#thisCounter#"].control.TableNameList />
							<cfquery name="setCounterControl" datasource="#variables.Global.DataSource#">
								Update	[dbo].[RRDB_#theDataBaseName#_CounterControl]
									Set		TableCount = #variables.DataStores["#theDataBaseName#"].counters["#thisCounter#"].control.TableCount#,
												TableNameList = '#variables.DataStores["#theDataBaseName#"].counters["#thisCounter#"].control.TableNameList#',
												TableSizeList = '#variables.DataStores["#theDataBaseName#"].counters["#thisCounter#"].control.TableSizeList#',
												TableIntervalList = '#variables.DataStores["#theDataBaseName#"].counters["#thisCounter#"].control.TableIntervalList#',
												FillValueList = '#variables.DataStores["#theDataBaseName#"].counters["#thisCounter#"].control.FillValueList#',
												TableOrder = '#variables.DataStores["#theDataBaseName#"].counters["#thisCounter#"].control.TableOrder#'
									Where	Counter = '#thisCounter#'
							</cfquery>
							<cfloop list="#theTableList#" index="thisTable">
								<cfquery name="setTableControl" datasource="#variables.Global.DataSource#">
									Update	[dbo].[RRDB_#theDataBaseName#_TableControl]
										Set		CurrentSlot = #variables.DataStores["#theDataBaseName#"].counters["#thisCounter#"]["#thisTable#"].control.CurrentSlot#,
													TableSize = #variables.DataStores["#theDataBaseName#"].counters["#thisCounter#"]["#thisTable#"].control.TableSize#,
													SlotInterval = #variables.DataStores["#theDataBaseName#"].counters["#thisCounter#"]["#thisTable#"].control.Interval#,
													FillValue = #variables.DataStores["#theDataBaseName#"].counters["#thisCounter#"]["#thisTable#"].control.FillValue#,
													TableOrder = #variables.DataStores["#theDataBaseName#"].counters["#thisCounter#"]["#thisTable#"].control.TableOrder#
										Where	Counter = '#thisCounter#'
											and	DataSet = '#thisTable#'
								</cfquery>
							</cfloop>	<!--- end: dataset loop --->
						</cfloop>	<!--- end: counter loop --->
						<cfcatch type="any">
							<cfset ret.error.ErrorCode = 1 />
							<cfset ret.error.ErrorText = "Database Update failed. Database was: #thisDatabase#<br>" />
							<cfset ret.error.ErrorExtra =  cfcatch.TagContext />
							<cflog text="SaveDatabaseFile() Database-Update Trapped. ret.error.ErrorCode: #ret.error.ErrorCode# - Error Text: #ret.error.ErrorText# - Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#"  file="RRDBerrors" type="Error" application = "yes">
							<cfif application.SLCMS.Config.debug.debugmode>
								SaveDatabaseFile() Database Update Trapped error dump:<br>
								<cfdump var="#cfcatch#">
							</cfif>
						</cfcatch>
						</cftry>
					</cfif>	<!--- end: database mode choice --->
				</cfif>	<!--- end: only do it if there is a struct to save, could be missing if straight after a restart and not grabbed yet --->
			</cflock>
		</cfloop>	<!--- end: loop over every store in the list --->
	<cfcatch type="any">
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 128) />
		<cfset ret.error.ErrorText = ret.error.ErrorText & 'Oops! Error Caught, error message was: #cfcatch.message#, error detail was: #cfcatch.detail#<br>' />
		<cfset ret.error.ErrorExtra =  cfcatch.TagContext />
		<cflog text="SaveDatabaseFile() unhandled error Trapped. ret.error.ErrorCode: #ret.error.ErrorCode# - Error Text: #ret.error.ErrorText# - Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#"  file="RRDBerrors" type="Error" application = "yes">
		<cfif application.SLCMS.Config.debug.debugmode>
			SaveDatabaseFile() error dump:<br>
			<cfdump var="#cfcatch#">
		</cfif>
	</cfcatch>
	</cftry>
	
	<cfreturn ret  />
</cffunction>

<cffunction name="getDataBaseList" output="yes" returntype="struct" access="public"
	displayname="gets list of databases"
	hint="gets a list of all databases"
				>
	<!--- this function needs.... nothing --->
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorText = "getDataBaseList():-<br> " />
	<cfset ret.Data = "" />
	
	<!--- now do some validation --->
	<cfif not StructKeyExists(variables, "DataStoreFileNameList")>
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 1) />
		<cfset ret.error.ErrorText = ret.error.ErrorText & "The list of databases is missing<br>" />
	<cfelse>
		<!--- all OK so return the data --->
		<cfset ret.Data = FileName_DeCode(variables.DataStoreFileNameList) />
	</cfif>

	<cfreturn ret  />
</cffunction>

<cffunction name="DataBaseExists" output="yes" returntype="boolean" access="public"
	displayname="checks existance of database"
	hint="checks existance of database, returns a simple true/false"
				>
	<!--- this function needs.... nothing --->
	<cfargument name="DatabaseName" type="string" default="" />	<!--- the name of the database --->
	<!--- now all of the var declarations, first the arguments which need manipulation --->
	<cfset var theDataBaseName = trim(arguments.DatabaseName) />
	<cfset var temps = StructNew() />
	<cfset var ret = False />	<!--- this is the return to the caller --->
	
	<!--- make sure we have a database structure --->
	<cfset temps = ChecknSetDatabase(DatabaseName="#theDataBaseName#") />
	<cfif temps.error.ErrorCode eq 0>
	<cfelseif temps.error.ErrorCode eq 1>
	<cfelse>
	</cfif>
	
	<!--- do the find --->
	<cfif StructKeyExists(variables.DataStores, "#theDataBaseName#")>
		<cfset ret =  True />
	</cfif>

	<cfreturn ret  />
</cffunction>

<cffunction name="getFullDatabaseStructure" output="yes" returntype="struct" access="public"
	displayname="gets database Structure(s)"
	hint="gets full structure of all or specified database"
				>
	<!--- this function needs.... --->
	<cfargument name="DatabaseName" type="string" default="All" />	<!--- the name of the database --->
	<!--- now all of the var declarations, first the arguments which need manipulation --->
	<cfset var theDataBaseName = trim(arguments.DatabaseName) />
	<cfset var theDataBaseFileName = FileName_EnCode(theDataBaseName) />

	<cfset var temps = StructNew() />
	<cfset var ret = StructNew() />
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorText = "getFullDataBaseStructure():-<br> " />
	<cfset ret.Data = "" />

	<!--- now do some validation --->
	<cfif not len(theDataBaseName)>
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 1) />
		<cfset ret.error.ErrorText = ret.error.ErrorText & "DataStore name not supplied<br>" />
	<cfelseif theDataBaseName neq "All" and not ListFindNoCase(variables.DataStoreFileNameList, "#theDataBaseFileName#")>
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 2) />
		<cfset ret.error.ErrorText = ret.error.ErrorText & "The DataStore with the name of:- #theDatabaseName# doesn't exist<br>" />
	</cfif>
	<cfif ret.error.ErrorCode eq 0>
		<!--- all OK so return the data --->
		<cfif theDataBaseName eq "All">
			<cfset ret.Data = variables.DataStores />
		<cfelse>
			<cfset temps = CheckNsetDatabase(DatabaseName="#theDataBaseName#") />	<!--- make sure it has been grabbed off disk --->
			<cfset ret.Data = variables.DataStores["#theDataBaseName#"] />
		</cfif>
	</cfif>
	

	<cfreturn ret  />
</cffunction>

<cffunction name="getDatabaseCounterList" output="yes" returntype="struct" access="public"
	displayname="gets list of counters"
	hint="returns a list of all databases in specified database"
				>
	<!--- this function needs.... --->
	<cfargument name="DatabaseName" type="string" default="" />	<!--- the name of the databasee --->

	<!--- now all of the var declarations, first the arguments which need manipulation --->
	<cfset var theDataBaseName = trim(arguments.DatabaseName) />
	<cfset var theDataBaseFileName = FileName_EnCode(theDataBaseName) />
	<cfset var temps = StructNew() />
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorText = "getDatabaseCounterList():-<br> " />
	<cfset ret.Data = "" />
	
	<!--- now do some validation --->
	<cfif not len(theDataBaseName)>
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 1) />
		<cfset ret.error.ErrorText = ret.error.ErrorText & "DataStore name not supplied or all invalid characters<br>" />
	</cfif>
	<cfif not ListFindNoCase(variables.DataStoreFileNameList, "#theDataBaseFileName#")>
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 2) />
		<cfset ret.error.ErrorText = ret.error.ErrorText & "The DataStore with the name of:- #theDatabaseName# doesn't exist<br>" />
	</cfif>
	<!--- make sure we have a database structure --->
	<cfset temps = ChecknSetDatabase(DatabaseName="#theDatabaseName#") />
	<cfif temps.error.ErrorCode eq 0>
		<!--- subsiduary test here if needed --->
	<cfelseif temps.error.ErrorCode eq 1>
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 2) />
		<cfset ret.error.ErrorText = ret.error.ErrorText & "That DataStore with the short name of:- #theDatabaseName# does not exist, must be a new name<br>" />
	<cfelse>
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 2) />
		<cfset ret.error.ErrorText = ret.error.ErrorText & "That DataStore with the short name of:- #theDatabaseName# existed on disk but could not be read, error reported was: #temps.error.Errortext#<br>" />
	</cfif>
	<cfif not StructKeyExists(variables.DataStores, "#theDataBaseName#")>
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 4) />
		<cfset ret.error.ErrorText = ret.error.ErrorText & "The database structure is missing<br>" />
	</cfif>
	<cfif ret.error.ErrorCode eq 0>
		<!--- all OK so return the data --->
		<cfset ret.Data = variables.DataStores["#theDataBaseName#"].control.CounterNameList />
	</cfif>

	<cfreturn ret  />
</cffunction>

<cffunction name="getCounterTableList" output="yes" returntype="struct" access="public"
	displayname="get list of tables in a counter"
	hint="returns a list and a pecking ordered array of all tables in the specified counter in specified database"
				>
	<!--- this function needs.... --->
	<cfargument name="DatabaseName" type="string" default="" />	<!--- the name of the database --->
	<cfargument name="CounterName" type="string" default="" />	<!--- the name of the counter --->

	<!--- now all of the var declarations, first the arguments which need manipulation --->
	<cfset var theDataBaseName = trim(arguments.DatabaseName) />
	<cfset var theDataBaseFileName = FileName_EnCode(theDataBaseName) />
	<cfset var theCounterName = trim(arguments.CounterName) />
	<cfset var temps = StructNew() />
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorText = "getCounterTableList():-<br> " />
	<cfset ret.Data = StructNew() />
	<cfset ret.Data.Array = Arraynew(1) />
	<cfset ret.Data.List = "" />
	
	<!--- now do some validation --->
	<cfif not len(theDataBaseName)>
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 1) />
		<cfset ret.error.ErrorText = ret.error.ErrorText & "DataStore name not supplied or all invalid characters<br>" />
	</cfif>
	<cfif not ListFindNoCase(variables.DataStoreFileNameList, "#theDataBaseFileName#")>
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 2) />
		<cfset ret.error.ErrorText = ret.error.ErrorText & "The DataStore with the name of:- #theDatabaseName# doesn't exist<br>" />
	</cfif>
	<!--- make sure we have a database structure --->
	<cfset temps = ChecknSetDatabase(DatabaseName="#theDatabaseName#") />
	<cfif temps.error.ErrorCode eq 0>
		<!--- subsiduary test here if needed --->
	<cfelseif temps.error.ErrorCode eq 1>
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 2) />
		<cfset ret.error.ErrorText = ret.error.ErrorText & "That DataStore with the short name of:- #theDatabaseName# does not exist, must be a new name<br>" />
	<cfelse>
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 2) />
		<cfset ret.error.ErrorText = ret.error.ErrorText & "That DataStore with the short name of:- #theDatabaseName# existed on disk but could not be read, error reported was: #temps.error.Errortext#<br>" />
	</cfif>
	<cfif not StructKeyExists(variables.DataStores, "#theDataBaseName#")>
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 4) />
		<cfset ret.error.ErrorText = ret.error.ErrorText & "The database structure is missing<br>" />
	</cfif>
	<cfif not len(theCounterName)>
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 8) />
		<cfset ret.error.ErrorText = ret.error.ErrorText & "Counter name not supplied<br>" />
	</cfif>
	<cfif not ListFindNoCase(variables.DataStores["#theDatabaseName#"].control.CounterNameList, "#theCounterName#")>
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 16) />
		<cfset ret.error.ErrorText = ret.error.ErrorText & "The Counter with the name of:- #theCounterName# doesn't exist<br>" />
	</cfif>
	<cfif ret.error.ErrorCode eq 0>
		<!--- all OK so return the data --->
		<cfset ret.Data.Array = variables.DataStores["#theDataBaseName#"].counters["#theCounterName#"].control.OrderedTableNames />
		<cfset ret.Data.List = ArrayToList(ret.Data.Array) />
	</cfif>

	<cfreturn ret  />
</cffunction>

<cffunction name="getNextCounterTable" output="yes" returntype="struct" access="public"
	displayname="get next table in a counter"
	hint="returns name of the next table in order from the specified table in the specified counter in specified database"
				>
	<!--- this function needs.... --->
	<cfargument name="DatabaseName" type="string" default="" />	<!--- the name of the database --->
	<cfargument name="CounterName" type="string" default="" />	<!--- the name of the counter --->
	<cfargument name="CurrentTableName" type="string" default="" />	<!--- the name of the table --->

	<!--- now all of the var declarations, first the arguments which need manipulation --->
	<cfset var theDataBaseName = trim(arguments.DatabaseName) />
	<cfset var theDataBaseFileName = FileName_EnCode(theDataBaseName) />
	<cfset var theCounterName = trim(arguments.CounterName) />
	<cfset var theCurrentTableName = trim(arguments.CurrentTableName) />
	<!--- now temp stores --->	
	<cfset var temp = "" />	<!--- temp/throwaway var --->
	<cfset var tempa = ArrayNew(1) />	<!--- temp/throwaway var --->
	<cfset var temps = StructNew() />	<!--- temp/throwaway var --->
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorText = "getNextCounterTable():-<br> " />
	<cfset ret.Data = "" />
	
	<!--- now do some validation --->
	<cfif not len(theDataBaseName)>
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 1) />
		<cfset ret.error.ErrorText = ret.error.ErrorText & "DataStore name not supplied or all invalid characters<br>" />
	</cfif>
	<cfif not ListFindNoCase(variables.DataStoreFileNameList, "#theDataBaseFileName#")>
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 2) />
		<cfset ret.error.ErrorText = ret.error.ErrorText & "The DataStore with the name of:- #theDatabaseName# doesn't exist<br>" />
	</cfif>
	<!--- make sure we have a database structure --->
	<cfset temps = ChecknSetDatabase(DatabaseName="#theDatabaseName#") />
	<cfif temps.error.ErrorCode eq 0>
		<!--- subsiduary test here if needed --->
	<cfelseif temps.error.ErrorCode eq 1>
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 2) />
		<cfset ret.error.ErrorText = ret.error.ErrorText & "That DataStore with the short name of:- #theDatabaseName# does not exist, must be a new name<br>" />
	<cfelse>
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 2) />
		<cfset ret.error.ErrorText = ret.error.ErrorText & "That DataStore with the short name of:- #theDatabaseName# existed on disk but could not be read, error reported was: #temps.error.Errortext#<br>" />
	</cfif>
	<cfif not StructKeyExists(variables.DataStores, "#theDataBaseName#")>
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 4) />
		<cfset ret.error.ErrorText = ret.error.ErrorText & "The database structure is missing<br>" />
	</cfif>
	<cfif not len(theCounterName)>
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 8) />
		<cfset ret.error.ErrorText = ret.error.ErrorText & "Counter name not supplied<br>" />
	</cfif>
	<cfif not ListFindNoCase(variables.DataStores["#theDatabaseName#"].control.CounterNameList, "#theCounterName#")>
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 16) />
		<cfset ret.error.ErrorText = ret.error.ErrorText & "The Counter with the name of:- #theCounterName# doesn't exist<br>" />
	</cfif>
	<cfif not ListFindNoCase(variables.DataStores["#theDatabaseName#"].counters["#theCounterName#"].control.TableNameList, "#theCurrentTableName#")>
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 32) />
		<cfset ret.error.ErrorText = ret.error.ErrorText & "The Table with the name of:- #theCurrentTableName# doesn't exist<br>" />
	</cfif>
	<cfif ret.error.ErrorCode eq 0>
		<!--- all OK so return the data --->
		<!--- wrap the whole thing in a try/catch in case something breaks despite all the checking above --->
		<cftry>
			<cfset temp = variables.DataStores["#theDatabaseName#"].counters["#theCounterName#"]["#theCurrentTableName#"].control.TableOrder+1 />	<!--- our place plus one --->
			<cfif temp gt variables.DataStores["#theDatabaseName#"].counters["#theCounterName#"].control.TableCount or temp gt ArrayLen(variables.DataStores["#theDatabaseName#"].counters["#theCounterName#"].control.OrderedTableNames)>	<!-- make sure we don't walk off the end -->
				<cfset ret.Data = "" />
			<cfelse>
				<cfset ret.Data = variables.DataStores["#theDatabaseName#"].counters["#theCounterName#"].control.OrderedTableNames[temp] />
			</cfif>
		<cfcatch type="any">
			<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 128) />
			<cfset ret.error.ErrorText = ret.error.ErrorText & 'Oops! Error Caught, error message was: #cfcatch.message#, error detail was: #cfcatch.detail#<br>' />
			<cfset ret.error.ErrorExtra =  cfcatch.TagContext />
			<cflog text="getNextCounterTable() structure read Trapped. database:#theDatabaseName# - counter:#theCounterName# - CurrentTableName:#theCurrentTableName# - ret.error.ErrorCode: #ret.error.ErrorCode# - Error Text: #ret.error.ErrorText# - Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#"  file="RRDBerrors" type="Error" application = "yes">
			<cfif application.SLCMS.Config.debug.debugmode>
				getNextCounterTable() structure read Trapped - error dump:<br>
				<cfdump var="#ret.error.ErrorExtra#">
			</cfif>
		</cfcatch>
		</cftry>
	</cfif>

	<cfreturn ret  />
</cffunction>

<cffunction name="getCounterTableStructure" output="yes" returntype="struct" access="public"
	displayname="get Table structure"
	hint="returns a structure of the tables in the specified counter in the specified database"
				>
	<!--- this function needs.... --->
	<cfargument name="DatabaseName" type="string" default="" />	<!--- the name of the databasee --->
	<cfargument name="TableName" type="string" default="All" />	<!--- the name of the table in the above database --->
	<cfargument name="CounterName" type="string" default="All" />	<!--- the name of the counter in the above table --->

	<!--- now all of the var declarations, first the arguments which need manipulation --->
	<cfset var theDataBaseName = trim(arguments.DatabaseName) />
	<cfset var theDataBaseFileName = FileName_EnCode(theDataBaseName) />
	<!--- now vars that will get filled as we go --->
	<cfset var theTableList = "" />	<!--- temp/throwaway var --->
	<cfset var thisTable = "" />	<!--- temp/throwaway var --->
	<cfset var lcntr = 0 />	<!--- temp loop counter --->
	<cfset var temps = StructNew() />	<!--- temp/throwaway var --->
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorText = "getCounterTableStructure():-<br> " />
	<cfset ret.Data = "" />
	
	<!--- now do some validation --->
	<cfif not len(theDataBaseName)>
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 1) />
		<cfset ret.error.ErrorText = ret.error.ErrorText & "DataStore name not supplied or all invalid characters<br>" />
	</cfif>
	<cfif not ListFindNoCase(variables.DataStoreFileNameList, "#theDatabaseName#")>
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 2) />
		<cfset ret.error.ErrorText = ret.error.ErrorText & "The DataStore with the name of:- #theDatabaseFileName# doesn't exist<br>" />
	</cfif>
	<!--- make sure we have a database structure --->
	<cfset temps = ChecknSetDatabase(DatabaseName="#theDatabaseName#") />
	<cfif temps.error.ErrorCode eq 0>
		<!--- subsiduary test here if needed --->
	<cfelseif temps.error.ErrorCode eq 1>
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 2) />
		<cfset ret.error.ErrorText = ret.error.ErrorText & "That DataStore with the name of:- #theDatabaseName# does not exist, must be a new name<br>" />
	<cfelse>
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 2) />
		<cfset ret.error.ErrorText = ret.error.ErrorText & "That DataStore with the name of:- #theDatabaseName# existed on disk but could not be read, error reported was: #temps.error.Errortext#<br>" />
	</cfif>
	<cfif not StructKeyExists(variables.DataStores, "#theDataBaseName#")>
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 4) />
		<cfset ret.error.ErrorText = ret.error.ErrorText & "The DataStore with the Short name of:- #theDatabaseName# structure is missing<br>" />
	</cfif>
	<cfif not len(theTableName)>
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 8) />
		<cfset ret.error.ErrorText = ret.error.ErrorText & "The Table name not supplied<br>" />
	</cfif>
	<cfif not len(theCounterName)>
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 16) />
		<cfset ret.error.ErrorText = ret.error.ErrorText & "The Counter name not supplied<br>" />
	</cfif>
	<cfif ret.error.ErrorCode eq 0>
		<!--- all OK so return the data --->
		<!--- wrap the whole thing in a try/catch in case something breaks despite all the checking above --->
		<cftry>
			<cfset theTableList = variables.DataStores["#theDataBaseName#"]["#theCounterName#"].control.TableNameList />
			<cfloop index="thisTable" list="#theTableList#">
				<cfset ret.data["#thisTable#"] = StructNew() />
				<cfset ret.data["#thisTable#"].control = variables.DataStores["#theDataBaseName#"].counters["#theCounterName#"]["#thisTable#"].control />
				<cfset ret.data["#thisTable#"].data = variables.DataStores["#theDataBaseName#"].counters["#theCounterName#"]["#thisTable#"].data />
			</cfloop>
		<cfcatch type="any">
			<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 128) />
			<cfset ret.error.ErrorText = ret.error.ErrorText & 'Oops! Error Caught, error message was: #cfcatch.message#, error detail was: #cfcatch.detail#<br>' />
			<cfset ret.error.ErrorExtra =  cfcatch.TagContext />
			<cflog text="getNextCounterTable() structure read Trapped. ret.error.ErrorCode: #ret.error.ErrorCode# - Error Text: #ret.error.ErrorText# - Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#"  file="RRDBerrors" type="Error" application = "yes">
			<cfif application.SLCMS.Config.debug.debugmode>
				getNextCounterTable() structure read Trapped - error dump:<br>
				<cfdump var="#ret.error.ErrorExtra#">
			</cfif>
		</cfcatch>
		</cftry>
	</cfif>

	<cfreturn ret  />
</cffunction>

<cffunction name="getCounterTableData" output="yes" returntype="struct" access="public"
	displayname="get Counter Data"
	hint="gets the specified counter data from the specified table in the specified database"
				>
	<!--- this function needs.... --->
	<cfargument name="DatabaseName" type="string" default="" />	<!--- the name of the databasee --->
	<cfargument name="TableName" type="string" default="All" />	<!--- the name of the table in the above database --->
	<cfargument name="CounterName" type="string" default="" />	<!--- the name of the counter in the above table --->

	<!--- now all of the var declarations, first the arguments which need manipulation --->
	<cfset var theDataBaseName = trim(arguments.DatabaseName) />
	<cfset var theDataBaseFileName = FileName_EnCode(theDataBaseName) />
	<cfset var theTableName = trim(arguments.TableName) />
	<cfset var theCounterName = trim(arguments.CounterName) />thisTable
	<!--- now vars that will get filled as we go --->
	<cfset var temps = StructNew() />	<!--- temp/throwaway var --->
	<cfset var lcntr = 0 />	<!--- temp loop counter --->
	<cfset var ocntr = 0 />	<!--- temp loop counter --->
	<cfset var thisCounter = "" />	<!--- temp/throwaway var --->
	<cfset var thisTable = "" />	<!--- temp/throwaway var --->
	<cfset var theCounterID = 0 />	<!--- will hold which array dimension for the specified counter --->
	<cfset var sret = StructNew() />	<!--- temp/throwaway function call return struct --->
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorText = "getCounterTableData():-<br> " />
	<cfset ret.Data = "" />
	
	<!--- now do some validation --->
	<cfif not len(theDataBaseName)>
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 1) />
		<cfset ret.error.ErrorText = ret.error.ErrorText & "DataStore name not supplied<br>" />
	<cfelseif not ListFindNoCase(variables.DataStoreFileNameList, "#theDataBaseFileName#")>
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 2) />
		<cfset ret.error.ErrorText = ret.error.ErrorText & "The DataStore with the name of:- #theDatabaseName# doesn't exist<br>" />
	</cfif>
	<!--- make sure we have a database structure --->
	<cfset temps = ChecknSetDatabase(DatabaseName="#theDatabaseName#") />
	<cfif temps.error.ErrorCode eq 0>
		<!--- subsiduary test here if needed --->
	<cfelseif temps.error.ErrorCode eq 1>
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 2) />
		<cfset ret.error.ErrorText = ret.error.ErrorText & "That DataStore with the name of:- #theDatabaseName# does not exist, must be a new name<br>" />
	<cfelse>
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 2) />
		<cfset ret.error.ErrorText = ret.error.ErrorText & "That DataStore with the name of:- #theDatabaseName# existed on disk but could not be read, error reported was: #temps.error.Errortext#<br>" />
	</cfif>
	<cfif not StructKeyExists(variables.DataStores, "#theDataBaseName#")>
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 4) />
		<cfset ret.error.ErrorText = ret.error.ErrorText & "The DataStore with the name of:- #theDatabaseName# structure is missing<br>" />
	</cfif>
	<cfif not len(theTableName)>
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 8) />
		<cfset ret.error.ErrorText = ret.error.ErrorText & "The Table name not supplied<br>" />
	</cfif>
	<cfif not len(theCounterName)>
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 16) />
		<cfset ret.error.ErrorText = ret.error.ErrorText & "The Counter name not supplied<br>" />
	</cfif>
	<cfif ret.error.ErrorCode eq 0>
		<!--- all OK so return the data --->
		<!--- wrap the whole thing in a try/catch in case something breaks despite all the checking above --->
		<cftry>
			<!--- first work out what array element we need and from what store --->
			<cfif theTableName eq "All">
					<!---  we need to loop over all of them --->
			<cfelse>
				<cfset ret.data = StructNew() />
				<cfif theTableName eq "All">
					<!---  we need to return all counters --->
					<cfset theTableList = variables.DataStores["#theDataBaseName#"].counters["#theCounterName#"].control.TableNameList />
					<cfloop index="thisTable" list="#theTableList#">
						<cfset ret.data["#thisTable#"] = StructNew() />
						<cfif variables.DataStores["#theDataBaseName#"].control.DataStoreMode eq "File">
							<cfset ret.data["#thisTable#"] = variables.DataStores["#theDataBaseName#"].counters["#theCounterName#"]["#thisTable#"].data />
						<cfelseif variables.DataStores["#theDataBaseName#"].control.DataStoreMode eq "SQL">
							<cfset sret = getSQLTableDataToArray(databaseName="#theDataBaseName#", counterName="#theCounterName#", DatasetName="#thisTable#") />
							<cfif sret.error.ErrorCode eq 0>
								<cfset ret.data["#thisTable#"] = sret.data />
							<cfelse>
								<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 2) />
								<cfset ret.error.ErrorText = ret.error.ErrorText & 'Oops! Error returned from getSQLTableDataToArray call. Error was:<br>' />
								<cfset ret.error.ErrorText = ret.error.ErrorText & '#sret.error.errorText#<br>' />
							</cfif>
							<!--- 
							<!--- use a function to grab the database table data and drop into an array to match the local version --->
							<cfset ret.data["#thisTable#"] = getSQLTableDataToArray(databaseName="#theDataBaseName#", CounterName="#theCounterName#", datasetName="#thisTable#").data />
							 --->
						</cfif>
					</cfloop>
				<cfelse>
					<!---  just one counter so grab it --->
						<cfset ret.data[theTableName] = StructNew() />
						<cfif variables.DataStores["#theDataBaseName#"].control.DataStoreMode eq "File">
							<cfset ret.data[theTableName] = variables.DataStores["#theDataBaseName#"].counters["#theCounterName#"]["#theTableName#"].data />
						<cfelseif variables.DataStores["#theDataBaseName#"].control.DataStoreMode eq "SQL">
							<!--- use a function to grab the database table data and drop into an array to match the local version --->
							<cfset sret = getSQLTableDataToArray(databaseName="#theDataBaseName#", counterName="#theCounterName#", DatasetName="#theTableName#") />
							<cfif sret.error.ErrorCode eq 0>
								<cfset ret.data["#theTableName#"] = sret.data />
							<cfelse>
								<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 2) />
								<cfset ret.error.ErrorText = ret.error.ErrorText & 'Oops! Error returned from getSQLTableDataToArray call. Error was:<br>' />
								<cfset ret.error.ErrorText = ret.error.ErrorText & '#sret.error.errorText#<br>' />
							</cfif>
							<!--- 
							<cfset ret.data[theTableName] = getSQLTableDataToArray(databaseName="#theDataBaseName#", counterName="#theCounterName#", DatasetName="#thisTable#").data />
							 --->
						</cfif>
				</cfif>
			</cfif>
		<cfcatch type="any">
			<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 128) />
			<cfset ret.error.ErrorText = ret.error.ErrorText & 'Oops! Error Caught, error message was: #cfcatch.message#, error detail was: #cfcatch.detail#<br>' />
			<cfset ret.error.ErrorExtra =  cfcatch.TagContext />
			<cflog text="getCounterTableData() structure read Trapped. ret.error.ErrorCode: #ret.error.ErrorCode# - Error Text: #ret.error.ErrorText# - Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#"  file="RRDBerrors" type="Error" application = "yes">
			<cfif application.SLCMS.Config.debug.debugmode>
				getCounterTableData() structure read Trapped - error dump:<br>
				<cfdump var="#ret.error.ErrorExtra#">
			</cfif>
		</cfcatch>
		</cftry>
	</cfif>

	<cfreturn ret  />
</cffunction>

<cffunction name="GetCounter" output="yes" returntype="struct" access="public"
	displayname="get a counter"
	hint="returns data in specified counter and tables"
				>
	<!--- this function needs.... --->
	<cfargument name="DatabaseName" type="string" default="" />	<!--- the name of the database --->
	<cfargument name="CounterName" type="string" default="" />	<!--- the name of the counter --->
	<cfargument name="TableName" type="string" default="" />	<!--- the name of the table --->

	<!--- now all of the var declarations, first the arguments which need manipulation --->
	<cfset var theDataBaseName = trim(arguments.DatabaseName) />
	<cfset var theDataBaseFileName = FileName_EnCode(theDataBaseName) />
	<cfset var theCounterName = trim(arguments.CounterName) />
	<cfset var theTableName = trim(arguments.TableName) />
	<!--- now vars that will get filled as we go --->
	<cfset var theCounterData = StructNew() />
	<cfset var theTableCount = 0 />
	<cfset var TablesToAddFlag = True />	<!--- temp loop control --->
	<cfset var theNextTable = "" />	<!--- just that when looping up thru tables --->
	<cfset var temps = StructNew() />	<!--- temp/throwaway var --->
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorText = "" />
	<cfset ret.Data = StructNew() />
	
	<!--- full error checking and validation and defaulting as this is the one that called by the outside world --->
	<cfif len(theDataBaseName)>
		<!--- wrap the whole thing in a try/catch in case something breaks despite all the checking above --->
		<cftry>
		<!--- make sure we have a database structure --->
		<cfset temps = ChecknSetDatabase(DatabaseName="#theDatabaseName#") />
		<cfif temps.error.ErrorCode eq 0>
			<cfif ListFindNoCase(variables.DataStoreFileNameList, "#theDataBaseFileName#") and StructKeyExists(variables.DataStores, "#theDatabaseName#")>
				<cfif variables.DataStores["#theDatabaseName#"].control.CounterCount eq 0>
					<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 2) />
					<cfset ret.error.ErrorText = ret.error.ErrorText & "There are no counters in the database<br>" />
				<cfelseif theCounterName eq "" and variables.DataStores["#theDatabaseName#"].control.CounterCount neq 1>
					<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 2) />
					<cfset ret.error.ErrorText = ret.error.ErrorText & "No Counter Name supplied and there is more than one counter<br>" />
				<cfelse>	<!--- good counter options --->
					<cfif theCounterName eq "">
						<!--- if no counter specified and only one in database then use that --->
						<cfset theCounterName = variables.DataStores["#theDatabaseName#"].control.CounterNameList />
					</cfif>
					<!--- we should now have a good counter but check again in case the last was broken --->
					<cfif structKeyExists(variables.DataStores["#theDatabaseName#"].counters, "#theCounterName#")>
						<cfif variables.DataStores["#theDatabaseName#"].counters["#theCounterName#"].control.TableCount eq 0>	<!--- make sure we have tables --->
							<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 4) />
							<cfset ret.error.ErrorText = ret.error.ErrorText & "There are no tables in the counter<br>" />
						<cfelseif theTableName eq "">	<!--- get all tables if none specified --->
							<cfset theTableName = variables.DataStores["#theDatabaseName#"].counters["#theCounterName#"].control.TableNameList />
						</cfif>
						<cfset theTableCount = ListLen(theTableName) />
					<cfelse>
						<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 2) />
						<cfset ret.error.ErrorText = ret.error.ErrorText & "The calculated counter structure with the name of:- #theCounterName# cannot be found<br>" />
					</cfif>	<!--- end: counter structure test --->
				</cfif>	<!--- end: counter naming --->
			<cfelse>	<!--- bad database --->
				<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 1) />
				<cfset ret.error.ErrorText = ret.error.ErrorText & "The DataStore with the short name of:- #theDatabaseName# cannot be found<br>" />
			</cfif>	<!--- end: good database structure --->
		<cfelseif temps.error.ErrorCode eq 1>
			<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 2) />
			<cfset ret.error.ErrorText = ret.error.ErrorText & "That DataStore with the short name of:- #theCleanDatabaseName# does not exist, must be a new name<br>" />
		<cfelse>
			<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 2) />
			<cfset ret.error.ErrorText = ret.error.ErrorText & "That DataStore with the short name of:- #theCleanDatabaseName# existed on disk but could not be read, error reported was: #temps.error.Errortext#<br>" />
		</cfif>
		<cfcatch type="any">
			<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 128) />
			<cfset ret.error.ErrorText = ret.error.ErrorText & 'Oops! Error Caught, error message was: #cfcatch.message#, error detail was: #cfcatch.detail#<br>' />
			<cfset ret.error.ErrorExtra =  cfcatch.TagContext />
			<cflog text="GetCounter() Counter Structure Finder Trapped. ret.error.ErrorCode: #ret.error.ErrorCode# - Error Text: #ret.error.ErrorText# - Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#"  file="RRDBerrors" type="Error" application = "yes">
			<cfif application.SLCMS.Config.debug.debugmode>
				GetCounter() Counter Structure Finder Trapped - error dump:<br>
				<cfdump var="#ret.error.ErrorExtra#">
			</cfif>
		</cfcatch>
		</cftry>
	<cfelse>	<!--- no database name --->
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 1) />
		<cfset ret.error.ErrorText = ret.error.ErrorText & "DataStore name not supplied or all invalid characters<br>" />
	</cfif>
	<cfif ret.error.ErrorCode eq 0>
		<!--- we should have a table set specified by now so get it --->
		<cftry>
			<!--- loop thru the specified tables, grab their sorted data and add to o/p structure --->
			<cfloop index="thisTable" list="#theTableName#">
				<cfset ret.Data["#thisTable#"] = StructNew() />
				<cfset ret.Data["#thisTable#"] = GetTableSet(TableName="#thisTable#", CounterName="#theCounterName#", CleanDatabaseName="#theDatabaseName#").data />
			</cfloop>
		<cfcatch type="any">
			<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 128) />
			<cfset ret.error.ErrorText = ret.error.ErrorText & 'Oops! Error Caught, error message was: #cfcatch.message#, error detail was: #cfcatch.detail#<br>' />
			<cfset ret.error.ErrorExtra =  cfcatch.TagContext />
			<cflog text="GetCounter() Counter data gather Trapped. ret.error.ErrorCode: #ret.error.ErrorCode# - Error Text: #ret.error.ErrorText# - Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#"  file="RRDBerrors" type="Error" application = "yes">
			<cfif application.SLCMS.Config.debug.debugmode>
				GetCounter() Counter data gather Trapped - error dump:<br>
				<cfdump var="#ret.error.ErrorExtra#">
			</cfif>
		</cfcatch>
		</cftry>
	</cfif>
	
	<cfreturn ret  />
</cffunction>

<!--- now we get the functions that shovel data in and out --->
<!--- this first one is the biggy where we add to counters --->
<cffunction name="AddToCounter" output="yes" returntype="struct" access="public"
	displayname="add to counter"
	hint="adds numbers to specified counter"
				>
	<!--- this function needs.... --->
	<cfargument name="DatabaseName" type="string" default="" />	<!--- the name of the database --->
	<cfargument name="CounterName" type="string" default="" />	<!--- the name of the counter --->
	<cfargument name="TableName" type="string" default="" />	<!--- the name of the table --->
	<cfargument name="Number" type="string" default="1" />	<!--- the number/value to add --->
	<cfargument name="CheckTime" type="any" default="" />	<!--- the time value for the addition, as a datetime object --->
	<cfargument name="SaveMode" type="string" default="" />	<!--- the way to save, Block or Incremental --->

	<!--- now all of the var declarations, first the arguments which need manipulation --->
	<cfset var theDataBaseName = trim(arguments.DatabaseName) />
	<cfset var theDataBaseFileName = FileName_EnCode(theDataBaseName) />
	<cfset var theCounterName = trim(arguments.CounterName) />
	<cfset var theTableName = trim(arguments.TableName) />
	<cfset var theNumberToAdd = trim(arguments.Number) />
	<cfset var theCheckTime = trim(arguments.CheckTime) />
	<cfset var theSaveMode = trim(arguments.SaveMode) />
	<!--- now vars that will get filled as we go --->
	<cfset var theSlotNumberData = StructNew() />
	<cfset var theSlotValue = StructNew() />
	<cfset var theNewSlotValue = 0 />
	<cfset var TablesToAddFlag = True />	<!--- temp loop control --->
	<cfset var theNextTable = "" />	<!--- just that when looping up thru tables --->
	<cfset var temp = "" />	<!--- temp/throwaway var --->
	<cfset var temps1 = StructNew() />	<!--- temp/throwaway var --->
	<cfset var temps2 = StructNew() />	<!--- temp/throwaway var --->
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorText = "" />
	<cfset ret.Data = 0 />
	
		<!--- full error checking and validation and defaulting as this is the one that called by the outside world --->
	<cfif len(theDataBaseName)>
		<cftry>
		<!--- make sure we know how to save this count --->
		<cfif variables.Global.DataSaveMode eq "Auto" and theSaveMode eq "">
			<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 1) />
			<cfset ret.error.ErrorText = ret.error.ErrorText & "No Save Mode supplied, it is required as default RRDS mode is 'Auto'<br>" />
		<cfelseif variables.Global.DataSaveMode eq "Auto" and theSaveMode neq "" and not (theSaveMode eq "Incremental" or theSaveMode eq "Block")>
			<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 1) />
			<cfset ret.error.ErrorText = ret.error.ErrorText & "Invalid Save Mode supplied, it was #theSaveMode#<br>" />
		</cfif>
		<!--- make sure we have a database structure --->
		<cfset temps = ChecknSetDatabase(DatabaseName="#theDatabaseName#") />
		<cfif temps.error.ErrorCode eq 0>
			<cfif ListFindNoCase(variables.DataStoreFileNameList, "#theDatabaseFileName#") and StructKeyExists(variables.DataStores, "#theDatabaseName#")>
				<cfif variables.DataStores["#theDatabaseName#"].control.CounterCount eq 0>
					<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 2) />
					<cfset ret.error.ErrorText = ret.error.ErrorText & "There are no counters in the database<br>" />
				<cfelseif theCounterName eq "" and variables.DataStores["#theDatabaseName#"].control.CounterCount neq 1>
					<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 2) />
					<cfset ret.error.ErrorText = ret.error.ErrorText & "No Counter Name supplied and there is more than one counter<br>" />
				<cfelse>	<!--- good counter options --->
					<cfif theCounterName eq "">
						<!--- if no counter specified and only one in database then use that --->
						<cfset theCounterName = variables.DataStores["#theDatabaseName#"].control.CounterNameList />
					</cfif>
					<!--- we should now have a good counter but check again in case the last was broken --->
					<cfif structKeyExists(variables.DataStores["#theDatabaseName#"].counters, "#theCounterName#")>
						<cfif variables.DataStores["#theDatabaseName#"].counters["#theCounterName#"].control.TableCount eq 0>	<!--- make sure we have tables --->
							<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 4) />
							<cfset ret.error.ErrorText = ret.error.ErrorText & "There are no tables in the counter<br>" />
						<cfelseif theTableName eq "">	<!--- get the lowest table if none specified --->
							<cfset theTableName = variables.DataStores["#theDatabaseName#"].counters["#theCounterName#"].control.OrderedTableNames[1] />
						</cfif>
						<cfif not IsNumeric(theNumberToAdd)>
							<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 8) />
							<cfset ret.error.ErrorText = ret.error.ErrorText & "The supplied number to add was not numeric<br>" />
						</cfif>
						<cfif theCheckTime eq "">
							<cfset theCheckTime = Now() />
						</cfif>
					<cfelse>
						<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 2) />
						<cfset ret.error.ErrorText = ret.error.ErrorText & "The calculated counter structure with the name of:- #theCounterName# cannot be found<br>" />
					</cfif>	<!--- end: counter structure test --->
				</cfif>	<!--- end: counter naming --->
			<cfelse>	<!--- bad database --->
				<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 1) />
				<cfset ret.error.ErrorText = ret.error.ErrorText & "The DataStore with the short name of:- #theDatabaseName# cannot be found<br>" />
			</cfif>	<!--- end: good database structure --->
		<cfelseif temps.error.ErrorCode eq 1>
			<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 2) />
			<cfset ret.error.ErrorText = ret.error.ErrorText & "That DataStore with the short name of:- #theDatabaseName# does not exist, must be a new name<br>" />
		<cfelse>
			<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 2) />
			<cfset ret.error.ErrorText = ret.error.ErrorText & "That DataStore with the short name of:- #theDatabaseName# existed on disk but could not be read, error reported was: #temps.error.Errortext#<br>" />
		</cfif>
		<cfcatch type="any">
			<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 128) />
			<cfset ret.error.ErrorText = ret.error.ErrorText & 'Oops! Error Caught, error message was: #cfcatch.message#, error detail was: #cfcatch.detail#<br>' />
			<cfset ret.error.ErrorExtra =  cfcatch.TagContext />
			<cflog text="AddToCounter() Counter Find error Trapped: database #theDatabaseName#; counter #theCounterName#. ret.error.ErrorCode: #ret.error.ErrorCode# - Error Text: #ret.error.ErrorText# - Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#"  file="RRDBerrors" type="Error" application = "yes">
			<cfif application.SLCMS.Config.debug.debugmode eq True>
				AddToCounter() Counter Find error Trapped - error dump:<br>
				<cfdump var="#ret.error.ErrorExtra#" />
			</cfif>
		</cfcatch>
		</cftry>
	<cfelse>	<!--- no database name --->
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 1) />
		<cfset ret.error.ErrorText = ret.error.ErrorText & "DataStore name not supplied or all invalid characters<br>" />
	</cfif>
	<cfif ret.error.ErrorCode eq 0>
		<!--- no errors so start doing meaningful work, error checking the whole way --->
		<!--- first set up how we are going to save the count, theSaveMode thinks it knows what we are doing --->
		<cfif variables.Global.DataSaveMode eq "Auto">
			<cfif theSaveMode eq "">
				<!--- none supplied so must be a legacy job so drop back to incremental --->
				<cfset theSaveMode = "Incremental">
			</cfif>
		<cfelse>
			<!--- the RRDS mode is not auto so make this save the configured mode --->
			<cfset theSaveMode = variables.Global.DataSaveMode>
		</cfif>
		<cftry>
		<cflock timeout="30" throwontimeout="Yes" name="AddToCounterLock" type="EXCLUSIVE">
		<!--- 
		<cflock timeout="20" throwontimeout="No" name="AddToCounter_#theDatabaseName#" type="EXCLUSIVE">
		 --->
			<!--- grab the current slot --->
			<cfset theSlotNumberData = CheckNsetCurrentSlot(SaveMode="#theSaveMode#", CheckTime="#theCheckTime#", TableName="#theTableName#", CounterName="#theCounterName#", CleanDatabaseName="#theDatabaseName#") />
			<cfif theSlotNumberData.error.ErrorCode eq 0>
				<cfif theSaveMode eq "Incremental">
					<!--- add the value into it --->
					<cfset theSlotValue = GetSlotvalue(SlotNumber="#theSlotNumberData.Data.CurrentSlotNumber#", TableName="#theTableName#", CounterName="#theCounterName#", CleanDatabaseName="#theDatabaseName#") />
				<cfelse>
					<!--- we are in block mode so we have the count locally but we need to emulate the above function return --->
					<cfset theSlotValue = StructNew() />
					<cfset theSlotValue.data = variables.DataStores["#theDatabaseName#"].counters["#theCounterName#"].BlockCounts["#theTableName#"] />
				</cfif>
					<!--- make sure we got a valid value back --->
				<cfif theSlotValue.data neq "" and IsNumeric(theSlotValue.data)>
					<cfset theNewSlotValue = theSlotValue.data + theNumberToAdd />
					<cfif theSaveMode eq "Incremental" or (theSaveMode eq "Block" and theSlotNumberData.data.SlotChangedFlag)>
						<!---  if we are incrmental just add it in but if block drop it in if we have rolled over --->
						<cfset temps1 = SetSlotValue(SlotValue="#theNewSlotValue#", SlotNumber="#theSlotNumberData.Data.CurrentSlotNumber#", TableName="#theTableName#", CounterName="#theCounterName#", CleanDatabaseName="#theDatabaseName#") />
					<cfelse>
						<!--- we are in block mode so we have the count locally but we need to emulate the above function return --->
						<cfset variables.DataStores["#theDatabaseName#"].counters["#theCounterName#"].BlockCounts["#theTableName#"] = theNewSlotValue />
					</cfif>
					<cfif temps1.error.ErrorCode eq 0>
						<!--- now we have updated the lowest slot see if we have to ripple upwards --->
						<cfif theSlotNumberData.data.SlotChangedFlag>	<!--- only ripple if this lowest table has changed slot --->
							<!--- get the value to add into higher table --->
							<cfif theSaveMode eq "Incremental">
								<cfset theNumberToAdd = GetSlotvalue(SlotNumber="#theSlotNumberData.Data.PreviousSlotNumber#", TableName="#theTableName#", CounterName="#theCounterName#", CleanDatabaseName="#theDatabaseName#").data />
							<cfelse>
								<!--- we are in block mode so we have the count locally --->
								<cfset theNumberToAdd = variables.DataStores["#theDatabaseName#"].counters["#theCounterName#"].BlockCounts["#theTableName#"] />
								<!--- then we need to reset this to zero for the next block --->
								<cfset variables.DataStores["#theDatabaseName#"].counters["#theCounterName#"].BlockCounts["#theTableName#"] = 0 />
							</cfif>
							<cfif theNumberToAdd neq "" and IsNumeric(theNumberToAdd)>
								<!--- then loop up adding this value in --->
								<cfset theNextTable = theTableName  />
								<cfloop condition="TablesToAddFlag eq True">
									<!--- get the next table to add to --->
									<cfset theNextTable = getNextCounterTable(CurrentTableName="#theNextTable#", CounterName="#theCounterName#", DatabaseName="#theDatabaseName#").data  />
									<cfif theNextTable neq "">
										<cfset theSlotNumberData = CheckNsetCurrentSlot(SaveMode="Incremental", CheckTime="#theCheckTime#", TableName="#theNextTable#", CounterName="#theCounterName#", CleanDatabaseName="#theDatabaseName#") />
									<!--- ToDo --->
									<!--- **** need to add error checking here **** --->
										<cfif theSlotNumberData.data.SlotChangedFlag>	<!--- if this table has changed slot as well we need to put this count in its previous slot --->
											<cfset theSlotValue = GetSlotvalue(SlotNumber="#theSlotNumberData.Data.PreviousSlotNumber#", TableName="#theNextTable#", CounterName="#theCounterName#", CleanDatabaseName="#theDatabaseName#").data />
											<cfif theSlotValue neq "" and IsNumeric(theSlotValue)>
												<cfset theSlotValue = theSlotValue + theNumberToAdd />
												<cfset temps2 = SetSlotValue(SlotValue="#theSlotValue#", SlotNumber="#theSlotNumberData.Data.PreviousSlotNumber#", TableName="#theNextTable#", CounterName="#theCounterName#", CleanDatabaseName="#theDatabaseName#") />
											</cfif>
										<cfelse>
											<!--- the next table up did npot roll over so just increment the count --->
											<cfset theSlotValue = GetSlotvalue(SlotNumber="#theSlotNumberData.Data.CurrentSlotNumber#", TableName="#theNextTable#", CounterName="#theCounterName#", CleanDatabaseName="#theDatabaseName#").data />
											<cfif theSlotValue neq "" and IsNumeric(theSlotValue)>
												<cfset theSlotValue = theSlotValue + theNumberToAdd />
												<cfset temps2 = SetSlotValue(SlotValue="#theSlotValue#", SlotNumber="#theSlotNumberData.Data.CurrentSlotNumber#", TableName="#theNextTable#", CounterName="#theCounterName#", CleanDatabaseName="#theDatabaseName#") />
											</cfif>
										</cfif>
									<cfelse>
										<cfset TablesToAddFlag = false />
									</cfif>
								</cfloop>
								<!--- we did a ripple update as the bottom one rolled over so save to disk --->
								<cfset temp = SaveDatabaseFile(DatabaseName="#theDatabaseName#")/>
							<cfelse>
								<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 64) />
								<cfset ret.error.ErrorText = ret.error.ErrorText & "Inside Slot value Get Failed<br>slot was: #theSlotNumberData.Data.PreviousSlotNumber#" />
							</cfif>	<!--- end: legitmate slot value returned --->
						</cfif>	<!--- end: slot changed test --->
					<cfelse>
						<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 32) />
						<cfset ret.error.ErrorText = ret.error.ErrorText & "Outside Slot value Set Failed<br>slot was: #theSlotNumberData.Data.CurrentSlotNumber#" />
					</cfif>	<!--- end: slot changed test --->
				<cfelse>
					<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 32) />
					<cfset ret.error.ErrorText = ret.error.ErrorText & "Outside Slot value Get Failed<br>slot was: #theSlotNumberData.Data.CurrentSlotNumber#" />
				</cfif>	<!--- end: legitmate slot value returned --->
			<cfelse>
				<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 16) />
				<cfset ret.error.ErrorText = ret.error.ErrorText & "Slot Position Updating Failed<br>error was: #theSlotNumberData.error.ErrorText#" />
			</cfif>	<!--- end: test for good slot checknsetcurrentslot return --->
		</cflock>	<!--- end: lock round store updates --->
		<cfcatch type="any">
			<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 128) />
			<cfset ret.error.ErrorText = ret.error.ErrorText & 'Oops! Error Caught, error message was: #cfcatch.message#, error detail was: #cfcatch.detail#<br>' />
			<cfset ret.error.ErrorExtra =  cfcatch.TagContext />
			<cflog text="AddToCounter() Counter Find error Trapped: database #theDatabaseName#; counter #theCounterName#. ret.error.ErrorCode: #ret.error.ErrorCode# - Error Text: #ret.error.ErrorText# - Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#"  file="RRDBerrors" type="Error" application = "yes">
			<cfif application.SLCMS.Config.debug.debugmode>
				AddToCounter() Counter insert error Trapped - error dump:<br>
				<cfdump var="#cfcatch#">
			</cfif>
		</cfcatch>
		</cftry>
	</cfif>
	
	<cfreturn ret  />
</cffunction>

<cffunction name="GetTableSet" output="yes" returntype="struct" access="private"
	displayname="get Entire Table"
	hint="returns the entire table in specified counter sorted into ascending time order"
				>
	<!--- this function needs.... --->
	<cfargument name="CleanDatabaseName" type="string" default="" />	<!--- the clean name of the database --->
	<cfargument name="CounterName" type="string" default="" />	<!--- the name of the counter --->
	<cfargument name="TableName" type="string" default="" />	<!--- the name of the table --->

	<!--- now all of the var declarations, first the arguments which need manipulation --->
	<cfset var theDataBaseName = trim(arguments.CleanDatabaseName) />
	<cfset var theCounterName = trim(arguments.CounterName) />
	<cfset var theTableName = trim(arguments.TableName) />
	<!--- temp internal vars --->
	<cfset var theTableSize = 0 />	<!--- the size of the table we have to loop over --->
	<cfset var theCurrentSlot = 0 />	<!--- where the external pointer is currently --->
	<cfset var theSlotPointer = 1 />	<!--- where our loop pointer is --->
	<cfset var tempdata = ArrayNew(2) />	<!--- temp array of data --->
	<cfset var sret = StructNew() />	<!--- temp struct for function call returns --->
	<cfset var lcntr = 0 />	<!--- temp loop counter --->
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorText = "" />
	<cfset ret.Data = ArrayNew(2) />
	
	<!--- minimal error checking, just make sure we have adequate data --->
	<cfif theDataBaseName neq "" and theCounterName neq "" and theTableName neq "">
	<cftry>
		<cfset theTableSize = variables.DataStores["#theDatabaseName#"].counters["#theCounterName#"]["#theTableName#"].control.TableSize />
		<cfset theCurrentSlot = variables.DataStores["#theDatabaseName#"].counters["#theCounterName#"]["#theTableName#"].control.CurrentSlot />
		<cfset theSlotPointer = theCurrentSlot+1 />	<!--- start one up from where we are now as that should be the oldest --->
		<cfif variables.DataStores["#theDataBaseName#"].control.DataStoreMode eq "File">
			<cfset tempdata = variables.DataStores["#theDatabaseName#"].counters["#theCounterName#"]["#theTableName#"].data />
		<cfelseif variables.DataStores["#theDataBaseName#"].control.DataStoreMode eq "SQL">
			<cfset sret = getSQLTableDataToArray(databaseName="#theDataBaseName#", counterName="#theCounterName#", DatasetName="#thisTable#") />
			<cfif sret.error.ErrorCode eq 0>
				<cfset tempdata = sret.data />
			<cfelse>
				<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 2) />
				<cfset ret.error.ErrorText = ret.error.ErrorText & 'Oops! Error returned from getSQLTableDataToArray call. Error was:<br>' />
				<cfset ret.error.ErrorText = ret.error.ErrorText & '#sret.error.errorText#<br>' />
			</cfif>
		</cfif>
		<cfloop index="lcntr" to="#theTableSize#" from="1">
			<!--- having incremented the slot number roll it over if we need to --->
			<cfif theSlotPointer gt theTableSize>
				<cfset theSlotPointer = 1 />
			</cfif>
			<cfset ret.Data[lcntr][1] = tempdata[theSlotPointer][1] />	<!--- the time stamp for the slot --->
			<cfset ret.Data[lcntr][2] = tempdata[theSlotPointer][2] />	<!--- the data for the slot --->
			<cfset theSlotPointer = theSlotPointer+1 />
		</cfloop>
		<cfcatch type="any">
			<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 128) />
			<cfset ret.error.ErrorText = ret.error.ErrorText & 'Oops! Error Caught, error message was: #cfcatch.message#, error detail was: #cfcatch.detail#<br>' />
			<cfset ret.error.ErrorExtra =  cfcatch.TagContext />
			<cflog text="GetTableSet() data gather error Trapped. theDatabaseName:#theDatabaseName# - theCounterName:#theCounterName# - theTableName:#theTableName# ret.error.ErrorCode: #ret.error.ErrorCode# - Error Text: #ret.error.ErrorText# - Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#"  file="RRDBerrors" type="Error" application = "yes">
			<cfif application.SLCMS.Config.debug.debugmode>
				GetTableSet() data gather error Trapped - error dump:<br>
				<cfdump var="#cfcatch#">
			</cfif>
		</cfcatch>
	</cftry>
	<cfelse>
		<!--- oops no meaningful counter table so return an empty array --->
		<cfset ret.error.ErrorCode = 1 />
		<cfset ret.error.ErrorText = "Invalid parameters: - DataBaseName - #theDataBaseName#; CounterName - #theCounterName#; TableName - #theTableName#" />
	</cfif>
	
	<cfreturn ret  />
</cffunction>

<cffunction name="GetSlotValue" output="yes" returntype="struct" access="private"
	displayname="gets number in Slot"
	hint="returns the number in specified slot in specified counter"
				>
	<!--- this function needs.... --->
	<cfargument name="CleanDatabaseName" type="string" default="" />	<!--- the name of the database --->
	<cfargument name="CounterName" type="string" default="" />	<!--- the name of the counter --->
	<cfargument name="TableName" type="string" default="" />	<!--- the name of the table --->
	<cfargument name="SlotNumber" type="string" default=0 />	<!--- the number of the slot --->
	<cfargument name="getSlotTimeStamp" type="string" default="No" />	<!--- optional: get the timestamp in the slot --->

	<!--- now all of the var declarations, first the arguments which need manipulation --->
	<cfset var theDataBaseName = trim(arguments.CleanDatabaseName) />
	<cfset var theCounterName = trim(arguments.CounterName) />
	<cfset var theTableName = trim(arguments.TableName) />
	<cfset var theSlotNumber = trim(arguments.SlotNumber) />
	<cfset var getSlotTime = trim(arguments.getSlotTimeStamp) />
	<!--- then local temp variables --->
	<cfset var getTableSlot = "" />	<!--- localise the query --->
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorText = "" />
	<cfset ret.Data = 0 />
	
	<!--- minimal error checking, just make sure we have adequate data --->
	<cfif theDataBaseName neq "" and theCounterName neq "" and theTableName neq "" and theSlotNumber gt 0>
	<cftry>
		<cfif variables.DataStores["#theDataBaseName#"].control.DataStoreMode eq "File">
			<cfset ret.Data = variables.DataStores["#theDatabaseName#"].counters["#theCounterName#"]["#theTableName#"].data[theSlotNumber][2] />
		<cfelseif variables.DataStores["#theDataBaseName#"].control.DataStoreMode eq "SQL">
			<cfquery name="getTableSlot" datasource="#variables.Global.DataSource#">
				Select  #theCounterName#_#theTableName#_Value as DataValue, #theCounterName#_#theTableName#_TimeStamp as DataTimeStamp
					From	[dbo].[RRDB_#theDataBaseName#_Tables]
					Where	Slot = #theSlotNumber#
			</cfquery>
			<cfif getSlotTime eq "yes">
				<!--- return as an array just like the local file data structure --->
				<cfset ret.Data = ArrayNew(1) />
				<cfset ret.Data[1] = getTableSlot.DataTimeStamp />
				<cfset ret.Data[2] = getTableSlot.DataValue />
			<cfelse>
				<cfset ret.Data = getTableSlot.DataValue />
			</cfif>
		</cfif>
		<cfcatch type="any">
			<cfset ret.Data = "" />
			<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 128) />
			<cfset ret.error.ErrorText = ret.error.ErrorText & 'Oops! Error Caught, error message was: #cfcatch.message#, error detail was: #cfcatch.detail#<br>' />
			<cfset ret.error.ErrorExtra =  cfcatch.TagContext />
			<cflog text="GetSlotValue() data gather error Trapped. DataBaseName - #theDataBaseName#; CounterName - #theCounterName#; TableName - #theTableName#; SlotNumber - #theSlotNumber# - Error Text: #ret.error.ErrorText# - Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#"  file="RRDBerrors" type="Error" application = "yes">
			<cfif application.SLCMS.Config.debug.debugmode>
				GetSlotValue() data gather error Trapped - error dump:<br>
				<cfdump var="#cfcatch#">
			</cfif>
		</cfcatch>
	</cftry>
	<cfelse>
		<!--- oops no meaningful counter so return nothing --->
		<cfset ret.error.ErrorCode = 1 />
		<cfset ret.error.ErrorText = "Invalid parameters: - DataBaseName - #theDataBaseName#; CounterName - #theCounterName#; TableName - #theTableName#; SlotNumber - #theSlotNumber#" />
	</cfif>
	
	<cfreturn ret  />
</cffunction>

<cffunction name="SetSlotvalue" output="yes" returntype="struct" access="private"
	displayname="sets number in Slot"
	hint="sets the number in specified slot in specified counter
				optionally updates the timestamp for this slot"
				>
	<!--- this function needs.... --->
	<cfargument name="CleanDatabaseName" type="string" default="" />	<!--- the name of the database --->
	<cfargument name="CounterName" type="string" default="" />	<!--- the name of the counter --->
	<cfargument name="TableName" type="string" default="" />	<!--- the name of the table --->
	<cfargument name="SlotNumber" type="string" default=0 />	<!--- the number of the slot --->
	<cfargument name="SlotValue" type="string" default=0 />	<!--- the number to put in the slot --->
	<cfargument name="SlotTimeStamp" type="any" default="" />	<!--- the timestamp to put in the slot --->
	<!--- now all of the var declarations, first the arguments which need manipulation --->
	<cfset var theDataBaseName = trim(arguments.CleanDatabaseName) />
	<cfset var theCounterName = trim(arguments.CounterName) />
	<cfset var theTableName = trim(arguments.TableName) />
	<cfset var theSlotNumber = trim(arguments.SlotNumber) />
	<cfset var theSlotValue = trim(arguments.SlotValue) />
	<cfset var theSlotTimeStamp = Now() />
	<!--- then local temp variables --->
	<cfset var setTableSlot = "" />	<!--- localise the query --->
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorText = "" />
	<cfset ret.Data = 0 />
	<!--- minimal error checking, just make sure we have adequate data --->
	<cfif arguments.SlotTimeStamp neq "">
		<cfset theSlotTimeStamp = CreateODBCDateTime(arguments.SlotTimeStamp) />
	</cfif>
	<cfif theDataBaseName neq "" and theCounterName neq "" and theTableName neq "" and theSlotNumber gt 0 and IsNumeric(theSlotValue)>
	<cftry>
		<cflock timeout="20" throwontimeout="No" name="DataStoreWork" type="exclusive">
			<cfif variables.DataStores["#theDataBaseName#"].control.DataStoreMode eq "File">
				<cfset variables.DataStores["#theDatabaseName#"].counters["#theCounterName#"]["#theTableName#"].data[theSlotNumber][2] = theSlotValue />
				<cfif len(theSlotTimeStamp)>
					<cfset variables.DataStores["#theDatabaseName#"].counters["#theCounterName#"]["#theTableName#"].data[theSlotNumber][1] = theSlotTimeStamp />
				</cfif>
			<cfelseif variables.DataStores["#theDataBaseName#"].control.DataStoreMode eq "SQL">
				<cfquery name="setTableSlot" datasource="#variables.Global.DataSource#">
					Update	[dbo].[RRDB_#theDataBaseName#_Tables]
						Set		#theCounterName#_#theTableName#_Value = #theSlotValue#
						<cfif len(arguments.SlotTimeStamp)>
									,	#theCounterName#_#theTableName#_TimeStamp = #theSlotTimeStamp#
						</cfif>
						Where	Slot = #theSlotNumber#
				</cfquery>
			</cfif>
		</cflock>
		<cfcatch type="any">
			<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 128) />
			<cfset ret.error.ErrorText = ret.error.ErrorText & 'Oops! Error Caught, error message was: #cfcatch.message#, error detail was: #cfcatch.detail#<br>' />
			<cfset ret.error.ErrorExtra =  cfcatch.TagContext />
			<cflog text="SetSlotValue() data insert error Trapped. DataBaseName - #theDataBaseName#; CounterName - #theCounterName#; TableName - #theTableName#; SlotNumber - #theSlotNumber#; SlotValue - #theSlotValue#; - Error Text: #ret.error.ErrorText# - Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#"  file="RRDBerrors" type="Error" application = "yes">
			<cfif application.SLCMS.Config.debug.debugmode>
				SetSlotValue() data insert error Trapped - error dump:<br>
				<cfdump var="#cfcatch#">
			</cfif>
		</cfcatch>
	</cftry>
	<cfelse>
		<!--- oops no meaningful counter so return nothing --->
		<cfset ret.error.ErrorCode = 1 />
		<cfset ret.error.ErrorText = "Bad values supplied. DataBaseName - #theDataBaseName#; CounterName - #theCounterName#; TableName - #theTableName#; SlotNumber - #theSlotNumber#; SlotValue - #theSlotValue#;" />
	</cfif>
	
	<cfreturn ret  />
</cffunction>

<cffunction name="AddSlotvalue" output="yes" returntype="struct" access="private"
	displayname="Adds a number to Slot"
	hint="adds the specified number/value to the existing number in specified slot in specified counter
				optionally updates the timestamp for this slot"
				>
	<!--- this function needs.... --->
	<cfargument name="CleanDatabaseName" type="string" default="" />	<!--- the name of the database --->
	<cfargument name="CounterName" type="string" default="" />	<!--- the name of the counter --->
	<cfargument name="TableName" type="string" default="" />	<!--- the name of the table --->
	<cfargument name="SlotNumber" type="string" default=0 />	<!--- the number of the slot --->
	<cfargument name="SlotValue" type="string" default=0 />	<!--- the number to add to the slot --->
	<cfargument name="SlotTimeStamp" type="string" default="" />	<!--- optional the timestamp to put in the slot --->
	<!--- now all of the var declarations, first the arguments which need manipulation --->
	<cfset var theDataBaseName = trim(arguments.CleanDatabaseName) />
	<cfset var theCounterName = trim(arguments.CounterName) />
	<cfset var theTableName = trim(arguments.TableName) />
	<cfset var theSlotNumber = trim(arguments.SlotNumber) />
	<cfset var theSlotValue = trim(arguments.SlotValue) />
	<cfset var theSlotTimeStamp = trim(arguments.SlotTimeStamp) />
	<!--- then local temp variables --->
	<cfset var setTableSlot = "" />	<!--- localise the query --->
	<cfset var setString = "" />	<!--- localise the query strings --->
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorText = "" />
	<cfset ret.Data = 0 />
	<!--- minimal error checking, just make sure we have adequate data --->
	<cfif theDataBaseName neq "" and theCounterName neq "" and theTableName neq "" and theSlotNumber gt 0 and IsNumeric(theSlotValue)>
	<cftry>
		<cflock timeout="20" throwontimeout="No" name="DataStoreWork" type="exclusive">
			<cfif variables.DataStores["#theDataBaseName#"].control.DataStoreMode eq "File">
				<cfset variables.DataStores["#theDatabaseName#"].counters["#theCounterName#"]["#theTableName#"].data[theSlotNumber][2] = theSlotValue + variables.DataStores["#theDatabaseName#"].counters["#theCounterName#"]["#theTableName#"].data[theSlotNumber][2] />
				<!--- update the timestamp if we need to --->
				<cfif len(theSlotTimeStamp)>
					<cfset variables.DataStores["#theDatabaseName#"].counters["#theCounterName#"]["#theTableName#"].data[theSlotNumber][1] = theSlotTimeStamp />
				</cfif>
			<cfelseif variables.DataStores["#theDataBaseName#"].control.DataStoreMode eq "SQL">
				<cfset setString = "#theCounterName#_#theTableName#_Value = #theCounterName#_#theTableName#_Value+#theSlotValue#" />
				<cfif len(theSlotTimeStamp)>
					<cfset setString = setString & ",	#theCounterName#_#theTableName#_TimeStamp = #theSlotTimeStamp#" />
				</cfif>
				<cfquery name="setTableSlot" datasource="#variables.Global.DataSource#">
					Update	[dbo].[RRDB_#theDataBaseName#_Tables]
						Set		#setString#
						Where	Slot = #theSlotNumber#
				</cfquery>
			</cfif>
		</cflock>
		<cfcatch type="any">
			<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 128) />
			<cfset ret.error.ErrorText = ret.error.ErrorText & 'Oops! Error Caught, error message was: #cfcatch.message#, error detail was: #cfcatch.detail#<br>' />
			<cfset ret.error.ErrorExtra =  cfcatch.TagContext />
			<cflog text="SetSlotValue() data insert error Trapped. DataBaseName - #theDataBaseName#; CounterName - #theCounterName#; TableName - #theTableName#; SlotNumber - #theSlotNumber#; SlotValue - #theSlotValue#; - Error Text: #ret.error.ErrorText# - Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#"  file="RRDBerrors" type="Error" application = "yes">
			<cfif application.SLCMS.Config.debug.debugmode>
				SetSlotValue() data insert error Trapped - error dump:<br>
				<cfdump var="#cfcatch#">
			</cfif>
		</cfcatch>
	</cftry>
	<cfelse>
		<!--- oops no meaningful counter so return nothing --->
		<cfset ret.error.ErrorCode = 1 />
		<cfset ret.error.ErrorText = "Bad values supplied. DataBaseName - #theDataBaseName#; CounterName - #theCounterName#; TableName - #theTableName#; SlotNumber - #theSlotNumber#; SlotValue - #theSlotValue#;" />
	</cfif>
	
	<cfreturn ret  />
</cffunction>

<cffunction name="AddCustomItem" output="yes" returntype="struct" access="public"
	displayname="Add a Custom Item"
	hint="add an entry to the custom fields section in the specified database, can be anything, any data type"
				>
	<!--- this function needs.... --->
	<cfargument name="DatabaseName" type="string" default="" />	<!--- the name of the database --->
	<cfargument name="ItemName" type="string" default="" />	<!--- the name of the item/entry --->
	<cfargument name="ItemValue" type="any" default="" />	<!--- the value of the item/entry --->

	<!--- now all of the var declarations, first the arguments which need manipulation --->
	<cfset var theDataBaseName = trim(arguments.DatabaseName) />
	<cfset var theCustomItemName = trim(arguments.ItemName) />
	<cfset var theCustomItemValue = arguments.ItemValue />
	<!--- now vars that will get filled as we go --->
	<cfset var lcntr = 0 />	<!--- temp loop counter --->
	<cfset var temp = "" />	<!--- temp/throwaway var --->
	<cfset var temps = StructNew() />	<!--- temp/throwaway var --->
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorText = "" />
	<cfset ret.Data = "" />

	<cfif len(theDataBaseName)>
		<!--- make sure we have a database structure --->
		<cfset temps = ChecknSetDatabase(DatabaseName="#theDatabaseName#") />
		<cfif temps.error.ErrorCode eq 0>
			<!--- subsiduary test here if needed --->
		<cfelseif temps.error.ErrorCode eq 1>
			<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 2) />
			<cfset ret.error.ErrorText = ret.error.ErrorText & "That DataStore with the name of:- #theDatabaseName# does not exist, must be a new name<br>" />
		<cfelse>
			<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 2) />
			<cfset ret.error.ErrorText = ret.error.ErrorText & "That DataStore with the name of:- #theDatabaseName# existed on disk but could not be read, error reported was: #temps.error.Errortext#<br>" />
		</cfif>
		<cfif ListFindNoCase(variables.DataStoreFileNameList, "#theDatabaseName#") and StructKeyExists(variables.DataStores, "#theDatabaseName#")>
			<!--- we have a database of that name so shove a custom entry in --->
			<cftry>
				<cfset variables.DataStores["#theDatabaseName#"].custom["#theCustomItemName#"] = theCustomItemValue />
				<cfcatch type="any">
					<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 128) />
					<cfset ret.error.ErrorText = ret.error.ErrorText & "The insertion failed, error was: <cfdump var='#cfcatch#'><br>" />
					<cfset ret.error.ErrorExtra =  cfcatch.TagContext />
					<cflog text="AddCustomItem() data insert error Trapped. ret.error.ErrorCode: #ret.error.ErrorCode# - Error Text: #ret.error.ErrorText# - Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#"  file="RRDBerrors" type="Error" application = "yes">
					<cfif application.SLCMS.Config.debug.debugmode>
						AddCustomItem() data insert error Trapped - error dump:<br>
						<cfdump var="#ret.error.ErrorExtra#">
					</cfif>
				</cfcatch>
			</cftry>
		<cfelse>
			<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 2) />
			<cfset ret.error.ErrorText = ret.error.ErrorText & "The named database does not exist<br>" />
		</cfif>
	<cfelse>
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 1) />
		<cfset ret.error.ErrorText = ret.error.ErrorText & "No Database Name supplied.<br>" />
	</cfif>

	<cfreturn ret  />
</cffunction>

<cffunction name="GetCustomItem" output="yes" returntype="struct" access="public"
	displayname="Gets a Custom Item"
	hint="Gets an entry to the custom fields section in the specified database, can be anything, any data type"
				>
	<!--- this function needs.... --->
	<cfargument name="DatabaseName" type="string" default="" />	<!--- the name of the database --->
	<cfargument name="ItemName" type="string" default="" />	<!--- the name of the item/entry --->

	<!--- now all of the var declarations, first the arguments which need manipulation --->
	<cfset var theDataBaseName = trim(arguments.DatabaseName) />
	<cfset var theCustomItemName = trim(arguments.ItemName) />
	<!--- now vars that will get filled as we go --->
	<cfset var lcntr = 0 />	<!--- temp loop counter --->
	<cfset var temp = "" />	<!--- temp/throwaway var --->
	<cfset var temps = StructNew() />	<!--- temp/throwaway var --->
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorText = "" />
	<cfset ret.Data = "" />

	<cfif len(theDataBaseName)>
		<!--- make sure we have a database structure --->
		<cfset temps = ChecknSetDatabase(DatabaseName="#theDatabaseName#") />
		<cfif temps.error.ErrorCode eq 0>
			<!--- subsiduary test here if needed --->
		<cfelseif temps.error.ErrorCode eq 1>
			<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 2) />
			<cfset ret.error.ErrorText = ret.error.ErrorText & "That DataStore with the name of:- #theDatabaseName# does not exist, must be a new name<br>" />
		<cfelse>
			<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 2) />
			<cfset ret.error.ErrorText = ret.error.ErrorText & "That DataStore with the name of:- #theDatabaseName# existed on disk but could not be read, error reported was: #temps.error.Errortext#<br>" />
		</cfif>
		<cfif ListFindNoCase(variables.DataStoreFileNameList, "#theDatabaseName#") and StructKeyExists(variables.DataStores, "#theDatabaseName#") and StructKeyExists(variables.DataStores["#theDatabaseName#"], "#theCustomItemName#")>
			<!--- we have a database of that name so grab the spcified custom entry --->
			<cftry>
				<cfset ret.Data = variables.DataStores["#theDatabaseName#"].custom["#theCustomItemName#"] />
				<cfcatch type="any">
					<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 128) />
					<cfset ret.error.ErrorText = ret.error.ErrorText & 'Oops! Error Caught, error message was: #cfcatch.message#, error detail was: #cfcatch.detail#<br>' />
					<cfset ret.error.ErrorExtra =  cfcatch.TagContext />
					<cflog text="GetCustomItem() data get error Trapped. ret.error.ErrorCode: #ret.error.ErrorCode# - Error Text: #ret.error.ErrorText# - Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#"  file="RRDBerrors" type="Error" application = "yes">
					<cfif application.SLCMS.Config.debug.debugmode>
						GetCustomItem() data get error Trapped - error dump:<br>
						<cfdump var="#ret.error.ErrorExtra#">
					</cfif>
				</cfcatch>
			</cftry>
		<cfelse>
			<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 2) />
			<cfset ret.error.ErrorText = ret.error.ErrorText & "The named database and/or custom entry does not exist<br>" />
		</cfif>
	<cfelse>
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 1) />
		<cfset ret.error.ErrorText = ret.error.ErrorText & "No Database Name supplied.<br>" />
	</cfif>

	<cfreturn ret  />
</cffunction>

<cffunction name="getSQLTableDataToArray" output="yes" returntype="struct" access="public"
	displayname="getSQLTableDataToArray"
	hint="gets the SQL Table Dataset and puts into an Array to match the local structure"
				>
	<!--- this function needs.... --->
	<cfargument name="DatabaseName" type="string" default="" />	<!--- the name of the database --->
	<cfargument name="CounterName" type="string" default="" />	<!--- the name of the database --->
	<cfargument name="DatasetName" type="string" default="" />	<!--- the name of the database --->

	<!--- now all of the var declarations, first the arguments which need manipulation --->
	<cfset var theDataBaseName = trim(arguments.DatabaseName) />
	<cfset var thecounterName = trim(arguments.counterName) />
	<cfset var thetableName = trim(arguments.DatasetName) />
	<!--- now vars that will get filled as we go --->
	<cfset var lcntr = 0 />	<!--- temp loop counter --->
	<cfset var getTableData = "" />	<!--- localise the query --->
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorText = "TheFunctionName()<br>" />
	<cfset ret.Data = ArrayNew(2) />
	
	<cftry>	<!--- error handle the whole thing in case --->
		<!--- validate the incoming stuff --->
		
		<cfif len(theDataBaseName) and len(thecounterName) and len(thetableName)>
			<!--- its OK so do stuff --->
			<!--- wrap the relevant bits of code down in the works in a try/catch in case something breaks despite all the checking above --->
			<cftry>
				<!--- grab the data for this 'table' --->
				<cfquery name="getTableData" datasource="#variables.Global.DataSource#">
					Select  Slot, #theCounterName#_#theTableName#_Value as DataValue, #theCounterName#_#theTableName#_TimeStamp as DataTimeStamp
						From	[dbo].[RRDB_#theDataBaseName#_Tables]
						Order by Slot
				</cfquery>
				<!--- and make it into an array --->
				<cfloop query="getTableData">
					<cfset ret.Data[getTableData.slot][1] = getTableData.DataTimeStamp />
					<cfset ret.Data[getTableData.slot][2] = getTableData.DataValue />
				</cfloop>
			<cfcatch type="any">
				<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 128) />
				<cfset ret.error.ErrorText = ret.error.ErrorText & 'Oops! Error Caught, error message was: #cfcatch.message#, error detail was: #cfcatch.detail#<br>' />
				<cfset ret.error.ErrorExtra =  cfcatch.TagContext />
				<cflog text="emptyFunction() unhandled error Trapped. ret.error.ErrorCode: #ret.error.ErrorCode# - Error Text: #ret.error.ErrorText# - Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#"  file="RRDBerrors" type="Error" application = "yes">
				<cfif application.SLCMS.Config.debug.debugmode>
					emptyFunction() unhandled error Trapped - error dump:<br>
					<cfdump var="#ret.error.ErrorExtra#">
				</cfif>
			</cfcatch>
			</cftry>
		<cfelse>
			<!--- oops no meaningful parameters so return nothing --->
			<cfset ret.error.ErrorCode = 1 />
			<cfset ret.error.ErrorText = "Invalid parameters: - DataBaseName - #theDataBaseName#; CounterName - #theCounterName#; TableName - #theTableName#" />
		</cfif> <!--- end: incoming parameters validation check --->
	<cfcatch type="any">
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 128) />
		<cfset ret.error.ErrorText = ret.error.ErrorText & 'Oops! Error Caught, error message was: #cfcatch.message#, error detail was: #cfcatch.detail#<br>' />
		<cfset ret.error.ErrorExtra =  cfcatch.TagContext />
		<cflog text="emptyFunction() unhandled error Trapped. ret.error.ErrorCode: #ret.error.ErrorCode# - Error Text: #ret.error.ErrorText# - Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#"  file="RRDBerrors" type="Error" application = "yes">
		<cfif application.SLCMS.Config.debug.debugmode>
			emptyFunction() unhandled error Trapped - error dump:<br>
			<cfdump var="#ret.error.ErrorExtra#">
		</cfif>
	</cfcatch>
	</cftry>

	<cfreturn ret  />
</cffunction>

<cffunction name="DeleteCustomItem" output="yes" returntype="struct" access="public"
	displayname="Delete a Custom Item"
	hint="Removes an entry to the custom fields section in the specified database"
				>
	<!--- this function needs.... --->
	<cfargument name="DatabaseName" type="string" default="" />	<!--- the name of the database --->
	<cfargument name="ItemName" type="string" default="" />	<!--- the name of the item/entry --->

	<!--- now all of the var declarations, first the arguments which need manipulation --->
	<cfset var theDataBaseName = trim(arguments.DatabaseName) />
	<cfset var theCustomItemName = trim(arguments.ItemName) />
	<!--- now vars that will get filled as we go --->
	<cfset var lcntr = 0 />	<!--- temp loop counter --->
	<cfset var temp = "" />	<!--- temp/throwaway var --->
	<cfset var temps = StructNew() />	<!--- temp/throwaway var --->
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorText = "" />
	<cfset ret.Data = "" />

	<cfif len(theDataBaseName)>
		<!--- make sure we have a database structure --->
		<cfset temps = ChecknSetDatabase(DatabaseName="#theDatabaseName#") />
		<cfif temps.error.ErrorCode eq 0>
			<!--- subsiduary test here if needed --->
		<cfelseif temps.error.ErrorCode eq 1>
			<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 2) />
			<cfset ret.error.ErrorText = ret.error.ErrorText & "That DataStore with the name of:- #theDatabaseName# does not exist, must be a new name<br>" />
		<cfelse>
			<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 2) />
			<cfset ret.error.ErrorText = ret.error.ErrorText & "That DataStore with the name of:- #theDatabaseName# existed on disk but could not be read, error reported was: #temps.error.Errortext#<br>" />
		</cfif>
		<cfif ListFindNoCase(variables.DataStoreFileNameList, "#theDatabaseName#") and StructKeyExists(variables.DataStores, "#theDatabaseName#") and StructKeyExists(variables.DataStores["#theDatabaseName#"], "#theCustomItemName#")>
			<!--- we have a database of that name so grab the spcified custom entry --->
			<cftry>
				<cfset ret.Data = StructDelete(variables.DataStores["#theDatabaseName#"].custom, "#theCustomItemName#", true)> />
				<cfcatch type="any">
					<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 128) />
					<cfset ret.error.ErrorText = ret.error.ErrorText & 'Oops! Error Caught, error message was: #cfcatch.message#, error detail was: #cfcatch.detail#<br>' />
					<cfset ret.error.ErrorExtra =  cfcatch.TagContext />
					<cflog text="DeleteCustomItem() data delete error Trapped. ret.error.ErrorCode: #ret.error.ErrorCode# - Error Text: #ret.error.ErrorText# - Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#"  file="RRDBerrors" type="Error" application = "yes">
					<cfif application.SLCMS.Config.debug.debugmode>
						DeleteCustomItem() data delete error Trapped - error dump:<br>
						<cfdump var="#ret.error.ErrorExtra#">
					</cfif>
				</cfcatch>
			</cftry>
		<cfelse>
			<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 2) />
			<cfset ret.error.ErrorText = ret.error.ErrorText & "The named database and/or custom entry does not exist<br>" />
		</cfif>
	<cfelse>
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 1) />
		<cfset ret.error.ErrorText = ret.error.ErrorText & "No Database Name supplied.<br>" />
	</cfif>

	<cfreturn ret  />
</cffunction>

<cffunction name="CheckNsetCurrentSlot" output="yes" returntype="struct" access="public"
	displayname="Checks and Sets Current Slot Number"
	hint="Compares current slot number and time and updates if this table's interval has passed 
				then returns the current slot number. 
				Flags if slot was changed and if so returns the number of the previous slot (or zero if not changed)"
				>
	<!--- this function needs.... --->
	<cfargument name="CleanDatabaseName" type="string" default="" />	<!--- the clean name of the database --->
	<cfargument name="CounterName" type="string" default="" />	<!--- the name of the counter in the specified database --->
	<cfargument name="TableName" type="string" default="" />	<!--- the name of the table in the specified counter in the specified database --->
	<cfargument name="CheckTime" type="any" default="" />	<!--- the time value for the check as a datetime object --->
	<cfargument name="SaveMode" type="string" default="" />	<!--- the mode we are running, #incremental# does full checks, "Block" always pops to next slot --->

	<!--- now all of the var declarations, first the arguments which need manipulation --->
	<cfset var theDataBaseName = trim(arguments.CleanDatabaseName) />
	<cfset var theCounterName = trim(arguments.CounterName) />
	<cfset var theTableName = trim(arguments.TableName) />
	<cfset var theCheckTime = trim(arguments.CheckTime) />
	<cfset var theSaveMode = trim(arguments.SaveMode) />
	<!--- now vars that will get filled as we go --->
	<cfset var theFirstSlot = 0 />	<!--- carries the slot number b4 we manipulate anything --->
	<cfset var thisSlot = 0 />	<!--- temp slot number in fixerupperers --->
	<cfset var theFirstTime = 0 />	<!--- carries the time of the above slot --->
	<cfset var theInterval = 0 />	<!--- carries the interval for this table --->
	<cfset var theFillValue = 0 />	<!--- carries the fill value for this table --->
	<cfset var theTimeGap = 0 />	<!--- carries the difference between now and the time of the current,first slot --->
	<cfset var theSlotGap = 0 />	<!--- carries the number of slots that equates to theTimeGap --->
	<cfset var SlotNumberTemp = 0 />	<!--- temp/throwaway var --->
	<cfset var SlotTimeTemp = "" />	<!--- temp/throwaway var --->
	<cfset var lcntr = 0 />	<!--- temp loop counter --->
	<cfset var temps = StructNew() />
	<cfset var retemps = StructNew() />
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorText = "" />
	<cfset ret.Data = StructNew() />
	<cfset ret.Data.SlotChangedFlag = False />
	<cfset ret.Data.CurrentSlotNumber = 0 />
	<cfset ret.Data.PreviousSlotNumber = 0 />

	<!--- minimal error checking just do stuff --->
	<cfif theCheckTime eq "">
		<cfset theCheckTime = Now() />
	</cfif>
	<!--- make sure we have a database structure --->
	<cfset temps = ChecknSetDatabase(DatabaseName="#theDatabaseName#") />
	<cfif temps.error.ErrorCode eq 0>
		<cfif theDataBaseName neq "" and theCounterName neq "" and theTableName neq "">
			<!--- we have params so grab the current slot, see if its still current, time-wise and wind up if its not --->
			<cflock timeout="20" throwontimeout="No" name="CheckNsetCurrentSlot_#theDatabaseName#" type="EXCLUSIVE">
				<cftry>
				<cfset theInterval = variables.DataStores["#theDatabaseName#"].counters["#theCounterName#"]["#theTableName#"].control.Interval />
				<cfset theFillValue = variables.DataStores["#theDatabaseName#"].counters["#theCounterName#"]["#theTableName#"].control.FillValue />
				<!--- get the current slot, see if its still current, time-wise --->
				<cfset theFirstSlot = variables.DataStores["#theDatabaseName#"].counters["#theCounterName#"]["#theTableName#"].control.CurrentSlot />
				<cfif variables.DataStores["#theDataBaseName#"].control.DataStoreMode eq "File">
					<cftry>
						<cfset theFirstTime = variables.DataStores["#theDatabaseName#"].counters["#theCounterName#"]["#theTableName#"].data[theFirstSlot][1] />
					<cfcatch type="any">
						<!--- we have a corrupt array item so fix it, 
									first find the previous slot and time, add our interval to get a now time and then treat as a blank one and refill --->
						<cftry>
							<cfif theFirstSlot gt 1>
								<cfset theFirstTime = variables.DataStores["#theDatabaseName#"].counters["#theCounterName#"]["#theTableName#"].data[theFirstSlot-1][1] />
							<cfelseif theFirstSlot eq 1>	<!--- roll it backwards if at the bottom --->
								<cfset theFirstTime = variables.DataStores["#theDatabaseName#"].counters["#theCounterName#"]["#theTableName#"].data[variables.DataStores["#theDatabaseName#"].counters["#theCounterName#"]["#theTableName#"].control.TableSize][1] />
							<cfelse>
								<cfset theFirstTime = Now() />
							</cfif>
						<cfcatch type="any">
							<!---  the previous broken as well?, its really stuffed, just go for now().... --->
							<cfset theFirstTime = Now() />
							<cflog text="CheckNsetCurrentSlot() Array Failure Trapped, inner fix. theDatabaseName:#theDatabaseName# - theCounterName:#theCounterName# - theTableName:#theTableName# - theFirstSlot:#theFirstSlot#"  file="RRDBarrayFailureFix" type="Error" application = "yes">
						</cfcatch>
						</cftry>
						<cfset theFirstTime = DateAdd("n", theInterval, theFirstTime) />	<!--- increment the time by our interval --->
						<cflock timeout="20" throwontimeout="No" name="DataStoreWork" type="EXCLUSIVE">
							<cfset thisSlot = theFirstSlot />
							<cfset variables.DataStores["#theDatabaseName#"].counters["#theCounterName#"]["#theTableName#"].data[thisSlot] = arrayNew(1) />
							<cfset variables.DataStores["#theDatabaseName#"].counters["#theCounterName#"]["#theTableName#"].data[theFirstSlot][1] = theFirstTime />
							<cfset variables.DataStores["#theDatabaseName#"].counters["#theCounterName#"]["#theTableName#"].data[theFirstSlot][2] = theFillValue />
						</cflock>
						<cflog text="CheckNsetCurrentSlot() Array Failure Trapped, outer fix. theDatabaseName:#theDatabaseName# - theCounterName:#theCounterName# - theTableName:#theTableName# - theFirstSlot:#theFirstSlot#"  file="RRDBarrayFailureFix" type="Error" application = "yes">
					</cfcatch>
					</cftry>
				<cfelseif variables.DataStores["#theDataBaseName#"].control.DataStoreMode eq "SQL">
					<cfset retemps = 	GetSlotvalue(getSlotTimeStamp= "yes", SlotNumber="#theFirstSlot#", TableName="#theTableName#", CounterName="#theCounterName#", CleanDatabaseName="#theDatabaseName#") />
					<cfif retemps.error.errorcode eq 0>
						<cfset theFirstTime = retemps.data[1] />
					<cfelse>
						<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 8) />
						<cfset ret.error.ErrorText = ret.error.ErrorText & 'Oops! GetSlotvalue() Failed , error message was: #retemps.error.errortext#<br>' />
					</cfif>
				</cfif>
				<!---  we now have a valid time for the starting slot --->				
				<cfif theFirstTime eq 0 or theFirstTime eq "">
					<!--- we don't have a time for this slot, its a newbie, so make it now and "empty" --->
					<cfset theFirstTime = Now() />
					<cfset retemps = 	SetSlotvalue(SlotTimeStamp= "#theFirstTime#", SlotValue="#theFillValue#", SlotNumber="#theFirstSlot#", TableName="#theTableName#", CounterName="#theCounterName#", CleanDatabaseName="#theDatabaseName#") />
					<cfif retemps.error.errorcode neq 0>
						<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 8) />
						<cfset ret.error.ErrorText = ret.error.ErrorText & 'Oops! SetSlotvalue() Failed , error message was: #retemps.error.errortext#<br>' />
					</cfif>
				</cfif>
				<!--- now see if we need to move to the next slot --->
				<cfset theTimeGap = DateDiff("n", theFirstTime, theCheckTime) />	<!--- this will be the difference in minutes --->
				<cfif theTimeGap lte theInterval>
					<!--- its less than interval so just feed out this slot --->
					<cfset ret.Data.CurrentSlotNumber = theFirstSlot />
					<!--- and return --->
				<cfelse>
					<!--- more than one slot so lock it up and fill to there --->
					<cflock timeout="20" throwontimeout="No" name="DataStoreWork" type="EXCLUSIVE">
						<!--- its more than the interval so see by how much --->
						<cfset theSlotGap = theTimeGap\theInterval />
						<!--- and wind up to that slot, filling with the fill value as we go --->
						<cfset SlotTimeTemp = theFirstTime />	<!--- get our starting time --->
						<cfset SlotNumberTemp = theFirstSlot />	<!--- and the starting slot number --->
						<cfloop to="#theSlotGap#" from="1" index="lcntr">
							<cfset SlotTimeTemp = DateAdd("n", theInterval, SlotTimeTemp) />	<!--- increment the time by our interval --->
							<cfset SlotNumberTemp = SlotNumberTemp+1 />
							<!--- having incremented the slot number roll it over if we need to --->
							<cfif SlotNumberTemp gt variables.DataStores["#theDatabaseName#"].counters["#theCounterName#"]["#theTableName#"].control.TableSize>
								<cfset SlotNumberTemp = 1 />
							</cfif>
							<cfset variables.DataStores["#theDatabaseName#"].counters["#theCounterName#"]["#theTableName#"].control.CurrentSlot = SlotNumberTemp />
							<cfset retemps = SetSlotvalue(SlotTimeStamp= "#SlotTimeTemp#", SlotValue="#theFillValue#", SlotNumber="#SlotNumberTemp#", TableName="#theTableName#", CounterName="#theCounterName#", CleanDatabaseName="#theDatabaseName#") />
							<cfif retemps.error.errorcode neq 0>
								<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 16) />
								<cfset ret.error.ErrorText = ret.error.ErrorText & 'Oops! SetSlotvalue() Failed when filling to new slot, error message was: #retemps.error.errortext#<br>' />
							</cfif>
							<!--- 
							<cfset variables.DataStores["#theDatabaseName#"].counters["#theCounterName#"]["#theTableName#"].Data[SlotNumberTemp] = arrayNew(1) />
							<cfset variables.DataStores["#theDatabaseName#"].counters["#theCounterName#"]["#theTableName#"].Data[SlotNumberTemp][1] = SlotTimeTemp />
							<cfset variables.DataStores["#theDatabaseName#"].counters["#theCounterName#"]["#theTableName#"].Data[SlotNumberTemp][2] = theFillValue />
							 --->
							<cfif ret.error.ErrorCode neq 0>
								<cfbreak>
							</cfif>
						</cfloop>
						<!--- now we have filled up to the new current slot return the slot numbers as requested --->
						<cfset ret.Data.CurrentSlotNumber = SlotNumberTemp />
						<cfset ret.Data.PreviousSlotNumber = theFirstSlot />
						<cfset ret.Data.SlotChangedFlag = True />
					</cflock>
				</cfif>
				<cfcatch type="any">
					<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 128) />
					<cfset ret.error.ErrorText = ret.error.ErrorText & 'Oops! Error Caught, error message was: #cfcatch.message#, error detail was: #cfcatch.detail#<br>' />
					<cfset ret.error.ErrorExtra =  cfcatch.TagContext />
					<cflog text="CheckNsetCurrentSlot() error Trapped. theDatabaseName:#theDatabaseName# - theCounterName:#theCounterName# - theTableName:#theTableName# - FirstSlot:#theFirstSlot# - SlotNumberTemp:#SlotNumberTemp# - ret.error.ErrorCode: #ret.error.ErrorCode# - Error Text: #ret.error.ErrorText# - Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#"  file="RRDBerrors" type="Error" application = "yes">
					<cfif application.SLCMS.Config.debug.debugmode>
						CheckNsetCurrentSlot() error Trapped - error dump:<br>
						<cfdump var="#cfcatch#">
					</cfif>
				</cfcatch>
			</cftry>
			</cflock>
		<cfelse>
			<!--- oops no meaningful parameters so return nothing --->
			<cfset ret.error.ErrorCode = 1 />
			<cfset ret.error.ErrorText = "Invalid parameters: - DataBaseName - #theDataBaseName#; CounterName - #theCounterName#; TableName - #theTableName#" />
		</cfif>
	<cfelseif temps.error.ErrorCode eq 1>
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 2) />
		<cfset ret.error.ErrorText = ret.error.ErrorText & "That DataStore with the short name of:- #theCleanDatabaseName# does not exist, must be a new name<br>" />
	<cfelse>
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 2) />
		<cfset ret.error.ErrorText = ret.error.ErrorText & "That DataStore with the short name of:- #theCleanDatabaseName# existed on disk but could not be read, error reported was: #temps.error.Errortext#<br>" />
	</cfif>

	<cfreturn ret  />
</cffunction>

<cffunction name="CreateTestDatabases" output="yes" returntype="struct" access="public"
	displayname="used for development"
	hint="creates a couple of test databases with short slot counts to make small"
				>
	<!--- this function needs.... --->
	<cfargument name="Defaults" type="string" default="Yes" />	<!--- the name of the database --->

	<cfset var temp = "" />	<!--- this is the return to the caller --->
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorText = "" />
	<cfset ret.Data = "" />


	<!--- temp to test code --->
	<cfset temp = CreateBlankRRDB(DatabaseName="testDB_1") />
	<cfset temp = CreateBlankRRDB(DatabaseName="testDB_2") />
	<cfset temp = CreateBlankRRDB(DatabaseName="testDB30") />
	<cfset temp = AddEmptyCounter(DatabaseName="testDB_1", CounterName="testCounter1") />
	<cfset temp = AddEmptyCounter(DatabaseName="testDB_1", CounterName="testCounter2") />
	<cfset temp = AddEmptyCounter(DatabaseName="testDB_2", CounterName="testCounter3") />
	<cfset temp = AddEmptyCounter(DatabaseName="testDB30", CounterName="testCounter1") />
	<cfif variables.Debug.TestDefaults eq "yes">
		<cfset temp = AddTables(DatabaseName="testDB_1", CounterName="testCounter1") />
		<cfset temp = AddTables(DatabaseName="testDB_1", CounterName="testCounter2") />
		<cfset temp = AddTables(DatabaseName="testDB_2", CounterName="testCounter3") />
	<cfelse>
		<cfset temp = AddTables(DatabaseName="testDB_1", CounterName="testCounter1", TableSizeList="6,6,6,6,6", FillValueList="0,0,0,0,0") />
		<cfset temp = AddTables(DatabaseName="testDB_1", CounterName="testCounter2", TableNameList="firstly, secondly,fourthly,thirdly", TableOrderList="1,2,4,3", TableSizeList="3,3,3,3") />
		<cfset temp = AddTables(DatabaseName="testDB_2", CounterName="testCounter3", TableSizeList="6,6,6,6,6") />
	</cfif>
	
	<cfreturn ret  />
</cffunction>

<cffunction name="DeleteDatabase" output="yes" returntype="struct" access="public"
	displayname="Delete Database"
	hint="removes a complete database by renaming, optionally deletes it completely">
	<!--- this function needs.... --->
	<cfargument name="DatabaseName" type="string" default="" />	<!--- the name of the database --->
	<cfargument name="DropTables" type="string" default="No" hint="Yes to drop not rename, No(default) to rename" />	<!--- option to drop it or not --->

	<cfset var theDataBaseName = trim(arguments.DatabaseName) />
	<cfset var theDataBaseFileName = FileName_EnCode(theDataBaseName) />
	<cfset var bDropTables = False />	<!--- Drop table flag --->
	<cfset var temp = "" />	<!--- a temp return variable --->
	<cfset var thePos = 0 />	<!--- a temp variable --->
	<cfset var thisTableName = "" />
	<cfset var setMaster = "" />	<!--- localise the query --->
	<cfset var qryGetTables = "" />	<!--- localise the query --->
	<cfset var renCC = "" />	<!--- localise the query --->
	<cfset var renTC = "" />	<!--- localise the query --->
	<cfset var renTbls = "" />	<!--- localise the query --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorText = "DeleteDatabase():-<br>" />
	<cfset ret.Data = "" />

	<cfif arguments.DropTables eq "yes">
		<cfset bDropTables = True />
	</cfif>

	<!--- validate and work out our names and things --->
	<cfif not len(theDatabaseName)>
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 1) />
		<cfset ret.error.ErrorText = ret.error.ErrorText & "DataStore name not supplied<br>" />
	</cfif>
	<cfif ret.error.ErrorCode eq 0>
		<!--- all OK so do the work --->
		<!--- lock it in case, with MX no issues with overwrite but code could call it twice --->
		<cflock timeout="20" throwontimeout="No" name="DataStoreWork" type="EXCLUSIVE">
			<!--- now we have clean params so delete the database structure and its controls --->
			<cfset thePos = ListFindNoCase(variables.DataStoreFileNameList, "#theDataBaseFileName#")>
			<cfif thePos gt 0>
				<cftry>
				<cfset temp = StructDelete(variables.DataStores, "#theDatabaseName#")>
				<cfset variables.DataStoreFileNameList = ListDeleteAt(variables.DataStoreFileNameList, thePos)>
				<cfcatch type="Any"></cfcatch>
				</cftry>
			<cfelse>
				<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 2) />
				<cfset ret.error.ErrorText = ret.error.ErrorText & "The DataStore with the name of:- #theDatabaseName# didn't exist.<br>" />
			</cfif>
			<cfset variables.DataStoreCount = variables.DataStoreCount-1 />
			<cfif variables.DataStoreCount lt 0>	<!--- a little error check to make sure we don't end up negative --->
				<cfset variables.DataStoreCount = 0 />
			</cfif>
			<cfif variables.DataStores["#theDataBaseName#"].control.DataStoreMode eq "File">
			<!--- rename on disk so it gone missing but there for archival use --->
			<cftry>
				<cfif bDropTables>
					<cffile action="delete" file="#variables.Global.DataStorePath##theDataBaseFileName#.rrdb" />
				<cfelse>
					<cffile action="rename" source="#variables.Global.DataStorePath##theDataBaseFileName#.rrdb" destination="#variables.Global.DataStorePath##theDataBaseFileName#.rrdb.deleted" attributes="readonly" />
				</cfif>
			<cfcatch type="any">
				<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 4) />
				<cfset ret.error.ErrorText = ret.error.ErrorText & "DataStore file rename failed<br>" />
				<cfset ret.error.ErrorExtra =  cfcatch.TagContext />
				<cflog text="DeleteDatabase() file rename error Trapped. ret.error.ErrorCode: #ret.error.ErrorCode# - Error Text: #ret.error.ErrorText# - Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#"  file="RRDBerrors" type="Error" application = "yes">
				<cfif application.SLCMS.Config.debug.debugmode>
					DeleteDatabase() file rename error Trapped - error dump:<br>
					<cfdump var="#ret.error.ErrorExtra#">
				</cfif>
			</cfcatch>
			</cftry>
			<cfelseif variables.DataStores["#theDataBaseName#"].control.DataStoreMode eq "SQL">
				<!--- rename all of the tables in the database that refer to this datastore --->
				<cfif bDropTables>
					<!--- first rename in the Master Table --->
					<cfquery name="setMaster" datasource="#variables.Global.DataSource#">
						Delete from	RRDB_MasterControl
							Where	StoreFullName = '#theDataBaseName#'
					</cfquery>
				<cfelse>
					<!--- first rename in the Master Table --->
					<cfquery name="setMaster" datasource="#variables.Global.DataSource#">
						Update	RRDB_MasterControl
							Set		StoreFullName = StoreFullName+'_Deleted'
							Where	StoreFullName = '#theDataBaseName#'
					</cfquery>
				</cfif>
				<!--- then get a list of the tables to make sure we don't delete one that does not exist --->
				<cfquery name="qryGetTables" datasource="#variables.Global.DataSource#">
					sp_tables @table_type="'TABLE'"
				</cfquery>
				<!--- loop round and delete the ones that belong to this database --->
				<cfif bDropTables>
					<cfloop query="qryGetTables">
						<cfset thisTableName = qryGetTables.Table_Name />
						<cfif thisTableName eq "RRDB_#theDataBaseName#_CounterControl">
							<cfquery name="delCC" datasource="#variables.Global.DataSource#">
								DROP TABLE [dbo].[RRDB_#theDataBaseName#_CounterControl]
							</cfquery>
						</cfif>
						<cfif thisTableName eq "RRDB_#theDataBaseName#_TableControl">
							<cfquery name="delTC" datasource="#variables.Global.DataSource#">
								DROP TABLE [dbo].[RRDB_#theDataBaseName#_TableControl]
							</cfquery>
						</cfif>
						<cfif thisTableName eq "RRDB_#theDataBaseName#_Tables">
							<cfquery name="delTbls" datasource="#variables.Global.DataSource#">
								DROP TABLE [dbo].[RRDB_#theDataBaseName#_Tables]
							</cfquery>
						</cfif>
					</cfloop>
				<cfelse>
					<!---  we loop twice as there might be ones marked as deleted already there, we must delete those first --->
					<cfloop query="qryGetTables">
						<cfset thisTableName = qryGetTables.Table_Name />
						<cfif thisTableName eq "RRDB_#theDataBaseName#_CounterControl_Deleted">
							<cfquery name="delCC" datasource="#variables.Global.DataSource#">
								DROP TABLE [dbo].[RRDB_#theDataBaseName#_CounterControl_Deleted]
							</cfquery>
						</cfif>
						<cfif thisTableName eq "RRDB_#theDataBaseName#_TableControl_Deleted">
							<cfquery name="delTC" datasource="#variables.Global.DataSource#">
								DROP TABLE [dbo].[RRDB_#theDataBaseName#_TableControl_Deleted]
							</cfquery>
						</cfif>
						<cfif thisTableName eq "RRDB_#theDataBaseName#_Tables_Deleted">
							<cfquery name="delTbls" datasource="#variables.Global.DataSource#">
								DROP TABLE [dbo].[RRDB_#theDataBaseName#_Tables_Deleted]
							</cfquery>
						</cfif>
					</cfloop>
					<cfloop query="qryGetTables">
						<cfset thisTableName = qryGetTables.Table_Name />
						<cfif thisTableName eq "RRDB_#theDataBaseName#_CounterControl">
							<cfquery name="renCC" datasource="#variables.Global.DataSource#">
								sp_rename 'RRDB_#theDataBaseName#_CounterControl', 'RRDB_#theDataBaseName#_CounterControl_Deleted'
							</cfquery>
						</cfif>
						<cfif thisTableName eq "RRDB_#theDataBaseName#_TableControl">
							<cfquery name="renTC" datasource="#variables.Global.DataSource#">
								sp_rename 'RRDB_#theDataBaseName#_TableControl.PK_RRDB_#theDatabaseName#_TableControl', 'RRDB_#theDataBaseName#_TableControl.PK_RRDB_#theDatabaseName#_TableControl_Deleted', 'OBJECT'
							</cfquery>
							<cfquery name="renTC" datasource="#variables.Global.DataSource#">
								sp_rename 'RRDB_#theDataBaseName#_TableControl.IX_RRDB_#theDatabaseName#_TableControl', 'RRDB_#theDataBaseName#_TableControl.IX_RRDB_#theDatabaseName#_TableControl_Deleted', 'INDEX'
							</cfquery>
							<cfquery name="renTC" datasource="#variables.Global.DataSource#">
								sp_rename 'RRDB_#theDataBaseName#_TableControl.IX_RRDB_#theDatabaseName#_TableControl_1', 'RRDB_#theDataBaseName#_TableControl.IX_RRDB_#theDatabaseName#_TableControl_1_Deleted', 'INDEX'
							</cfquery>
							<cfquery name="renTC" datasource="#variables.Global.DataSource#">
								sp_rename 'RRDB_#theDataBaseName#_TableControl.IX_RRDB_#theDatabaseName#_TableControl_2', 'RRDB_#theDataBaseName#_TableControl.IX_RRDB_#theDatabaseName#_TableControl_2_Deleted', 'INDEX'
							</cfquery>
							<cfquery name="renTC" datasource="#variables.Global.DataSource#">
								sp_rename 'RRDB_#theDataBaseName#_TableControl', 'RRDB_#theDataBaseName#_TableControl_Deleted'
							</cfquery>
						</cfif>
						<cfif thisTableName eq "RRDB_#theDataBaseName#_Tables">
							<cfquery name="renTbls" datasource="#variables.Global.DataSource#">
								sp_rename 'RRDB_#theDataBaseName#_Tables.PK_RRDB_#theDatabaseName#_Tables', 'RRDB_#theDataBaseName#_Tables.PK_RRDB_#theDatabaseName#_Tables_Deleted', 'OBJECT'
							</cfquery>
							<cfquery name="renTbls" datasource="#variables.Global.DataSource#">
								sp_rename 'RRDB_#theDataBaseName#_Tables.IX_RRDB_#theDatabaseName#_Tables', 'RRDB_#theDataBaseName#_Tables.IX_RRDB_#theDatabaseName#_Tables_Deleted', 'INDEX'
							</cfquery>
							<cfquery name="renTbls" datasource="#variables.Global.DataSource#">
								sp_rename 'RRDB_#theDataBaseName#_Tables.IX_RRDB_#theDatabaseName#_Tables_1', 'RRDB_#theDataBaseName#_Tables.IX_RRDB_#theDatabaseName#_Tables_1_Deleted', 'INDEX'
							</cfquery>
							<cfquery name="renTbls" datasource="#variables.Global.DataSource#">
								sp_rename 'RRDB_#theDataBaseName#_Tables', 'RRDB_#theDataBaseName#_Tables_Deleted'
							</cfquery>
						</cfif>
					</cfloop>	<!--- end: SQL - loop over tables --->
				</cfif>	<!--- end: drop or rename --->
			</cfif>	<!--- end: file or SQL --->
		</cflock>
	</cfif>

	<cfreturn ret  />
</cffunction>

<cffunction name="CreateTestStatsDatabases" output="yes" returntype="struct" access="public"
	displayname="used for development"
	hint="creates a test database with standard site statistics format and random data"
				>
	<!--- this function needs.... --->
	<cfargument name="DatabaseName" type="string" default="FullStats_1" />	<!--- the name of the database --->

	<cfset var theDataBaseName = trim(arguments.DatabaseName) />
	<cfset var lcntr = 0 />	<!--- temp loop counter --->
	<cfset var temp = "" />	<!--- this is a temp var --->
	<cfset var temps = StructNew() />	<!--- this is a temp var --->
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorText = "" />
	<cfset ret.Data = "" />

	<cfif left(theDataBaseName, 9) neq "mbcStats_">
		<cfset theDataBaseName = "mbcStats_" & theDataBaseName />
	</cfif>

	<!--- dump any old versions --->
	<cfset temp = DeleteDatabase(DatabaseName="#theDataBaseName#", DropTables="Yes") />
	<!--- and make a new one --->
	<cfset temp = CreateBlankRRDB(DatabaseName="#theDataBaseName#") />
	<cfset temp = AddEmptyCounter(DatabaseName="#theDataBaseName#", CounterName="PageViews") />
	<cfset temp = AddEmptyCounter(DatabaseName="#theDataBaseName#", CounterName="Visits") />
	<cfset temp = AddEmptyCounter(DatabaseName="#theDataBaseName#", CounterName="UniqueVisitors") />
	<cfset temp = AddTables(DatabaseName="#theDataBaseName#", CounterName="PageViews") />
	<cfset temp = AddTables(DatabaseName="#theDataBaseName#", CounterName="Visits") />
	<cfset temp = AddTables(DatabaseName="#theDataBaseName#", CounterName="UniqueVisitors") />
	<!--- now we have an empty database we can fill it --->
	<cfset thisUnique = RandRange(0, 2) />
	<cfloop from="1" to="400" index="lcntr">
		<cfset thisHit = RandRange(0, 500) />
		<cfset thisVisit = RandRange(0, 100) />
		<cfset thisUnique = thisUnique + round(Rand()) />
		<cfset thisDate = DateAdd("n", lcntr*4, Now()) />

		<cfset temps2 = SetSlotValue(SlotTimeStamp="#thisDate#", SlotValue="#thisHit#", SlotNumber="#lcntr#", TableName="Daily", CounterName="PageViews", CleanDatabaseName="#theDatabaseName#") />
		<cfset temps2 = SetSlotValue(SlotTimeStamp="#thisDate#", SlotValue="#thisHit#", SlotNumber="#lcntr#", TableName="Daily", CounterName="Visits", CleanDatabaseName="#theDatabaseName#") />
		<cfset temps2 = SetSlotValue(SlotTimeStamp="#thisDate#", SlotValue="#thisHit#", SlotNumber="#lcntr#", TableName="Daily", CounterName="UniqueVisitors", CleanDatabaseName="#theDatabaseName#") />
		<!--- 
		<cfset variables.DataStores["#theDatabaseName#"].counters["PageViews"]["Daily"].data[lcntr][2] = thisHit />
		<cfset variables.DataStores["#theDatabaseName#"].counters["PageViews"]["Daily"].data[lcntr][1] = thisDate />
		<cfset variables.DataStores["#theDatabaseName#"].counters["Visits"]["Daily"].data[lcntr][2] = thisVisit />
		<cfset variables.DataStores["#theDatabaseName#"].counters["Visits"]["Daily"].data[lcntr][1] = thisDate />
		<cfset variables.DataStores["#theDatabaseName#"].counters["UniqueVisitors"]["Daily"].data[lcntr][2] = thisUnique />
		<cfset variables.DataStores["#theDatabaseName#"].counters["UniqueVisitors"]["Daily"].data[lcntr][1] = thisDate />
		 --->
	</cfloop>
	<cfset thisUnique = RandRange(0, 2) />
	<cfloop from="1" to="400" index="lcntr">
		<cfset thisHit = RandRange(0, 500) />
		<cfset thisVisit = RandRange(0, 100) />
		<cfset thisUnique = thisUnique + round(Rand()) />
		<cfset thisDate = DateAdd("n", lcntr*30, Now()) />
		<cfset temps2 = SetSlotValue(SlotTimeStamp="#thisDate#", SlotValue="#thisHit#", SlotNumber="#lcntr#", TableName="Weekly", CounterName="PageViews", CleanDatabaseName="#theDatabaseName#") />
		<cfset temps2 = SetSlotValue(SlotTimeStamp="#thisDate#", SlotValue="#thisHit#", SlotNumber="#lcntr#", TableName="Weekly", CounterName="Visits", CleanDatabaseName="#theDatabaseName#") />
		<cfset temps2 = SetSlotValue(SlotTimeStamp="#thisDate#", SlotValue="#thisHit#", SlotNumber="#lcntr#", TableName="Weekly", CounterName="UniqueVisitors", CleanDatabaseName="#theDatabaseName#") />
		<!--- 
		<cfset variables.DataStores["#theDatabaseName#"].counters["PageViews"]["Weekly"].data[lcntr][2] = thisHit />
		<cfset variables.DataStores["#theDatabaseName#"].counters["PageViews"]["Weekly"].data[lcntr][1] = thisDate />
		<cfset variables.DataStores["#theDatabaseName#"].counters["Visits"]["Weekly"].data[lcntr][2] = thisVisit />
		<cfset variables.DataStores["#theDatabaseName#"].counters["Visits"]["Weekly"].data[lcntr][1] = thisDate />
		<cfset variables.DataStores["#theDatabaseName#"].counters["UniqueVisitors"]["Weekly"].data[lcntr][2] = thisUnique />
		<cfset variables.DataStores["#theDatabaseName#"].counters["UniqueVisitors"]["Weekly"].data[lcntr][1] = thisDate />
		 --->
	</cfloop>
	<cfset thisUnique = RandRange(0, 2) />
	<cfloop from="1" to="400" index="lcntr">
		<cfset thisHit = RandRange(0, 500) />
		<cfset thisVisit = RandRange(0, 100) />
		<cfset thisUnique = thisUnique + round(Rand()) />
		<cfset thisDate = DateAdd("n", lcntr*120, Now()) />
		<cfset temps2 = SetSlotValue(SlotTimeStamp="#thisDate#", SlotValue="#thisHit#", SlotNumber="#lcntr#", TableName="Monthly", CounterName="PageViews", CleanDatabaseName="#theDatabaseName#") />
		<cfset temps2 = SetSlotValue(SlotTimeStamp="#thisDate#", SlotValue="#thisHit#", SlotNumber="#lcntr#", TableName="Monthly", CounterName="Visits", CleanDatabaseName="#theDatabaseName#") />
		<cfset temps2 = SetSlotValue(SlotTimeStamp="#thisDate#", SlotValue="#thisHit#", SlotNumber="#lcntr#", TableName="Monthly", CounterName="UniqueVisitors", CleanDatabaseName="#theDatabaseName#") />
		<!--- 
		<cfset variables.DataStores["#theDatabaseName#"].counters["PageViews"]["Monthly"].data[lcntr][2] = thisHit />
		<cfset variables.DataStores["#theDatabaseName#"].counters["PageViews"]["Monthly"].data[lcntr][1] = thisDate />
		<cfset variables.DataStores["#theDatabaseName#"].counters["Visits"]["Monthly"].data[lcntr][2] = thisVisit />
		<cfset variables.DataStores["#theDatabaseName#"].counters["Visits"]["Monthly"].data[lcntr][1] = thisDate />
		<cfset variables.DataStores["#theDatabaseName#"].counters["UniqueVisitors"]["Monthly"].data[lcntr][2] = thisUnique />
		<cfset variables.DataStores["#theDatabaseName#"].counters["UniqueVisitors"]["Monthly"].data[lcntr][1] = thisDate />
		 --->
	</cfloop>
	<cfset thisUnique = RandRange(0, 2) />
	<cfloop from="1" to="400" index="lcntr">
		<cfset thisHit = RandRange(0, 500) />
		<cfset thisVisit = RandRange(0, 100) />
		<cfset thisUnique = thisUnique + round(Rand()) />
		<cfset thisDate = DateAdd("n", lcntr*1440, Now()) />
		<cfset temps2 = SetSlotValue(SlotTimeStamp="#thisDate#", SlotValue="#thisHit#", SlotNumber="#lcntr#", TableName="Yearly", CounterName="PageViews", CleanDatabaseName="#theDatabaseName#") />
		<cfset temps2 = SetSlotValue(SlotTimeStamp="#thisDate#", SlotValue="#thisHit#", SlotNumber="#lcntr#", TableName="Yearly", CounterName="Visits", CleanDatabaseName="#theDatabaseName#") />
		<cfset temps2 = SetSlotValue(SlotTimeStamp="#thisDate#", SlotValue="#thisHit#", SlotNumber="#lcntr#", TableName="Yearly", CounterName="UniqueVisitors", CleanDatabaseName="#theDatabaseName#") />
		<!--- 
		<cfset variables.DataStores["#theDatabaseName#"].counters["PageViews"]["Yearly"].data[lcntr][2] = thisHit />
		<cfset variables.DataStores["#theDatabaseName#"].counters["PageViews"]["Yearly"].data[lcntr][1] = thisDate />
		<cfset variables.DataStores["#theDatabaseName#"].counters["Visits"]["Yearly"].data[lcntr][2] = thisVisit />
		<cfset variables.DataStores["#theDatabaseName#"].counters["Visits"]["Yearly"].data[lcntr][1] = thisDate />
		<cfset variables.DataStores["#theDatabaseName#"].counters["UniqueVisitors"]["Yearly"].data[lcntr][2] = thisUnique />
		<cfset variables.DataStores["#theDatabaseName#"].counters["UniqueVisitors"]["Yearly"].data[lcntr][1] = thisDate />
		 --->
	</cfloop>
	<cfset thisUnique = RandRange(0, 2) />
	<cfloop from="1" to="400" index="lcntr">
		<cfset thisHit = RandRange(0, 500) />
		<cfset thisVisit = RandRange(0, 100) />
		<cfset thisUnique = thisUnique + round(Rand()) />
		<cfset thisDate = DateAdd("n", lcntr*10080, Now()) />
		<cfset temps2 = SetSlotValue(SlotTimeStamp="#thisDate#", SlotValue="#thisHit#", SlotNumber="#lcntr#", TableName="8Yearly", CounterName="PageViews", CleanDatabaseName="#theDatabaseName#") />
		<cfset temps2 = SetSlotValue(SlotTimeStamp="#thisDate#", SlotValue="#thisHit#", SlotNumber="#lcntr#", TableName="8Yearly", CounterName="Visits", CleanDatabaseName="#theDatabaseName#") />
		<cfset temps2 = SetSlotValue(SlotTimeStamp="#thisDate#", SlotValue="#thisHit#", SlotNumber="#lcntr#", TableName="8Yearly", CounterName="UniqueVisitors", CleanDatabaseName="#theDatabaseName#") />
	</cfloop>
	<!--- save to disk so its there for the future --->
	<cfset temp = SaveDatabaseFile(DatabaseName="#theDatabaseName#")/>
	
	<cfreturn ret  />
</cffunction>

<cffunction name="DumpGlobals" output="yes" returntype="string" access="public"
	displayname="Nothing"
	hint="returns a dump of the sites and global structures"
				>
	
	<cfset var theDump = "" />
	<cfsavecontent variable="theDump">
		Variables Structure:<br>
		<cfdump var="#variables#">
	</cfsavecontent>
	<cfreturn theDump  />
</cffunction>

<cffunction name="copyFileStore2SQLdb" output="yes" returntype="struct" access="public"
	displayname="copy named FileStore to a SQL db"
	hint="copies named store, creates a SQL DB if needed, 
				minimal error handling except for the file db decode where it is intelligent
				to allow for broken dbs to copy around broken parts">
	
	<!--- this function needs.... --->
	<cfargument name="DatabaseName" type="string" default="" />	<!--- the name of the database --->

	<!--- now all of the var declarations, first the arguments which need manipulation --->
	<cfset var theDataBaseName = trim(arguments.DatabaseName) />
	<cfset var theDataBaseFileName = FileName_EnCode(theDataBaseName) />
	<!--- now vars that will get filled as we go --->
	<cfset var TableExists = False />
	<cfset var acntr = 0 />	<!--- temp loop counter --->
	<cfset var lcntr = 0 />	<!--- temp loop counter --->
	<cfset var temp = "" />	<!--- temp/throwaway var --->
	<cfset var temps = StructNew() />	<!--- temp/throwaway var --->
	<cfset var MaxSlotNumber = 0 />	<!--- will be used to seee how big a table to make --->
	<cfset var thisCounter = "" />	<!--- the counter being created in loop var --->
	<cfset var thisControlSet1 = "" />	<!--- the control structure for one counter as looped --->
	<cfset var thisControlSet2 = "" />	<!--- the control structure for one counter as looped --->
	<cfset var thisDataSet = "" />	<!--- name oif a dataset within one counter as looped --->
	<cfset var DataSetList = "" />	<!--- a list of every  "table" counter to eventually be created --->
	<cfset var qryGetTables = "" />	<!--- localise query --->
	<cfset var setController = "" />	<!--- localise query --->
	<cfset var setTableData = "" />	<!--- localise query --->
	<cfset var createTableDatasetColumns = "" />	<!--- localise query --->
	<cfset var theSet = "" />	<!--- temp/throwaway var --->
	<cfset var qrySetString = "" />	<!--- temp/throwaway var --->
	<cfset var SetStringLen = 0 />
	<cfset var SetStringCntr = 0 />
	<cfset var flagAdd5th = False />	<!--- if we have to add a 5th dataset --->
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorText = "copyFileStore2SQLdb()<br>" />
	<cfset ret.Data = "" />
	
	<cftry>	<!--- error handle the whole thing in case --->
		<!--- validate the incoming stuff --->
		<cfif len(theDataBaseName)>
			<!--- <cfif FileExists("#variables.Global.DataStorePath##theDataBaseFileName#.rrdb")> --->
			<cfset temps = ChecknSetDatabase(DatabaseName="#theDatabaseName#") />
			<!--- first make sure we don't have a table set of this name already --->
			<cfquery name="qryGetTables" datasource="#variables.Global.DataSource#">
				sp_tables @table_type="'TABLE'"
			</cfquery>
			<cfloop query="qryGetTables">
				<cfif qryGetTables.Table_Name eq "RRDB_#theDataBaseName#_CounterControl">	<!--- look for this table --->
					<cfset TableExists = True />
				</cfif>
			</cfloop>	<!--- end: loop over tables in database --->
			<cfif not TableExists>
				<!--- its OK to do stuff --->
				<!--- we are going to create a set of counters and an empty dataset table using the standard functions above.
							Then we are going to add in directly rather than use the functions above 
							as we can save a big chunk of work by doing it in one hit rather than looping every which way --->
				<cftry>
				<!--- wrap the relevant bits of code down in the works in a try/catch in case something breaks despite all the checking above --->
				<cfset temps = CreateBlankRRDB(DatabaseName="#theDataBaseName#", AddMethod="Block", CreationMode="File2SQL") />
				<cfif temps.error.errorcode eq 0>
					<!--- we have a blank DB so now create the counters by looping over the counter list --->
					<cfloop list="#variables.DataStores["#theDatabaseName#"].control.CounterNameList#" index="thisCounter">
						<cfset temps = AddEmptyCounter(DatabaseName="#theDataBaseName#", CounterName="#thisCounter#", CreationMode="File2SQL") />
						<cfif temps.error.errorcode eq 0>
							<!--- good empty counter so update the control table with the dataset control data --->
							<cfset thisControlSet1 = variables.DataStores["#theDatabaseName#"].counters["#thisCounter#"].control />
							<!--- check to see if its old style without the fifth, 8yearly, table, add it in as a default set if not there --->
							<cfif thisControlSet1.TableCount eq 4>
								<cfset thisControlSet1.TableCount = 5 />
								<cfset thisControlSet1.FillValueList = thisControlSet1.FillValueList & ",0" />
								<cfset thisControlSet1.TableNameList = thisControlSet1.TableNameList & ",8Yearly" />
								<cfset thisControlSet1.TableSizeList = thisControlSet1.TableSizeList & ",400" />
								<cfset thisControlSet1.TableIntervalList = thisControlSet1.TableIntervalList & ",10080" />
								<cfset thisControlSet1.TableOrder = thisControlSet1.TableOrder & ",5" />
								<!--- flag to below --->
								<cfset flagAdd5th = True />
							<cfelse>
								<cfset flagAdd5th = False />
							</cfif>
							<cfquery name="setController" datasource="#variables.Global.DataSource#">
								Update	[dbo].[RRDB_#theDatabaseName#_CounterControl]
									set		FillValueList = '#thisControlSet1.FillValueList#', 
												TableCount = '#thisControlSet1.TableCount#', 
												TableNameList = '#thisControlSet1.TableNameList#', 
												TableSizeList = '#thisControlSet1.TableSizeList#', 
												TableIntervalList = '#thisControlSet1.TableIntervalList#', 
												TableOrder = '#thisControlSet1.TableOrder#'
									where	Counter = '#thisCounter#'
							</cfquery>
							<!--- then loop over the defined datasets and build list of dataset column names and build control db table --->
							<cfloop from="1" to="#thisControlSet1.TableCount#" index="lcntr">
								<cfset thisDataSet = ListGetAt(thisControlSet1.TableNameList, lcntr) />
								<cfset DataSetList = ListAppend(DataSetList, "#thisCounter#_#thisDataSet#") />	<!--- the column name first part --->
								<cfif StructKeyExists(variables.DataStores["#theDatabaseName#"].counters["#thisCounter#"], thisDataSet)>	<!--- this is the handle a missing 5th one --->
									<cfset thisControlSet2 = variables.DataStores["#theDatabaseName#"].counters["#thisCounter#"]["#thisDataSet#"].control />	<!--- note down a level  --->
									<cfquery name="setController" datasource="#variables.Global.DataSource#">
										Insert into [dbo].[RRDB_#theDatabaseName#_TableControl]
															(Counter, Dataset, CurrentSlot, 
															TableSize, SlotInterval, FillValue, TableOrder)
											Values	('#thisCounter#', '#thisDataSet#', #thisControlSet2.CurrentSlot#, 
															#thisControlSet2.TableSize#, #thisControlSet2.Interval#, #thisControlSet2.FillValue#, #thisControlSet2.TableOrder#)
									</cfquery>
									<!--- on the fly make sure we know how big our biggest dataset is --->
									<cfif thisControlSet2.TableSize gt MaxSlotNumber>
										<cfset MaxSlotNumber = thisControlSet2.TableSize />
									</cfif>
								</cfif>
							</cfloop>
							<cfif flagAdd5th>
								<!---  add a set of empty defaults for the 8yearly table --->
								<cfquery name="setController" datasource="#variables.Global.DataSource#">
									Insert into [dbo].[RRDB_#theDatabaseName#_TableControl]
														(Counter, Dataset, CurrentSlot, TableSize, SlotInterval, FillValue, TableOrder)
										Values	('#thisCounter#', '8Yearly', 1, 400, 10080, 0, 5)
								</cfquery>
								<cfif 400 gt MaxSlotNumber>
									<cfset MaxSlotNumber = 400 />
								</cfif>
							</cfif>
						<cfelse>
							<cfset ret.error.ErrorCode = 8 />
							<cfset ret.error.ErrorText = ret.error.ErrorText & "Create Counter Failed. DataBaseName - #theDataBaseName#; CounterName - #thisCounter# error was: #temps.error.errortext#" />
						</cfif>
					</cfloop>
					<cfif ret.error.errorcode eq 0>
						<!--- we now have a correct set of counters and their control DBtable and an empty dataset table.
									we know what columns we need for the whole shebang in DataSetList so do a big table add --->
						<cfquery name="createTableDatasetColumns" datasource="#variables.Global.DataSource#">
							<cfloop list="#DataSetList#" index="theSet">
								Alter TABLE [dbo].[RRDB_#theDatabaseName#_Tables]
									ADD #theSet#_Value [int] NOT NULL DEFAULT (0)
								Alter TABLE [dbo].[RRDB_#theDatabaseName#_Tables]
									ADD #theSet#_TimeStamp [datetime] NULL
							</cfloop>
						</cfquery>
						<!--- now we need to add all the data. we could do a set of inserts but there could be gaps al over so we are
									going to create a full set of slots with inserts so there are default values everywhere and put in the data with updates --->
						<cfquery name="setTableData" datasource="#variables.Global.DataSource#">
							<cfloop index="acntr" from="1" to="#MaxSlotNumber#">
								Insert into [dbo].[RRDB_#theDatabaseName#_Tables]
													(Slot)
									Values	(#acntr#)
							</cfloop>
						</cfquery>
						<cfloop index="acntr" from="1" to="#MaxSlotNumber#">
							<cfset SetStringLen = ListLen(DataSetList) />
							<cfset SetStringCntr = 0 />
							<cfquery name="setTableData" datasource="#variables.Global.DataSource#">
								Update	[dbo].[RRDB_#theDatabaseName#_Tables]
									Set		
									<cfloop list="#DataSetList#" index="theSet">
										<cfset SetStringCntr = SetStringCntr+1 />
										<cftry>
											<cfif len(#variables.DataStores["#theDatabaseName#"].counters["#listFirst(theSet, "_")#"]["#listLast(theSet, "_")#"].data[acntr][2]#)>
											#theSet#_Value = #variables.DataStores["#theDatabaseName#"].counters["#listFirst(theSet, "_")#"]["#listLast(theSet, "_")#"].data[acntr][2]#,
											</cfif>
										<cfcatch></cfcatch>
										</cftry>
										<cftry>
											<cfif len(#variables.DataStores["#theDatabaseName#"].counters["#listFirst(theSet, "_")#"]["#listLast(theSet, "_")#"].data[acntr][1]#)>
											#theSet#_TimeStamp = #variables.DataStores["#theDatabaseName#"].counters["#listFirst(theSet, "_")#"]["#listLast(theSet, "_")#"].data[acntr][1]#,
											</cfif>
										<cfcatch></cfcatch>
										</cftry>
										<cfif SetStringCntr eq SetStringLen>slot = #acntr#</cfif>
									</cfloop>
									where	Slot = #acntr#
							</cfquery>
						</cfloop>
						<!--- we got there! :-) flag all converted in status --->
						<cfquery name="setMaster" datasource="#variables.Global.DataSource#">
							Update	RRDB_MasterControl
								set		DataStoreMode = 'SQL',
											StoreStatus = 'Running',
											StoreOKtoUse = 'Yes'
								where	StoreFullName = '#theDatabaseName#'
						</cfquery>
						<cfset variables.DataStores["#theDatabaseName#"].control.StoreStatus = "Running" />	<!--- the store's running status --->
						<cfset variables.DataStores["#theDatabaseName#"].control.StoreOKtoUse = "Yes" />	<!--- the store's running status --->
					</cfif> <!--- end: creates were good - is OK to do tables --->
				<cfelse>
					<cfset ret.error.ErrorCode = 4 />
					<cfset ret.error.ErrorText = ret.error.ErrorText & "Create Blank Database Failed. DataBaseName - #theDataBaseName#; error was: #temps.error.errortext#" />
				</cfif>
				<cfcatch type="any">
					<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 128) />
					<cfset ret.error.ErrorText = ret.error.ErrorText & 'Oops! Error Caught, error message was: #cfcatch.message#, error detail was: #cfcatch.detail#<br>' />
					<cfset ret.error.ErrorExtra =  cfcatch.TagContext />
					<cflog text="copyFileStore2SQLdb() unhandled error Trapped. ret.error.ErrorCode: #ret.error.ErrorCode# - Error Text: #ret.error.ErrorText# - Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#"  file="RRDBerrors" type="Error" application = "yes">
					<cfif application.SLCMS.Config.debug.debugmode>
						copyFileStore2SQLdb() unhandled error Trapped - error dump:<br>
						<cfdump var="#ret.error.ErrorExtra#">
					</cfif>
				</cfcatch>
				</cftry>
			<cfelse>
				<!--- oops no meaningful parameters so return nothing --->
				<cfset ret.error.ErrorCode = 2 />
				<cfset ret.error.ErrorText = ret.error.ErrorText & "DataBaseName - #theDataBaseName# already is in the SQL db!" />
			</cfif>
		<cfelse>
			<!--- oops no meaningful parameters so return nothing --->
			<cfset ret.error.ErrorCode = 1 />
			<cfset ret.error.ErrorText = ret.error.ErrorText & "Invalid parameters: - DataBaseName - #theDataBaseName#" />
		</cfif> <!--- end: incoming parameters validation check --->
	<cfcatch type="any">
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 128) />
		<cfset ret.error.ErrorText = ret.error.ErrorText & 'Oops! Error Caught, error message was: #cfcatch.message#, error detail was: #cfcatch.detail#<br>' />
		<cfset ret.error.ErrorExtra =  cfcatch.TagContext />
		<cflog text="copyFileStore2SQLdb() unhandled error Trapped. ret.error.ErrorCode: #ret.error.ErrorCode# - Error Text: #ret.error.ErrorText# - Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#"  file="RRDBerrors" type="Error" application = "yes">
		<cfif application.SLCMS.Config.debug.debugmode>
			emptyFunction() unhandled error Trapped - error dump:<br>
			<cfdump var="#ret.error.ErrorExtra#">
		</cfif>
	</cfcatch>
	</cftry>

	<cfreturn ret  />
</cffunction>


<cffunction name="emptyFunction" output="yes" returntype="struct" access="public"
	displayname="Nothing"
	hint="this is just a shell to copy, 
				can be deleted once coding has finished, 
				and turn off output if we don't need it to save whitespace"
				>
	<!--- this function needs.... --->
	<cfargument name="DatabaseName" type="string" default="" />	<!--- the name of the database --->

	<!--- now all of the var declarations, first the arguments which need manipulation --->
	<cfset var theDataBaseName = trim(arguments.DatabaseName) />
	<cfset var theDataBaseFileName = FileName_EnCode(theDataBaseName) />
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
	
	<cftry>	<!--- error handle the whole thing in case --->
		<!--- validate the incoming stuff --->
		
		<cfif 1 eq 0>
			<!--- its OK so do stuff --->
			<!--- wrap the relevant bits of code down in the works in a try/catch in case something breaks despite all the checking above --->
			<cftry>
			<cfcatch type="any">
				<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 128) />
				<cfset ret.error.ErrorText = ret.error.ErrorText & 'Oops! Error Caught, error message was: #cfcatch.message#, error detail was: #cfcatch.detail#<br>' />
				<cfset ret.error.ErrorExtra =  cfcatch.TagContext />
				<cflog text="emptyFunction() unhandled error Trapped. ret.error.ErrorCode: #ret.error.ErrorCode# - Error Text: #ret.error.ErrorText# - Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#"  file="RRDBerrors" type="Error" application = "yes">
				<cfif application.SLCMS.Config.debug.debugmode>
					emptyFunction() unhandled error Trapped - error dump:<br>
					<cfdump var="#ret.error.ErrorExtra#">
				</cfif>
			</cfcatch>
			</cftry>
		<cfelse>
			<!--- oops no meaningful parameters so return nothing --->
			<cfset ret.error.ErrorCode = 1 />
			<cfset ret.error.ErrorText = ret.error.ErrorText & "Invalid parameters: - DataBaseName - #theDataBaseName#; CounterName - #theCounterName#; TableName - #theTableName#" />
		</cfif> <!--- end: incoming parameters validation check --->
	<cfcatch type="any">
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 128) />
		<cfset ret.error.ErrorText = ret.error.ErrorText & 'Oops! Error Caught, error message was: #cfcatch.message#, error detail was: #cfcatch.detail#<br>' />
		<cfset ret.error.ErrorExtra =  cfcatch.TagContext />
		<cflog text="emptyFunction() unhandled error Trapped. ret.error.ErrorCode: #ret.error.ErrorCode# - Error Text: #ret.error.ErrorText# - Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#"  file="RRDBerrors" type="Error" application = "yes">
		<cfif application.SLCMS.Config.debug.debugmode>
			emptyFunction() unhandled error Trapped - error dump:<br>
			<cfdump var="#ret.error.ErrorExtra#">
		</cfif>
	</cfcatch>
	</cftry>

	<cfreturn ret  />
</cffunction>

</cfcomponent>
	
	
	