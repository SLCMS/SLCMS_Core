<!--- SLCMS base tags to be used in template pages  --->
<!--- &copy; mort bay communications --->
<!---  --->
<!--- custom tag to display a Form --->
<!--- this is the code for V2.1.0 upwards forms using a form tagset
			ie the html for the form is made by slcms tags inside a form template 
		  --->
<!--- created:   9th Sep 2009 by Kym K - mbcomms --->
<!--- modified:  9th Sep 2009 - 16th Sep 2009 by Kym K - mbcomms: did initial stuff --->
<!--- modified: 23rd Mar 2009 - 23rd Mar 2009 by Kym K - mbcomms: V2.2, changing structures to new module-allowing architecture, the core code is now just another module --->
<!--- modified: 29th Apr 2009 - 30th Apr 2009 by Kym K - mbcomms: V2.2, changing template folder structure to portal/sub-site architecture, sites inside the top site --->
<!--- modified: 19th Nov 2009 - 19th Nov 2009 by Kym K - mbcomms: V2.2, refining and recoding for new sessions and portal structure changes --->

<!--- 
 --->
<cfsetting enablecfoutputonly="Yes">
<cfif NOT IsDefined("thisTag.executionMode")>
	<cfabort showerror="Must be called as customtag.">
</cfif>
<cfif thisTag.executionMode IS "start">
	<cfparam name="attributes.formName" type="string" default="">	<!--- the name of the form files to show --->
	<cfparam name="attributes.objectName" type="string" default="">	<!--- the name of the form object to use --->

	<!--- set our flags --->
	<cfset thisTag.IsConfirmedShowResult = False>
	<cfset thisTag.IsValidatedShowResult = True>
	<cfset thisTag.IsAuthor = application.SLCMS.core.UserPermissions.IsAuthor() />	<!--- do we have authoring rights --->
	<cfset thisTag.IsEditor = application.SLCMS.core.UserPermissions.IsEditor() />	<!--- do we have edit rights --->
	
	<!--- process/validate our attributes --->
	<cfset thisTag.tempFN = trim(attributes.formName) /> <!--- save the short file name for testing --->
	<cfset thisTag.tempON = trim(attributes.objectName) /> <!--- save the object name for testing --->
	<cfif thisTag.tempFN eq "" and thisTag.tempON eq "">
		<cfthrow message="Oops! No Form has been Specified!" />
	<cfelseif thisTag.tempFN neq "" and thisTag.tempON neq "">
		<cfthrow message="Oops! Invalid Form Request! You cannnot ask for a form name and an object name at the same time." />
	<cfelse>
		<!--- now we have one or the other as a possible name --->
		<cfif thisTag.tempFN neq "" and thisTag.tempON eq "">
			<cfset thisTag.tempName = thisTag.tempFN /> <!--- save the short file name --->
			<cfset thisTag.tempMode = "File" /> <!--- set up the type --->
		<cfelse>
			<cfset thisTag.tempName = thisTag.tempON /> <!--- save the final name --->
			<cfset thisTag.tempMode = "Object" /> <!--- set up the type --->
		</cfif>
		<cfif ListLen(thisTag.tempName, "/") eq 3>
			<!--- we have a new architecture template so chop off the first part which is its home, "shared" or whatever --->
			<cfset thisTag.tempName = ListRest(thisTag.tempName, "/") />
		</cfif>
		<cfset thisTag.SetName = ListFirst(thisTag.tempName, "/") /> <!--- save the template set name --->
		<cfset thisTag.FilePartName = ListLast(thisTag.tempName, "/") /> <!--- save the template set name --->
		<!--- make its structures --->
		<cfif not StructKeyExists(session.SLCMS.forms, "#thisTag.tempName#")>
			<cfset session.SLCMS.forms["#thisTag.tempName#"] = StructNew() /> <!--- set up for this form (has this format as could be more than one form on the page) --->
			<cfset session.SLCMS.forms["#thisTag.tempName#"].formShortName = thisTag.tempName /> <!--- save the short name just in case --->
			<cfset session.SLCMS.forms["#thisTag.tempName#"].FilePartName = thisTag.FilePartName /> <!--- save the file part of the name just in case --->
			<cfset session.SLCMS.forms["#thisTag.tempName#"].CurrentAction = ""  />	<!--- set to first step, show the form --->
			<cfset session.SLCMS.forms["#thisTag.tempName#"].Fields = StructNew() />	<!--- store for our field definitions --->
			<cfset session.SLCMS.forms["#thisTag.tempName#"].Fields.FilesUploaded = StructNew() />	<!---tells us what has been uploaded for file fields --->
			<cfset session.SLCMS.forms["#thisTag.tempName#"].Fields.FilesUploaded.FieldList = ""  />	<!--- list of fields that had a succesful file upload --->
		</cfif>
		<cflock name="FormDetailSet_Outer" type="readonly" timeout="10">	<!--- do our usual double lock to set this so we don't get overlapping setting --->
			<cfif not StructKeyExists(application.SLCMS.Sites["Site_#request.SLCMS.pageParams.SubSiteID#"].FormDetails, "#thisTag.tempName#")>
				<cflock name="FormDetailSet_Inner" type="Exclusive" timeout="10">	<!--- inner part of double lock to set this so we don't get overlapping setting --->
					<cfif not StructKeyExists(application.SLCMS.Sites["Site_#request.SLCMS.PageParams.SubSiteID#"].FormDetails, "#thisTag.tempName#")>
						<cfset application.SLCMS.Sites["Site_#request.SLCMS.PageParams.SubSiteID#"].FormDetails["#thisTag.tempName#"] = StructNew()>
						<cfset application.SLCMS.Sites["Site_#request.SLCMS.PageParams.SubSiteID#"].FormDetails["#thisTag.tempName#"].flagFirstTimeIn = True />	<!--- flag that we have just created it --->
						<cfset application.SLCMS.Sites["Site_#request.SLCMS.PageParams.SubSiteID#"].FormDetails["#thisTag.tempName#"].FieldList = "" />	<!--- The list of fields in the form --->
						<cfset application.SLCMS.Sites["Site_#request.SLCMS.PageParams.SubSiteID#"].FormDetails["#thisTag.tempName#"].FieldValidationNeededList = "" />	<!--- The list of fields we need to validate --->
						<cfset application.SLCMS.Sites["Site_#request.SLCMS.PageParams.SubSiteID#"].FormDetails["#thisTag.tempName#"].flagFileFieldUsed = False />	<!--- if we have a file (upload) field in the form --->
						<cfset application.SLCMS.Sites["Site_#request.SLCMS.PageParams.SubSiteID#"].FormDetails["#thisTag.tempName#"].Fields = StructNew()>
						<cfset application.SLCMS.Sites["Site_#request.SLCMS.PageParams.SubSiteID#"].FormDetails["#thisTag.tempName#"].Status = StructNew()>
						<cfset application.SLCMS.Sites["Site_#request.SLCMS.PageParams.SubSiteID#"].FormDetails["#thisTag.tempName#"].Status.flagChanged = True />	<!--- The global flag that there has been a change, in this case it is a new form! --->
						<cfset application.SLCMS.Sites["Site_#request.SLCMS.PageParams.SubSiteID#"].FormDetails["#thisTag.tempName#"].Status.FieldChangedList = "" />	<!--- The list of fields in the form --->
						<cfset application.SLCMS.Sites["Site_#request.SLCMS.PageParams.SubSiteID#"].FormDetails["#thisTag.tempName#"].Status.FieldSizeGrewList = "" />	<!--- The list of fields that changed their size in the form --->
						<cfset application.SLCMS.Sites["Site_#request.SLCMS.PageParams.SubSiteID#"].FormDetails["#thisTag.tempName#"].Status.FieldisNewList = "" />	<!--- The list of fields that are new --->
					</cfif>
				</cflock>
			</cfif>
		</cflock>
		
		
		
