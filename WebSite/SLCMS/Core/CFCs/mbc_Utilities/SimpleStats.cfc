<!--- SimpleStats.cfc --->
<!---  --->
<!--- CFC containing functions that relate to a stats engine using the round-robin data stores --->
<!--- Part of the mbcomms Standard Site Architecture toolkit --->
<!--- One thing we want this beast to do is run very quickly as it will be used on quite high traffic sites.
			To do this effectively we need a simple function call from the host website specifying site name
			and counter to store (hit or visit at this stage) so we to do the checking to see if this site exists
			already and then incrementing the counters all in one pass and with minimum delay.
			One use of this enmgine will be on a site that will have internal sites created and we won't know
			about the site until the hit call comes so the ChecknSet function will need to be called every time.
			To make that call fast a persistent local data structure of sites is carried that is used to rapidly
			identify existing sites, things will only slow down if a site appears to be a new one and the creation 
			process has to take place.
			 --->
<!---  --->
<!--- copyright: mbcomms 2007 --->
<!---  --->
<!--- Created:  18th Jun 2007 by Kym K --->
<!--- Modified: 20th Aug 2007 - 21st Aug 2007 by Kym K - mbcomms, working on it --->
<!--- Modified:  2nd Sep 2007 - 10th Sep 2007 by Kym K - mbcomms, added functions and added  stats_" to DB name" --->
<!--- Modified: 14th Sep 2007 - 17th Sep 2007 by Kym K - mbcomms, added getSiteCount, CheckDatabaseIntegrity functions --->
<!--- Modified: 24th Sep 2007 - 28th Sep 2007 by Kym K - mbcomms, using above to find bugs, 
																																	added locks to create db code in CheckNset
																																	added "AllowHits" flag to (dis)enable hits globally
																																	added DumpSite() function to dump entire structure of RRDS
																																	as a result --->
<!--- Modified:  3rd Oct 2007 -  4th Oct 2007 by Kym K - mbcomms, added version control function and HTML chart --->
<!--- Modified:  7th Oct 2007 - 13th Oct 2007 by Kym K - mbcomms, added try/catch error handling on all functions
																																	logging to cf logs for caught errors
																																	var'd arguments in AddUniqueVisitor() to check issues --->
<!--- Modified: 15th Oct 2007 - 15th Oct 2007 by Kym K - mbcomms, fixed HTML chart cosmetics and partial calculation resets --->
<!--- Modified: 16th Oct 2007 - 16th Oct 2007 by Kym K - mbcomms, improved init error handling top give more detail in logs --->
<!--- Modified: 20th Oct 2007 - 20th Oct 2007 by Kym K - mbcomms, changed chart code to handle fact that empty slot has null for time --->
<!---  --->
<!--- Modified:  3rd Feb 2008 -  3rd Feb 2008 by Kym K - mbcomms, adding SQL database datastores as a store mode alternative --->
<!--- Modified: 19th Feb 2008 - 19th Feb 2008 by Kym K - mbcomms, adding Block and Auto modes --->
<!--- modified:  9th Apr 2012 -  9th Apr 2012 by Kym K, mbcomms: V3.0, CFWheels version. All SLCMS in own struct under app scope --->


<cfcomponent output="no"
	displayname="Stats Recorder and Reporter"
	hint="set of tools to record site statistics and return results">
		
	<!--- set up our persistent data (this CFC is in the Application scope so is persistent in itself) --->
	<cfset variables.Sites = StructNew() />
	<cfset variables.Global = StructNew() />
	<cfset variables.Global.Version = "1.0.1.343" />
	<cfset variables.Global.VersionText = "1.0.1 - original code plus SQL database option" />
	<cfset variables.Global.VersionRequisites = "needs RRDS 1.0.1.343+" />
	<cfset variables.Global.DataStorePath = "" />
	<cfset variables.Global.DataStoreMode = "" />
	<cfset variables.Global.SaveMode = "" />
	<cfset variables.Global.SiteCount = 0 />
	<cfset variables.Global.SiteList = "" />
	<cfset variables.Global.Control = StructNew() />
	<cfset variables.Global.Control.AllowHits = True />
	<cfset variables.Global.Integrity = StructNew() />
	<cfset variables.Global.Integrity.LastSaved_Global = "" />

<!--- initialise the various thingies, this should only be called after an app scope refresh or similar --->
<cffunction name="init" access="public" output="yes" returntype="struct" 
	description="The Initializer"
	hint="Sets up a scheduler to refresh stats db's to disk as specified rate"
	>
	<cfargument name="DiskRefreshRate" type="string" default="9" hint="time in minutes between disk updates" />	
	<cfargument name="RefreshURL" type="string" default="" hint="the url to call to run the refresher" />
	<cfargument name="DataStorePath" type="string" default="" hint="full physical path to where the Stats session data lives" />
	<cfargument name="SiteName" type="string" default="SiteName">	<!--- this is the application name of the website to differentiate many copies on one server --->
	<cfargument name="DataStoreMode" type="string" default="File" hint="type of datastorage, file or SQL database" />
	<cfargument name="SaveMode" type="string" default="" hint="method of saving data, block or incremental" />

	<!--- now all of the var declarations --->
	<cfset var theDiskRefreshRate = trim(arguments.DiskRefreshRate) />	<!--- the refresh rate in minutes --->
	<cfset var theRefreshURL = trim(arguments.RefreshURL) />	<!--- the refresh rate in minutes --->
	<cfset var theDataStorePath = trim(arguments.DataStorePath) />	<!--- the refresh rate in minutes --->
	<cfset var theSiteName = trim(arguments.SiteName) />	<!--- the refresh rate in minutes --->
	<cfset var theStoreDBmode = trim(arguments.DataStoreMode) />	<!--- the mode of the databases, file or SQL db --->
	<cfset var theSaveMode = trim(arguments.SaveMode) />	<!--- the mode to save the counts, incrementally or as the time rolls over --->
	
	<cfset var AllowHitsStatus = False />	<!--- the stored AllowHits state --->
	<cfset var thisFileNamePart = "" />	<!--- the name of the file derived from its site name --->
	<cfset var theStruct = StructNew() />	<!--- the unpacking result --->
	<cfset var thisSite = "" />	<!--- the unpacking result --->
	<cfset var qryStoresFiles = "" />	<!--- localize the query --->
	<cfset var qryGetTables = "" />	<!--- localize the directory query --->
	<cfset var thisTableName = "" />	<!--- the name of an individual database table --->
	<cfset var MasterTableExists = False />	<!--- does the name main, global control table exist? --->
	<cfset var MasterPacketExists = False />	<!--- does the name main, global control table packet exist? --->
	<cfset var createMasterControlTable = "" />	<!--- localize the query --->
	<cfset var setPacketStore = "" />	<!--- localize the query --->
	<cfset var getGlobalPacket = "" />	<!--- localize the query --->
	<cfset var NoMasterFlag = False />	<!--- local flag to say no master file/db to read, must be a fresh install --->
	<cfset var GoodDecodeFlag = True />	<!--- local flag to say file read and decode was OK --->
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorText = "init():-<br>" />
	<cfset ret.Data = "" />
	
	<!--- first global stuff --->
	<cfset variables.Global.DataStoreMode = theStoreDBmode />	<!--- this is whether to use local files or SQL DB --->
	<cfset variables.Global.DataStorePath = theDataStorePath />
	<cfset variables.Global.SaveMode = theSaveMode />
	
	<cfif theSaveMode eq "Block">
		<cfset theDiskRefreshRate = 1 />	
	</cfif>

	<!--- set up the automation --->
	<cftry>
	<cfif IsNumeric(theDiskRefreshRate) and len(theRefreshURL)>
		<cfschedule URL="#theRefreshURL#" action="update" task="StatsUpdater_#theSiteName#" interval="#theDiskRefreshRate*60#" starttime="00:00:01" startdate="1/1/2000" operation="HTTPRequest">
	</cfif>
	<cfcatch type="Any">
		<!--- poo it broke CF must have thrown a wobbly or cfschedule is not allowed --->
		<cfset ret.error.ErrorExtra =  cfcatch.TagContext />
		<cflog text="Init() Scheduler set Trapped. ret.error.ErrorCode: #ret.error.ErrorCode# - Error Text: #ret.error.ErrorText# - Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#"  file="SimpleStatsErrors" type="Error" application = "yes">
		<cfif application.SLCMS.Config.debug.debugmode>
			Init() Scheduler set Trapped - error dump:<br>
			<cfdump var="#ret.error.ErrorExtra#">
		</cfif>
	</cfcatch>
	</cftry>
	
	<!--- now read in the base site structures and global data --->
	<cfif variables.Global.DataStoreMode eq "File" and len(theDataStorePath) and not DirectoryExists(theDataStorePath)>
		<!--- Oops! we've been given a bad path --->
		<cfset variables.Global.SystemStatus = "Initialization Failed" />
		<cfthrow type="Custom" detail="DataStore Path Not Found!" message="Init(): The Datastore Path:- #variables.Global.DataStorePath# does not exist">
	<cfelseif variables.Global.DataStoreMode eq "SQL" and variables.Global.DataStorePath eq "">
		<!--- test for DB existing in proper version --->
		<cfset variables.Global.SystemStatus = "Initialization Failed" />
		<cfthrow type="Custom" detail="DataStore DSN Not Found!" message="Init(): The Datastore DSN:- #variables.Global.DataStorePath# does not exist">
	</cfif>

	<cflock timeout="20" throwontimeout="No" name="initializing" type="EXCLUSIVE">
		<cfif variables.Global.DataStoreMode eq "File">
			<!--- first the global data as that tells what site we know about --->
			<cfif FileExists("#variables.global.DataStorePath#StatsGlobal.wddx")>
				<cflock timeout="20" throwontimeout="No" name="DataFileWork" type="EXCLUSIVE">
					<cfif FileExists("#variables.global.DataStorePath#StatsGlobal.wddx")>
						<cftry>
							<cffile action="read" file="#variables.global.DataStorePath#StatsGlobal.wddx" variable="thePacket" />
						<cfcatch type="Any">
							<!--- poo it broke or its a new install with no file so don't do anything --->
							<cfset GoodDecodeFlag = False />
							<cfset ret.error.ErrorExtra1 =  cfcatch.TagContext />
							<cflog text="Init() global file read Trapped. ret.error.ErrorCode: #ret.error.ErrorCode# - Error Text: #ret.error.ErrorText# - Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#"  file="SimpleStatsErrors" type="Error" application = "yes">
							<cfif application.SLCMS.Config.debug.debugmode>
								Init() global file read Trapped - error dump:<br>
								<cfdump var="#cfcatch#">
							</cfif>
						</cfcatch>
						</cftry>
					<cfelse>
						<!--- no file there so must be fresh --->
						<cfset NoMasterFlag = True />
					</cfif>
					<cfif len(thePacket) and IsWDDX(thePacket)>
						<cfset MasterPacketExists = True />
					</cfif>
				</cflock>
			<cfelse>
				<!--- no file there so must be fresh --->
				<cfset NoMasterFlag = True />
			</cfif>
		<cfelseif variables.Global.DataStoreMode eq "SQL">
			<!--- see if we have a stats database table and if so is there a statsglobal packet in in it --->
			<cfquery name="qryGetTables" datasource="#variables.Global.DataStorePath#">
				sp_tables @table_type="'TABLE'"
			</cfquery>
			<cfloop query="qryGetTables">
				<cfset thisTableName = qryGetTables.Table_Name />
				<cfif thisTableName eq "Stats_PacketStore">	<!--- this is the container for all the WDDX packets that the stats engine uses, it is the equivalent to the file store --->
					<cfset MasterTableExists = True />
					<cfquery name="getGlobalPacket" datasource="#variables.Global.DataStorePath#">
						Select	PacketStore
							From	Stats_PacketStore
							Where	PacketName = 'StatsGlobal'
					</cfquery>
					<cfif getGlobalPacket.RecordCount eq 1>
						<!--- we have a packet to read it in --->
						<cfif len(getGlobalPacket.PacketStore) and IsWDDX(getGlobalPacket.PacketStore)>
							<cfset thePacket = getGlobalPacket.PacketStore />
							<cfset MasterPacketExists = True />
						</cfif>
					<cfelse>
					</cfif>
				</cfif>
			</cfloop>
			<cfif not MasterTableExists>
				<!--- we don't have a master table yet, must be a fresh start so create it --->
				<cfquery name="createMasterControlTable" datasource="#variables.Global.DataStorePath#">
					CREATE TABLE [dbo].[Stats_PacketStore] (
						[RepID]  uniqueidentifier ROWGUIDCOL  NOT NULL ,
						[PacketName] [varchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
						[PacketStore] [text] COLLATE SQL_Latin1_General_CP1_CI_AS NULL 
					) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
					
					ALTER TABLE [dbo].[Stats_PacketStore] WITH NOCHECK ADD 
						CONSTRAINT [PK_Stats_PacketStore] PRIMARY KEY  CLUSTERED 
						(
							[RepID]
						)  ON [PRIMARY] 
					
					ALTER TABLE [dbo].[Stats_PacketStore] WITH NOCHECK ADD 
						CONSTRAINT [DF_Stats_PacketStore_RepID] DEFAULT (newid()) FOR [RepID]
					
					 CREATE  INDEX [IX_Stats_PacketStore] ON [dbo].[Stats_PacketStore]([PacketName]) ON [PRIMARY]
				</cfquery>
				<cfset MasterTableExists = True />
				<!--- and add in a blank StatsGlobal row so we always do an update --->
				<cfwddx action="CFML2WDDX" input="#variables.global#" output="thePacket" />
				<cfquery name="setPacketStore" datasource="#variables.Global.DataStorePath#">
					insert into Stats_PacketStore
										(PacketName, PacketStore)
						Values	('StatsGlobal', '#thePacket#')
				</cfquery>
			</cfif>
		</cfif>
						
		<cfif MasterPacketExists>
			<cftry>
				<cfwddx action="WDDX2CFML" output="theStruct" input="#thePacket#" />
			<cfcatch type="Any">
				<!--- poo it broke or its a new install with no file so don't do anything --->
				<cfset GoodDecodeFlag = False />
				<cfset ret.error.ErrorExtra1 =  cfcatch.TagContext />
				<cflog text="Init() global file WDDX decode Trapped. ret.error.ErrorCode: #ret.error.ErrorCode# - Error Text: #ret.error.ErrorText# - Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#"  file="SimpleStatsErrors" type="Error" application = "yes">
				<cfif application.SLCMS.Config.debug.debugmode>
					Init() global file decode Trapped - error dump:<br>
					<cfdump var="#cfcatch#">
				</cfif>
			</cfcatch>
			</cftry>
						
			<cfif GoodDecodeFlag>
				<!--- version control, needs to go here when we have a need --->
				<cfset variables.Global = Duplicate(theStruct) />
				<!--- we now have our control structure back --->
				<!--- save the status of AllowHits as we are going to turn it off whilst we load in the rest --->
				<cfset AllowHitsStatus = variables.Global.Control.AllowHits />
				<cfset variables.Global.Control.AllowHits = False />
				<!--- we should now have a list of the sites according to saved data --->
				<cfloop list="#variables.Global.SiteList#" index="thisSite">
					<!--- so get each site's session and local data --->
					<cfset GoodDecodeFlag = True />
					<cfset thisFileNamePart = application.mbc_utility.utilities.SafeStringEnCode("#thisSite#") />	<!--- the name of the file derived from its site name --->
					<cfif variables.Global.DataStoreMode eq "File">
						<cftry>
							<cffile action="read" file="#variables.Global.DataStorePath#SessionID_#thisFileNamePart#.wddx" variable="thePacket" />
						<cfcatch type="Any">
							<!--- poo it broke so don't do this one --->
							<cfset GoodDecodeFlag = False />
							<cfset ret.error.ErrorExtra2 =  cfcatch.TagContext />
							<cflog text="Init() session file read Trapped. File: SessionID_#thisFileNamePart#.wddx"  file="SimpleStatsErrors" type="Error" application = "yes">
							<cfif application.SLCMS.Config.debug.debugmode>
								Init() Session file read Trapped - error dump:<br>
								<cfdump var="#cfcatch#">
							</cfif>
						</cfcatch>
						</cftry>
					<cfelseif variables.Global.DataStoreMode eq "SQL">
						<cfquery name="getPacketStore" datasource="#variables.Global.DataStorePath#">
							Select	PacketStore
								from 	Stats_PacketStore
								where	PacketName = 'SessionID_#thisFileNamePart#'
						</cfquery>
						<cfif getPacketStore.RecordCount eq 1>
							<!--- we have a packet to read in --->
							<cfif len(getPacketStore.PacketStore) and IsWDDX(getGlobalPacket.PacketStore)>
								<cfset thePacket = getGlobalPacket.PacketStore />
							<cfelse>
								<cfset GoodDecodeFlag = False />
							</cfif>
						<cfelse>
							<cfset GoodDecodeFlag = False />
						</cfif>
					</cfif>
					<cfif GoodDecodeFlag>
						<cftry>
							<cfwddx action="WDDX2CFML" output="theStruct" input="#thePacket#" />
						<cfcatch type="Any">
							<!--- poo it broke so don't do this one --->
							<cfset GoodDecodeFlag = False />
							<cfset ret.error.ErrorExtra2 =  cfcatch.TagContext />
							<cflog text="Init() session packet decodeTrapped. File: SessionID_#thisFileNamePart#.wddx"  file="SimpleStatsErrors" type="Error" application = "yes">
							<cfif application.SLCMS.Config.debug.debugmode>
								Init() Session packet decode Trapped - error dump:<br>
								<cfdump var="#cfcatch#">
							</cfif>
						</cfcatch>
						</cftry>
					</cfif>
					<cfif GoodDecodeFlag>
						<cftry>
							<cfset variables.Sites[thisSite] = duplicate(theStruct) />
						<cfcatch type="any">
							<cfset ret.error.ErrorCode = BitOr(ret.error.ErrorCode, 2) />
							<cfset ret.error.ErrorText = ret.error.ErrorText & "#thisSite# has a bad data structure" />
							<cfset ret.error.ErrorExtra3 =  cfcatch.TagContext />
							<cflog text="Init() session structure copy Trapped. ret.error.ErrorCode: #ret.error.ErrorCode# - Error Text: #ret.error.ErrorText# - Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#"  file="SimpleStatsErrors" type="Error" application = "yes">
							<cfif application.SLCMS.Config.debug.debugmode>
								Init() Session structure copy Trapped - error dump:<br>
								<cfdump var="#cfcatch#">
							</cfif>
						</cfcatch>
						</cftry>
					<cfelse>
						<cfset ret.error.ErrorCode = BitOr(ret.error.ErrorCode, 1) />
						<cfset ret.error.ErrorText = ret.error.ErrorText & "Failed to read/decode: #thisSite#" />
					</cfif>
				</cfloop>
				<cfset variables.Global.Control.AllowHits = AllowHitsStatus />
			<cfelse>
				<cfset ret.error.ErrorCode = BitOr(ret.error.ErrorCode, 1) />
				<cfset ret.error.ErrorText = ret.error.ErrorText & "Failed to read/decode the Global Site Structure" />
			</cfif>
		</cfif>	<!--- end: inside test to see if we have a global file --->
	</cflock>	<!--- end: lock while reading global file --->

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
		<!--- wrap the whole thing in a try/catch in case something breaks --->
		<cftry>
		<cfcatch type="any">
			<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 128) />
			<cfset ret.error.ErrorText = ret.error.ErrorText & 'Oops! Error Caught, error message was: #cfcatch.message#, error detail was: #cfcatch.detail#<br>' />
			<cfset ret.error.ErrorExtra =  cfcatch.TagContext />
			<cflog text="Versioning() Trapped. ret.error.ErrorCode: #ret.error.ErrorCode# - Error Text: #ret.error.ErrorText# - Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#"  file="SimpleStatsErrors" type="Error" application = "yes">
			<cfif application.SLCMS.Config.debug.debugmode>
				Versioning() Trapped - error dump:<br>
				<cfdump var="#ret.error.ErrorExtra#">
			</cfif>
		</cfcatch>
		</cftry>
	<cfelse>	<!--- this is the error code --->
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 1) />
		<cfset ret.error.ErrorText = ret.error.ErrorText & "Oops! invalid new version supplied<br>" />
	</cfif>
	
	
	<cfreturn ret  />
