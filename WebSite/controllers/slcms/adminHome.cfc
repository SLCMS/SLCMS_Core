<cfcomponent extends="Controller">

	<cffunction name="init">
		<!--- use what we have in the common controller for SLCMS --->
		<cfset super.init() />
		<!--- we use a common layout for the admin pages, and also a couple of standard includePartial()s --->
	  <cfset usesLayout(template="/slcms/Layout", except="myajax")>
	</cffunction>

	<cffunction name="index">
		<!--- admin home page --->
		<cfset commonAdminFlags() />
		<!--- 
		<cfset ErrFlag  = False>
		<cfset ErrMsg  = "">
		<cfset GoodMsg  = "">

		<cfif StructKeyExists(params, "mode")>
			<cfset WorkMode = params.mode>
			<cfset DispMode = params.mode>
		<cfelse>
			<cfset WorkMode = "">
			<cfset DispMode = "">
		</cfif>
		 --->
		<cfif StructKeyExists(params, "job") and StructKeyExists(params, "SecID") and params.SecID eq session.slcms.user.security.thisPageSecurityID>
			<cfif params.job eq "ReloadAppScope">
				<cfset application.slcms.Config.StartUp.FlushAppGlobals = True />
				<cfset GoodMsg  = "The System is set to reload on the next page view">
				<cfset DispMode = "Reload">
			<cfelseif params.job eq "ReloadTemplates">
				<cfset ret = application.slcms.Core.Templates.ReInit() />	<!--- give the template managing engine the config to work out the base paths to the templates. It will work out the rest, its by convention from there on down --->
				<cfset GoodMsg  = "The Templates have been reloaded">
				<cfset DispMode = "">
			<cfelseif params.job eq "ReloadModules">
				<cfset ret = application.slcms.System.ModuleManager.init(ApplicationConfig=application.slcms.config) />	<!--- init telling the module managing engine the site config --->
				<cfset GoodMsg  = "The Modules have been reloaded">
				<cfset DispMode = "">
			</cfif>
		</cfif>
		<!--- portal settings --->
		<cfif application.slcms.Core.PortalControl.IsPortalAllowed()>
			<!--- we are allowing subSites so get the name of the current one --->
			<cfset session.slcms.Currents.Admin.PageStructure.CurrentSubSiteShortName = application.slcms.Core.PortalControl.GetSubSite(SubSiteID="#session.slcms.Currents.Admin.PageStructure.CurrentSubSiteID#").data.SubSiteShortName />
		<cfelse>
			<!--- no portal ability so force to site zero. We need this in case we have had portals and another admin just turned them off and then we arrived here from a subsite, unlikely but possible --->
			<cfset session.slcms.Currents.Admin.PageStructure.CurrentSubSiteID = 0 />
			<cfset session.slcms.Currents.Admin.PageStructure.CurrentSubSiteShortName = application.slcms.Core.PortalControl.GetSubSite(SubSiteID="0").data.SubSiteShortName />
		</cfif>
		<!--- local display --->
		<cfif application.slcms.core.UserPermissions.IsLoggedin()>
			<cfset showModuleSection = application.slcms.System.ModuleManager.SystemHasModules() />
		<cfelse>
			<cfset showModuleSection = False />
		</cfif>
		<cfset SystemLinktext = "System Controls:" />
		<cfif application.slcms.Core.PortalControl.IsPortalAllowed()>
			<cfset SystemLinktext = SystemLinktext & " Portal Mode (Is Enabled)" />
		<cfelse>
			<cfset SystemLinktext = SystemLinktext & " Portal Mode (Is Disabled)" />
		</cfif>
		<cfif showModuleSection>
			<cfset SystemLinktext = SystemLinktext & "; Module Control(#showModuleSection#)" />
		<cfelse>		
			<cfset SystemLinktext = SystemLinktext & "; Module Control" />
		</cfif>
		<cfset SystemLinktext = SystemLinktext & "; Other Stuff" />
		<!--- set global display flags --->
		<cfset PageContextFlags = application.SLCMS.Core.ControllerHelpers_Admin.setPageContextFlags("Administration Home Page") />
		<cfset PageContextFlags.IsAdminHomePage = True />
<!--- 
		<cfset PageContextFlags.HeadTitleString = "SLCMS Admin Home Page::#application.slcms.config.base.SiteName#" />
 --->
  </cffunction>

	<cffunction name="adminlogin">
		<!--- Log In or Out page, common logic --->
		<cfset ErrFlag  = False>
		<cfset ErrMsg  = "">
		<cfset GoodMsg  = "">
		<cfset temp1 = StructGet("session.slcms.user.Security") />
		<cfif StructKeyExists(session.slcms.user.Security, "LoggedIn") and session.slcms.user.Security.LoggedIn eq "" and application.slcms.Config.StartUp.FlushSerialFromInitWiz eq "yes">
			<!--- a proper session should be true or false, not a null value --->
			<cfset session.slcms.user.Security.LoggedIn eq False />
		</cfif>
		<cfset $include(template="SLCMS/events/_onrequeststart_loginHandler_inc.cfm") />
		<!--- set global display flags --->
		<cfset PageContextFlags = application.SLCMS.Core.ControllerHelpers_Admin.setPageContextFlags("Administration SignIn") />
<!--- 
		<cfset PageContextFlags.HeadTitleString = "SLCMS Admin Sign In::#application.slcms.config.base.SiteName# " />
		<cfset PageContextFlags.BannerHeadString = "Sign In - " & PageContextFlags.BannerHeadString />
		 --->
  </cffunction>
	
</cfcomponent>