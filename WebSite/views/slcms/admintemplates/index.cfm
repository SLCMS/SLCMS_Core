

<!--- first some portal related code --->
 <cfif request.SLCMS.PortalAllowed>
	<cfset theAllowedSubsiteList = application.SLCMS.core.PortalControl.GetAllowedSubSiteIDList_AllSites(UserID="#session.SLCMS.user.UserID#") />
	<cfif request.SLCMS.modes.WorkMode0 eq "ChangeSubSite" and IsDefined("url.NewSubSiteID") and IsNumeric(url.NewSubSiteID)>
		<!--- set a new current state --->
		<cfset session.SLCMS.Currents.Admin.templates.CurrentSubSiteID = url.NewSubSiteID />
		<cfset session.SLCMS.Currents.Admin.templates.CurrentSubSiteFriendlyName = application.SLCMS.core.PortalControl.GetSubSite(url.NewSubSiteID).data.SubSiteFriendlyName />
		<cfset request.SLCMS.modes.WorkMode1 = "InitialEntry" />
		<cfset request.SLCMS.modes.WorkMode2 = "" />
		<cfset request.SLCMS.modes.DispMode = "ViewTypes" />
		
	<cfelseif request.SLCMS.modes.WorkMode0 eq "xxx" >	<!--- next request.SLCMS.modes.WorkMode0 --->
	
	<cfelse>	<!--- no request.SLCMS.modes.WorkMode0 so set up defaults/currents --->
	</cfif>
<cfelse>
	<!--- no portal ability so force to site zero --->
	<cfset theAllowedSubsiteList = "0" />
</cfif>


<!--- the workflows --->
<cfif request.SLCMS.modes.WorkMode1 eq "InitialEntry">
	<!--- do first time in so grab the templates and types --->
	<cfset theTemplateVariables = application.SLCMS.core.Templates.getVariablesScope() />
	
<cfelseif request.SLCMS.modes.WorkMode1 eq "ViewTypesSets">
	<cfset theTemplateType = url.Type />
	<cfset theTemplates = application.SLCMS.core.Templates.getTemplateTypeDataStruct(TemplateType=theTemplateType, SubSiteID="#session.SLCMS.Currents.Admin.templates.CurrentSubSiteID#") />
	<cfset request.SLCMS.modes.DispMode = "ShowTypesTemplates"  />
	
<cfelseif request.SLCMS.modes.WorkMode1 eq "ViewTemplateSet">
	<cfset theTemplateType = url.Type />
	<cfset theTemplateSet = url.Set />
	<cfset request.SLCMS.modes.WorkMode2 = "getSingleTemplateSetParams"  />
	<cfset request.SLCMS.modes.DispMode = "ShowSingleTemplateSet"  />
	
<cfelseif request.SLCMS.modes.WorkMode1 eq "AddSet">
	<cfset theTemplateVariables = application.SLCMS.core.Templates.getVariablesScope() />
	<cfset theTemplateType = url.CurrentType />
	<cfset hNextMode = "SaveNewSet" />
	<cfset dSetName = "" />
	<cfset request.SLCMS.modes.DispMode = "AddSet"  />
	
<cfelseif request.SLCMS.modes.WorkMode1 eq "SaveNewSet">
	<!--- just some simple validation for the moment --->
	<cfif form.nextmode eq "SaveNewSet" and ListFindNoCase(application.SLCMS.core.Templates.getTemplateTypeList(), form.TemplateType)>
		<cfset ret = application.SLCMS.core.Templates.CreateTemplateSet(SetName="#form.SetName#", TemplateType="#form.TemplateType#", SubSiteID="#session.SLCMS.Currents.Admin.templates.CurrentSubSiteID#") />
		<cfset theTemplateSet = "#form.SetName#" />
		<cfset theTemplateType = "#form.TemplateType#" />
		<cfset request.SLCMS.modes.WorkMode2 = "getSingleTemplateSetParams"  />
		<cfset request.SLCMS.modes.DispMode = "ShowSingleTemplateSet"  />
	<cfelse>
		<cfset ErrMsg  = "validation failed">
		<!--- reload the vars and go back and try again --->
		<cfset theTemplateVariables = application.SLCMS.core.Templates.getVariablesScope() />
		<cfset theTemplateType = form.TemplateType />
		<cfset hNextMode = "SaveNewSet" />
		<cfset dSetName = form.SetName />
		<cfset request.SLCMS.modes.DispMode = "AddSet"  />
	</cfif>
	
<cfelseif request.SLCMS.modes.WorkMode1 eq "AddTemplate">
	<cfset theTemplateType = url.CurrentType />
	<cfset theTemplates = application.SLCMS.core.Templates.getTemplateTypeDataStruct(TemplateType=theTemplateType, SubSiteID="#session.SLCMS.Currents.Admin.templates.CurrentSubSiteID#") />
	<cfset theTemplateSet = url.CurrentSet />
	<cfset theSubset = url.CurrentSubSet />
	<cfset theFormPlacement = theSubset />
	<cfswitch expression="#theSubset#">
		<cfcase value="Templates">
			<cfset thisPresentationString1 = "Template" />
			<cfset thisPresentationString2 = "Template" />
			<cfset ShowFileNameNotItemName = False />
		</cfcase>
		<cfcase value="TemplateIncludes">
			<cfset thisPresentationString1 = "Template Include File" />
			<cfset thisPresentationString2 = "Template Include" />
			<cfset ShowFileNameNotItemName = False />
		</cfcase>
		<cfcase value="TemplateGraphics">
			<cfset thisPresentationString1 = "Template Graphic" />
			<cfset thisPresentationString2 = "Template Graphic" />
			<cfset ShowFileNameNotItemName = True />
		</cfcase>
		<cfcase value="StyleSheets">
			<cfset thisPresentationString1 = "StyleSheet" />
			<cfset thisPresentationString2 = "StyleSheet" />
			<cfset ShowFileNameNotItemName = True />
		</cfcase>
		<cfcase value="StylingGraphics">
			<cfset thisPresentationString1 = "Styling Graphic" />
			<cfset thisPresentationString2 = "Styling Graphic" />
			<cfset ShowFileNameNotItemName = True />
		</cfcase>
		<cfcase value="NavigationControl">
			<cfset thisPresentationString1 = "Navigation Control File" />
			<cfset thisPresentationString2 = "Navigation Control" />
			<cfset ShowFileNameNotItemName = False />
		</cfcase>
		<cfdefaultcase>
			<cfset thisPresentationString1 = "Template" />
			<cfset thisPresentationString2 = "Template" />
			<cfset ShowFileNameNotItemName = False />
		</cfdefaultcase>
	</cfswitch>
	<cfset hNextMode = "SaveNewTemplate" />
	<cfset dTemplateName = "" />
	<cfset request.SLCMS.modes.DispMode = "AddTemplate" />
	