</cffunction>

<cffunction name="ChecknSetSite" output="yes" returntype="struct" access="public"
	displayname="Check'n'Set Site Database"
	hint="checks if the specified database exists and if it does not creates it to stats-suitable parameters
				with three counters - PageViews, Visits and UniqueVisitors"
				>
	<!--- this function needs.... --->
	<cfargument name="SiteName" type="string" default="" />	<!--- the name of the database --->

	<!--- now all of the var declarations, first the arguments which need manipulation --->
	<cfset var theDataBaseName = trim(arguments.SiteName) />
	<!--- now vars that will get filled as we go --->
	<cfset var temp = "" />	<!--- temp/throwaway var --->
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorText = "" />
	<cfset ret.Data = "" />

	<!--- now validate and do --->
	<cfif left(theDataBaseName, 9) neq "mbcStats_">
		<cfset theDataBaseName = "mbcStats_" & theDataBaseName />
	</cfif>
	<cfif len(theDataBaseName) gt 9>
	<!--- wrap the whole thing in a try/catch in case something breaks --->
	<cftry>
		<cfif application.mbc_Utility.RRDS.getSystemStatus().data.SystemOKtoUse eq True>
			<cfif not StructKeyExists(variables.Sites, "#theDatabaseName#")>
				<!--- its not in our local datastore so create empty structure to fill --->
				<!--- first we set a lock so we don't get two being created at once --->
				<cflock name="StatsDBCreateOuter" type="exclusive" throwontimeout="false" timeout="60">
					<!--- and of course test and lock again --->
					<cfif not StructKeyExists(variables.Sites, "#theDatabaseName#")>
						<cflock name="StatsDBCreateInner" type="exclusive" throwontimeout="false" timeout="60">
							<cfset variables.sites["#theDatabaseName#"] = StructNew() />
							<cfset variables.sites["#theDatabaseName#"].TotalHits = 0 />
							<cfset variables.sites["#theDatabaseName#"].TotalVisits = 0 />
							<cfset variables.sites["#theDatabaseName#"].TotalUniques = 0 />
							<cfset variables.sites["#theDatabaseName#"].SessionID = StructNew() />
							<cfset variables.sites["#theDatabaseName#"].Changed = True />
							<cfset variables.sites["#theDatabaseName#"].BlockCounts = StructNew() />
							<cfset variables.sites["#theDatabaseName#"].BlockCounts.PageViews = 0 />
							<cfset variables.sites["#theDatabaseName#"].BlockCounts.Visits = 0 />
							<cfset variables.sites["#theDatabaseName#"].BlockCounts.UniqueVisitors = 0 />
							<cfset variables.sites["#theDatabaseName#"].Changed = True />
							<cfif not ListFindNoCase(variables.Global.SiteList, theDatabaseName)>
								<cfset variables.Global.SiteList = ListAppend(variables.Global.SiteList, "#theDatabaseName#") />
								<cfset variables.Global.SiteCount = variables.Global.SiteCount+1 />
							</cfif>
							<cfset ret.error.ErrorText = ret.error.ErrorText & "checkNset OK: Site created in Stats Global<br>" />
							<!--- then see if it is exists as a RRDB, just not locally stored yet --->
							<cfif not application.mbc_Utility.RRDS.DataBaseExists("#theDataBaseName#")>	
								<!--- It doesn't exist at all so create it with counters called PageViews, Visits & UniqueVisitors and daily,weekly,monthly and yearly tables for each --->
								<cfset temp = application.mbc_Utility.RRDS.CreateBlankRRDB(DatabaseName="#theDataBaseName#", DataStoreMode="#variables.Global.DataStoreMode#")>
								<cfset temp = application.mbc_Utility.RRDS.AddEmptyCounter(DatabaseName="#theDataBaseName#", CounterName="PageViews") />
								<cfset temp = application.mbc_Utility.RRDS.AddTables(DatabaseName="#theDataBaseName#", CounterName="PageViews") />
								<cfset temp = application.mbc_Utility.RRDS.AddEmptyCounter(DatabaseName="#theDataBaseName#", CounterName="Visits") />
								<cfset temp = application.mbc_Utility.RRDS.AddTables(DatabaseName="#theDataBaseName#", CounterName="Visits") />
								<cfset temp = application.mbc_Utility.RRDS.AddEmptyCounter(DatabaseName="#theDataBaseName#", CounterName="UniqueVisitors") />
								<cfset temp = application.mbc_Utility.RRDS.AddTables(DatabaseName="#theDataBaseName#", CounterName="UniqueVisitors") />
								<cfset ret.error.ErrorText = ret.error.ErrorText & "checkNset OK: RRDS DataStore Created<br>" />
							<cfelse>
								<!--- it was there in the RRDB so all we needed to do was add it to local store --->
								<cfset ret.error.ErrorText = ret.error.ErrorText & "checkNset OK: DataFile Existed in RRDS, copied into Stats<br>" />
							</cfif>
							<cfif variables.Global.DataStoreMode eq "SQL">
								<!--- create a blank entry to fill later --->
								<cfset thisFileNamePart = application.mbc_utility.utilities.SafeStringEnCode("#theDatabaseName#") />	<!--- the name of the file derived from its site name --->
								<cfquery name="setPacketStore" datasource="#variables.Global.DataStorePath#">
									insert into Stats_PacketStore
														(PacketName)
										Values	('SessionID_#thisFileNamePart#')
								</cfquery>
							</cfif>
						</cflock>	<!--- end: inner lock --->
					</cfif>	<!--- end: inner does it exist --->
				</cflock>	<!--- end: outer lock --->
			<cfelse>
				<!--- it was there locally but posibly not in RRDBs if things got broken so now reverse the above --->
				<!--- it was there locally so do nothing --->
				<cfset ret.error.ErrorText = ret.error.ErrorText & "checkNset OK: DataStore Already Existed in store<br>" />
			</cfif>	<!--- end: site exists check --->
		<cfelse>
			<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 2) />
			<cfset ret.error.ErrorText = ret.error.ErrorText & "RRDS service not available<br>" />
		</cfif>	<!--- end: RRDS service available --->
		<cfcatch type="any">
			<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 128) />
			<cfset ret.error.ErrorText = ret.error.ErrorText & 'Oops! Error Caught, error message was: #cfcatch.message#, error detail was: #cfcatch.detail#<br>' />
			<cfset ret.error.ErrorExtra =  cfcatch.TagContext />
			<cflog text="ChecknSetSite() Trapped. ret.error.ErrorCode: #ret.error.ErrorCode# - Error Text: #ret.error.ErrorText# - Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#"  file="SimpleStatsErrors" type="Error" application = "yes">
			<cfif application.SLCMS.Config.debug.debugmode>
				ChecknSetSite() Trapped - error dump:<br>
				<cfdump var="#ret.error.ErrorExtra#">
			</cfif>
		</cfcatch>
	</cftry>
	<cfelse>	<!--- no database name --->
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 1) />
		<cfset ret.error.ErrorText = ret.error.ErrorText & "DataStore name not supplied<br>" />
	</cfif>
	
	<cfreturn ret  />
</cffunction>

<!--- this is the function to add a full stats hit to the system, hit, visit and unique --->
<cffunction name="AddHit" output="yes" returntype="struct" access="public"
	displayname="Adds a PageView and possibly a Visit"
	hint="The base tag to add a stat, checks db existance and creates if req and adds page view and a visit according to IP address and expirytime"
				>
	<!--- this function needs.... --->
	<cfargument name="SiteName" type="string" default="" hint="the Name of the Site" />
	<cfargument name="Count" type="string" required="false" default="1" hint="the number of hits to add" />
	<cfargument name="sessionID" type="string" required="false" default="#CGI.REMOTE_ADDR#" hint="the identifier of this visit, an IP address, session var or whatever" />

	<!--- now all of the var declarations, first the arguments which need manipulation --->
	<cfset var theDataBaseName = trim(arguments.SiteName) />
	<cfset var theCount = trim(arguments.Count) />
	<cfset var thesessionID = trim(arguments.sessionID) />
	<!--- now vars that will get filled as we go --->
	<cfset var lcntr = 0 />	<!--- temp loop counter --->
	<cfset var temp = "" />	<!--- temp/throwaway var --->
	<cfset var temps = StructNew() />	<!--- temp/throwaway structure --->
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorText = "" />
	<cfset ret.Data = "" />

	<!--- see if we are taking hits or idling --->
	<cfif variables.Global.Control.AllowHits>
		<cfif application.mbc_Utility.RRDS.getSystemStatus().data.SystemOKtoUse eq True>
			<!--- now validate and do --->
			<cfif left(theDataBaseName, 9) neq "mbcStats_">
				<cfset theDataBaseName = "mbcStats_" & theDataBaseName />
			</cfif>
			<cfif IsNumeric(theCount) and len(theDataBaseName) gt 9>
				<cflock timeout="20" throwontimeout="No" name="AddHit_#theDatabaseName#" type="EXCLUSIVE">
					<!--- wrap the whole thing in a try/catch in case something breaks --->
					<cftry>
						<!--- firstly make sure we have a database for this site --->
						<cfset temps = ChecknSetSite(SiteName="#theDataBaseName#") />
						<cfif temps.error.ErrorCode eq 0>
							<cfset ret.error.ErrorText = temps.error.ErrorText />
							<!--- we have a site db so add a pageview --->
							<cfset temps = AddPageView(SiteName="#theDataBaseName#", Count="#theCount#") />
							<!--- next see if the incoming is a new visit or an old one and add a visit or not as req --->
							<cfif not StructKeyExists(variables.sites["#theDataBaseName#"].SessionID, "#thesessionID#")>
								<!--- we haven't seen this one before so create local data structure --->
								<cfset variables.sites["#theDataBaseName#"].SessionID["#thesessionID#"] = StructNew() />
								<!--- and add in as a visit --->
								<cfset variables.sites["#theDataBaseName#"].SessionID["#thesessionID#"].HitCount = 1 />
								<cfset variables.sites["#theDataBaseName#"].SessionID["#thesessionID#"].LastHit = Now() />
								<cfset temps = AddUniqueVisitor(SiteName="#theDataBaseName#", SessionID="#thesessionID#") />
								<cfset temps = AddVisit(SiteName="#theDataBaseName#", Count=1) />
							</cfif>
							<cfset IncrementValue(variables.sites["#theDataBaseName#"].SessionID["#thesessionID#"].HitCount) />
							<cfif StructKeyExists(variables.sites["#theDataBaseName#"].SessionID["#thesessionID#"], "LastHit")>
								<cfif DateDiff("n", variables.sites["#theDataBaseName#"].SessionID["#thesessionID#"].LastHit, Now()) gt 60 >
									<!--- it does exist and it has timed out so make it a new visit --->
									<cfset IncrementValue(variables.sites["#theDataBaseName#"].SessionID["#thesessionID#"].HitCount) />
									<cfset temps = AddVisit(SiteName="#theDataBaseName#", Count=1) />
								</cfif>
							<cfelse>
								<!--- its a legacy item that does not have a "lasthit" so make it --->
								<cfset variables.sites["#theDataBaseName#"].SessionID["#thesessionID#"].LastHit = Now() />
								<cfif StructKeyExists(variables.sites["#theDataBaseName#"].SessionID["#thesessionID#"], "HitCount")>
									<cfset IncrementValue(variables.sites["#theDataBaseName#"].SessionID["#thesessionID#"].HitCount) />
								<cfelse>
									<cfset variables.sites["#theDataBaseName#"].SessionID["#thesessionID#"].HitCount = 1 />
								</cfif>
								<cfset temps = AddVisit(SiteName="#theDataBaseName#", Count=1) />
							</cfif>
							<!--- refresh or create the timestamp --->
							<cfset variables.sites["#theDataBaseName#"].SessionID["#thesessionID#"].LastHit = Now() />
							<cfif not StructKeyExists(variables.sites["#theDataBaseName#"].SessionID["#thesessionID#"], "HitCount")>
								<cfset variables.sites["#theDataBaseName#"].SessionID["#thesessionID#"].HitCount = 1 />
							</cfif>
							<cfset IncrementValue(variables.sites["#theDataBaseName#"].SessionID["#thesessionID#"].HitCount) />
						<cfelse>	<!--- this is the error code --->
							<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 8) />
							<cfset ret.error.ErrorText = ret.error.ErrorText & "Oops! CheckNset failed, error was #temps.error.ErrorText#<br>" />
						</cfif>
					<cfcatch type="any">
						<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 128) />
						<cfset ret.error.ErrorText = ret.error.ErrorText & 'Oops! Error Caught, error message was: #cfcatch.message#, error detail was: #cfcatch.detail#<br>' />
						<cfset ret.error.ErrorExtra =  cfcatch.TagContext />
						<cflog text="AddHit() Trapped. ret.error.ErrorCode: #ret.error.ErrorCode# - Error Text: #ret.error.ErrorText# - Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#"  file="SimpleStatsErrors" type="Error" application = "yes">
						<cfif application.SLCMS.Config.debug.debugmode>
							AddHit() Trapped - error dump:<br>
							<cfdump var="#ret.error.ErrorExtra#">
						</cfif>
					</cfcatch>
					</cftry>
				</cflock>
			<cfelse>	<!--- no database name --->
				<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 1) />
				<cfset ret.error.ErrorText = ret.error.ErrorText & "Site name not supplied<br>" />
			</cfif>	<!--- end: legit site name test --->
		<cfelse>
			<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 2) />
			<cfset ret.error.ErrorText = ret.error.ErrorText & "RRDS service not available<br>" />
		</cfif>	<!--- end: RRDS service available --->
	<cfelse>	<!--- hits not allowed --->
		<cfset ret.error.ErrorCode =  0 />
		<cfset ret.error.ErrorText = ret.error.ErrorText & "AllowHits is Off<br>" />
	</cfif>	
	
	<cfreturn ret  />
</cffunction>

