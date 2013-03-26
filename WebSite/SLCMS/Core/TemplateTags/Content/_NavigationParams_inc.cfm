<!--- SLCMS base tags to be used in template pages  --->
<!---  --->
<!--- include file for common code in the custom tags that display a navigation menu or a breadcrumb --->
<!--- &copy; mort bay communications --->
<!---  --->
<!--- created:  30th Dec 2007 by Kym K, mbcomms - cloned from displayNavigation tag --->
<!--- modified: 30th Dec 2007 - 30th Dec 2007 by Kym K, mbcomms - did initial stuff --->
<!--- modified: 21st Dec 2008 - 21st Dec 2008 by Kym K, mbcomms - added code to not show specified number of first and/or last elements for menus nesting inside other code --->
<!--- modified:  1st Feb 2009 -  3rd Feb 2009 by Kym K - mbcomms: moved menu/nav expansion flags to content.cfm from include-NavigationParams so it only runs once per page --->
<!--- modified: 25th Mar 2009 - 25th Mar 2009 by Kym K, mbcomms - added a js and stylesheet definition --->
<!--- modified: 27th Apr 2009 - 27th Apr 2009 by Kym K - mbcomms: V2.2, changing template folder structure to portal/sub-site architecture, sites inside the top site, data structures added/changed to match --->
<!--- modified: 21st Oct 2009 - 21st Oct 2009 by Kym K - mbcomms: V2.2, added struct key tests for new nav variables to allow old nav definition ini files to work --->
<!--- modified:  7th Nov 2009 -  7th Nov 2009 by Kym K - mbcomms: V2.2, added flag to (not)show a link to portal top site in menus --->
<!---
docs: modified: 25th Feb 2012 - 25th Feb 2012 by Kym K, mbcomms: version 2.0.3, core V2.2+, added a top folder attribute so can show a menu for a folder other than its own parent, also added new "docs" documentation
docs: endHistory_Coding
--->
<cfsetting enablecfoutputonly="Yes">
	