<!--- 
		<!--- first off flag this one form as the current one, I hope we can't process two overlapping, that would be interesting --->
		<cfset session.SLCMS.forms.CurrentForm = thisTag.tempName />
		<cfset session.SLCMS.forms.CurrentMode = thisTag.tempMode />
		<cfset session.SLCMS.forms.CurrentAction = session.SLCMS.forms["#thisTag.tempName#"].CurrentAction />
 --->
		<!--- a special, the login form that does not have a processing page, it is all in Application.cfm --->
		<cfif thisTag.tempName eq "SLCMSLogin">
			<cfset session.SLCMS.forms["#thisTag.tempName#"].CurrentAction = ""  />	<!--- set to bring up first step always, show the form --->
		</cfif>
		<!--- work out the correct working mode --->
		<cfif (not StructKeyExists(form, "Sconfirmer")) or session.SLCMS.forms["#thisTag.tempName#"].CurrentAction eq "">
			<cfset session.SLCMS.forms["#thisTag.tempName#"].CurrentAction = "ShowForm"  />	<!--- set to first step, show the form --->
			<cfset session.SLCMS.forms["#thisTag.tempName#"].temp.errorCode = 0 />	<!--- clear our error flag --->
			<cfset session.SLCMS.forms["#thisTag.tempName#"].Confirmer = 'SLCMS#DateFormat(Now(), "YYYYMMDD")##session.SLCMS.forms["#thisTag.tempName#"].formShortName##TimeFormat(Now(),"HHmmss")#' />	<!--- this will help in trapping captcha bots --->
		<cfelseif StructKeyExists(form, "Sconfirmer") and (session.SLCMS.forms["#thisTag.tempName#"].CurrentAction eq "ShowForm" or session.SLCMS.forms["#thisTag.tempName#"].CurrentAction eq "ValidationFail")>	
			<cfset session.SLCMS.forms["#thisTag.tempName#"].CurrentAction = "Process"  />	<!--- set to second step, process the results --->
			<cfset session.SLCMS.forms["#thisTag.tempName#"].temp.errorCode = 0 />	<!--- clear our error flag --->
		<cfelse>
			<cfset session.SLCMS.forms["#thisTag.tempName#"].CurrentAction = "ShowForm"  />	<!--- set to first step, show the form --->
			<cfset session.SLCMS.forms["#thisTag.tempName#"].temp.errorCode = 256 />	<!--- set our error flag to major workflow oops! --->
		</cfif>
		<cfset session.SLCMS.forms.CurrentForm = thisTag.tempName  />	<!--- make what we are doing available in a scope that the form tags can find--->
		<cfset session.SLCMS.forms.CurrentAction = session.SLCMS.forms["#thisTag.tempName#"].CurrentAction  />	<!--- ditto --->
		<!--- now we know where we are at in a broad sense so we can choose what type of form to show and get into it --->
		<cfif thisTag.tempMode eq "File">
			<!--- we are going to use a form template --->
			<cfset thisTag.theTemplateSetPath =  application.SLCMS.core.templates.getSubTemplateSetPhysicalPath(Subset="Templates", TemplateSet="#thisTag.FilePartName#", TemplateSubTypeFallBack="CoreForms", TemplateSubType="#thisTag.SetName#", TemplateType="Form", SubSiteID="#request.SLCMS.PageParams.SubSiteID#") />
