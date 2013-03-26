<cfcomponent extends="Controller" displayname="Content Controller" output="false">
	<!---manage the staff memebrs of the site, admins, editors and authors --->

	<cffunction name="init">
		<!--- use what we have in the common controller for SLCMS --->
		<cfset super.init() />
		<!--- we want a null layout for the content as everything will be coming from the CMS templates, all being well --->
	  <cfset usesLayout(template="/slcms/content/Layout", except="myajax")>
	</cffunction>

	<cffunction name="index">
		<cfset theContent = getContent() />
	</cffunction>

	<cffunction name="create">
		<!--- we get form posts from the WYSIWYG editor so this just processes and uses the same view as normal content --->
		<cfset theContent = getContent() />
		<cfset renderView(action="index") />
	</cffunction>

	<cffunction name="getContent">
		<!--- this is the controller for the main content output of the CMS, the bit that people look at :-) --->
		<cftimer label="content.cfm">
		<cfset var loc = {} />
		<!--- first off we create a struct to dump a lot of temp stuff into that is used on this page rather than by templates or tags --->
		<cfset loc.tempData = StructNew() />

		<!--- first see what Doc we are going to show - this will return a struct of DocID and related data  --->
		<cfset loc.getDocRet = application.SLCMS.Core.ContentCFMfunctions.getDocFromURL() />	<!--- it will return the Doc struct of the home page if no match found for the path or "" if site is empty --->

		<cfif loc.getDocRet.error.errorcode eq 0>
			<cfset loc.tempData = loc.getDocRet.data />
		<cfelse>
			<cfset loc.theErrorStruct = loc.getDocRet.error />
			<cfset loc.TheFunctionCall = "getDocFromURL" />
			<cfinclude template="#application.SLCMS.Paths_Common.rootURL#/views/slcms/content/ErrorPage_ForContentcfm_FunctionCalls.cfm" />
			<cfabort />
		</cfif>
		<!--- now have the doc data so we make the temp stuff for the content with its flags --->
		<cfset loc.tempData.Content = StructNew() />	<!--- this will be the generated content and some flags neatly out of the way --->
		<cfset loc.tempData.Content.ContentToBeHad = False />		<!--- page called that has no content or an error occured --->
		<cfset loc.tempData.Content.ContentHasError = False />	<!--- something went wrong --->
		<cfset loc.tempData.Content.ContentHasErrorMessage = "" />	<!--- what went wrong to display on screen --->
		<cfset loc.tempData.Content.ContentArray = ArrayNew(1) />	<!--- this will have an array of the content in bits as we insert extra stuff in --->
		<cfset loc.tempData.Content.Content = "" />	<!--- guess what? :-) --->

		<cfif loc.tempData.DocID neq "">
			<!--- we have a docID set up the data structures to display the page, 
						request.SLCMS.PageParams is the struct the template tags can see and use directly so we dump heaps in there --->
			<cfset request.SLCMS.PageParams = StructNew()>	<!--- make sure we start with nothing --->
			<!--- this gets all of the stuff belonging to the document itself --->
			<cfset request.SLCMS.PageParams = duplicate(application.SLCMS.Core.PageStructure.getSingleDocStructure(DocID="#loc.tempData.DocID#", SubSiteID="#loc.tempData.SubSiteID#")) />
			<!--- set up the base structures --->
			<cfset request.SLCMS.PageParams.HeadContent = StructNew() />
			<cfset request.SLCMS.PageParams.Navigation = StructNew()>	<!--- the place all the navigation related stuff goes, breadcrumbs and nav styling commands --->
			<cfset request.SLCMS.PageParams.PageToggles = StructNew() />	<!--- this is for things that get togggled or whatever during a page display but don't need saving persistently --->
			<cfset request.SLCMS.PageParams.Paths = StructNew() />	<!--- for all the paths --->
			<cfset request.SLCMS.PageParams.Module = StructNew() />	<!--- everything relevant to any possible module --->
			<!--- and fill them up --->
			<cfset request.SLCMS.PageParams.Navigation.Styling = StructNew() />
			<cfset request.SLCMS.PageParams.Navigation.Breadcrumbs = StructNew() />
			<cfset request.SLCMS.PageParams.PageToggles.flagNavExpansionDone = False />	<!--- we only flip the Expansion flag once per page --->
			<cfset loc.setInitialHeadContentRet = application.SLCMS.Core.ContentCFMfunctions.SetInitialHeadContent() />	<!--- load in the stuff for the html head section --->
			<cfif loc.setInitialHeadContentRet.error.errorcode eq 0>
				<cfset request.SLCMS.PageParams.HeadContent = loc.setInitialHeadContentRet.data />
			<cfelse>
				<cfset loc.theErrorStruct = loc.setInitialHeadContentRet.error />
				<cfset loc.TheFunctionCall = "SetInitialHeadContent" />
				<cfinclude template="#application.SLCMS.Paths_Common.rootURL#/views/slcms/content/ErrorPage_ForContentcfm_FunctionCalls.cfm" />
				<cfabort />
			</cfif>
			<!--- add in some of the calculated loc.tempData from above --->
			<cfset request.SLCMS.PageParams.Module.URLParams = loc.tempData.ModuleParams />	<!--- params beyond the base page URL params --->
			<cfset request.SLCMS.PageParams.Module.DocPath = loc.tempData.DocPath />	<!--- the base page URL params --->
			<cfset request.SLCMS.PageParams.SubSiteID = loc.tempData.SubSiteID />
			<cfset request.SLCMS.PageParams.SubSiteShortName = loc.tempData.SubSiteShortName />
			<cfset request.SLCMS.PageParams.SubSiteNavName = loc.tempData.SubSiteNavName />
			<cfset request.SLCMS.PageParams.wikibits = StructNew() />
			<cfset request.SLCMS.PageParams.wikibits = duplicate(loc.tempData.wikibits) />
			<cfset request.SLCMS.PageParams.wikibits.ContentTypeID = loc.tempData.ContentTypeID />	<!--- the ContentTypeID shows if a wiki or not --->
			<!--- see if there is a page there at all, ie we don't have an empty database on startup --->
			<cfif structKeyExists(request.SLCMS.PageParams, "HasContent")>
				<cfset loc.tempData.Content.ContentToBeHad = True />
				<!--- we have stuff there, the site is not empty so grab more bits --->
					<!--- first calculate all the paths, physical and url --->
				<cfset loc.tempData.PathsGet = application.SLCMS.Core.ContentCFMfunctions.getSubSitePaths(PageParam1="#request.SLCMS.PageParams.Param1#", subSiteID="#request.SLCMS.PageParams.SubSiteID#", SubSiteShortName="#request.SLCMS.PageParams.SubSiteShortName#") />
				<!--- and make sure we have a template that matches the page params (happens when people rename stuff and don't do their houskeeping, guess who did that? :-)) --->
		  	<cfset loc.tempData.MainTemplateList = application.SLCMS.core.templates.getTemplateList(TemplateType="page", SubSiteID="#request.SLCMS.pageparams.SubSiteID#") />
		  	<cfset loc.tempData.SharedTemplateList = application.SLCMS.core.templates.getTemplateList(TemplateType="page", SubSiteID="Shared") />
				<cfif ListFindNoCase(loc.tempData.MainTemplateList, '#loc.tempData.PathsGet.TemplateSetName#/#loc.tempData.PathsGet.TemplateName#') or ListFindNoCase(loc.tempData.SharedTemplateList, '#loc.tempData.PathsGet.TemplateSetName#/#loc.tempData.PathsGet.TemplateName#')>
					<cfset request.SLCMS.PageParams.Paths.Physical = loc.tempData.PathsGet.Physical />	<!--- all the physical paths --->
					<cfset request.SLCMS.PageParams.Paths.URL = loc.tempData.PathsGet.URL />	<!--- all the url paths --->
					<cfset request.SLCMS.PageParams.TemplateSetName = loc.tempData.PathsGet.TemplateSetName />	<!--- the name of the template set if we need it --->
					<cfset request.SLCMS.PageParams.TemplateName = loc.tempData.PathsGet.TemplateName />	<!--- the name of the template if we need it --->
					<!--- see if we have a page with content, if not then grab this page's default page. --->
					<cfif request.SLCMS.PageParams.HasContent eq False and request.SLCMS.PageParams.DocID neq request.SLCMS.PageParams.DefaultDocID>
						<cfset request.SLCMS.PageParams = duplicate(application.SLCMS.Core.PageStructure.getSingleDocStructure(DocID="#request.SLCMS.PageParams.DefaultDocID#", SubSiteID="# request.SLCMS.PageParams.SubSiteID#")) />
					</cfif>
				<cfelse>
					<!--- oops! no point continuing there is no template to display --->
					<cfset loc.tempData.Content.ContentToBeHad = False />
					<cfset loc.tempData.Content.ContentHasError = True />	<!--- something went wrong --->
					<cfset loc.tempData.Content.ContentHasErrorMessage = loc.tempData.Content.ContentHasErrorMessage & "A page Template was requested that does not exist!" />	<!--- what went wrong to display on screen --->
				</cfif>
			<cfelse>
				<!--- nothing there so flick to the admin area --->
				<cfset loc.tempData.Content.ContentToBeHad = False />
			</cfif>
			<!--- throw in the path we have decoded --->
			<cfset request.SLCMS.PageParams.PagePath = loc.tempData.theParams />
			<cfset request.SLCMS.PageParams.PageQueryString = loc.tempData.theQueryString />
			<!--- all is set up so record a stats hit for this page and the site overall if we have stats turned on --->
			<cfif application.SLCMS.config.Components.Use_Stats eq "yes">
				<cfset loc.temp = application.SLCMS.mbc_Utility.Stats.AddHit(SiteName="Site_Hit")>
				<cfset loc.temp = application.SLCMS.mbc_Utility.Stats.AddHit(SiteName="Page_Hit_ID_#loc.tempData.DocID#")>
			</cfif>
			<!--- do the needed work to get nav --->
			<cfif loc.tempData.Content.ContentToBeHad>
				<!--- this bit of code makes sure we have current navigation structs for the navigation system to work from --->
				<cfset session.SLCMS.PortalControl.SubSiteIDList_Active = application.SLCMS.core.portalControl.GetAllowedSubSiteIDList_ActiveSites() />	<!--- quick update in case a new one has popped up --->
					<cfif not ListFind(session.SLCMS.PortalControl.SubSiteIDList_Active, loc.tempData.SubSiteID)>
						<!--- oops we have gone to a bookmarked page or something that is not turned on at the moment --->
						<cfset request.SLCMS.PageParams.hidden = 2 />	<!--- flag not allowed to view --->
					<cfelse>
					<!--- make sure we have a nav structures for this subSite --->
					<cfif not StructkeyExists(session, "SLCMS")>
						<cfset session["SLCMS"] = StructNew()>
					</cfif>
					<cfif not StructkeyExists(session.SLCMS, "FrontEnd")>
						<cfset session.SLCMS["FrontEnd"] = StructNew()>
					</cfif>
					<cfif not StructkeyExists(session.SLCMS.FrontEnd, "SubSite_#loc.tempData.SubSiteID#")>
						<cfset session.SLCMS.FrontEnd["SubSite_#loc.tempData.SubSiteID#"] = StructNew()>
					</cfif>
					<cfif not StructkeyExists(session.SLCMS.FrontEnd["SubSite_#loc.tempData.SubSiteID#"], "NavState")>
						<cfset session.SLCMS.FrontEnd["SubSite_#loc.tempData.SubSiteID#"].NavState = StructNew() />
						<cfset session.SLCMS.FrontEnd["SubSite_#loc.tempData.SubSiteID#"].NavState.theCurrentNavArray = Duplicate(application.SLCMS.Core.PageStructure.getFullNavArray(SubSiteID="#loc.tempData.SubSiteID#")) />
						<!--- initialise the nav tree expansion flag structure with all minimised --->
						<cfset session.SLCMS.FrontEnd["SubSite_#loc.tempData.SubSiteID#"].DocIdList = application.SLCMS.Core.PageStructure.getDocIdList(loc.tempData.SubSiteID) />
						<cfset session.SLCMS.FrontEnd["SubSite_#loc.tempData.SubSiteID#"].NavState.ExpansionFlags = StructNew() />
						<cfloop list="#session.SLCMS.FrontEnd['SubSite_#loc.tempData.SubSiteID#'].DocIdList#" index="loc.thisDocID">
							<cfset session.SLCMS.FrontEnd["SubSite_#loc.tempData.SubSiteID#"].NavState.ExpansionFlags[loc.thisDocID] = False />
						</cfloop>
						<cfset session.SLCMS.FrontEnd["SubSite_#loc.tempData.SubSiteID#"].NavSerial = Now() />	<!--- gets used to check if the site structure has changed --->
						<cfset session.SLCMS.FrontEnd["SubSite_#loc.tempData.SubSiteID#"].SubSiteID = loc.tempData.SubSiteID />	<!--- the current subSite --->
					</cfif>
					<!--- we have a front end session for navigation, etc., so see if the structure has changed since last time --->
					<cfif DateDiff("s", session.SLCMS.FrontEnd["SubSite_#loc.tempData.SubSiteID#"].NavSerial, application.SLCMS.Core.PageStructure.getSerial("#loc.tempData.SubSiteID#")) neq 0>
						<!--- its not the same so reload the structure --->
						<cfset session.SLCMS.FrontEnd["SubSite_#loc.tempData.SubSiteID#"].NavState.theCurrentNavArray = Duplicate(application.SLCMS.Core.PageStructure.getFullNavArray(loc.tempData.SubSiteID)) />
						<cfset session.SLCMS.FrontEnd["SubSite_#loc.tempData.SubSiteID#"].DocIdList = application.SLCMS.Core.PageStructure.getDocIdList(loc.tempData.SubSiteID) />
						<!--- and put any new documents as closed into the expansion structure --->
						<cfloop list="#session.SLCMS.FrontEnd["SubSite_#loc.tempData.SubSiteID#"].DocIdList#" index="loc.thisDocID">
							<cfif (not StructKeyExists(session.SLCMS.FrontEnd["SubSite_#loc.tempData.SubSiteID#"].NavState.ExpansionFlags, loc.thisDocID)) or session.SLCMS.FrontEnd["SubSite_#loc.tempData.SubSiteID#"].SubSiteID neq loc.tempData.SubSiteID>
								<cfset session.SLCMS.FrontEnd["SubSite_#loc.tempData.SubSiteID#"].NavState.ExpansionFlags[loc.thisDocID] = False />
							</cfif>
						</cfloop>
						<!--- straighten our  flags --->
						<cfset session.SLCMS.FrontEnd["SubSite_#loc.tempData.SubSiteID#"].NavSerial = application.SLCMS.Core.PageStructure.getSerial("#loc.tempData.SubSiteID#") />
						<cfset session.SLCMS.FrontEnd["SubSite_#loc.tempData.SubSiteID#"].SubSiteID = loc.tempData.SubSiteID />	
					</cfif>
				</cfif>
			</cfif>
			<!--- now we do a tad of admin session handling as now in V3 we can pop the admin pages over the top of our content --->
			<cfif session.slcms.user.IsLoggedIn>
					<!--- load in jQuery --->
				<cfset loc.Ret = application.SLCMS.Core.ContentCFMfunctions.AddHeadContent(Place="Top", Path="#application.SLCMS.Paths_Common.jQueryJsPath_Abs#") />
				<!--- and the js and styling for the slide-down admin panel --->
				<cfset loc.Ret = application.SLCMS.Core.ContentCFMfunctions.AddHeadContent(Place="Top", Type="stylesheet", Path="#application.SLCMS.Paths_Admin.AdminPopWrapperStyleSheet_Abs#") />
				<cfset loc.Ret = application.SLCMS.Core.ContentCFMfunctions.AddHeadContent(Place="Top", Path="#application.SLCMS.Paths_Admin.AdminPopWrapperjs_Abs#") />
				<cfsavecontent variable="loc.tempData.Content.AdminPopper">
					<cfinclude template="#application.SLCMS.Paths_Common.rootURL#/views/slcms/content/_AdminPopWrapper_inc.cfm" />
				</cfsavecontent>
			</cfif>

			<!--- display the page if it flagged as viewable --->
			<cfif StructKeyExists(request.SLCMS.PageParams, "hidden") and BitAnd(request.SLCMS.PageParams.hidden,2) neq 2>
				<!--- if it is SLCMS template then process it and its output --->
				<cfif request.SLCMS.PageParams.DocType eq 2 and loc.tempData.Content.ContentToBeHad>
					<cfset request.SLCMS.PageParams.PageTitle = request.SLCMS.PageParams.NavName />
						<!--- load in the relevant nav stuff for this template, can be from a shared one or in the subsite --->
					<cfif ListLen(request.SLCMS.PageParams.param1, "/") eq 3>
						<cfset request.SLCMS.PageParams.Navigation.Styling = application.SLCMS.Core.Templates.getNavigationStyling_All(TemplateSet="#request.SLCMS.PageParams.TemplateSetName#", SubsiteID="Shared") />
					<cfelse>
						<cfset request.SLCMS.PageParams.Navigation.Styling = application.SLCMS.Core.Templates.getNavigationStyling_All(TemplateSet="#request.SLCMS.PageParams.TemplateSetName#", SubsiteID="#request.SLCMS.PageParams.SubSiteID#") />	<!--- load in the relevant nav stuff for this template --->
					</cfif>
					<cfset request.SLCMS.PageParams.Navigation.Breadcrumbs = application.SLCMS.Core.ContentCFMfunctions.SetBreadcrumbs(PathToThisPage="#loc.tempData.theParams#", SubsiteID="#request.SLCMS.PageParams.SubSiteID#") />	<!--- load in the relevant nav stuff for this template --->
					<cfset request.SLCMS.PageParams.PagePathEncoded = request.SLCMS.PageParams.Navigation.Breadcrumbs.PagePathEncoded />
					<!--- now the breadcrumbs are done process any menu/nav expansion we might need --->
					<!--- expand where we are if needs be, but only if this navigation menu shows the current document --->
					<cfif not request.SLCMS.PageParams.PageToggles.flagNavExpansionDone>
						<cfset request.SLCMS.PageParams.PageToggles.flagNavExpansionDone = True />	<!--- only  --->
						<!--- ToDo: switch with nav style thingo, for the moment it is just a toggle --->
						<cfif structKeyExists(session.SLCMS.FrontEnd["SubSite_#loc.tempData.SubSiteID#"].NavState.ExpansionFlags, "#request.SLCMS.PageParams.DocID#")>
							<cfif session.SLCMS.FrontEnd["SubSite_#loc.tempData.SubSiteID#"].NavState.ExpansionFlags[request.SLCMS.PageParams.DocID] eq True>
								<cfset session.SLCMS.FrontEnd["SubSite_#loc.tempData.SubSiteID#"].NavState.ExpansionFlags[request.SLCMS.PageParams.DocID] = False />
							<cfelse>
								<cfset session.SLCMS.FrontEnd["SubSite_#loc.tempData.SubSiteID#"].NavState.ExpansionFlags[request.SLCMS.PageParams.DocID] = True />
							</cfif>
						<cfelse>
							<cfset session.SLCMS.FrontEnd["SubSite_#loc.tempData.SubSiteID#"].NavState.ExpansionFlags[request.SLCMS.PageParams.DocID] = True />
						</cfif>
						<!--- and expand the parent if it does --->
						<cfset session.SLCMS.FrontEnd["SubSite_#loc.tempData.SubSiteID#"].NavState.ExpansionFlags[request.SLCMS.PageParams.ParentID] = True />
					</cfif>
					<!--- now worry about paths and things --->
					<cfset request.SLCMS.PageParams.PagePathEncoded = "/" & request.SLCMS.PageParams.PagePathEncoded />	<!--- tidy up from list prepend --->
					<!--- if it is a module some of the paths above gets broken due to the lack of a full path so we will straighten them here  --->
					<cfif request.SLCMS.PageParams.Module.URLParams neq "">
						<cfset request.SLCMS.PageParams.PagePathEncoded = "#request.SLCMS.PageParams.PagePathEncoded#/#application.SLCMS.Core.PageStructure.EncodeNavName(NavName=request.SLCMS.PageParams.Module.URLParams, SkipSlashes=True)#" />
					</cfif>
					<!--- used to find the home page of a subSite --->
					<cfset request.SLCMS.PageParams.SubSiteURLNameEncoded = ListFirst(request.SLCMS.PageParams.PagePathEncoded, "/") />
		
					<!--- set the default editor stylesheet if the page is not dedicated to a single output type --->
					<cfif request.SLCMS.PageParams.Param3 eq "shop" or request.SLCMS.PageParams.Param3 eq "form">
						<cfset request.SLCMS.PageParams.EditorStyleSheet = "" />
					<cfelse>
						<cfset request.SLCMS.PageParams.EditorStyleSheet = request.SLCMS.PageParams.Param3 />
					</cfif>
					<!--- now we have set everything up we can show the page, first any stuff that has to be in the HTML head tag, then the template.
								cfhtmlhead puts its content at the end of the head tag after existing html so would be after any style sheets in the page templates and possibly overwrite them, 
								We want it the other way round for the default SLCMS stylesheets so they can be overwritten (at the designers' risk of course :-))
								so we grab the generated content and insert the styling, js, etc., we want into that immediately after the head tag
								so the user's template can overwrite as needed, then output it 
								 --->
					<!--- firstly get the entire page --->
					<cfsavecontent variable="loc.tempData.Content.PageContent_Generated">
						<cfinclude template="#request.SLCMS.PageParams.Paths.URL.thisPageTemplateFullURL#">
					</cfsavecontent>
					<cftimer label="content.cfm head array">
					<!--- then find the <head> tag and shove our stuff in straight after for the bits we want at the beginning of the head --->
					<cfset loc.tempData.Content.HeadOpeningTagEndPos = FindNoCase("<head>", loc.tempData.Content.PageContent_Generated)+5 />
					<cfif loc.tempData.Content.HeadOpeningTagEndPos gt 0>
						<!--- we do have a <head> tag so load in what is before it --->
						<cfset loc.tempData.Content.ContentArray[1] = trim(left(loc.tempData.Content.PageContent_Generated, loc.tempData.Content.HeadOpeningTagEndPos)) />
						<!--- then all of the bits we have flagged as needing to be at the top of the <head> area --->
						<cfloop from="1" to="#ArrayLen(request.SLCMS.PageParams.HeadContent.Start.Strings)#" index="loc.tempData.lcntr"> <!--- by default there will be a stylesheet for the editing sections and one for forms - login, etc --->
							<cfset ArrayAppend(loc.tempData.Content.ContentArray, request.SLCMS.PageParams.HeadContent.Start.Strings[loc.tempData.lcntr] & chr(13) & chr(10)) />
						</cfloop>
						<!---  now we have the original content up to the <head> and all of the bits we want straight after it so lets now add in the original <head> html --->
						<cfset loc.tempData.Content.HeadEndingTagStartPos = FindNoCase("</head>", loc.tempData.Content.PageContent_Generated)-1 />
						<cfif loc.tempData.Content.HeadEndingTagStartPos gt 0>
							<cfset ArrayAppend(loc.tempData.Content.ContentArray, mid(loc.tempData.Content.PageContent_Generated, loc.tempData.Content.HeadOpeningTagEndPos+1, loc.tempData.Content.HeadEndingTagStartPos-loc.tempData.Content.HeadOpeningTagEndPos)) />
							<!--- done so now we can repeat above and insert the extras we want at the bottom of the head tag --->
							<cfloop from="1" to="#ArrayLen(request.SLCMS.PageParams.HeadContent.End.Strings)#" index="loc.tempData.lcntr"> <!--- by default there will be a stylesheet for the editing sections and one for forms - login, etc --->
								<cfset ArrayAppend(loc.tempData.Content.ContentArray, request.SLCMS.PageParams.HeadContent.End.Strings[loc.tempData.lcntr] & chr(13) & chr(10)) />
							</cfloop>
							<!---  great! now we have everything up to the end of the head section, including the extras we flagged, so now add in the remains of the content from the </head> tag onwards --->
							<!--- firstly wind back to unused-so-far-content --->
							<cfset loc.tempData.Content.PageContent_Generated = RemoveChars(loc.tempData.Content.PageContent_Generated, 1, loc.tempData.Content.HeadEndingTagStartPos) />
						</cfif>
					</cfif>
					<cfif session.slcms.user.IsLoggedIn>
						<!--- if we are staff we need to add the div to show the slide-down admin area --->
						<cfset loc.tempData.Content.BodyOpeningTagEndPos = FindNoCase("<body", loc.tempData.Content.PageContent_Generated)+5 />
						<cfset loc.tempData.Content.BodyOpeningTagEndPos = FindNoCase(">", loc.tempData.Content.PageContent_Generated, loc.tempData.Content.BodyOpeningTagEndPos)+1 />	<!--- end of body tag which can have attributes --->
						<!--- push in the code between start of head closing tag and end of opening body --->
						<cfset ArrayAppend(loc.tempData.Content.ContentArray, left(loc.tempData.Content.PageContent_Generated, loc.tempData.Content.BodyOpeningTagEndPos)) />
						<!--- then add the div that will slide down for the admin pages --->
						<cfset ArrayAppend(loc.tempData.Content.ContentArray, loc.tempData.Content.AdminPopper) />
						<!--- and trim back our remaining content again and add it in after the new admin div --->
						<cfset loc.tempData.Content.PageContent_Generated = RemoveChars(loc.tempData.Content.PageContent_Generated, 1, loc.tempData.Content.BodyOpeningTagEndPos) />
						<!--- ToDo: add the same for body end for tail stuff --->
						<cfset ArrayAppend(loc.tempData.Content.ContentArray, loc.tempData.Content.PageContent_Generated) />
					<cfelse>
						<!--- not logged in so just push the rest of the content out --->
						<cfset ArrayAppend(loc.tempData.Content.ContentArray, loc.tempData.Content.PageContent_Generated) />
					</cfif>
					</cftimer>
					<cfset loc.tempData.Content.Content = ArrayToList(loc.tempData.Content.ContentArray, "") />
				<cfelseif request.SLCMS.PageParams.DocType eq 2>
					<!--- this is if it meant to be a SLCMS template but we had no content to get, the site is empty or an error happened --->
					<cfset ArrayAppend(loc.tempData.Content.ContentArray, '<html><head></head> <body>') />
					<cfif loc.tempData.Content.ContentHasError>
						<cfset ArrayAppend(loc.tempData.Content.ContentArray, '<p>#loc.tempData.Content.ContentHasErrorMessage#.</p><p><a href="#application.SLCMS.Paths_Common.ContentRootURL#">Go to the Home Page</a></p><p><a href="#application.SLCMS.Paths_Admin.AdminBaseURL#Admin-Home">Go to the Administration Area</a></p>') />
					<cfelse>
						<cfset ArrayAppend(loc.tempData.Content.ContentArray, '<p>There is nothing in the site yet. Go to Admin area first and create a Home Page.</p><p><a href="#application.SLCMS.Paths_Admin.AdminBaseURL#Admin-Home">Go to the Administration Area</a></p>') />
					</cfif>
					<cfset ArrayAppend(loc.tempData.Content.ContentArray, '</body></html>' )/>
					<cfset loc.tempData.Content.Content = ArrayToList(loc.tempData.Content.ContentArray, "") />
				<cfelseif request.SLCMS.PageParams.DocType eq 1>
					<!--- ToDo put doc handler here for include files --->
					<cfsavecontent variable="loc.tempData.Content.Content">
						<cfinclude template="#request.SLCMS.PageParams.Param1#">
					</cfsavecontent>
					<!--- 
					<cffile action="READ" file="#request.SLCMS.PageParams.Param1#" variable="Content">
					 --->
				</cfif>	<!--- end: doctype handling --->
			</cfif>	<!--- end: page not hidden --->
		</cfif>	<!--- end: DocID decoded --->
		<!--- and display it all --->	
		<cfreturn loc.tempData.Content.Content />
	</cftimer>	
  </cffunction>
	
</cfcomponent>