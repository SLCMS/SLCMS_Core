<cfcomponent extends="controllers.Controller" output="false" 
	displayname="SLCMS Controllers Controller" 
	hint="Common functions for all SLCMS controllers"
	>

	<cffunction name="init">
	</cffunction>

	<cffunction name="CheckFlags">
		<!--- check if we need to run the install wizard --->
		<cfif application.SLCMS.flags.RunInstallWizard>
			<cflocation url="#application.SLCMS.Paths_Admin.AdminBaseURL#install-wizard" addtoken="false" />
		</cfif>
		<!--- flag if we are popped or not --->
		<cfif StructKeyExists(request.wheels.params, "popped") and request.wheels.params.popped eq "yes">
			<cfset request.SLCMS.flags.PoppedAdminPage = True />
		<cfelse>
			<cfset request.SLCMS.flags.PoppedAdminPage = False />
		</cfif>
	</cffunction>

	<cffunction name="setAdminPageContextFlags"output="No" returntype="struct" access="public"  
		displayname="set Page Context Flags"
		hint="sets the flags used to manage display context, standalone page or popdown over main site"
		>
		<cfargument name="PrependString" type="string" required="no" default="" hint="string to prepend the standard head/title text">
		<cfset PageFlags = {} />
		<cfset PageFlags.IsAdminHomePage = False />
		<cfset PageFlags.BannerHeadString = arguments.PrependString & ' for the <span class="AdminHeadingSiteName">#application.slcms.config.base.SiteName#</span> website' />
		<cfset PageFlags.HeadTitleString = "SLCMS Admin::" & arguments.PrependString & "::#application.slcms.config.base.SiteName#" />
		<cfif application.SLCMS.core.UserPermissions.IsLoggedin()>
			<cfset PageFlags.ShowGoToSiteLink = True />
			<cfset PageFlags.ShowSignInLink = False />
		<cfelse>
			<cfset PageFlags.ShowGoToSiteLink = False />
			<cfset PageFlags.ShowSignInLink = True />
		</cfif>
		<cfif request.SLCMS.flags.PoppedAdminPage>
			<cfset PageFlags.ReturnLinkParams = "&amp;#request.SLCMS.flags.PoppedAdminURLFlagString#" />
		<cfelse>
			<cfset PageFlags.ReturnLinkParams = "" />
		</cfif>
		<!--- as the admin pages can be got at if web server hacked add a second level of security --->
		<cfif not StructKeyExists(session.slcms.user.security, "thisPageSecurityID")>
			<cfset session.slcms.user.security.thisPageSecurityID = CreateUUID()>
		</cfif>
		<cfset PageFlags.ReturnLinkParams = "SecID=#session.slcms.user.security.thisPageSecurityID##PageFlags.ReturnLinkParams#" />
		<cfreturn PageFlags />
	</cffunction>

	<cffunction name="setCommonAdminFlags">
		<cfset request.SLCMS.ErrFlag  = False />
		<cfset request.SLCMS.ErrMsg  = "" />
		<cfset request.SLCMS.GoodMsg  = "" />
		<cfset request.SLCMS.opnext = "">	<!--- what we do next in forms --->
		<!--- DAL related vars we use right thru --->
		<cfset request.SLCMS.DAL = StructNew() />
		<cfset request.SLCMS.DAL.theQueryDataArguments = StructNew() />	<!--- temp struct to compose the data clauses --->
		<cfset request.SLCMS.DAL.theQueryWhereArguments = StructNew() />	<!--- temp struct to compose the where clauses --->
		<cfset request.SLCMS.DAL.theQueryWhereFilters = ArrayNew(1) />	<!--- temp array to compose the filters for where clauses --->

		<cfif StructKeyExists(params, "mode")>
			<cfset request.SLCMS.WorkMode = params.mode />
			<cfset request.SLCMS.DispMode = params.mode />
			<cfset request.SLCMS.WorkMode0 = params.mode />
			<cfset request.SLCMS.DispMode0 = params.mode />
			<cfset request.SLCMS.WorkMode1 = params.mode />
			<cfset request.SLCMS.DispMode1 = params.mode />
			<cfset request.SLCMS.WorkMode2 = params.mode />
			<cfset request.SLCMS.WorkMode3 = params.mode   />
		<cfelse>
			<cfset request.SLCMS.WorkMode = "" />
			<cfset request.SLCMS.DispMode = "" />
			<cfset request.SLCMS.WorkMode0 = "" />
			<cfset request.SLCMS.DispMode0 = "" />
			<cfset request.SLCMS.WorkMode1 = "" />
			<cfset request.SLCMS.DispMode1 = "" />
			<cfset request.SLCMS.WorkMode2 = "" />
			<cfset request.SLCMS.WorkMode3 = "" />
		</cfif>
	</cffunction>

</cfcomponent>