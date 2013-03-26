<cfsilent>
<!--- SLCMS --->
<!---  --->
<!--- A simple, light CMS system by Mort Bay Communications Pty Ltd --->
<!--- Copyright 2002-2009 --->
<!---  --->
<!--- Admin Home Page --->
<!---  --->
<!--- Created:  26th Jul 2002 by Kym Kovan --->
<!--- Modified:  6th Aug 2002 -  6th Aug 2002 by Kym K, mbcomms: added Site Structure Menu Item --->
<!--- Modified:  4th Aug 2007 -  4th Aug 2007 by Kym K, mbcomms: added site name to heading. wow! its five years since this was last touched! --->
<!--- Modified: 31st Mar 2009 - 31st Mar 2009 by Kym K, mbcomms: added SuperUser admin. wow again! its another 2 years since this was last touched! --->
<!--- modified:  5th Sep 2009 -  2nd Oct 2009 by Kym K, mbcomms: V2.2, changing to user permissions system and adding portal capacity --->
<!--- modified:  6th Nov 2010 -  6th Nov 2010 by Kym K, mbcomms: V2.2+, adding module management to the mix, another year gone by :-) --->
<!--- modified:  8th Nov 2011 -  9th Nov 2011 by Kym K, mbcomms: V2.2+, finishing change of LogIn to SignIn in database tables, etc, , another year gone by!!! --->
<!--- modified: 21st Nov 2011 - 21st Nov 2011 by Kym K, mbcomms: V2.2+, broke Supervisor's Dashboard up into site super and dev pages so now we have a Developer's toolkit page here --->
<!--- modified:  2nd Jan 2012 -  2nd Jan 2012 by Kym K, mbcomms: V2.2+, changed the way templates are handled, changed template manager init() calls here to match --->
<!---  --->


<!--- 
<cfdump var="#application#" expand="false" label="application.">
<cfdump var="#request#" expand="false" label="request">
<cfdump var="#session#" expand="false" label="session">
<cfabort>
 ---> 

<!--- 
Admin Home <br>

Session Variables:<br>
<cfdump var="#session#" expand="false">

available subsites:<br>
<cfdump var="#application.slcms.core.PortalControl.GetAllowedSubSiteIDList_AllSites(UserID="#session.slcms.user.UserID#")#" expand="false"><br>
and the User variables scope<br>
<cfset theUsers = application.slcms.Core.UserControl.getVariablesScope() />
<cfdump var="#theUsers#" expand="false"><br>
 --->
<!--- 
<cfabort>
 --->
</cfsilent>
<cfoutput>#includePartial("/slcms/adminbanner")#</cfoutput><!--- show the banner if we are in the backend, returns nothing if we are popped up --->

<table border="0" cellpadding="3" cellspacing="0" width="100%">	<!--- this table has the page/menu content --->
<cfif request.SLCMS.DispMode eq ""><cfoutput>
	<cfif application.slcms.core.UserPermissions.IsEditor(SubSiteID="any")>
		<tr><td colspan="3" align="left"><strong>Editor Controls</strong></td></tr>
		<tr><td></td><td colspan="2">#linkTo(text="Manage Site Page Structure", controller="slcms.admin-pages", action="index", params="#PageContextFlags.ReturnLinkParams#")#</td></tr>
		<!--- <a href="Admin_PageStructure.cfm">Manage Site Page Structure</a> --->
		<!--- 
		<tr><td></td><td colspan="2"><a href="Admin_Search.cfm">Manage Search Collections</a></td></tr>
	 	--->
	</cfif>
	<cfif showModuleSection>
		<tr><td colspan="3" align="left"><hr size="1" width="600" align="left"></td></tr>
		<tr><td colspan="3" align="left"><strong>Module Controls</strong></td></tr>
		<tr><td></td><td colspan="2">
			#linkTo(text="Administer a Module", controller="slcms.admin-module", action="index", params="#PageContextFlags.ReturnLinkParams#")#
			<!--- <a href="Admin_Modules.cfm">Administer a Module</a> --->
			</td></tr>
		<cfif application.slcms.Core.PortalControl.IsPortalAllowed()>
			<tr><td></td><td colspan="2">
			#linkTo(text="Manage Module Availability in subSites", controller="slcms.admin-modulesinsubs", action="index", params="#PageContextFlags.ReturnLinkParams#")#
			<!--- <a href="Admin_ModulesInSubSites.cfm">Manage Module Availability in subSites</a> --->
			</td></tr>
		</cfif>
	</cfif>
	<cfif application.slcms.core.UserPermissions.IsAdmin(SubSiteID="any")>
		<tr><td colspan="3" align="left"><hr size="1" width="600" align="left"></td></tr>
		<tr><td colspan="3" align="left"><strong>Administrator Controls</strong></td></tr>
		<tr><td></td><td colspan="2">
			#linkTo(text="Manage Templates and Stylesheets", controller="slcms.admin-templates", action="index", params="#PageContextFlags.ReturnLinkParams#")#
			<!--- 
			<a href="Admin_Templates.cfm">Manage Templates and Stylesheets</a>
			 --->
		</td></tr>
		<cfif application.slcms.Core.PortalControl.IsPortalAllowed()>
		<tr><td></td><td colspan="2">
			#linkTo(text="Manage Portal/subSites", controller="slcms.admin-portal", action="index", params="#PageContextFlags.ReturnLinkParams#")#
			<!--- 
			<a href="Admin_PortalSubSites.cfm">Manage Portal/subSites</a>
			 --->
			</td></tr>
		</cfif>
		<tr><td></td><td colspan="2">
			#linkTo(text="Administer Site Management Users and their Roles - Administrators, Editors and Authors", controller="slcms.admin-staff", action="index", params="#PageContextFlags.ReturnLinkParams#")#
		<!--- 
		<a href="Admin_Users.cfm">Administer Site Management Users and their Roles - Administrators, Editors and Authors</a>
 		--->
		</td></tr>
	</cfif>
	<cfif application.slcms.core.UserPermissions.IsSuper()>
		<tr><td colspan="3" align="left"><hr size="1" width="600" align="left"></td></tr>
		<tr><td colspan="3" align="left"><strong>Supervisor Controls</strong></td></tr>
		<tr><td></td><td colspan="2">
			#linkTo(text="#SystemLinktext#", controller="slcms.admin-system", action="index", params="#PageContextFlags.ReturnLinkParams#")#
			<!--- 
			<a href="Admin_System.cfm">System Controls: Portal Mode <cfif application.slcms.Core.PortalControl.IsPortalAllowed()>(Is Enabled)<cfelse>(Is Disabled)</cfif>; Module Control; Other Stuff</a>
			 --->
			</td></tr>
		<tr><td></td><td colspan="2">
			#linkTo(text="Administer Supervisor Users", controller="slcms.admin-superusers", action="index", params="#PageContextFlags.ReturnLinkParams#")#
			<!--- 
			<a href="Admin_SuperUsers.cfm?SecID=#session.slcms.user.security.thisPageSecurityID#">Administer Supervisor Users</a>
			 --->
		</td></tr>
		<tr><td></td><td colspan="2"></td></tr>
		<tr><td></td><td colspan="2">
			#linkTo(text="Supervisor's Dashboard", controller="slcms.admin-superdashboard", action="index", params="#PageContextFlags.ReturnLinkParams#")#
		<!--- 
		<a href="Admin_SuperDashboard.cfm">Supervisor's Dashboard</a>
		 --->
		</td></tr>
		<!--- 
		<cfif application.slcms.config.base.sitemode eq "development">
			<tr><td></td><td colspan="2"><a href="Admin_DevelopersTools.cfm">Developer's Toolkit</a></td></tr>
		</cfif>
		 --->
		<tr><td></td><td colspan="2"></td></tr>
		<tr><td></td><td colspan="2">
			#linkTo(text="Reload The Template Data", controller="slcms.admin-home", action="index", params="#PageContextFlags.ReturnLinkParams#&amp;job=ReloadTemplates", confirm="Confirm you want to reload the templates")#
