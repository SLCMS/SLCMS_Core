<cfsetting enablecfoutputonly="Yes">
<cfif thisTag.executionMode IS "start">
<!--- SLCMS base tags to be used in template pages  --->
<!---  --->
<!--- custom tag to display a WYSIWG editor for content --->
<!--- &copy; mort bay communications --->
<!---  --->
<!--- cloned:   20th Jan 2013 by Kym K, mbcomms: from display container so we can have the editor available as a standalone entity --->
<!--- modified: 20th Jan 2013 - 20th Jan 2013 by Kym K, mbcomms: working on it --->

	<cfparam name="attributes.Name" type="string" default="">
	<cfparam name="attributes.id" type="string" default="0">
	<cfparam name="attributes.Content" type="string" default="">
	<cfparam name="attributes.DisplayType" type="string" default="">
	<cfparam name="attributes.EditHeading" type="string" default="">
	<cfparam name="attributes.EditorStyleSheet" type="string" default="">

	<cfset thisTag.theContent = trim(attributes.Content) />
	<cfset thisTag.theDisplayType = trim(attributes.DisplayType) />
	<cfset thisTag.theEditHeading = trim(attributes.EditHeading) />
	<cfset thisTag.theEditorStyleSheet = trim(attributes.EditorStyleSheet) />
	<cfset thisTag.flagNeedToUpdateSearchCollection = False />
	<cfset thisTag.flagIsInEditMode = False />	<!--- are we editing --->
	<cfset thisTag.flagIsInShowContentNormallyMode = True />	<!--- are we just showing content --->
	<cfset thisTag.flagIsInShowVersionsMode = False />	<!--- are we looking at the versions list --->
	<!--- 
	<cfset thisTag.flagContentIsWiki = False />	<!--- are we looking at wiki content --->
	 --->
	<cfset thisTag.flagIsOurContainer = False />
	<cfset thisTag.ContentGetModeMode = "Live"  />
	<cfset thisTag.IsAuthor = application.SLCMS.Core.UserPermissions.IsAuthor() />	<!--- do we have authoring rights --->
	<cfset thisTag.IsEditor = application.SLCMS.Core.UserPermissions.IsEditor() />	<!--- do we have edit rights --->
	<!--- now we have a set of flags and counters to work out what we are going to show --->
	<cfset thisTag.flagShowPublishedVersion = True />	<!--- tells to display the currently published version, ie normal behaviour --->
	<cfset thisTag.PublishedVersionNumber = 0 />	<!--- will be set to the version of the currently published content --->
	<cfset thisTag.flagShowLatestVersion = False />	<!--- tells to display the currently latest version, will be set by incoming flags further down the page --->
	<cfset thisTag.CurrentVersionNumber = 0 />	<!--- contains the version of the content being displayed --->

	<!--- 
	<cfdump var="#request.SLCMS.PageParams#" expand="false" label="request.SLCMS.PageParams" />
	<cfdump var="#thisTag#" expand="false" label="thisTag" />
	<cfdump var="#form#" expand="false" label="form" />

	<cfabort >
	 --->
	<!--- see if we are in edit mode for this container --->

	<cfoutput>
  <div class="ContentContainer_Wrapper">
	<cfif thisTag.IsAuthor>
		<div class="ContentContainer_Marker">
		<cfif not thisTag.flagIsInEditMode>
			<div class="ContentContainer_ControlsMarker">	<!--- marker div as the visibility of the one inside can be toggled on and off --->
			<div class="ContentContainer_Controls">
			<!--- a bunch of controls and things depending on what is going on --->
			<cfif thisTag.flagIsInShowVersionsMode>
				<!--- its the version list so we need to manage that --->
				A list of the versions of this content, choose one
				<form action="#application.SLCMS.Config.Base.rootURL#content.cfm#request.SLCMS.PageParams.PagePathEncoded#" method="post" >
					<input type="hidden" name="DocID" value="#thePageID#">
					<input type="hidden" name="ContentHandle" value="#thisTag.theContentControlData.Handle#">
					<input type="hidden" name="ContainerName" value="#attributes.Name#">
					<input type="hidden" name="ContainerID" value="#attributes.ID#">
					<input type="hidden" name="ContentVersion" value="">
					<input type="hidden" name="FCKSubmission" value="No">
					<input type="hidden" name="Edit" value="EditContainer">
					<!--- the rest of the form is down below with the version list --->
			<cfelse>
				<!--- nothing else special happening so go to the default of doing some editing :-) --->
				<form action="#application.SLCMS.Config.Base.rootURL#content.cfm#request.SLCMS.PageParams.PagePathEncoded#" method="post" >
					<input type="hidden" name="DocID" value="#thePageID#">
					<input type="hidden" name="ContentID" value="#thisTag.theContentControlData.ContentID#">
					<input type="hidden" name="ContentHandle" value="#thisTag.theContentControlData.Handle#">
					<input type="hidden" name="ContainerName" value="#attributes.Name#">
					<input type="hidden" name="ContainerID" value="#attributes.ID#">
					<input type="hidden" name="ContentVersion" value="#thisTag.theContentControlData.Version#">
					<input type="hidden" name="FCKSubmission" value="No">
					<input type="hidden" name="Edit" value="EditContainer">
			<!--- decode which buttons to show --->
			<!--- 
			<cfif thisTag.theContentControlData.EditorMode eq "WYSIWYG">
			 --->
				<div class="ContentContainer_Controls_EditButton">	<!--- the edit button floats to the right --->
					<input type="image" name="EditButton" value="EditContainer_WYSIWYG" src="#request.SLCMS.rootURL#SLCMS/SLCMSstyling/nbutton_edit.gif" border="0" title="Edit the Content in this Container with a WYSIWYG Editor">
				</div>
				<div class="ContentContainer_Controls_Heading">#thisTag.theEditHeading#</div>	<!--- the text heading on the left --->
				<span class="ContentContainer_Center">	<!--- the centered other stuff --->
	<!--- see if we have to edit this container or show stuff --->
	<cfif thisTag.theContentControlData.ContentID eq -1 or not thisTag.flagIsInEditMode>
		<!--- no edit so see what we have to show --->
		
		<!--- show the editor with the content within instead of the straight content --->
		<form action="/content.cfm#request.SLCMS.PageParams.PagePathEncoded#" method="post" class="ContentContainer_ControlButtons">
			<input type="hidden" name="DocID" value="#thePageID#">
			<input type="hidden" name="ContentID" value="#thisTag.theContentControlData.ContentID#">
			<input type="hidden" name="ContentHandle" value="#thisTag.theContentControlData.Handle#">
			<input type="hidden" name="ContainerName" value="#form.ContainerName#">
			<input type="hidden" name="ContainerID" value="#form.ContainerID#">
			<input type="hidden" name="FCKSubmission" value="Yes">
			<input type="hidden" name="Edit" value="EditContainer">
		<cfif StructKeyExists(form, "EditButton") and form.EditButton eq "EditContainer_WYSIWYG">
			<input type="hidden" name="EditMode" value="WYSIWYG">
		<!--- 
		<cfelseif StructKeyExists(form, "EditButton") and form.EditButton eq "EditContainer_wiki">
			<input type="hidden" name="EditMode" value="wiki">
			<cfset request.EditorControl.EditorToUse = "" />	<!--- this turns off all of the wysiwyg editors --->
		 --->
		<cfelse>
			<input type="hidden" name="EditMode" value="">
		</cfif>
		
		<cfinclude template="_wysiwygEditors_inc.cfm">

		<div class="ContentContainer_UnderButtonsWrapper">
			<div class="ContentContainer_UnderButtonsLeft">	<!--- put save and cancel buttons neatly under for better usability --->
			<input type="image" name="SaveButton" value="Save" src="#request.SLCMS.rootURL#SLCMS/SLCMSstyling/nbutton_save.gif" class="ContentContainer_ControlButtonsUnder" title="Save Content">
			<input type="image" name="CancelButton" value="Cancel" src="#request.SLCMS.rootURL#SLCMS/SLCMSstyling/nbutton_cancel.gif" class="ContentContainer_ControlButtonsUnder" title="Cancel Editing">
			</div>
		</div>
		</form>
		<div style="clear:both; min-width:500px"></div>
	</cfif>

<cfif thisTag.executionMode IS "end"></cfif>
<cfsetting enablecfoutputonly="No">