<cffunction name="AddPageView" output="yes" returntype="struct" access="public"
	displayname="Add a Page View"
	hint="Adds one or more Page Views to defined site"
				>
	<!--- this function needs.... --->
	<cfargument name="SiteName" type="string" default="" />	<!--- the name of the database --->
	<cfargument name="Count" type="string" default="1" />	<!--- the number of hits to add --->

	<!--- now all of the var declarations, first the arguments which need manipulation --->
	<cfset var theDataBaseName = trim(arguments.SiteName) />
	<cfset var theCount = trim(arguments.Count) />
	<!--- now vars that will get filled as we go --->
	<cfset var lcntr = 0 />	<!--- temp loop counter --->
	<cfset var temp = Structnew() />	<!--- temp/throwaway var --->
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
	<cfif IsNumeric(theCount) and len(theDataBaseName) gt 9>
	<!--- wrap the whole thing in a try/catch in case something breaks --->
	<cftry>
		<cfif application.mbc_Utility.RRDS.getSystemStatus().data.SystemOKtoUse eq True>
			<!--- we have a number to add to a database name so do it --->
			<!--- first check that the DB exists --->
			<cfset temp = ChecknSetSite(SiteName="#theDataBaseName#")/>
			<!--- then do the add --->
			<cfset variables.sites["#theDatabaseName#"].TotalHits = variables.sites["#theDatabaseName#"].TotalHits + theCount>
			<!--- incremental mode so just add to counter on the fly --->
			<cfset temp = application.mbc_Utility.RRDS.AddToCounter(SaveMode="#variables.Global.SaveMode#", Number="#theCount#", CounterName="PageViews", DatabaseName="#theDataBaseName#")>
			<!--- error handle the result --->
			<cfif temp.error.errorcode neq 0>
				<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 4) />
				<cfset ret.error.ErrorText = ret.error.ErrorText & "The database AddToCounter() function failed. The error code was: #temp.error.ErrorText#<br>" />
			</cfif>
			<cfif variables.Global.SaveMode eq "Block">
				<cfset IncrementValue(variables.sites["#theDatabaseName#"].BlockCounts.PageViews) />
				<cfset variables.sites["#theDatabaseName#"].Changed = True />
			</cfif>
		<cfelse>
			<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 2) />
			<cfset ret.error.ErrorText = ret.error.ErrorText & "RRDS service not available<br>" />
		</cfif>	<!--- end: RRDS service available --->
		<cfcatch type="any">
			<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 128) />
			<cfset ret.error.ErrorText = ret.error.ErrorText & 'Oops! Error Caught, error message was: #cfcatch.message#, error detail was: #cfcatch.detail#<br>' />
			<cfset ret.error.ErrorExtra =  cfcatch.TagContext />
			<cflog text="AddPageView() Trapped. ret.error.ErrorCode: #ret.error.ErrorCode# - Error Text: #ret.error.ErrorText# - Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#"  file="SimpleStatsErrors" type="Error" application = "yes">
			<cfif application.SLCMS.Config.debug.debugmode>
				AddPageView() Trapped - error dump:<br>
				<cfdump var="#ret.error.ErrorExtra#">
			</cfif>
		</cfcatch>
	</cftry>
	<cfelse>	<!--- this is the error code --->
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 1) />
		<cfset ret.error.ErrorText = ret.error.ErrorText & "No database name or number of hits was not numeric<br>" />
	</cfif>
	
	<cfreturn ret  />
</cffunction>

<cffunction name="AddVisit" output="yes" returntype="struct" access="public"
	displayname="Add a Visit"
	hint="Adds one or more visits to defined site"
				>
	<!--- this function needs.... --->
	<cfargument name="SiteName" type="string" default="" />	<!--- the name of the database --->
	<cfargument name="Count" type="string" default="1" />	<!--- the number of visits to add --->

	<!--- now all of the var declarations, first the arguments which need manipulation --->
	<cfset var theDataBaseName = trim(arguments.SiteName) />
	<cfset var theCount = trim(arguments.Count) />
	<!--- now vars that will get filled as we go --->
	<cfset var lcntr = 0 />	<!--- temp loop counter --->
	<cfset var temp = Structnew() />	<!--- temp/throwaway var --->
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
	<cfif IsNumeric(theCount) and len(theDataBaseName) gt 9>
	<!--- wrap the whole thing in a try/catch in case something breaks --->
	<cftry>
		<!--- we have a number to add to a database so do it --->
		<cfif application.mbc_Utility.RRDS.getSystemStatus().data.SystemOKtoUse eq True>
			<!--- first check that the DB exists --->
			<cfset temp = ChecknSetSite(SiteName="#theDataBaseName#")/>
			<!--- then do the add --->
			<cfset temp = application.mbc_Utility.RRDS.AddToCounter(SaveMode="#variables.Global.SaveMode#", Number="#theCount#", CounterName="Visits", DatabaseName="#theDataBaseName#")>
			<!--- error handle the result --->
			<cfif temp.error.errorcode neq 0>
				<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 4) />
				<cfset ret.error.ErrorText = ret.error.ErrorText & "The database AddToCounter() function failed. The error code was: #temp.error.ErrorText#<br>" />
			</cfif>
			<cfif variables.Global.SaveMode eq "Block">
				<cfset IncrementValue(variables.sites["#theDatabaseName#"].BlockCounts.Visits) />
				<cfset variables.sites["#theDatabaseName#"].Changed = True />
			</cfif>
		<cfelse>
			<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 2) />
			<cfset ret.error.ErrorText = ret.error.ErrorText & "RRDS service not available<br>" />
		</cfif>	<!--- end: RRDS service available --->
		<cfcatch type="any">
			<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 128) />
			<cfset ret.error.ErrorText = ret.error.ErrorText & 'Oops! Error Caught, error message was: #cfcatch.message#, error detail was: #cfcatch.detail#<br>' />
			<cfset ret.error.ErrorExtra =  cfcatch.TagContext />
			<cflog text="AddVisit() Trapped. ret.error.ErrorCode: #ret.error.ErrorCode# - Error Text: #ret.error.ErrorText# - Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#"  file="SimpleStatsErrors" type="Error" application = "yes">
			<cfif application.SLCMS.Config.debug.debugmode>
				AddVisit() Trapped - error dump:<br>
				<cfdump var="#ret.error.ErrorExtra#">
			</cfif>
		</cfcatch>
	</cftry>
	<cfelse>	<!--- this is the error code --->
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 1) />
		<cfset ret.error.ErrorText = ret.error.ErrorText & "No database name or number of visits was not numeric<br>" />
	</cfif>
	
	<cfreturn ret  />
</cffunction>

<cffunction name="AddUniqueVisitor" output="yes" returntype="struct" access="public"
	displayname="Add a new Unique Visitor"
	hint="Adds one uniquevisitor to defined site"
				>
	<!--- this function needs.... --->
	<cfargument name="SiteName" type="string" default="" />	<!--- the name of the database --->
	<cfargument name="SessionID" type="string" default="1" />	<!--- unique identifier for this session --->

	<!--- now all of the var declarations, first the arguments which need manipulation --->
	<cfset var theDataBaseName = trim(arguments.SiteName) />
	<cfset var theSessionID = trim(arguments.SessionID) />
	<!--- now vars that will get filled as we go --->
	<cfset var lcntr = 0 />	<!--- temp loop counter --->
	<cfset var temp = Structnew() />	<!--- temp/throwaway var --->
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
	<cfif len(theDataBaseName) gt 9 and theSessionID neq "">
	<!--- wrap the whole thing in a try/catch in case something breaks --->
	<cftry>
		<!--- we have a number to add to a database so do it --->
		<cfif application.mbc_Utility.RRDS.getSystemStatus().data.SystemOKtoUse eq True>
			<!--- first check that the DB exists --->
			<cfset temp = ChecknSetSite(SiteName="#theDataBaseName#")/>
			<!--- then do the add --->
			<cfset temp = application.mbc_Utility.RRDS.AddToCounter(SaveMode="#variables.Global.SaveMode#", Number="1", CounterName="UniqueVisitors", DatabaseName="#theDataBaseName#")>
			<!--- then put in the unique identifier locally --->
			<cfset variables.sites["#theDatabaseName#"].SessionID["#theSessionID#"] = StructNew() />
			<cfset variables.sites["#theDatabaseName#"].SessionID["#theSessionID#"].LastHit = Now() />
			<cfset variables.sites["#theDatabaseName#"].SessionID["#theSessionID#"].HitCount = 0 />
			<!--- error handle the result --->
			<cfif temp.error.errorcode neq 0>
				<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 4) />
				<cfset ret.error.ErrorText = ret.error.ErrorText & "The database AddToCounter() function failed. The error code was: #temp.error.ErrorText#<br>" />
			</cfif>
			<cfif variables.Global.SaveMode eq "Block">
				<cfset IncrementValue(variables.sites["#theDatabaseName#"].BlockCounts.UniqueVisitors) />
				<cfset variables.sites["#theDatabaseName#"].Changed = True />
			</cfif>
		<cfelse>
			<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 2) />
			<cfset ret.error.ErrorText = ret.error.ErrorText & "RRDS service not available<br>" />
		</cfif>	<!--- end: RRDS service available --->
		<cfcatch type="any">
			<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 128) />
			<cfset ret.error.ErrorText = ret.error.ErrorText & 'Oops! Error Caught, error message was: #cfcatch.message#, error detail was: #cfcatch.detail#<br>' />
			<cfset ret.error.ErrorExtra =  cfcatch.TagContext />
			<cflog text="AddUniqueVisitor() Trapped. ret.error.ErrorCode: #ret.error.ErrorCode# - Error Text: #ret.error.ErrorText# - Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#"  file="SimpleStatsErrors" type="Error" application = "yes">
			<cfif application.SLCMS.Config.debug.debugmode>
				AddUniqueVisitor() Trapped - error dump:<br>
				<cfdump var="#ret.error.ErrorExtra#">
			</cfif>
		</cfcatch>
	</cftry>
	<cfelse>	<!--- this is the error code --->
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 1) />
		<cfset ret.error.ErrorText = ret.error.ErrorText & "No database and/or sessionID name<br>" />
	</cfif>
	
	<cfreturn ret  />
</cffunction>

<cffunction name="getSites" output="yes" returntype="struct" access="public"
	displayname="Get Sites"
	hint="returns a list of the sites"
				>
	<cfargument name="ForceRefresh" default="No">	<!--- if yes grab all from RRDS engine --->

	<cfset var flagForceRefresh = trim(arguments.ForceRefresh) />
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorText = "" />
	<cfset ret.Data = "" />

	<!--- wrap the whole thing in a try/catch in case something breaks --->
	<cftry>
		<cfif flagForceRefresh eq "yes">
			<cfset theDatabases = application.mbc_Utility.RRDS.getDataBaseList().data />
			<cfloop list="#theDatabases#" index="thisItem">
				<cfif left(thisItem, 9) eq "mbcStats_">
					<cfset temps = ChecknSetSite(sitename="#thisItem#") />
				</cfif>
			</cfloop>
		</cfif>
		<cfif len(variables.Global.SiteList)>
			<!--- get the sites and strip off the leading "mbcStats_" as we go --->
			<cfloop list="#variables.Global.SiteList#" index="thisItem">
				<cfset ret.Data = ListAppend(ret.Data, removeChars(thisItem, 1, 9)) />
			</cfloop>
		<cfelse>	<!--- this is the error code --->
			<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 1) />
			<cfset ret.error.ErrorText = ret.error.ErrorText & "Oops! No sites available<br>" />
		</cfif>
		<cfcatch type="any">
			<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 128) />
			<cfset ret.error.ErrorText = ret.error.ErrorText & 'Oops! Error Caught, error message was: #cfcatch.message#, error detail was: #cfcatch.detail#<br>' />
			<cfset ret.error.ErrorExtra =  cfcatch.TagContext />
			<cflog text="getSites() Trapped. ret.error.ErrorCode: #ret.error.ErrorCode# - Error Text: #ret.error.ErrorText# - Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#"  file="SimpleStatsErrors" type="Error" application = "yes">
			<cfif application.SLCMS.Config.debug.debugmode>
				getSites() Trapped - error dump:<br>
				<cfdump var="#cfcatch#">
			</cfif>
		</cfcatch>
	</cftry>
	
	<cfreturn ret  />
</cffunction>

<cffunction name="getSiteCount" output="yes" returntype="struct" access="public"
	displayname="Get Site Count"
	hint="returns the number of sites in the system"
				>
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorText = "" />

	<cfset ret.Data = variables.Global.SiteCount />
	
	<cfreturn ret  />
</cffunction>

<cffunction name="GetPageViews" output="yes" returntype="struct" access="public"
	displayname="get Page View Data"
	hint="get the stats data structure for Page Views in the defined site"
				>
	<!--- this function needs.... --->
	<cfargument name="SiteName" type="string" default="" />	<!--- the name of the database --->
	<cfargument name="TableName" type="string" default="" />	<!--- the name of the table to get --->

	<!--- now all of the var declarations, first the arguments which need manipulation --->
	<cfset var theDataBaseName = trim(arguments.SiteName) />
	<cfset var theTableName = trim(arguments.TableName) />
	<!--- now vars that will get filled as we go --->
	<cfset var lcntr = 0 />	<!--- temp loop counter --->
	<cfset var temp = Structnew() />	<!--- temp/throwaway var --->
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
	<cfif len(theDataBaseName) gt 9>
	<!--- wrap the whole thing in a try/catch in case something breaks --->
	<cftry>
		<!--- we have a database to read so do it --->
		<cfif application.mbc_Utility.RRDS.getSystemStatus().data.SystemOKtoUse eq True>
			<!--- first check that the DB exists --->
			<cfset temp = ChecknSetSite(SiteName="#theDataBaseName#")/>
			<cfset temp = application.mbc_Utility.RRDS.GetCounter(TableName="#theTableName#", CounterName="PageViews", DatabaseName="#theDataBaseName#")>
			<!--- error handle the result --->
			<cfif temp.error.errorcode eq 0>
				<cfset ret.Data = temp.data />
			<cfelse>
				<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 4) />
				<cfset ret.error.ErrorText = ret.error.ErrorText & "The database getPageViews() function failed. The error code was: #temp.error.ErrorText#<br>" />
			</cfif>
		<cfelse>
			<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 2) />
			<cfset ret.error.ErrorText = ret.error.ErrorText & "RRDS service not available<br>" />
		</cfif>	<!--- end: RRDS service available --->
		<cfcatch type="any">
			<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 128) />
			<cfset ret.error.ErrorText = ret.error.ErrorText & 'Oops! Error Caught, error message was: #cfcatch.message#, error detail was: #cfcatch.detail#<br>' />
			<cfset ret.error.ErrorExtra =  cfcatch.TagContext />
			<cflog text="getPageViews() Trapped. ret.error.ErrorCode: #ret.error.ErrorCode# - Error Text: #ret.error.ErrorText# - Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#"  file="SimpleStatsErrors" type="Error" application = "yes">
			<cfif application.SLCMS.Config.debug.debugmode>
				getPageViews() Trapped - error dump:<br>
				<cfdump var="#ret.error.ErrorExtra#">
			</cfif>
		</cfcatch>
	</cftry>
	<cfelse>	<!--- this is the error code --->
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 1) />
		<cfset ret.error.ErrorText = ret.error.ErrorText & "No database name supplied<br>" />
	</cfif>
	
	<cfreturn ret  />
</cffunction>

<cffunction name="GetVisits" output="yes" returntype="struct" access="public"
	displayname="get Visit Statistics"
	hint="get the stats for visits in a defined site"
				>
	<!--- this function needs.... --->
	<cfargument name="SiteName" type="string" default="" />	<!--- the name of the database --->
	<cfargument name="TableName" type="string" default="" />	<!--- the name of the table to get --->

	<!--- now all of the var declarations, first the arguments which need manipulation --->
	<cfset var theDataBaseName = trim(arguments.SiteName) />
	<cfset var theTableName = trim(arguments.TableName) />
	<!--- now vars that will get filled as we go --->
	<cfset var lcntr = 0 />	<!--- temp loop counter --->
	<cfset var temp = Structnew() />	<!--- temp/throwaway var --->
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
	<cfif len(theDataBaseName) gt 9>
	<!--- wrap the whole thing in a try/catch in case something breaks --->
	<cftry>
		<!--- we have a database to read so do it --->
		<cfif application.mbc_Utility.RRDS.getSystemStatus().data.SystemOKtoUse eq True>
			<!--- first check that the DB exists --->
			<cfset temp = ChecknSetSite(SiteName="#theDataBaseName#")/>
			<cfset temp = application.mbc_Utility.RRDS.GetCounter(TableName="#theTableName#", CounterName="Visits", DatabaseName="#theDataBaseName#")>
			<!--- error handle the result --->
			<cfif temp.error.errorcode eq 0>
				<cfset ret.Data = temp.data />
			<cfelse>
				<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 4) />
				<cfset ret.error.ErrorText = ret.error.ErrorText & "The database getCounter() function failed. The error code was: #temp.error.ErrorText#<br>" />
			</cfif>
		<cfelse>
			<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 2) />
			<cfset ret.error.ErrorText = ret.error.ErrorText & "RRDS service not available<br>" />
		</cfif>	<!--- end: RRDS service available --->
		<cfcatch type="any">
			<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 128) />
			<cfset ret.error.ErrorText = ret.error.ErrorText & 'Oops! Error Caught, error message was: #cfcatch.message#, error detail was: #cfcatch.detail#<br>' />
			<cfset ret.error.ErrorExtra =  cfcatch.TagContext />
			<cflog text="GetVisits() Trapped. ret.error.ErrorCode: #ret.error.ErrorCode# - Error Text: #ret.error.ErrorText# - Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#"  file="SimpleStatsErrors" type="Error" application = "yes">
			<cfif application.SLCMS.Config.debug.debugmode>
				GetVisits() Trapped - error dump:<br>
				<cfdump var="#ret.error.ErrorExtra#">
			</cfif>
		</cfcatch>
	</cftry>
	<cfelse>	<!--- this is the error code --->
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 1) />
		<cfset ret.error.ErrorText = ret.error.ErrorText & "No database name supplied<br>" />
	</cfif>
	
	<cfreturn ret  />
</cffunction>

