
<!---
    <cfdump var="#request#" expand="false" label="request">    
    <cfdump var="#application#" expand="false" label="application">    
	<cfdump var="#application.wheels#" expand="false" label="application.wheels" />
--->
<!---	
    <cfdump var="#session#" expand="false" label="session">    
    
    <cfabort>    
--->    
<!---<cftry>---><!---<cfsilent>--->
<!--- have an error handler above for the entire thing in case someone tries something stoopid --->

<!--- SLCMS --->
<!---  --->
<!--- A Simple Light CMS system by Mort Bay Communications Pty Ltd --->
<!--- Copyright 2002-2012 --->
<!---  --->
<!--- Show Page --->
<!--- this page is not known by this name, it is called content.cfm. 
			It is the base display page that shows content in the site --->
<!---  --->
<!--- Cloned    1st Sep 2007 by Kym Kovan from the orignal showpage.cfm which was for a fixed files structure --->
<!--- Modified: 22nd Oct 2007 - 27th Oct 2007 by Kym K, mbcomms: original code changes --->
<!--- Modified: 22nd Nov 2007 -  3rd Dec 2007 by Kym K, mbcomms: adding navigation bit and pieces like breadcrumb calculator --->
<!--- modified: 27th Dec 2007 - 28th Dec 2007 by Kym K, mbcomms: changed to different structures of control info with one file per nav --->
<!--- modified: 19th Feb 2008 - 19th Feb 2008 by Kym K, mbcomms: added cfhtmlhead tag to auto include SLCMS styles, etc --->
<!--- modified: 16th May 2008 - 16th May 2008 by Kym K, mbcomms: added cfif around Stats AddHit() functions so is now controlled by useStats in config ini file --->
<!--- modified: 27th Jun 2008 - 27th Jun 2008 by Kym K, mbcomms: added errorhandling for bad urls and related after architure changed for homepage flag --->
<!---  --->
<!--- modified: 14th Sep 2008 - 14th Sep 2008 by Kym K, mbcomms: V2.1 , new architecture separating presentation from SLCMS code --->
<!--- modified: 14th Sep 2008 - 14th Sep 2008 by Kym K, mbcomms: added array of strings for stylesheets, etc to go at head to allow forms, etc to insert styling before or after all else. cfhtmlhead tag is now gone --->
<!--- modified: 20th Nov 2008 - 20th Nov 2008 by Kym K, mbcomms: updating TinyMCE code, added styling variables --->
<!--- modified:  1st Feb 2009 -  3rd Feb 2009 by Kym K, mbcomms: moved menu/nav expansion flags to content.cfm from include-NavigationParams so it only runs once per page --->
<!--- modified: 15th Feb 2009 - 17th Feb 2009 by Kym K, mbcomms: integrating wiki into SLCMS --->
<!--- modified: 23rd Mar 2009 - 25th Mar 2009 by Kym K, mbcomms: V2.2, changing structures to new module-allowing architecture, the core code is now just another module --->
<!--- modified: 17th Apr 2009 - 26th Apr 2009 by Kym K, mbcomms: V2.2, changing folder structure to portal/sub-site architecture, sites inside the top site
																																				this includes moving a lot of code from application.SLCMS.cfm to here cfm as it becomes context sensitive
																																				this is all the request scope generated stuff that is made on the fly each hit
																																				to make this easier we are also breaking this page's code up into includes/custom-tags/functions --->
<!--- modified: 30th Aug 2009 - 30th Aug 2009 by Kym K, mbcomms: adding code for session based nav dependent on subsite, ie portal based. Code moved from OnRequestStart --->
<!--- modified: 21st Sep 2009 - 24th Sep 2009 by Kym K, mbcomms: tidying code for first start detection when the database is empty --->
<!--- modified: 22nd Oct 2009 - 25th Oct 2009 by Kym K, mbcomms: adding code for bad or renamed templates and refining portal code --->
<!--- modified:  3rd Nov 2009 -  7th Nov 2009 by Kym K, mbcomms: reworking portal-related code to stop using session scope to allow for mutiple tabs open at once
																																				put subSiteID in request scope, 
																																				dropped a bunch of session flags or added subSiteID to structs --->
