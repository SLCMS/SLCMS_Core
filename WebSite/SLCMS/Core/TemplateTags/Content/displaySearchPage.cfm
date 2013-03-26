<!--- SLCMS base tags to be used in template pages  --->
<!---  --->
<!--- custom tag to display search results --->
<!--- &copy; mort bay communications --->
<!---  --->
<!--- created:  15th Dec 2006 by Kym K --->
<!--- modified: 15th Dec 2006 - 18th Dec 2006 by Kym K - did initial stuff --->
<!--- modified: 29th Mar 2008 - 30th Mar 2008 by Kym K - changed to a full Verity Collection Search engine --->
<!--- modified: 23rd Mar 2009 - 23rd Mar 2009 by Kym K - mbcomms: V2.2, changing structures to new module-allowing architecture, the core code is now just another module --->
<!--- modified: 21st Nov 2009 - 21st Nov 2009 by Kym K - mbcomms: V2.2, moved on the portal capability, we now have subSites! --->

<!--- 
 --->
<cfsetting enablecfoutputonly="Yes">
<cfif thisTag.executionMode IS "start">
	<cfparam name="attributes.QueryControl" type="struct" default="">
	<cfparam name="attributes.SubSiteID" type="numeric" default="#request.PageParams.subSiteID#">
<!--- 
	<cfoutput>
	<cfdump var="#attributes.QueryControl#">
	</cfoutput>
 --->
	<cfset loopCounter = 0 />	<!--- just an odd/even thing for styling --->
	<cfset theDSPVars = StructNew() />
	<cfset theDSPVars.SearchResults = application.Core.Content_Search.SearchCollection(name="Body", SearchTerm="#attributes.QueryControl.QueryTerm#", subSiteID="#attributes.SubSiteID#") />

	<cfoutput><div class="SearchResultsHeading">
			<h1>Search Results</h1><h2>There were #theDSPVars.SearchResults.RecordCount# results</h2>
		</div></cfoutput>
	<cfoutput><div class="SearchResultsWrapper"></cfoutput>
	<cfif theDSPVars.SearchResults.RecordCount>
		<cfloop query="theDSPVars.SearchResults">
			<cfset theDSPVars.thisID = theDSPVars.SearchResults.key />
			<cfset theDSPVars.Nav = application.SLCMS.Core.PageStructure.getFixedBreadcrumb(DocID="#theDSPVars.thisID#", SubSiteID="#attributes.SubSiteID#") />
			<cfif theDSPVars.Nav.NamePath neq "">	<!--- if we have bad info from the search the page might not be there any more, or is in another subSite --->
				<cfset theDSPVars.ContextText = theDSPVars.SearchResults.Context />
				<!--- we need to tidy up any loose partial html tags at the beginning or end due to the partial text fed to the stripper from the search context result --->
				<cfset theDSPVars.ContextTextGtPos = FindNoCase(">", theDSPVars.ContextText) />
				<cfset theDSPVars.ContextTextLtPos = FindNoCase("<", theDSPVars.ContextText) />
				<cfif theDSPVars.ContextTextGtPos lt theDSPVars.ContextTextLtPos and theDSPVars.ContextTextGtPos gt 5>
					<!--- we have a stray at start so strip, allowing for the ... at the beginning --->
					<cfset theDSPVars.ContextText = RemoveChars(theDSPVars.ContextText,5,theDSPVars.ContextTextGtPos-4) />
				</cfif>
				<!--- flip and check the other end --->
				<cfset theDSPVars.ContextText = Reverse(theDSPVars.ContextText) />
				<cfset theDSPVars.ContextTextGtPos = FindNoCase(">", theDSPVars.ContextText) />
				<cfset theDSPVars.ContextTextLtPos = FindNoCase("<", theDSPVars.ContextText) />
				<cfif theDSPVars.ContextTextLtPos lt theDSPVars.ContextTextGtPos and theDSPVars.ContextTextGtPos gt 5>
					<!--- we have a stray at end so strip, allowing for the ... at the beginning --->
					<cfset theDSPVars.ContextText = RemoveChars(theDSPVars.ContextText,5,theDSPVars.ContextTextLtPos-4) />
				</cfif>
				<cfset theDSPVars.ContextText = Reverse(theDSPVars.ContextText) />
				<!--- we now have clean string with no rubbish at front or back so strip stray html from middle --->
				<cfset theDSPVars.ContextText = application.SLCMS.mbc_Utility.Utilities.tagStripper(theDSPVars.ContextText,"strip","b") />
				<cfset loopCounter = loopCounter+1 />
				<cfif loopCounter MOD 2>
					<cfset theSingleWrapperStyle = "SingleResultWrapper_Odd" />
				<cfelse>
					<cfset theSingleWrapperStyle = "SingleResultWrapper_Even" />
				</cfif>
				<cfoutput>
				<div class="#theSingleWrapperStyle#">
					<div class="SearchHeadingWrapper">
						<div class="PageHeading">
							<span class="PageHeadingLabel">Page: </span><a href="#request.SLCMS.rootURL#content.cfm#theDSPVars.Nav.URLPath#">#theDSPVars.Nav.NamePath#</a> 
						</div>
						<div class="ScoreHeading">
							<span class="ScoreHeadingLabel">Search Score: </span>#theDSPVars.SearchResults.Score# 
						</div>
						<div class="LastEditedHeading">
							<span class="LastEditedHeadingLabel">Last Edited on: </span>#DateFormat(theDSPVars.SearchResults.Custom1, "dd mmm yyyy")#
						</div>
					</div>
					<div class="SearchContextWrapper">
						<div class="ContextHeading">
							Context of the Result: 
						</div>
						<div class="ContextText">
							#theDSPVars.ContextText#
						</div>
					</div>
				</div>
				</cfoutput>
			</cfif>
		</cfloop>
	<cfelse>
		<cfoutput><strong>Page Content Search:</strong> Sorry, there were no results matching that query.</cfoutput>
	</cfif> 
	<cfoutput></div></cfoutput>


	<!--- now we do the Documents --->
	<cfset theDSPVars = StructNew() />
	<cfset theDSPVars.SearchResults = application.SLCMS.Core.Content_Search.SearchCollection(name="Doc", SearchTerm="#attributes.QueryControl.QueryTerm#", subSiteID="#attributes.SubSiteID#") />