<cfelseif request.SLCMS.modes.WorkMode1 eq "SaveNewTemplate">
	<!--- just some simple validation for the moment --->
	<cfif StructKeyExists(form, "Cancel") and form.Cancel eq "Cancel">
		<cfset DoIt = False />
	<cfelse>
		<cfset DoIt = True />
	</cfif>
	<cfif DoIt>
		<cfif form.nextmode eq "SaveNewTemplate" and ListFindNoCase(application.SLCMS.core.Templates.getTemplateTypeList(), form.TemplateType)>
			<!--- we are going to upload to a temp folder so we can check names, etc, then copy over to the correct template set folder --->
			<cfset theTempFolderName = CreateUUID() />
			<cfset theTempDestPath = "#application.SLCMS.Config.StartUp.SiteBasePath#Admin/UploadTemp/#theTempFolderName#" />
			<cfdirectory action="create" directory="#theTempDestPath#">
			<cfset theTemplateType = form.TemplateType />
			<cfset theTemplateSet = form.TemplateSet />
			<cfset theSubset = form.SubSet />
			<cfset theFinalDestPath = application.SLCMS.core.Templates.getTemplateSetPhysicalPath(TemplateType="#theTemplateType#", TemplateSet="#theTemplateSet#", Subset="#theSubset#", SubSiteID="#session.SLCMS.Currents.Admin.templates.CurrentSubSiteID#") />
			<cfif theFinalDestPath neq "">	<!--- this is an error check to make sure we haven't a funny --->
				<!--- now upload the file to our temp directory so we can make more checks --->
				<cffile action="upload" filefield="TemplateFile" destination="#theTempDestPath#" nameconflict="makeunique">
				<cfset theTemplateFileName = cffile.ServerFile />
				<!--- compare this name with what is already there --->
				<cfif FileExists(theFinalDestPath & theTemplateFileName)>
					<!--- a file does exists already so flag that --->
					<cfset GoodMsg  = "A Template of that name existed, it was backed up">
				</cfif>
				<!--- copy the template across and do structures and things --->
				<cfset ret = application.SLCMS.core.Templates.AddTemplate(FileName="#theTemplateFileName#", Subset="#theSubset#", TemplateSet="#form.TemplateSet#", TemplateType="#form.TemplateType#", TemplateFileSource="#theTempDestPath#/", SubSiteID="#session.SLCMS.Currents.Admin.templates.CurrentSubSiteID#") />
				<cfif ret.error.errorcode eq 0>
					<cfdirectory action="delete" directory="#theTempDestPath#">
				<cfelse>
					<cfset ErrMsg  = "AddTemplate() Failed. Error was #ret.error.errorText#">
				</cfif>
				<!--- 
				<cfdump var="#cffile#" expand="false">
			
			<cfabort>
	
	
			<cfif FileExists(theFileDestPath)>
			</cfif>
			
				<cfdump var="#ret#">
	 --->
			<cfelse>
				<cfset ErrMsg  = "No Set Folder Found">
			</cfif>
		<cfelse>
			<cfset ErrMsg  = "validation failed">
		</cfif>	<!--- end: valid input --->
		<cfif ErrMsg neq "">
			<!--- reload the vars and go back and try again --->
			<cfset theTemplates = application.SLCMS.core.Templates.getTemplateTypeDataStruct(TemplateType=theTemplateType, SubSiteID="#session.SLCMS.Currents.Admin.templates.CurrentSubSiteID#") />
			<cfset theTemplateType = form.TemplateType />
			<cfset hNextMode = "SaveNewTemplate" />
			<cfset dTemplateName = "" />
			<cfset theTemplateSet = form.TemplateSet />
			<cfset request.SLCMS.modes.DispMode = "AddTemplate"  />
		<cfelse>
			<!--- put bit here to show single or all depending on where we came from? --->
			<cfset theTemplateType = form.TemplateType />
			<cfset theTemplateSet = form.TemplateSet />
			<cfset request.SLCMS.modes.WorkMode2 = "getSingleTemplateSetParams"  />
			<cfset request.SLCMS.modes.DispMode = "ShowSingleTemplateSet"  />
		</cfif>
	<cfelse>
		<cfset theTemplateType = form.TemplateType />
		<cfset theTemplateSet = form.TemplateSet />
		<cfset request.SLCMS.modes.WorkMode2 = "getSingleTemplateSetParams"  />
		<cfset request.SLCMS.modes.DispMode = "ShowSingleTemplateSet"  />
	</cfif>	<!--- end: ok to do it --->
	
<cfelseif request.SLCMS.modes.WorkMode1 eq "MakeActive">
	<cfset theTemplateType = url.CurrentType />
	<cfset theTemplateSet = url.CurrentSet />
	<cfset theSubset = url.CurrentSubSet />
	<cfset theTemplate = url.CurrentTemplate />
	<cfset ret = application.SLCMS.core.Templates.ActivateTemplate(TemplateName="#theTemplate#", TemplateSet="#theTemplateSet#", TemplateType="#theTemplateType#", Subset="#theSubset#", SubSiteID="#session.SLCMS.Currents.Admin.templates.CurrentSubSiteID#") />
	<cfset request.SLCMS.modes.WorkMode2 = "getSingleTemplateSetParams"  />
	<cfset request.SLCMS.modes.DispMode = "ShowSingleTemplateSet"  />
	
<cfelseif request.SLCMS.modes.WorkMode1 eq "MakeInactive">
	<cfset theTemplateType = url.CurrentType />
	<cfset theTemplateSet = url.CurrentSet />
	<cfset theSubset = url.CurrentSubSet />
	<cfset theTemplate = url.CurrentTemplate />
	<cfset ret = application.SLCMS.core.Templates.InactivateTemplate(TemplateName="#theTemplate#", TemplateSet="#theTemplateSet#", TemplateType="#theTemplateType#", Subset="#theSubset#", SubSiteID="#session.SLCMS.Currents.Admin.templates.CurrentSubSiteID#") />
	<cfset request.SLCMS.modes.WorkMode2 = "getSingleTemplateSetParams"  />
	<cfset request.SLCMS.modes.DispMode = "ShowSingleTemplateSet"  />
	