<!---
			<cfoutput>		
					This Tag:<br>
					<cfdump var="#thisTag#" expand="false" label="thisTag">
			<cfdump var="#request.SLCMS.PageParams#" expand="false" label="request.SLCMS.PageParams">
			<cfabort>
			</cfoutput>		

--->
			<cfset session.SLCMS.forms["#thisTag.tempName#"].FilePhysicalPath_Form = '#thisTag.theTemplateSetPath##session.SLCMS.forms["#thisTag.tempName#"].FilePartName#-form.cfm' />
			<cfset session.SLCMS.forms["#thisTag.tempName#"].FilePhysicalPath_Process = '#thisTag.theTemplateSetPath##session.SLCMS.forms["#thisTag.tempName#"].FilePartName#-process.cfm' />
			<!--- 	
			<cfset session.SLCMS.forms["#thisTag.tempName#"].FilePhysicalPath_Form = '#application.SLCMS.Sites["Site_#request.SLCMS.PageParams.SubSiteID#"].Paths.FormTemplatesPhysicalPath##session.SLCMS.forms["#thisTag.tempName#"].formShortName#-form.cfm' />
			<cfset session.SLCMS.forms["#thisTag.tempName#"].FilePhysicalPath_Process = '#application.SLCMS.Sites["Site_#request.SLCMS.PageParams.SubSiteID#"].Paths.FormTemplatesPhysicalPath##session.SLCMS.forms["#thisTag.tempName#"].formShortName#-process.cfm' />
			<cfoutput>		
					<cfdump var="#form#" expand="false">
					<cfdump var="#session.SLCMS.forms#" expand="false">
			</cfoutput>		
			 --->	
			<cfif FileExists('#session.SLCMS.forms["#thisTag.tempName#"].FilePhysicalPath_Form#') and FileExists('#session.SLCMS.forms["#thisTag.tempName#"].FilePhysicalPath_Process#')>
				<!--- we have the needed html form so we can show it. We put the 2nd pass, the processing code, first so that if it fails validation we can go back to the original form --->
				<!--- there is also what appears to be redundant flags so we can show all the content containers when logged in so they can be edited --->
				<cfif session.SLCMS.forms["#thisTag.tempName#"].CurrentAction eq "Process">
					<!--- if validation fails we need to reenter all fields so loop over the lot but only test those that are in the validation list --->
					<cfloop collection="#session.SLCMS.forms['#thisTag.tempName#'].Fields#" item="thisTag.thisField">
						<!--- first thing - drop in the value for re-entry if required --->
						<cfif StructKeyExists(form, "#thisTag.thisField#")>	<!--- have to allow for missing fields like unchecked checkboxes --->
							<cfset session.SLCMS.forms["#thisTag.tempName#"].Fields["#thisTag.thisField#"].Value = form["#thisTag.thisField#"] />
						</cfif>
						<cfif ListFindNoCase(application.SLCMS.Sites["Site_#request.SLCMS.PageParams.SubSiteID#"].FormDetails["#thisTag.tempName#"].FieldValidationNeededList, thisTag.thisField)>	<!--- pick fields that need some form of validation --->
							<cfset session.SLCMS.forms["#thisTag.tempName#"].Fields["#thisTag.thisField#"].ValidationFailReason = "" />	<!--- get rid of old errors if we re-submit directly, which is the norm --->
							<!--- check in the three ways, and we are going to check all of them regardless to show all errors at once --->
							<cfif application.SLCMS.Sites["Site_#request.SLCMS.PageParams.SubSiteID#"].FormDetails["#thisTag.tempName#"].Fields["#thisTag.thisField#"].Validation.Required>
								<cfif not (StructKeyExists(form, "#thisTag.thisField#") and form["#thisTag.thisField#"] neq "") >	<!--- is the field is there with a value --->
									<cfset session.SLCMS.forms["#thisTag.tempName#"].Fields["#thisTag.thisField#"].ValidationOK = False />
									<cfset session.SLCMS.forms["#thisTag.tempName#"].Fields["#thisTag.thisField#"].ValidationFailReason = ListAppend(session.SLCMS.forms["#thisTag.tempName#"].Fields["#thisTag.thisField#"].ValidationFailReason, "Required Field") />
									<cfset thisTag.IsValidatedShowResult = False>
								</cfif>
							</cfif>
							<cfif not application.SLCMS.Sites["Site_#request.SLCMS.PageParams.SubSiteID#"].FormDetails["#thisTag.tempName#"].Fields["#thisTag.thisField#"].Validation.BlankAllowed>
								<cfif not (StructKeyExists(form, "#thisTag.thisField#") and trim(form["#thisTag.thisField#"]) neq "") >	<!--- is the field is there with a non-white-space value --->
									<cfset session.SLCMS.forms["#thisTag.tempName#"].Fields["#thisTag.thisField#"].ValidationOK = False />
									<cfset session.SLCMS.forms["#thisTag.tempName#"].Fields["#thisTag.thisField#"].ValidationFailReason = ListAppend(session.SLCMS.forms["#thisTag.tempName#"].Fields["#thisTag.thisField#"].ValidationFailReason, "Blank Not Allowed") />
									<cfset thisTag.IsValidatedShowResult = False>
								</cfif>
							</cfif>
							<cfif application.SLCMS.Sites["Site_#request.SLCMS.PageParams.SubSiteID#"].FormDetails["#thisTag.tempName#"].Fields["#thisTag.thisField#"].Validation.ValidateType neq "">
								<!--- we have one of more validations to perform so loop over them --->
								<cfloop list='#application.SLCMS.Sites["Site_#request.SLCMS.PageParams.SubSiteID#"].FormDetails["#thisTag.tempName#"].Fields["#thisTag.thisField#"].Validation.ValidateType#' index="thisTag.thisValidation">
									<cfif thisTag.thisValidation eq "email" and form["#thisTag.thisField#"] neq "" and not application.mbc_Utility.Utilities.IsValidEddress(form["#thisTag.thisField#"])>
										<cfset session.SLCMS.forms["#thisTag.tempName#"].Fields["#thisTag.thisField#"].ValidationOK = False />
										<cfset session.SLCMS.forms["#thisTag.tempName#"].Fields["#thisTag.thisField#"].ValidationFailReason = ListAppend(session.SLCMS.forms["#thisTag.tempName#"].Fields["#thisTag.thisField#"].ValidationFailReason, "Email address is not valid") />
										<cfset thisTag.IsValidatedShowResult = False>
									</cfif>
								</cfloop>
							</cfif>
							<cfset session.SLCMS.forms["#thisTag.tempName#"].Fields["#thisTag.thisField#"].ValidationFailReason = Replace(session.SLCMS.forms["#thisTag.tempName#"].Fields["#thisTag.thisField#"].ValidationFailReason, ",", ", ","all") />
						</cfif>
					</cfloop>
					<!--- looped over all the fields in the form so see how the validation went, flag a failure to show the form again --->
					<cfif not thisTag.IsValidatedShowResult>
						<cfset session.SLCMS.forms.CurrentAction = "ValidationFail"  />	<!--- set back to first step, show the form --->
						<cfset session.SLCMS.forms["#thisTag.tempName#"].CurrentAction = "ValidationFail"  />	<!--- set back to first step, show the form --->
						<cfset session.SLCMS.forms["#thisTag.tempName#"].temp.errorCode = 0 />	<!--- clear our error flag --->
						<cfset session.SLCMS.forms["#thisTag.tempName#"].Confirmer = 'SLCMS#DateFormat(Now(), "YYYYMMDD")##session.SLCMS.forms["#thisTag.tempName#"].formShortName##TimeFormat(Now(),"HHmmss")#' />	<!--- this will help in trapping captcha bots --->
					</cfif>
				</cfif>	
				<!--- if we are about to process a form check that the confirmation hidden fields are what they are meant to be and a bot has not stuck its finger in the pie --->
				<cfif session.SLCMS.forms["#thisTag.tempName#"].CurrentAction eq "Process">		
					<cfif StructKeyExists(form, "Sconfirmer") and form.Sconfirmer eq session.SLCMS.forms["#thisTag.tempName#"].Confirmer and StructKeyExists(form, "Tconfirmer") and form.Tconfirmer eq "">		
						<cfset thisTag.IsConfirmedShowResult = True>
					<cfelse>
						<cfoutput>Oops! The Form security data did not validate. We did not process it. Perhaps you took too long to submit the form.</cfoutput>
						<cfset session.SLCMS.forms["#thisTag.tempName#"].CurrentAction = "ValidationFail"  />	<!--- set back to first step, show the form --->
						<cfset session.SLCMS.forms["#thisTag.tempName#"].temp.errorCode = 0 />	<!--- clear our error flag --->
						<cfset session.SLCMS.forms["#thisTag.tempName#"].Confirmer = 'SLCMS#DateFormat(Now(), "YYYYMMDD")##session.SLCMS.forms["#thisTag.tempName#"].formShortName##TimeFormat(Now(),"HHmmss")#' />	<!--- this will help in trapping captcha bots --->
					</cfif>	
				</cfif>	
				<!--- now we have our flags show the top containers --->
				<cfif session.SLCMS.forms["#thisTag.tempName#"].CurrentAction eq "ShowForm" or thisTag.IsAuthor>
					<cf_displayContainer name="FormEntryTop_#thisTag.tempName#" EditHeading="Text shown only when Form displayed" />	<!--- a text area at the top of the page below the page common area that is for entry text only --->
				</cfif>
				<cfif (thisTag.IsConfirmedShowResult and thisTag.IsValidatedShowResult) or thisTag.IsAuthor>
					<cf_displayContainer name="ProcessTop_#thisTag.tempName#" EditHeading="Text shown only when Results displayed" />	<!--- a text area at the top of the page below the page common area that is for the processing message --->
				</cfif>
				<!--- now we have shown the top editable content areas show the appropriate template, first pointing to it --->
				<cfset session.SLCMS.forms["#thisTag.tempName#"].CurrentFormSetURLPath = application.SLCMS.config.base.RootURL & application.SLCMS.core.Templates.getSubTemplateSetURLPath(Subset="Templates", TemplateSet="#thisTag.FilePartName#", TemplateSubTypeFallBack="CoreForms", TemplateSubType="#thisTag.SetName#", TemplateType="Form", SubSiteID="#request.SLCMS.PageParams.SubSiteID#") />
				<cfset session.SLCMS.forms.CurrentFormURL = session.SLCMS.forms["#thisTag.tempName#"].CurrentFormSetURLPath  />
				<cfif session.SLCMS.forms["#thisTag.tempName#"].CurrentAction eq "Process" and thisTag.IsConfirmedShowResult and thisTag.IsValidatedShowResult>
					<!--- we have a good form submission so show the process template --->
					<cfset session.SLCMS.forms["#thisTag.tempName#"].CurrentFormFileURLPath = '#session.SLCMS.forms["#thisTag.tempName#"].CurrentFormSetURLPath##session.SLCMS.forms["#thisTag.tempName#"].FilePartName#-process.cfm' />
