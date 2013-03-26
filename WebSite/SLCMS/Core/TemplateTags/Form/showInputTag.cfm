<!--- SLCMS base tags to be used in template pages  --->
<!--- &copy; 2009 mort bay communications --->
<!---  --->
<!--- custom tag to display a form input field --->
<!--- 
			this tags's output replicates the html of a standard form input tag plus processes things from an SLCMS perspective
			All the attributes that a standard HTML input tag takes are here plus a few for validation, etc
		  --->
<!--- created:  10th Sep 2008 by Kym K, mbcomms from standard blank tag in FormTags --->
<!--- modified: 10th Sep 2008 - 14th Sep 2008 by Kym K, mbcomms - initial work --->
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
	<cfparam name="attributes.AllowBlank" type="string" default="Yes">	<!--- whether a blank string is allowed --->
	<cfparam name="attributes.Required" type="string" default="No">	<!--- just that --->
	<cfparam name="attributes.Class_RequiredField" type="string" default="RequiredField">	<!--- just that --->
	<cfparam name="attributes.Class_FieldValidationFailed" type="string" default="FieldValidationFailed">	<!--- just that --->
	<!--- all the attribute, the common one first, then alpha, not all may apply --->
	<cfparam name="attributes.type" type="string" default="">	<!--- the type of input, one of: text|password|checkbox|radio|submit|reset|file|hidden|image|button --->
	<cfparam name="attributes.Name" type="string" default="">	<!--- field name as passed back in form vars --->
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
	<!--- clean up the input flags so any attribute input style will work --->
	<cftry>
		<cfset thisTag.Controls.IsRequired = yesNoFormat(attributes.Required) />
		<cfset thisTag.Controls.BlankAllowed = yesNoFormat(attributes.AllowBlank) />
		<cfset thisTag.Controls.IsDisabled = yesNoFormat(attributes.disabled) />
		<cfset thisTag.Controls.ReadOnly = yesNoFormat(attributes.readonly) />
	<cfcatch type="any">
		<cfthrow detail="AllowBlank attribute was: #attributes.AllowBlank#. Required attribute was: #attributes.Required#" message="Invalid Flag attribute" />
	</cfcatch>
	</cftry>
	<cfif thisTag.Controls.IsRequired>
		<cfset thisTag.Controls.BlankAllowed = False />
	</cfif>
	<!--- check for a valid input type --->
	<cfif ListFindNoCase("text|password|checkbox|radio|submit|reset|file|hidden|image|button", attributes.type, "|")>
		<cfset thisTag.Controls.InputType = attributes.type />
	<cfelse>
		<cfthrow detail="type attribute was: #attributes.type#" message="Invalid Type attribute" />
	</cfif>
	<!--- then tidy up our parameters --->
	<cfset thisTag.Controls.name = trim(attributes.Name) />	<!--- keep things neat and tidy --->
	<cfif thisTag.Controls.name eq "">
		<cfthrow detail="No field name" message="No Name Supplied" />
	<cfelseif (not reFindNoCase("[[:alpha:]]", left(thisTag.Controls.name,1))) or findOneOf("/:.'\ -,", thisTag.Controls.name) or find("""", thisTag.Controls.name)>
		<cfthrow detail="Invalid Field Name" message="Field Name Supplied was Invalid, it was: #thisTag.Controls.name#" />
	</cfif>
	<cfset thisTag.Controls.Size = trim(attributes.Size) />	<!--- the size/maxlength combo tells us how big to make the database fields tell us --->
	<cfif thisTag.Controls.Size neq "" and not isNumeric(thisTag.Controls.Size)>
		<cfthrow detail="Size attribute incorrect" message="Field size attribute is not numeric" />
	</cfif>
	<cfset thisTag.Controls.MaxLength = trim(attributes.maxlength) />
	<cfif thisTag.Controls.MaxLength neq "" and not isNumeric(thisTag.Controls.MaxLength)>
		<cfthrow detail="MaxLength attribute incorrect" message="Field MaxLength attribute is not numeric" />
	</cfif>

	<!--- grab in the passed value as we might have to process it --->
	<cfset thisTag.FieldValue = attributes.value />
	
	<!--- then the database related bits of work --->
	<cfset thisTag.Controls.DatabaseFieldName = thisTag.Controls.name />
	<!--- and work out what type of Field to add into the database table --->	
	<cfif ListFindNoCase("text|password|hidden", thisTag.Controls.InputType, "|")>	<!--- its a simple text input field so we will be storing a varchar or memo if its long --->
		<cfset thisTag.Controls.DatabaseFieldSize = thisTag.Controls.Size />	<!--- see which is the bigger number --->
		<cfif thisTag.Controls.MaxLength gt thisTag.Controls.DatabaseFieldSize>
			<cfset thisTag.Controls.DatabaseFieldSize = thisTag.Controls.MaxLength />
		</cfif>
		<cfif thisTag.Controls.DatabaseFieldSize lte 4000>
			<cfset thisTag.Controls.DatabaseFieldSize = 4000 />
			<cfset thisTag.Controls.DatabaseFieldType = "varChar" />
		<cfelse>
			<cfset thisTag.Controls.DatabaseFieldSize = "" />
			<cfset thisTag.Controls.DatabaseFieldType = "memo" />
		</cfif>
	<cfelseif ListFindNoCase("checkbox|radio", thisTag.Controls.InputType, "|")>
		<cfset thisTag.Controls.DatabaseFieldSize = Len(thisTag.FieldValue) />
		<cfset thisTag.Controls.DatabaseFieldType = "varChar" />
	<cfelseif thisTag.Controls.InputType eq "File">
		<cfset thisTag.Controls.DatabaseFieldSize = "255" />
		<cfset thisTag.Controls.DatabaseFieldType = "varChar" />
	<cfelse>
		<cfset thisTag.Controls.DatabaseFieldSize = "" />
		<cfset thisTag.Controls.DatabaseFieldType = "" />
	</cfif>
	
	<!--- and validation forces for certain input types --->
<!--- 
	<cfif thisTag.Controls.InputType eq "File">
		<cfset thisTag.Controls.IsRequired = "Yes" />
		<cfset thisTag.Controls.BlankAllowed = "No" />
	</cfif>
 --->	
	<!--- now we have all our params store the validation stuff in the session so it can be processed after form submission --->
	<cfif not ListFindNoCase("submit|reset", thisTag.Controls.InputType, "|")>	<!--- skip the meaningless fields --->
		<!--- we keep in the session scope just enuf to know what we are doing. Everything else is not session-specific but form-specific so goes in our application.SLCMS.Sites["Site_#request.SLCMS.PageParams.SubSiteID#"].FormDetails structure --->	
		<cfif not StructKeyExists(session.SLCMS.forms["#session.SLCMS.forms.CurrentForm#"].Fields, "#thisTag.Controls.name#")>
			<!--- if it is the first hit for this form create all the stufffff we need --->
			<cfset session.SLCMS.forms["#session.SLCMS.forms.CurrentForm#"].Fields["#thisTag.Controls.name#"] = StructNew() />	<!--- store for our flags --->
			<cfset session.SLCMS.forms["#session.SLCMS.forms.CurrentForm#"].Fields["#thisTag.Controls.name#"].Value = thisTag.FieldValue />	<!--- will be the data in our validation failed rentry --->
			<cfset session.SLCMS.forms["#session.SLCMS.forms.CurrentForm#"].Fields["#thisTag.Controls.name#"].FileUploaded = False />	<!--- flag for fields that have a file upload --->
			<cfset session.SLCMS.forms["#session.SLCMS.forms.CurrentForm#"].Fields["#thisTag.Controls.name#"].FileUploaded_FinalFilename = "" />	<!--- filename as stored by cffile (could be renamed) --->
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
						<cfset application.SLCMS.Sites["Site_#request.SLCMS.PageParams.SubSiteID#"].FormDetails["#session.SLCMS.forms.CurrentForm#"].Fields["#thisTag.Controls.name#"].Database.FieldType = thisTag.Controls.DatabaseFieldType />	<!--- what sort of field, string, bit, whatever --->
						<cfset application.SLCMS.Sites["Site_#request.SLCMS.PageParams.SubSiteID#"].FormDetails["#session.SLCMS.forms.CurrentForm#"].Fields["#thisTag.Controls.name#"].Database.FieldSize = thisTag.Controls.DatabaseFieldSize />	<!--- size of field if relevant --->
						<cfset application.SLCMS.Sites["Site_#request.SLCMS.PageParams.SubSiteID#"].FormDetails["#session.SLCMS.forms.CurrentForm#"].Fields["#thisTag.Controls.name#"].Validation = StructNew() />	<!--- store for our flags --->
						<cfset application.SLCMS.Sites["Site_#request.SLCMS.PageParams.SubSiteID#"].FormDetails["#session.SLCMS.forms.CurrentForm#"].Fields["#thisTag.Controls.name#"].Validation.Required = thisTag.Controls.IsRequired />	<!--- is this field required? --->
						<cfset application.SLCMS.Sites["Site_#request.SLCMS.PageParams.SubSiteID#"].FormDetails["#session.SLCMS.forms.CurrentForm#"].Fields["#thisTag.Controls.name#"].Validation.BlankAllowed = thisTag.Controls.BlankAllowed />	<!--- empty field allowed? --->
						<cfset application.SLCMS.Sites["Site_#request.SLCMS.PageParams.SubSiteID#"].FormDetails["#session.SLCMS.forms.CurrentForm#"].Fields["#thisTag.Controls.name#"].Validation.ValidateType = trim(attributes.validate) />	<!--- what to validate against --->
						<cfset application.SLCMS.Sites["Site_#request.SLCMS.PageParams.SubSiteID#"].FormDetails["#session.SLCMS.forms.CurrentForm#"].FieldList = ListAppend(application.SLCMS.Sites["Site_#request.SLCMS.PageParams.SubSiteID#"].FormDetails["#session.SLCMS.forms.CurrentForm#"].FieldList, thisTag.Controls.name) />	<!--- add to the list of fields in the form --->
						<cfset application.SLCMS.Sites["Site_#request.SLCMS.PageParams.SubSiteID#"].FormDetails["#session.SLCMS.forms.CurrentForm#"].Status.FieldisNewList = ListAppend(application.SLCMS.Sites["Site_#request.SLCMS.PageParams.SubSiteID#"].FormDetails["#session.SLCMS.forms.CurrentForm#"].Status.FieldisNewList, "#thisTag.Controls.name#") />	<!--- The list of fields that need changing in the form --->
						<!--- add to "validation required" list if needs be --->
						<cfif trim(attributes.validate) neq "" or thisTag.Controls.IsRequired or not thisTag.Controls.BlankAllowed>
							<cfset application.SLCMS.Sites["Site_#request.SLCMS.PageParams.SubSiteID#"].FormDetails["#session.SLCMS.forms.CurrentForm#"].FieldValidationNeededList = ListAppend(application.SLCMS.Sites["Site_#request.SLCMS.PageParams.SubSiteID#"].FormDetails["#session.SLCMS.forms.CurrentForm#"].FieldValidationNeededList, thisTag.Controls.name) />	<!--- add to the list of fields we need to process --->
						</cfif>
						<!--- flag if it is a file type so we can change the form encoding --->
						<cfif thisTag.Controls.InputType eq "File">
							<cfset application.SLCMS.Sites["Site_#request.SLCMS.PageParams.SubSiteID#"].FormDetails["#session.SLCMS.forms.CurrentForm#"].flagFileFieldUsed = True />	<!--- we have a file (upload) field in the form --->
						</cfif>
					</cfif>
				</cflock>
			<cfelse>
				<cflock name="FormDetailSet_Inner" type="Exclusive" timeout="10">	<!--- inner part of double lock to set this so we don't get overlapping setting --->
					<!--- it did exist so compare our details to see if we need to change the database --->
					<cfif thisTag.Controls.DatabaseFieldSize gt application.SLCMS.Sites["Site_#request.SLCMS.PageParams.SubSiteID#"].FormDetails["#session.SLCMS.forms.CurrentForm#"].Fields["#thisTag.Controls.name#"].Database.FieldSize>
						<!--- the form field size spec got bigger so flag that --->
						<cfset application.SLCMS.Sites["Site_#request.SLCMS.PageParams.SubSiteID#"].FormDetails["#session.SLCMS.forms.CurrentForm#"].Status.flagChanged = True />
						<cfset application.SLCMS.Sites["Site_#request.SLCMS.PageParams.SubSiteID#"].FormDetails["#session.SLCMS.forms.CurrentForm#"].Status.FieldSizeGrewList = ListAppend(application.SLCMS.Sites["Site_#request.SLCMS.PageParams.SubSiteID#"].FormDetails["#session.SLCMS.forms.CurrentForm#"].Status.FieldSizeGrewList, "#thisTag.Controls.name#") />	<!--- The list of fields that need changing in the form --->
					</cfif>
					<!--- flag if it is a file type so we can change the form encoding --->
					<cfif thisTag.Controls.InputType eq "File">
						<cfset application.SLCMS.Sites["Site_#request.SLCMS.PageParams.SubSiteID#"].FormDetails["#session.SLCMS.forms.CurrentForm#"].flagFileFieldUsed = True />	<!--- we have a file (upload) field in the form --->
					</cfif>
				</cflock>
			</cfif>
		</cflock>
	</cfif>
	<!--- now we have our application scope --->
	<!--- now we generate the content --->
	<cfset thisTag.OurContent = "" />	<!--- this will store the output --->
	<cfif ListFindNoCase("text|password|hidden|checkbox|radio|submit|reset|file", thisTag.Controls.InputType, "|")>
		<cfset thisTag.OurContent = '<input type="#attributes.type#" name="#thisTag.Controls.name#" value="#thisTag.FieldValue#"' />
	<cfelseif thisTag.Controls.InputType eq "button">
		<cfset thisTag.OurContent = '<input type="button" value="#thisTag.FieldValue#"' />
	<cfelseif thisTag.Controls.InputType eq "image">
		<cfset thisTag.OurContent = '<input type="image" name="#thisTag.Controls.name#" value="#thisTag.FieldValue#" scr="#attributes.src#"' />
	<cfelseif thisTag.Controls.InputType eq "xxx">
		<cfset thisTag.OurContent = '<input type="xxx" name="#thisTag.Controls.name#" value="#thisTag.FieldValue#"' />
	</cfif>
	<cfif thisTag.Controls.InputType eq "text" or thisTag.Controls.InputType eq "password">
		<cfif len(attributes.size)><cfset thisTag.OurContent = thisTag.OurContent & ' size="#thisTag.Controls.Size#"' /></cfif>
		<cfif len(attributes.maxlength)><cfset thisTag.OurContent = thisTag.OurContent & ' maxlength="#thisTag.Controls.MaxLength#"' /></cfif>
	</cfif>
	<cfif thisTag.Controls.IsDisabled><cfset thisTag.OurContent = thisTag.OurContent & ' disabled' /></cfif>
	<cfif thisTag.Controls.ReadOnly><cfset thisTag.OurContent = thisTag.OurContent & ' ReadOnly' /></cfif>
	<cfif len(attributes.id)><cfset thisTag.OurContent = thisTag.OurContent & ' id="#attributes.id#"' /></cfif>
	<cfif len(attributes.class)><cfset thisTag.OurContent = thisTag.OurContent & ' class="#attributes.class#"' /></cfif>
	<cfif len(attributes.style)><cfset thisTag.OurContent = thisTag.OurContent & ' style="#attributes.style#"' /></cfif>
	<cfif len(attributes.onblur)><cfset thisTag.OurContent = thisTag.OurContent & ' onchange="#attributes.onblur#"' /></cfif>
	<cfif len(attributes.onchange)><cfset thisTag.OurContent = thisTag.OurContent & ' onchange="#attributes.onchange#"' /></cfif>
	<cfif len(attributes.onfocus)><cfset thisTag.OurContent = thisTag.OurContent & ' onchange="#attributes.onfocus#"' /></cfif>
	<cfif len(attributes.onselect)><cfset thisTag.OurContent = thisTag.OurContent & ' onchange="#attributes.onselect#"' /></cfif>
	<cfset thisTag.OurContent = thisTag.OurContent & '>' />
	<!--- now tack on the validation stuff --->
	<cfif not ListFindNoCase("submit|reset", thisTag.Controls.InputType, "|")>	<!--- skip the meaningless fields --->
		<cfif thisTag.Controls.IsRequired>
			<cfset thisTag.OurContent = thisTag.OurContent & '<span class="#attributes.Class_RequiredField#">*</span>' />
		</cfif>
		<cfif trim(attributes.validate) neq "" or thisTag.Controls.IsRequired or thisTag.Controls.BlankAllowed>
			<cfif not session.SLCMS.forms["#session.SLCMS.forms.CurrentForm#"].Fields["#thisTag.Controls.name#"].ValidationOK>
				<cfset thisTag.OurContent = thisTag.OurContent & '<span class="#attributes.Class_FieldValidationFailed#">#session.SLCMS.forms["#session.SLCMS.forms.CurrentForm#"].Fields["#thisTag.Controls.name#"].ValidationFailReason#</span>' />
			</cfif>
		</cfif>
	</cfif>
</cfif>	<!--- end: tag execution mode is start --->

<cfif NOT thisTag.hasEndTag>
	<cfabort showerror="Missing end tag.">
<cfelseif thisTag.executionMode IS "end">
	<cfset thisTag.GeneratedContent = "" /><cfoutput>#thisTag.OurContent#</cfoutput></cfif>