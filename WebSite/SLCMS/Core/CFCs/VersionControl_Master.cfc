<cfcomponent output="False"
	displayname="Version Control" 
	hint="Manages the codebase versioning and related database table creation/modification activity" 
	>
<!--- mbc SLCMS CFCs  --->
<!--- &copy; 2011 mort bay communications --->
<!---  --->
<!--- VersionControl_Master.CFC  --->
<!--- Manages the codebase versioning and related database table creation/modification activity
			calls ancilary CFCs to do these tasks, not stored persistently like the main CFCs --->
<!--- Contains:
			init - set up structures for the cfc, just the database really
			lots more related stuff :-)
			 --->
<!---  --->
<!--- created:   5th Sep 2009 by Kym K, mbcomms --->
<!--- modified:  6th Sep 2009 - 22nd Sep 2009 by Kym K, mbcomms: initial work on it --->
<!--- modified:  2nd Jan 2010 -  2nd Jan 2010 by Kym K, mbcomms: adding in versioning code bit by bit --->
<!--- modified: 18th Feb 2011 - 18th Feb 2011 by Kym K, mbcomms: ran varScoper over code and found one un-var'd variable! oops, one too many :-/  --->
<!--- modified:  7th Jun 2011 -  8th Jun 2011 by Kym K, mbcomms: added logging functions so we can have consistent logging outside CF's logs --->
<!--- modified:  9th Apr 2012 -  9th Apr 2012 by Kym K, mbcomms: V3.0, CFWheels version. All SLCMS in own struct under app scope --->

	
	<!--- set up a few persistant things on the way in. --->
	<cfset variables.theDSN = "" />	<!--- the database it all lives in --->
	<cfset variables.CFCsPath = "" />	<!--- path to where to find the cofe CFCs, we call the other version ones on the fly --->
	<cfset variables.VersionPath = "" />	<!--- the path to the version config files --->
	<cfset variables.theSAuser = "" />	<!--- the login that has admin privaleges to create DBs --->
	<cfset variables.theSApassword = "" />	<!--- the login password that has admin privaleges to create DBs --->
	<cfset variables.theSiteUser = "" />	<!--- the login that is going to be used for this site, needs dbo privilege --->
	<cfset variables.theSitePassword = "" />	<!--- the login password that is going to be used for this site, needs dbo privilege --->
	<cfset variables.CurrentVersion = StructNew() />	<!--- struct to carry the current version setup --->
	<cfset variables.CurrentVersion.Path = "" />
	<cfset variables.CurrentVersion.VersionNumber_Full = "" />
	<cfset variables.CurrentVersion.VersionNumber_Major = "" />
	<cfset variables.CurrentVersion.VersionNumber_Minor = "" />
	<cfset variables.CurrentVersion.VersionNumber_Dot = "" />
	<cfset variables.CurrentVersion.VersionDate = "" />
	<cfset variables.CurrentVersion.Revision = "" />
	<cfset variables.CurrentVersion.CodeFolderRelPath = "" />
	<cfset variables.CurrentVersion.DataBaseFolderRelPath = "" />
	<cfset variables.NextVersion = StructNew() />	<!--- struct to carry the current version setup --->
	<cfset variables.NextVersion.Path = "" />
	<cfset variables.NextVersion.VersionNumber_Full = "" />
	<cfset variables.NextVersion.VersionNumber_Major = "" />
	<cfset variables.NextVersion.VersionNumber_Minor = "" />
	<cfset variables.NextVersion.VersionNumber_Dot = "" />
	<cfset variables.NextVersion.VersionDate = "" />
	<cfset variables.NextVersion.Revision = "" />
	<cfset variables.NextVersion.CodeFolderRelPath = "" />
	<cfset variables.NextVersion.DataBaseFolderRelPath = "" />

