<!--- SLCMS base tags to be used in template pages  --->
<!--- &copy; mort bay communications --->
<!---  --->
<!--- custom tag to display a page's name --->
<!--- --->
<!--- created:   4th Dec 2007 by Kym K of mbcomms --->
<!--- modified:  4th Dec 2007 -  4th Dec 2007 by Kym K of mbcomms, did initial stuff --->

<!--- 
 --->
<cfsetting enablecfoutputonly="Yes">
<cfif thisTag.executionMode IS "start">
	<cfparam name="attributes.ShowURLName" type="string" default="False">	<!--- flag to show the URL Name rater than the Nav Name --->
	<cfparam name="attributes.Level" type="string" default="">	<!--- level to get page name from, defaults to current page's level' --->

	<cfset theOutPut = "" />
	<cfif attributes.Level eq "">
		<cfif attributes.ShowURLName>
			<cfset theOutPut = request.SLCMS.PageParams.URLName />
		<cfelse>
			<cfset theOutPut = request.SLCMS.PageParams.NavName />
		</cfif>
	<cfelseif attributes.Level neq "" and IsNumeric(attributes.Level) and attributes.Level lte ArrayLen(request.SLCMS.PageParams.Navigation.Breadcrumbs.Fixed)>	
		<cfif attributes.ShowURLName>
			<cfset theOutPut = request.SLCMS.PageParams.Navigation.Breadcrumbs.Fixed[attributes.Level].URLName />
		<cfelse>
			<cfset theOutPut = request.SLCMS.PageParams.Navigation.Breadcrumbs.Fixed[attributes.Level].NavName />
		</cfif>
	</cfif>
	<cfoutput>#theOutPut#</cfoutput>

</cfif>	<!--- end: tag execution mode is start --->

<cfif thisTag.executionMode IS "end">
</cfif>
<cfsetting enablecfoutputonly="No">
