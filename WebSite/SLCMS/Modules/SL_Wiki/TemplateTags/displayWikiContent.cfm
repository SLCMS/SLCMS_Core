<cfsetting enablecfoutputonly="Yes">
<cfif thisTag.executionMode IS "start">
<!--- SLCMS base tags to be used in template pages  --->
<!---  --->
<!--- custom tag to display a content container --->
<!--- &copy; mort bay communications --->
<!---  --->
<!--- created:  15th Dec 2006 by Kym K --->
<!--- modified: 15th Dec 2006 - 18th Dec 2006 by Kym K, mbcomms: working on it --->
<!--- Modified:  4th Jan 2007 -  6th Jan 2007 by Kym K, mbcomms: added contentType now we have gone to CFC DB management --->
<!--- Modified: 20th Jan 2007 - 21st Jan 2007 by Kym K, mbcomms: adding more CFC functions --->
<!--- Modified:  8th Feb 2007 -  8th Feb 2007 by Kym K, mbcomms: added "Author" role for edit content only, no backend at all --->
<!--- Modified: 13th Feb 2007 - 13th Feb 2007 by Kym K, mbcomms: fixed issue with edit button formfield naming in IE --->
<!--- modified: 31st Oct 2007 - 31st Oct 2007 by Kym K, mbcomms: changed image path to templateimages folder --->
<!--- modified: 28th Nov 2007 - 29th Nov 2007 by Fiona & Kym K, mbcomms: edited slcmsimages and added clear divs to improve cosmetics when showing edit buttons --->
<!--- modified: 22nd Dec 2007 - 23rd Dec 2007 by Fiona & Kym K, mbcomms: shrank edit button and added save & cancel buttons under editor area to aid usability --->
<!--- modified: 22nd Feb 2008 - 23rd Feb 2008 by Kym K, mbcomms: added editors: simple and tinyMCE used with textarea --->
<!--- modified: 28th Feb 2008 - 28th Feb 2008 by Kym K, mbcomms: moved editors into include file --->
<!--- modified: 30th Mar 2008 - 30th Mar 2008 by Kym K, mbcomms: added search update to save and put in new save/cancel graphics --->
<!--- modified: 10th Sep 2008 - 10th Sep 2008 by Kym K, mbcomms: added EditHeading attribute to put text in the edit div to show when in edit mode, a heading or a hint or whatever --->
<!--- modified: 20th Nov 2008 - 20th Nov 2008 by Kym K, mbcomms: updated TinyMCE code, added styling variables --->
<!--- modified: 25th Jan 2009 - 25th Jan 2009 by Kym K, mbcomms: changed location of styling wrapper, container_wrapper so it is consistent in edit mode or not and makes styling easier --->
<!--- modified:  7th Feb 2009 - 17th Feb 2009 by Kym K, mbcomms: adding code to allow integration of a wiki --->
<!--- modified: 22nd Feb 2009 - 28th Feb 2009 by Kym K, mbcomms: adding code for version control --->
<!--- modified: 23rd Mar 2009 - 23rd Mar 2009 by Kym K, mbcomms: V2.2, changing structures to new module-allowing architecture, the core code is now just another module --->
<!--- modified: 27th Apr 2009 -  7th May 2009 by Kym K, mbcomms: V2.2, changing template folder structure to portal/sub-site architecture, sites inside the top site, data structures added/changed to match --->
<!--- modified:  1st Sep 2009 -  5th Sep 2009 by Kym K, mbcomms: V2.2, changing over to permissions tags for user rights --->
<!--- modified: 29th Oct 2009 - 30th Oct 2009 by Kym K, mbcomms: V2.2, cosmetic and usability improvements --->
<!--- modified: 27th Dec 2009 - 27th Dec 2009 by Kym K, mbcomms: V2.2, adding tabs to the wiki content display so we can have base wiki content and related discussion --->
<!--- modified: 12th May 2011 - 12th May 2011 by Kym K, mbcomms: V2.2, we are now using jQuery all over the place and the various control buttons fail if some js libararies are called, 
																																				form params are not the same so now detecting with StructKeyExists() not IsDefined()
																																				also moved a few vars into the thisTag struct to clean up the variables scope --->
