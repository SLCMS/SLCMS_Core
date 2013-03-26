<cfcomponent output="False"
	displayname="Version Control-Database" 
	hint="Manages the database versioning and related database table creation/modification activity. Non-persistent" 
	>
<!--- mbc SLCMS CFCs  --->
<!--- &copy; 2011 mort bay communications --->
<!---  --->
<!--- VersionControl_Database.CFC  --->
<!--- Manages the database table versioning and related creation/modification activity --->
<!--- Contains:
			init - set up structures for the cfc, just the database really
			lots more related stuff :-)
			 --->
<!---  --->
<!--- created:   5th Sep 2009 by Kym K, mbcomms --->
<!--- modified:  5th Sep 2009 - 19th Sep 2009 by Kym K, mbcomms: initial work on it --->
<!--- modified: 18th Feb 2011 - 18th Feb 2011 by Kym K, mbcomms: ran varScoper over code and found one un-var'd variable! oops, one too many :-/  --->
<!--- modified:  7th Jun 2011 -  8th Jun 2011 by Kym K, mbcomms: added logging functions so we can have consistent logging outside CF's logs --->
<!--- modified: 18th Aug 2011 - 18th Aug 2011 by Kym K, mbcomms: changed subSite creation to use DataMgr --->
<!--- modified:  9th Apr 2012 -  9th Apr 2012 by Kym K, mbcomms: V3.0, CFWheels version. All SLCMS in own struct under app scope --->

	
	<!--- set up a few things on the way in, normally not inited as this CFC is not persistent, each function can grab the dsn, etc., details if not set --->
	<cfset variables.InitSet = False />	<!--- flags that we don't know anything yet --->
	<cfset variables.theDSN = "" />	<!--- the database it all lives in --->
	<cfset variables.CurrentVersion = StructNew() />	<!--- the current version data --->
	<cfset variables.versionPath = "" />	<!--- where to find the version files --->
	
	<cfset variables.theSAuser = "" />	<!--- the login that has admin privaleges to create DBs --->
	<cfset variables.theSApassword = "" />	<!--- the login password that has admin privaleges to create DBs --->
	<cfset variables.theSiteUser = "" />	<!--- the login that is going to be used for this site, needs dbo privilege --->
	<cfset variables.theSitePassword = "" />	<!--- the login password that is going to be used for this site, needs dbo privilege --->

<!--- initialize the various thingies, gets called on the fly as the CFC is not persistent --->
<cffunction name="init" output="No" returntype="any" access="public" 
	displayname="Initializer"
	hint="sets up the internal structures for this component"
	>
	<cfset var thegetRet = "" />
	<cfset temps = LogIt(LogType="CFC_Init", LogString="VersionControl-Database Init() Started") />
	<!--- if we don't have a dsn grab it from the master CFC --->
	<cfif variables.theDSN eq "">
		<cfset thegetRet = application.SLCMS.Core.Versions_Master.getVersionMasterConfig() />
	</cfif>
	<cfset variables.theDSN = thegetRet.dsn />	<!--- the database it all lives in --->
	<cfset variables.CurrentVersion = thegetRet.CurrentVersion />	<!--- the database it all lives in --->
	<cfset variables.versionPath = thegetRet.versionPath />	<!--- the database it all lives in --->
	<cfset variables.InitSet = True />
	
	<cfset temps = LogIt(LogType="CFC_Init", LogString="Version ontrol-Database Init() Finished") />
	<cfreturn True />
</cffunction>

<cffunction name="CreateSubSiteTables" output="yes" returntype="struct" access="public"
	displayname="Create SubSite Tables"
	hint="Creates the complete set of tables used in a SubSite"
	>
	<!--- this function needs.... --->
	<cfargument name="SubSiteID" type="string" default="" />	<!--- the ID of the subsite --->

	<!--- now all of the var declarations, first the arguments which need manipulation --->
	<cfset var theSubSiteID = trim(arguments.SubSiteID) />
	<!--- now vars that will get filled as we go --->
	<cfset var theCurrentConfig = "" />
	<cfset var theFileName = "" />	<!--- temp var for the file name that the code is in --->
	<cfset var theFolderName = "" />	<!--- temp var for the folder name that the SQL file is in --->
	<cfset var theFileFullPath = "" />	<!--- temp var for the full path to the SQL file --->
	<cfset var theSQLFileContents = "" />	<!--- temp var for the contents of the file --->
	<cfset var CreateSubSiteSet = "" />
	<cfset var theFinalSQL = "" />	<!--- temp var for the final SQL from the file with variables evaluated --->
	<cfset var theTableNamePrefix = application.SLCMS.Config.DatabaseDetails.DatabaseTableNaming_Root_Site />	<!--- first part of the table name, we add the subsite id after this using the delimiter specified below --->
	<cfset var theTableNameDelimiter = application.SLCMS.Config.DatabaseDetails.TableNaming_Delimiter />	<!--- the delim we need to use in the naming format --->
	<cfset var temps = StructNew() />	<!--- temp/throwaway structure --->
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorContext = "VersionControl_Database CFC: CreateSubSiteTables()" />
	<cfset ret.error.ErrorText = "" />
	<cfset ret.error.ErrorExtra = "" />
	<cfset ret.Data = "" />	<!--- and no data yet --->

	<!--- grab the current version data so we know what to create --->
	<cfif not variables.InitSet>
		<cfset init() />
	</cfif>