<cffunction name="GetUniqueVisitors" output="yes" returntype="struct" access="public"
	displayname="get UniqueVisitor Statistics"
	hint="get the stats for visits in a defined site"
				>
	<!--- this function needs.... --->
	<cfargument name="SiteName" type="string" default="" />	<!--- the name of the database --->
	<cfargument name="TableName" type="string" default="" />	<!--- the name of the table to get --->

	<!--- now all of the var declarations, first the arguments which need manipulation --->
	<cfset var theDataBaseName = trim(arguments.SiteName) />
	<cfset var theTableName = trim(arguments.TableName) />
	<!--- now vars that will get filled as we go --->
	<cfset var lcntr = 0 />	<!--- temp loop counter --->
	<cfset var temp = Structnew() />	<!--- temp/throwaway var --->
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
	<cfif len(theDataBaseName) gt 9>
	<!--- wrap the whole thing in a try/catch in case something breaks --->
	<cftry>
		<!--- we have a database to read so do it --->
		<cfif application.mbc_Utility.RRDS.getSystemStatus().data.SystemOKtoUse eq True>
			<!--- first check that the DB exists --->
			<cfset temp = ChecknSetSite(SiteName="#theDataBaseName#")/>
			<cfset temp = application.mbc_Utility.RRDS.GetCounter(TableName="#theTableName#", CounterName="UniqueVisitors", DatabaseName="#theDataBaseName#")>
			<!--- error handle the result --->
			<cfif temp.error.errorcode eq 0>
				<cfset ret.Data = temp.data />
			<cfelse>
				<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 4) />
				<cfset ret.error.ErrorText = ret.error.ErrorText & "The database getCounter() function failed. The error code was: #temp.error.ErrorText#<br>" />
			</cfif>
		<cfelse>
			<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 2) />
			<cfset ret.error.ErrorText = ret.error.ErrorText & "RRDS service not available<br>" />
		</cfif>	<!--- end: RRDS service available --->
		<cfcatch type="any">
			<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 128) />
			<cfset ret.error.ErrorText = ret.error.ErrorText & 'Oops! Error Caught, error message was: #cfcatch.message#, error detail was: #cfcatch.detail#<br>' />
			<cfset ret.error.ErrorExtra =  cfcatch.TagContext />
			<cflog text="GetUniqueVisitors() Trapped. ret.error.ErrorCode: #ret.error.ErrorCode# - Error Text: #ret.error.ErrorText# - Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#"  file="SimpleStatsErrors" type="Error" application = "yes">
			<cfif application.SLCMS.Config.debug.debugmode>
				GetUniqueVisitors() Trapped - error dump:<br>
				<cfdump var="#ret.error.ErrorExtra#">
			</cfif>
		</cfcatch>
	</cftry>
	<cfelse>	<!--- this is the error code --->
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 1) />
		<cfset ret.error.ErrorText = ret.error.ErrorText & "No database name supplied<br>" />
	</cfif>
	
	<cfreturn ret  />
</cffunction>

<cffunction name="getCurrentVisitors" output="yes" returntype="struct" access="public"
	displayname="get Current Visitors"
	hint="returns a list of the visitor identifiers that are valid, ie not timed out"
				>
	<!--- this function needs.... --->
	<cfargument name="SiteName" type="string" default="" />	<!--- the name of the database --->

	<!--- now all of the var declarations, first the arguments which need manipulation --->
	<cfset var theDataBaseName = trim(arguments.SiteName) />
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

	<cfif left(theDataBaseName, 9) neq "mbcStats_">
		<cfset theDataBaseName = "mbcStats_" & theDataBaseName />
	</cfif>
	<cfif len(theDataBaseName) gt 9>
	<!--- wrap the whole thing in a try/catch in case something breaks --->
	<cftry>
		<!--- grab the identifier structure for this site --->
		<!--- first check that the DB exists --->
		<cfset temp = ChecknSetSite(SiteName="#theDataBaseName#")/>
		<cfset ret.Data = variables.sites["#theDatabaseName#"].SessionID />
		<cfcatch type="any">
			<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 128) />
			<cfset ret.error.ErrorText = ret.error.ErrorText & 'Oops! Error Caught, error message was: #cfcatch.message#, error detail was: #cfcatch.detail#<br>' />
			<cfset ret.error.ErrorExtra =  cfcatch.TagContext />
			<cflog text="GetCurrentVisitors() Trapped. ret.error.ErrorCode: #ret.error.ErrorCode# - Error Text: #ret.error.ErrorText# - Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#"  file="SimpleStatsErrors" type="Error" application = "yes">
			<cfif application.SLCMS.Config.debug.debugmode>
				GetCurrentVisitors() Trapped - error dump:<br>
				<cfdump var="#ret.error.ErrorExtra#">
			</cfif>
		</cfcatch>
	</cftry>
	<cfelse>	<!--- this is the error code --->
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 1) />
		<cfset ret.error.ErrorText = ret.error.ErrorText & "Oops! No Site Name supplied<br>" />
	</cfif>
	
	<cfreturn ret  />
</cffunction>

<cffunction name="GetTotalPageViews" output="yes" returntype="struct" access="public"
	displayname="Get Page Views"
	hint="returns the page views for the specified table: daily, weekly, monthly, yearly"
				>
	<!--- this function needs.... --->
	<cfargument name="SiteName" type="string" default="" />	<!--- the name of the database --->
	<cfargument name="Tablename" type="string" default="Daily" hint="the name of the table to read" />

	<!--- now all of the var declarations, first the arguments which need manipulation --->
	<cfset var theDataBaseName = trim(arguments.SiteName) />
	<cfset var theTablename = trim(arguments.Tablename) />
	<!--- now vars that will get filled as we go --->
	<cfset var temps = StructNew() />	<!--- temp/throwaway var --->
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
	<cfif len(theDataBaseName) gt 9>
		<cfset temps = GetTotals(TableName="#theTablename#", Countername="PageViews", SiteName="#theDataBaseName#") />
		<cfif temps.error.ErrorCode neq 0>
			<!--- oops something went wrong further in so return a zero count and an error --->
			<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, temps.error.ErrorCode) />
			<cfset ret.error.ErrorText = ret.error.ErrorText & "Table data retrieval failed<br>" />
		<cfelse>
			<cfset ret.Data = temps.data />
		</cfif>
	<cfelse>	<!--- this is the error code --->
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 1) />
		<cfset ret.error.ErrorText = ret.error.ErrorText & "Oops! No site name suplied<br>" />
	</cfif>
		
	<cfreturn ret  />
</cffunction>

<cffunction name="GetTotalVisits" output="yes" returntype="struct" access="public"
	displayname="Get Visits"
	hint="returns the visits for the specified table: daily, weekly, monthly, yearly"
				>
	<!--- this function needs.... --->
	<cfargument name="SiteName" type="string" default="" />	<!--- the name of the database --->
	<cfargument name="Tablename" type="string" default="Daily" hint="the name of the table to read" />

	<!--- now all of the var declarations, first the arguments which need manipulation --->
	<cfset var theDataBaseName = trim(arguments.SiteName) />
	<cfset var theTablename = trim(arguments.Tablename) />
	<!--- now vars that will get filled as we go --->
	<cfset var temps = StructNew() />	<!--- temp/throwaway var --->
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
	<cfif len(theDataBaseName) gt 9>
		<cfset temps = GetTotals(TableName="#theTablename#", Countername="Visits", SiteName="#theDataBaseName#") />
		<cfif temps.error.ErrorCode neq 0>
			<!--- oops something went wrong further in so return a zero count and an error --->
			<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, temps.error.ErrorCode) />
			<cfset ret.error.ErrorText = ret.error.ErrorText & "Table data retrieval failed<br>" />
		<cfelse>
			<cfset ret.Data = temps.data />
		</cfif>
	<cfelse>	<!--- this is the error code --->
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 1) />
		<cfset ret.error.ErrorText = ret.error.ErrorText & "Oops! No site name suplied<br>" />
	</cfif>
		
	<cfreturn ret  />
</cffunction>

<cffunction name="GetTotalUniqueVisitors" output="yes" returntype="struct" access="public"
	displayname="Get Unique Visitors"
	hint="returns the total Unique Visitors for the specified table: daily, weekly, monthly, yearly"
				>
	<!--- this function needs.... --->
	<cfargument name="SiteName" type="string" default="" />	<!--- the name of the database --->
	<cfargument name="Tablename" type="string" default="" hint="the name of the table to read" />

	<!--- now all of the var declarations, first the arguments which need manipulation --->
	<cfset var theDataBaseName = trim(arguments.SiteName) />
	<cfset var theTablename = trim(arguments.Tablename) />
	<!--- now vars that will get filled as we go --->
	<cfset var temps = StructNew() />	<!--- temp/throwaway var --->
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
	<cfif len(theDataBaseName) gt 9>
		<cfset temps = GetTotals(TableName="#theTablename#", Countername="UniqueVisitors", SiteName="#theDataBaseName#") />
		<cfif temps.error.ErrorCode neq 0>
			<!--- oops something went wrong further in so return a zero count and an error --->
			<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, temps.error.ErrorCode) />
			<cfset ret.error.ErrorText = ret.error.ErrorText & "Table data retrieval failed<br>" />
		<cfelse>
			<cfset ret.Data = temps.data />
		</cfif>
<!--- 	
		<cfset temp = ChecknSetSite(SiteName="#theDataBaseName#")/>
		<!--- get either the single table data and loop over adding them all up --->
		<cfif len(theTablename)>
			<!--- get a specific table --->
			<cfif ListFindNocase("Daily,Weekly,Monthly,Yearly", theTablename)>
				<cfset temps = GetUniqueVisitors(TableName="#theTablename#", SiteName="#theDataBaseName#") />
				<cfif temps.error.ErrorCode neq 0>
					<!--- oops something went wrong further in so return a zero count and an error --->
					<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 16) />
					<cfset ret.error.ErrorText = ret.error.ErrorText & "Table data retrieval failed<br>" />
				<cfelse>
					<cfif StructKeyExists(temps.data, "#theTablename#")>
						<cfset tempa = temps.data["#theTablename#"] />
						<cfif IsArray("tempa") and not ArrayIsEmpty(#tempa#)>
							<!--- we have legit data there so start counting --->
							<cfloop index="lcntr" from="1" to="#ArrayLen(tempa)#">
								<cfset total = total + tempa[lcntr][2] />
							</cfloop>
						<cfelse>
							<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 8) />
							<cfset ret.error.ErrorText = ret.error.ErrorText & "table data not an array<br>" />
						</cfif>
					<cfelse>
						<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 4) />
						<cfset ret.error.ErrorText = ret.error.ErrorText & "returned structure had table data missing<br>" />
					</cfif>	<!--- end: we have a data structure --->
				</cfif>	<!--- end: error check on returned data --->
			<cfelse>
				<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 2) />
				<cfset ret.error.ErrorText = ret.error.ErrorText & "Oops! Invalid table name supplied<br>" />
			</cfif>	<!--- end: test for legit table name --->
		<cfelse>
			<!--- no table specified so give the yearly total --->
			<cfset temps = GetUniqueVisitors(TableName="Yearly", SiteName="#theDataBaseName#") />
			<cfif StructKeyExists(temps.data, "Yearly")>
				<cfset tempa = temps.data["Yearly"] />
				<cfif IsArray("tempa") and not ArrayIsEmpty(#tempa#)>
					<cfloop index="lcntr" from="1" to="#ArrayLen(tempa)#">
						<cfset total = total + tempa[lcntr][2] />
					</cfloop>
				</cfif>
			</cfif>
		</cfif>
		<cfset ret.Data = total />
 --->
	<cfelse>	<!--- this is the error code --->
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 1) />
		<cfset ret.error.ErrorText = ret.error.ErrorText & "Oops! No site name supplied<br>" />
	</cfif>
		
	<cfreturn ret  />
</cffunction>

<cffunction name="GetTotals" output="yes" returntype="struct" access="private"
	displayname="Get a Total"
	hint="returns the total count for the specified counter (PageViews, Visits, UniqueVisitors) and table (daily, weekly, monthly, yearly)"
				>
	<!--- this function needs.... --->
	<cfargument name="SiteName" type="string" default="" />	<!--- the name of the database --->
	<cfargument name="CounterName" type="string" default="" hint="the name of the counter to read" />
	<cfargument name="TableName" type="string" default="" hint="the name of the table to read" />

	<!--- now all of the var declarations, first the arguments which need manipulation --->
	<cfset var theDataBaseName = trim(arguments.SiteName) />
	<cfset var theCounterName = trim(arguments.CounterName) />
	<cfset var theTablename = trim(arguments.Tablename) />
	<!--- now vars that will get filled as we go --->
	<cfset var lcntr = 0 />	<!--- temp loop counter --->
	<cfset var tempa = ArrayNew(2) />	<!--- temp/throwaway var --->
	<cfset var temps = StructNew() />	<!--- temp/throwaway var --->
	<cfset var thisTable = ArrayNew(2) />	<!--- temp/throwaway var for table structure loop --->
	<cfset var total = 0 />	<!--- total thingy --->
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
	<cfif len(theDataBaseName) gt 9>
	<!--- wrap the whole thing in a try/catch in case something breaks --->
	<cftry>
		<cfset temp = ChecknSetSite(SiteName="#theDataBaseName#")/>
		<!--- get either the single table data and loop over adding them all up --->
		<cfif Len(theCounterName)>
			<!--- we have a counter so get the relevant table --->
			<cfif theTablename eq "">
				<!--- if we don't have a table specified get the yearly which is the big total --->
				<cfset theTablename = "Yearly">
			</cfif>
			<!--- get a specific table --->
			<cfif ListFindNocase("Daily,Weekly,Monthly,Yearly", theTablename)>
				<cfif theCounterName eq "PageViews">
					<cfset temps = GetPageViews(TableName="#theTablename#", SiteName="#theDataBaseName#") />
				<cfelseif theCounterName eq "Visits">
					<cfset temps = GetVisits(TableName="#theTablename#", SiteName="#theDataBaseName#") />
				<cfelse>
					<cfset temps = GetUniqueVisitors(TableName="#theTablename#", SiteName="#theDataBaseName#") />
				</cfif>
				<cfif temps.error.ErrorCode neq 0>
					<!--- oops something went wrong further in so return a zero count and an error --->
					<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 32) />
					<cfset ret.error.ErrorText = ret.error.ErrorText & "Table data retrieval failed, error was: #temps.error.ErrorText#<br>" />
				<cfelse>
					<cfif StructKeyExists(temps.data, "#theTablename#")>
						<cfset tempa = temps.data["#theTablename#"] />
						<cfif IsArray("#tempa#") and not ArrayIsEmpty(#tempa#)>
							<!--- we have legit data there so start counting --->
							<cfloop index="lcntr" from="1" to="#ArrayLen(tempa)#">
								<cfset total = total + tempa[lcntr][2] />
							</cfloop>
						<cfelse>
							<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 16) />
							<cfset ret.error.ErrorText = ret.error.ErrorText & "table data not an array<br>" />
						</cfif>
					<cfelse>
						<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 8) />
						<cfset ret.error.ErrorText = ret.error.ErrorText & "returned structure had table data missing<br>" />
					</cfif>	<!--- end: we have a data structure --->
				</cfif>	<!--- end: error check on returned data --->
			<cfelse>
				<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 4) />
				<cfset ret.error.ErrorText = ret.error.ErrorText & "Oops! Invalid table name supplied<br>" />
			</cfif>	<!--- end: test for legit table name --->
		<cfelse>
			<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 2) />
			<cfset ret.error.ErrorText = ret.error.ErrorText & "Oops! No Counter name supplied<br>" />
		</cfif>
		<cfset ret.Data = total />
		<cfcatch type="any">
			<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 128) />
			<cfset ret.error.ErrorText = ret.error.ErrorText & 'Oops! Error Caught, error message was: #cfcatch.message#, error detail was: #cfcatch.detail#<br>' />
			<cfset ret.error.ErrorExtra =  cfcatch.TagContext />
			<cflog text="GetTotals() Trapped. ret.error.ErrorCode: #ret.error.ErrorCode# - Error Text: #ret.error.ErrorText# - Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#"  file="SimpleStatsErrors" type="Error" application = "yes">
			<cfif application.SLCMS.Config.debug.debugmode>
				GetTotals() Trapped - error dump:<br>
				<cfdump var="#ret.error.ErrorExtra#">
			</cfif>
		</cfcatch>
	</cftry>
	<cfelse>	<!--- this is the error code --->
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 1) />
		<cfset ret.error.ErrorText = ret.error.ErrorText & "Oops! No site name supplied<br>" />
	</cfif>
		
	<cfreturn ret  />
</cffunction>