<cfelseif request.SLCMS.modes.WorkMode1 eq "Download">
	<cfset theTemplateType = url.CurrentType />
	<cfset theTemplateState = url.CurrentState />
	<cfset theTemplateSet = url.CurrentSet />
	<cfset theSubset = url.CurrentSubSet />
	<cfset theTemplate = url.CurrentTemplate />
	<cfset theFinalDestPath = application.SLCMS.core.Templates.getTemplateSetPhysicalPath(TemplateType="#theTemplateType#", TemplateSet="#theTemplateSet#", Subset="#theSubset#", SubSiteID="#session.SLCMS.Currents.Admin.templates.CurrentSubSiteID#") />
	<cfif theTemplateState eq "Inactive">
		<cfset theFinalDestPath = theFinalDestPath & "Inactive/" />
	</cfif>
	<cfset theFinalDestPath = theFinalDestPath & theTemplate />
	<cfif FileExists("#theFinalDestPath#")>
		<!--- now send the file --->
			<cfheader name="Content-Disposition" value="attachment; filename=#theTemplate#">
			<cfcontent type = "text/plain" file = "#theFinalDestPath#" deleteFile = "no">
<!--- 
		<cfif theSubset eq "Templates" or theSubset eq "TemplateIncludes">
			<cfheader name="Content-Disposition" value="attachment; filename=#theTemplate#.cfm">
			<cfcontent type = "text/html" file = "#theFinalDestPath#" deleteFile = "no">
		<cfelseif theSubset eq "NavigationControl">
			<cfheader name="Content-Disposition" value="attachment; filename=#theTemplate#.ini">
			<cfcontent type = "text/html" file = "#theFinalDestPath#" deleteFile = "no">
		<cfelse>
			<cfheader name="Content-Disposition" value="attachment; filename=#theTemplate#.cfm">
			<cfcontent type = "text/html" file = "#theFinalDestPath#" deleteFile = "no">
		</cfif>
 --->
	<cfelse>
		<cfset ErrMsg  = "Template not Found">
	</cfif>
	<cfset request.SLCMS.modes.WorkMode2 = "getSingleTemplateSetParams"  />
	<cfset request.SLCMS.modes.DispMode = "ShowSingleTemplateSet"  />
</cfif>

<cfif request.SLCMS.modes.WorkMode2 eq "getSingleTemplateSetParams" or request.SLCMS.modes.WorkMode2 eq "AddTemplate">
	<!--- do something --->
	<cfset theTemplates = application.SLCMS.core.Templates.getTemplateTypeDataStruct(TemplateType=theTemplateType, SubSiteID="#session.SLCMS.Currents.Admin.templates.CurrentSubSiteID#") />
	<cfset theSubsetList = application.SLCMS.core.Templates.getTemplateSubsetTypeList() />
	<!--- 
	<cfset request.SLCMS.modes.DispMode = "ShowSingleTemplateSet"  />
		<cfdump var="#application.SLCMS.core.Templates.getVariablesScope()#" expand="false" label="templates getVariablesScope()">
		<cfdump var="#theTemplates#" label="theTemplates" expand="false">
		<cfabort>
	 --->

</cfif>
<!--- 
		<cfdump var="#application.SLCMS.core.Templates.getVariablesScope()#" expand="false">
		<cfdump var="#theTemplates#" label="theTemplates" expand="false">
 --->
<!--- 
</cfsilent>
 --->

<cfoutput>#includePartial("/slcms/adminbanner")#</cfoutput><!--- show the banner if we are in the backend, returns nothing if we are popped up --->
<cfif request.SLCMS.modes.DispMode neq "ViewTypes">
	<cfoutput>
	| #linkTo(text="Back to Template Management Home Page", controller="slcms.admin-templates", action="index", params="#PageContextFlags.ReturnLinkParams#")#</cfoutput>
</cfif>

