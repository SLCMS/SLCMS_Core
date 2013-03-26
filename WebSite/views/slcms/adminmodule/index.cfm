<cfsilent>
<!--- SLCMS --->
<!---  --->
<!--- A simple, light CMS system by Mort Bay Communications Pty Ltd --->
<!--- Copyright 2002-2011 --->
<!---  --->
<!--- Module Control --->
<!---  --->
<!--- Cloned:    6th Nov 2010 by Kym Kovan, mbcomms from the admin system page --->
<!--- modified: 27th Nov 2010 - 20th Dec 2010 by Kym K, mbcomms - turning into module administration home --->
<!--- modified:  8th Jan 2011 -  8th Jan 2011 by Kym K, mbcomms - changing jQuery path to be version agnostic --->


<cfsetting enablecfoutputonly="Yes">
<!--- 
<cfset ErrFlag  = False />
<cfset ErorMsg  = "" />
<cfset WarnMsg  = "" />
<cfset GoodMsg  = "" />
<cfset request.FromAdminModulePage = False />	flag used in the admin page to make sure it is an included file, not called on its own
<cfset opnext = "" />	<!--- what we do next --->
<!--- default behaviour --->
<cfset WorkMode1 = "" />
<cfset WorkMode2 = "" />
<cfset DispMode1 = "ShowBaseDisplayItems" />
 --->
<cfparam name="params.Showheader" default="Yes">

<cfif IsDefined("params.task")>
	<cfset WorkMode1 = params.task>
</cfif>
<cfif isdefined("params.cancel")>	<!--- do nothing if cancelled --->
	<cfset WorkMode1 = "ShowAdmin">
</cfif>

<cfif WorkMode1 eq "ShowAdmin">
	<!--- set up to show the admin for a particular module --->
	<cfset AvailableModules = application.SLCMS.System.ModuleManager.getQuickAvailableModulesList() />
	<cfparam name="params.module" default="">
	<cfparam name="params.AdminPage" default="">
	<cfset theAdminPage = params.AdminPage />
	<cfif ListFindNoCase(AvailableModules, params.module)>
		<cfset theModuleFormalname = params.module />
		<cfset theModuleFriendlyName = application.SLCMS.modules['#theModuleFormalname#'].FriendlyName />
		<cfif theAdminPage eq "">
			<cfset theAdminTemplate = application.SLCMS.modules["#theModuleFormalname#"].ModuleAdmin.AdminDefaultPageURL_Abs />
			<cfset theAdminPage = application.SLCMS.modules["#theModuleFormalname#"].ModuleAdmin.AdminDefaultPage />
		<cfelse>
			<cfset theAdminTemplate = "#application.SLCMS.modules["#theModuleFormalname#"].ModuleAdmin.AdminRootURL_Abs##theAdminPage#.cfm" />
		</cfif>
		<!--- ToDo: add error handler for bad page --->
		<cfset WorkMode2 = "ShowAdmin" />
		<cfset DispMode1 = "ShowAdmin" />
	<cfelse>
		<cfset ErrFlag  = True>
		<cfset ErorMsg  = "Invalid Module Name given when trying to Administer Module.">
		<cfset WorkMode2 = "">
		<cfset DispMode1 = "ShowBaseDisplayItems">
	</cfif>
<cfelse>
</cfif>

<!--- no second-pass stuff, do that in the individual modules --->
<!--- but we will get some default stuff that all modules use --->
<cfset IsAllowedToBePortal = application.SLCMS.Core.PortalControl.IsPortalAllowed() />
<cfset theActivesubSiteList = application.SLCMS.Core.PortalControl.GetActiveSubSiteIDList()>
<cfset theAllowedSubsiteList = application.SLCMS.Core.PortalControl.GetAllowedSubSiteIDList_AllSites(UserID="#session.SLCMS.user.UserID#") />	<!--- what this user can see --->
<cfset ModuleData = application.SLCMS.System.ModuleManager.getAvailableModulesFlags() />
<cfif ModuleData.error.errorcode neq 0>
	<cfset ErorMsg  = ErorMsg & "Retrieval of the System Module data failed.<br>" />
	<cfset ErorMsg  = ErorMsg & "Error was: #ModuleData.error.errorText#.<br>" />
	<cfset ErrFlag  = True />
</cfif>

<cfsetting enablecfoutputonly="No">

</cfsilent>
<!--- show the banner if we are in the backend, show nothing if we are popped up --->
<cfoutput>#includePartial("/slcms/adminbanner")#</cfoutput>
<!--- 
<cfdump var="#ModuleData#" expand="false" label="ModuleData">
 --->