<!--- 	
	<cfdump var="#variables#" expand="false">
	<cfabort>
 --->	
	<cfif len(theSubSiteID) and theSubSiteID neq 0>
		<!--- validated so go for it --->
		<!--- wrap the whole thing in a try/catch in case something breaks --->
		<cftry>
			<cfset theVersionPath = "#application.SLCMS.Config.startup.DataFolderPath#Versions/Current_Version/" />
			<cfset theVersionIniFilePath = "#theVersionPath#WorkFlow_NewInstall.ini" />
			<cfif FileExists(theVersionIniFilePath)>
	  		<cftry>
					<cfset theXMLTableFileCount = getProfileString(theVersionIniFilePath, "subSiteTables", "ItemCount") />
					<cfif theXMLTableFileCount>
						<!--- we have some definitions to load so lets do it --->
						<cfloop from="1" to="#theXMLTableFileCount#" index="thisItem">
							<cfset theTableDefFileName = getProfileString(theVersionIniFilePath, "subSiteTables", "Item_#thisItem#") />
							<cfset theTableDefFileName = theVersionPath & theTableDefFileName & ".xml" />
							<!--- we are now pointing at a database definition xml file so load into the DAL --->
			  			<cfif FileExists(theTableDefFileName)>
								<cftry>
									<cffile action="read" file="#theTableDefFileName#" variable="theXML" >
									<!--- "theXML" now has the table defs for subSite0 so we have to change to ths subSiteID --->
									<cfset theXML = ReplaceNoCase(theXML, "Site_0_", "Site_#theSubSiteID#_", "all") />
	
		<cfdump var="#theXML#" expand="false" label="theXML">
		<!---
		<cfabort>
		--->							
									
									<cfset LoadRet = application.SLCMS.Core.DataMgr.loadXML(xmldata=theXML, docreate=True, addcolumns=True)>	<!---  with the two true flags this will create table and columns --->
								<cfcatch>
									<cfset ret.error.ErrorCode = BitOr(ret.error.errorCode, 8) />
									<cfset ret.error.ErrorText = ret.error.ErrorText & "The Database Definition load of #theTableDefFileName# Failed.<br>" />
	
		<cfdump var="#cfcatch#" expand="false" label="cfcatch">
		
								</cfcatch>
								</cftry>
			  			<cfelse>
								<cfset ret.error.ErrorText = ret.error.ErrorText & "Error: The Database XML Definition File is missing!" />
								<cfset ret.error.ErrorText = ret.error.ErrorText & '<br>Was looking for: #theTableDefFileName#' />
								<cfset ret.error.ErrorCode = BitOr(ret.error.errorCode, 16) />
			  			</cfif>
						</cfloop>
					</cfif>
				<cfcatch>
					<cfset ret.error.ErrorText = ret.error.ErrorText & "Error: The Database creation failed!" />
					<cfset ret.error.ErrorText = ret.error.ErrorText & '<br>Error was: #cfcatch.message#, error detail was: #cfcatch.detail#' />
					<cfset ret.error.errorCode = BitOr(application.SLCMS.Config.startup.initialization.installationTemp["#theFlow#"].Steps["Step_2"].error.errorCode, 32) />
				</cfcatch>
	  		</cftry>
			<cfelse>
				<cfset ret.error.errorCode = BitOr(application.SLCMS.Config.startup.initialization.installationTemp["#theFlow#"].Steps["Step_2"].error.errorCode, 4) />
				<cfset ret.error.ErrorText = ret.error.ErrorText & "Error: The Database Definition Control File is Missing!" />
			</cfif>



			<!---
			<cfset theFileName = "SubSite_CreateTables_V#variables.CurrentVersion.CodeBase.VersionNumber_Major#-#variables.CurrentVersion.CodeBase.VersionNumber_Minor#-#variables.CurrentVersion.CodeBase.VersionNumber_Dot#-sql.cfm" />
			<cfset theFolderName = "DB_#variables.CurrentVersion.CodeBase.VersionNumber_Major#_#variables.CurrentVersion.CodeBase.VersionNumber_Minor#_#variables.CurrentVersion.CodeBase.VersionNumber_Dot#/" />
			<cfset theFileFullPath = variables.versionPath & theFolderName & theFileName />
			<cfif FileExists("#theFileFullPath#")>
				<!--- we have a file so grab its contents --->
				<cffile action="read" file="#theFileFullPath#" variable="theSQLFileContents">
				<!--- set up the full naming prefix for the tables --->
				<cfset theTableNamePrefix = theTableNamePrefix & theSubSiteID & theTableNameDelimiter />
				<!--- replace the variables --->
				<cfset theFinalSQL = ReplaceNoCase(theSQLFileContents, "[^[theTableNameDelimiter]^]", "#theTableNameDelimiter#", "all") />
				<cfset theFinalSQL = ReplaceNoCase(theFinalSQL, "[^[theTableNamePrefix]^]", "#theTableNamePrefix#", "all") />
				<!--- and then create the tables --->
				<cfquery name="CreateSubSiteSet" datasource="#variables.theDSN#">
					#PreserveSingleQuotes(theFinalSQL)#
				</cfquery>
			<cfelse>
				<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 2) />
				<cfset ret.error.ErrorText = ret.error.ErrorText & "SQL file not found <br>" />
			</cfif>
			--->
		<cfcatch type="any">
			<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 128) />
			<cfset ret.error.ErrorText = ret.error.ErrorContext & " Trapped. Site: #application.SLCMS.Config.base.SiteName#, error message was: #cfcatch.message#, error detail was: #cfcatch.detail#" />
			<cfset ret.error.ErrorExtra =  cfcatch.TagContext />
			<cfif isArray(ret.error.ErrorExtra) and StructKeyExists(ret.error.ErrorExtra[1], "Raw_Trace")>
				<cfset ret.error.ErrorText = ret.error.ErrorText & ", Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#" />
			</cfif>
			<cflog text='#ret.error.ErrorText# - ret.error.ErrorCode: #ret.error.ErrorCode# - Time: #DateFormat(Now(),"YYYYMMDD")#-#TimeFormat(now(),"HH:mm:ss")#'  file="#Application.Logging.theSiteLogName#" type="Error" application = "yes">
			<cfif application.SLCMS.Config.debug.debugmode>
				<cfoutput>#ret.error.ErrorContext#</cfoutput> Trapped - error dump:<br>
				<cfdump var="#cfcatch#">
			</cfif>
		</cfcatch>
		</cftry>
	<cfelse>	<!--- this is the error code --->
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 1) />
		<cfset ret.error.ErrorText = ret.error.ErrorText & "Oops! No SubsiteID supplied or it was zero<br>" />
	</cfif>
	<cfif ret.error.ErrorCode neq 0>
		<cflog text="#ret.error.ErrorContext# #ret.error.ErrorText# - ret.error.ErrorCode: #ret.error.ErrorCode# - Time: #DateFormat(Now(),"YYYYMMDD")#-#TimeFormat(now(),"HH:mm:ss")#"  file="#Application.Logging.theSiteLogName#" type="Error" application = "yes">
	</cfif>

	<!--- return our data structure --->
	<cfreturn ret  />
</cffunction>

<cffunction name="LogIt" output="No" returntype="struct" access="private"
	displayname="Log It"
	hint="Local Function in every CFC to log info to standard log space via SLCMS_Utility.WriteLog_Core(), minimizes log code in individual functions"
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
	<cfset ret.error.ErrorContext = "SLCMS_Utility CFC: LogIt()" />
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
			<cflog text='#ret.error.ErrorText# - ret.error.ErrorCode: #ret.error.ErrorCode# - Time: #DateFormat(Now(),"YYYYMMDD")#-#TimeFormat(now(),"HH:mm:ss")#'  file="#Application.Logging.theSiteLogName#" type="Error" application = "yes">
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