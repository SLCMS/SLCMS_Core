<cfsetting enablecfoutputonly="Yes">
<!--- 
<cfset ErrFlag  = False />
<cfset ErrMsg  = "" />
<cfset GoodMsg  = "" />

<cfif IsDefined("url.mode")>
	<cfset request.SLCMS.WorkMode0 = url.mode />	<!--- code to run before the main set to work out the subsite we are in --->
	<cfset request.SLCMS.WorkMode1 = url.mode />
	<cfset request.SLCMS.DispMode = url.mode />
<cfelseif IsDefined("form.task")>
	<cfset request.SLCMS.WorkMode0 = form.task />	<!--- code to run before the main set to work out the subsite we are in --->
	<cfset request.SLCMS.WorkMode1 = form.task />
	<cfset request.SLCMS.DispMode = form.task />
<cfelse>
	<cfset request.SLCMS.WorkMode0 = "" />
	<cfset request.SLCMS.WorkMode1 = "" />
	<cfset request.SLCMS.DispMode = "" />
</cfif>
 --->
<!--- 
<!--- first some portal related code --->
<cfset request.SLCMS.PortalAllowed = application.SLCMS.Core.PortalControl.IsPortalAllowed() />
<cfif request.SLCMS.PortalAllowed>
	<cfset theAllowedSubsiteList = application.SLCMS.core.PortalControl.GetAllowedSubSiteIDList_AllSites(UserID="#session.SLCMS.user.UserID#") />
	<cfif request.SLCMS.WorkMode0 eq "ChangeSubSite" and IsDefined("url.NewSubSiteID") and IsNumeric(url.NewSubSiteID)>
		<!--- set a new current state --->
		<cfset session.SLCMS.Currents.Admin.PageStructure.CurrentSubSiteID = url.NewSubSiteID />
		<cfset session.SLCMS.Currents.Admin.PageStructure.CurrentSubSiteFriendlyName = application.SLCMS.core.PortalControl.GetSubSite(url.NewSubSiteID).data.SubSiteFriendlyName />
		<!--- work out the database tables --->		
		<cfset request.SLCMS.PageStructTable = application.SLCMS.config.DatabaseDetails.databaseTableNaming_Root_Site
																		&	session.SLCMS.Currents.Admin.PageStructure.CurrentSubSiteID
																		&	application.SLCMS.config.DatabaseDetails.databaseTableNaming_Tail_PageStructure />
		<!--- this code below is cloned in App.cfc in OnRequestStart to make sure we have something first time in (using site_0) --->
		<cfset session.SLCMS.pageAdmin.NavState = StructNew()/>	<!--- dump all old data --->
		set up our vars to display the structure from
		<cfset session.SLCMS.pageAdmin.NavState.theOriginalNavArray = Duplicate(application.SLCMS.Core.PageStructure.getFullNavArray(SubSiteID=session.SLCMS.Currents.Admin.PageStructure.CurrentSubSiteID)) />
		<cfset session.SLCMS.pageAdmin.NavState.theCurrentNavArray = Duplicate(application.SLCMS.Core.PageStructure.getFullNavArray(SubSiteID=session.SLCMS.Currents.Admin.PageStructure.CurrentSubSiteID)) />
		<cfset session.SLCMS.pageAdmin.NavState.dispRowCounter = 0 />
		<cfset session.SLCMS.Currents.Admin.PageStructure.FlushExpansionFlags = True />
		<cfset request.SLCMS.WorkMode = "" />
		<cfset request.SLCMS.DispMode = "" />
		
	<cfelseif request.SLCMS.WorkMode0 eq "xxx" >	<!--- next request.SLCMS.WorkMode0 --->
	
	<cfelse>	<!--- no request.SLCMS.WorkMode0 so set up defaults/currents --->
		<cfset request.SLCMS.PageStructTable = application.SLCMS.config.DatabaseDetails.databaseTableNaming_Root_Site
																		&	session.SLCMS.Currents.Admin.PageStructure.CurrentSubSiteID
																		&	application.SLCMS.config.DatabaseDetails.databaseTableNaming_Tail_PageStructure />
	</cfif>
<cfelse>
	<!--- no portal ability so force to site zero --->
	<cfset theAllowedSubsiteList = "0" />
	<cfset request.SLCMS.PageStructTable = application.SLCMS.config.DatabaseDetails.TableName_Site_0_PageStruct />
</cfif>
 --->
