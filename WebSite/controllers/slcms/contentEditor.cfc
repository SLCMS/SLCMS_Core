<cfcomponent extends="Controller">
	<!--- all the goodies that the SuperAdmin can use to check things out --->

	<cffunction name="init">
		<!--- use what we have in the common controller for SLCMS --->
		<cfset super.init() />
		<!--- we use a common layout for the admin pages, and also a couple of standard includePartial()s --->
	  <cfset usesLayout(template="/slcms/Layout", except="myajax")>
	</cffunction>

	<cffunction name="index">
		<!--- Content Edit home --->
		<cfset CheckFlags() />	<!--- see if we need to run install wiz or any other startup stuff --->
		<cfset setCommonAdminFlags() />	<!--- set all the common page variables --->
		<cfset setAdminPageContextFlags() />	<!--- set global display flags --->
		<!--- now customize for this particular page --->
		<cfset WorkMode2 = "GetUserList">
		<cfset DispMode = "ShowUserList">
		<cfset DispSubMode1 = "Local" />	<!--- gets changed if we came from the EmptySiteWorkflow startup page --->
		<!--- 
		<cfset PageContextFlags = application.SLCMS.Core.ControllerHelpers_Admin.setPageContextFlags("Developer's Toolkit") />
		 --->

<!--- 
FileManager/cffm.cfm
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