<cffunction name="SaveToDisk" output="yes" returntype="struct" access="public"
	displayname="Saves the datastores to disk"
	hint="makes sure the stats data in persistent scope gets saved to disk when called, saves global data and sites that have changed"
				>
	<!--- this function needs.... --->
	<cfargument name="SiteName" type="string" default="" />	<!--- name of the site stats to save --->
	<cfargument name="ForceAll" type="string" default="" />	<!--- flag to force every one to be saved --->

	<!--- now all of the var declarations, first the arguments which need manipulation --->
	<cfset var theDataBaseNames = variables.global.siteList />
	<!--- now vars that will get filled as we go --->
	<cfset var thisSite = "" />	<!--- temp loop counter --->
	<cfset var OK1 = True />	<!--- temp/throwaway var --->
	<cfset var OK2 = True />	<!--- temp/throwaway var --->
	<cfset var thisFileNamePart = "" />	<!--- the name of the file derived from its site name --->
	<cfset var thePacket = "" />	<!--- temp/throwaway var --->
	<cfset var temps = StructNew() />	<!--- temp/throwaway var --->
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorText = "" />
	<cfset ret.Data = "" />

	<cflock timeout="20" throwontimeout="No" name="DataStoreFileWork_SaveStats" type="EXCLUSIVE">
		<!--- first off save our global data --->
		<cftry>
			<cfwddx action="CFML2WDDX" input="#variables.global#" output="thePacket" />
			<cfif variables.Global.DataStoreMode eq "File">
				<cffile action="write" file="#variables.Global.DataStorePath#StatsGlobal.wddx" output="#thePacket#" addnewline="No" />
			<cfelseif variables.Global.DataStoreMode eq "SQL">
				<cfquery name="setPacketStore" datasource="#variables.Global.DataStorePath#">
					Update	Stats_PacketStore
						set		PacketStore = '#thePacket#'
						where	PacketName = 'StatsGlobal'
				</cfquery>
			</cfif>
			<cfcatch type="any">
				<!--- oops, something broke --->
				<cfset OK1 = False />
				<cfset ret.error.ErrorExtra =  cfcatch.TagContext />
				<cflog text="SaveToDisk() StatsGlobal.wddx file save Trapped. ret.error.ErrorCode: #ret.error.ErrorCode# - Error Text: #ret.error.ErrorText# - Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#"  file="SimpleStatsErrors" type="Error" application = "yes">
				<cfif application.SLCMS.Config.debug.debugmode>
					SaveToDisk() StatsGlobal.wddx file save Trapped - error dump:<br>
					<cfdump var="#ret.error.ErrorExtra#">
				</cfif>
			</cfcatch>
		</cftry>
		<cfif OK1>
			<cfset variables.Global.Integrity.LastSaved = Now() />
			<cfloop list="#theDataBasenames#" index="thisSite">
				<cfset OK2 = True />
				<!--- first check to see if we have changed anything --->
				<cfif StructKeyExists(variables.Sites, "#thisSite#") and variables.Sites["#thisSite#"].Changed>
					<!--- the save the site related data: session data and flags --->
					<cfset thisFileNamePart = application.mbc_utility.utilities.SafeStringEnCode("#thisSite#") />	<!--- the name of the file derived from its site name --->
					<cftry>
						<cfwddx action="CFML2WDDX" input="#variables.Sites[thisSite]#" output="thePacket" />
						<cfif variables.Global.DataStoreMode eq "File">
							<cffile action="write" file="#variables.Global.DataStorePath#SessionID_#thisFileNamePart#.wddx" output="#thePacket#" addnewline="No" />
						<cfelseif variables.Global.DataStoreMode eq "SQL">
							<cfquery name="setPacketStore" datasource="#variables.Global.DataStorePath#">
								Update	Stats_PacketStore
									set		PacketStore = '#thePacket#'
									where	PacketName = 'SessionID_#thisFileNamePart#'
							</cfquery>
						</cfif>
						<cfcatch type="any">
							<!--- oops, something broke --->
							<cfset OK2 = False />
							<cfset ret.error.ErrorExtra =  cfcatch.TagContext />
							<cflog text="SaveToDisk() SessionID_#thisFileNamePart#.wddx file save Trapped. ret.error.ErrorCode: #ret.error.ErrorCode# - Error Text: #ret.error.ErrorText# - Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#"  file="SimpleStatsErrors" type="Error" application = "yes">
							<cfif application.SLCMS.Config.debug.debugmode>
								SaveToDisk() SessionID_#thisFileNamePart#.wddx file save Trapped - error dump:<br>
								<cfdump var="#ret.error.ErrorExtra#">
							</cfif>
						</cfcatch>
					</cftry>
					<cfif OK2>
						<cfset variables.Sites[thisSite].Changed = False>
					<cfelse>	<!--- this is the error code --->
						<cfset ret.error.ErrorCode = BitOr(ret.error.ErrorCode, 4) />
						<cfset ret.error.ErrorText = ret.error.ErrorText & "SessionID File encode/save failed. Database was: #thisSite#<br>" />
					</cfif>
					<!--- then save the RRDB Datastores --->
					<cfif application.mbc_Utility.RRDS.getSystemStatus().data.SystemOKtoUse eq True>
						<!--- ToDo: make this save only if the RRDBD has not done it in last repeat interval?? --->
						<cfset temps = application.mbc_Utility.RRDS.SaveDatabase(DataBaseName="#thisSite#") />
						<cfif temps.error.ErrorCode neq 0>
							<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 2) />
							<cfset ret.error.ErrorText = ret.error.ErrorText & "Database File save didn't happen for site: #thisSite# - RRDS SaveDatabase() Failed<br>" />
						</cfif>
					<cfelse>
						<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 2) />
						<cfset ret.error.ErrorText = ret.error.ErrorText & "Database File save can't happen for site: #thisSite# - RRDS service not available<br>" />
					</cfif>	<!--- end: RRDS service available --->
				</cfif>
			</cfloop>	
		<cfelse>	<!--- this is the error code --->
			<cfset ret.error.ErrorCode = BitOr(ret.error.ErrorCode, 1) />
			<cfset ret.error.ErrorText = "Global Data File encode/save failed. Individual sites not processed<br>" />
		</cfif>
	</cflock>
	
	
	<cfreturn ret  />
</cffunction>

<cffunction name="DeleteSite" output="yes" returntype="struct" access="public"
	displayname="Delete a Site"
	hint="Deletes the specified site"
				>
	<!--- this function needs.... --->
	<cfargument name="SiteName" type="string" default="" />	<!--- the name of the database --->

	<!--- now all of the var declarations, first the arguments which need manipulation --->
	<cfset var theDataBaseName = trim(arguments.SiteName) />
	<!--- now vars that will get filled as we go --->
	<cfset var temp = "" />	<!--- temp/throwaway var --->
	<cfset var thisFileNamePart = "" />	<!--- temp/throwaway var --->
	<cfset var theFileName = "" />	<!--- temp/throwaway var --->
	<cfset var theNamePos = 0 />	<!--- temp --->
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorText = "DeleteSite()<br>" />
	<cfset ret.Data = "" />

	<cfif left(theDataBaseName, 9) neq "mbcStats_">
		<cfset theDataBaseName = "mbcStats_" & theDataBaseName />
	</cfif>
	<cfif len(theDataBaseName) gt 9>
		<!--- this is the good code --->
		<!--- wrap the whole thing in a try/catch in case something breaks --->
		<cftry>
			<cfif StructKeyExists(variables.Sites, "#theDatabaseName#")>
				<cfset temp = StructDelete(variables.Sites, "#theDatabaseName#")>
			</cfif>
			<cfset thisFileNamePart = application.mbc_utility.utilities.SafeStringEnCode("#theDatabaseName#") />	<!--- the name of the file derived from its site name --->
			<cfset theFileName = "#variables.Global.DataStorePath#SessionID_#thisFileNamePart#.wddx" />
			<cfif FileExists(theFileName)>
				<cffile action="delete" file="#theFileName#" />
			</cfif>
			<cfset theNamePos = ListFindNoCase(variables.Global.SiteList, "#theDatabaseName#") />
			<cfif theNamePos gt 0>
				<cfset variables.Global.SiteList = ListDeleteAt(variables.Global.SiteList, theNamePos) />
				<cfset variables.Global.SiteCount = variables.Global.SiteCount-1 />
			</cfif>
			<cfset temp = SaveToDisk() />
			<!--- now its gone locally so remove in RRDBs --->
			<cfset temp = application.mbc_Utility.RRDS.DeleteDatabase(DataBaseName="#theDatabaseName#") />
		<cfcatch type="any">
			<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 128) />
			<cfset ret.error.ErrorText = ret.error.ErrorText & 'Oops! Error Caught, error message was: #cfcatch.message#, error detail was: #cfcatch.detail#<br>' />
			<cfset ret.error.ErrorExtra =  cfcatch.TagContext />
			<cflog text="DeleteSite() Trapped. ret.error.ErrorCode: #ret.error.ErrorCode# - Error Text: #ret.error.ErrorText# - Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#"  file="SimpleStatsErrors" type="Error" application = "yes">
			<cfif application.SLCMS.Config.debug.debugmode>
				DeleteSite() Trapped - error dump:<br>
				<cfdump var="#ret.error.ErrorExtra#">
			</cfif>
		</cfcatch>
		</cftry>
	<cfelse>	<!--- this is the error code --->
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 1) />
		<cfset ret.error.ErrorText = ret.error.ErrorText & "Oops! no site name supplied<br>" />
	</cfif>
	
	
	<cfreturn ret  />
</cffunction>