<!--- initialize the various thingies, this should only be called after an app scope refresh --->
<cffunction name="init" output="No" returntype="any" access="public"
	displayname="Initializer"
	hint="sets up the internal structures for this component"
	>
	<!--- this function needs.... --->
	<cfargument name="config" type="struct" default="" />	<!--- the application.SLCMS.Config struct so we can work out stuff --->
	<cfargument name="CFCsPath" type="string" default="" />	<!--- where to find the CFCs --->
	<cfargument name="databaseSystemName" type="string" default="" />	<!--- where to find the version control files/data --->
	<!--- 
	<cfargument name="SiteDSN" type="string" default="" />	<!--- the name of the Datasource for this SLCMS instance --->
	 --->
	
	<cfset var theVersionControlTable = "" />
	<cfset var getVersionTable = "" />
	<cfset var getActiveVersion = "" />
	<cfset var bVersionTableExists = True />
	<!--- the DAL structures we use everywhere --->
	<cfset var theQueryDataArguments = StructNew() />	<!--- temp struct to compose the data clauses of SQL queries --->
	<cfset var theQueryWhereArguments = StructNew() />	<!--- temp struct to compose the where clauses of SQL queries --->
	<cfset var theQueryWhereFilters = ArrayNew(1) />	<!--- temp array to compose the filters for where clauses --->

	<cfset temps = LogIt(LogType="CFC_Init", LogString="Version Control-Master Init() Started") />
	
	<cfset variables.theDSN = "#arguments.config.datasources.CMS#" />
	<cfset variables.VersionPath = "#arguments.config.StartUp.InstallationFilesPath#Versions/" />
	<cfset variables.CFCsPath = trim(arguments.CFCsPath) />
	<cfset variables.databaseSystemName_Base = trim(arguments.databaseSystemName) />
	<cfset theVersionControlTable = "#variables.databaseSystemName_Base#Version_ControlXX" />

	<!--- first we grab the current version from the DB --->
	<!--- set up a base version set that will do if we are not yet versioned --->
	<cfset variables.CurrentVersion.VersionNumber_Full = "Unknown" />
	<cfset variables.CurrentVersion.VersionNumber_Major = "0" />
	<cfset variables.CurrentVersion.VersionNumber_Minor = "0" />
	<cfset variables.CurrentVersion.VersionNumber_Dot = "0" />
	<cfset variables.CurrentVersion.VersionDate = "" />
	<cfset variables.CurrentVersion.InstallDate = "" />
	<cfset variables.CurrentVersion.Revision = "" />
	<!--- if we are moving up from a legacy codebase there might not be anything in the db at all so lets load the table and see if we error --->
	<cftry>
		<cfset getVersionTable = application.SLCMS.Core.DataMgr.loadTable(tablename="#theVersionControlTable#") />
	<cfcatch>
		<!--- if we catch the table isn't there --->
		<cfset bVersionTableExists = False />
	</cfcatch>
	</cftry>
	<cfif bVersionTableExists>
		<cfset theQueryWhereArguments.flag_ActiveVersion = 1 />	<!--- make up the specialist query we need --->
		<cfset getActiveVersion = application.SLCMS.Core.DataMgr.getRecords(tablename="#theVersionControlTable#", data=theQueryWhereArguments, fieldList="flag_ActiveVersion,VersionNumber_Full,VersionNumber_Major,VersionNumber_Minor,VersionNumber_Dot,VersionNumber_Revision,VersionDate,InstallDate,ThroughDate") />
		<cfif getActiveVersion.RecordCount>
			<cfset variables.CurrentVersion.VersionNumber_Full = getActiveVersion.VersionNumber_Full />
			<cfset variables.CurrentVersion.VersionNumber_Major = getActiveVersion.VersionNumber_Major />
			<cfset variables.CurrentVersion.VersionNumber_Minor = getActiveVersion.VersionNumber_Minor />
			<cfset variables.CurrentVersion.VersionNumber_Dot = getActiveVersion.VersionNumber_Dot />
			<cfset variables.CurrentVersion.VersionDate = getActiveVersion.VersionDate />
			<cfset variables.CurrentVersion.InstallDate = getActiveVersion.InstallDate />
			<cfset variables.CurrentVersion.Revision = getActiveVersion.VersionNumber_Revision />
		</cfif>
	<cfelse>	
	</cfif>
	<cfset variables.CurrentVersion.CodeFolderName = "Code_#variables.CurrentVersion.VersionNumber_Major#_#variables.CurrentVersion.VersionNumber_Minor#_#variables.CurrentVersion.VersionNumber_Dot#" />
	<cfset variables.CurrentVersion.DataBaseFolderName = "DB_#variables.CurrentVersion.VersionNumber_Major#_#variables.CurrentVersion.VersionNumber_Minor#_#variables.CurrentVersion.VersionNumber_Dot#" />

	<cfset temps = LogIt(LogType="CFC_Init", LogString="Version Control-Master Init() Finished") />
	<cfreturn True />
