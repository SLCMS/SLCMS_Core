<!---
	This file is used to configure specific settings for the "design" environment.
	A variable set in this file will override the one in "slcms/config/settings.cfm".
	Example: <cfset set(dataSourceName="devDB")>
--->

<!--- in design mode we can mess with plugins --->
<cfset set(overwritePlugins=false) />
<cfset set(deletePluginDirectories=false) />

<!--- override a few things from the default settings as we are coding in this environment--->
<cfset application.SLCMS.config.Base.SiteMode = "Development" />
<cfset application.SLCMS.config.Base.DebugMode = "Yes" />
<!--- set up the local db we want to run off --->
<cfif server.os.MachineName eq "Cheshire">
	<cfset application.SLCMS.config.Datasources.CMS = "SLCMS_dev" />
<cfelseif server.os.MachineName eq "Edam">
	<!--- <cfset application.SLCMS.config.Datasources.CMS = "SLCMS_Core_Dev_InitialInstallTest"	 /> --->
 	<!--- <cfset application.SLCMS.config.Datasources.CMS = "SLCMS_Core_Dev_local_MSSQL" /> --->
	<!--- <cfset application.SLCMS.config.Datasources.CMS = "SLCMS_Core_Dev_local_mySQL" /> --->
	<cfset application.SLCMS.config.Datasources.CMS = "SLCMS_Core_dev" />
<cfelseif server.os.MachineName eq "Stilton">
	<cfset application.SLCMS.config.Datasources.CMS = "SLCMS_dev" />
<cfelseif server.os.MachineName eq "Wensleydale">
	<cfset application.SLCMS.config.Datasources.CMS = "SLCMS_dev" />
</cfif>

<!--- trashable dbs to start empty with for the installer code development--->
<!--- 
	<cfset application.SLCMS.config.Datasources.CMS = "SLCMS_Core_Dev_InitialInstallTest"	 />
	<cfset application.SLCMS.config.Datasources.CMS = "SLCMS_Core_Dev_InitialInstallTest_mySQL"	 />
 --->

