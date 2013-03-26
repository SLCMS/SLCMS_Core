<!--- SLCMS base tags to be used in template pages  --->
<!--- &copy; 2009 mort bay communications --->
<!---  --->
<!--- custom tag to display a form text area --->
<!--- 
			this tags's output replicates the html of a standard form input tag plus processes things from an SLCMS perspective
			All the attributes that a standard HTML input tag takes are here plus a few for validation, etc
		  --->
<!--- created:  11th Sep 2008 by Kym K, mbcomms from standard blank tag in FormTags --->
<!--- modified: 11th Sep 2008 - 15th Sep 2008 by Kym K, mbcomms - initial work --->
<!--- modified: 24th Sep 2008 - 24th Sep 2008 by Kym K, mbcomms - added code for form manager use, field lists, etc. --->
<!--- modified: 19th Nov 2009 - 19th Nov 2009 by Kym K - mbcomms: V2.2, refining and recoding for new sessions and portal structure changes --->

<!--- 
 --->
<cfif NOT IsDefined("thisTag.executionMode")>
	<cfabort showerror="Must be called as customtag.">
</cfif>
<cfif thisTag.executionMode IS "start">
	<!--- our attributes first --->
	<cfparam name="attributes.validate" type="string" default="">	<!--- no validation if null or validate to this type, one of: email|numeric|alpha|alphanumeric  --->
	<cfparam name="attributes.AllowBlank" type="string" default="">	<!--- whether a blank string is allowed --->
	<cfparam name="attributes.Required" type="string" default="No">	<!--- just that --->
	<cfparam name="attributes.Class_RequiredField" type="string" default="RequiredField">	<!--- just that --->
	<cfparam name="attributes.Class_FieldValidationFailed" type="string" default="FieldValidationFailed">	<!--- just that --->
	<!--- all the attribute, the common one first, then alpha, not all may apply --->
	<cfparam name="attributes.Name" type="string" default="">	<!--- form name as passed back in form vars --->
	<cfparam name="attributes.rows" type="string" default="">	<!--- height of text area (width in chars) --->
	<cfparam name="attributes.cols" type="string" default="">	<!--- width in chars --->
	<cfparam name="attributes.value" type="string" default="">	<!--- value param, text to display or whatever --->
	<cfparam name="attributes.id" type="string" default="">	<!--- id for styling, DOM, etc --->
	<cfparam name="attributes.style" type="string" default="">	<!--- inline styling --->
	<cfparam name="attributes.disabled" type="string" default="">	<!--- input disabled --->
	<cfparam name="attributes.readonly" type="string" default="">	<!--- read only field --->
	<cfparam name="attributes.title" type="string" default="">	<!--- tooltip --->
	<!--- then the javascript ones --->
	<cfparam name="attributes.onchange" type="string" default="">	<!---  --->
	<cfparam name="attributes.onblur" type="string" default="">	<!---  --->
	<cfparam name="attributes.onfocus" type="string" default="">	<!---  --->
	<cfparam name="attributes.onselect" type="string" default="">	<!---  --->

	<cfset thisTag.Controls = StructNew() />	<!--- keep flags and things neat and tidy --->
	<!--- a clean up the input flags so any attribute input style will work --->
	<cftry>
		<cfset thisTag.Controls.IsRequired = yesNoFormat(attributes.Required) />
		<cfset thisTag.Controls.BlankAllowed = yesNoFormat(attributes.AllowBlank) />
		<cfset thisTag.Controls.IsDisabled = yesNoFormat(attributes.disabled) />
		<cfset thisTag.Controls.ReadOnly = yesNoFormat(attributes.readonly) />
	<cfcatch type="any">
		<cfthrow detail="AllowBlank attribute was: #attributes.AllowBlank#. Required attribute was: #attributes.Required#" message="Invalid Flag attribute" />
	</cfcatch>
	</cftry>
	<!--- then tidy up our parameters --->
	<cfset thisTag.Controls.name = trim(attributes.Name) />	<!--- keep things neat and tidy --->
	<cfset thisTag.Controls.rows = trim(attributes.rows) />	<!--- keep things neat and tidy --->
	<cfset thisTag.Controls.cols = trim(attributes.cols) />	<!--- keep things neat and tidy --->
	<cfif thisTag.Controls.name eq "">
		<cfthrow detail="No field name" message="No Name Supplied" />
	<cfelseif (not reFindNoCase("[[:alpha:]]", left(thisTag.Controls.name,1))) or findOneOf("/:.' \-,", thisTag.Controls.name) or find("""", thisTag.Controls.name)>
		<cfthrow detail="Invalid Field Name" message="Field Name Supplied was Invalid, it was: #thisTag.Controls.name#" />
	</cfif>
	<cfif not (len(thisTag.Controls.rows) and IsNumeric(thisTag.Controls.rows))>
		<cfthrow detail="rows attribute was: #attributes.rows#" message="Invalid rows attribute" />
	</cfif>
	<cfif not (len(thisTag.Controls.cols) and IsNumeric(thisTag.Controls.cols))>
		<cfthrow detail="cols attribute was: #attributes.cols#" message="Invalid cols attribute" />
	</cfif>
	<!--- then grab in the passed value as we might have to process it --->
	<cfset thisTag.FieldValue = attributes.value />
	<!--- then the database related bits of work --->
	<cfset thisTag.Controls.DatabaseFieldName = thisTag.Controls.name />

	<!--- now we have all our params store the validation stuff in the session so it can be processed after form submission --->
	<!--- we keep in the session scope just enuf to know what we are doing. Everything else is not session-specific but form-specific so goes in our application.SLCMS.Sites["Site_#request.SLCMS.PageParams.SubSiteID#"].FormDetails structure --->	
	<cfif not StructKeyExists(session.SLCMS.forms["#session.SLCMS.forms.CurrentForm#"].Fields, "#thisTag.Controls.name#")>
		<!--- if it is the first hit for this form create all the stufffff we need --->
		<cfset session.SLCMS.forms["#session.SLCMS.forms.CurrentForm#"].Fields["#thisTag.Controls.name#"] = StructNew() />	<!--- store for our flags --->
		<cfset session.SLCMS.forms["#session.SLCMS.forms.CurrentForm#"].Fields["#thisTag.Controls.name#"].Value = thisTag.FieldValue />	<!--- will be the data in our validation failed rentry --->
		<cfset session.SLCMS.forms["#session.SLCMS.forms.CurrentForm#"].Fields["#thisTag.Controls.name#"].ValidationOK = True />	<!--- did it validate --->
		<cfset session.SLCMS.forms["#session.SLCMS.forms.CurrentForm#"].Fields["#thisTag.Controls.name#"].ValidationFailReason = "" />	<!--- why it failed --->
	<cfelse>
		<!--- the struct exists so we must be coming in from a failed validation or some such --->
		<cfset thisTag.FieldValue = session.SLCMS.forms["#session.SLCMS.forms.CurrentForm#"].Fields["#thisTag.Controls.name#"].Value /> <!--- change the value to the entered one from last time --->
	</cfif>
	<!--- now we set up the rest of the data storage in the app scope --->
	<!--- now the field --->
	<cflock name="FormDetailSet_Outer" type="readonly" timeout="10">	<!--- do our usual double lock to set this so we don't get overlapping setting --->
		<cfif not StructKeyExists(application.SLCMS.Sites["Site_#request.SLCMS.PageParams.SubSiteID#"].FormDetails["#session.SLCMS.forms.CurrentForm#"].Fields, "#thisTag.Controls.name#")>
			<cflock name="FormDetailSet_Inner" type="Exclusive" timeout="10">	<!--- inner part of double lock to set this so we don't get overlapping setting --->
				<cfif not StructKeyExists(application.SLCMS.Sites["Site_#request.SLCMS.PageParams.SubSiteID#"].FormDetails["#session.SLCMS.forms.CurrentForm#"].Fields, "#thisTag.Controls.name#")>
					<cfset application.SLCMS.Sites["Site_#request.SLCMS.PageParams.SubSiteID#"].FormDetails["#session.SLCMS.forms.CurrentForm#"].Status.flagChanged = True />
					<cfset application.SLCMS.Sites["Site_#request.SLCMS.PageParams.SubSiteID#"].FormDetails["#session.SLCMS.forms.CurrentForm#"].Fields["#thisTag.Controls.name#"] = StructNew()>
					<cfset application.SLCMS.Sites["Site_#request.SLCMS.PageParams.SubSiteID#"].FormDetails["#session.SLCMS.forms.CurrentForm#"].Fields["#thisTag.Controls.name#"].Database = StructNew() />	<!--- store for our flags --->
					<cfset application.SLCMS.Sites["Site_#request.SLCMS.PageParams.SubSiteID#"].FormDetails["#session.SLCMS.forms.CurrentForm#"].Fields["#thisTag.Controls.name#"].Database.FieldName = thisTag.Controls.DatabaseFieldName />	<!--- Name of the field --->
					<cfset application.SLCMS.Sites["Site_#request.SLCMS.PageParams.SubSiteID#"].FormDetails["#session.SLCMS.forms.CurrentForm#"].Fields["#thisTag.Controls.name#"].Database.FieldType = "memo" />	<!--- what sort of field, string, bit, whatever --->
					<cfset application.SLCMS.Sites["Site_#request.SLCMS.PageParams.SubSiteID#"].FormDetails["#session.SLCMS.forms.CurrentForm#"].Fields["#thisTag.Controls.name#"].Database.FieldSize = "" />	<!--- size of field if relevant --->
					<cfset application.SLCMS.Sites["Site_#request.SLCMS.PageParams.SubSiteID#"].FormDetails["#session.SLCMS.forms.CurrentForm#"].Fields["#thisTag.Controls.name#"].Validation = StructNew() />	<!--- store for our flags --->
					<cfset application.SLCMS.Sites["Site_#request.SLCMS.PageParams.SubSiteID#"].FormDetails["#session.SLCMS.forms.CurrentForm#"].Fields["#thisTag.Controls.name#"].Validation.Required = thisTag.Controls.IsRequired />	<!--- is this field required? --->
					<cfset application.SLCMS.Sites["Site_#request.SLCMS.PageParams.SubSiteID#"].FormDetails["#session.SLCMS.forms.CurrentForm#"].Fields["#thisTag.Controls.name#"].Validation.BlankAllowed = thisTag.Controls.BlankAllowed />	<!--- empty field allowed? --->
					<cfset application.SLCMS.Sites["Site_#request.SLCMS.PageParams.SubSiteID#"].FormDetails["#session.SLCMS.forms.CurrentForm#"].Fields["#thisTag.Controls.name#"].Validation.ValidateType = trim(attributes.validate) />	<!--- what to validate against --->
					<cfset application.SLCMS.Sites["Site_#request.SLCMS.PageParams.SubSiteID#"].FormDetails["#session.SLCMS.forms.CurrentForm#"].FieldList = ListAppend(application.SLCMS.Sites["Site_#request.SLCMS.PageParams.SubSiteID#"].FormDetails["#session.SLCMS.forms.CurrentForm#"].FieldList, thisTag.Controls.name) />	<!--- add to the list of fields in the form --->
					<cfset application.SLCMS.Sites["Site_#request.SLCMS.PageParams.SubSiteID#"].FormDetails["#session.SLCMS.forms.CurrentForm#"].Status.FieldisNewList = ListAppend(application.SLCMS.Sites["Site_#request.SLCMS.PageParams.SubSiteID#"].FormDetails["#session.SLCMS.forms.CurrentForm#"].Status.FieldisNewList, "#thisTag.Controls.name#") />	<!--- The list of fields that need changing in the form --->
					<cfif trim(attributes.validate) neq "" or thisTag.Controls.IsRequired or not thisTag.Controls.BlankAllowed>
						<cfset application.SLCMS.Sites["Site_#request.SLCMS.PageParams.SubSiteID#"].FormDetails["#session.SLCMS.forms.CurrentForm#"].FieldValidationNeededList = ListAppend(application.SLCMS.Sites["Site_#request.SLCMS.PageParams.SubSiteID#"].FormDetails["#session.SLCMS.forms.CurrentForm#"].FieldValidationNeededList, thisTag.Controls.name) />	<!--- add to the list of fields we need to process --->
					</cfif>
				<cfelse>
					<!--- it did exist so compare our details to see if we need to change the database --->
					<!--- 
					<cfif thisTag.Controls.DatabaseFieldSize gt application.SLCMS.Sites["Site_#request.SLCMS.PageParams.SubSiteID#"].FormDetails["#session.SLCMS.forms.CurrentForm#"].Fields["#thisTag.Controls.name#"].Database.FieldSize>
						<!--- the form field size spec got bigger so flag that --->
						<cfset application.SLCMS.Sites["Site_#request.SLCMS.PageParams.SubSiteID#"].FormDetails["#session.SLCMS.forms.CurrentForm#"].Status.FieldSizeGrewList = ListAppend(application.SLCMS.Sites["Site_#request.SLCMS.PageParams.SubSiteID#"].FormDetails["#session.SLCMS.forms.CurrentForm#"].Status.FieldSizeGrewList, "#thisTag.Controls.name#") />	<!--- The list of fields that need changing in the form --->
						<cfset application.SLCMS.Sites["Site_#request.SLCMS.PageParams.SubSiteID#"].FormDetails["#session.SLCMS.forms.CurrentForm#"].Status.flagChanged = True />
					</cfif>
					 --->
				</cfif>
			</cflock>
		</cfif>
	</cflock>

<!--- 
	<!--- now we have all our params store the validation stuff in the session so it can be processed after form submission --->
	<cfif not StructKeyExists(session.SLCMS.forms["#session.SLCMS.forms.CurrentForm#"].Fields, "#thisTag.Controls.name#")>
		<!--- if it is the first hit for this form create all the stufffff we need --->
		<cfset session.SLCMS.forms["#session.SLCMS.forms.CurrentForm#"].Fields["#thisTag.Controls.name#"] = StructNew() />	<!--- store for our flags --->
		<cfset session.SLCMS.forms["#session.SLCMS.forms.CurrentForm#"].Fields["#thisTag.Controls.name#"].Value = "" />	<!--- will be the data in our validation failed rentry --->
		<cfset session.SLCMS.forms["#session.SLCMS.forms.CurrentForm#"].Fields["#thisTag.Controls.name#"].Database = StructNew() />	<!--- store for our flags --->
		<cfset session.SLCMS.forms["#session.SLCMS.forms.CurrentForm#"].Fields["#thisTag.Controls.name#"].Database.FieldName = thisTag.Controls.DatabaseFieldName />	<!--- Name of the field --->
		<cfset session.SLCMS.forms["#session.SLCMS.forms.CurrentForm#"].Fields["#thisTag.Controls.name#"].Database.FieldType = "memo" />	<!--- what sort of field, string, bit, whatever --->
		<cfset session.SLCMS.forms["#session.SLCMS.forms.CurrentForm#"].Fields["#thisTag.Controls.name#"].Database.FieldSize = "" />	<!--- size of field if relevant --->
		<cfset session.SLCMS.forms["#session.SLCMS.forms.CurrentForm#"].Fields["#thisTag.Controls.name#"].Validation = StructNew() />	<!--- store for our flags --->
		<cfset session.SLCMS.forms["#session.SLCMS.forms.CurrentForm#"].Fields["#thisTag.Controls.name#"].Validation.Needs = StructNew() />	<!--- store for our flags --->
		<cfset session.SLCMS.forms["#session.SLCMS.forms.CurrentForm#"].Fields["#thisTag.Controls.name#"].Validation.Needs.Required = thisTag.Controls.IsRequired />	<!--- is this field required? --->
		<cfset session.SLCMS.forms["#session.SLCMS.forms.CurrentForm#"].Fields["#thisTag.Controls.name#"].Validation.Needs.BlankAllowed = thisTag.Controls.BlankAllowed />	<!--- empty field allowed? --->
		<cfset session.SLCMS.forms["#session.SLCMS.forms.CurrentForm#"].Fields["#thisTag.Controls.name#"].Validation.Needs.ValidateType = trim(attributes.validate) />	<!--- what to validate against --->
		<cfset session.SLCMS.forms["#session.SLCMS.forms.CurrentForm#"].Fields["#thisTag.Controls.name#"].Validation.Results = StructNew() />	<!--- store for our result details --->
		<cfset session.SLCMS.forms["#session.SLCMS.forms.CurrentForm#"].Fields["#thisTag.Controls.name#"].Validation.Results.OK = True />	<!--- did it validate --->
		<cfset session.SLCMS.forms["#session.SLCMS.forms.CurrentForm#"].Fields["#thisTag.Controls.name#"].Validation.Results.FailReason = "" />	<!--- why it failed --->
		<cfset session.SLCMS.forms["#session.SLCMS.forms.CurrentForm#"].Fields.FieldList = ListAppend(session.SLCMS.forms["#session.SLCMS.forms.CurrentForm#"].Fields.FieldList, thisTag.Controls.name) />	<!--- add to the list of fields in the form --->
		<cfif trim(attributes.validate) neq "" or thisTag.Controls.IsRequired or not thisTag.Controls.BlankAllowed>
			<cfset session.SLCMS.forms["#session.SLCMS.forms.CurrentForm#"].Fields.ValidationNeededList = ListAppend(session.SLCMS.forms["#session.SLCMS.forms.CurrentForm#"].Fields.ValidationNeededList, thisTag.Controls.name) />	<!--- add to the list of fields we need to process --->
		</cfif>
	<cfelse>
		<!--- the struct exists so we must be coming in from a failed validation or some such --->
		<cfset thisTag.FieldValue = session.SLCMS.forms["#session.SLCMS.forms.CurrentForm#"].Fields["#thisTag.Controls.name#"].Value /> <!--- change the value to the entered one from last time --->
	</cfif>
 --->
	<!--- now we generate the content --->
	<cfset thisTag.OurContent = "" />	<!--- this will store the output --->
	<cfset thisTag.OurContent = '<textarea name="#thisTag.Controls.name#" rows="#attributes.rows#" cols="#attributes.cols#"' />
	<cfif len(attributes.id)><cfset thisTag.OurContent = thisTag.OurContent & ' id="#attributes.id#"' /></cfif>
	<cfif len(attributes.style)><cfset thisTag.OurContent = thisTag.OurContent & ' style="#attributes.style#"' /></cfif>
	<cfif thisTag.Controls.IsDisabled><cfset thisTag.OurContent = thisTag.OurContent & ' disabled' /></cfif>
	<cfif thisTag.Controls.ReadOnly><cfset thisTag.OurContent = thisTag.OurContent & ' ReadOnly' /></cfif>
	<cfif len(attributes.onblur)><cfset thisTag.OurContent = thisTag.OurContent & ' onchange="#attributes.onblur#"' /></cfif>
	<cfif len(attributes.onchange)><cfset thisTag.OurContent = thisTag.OurContent & ' onchange="#attributes.onchange#"' /></cfif>
	<cfif len(attributes.onfocus)><cfset thisTag.OurContent = thisTag.OurContent & ' onchange="#attributes.onfocus#"' /></cfif>
	<cfif len(attributes.onselect)><cfset thisTag.OurContent = thisTag.OurContent & ' onchange="#attributes.onselect#"' /></cfif>
	<cfset thisTag.OurContent = thisTag.OurContent & '>#thisTag.FieldValue#</textarea>' />
	<cfif thisTag.Controls.IsRequired>
		<cfset thisTag.OurContent = thisTag.OurContent & '<span class="#attributes.Class_RequiredField#">*</span>' />
	</cfif>
	<cfif trim(attributes.validate) neq "" or thisTag.Controls.IsRequired or thisTag.Controls.BlankAllowed>
		<cfif not session.SLCMS.forms["#session.SLCMS.forms.CurrentForm#"].Fields["#thisTag.Controls.name#"].ValidationOK>
			<cfset thisTag.OurContent = thisTag.OurContent & '<span class="#attributes.Class_FieldValidationFailed#">#session.SLCMS.forms["#session.SLCMS.forms.CurrentForm#"].Fields["#thisTag.Controls.name#"].ValidationFailReason#</span>' />
		</cfif>
	</cfif>
</cfif>	<!--- end: tag execution mode is start --->

<cfif NOT thisTag.hasEndTag>
	<cfabort showerror="Missing end tag.">
<cfelseif thisTag.executionMode IS "end">
	<cfset thisTag.GeneratedContent = "" /><cfoutput>#thisTag.OurContent#</cfoutput></cfif>