<!--- modified:  8th Jun 2011 -  8th Jun 2011 by Kym K, mbcomms: tidying up --->
<!--- modified: 30th Oct 2011 - 30th Oct 2011 by Kym K, mbcomms: improving workflow flagging and logging --->
<!--- modified: 20th Mar 2012 - 20th Mar 2012 by Kym K, mbcomms: moved search update to "publish" not immediately after noram save --->

	<cfparam name="attributes.Name" type="string" default="">
	<cfparam name="attributes.id" type="string" default="0">
	<cfparam name="attributes.EditHeading" type="string" default="">
	<cfparam name="attributes.EditorStyleSheet" type="string" default="">

	<cfset thisTag.theContent = "" />
	<cfset thisTag.theEditHeading = trim(attributes.EditHeading) />
	<cfset thisTag.theEditorStyleSheet = trim(attributes.EditorStyleSheet) />
	<cfset thisTag.flagNeedToUpdateSearchCollection = False />
	<cfset thisTag.flagIsInEditMode = False />	<!--- are we editing --->
	<cfset thisTag.flagIsInShowContentNormallyMode = True />	<!--- are we just showing content --->
	<cfset thisTag.flagIsInShowVersionsMode = False />	<!--- are we looking at the versions list --->
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
	<cfdump var="#session.SLCMS.user#" expand="false" />
	<cfdump var="#thisTag#" expand="false" />
	 --->
	<!--- work out default params so they are out of the way, might tickle them later, ie further down the page... --->
	<cfif thisTag.theEditorStyleSheet eq "">
		<cfset thisTag.theEditorStyleSheet = application.SLCMS.Config.editors.DefaultEditorStyleSheet />	<!---  a highly recommended naming default --->
	</cfif>	
	
	<!--- work out if we are using names or ids for the comparisons further down as to what we show --->
	<cfif len(attributes.Name)>	
		<cfset thisTag.IDmode = "Name" />
		<cfif IsDefined("form.ContainerName") and len(form.ContainerName) and form.ContainerName eq attributes.Name>	<!--- see if this is the content to edit --->
			<cfset thisTag.flagIsOurContainer = True>
		</cfif>
	<cfelse>
		<cfset thisTag.IDmode = "ID" />
		<cfif IsDefined("form.ContainerID") and len(form.ContainerID) and form.ContainerID eq attributes.ID>
			<cfset thisTag.flagIsOurContainer = True>
		</cfif>
	</cfif>
	<!--- sort out the display type and what content it is --->
	<cfset theContentTypeID = 5 />
	<cfset thisTag.flagIsInShowContentNormallyMode = True />
	<cfset thisTag.flagContentIsWiki = True />
	<cfset thePageID = request.SLCMS.PageParams.DocID />
	<!---
	<!--- get the control data for this content --->
	<cfset thisTag.theContentControlData = application.SLCMS.Core.Content_DatabaseIO.getContainerContentID(PageID="#thePageID#", ContainerID="#attributes.id#", ContainerName="#attributes.name#", ContentVersion="#thisTag.ContentGetModeMode#", InEditMode="#thisTag.IsAuthor#", SubSiteID="#request.SLCMS.PageParams.SubSiteID#") />