<!--- modified:  5th Jun 2010 -  5th Jun 2010 by Kym K, mbcomms: bug fixes from above changes, still finding them!!! --->
<!--- modified: 20th Feb 2011 - 26th Feb 2011 by Kym K, mbcomms: major change to handle SEO paths that are longer than the doc for modules like shops, etc --->
<!--- modified: 10th Jun 2011 - 11th Jun 2011 by Kym K, mbcomms: improving path decoding for subSites when we have modules in the mix --->
<!--- modified: 13th Dec 2011 - 13th Dec 2011 by Kym K, mbcomms: tickling the head section filleruperrer to use faster code (arrayappend) as now we have lots more stuff like jquery and plugins and their ready code --->
<!--- modified:  2nd Jan 2012 -  4th Jan 2012 by Kym K, mbcomms: V2.2+, changed the way templates are handled, changed template related calls here to match --->

	<!--- 	
	<cfdump var="#server#" expand="false" label="server scope" >
	<cfdump var="#application#" expand="false" label="application scope" >
	<cfabort>
	 --->

	<cfoutput>#application.wheels.dispatch.$request(pathInfo="/slcms/content", scriptName="index.cfm")#</cfoutput>
	 
<!--- 
<cfif application.SLCMS.flags.RunInstallWizard>
	<cflocation url="#application.SLCMS.Paths_Admin.AdminBaseURL#install-wizard" addtoken="false" />
</cfif>
	<!--- 	
	<cfdump var="#request#" expand="false" label="request scope" >
	<cfdump var="#application#" expand="false" label="application scope" >
	 --->


<cfset $include(template="wheels/plugins/injection.cfm") />
<cfdump var="#application.wheels.plugins.Nexts.Nexts_getPersistentData()#" expand=false label="Nexts_getGlobal">
<!--- 
<cfinclude template="/wheels/plugins/injection.cfm">
<cfdump var="#application.wheels.plugins.Nexts.Nexts_getPersistentData()#" expand=false label="Nexts_getGlobal">
 --->


<cftimer label="content.cfm">
<!--- first off we creat a struct to dump a lot of temp stuff into that is used on this page rather than by templates or tags --->
<cfset tempData = StructNew() />

<!--- first see what Doc we are going to show - this will return a struct of DocID and related data like wiki structs --->
<cfset getDocRet = application.SLCMS.Core.ContentCFMfunctions.getDocFromURL() />	<!--- it will return the Doc struct of the home page if no match found for the path or "" if site is empty --->

<cfif getDocRet.error.errorcode eq 0>
	<cfset tempData = getDocRet.data />
<cfelse>
	<cfset TheErrorStruct = getDocRet.error />
	<cfset TheFunctionCall = "getDocFromURL" />
	<cfinclude template="/ErrorPage_ForContentcfm_FunctionCalls.cfm" />
	<cfabort />
</cfif>

<!--- more temp stuff with flags --->
<cfset tempData.Content = StructNew() />	<!--- this will be the generated content and some flags neatly out of the way --->
<cfset tempData.Content.ContentToBeHad = False />		<!--- page called that has no content or an error occured --->
<cfset tempData.Content.ContentHasError = False />	<!--- something went wrong --->
<cfset tempData.Content.ContentHasErrorMessage = "" />	<!--- what went wrong to display on screen --->
<cfset tempData.Content.ContentArray = ArrayNew(1) />	<!--- this will have the content in bits as we insert extra stuff in --->
<cfset tempData.Content.Content = "" />	<!--- guess what this will be? --->

