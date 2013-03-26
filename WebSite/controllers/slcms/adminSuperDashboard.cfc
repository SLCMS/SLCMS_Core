<cfcomponent extends="Controller">
	<!--- all the goodies that the SuperAdmin can use to check things out --->

	<cffunction name="init">
		<!--- use what we have in the common controller for SLCMS --->
		<cfset super.init() />
		<!--- we use a common layout for the admin pages, and also a couple of standard includePartial()s --->
	  <cfset usesLayout(template="/slcms/Layout", except="myajax")>
	</cffunction>

	<cffunction name="index">
		<!--- admin pages home --->
		<cfset commonAdminFlags() />
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
				<!--- set up our vars to display the structure from --->
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

		<!--- as this page can be got at if web server hacked add a second level of security --->
		<cfif not StructKeyExists(session.slcms.user.security, "thisPageSecurityID")>
			<cfset session.slcms.user.security.thisPageSecurityID = CreateUUID()>
		</cfif>
		<!--- set global display flags --->
		<cfset PageContextFlags = application.SLCMS.Core.ControllerHelpers_Admin.setPageContextFlags("Super's Dashboard") />
<!--- 
		<cfset PageContextFlags.HeadTitleString = "SLCMS Admin Page Structure::#application.slcms.config.base.SiteName#" />
		<cfset PageContextFlags.BannerHeadString = "Page Structure " & PageContextFlags.BannerHeadString />
		 --->
  </cffunction>
<!--- 
	<cffunction name="create">
		<cfset PageContextFlags = application.SLCMS.Core.ControllerHelpers_Admin.setPageContextFlags("Page Structure") />
		
		<cfset PageContextFlags.HeadTitleString = "SLCMS Admin Page Structure::#application.slcms.config.base.SiteName#" />
		<cfset PageContextFlags.BannerHeadString = PageContextFlags.BannerHeadString />
		
		<cfset renderPage(action="index") />
  </cffunction>
 --->


	
</cfcomponent>