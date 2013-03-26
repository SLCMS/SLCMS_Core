<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<!--- SLCMS --->
<!---  --->
<!--- A simple, light CMS system by Mort Bay Communications Pty Ltd --->
<!--- Copyright 2002-2010 --->
<!---  --->
<!--- Module Control --->
<!---  --->
<!--- Cloned:    6th Nov 2010 by Kym Kovan, mbcomms from the admin system page --->
<!--- modified:  6th Nov 2010 -  6th Nov 2010 by Kym K, mbcomms - adding module subSite management capability --->
<!--- modified: 23rd Nov 2010 - 23rd Nov 2010 by Kym K, mbcomms - tidy up of above now we have real modules to play with --->
<!--- modified: 28th Dec 2010 - 28th Dec 2010 by Kym K, mbcomms - adding Module ReinitAfter Calls --->


<cfsetting enablecfoutputonly="Yes">
<cfset ErrFlag  = False>
<cfset ErrMsg  = "">
<cfset GoodMsg  = "">
<cfset opnext = "">	<!--- what we do next --->
<!--- default behaviour --->
<cfset RunReInitAfters = False />
<cfset WorkMode1 = "">
<cfset WorkMode2 = "GetBaseDisplayItems">
<cfset DispMode = "ShowBaseDisplayItems">

<cfif IsDefined("url.task")>
	<cfset WorkMode1 = url.task />
</cfif>
<cfif isdefined("form.cancel")>	<!--- do nothing if cancelled --->
	<cfset WorkMode1 = "" />
</cfif>

<cfif WorkMode1 eq "SubSiteToggle">
	<!--- toggle whether subsites can be used or not --->
	<!--- 
	<cfif StructKeyExists(params, "Function") and params.function eq "SubSiteToggle" and StructKeyExists(params, "CurrentState")>
	
	</cfif>
	 --->
	<cfset WorkMode2 = "GetBaseDisplayItems">
	<cfset DispMode = "ShowBaseDisplayItems">
	
<cfelseif WorkMode1 eq "Enable">
	<!--- we are going to enable a module globally --->
	<cfset ModuleData = application.SLCMS.System.ModuleManager.ChangeModuleEnableState(Modulename=url.module, Change="Enable") />
	<cfset RunReInitAfters = True />
	<cfset WorkMode2 = "GetBaseDisplayItems">
	<cfset DispMode = "ShowBaseDisplayItems">

<cfelseif WorkMode1 eq "disable">
	<!--- we are going to disable a module globally --->
	<cfset ModuleData = application.SLCMS.System.ModuleManager.ChangeModuleEnableState(Modulename=url.module, Change="Disable") />
	<cfset RunReInitAfters = True />
	<cfset WorkMode2 = "GetBaseDisplayItems">
	<cfset DispMode = "ShowBaseDisplayItems">

<cfelseif WorkMode1 eq "EnableSub">
	<!--- we are going to enable a module for a subSite --->
	<cfset ModuleData = application.SLCMS.System.ModuleManager.ChangeModuleEnableState(Modulename=url.module, Change="Enable", subSite="#url.subSiteID#") />
	<cfset RunReInitAfters = True />
	<cfset WorkMode2 = "GetBaseDisplayItems">
	<cfset DispMode = "ShowBaseDisplayItems">

<cfelseif WorkMode1 eq "disableSub">
	<!--- we are going to disable a module for a subSite --->
	<cfset ModuleData = application.SLCMS.System.ModuleManager.ChangeModuleEnableState(Modulename=url.module, Change="Disable", subSite="#url.subSiteID#") />
	<cfset RunReInitAfters = True />
	<cfset WorkMode2 = "GetBaseDisplayItems">
	<cfset DispMode = "ShowBaseDisplayItems">

</cfif>

<cfif RunReInitAfters>
	<cfset ret = application.SLCMS.System.ModuleManager.ReInitModulesAfter(InitiatingModule="Core", InitiatingFunction="PortalControl", Action="subSiteChange") />
	<cfif ret.error.errorcode neq 0>
		<cfset ErrMsg  = "Module ReInitialisation After Change Failed">
		<cfif application.SLCMS.config.debug.debugmode>
			<cfoutput>#ret.error.ErrorContext#</cfoutput> Errored - error dump:<br>
			<cfdump var="#ret#">
		</cfif>
	</cfif>
</cfif>


<!--- now do the second-pass stuff --->
<cfif WorkMode2 eq "zzz">
	<!--- do things --->
	<cfset DispMode = "yyy">
<cfelseif WorkMode2 eq "GetBaseDisplayItems">
	<!--- get the state of the portal mode --->
	<cfset IsAllowedToBePortal = application.SLCMS.Core.PortalControl.IsPortalAllowed() />
	<cfset ModuleData = application.SLCMS.System.ModuleManager.getAvailableModulesFlags() />
	<cfset theActivesubSiteList = application.SLCMS.core.PortalControl.GetActiveSubSiteIDList()>
	<!---						
							<cfdump var="#theActivesubSiteList#" expand="false" >
	--->						
	
</cfif>

<!--- get the base display stuff --->
<cfif StructKeyExists(session.SLCMS, "Super") and session.SLCMS.Super eq "SuperRunning">
	<cfset rEmulateMode = True>
<cfelse>
	<cfset rEmulateMode = False>
</cfif>

<cfsetting enablecfoutputonly="No">
<!--- show the banner if we are in the backend, show nothing if we are popped up --->
<cfoutput>#includePartial("/slcms/adminbanner")#</cfoutput>
<!--- 
<html>
<head>
	<title><cfoutput>#application.SLCMS.config.base.SiteName#</cfoutput> site administration</title>
	<cfoutput><link href="#request.styleSheet#" rel="STYLESHEET" type="text/css"></cfoutput>
