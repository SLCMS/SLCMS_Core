<!--- mbc SLCMS --->
<!--- &copy; 2012 mort bay communications --->
<!---  --->
<!--- Content CFM functions  --->
<!--- carries all of the functions used by Content.cfm to make a page happen --->
<!--- Contains:
			init - sets up in persistent in application scope so content.cfm can grab easily
			lots more related stuff :-)
			 --->
<!---  --->
<!--- created:  19th Apr 2009 by Kym K, mbcomms --->
<!--- modified: 19th Apr 2009 -  7th May 2009 by Kym K, mbcomms: initial work on it, this has been V2.2 from the word go --->
<!--- modified:  3rd Nov 2009 -  5th Nov 2009 by Kym K, mbcomms:	reworking portal-related code to stop using session scope to allow for mutiple tabs open at once
																																 put subSiteID in request scope so needs to be fed in and out here --->
<!--- modified: 17th Nov 2009 - 17th Nov 2009 by Kym K, mbcomms: changed param fed to GetSubSiteIDfromURL(cgi.server_name) instead of cgi.http_host, umm --->
<!--- modified:  9th Feb 2011 -  9th Feb 2011 by Kym K, mbcomms: added AddHeadContent() as an API call for modules to use to add in styles and scripts --->
<!--- modified: 20th Feb 2011 - 26th Feb 2011 by Kym K, mbcomms: major change to getDocFromURL() to handle SEO paths that are longer than the doc for modules like shops, etc --->
<!--- modified:  6th May 2011 -  7th May 2011 by Kym K, mbcomms: adding functionality to AddHeadContent() to help jQuery extra functionality --->
<!--- modified: 10th Jun 2011 - 19th Jun 2011 by Kym K, mbcomms: improving path decoding for subSites when we have modules in the mix --->
<!--- modified:  2nd Jan 2012 -  4th Jan 2012 by Kym K, mbcomms: changed the way templates are handled, changed template manager calls here to match --->
<!--- modified:  9th Apr 2012 -  9th Apr 2012 by Kym K, mbcomms: V3.0, CFWheels version. Now an include in true CFWheels style --->


<!--- initialize the various thingies, this should only be called after an app scope refresh --->
<cffunction name="init" 
	access="public" output="yes" returntype="any" 
	displayname="Initializer"
	hint="sets up the internal structures for this component"
	>
	<cfreturn this  />
</cffunction>