<cfif request.SLCMS.modes.DispMode eq "ShowTypesTemplates">
	<table border="0" cellpadding="3" cellspacing="0" class="worktable">
		<tr>
			<td colspan="5">
			<cfif request.SLCMS.PortalAllowed>
				<cfif ListLen(theAllowedSubsiteList) gt 1>
					<div id="SubSiteLinksWrapper">
						<cfset lcntr = 0 />
						<p>This website is a portal. You can manage the templates in the following subsites:</p>
						<p>
						<cfloop list="#theAllowedSubsiteList#" index="thisSubSite">
							<span class="<cfif lcntr eq 0>LeftEnd<cfelseif lcntr mod 2 eq 1>OddNumbered<cfelse>EvenNumbered</cfif>">
							<cfset thisSubsiteDetails = application.SLCMS.core.PortalControl.GetSubSite(thisSubSite).data />
							<cfoutput>
							<cfif thisSubsiteDetails.SubSiteID eq 0>
								<cfif thisSubsiteDetails.SubSiteFriendlyName eq "Top">
									The #linkTo(text="Top Site", controller="slcms.admin-templates", action="index", params="#PageContextFlags.ReturnLinkParams#&amp;job=ChangeSubSite&amp;NewSubSiteID=0")#
									<!--- 
									<a href="Admin_Templates.cfm?job=ChangeSubSite&amp;NewSubSiteID=0">Top Site</a>
									 --->
								<cfelse>
									The Top Site (called &quot;#linkTo(text="#thisSubsiteDetails.SubSiteFriendlyName#", controller="slcms.admin-templates", action="index", params="#PageContextFlags.ReturnLinkParams#&amp;job=ChangeSubSite&amp;NewSubSiteID=0")#&quot;)
									<!--- 
									<a href="Admin_Templates.cfm?job=ChangeSubSite&amp;NewSubSiteID=0">#thisSubsiteDetails.SubSiteFriendlyName#</a>
									 --->
									
								</cfif>
							<cfelse>
								Site: &quot;#linkTo(text="#thisSubsiteDetails.SubSiteFriendlyName#", controller="slcms.admin-templates", action="index", params="#PageContextFlags.ReturnLinkParams#&amp;job=ChangeSubSite&amp;NewSubSiteID=#thisSubsiteDetails.SubSiteID#")#&quot;
								<!--- 
								<a href="Admin_Templates.cfm?job=ChangeSubSite&amp;NewSubSiteID=#thisSubsiteDetails.SubSiteID#">#thisSubsiteDetails.SubSiteFriendlyName#</a>
								 --->
							</cfif>
							</cfoutput> 
							</span>
							<cfset lcntr = lcntr+1 />
						</cfloop>
					</p></div>
					<div>You are currently looking at site: <span class="majorheading"><cfoutput>#session.SLCMS.Currents.Admin.Templates.CurrentSubSiteFriendlyName#</cfoutput></span>
					</div>				
				<cfelse>
					<p>This website is a portal.</p>
					<p>You can manage the page structure in the site: <span class="majorheading"><cfoutput>#session.SLCMS.Currents.Admin.Templates.CurrentSubSiteFriendlyName#</cfoutput></span></p>
				</cfif>	<!--- end: one of more subsites --->
			</cfif>	<!--- end: portal allowed --->
			</td>
		</tr>
		<tr><td colspan="5"></td></tr>
		<tr><cfoutput>
			<td colspan="5"><span class="minorheadingName">#theTemplateType#</span> <span class="minorheadingText">Templates</span></td>
		</tr>
	<tr>
		<td colspan="1" class="WorkTableTopRow" align="center"><u>Template Set</u></td>
		<td colspan="1" class="WorkTableTopRow"><u>Template Name</u></td>
		<!--- 
		<td colspan="1" rowspan="2" align="center" class="WorkTableTopRow">&nbsp;</td>
		<td colspan="2" rowspan="2" align="center" class="WorkTableTopRow">&nbsp;</td>
		 --->
		<td colspan="3" class="WorkTableTopRowRHCol">
			#linkTo(text="Add a Template Set", controller="slcms.admin-templates", action="index", params="#PageContextFlags.ReturnLinkParams#&amp;job=AddSet&amp;CurrentType=#theTemplateType#")#
			<!--- 
			<a href="Admin_Templates.cfm?job=AddSet&amp;CurrentType=#theTemplateType#">Add a Template Set</a>
			 --->
		</td>
	</tr>
	<cfset flagBigLoopFirst = True />
	<cfloop list="#theTemplates.TemplateSetList#" index="thisTemplateFolder">
		<cfif not flagBigLoopFirst or 1 eq 1>
			<tr><td colspan="5" class="WorkTableRowColour2withRH"></td></tr>
		</cfif>
		<cfset flagBigLoopFirst = False />
		<tr>
			<td colspan="1" class="WorkTableRowColour1" align="center"><span class="minorheadingName">#thisTemplateFolder#</span></td>
			<td colspan="1" class="WorkTableRowColour1">
				#linkTo(text="View all items", controller="slcms.admin-templates", action="index", params="#PageContextFlags.ReturnLinkParams#&amp;job=ViewTemplateSet&amp;Set=#thisTemplateFolder#&amp;Type=#theTemplateType#")#
				<!--- 
				<a href="Admin_Templates.cfm?job=ViewTemplateSet&amp;Set=#thisTemplateFolder#&amp;Type=#theTemplateType#">View all items</a> 
				 --->
				in #thisTemplateFolder#
			</td>
			<td colspan="3" class="WorkTableRowColour1RHCol">
				#linkTo(text="Add a Template", controller="slcms.admin-templates", action="index", params="#PageContextFlags.ReturnLinkParams#&amp;job=addTemplate&amp;CurrentSet=#thisTemplateFolder#&amp;CurrentType=#theTemplateType#")#
				<!--- 
				<a href="Admin_Templates.cfm?job=addTemplate&amp;CurrentSet=#thisTemplateFolder#&amp;CurrentType=#theTemplateType#">Add a Template</a>
				 --->
				 to #thisTemplateFolder#
				<!--- 
				<a href="Admin_Templates.cfm?job=HideSet&amp;CurrentSet=#thisTemplateFolder#&amp;CurrentType=#theTemplateType#">Make this Set inactive</a>
				 --->&nbsp;
			</td>
		</tr>
		<!--- 
		<cfdump var="#theTemplates.Templates[thisTemplateFolder]#">
		<cfabort>
		 --->
		<cfset flagFirst = True />
		<cfloop collection="#theTemplates.TemplateSets[thisTemplateFolder].Templates.Active.Items#" item="thisTemplate">
			<cfset thisbackupCount = theTemplates.TemplateSets[thisTemplateFolder].Templates.Active.Items["#thisTemplate#"].BackupCount>
			<tr>
				<td colspan="1" class="WorkTableRowColour1" align="center"><cfif flagFirst>Active<cfelse>&nbsp;</cfif></td>
				<td colspan="1" class="WorkTableRowColour1">#thisTemplate#</td>
				<td colspan="1" class="WorkTableRowColour1">
					#linkTo(text="Make Inactive", controller="slcms.admin-templates", action="index", params="#PageContextFlags.ReturnLinkParams#&amp;job=MakeInactive&amp;CurrentTemplate=#thisTemplate#&amp;CurrentSubSet=Templates&amp;CurrentSet=#thisTemplateFolder#&amp;CurrentType=#theTemplateType#")#
					<!--- 
					<a href="Admin_Templates.cfm?job=MakeInactive&amp;CurrentTemplate=#thisTemplate#&amp;CurrentSubSet=Templates&amp;CurrentSet=#thisTemplateFolder#&amp;CurrentType=#theTemplateType#">Make Inactive</a>
					 --->
				</td>
				<td colspan="1" class="WorkTableRowColour1"><cfif thisbackupCount eq 0>No Backups<cfelseif thisbackupCount eq 1>1 Backup<cfelse>#thisbackupCount# Backups</cfif></td>
				<td class="WorkTableRowColour1RHCol">
					#linkTo(text="Download", controller="slcms.admin-templates", action="index", params="#PageContextFlags.ReturnLinkParams#&amp;job=Download&amp;CurrentTemplate=#thisTemplate#&amp;CurrentState=Active&amp;CurrentSet=#thisTemplateFolder#&amp;CurrentType=#theTemplateType#")#
					<!--- 
					<a href="Admin_Templates.cfm?job=Download&amp;CurrentTemplate=#thisTemplate#&amp;CurrentState=Active&amp;CurrentSet=#thisTemplateFolder#&amp;CurrentType=#theTemplateType#">Download</a>
					 --->
				</td>
			</tr>
			<cfset flagFirst = false />
		</cfloop>
		<cfset flagFirst = True />
		<cfloop collection="#theTemplates.TemplateSets[thisTemplateFolder].Templates.Inactive.Items#" item="thisTemplate">
			<cfset thisbackupCount = theTemplates.TemplateSets[thisTemplateFolder].Templates.Inactive.Items["#thisTemplate#"].BackupCount>
			<tr>
				<td colspan="1" class="WorkTableRowColour1" align="center"><cfif flagFirst>InActive<cfelse>&nbsp;</cfif></td>
				<td colspan="1" class="WorkTableRowColour1">#thisTemplate#</td>
				<td colspan="1" class="WorkTableRowColour1">
					#linkTo(text="Make Active", controller="slcms.admin-templates", action="index", params="#PageContextFlags.ReturnLinkParams#&amp;job=MakeActive&amp;CurrentTemplate=#thisTemplate#&amp;CurrentSubSet=Templates&amp;CurrentSet=#thisTemplateFolder#&amp;CurrentType=#theTemplateType#")#
					<!--- 
					<a href="Admin_Templates.cfm?job=MakeActive&amp;CurrentTemplate=#thisTemplate#&amp;CurrentSubSet=Templates&amp;CurrentSet=#thisTemplateFolder#&amp;CurrentType=#theTemplateType#">Make Active</a>
					 --->
				</td>
				<td colspan="1" class="WorkTableRowColour1"><cfif thisbackupCount eq 0>No Backups<cfelseif thisbackupCount eq 1>1 Backup<cfelse>#thisbackupCount# Backups</cfif></td>
				<td class="WorkTableRowColour1RHCol">
					#linkTo(text="Download", controller="slcms.admin-templates", action="index", params="#PageContextFlags.ReturnLinkParams#&amp;job=Download&amp;CurrentTemplate=#thisTemplate#&amp;CurrentState=Inactive&amp;CurrentSet=#thisTemplateFolder#&amp;CurrentType=#theTemplateType#")#
					<!--- 
					<a href="Admin_Templates.cfm?job=Download&amp;CurrentTemplate=#thisTemplate#&amp;CurrentState=Inactive&amp;CurrentSet=#thisTemplateFolder#&amp;CurrentType=#theTemplateType#">Download</a>
					 --->
				</td>
			</tr>
			<cfset flagFirst = false />
		</cfloop>
	</cfloop>
	</cfoutput>
	</table>

	<!---  
	<cfdump var="#application.SLCMS.core.Templates.getVariablesScope()#" expand="false">
	 --->
	<!--- 
	<cfdirectory action="list" name="qryTemplateDirectories" directory="#request.SLCMS.TemplatesBasePath#" filter="*.cfm" recurse="true">
 --->

<cfelseif request.SLCMS.modes.DispMode eq "AddSet" or request.SLCMS.modes.DispMode eq "EditSet">
	<table border="0" cellpadding="3" cellspacing="0">
	<tr><td colspan="2" align="center"><span class="minorheadingText"><cfoutput>
		<cfif request.SLCMS.modes.DispMode eq "AddSet">Adding a New Template Set to: <span class="minorheadingName">#theTemplateType#</span>
		<cfelse>Editing a Template Set Name:<span class="minorheadingName">#theTemplateType#</span>
		</cfif>
		</span></td></tr>
	<tr><td colspan="2"></td></tr>
	<form name="theForm" action="Admin_Templates.cfm?#PageContextFlags.ReturnLinkParams#&amp;job=#hNextMode#" method="post">
	<input type="hidden" name="TemplateType" value="#theTemplateType#">
	<input type="hidden" name="NextMode" value="#hNextMode#">
	<tr>
		<td align="right">Set Name: </td>
		<td><input type="text" name="SetName" value="#dSetName#"></td>
	</tr>
	<tr>
		<td align="right">&nbsp;</td>
		<td><input type="submit" name="SaveSet" value="Save New Set"></td>
	</tr>
	</form></cfoutput>
	</table>	<!--- end: worktable --->

<cfelseif request.SLCMS.modes.DispMode eq "AddTemplate" or request.SLCMS.modes.DispMode eq "EditTemplate">
	<!--- 
	<table border="0" cellpadding="3" cellspacing="0">
	<tr><td colspan="2" align="center"><span class="minorheadingText"><cfoutput>
		<cfif request.SLCMS.modes.DispMode eq "AddTemplate">Adding a New #thisPresentationString1# to: <span class="minorheadingName">#theTemplateSet#</span>
		<cfelse>Editing a #thisPresentationString1# Named:<span class="minorheadingName">#dTemplateName#</span>
		</cfif>
		</span></td></tr>
	<tr><td colspan="2"></td></tr>
	<form name="theForm" action="Admin_Templates.cfm?job=#hNextMode#" method="post"<cfif request.SLCMS.modes.DispMode eq "AddTemplate"> enctype="multipart/form-data"</cfif>>
	<input type="hidden" name="TemplateType" value="#theTemplateType#">
	<input type="hidden" name="TemplateSet" value="#theTemplateSet#">
	<input type="hidden" name="Subset" value="#theSubset#">
	<input type="hidden" name="NextMode" value="#hNextMode#">
	<!--- 
	<tr>
		<td align="right">Template Name: </td>
		<td><input type="text" name="TemplateName" value="#dTemplateName#"></td>
	</tr>
	 --->
	<tr>
		<td align="right">#thisPresentationString2# File: </td>
		<td><input type="File" name="TemplateFile"></td>
	</tr>
	<tr>
		<td align="right">&nbsp;</td>
		<td><input type="submit" name="SaveSet" value="Save New #thisPresentationString1#"></td>
	</tr>
	</form></cfoutput>
	</table>	<!--- end: worktable --->
	 --->
</cfif>	

<cfif request.SLCMS.modes.DispMode eq "AddTemplate" or request.SLCMS.modes.DispMode eq "EditTemplate" or request.SLCMS.modes.DispMode eq "ShowSingleTemplateSet">
	<!--- show just a single set for viewing alone or when we are editing/adding a set --->
	<!--- 
	<cfdump var="#thetemplates#" expand="false">
	 --->
	<table border="0" cellpadding="3" cellspacing="0" class="worktable">
		<tr>
			<td colspan="5">
			<cfif request.SLCMS.PortalAllowed>
				<cfif ListLen(theAllowedSubsiteList) gt 1>
					<div id="SubSiteLinksWrapper">
						<cfset lcntr = 0 />
						<p>This website is a portal. You can manage the templates in the following subsites:</p>
						<p>
						<cfloop list="#theAllowedSubsiteList#" index="thisSubSite">
							<span class="<cfif lcntr eq 0>LeftEnd<cfelseif lcntr mod 2 eq 1>OddNumbered<cfelse>EvenNumbered</cfif>">
							<cfset thisSubsiteDetails = application.SLCMS.core.PortalControl.GetSubSite(thisSubSite).data />
							<cfoutput>
							<cfif thisSubsiteDetails.SubSiteID eq 0>
								<cfif thisSubsiteDetails.SubSiteFriendlyName eq "Top">
									The #linkTo(text="Top Site", controller="slcms.admin-templates", action="index", params="#PageContextFlags.ReturnLinkParams#&amp;job=ChangeSubSite&amp;NewSubSiteID=0")#
									<!--- 
									<a href="Admin_Templates.cfm?job=ChangeSubSite&amp;NewSubSiteID=0">Top Site</a>
									 --->
								<cfelse>
									The Top Site (called &quot;#linkTo(text="#thisSubsiteDetails.SubSiteFriendlyName#", controller="slcms.admin-templates", action="index", params="#PageContextFlags.ReturnLinkParams#&amp;job=ChangeSubSite&amp;NewSubSiteID=0")#&quot;)
									<!--- 
									<a href="Admin_Templates.cfm?job=ChangeSubSite&amp;NewSubSiteID=0">#thisSubsiteDetails.SubSiteFriendlyName#</a>
									 --->
									
								</cfif>
							<cfelse>
								Site: &quot;#linkTo(text="#thisSubsiteDetails.SubSiteFriendlyName#", controller="slcms.admin-templates", action="index", params="#PageContextFlags.ReturnLinkParams#&amp;job=ChangeSubSite&amp;NewSubSiteID=#thisSubsiteDetails.SubSiteID#")#&quot;
								<!--- 
								<a href="Admin_Templates.cfm?job=ChangeSubSite&amp;NewSubSiteID=#thisSubsiteDetails.SubSiteID#">#thisSubsiteDetails.SubSiteFriendlyName#</a>
								 --->
								
							</cfif>
							</cfoutput> 
							</span>
							<cfset lcntr = lcntr+1 />
						</cfloop>
					</p></div>
					<div>You are currently looking at site: <span class="majorheading"><cfoutput>#session.SLCMS.Currents.Admin.Templates.CurrentSubSiteFriendlyName#</cfoutput></span>
					</div>				
				<cfelse>
					<p>This website is a portal.</p>
					<p>You can manage the page structure in the site: <span class="majorheading"><cfoutput>#session.SLCMS.Currents.Admin.Templates.CurrentSubSiteFriendlyName#</cfoutput></span></p>
				</cfif>	<!--- end: one of more subsites --->
			</cfif>	<!--- end: portal allowed --->
			</td>
		</tr>
		<tr><td colspan="5"></td></tr>
		<tr><cfoutput>
			<td colspan="5"><span class="minorheadingText">Template Set: #theTemplateSet#</span> in <strong>#theTemplateType#</strong> templates</td>
		</tr>
	<tr>
		<td colspan="1" class="WorkTableTopRow" align="center"><u>Template Set</u></td>
		<td colspan="1" class="WorkTableTopRow"><u>Template or Stylesheet Name</u></td>
		<td colspan="3" class="WorkTableTopRowRHCol">
			<!--- 
			<a href="Admin_Templates.cfm?job=AddSet&amp;CurrentType=#theTemplateType#">Add a Template Set</a>
			 --->&nbsp;
		</td>
	</tr>
	<tr>
		<td colspan="1" class="WorkTableRowColour1">&nbsp;</td>
		<td colspan="1" class="WorkTableRowColour1" align="center"><span class="minorheadingName">#theTemplateSet#</span></td>
		<td colspan="3" class="WorkTableRowColour1RHCol">&nbsp;</td>
	</tr>
	<cfloop list="#theSubsetList#" index="thisSubset">
		<cfswitch expression="#thisSubset#">
			<cfcase value="Templates">
				<cfset thisPresentationString1 = "Template" />
				<cfset thisPresentationString2 = "Templates" />
				<cfset ShowFileNameNotItemName = False />
			</cfcase>
			<cfcase value="TemplateIncludes">
				<cfset thisPresentationString1 = "Template Include File" />
				<cfset thisPresentationString2 = "Template Include Files" />
				<cfset ShowFileNameNotItemName = False />
			</cfcase>
			<cfcase value="TemplateGraphics">
				<cfset thisPresentationString1 = "Template Graphic" />
				<cfset thisPresentationString2 = "Template Graphics" />
				<cfset ShowFileNameNotItemName = True />
			</cfcase>
			<cfcase value="StyleSheets">
				<cfset thisPresentationString1 = "StyleSheet" />
				<cfset thisPresentationString2 = "StyleSheets" />
				<cfset ShowFileNameNotItemName = True />
			</cfcase>
			<cfcase value="StylingGraphics">
				<cfset thisPresentationString1 = "Styling Graphic" />
				<cfset thisPresentationString2 = "Styling Graphics" />
				<cfset ShowFileNameNotItemName = True />
			</cfcase>
			<cfcase value="NavigationControl">
				<cfset thisPresentationString1 = "Navigation Control File" />
				<cfset thisPresentationString2 = "Navigation Control" />
				<cfset ShowFileNameNotItemName = False />
			</cfcase>
			<cfdefaultcase>
				<cfset thisPresentationString1 = "Template" />
				<cfset thisPresentationString2 = "Templates" />
				<cfset ShowFileNameNotItemName = False />
			</cfdefaultcase>>
		</cfswitch>
		<tr>
			<td colspan="1" class="WorkTableRowColour1" align="center"><strong>#thisPresentationString2#</strong></td>
			<td colspan="1" class="WorkTableRowColour1">&nbsp;</td>
			<td colspan="3" class="WorkTableRowColour1RHCol">
				#linkTo(text="Add a #thisPresentationString1#", controller="slcms.admin-templates", action="index", params="#PageContextFlags.ReturnLinkParams#&amp;job=addTemplate&amp;CurrentSubSet=#thisSubset#&amp;CurrentSet=#theTemplateSet#&amp;CurrentType=#theTemplateType#")#
				<!--- 
				<a href="Admin_Templates.cfm?job=addTemplate&amp;CurrentSubSet=#thisSubset#&amp;CurrentSet=#theTemplateSet#&amp;CurrentType=#theTemplateType#">Add a #thisPresentationString1#</a>
				 --->
			</td>
		</tr>
		<!--- if we are adding a template show the form if its the correct section --->
		<cfif request.SLCMS.modes.DispMode eq "AddTemplate" and theFormPlacement eq thisSubset>
		<tr><td colspan="5" align="left" class="WorkTableMidRowColour2"><span class="minorheadingText">
			Adding a New #thisPresentationString1#
			</span></td></tr>
		<form name="theForm" action="Admin_Templates.cfm?#PageContextFlags.ReturnLinkParams#&amp;job=#hNextMode#" method="post"<cfif request.SLCMS.modes.DispMode eq "AddTemplate"> enctype="multipart/form-data"</cfif>>
		<input type="hidden" name="TemplateType" value="#theTemplateType#">
		<input type="hidden" name="TemplateSet" value="#theTemplateSet#">
		<input type="hidden" name="Subset" value="#theSubset#">
		<input type="hidden" name="NextMode" value="#hNextMode#">
		<!--- 
		<tr>
			<td align="right">Template Name: </td>
			<td><input type="text" name="TemplateName" value="#dTemplateName#"></td>
		</tr>
		 --->
		<tr>
			<td align="right" class="WorkTable2ndRowColour2">#thisPresentationString2# File: </td>
			<td class="WorkTable2ndRowColour2">
				<input type="File" name="TemplateFile">
				<input type="submit" name="SaveSet" value="Save New #thisPresentationString1#">
			</td>
			<td colspan="3" class="WorkTable2ndRowColour2RHcol"><input type="submit" name="Cancel" value="Cancel"></td>
		</tr>
		</form>
		</cfif>
		<cfset flagFirst = True />
		<cfset noFiles = True />
<!--- 
		<cfdump var="#theTemplates#" label="theTemplates" expand="true" abort="true">
		<cfabort>
 --->
		<cfloop collection="#theTemplates.TemplateSets[theTemplateSet][thisSubset].Active.Items#" item="thisTemplate">
			<cfset noFiles = False />
			<cfset thisbackupCount = theTemplates.TemplateSets[theTemplateSet][thisSubset].Active.Items["#thisTemplate#"].BackupCount>
			<cfset theFileName = theTemplates.TemplateSets[theTemplateSet][thisSubset].Active.Items[thisTemplate].FileName />
			<cfif ShowFileNameNotItemName>
				<cfset theName = theFileName />
			<cfelse>
				<cfset theName = thisTemplate />
			</cfif>
			<tr>
				<td colspan="1" class="WorkTableRowColour1" align="center"><cfif flagFirst>Active<cfelse>&nbsp;</cfif></td>
				<td colspan="1" class="WorkTableRowColour1">#theName#</td>
				<td colspan="1" class="WorkTableRowColour1">
					#linkTo(text="Make Inactive", controller="slcms.admin-templates", action="index", params="#PageContextFlags.ReturnLinkParams#&amp;job=MakeInactive&amp;CurrentTemplate=#thisTemplate#&amp;CurrentSubSet=#thisSubset#&amp;CurrentSet=#theTemplateSet#&amp;CurrentType=#theTemplateType#")#
					<!--- 
					<a href="Admin_Templates.cfm?job=MakeInactive&amp;CurrentTemplate=#thisTemplate#&amp;CurrentSubSet=#thisSubset#&amp;CurrentSet=#theTemplateSet#&amp;CurrentType=#theTemplateType#">Make Inactive</a>
					 --->
				</td>
				<td colspan="1" class="WorkTableRowColour1"><cfif thisbackupCount eq 0>No Backups<cfelseif thisbackupCount eq 1>1 Backup<cfelse>#thisbackupCount# Backups</cfif></td>
				<td class="WorkTableRowColour1RHCol">
					#linkTo(text="Download", controller="slcms.admin-templates", action="index", params="#PageContextFlags.ReturnLinkParams#&amp;job=Download&amp;CurrentTemplate=#theFileName#&amp;CurrentState=Active&amp;CurrentSubSet=#thisSubset#&amp;CurrentSet=#theTemplateSet#&amp;CurrentType=#theTemplateType#")#
					<!--- 
					<a href="Admin_Templates.cfm?job=Download&amp;CurrentTemplate=#theFileName#&amp;CurrentState=Active&amp;CurrentSubSet=#thisSubset#&amp;CurrentSet=#theTemplateSet#&amp;CurrentType=#theTemplateType#">Download</a>
					 --->
				</td>
			</tr>
			<cfset flagFirst = false />
		</cfloop>
		<cfif noFiles>
			<tr>
				<td colspan="1" class="WorkTableRowColour1" align="center">&nbsp;</td>
				<td colspan="4" class="WorkTableRowColour1RHCol">No Active Files</td>
			</tr>
		</cfif>
		<cfset flagFirst = True />
		<cfloop collection="#theTemplates.TemplateSets[theTemplateSet][thisSubset].Inactive.Items#" item="thisTemplate">
			<cfset thisbackupCount = theTemplates.TemplateSets[theTemplateSet][thisSubset].Inactive.Items["#thisTemplate#"].BackupCount>
			<cfset theFileName = theTemplates.TemplateSets[theTemplateSet][thisSubset].Inactive.Items[thisTemplate].FileName />
			<cfif ShowFileNameNotItemName>
				<cfset theName = theFileName />
			<cfelse>
				<cfset theName = thisTemplate />
			</cfif>
			<tr>
				<td colspan="1" class="WorkTableRowColour1" align="center"><cfif flagFirst>InActive<cfelse>&nbsp;</cfif></td>
				<td colspan="1" class="WorkTableRowColour1">#theName#</td>
				<td colspan="1" class="WorkTableRowColour1">
					#linkTo(text="Make Active", controller="slcms.admin-templates", action="index", params="job=MakeActive&amp;CurrentTemplate=#thisTemplate#&amp;CurrentSubSet=#thisSubset#&amp;CurrentSet=#theTemplateSet#&amp;CurrentType=#theTemplateType##PageContextFlags.ReturnLinkParams#")#
					<!--- 
					<a href="Admin_Templates.cfm?job=MakeActive&amp;CurrentTemplate=#thisTemplate#&amp;CurrentSubSet=#thisSubset#&amp;CurrentSet=#theTemplateSet#&amp;CurrentType=#theTemplateType#">Make Active</a>
					 --->
				</td>
				<td colspan="1" class="WorkTableRowColour1"><cfif thisbackupCount eq 0>No Backups<cfelseif thisbackupCount eq 1>1 Backup<cfelse>#thisbackupCount# Backups</cfif></td>
				<td class="WorkTableRowColour1RHCol">
					#linkTo(text="Download", controller="slcms.admin-templates", action="index", params="#PageContextFlags.ReturnLinkParams#&amp;job=Download&amp;CurrentTemplate=#theFileName#&amp;CurrentState=Inactive&amp;CurrentSubSet=#thisSubset#&amp;CurrentSet=#theTemplateSet#&amp;CurrentType=#theTemplateType#")#
					<!--- 
					<a href="Admin_Templates.cfm?job=Download&amp;CurrentTemplate=#theFileName#&amp;CurrentState=Inactive&amp;CurrentSubSet=#thisSubset#&amp;CurrentSet=#theTemplateSet#&amp;CurrentType=#theTemplateType#">Download</a>
					 --->
				</td>
			</tr>
			<cfset flagFirst = false />
		</cfloop>
	</cfloop>
	</cfoutput>
	</table>

<cfelseif request.SLCMS.modes.DispMode eq "AddSet" or request.SLCMS.modes.DispMode eq "EditSet" or request.SLCMS.modes.DispMode eq "ViewTypes">
	<!--- just show the types and the sets in them --->
<!---  	
  	<cfdump var="#theTemplateVariables#" label="theTemplateVariables" expand="false" >
--->		
	<table border="0" cellpadding="3" cellspacing="0" class="worktable">
		<tr>
			<td colspan="2">
			<cfif request.SLCMS.PortalAllowed>
				<cfif ListLen(theAllowedSubsiteList) gt 1>
					<div id="SubSiteLinksWrapper">
						<cfset lcntr = 0 />
						<p>This website is a portal. You can manage the templates in the following subsites:</p>
						<p>
						<cfloop list="#theAllowedSubsiteList#" index="thisSubSite">
							<span class="<cfif lcntr eq 0>LeftEnd<cfelseif lcntr mod 2 eq 1>OddNumbered<cfelse>EvenNumbered</cfif>">
							<cfset thisSubsiteDetails = application.SLCMS.core.PortalControl.GetSubSite(thisSubSite).data />
							<cfoutput>
							<cfif thisSubsiteDetails.SubSiteID eq 0>
								<cfif thisSubsiteDetails.SubSiteFriendlyName eq "Top">
									The 
									#linkTo(text="Top Site", controller="slcms.admin-templates", action="index", params="#PageContextFlags.ReturnLinkParams#&amp;job=ChangeSubSite&amp;NewSubSiteID=0")#
									<!--- 
									<a href="Admin_Templates.cfm?job=ChangeSubSite&amp;NewSubSiteID=0">Top Site</a>
									 --->
								<cfelse>
									The Top Site (called &quot;#linkTo(text="#thisSubsiteDetails.SubSiteFriendlyName#", controller="slcms.admin-templates", action="index", params="#PageContextFlags.ReturnLinkParams#&amp;job=ChangeSubSite&amp;NewSubSiteID=0")#&quot;)
									<!--- 
									<a href="Admin_Templates.cfm?job=ChangeSubSite&amp;NewSubSiteID=0">#thisSubsiteDetails.SubSiteFriendlyName#</a>
									 --->
									
								</cfif>
							<cfelse>
								Site: &quot;#linkTo(text="#thisSubsiteDetails.SubSiteFriendlyName#", controller="slcms.admin-templates", action="index", params="#PageContextFlags.ReturnLinkParams#&amp;job=ChangeSubSite&amp;NewSubSiteID=#thisSubsiteDetails.SubSiteID#")#&quot;
								<!--- 
								<a href="Admin_Templates.cfm?job=ChangeSubSite&amp;NewSubSiteID=#thisSubsiteDetails.SubSiteID#">#thisSubsiteDetails.SubSiteFriendlyName#</a>
								 --->
								
							</cfif>
							</cfoutput> 
							</span>
							<cfset lcntr = lcntr+1 />
						</cfloop>
					</p></div>
					<div>You are currently looking at site: <span class="majorheading"><cfoutput>#session.SLCMS.Currents.Admin.Templates.CurrentSubSiteFriendlyName#</cfoutput></span>
					</div>				
				<cfelse>
					<p>This website is a portal.</p>
					<p>You can manage the page structure in the site: <span class="majorheading"><cfoutput>#session.SLCMS.Currents.Admin.Templates.CurrentSubSiteFriendlyName#</cfoutput></span></p>
				</cfif>	<!--- end: one of more subsites --->
			</cfif>	<!--- end: portal allowed --->
			</td>
		</tr>
		<tr>
			<td colspan="2"></td>
		</tr>
		<tr>
			<td colspan="2"><span class="minorheadingText">Template Types and their Template Sets</span></td>
		</tr>
		<tr>
			<td colspan="1" class="WorkTableTopRow" align="center"><u>Template Type</u><br>(Click to view all Sets for Type, and to add a Set)</td>
			<td colspan="1" class="WorkTableTopRowRHCol" align="center"><u>Template Sets</u><br>(Click to view Set, with its related items)</td>
		</tr><cfoutput>
		<cfloop list="#theTemplateVariables.Lists.CoreTemplateTypeList#" index="thisTemplateType">
			<cfif thisTemplateType neq "Sub">
				<tr>
					<td colspan="1" class="WorkTableRowColour1" align="center">
						#linkTo(text="#thisTemplateType#", controller="slcms.admin-templates", action="index", params="#PageContextFlags.ReturnLinkParams#&amp;job=ViewTypesSets&amp;Type=#thisTemplateType#")#
							<!--- 
							<a href="Admin_Templates.cfm?job=ViewTypesSets&amp;Type=#thisTemplateType#">#thisTemplateType#</a>
							 --->
					</td>
					<td colspan="1" class="WorkTableRowColour1RHCol">
						<cfif ListLen(theTemplateVariables.SubSite_Shared['#thisTemplateType#_Templates'].TemplateSetList)>
							<cfloop list="#theTemplateVariables.SubSite_Shared['#thisTemplateType#_Templates'].TemplateSetList#" index="thisTemplateSet">
								#linkTo(text="#thisTemplateSet#", controller="slcms.admin-templates", action="index", params="#PageContextFlags.ReturnLinkParams#&amp;job=ViewTemplateSet&amp;mode=TypeSet&amp;Type=#thisTemplateType#&amp;Set=#thisTemplateSet#&amp;subSiteId=Shared")#
								<!--- 
								<a href="Admin_Templates.cfm?job=ViewTemplateSet&amp;mode=TypeSet&amp;Type=#thisTemplateType#&amp;Set=#thisTemplateSet#&amp;subSiteId=Shared">#thisTemplateSet#</a>
								 --->
							</cfloop>
						<cfelseif ListLen(theTemplateVariables["SubSite_#session.SLCMS.Currents.Admin.templates.CurrentSubSiteID#"]['#thisTemplateType#_Templates'].TemplateSetList)>
							<cfloop list="#theTemplateVariables['SubSite_#session.SLCMS.Currents.Admin.templates.CurrentSubSiteID#']['#thisTemplateType#_Templates'].TemplateSetList#" index="thisTemplateSet">
								#linkTo(text="#thisTemplateSet#", controller="slcms.admin-templates", action="index", params="#PageContextFlags.ReturnLinkParams#&amp;job=ViewTemplateSet&amp;mode=TypeSet&amp;Type=#thisTemplateType#&amp;Set=#thisTemplateSet#&amp;subSiteId=#session.SLCMS.Currents.Admin.templates.CurrentSubSiteID#")#
								<!--- 
								<a href="Admin_Templates.cfm?job=ViewTemplateSet&amp;mode=TypeSet&amp;Type=#thisTemplateType#&amp;Set=#thisTemplateSet#&amp;subSiteId=#session.SLCMS.Currents.Admin.templates.CurrentSubSiteID#">#thisTemplateSet#</a>
								 --->
							</cfloop>
						<cfelse>
							No Template Sets
						</cfif>
					</td>
				</tr>
			</cfif>
		</cfloop></cfoutput>
	</table>

</cfif>	
<cfif application.SLCMS.config.base.debugMode>
<!--- you might need this if using divs to format the page --->
<div style="clear:both"></div>
</cfif>
</body>
</html>


