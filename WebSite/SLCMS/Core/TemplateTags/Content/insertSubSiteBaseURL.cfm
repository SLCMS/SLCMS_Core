<cfsilent><!--- inserts the base url to the subSite ---></cfsilent><cfif thisTag.executionMode IS "start"><cfset thisTag.OurContent = application.SLCMS.Config.Base.rootURL & "content.cfm/" & request.SLCMS.PageParams.SubSiteURLNameEncoded /></cfif><cfif thisTag.executionMode IS "end"><cfset thisTag.GeneratedContent = "" /><cfoutput>#thisTag.OurContent#</cfoutput></cfif>