<!--- 
					<cfset session.SLCMS.forms["#thisTag.tempName#"].CurrentFormFileURLPath = '#application.config.base.RootURL##application.config.base.SLCMSFormTemplatesRelPath##session.SLCMS.forms["#thisTag.tempName#"].formShortName#-process.cfm' />
 --->
					<cfinclude template="#session.SLCMS.forms['#thisTag.tempName#'].CurrentFormFileURLPath#">	<!--- this is the results.... ToDo --->
<!--- 
<cfoutput>
	session.SLCMS.forms['#thisTag.tempName#'].fields Struct:<br>
	<cfdump var="#session.SLCMS.forms['#thisTag.tempName#'].fields#" expand="false">
	<!--- 
	application.SLCMS.Sites["Site_#request.SLCMS.PageParams.SubSiteID#"].FormDetails['#thisTag.tempName#'] Struct:<br>
	<cfdump var="#application.SLCMS.Sites["Site_#request.SLCMS.PageParams.SubSiteID#"].FormDetails['#thisTag.tempName#']#" expand="false">
	Form handler variables scope:<br>
	<cfdump var="#application.forms.getVariablesScope()#" expand="false">
	TemplateManager variables scope:<br>
	<cfdump var="#application.templates.getVariablesScope()#" expand="false">
	Form fields Struct:<br>
	<cfdump var="#form#" expand="false">
	 --->