--->
	<!--- work out if we are possibly editing or not as that governs what content we are going to grab from the database --->
	<!--- and see if we are doing a publish or something that also affects what content to get before we actually grab it --->
	<cfif thisTag.IsAuthor and thisTag.flagIsOurContainer and IsDefined("form.FCKSubmission") and form.FCKSubmission eq "No">	<!--- this combo will be here for any button push that is not saving the form --->
		<!--- this is our container to edit so do something --->
		<cfif StructKeyExists(form, "PublishButton.x") or (StructKeyExists(form, "PublishButton") and form.PublishButton eq "Publish_Version")>
			<!--- we have been told to publish the displayed version --->
			<cfset thisTag.ret = application.SLCMS.Core.Content_DatabaseIO.setContainerPublishedContent(PageID="#thePageID#", ContainerID="#attributes.id#", ContainerName="#attributes.name#", ContentID="#form.ContentID#", UserID="#session.SLCMS.user.UserID#", SubSiteID="#request.SLCMS.PageParams.SubSiteID#") />
			<!---
			<cfset ret = application.SLCMS.Core.Content_Search.UpdateCollection(Name="Body", ContentID="#thisTag.theContentControlData.ContentID#", SubSiteID="#request.SLCMS.PageParams.SubSiteID#") />
			--->
			<cfset thisTag.flagNeedToUpdateSearchCollection = True />
			<!--- then we must clear our flags so we don't drop into edit mode --->
			<cfset thisTag.flagIsOurContainer = False />
			<cfset thisTag.flagIsInEditMode = False />
			<cfset thisTag.flagIsInShowContentNormallyMode = True />
		<cfelseif StructKeyExists(form,"LatestVersion.x") or StructKeyExists(form,"LatestVersion")>
			<cfset thisTag.ContentGetModeMode = "Latest"  />
			<cfset thisTag.flagIsOurContainer = False />
		<cfelseif StructKeyExists(form, "ViewThisVersion") or StructKeyExists(form, "ViewThisVersion.x")>
			<cfif StructKeyExists(form, "ChosenVersion")>
				<cfset thisTag.ContentGetModeMode = "Version_#form.ChosenVersion#"  />
			<cfelse>
				<cfset thisTag.ContentGetModeMode = "Live"  />
			</cfif>
			<cfset thisTag.flagIsOurContainer = False />
		<cfelseif StructKeyExists(form, "ListVersions") or StructKeyExists(form, "ListVersions.x")>
			<!--- we want to see a list of versions to possibly choose another to work with --->
			<cfset thisTag.VersionsQuery = application.SLCMS.Core.Content_DatabaseIO.getContainerContentVersions(PageID="#thePageID#", ContainerID="#attributes.id#", ContainerName="#attributes.name#", SubSiteID="#request.SLCMS.PageParams.SubSiteID#") />
			<!--- then we must clear our flags so we don't drop into edit mode --->
			<cfset thisTag.flagIsInShowVersionsMode = True />
			<cfset thisTag.flagIsInEditMode = False />
			<cfset thisTag.flagIsOurContainer = False />
		<cfelseif StructKeyExists(form, "Edit") or StructKeyExists(form, "Edit.x")>
			<!--- the edit button was pressed so we must get the data for the passed-in contentID  --->
			<cfset thisTag.flagIsInEditMode = True />
			<cfset thisTag.flagIsInShowContentNormallyMode = False />
			<cfset thisTag.flagIsInShowVersionsMode = False />
			<cfif form.contentVersion eq 0>
				<cfset thisTag.ContentGetModeMode = "Latest"  />
			<cfelse>
				<cfset thisTag.ContentGetModeMode = "Version_#form.contentVersion#"  />
			</cfif>
		</cfif>
	</cfif>

	<!--- get the control data for the content --->
	<cfset thisTag.theContentControlData = application.SLCMS.Core.Content_DatabaseIO.getContainerContentID(PageID="#thePageID#", ContainerID="#attributes.id#", ContainerName="#attributes.name#", ContentVersion="#thisTag.ContentGetModeMode#", InEditMode="#thisTag.IsAuthor#", SubSiteID="#request.SLCMS.PageParams.SubSiteID#") />

	<cfif thisTag.flagNeedToUpdateSearchCollection>
<!---
<cfdump var="#thisTag#" expand="false" label="thisTag">
<cfabort>
--->
		<cfset ret = application.SLCMS.Core.Content_Search.UpdateCollection(Name="Body", ContentID="#thisTag.theContentControlData.ContentID#", SubSiteID="#request.SLCMS.PageParams.SubSiteID#") />
	</cfif>

<!--- 
ContentGetModeMode<br>
<cfdump var="#thisTag.ContentGetModeMode#" expand="false">
thisTag.theContentControlData<br>
<cfdump var="#thisTag.theContentControlData#" expand="false">
thePageID<br>
<cfdump var="#thePageID#" expand="false">
request.SLCMS.PageParams<br>
<cfdump var="#request.SLCMS.PageParams#" expand="false">

