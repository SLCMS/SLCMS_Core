<!--- this code runs within OnApplicationStart, included by /config/environment.cfm which is included in CFWheels' OnApplicationStart code --->
<!---
	The environment setting can be set to "design", "development", "testing", "maintenance" or "production".
	For example, set it to "design" or "development" when you are building your application and to "production" when it's running live.
--->
<!--- 
	This code will work out which to operating environment to use from the config ini files. Overide or comment out and hard code for mixed-mode machines.
	It also sets up the base application scxope that SLCMS will live in to keep it untangled from any other cfw app that might be here
 --->
<cfset server.os["MachineName"] = createObject( 'java', 'java.net.InetAddress').getLocalHost().getHostName() />

<!--- we are in OnAppStart so lets start over --->
<!--- later we will force new structs for everything but these startup config structs as we are going to re-read it all as the environment might be changing --->
<cfset application["SLCMS"] = StructNew() />
<cfset application.SLCMS["Config"] = StructNew() />
<cfset application.SLCMS.config["Startup"] = StructNew() />
<cfset application.SLCMS.Config.StartUp["FlushSerial"] = "" />
<cfset application.SLCMS.config.StartUp["FlushSerialFromInitWiz"] = "No" />
<!--- 
<cfset application.SLCMS.config.StartUp.ConfigFilesPath = ReplaceNoCase(GetDirectoryFromPath(GetCurrentTemplatePath()) & "ConfigFiles/", "\", "/", "all") />
 --->
<!--- set up the physical paths needed to load the configs, the environment here and the Base settings later --->
<cfset application.SLCMS.config.startup["SiteBasePath"] = this.variables.SLCMS.SiteBasePath />
<cfset application.SLCMS.config.startup["SLCMSBasePath"] = "#application.SLCMS.config.startup.SiteBasePath#SLCMS/" />
<cfset application.SLCMS.config.StartUp["DataFolderPath"] = "#application.SLCMS.config.startup.SLCMSBasePath#Data/" />
<cfset application.SLCMS.config.StartUp["InstallationFilesPath"] = "#application.SLCMS.config.StartUp.DataFolderPath#Installation/" />
<cfset application.SLCMS.config.StartUp["CollectionsPath"] = "#application.SLCMS.config.StartUp.DataFolderPath#Collections/" />
<cfset application.SLCMS.config.startup["ConfigFilesFolder"] = "#application.SLCMS.config.StartUp.InstallationFilesPath#SiteConfig/" />
<cfset application.SLCMS.config.startup["configMapperPath"] = "#application.SLCMS.config.startup.ConfigFilesFolder#Config_Mapper.ini.cfm" />
<cfset application.SLCMS.config.startup["BaseConfigPath"] = "#application.SLCMS.config.startup.ConfigFilesFolder#Config_BaseData.ini.cfm" />
<cfset application.SLCMS.config.startup["LogPath"] = "#application.SLCMS.config.startup.DataFolderPath#Logs/" />

<cfif FileExists(application.SLCMS.config.startup.configMapperPath)>
	<cfset application.SLCMS.config.startup["cfwEnvironment"] = GetProfileString("#application.SLCMS.config.startup.configMapperPath#", "Machines", "#server.os.MachineName#") />
	<!--- no match in mapper file will return a null --->
<cfelse>
	<cfset application.SLCMS.config.startup["cfwEnvironment"] = "" />	<!--- ini mapper file missing! set to go to default --->
</cfif>
<!--- in case we have read garbage from the ini file --->
<!--- 
<cfif not ListFindNoCase("design,development,testing,maintenance,production", application.SLCMS.config.startup.cfwEnvironment)>
	<cfset application.SLCMS.config.startup.cfwEnvironment = "production" />	<!--- default to Production --->
</cfif>
 --->
<!--- 
******
			now we know what we are force the CFW environment to match
******
 --->
<cfset set(environment="#application.SLCMS.config.startup.cfwEnvironment#")>
