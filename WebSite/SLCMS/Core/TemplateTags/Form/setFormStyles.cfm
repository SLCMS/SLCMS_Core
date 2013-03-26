<!--- SLCMS base tags to be used in template pages  --->
<!--- &copy; 2009 mort bay communications --->
<!---  --->
<!--- custom tag to include a form stylesheet, puts it at the end of the html head section --->
<!--- cloned:   10th Sep 2008 by Kym K, mbcomms from standard blank tag in TemplateTags --->
<!--- modified: 10th Sep 2008 - 10th Sep 2008 by Kym K, mbcomms - added a bunch of attributes which are going to be used in every tag --->
<!--- modified: 25th Mar 2009 - 25th Mar 2009 by Kym K - mbcomms: V2.2, changing structures to new module-allowing architecture, changed the style adding engine structures --->

<!--- 
 --->
<cfsetting enablecfoutputonly="Yes">
<cfif NOT IsDefined("thisTag.executionMode")>
	<cfabort showerror="Must be called as customtag.">
</cfif>
<cfif thisTag.executionMode IS "start">
	<!--- all the attribute, the common one first, then alpha, not all may apply --->
	<cfparam name="attributes.StyleSheet" type="string" default="">	<!--- the style sheet to insert in the head, full filename, rel path --->
	<cfparam name="attributes.Place" type="string" default="After">	<!--- where to insert in the head, before or after the template's html --->

	<cfset thisTag.OurContent = "" />	<!--- this will store the output which we want to be nothing --->
	
	<!--- if we have a stylesheet to add then add it to the list to put in the head tag in the source html --->
	<cfif attributes.StyleSheet neq "">
		<cfif attributes.Place eq "After">
			<cfif not ListFindNoCase(request.SLCMS.PageParams.HeadContent.End.FileList, "#session.SLCMS.forms.CurrentFormURL#TemplateControl/#attributes.StyleSheet#")> <!--- make sure we don't add it twice --->
				<cfset thisTag.ret = ArrayAppend(request.SLCMS.PageParams.HeadContent.End.Strings, '<link rel="stylesheet" href="#session.SLCMS.forms.CurrentFormURL#TemplateControl/#attributes.StyleSheet#" type="text/css">') />
				<cfset request.SLCMS.PageParams.HeadContent.End.FileList = ListAppend(request.SLCMS.PageParams.HeadContent.End.FileList, "#session.SLCMS.forms.CurrentFormURL#TemplateControl/#attributes.StyleSheet#") />
			</cfif>
		<cfelse>
			<cfif not ListFindNoCase(request.SLCMS.PageParams.HeadContent.Start.FileList, "#session.SLCMS.forms.CurrentFormURL#TemplateControl/#attributes.StyleSheet#")>
				<cfset thisTag.ret = ArrayAppend(request.SLCMS.PageParams.HeadContent.Start.Strings, '<link rel="stylesheet" href="#session.SLCMS.forms.CurrentFormURL#TemplateControl/#attributes.StyleSheet#" type="text/css">') />
				<cfset request.SLCMS.PageParams.HeadContent.Start.FileList = ListAppend(request.SLCMS.PageParams.HeadContent.Start.FileList, "#session.SLCMS.forms.CurrentFormURL#TemplateControl/#attributes.StyleSheet#") />
			</cfif>
		</cfif>
	</cfif>

</cfif>	<!--- end: tag execution mode is start --->

<cfsetting enablecfoutputonly="No">
<cfif NOT thisTag.hasEndTag>
<cfabort showerror="Missing end tag.">
<cfelseif thisTag.executionMode IS "end">
<cfset thisTag.GeneratedContent = "" /><cfoutput>#thisTag.OurContent#</cfoutput></cfif>