<cffunction name="CheckDatabaseIntegrity" output="yes" returntype="struct" access="public"
	displayname="Check Database Integrity"
	hint="Checks the integrity of the named site database"
				>
	<!--- this function needs.... --->
	<cfargument name="SiteName" type="string" default="" />	<!--- the name of the database --->

	<!--- now all of the var declarations, first the arguments which need manipulation --->
	<cfset var theDataBaseName = trim(arguments.SiteName) />
	<!--- now vars that will get filled as we go --->
	<cfset var theDBStructureRet = StructNew() />	<!--- the full structure returned from the RRDS engine --->
	<cfset var theDBStructure = StructNew() />	<!--- the db structure returned from the RRDS engine .dat from above --->
	<cfset var lcntr = 0 />	<!--- temp loop counter --->
	<cfset var OK = True />	<!--- temp loop counter --->
	<cfset var OK2 = True />	<!--- temp loop counter --->
	<cfset var OK3 = True />	<!--- temp loop counter --->
	<cfset var temp = "" />	<!--- temp/throwaway var --->
	<cfset var temp1 = "" />
	<cfset var temp2 = "" />
	<cfset var temp3 = "" />
	<cfset var theHTML = "" />	<!--- the HTML to return --->
	<cfset var theStructKeyList = "" />
	<cfset var theTableCount = "" />
	<cfset var thisCounter = "" />	<!--- counter loop --->
	<cfset var thisTable = "" />	<!--- table in counter loop --->
	<cfset var thisSlot = "" />	<!--- slot in table loop --->
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
	<cfif len(theDataBaseName) gt 9>
		<cftry>
		<!--- we have a viable name so lets get the db structure and if we get one back walk thru it looking for wrongnesses --->
		<cfset theDBStructureRet = application.mbc_Utility.RRDS.getFullDatabaseStructure(DatabaseName="#theDataBaseName#")>
		<cfif theDBStructureRet.error.errorcode neq 0>
			<cfset ret.Data = theDBStructureRet.error.errorText />
		<cfelse>
			<cfset theDBStructure = theDBStructureRet.data />
			<cfsavecontent variable="theHTML">
				<!--- check the top levels and drop in if there are there --->
				<cfif not (StructKeyExists(theDBStructure, "Control") and IsStruct(theDBStructure.Control))>
					Control Structure Missing<br>
					<cfset OK = False />	<!--- flag bad so we don't drop into crazy places --->
				<cfelse>
					<!--- OK so test the four control items --->
					<cfif not (StructKeyExists(theDBStructure.Control, "CounterCount") and StructKeyExists(theDBStructure.Control, "CounterNameList") and StructKeyExists(theDBStructure.Control, "RefreshRate") and StructKeyExists(theDBStructure.Control, "StoreFullName"))>
						Control Structure missing parts, what we have is<br><cfdump var="#theDBStructure.Control#"><br>
						<cfset OK = False />
					<cfelse>
						<!--- they are all there so make sure legit, matching data in them --->
						<cfif not IsNumeric(theDBStructure.Control.CounterCount)>
							Control Structure key &quot;CounterCount&quot; is not numeric, what we have is<br><cfdump var="#theDBStructure.Control.CounterCount#"><br>
							<cfset OK = False />
						<cfelse>
							<!--- we have what could be a number so compare with the list of counternames --->
							<cfif not (theDBStructure.Control.CounterCount gt 0 and IsSimplevalue(theDBStructure.Control.CounterNameList) and ListLen(theDBStructure.Control.CounterNameList) eq theDBStructure.Control.CounterCount)>
								Control Structures &quot;CounterCount&quot; and &quot;CounterNameList&quot; do not match, what we have is<br><cfdump var="#theDBStructure.Control#"><br>
								<cfset OK = False />
							</cfif>
						</cfif>
						<cfif not IsNumeric(theDBStructure.Control.RefreshRate)>
							Control Structure &quot;RefreshRate&quot; is not numeric, what we have is<br><cfdump var="#theDBStructure.Control.RefreshRate#"><br>
						</cfif>
						<cfif not IsSimplevalue(theDBStructure.Control.StoreFullName)>
							Control Structure &quot;RefreshRate&quot; is not numeric, what we have is<br><cfdump var="#theDBStructure.Control.RefreshRate#"><br>
						</cfif>
					</cfif>
				</cfif>	<!--- end: control structure exists --->
				<cfif not StructKeyExists(theDBStructure, "Counters")>
					Counters Structure Missing<br>
				<cfelse>
					<cfif OK>	<!--- only test if we have a viable list of Counters from above --->
						<!--- first see if the actual counter structures match the control list --->
						<cfset theStructKeyList = StructKeyList(theDBStructure.Counters) />
						<cfif theDBStructure.Control.CounterCount neq ListLen(theStructKeyList)>
							The Control Structure count of Counters (#theDBStructure.Control.CounterCount#) is not the same as the number of counters in the Counter's structure which is: #ListLen(theStructKeyList)#<br>
						<cfelseif theDBStructure.Control.CounterCount neq ListLen(theDBStructure.Control.CounterNameList)>
							The Control Structure count of Counters (#theDBStructure.Control.CounterCount#) is not the same as the number of counters in the Counterlist which is: #theDBStructure.Control.CounterNameList#<br>
						<cfelse>
							<!--- correct number so see if the names match and if they do check the counter --->
							<cfloop list="#theStructKeyList#" index="thisCounter">
								<cfset OK2 = True />
								<cfif not ListFindNocase(theDBStructure.Control.CounterNameList, thisCounter)>
									The Counter Structure of #thisCounter# was not found in the Control Name List which is: #theDBStructure.Control.CounterNameList#<br>
								<cfelse>
									<!--- its there so check its integrity --->
									<!--- first check the integrity of the control structure --->
									<cfif not (StructKeyExists(theDBStructure.Counters["#thisCounter#"], "Control") and IsStruct(theDBStructure.Counters["#thisCounter#"].Control))>
										The Control Structure for the Counter &quot;#thisCounter#&quot; does not exist<br>
										<cfset OK2 = False />
									<cfelse>
										<!--- make sure every item is in the control structure --->
										<cfif not (StructKeyExists(theDBStructure.Counters["#thisCounter#"].Control, "FillValueList") and StructKeyExists(theDBStructure.Counters["#thisCounter#"].Control, "OrderedTableNames") and StructKeyExists(theDBStructure.Counters["#thisCounter#"].Control, "TableCount") and StructKeyExists(theDBStructure.Counters["#thisCounter#"].Control, "TableIntervalList") and StructKeyExists(theDBStructure.Counters["#thisCounter#"].Control, "TableNameList") and StructKeyExists(theDBStructure.Counters["#thisCounter#"].Control, "TableOrder") and StructKeyExists(theDBStructure.Counters["#thisCounter#"].Control, "TableSizeList"))>
											The Control Structure for the Counter &quot;#thisCounter#&quot; is broken. What is there is:<br><cfdump var="#theDBStructure.Counters[thisCounter].Control#"><br>
										<cfelse>
											<cfif not (StructKeyExists(theDBStructure.Counters["#thisCounter#"].Control, "TableCount") and IsNumeric(theDBStructure.Counters["#thisCounter#"].Control.TableCount))>
												The TableCount for &quot;#thisCounter#&quot; is not a number<br>
												<cfset OK2 = False />
											<cfelse>
												<!--- we have a number of tables so scan over the control data to check it all matches --->
												<cfset theTableCount = theDBStructure.Counters["#thisCounter#"].Control.TableCount />	<!--- put it in a var just for code readability --->
												<cfif not (ListLen(theDBStructure.Counters["#thisCounter#"].Control.FillValueList) eq theTableCount and ArrayLen(theDBStructure.Counters["#thisCounter#"].Control.OrderedTableNames) eq theTableCount and ListLen(theDBStructure.Counters["#thisCounter#"].Control.TableIntervalList) eq theTableCount and ListLen(theDBStructure.Counters["#thisCounter#"].Control.TableNameList) eq theTableCount and ListLen(theDBStructure.Counters["#thisCounter#"].Control.TableOrder) eq theTableCount and ListLen(theDBStructure.Counters["#thisCounter#"].Control.TableSizeList) eq theTableCount)>
													The table counts in the Control Structure for the Counter &quot;#thisCounter#&quot; do not match up. The data there is:<br><cfdump var="#theDBStructure.Counters[thisCounter].Control#"><br>
												<cfelse>
													<!--- loop over the tables for this counter --->
													<cfloop list="#theDBStructure.Counters["#thisCounter#"].Control.TableNameList#" index="thisTable">
														<!--- we have a matching set of numbers for the various table definitions so one last integrity test on the ordered names against the list of names --->
														<cfset temp1 = ArrayToList(theDBStructure.Counters["#thisCounter#"].Control.OrderedTableNames)>
														<cfif not ListFindNoCase(temp1, thisTable)>
															The Table &quot;#thisTable#&quot; could not be matched in the Array of OrderedTableNames. The data there is:<br><cfdump var="#theDBStructure.Counters[thisCounter].Control#"><br>
														<cfelse>
															<!--- we have a proper table in the control structure so check if its there as a data structure --->
															<cfif not StructKeyExists(theDBStructure.Counters["#thisCounter#"], thisTable)>
																The structure for table &quot;#thisTable#&quot; in counter &quot;#thisCounter#&quot; is missing.
															<cfelse>
																<!--- we do have a table so check its structure --->
																<!--- first the control structure --->
																<cfif not StructKeyExists(theDBStructure.Counters["#thisCounter#"]["#thisTable#"], "Control")>
																	The control structure for table &quot;#thisTable#&quot; in counter &quot;#thisCounter#&quot; is missing.
																<cfelse>
																	<cfif not (StructKeyExists(theDBStructure.Counters["#thisCounter#"]["#thisTable#"].Control, "CurrentSlot") and StructKeyExists(theDBStructure.Counters["#thisCounter#"]["#thisTable#"].Control, "FillValue") and StructKeyExists(theDBStructure.Counters["#thisCounter#"]["#thisTable#"].Control, "Interval") and StructKeyExists(theDBStructure.Counters["#thisCounter#"]["#thisTable#"].Control, "TableOrder") and StructKeyExists(theDBStructure.Counters["#thisCounter#"]["#thisTable#"].Control, "TableSize"))>
																		The control structure for table &quot;#thisTable#&quot; in counter &quot;#thisCounter#&quot; is broken. It looks like: <br><cfdump var="#theDBStructure.Counters["#thisCounter#"]["#thisTable#"].Control#"><br>
																		<cfset OK3 = False />
																	<cfelse>
																		<!--- everything is there so check data within --->
																		<cfif not (IsNumeric(theDBStructure.Counters["#thisCounter#"]["#thisTable#"].Control.CurrentSlot) and IsNumeric(theDBStructure.Counters["#thisCounter#"]["#thisTable#"].Control.FillValue) and IsNumeric(theDBStructure.Counters["#thisCounter#"]["#thisTable#"].Control.Interval) and IsNumeric(theDBStructure.Counters["#thisCounter#"]["#thisTable#"].Control.TableOrder) and IsNumeric(theDBStructure.Counters["#thisCounter#"]["#thisTable#"].Control.TableSize) )>
																			The data with the control structure for table &quot;#thisTable#&quot; in counter &quot;#thisCounter#&quot; is not numeric. It looks like: <br><cfdump var="#theDBStructure.Counters["#thisCounter#"]["#thisTable#"].Control#"><br>
																		<cfelse>
																			<!--- control data is vaguely there so see if the data side is OK --->
																			<cfif IsArray(theDBStructure.Counters["#thisCounter#"]["#thisTable#"].data)>
																				<!--- data is an array so check that tablesizes match --->
																				<cfset temp2 = ArrayLen(theDBStructure.Counters["#thisCounter#"]["#thisTable#"].data) />
																				<cfif temp2 neq theDBStructure.Counters["#thisCounter#"]["#thisTable#"].Control.TableSize>
																					The data array (#temp2# items long) in table &quot;#thisTable#&quot; in counter &quot;#thisCounter#&quot; does not match the control data size: #theDBStructure.Counters["#thisCounter#"]["#thisTable#"].Control.TableSize#<br>
																					<cfset OK3 = False />
																				<cfelseif OK3>
																					<!--- we do have a table of correct length so check it looping over every item --->
																					<cfloop from="1" to="#ArrayLen(theDBStructure.Counters["#thisCounter#"]["#thisTable#"].data)#" index="thisSlot">
																						<cfset temp3 = theDBStructure.Counters["#thisCounter#"]["#thisTable#"].data[thisSlot] />
																						<!--- first check to make sure the item has an array of two things in it --->
																						<cfif IsArray(temp3, 1)>
																							<!--- and those two things are correct --->
																							<cfif temp3[1] eq "">
																								<!--- its blank so check fill is 0 --->
																								<cfif temp3[2] neq 0>
																									The data array item #thisSlot#[2] in table &quot;#thisTable#&quot; in counter &quot;#thisCounter#&quot; is should be zero, item was: <br><cfdump var="#temp3#"><br>
																								</cfif>	<!--- end: check timestamp is a date object --->
																							<cfelse>
																								<cfif Isdate(temp3[1])>
																									<!--- data OK, so check for a number, last check! --->
																									<cfif not IsNumeric(temp3[2])>
																										The data array item #thisSlot#[2] in table &quot;#thisTable#&quot; in counter &quot;#thisCounter#&quot; is not a number, item was: <br><cfdump var="#temp3#"><br>
																									<cfelse>
																										<!--- no more :-) --->
																									</cfif>	<!--- end: check timestamp is a date object --->
																								<cfelse>
																									The data array item #thisSlot#[1] in table &quot;#thisTable#&quot; in counter &quot;#thisCounter#&quot; is not a date, item was: <br><cfdump var="#temp3#"><br>
																								</cfif>	<!--- end: check timestamp is a date object --->
																							</cfif>	<!--- end: check timestamp is blank --->
																						<cfelse>
																							The data array item #thisSlot# in table &quot;#thisTable#&quot; in counter &quot;#thisCounter#&quot; is not an array, item was: <br><cfdump var="#temp3#"><br>
																						</cfif>	<!--- end: slot has data array check --->
																					</cfloop>	<!--- end: loop over data in table --->
																				</cfif>	<!--- end: table data array size check --->
																			<cfelse>
																				The data is not an array array in table &quot;#thisTable#&quot; in counter &quot;#thisCounter#&quot;  It looks like: <br><cfdump var="#theDBStructure.Counters["#thisCounter#"]["#thisTable#"].data#"><br>
																			</cfif>	<!--- end: is data an array --->
																		</cfif>	<!--- end: table control structure data is correct test --->
																	</cfif>	<!--- end: table control structure is correct test --->
																</cfif>	<!--- end: table control structure exists test --->
															</cfif>	<!--- end: table structure exists test --->
														</cfif>	<!--- end: test that table name list and structure name list match --->
													</cfloop>	<!--- end: loop over tables --->
												</cfif>	<!--- end:  --->
											</cfif>	<!--- end: tablecount is legitmate --->
											<!--- we have a number of tables so scan over the control data to check it all matches --->
										</cfif>	<!--- end: test all items in control structure exist --->
									</cfif>	<!--- end: control structure exists --->
								</cfif>	<!--- end: this counter's' name matches --->
							</cfloop>	<!--- loop over counters --->
						</cfif>	<!--- end: counters matches list of them test --->
					</cfif>	<!--- end: OK to do it --->
				</cfif>	<!--- end: Counters struct exists test --->
<!--- 				
				<cfdump var="#theDBStructure#" expand="false">
 --->				
			</cfsavecontent>
			<cfif trim(theHTML) eq "">	<!--- no error messages --->
				<cfset ret.Data = "Checked OK!" />
			<cfelse>
				<cfset ret.Data = theHTML />
			</cfif>
		</cfif>	<!--- end: good data returned from RRDS --->
		<cfcatch type="any">
			<cfdump var="#theDBStructure#" expand="false">
			<cfdump var="#cfcatch#">
		</cfcatch>
		</cftry>
	<cfelse>	<!--- this is the error code --->
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 1) />
		<cfset ret.error.ErrorText = ret.error.ErrorText & "Oops! Database name missing<br>" />
	</cfif>
	
	
	<cfreturn ret  />
</cffunction>

<cffunction name="DumpGlobals" output="yes" returntype="string" access="public"
	displayname="Nothing"
	hint="returns a dump of the sites and global structures"
				>
	
	<cfset var theDump = "" />
	<cfsavecontent variable="theDump">
		variables.Global Structure:<br>
		<cfdump var="#variables.global#">
		variables.Sites Structure:<br>
		<cfdump var="#variables.sites#">
	</cfsavecontent>
	<cfreturn theDump  />
</cffunction>

<cffunction name="DumpSite" output="yes" returntype="struct" access="public"
	displayname="Nothing"
	hint="returns a dump of the sites and global structures"
				>
	
	<!--- this function needs.... --->
	<cfargument name="SiteName" type="string" default="" />	<!--- the name of the database --->

	<!--- now all of the var declarations, first the arguments which need manipulation --->
	<cfset var theDataBaseName = trim(arguments.SiteName) />
	<!--- temps --->
	<cfset var temps = StructNew() />	<!--- this is the functiopn call return --->
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
	<cfif len(theDataBaseName) gt 9>
		<cfset temps = application.mbc_Utility.RRDS.getFullDatabaseStructure(DatabaseName="#theDataBaseName#")/>
		<cfset ret.Data = temps.data />
		<cfif temps.error.errorcode neq 0>
			<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 2) />
			<cfset ret.error.ErrorText = ret.error.ErrorText & "Site Dump Failed, error was:<br>#temps.error.ErrorText#" />
		</cfif>
	<cfelse>	<!--- this is the error code --->
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 1) />
		<cfset ret.error.ErrorText = ret.error.ErrorText & "Oops! No site name supplied<br>" />
	</cfif>

	<cfreturn ret  />
</cffunction>

<cffunction name="ShowStatsChart" output="yes" returntype="string" access="public"
	displayname="Shows a chart of the specified stats"
	hint="returns HTML for the chart"
				>
	<!--- this function needs.... --->
	<cfargument name="SiteName" type="string" default="" />	<!--- the name of the database --->
	<cfargument name="TableName" type="string" default="" hint="the name of the table - daily to yearly, blank eq all" />
	<cfargument name="Counters" type="string" default="PageViews,Visits,UniqueVisitors" hint="the name of the counter - PageViews, Visits, UniqueVisitors, blank eq all" />
	<cfargument name="DisplayMode" type="string" default="CFChart" />	<!--- cfchart|html|Flash the type of chart produced --->

	<!--- now all of the var declarations, first the arguments which need manipulation --->
	<cfset var theDataBaseName = trim(arguments.SiteName) />
	<cfset var theTableName = trim(arguments.TableName) />
	<cfset var theWantedCounters = trim(arguments.Counters) />
	<!--- now vars that will get filled as we go --->
	<cfset var theAvailableCounters = "" />
	<cfset var theTables = "" />
	<cfset var thisCounter = "" />
	<cfset var theCountersToGet = "" />
	<cfset var CounterToGet1 = "" />
	<cfset var CounterToGet2 = "" />
	<cfset var CounterToGet3 = "" />
	<cfset var ShowPageViews = False />
	<cfset var ShowVisits = False />
	<cfset var ShowUniqueVisitors = False />
	<cfset var temp1s = StructNew() />
	<cfset var temp2s = StructNew() />
	<cfset var temp3s = StructNew() />
	<cfset var temp1 = "" />
	<cfset var temp2 = "" />
	<cfset var temp3 = "" />
	<cfset var theDataSet = ArrayNew(2) />
	<cfset var thePageViewMax = 0>
	<cfset var theVisitsMax = 0>
	<cfset var theUniquesMax = 0>
	<cfset var thePageViewTotal = 0>
	<cfset var theVisitsTotal = 0>
	<cfset var theUniquesTotal = 0>
	<cfset var theMax = 0 />
	<cfset var theScale = 0 />
	<cfset var thisHour = "" />
	<cfset var thisDateItem = "" />
	<cfset var thisColumn = "" />
	<!--- thse next are for the html table chart --->
	<cfset var theFactor = 1 />	<!--- scaling factor --->
	<cfset var theGraphHTMLString = "" />			
	<cfset var theXaxisHTMLString = "" />			
	<cfset var theXfactor = 0 />	<!--- X axis marker --->
	<cfset var theFirstXaxisColumn = 0 />
	<cfset var theSpacer = 0 />
	<cfset var Xchanged = False />
	<cfset var thePageXmin = 0 />	<!--- PageViewMin will be set to the biggest so it can shrink --->
	<cfset var thePageXmax = 0 />	<!--- set the PageViewMax will be set to the smallest so it can grow --->
	<cfset var thePageXav = 0 />	<!--- set the average --->
	<cfset var thePageXTemp = 0 />	<!--- set the interim counter --->
	<cfset var theVisitXmin = 0 />
	<cfset var theVisitXmax = 0 />	
	<cfset var theVisitXav = 0 />
	<cfset var theVisitXTemp = 0 />
	<cfset var theUniqueXmin = 0 />
	<cfset var theUniqueXmax = 0 />	
	<cfset var theUniqueXav = 0 />
	<cfset var theUniqueXTemp = 0 />
	<cfset var theXchangeCount = 1 />
	<cfset var theXspacing = 0 />
	<cfset var theXaxisSpace  = 13 />
	<cfset var theDistToEnd = 0 />
	<cfset var theOverTopDivLineHeight = 0 />	<!--- these are for when the line is above the top area --->
	<cfset var theOverTopDivLowerHeight = 0 />
	<cfset var theTopDivHigherHeight = 0 />	<!--- it sits on top of the lower data --->
	<cfset var theTopDivLineHeight = 0 />
	<cfset var theTopDivLowerHeight = 0 />
	<cfset var theMiddleDivLineHeight = 0 />
	<cfset var theBottomDivHigherHeight = 0 />
	<cfset var theBottomDivLineHeight = 0 />
	<cfset var theBottomDivLowerHeight = 0 />
	<cfset var theRubbishHeight = 0 />
	<!--- then the return strings of html code --->
	<cfset var theHTML1 = "" />	<!--- this is partial --->
	<cfset var theHTML2 = "" />	<!--- this is the return to the caller --->
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
	<cfif len(theDataBaseName) gt 9>
	<!--- wrap the whole thing in a try/catch in case something breaks --->
	<cftry>
		<!--- first check what data is available --->
		<cfset theAvailableCounters = application.mbc_Utility.RRDS.getDatabaseCounterList(DatabaseName="#theDataBaseName#").data />
		<!--- and we will loop over the whole thing for each table requested so work out what we want --->
		<cfif theTableName eq "">
			<cfset theTables = "Daily,Weekly,Monthly,Yearly" />
		<cfelse>
			<cfset theTables = theTableName />
		</cfif>
		<cfloop list="#theTables#" index="thisTable">
			<!--- loop over requested counters to make sure we have a match and gather the data --->
			<!--- reset our vars for each loop --->
			<cfset temp1s = StructNew() />
			<cfset temp2s = StructNew() />
			<cfset temp3s = StructNew() />
			<cfset theDataSet = ArrayNew(2) />
			<cfset ShowPageViews = False />
			<cfset thePageViewMax = 0 />
			<cfset thePageViewTotal = 0>
			<cfset ShowVisits = False />
			<cfset theVisitsMax = 0 />
			<cfset theVisitsTotal = 0>
			<cfset ShowUniqueVisitors = False />
			<cfset theUniquesMax = 0 />
			<cfset theUniquesTotal = 0>
			<!--- grab the data for all three at once --->
			<cfset temp1s = GetPageViews(TableName="#thisTable#", SiteName="#theDataBaseName#")>
			<cfif temp1s.error.errorcode eq 0>
				<cfset ShowPageViews = True />
				<cfset temp1 = temp1s.data[thisTable] />
			</cfif>
			<cfset temp2s = GetVisits(TableName="#thisTable#", SiteName="#theDataBaseName#")>
			<cfif temp2s.error.errorcode eq 0>
				<cfset ShowVisits = True />
				<cfset temp2 = temp2s.data[thisTable] />
			</cfif>
			<cfset temp3s = GetUniqueVisitors(TableName="#thisTable#", SiteName="#theDataBaseName#")>
			<cfif temp3s.error.errorcode eq 0>
				<cfset ShowUniqueVisitors = True />
				<cfset temp3 = temp3s.data[thisTable] />
			</cfif>
			<!--- then build an array of all of the bits we need and other bits like the max vaules so we can scale --->
			<cfloop index="thisItem" from="1" to="400">
				<cfset thePageViewTotal = thePageViewTotal + temp1[thisItem][2]>
				<cfset theVisitsTotal = theVisitsTotal + temp2[thisItem][2]>
				<cfset theUniquesTotal = theUniquesTotal + temp3[thisItem][2]>
				<cfset theDataSet[thisItem][1] = temp1[thisItem][2] />
				<cfset theDataSet[thisItem][2] = temp2[thisItem][2] />
				<cfset theDataSet[thisItem][3] = temp3[thisItem][2] />
				<cfif temp1[thisItem][1] neq "" and IsNumericDate(temp1[thisItem][1])>
					<cfif thisTable eq "Daily">
						<cfset theDataSet[thisItem][4] = TimeFormat(temp1[thisItem][1], "HH") />
					<cfelseif thisTable eq "Weekly">
						<cfset theDataSet[thisItem][4] = DateFormat(temp1[thisItem][1], "ddd") />
					<cfelseif thisTable eq "Monthly">
						<cfset theDataSet[thisItem][4] = "Week #Week(temp1[thisItem][1])#" />
					<cfelseif thisTable eq "Yearly">
						<cfset theDataSet[thisItem][4] = DateFormat(temp1[thisItem][1], "mmm") />
					</cfif>
				<cfelse>
					<cfset theDataSet[thisItem][4] = "" />
				</cfif>
				<cfif temp1[thisItem][2] gt thePageViewMax>
					<cfset thePageViewMax = temp1[thisItem][2] />
				</cfif>
				<cfif temp2[thisItem][2] gt theVisitsMax>
					<cfset theVisitsMax = temp2[thisItem][2] />
				</cfif>
				<cfif temp3[thisItem][2] gt theUniquesMax>
					<cfset theUniquesMax = temp3[thisItem][2] />
				</cfif>
			</cfloop>