<cffunction name="getDocFromURL" output="yes" returntype="struct" access="public"
	displayname="get Doc data From URL"
	hint="returns the base data for the doc to be displayed, calculated from the URL, CGI, etc., scopes"
	>

	<!--- vars that will get filled as we go --->
	<cfset var temp = "" />	<!--- temp/throwaway var --->
	<cfset var theScriptLen = 0 />	<!--- temp URL calculations --->
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorContext = "ContentCFMfunctions CFC: getDocFromURL()" />
	<cfset ret.error.ErrorExtra = "" />
	<cfset ret.Data = StructNew() />	<!--- no data yet --->
	<cfset ret.Data.SubSiteID = 0 />	<!--- assume top unless otherwise calculated --->
	<cfset ret.Data.SubSiteShortName = "" />	<!--- assume top unless otherwise calculated --->
	<cfset ret.Data.SubSiteNavName = "" />	<!--- assume top unless otherwise calculated --->
	<cfset ret.Data.DocID = 0 />
	<cfset ret.Data.DocPath = "" />
	<cfset ret.Data.ModuleParams = "" />
	<cfset ret.Data.wikibits = StructNew() />	<!--- and no wiki data yet --->

	<!--- wrap the whole thing in a try/catch in case something breaks --->
	<cftry>
	<!--- first get the page's data from the SiteStructure CFC --->
	<cfif application.SLCMS.Config.base.AllowDirectDocIDs and IsDefined("url.docID") and IsNumeric(url.docID)>
	<!--- this first bit is to allow for direct calls of this page rather than as a uniquely-named page 
					for testing and whatever else
					Normally turned off in the base config --->
		<cfset ret.Data.DocID = url.DocID />
		<cfset ret.Data.theParams = "" />
		<cfset ret.Data.theQueryString = URLDecode(cgi.query_string) />
	<cfelseif IsDefined("cgi.Script_Name")>
		<!--- normal running so work out our paths and things --->
		<!--- strip out any mapping and the leading / --->
		<cfset ret.Data.ScriptPath = trim(cgi.Script_Name) />
		<cfif left(ret.Data.ScriptPath, Len(request.SLCMS.rootURL)) eq request.SLCMS.rootURL>
			<cfset ret.Data.ScriptPath = RemoveChars(ret.Data.ScriptPath, 1, Len(request.SLCMS.rootURL))>
		</cfif>
		<!--- then set variables related to that path --->
		<!--- now we see if the page SearchEngineFriendly path is null if so then use the above and default home page info, 
					otherwise work out what we want to see --->
		<!--- we first do a wrinkle to compensate for the behaviours of IIS compared with Apache --->
		<cfset theScriptLen = len(cgi.script_name) />
		<cfif left(cgi.path_info, theScriptLen) eq cgi.script_name>
			<!--- the left part of the path info is the page's name so we have to strip it out, this is IIS  --->
			<cfset ret.Data.theParams = removeChars(cgi.path_info, 1, theScriptLen) />
		<cfelse>	
			<cfset ret.Data.theParams = cgi.path_info />
		</cfif>
		<!--- strip any params that might be tagged on the end, can be in URL but not here but why take chances --->
		<cfset ret.Data.theParams = ListFirst(ret.Data.theParams, "?") />	<!--- just in case --->
		<cfset ret.Data.theQueryString = URLDecode(cgi.query_string) />	<!--- this is always legit --->
		<cfif right(ret.Data.theParams, 1) eq "/">	<!--- strip trailing slashes --->
			<cfset ret.Data.theParams = RemoveChars(ret.Data.theParams, len(ret.Data.theParams), 1) />
		</cfif>
		<!--- now we have a path to our site, possibly encoded, so work out if we are in a portal subsite or not and from that look up the DocID --->
		<cfset ret.Data.SubSiteID = application.SLCMS.Core.PortalControl.GetSubSiteIDfromURL(cgi.server_name) />	<!--- this will grab the ID of the subsite if we are in one or pass back 0 if we are not --->
		<cfif len(ret.Data.theParams)>
			<!--- decode it so it is clean --->
			<cfset ret.Data.theParams = application.SLCMS.Core.PageStructure.DecodeNavName(ret.Data.theParams) />
			<!--- and grab the docID and related useful things --->
			<cfset ret.Data.DocIDStruct = application.SLCMS.Core.PageStructure.getDocIDfromURL(URLpath="#ret.Data.theParams#", SubSiteID="#ret.Data.SubSiteID#") />
			<cfset ret.Data.DocID = ret.Data.DocIDStruct.DocID />
			<cfset ret.Data.DocPath = ret.Data.DocIDStruct.DocPath />
			<cfset ret.Data.SubSiteID = ret.Data.DocIDStruct.SubSiteID />	<!--- if we have wound down from the portal to a subsite this could have changed --->
			<cfset ret.Data.ContentTypeID = ret.Data.DocIDStruct.ContentTypeID />
			<cfset ret.Data.ModuleParams = ret.Data.DocIDStruct.ModuleParams />
			<cfset ret.Data.wikibits.wikiDocID = ret.Data.DocIDStruct.wikiDocID />
			<cfset ret.Data.wikibits.wikiHomePath = ret.Data.DocIDStruct.wikiHomePath />
			<cfset ret.Data.wikibits.wikiHomePathEncoded = application.SLCMS.Core.PageStructure.EncodeNavName(NavName="#ret.Data.DocIDStruct.wikiHomePath#", SkipSlashes=True) />
			<cfset ret.Data.wikibits.wikiPageName = ret.Data.DocIDStruct.wikiPageName />
			<cfset ret.Data.wikibits.wikiPageNameEncoded = application.SLCMS.Core.PageStructure.EncodeNavName(ret.Data.DocIDStruct.wikiPageName) />
			<!--- now check to see if we are trying to display a module page --->
			<cfif ret.Data.DocID neq 0 and ret.Data.ModuleParams neq "">
				<!--- something there so lets see what --->
				<!---  as it could be an as yet non-existant wiki page we also need to tell if we are being asked to create it --->
				<cfif listFirst(ret.Data.theQueryString, "=") eq "task" and listLast(ret.Data.theQueryString, "=") eq "create" and ret.Data.ModuleParams neq "">
					<!--- ToDo: put the call to the wiki page maker here --->
					<cfset ret.Data.CreateWikiPage = True />
					<cfset temp = application.SLCMS.Core.PageStructure.MakeWikiPage(DocID="#ret.Data.DocID#", WikiPath="#ret.Data.ModuleParams#", SubSiteID="#ret.Data.SubSiteID#") />
				</cfif>
			</cfif>
		<cfelse>
			<!--- no params so go to the home page for the relevant subsite --->	
			<cfset ret.Data.DocID = application.SLCMS.Core.PageStructure.getHomePageDocID(SubSiteID=ret.Data.SubSiteID) />
			<cfset ret.Data.DocIDStruct = application.SLCMS.Core.PageStructure.getSingleDocStructure(DocID="#ret.Data.DocID#", SubSiteID="#ret.Data.SubSiteID#") />
			<cfset ret.Data.ContentTypeID = 1 />
			<cfset ret.Data.wikibits.wikiDocID = 0 />
			<cfset ret.Data.wikibits.wikiHomePath = application.SLCMS.Config.Base.rootURL />
			<cfset ret.Data.wikibits.wikiHomePathEncoded = application.SLCMS.Config.Base.rootURL />
			<cfset ret.Data.wikibits.wikiPageName = "" />
			<cfset ret.Data.wikibits.wikiPageNameEncoded = "" />
			<!--- 
				<cfset ret.Data.DocID = 0 />
				<cfset ret.Data.SubSiteID = 0 />
				<cfset ret.Data.ContentTypeID = 0 />
				<cfset ret.Data.wikibits.wikiDocID = 0 />
				<cfset ret.Data.wikibits.wikiHomePath = application.SLCMS.Config.Base.rootURL />
				<cfset ret.Data.wikibits.wikiHomePathEncoded = application.SLCMS.Config.Base.rootURL />
				<cfset ret.Data.wikibits.wikiPageName = "" />
				<cfset ret.Data.wikibits.wikiPageNameEncoded = "" />
			 --->
		</cfif>	
		<!--- we might have changed the subsite id if we dug down from the top so reset here --->
		<cfif ret.Data.SubSiteID neq "">
			<cfset temp = application.SLCMS.Core.PortalControl.GetSubSite(SubSiteID="#ret.Data.SubSiteID#") />
			<cfif temp.error.errorcode eq 0>
				<cfset ret.Data.SubSiteShortName = temp.data.SubSiteShortName />
				<cfset ret.Data.SubSiteNavName = temp.data.SubSiteNavName />
			<cfelse>
				<cfset ret.Data.SubSiteShortName = "" />
				<cfset ret.Data.SubSiteNavName = "" />
			</cfif>
		</cfif>
	<cfelse>
		<!--- how did we get here? web server lost the plot or no params, goto home page --->
		<cfset ret.Data.DocID = 0 />
		<cfset ret.Data.SubSiteID = 0 />
		<cfset ret.Data.ContentTypeID = 0 />
		<cfset ret.Data.wikibits.wikiDocID = 0 />
		<cfset ret.Data.wikibits.wikiHomePath = "" />
		<cfset ret.Data.wikibits.wikiHomePathEncoded = "" />
		<cfset ret.Data.wikibits.wikiPageName = "" />
		<cfset ret.Data.wikibits.wikiPageNameEncoded = "" />
	</cfif>
	
	<cfif ret.Data.DocID eq 0>
		<!--- no useful docID so go to the home page --->	
		<cfset ret.Data.DocID =application.SLCMS.Core.PageStructure.getHomePageDocID(SubSiteID=ret.Data.SubSiteID) />
		<cfset ret.Data.ContentTypeID = 1 />
		<cfset ret.Data.SubSiteID = 0 />
		<cfset temp = application.SLCMS.Core.PortalControl.GetSubSite(SubSiteID="#ret.Data.SubSiteID#").data />
		<cfset ret.Data.SubSiteShortName = temp.SubSiteShortName />
		<cfset ret.Data.SubSiteNavName = temp.SubSiteNavName />
	</cfif>	

	<cfcatch type="any">
		<cfset ret.error = TakeErrorCatch(RetErrorStruct=ret.error, CatchStruct=cfcatch) />
	</cfcatch>
	</cftry>

	<!--- return our data structure --->
	<cfreturn ret  />