<cfabort>
 --->
	<!--- check it for goodness --->
 	<cfif thisTag.theContentControlData.ContentID gt 0>
		<!--- we have a content ID that we can use so grab the content --->
		<cfset thisTag.theContent = application.SLCMS.Core.Content_DatabaseIO.getContent(ContentID="#thisTag.theContentControlData.ContentID#", SubSiteID="#request.SLCMS.PageParams.SubSiteID#") />
		<!--- and flag what type of content --->
		<cfset thisTag.theContentControlData.ContentTypeID = theContentTypeID />
		<!--- and a quick fix to pick up legacy content that did not have a handle --->
		<cfif not (StructKeyExists(thisTag.theContentControlData, "Handle") and thisTag.theContentControlData.Handle neq "" and isValid("UUID", thisTag.theContentControlData.Handle))>
			<cfset thisTag.theContentControlData.Handle = CreateUUID() />
		</cfif>
	<cfelseif thisTag.theContentControlData.ContentID eq 0>
		<!--- its new content so fill in the control structure, partly according to type of content --->
		<cfif theContentTypeID eq 5>
			<cfset thisTag.theContentControlData.EditorMode = "" />
			<!--- and as its a wiki amend the data --->
			<cfset thisTag.theContentControlData.DocID = thePageID />	<!--- we have to set this again as we are pointing at the parent from the getContent --->
		<cfelse>
			<cfset thisTag.theContentControlData.EditorMode = "WYSIWYG" />
			<cfset thisTag.theContentControlData.DocID = request.SLCMS.PageParams.DocID />
		</cfif>
		<cfset thisTag.theContentControlData.Handle = CreateUUID() />
		<cfset thisTag.theContentControlData.ContentTypeID = theContentTypeID />
		<cfset thisTag.theContentControlData.ContainerID = attributes.id />
		<cfset thisTag.theContentControlData.ContainerName = attributes.name />
		<cfset thisTag.theContent = "" />
	<cfelse>
		<cfset thisTag.theContent = "Oops! Error in Finding Content!" />
	</cfif>
	
	<cfdump var="#request.SLCMS.PageParams#" expand="false" label="request.SLCMS.PageParams" />
	<cfdump var="#thisTag#" expand="false" label="thisTag" />
	<cfdump var="#form#" expand="false" label="form" />

	<cfabort >
	
	<!--- see if we are in edit mode for this container --->
	<cfif IsDefined("form.FCKSubmission") and thisTag.flagIsOurContainer>	<!--- this will be here for either edit state --->
		<!--- this is our container to edit so do something --->
		<!--- we have either hit the edit button or saved an edit --->
		<cfif form.edit eq "EditContainer">
			<cfif form.FCKSubmission eq "No">
				<!--- edit button has been pressed --->
				<cfset thisTag.flagIsInEditMode = True  />
				<cfset thisTag.flagIsInShowContentNormallyMode = False />
			<cfelseif form.FCKSubmission eq "Yes" and not ((IsDefined("form.CancelButton") and form.CancelButton eq "Cancel") or StructKeyExists(form, "CancelButton.x"))>
				<!--- it is a save from the editor so save the content and update the search engine collection --->
				<cfif form.ContentID eq 0>
					<!--- this will define what mode, wysiwyg or wiki, when we first create the content --->
					<cfset thisTag.theContentControlData.EditorMode = trim(form.editmode) />
				</cfif>
				<cfset thisTag.theContent = trim(form.content) />	<!--- this is to show it on the page when the save is done --->
<!---
<cfdump var="#thisTag.theContentControlData#" expand="false">

