<cfcomponent extends="Controller">
	<!---manage the staff memebrs of the site, admins, editors and authors --->

	<cffunction name="init">
		<!--- use what we have in the common controller for SLCMS --->
		<cfset super.init() />
		<!--- we use a common layout for the admin pages, and also a couple of standard includePartial()s --->
	  <cfset usesLayout(template="/slcms/Layout", except="myajax")>
	</cffunction>

	<cffunction name="index">
		<!--- admin SuperUsers home --->
		<cfset ErrFlag  = False>
		<cfset ErrMsg  = "">
		<cfset GoodMsg  = "">
		<cfset opnext = "">	<!--- what we do next --->
		<cfset setModes() />
		<cfset theFormPlacement = "" />
		<!--- DAL related vars we use right thru --->
		<cfset theQueryDataArguments = StructNew() />	<!--- temp struct to compose the data clauses of SQL queries --->
		<cfset theQueryWhereArguments = StructNew() />	<!--- temp struct to compose the where clauses of SQL queries --->
		<cfset theQueryWhereFilters = ArrayNew(1) />	<!--- temp array to compose the filters for where clauses --->

		<!--- as this page can be got at if web server hacked add a second level of security --->
		<cfif not StructKeyExists(session.slcms.user.security, "thisPageSecurityID")>
			<cfset session.slcms.user.security.thisPageSecurityID = CreateUUID()>
		</cfif>
		<!--- set global display flags --->
		<cfset PageContextFlags = application.SLCMS.Core.ControllerHelpers_Admin.setPageContextFlags("index Template and Stylesheet Management") />
  </cffunction>

	<cffunction name="create">
		<cfset ErrFlag  = False>
		<cfset ErrMsg  = "">
		<cfset GoodMsg  = "">
		<cfset opnext = "">	<!--- what we do next --->
		<cfset setModes() />
		<cfset theFormPlacement = "" />
		<!--- DAL related vars we use right thru --->
		<cfset theQueryDataArguments = StructNew() />	<!--- temp struct to compose the data clauses of SQL queries --->
		<cfset theQueryWhereArguments = StructNew() />	<!--- temp struct to compose the where clauses of SQL queries --->
		<cfset theQueryWhereFilters = ArrayNew(1) />	<!--- temp array to compose the filters for where clauses --->

		<!--- as this page can be got at if web server hacked add a second level of security --->
		<cfif not StructKeyExists(session.slcms.user.security, "thisPageSecurityID")>
			<cfset session.slcms.user.security.thisPageSecurityID = CreateUUID()>
		</cfif>
		<!--- set global display flags --->
		<cfset PageContextFlags = application.SLCMS.Core.ControllerHelpers_Admin.setPageContextFlags("create Template and Stylesheet Management") />
<!--- 		
		<cfset PageContextFlags.HeadTitleString = "SLCMS Admin Page Structure::#application.slcms.config.base.SiteName#" />
		<cfset PageContextFlags.BannerHeadString = PageContextFlags.BannerHeadString />
 --->		
		<cfset renderPage(action="index") />
  </cffunction>


	<cffunction name="update">
		<cfset ErrFlag  = False>
		<cfset ErrMsg  = "">
		<cfset GoodMsg  = "">
		<cfset opnext = "">	<!--- what we do next --->
		<cfset setModes() />
		<cfset theFormPlacement = "" />
		<!--- DAL related vars we use right thru --->
		<cfset theQueryDataArguments = StructNew() />	<!--- temp struct to compose the data clauses of SQL queries --->
		<cfset theQueryWhereArguments = StructNew() />	<!--- temp struct to compose the where clauses of SQL queries --->
		<cfset theQueryWhereFilters = ArrayNew(1) />	<!--- temp array to compose the filters for where clauses --->

		<!--- as this page can be got at if web server hacked add a second level of security --->
		<cfif not StructKeyExists(session.slcms.user.security, "thisPageSecurityID")>
			<cfset session.slcms.user.security.thisPageSecurityID = CreateUUID()>
		</cfif>
		<!--- set global display flags --->
		<cfset PageContextFlags = application.SLCMS.Core.ControllerHelpers_Admin.setPageContextFlags("update Template and Stylesheet Management") />
<!--- 		
		<cfset PageContextFlags.HeadTitleString = "SLCMS Admin Page Structure::#application.slcms.config.base.SiteName#" />
		<cfset PageContextFlags.BannerHeadString = PageContextFlags.BannerHeadString />
 --->		
		<cfset renderPage(action="index") />
  </cffunction>

  <cffunction name="setModes" returntype="Any" output="false" hint="takes incoming params and sets workmode, displayMode, etc">
		<cfset request.SLCMS.modes = structNew() />
	  <cfif structKeyExists(params, "job")>
			<cfset request.SLCMS.modes.WorkMode0 = params.job />
			<cfset request.SLCMS.modes.WorkMode1 = params.job />
			<cfset request.SLCMS.modes.WorkMode2 = params.job />
			<cfset request.SLCMS.modes.DispMode = params.job />
		<cfelse>
			<cfset request.SLCMS.modes.WorkMode0 = "" />
			<cfset request.SLCMS.modes.WorkMode1 = "InitialEntry" />
			<cfset request.SLCMS.modes.WorkMode2 = "" />
			<cfset request.SLCMS.modes.DispMode = "ViewTypes" />
		</cfif>
		<cfif structKeyExists(params, "SubSiteID")>
			<cfset session.SLCMS.Currents.Admin.templates.CurrentSubSiteID = params.SubSiteID />
		</cfif>
		<cfset request.SLCMS.PortalAllowed = application.SLCMS.Core.PortalControl.IsPortalAllowed() />
	</cffunction>

	
</cfcomponent>