</cffunction>

<cffunction name="SetInitialHeadContent" output="yes" returntype="struct" access="public"
	displayname="Set Initial Head Content"
	hint="sets up the intial structures for the head content section of the page params"
	>

	<!--- now vars that will get filled as we go --->
	<cfset var temp = "" />	<!--- temp/throwaway var --->
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorContext = "ContentCFMfunctions CFC: setInitialHeadContent()" />
	<cfset ret.error.ErrorExtra = "" />
	<cfset ret.Data = StructNew() />	<!--- and no data yet --->

	<cftry>
		<cfset ret.Data.Start = StructNew() />
		<cfset ret.Data.Start.FileList = "" />	<!--- carries a list of the added files so we don't add them twice from display tags like the navigation ones --->
		<cfset ret.Data.Start.Strings = ArrayNew(1) />	<!--- this will contain strings for style sheets and whatever that need adding at the start of the html head section, before the Head content from the template --->
		<cfset ret.Data.Start.Strings[1] = '<link rel="stylesheet" href="#application.SLCMS.Config.Base.rootURL#SLCMS/SLCMSstyling/slcms.css" type="text/css">' />	<!--- our global style for containers and the like that is always used. Put at the start so it can be overidden --->
		<cfset ret.Data.Start.FileList = ListAppend(ret.Data.Start.FileList, "#application.SLCMS.Config.Base.rootURL#SLCMS/SLCMSstyling/slcms.css") />
		<cfset ret.Data.Start.Strings[2] = '<link rel="stylesheet" href="#application.SLCMS.Config.Base.rootURL#SLCMS/SLCMSstyling/SLCMSFormStyles.css" type="text/css">' />	<!--- our global style for forms. Put at the start so it can be overidden --->
		<cfset ret.Data.Start.FileList = ListAppend(ret.Data.Start.FileList, "#application.SLCMS.Config.Base.rootURL#SLCMS/SLCMSstyling/SLCMSFormStyles.css") />
		<cfset ret.Data.End = StructNew() />
		<cfset ret.Data.End.FileList = "" />
		<cfset ret.Data.End.Strings = ArrayNew(1) />	<!--- this will contain strings for style sheets and whatever that need adding at the end of the html head section, after the Head content from the template --->
	<cfcatch type="any">
		<cfset ret.error = TakeErrorCatch(RetErrorStruct=ret.error, CatchStruct=cfcatch) />
	</cfcatch>
	</cftry>