<!--- 
		<a href="AdminHome.cfm?job=ReloadTemplates&amp;ID=#session.slcms.user.security.thisPageSecurityID#" onClick="return confirm('Confirm you want to reload the templates');">Reload The Template Data</a>
 --->		
	</td></tr>
		<tr><td></td><td colspan="2">
		#linkTo(text="Reload The Modules", controller="slcms.admin-home", action="index", params="#PageContextFlags.ReturnLinkParams#&amp;job=ReloadModules", confirm="Confirm you want to reload the modules")#
<!--- 
		<a href="AdminHome.cfm?job=ReloadModules&amp;ID=#session.slcms.user.security.thisPageSecurityID#" onClick="return confirm('Confirm you want to reload the modules');">Reload The Modules</a>
 --->
	</td></tr>
		<tr><td></td><td colspan="2">
			#linkTo(text="Reload The System Data", controller="slcms.admin-home", action="index", params="#PageContextFlags.ReturnLinkParams#&amp;job=ReloadAppScope", confirm="Are You Serious!")#
<!--- 
		<a href="AdminHome.cfm?job=ReloadAppScope&amp;ID=#session.slcms.user.security.thisPageSecurityID#" onClick="return confirm('Are You Serious!');">Reload The System Data</a>
 --->
		</td></tr>
	</cfif>
	<cfif application.slcms.core.UserPermissions.IsLoggedin()>
		<tr><td colspan="3" align="left"><hr size="1" width="600" align="left"></td></tr>
		<tr><td></td><td colspan="2">#linkTo(text="Go to Log Out Page", action="adminLogin", params="#PageContextFlags.ReturnLinkParams#")#</td></tr>
	<cfelse>
		<tr><td></td><td colspan="2">You are not Logged in: #linkTo(text="Go to Log In Page", action="adminLogin")#</td></tr>
	</cfif>
	</cfoutput>
<cfelseif request.SLCMS.DispMode eq "Reload"><cfoutput>
	<tr><td colspan="3">
		#linkTo(text="Back to Admin Home (System will Reload its configuration data if it hasn't already", controller="slcms.admin-home", action="index", params="#PageContextFlags.ReturnLinkParams#")#
	<!--- 
	<a href="AdminHome.cfm">Back to Admin Home (System will Reload its configuration data if it hasn't already)</a>
 --->
	</td></tr></cfoutput>
</cfif>
</table>
<!--- 
<cfoutput>
<p><br><br><a href="http://www.mbcomms.net.au" target="_blank"><img src="#application.SLCMS.Paths_Admin.GraphicsPath_ABS#servedByMBCOMMSv2-2.gif" alt="MBComms Admin Page Logo and Link" border="0"></a></p></cfoutput>
 --->
