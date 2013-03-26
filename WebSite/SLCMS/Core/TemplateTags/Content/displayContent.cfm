<cfif thisTag.executionMode IS "start">
<cfsetting enablecfoutputonly="Yes">
<!--- SLCMS base tags to be used in template pages  --->
<!--- &copy; mort bay communications --->
<!---  --->
<!--- custom tag to display the content in a page --->
<!--- run in the page and chooses which actual content to supply by calling standard tags
			lots of attributes according to what is needed to be displayed
			attributes.Type = type of content, must match a type specifed in param2, any|search|form... defaults to "", container
			attributes.Name = name of form or container
			attributes.id = id of container, ie place on page
			 --->
<!---  --->
<!--- Created:   3rd Jan 2007 by Kym K --->
<!--- Modified:  3rd Jan 2007 -  4th Jan 2007 by Kym K, mbcomms: initial work --->
<!--- Modified: 27th Jan 2007 - 27th Jan 2007 by Kym K, mbcomms: added params for forms --->
<!--- Modified: 23rd Apr 2007 - 23rd Apr 2007 by Kym K, mbcomms: added site map to the template types --->
<!--- Modified: 23rd Jul 2008 - 23rd Jul 2008 by Kym K, mbcomms: tickled the form type for new form template tag set --->
<!--- modified: 10th Sep 2008 - 10th Sep 2008 by Kym K, mbcomms: used new EditHeading attribute to put explanation text in the conatainers above and below forms --->
<!--- modified:  7th Feb 2009 -  7th Feb 2009 by Kym K, mbcomms: adding code to allow integration of a wiki --->
<!--- modified:  3rd Mar 2009 -  3rd Mar 2009 by Kym K, mbcomms: adding code to allow for the new Photogallery type --->
<!--- modified: 26th Mar 2009 - 26th Mar 2009 by Kym K, mbcomms: V2.2, changing folder structure to new module-allowing architecture, the core code is now just another module --->
<!--- modified: 12th Nov 2010 - 22nd Nov 2010 by Kym K, mbcomms: adding modules, param2 now has "core" or module name prepended to display type --->
<!--- modified:  2nd Jun 2011 -  2nd Jun 2011 by Kym K, mbcomms: added PreProcessor ability for module display so we can do "where are we" type processing before module display is called --->

	<cfparam name="attributes.Type" type="string" default="Any">
	<cfparam name="attributes.Module" type="string" default="Core">
	<cfparam name="attributes.SearchQueryTerm" type="string" default="">
	<cfparam name="attributes.Name" type="string" default="">
	<cfparam name="attributes.id" type="string" default="1">	<!--- if not told otherwise assume a single container --->
	
	<!--- 
	<cfdump var="#request.SLCMS.PageParams#" expand="false" label="request.SLCMS.PageParams">
	<!---<cfabort>--->
	<cfdump var="#attributes#" expand="false" label="attributes">
	--->
	<cfset theModule = "Core" />
	<cfset theCTParam = "" />	
	<cfset theContentType = "" />	
	<cfset theModuleType = "" />	
	<cfset theExtraType = "" />	
	
	<!--- select by type as to what to display
				can be "any" so work out what either from the attributes or page type
				all of this is sorted in alphabetical order to make finding things easy :-) --->
	<cfswitch expression="#attributes.type#">
	<cfcase value="Container">
		<cfset theContentType = "Container" />	
	</cfcase>
	<cfcase value="Form">
		<cfset theContentType = "Form" />	
	</cfcase>
	<cfcase value="Search">
		<cfset theContentType = "Search" />	
	</cfcase>
	<cfcase value="SiteMap">
		<cfset theContentType = "SiteMap" />	
	</cfcase>
	<cfcase value="Wiki">
		<cfset theContentType = "Wiki" />	
	</cfcase>
	<cfcase value="Any">
		<!--- param2 should carry what module and what display type we want --->
		<!---  there are legacy sites, pre-V2.2, that have just a plain core type --->
		<cfif ListLen(request.SLCMS.PageParams.Param2) eq 1>	<!--- its core or legacy, which is core only anyway --->
			<cfset theCTParam = request.SLCMS.PageParams.Param2 />
		<cfelseif ListLen(request.SLCMS.PageParams.Param2) eq 2>	<!--- its V2.2+ style, a list. First item is core/module, 2nd is type --->
			<cfset theModule = ListFirst(request.SLCMS.PageParams.Param2) />
			<cfset theCTParam = ListRest(request.SLCMS.PageParams.Param2) />
		<cfelseif ListLen(request.SLCMS.PageParams.Param2) gt 2>	<!--- its V2.2+ style list, first item  is core/module, 2nd is type, 3rd is whatever --->
			<cfset theModule = ListFirst(request.SLCMS.PageParams.Param2) />
			<cfset theCTParam = ListGetAt(request.SLCMS.PageParams.Param2, 2) />
			<cfset theExtraType = ListGetAt(request.SLCMS.PageParams.Param2, 3) />	
		</cfif>
		<cfif theModule eq "Core">
			<cfif theCTParam eq "Form">
				<cfset theContentType = "Form" />	
			<cfelseif theCTParam eq "SearchResult">
				<cfset theContentType = "Search" />	
			<cfelseif theCTParam eq "SiteMap">
				<cfset theContentType = "SiteMap" />	
			<cfelseif theCTParam eq "Wiki">
				<cfset theContentType = "Wiki" />	
			<cfelse>
				<cfset theContentType = "Container" />	
			</cfif>
		<cfelse>
			<!--- in a module we have to work out what display tag to call --->
			<cfset theContentType = theCTParam />	
		</cfif>
	</cfcase>
	<cfdefaultcase>
		<cfset theContentType = "" />	
	</cfdefaultcase>
	</cfswitch>
	
	<!--- now show the content we have selected --->
	<cfif theModule eq "Core">
		<cfswitch expression="#theContentType#">
		<cfcase value="container">
			<cf_displayContainer name="#attributes.Name#" id="#attributes.id#" />	
		</cfcase>
		
		<cfcase value="Form">
			<!--- display the form with editable wrapping content, both of which are displayed for all form types and modes
						there are further editable areas within the form space specific to input, validation/error and completion --->
			<cf_displayContainer id="101" EditHeading="Content shown at all times on this page" />	<!--- a generic text area at the top of the page --->
			<cf_displayForm formName="#request.SLCMS.PageParams.Param3#" />	<!--- show the form --->
			<cf_displayContainer id="102" EditHeading="Content shown at all times on this page" />	<!--- ditto below the form, both of these are displayed above and below for all form types and modes --->
		</cfcase>
		
		<cfcase value="Search">
			<!--- set up defaults which will give us nothing --->
			<cfset thisQueryControl = StructNew() />
			<cfset thisQueryControl.Mode = "Simple" />
			<cfset thisQueryControl.QueryTerm = "uytkdjljkdflskjdla;jsflaksjfl;rubbish so we get nothing rather than everything" />
			<cfset thisQueryControl.Types = "Page" />
		<!--- 
			<cfif len(attributes.SearchQueryTerm)>
				<cfset HaveQuery = IsDefined(attributes.SearchQueryTerm) />
				<cfif HaveQuery>
					<cfset theQueryterm = evaluate(attributes.SearchQueryTerm) />
				<cfelse>
					<cfset theQueryterm = "" />
				</cfif>
			<cfelse>
				<cfset HaveQuery = False />
				<cfset theQueryterm = "" />
			</cfif>
			<!--- this is to handle pages in edit mode --->
			<cfif IsDefined("form.edit")>
				<cfset theQueryterm = "uytkdjljkdflskjdla;jsflaksjfl;rubbish so we get nothing rather than everything" />
			</cfif>
	 --->
			<!--- now we see if we have to just show results from search form 
						or whether we need to show the advanced form
						or whether we need to show the advanced results
						or if an edit button for one of the surrounding content conatiners has been pushed don't do any search at all!
						 --->
			<cfif (IsDefined("form.edit") or IsDefined("form.FCKSubmission")) and not (IsDefined("form.UnderButton") and form.UnderButton eq "Cancel")>
				<cf_displayContainer id="1" />
				<cf_displayContainer id="2" />
				<cf_displayContainer id="3" />
				<cf_displayContainer id="9" />
			<cfelse>
		 		<cfif IsDefined("form.SimpleSearchRequested")>
					<!--- this means the simple search form was submitted --->
					<cfif IsDefined("form.SearchTerm")>
						<cfset thisQueryControl.QueryTerm = form.SearchTerm />
					</cfif>
					<cf_displayContainer id="1" />
		 		<cfelseif IsDefined("url.mode") and url.mode eq "AdvancedSearchRequested">
					<!--- this is the advanced form --->
					<cfset thisQueryControl.Mode = "ShowAdvancedEntryForm" />
					<cf_displayContainer id="2" />
		 		<cfelseif IsDefined("form.AdvancedSearchSubmitted")>
					<!--- the advanced form has been submitted --->
					<cfif IsDefined("form.SearchTerm")>
						<cfset thisQueryControl.QueryTerm = form.SearchTerm />
						<cfset thisQueryControl.Mode = "Advanced" />
						<cfset thisQueryControl.Types = form.SearchTypes />
					</cfif>
					<cf_displayContainer id="3" />
				<cfelse>
				</cfif>
				<cf_displaySearchPage QueryControl="#thisQueryControl#" />
				<cf_displayContainer id="9" />
			</cfif>
		</cfcase>

		<cfcase value="SiteMap">
			<cf_displaySiteMap />	
		</cfcase>
		<!--- 
		<cfcase value="wiki">
			<cf_displayContainer name="#attributes.Name#" id="#attributes.id#" DisplayType="wiki" />	
		</cfcase>
		 --->
		<cfdefaultcase>
			<!--- we don't recognise it as a core display component so what is it? --->
			<!--- default to a container, it'll come up blank if we got it wrong --->
			<cf_displayContainer name="#attributes.Name#" id="#attributes.id#" />	
		</cfdefaultcase>
		</cfswitch>
	
	<cfelse>
		<!--- not core so must be a module --->
		<!--- run any preprocessors we might need to run --->
		<cfset thisTag.PreProcIncludes = application.SLCMS.system.ModuleManager.getQuickPreProcessorIncludeList(module="#theModule#") />
		<cfloop list="#thisTag.PreProcIncludes#" index="thisTag.thisInclude">
			<cfinclude template="#application.SLCMS.modules["#theModule#"].Paths.ModuleRootURLPath##thisTag.thisInclude#">
		</cfloop>
		<cfset thisTag.PreProcTags = application.SLCMS.system.ModuleManager.getQuickPreProcessorTagList(module="#theModule#") />
		<cfloop list="#thisTag.PreProcTags#" index="thisTag.thisPreTag">
			<cfmodule template="#application.SLCMS.modules['#theModule#'].Paths.ModuleRootURLPath##application.SLCMS.modules['#theModule#'].Paths.TemplateTags##thisTag.thisPreTag#"></cfmodule>
		</cfloop>
		<!--- and then display the module content --->
		<cfif StructKeyExists(application.SLCMS.modules["#theModule#"].DisplayTypes, "#theContentType#")>
			<cfif application.SLCMS.modules["#theModule#"].DisplayTypes["#theContentType#"].mode eq "Template">
				<cfset thisTag.theDisplayPath = application.SLCMS.modules["#theModule#"].Paths.ModuleRootURLPath 
																& application.SLCMS.modules["#theModule#"].Paths.Templates 
																& application.SLCMS.modules["#theModule#"].DisplayTypes["#theContentType#"].template />
				<cfoutput>
				<cfinclude template="#thisTag.theDisplayPath#">
				</cfoutput>
			<cfelseif application.SLCMS.modules["#theModule#"].DisplayTypes["#theContentType#"].mode eq "Tag">
				<cfset theModulePath = application.SLCMS.modules["#theModule#"].Paths.ModuleRootURLPath 
																& application.SLCMS.modules["#theModule#"].Paths.TemplateTags 
																& application.SLCMS.modules["#theModule#"].DisplayTypes["#theContentType#"].tag />
				<cfmodule template="#theModulePath#" extras="#theExtraType#"></cfmodule>
			</cfif>
		</cfif>
		
	</cfif>
</cfif>

<cfsetting enablecfoutputonly="No"><cfif thisTag.executionMode IS "end"></cfif>