<!--- return our data structure --->
<cfreturn ret  />
</cffunction>

<cffunction name="AddHeadContent" output="yes" returntype="struct" access="public"
	displayname="Add Head Content"
	hint="adds a line of text to the head content. NOTE: Not Encapsulated Function, it adds to the request.SLCMS.PageParams.HeadContent struct directly"
	>
	<cfargument name="Type" default="Script" hint="StyleSheet|Script (default: Script)">	
	<cfargument name="Place" default="Top" hint="Top|Bottom - the place we want the line of html put, defaults to the top">	
	<cfargument name="Path" default="Top" hint="the path of the stylesheet or script">	
	<cfargument name="IDlabel" default="" hint="id of tag if needed">	

	<cfset var temp = "" />
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorContext = "ContentCFMfunctions CFC: AddHeadContent()" />
	<cfset ret.error.ErrorExtra = "" />
	<cfset ret.Data = StructNew() />	<!--- and no data yet --->

	<cftry>
	<cfif arguments.Path neq "">
		<cfif arguments.IDlabel neq "">
			<cfset theIDstring = ' ID="#arguments.IDlabel#"' />
		<cfelse>
			<cfset theIDstring = "" />
		</cfif>
		<cfif arguments.Place eq "Bottom">
			<cfif not ListFindNoCase(request.SLCMS.PageParams.HeadContent.End.FileList, "#arguments.Path#")> <!--- make sure we don't add it twice --->
				<cfset request.SLCMS.PageParams.HeadContent.End.FileList = ListAppend(request.SLCMS.PageParams.HeadContent.End.FileList, "#arguments.Path#") />
				<cfif arguments.Type eq "StyleSheet">
					<cfset temp = ArrayAppend(request.SLCMS.PageParams.HeadContent.End.Strings, '<link type="text/css" rel="stylesheet" href="#arguments.Path#"#theIDstring#>') />
				<cfelseif arguments.Type eq "Script">
					<cfset temp = ArrayAppend(request.SLCMS.PageParams.HeadContent.End.Strings, '<script type="text/javascript" src="#arguments.Path#"></script>#theIDstring#') />
				</cfif>
			</cfif>
		<cfelse>
			<cfif not ListFindNoCase(request.SLCMS.PageParams.HeadContent.Start.FileList, "#arguments.Path#")> <!--- make sure we don't add it twice --->
				<cfset request.SLCMS.PageParams.HeadContent.Start.FileList = ListAppend(request.SLCMS.PageParams.HeadContent.Start.FileList, "#arguments.Path#") />
				<cfif arguments.Type eq "StyleSheet">
					<cfset temp = ArrayAppend(request.SLCMS.PageParams.HeadContent.Start.Strings, '<link type="text/css" rel="stylesheet" href="#arguments.Path#"#theIDstring#>') />
				<cfelseif arguments.Type eq "Script">
					<cfset temp = ArrayAppend(request.SLCMS.PageParams.HeadContent.Start.Strings, '<script type="text/javascript" src="#arguments.Path#"#theIDstring#></script>') />
				</cfif>
			</cfif>
		</cfif>
	</cfif>
	<cfcatch type="any">
		<cfset ret.error = TakeErrorCatch(RetErrorStruct=ret.error, CatchStruct=cfcatch) />
	</cfcatch>
	</cftry>

<!--- return our data structure --->
<cfreturn ret  />
</cffunction>