</head>

<body class="body">
<a href="AdminHome.cfm"><img src="graphics/slcmsLogo1.gif" alt="SLCMS Logo and Link" border="0"></a>
<div class="majorheading">System Management for the <span class="AdminHeadingSiteName"><cfoutput>#application.SLCMS.config.base.SiteName#</cfoutput></span> website</div>

<div class="HeadNavigation">
<cfif application.SLCMS.core.UserPermissions.IsLoggedin()>
	<a href="AdminHome.cfm">Back to Site Administration Home Page</a>
<cfelse>
	You are not Logged in: <a href="AdminLogin.cfm">Go to Log In Page</a>
	</div></body></html>	<!--- tidy up the html so we still have a green tick --->
	<cfabort>
</cfif>
</div>
<table border="0" cellpadding="3" cellspacing="0" >	<!--- this table has the page/menu content --->
<cfif len(ErrMsg) or len(GoodMsg)>
	<tr><td colspan="3"></td></tr>
</cfif>
<cfif len(ErrMsg)><tr><td align="left" colspan="3" class="warnColour">Error:- <cfoutput>#ErrMsg#</cfoutput></td></tr></cfif>
<cfif len(GoodMsg)><tr><td align="left" colspan="3" class="goodColour">Result:- <cfoutput>#GoodMsg#</cfoutput></td></tr></cfif>
<tr><td colspan="3"></td></tr>
 --->
<table border="0" cellpadding="3" cellspacing="0" >	<!--- this table has the page/menu content --->
<cfif DispMode eq ""><cfoutput>
	<tr><td></td><td colspan="2"></td></tr>
	<tr><td colspan="3" align="left"></cfoutput>

<cfelseif DispMode eq "ShowBaseDisplayItems">
	<tr><td colspan="3"></td></tr>
	<tr><td colspan="3" class="minorheadingName">Portal Capability</td></tr>
	<tr><td colspan="3"></td></tr>
	<tr>
		<td colspan="1" class="minorheadingText">
		<cfif IsAllowedToBePortal>
			Sub Sites are allowed
		<cfelse>
			Sub Sites are not allowed
		</cfif>
		</td>
		</tr>
	<tr><td colspan="3"></td></tr>
	<tr><td colspan="3"></td></tr>
	<tr><td colspan="3" class="minorheadingName">Module Control</td></tr>
	<tr><td colspan="3"></td></tr>
	<cfif ModuleData.Error.ErrorCode eq 0>
		<tr><td colspan="3">The following Modules are enabled in the system:</td></tr>
		<tr><td colspan="3"><hr></td></tr>
		<cfloop list="#ModuleData.Data.ModuleList#" index="thisModule">
			<cfset thissubSites_Enabled_subSiteList = ModuleData.Data["#thisModule#"].Flags.Enabled_subSiteList />
			<cfif ModuleData.Data["#thisModule#"].Flags.Enabled_Global>
				<tr valign="top"><cfoutput>
					<td>Module Name</td>
					<td colspan="2" class="minorheadingText">#ModuleData.Data["#thisModule#"].FriendlyName#</td>
				</tr>
				<cfif ModuleData.Data["#thisModule#"].Flags.PortalAware>
					<tr><td colspan="3">This module is enabled in the following subsites as indicated:</td></tr>
					<cfloop list="#theActivesubSiteList#" index="thissubSite">	<!--- use the list of subsites, loop over and match against enabled_subSiteList --->
						<cfif ListFind(thissubSites_Enabled_subSiteList, thissubSite)>
							<cfset theClass = ' class="minorheadingText"' />
							<cfset theWords = "Enabled" />
							<cfset theLink = '#linkTo(text="Disable Module", controller="slcms.admin-modulesinsubs", action="index", params="#PageContextFlags.ReturnLinkParams#&amp;task=DisableSub&amp;module=#thisModule#&amp;subSiteID=#thissubSite#")#' />
							<!--- 
							<cfset theLink = '<a href="Admin_ModulesInSubSites.cfm?task=DisableSub&amp;module=#thisModule#&amp;subSiteID=#thissubSite#">Disable Module</a>' />
							 --->
						<cfelse>
							<cfset theClass = '' />
							<cfset theWords = "Disabled" />
							<cfset theLink = '#linkTo(text="Enable Module", controller="slcms.admin-modulesinsubs", action="index", params="#PageContextFlags.ReturnLinkParams#&amp;task=EnableSub&amp;module=#thisModule#&amp;subSiteID=#thissubSite#")#' />
							<!--- 
							<cfset theLink = '<a href="Admin_ModulesInSubSites.cfm?task=EnableSub&amp;module=#thisModule#&amp;subSiteID=#thissubSite#">Enable Module</a>' />
							 --->
						</cfif>
						<tr>
							<td#theClass#>
								#application.SLCMS.core.PortalControl.GetSubSite(SubSiteID="#thissubSite#").data.SubSiteFriendlyName#
							</td>
							<td>#theWords#</td>
							<td>#theLink#</td>
						</tr>
					</cfloop>
				<cfelse>
					<tr>
						<td></td>
						<td colspan="2">
						This Module is not portal aware, it will only work in the <strong>#application.SLCMS.core.PortalControl.GetSubSite(SubSiteID="0").data.SubSiteFriendlyName#</strong> subSite.
						</td>
					</tr>
				</cfif>
				</cfoutput>
				<tr><td colspan="3"><hr></td></tr>
			</cfif>
		</cfloop>
	<cfelse>
		<tr><td colspan="3" class="errrColour">oops! The data collection for the modules failed.</td></tr>
	</cfif>
	
</cfif>
</table>

</body>
</html>