<cfabort>
--->
				<cfset ret = application.SLCMS.Core.Content_DatabaseIO.saveContainerContent(content="#thisTag.theContent#", ContentControlData="#thisTag.theContentControlData#", UserID="#session.SLCMS.user.UserID#", SubSiteID="#request.SLCMS.PageParams.SubSiteID#") />
				<!---
				<cfset ret = application.SLCMS.Core.Content_Search.UpdateCollection(Name="Body", Item="#thisTag.theContentControlData.DocID#", SubSiteID="#request.SLCMS.PageParams.SubSiteID#") />
				--->
				<!--- and fix the versionsout calculated above as we are now one out --->
				<cfset thisTag.theContentControlData.VersionOutCount = thisTag.theContentControlData.VersionOutCount+1>
				<cfset thisTag.ContentGetModeMode = "Latest"  />
				<!--- and regrab the control data as we are a new bit of content --->
				<cfset thisTag.theContentControlData = application.SLCMS.Core.Content_DatabaseIO.getContainerContentID(PageID="#thePageID#", ContainerID="#attributes.id#", ContainerName="#attributes.name#", ContentVersion="#thisTag.ContentGetModeMode#", UserState="#session.SLCMS.user#", SubSiteID="#request.SLCMS.PageParams.SubSiteID#") />
				
				<cfset thisTag.flagIsInEditMode = False  />
			<cfelse>
				<!--- oops! or cancelled --->
				<cfset thisTag.flagIsInEditMode = False  />
				<cfset thisTag.flagIsInShowContentNormallyMode = True />
			</cfif>	<!--- end: type of submission --->
		</cfif>	<!--- end: was editcontainer --->
	<cfelse>
		<cfset thisTag.flagIsInEditMode = False  />
	</cfif>	<!--- end: check/set edit mode --->

	<!--- now we are ready to display content check if its wiki-formatted content and process it if it is and we aren't editing it --->
	<cfset thisTag.wikiDBtablePath = application.SLCMS.Config.DatabaseDetails.TableNaming_Base 
																	& application.SLCMS.Config.DatabaseDetails.TableNaming_Delimiter 
																	& application.SLCMS.Config.DatabaseDetails.TableNaming_SiteMarker 
																	& application.SLCMS.Config.DatabaseDetails.TableNaming_Delimiter
																	&	request.SLCMS.PageParams.SubSiteID
																	& application.SLCMS.Config.DatabaseDetails.TableNaming_Delimiter
																	& application.SLCMS.Config.DatabaseDetails.wikiMappingTable
																		 />
	<cfset request.wiki_render=createObject('component','#application.SLCMS.Config.base.MapURL##application.SLCMS.Config.base.SLCMSCoreRelPath#CFCs/wiki_PageRender') /><!--- this cfc has the tools to take the content and render into proper html --->
	<cfset request.wiki_code=createObject('component','#application.SLCMS.Config.base.MapURL##application.SLCMS.Config.base.SLCMSCoreRelPath#CFCs/wiki_code') /><!--- and this one has code bits would you believe! --->
	<cfset ret = request.wiki_render.init(SubSiteID="#request.SLCMS.PageParams.SubSiteID#", TablePath="#thisTag.wikiDBtablePath#") />
	<cfset ret = request.wiki_code.init(SubSiteID="#request.SLCMS.PageParams.SubSiteID#", TablePath="#thisTag.wikiDBtablePath#") />
	<cfif not thisTag.flagIsInEditMode>
		<cfset request.wiki_disp=createObject('component','#application.SLCMS.Config.base.MapURL##application.SLCMS.Config.base.SLCMSCoreRelPath#CFCs/wiki_disp') /><!--- and this one has the overall display creating bits bits --->
		<cfset ret = request.wiki_disp.init(SubSiteID="#request.SLCMS.PageParams.SubSiteID#", TablePath="#thisTag.wikiDBtablePath#") />
		<cfif thisTag.theContentControlData.EditorMode eq "WYSIWYG">
	  	<!--- we used an html editor so just render the wiki-type links on the content --->
			<cfset thisTag.theContent = request.wiki_render.render_links(string="#thisTag.theContent#", webpath="#application.SLCMS.Config.Base.rootURL#content.cfm#request.SLCMS.PageParams.wikibits.wikiHomePathEncoded#/")>
		<cfelseif thisTag.theContentControlData.EditorMode eq "wiki">
			<!--- its full wiki so fully process --->
		  <cfset thisTag.theContent = request.wiki_render.RenderPage(PageContent="#thisTag.theContent#", webpath="#application.SLCMS.Config.Base.rootURL#content.cfm#request.SLCMS.PageParams.wikibits.wikiHomePathEncoded#/")>
	  <cfelse>
	  	<!--- assume we used an html editor in legacy database data so just do the links --->
			<cfset thisTag.theContent = request.wiki_render.render_links(string="#thisTag.theContent#", webpath="#application.SLCMS.Config.Base.rootURL#content.cfm#request.SLCMS.PageParams.wikibits.wikiHomePathEncoded#/")>
		</cfif>
	</cfif>	<!--- end: not in edit mode --->
	<cfif thisTag.theContent eq "">
		<cfset thisTag.theContent = "There is no content in this wiki page" />
	</cfif>

<!--- 
<cfdump var="#thisTag.theContentControlData#" expand="false"><br>