<!--- 
	<cfoutput>
	<cfdump var="#theDSPVars.SearchResults#">
	</cfoutput>
 --->

	<cfoutput><div class="SearchResultsWrapper"></cfoutput>
	<cfif theDSPVars.SearchResults.RecordCount>
		<cfloop query="theDSPVars.SearchResults">
			<cfset theDSPVars.ContextText = theDSPVars.SearchResults.Context />
<!--- 
			<cfset theDSPVars.ContextText = application.mbc_Utility.Utilities.tagStripper(theDSPVars.SearchResults.Context,"strip","b") />
			<!--- we need to tidy up any loose partial html tags at the beginning or end due to the partial text fed to the stripper from the search context result --->
			<cfset theDSPVars.ContextTextGtPos = FindNoCase(">", theDSPVars.ContextText) />
			<cfset theDSPVars.ContextTextLtPos = FindNoCase("<", theDSPVars.ContextText) />
			<cfif theDSPVars.ContextTextGtPos lt theDSPVars.ContextTextLtPos and theDSPVars.ContextTextGtPos gt 5>
				<!--- we have a stray so strip, allowing for the ... at the beginning --->
				<cfset theDSPVars.ContextText = RemoveChars(theDSPVars.ContextText,5,theDSPVars.ContextTextGtPos-4) />
			</cfif>
 --->
			<cfoutput>
			<div class="SingleResultWrapper">
				<div class="SearchHeadingWrapper">
					<div class="PageHeading">
						<span class="PageHeadingLabel">Document: </span><a href="#application.SLCMS.Site_Root.Paths.ResourceURLs.FileResources##ListLast(theDSPVars.SearchResults.key, '\')#">#theDSPVars.SearchResults.Title#</a> 
					</div>
					<div class="ScoreHeading">
						<span class="ScoreHeadingLabel">Search Score: </span>#theDSPVars.SearchResults.Score# 
					</div>
				</div>
				<div class="SearchContextWrapper">
					<div class="ContextHeading">
						Context of the Result: 
					</div>
					<div class="ContextText">
						#theDSPVars.ContextText#
					</div>
				</div>
			</div>
			</cfoutput>
		</cfloop>
	<cfelse>
		<cfoutput><strong>Document Search:</strong> Sorry, there were no results matching that query.</cfoutput>
	</cfif> 
	<cfoutput></div></cfoutput>

</cfif>

<cfif thisTag.executionMode IS "end">
</cfif>
<cfsetting enablecfoutputonly="No">