<cffunction name="getSubSitePaths" output="yes" returntype="struct" access="public"
	displayname="Set SubSite Paths"
	hint="sets up the paths into page params for the templates, etc., for this subsite
				it uses sessions and app scopes to get data and returns a struct with the details, no error handling"
	>
	<cfargument name="PageParam1" default="" hint="PageParam1 for this page, contains the template name">	
	<cfargument name="SubSiteID" default="" hint="what subsite we are in">	<!--- passed in as no longer in the session scope, have to handle multiple tabs/windows open at once --->
	<cfargument name="SubSiteShortName" default="" hint="short name subsite we are in, which is the folder name">	<!--- passed in as no longer in the session scope, have to handle multiple tabs/windows open at once --->

	<cfset var thePageParam1 = trim(arguments.PageParam1) />	<!--- which subsite this page is in --->
	<!--- now vars that will get filled as we go --->
	<cfset var theSubSiteID = trim(arguments.SubSiteID) />	<!--- which subsite this page is in --->
	<cfset var theSubSiteShortName = trim(arguments.SubSiteShortName) />	<!--- which subsite this page is in --->
	<cfset var temp = "" />	<!--- temp/throwaway var --->
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<cfset ret.Error = StructNew() />
	<cfset ret.error.errorcode = 0 />
	<cfset ret.Error.ErrorContext = "ContentCFMfunctions CFC: getSubSitePaths()" />
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.Physical = StructNew() />	<!--- this is the return of the physical paths --->
	<cfset ret.URL = StructNew() />	<!--- this is the return of the URL paths --->
	<cfset ret.Physical.thePageTemplateSetBasePath = "" />	<!--- no path yet --->
	<cfset ret.Physical.thisPageTemplateBasePath = "" />	<!--- no path yet --->
	<cfset ret.Physical.thisPageTemplateFullPath = "" />	<!--- no path yet --->
	<cfset ret.URL.thePageTemplatesBaseURL = "" />	<!--- no path yet --->
	<cfset ret.URL.thisPageTemplateSetURLpath = "" />	<!--- no path yet --->
	<cfset ret.URL.thisPageTemplateFullURL = "" />	<!--- no path yet --->
	<cfset ret.URL.thisPageTemplateControlURLpath = "" />	<!--- no path yet --->
	<cfset ret.URL.thisPageTemplateGraphicsURLpath = "" />	<!--- no path yet --->
	<cfset ret.URL.thisPageTemplateIncludesURLpath = "" />	<!--- no path yet --->
					
	<cftry>
		<cfif ListLen(request.SLCMS.PageParams.Param1, "/") eq 3>	<!--- test for a shared template --->
			<cfset ret.TemplateSource = ListFirst(request.SLCMS.PageParams.Param1, "/") />	<!--- where the template set lives, in shared probably --->
			<cfset ret.TemplateSetName = ListGetAt(request.SLCMS.PageParams.Param1, 2, "/") />	<!--- the name of the template set if we need it --->
			<cfset ret.URL.thesubSiteBaseURL =  application.SLCMS.Config.Base.rootURL & application.SLCMS.Config.Base.SharedRelPath & application.SLCMS.Config.Base.PresentationRelPath />
		<cfelse>
			<cfset ret.TemplateSource = theSubSiteID />	<!--- where the template set lives, in its subSite as we have not specified otherwise --->
			<cfset ret.TemplateSetName = ListFirst(request.SLCMS.PageParams.Param1, "/") />	<!--- the name of the template set if we need it --->
			<cfset ret.URL.thesubSiteBaseURL =  application.SLCMS.Config.Base.rootURL & application.SLCMS.Config.Base.SitesBaseRelPath & theSubSiteShortName & "/" & application.SLCMS.Config.Base.PresentationRelPath />
		</cfif>
		<cfset ret.URL.thePageTemplatesBaseURL =  ret.URL.thesubSiteBaseURL & application.SLCMS.Config.Base.PageTemplatesRelPath />
		<cfset ret.TemplateName = ListFirst(ListLast(request.SLCMS.PageParams.Param1, "/"), ".") />	<!--- the name of the template if we need it --->
		<cfset ret.Physical.thePageTemplatesBasePath = application.SLCMS.Core.Templates.getTemplatesBasePhysicalPath(TemplateType="Page", SubSiteID="#ret.TemplateSource#") />	<!--- the template manager CFC knows all! --->
		<cfset ret.Physical.thisPageTemplateSetBasePath = ret.Physical.thePageTemplatesBasePath & ret.TemplateSetName & "/" />	<!--- path to the template folder being used --->
		<cfset ret.Physical.thisPageTemplateFullPath = ret.Physical.thisPageTemplateSetBasePath & ret.TemplateName & ".cfm" />	<!--- path to the template file being used --->
		<!---
		<cfset ret.URL.thePageTemplatesBaseURL =  application.SLCMS.Config.Base.rootURL & application.SLCMS.Config.Base.SitesBaseRelPath & theSubSiteShortName & "/" & application.SLCMS.Config.Base.SLCMSPageTemplatesRelPath />
		--->
		<cfset ret.URL.thisPageTemplateSetURLpath = ret.URL.thePageTemplatesBaseURL & ret.TemplateSetName & "/" />
		<cfset ret.URL.thisPageTemplateFullURL = ret.URL.thisPageTemplateSetURLpath & ret.TemplateName & ".cfm" />
		<cfset ret.URL.thisPageTemplateControlURLpath = "#ret.URL.thisPageTemplateSetURLpath#TemplateControl/"  />
		<cfset ret.URL.thisPageTemplateGraphicsURLpath = "#ret.URL.thisPageTemplateSetURLpath#TemplateGraphics/" />
		<cfset ret.URL.thisPageTemplateIncludesURLpath = "#ret.URL.thisPageTemplateSetURLpath#TemplateIncludes/" />
		<cfset ret.URL.thisPageResourcesBaseURL =  ret.URL.thesubSiteBaseURL & application.SLCMS.Config.Base.ResourcesBaseRelPath />

	<cfcatch type="any">
		<cfset ret.error = TakeErrorCatch(RetErrorStruct=ret.error, CatchStruct=cfcatch) />
	</cfcatch>
	</cftry>