<!--- 
<html>
<head><cfoutput>
	<title>#application.config.base.SiteName# Module Management</title>
	<link href="#request.styleSheet#" rel="STYLESHEET" type="text/css">
	<!--- 
	<script type='text/javascript' src='js/ajax.js'></script>
	 --->
	<!--- NOTE: we call jquery here but put the OnReady script stuff in each admin include --->
	<script type='text/javascript' src='#application.Paths_Common.RootURL##application.Paths_Common.jQueryPath_Rel#'></script>
</head></cfoutput>

<body class="body">
<cfif params.Showheader eq "Yes">
	<a href="AdminHome.cfm"><img src="graphics/slcmsLogo1.gif" alt="SLCMS Logo and Link" border="0"></a>
	<div class="majorheading">System Management for the <span class="AdminHeadingSiteName"><cfoutput>#application.config.base.SiteName#</cfoutput></span> website</div>
	
	<div class="HeadNavigation">
	<cfif application.SLCMS.Core.UserPermissions.IsLoggedin()>
		<a href="AdminHome.cfm">Back to Site Administration Home Page</a>
		<cfif DispMode1 eq "ShowAdmin">
		- <a href="Admin_Modules.cfm">Back to Modules Administration Home Page</a>
		</cfif>
	<cfelse>
		You are not Signed in: <a href="AdminLogin.cfm">Go to Sign In Page</a>
		</div></body></html>	<!--- tidy up the html so we still have a green tick --->
		<cfabort>
	</cfif>
	</div>
<cfelse>
	<cfif not application.SLCMS.Core.UserPermissions.IsLoggedin()>
		You are not Signed in. You cannot access this page directly.
		</body></html>	<!--- tidy up the html so we still have a green tick --->
		<cfabort>
	</cfif>
</cfif>
 --->
<cfif DispMode1 eq "ShowAdmin">
	<!--- we have done a base error check and set the page up so include the needed admin --->
	<cfset request.FromAdminModulePage = True />	<!--- flag used from the admin page --->
	<cftry>
		<cfinclude template="#theAdminTemplate#">
	<cfcatch type="missinginclude" ><cfoutput>Admin Page &quot;#theAdminTemplate#&quot; was not found for module: #theModuleFriendlyName#</cfoutput></cfcatch>
	</cftry>
<cfelseif DispMode1 eq "ShowBaseDisplayItems">
	<table border="0" cellpadding="3" cellspacing="0" >
	<!--- 
	<cfif len(ErorMsg) or len(GoodMsg)>
		<tr><td colspan="3"></td></tr>
	</cfif>
	<cfoutput><cfoutput>
	<cfif len(ErorMsg) or len(GoodMsg)>
		<cfif len(ErorMsg)><tr><td align="left" colspan="3" class="warnColour">Error:- #ErorMsg#</td></tr></cfif>
		<cfif len(GoodMsg)><tr><td align="left" colspan="3" class="goodColour">Result:- #GoodMsg#</td></tr></cfif>
	<cfelse>
		<tr><td colspan="3">&nbsp;</td></tr>
	</cfif></cfoutput>
	</cfoutput>
	 --->
	<tr><td colspan="3" class="minorheadingName">Module Administration</td></tr>
	<tr><td colspan="3"></td></tr>
	<cfif ModuleData.Error.ErrorCode eq 0>
		<tr><td colspan="3">The following Modules are installed and available in the system:</td></tr>
		<cfset thereIsAnEnabledOne = False />
		<cfloop list="#ModuleData.Data.ModuleList#" index="thisModule">
			<tr valign="top"><cfoutput>
				<td class="minorheadingText">#ModuleData.Data["#thisModule#"].FriendlyName#</td>
				<td>
				</td>
				<td>
				<cfif ModuleData.Data["#thisModule#"].Flags.HasAdmin>
					#linkTo(text="Administer", controller="slcms.admin-module", action="index", params="#PageContextFlags.ReturnLinkParams#&amp;task=ShowAdmin&amp;module=#thisModule#")#
					<!--- <a href="Admin_Modules.cfm?task=ShowAdmin&amp;module=#thisModule#">Administer</a><br> --->
				<cfelse>
					No Administration Available for this module
				</cfif>
				</td></cfoutput>
			</tr>
		</cfloop>
	<cfelse>
		<tr><td colspan="3" class="errrColour">oops! The data collection for the modules failed.</td></tr>
	</cfif>
	</table>
	
</cfif>

</body>
</html>