</cffunction>

<cffunction name="getVersionMasterConfig" output="No" returntype="struct" access="public"
	displayname="get Version Master Config"
	hint="returns the master config data, dsn, current version, etc"
	>

	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with the relevant variables --->
	<cfset ret.CurrentVersion = variables.CurrentVersion />
	<cfset ret.dsn = variables.theDSN />
	<cfset ret.VersionPath = variables.VersionPath />

	<cfreturn ret  />
</cffunction>

<cffunction name="CreateSubSite" output="No" returntype="struct" access="public"
	displayname="Create SubSite"
	hint="Creates a SubSite: DB tables; folder structure"
	>
	<!--- this function needs.... --->
	<cfargument name="SubSiteID" type="string" default="" />	<!--- the ID of the subsite to make --->
	<cfargument name="SubSiteShortName" type="string" default="" />	<!--- the short name of the subsite to make the folder structure --->

	<!--- now all of the var declarations, first the arguments which need manipulation --->
	<cfset var theSubSiteID = trim(arguments.SubSiteID) />
	<cfset var theSubSiteShortName = trim(arguments.SubSiteShortName) />
	<!--- now vars that will get filled as we go --->
	<cfset var cfcVersions_Database = "" />	<!--- will be the CFC to drive DB --->
	<cfset var cfcVersions_Folders = "" />	<!--- will be the CFC to drive folders --->
	<cfset var temp = "" />	<!--- temp/throwaway var --->
	<cfset var tempa = ArrayNew(1) />	<!--- temp/throwaway array --->
	<cfset var temps = StructNew() />	<!--- temp/throwaway structure --->
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorContext = "VersionControl_Master CFC: CreateSubSite()" />
	<cfset ret.error.ErrorText = "" />
	<cfset ret.error.ErrorExtra = "" />
	<cfset ret.Data = "" />	<!--- and no data yet --->

		<!--- validation --->
	<cfif len(theSubSiteShortName) neq "" and theSubSiteID gt 0>
		<!--- validated so go for it --->
		<!--- wrap the whole thing in a try/catch in case something breaks --->
		<cftry>
			<!--- first create the database tables --->
			<cfset cfcVersions_Database = createObject("component","#application.SLCMS.Config.base.MapURL##variables.CFCsPath#VersionControl_Database") /><!--- this CFC has the functions for database control --->
			<cfset temps = cfcVersions_Database.CreateSubSiteTables(subSiteID="#theSubSiteID#") />
			<cfif temps.error.errorcode neq 0>	
				<!--- oops something went wrong --->
				<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 4) />
				<cfset ret.error.ErrorText = ret.error.ErrorText & 'Table Creation Failed. Error was: #temps.error.ErrorText#' />
			</cfif>
			<!--- then create the folder structure --->
			<cfset cfcVersions_Folders = createObject("component","#application.SLCMS.Config.base.MapURL##variables.CFCsPath#VersionControl_Folders") /><!--- this CFC has the functions for folder control --->
			<cfset temps = cfcVersions_Folders.CreateSubSiteFolders(SubSiteShortName="#theSubSiteShortName#") />
			<cfif temps.error.errorcode neq 0>	
				<!--- oops something went wrong --->
				<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 8) />
				<cfset ret.error.ErrorText = ret.error.ErrorText & 'Folder Creation Failed. Error was: #temps.error.ErrorText#' />
			</cfif>
		<cfcatch type="any">
			<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 128) />
			<cfset ret.error.ErrorText = ret.error.ErrorContext & ' Trapped. Site: #application.SLCMS.Config.base.SiteName#, error message was: #cfcatch.message#, error detail was: #cfcatch.detail#' />
			<cfset ret.error.ErrorExtra =  cfcatch.TagContext />
			<cfif isArray(ret.error.ErrorExtra) and StructKeyExists(ret.error.ErrorExtra[1], "Raw_Trace")>
				<cfset ret.error.ErrorText = ret.error.ErrorText & ", Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#" />
			</cfif>
			<cflog text='#ret.error.ErrorText# - ret.error.ErrorCode: #ret.error.ErrorCode# - Time: #DateFormat(Now(),"YYYYMMDD")#-#TimeFormat(now(),"HH:mm:ss")#'  file="#Application.SLCMS.Logging.theSiteLogName#" type="Error" application = "yes">
			<cfif application.SLCMS.Config.debug.debugmode>
				<cfoutput>#ret.error.ErrorContext#</cfoutput> Trapped - error dump:<br>
				<cfdump var="#cfcatch#">
			</cfif>
		</cfcatch>
		</cftry>
	<cfelse>	<!--- this is the error code --->
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 1) />
		<cfset ret.error.ErrorText = ret.error.ErrorText & "Oops! bad arguments. Short Name was: #theSubSiteShortName#; ID was: #theSubSiteID#<br>" />
	</cfif>
	<cfif ret.error.ErrorCode neq 0>
		<cflog text="#ret.error.ErrorContext# #ret.error.ErrorText# - ret.error.ErrorCode: #ret.error.ErrorCode# - Time: #DateFormat(Now(),"YYYYMMDD")#-#TimeFormat(now(),"HH:mm:ss")#"  file="#Application.SLCMS.Logging.theSiteLogName#" type="Error" application = "yes">
	</cfif>

	<!--- return our data structure --->
	<cfreturn ret  />