<!--- return our data structure --->
<cfreturn ret  />
</cffunction>

<cffunction name="SetBreadcrumbs" output="yes" returntype="struct" access="public"
	displayname="Set Breadcrumbs"
	hint="sets up the breadcrumb trails for this page"
	>

	<cfargument name="PathToThisPage" default="" hint="URL path to this page">	
	<cfargument name="SubSiteID" type="numeric" required="yes" hint="the ID of the subsite to use">

	<!--- set local vars --->
	<cfset var thePathToThisPage = trim(arguments.PathToThisPage) />
	<cfset var theSubSiteID = trim(arguments.SubSiteID) />
	<!--- set local temp vars --->
	<cfset var tempdata = StructNew() />	<!--- everything is in here as this is cloned code from content.cfm directly --->
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<cfset ret.flexi = ArrayNew(1) />	<!--- array from the root to where we are via the flexible path --->
	<cfset ret.Fixed = ArrayNew(1) />	<!--- array from the root to where we are via the fixed nav structure --->
	<cfset ret.PagePathEncoded = "" />

	<cfset tempdata.Breadcrumbs = ArrayNew(1) />	<!--- everything is in here as this is cloned code from content.cfm directly --->
			<!--- work out the breadcrumb from here to the top, 
						we do it twice as it can be strange if we have arrived in Flexi-nav
						or normal formal structure so calculate both every time
						We need the formal one for finding parents on 2nd level only navs and the like --->
			<!--- FLEXI we have a url path in tempData.theParams (here is arguments.PathToThisPage) that defines our path back to the top so lets use that --->
			<cfset tempData.Pathtemp = "" />
			<cfloop from="1" to="#ListLen(thePathToThisPage)#" index="tempData.thisStep">
				<cfset tempData.Pathtemp = tempData.Pathtemp&"/"&ListGetAt(thePathToThisPage, tempData.thisStep, "/") />
				<cfset tempData.thisDocIDStruct = application.SLCMS.Core.PageStructure.getDocIDfromURL(URLpath="#thePathToThisPage#", SubSiteID="#theSubSiteID#") />
				<cfset tempData.thisDocID = tempData.thisDocIDStruct.DocID />
				<!--- 
				<cfset tempData.thisContentTypeID = tempData.thisDocIDStruct.ContentTypeID />
				<cfif tempData.thisDocID neq 0 and tempData.thisContentTypeID eq 1>	<!--- only for valid pages, not wiki ones --->
				 --->
				<cfif tempData.thisDocID neq 0 >	<!--- only for valid pages --->
					<cfset tempData.tempDoc = application.SLCMS.Core.PageStructure.getSingleDocStructure(DocID="#tempData.thisDocID#", SubSiteID="#theSubSiteID#") />
					<cfset ret.flexi[tempData.thisStep] = StructNew() />
					<cfset ret.flexi[tempData.thisStep].DocID = tempData.tempDoc.DocID />
					<cfset ret.flexi[tempData.thisStep].NavName = tempData.tempDoc.NavName />
					<cfset ret.flexi[tempData.thisStep].URLName = tempData.tempDoc.URLName />
					<cfset ret.flexi[tempData.thisStep].URLNameEncoded = tempData.tempDoc.URLNameEncoded />
					<cfset ret.flexi[tempData.thisStep].Hidden = tempData.tempDoc.Hidden />
					<cfset ret.flexi[tempData.thisStep].IsParent = tempData.tempDoc.IsParent />
					<cfset ret.flexi[tempData.thisStep].HasContent = tempData.tempDoc.HasContent />
					<cfset ret.flexi[tempData.thisStep].ParentID = tempData.tempDoc.ParentID />
				</cfif>
			</cfloop>
			<!--- now the FIXED structure, we have to work from the bottom up from the DocID as we can't trust the URL path
						so the array is backwards first off, then we flip it --->
			<cfset request.SLCMS.PageParams.Navigation.tempData.Breadcrumbs = ArrayNew(1) />	<!--- array from the bottom up --->
			<cfset tempData.tempID = request.SLCMS.PageParams.DocID />
			<cfset request.SLCMS.PageParams.PagePathEncoded = "" />	<!--- on the fly we are going to build the path to here as a straight url path as the pagepath param has been decoded --->
			<cfloop from="1" to="10" index="tempData.lcntr">
				<cfset tempData.tempDoc = application.SLCMS.Core.PageStructure.getSingleDocStructure(DocID="#tempData.tempID#", SubSiteID="#theSubSiteID#") />
				<cfset tempData.Breadcrumbs[tempData.lcntr] = StructNew() />
				<cfset tempData.Breadcrumbs[tempData.lcntr].DocID = tempData.tempDoc.DocID />
				<cfset tempData.Breadcrumbs[tempData.lcntr].NavName = tempData.tempDoc.NavName />
				<cfset tempData.Breadcrumbs[tempData.lcntr].URLName = tempData.tempDoc.URLName />
				<cfset tempData.Breadcrumbs[tempData.lcntr].URLNameEncoded = tempData.tempDoc.URLNameEncoded />
				<cfset tempData.Breadcrumbs[tempData.lcntr].Hidden = tempData.tempDoc.Hidden />
				<cfset tempData.Breadcrumbs[tempData.lcntr].IsParent = tempData.tempDoc.IsParent />
				<cfset tempData.Breadcrumbs[tempData.lcntr].HasContent = tempData.tempDoc.HasContent />
				<cfset tempData.Breadcrumbs[tempData.lcntr].ParentID = tempData.tempDoc.ParentID />
				<cfset ret.PagePathEncoded = ListPrepend(ret.PagePathEncoded, tempData.tempDoc.URLNameEncoded, "/") />	<!--- prepend as this is bottom up --->
				<cfset tempData.tempID = tempData.tempDoc.ParentID />
				<cfif tempData.tempDoc.ParentID eq 0><cfbreak></cfif>
			</cfloop>
			<!--- now we copy it across the right way round --->
			<cfset tempData.bcntr = 1 />
			<cfloop from="#ArrayLen(tempData.Breadcrumbs)#" to="1" step="-1" index="tempData.lcntr">
				<cfset ret.Fixed[tempData.bcntr] = tempData.Breadcrumbs[tempData.lcntr] />
				<cfset tempData.bcntr = tempData.bcntr+1 />
			</cfloop>

