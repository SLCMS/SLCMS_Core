<cfcomponent extends="Controller">
	<!--- all the goodies that the SuperAdmin can use to check things out --->

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
		<cfset WorkMode1 = "">
		<cfset WorkMode2 = "GetBaseDisplayItems">
		<cfset DispMode = "ShowBaseDisplayItems">
		<cfset PagesHaveTemplatesOnly = True />
		<!--- DAL related vars we use right thru --->
		<cfset theQueryDataArguments = StructNew() />	<!--- temp struct to compose the data clauses of SQL queries --->
		<cfset theQueryWhereArguments = StructNew() />	<!--- temp struct to compose the where clauses of SQL queries --->
		<cfset theQueryWhereFilters = ArrayNew(1) />	<!--- temp array to compose the filters for where clauses --->

		<!--- as this page can be got at if web server hacked add a second level of security --->
		<cfif not StructKeyExists(session.slcms.user.security, "thisPageSecurityID")>
			<cfset session.slcms.user.security.thisPageSecurityID = CreateUUID()>
		</cfif>
		<!--- set global display flags --->
		<cfset PageContextFlags = application.SLCMS.Core.ControllerHelpers_Admin.setPageContextFlags("System Management") />
  </cffunction>

	<cffunction name="create">
		<cfset ErrFlag  = False>
		<cfset ErrMsg  = "">
		<cfset GoodMsg  = "">
		<cfset opnext = "">	<!--- what we do next --->
		<cfset WorkMode1 = "">
		<cfset WorkMode2 = "GetBaseDisplayItems">
		<cfset DispMode = "ShowBaseDisplayItems">
		<cfset DispSubMode1 = "Local" />	<!--- gets changed if we came from the EmptySiteWorkflow startup page --->
		<!--- DAL related vars we use right thru --->
		<cfset theQueryDataArguments = StructNew() />	<!--- temp struct to compose the data clauses of SQL queries --->
		<cfset theQueryWhereArguments = StructNew() />	<!--- temp struct to compose the where clauses of SQL queries --->
		<cfset theQueryWhereFilters = ArrayNew(1) />	<!--- temp array to compose the filters for where clauses --->

		<!--- as this page can be got at if web server hacked add a second level of security --->
		<cfif not StructKeyExists(session.slcms.user.security, "thisPageSecurityID")>
			<cfset session.slcms.user.security.thisPageSecurityID = CreateUUID()>
		</cfif>
		<!--- set global display flags --->
		<cfset PageContextFlags = application.SLCMS.Core.ControllerHelpers_Admin.setPageContextFlags("System Management") />
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
		<cfset WorkMode1 = "">
		<cfset WorkMode2 = "GetBaseDisplayItems">
		<cfset DispMode = "ShowBaseDisplayItems">
		<cfset DispSubMode1 = "Local" />	<!--- gets changed if we came from the EmptySiteWorkflow startup page --->
		<!--- DAL related vars we use right thru --->
		<cfset theQueryDataArguments = StructNew() />	<!--- temp struct to compose the data clauses of SQL queries --->
		<cfset theQueryWhereArguments = StructNew() />	<!--- temp struct to compose the where clauses of SQL queries --->
		<cfset theQueryWhereFilters = ArrayNew(1) />	<!--- temp array to compose the filters for where clauses --->

		<!--- as this page can be got at if web server hacked add a second level of security --->
		<cfif not StructKeyExists(session.slcms.user.security, "thisPageSecurityID")>
			<cfset session.slcms.user.security.thisPageSecurityID = CreateUUID()>
		</cfif>
		<!--- set global display flags --->
		<cfset PageContextFlags = application.SLCMS.Core.ControllerHelpers_Admin.setPageContextFlags("Superuser's Administration") />
<!--- 		
		<cfset PageContextFlags.HeadTitleString = "SLCMS Admin Page Structure::#application.slcms.config.base.SiteName#" />
		<cfset PageContextFlags.BannerHeadString = PageContextFlags.BannerHeadString />
 --->		
		<cfset renderPage(action="index") />
  </cffunction>



	
</cfcomponent>