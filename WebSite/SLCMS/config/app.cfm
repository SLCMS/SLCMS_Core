<!--- this code runs in the constructor area Application.cfc, included by /config/app.cfm which is included in CFWheels' Application.cfc code --->
<!---
	SLCMS related items that are needed to enable the application to set itself up. 
--->
<cfset this.variables.SLCMS = StructNew() />
<!--- use this serial to relaod the SLCMS application for dev work or site updates --->
<cfset this.variables.SLCMS.snFlushAppscope = 2012122103 />	<!--- its an "incrementing number", we use an SOA style serial but all it has to do is change each time to flag to relaod the SLCMS application --->

	
<!--- ***ALL THESE FOLLOWING THREE FLAGS SHOULD BE FALSE IN A PRODUCTION ENVIRONMENT*** --->
<cfset this.variables.SLCMS.CodingMode = False />	<!--- use this to force a full restart of session, etc. when app scope flushed, leave off if not working on session init stuff and always for production --->
<cfset this.variables.SLCMS.ForceInstallWizard = False />	<!--- use this to force the application to reload and then force the Installation Wiz to start, otherwise needs a full CF restart to get it to come up --->
<cfset this.variables.SLCMS.DoNotLoadSLCMS = False />	<!--- this turns off the loading of SLCMS's OnAppStart and OnReqStart code for when running framework tests --->
<!---
<!--- Include the CFC creation proxy for getting at our common code and "safe" stuff --->
<cfinclude template="../mbc_GlobalCreator-udf.cfm" />	<!--- this includes various init type functions as well as the CFC creator --->
<cfset this.variables.SLCMS.theSystemPath = getTopPhysicalPath() />	<!--- directory of top level of site system --->
--->
<cfset this.variables.SLCMS.SiteBasePath = ReplaceNoCase(GetDirectoryFromPath(GetBaseTemplatePath()), "\", "/", "all") />
<cfset this.variables.SLCMS.theSiteName = "SLCMS_#hash(this.variables.SLCMS.SiteBasePath)#" />	<!--- as each site should be in its own directory so this should work for uniqueness for a site name --->
<cfset this.variables.SLCMS.theSLCMSCommonLogName = "SLCMS_Common" />
<cfset this.variables.SLCMS.theSiteLogName = this.variables.SLCMS.theSLCMSCommonLogName />	<!--- will get overwritten by the real name as we load up our config --->

<!--- a few initializing things that will get ignored once things have started, which is why they in this "this" scope --->
<cfset this.variables.SLCMS.Initialization = StructNew() />	<!--- tidy store for initialization values --->
<cfset this.variables.SLCMS.Temp = StructNew() />	<!--- ditto for really temp stuff, considering all of this is temp anyway :-) --->
<cfset this.variables.SLCMS.Initialization.AppWasRestarted = False />	<!--- flag to use in the other "starts" --->


<cfset this.sessionManagement = true>
<cfset this.Sessiontimeout = "#createtimespan(0,2,0,0)#" />
<cfset this.Applicationtimeout = "#createtimespan(2,0,0,0)#" />

<!--- 
******
			modify below if we need to use a different name for the app scope
******
 --->
<cfset this.name = this.variables.SLCMS.theSiteName>