<!--- return our data structure --->
<cfreturn ret  />
</cffunction>

<cffunction name="TakeErrorCatch" output="Yes" returntype="any" access="private" 
	displayname="Take Error Catch"
	hint="Takes Error Trap in function and logs/displays it, etc"
	>
	<cfargument name="RetErrorStruct" type="struct" required="true" hint="the ret structure from the calling function" />	
	<cfargument name="CatchStruct" type="any" required="true" hint="the catch structure from the calling function" />	
	
	<!--- some temp vars --->
	<cfset var temps = "" />
	<cfset var error = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result it is just the error part of the standard ret struct --->
	<cfset error = StructNew() />
	<cfset error.ErrorCode = 0 />
	<cfset error.ErrorText = "" />
	<cfset error.ErrorContext = "" />
	<cfset error.ErrorExtra = "" />
	<cftry>
		<!--- build the standard return structure using whatever may have been fed in --->
		<cfset ret.error = StructNew() />
		<cfif StructKeyExists(arguments.RetErrorStruct, "ErrorCode")>
			<cfset error.ErrorCode = BitOr(error.ErrorCode, arguments.RetErrorStruct.ErrorCode) />
		</cfif>
		<cfif StructKeyExists(arguments.RetErrorStruct, "ErrorContext")>
			<cfset error.ErrorContext = arguments.RetErrorStruct.ErrorContext />
		</cfif>
		<cfif StructKeyExists(arguments.RetErrorStruct, "ErrorText")>
			<cfset error.ErrorText = arguments.RetErrorStruct.ErrorText />
		</cfif>
		<cfif StructKeyExists(arguments.CatchStruct, "TagContext")>
			<cfset error.ErrorExtra = arguments.CatchStruct.TagContext />
		<cfelse>
			<cfif StructKeyExists(arguments.RetErrorStruct, "ErrorExtra")>
				<cfset error.ErrorExtra = arguments.RetErrorStruct.ErrorExtra />
			</cfif>
		</cfif>
		<cfset error.ErrorText = error.ErrorConText & error.ErrorText & ' Trapped. Site: #application.SLCMS.Config.base.SiteName#, error message was: #arguments.CatchStruct.message#, error detail was: #arguments.CatchStruct.detail#' />
		<cfif isArray(error.ErrorExtra) and StructKeyExists(error.ErrorExtra[1], "Raw_Trace")>
			<cfset error.ErrorText = error.ErrorText & " Line: #ListLast(arguments.CatchStruct.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#" />
		</cfif>
		<cfset temps = LogIt(LogType="CFC_ErrorCatch", LogString='#error.ErrorText# - ErrorCode: #error.ErrorCode#') />
	<cfcatch type="any">
		<cfset error.ErrorCode =  BitOr(error.ErrorCode, 255) />
		<cfset error.ErrorText = error.ErrorContext & ' Trapped. Site: #application.SLCMS.Config.base.SiteName#, error message was: #cfcatch.message#, error detail was: #cfcatch.detail#' />
		<cfset error.ErrorText = error.ErrorText & ' caller error message was: #arguments.CatchStruct.message#, error detail was: #arguments.CatchStruct.detail#' />
		<cfset error.ErrorExtra =  arguments.CatchStruct.TagContext />
		<cfif isArray(error.ErrorExtra) and StructKeyExists(error.ErrorExtra[1], "Raw_Trace")>
			<cfset error.ErrorText = error.ErrorText & ", Line: #ListLast(arguments.CatchStruct.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#" />
		</cfif>
		<cflog text='TakeErrorCatch: Error Catch Caught: #error.ErrorText# - error.ErrorCode: #error.ErrorCode# - Time: #DateFormat(Now(),"YYYYMMDD")#-#TimeFormat(now(),"HH:mm:ss")#'  file="#Application.Logging.theSiteLogName#" type="Error" application = "yes">
		<cfif application.SLCMS.Config.debug.debugmode>
			<cfoutput>#error.ErrorContext#</cfoutput> Trapped - error dump:<br>
			<cfdump var="#arguments.CatchStruct#">
		</cfif>
	</cfcatch>
	</cftry>	
	<cfreturn error  />
