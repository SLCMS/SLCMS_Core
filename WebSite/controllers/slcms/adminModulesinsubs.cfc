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
		<cfset WorkMode2 = "GetUserList">
		<cfset DispMode = "ShowUserList">
		<cfset DispSubMode1 = "Local" />	<!--- gets changed if we came from the EmptySiteWorkflow startup page --->
		<!--- DAL related vars we use right thru --->
		<cfset theQueryDataArguments = StructNew() />	<!--- temp struct to compose the data clauses of SQL queries --->
		<cfset theQueryWhereArguments = StructNew() />	<!--- temp struct to compose the where clauses of SQL queries --->
		<cfset theQueryWhereFilters = ArrayNew(1) />	<!--- temp array to compose the filters for where clauses --->
		<!--- set global display flags --->
		<cfset PageContextFlags = application.SLCMS.Core.ControllerHelpers_Admin.setPageContextFlags("Developer's Toolkit") />
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