<cfabort>
 --->
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
			<cfif thisTag.theContentControlData.EditorMode eq "WYSIWYG">
				<div class="ContentContainer_Controls_EditButton">	<!--- the edit button floats to the right --->
					<input type="image" name="EditButton" value="EditContainer_WYSIWYG" src="#request.SLCMS.rootURL#SLCMS/SLCMSstyling/nbutton_edit.gif" border="0" title="Edit the Content in this Container with a WYSIWYG Editor">
				</div>
			<cfelseif thisTag.theContentControlData.EditorMode eq "wiki">
				<div class="ContentContainer_Controls_EditButton">	<!--- the edit button floats to the right --->
					<input type="image" name="EditButton" value="EditContainer_wiki" src="#request.SLCMS.rootURL#SLCMS/SLCMSstyling/nbutton_edit.gif" border="0" title="Edit the Content in this Container with wiki-style controls">
				</div>
			<cfelse>
				<!--- its neither so it must be a new wiki page that has no content yet --->
				<div class="ContentContainer_Controls_EditButton">	<!--- the edit button floats to the right --->
					<input type="image" name="EditButton" value="EditContainer_WYSIWYG" src="#request.SLCMS.rootURL#SLCMS/SLCMSstyling/nbutton_edit.gif" border="0" title="Edit the Content in this Container with a WYSIWYG Editor">
					<input type="image" name="EditButton" value="EditContainer_wiki" src="#request.SLCMS.rootURL#SLCMS/SLCMSstyling/nbutton_edit.gif" border="0" title="Edit the Content in this Container with wiki-style controls">
				</div>
			</cfif>
				<div class="ContentContainer_Controls_Heading">#thisTag.theEditHeading#</div>	<!--- the text heading on the left --->
				<span class="ContentContainer_Center">	<!--- the centered other stuff --->
				<cfif thisTag.IsEditor>	<!--- Editors can publish, the author can't --->
					<cfif thisTag.theContentControlData.VersionOutCount gt 0 and thisTag.theContentControlData.ContentStatus eq "Live">
						This is the published version, there <cfif thisTag.theContentControlData.VersionOutCount neq 1>are<cfelse>is</cfif> #thisTag.theContentControlData.VersionOutCount# newer version<cfif thisTag.theContentControlData.VersionOutCount neq 1>s</cfif>.
						<input type="image" name="ListVersions" value="List Other Versions" src="#request.SLCMS.rootURL#SLCMS/SLCMSstyling/nbutton_ListOtherVersions.gif" border="0" title="List Other Versions of this content">
						or 
						<input type="image" name="LatestVersion" value="See Latest Version" src="#request.SLCMS.rootURL#SLCMS/SLCMSstyling/nbutton_SeeLatestVersion.gif" border="0" title="See Latest Version of this content">
					<cfelseif thisTag.theContentControlData.VersionOutCount gt 0 and thisTag.theContentControlData.ContentStatus eq "Latest">
						<cfif thisTag.theContentControlData.VersionOutCount eq 1>
							This is the latest version, the currently published version is the previous version.
						<cfelse>
							This is the latest version, it is #thisTag.theContentControlData.VersionOutCount# version<cfif thisTag.theContentControlData.VersionOutCount neq 1>s</cfif> newer than the currently published version.
						</cfif>
						<input type="image" name="PublishButton" value="Publish_Version" src="#request.SLCMS.rootURL#SLCMS/SLCMSstyling/nbutton_publish.gif" border="0" title="Publish this content">
						or 
						<input type="image" name="ListVersions" value="LIst Other Versions" src="#request.SLCMS.rootURL#SLCMS/SLCMSstyling/nbutton_ListOtherVersions.gif" border="0" title="List Other Versions of this content">
					<cfelseif thisTag.theContentControlData.VersionOutCount gt 0 and thisTag.theContentControlData.ContentStatus neq "Live">
						There <cfif thisTag.theContentControlData.VersionOutCount neq 1>are<cfelse>is</cfif> #thisTag.theContentControlData.VersionOutCount# version<cfif thisTag.theContentControlData.VersionOutCount neq 1>s</cfif> newer than the currently published version.
						<input type="image" name="PublishButton" value="Publish_Version" src="#request.SLCMS.rootURL#SLCMS/SLCMSstyling/nbutton_publish.gif" border="0" title="Publish this content">
						or 
						<input type="image" name="ListVersions" value="List Other Versions" src="#request.SLCMS.rootURL#SLCMS/SLCMSstyling/nbutton_ListOtherVersions.gif" border="0" title="List Other Versions of this content">
						or 
						<input type="image" name="LatestVersion" value="See Latest Version" src="#request.SLCMS.rootURL#SLCMS/SLCMSstyling/nbutton_SeeLatestVersion.gif" border="0" title="See Latest Version of this content">
					<cfelseif thisTag.theContentControlData.VersionOutCount lt 0 and thisTag.theContentControlData.ContentStatus neq "Live">
						This version is #abs(thisTag.theContentControlData.VersionOutCount)# version<cfif thisTag.theContentControlData.VersionOutCount neq -1>s</cfif> older than the currently published version.
						<input type="image" name="PublishButton" value="Publish_Version" src="#request.SLCMS.rootURL#SLCMS/SLCMSstyling/nbutton_publish.gif" border="0" title="Publish this content">
						or 
						<input type="image" name="ListVersions" value="List Other Versions" src="#request.SLCMS.rootURL#SLCMS/SLCMSstyling/nbutton_ListOtherVersions.gif" border="0" title="List Other Versions of this content">
						or 
						<input type="image" name="LatestVersion" value="See Latest Version" src="#request.SLCMS.rootURL#SLCMS/SLCMSstyling/nbutton_SeeLatestVersion.gif" border="0" title="See Latest Version of this content">
					<cfelseif thisTag.theContentControlData.VersionOutCount eq 0 and thisTag.theContentControlData.ContentID eq 0>	<!--- new content, not yet published? --->
						No Content yet.
					<cfelseif thisTag.theContentControlData.VersionOutCount eq 0 and not thisTag.theContentControlData.LiveVersion>
		  			<cfif thisTag.theContentControlData.VersionOutCount neq 1>
							No content has yet been published, there are #thisTag.theContentControlData.VersionOutCount# versions of the content.
						<cfelse>
							No content has yet been published, there is one version of the content.
						</cfif>
						<input type="image" name="PublishButton" value="Publish_Version" src="#request.SLCMS.rootURL#SLCMS/SLCMSstyling/nbutton_publish.gif" border="0" title="Publish this content">
						or 
						<input type="image" name="ListVersions" value="List Other Versions" src="#request.SLCMS.rootURL#SLCMS/SLCMSstyling/nbutton_ListOtherVersions.gif" border="0" title="List Other Versions of this content">
					<cfelseif thisTag.theContentControlData.VersionOutCount eq "" and not thisTag.theContentControlData.LiveVersion>
						No content has yet been published, there are other versions, this is <cfif thisTag.theContentControlData.Version eq 0>the latest version<cfelse>version #thisTag.theContentControlData.Version#</cfif>. 
						<input type="image" name="PublishButton" value="Publish_Version" src="#request.SLCMS.rootURL#SLCMS/SLCMSstyling/nbutton_publish.gif" border="0" title="Publish this content">
						or 
						<input type="image" name="ListVersions" value="List Other Versions" src="#request.SLCMS.rootURL#SLCMS/SLCMSstyling/nbutton_ListOtherVersions.gif" border="0" title="List Other Versions of this content">
					<cfelseif thisTag.theContentControlData.VersionOutCount eq 0 and thisTag.theContentControlData.LiveVersion>
						This content is the currently published version.&nbsp;
						<input type="image" name="ListVersions" value="List Other Versions" src="#request.SLCMS.rootURL#SLCMS/SLCMSstyling/nbutton_ListOtherVersions.gif" border="0" title="List Other Versions of this content">
					</cfif>	<!--- end: what version information and controls to show --->
				</cfif>	<!--- end: is editor --->
				</span>
				</form>
			</cfif>
			</div>	<!--- end: container controls div --->
			</div>	<!--- end: container controls marker div --->
			<!--- we see the tool buttons so push the content below them if styled that way --->
			<div class="ContentContainer_Controls_Clear"></div>
		</cfif>
	<cfelse>
	</cfif>
	<!--- see if we have to edit this container or show stuff --->
	<cfif thisTag.theContentControlData.ContentID eq -1 or not thisTag.flagIsInEditMode>
		<!--- no edit so see what we have to show --->
		<cfif thisTag.flagIsInShowVersionsMode>
			<cfset thisTag.FirstRow = True />
		<!--- 
		<cfdump var="#thisTag.VersionsQuery#" expand="false">
		 --->
			<table cellpadding="3" cellspacing="0">
				<tr>
					<th></th>
					<th>Edit Date</th>
					<th align="center" style="text-align:center;">View</th>
					<th>Status</th>
					<th>Edited By &nbsp;</th>
					<th>Published By</th>
				</tr>
			<cfloop query="thisTag.VersionsQuery">
				<tr>
					<td>&nbsp;</td>
					<td>#DateFormat(thisTag.VersionsQuery.VersionTimeStamp, "dd-mmm-yy")#</td>
					<td align="center" style="text-align:center;">
						<input type="radio" name="ChosenVersion" value="#thisTag.VersionsQuery.Version#">
						<!--- 
						<input type="radio" name="ContentID" value="#thisTag.VersionsQuery.ContentID#">
						 --->
					</td>
					<td><cfif thisTag.FirstRow>Latest Version </cfif><cfif thisTag.VersionsQuery.flag_LiveVersion>Published Version</cfif></td>
					<td>
						<cfset theUsersDetails = application.SLCMS.Core.UserControl.getUserDetails_Staff(StaffID="#thisTag.VersionsQuery.UserID_EditedBy#") />
						<cfif (not StructIsEmpty(theUsersDetails)) and theUsersDetails.NameDetails.Staff_FullName neq "">
							#theUsersDetails.NameDetails.Staff_FullName#
						<cfelse>
							&nbsp; &nbsp; - 
						</cfif>
					</td>
					<td>
						<cfset theUsersDetails = application.SLCMS.Core.UserControl.getUserDetails_Staff(StaffID="#thisTag.VersionsQuery.UserID_PublishedBy#") />
						<cfif (not StructIsEmpty(theUsersDetails)) and theUsersDetails.NameDetails.Staff_FullName neq "">
							#theUsersDetails.NameDetails.Staff_FullName#
						<cfelse>
							&nbsp; &nbsp; - 
						</cfif>
					</td>
				</tr>
				<cfset thisTag.FirstRow = False />
			</cfloop>	<!--- end: loop over versions --->
				<tr>
					<td></td>
					<td>
						<input type="image" name="ViewThisVersion" value="Cancel" src="#request.SLCMS.rootURL#SLCMS/SLCMSstyling/nbutton_cancel.gif" border="0" title="Back to published version">
					</td>
					<td align="center" style="text-align:center;">
						<input type="image" name="ViewThisVersion" value="View" src="#request.SLCMS.rootURL#SLCMS/SLCMSstyling/nbutton_View.gif" border="0" title="View Selected Version of this content">
					</td>
					<td></td>
					<td></td>
					<td></td>
				</tr>
			</table>
			</form>
		
		<cfelse>
			<!--- nothing special so put the content on the page --->
			<!--- as its a wiki we need to wrap it and show the discussion tabs, etc --->
			<div class="wikiContainer_Tab_Wrapper">
				<!--- tabs go here --->
			</div>
			<div class="wikiContainer_Content_Wrapper">
			#thisTag.theContent#
			</div>
		</cfif>

	<cfelse>
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
		<cfelseif StructKeyExists(form, "EditButton") and form.EditButton eq "EditContainer_wiki">
			<input type="hidden" name="EditMode" value="wiki">
			<cfset request.EditorControl.EditorToUse = "" />	<!--- this turns off all of the wysiwyg editors --->
		<cfelse>
			<input type="hidden" name="EditMode" value="">
		</cfif>
		
		<cfinclude template="_wysiwygEditors_inc.cfm">

		<div class="ContentContainer_UnderButtonsWrapper">
			<div class="ContentContainer_UnderButtonsLeft">	<!--- put save and cancel buttons neatly under for better usability --->
			<input type="image" name="SaveButton" value="Save" src="#request.SLCMS.rootURL#SLCMS/SLCMSstyling/nbutton_save.gif" class="ContentContainer_ControlButtonsUnder" title="Save Content">
			<input type="image" name="CancelButton" value="Cancel" src="#request.SLCMS.rootURL#SLCMS/SLCMSstyling/nbutton_cancel.gif" class="ContentContainer_ControlButtonsUnder" title="Cancel Editing">
			</div>
			<cfif thisTag.theContentControlData.EditorMode eq "wiki">
				<div class="ContentContainer_UnderButtonsHelp">
	       	<span id="ContentContainer_WikiHelpShowButton">
						<input type="image" id="WikiHelpShowButton" name="WikiHelpShowButton" value="Show Text Formatting Hints:" src="#request.SLCMS.rootURL#SLCMS/SLCMSstyling/nbutton_ShowTextFormattingHints.gif" border="0" title="Show Text Formatting Hints" onclick="return ShowWikiHelpText()">
						</span>
					<span id="ContentContainer_WikiHelpText">
						<input type="image" id="WikiHelpShowButton" name="WikiHelpShowButton" value="Hide Text Formatting Hints:" src="#request.SLCMS.rootURL#SLCMS/SLCMSstyling/nbutton_HideTextFormattingHints.gif" border="0" title="Hide Text Formatting Hints" onclick="return HideWikiHelpText()">
						#request.wiki_render.instructions()#
					</span>
				</div>
				<script type="text/javascript">
					document.getElementById('ContentContainer_WikiHelpShowButton').style.display='inline'
					document.getElementById('ContentContainer_WikiHelpText').style.display='none'
					function ShowWikiHelpText() {
						document.getElementById('ContentContainer_WikiHelpShowButton').style.display='none'
						document.getElementById('ContentContainer_WikiHelpText').style.display='inline'
						return false
					}
					function HideWikiHelpText() {
						document.getElementById('ContentContainer_WikiHelpShowButton').style.display='inline'
						document.getElementById('ContentContainer_WikiHelpText').style.display='none'
						return false
					}
				</script>
			</cfif>
		</div>
		</form>
		<div style="clear:both; min-width:500px"></div>
	</cfif>
	<cfif thisTag.IsAuthor>
		</div><!--- end: div for ContentContainer_Marker, to show where the container is when logged in --->
	</cfif>
	</div><!--- end: div for ContentContainer_Wrapper, for styling --->
	</cfoutput> 
</cfif>

<cfif thisTag.executionMode IS "end"></cfif>
<cfsetting enablecfoutputonly="No">