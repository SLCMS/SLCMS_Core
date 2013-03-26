<cfcomponent output="False"
	displayname="Version Control-Folders" 
	hint="Manages the folder structure versioning and related creation/modification activity. Non-persistent" 
	>
<!--- mbc SLCMS CFCs  --->
<!--- &copy; 2009 mort bay communications --->
<!---  --->
<!--- VersionControl_Folder.CFC  --->
<!--- Manages the foldr structure versioning and related creation/modification activity --->
<!--- Contains:
			init - set up structures for the cfc, just the database really
			lots more related stuff :-)
			 --->
<!---  --->
<!--- created:  20th Sep 2009 by Kym K, mbcomms --->
<!--- modified: 20th Sep 2009 - 22nd Sep 2009 by Kym K, mbcomms: initial work on it --->
<!--- modified:  7th Jun 2011 -  8th Jun 2011 by Kym K, mbcomms: added logging functions so we can have consistent logging outside CF's logs --->
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
	<cfset temps = LogIt(LogType="CFC_Init", LogString="VersionControl-Folders Init() Started") />
	<!--- if we don't have a dsn grab it from the master CFC --->
	<cfif variables.theDSN eq "">
		<cfset thegetRet = application.SLCMS.Core.Versions_Master.getVersionMasterConfig() />
	</cfif>
	<cfset variables.theDSN = thegetRet.dsn />	<!--- the database it all lives in --->
	<cfset variables.CurrentVersion = thegetRet.CurrentVersion />	<!--- the database it all lives in --->
	<cfset variables.versionPath = thegetRet.versionPath />	<!--- the database it all lives in --->
	<cfset variables.InitSet = True />
	
	<cfset temps = LogIt(LogType="CFC_Init", LogString="VersionControl-Folders Init() Finished") />
	<cfreturn True />
</cffunction>

<cffunction name="CreateSubSiteFolders" output="No" returntype="struct" access="public"
	displayname="Create SubSite Folders"
	hint="Creates the complete set of folders used in a SubSite"
	>
	<!--- this function needs.... --->
	<cfargument name="SubSiteShortName" type="string" default="" hint="the short name of the subsite, will be the folder name" />	<!--- has to be clean as a foldername --->

	<!--- now all of the var declarations, first the arguments which need manipulation --->
	<cfset var theSubSiteShortName = trim(arguments.SubSiteShortName) />
	<!--- now vars that will get filled as we go, in order of creation --->
	<cfset var theVersionFolderName = "" />	<!--- temp var for the folder name that the folder structure is in --->
	<cfset var theBaseNewPath = "" />
	<cfset var theVersionFolderContents = "" />	<!--- temp query result --->
	<cfset var theVersionFolderNameRemoveLength = 0 />	<!--- temp struct for the contents of the directory search --->
	<cfset var theTemplateFolderPath = "" />	<!--- all the details of the subsite so we can get the path name to use for the folders --->
	<cfset var theFullNewPath = "" />	<!--- all the details of the subsite so we can get the path name to use for the folders --->
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorContext = "VersionControl_Database CFC: CreateSubSiteFolders()" />
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
	<cfif len(theSubSiteShortName)>
		<!--- validated so go for it --->
		<!--- wrap the whole thing in a try/catch in case something breaks --->
		<cftry>
			<!--- get the name to use for the folder base path --->
			<cfset theVersionFolderName = variables.versionPath & "Folders_#variables.CurrentVersion.CodeBase.VersionNumber_Major#_#variables.CurrentVersion.CodeBase.VersionNumber_Minor#_#variables.CurrentVersion.CodeBase.VersionNumber_Dot#/" />
			<cfif DirectoryExists("#theVersionFolderName#")>
				<!--- we have a folder so assuming its contents mean something lets make the root folder for this subsite --->
				<cfset theBaseNewPath = "#application.SLCMS.Config.startup.SiteBasePath#Sites/#theSubSiteShortName#/" />
				<cfdirectory action="create" directory="#theBaseNewPath#">
				<!--- then grab the Version folder's contents --->
				<cfdirectory action="list" name="theVersionFolderContents" directory="#theVersionFolderName#" recurse="true" sort="directory asc">
				<!--- and loop over the folders in the result to create the new ones --->
				<cfset theVersionFolderNameRemoveLength = len(theVersionFolderName)-1 />
				<cfloop query="theVersionFolderContents">
					<cfif theVersionFolderContents.Type eq "Dir">
						<cfset theTemplateFolderPath = removechars(theVersionFolderContents.Directory, 1, theVersionFolderNameRemoveLength)>	<!--- the folder without the version path on the front --->
						<cfif left(theTemplateFolderPath, 1) eq "\">
							<cfset theTemplateFolderPath = removechars(theTemplateFolderPath, 1, 1)>
						</cfif>
						<cfif not (left(theTemplateFolderPath, 4) eq ".svn" or left(theVersionFolderContents.Name, 4) eq ".svn")>	<!--- ew don't need to do SubVersion Folders, I wonder why? :-) --->
							<cfset theFullNewPath = theBaseNewPath & theTemplateFolderPath />
							<cfif theTemplateFolderPath neq "">/
								<cfset theFullNewPath = theFullNewPath & "/" />
							</cfif>
							<cfset theFullNewPath = theFullNewPath & theVersionFolderContents.Name & "/" />
							<cfdirectory action="create" directory="#theFullNewPath#">
						</cfif>
					</cfif>
				</cfloop>
			<cfelse>
				<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 2) />
				<cfset ret.error.ErrorText = ret.error.ErrorText & "version template folder not found. looking for: #theVersionFolderName# <br>" />
			</cfif>
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
		<cfset ret.error.ErrorText = ret.error.ErrorText & "Oops! No SubSiteShortName supplied<br>" />
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