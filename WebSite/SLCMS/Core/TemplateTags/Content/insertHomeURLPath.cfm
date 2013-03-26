<cfsilent><!--- inserts the url to the website's Home Page with the base controller file, content.cfm or whatever. Useful in templates for hard coded menus and the like --->
	<!--- created:  11th Feb 2012 by Kym K, mbcomms: cloned from insertHomePageURL --->
	<!--- modified: 11th Feb 2012 - 11th Feb 2012 by Kym K, mbcomms: initial work on it --->
stuff will go in here

</cfsilent><cfif thisTag.executionMode IS "start"><cfsilent>
	<cfparam name="attributes.UseDomainName" type="boolean" default="False">	<!--- allow to use full domain name in path but normal is absolute path from site root  --->
	<cfparam name="attributes.AddClosingSlash" type="boolean" default="True">	<!--- adds the closing slash so calling template only has to add the page name  --->
	<cfif attributes.UseDomainName>
		<cfset thisTag.OurContent = application.SLCMS.core.PortalControl.getPortalHomeURL() & application.SLCMS.Config.Base.rootURL />
	<cfelse>
		<cfset thisTag.OurContent = "" />
	</cfif>
	<cfset thisTag.OurContent = thisTag.OurContent & application.SLCMS.paths_Common.ContentRootUrl />
	<cfif attributes.AddClosingSlash>
		<cfset thisTag.OurContent = thisTag.OurContent & "/" />
	</cfif>
</cfsilent></cfif><cfif thisTag.executionMode IS "end"><cfset thisTag.GeneratedContent = "" /><cfoutput>#thisTag.OurContent#</cfoutput></cfif>