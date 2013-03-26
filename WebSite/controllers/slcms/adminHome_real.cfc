<cfcomponent extends="Controller">

	<cffunction name="adminHome">
		<cfset variables.mytestvar = "hello me in the SLCMS admin controller" />




<!--- 
Admin Home <br>

Session Variables:<br>
<cfdump var="#session#" expand="false">

available subsites:<br>
<cfdump var="#application.core.PortalControl.GetAllowedSubSiteIDList_AllSites(UserID="#session.user.UserID#")#" expand="false"><br>
and the User variables scope<br>
<cfset theUsers = application.Core.UserControl.getVariablesScope() />
<cfdump var="#theUsers#" expand="false"><br>
 --->
<!--- 
<cfabort>
 --->
<cfset ErrFlag  = False>
<cfset ErrMsg  = "">
<cfset GoodMsg  = "">

<cfif IsDefined("url.mode")>
	<cfset WorkMode = url.mode>
	<cfset DispMode = url.mode>
<cfelse>
	<cfset WorkMode = "">
	<cfset DispMode = "">
</cfif>

<!--- as this page can be got at if web server hacked add a second level of security --->
<cfif not StructKeyExists(session.user.security, "thisPageSecurityID")>
	<cfset session.user.security.thisPageSecurityID = CreateUUID()>
</cfif>

<cfif IsDefined("url.job") and IsDefined("url.ID") and url.ID eq session.user.security.thisPageSecurityID>
	<cfif url.job eq "ReloadAppScope">
		<cfset application.Config.StartUp.FlushAppGlobals = True />
		<cfset GoodMsg  = "The System is set to reload on the next page view">
		<cfset DispMode = "Reload">
	<cfelseif url.job eq "ReloadTemplates">
		<cfset ret = application.Core.Templates.ReInit() />	<!--- give the template managing engine the config to work out the base paths to the templates. It will work out the rest, its by convention from there on down --->
		<cfset GoodMsg  = "The Templates have been reloaded">
		<cfset DispMode = "">
	<cfelseif url.job eq "ReloadModules">
		<cfset ret = application.System.ModuleManager.init(ApplicationConfig=application.config) />	<!--- init telling the module managing engine the site config --->
		<cfset GoodMsg  = "The Modules have been reloaded">
		<cfset DispMode = "">
	</cfif>
</cfif>

<cfif application.Core.PortalControl.IsPortalAllowed()>
	<!--- we are allowing subSites so get the name of the current one --->
	<cfset session.Currents.Admin.PageStructure.CurrentSubSiteShortName = application.Core.PortalControl.GetSubSite(SubSiteID="#session.Currents.Admin.PageStructure.CurrentSubSiteID#").data.SubSiteShortName />
<cfelse>
	<!--- no portal ability so force to site zero. We need this in case we have had portals and another admin just turned them off and then we arrived here from a subsite, unlikely but possible --->
	<cfset session.Currents.Admin.PageStructure.CurrentSubSiteID = 0 />
	<cfset session.Currents.Admin.PageStructure.CurrentSubSiteShortName = application.Core.PortalControl.GetSubSite(SubSiteID="0").data.SubSiteShortName />
</cfif>

<cfif WorkMode eq "xxx">
	<!--- do things --->
	<cfset DispMode = "yyy">
</cfif>

<!--- get the base display stuff --->
<cfif application.core.UserPermissions.IsLoggedin()>
	<cfset showModuleSection = application.System.ModuleManager.SystemHasModules() />
<cfelse>
	<cfset showModuleSection = False />
</cfif>















  </cffunction>
	
</cfcomponent>