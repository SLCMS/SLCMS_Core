<!--- SLCMS base tags to be used in template pages  --->
<!--- &copy; 2009 mort bay communications --->
<!---  --->
<!--- custom tag to set the style sheet for the editor to use --->
<!--- 
			description goes here
			and what attributes are needed and what they do
		  --->
<!--- created:  20th Nov 2008 by Kym K, mbcomms --->
<!--- modified: 20th Nov 2008 - 20th Nov 2008 by Kym K, mbcomms - did initial stuff, wasn't exactly hard :-)' --->
<!--- modified:  3rd Mar 2012 -  3rd Mar 2012 by Kym K, mbcomms - added IncludeInPageStyling attribute and added docs --->

<cfsetting enablecfoutputonly="Yes">
<cfif NOT IsDefined("thisTag.executionMode")>
	<cfabort showerror="Must be called as customtag.">
</cfif>
<cfif thisTag.executionMode IS "start">
	<cfparam name="attributes.Stylesheet" type="string" default="">	<!--- the name of the stylesheet --->
	<cfparam name="attributes.IncludeInPageStyling" type="Boolean" default="True">	<!--- flag to see if the stylesheet has to go in the page head area --->
	
	<cfset theStyleSheet = trim(attributes.StyleSheet) />
	<!--- if we have a stylesheet specified then set our page params to match --->
	<cfif theStyleSheet neq "">
		<cfset request.SLCMS.PageParams.EditorStyleSheet = theStyleSheet />
		<cfif attributes.IncludeInPageStyling>
			<!--- now add the same stylesheet to the head if requested --->
			<cfset application.SLCMS.core.contentCFMfunctions.AddHeadContent(type="StyleSheet", place="Bottom", path="#request.SLCMS.PageParams.Paths.URL.thisPageTemplateControlURLpath##theStyleSheet#") />
		</cfif>
	</cfif>

</cfif>	<!--- end: tag execution mode is start --->

<cfif thisTag.executionMode IS "end">
	<!--- 
	<cfexit>	<!--- this allows for tags called with an XML form <cf_xxx />, can be omitted --->
	 --->
<cfelseif NOT thisTag.hasEndTag>
	<cfabort showerror="Missing end tag.">
</cfif>
<cfsetting enablecfoutputonly="No">
