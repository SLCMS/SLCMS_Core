<cfsilent><!--- inserts the full url to the website's Home Page with the name of the home page, useful to get back to the top in an absolute way --->
	<!--- created:  11th Feb 2012 by Kym K, mbcomms: cloned from insertSiteBaseURL --->
	<!--- modified: 11th Feb 2012 - 11th Feb 2012 by Kym K, mbcomms: initial work on it --->
stuff will go in here

</cfsilent><cfif thisTag.executionMode IS "start"><cfsilent>
	<cfparam name="attributes.UseDomainName" type="boolean" default="False">	<!--- allow to use full domain name in path but normal is absolute path from site root  --->
	<cfif attributes.UseDomainName>
		<cfset thisTag.OurContent = application.SLCMS.core.PortalControl.getPortalHomeURL() & application.SLCMS.Config.Base.rootURL />
	<cfelse>
		<cfset thisTag.OurContent = "" />
	</cfif>
	<cfset thisTag.OurContent = thisTag.OurContent & application.SLCMS.paths_Common.ContentRootUrl & "/" & application.SLCMS.core.PageStructure.getHomePageDocPath(subSiteID="#request.SLCMS.pageParams.subSiteID#") />
</cfsilent></cfif><cfif thisTag.executionMode IS "end"><cfset thisTag.GeneratedContent = "" /><cfoutput>#thisTag.OurContent#</cfoutput></cfif>