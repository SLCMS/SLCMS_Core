<!--- SLCMS base tags to be used in template pages  --->
<!--- &copy; 2009 mort bay communications --->
<!---  --->
<!--- custom tag to display a form item --->
<!--- 
			these tags's output replicates the html of a standard form input tag plus processes things fomr an SLCMS perspective
			All the attributes that a standard HTML for tag takes are here plus a few for validation, etc
		  --->
<!--- cloned:   10th Sep 2008 by Kym K, mbcomms from standard blank tag in TemplateTags --->
<!--- modified: 10th Sep 2008 - 10th Sep 2008 by Kym K, mbcomms - added a bunch of attributes which are going to be used in every tag --->

<!--- 
 --->
<cfsetting enablecfoutputonly="Yes">
<cfif NOT IsDefined("thisTag.executionMode")>
	<cfabort showerror="Must be called as customtag.">
</cfif>
<cfif thisTag.executionMode IS "start">
	<!--- our attributes first --->
	<cfparam name="attributes.validate" type="string" default="">	<!--- no validation if null or validate to this type, one of: email|numeric|alpha|alphanumeric  --->
	<cfparam name="attributes.AllowBlank" type="string" default="Yes">	<!--- whether a blank string is allowed --->
	<cfparam name="attributes.Required" type="string" default="No">	<!--- just that --->
	<!--- all the attribute, the common one first, then alpha, not all may apply --->
	<cfparam name="attributes.type" type="string" default="">	<!--- the type of input, one of: text|password|checkbox|radio|submit|reset|file|hidden|image|button --->
	<cfparam name="attributes.Name" type="string" default="">	<!--- form name as passed back in form vars --->
	<cfparam name="attributes.value" type="string" default="">	<!--- value param, text to display or whatever --->
	<cfparam name="attributes.id" type="string" default="">	<!--- id for styling, DOM, etc --->
	<cfparam name="attributes.class" type="string" default="">	<!--- class for styling --->
	<cfparam name="attributes.style" type="string" default="">	<!--- inline styling --->
	<cfparam name="attributes.accept" type="string" default="">	<!--- mime type to accept in file uploads --->
	<cfparam name="attributes.align" type="string" default="">	<!--- text alignment --->
	<cfparam name="attributes.alt" type="string" default="">	<!--- alt text for image --->
	<cfparam name="attributes.checked" type="string" default="">	<!---  --->
	<cfparam name="attributes.dir" type="string" default="">	<!--- text direction --->
	<cfparam name="attributes.disabled" type="string" default="">	<!--- input disabled --->
	<cfparam name="attributes.lang" type="string" default="">	<!--- language code --->
	<cfparam name="attributes.maxlength" type="string" default="">	<!--- length of allowed string --->
	<cfparam name="attributes.readonly" type="string" default="">	<!--- read only field --->
	<cfparam name="attributes.size" type="string" default="">	<!--- size of input field (width in chars) --->
	<cfparam name="attributes.src" type="string" default="">	<!--- URL of image to display --->
	<cfparam name="attributes.title" type="string" default="">	<!--- tooltip --->
	<!--- then the javascript ones --->
	<cfparam name="attributes.onchange" type="string" default="">	<!---  --->
	<cfparam name="attributes.onblur" type="string" default="">	<!---  --->
	<cfparam name="attributes.onfocus" type="string" default="">	<!---  --->
	<cfparam name="attributes.onselect" type="string" default="">	<!---  --->

	<cfset thisTag.Controls = StructNew() />	<!--- keep flags and things neat and tidy --->
	<!--- a clean up the input flags so any input style will work --->
	<cftry>
		<cfset thisTag.Controls.IsRequired = yesNoFormat(attributes.Required) />
		<cfset thisTag.Controls.BlankAllowed = yesNoFormat(attributes.AllowBlank) />
	<cfcatch type="any">
		<cfthrow detail="AllowBlank attribute was: #attributes.AllowBlank#. Required attribute was: #attributes.Required#" message="Invalid Flag attribute" />
	</cfcatch>
	</cftry>

</cfif>	<!--- end: tag execution mode is start --->

<!--- one version of an ending, can't use both --->
<cfif thisTag.executionMode IS "end">
	<!--- 
	<cfexit>	<!--- this allows for tags called with an XML form <cf_xxx /> ("start only" tags) to make sure there is no extra white space appended to the output, can be omitted --->
	 --->
<cfelseif NOT thisTag.hasEndTag>
	<cfabort showerror="Missing end tag.">
</cfif>
<cfsetting enablecfoutputonly="No">
<!--- the other, can't use both --->
<cfif NOT thisTag.hasEndTag>
<cfabort showerror="Missing end tag.">
<cfelseif thisTag.executionMode IS "end">
<cfset thisTag.GeneratedContent = "" /><cfoutput>#thisTag.OurContent#</cfoutput></cfif>
