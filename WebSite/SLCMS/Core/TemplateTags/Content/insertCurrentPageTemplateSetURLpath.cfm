<cfsilent><!--- inserts the url path to the top of the current page template set ---></cfsilent><cfif thisTag.executionMode IS "start"><cfset thisTag.OurContent = request.SLCMS.PageParams.Paths.URL.thisTemplateSetURLpath /></cfif><cfif thisTag.executionMode IS "end"><cfset thisTag.GeneratedContent = "" /><cfoutput>#thisTag.OurContent#</cfoutput></cfif>