<!--- 	
<cfoutput>attributes:	</cfoutput><cfdump var="#attributes#" expand="false">
<cfoutput>start nav array:	</cfoutput><cfdump var="#session.FrontEnd["SubSite_#request.SLCMS.PageParams.SubSiteID#"].NavState.theCurrentNavArray#" expand="false">
 --->
		
	<cfset baseURL = application.SLCMS.Config.base.RootURL & attributes.ContentPage />	<!--- page is always at the root in flexi --->
	<cfset theNavstyle = trim(attributes.NavName) />
	<!--- work out what the shape of the menu tree is --->
	<cfif len(attributes.TreeStyle) eq 0>
		<cfset theTreeStyle = request.SLCMS.PageParams.Navigation.Styling["#theNavstyle#"].NavigationControl.TreeStyle />
	<cfelse>
		<cfset theTreeStyle = trim(attributes.Format) />
	</cfif>
	<!--- work out what format to use for the HTML if it is not specified as an attribute --->
	<cfif len(attributes.Format) eq 0>
		<!--- we need to handle older ini files so do a quick test --->
		<cfif StructKeyExists(request.SLCMS.PageParams.Navigation.Styling["#theNavstyle#"].NavigationControl, "HTMLFormat")>
			<cfset theFormat = request.SLCMS.PageParams.Navigation.Styling["#theNavstyle#"].NavigationControl.HTMLFormat />
		<cfelse>
			<cfset theFormat = request.SLCMS.PageParams.Navigation.Styling["#theNavstyle#"].NavigationControl.Format />
		</cfif>
	<cfelse>
		<cfset theFormat = attributes.Format />
	</cfif>
	<!--- process any specified Stylesheet --->
	<cfif len(trim(attributes.Stylesheet)) eq 0>
		<cfset theStylesheet = request.SLCMS.PageParams.Navigation.Styling["#theNavstyle#"].NavigationStyling.Stylesheets />
	<cfelse>
		<cfset theStylesheet = attributes.Stylesheet />
	</cfif>
	<!--- and any specified javascript --->
	<cfif len(trim(attributes.js)) eq 0 and StructKeyExists(request.SLCMS.PageParams.Navigation.Styling["#theNavstyle#"].NavigationStyling, "javascript")>	<!--- allow for missing key from old definitions pre version 2.2 --->
		<cfset theJS = request.SLCMS.PageParams.Navigation.Styling["#theNavstyle#"].NavigationStyling.javascript />
	<cfelse>
		<cfset theJS = attributes.js />
	</cfif>
	<!--- work out what style class to use for the HTML if it is not specified as an attribute --->
	<cfif len(attributes.WrapperClass) eq 0>
		<cfif StructKeyExists(request.SLCMS.PageParams.Navigation.Styling["#theNavstyle#"].NavigationStyling, "WrapperClass") and len(request.SLCMS.PageParams.Navigation.Styling["#theNavstyle#"].NavigationStyling.WrapperClass)>
			<cfset theWrapperClass = ' class="#request.SLCMS.PageParams.Navigation.Styling["#theNavstyle#"].NavigationStyling.WrapperClass#"' />
		<cfelse>
			<cfset theWrapperClass = '' />
		</cfif>
	<cfelse>
		<cfset theWrapperClass = ' class="#attributes.WrapperClass#"' />
	</cfif>
	<!--- work out what style id to use for the HTML if it is not specified as an attribute --->
	<cfif len(attributes.WrapperId) eq 0>
		<cfif StructKeyExists(request.SLCMS.PageParams.Navigation.Styling["#theNavstyle#"].NavigationStyling, "WrapperId") and len(request.SLCMS.PageParams.Navigation.Styling["#theNavstyle#"].NavigationStyling.WrapperId)>
			<cfset theWrapperId = ' id="#request.SLCMS.PageParams.Navigation.Styling["#theNavstyle#"].NavigationStyling.WrapperId#"' />
		<cfelse>
			<cfset theWrapperId = '' />
		</cfif>
	<cfelse>
		<cfset theWrapperId = ' id="#attributes.WrapperId#"' />
	</cfif>
	<!--- work out what elements to show if they are not specified as an attribute
				this is a top-level only trick to insert nav items into existing tabular structures --->
	<cfif len(attributes.SkipFirstElements) eq 0>
		<cfif StructKeyExists(request.SLCMS.PageParams.Navigation.Styling["#theNavstyle#"].NavigationControl, "SkipFirstElements")>
			<cfset theFirstElementsToSkip = request.SLCMS.PageParams.Navigation.Styling["#theNavstyle#"].NavigationControl.SkipFirstElements />
		<cfelse>
			<cfset theFirstElementsToSkip = 0 />
		</cfif>
	<cfelse>
		<cfset theFirstElementsToSkip = attributes.SkipFirstElements />
	</cfif>
	<cfif len(attributes.SkipLastElements) eq 0>
		<cfif StructKeyExists(request.SLCMS.PageParams.Navigation.Styling["#theNavstyle#"].NavigationControl, "SkipLastElements")>
			<cfset theLastElementsToSkip = request.SLCMS.PageParams.Navigation.Styling["#theNavstyle#"].NavigationControl.SkipLastElements />
		<cfelse>
			<cfset theLastElementsToSkip = 0 />
		</cfif>
	<cfelse>
		<cfset theLastElementsToSkip = attributes.SkipLastElements />
	</cfif>
	<!--- work out what levels to show if it is not specified as an attribute --->
	<cfif len(attributes.LevelToStartAt) eq 0>
		<cfset theStartLevel = request.SLCMS.PageParams.Navigation.Styling["#theNavstyle#"].NavigationControl.LevelToStart />
	<cfelse>
		<cfset theStartLevel = attributes.LevelToStartAt />
	</cfif>
	<cfif len(attributes.LevelsToShow) eq 0>
		<cfset theLevelsToShow = request.SLCMS.PageParams.Navigation.Styling["#theNavstyle#"].NavigationControl.LevelsToShow />
	<cfelse>
		<cfset theLevelsToShow = attributes.LevelsToShow />
	</cfif>
	<cfif IsNumeric(theLevelsToShow) and theLevelsToShow gte 1>
		<cfset theBottomLevel = theStartLevel+theLevelsToShow-1 />	<!--- work out what level to stop at --->
	<cfelse>
		<cfset theBottomLevel = 99 />	<!--- nothing specified or 0 means show all --->
	</cfif>
	<!--- other flags and things --->
	<cfif attributes.HidePortalHomeLink or request.SLCMS.PageParams.SubSiteID eq 0>
		<cfset flgShowTopHomeLink = False />
	<cfelse>
		<cfset flgShowTopHomeLink = True />
	</cfif>
	
<cfsetting enablecfoutputonly="No">