<!--- 
			<cfdump var="#theDataSet#">
			<cfabort>
 --->
			
			<!--- now work out our scaling --->
			<cfset theMax = theUniquesMax />
			<cfif theVisitsMax gt theMax>
				<cfset theMax = theVisitsMax />
			</cfif>
			<cfif thePageViewMax gt theMax>
				<cfset theMax = thePageViewMax />
			</cfif>
			<!--- we now have the biggest number out of all 3 --->
			<!--- round it to a nice number to view --->
			<cfif theMax lte 10>
				<cfset theScale = 10 />
			<cfelseif theMax gt 10 and theMax lte 100>
				<cfset theScale = int(Ceiling(theMax/10) * 10) />
			<cfelseif theMax gt 100 and theMax lte 1000>
				<cfset theScale = int(Ceiling(theMax/100) * 100) />
			<cfelseif theMax gt 1000 and theMax lte 10000>
				<cfset theScale = int(Ceiling(theMax/1000) * 1000) />
			</cfif>
			<!---  and lastly a bit of cosmetic stuff --->
			<cfif thisTable eq "Daily">
				<cfset theXaxisTitle  = "Daily Statistics" />
				<cfset theXaxisSpace  = 13 />
				<cfset theFooterTitle  = "Hourly Data" />
			<cfelseif thisTable eq "Weekly">
				<cfset theXaxisTitle  = "Weekly Statistics" />
				<cfset theXaxisSpace  = 20 />
				<cfset theFooterTitle  = "Daily Data" />
			<cfelseif thisTable eq "Monthly">
				<cfset theXaxisTitle  = "Monthly Statistics" />
				<cfset theXaxisSpace  = 45 />
				<cfset theFooterTitle  = "Weekly Data" />
			<cfelseif thisTable eq "Yearly">
				<cfset theXaxisTitle  = "Yearly Statistics" />
				<cfset theXaxisSpace  = 20 />
				<cfset theFooterTitle  = "Monthly Data" />
			</cfif>
			<!--- and then make a chart --->
			<cfif (ShowPageViews or ShowVisits or ShowUniqueVisitors) and DisplayMode eq "CFChart">
			<cfsavecontent variable="theHTML1">
				<cfchart chartheight="250" chartwidth="550"
					backgroundColor="white"
					xAxisTitle="#theXaxisTitle#"
					yAxisTitle="Count"
					font="Arial"
					gridlines=6
					scaleTo=#theScale#
					showXGridlines="yes"
					showYGridlines="yes"
					showborder="yes"
					databackgroundcolor="white"
					format="jpg" showlegend="true"
					showmarkers="no" markerSize="2"
					>
					<cfif ShowUniqueVisitors>
						<cfchartseries 
							type="line"  
							seriesColor="yellow" 
							paintStyle="plain"
							seriesLabel="#theUniquesTotal# Unique Visitors"
							>
							<cfset thisHour = "" />
							<cfloop index="thisItem" from="1" to="400" step="4">
								<cfset thisDateItem = theDataSet[thisItem][4] />
								<cfif len(thisDateItem)>
									<cfset thisColumn = thisDateItem />
								<cfelse>
									<cfset thisColumn = thisHour />
								</cfif>
								<cfif thisItem eq 1>	<!--- very first column, don't want writing --->
									<cfset thisHour = thisColumn />
									<cfchartdata item="#thisColumn#" value="#theDataSet[thisItem][3]#">
								<cfelseif thisItem eq 5>	<!--- next column, make normal --->
									<cfchartdata item="#thisColumn#" value="#theDataSet[thisItem][3]#">
								<!--- 	
								<cfelseif thisItem gte 396>	<!--- last column, make blank --->
									<cfchartdata item="" value="#temp3[thisItem][2]#">
								 --->
								<cfelse>
									<cfif thisHour neq thisColumn>
										<cfset thisHour = thisColumn />
										<cfchartdata item="" value="#theDataSet[thisItem][3]#">
									<cfelse>
										<cfchartdata item="#thisColumn#" value="#theDataSet[thisItem][3]#">
									</cfif>
								</cfif>
							</cfloop>
						</cfchartseries>
					</cfif>
					
					<cfif ShowVisits>
						<cfchartseries 
							type="area"  
							seriesColor="green" 
							paintStyle="plain"
							seriesLabel="#theVisitsTotal# Visits"
							>
							<cfset thisHour = "" />
							<cfloop index="thisItem" from="1" to="400" step="4">
								<cfset thisDateItem = theDataSet[thisItem][4] />
								<cfif len(thisDateItem)>
									<cfset thisColumn = thisDateItem />
								<cfelse>
									<cfset thisColumn = thisHour />
								</cfif>
								<cfif thisItem eq 1>	<!--- very first column, don't want writing --->
									<cfset thisHour = thisColumn />
									<cfchartdata item="#thisColumn#" value="#theDataSet[thisItem][2]#">
								<cfelseif thisItem eq 5>	<!--- next column, make normal --->
									<cfchartdata item="#thisColumn#" value="#theDataSet[thisItem][2]#">
								<!--- 	
								<cfelseif thisItem gte 396>	<!--- last column, make blank --->
									<cfchartdata item="" value="#temp3[thisItem][2]#">
								 --->
								<cfelse>
									<cfif thisHour neq thisColumn>
										<cfset thisHour = thisColumn />
										<cfchartdata item="" value="#theDataSet[thisItem][2]#">
									<cfelse>
										<cfchartdata item="#thisColumn#" value="#theDataSet[thisItem][2]#">
									</cfif>
								</cfif>
							</cfloop>
						</cfchartseries>
					</cfif>
					
					<cfif ShowPageViews>
						<cfchartseries 
							type="area" 
							seriesColor="red" 
							paintStyle="light"
							valuecolumn="Page Views" 
							itemcolumn=""
							seriesLabel="#thePageViewTotal# Page Views"
							>
							<cfset thisHour = "" />
							<cfloop index="thisItem" from="1" to="400" step="4">
								<cfset thisDateItem = theDataSet[thisItem][4] />
								<cfif len(thisDateItem)>
									<cfset thisColumn = thisDateItem />
								<cfelse>
									<cfset thisColumn = thisHour />
								</cfif>
								<cfif thisItem eq 1>	<!--- very first column, don't want writing --->
									<cfset thisHour = thisColumn />
									<cfchartdata item="#thisColumn#" value="#theDataSet[thisItem][1]#">
								<cfelseif thisItem eq 5>	<!--- next column, make normal --->
									<cfchartdata item="#thisColumn#" value="#theDataSet[thisItem][1]#">
								<!--- 	
								<cfelseif thisItem gte 396>	<!--- last column, make blank --->
									<cfchartdata item="" value="#temp3[thisItem][2]#">
								 --->
								<cfelse>
									<cfif thisHour neq thisColumn>
										<cfset thisHour = thisColumn />
										<cfchartdata item="" value="#theDataSet[thisItem][1]#">
									<cfelse>
										<cfchartdata item="#thisColumn#" value="#theDataSet[thisItem][1]#">
									</cfif>
								</cfif>
							</cfloop>
						</cfchartseries>
					</cfif>
				</cfchart>
			</cfsavecontent>
			
			<cfelseif (ShowPageViews or ShowVisits or ShowUniqueVisitors) and (DisplayMode eq "HTML" or DisplayMode eq "Flash")>
				<!--- this is the HTML table version --->
				<!--- we have to scale the data ourselves unlike cfchart so loop over the array and bring it all down to size for our 150px tall table --->
				<cfset theFactor = theScale/150 />
				<cfif theFactor neq 0>
					<cfloop index="thisItem" from="1" to="400">
						<cfset theDataSet[thisItem][1] = int(theDataSet[thisItem][1]/theFactor) />
						<cfset theDataSet[thisItem][2] = int(theDataSet[thisItem][2]/theFactor) />
						<cfset theDataSet[thisItem][3] = int(theDataSet[thisItem][3]/theFactor) />
					</cfloop>
				</cfif>
				
				<!--- this bit makes the html strings for the chart and X-axis --->
				<cfset theGraphHTMLString = theGraphHTMLString & '<td><img src="blank.gif" width=3 height=6></td>' />
				<cfloop index="thisItem" from="1" to="6">
					<!--- these are the grid lines sticking out to the left of the Y axis --->
					<cfset theGraphHTMLString = theGraphHTMLString & '<td class="ChartCellBack"><img src="blank.gif" width=1 height=6></td>' />
					<cfset theXaxisHTMLString = theXaxisHTMLString & '<td></td>' />
				</cfloop>	
				<!--- now we make the left border of the chart --->		
				<cfset theGraphHTMLString = theGraphHTMLString & '<td class="ChartCellBack" bgcolor="black"><img src="blank.gif" width=1 height=6></td>' />
				<cfset theXaxisHTMLString = theXaxisHTMLString & "<td></td>" />
				<!--- then we work out where all the X-axis marks are as we need to work out our colspans --->
				<cfset theXfactor = theDataSet[1][4]>	<!--- set the timestamp to the first item --->
				<cfset theFirstXaxisColumn = 1 />
				<cfloop index="thisItem" from="1" to="399">
					<cfif thisTable eq "Daily">
						<!--- for daily stats, ie numric X axis we want the text under the marker and only every other item --->
						<cfif theXfactor neq theDataSet[thisItem][4]>
							<cfif thisItem lt (theXaxisSpace+(theXaxisSpace\2))>
								<cfset theXaxisHTMLString = theXaxisHTMLString & '<td colspan=#thisItem\2#></td>' />
							<cfelse>
								<cfset theSpacer = thisItem-theFirstXaxisColumn>
								<cfif theXfactor mod 2 eq 0>
									<cfset theXaxisHTMLString = theXaxisHTMLString & '<td colspan=#theSpacer# align="center">#theXfactor#</td>' />
								<cfelse>
									<cfset theXaxisHTMLString = theXaxisHTMLString & '<td colspan=#theSpacer# align="center"></td>' />
								</cfif>
							</cfif>
							<cfset theFirstXaxisColumn = thisItem />
							<cfset theXfactor = theDataSet[thisItem][4]>	<!--- reset the timestamp to this item --->
						</cfif>
					<cfelse>
						<!--- for the rest we want the X axis label in the middle between the markers --->
						<cfif theXfactor neq theDataSet[thisItem][4]>
							<cfif thisItem lt theXaxisSpace>
								<cfset theXaxisHTMLString = theXaxisHTMLString & '<td colspan=#thisItem#></td>' />
							<cfelse>
								<cfset theSpacer = thisItem-theFirstXaxisColumn>
								<cfset theXaxisHTMLString = theXaxisHTMLString & '<td colspan=#theSpacer# align="center">#theXfactor#</td>' />
							</cfif>
							<cfset theFirstXaxisColumn = thisItem />
							<cfset theXfactor = theDataSet[thisItem][4]>	<!--- reset the timestamp to this item --->
						</cfif>
					</cfif>
				</cfloop>
				<!--- then work out the last bit --->
				<cfset theDistToEnd = 400-thisItem>
				<cfif theDistToEnd gt 0>
					<cfset theXaxisHTMLString = theXaxisHTMLString & '<td colspan=#theDistToEnd#></td>' />
				</cfif>
				<!--- then we fill with data --->
				<cfset theXfactor = theDataSet[1][4] />	<!--- set the timestamp to the first item --->
				<cfset thePageXmin = thePageViewMax />	<!--- set the thePageXmin to the biggest so it can shrink --->
				<cfset thePageXmax = 0 />	<!--- set the thePageXmax to the smallest so it can grow --->
				<cfset thePageXav = 0 />	<!--- set the average --->
				<cfset thePageXTemp = 0 />	<!--- set the interim counter --->
				<cfset theVisitXmin = theVisitsMax />
				<cfset theVisitXmax = 0 />	
				<cfset theVisitXav = 0 />
				<cfset theVisitXTemp = 0 />
				<cfset theUniqueXmin = theUniquesMax />
				<cfset theUniqueXmax = 0 />	
				<cfset theUniqueXav = 0 />
				<cfset theUniqueXTemp = 0 />
				<cfset theXchangeCount = 1 />	<!--- how many marks on our X axis --->
				<cfset theXspacing = 0 />
				<cfloop index="thisItem" from="1" to="400">
					<cfif theDataSet[thisItem][4] neq theXfactor>
						<cfset theXfactor = theDataSet[thisItem][4]>	<!--- reset the timestamp to this item --->
						<cfset Xchanged = True />
						<cfif theXfactor eq "00" or theXfactor eq "Sun" or theXfactor eq "Week 1" or theXfactor eq "Jan">
							<!--- midnight or rolled over date-wise so flag it --->
							<cfset theGraphHTMLString = theGraphHTMLString & '<td class="ChartCellBack" bgcolor="##1111FF">' />
						<cfelse>
							<cfset theGraphHTMLString = theGraphHTMLString & '<td class="ChartCellBack" bgcolor="##999999">' />
						</cfif>
						<cfset theDistToEnd = 400-thisItem />
					<cfelse>
						<cfset theGraphHTMLString = theGraphHTMLString & '<td class="ChartCellBack">' />
						<cfset Xchanged = False />
					</cfif>
					<!--- set the interim counters --->
					<cfset thePageXTemp = thePageXTemp+theDataSet[thisItem][1] />	
					<cfset theVisitXTemp = theVisitXTemp+theDataSet[thisItem][2] />
					<cfset theUniqueXTemp = theUniqueXTemp+theDataSet[thisItem][3] />
					<cfif Xchanged>