<!---</cfsilent>---><!--- 
 ---><cfif tempData.DocID neq ""><!---<cfsilent>--->
	<!--- we do so lets do it --->
	<!--- now we have a docID set up the data structures to display the page, request.SLCMS.PageParams is the struct the template tags can see and use directly --->
	<cfset request.SLCMS.PageParams = StructNew()>	<!--- make sure we start with nothing --->
	<!--- this gets all of the stuff belonging to the document itself --->
	<cfset request.SLCMS.PageParams = duplicate(application.SLCMS.Core.PageStructure.getSingleDocStructure(DocID="#tempData.DocID#", SubSiteID="#tempdata.SubSiteID#")) />
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
	<cfset SetInitialHeadContentRet = application.SLCMS.Core.ContentCFMfunctions.SetInitialHeadContent() />	<!--- load in the stuff for the html head section --->
	<cfif SetInitialHeadContentRet.error.errorcode eq 0>
		<cfset request.SLCMS.PageParams.HeadContent = SetInitialHeadContentRet.data />
	<cfelse>
		<cfset TheErrorStruct = SetInitialHeadContentRet.error />
		<cfset TheFunctionCall = "SetInitialHeadContent" />
		<cfinclude template="/ErrorPage_ForContentcfm_FunctionCalls.cfm" />
		<cfabort />
	</cfif>
	<!--- add in some of the calculated tempdata from above --->
	<cfset request.SLCMS.PageParams.Module.URLParams = tempdata.ModuleParams />	<!--- params beyond the base page URL params --->
	<cfset request.SLCMS.PageParams.Module.DocPath = tempdata.DocPath />	<!--- the base page URL params --->
	<cfset request.SLCMS.PageParams.SubSiteID = tempdata.SubSiteID />
	<cfset request.SLCMS.PageParams.SubSiteShortName = tempdata.SubSiteShortName />
	<cfset request.SLCMS.PageParams.SubSiteNavName = tempdata.SubSiteNavName />
	<cfset request.SLCMS.PageParams.wikibits = StructNew() />
	<cfset request.SLCMS.PageParams.wikibits = duplicate(tempdata.wikibits) />
	<cfset request.SLCMS.PageParams.wikibits.ContentTypeID = tempData.ContentTypeID />	<!--- the ContentTypeID shows if a wiki or not --->
	<!--- see if there is a page there at all, ie we don't have an empty database on startup --->
	<cfif structKeyExists(request.SLCMS.PageParams, "HasContent")>
		<cfset tempData.Content.ContentToBeHad = True />
		<!--- we have stuff there, the site is not empty so grab more bits --->
			<!--- first calculate all the paths, physical and url --->
		<cfset tempdata.PathsGet = application.SLCMS.Core.ContentCFMfunctions.getSubSitePaths(PageParam1="#request.SLCMS.PageParams.Param1#", subSiteID="#request.SLCMS.PageParams.SubSiteID#", SubSiteShortName="#request.SLCMS.PageParams.SubSiteShortName#") />
		<!--- and make sure we have a template that matches the page params (happens when people rename stuff and don't do their houskeeping, guess who did that? :-)) --->
  	<cfset tempdata.MainTemplateList = application.SLCMS.core.templates.getTemplateList(TemplateType="page", SubSiteID="#request.SLCMS.pageparams.SubSiteID#") />
  	<cfset tempdata.SharedTemplateList = application.SLCMS.core.templates.getTemplateList(TemplateType="page", SubSiteID="Shared") />
		<cfif ListFindNoCase(tempdata.MainTemplateList, '#tempdata.PathsGet.TemplateSetName#/#tempdata.PathsGet.TemplateName#') or ListFindNoCase(tempdata.SharedTemplateList, '#tempdata.PathsGet.TemplateSetName#/#tempdata.PathsGet.TemplateName#')>
			<cfset request.SLCMS.PageParams.Paths.Physical = tempdata.PathsGet.Physical />	<!--- all the physical paths --->
			<cfset request.SLCMS.PageParams.Paths.URL = tempdata.PathsGet.URL />	<!--- all the url paths --->
			<cfset request.SLCMS.PageParams.TemplateSetName = tempdata.PathsGet.TemplateSetName />	<!--- the name of the template set if we need it --->
			<cfset request.SLCMS.PageParams.TemplateName = tempdata.PathsGet.TemplateName />	<!--- the name of the template if we need it --->
			<!--- see if we have a page with content, if not then grab this page's default page. --->
			<cfif request.SLCMS.PageParams.HasContent eq False and request.SLCMS.PageParams.DocID neq request.SLCMS.PageParams.DefaultDocID>
				<cfset request.SLCMS.PageParams = duplicate(application.SLCMS.Core.PageStructure.getSingleDocStructure(DocID="#request.SLCMS.PageParams.DefaultDocID#", SubSiteID="# request.SLCMS.PageParams.SubSiteID#")) />
			</cfif>
		<cfelse>
			<!--- oops! no point continuing there is no template to display --->
			<cfset tempData.Content.ContentToBeHad = False />
			<cfset tempData.Content.ContentHasError = True />	<!--- something went wrong --->
			<cfset tempData.Content.ContentHasErrorMessage = tempData.Content.ContentHasErrorMessage & "A page Template was requested that does not exist!" />	<!--- what went wrong to display on screen --->
		</cfif>
	<cfelse>
		<!--- nothing there so flick to the admin area --->
		<cfset tempData.Content.ContentToBeHad = False />
	</cfif>
	<!--- throw in the path we have decoded --->
	<cfset request.SLCMS.PageParams.PagePath = tempData.theParams />
	<cfset request.SLCMS.PageParams.PageQueryString = tempData.theQueryString />
	<!--- all is set up so record a stats hit for this page and the site overall if we have stats turned on --->
	<cfif application.SLCMS.config.Components.Use_Stats eq "yes">
		<cfset temp = application.SLCMS.mbc_Utility.Stats.AddHit(SiteName="Site_Hit")>
		<cfset temp = application.SLCMS.mbc_Utility.Stats.AddHit(SiteName="Page_Hit_ID_#tempData.DocID#")>
	</cfif>
	<!--- do the needed work to get nav --->
	<cfif tempData.Content.ContentToBeHad>
		<!--- this bit of code makes sure we have current navigation structs for the navigation system to work from --->
		<cfset session.SLCMS.PortalControl.SubSiteIDList_Active = application.SLCMS.core.portalControl.GetAllowedSubSiteIDList_ActiveSites() />	<!--- quick update in case a new one has popped up --->
			<cfif not ListFind(session.SLCMS.PortalControl.SubSiteIDList_Active, tempdata.SubSiteID)>
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
			<cfif not StructkeyExists(session.SLCMS.FrontEnd, "SubSite_#tempdata.SubSiteID#")>
				<cfset session.SLCMS.FrontEnd["SubSite_#tempdata.SubSiteID#"] = StructNew()>
			</cfif>
			<cfif not StructkeyExists(session.SLCMS.FrontEnd["SubSite_#tempdata.SubSiteID#"], "NavState")>
				<cfset session.SLCMS.FrontEnd["SubSite_#tempdata.SubSiteID#"].NavState = StructNew() />
				<cfset session.SLCMS.FrontEnd["SubSite_#tempdata.SubSiteID#"].NavState.theCurrentNavArray = Duplicate(application.SLCMS.Core.PageStructure.getFullNavArray(SubSiteID="#tempdata.SubSiteID#")) />
				<!--- initialise the nav tree expansion flag structure with all minimised --->
				<cfset session.SLCMS.FrontEnd["SubSite_#tempdata.SubSiteID#"].DocIdList = application.SLCMS.Core.PageStructure.getDocIdList(tempdata.SubSiteID) />
				<cfset session.SLCMS.FrontEnd["SubSite_#tempdata.SubSiteID#"].NavState.ExpansionFlags = StructNew() />
				<cfloop list="#session.SLCMS.FrontEnd['SubSite_#tempdata.SubSiteID#'].DocIdList#" index="thisDocID">
					<cfset session.SLCMS.FrontEnd["SubSite_#tempdata.SubSiteID#"].NavState.ExpansionFlags[thisDocID] = False />
				</cfloop>
				<cfset session.SLCMS.FrontEnd["SubSite_#tempdata.SubSiteID#"].NavSerial = Now() />	<!--- gets used to check if the site structure has changed --->
				<cfset session.SLCMS.FrontEnd["SubSite_#tempdata.SubSiteID#"].SubSiteID = tempdata.SubSiteID />	<!--- the current subSite --->
			</cfif>
			<!--- we have a front end session for navigation, etc., so see if the structure has changed since last time --->
			<cfif DateDiff("s", session.SLCMS.FrontEnd["SubSite_#tempdata.SubSiteID#"].NavSerial, application.SLCMS.Core.PageStructure.getSerial("#tempdata.SubSiteID#")) neq 0>
				<!--- its not the same so reload the structure --->
				<cfset session.SLCMS.FrontEnd["SubSite_#tempdata.SubSiteID#"].NavState.theCurrentNavArray = Duplicate(application.SLCMS.Core.PageStructure.getFullNavArray(tempdata.SubSiteID)) />
				<cfset session.SLCMS.FrontEnd["SubSite_#tempdata.SubSiteID#"].DocIdList = application.SLCMS.Core.PageStructure.getDocIdList(tempdata.SubSiteID) />
				<!--- and put any new documents as closed into the expansion structure --->
				<cfloop list="#session.SLCMS.FrontEnd["SubSite_#tempdata.SubSiteID#"].DocIdList#" index="thisDocID">
					<cfif (not StructKeyExists(session.SLCMS.FrontEnd["SubSite_#tempdata.SubSiteID#"].NavState.ExpansionFlags, thisDocID)) or session.SLCMS.FrontEnd["SubSite_#tempdata.SubSiteID#"].SubSiteID neq tempdata.SubSiteID>
						<cfset session.SLCMS.FrontEnd["SubSite_#tempdata.SubSiteID#"].NavState.ExpansionFlags[thisDocID] = False />
					</cfif>
				</cfloop>
				<!--- straighten our  flags --->
				<cfset session.SLCMS.FrontEnd["SubSite_#tempdata.SubSiteID#"].NavSerial = application.SLCMS.Core.PageStructure.getSerial("#tempdata.SubSiteID#") />
				<cfset session.SLCMS.FrontEnd["SubSite_#tempdata.SubSiteID#"].SubSiteID = tempdata.SubSiteID />	
			</cfif>
		</cfif>
	</cfif>
	<!--- now we do a tad of admin session handling as now in V3 we can pop the admin pages over the top of our content --->
	<cfif session.slcms.user.IsLoggedIn>
		<cfset thisTag.Ret = application.SLCMS.Core.ContentCFMfunctions.AddHeadContent(Place="Top", Path="#application.SLCMS.Paths_Common.jQueryJsPath_Abs#") />	<!--- load in jQuery --->
		<!--- and the js and styling fr the slide-down admin panel --->
		<cfset thisTag.Ret = application.SLCMS.Core.ContentCFMfunctions.AddHeadContent(Place="Top", Type="stylesheet", Path="#application.SLCMS.Paths_Admin.AdminPopWrapperStyleSheet_Abs#") />
		<cfset thisTag.Ret = application.SLCMS.Core.ContentCFMfunctions.AddHeadContent(Place="Top", Path="#application.SLCMS.Paths_Admin.AdminPopWrapperjs_Abs#") />
		<cfsavecontent variable="tempData.Content.AdminPopper">
			<cfinclude template="_AdminPopWrapper_inc.cfm" />
		</cfsavecontent>
	</cfif>

	<!--- 
	<!--- and the last session bit is just to flag we are showing a page, used by the IsAdmin(), etc., code to know what to flag back --->	
	<cfset session.SLCMS.Flags.InAdminPages = False />
	<cfset session.SLCMS.Flags.InSitePages = True />
	 --->
		<!---</cfsilent>---><!--- 
		and then display it if it flagged as viewable
 ---><cfif StructKeyExists(request.SLCMS.PageParams, "hidden") and BitAnd(request.SLCMS.PageParams.hidden,2) neq 2><!--- 
 ---><cfswitch expression="#request.SLCMS.PageParams.DocType#">
		<cfcase value="1">	<!--- File Directly --->
			<cffile action="READ" file="#request.SLCMS.PageParams.Param1#" variable="Content">
			<cfoutput>#Content#</cfoutput>
		</cfcase>
		<cfcase value="2"><!--- 
		Template File, the normal page in SLCMS
 ---><!---<cfsilent>--->
			<cfif tempData.Content.ContentToBeHad>
				<cfset request.SLCMS.PageParams.PageTitle = request.SLCMS.PageParams.NavName />
					<!--- load in the relevant nav stuff for this template, can be from a shared one or in the subsite --->
				<cfif ListLen(request.SLCMS.PageParams.param1, "/") eq 3>
					<cfset request.SLCMS.PageParams.Navigation.Styling = application.SLCMS.Core.Templates.getNavigationStyling_All(TemplateSet="#request.SLCMS.PageParams.TemplateSetName#", SubsiteID="Shared") />
				<cfelse>
					<cfset request.SLCMS.PageParams.Navigation.Styling = application.SLCMS.Core.Templates.getNavigationStyling_All(TemplateSet="#request.SLCMS.PageParams.TemplateSetName#", SubsiteID="#request.SLCMS.PageParams.SubSiteID#") />	<!--- load in the relevant nav stuff for this template --->
				</cfif>
				<cfset request.SLCMS.PageParams.Navigation.Breadcrumbs = application.SLCMS.Core.ContentCFMfunctions.SetBreadcrumbs(PathToThisPage="#tempData.theParams#", SubsiteID="#request.SLCMS.PageParams.SubSiteID#") />	<!--- load in the relevant nav stuff for this template --->
				<cfset request.SLCMS.PageParams.PagePathEncoded = request.SLCMS.PageParams.Navigation.Breadcrumbs.PagePathEncoded />
				<!--- now the breadcrumbs are done process any menu/nav expansion we might need --->
				<!--- expand where we are if needs be, but only if this navigation menu shows the current document --->
				<cfif not request.SLCMS.PageParams.PageToggles.flagNavExpansionDone>
					<cfset request.SLCMS.PageParams.PageToggles.flagNavExpansionDone = True />	<!--- only  --->
					<!--- ToDo: switch with nav style thingo, for the moment it is just a toggle --->
					<cfif structKeyExists(session.SLCMS.FrontEnd["SubSite_#tempdata.SubSiteID#"].NavState.ExpansionFlags, "#request.SLCMS.PageParams.DocID#")>
						<cfif session.SLCMS.FrontEnd["SubSite_#tempdata.SubSiteID#"].NavState.ExpansionFlags[request.SLCMS.PageParams.DocID] eq True>
							<cfset session.SLCMS.FrontEnd["SubSite_#tempdata.SubSiteID#"].NavState.ExpansionFlags[request.SLCMS.PageParams.DocID] = False />
						<cfelse>
							<cfset session.SLCMS.FrontEnd["SubSite_#tempdata.SubSiteID#"].NavState.ExpansionFlags[request.SLCMS.PageParams.DocID] = True />
						</cfif>
					<cfelse>
						<cfset session.SLCMS.FrontEnd["SubSite_#tempdata.SubSiteID#"].NavState.ExpansionFlags[request.SLCMS.PageParams.DocID] = True />
					</cfif>
					<!--- and expand the parent if it does --->
					<cfset session.SLCMS.FrontEnd["SubSite_#tempdata.SubSiteID#"].NavState.ExpansionFlags[request.SLCMS.PageParams.ParentID] = True />
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
				<cfsavecontent variable="tempData.Content.PageContent_Generated">
					<cfinclude template="#request.SLCMS.PageParams.Paths.URL.thisPageTemplateFullURL#">
				</cfsavecontent>
				<cftimer label="content.cfm head array">
				<!--- then find the <head> tag and shove our stuff in straight after for the bits we want at the beginning of the head --->
				<cfset tempData.Content.HeadOpeningTagEndPos = FindNoCase("<head>", tempData.Content.PageContent_Generated)+5 />
				<cfif tempData.Content.HeadOpeningTagEndPos gt 0>
					<!--- we do have a <head> tag so load in what is before it --->
					<cfset tempData.Content.ContentArray[1] = trim(left(tempData.Content.PageContent_Generated, tempData.Content.HeadOpeningTagEndPos)) />
					<!--- then all of the bits we have flagged as needing to be at the top of the <head> area --->
					<cfloop from="1" to="#ArrayLen(request.SLCMS.PageParams.HeadContent.Start.Strings)#" index="tempData.lcntr"> <!--- by default there will be a stylesheet for the editing sections and one for forms - login, etc --->
						<cfset ArrayAppend(tempData.Content.ContentArray, request.SLCMS.PageParams.HeadContent.Start.Strings[tempData.lcntr] & chr(13) & chr(10)) />
					</cfloop>
					<!---  now we have the original content up to the <head> and all of the bits we want straight after it so lets now add in the original <head> html --->
					<cfset tempData.Content.HeadEndingTagStartPos = FindNoCase("</head>", tempData.Content.PageContent_Generated)-1 />
					<cfif tempData.Content.HeadEndingTagStartPos gt 0>
						<cfset ArrayAppend(tempData.Content.ContentArray, mid(tempData.Content.PageContent_Generated, tempData.Content.HeadOpeningTagEndPos+1, tempData.Content.HeadEndingTagStartPos-tempData.Content.HeadOpeningTagEndPos)) />
						<!--- done so now we can repeat above and insert the extras we want at the botom of the head tag --->
						<cfloop from="1" to="#ArrayLen(request.SLCMS.PageParams.HeadContent.End.Strings)#" index="tempData.lcntr"> <!--- by default there will be a stylesheet for the editing sections and one for forms - login, etc --->
							<cfset ArrayAppend(tempData.Content.ContentArray, request.SLCMS.PageParams.HeadContent.End.Strings[tempData.lcntr] & chr(13) & chr(10)) />
						</cfloop>
						<!---  great! now we have everything up to the end of the head section, including the extras we flagged, so now add in the remains of the content from the </head> tag onwards --->
						<cfset tempData.Content.PageContent_Generated = RemoveChars(tempData.Content.PageContent_Generated, 1, tempData.Content.HeadEndingTagStartPos) />
					</cfif>
				</cfif>
				<cfif session.slcms.user.IsLoggedIn>
					<!--- if we are staff we need to add the div to show the slide-down admin area --->
					<cfset tempData.Content.BodyOpeningTagEndPos = FindNoCase("<body", tempData.Content.PageContent_Generated)+5 />
					<cfset tempData.Content.BodyOpeningTagEndPos = FindNoCase(">", tempData.Content.PageContent_Generated, tempData.Content.BodyOpeningTagEndPos)+1 />	<!--- end of body tag which can have attributes --->
					<!--- push in the code between start of head closing tag and end of opening body --->
					<cfset ArrayAppend(tempData.Content.ContentArray, left(tempData.Content.PageContent_Generated, tempData.Content.BodyOpeningTagEndPos)) />
					<!--- then add the div that will slide down for the admin pages --->
					<cfset ArrayAppend(tempData.Content.ContentArray, tempData.Content.AdminPopper) />
					<!--- and trim back our remaining content again and add it in after the new admin div --->
					<cfset tempData.Content.PageContent_Generated = RemoveChars(tempData.Content.PageContent_Generated, 1, tempData.Content.BodyOpeningTagEndPos) />
					<!--- ToDo: add the same for body end for tail stuff --->
					<cfset ArrayAppend(tempData.Content.ContentArray, tempData.Content.PageContent_Generated) />
				<cfelse>
					<!--- not logged in so just push the rest of the content out --->
					<cfset ArrayAppend(tempData.Content.ContentArray, tempData.Content.PageContent_Generated) />
				</cfif>
				</cftimer>
			<cfelse>
				<!--- this is if we had no content to get, the site is empty or an error happened --->
				<cfset ArrayAppend(tempData.Content.ContentArray, '<html><head></head> <body>') />
				<cfif tempData.Content.ContentHasError>
					<cfset ArrayAppend(tempData.Content.ContentArray, '<p>#tempData.Content.ContentHasErrorMessage#.</p><p><a href="#request.SLCMS.mapURL#content.cfm">Go to the Home Page</a></p><p><a href="/admin/AdminLogin.cfm">Go to the Administration Area</a></p>') />
				<cfelse>
					<cfset ArrayAppend(tempData.Content.ContentArray, '<p>There is nothing in the site yet. Go to Admin area first and create a Home Page.</p><p><a href="/admin/AdminLogin.cfm">Go to the Administration Area</a></p>') />
				</cfif>
				<cfset ArrayAppend(tempData.Content.ContentArray, '</body></html>' )/>
			</cfif>
		<!--- and display it all --->	
		<!---</cfsilent>---><cfif application.SLCMS.config.base.sitemode eq "Production"><cfcontent reset="yes"></cfif><cfoutput>#ArrayToList(tempData.Content.ContentArray, "")#</cfoutput><!--- 
 ---></cfcase>
		<cfcase value="3">	<!--- Custom Tag --->
			<cfif request.SLCMS.PageParams.Param2 eq "template path">
				<cfmodule template="#request.SLCMS.PageParams.Param1#">
			<cfelseif request.SLCMS.PageParams.Param2 eq "name">
				<cfmodule name="#request.SLCMS.PageParams.Param1#">
			</cfif>
		</cfcase>
		<cfcase value="4">	<!--- Speck??? --->
		</cfcase>
		<cfcase value="5">	<!--- Include File --->
			<cfset PageParams = request.SLCMS.PageParams.Param3 />
			<cfinclude template="#request.SLCMS.mapURL#SLCMS/Includes/#request.SLCMS.PageParams.Param1#" />
		</cfcase>
		<cfdefaultcase>
			<cflocation url="#request.SLCMS.mapURL#content.cfm" addtoken="No">
		</cfdefaultcase>
		</cfswitch>
	<cfelse>
	<!--- 
		<cfif tempData.Content.ContentToBeHad and StructKeyExists(request.SLCMS.PageParams, "hidden") and BitAnd(request.SLCMS.PageParams.hidden,2) neq 2>
	 --->
		<cfif StructKeyExists(request.SLCMS.PageParams, "hidden") and BitAnd(request.SLCMS.PageParams.hidden,2) eq 2>
			The page is not allowed to be viewed. <a href="content.cfm">Click here to go to Home Page</a>
		<cfelse>
			An error has occurred. The page could not be found. <a href="content.cfm">Click here to go to Home Page</a>
		</cfif>
	</cfif>
<cfelse>
	<!--- this is if we had no content to get, the site is empty --->
	<cfset $include(template="SLCMS/_EmptySiteWorkflow_inc.cfm") />
</cfif>
<!---
<!--- if it blew up this is where we catch it --->
<cfcatch>
	<cfinclude template="/ErrorPage_ForContentcfm_GeneralError.cfm" />
</cfcatch>
</cftry>
--->

 --->  
<!--- 
   <cfdump var="#IsCustomFunction(Nexts_getPersistentData)#" expand="false" label="IsCustomFunction(Nexts_getPersistentData)">    
 --->
<!---
    <cfdump var="#application#" expand="false" label="application">    
    <cfdump var="#request#" expand="false" label="request">    
		<cfdump var="#request.SLCMS.PageParams#" expand=false>
    <cfdump var="#application#" expand="false" label="application">    
    <cfdump var="#tempdata#" expand="false" label="tempdata">    
		<cfdump var='#application.slcms.core.templates.getVariablesScope()#' expand="false">
		<cfdump var="#session.slcms#" label="session.slcms" expand="false" />
    <cfdump var="#application.slcms#" expand="false" label="application.slcms">    
    <cfdump var="#request.slcms#" expand="false" label="request.slcms">    
--->
<!---
    <cfdump var="#SLCMS_Test()#" expand="false" label="SLCMS_Test()">    
--->
<!--- 
</cftimer>
 --->

