<cfsetting enablecfoutputonly="Yes">
<!--- 
docs: startDescription
docs: SLCMS Core - base tags to be used in template pages
docs: &copy; 2012 mort bay communications
docs: custom tag to display or do something
docs: endDescription
docs: 
docs: startParams
docs:	Name: BlankTag
docs:	Type:	Custom Tag 
docs:	Role:	Content Display Tag - Core 
docs:	Hint: display something or other
docs:	Versions: Tag - 1.0.0; Core - 2.2.0+
docs: endParams
docs: 
docs: startAttributes
docs:	name="myStringAttribute" 	type="string" 	default=""			;	show something, this bit is free form
docs:	name="myIntAttribute" 		type="numeric" 	default="0"			;	a number, this bit is free form
docs:	name="myBoolAttribute" 		type="boolean" 	default="False"	;	flag something, this bit is free form
docs: endAttributes
docs: 
docs: startManual
docs: Describe it all here, as many lines as you want
docs: endManual
docs: 
docs: startHistory_Versions
docs: Version 1.0.0.0  : 	Base tag
docs: Version 1.0.0.383: 	added this documentation commenting system
docs: endHistory_Versions
docs:
docs: startHistory_Coding
docs:	created:  27th Jan 2008 by Kym K, mbcomms
docs:	modified: 20th Feb 2012 - 20th Feb 2012 by Kym K, mbcomms: updated to include the documentation engine notation
docs: endHistory_Coding
 --->

<cfif NOT IsDefined("thisTag.executionMode")>
	<cfabort showerror="Must be called as customtag.">
</cfif>
<cfif thisTag.executionMode IS "start">
	<cfparam name="attributes.myStringAttribute" type="string" default="">
	<cfparam name="attributes.myIntAttribute" type="numeric" default="0">
	<cfparam name="attributes.myBoolAttribute" type="boolean" default="False">

</cfif>	<!--- end: tag execution mode is start --->

<cfif thisTag.executionMode IS "end">
	<!--- 
	<cfexit>	<!--- this allows for tags called with an XML form <cf_xxx />, can be omitted --->
	 --->
<cfelseif NOT thisTag.hasEndTag>
	<cfabort showerror="Missing end tag.">
</cfif><!--- this tail stuff can be tickled to give zero whitespace if needed --->
<cfsetting enablecfoutputonly="No">