<!--- 					
					<cfoutput><p>
					Xchanged<br>
					theXchangeCount: #theXchangeCount#<br>
					thisItem: #thisItem#<br>
					thePageXTemp: #thePageXTemp#<br>
					theVisitXTemp: #theVisitXTemp#<br>
					theUniqueXTemp: #theUniqueXTemp#
					</p></cfoutput>
					
 --->					
						<!--- we have started a new X axis section to get our max and mins --->
						<cfset theXchangeCount = theXchangeCount+1 />	<!--- how many marks on our X axis --->
						<cfif thePageXTemp gt thePageXmax>
							<cfset thePageXmax = thePageXTemp />	<!--- set the PageViewMax to this as a new max per X --->
						</cfif>
						<cfif thePageXTemp lt thePageXmin>
							<cfset thePageXmin = thePageXTemp />	<!--- set the PageViewMin down to this as a new min per X --->
						</cfif>
						<cfif theVisitXTemp gt theVisitXmax>
							<cfset theVisitXmax = theVisitXTemp />
						</cfif>
						<cfif theVisitXTemp lt theVisitXmin>
							<cfset theVisitXmin = theVisitXTemp />
						</cfif>
						<cfif theUniqueXTemp gt theUniqueXmax>
							<cfset theUniqueXmax = theUniqueXTemp />
						</cfif>
						<cfif theUniqueXTemp lt theUniqueXmin>
							<cfset theUniqueXmin = theUniqueXTemp />
						</cfif>
						<cfset thePageXTemp = 0 />	
						<cfset theVisitXTemp = 0 />
						<cfset theUniqueXTemp = 0 />
					</cfif>
					<!--- work out where to put the line and work out the heights needed --->
					<cfset theOverTopDivLineHeight = 0 />	<!--- these are for when the line is above the top area --->
					<cfset theOverTopDivLowerHeight = 0 />
					<cfset theTopDivHigherHeight = int(theDataSet[thisItem][1]-theDataSet[thisItem][2]) />	<!--- it sits on top of the lower data --->
					<cfset theTopDivLineHeight = 0 />
					<cfset theTopDivLowerHeight = 0 />
					<cfset theMiddleDivLineHeight = 0 />
					<cfset theBottomDivHigherHeight = 0 />
					<cfset theBottomDivLineHeight = 0 />
					<cfset theBottomDivLowerHeight = int(theDataSet[thisItem][2]) />
					<!--- see if the line is in the bottom area --->
					<cfif theDataSet[thisItem][3] lt theDataSet[thisItem][2]>
						<!--- it is so make a line --->
						<cfset theBottomDivLineHeight = 1 />
						<cfset theBottomDivLowerHeight = int(theDataSet[thisItem][3]) />
						<cfset theBottomDivHigherHeight = int(theDataSet[thisItem][2]-theDataSet[thisItem][3]-1) />
					<cfelseif theDataSet[thisItem][3] eq theDataSet[thisItem][2]>
						<!--- its exactly between so drop it in above bottom one --->
						<cfset theMiddleDivLineHeight = 1 />
						<cfset theTopDivLowerHeight = int(theTopDivLowerHeight-1) />
					<cfelseif theDataSet[thisItem][3] gt theDataSet[thisItem][2] and theDataSet[thisItem][3] lt theDataSet[thisItem][1]>
						<!---  its in the top section --->
						<cfset theTopDivLineHeight = 1 />
						<cfset theTopDivLowerHeight = int(theDataSet[thisItem][3]-theDataSet[thisItem][2]-1) />
						<cfset theTopDivHigherHeight = int(theTopDivHigherHeight-theTopDivLowerHeight-1) />
					<cfelseif theDataSet[thisItem][3] gte theDataSet[thisItem][1] and theDataSet[thisItem][3] gte theDataSet[thisItem][2]>
						<!---  its right over the top! --->
						<!--- but there could be rubbish below so work out how tall that rubbish is --->
						<cfset theRubbishHeight = int(theDataSet[thisItem][2]) />
						<cfif theDataSet[thisItem][1] gt theRubbishHeight>
							<cfset theRubbishHeight = int(theDataSet[thisItem][1]) />
						</cfif>
						<cfset theOverTopDivLineHeight = 1 />
						<cfset theOverTopDivLowerHeight = int(theDataSet[thisItem][3]-theRubbishHeight-1) />
					</cfif>
					<!--- work out if this is an X axis marker --->
					
					<!--- now write the needed html for this cell --->
					<cfif theOverTopDivLineHeight gt 0>
						<cfset theGraphHTMLString = theGraphHTMLString & '<img src="blankY.gif" width=1 height=#theOverTopDivLineHeight#>' />
					</cfif>
					<cfif theOverTopDivLowerHeight gt 0>
						<cfset theGraphHTMLString = theGraphHTMLString & '<img src="blank.gif" width=1 height=#theOverTopDivLowerHeight#>' />
					</cfif>
					<cfif theTopDivHigherHeight gt 0>
						<cfset theGraphHTMLString = theGraphHTMLString & '<img src="blankR.gif" width=1 height=#theTopDivHigherHeight#>' />
					</cfif>
					<cfif theTopDivLineHeight gt 0>
						<cfset theGraphHTMLString = theGraphHTMLString & '<img src="blankY.gif" width=1 height=#theTopDivLineHeight#>' />
					</cfif>
					<cfif theTopDivLowerHeight gt 0>
						<cfset theGraphHTMLString = theGraphHTMLString & '<img src="blankR.gif" width=1 height=#theTopDivLowerHeight#>' />
					</cfif>
					<cfif theMiddleDivLineHeight gt 0>
						<cfset theGraphHTMLString = theGraphHTMLString & '<img src="blankY.gif" width=1 height=#theMiddleDivLineHeight#>' />
					</cfif>
					<cfif theBottomDivHigherHeight gt 0>
						<cfset theGraphHTMLString = theGraphHTMLString & '<img src="blankG.gif" width=1 height=#theBottomDivHigherHeight#>' />
					</cfif>
					<cfif theBottomDivLineHeight gt 0>
						<cfset theGraphHTMLString = theGraphHTMLString & '<img src="blankY.gif" width=1 height=#theBottomDivLineHeight#>' />
					</cfif>
					<cfif theBottomDivLowerHeight gt 0>
						<cfset theGraphHTMLString = theGraphHTMLString & '<img src="blankG.gif" width=1 height=#theBottomDivLowerHeight#>' />
					</cfif>
					<cfset theGraphHTMLString = theGraphHTMLString & '<img src="blank.gif" width=1 height=8>' />
					<cfset theGraphHTMLString = theGraphHTMLString & "</td>" />
				</cfloop>
				<cfset theGraphHTMLString = theGraphHTMLString & '<td class="ChartCellBack" bgcolor="black"><img src="blank.gif" width=1 height=8></td>' />
				<cfset theXaxisHTMLString = theXaxisHTMLString & "<td></td>" />
				<!--- now we have all of the table cells worked out --->
				<!--- work out the average counts --->
				<cfset theXchangeCount = theXchangeCount-1 />	<!--- offset from initial 1 --->
				<cfif theXchangeCount neq 0>	<!--- don't want a nasty! --->
					<cfset thePageXav = thePageViewTotal\theXchangeCount />
					<cfset theVisitXav = theVisitsTotal\theXchangeCount />
					<cfset theUniqueXav = theUniquesTotal\theXchangeCount />
				</cfif>
				<!--- so make the table --->
				<cfsavecontent variable="theHTML1">
				<cfoutput>
				<style type="text/css" media="screen">
				.GraphTable {
					font-family:verdana,sans-serif;
					font-size:10px;
				}
				.GraphTitle {
					font-size:12px;
				}
				.GraphHigher {
					width:1px;
					background-color:red;
					background-image:url('blank.gif');
				}
				.GraphLine {
					width:1px;
					background-color:yellow;
					background-image:url('blank.gif');
				}
				.GraphLower {
					width:1px;
					background-color:green;
					background-image:url('blank.gif');
				}
				.GraphOverTopLineLower {
					width:1px;
				}
				.ChartCellBack {
					background-image:url('ChartBack6.gif');
					width:1px;
				}
				.GraphFooter {
					font-size:10px;
					line-height:15px;
				}
				
				</style>
					
				<table cellpadding="0" cellspacing="0" width="500" border="0" class="GraphTable">
					<tr>
						<td bgcolor="black"><img src="blank.gif" width=1 height=1 border=0></td>
						<td bgcolor="black"><img src="blank.gif" width=92 height=1 border=0></td>
						<td bgcolor="black"><img src="blank.gif" width=140 height=1 border=0></td>
						<td bgcolor="black"><img src="blank.gif" width=140 height=1 border=0></td>
						<td bgcolor="black"><img src="blank.gif" width=140 height=1 border=0></td>
						<td rowspan=13 bgcolor="black"><img src="blank.gif" width=1 height=233 border=0></td>
						</tr>
					<tr>
						<td bgcolor="black"><img src="blank.gif" width=1 height=55 border=0></td>
						<td colspan="4" height="55" align="center">
							<p class="GraphTitle">#theXaxisTitle#</p>
							<p><img src="blankR.gif" width=10 height=10 border=0> #thePageViewTotal# Page Views &nbsp; &nbsp;
							<img src="blankG.gif" width=10 height=10 border=0> #theVisitsTotal# Visits &nbsp; &nbsp;
							<img src="blankY.gif" width=20 height=2 border=0> #theUniquesTotal# Unique Visitors</p>
						</td>
						</tr>
					<tr>
						<td bgcolor="black"><img src="blank.gif" width=1 height=15 border=0></td>
						<td rowspan="2" align="right"><cfif DisplayMode eq "HTML">#theScale#</cfif></td>
						<td colspan="3"><img src="blank.gif" width=1 height=15 border=0></td>
						</tr>
					<tr>
						<td bgcolor="black"><img src="blank.gif" width=1 height=15 border=0></td>
						<td colspan="3" rowspan="7" valign="top">
						<cfif DisplayMode eq "HTML">
							<table cellpadding="0" cellspacing="0" border="0" class="GraphTable">
								<tr valign="bottom">
									<td><img src="blank.gif" width=1 height=158 border=0></td>
								#theGraphHTMLString#
								</tr>
								<tr valign="bottom">
									<td><img src="blank.gif" width=1 height=15 border=0></td>
								#theXaxisHTMLString#
								</tr>
							</table>
						<cfelseif DisplayMode eq "Flash">
							<object classid="clsid:d27cdb6e-ae6d-11cf-96b8-444553540000" codebase="http://fpdownload.macromedia.com/pub/shockwave/cabs/flash/swflash.cab##version=8,0,0,0" width="400" height="158" id="graph-2" align="middle">
								<param name="allowScriptAccess" value="sameDomain" /> 
								<param name="movie" value="open-flash-chart.swf?width=500&height=250&data=http://teethgrinder.co.uk/open-flash-chart/data-2.php" /> 
								<param name="quality" value="high" />
								<param name="bgcolor" value="##FFFFFF" /> 
								<embed src="open-flash-chart.swf?width=400&height=158&data=http://teethgrinder.co.uk/open-flash-chart/data-2.php" quality="high" bgcolor="##FFFFFF" width="400" height="158" name="open-flash-chart" align="middle" allowScriptAccess="sameDomain" type="application/x-shockwave-flash" pluginspage="http://www.macromedia.com/go/getflashplayer" /> 
							</object>
						</cfif>
						</td></tr>
					<tr>
						<td bgcolor="black"><img src="blank.gif" width=1 height=30 border=0></td>
						<td align="right" valign="middle"><cfif DisplayMode eq "HTML">#int(theScale*0.8)#</cfif></td>
						</tr>
					<tr>
						<td bgcolor="black"><img src="blank.gif" width=1 height=30 border=0></td>
						<td align="right" valign="middle"><cfif DisplayMode eq "HTML">#int(theScale*0.6)#</cfif></td>
						</tr>
					<tr>
						<td bgcolor="black"><img src="blank.gif" width=1 height=30 border=0></td>
						<td align="right" valign="middle"><cfif DisplayMode eq "HTML">#int(theScale*0.4)#</cfif></td>
						</tr>
					<tr>
						<td bgcolor="black"><img src="blank.gif" width=1 height=30 border=0></td>
						<td align="right" valign="middle"><cfif DisplayMode eq "HTML">#int(theScale*0.2)#</cfif></td>
						</tr>
					<tr>
						<td bgcolor="black"><img src="blank.gif" width=1 height=15 border=0></td>
						<td rowspan="2" align="right" valign="middle"><cfif DisplayMode eq "HTML">0</cfif></td>
						</tr>
					<tr>
						<td bgcolor="black"><img src="blank.gif" width=1 height=15 border=0></td>
						</tr>
					<tr>
						<td bgcolor="black"><img src="blank.gif" width=1 height=18 border=0></td>
						<td align="center">#theFooterTitle#</td>	
						<td><img src="blank.gif" width=10 height=1 border=0> Page Views</td>	
						<td><img src="blank.gif" width=10 height=1 border=0> Visits</td>	
						<td><img src="blank.gif" width=20 height=1 border=0> Unique Visitors</td>	
						</tr>
					<tr>
						<td bgcolor="black"><img src="blank.gif" width=1 height=60 border=0></td>
						<td align="Right">
							<p class="GraphFooter">Maximum: </p>
							<p class="GraphFooter">Average: </p>
							<p class="GraphFooter">Minimum: </p>
						</td>
						<td>
							<p class="GraphFooter"><img src="blankR.gif" width=10 height=10 border=0> #thePageXmax#</p>
							<p class="GraphFooter"><img src="blankR.gif" width=10 height=10 border=0> #thePageXav#</p>
							<p class="GraphFooter"><img src="blankR.gif" width=10 height=10 border=0> #thePageXmin#</p>
						</td>
						<td>
							<p class="GraphFooter"><img src="blankG.gif" width=10 height=10 border=0> #theVisitXmax#</p>
							<p class="GraphFooter"><img src="blankG.gif" width=10 height=10 border=0> #theVisitXav#</p>
							<p class="GraphFooter"><img src="blankG.gif" width=10 height=10 border=0> #theVisitXmin#</p>
						</td>
						<td>
							<p class="GraphFooter"><img src="blankY.gif" width=20 height=2 border=0> #theUniqueXmax#</p>
							<p class="GraphFooter"><img src="blankY.gif" width=20 height=2 border=0> #theUniqueXav#</p>
							<p class="GraphFooter"><img src="blankY.gif" width=20 height=2 border=0> #theUniqueXmin#</p>
						</td>
						</tr>
					<tr>
						<td bgcolor="black"><img src="blank.gif" width=1 height=1 border=0></td>
						<td bgcolor="black"><img src="blank.gif" width=92 height=1 border=0></td>
						<td colspan="3" bgcolor="black"><img src="blank.gif" width=420 height=1 border=0></td>
						</tr>
				</table>
				</cfoutput>	
				</cfsavecontent>
			<cfelse>
				<cfset theHTML1 = "No Data Available" />
			</cfif>
			<cfset theHTML2 = theHTML2 & theHTML1 />
		</cfloop>	<!--- end: loop over tables --->
		<cfcatch type="any">
			<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 128) />
			<cfset ret.error.ErrorText = ret.error.ErrorText & 'Oops! Error Caught, error message was: #cfcatch.message#, error detail was: #cfcatch.detail#<br>' />
			<cfset ret.error.ErrorExtra =  cfcatch.TagContext />
			<cflog text="ShowStatsChart() Trapped. ret.error.ErrorCode: #ret.error.ErrorCode# - Error Text: #ret.error.ErrorText# - Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#"  file="SimpleStatsErrors" type="Error" application = "yes">
			<cfif application.SLCMS.Config.debug.debugmode>
				ShowStatsChart() Trapped - error dump:<br>
				<cfdump var="#cfcatch#">
			</cfif>
		</cfcatch>
	</cftry>
	</cfif>	<!--- end: legitmate database/site name --->
	
	<cfreturn theHTML2  />
</cffunction>

<cffunction name="Control_AllowHits" output="yes" returntype="struct" access="public"
	displayname="Control function for Allowing Hits"
	hint="Turns on the switch that controls allowing hits to be recorded, global or single site">
		
	<!--- this function needs.... --->
	<cfargument name="SiteName" type="string" default="" />	<!--- the name of the database --->

	<!--- now all of the var declarations, first the arguments which need manipulation --->
	<cfset var theDataBaseName = trim(arguments.SiteName) />
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

	<cfif theDataBaseName eq "">
		<!--- we have no name so turn the lot on --->
		<cfset variables.Global.Control.AllowHits = True />
	<cfelse>
		<!--- there is a name so make it legit and handle that site --->
		<cfif left(theDataBaseName, 9) neq "mbcStats_">
			<cfset theDataBaseName = "mbcStats_" & theDataBaseName />
		</cfif>
		<cfif len(theDataBaseName) gt 9>
			<!--- ToDo: add site specific code --->
		<cfelse>	<!--- this is the error code --->
			<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 1) />
			<cfset ret.error.ErrorText = ret.error.ErrorText & "Oops! Bad site name supplied<br>" />
		</cfif>
	</cfif>
	
	<cfreturn ret  />
</cffunction>

<cffunction name="Control_DisAllowHits" output="yes" returntype="struct" access="public"
	displayname="Control function for Disallowing Hits"
	hint="Turns off the switch that controls allowing hits to be recorded, global or single site">
		
	<!--- this function needs.... --->
	<cfargument name="SiteName" type="string" default="" />	<!--- the name of the database --->

	<!--- now all of the var declarations, first the arguments which need manipulation --->
	<cfset var theDataBaseName = trim(arguments.SiteName) />
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

	<cfif theDataBaseName eq "">
		<!--- we have no name so turn the lot on --->
		<cfset variables.Global.Control.AllowHits = False />
	<cfelse>
		<!--- there is a name so make it legit and handle that site --->
		<cfif left(theDataBaseName, 9) neq "mbcStats_">
			<cfset theDataBaseName = "mbcStats_" & theDataBaseName />
		</cfif>
		<cfif len(theDataBaseName) gt 9>
			<!--- ToDo: add site specific code --->
		<cfelse>	<!--- this is the error code --->
			<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 1) />
			<cfset ret.error.ErrorText = ret.error.ErrorText & "Oops! Bad site name supplied<br>" />
		</cfif>
	</cfif>
	
	<cfreturn ret  />
</cffunction>

<cffunction name="Control_GetAllowHitsStatus" output="yes" returntype="struct" access="public"
	displayname="Control function get Allowing Hits status"
	hint="get the status of the switch that controls allowing hits to be recorded, global or single site">
		
	<!--- this function needs.... --->
	<cfargument name="SiteName" type="string" default="" />	<!--- the name of the database --->

	<!--- now all of the var declarations, first the arguments which need manipulation --->
	<cfset var theDataBaseName = trim(arguments.SiteName) />
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

	<cfif theDataBaseName eq "">
		<!--- we have no name so use the global var --->
		<cfset ret.Data = variables.Global.Control.AllowHits />
	<cfelse>
		<!--- there is a name so make it legit and handle that site --->
		<cfif left(theDataBaseName, 9) neq "mbcStats_">
			<cfset theDataBaseName = "mbcStats_" & theDataBaseName />
		</cfif>
		<cfif len(theDataBaseName) gt 9>
			<!--- ToDo: add site specific code --->
		<cfelse>	<!--- this is the error code --->
			<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 1) />
			<cfset ret.error.ErrorText = ret.error.ErrorText & "Oops! Bad site name supplied<br>" />
		</cfif>
	</cfif>
	
	<cfreturn ret  />
</cffunction>

<cffunction name="emptyFunction" output="yes" returntype="struct" access="public"
	displayname="Nothing"
	hint="this is just a shell to copy"
				>
	<!--- this function needs.... --->
	<cfargument name="SiteName" type="string" default="" />	<!--- the name of the database --->

	<!--- now all of the var declarations, first the arguments which need manipulation --->
	<cfset var theDataBaseName = trim(arguments.SiteName) />
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

	<cfif left(theDataBaseName, 9) neq "mbcStats_">
		<cfset theDataBaseName = "mbcStats_" & theDataBaseName />
	</cfif>
	<cfif len(theDataBaseName) gt 9>
		<!--- this is the good code --->
		<!--- wrap the whole thing in a try/catch in case something breaks --->
		<cftry>
		<cfcatch type="any">
			<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 128) />
			<cfset ret.error.ErrorText = ret.error.ErrorText & 'Oops! Error Caught, error message was: #cfcatch.message#, error detail was: #cfcatch.detail#<br>' />
			<cfset ret.error.ErrorExtra =  cfcatch.TagContext />
			<cflog text="emptyFunction() Trapped. ret.error.ErrorCode: #ret.error.ErrorCode# - Error Text: #ret.error.ErrorText# - Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#"  file="SimpleStatsErrors" type="Error" application = "yes">
			<cfif application.SLCMS.Config.debug.debugmode>
				emptyFunction() Trapped - error dump:<br>
				<cfdump var="#ret.error.ErrorExtra#">
			</cfif>
		</cfcatch>
		</cftry>
	<cfelse>	<!--- this is the error code --->
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 1) />
		<cfset ret.error.ErrorText = ret.error.ErrorText & "Oops!<br>" />
	</cfif>
	
	
	<cfreturn ret  />
</cffunction>

</cfcomponent>
	
	
	