</cffunction>

<cffunction name="LogIt" output="No" returntype="struct" access="Private"
	displayname="Log It"
	hint="Local Function to log info to standard log space via application.SLCMS.Core.SLCMS_Utility.WriteLog_Core(), minimizes log code in individual functions"
	>
	<cfargument name="LogType" type="string" default="" hint="The log to write to" />
	<cfargument name="LogString" type="string" default="" hint="The string to write to the log" />

	<cfset var theLogType = trim(arguments.LogType) />
	<cfset var theLogString = trim(arguments.LogString) />
	<cfset var temps = StructNew() />	<!--- temp/throwaway structure --->
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorText = "" />
	<cfset ret.error.ErrorContext = "VersionControl_Master CFC: LogIt()" />
	<cfset ret.error.ErrorExtra = "" />
	<cfset ret.Data = "" />	<!--- no data --->

		<!--- validation --->
	<cfif theLogType neq "">
		<cftry>
			<cfset temps = application.SLCMS.Core.SLCMS_Utility.WriteLog_Core(LogType="#theLogType#", LogString="#theLogString#") />
			<cfif temps.error.errorcode neq 0>
				<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 2) />
				<cfset ret.error.ErrorText = ret.error.ErrorText & "Log Write Failed. Error was: #temps.error.ErrorText#<br>" />
			</cfif>
		<cfcatch type="any">
			<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 128) />
			<cfset ret.error.ErrorText = ret.error.ErrorContext & ' Trapped. Site: #application.SLCMS.Config.base.SiteName#, error message was: #cfcatch.message#, error detail was: #cfcatch.detail#' />
			<cfset ret.error.ErrorExtra =  cfcatch.TagContext />
			<cfif isArray(ret.error.ErrorExtra) and StructKeyExists(ret.error.ErrorExtra[1], "Raw_Trace")>
				<cfset ret.error.ErrorText = ret.error.ErrorText & ", Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#" />
			</cfif>
			<cflog text='#ret.error.ErrorText# - ret.error.ErrorCode: #ret.error.ErrorCode# - Time: #DateFormat(Now(),"YYYYMMDD")#-#TimeFormat(now(),"HH:mm:ss")#'  file="#Application.SLCMS.Logging.theSiteLogName#" type="Error" application = "yes">
			<cfif application.SLCMS.Config.debug.debugmode>
				<cfoutput>#ret.error.ErrorContext#</cfoutput> Trapped - error dump:<br>
				<cfdump var="#cfcatch#">
			</cfif>
		</cfcatch>
		</cftry>
	<cfelse>	<!--- this is the error code --->
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 1) />
		<cfset ret.error.ErrorText = ret.error.ErrorText & "Oops! Unknown Log<br>" />
	</cfif>

	<cfreturn ret  />
</cffunction>

<cffunction name="getVariablesScope"output="No" returntype="struct" access="public"  
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

</cfcomponent>