<cfif request.SLCMS.WorkMode1 eq "">
	<!--- must be the entry, show basic stuff so grab the version state, etc --->
	<cfset theVersionData = application.SLCMS.Core.Versions_Master.getVersionMasterConfig() />
	<cfset request.SLCMS.DispMode = "" />
</cfif>

<cfset theVersionData = application.SLCMS.Core.Versions_Master.getVersionMasterConfig() />

<cfsavecontent variable="headStuff">
	<script type="text/javascript">
		$(document).ready(function() {
			$('#WorkingMsg').hide();
		});	<!--- jQuery OnReady end --->		
	</script>
</cfsavecontent>
<cfhtmlhead text="#headStuff#">

<cfsetting enablecfoutputonly="No">
<cfoutput>#includePartial("/slcms/adminbanner")#</cfoutput><!--- show the banner if we are in the backend, returns nothing if we are popped up --->
<!--- as we are doing nasty dumps and all sorts lets give the punter something to look at while the browser handles the dump js --->
<div id="WorkingMsg"><p>Gathering Data</p></div>
<cfif application.SLCMS.core.UserPermissions.IsLoggedin()>
<table border="0" cellpadding="3" cellspacing="0">	<!--- this table has the page/menu content --->
<cfif request.SLCMS.DispMode eq ""><cfoutput>
	<tr><td colspan="3"></td></tr>
	<tr><td colspan="3">
		<div>
			<strong>Where we are at:</strong>
		</div>
		<div>
			The site code is Version: <cfoutput>#theVersionData.CurrentVersion.VersionNumber_Full#</cfoutput>
		</div>
		<div>
		<cfif theVersionData.CurrentVersion.VersionNumber_Full eq "Unknown">
			This is an older version of SLCMS, before Version 2.2 when automatic updating was included.<br>It will need semi-manually upgrading.
		<cfelse>
			It was installed on: 
			<cfif theVersionData.CurrentVersion.InstallDate neq "">
				<cfoutput>#DateFormat(theVersionData.CurrentVersion.InstallDate, "dd-mmm-yyyy")#</cfoutput>
			<cfelse>
				Installed but not yet configured
			</cfif>
		</cfif>
		</div>
		<div class="SuperDashboardSmallHeading"><p>The mode of this SLCMS site is: <cfoutput>#application.SLCMS.config.base.sitemode#</cfoutput></p></div>
		<cfif application.SLCMS.config.base.sitemode eq "development">
			<div>
			#linkTo(text="Go to Developer's Toolkit", controller="slcms.developers", action="index", params="#PageContextFlags.ReturnLinkParams#")#
			</div>
		</cfif>
	</td></tr>
	<tr><td colspan="3"><hr></td></tr>
	<tr><td colspan="3"><strong>Tools to see what is going on</strong></td></tr>
	<tr><td colspan="3"><u>subSite Specific Tools</u></td></tr>
	<tr>
		<td colspan="3">
			<cfif request.SLCMS.PortalAllowed>
				<cfif ListLen(theAllowedSubsiteList) gt 1>
					<div id="SubSiteLinksWrapper">
						<cfset lcntr = 0 />
						<p>This website is a portal. There are the following subSites:</p>
						<p>
						<cfloop list="#theAllowedSubsiteList#" index="thisSubSite">
							<span class="<cfif lcntr eq 0>LeftEnd<cfelseif lcntr mod 2 eq 1>OddNumbered<cfelse>EvenNumbered</cfif>">
							<cfset thisSubsiteDetails = application.SLCMS.core.PortalControl.GetSubSite(thisSubSite).data />
							<cfoutput>
							<cfif thisSubsiteDetails.SubSiteID eq 0>
								<cfif thisSubsiteDetails.SubSiteFriendlyName eq "Top">
									The #linkTo(text="Top Site", controller="slcms.admin-superdashboard", action="index", params="#PageContextFlags.ReturnLinkParams#&amp;mode=ChangeSubSite&amp;NewSubSiteID=0")#
								<cfelse>
									The Top Site (called &quot;#linkTo(text="Top Site", controller="slcms.admin-superdashboard", action="index", params="#PageContextFlags.ReturnLinkParams#&amp;mode=ChangeSubSite&amp;NewSubSiteID=0")#&quot;)
								</cfif>
							<cfelse>
									Site: &quot;#linkTo(text="#thisSubsiteDetails.SubSiteFriendlyName#", controller="slcms.admin-superdashboard", action="index", params="#PageContextFlags.ReturnLinkParams#&amp;mode=ChangeSubSite&amp;NewSubSiteID=#thisSubsiteDetails.SubSiteID#")#&quot;)
							</cfif>
							</cfoutput> 
							</span>
							<cfset lcntr = lcntr+1 />
						</cfloop>
					</p></div>
					<div><p>&nbsp;The links immediately below will operate on subSite: <span class="majorheading"><cfoutput>#session.SLCMS.Currents.Admin.PageStructure.CurrentSubSiteFriendlyName#</cfoutput></span></p></div>				
				<cfelse>
					<p>This website is a portal but there is only one subSite: <span class="majorheading"><cfoutput>#session.SLCMS.Currents.Admin.PageStructure.CurrentSubSiteFriendlyName#</cfoutput></span></p>
					<p>The links below will operate on this subSite.</p>
				</cfif>	<!--- end: one or more subsites --->
			</cfif>	<!--- end: portal allowed --->
		</td>
	</tr>
	<tr><td colspan="3">
		#linkTo(text="View the URL &gt; DocumentID structure", controller="slcms.admin-superdashboard", action="index", params="#PageContextFlags.ReturnLinkParams#&amp;mode=ViewURL2DocStruct")#
	</td></tr>
	<tr><td colspan="3">
		#linkTo(text="View the application nav Array structure", controller="slcms.admin-superdashboard", action="index", params="#PageContextFlags.ReturnLinkParams#&amp;mode=ViewAppNavArray")#
	</td></tr>
	<tr><td colspan="3"></td></tr>
	<tr><td colspan="3"><u>Global or General Tools</u></td></tr>
	<tr><td colspan="3">Dumps of the Variables Scope in the system management objects:</td></tr>
	<tr><td colspan="3">
		#linkTo(text="View the Module Management Controller", controller="slcms.admin-superdashboard", action="index", params="#PageContextFlags.ReturnLinkParams#&amp;mode=ViewVariablesScope&amp;Set=System&amp;CFC=ModuleManager")#
	</td></tr>
	<tr><td colspan="3">
		#linkTo(text="View the Nexts data", controller="slcms.admin-superdashboard", action="index", params="#PageContextFlags.ReturnLinkParams#&amp;mode=ViewSpecificData&amp;Data=Nexts_getPersistentData&amp;CFC=")#
	</td></tr>
	<tr><td colspan="3">Dumps of the Variables Scope in core content management objects:</td></tr>
	<tr><td colspan="3">
		#linkTo(text="View the Content_DatabaseIO CFC", controller="slcms.admin-superdashboard", action="index", params="#PageContextFlags.ReturnLinkParams#&amp;mode=ViewVariablesScope&amp;Set=Core&amp;CFC=Content_DatabaseIO")#
	</td></tr>
	<tr><td colspan="3">
		#linkTo(text="View the Forms Management CFC", controller="slcms.admin-superdashboard", action="index", params="#PageContextFlags.ReturnLinkParams#&amp;mode=ViewVariablesScope&amp;Set=Core&amp;CFC=Forms")#
	</td></tr>
	<tr><td colspan="3">
		#linkTo(text="View the PageStructure Management CFC", controller="slcms.admin-superdashboard", action="index", params="#PageContextFlags.ReturnLinkParams#&amp;mode=ViewVariablesScope&amp;Set=Core&amp;CFC=PageStructure")#
	</td></tr>
	<tr><td colspan="3">
		#linkTo(text="View the Portal Management CFC", controller="slcms.admin-superdashboard", action="index", params="#PageContextFlags.ReturnLinkParams#&amp;mode=ViewVariablesScope&amp;Set=Core&amp;CFC=portalControl")#
	</td></tr>
	<tr><td colspan="3">
		#linkTo(text="View the SLCMS_Utility Management CFC", controller="slcms.admin-superdashboard", action="index", params="#PageContextFlags.ReturnLinkParams#&amp;mode=ViewVariablesScope&amp;Set=Core&amp;CFC=SLCMS_Utility")#
	</td></tr>
	<tr><td colspan="3">
		#linkTo(text="View the Templates Management CFC", controller="slcms.admin-superdashboard", action="index", params="#PageContextFlags.ReturnLinkParams#&amp;mode=ViewVariablesScope&amp;Set=Core&amp;CFC=Templates")#
	</td></tr>
	<tr><td colspan="3">
		#linkTo(text="View the UserControl Management CFC", controller="slcms.admin-superdashboard", action="index", params="#PageContextFlags.ReturnLinkParams#&amp;mode=ViewVariablesScope&amp;Set=Core&amp;CFC=UserControl")#
	</td></tr>
	<tr><td colspan="3">
		#linkTo(text="View the UserPermissions Management CFC", controller="slcms.admin-superdashboard", action="index", params="#PageContextFlags.ReturnLinkParams#&amp;mode=ViewVariablesScope&amp;Set=Core&amp;CFC=UserPermissions")#
	</td></tr>
	<tr><td colspan="3"></td></tr>
	<tr><td colspan="3">General Scope Dumps:</td></tr>
	<tr><td colspan="3">
		#linkTo(text="View the Application Scope", controller="slcms.admin-superdashboard", action="index", params="#PageContextFlags.ReturnLinkParams#&amp;mode=ViewAppScope")#
	</td></tr>
	<tr><td colspan="3">
		#linkTo(text="View the Session Scope", controller="slcms.admin-superdashboard", action="index", params="#PageContextFlags.ReturnLinkParams#&amp;mode=ViewSessionScope")#
</td></tr>
	<tr><td colspan="3">
		#linkTo(text="View the Server Scope", controller="slcms.admin-superdashboard", action="index", params="#PageContextFlags.ReturnLinkParams#&amp;mode=ViewServerScope")#
	</td></tr>
	<tr><td colspan="3"></td></tr></cfoutput>
	
<cfelseif request.SLCMS.DispMode eq "ViewURL2DocStruct">
	<tr><td colspan="3"></td></tr>
	<tr><td>
		<cfoutput>#linkTo(text="Back to Supervisor's Dashboard", controller="slcms.admin-superdashboard", action="index", params="#PageContextFlags.ReturnLinkParams#")#</cfoutput>
	</td><td colspan="2"></td></tr>
	<tr><td colspan="3">
		<strong>URL &gt; DocumentID</strong> structure:
		<cfif server.mbc_Utility.CFconfig.DumpHasExpandAttribute>
			<br>(Click to Expand structures)
		</cfif>
	</td></tr>
	<tr><td colspan="3">
		<cfif server.mbc_Utility.CFconfig.DumpHasExpandAttribute>
			<cfdump var='#application.SLCMS.Core.PageStructure.getVariablesScope("Site_#session.SLCMS.Currents.Admin.PageStructure.CurrentSubSiteID#")#' expand="false">
		<cfelse>
			<cfdump var='#application.SLCMS.Core.PageStructure.getVariablesScope("Site_#session.SLCMS.Currents.Admin.PageStructure.CurrentSubSiteID#")#'>
		</cfif>
	</td></tr>
	
<cfelseif request.SLCMS.DispMode eq "ViewAppNavArray">
	<tr><td colspan="3"></td></tr>
	<tr><td>
		<cfoutput>#linkTo(text="Back to Supervisor's Dashboard", controller="slcms.admin-superdashboard", action="index", params="#PageContextFlags.ReturnLinkParams#")#</cfoutput>
	</td><td colspan="2"></td></tr>
	<tr><td colspan="3">
		<strong>the application scope Nav Array</strong> structure:
		<cfif server.mbc_Utility.CFconfig.DumpHasExpandAttribute>
			<br>(Click to Expand structures)
		</cfif>
	</td></tr>
	<tr><td colspan="3">
		<cfif server.mbc_Utility.CFconfig.DumpHasExpandAttribute>
			<cfdump var='#application.SLCMS.Core.PageStructure.getFullNavArray(SubSiteID="#session.SLCMS.Currents.Admin.PageStructure.CurrentSubSiteID#")#' expand="false">
		<cfelse>
			<cfdump var='#application.SLCMS.Core.PageStructure.getFullNavArray(SubSiteID="#session.SLCMS.Currents.Admin.PageStructure.CurrentSubSiteID#")#'>
		</cfif>
	</td></tr>
	
<cfelseif request.SLCMS.DispMode eq "ViewAppScope">
	<tr><td colspan="3"></td></tr>
	<tr><td>
		<cfoutput>#linkTo(text="Back to Supervisor's Dashboard", controller="slcms.admin-superdashboard", action="index", params="#PageContextFlags.ReturnLinkParams#")#</cfoutput>
	</td><td colspan="2"></td></tr>
	<tr><td colspan="3">
		the <strong>Application scope</strong> structure: 
		<cfif server.mbc_Utility.CFconfig.DumpHasExpandAttribute>
			<br>(Click to Expand structures)
		</cfif>
	</td></tr>
	<tr><td colspan="3">
		<cfif server.mbc_Utility.CFconfig.DumpHasExpandAttribute>
			<cfdump var='#Application#' expand="false">
		<cfelse>
			<cfdump var='#Application#'>
		</cfif>
	</td></tr>
	
<cfelseif request.SLCMS.DispMode eq "ViewSessionScope">
	<tr><td colspan="3"></td></tr>
	<tr><td>
		<cfoutput>#linkTo(text="Back to Supervisor's Dashboard", controller="slcms.admin-superdashboard", action="index", params="#PageContextFlags.ReturnLinkParams#")#</cfoutput>
	</td><td colspan="2"></td></tr>
	<tr><td colspan="3">
		the <strong>session scope</strong> structure:
		<cfif server.mbc_Utility.CFconfig.DumpHasExpandAttribute>
			<br>(Click to Expand structures)
		</cfif>
	</td></tr>
	<tr><td colspan="3">
		<cfif server.mbc_Utility.CFconfig.DumpHasExpandAttribute>
			<cfdump var='#Session#' expand="false">
		<cfelse>
			<cfdump var='#Session#'>
		</cfif>
	</td></tr>
	
<cfelseif request.SLCMS.DispMode eq "ViewServerScope">
	<tr><td colspan="3"></td></tr>
	<tr><td>
		<cfoutput>#linkTo(text="Back to Supervisor's Dashboard", controller="slcms.admin-superdashboard", action="index", params="#PageContextFlags.ReturnLinkParams#")#</cfoutput>
	</td><td colspan="2"></td></tr>
	<tr><td colspan="3">
		the <strong>Server scope</strong> structure:
		<cfif 1 eq 1 or server.mbc_Utility.CFconfig.DumpHasExpandAttribute>
			<br>(Click to Expand structures)
		</cfif>
	</td></tr>
	<tr><td colspan="3">
		<cfif 1 eq 1 or server.mbc_Utility.CFconfig.DumpHasExpandAttribute>
			<cfdump var='#Server#' expand="false">
		<cfelse>
			<cfdump var='#Server#'>
		</cfif>
	</td></tr>

<cfelseif request.SLCMS.DispMode eq "ViewSpecificData">
	<tr><td colspan="3"></td></tr>
	<tr><td>
		<cfoutput>#linkTo(text="Back to Supervisor's Dashboard", controller="slcms.admin-superdashboard", action="index", params="#PageContextFlags.ReturnLinkParams#")#</cfoutput>
	</td><td colspan="3"></td></tr>
	<cfif params.Data eq "Nexts_getPersistentData">
		<tr><td colspan="3">
		Nexts_getPersistentData<br>
			<cfdump var='#Nexts_getPersistentData()#' expand="false">
		</td></tr>
	</cfif>

<cfelseif request.SLCMS.DispMode eq "ViewVariablesScope">
	<tr><td colspan="3"></td></tr>
	<tr><td>
		<cfoutput>#linkTo(text="Back to Supervisor's Dashboard", controller="slcms.admin-superdashboard", action="index", params="#PageContextFlags.ReturnLinkParams#")#</cfoutput>
	</td><td colspan="3"></td></tr>
	<cfif StructKeyExists(url, "CFC") and ListFindNoCase("Content_DatabaseIO,Forms,ModuleManager,PageStructure,PortalControl,SLCMS_Utility,Templates,UserControl,UserPermissions", url.CFC)>
		<tr><td colspan="3">
			the <strong><cfoutput>#url.CFC#</cfoutput></strong> structure:
			<cfif server.mbc_Utility.CFconfig.DumpHasExpandAttribute>
				<br>(Click to Expand structures)
			</cfif>
		</td></tr>
		<tr><td colspan="3">
			<cfif server.mbc_Utility.CFconfig.DumpHasExpandAttribute>
				<cfdump var='#application.SLCMS["#url.Set#"]["#url.CFC#"].getVariablesScope()#' expand="false">
			<cfelse>
				<cfdump var='#application.SLCMS["#url.Set#"]["#url.CFC#"].getVariablesScope()#'>
			</cfif>
		</td></tr>
	<cfelse>
		<tr><td colspan="3">Invalid Function Set Selected</td></tr>
	</cfif>
	
</cfif>
</table>
</cfif>	<!--- end: has permission --->
</body>
</html>
