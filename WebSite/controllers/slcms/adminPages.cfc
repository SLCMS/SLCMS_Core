p;lp;<cfcomponent extends="Controller">

	<cffunction name="init">
		<!--- use what we have in the common controller for SLCMS --->
		<cfset super.init() />
		<!--- we use a common layout for the admin pages, and also a couple of standard includePartial()s --->
	  <cfset usesLayout(template="/slcms/Layout", except="myajax")>
	</cffunction>

	<cffunction name="index">
		<!--- admin pages home --->
		<!--- set global display flags --->
		<cfset PageContextFlags = application.SLCMS.Core.ControllerHelpers_Admin.setPageContextFlags("Page Structure Administration") />
<!--- 
		<cfset PageContextFlags.HeadTitleString = "SLCMS Admin Page Structure::#application.slcms.config.base.SiteName#" />
		<cfset PageContextFlags.BannerHeadString = "Page Structure " & PageContextFlags.BannerHeadString />
		 --->
		<!--- as this page can be got at if web server hacked add a second level of security --->
		<cfif not StructKeyExists(session.slcms.user.security, "thisPageSecurityID")>
			<cfset session.slcms.user.security.thisPageSecurityID = CreateUUID()>
		</cfif>
		<cfset $include(template="SLCMS/Core/includes/__Admin_PageStructure-Functions.cfm") />
		<cfset $include(template="SLCMS/Core/includes/__Admin_PageStructure-Code.cfm") />
  </cffunction>

	<cffunction name="create">
		<!--- as this page can be got at if web server hacked add a second level of security --->
		<cfif not StructKeyExists(session.slcms.user.security, "thisPageSecurityID")>
			<cfset session.slcms.user.security.thisPageSecurityID = CreateUUID()>
		</cfif>
		<cfset PageContextFlags = application.SLCMS.Core.ControllerHelpers_Admin.setPageContextFlags("Page Structure Administration") />
		<cfset $include(template="SLCMS/Core/includes/__Admin_PageStructure-Functions.cfm") />
		<cfset $include(template="SLCMS/Core/includes/__Admin_PageStructure-Code.cfm") />
		<cfset renderPage(action="index") />
  </cffunction>



	
</cfcomponent>