</cffunction>

<cffunction name="LogIt" output="No" returntype="struct" access="private"
	displayname="Log It"
	hint="Local Function in every CFC to log info to standard log space via SLCMS_Utility.WriteLog_Core(), minimizes log code in individual functions"
	>
	<cfargument name="LogType" type="string" default="" hint="The log to write to" />
	<cfargument name="LogString" type="string" default="" hint="The string to write to the log" />

	<cfset var theLogType = trim(arguments.LogType) />
	<cfset var theLogString = trim(arguments.LogString) />
	<cfset var temps = StructNew() />	<!--- temp/throwaway structure --->
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorText = "" />
	<cfset ret.error.ErrorContext = "_Empty_Core CFC: LogIt()" />
	<cfset ret.error.ErrorExtra = "" />
	<cfset ret.Data = "" />	<!--- no data --->

	<!--- minimal validation --->
	<cfif theLogType neq "">
		<cftry>
			<cfset temps = application.SLCMS.Core.SLCMS_Utility.WriteLog_Core(LogType="#theLogType#", LogString="#theLogString#") />
			<cfif temps.error.errorcode neq 0>
				<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 2) />
				<cfset ret.error.ErrorText = ret.error.ErrorText & "Log Write Failed. Error was: #temps.error.ErrorText#<br>" />
			</cfif>
		<cfcatch type="any">
			<!--- we cannot use our error catcher as it is using this function, we would have an infinite loop! --->
			<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 128) />
			<cfset ret.error.ErrorText = ret.error.ErrorContext & ' Trapped. Site: #application.SLCMS.Config.base.SiteName#, error message was: #cfcatch.message#, error detail was: #cfcatch.detail#' />
			<cfset ret.error.ErrorExtra =  cfcatch.TagContext />
			<cfif isArray(ret.error.ErrorExtra) and StructKeyExists(ret.error.ErrorExtra[1], "Raw_Trace")>
				<cfset ret.error.ErrorText = ret.error.ErrorText & ", Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#" />
			</cfif>
			<cflog text='#ret.error.ErrorText# - ret.error.ErrorCode: #ret.error.ErrorCode# - Time: #DateFormat(Now(),"YYYYMMDD")#-#TimeFormat(now(),"HH:mm:ss")#'  file="#Application.SLCMS.Logging.theSiteLogName#" type="Error" application = "yes">
			<cfif application.SLCMS.Config.debug.debugmode>
				<cfoutput>#ret.error.ErrorContext#</cfoutput> Trapped - error dump:<br>
				<cfdump var="#cfcatch#">
			</cfif>
		</cfcatch>
		</cftry>
	<cfelse>	<!--- this is the error code --->
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 1) />
		<cfset ret.error.ErrorText = ret.error.ErrorText & "Oops! No Log Type<br>" />
	</cfif>

	<cfreturn ret  />
</cffunction>