</cfoutput>
 --->
					<!--- and then save the data, we do it that way as we might have done a file upload that the processor picked up --->
					<cfset thisTag.tempRet = application.SLCMS.core.Forms.SaveData(FormName="#thisTag.tempName#", FieldSessionStruct="#session.SLCMS.forms['#thisTag.tempName#'].Fields#", SubSiteID="#request.SLCMS.PageParams.SubSiteID#") />
				</cfif>	
				<cfif session.SLCMS.forms["#thisTag.tempName#"].CurrentAction eq "ShowForm">
					<!--- if showing the form first time reset the fields lists that flag changes each loading --->
					<cfset session.SLCMS.forms["#thisTag.tempName#"].Fields = StructNew() />	<!--- clear out our field definitions so the form tags can write them back in again (need to do that if form code has been changed) --->
					<cfset session.SLCMS.forms["#thisTag.tempName#"].Fields.FilesUploaded = StructNew() />	<!--- clear out our field definitions so the form tags can write them back in again (need to do that if form code has been changed) --->
					<cfset session.SLCMS.forms["#thisTag.tempName#"].Fields.FilesUploaded.FieldList = ""  />	<!--- list of fields that had a succesful file upload --->
					<cfset application.SLCMS.Sites["Site_#request.SLCMS.PageParams.SubSiteID#"].FormDetails["#thisTag.tempName#"].Status.flagChanged = False />	<!--- The global flag that there has been a change, in this case clear it as we start to process the form --->
					<cfset application.SLCMS.Sites["Site_#request.SLCMS.PageParams.SubSiteID#"].FormDetails["#thisTag.tempName#"].Status.FieldisNewList = "" />	<!--- this is the list of all the fields set up by our form tags that were not there before --->
					<cfset application.SLCMS.Sites["Site_#request.SLCMS.PageParams.SubSiteID#"].FormDetails["#thisTag.tempName#"].Status.FieldSizeGrewList = "" />	<!--- The list of fields that changed their size in the form --->
					<cfset application.SLCMS.Sites["Site_#request.SLCMS.PageParams.SubSiteID#"].FormDetails["#thisTag.tempName#"].FieldValidationNeededList = "" />	<!--- this is the list of fields we need to validate --->
				</cfif>	
				<!--- now we show the input form. Rather than simply include the form and let it show we are going to cahe the content so that we can process the form tag results and do adjustmens if needed --->
				<cfif session.SLCMS.forms["#thisTag.tempName#"].CurrentAction eq "ShowForm" or session.SLCMS.forms["#thisTag.tempName#"].CurrentAction eq "ValidationFail">
					<cfset session.SLCMS.forms["#thisTag.tempName#"].CurrentFormFileURLPath = '#session.SLCMS.forms["#thisTag.tempName#"].CurrentFormSetURLPath##session.SLCMS.forms["#thisTag.tempName#"].FilePartName#-form.cfm' />

					<cfsavecontent variable="theFormContent">
						<cfinclude template="#session.SLCMS.forms['#thisTag.tempName#'].CurrentFormFileURLPath#">
					</cfsavecontent>
					<!--- we have gathered the form output so lets check its existance in our databases and create as needed so we can store the results --->
					<!--- the current form's fields will have appeared in application.SLCMS.Sites["Site_#request.SLCMS.PageParams.SubSiteID#"].FormDetails["#thisTag.tempName#"] and session.SLCMS.forms["#thisTag.tempName#"].Fields from the work of the slcms form tags in the template --->
					<cfset thisTag.tempRet = application.SLCMS.core.Forms.FormChecknSet(FormName="#thisTag.tempName#", FieldSessionStruct="#session.SLCMS.forms['#thisTag.tempName#'].Fields#", FormDetails="#application.SLCMS.Sites["Site_#request.SLCMS.PageParams.SubSiteID#"].FormDetails['#thisTag.tempName#']#", SubSiteID="#request.SLCMS.PageParams.SubSiteID#") />
					<cfset application.SLCMS.Sites["Site_#request.SLCMS.PageParams.SubSiteID#"].FormDetails["#thisTag.tempName#"].flagFirstTimeIn = False />	<!--- we should be right now internally --->
					<!--- now actually send the form content to the browser --->
					<cfoutput>
						<div class="ContentContainer_Wrapper">
						<form name="SLCMSForm" action="#request.SLCMS.rootURL#content.cfm#request.SLCMS.PageParams.PagePathEncoded##request.SLCMS.PageParams.PageQueryString#" method="Post"<cfif application.SLCMS.Sites["Site_#request.SLCMS.PageParams.SubSiteID#"].FormDetails["#thisTag.tempName#"].flagFileFieldUsed> enctype="multipart/form-data"</cfif>>
						<input type="Hidden" name="Sconfirmer" value="#session.SLCMS.forms['#thisTag.tempName#'].Confirmer#">
						<!-- screen reader users, do not place a value in the following text input field named Tconfirmer, leave it empty  -->
						<input type="text" name="Tconfirmer" value="" class="captchaconfirmer">	<!--- if we are bot proof this should stay empty --->
					 	#theFormContent#
						</form></div>
					</cfoutput>

				</cfif>	
			<cfelse>
				<cfoutput>
					Oops! The Form Templates &quot;#session.SLCMS.forms["#thisTag.tempName#"].FilePhysicalPath_Form#&quot; and &quot;#session.SLCMS.forms["#thisTag.tempName#"].FilePhysicalPath_Process#&quot; could not be found!
					<cfif application.config.DeBug.DebugMode eq True>
						<br>Looking in: '#session.SLCMS.forms["#thisTag.tempName#"].FilePhysicalPath_Form#'
					</cfif>
		  	  </cfoutput>
			</cfif>	<!--- end: the form template file exists check --->
		<cfelse>
			<!--- this is a form object, not implemented yet --->
			<cfoutput>Sorry, We have not yet implemented Form Objects, you will have to use a Form template </cfoutput>
		</cfif>	<!--- end: type of form processing --->
	</cfif>	<!--- end: valid attributes supplied --->
</cfif>	<!--- end: tag execution mode is start --->

<cfif thisTag.executionMode IS "end">
<cfelseif NOT thisTag.hasEndTag>
	<cfabort showerror="Must be called as customtag.">
</cfif>
<cfsetting enablecfoutputonly="No">
