<!--- SLCMS base tags to be used in template pages  --->
<!--- SLShop part of SLCMS &copy; mort bay communications --->
<!---  --->
<!--- custom tag to display a page's name --->
<!---  --->
<!---  --->
<!--- Created:   6th Feb 2007 by Kym K --->
<!--- Modified:  6th Feb 2007 -  6th Feb 2007 by Kym K, initial work on it --->

<!--- 
 --->
<cfsetting enablecfoutputonly="Yes">
<cfif thisTag.executionMode IS "start">
	<cfparam name="attributes.ShowURLName" type="string" default="False">	<!--- flag to show the URL Name rater than the Nav Name --->

	<cfoutput>
	<cfif attributes.ShowURLName>
		#request.PageParams.URLName#
	<cfelse>
		#request.PageParams.NavName#
	</cfif>
	</cfoutput>

</cfif>	<!--- end: tag execution mode is start --->

<cfif thisTag.executionMode IS "end">
</cfif>
<cfsetting enablecfoutputonly="No">
