<!--- mbc SLCMS CFCs  --->
<!--- &copy; 2011 mort bay communications --->
<!---  --->
<!--- a set of utilities for working with SLCMS site forms --->
<!--- A SLCMS form can have one base component with possible extra components.
			The base component must be named: formname-Form.cfm 
			 with the "formname" part being the common name used as a reference and displayed in selectors, etc.
			 At a minimum it must carry the HTML to display the form and it uses SLCMStag to.
			The second component is a processing page named: formname-Process.cfm 
			 --->
<!--- Contains:
			init - set up persistent structures for control of the forms in the site
			lots more related stuff :-)
			 --->
<!---  --->
<!--- created:  30th Jun 2008 by Kym K - mbcomms --->
<!--- modified: 30th Jun 2008 -  9th Jul 2008 by Kym K, mbcomms: initial work --->
<!--- modified: 24th Sep 2008 -  1st Oct 2008 by Kym K, mbcomms: added new init to match templatemanager new structure and checknset, etc. Form details into application scope directly --->
<!--- modified:  1st Dec 2008 -  1st Dec 2008 by Kym K, mbcomms: made it silent, all function outputs --->
<!--- modified: 22nd Apr 2009 - 28th Apr 2009 by Kym K, mbcomms: V2.2, changing template folder structure to portal/sub-site architecture, sites inside the top site --->
<!--- modified: 19th Nov 2009 - 19th Nov 2009 by Kym K, mbcomms: V2.2, refining and recoding for new sessions and portal structure changes --->
<!--- modified: 18th Feb 2011 - 18th Feb 2011 by Kym K, mbcomms: ran varScoper over code and found an un-var'd variable! oops :-/  --->
<!--- modified:  7th Jun 2011 - 19th Jun 2011 by Kym K, mbcomms: added logging functions so we can have consistent logging outside CF's logs --->
<!--- modified: 18th Aug 2011 - 18th Aug 2011 by Kym K, mbcomms: changed table creation to use DataMgr --->
<!--- modified:  9th Apr 2012 -  9th Apr 2012 by Kym K, mbcomms: V3.0, CFWheels version. All SLCMS in own struct under app scope --->
 
<cfcomponent extends="controller" 
	output="No"
	displayname="Form Handling Utilities" 
	hint="contains standard utilities to work with Forms inside SLCMS"
	>
	
	<!--- set up a few persistant things on the way in. --->
	<cfset variables.FullFormList = "" />		<!--- this carries a list of the forms available --->
	<cfset variables.FullFormCount = 0 />		<!--- this carries how many forms there are --->
	<cfset variables.TableList = "" />			<!--- this is a list of the tables in the database --->
	<cfset variables.TemplateList = "" />		<!--- this is a list of the templates that the template manager found in the form templates folders --->
	<cfset variables.FormDataSource = "" />	<!--- this is where to find the form data tables --->
	<cfset variables.Forms = StructNew() />	<!--- this structure carries what??? --->
	<!--- portal related data --->
	<cfset variables.SubSiteControl = StructNew() />
	<cfset variables.SubSiteControl.ActiveSubSiteIDList = "0" />
	<cfset variables.SubSiteControl.SubSiteIDList_Full = "0" />
	<cfset variables.SubSiteControl.SubSiteData = StructNew() />

<!--- initialize the various thingies, this should only be called after an app scope refresh --->
<cffunction name="init" 
	access="public" output="No" returntype="any" 
	displayname="Initializer"
	hint="sets up the internal structures for this component"
	>

	<cfargument name="dsn" type="string" required="yes">	<!--- the datasource for our data tables --->

	<cfset var theFormDataSource = trim(arguments.dsn) />
	<cfset var temps = "" /> <!--- temp ret from log calls --->
	<cfset var theFormSets = "" /> <!--- this will have the query result of the form sets available from above --->
	<cfset var theFormtemplateList = "" /> <!--- this will have a list of the forms available, with their "set" paths --->
	<cfset var thisSubSiteID = 0 /> <!--- temp for loops --->
	<cfset var thisForm = "" /> <!--- temp for loops --->
	<cfset var acfquery = "" /> <!--- temp query result --->
	<cfset var qryGetTables = "" /> <!--- temp query result --->
	<cfset var thisTableName = "" /> <!--- temp var --->
	<cfset var thisFormatName = "" /> <!--- temp var --->
	<cfset var thisFormatLen = 0 /> <!--- temp var --->
	<cfset var thisFormName = "" /> <!--- temp var --->
	<cfset var qryGetColumns = "" /> <!--- temp query result --->
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorText = "Init()<br>" />
	<cfset ret.Data = "" />

	<cfset temps = LogIt(LogType="CFC_Init", LogString="FormHandler Started") />
	<cfif theFormDataSource neq "">
		<cfset variables.FormDataSource = theFormDataSource />
		<!--- grab the list of subsites --->
		<cfset variables.SubSiteControl.SubSiteIDList_Active = application.SLCMS.Core.PortalControl.GetActiveSubSiteIDList() />
		<cfset variables.SubSiteControl.SubSiteIDList_Full = application.SLCMS.Core.PortalControl.GetFullSubSiteIDList() />
		<!--- and then loop over them refreshing each in turn --->
		<cfloop list="#variables.SubSiteControl.SubSiteIDList_Full#" index="thisSubSiteID">
			<cfset variables["SubSite_#thisSubSiteID#"] = StructNew() />
			<cfset variables["SubSite_#thisSubSiteID#"].TemplateList = application.SLCMS.Core.Templates.getTemplateList(TemplateType="Form", SubSiteID="#thisSubSiteID#") />
			<cfset variables["SubSite_#thisSubSiteID#"].FullFormList = "" />
			<cfset variables["SubSite_#thisSubSiteID#"].FullFormCount = 0 />
			<cfset variables["SubSite_#thisSubSiteID#"].TableList = "" />
	  <!--- ToDo: change all this to file-based so we don't have dynamic tables to fret over in CFWheels
			<!--- see what form data tables we have --->
			<cfquery name="qryGetTables" datasource="#variables.FormDataSource#">
				sp_tables @table_type="'TABLE'"
			</cfquery>
			<cfloop query="qryGetTables">
				<cfset thisTableName = qryGetTables.Table_Name />
				<cfset thisFormatName = "SLCMS_Site_#thisSubSiteID#_FormData_" /> <!--- the first part of the name of the table that we are looking for --->
				<cfset thisFormatLen = Len(thisFormatName) />	<!--- use this to strip off the first part of the table name --->
				<cfif left(thisTableName, thisFormatLen) eq thisFormatName>	<!--- this is one that we want --->
					<cfset thisFormName = removeChars(thisTableName, 1, thisFormatLen) />	<!--- grab the name of the form according to the table --->
					<cfset thisFormName = replace(thisFormName,"_","/") />	<!--- as we don't have the slash of the template name in the table name we need to put the slash back --->
					<cfif ListFindNoCase(variables["SubSite_#thisSubSiteID#"].TemplateList, thisFormName)>	<!--- see if we have matching form templates --->
						<!--- we do so add this one in to our Form List --->
						<cfset variables["SubSite_#thisSubSiteID#"].FullFormList = ListAppend(variables["SubSite_#thisSubSiteID#"].FullFormList, thisFormName) />
						<cfset variables["SubSite_#thisSubSiteID#"].FullFormCount = variables["SubSite_#thisSubSiteID#"].FullFormCount+1 />
						<cfset variables["SubSite_#thisSubSiteID#"].TableList = ListAppend(variables["SubSite_#thisSubSiteID#"].TableList, thisFormName) />
						<!--- 
						<!--- now we read in the column data to load up our data fields --->
						<cfquery name="qryGetColumns" datasource="#variables.FormDataSource#">
							sp_columns @table_name='#thisTableName#'
						</cfquery>
						<cfloop query="qryGetColumns">
							<cfif qryGetColumns.name neq "RepID" or qryGetColumns.name neq "EntryID" or qryGetColumns.name neq "EntryTimeStamp">
								<cfset application.FormDetails["#thisFormName#"] = StructNew()
							</cfif>
						</cfloop>
						 --->
					</cfif>
				</cfif>
			</cfloop>
		--->
			<!--- now the FormList variable has a list of all forms that have both a template and a table
						any template that has not a table to match will be created with FormChecknSet later --->
		</cfloop>
	<cfelse>
		<!--- oops! --->
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 1) />
		<cfset ret.error.ErrorText = ret.error.ErrorText & "Oops! The DataSource argument 'dsn' was not supplied" />
	</cfif>
	
	<cfset temps = LogIt(LogType="CFC_Init", LogString="FormHandler Finished") />
	<cfreturn ret />
</cffunction>

<!--- this function sees if a form name exists in the system and creates as needed
			it is fed the template name so that must exist as a form template, ie it has been run by a page
			we will check to see if there is a matching system reference and database table and create it if it does not exist --->
<cffunction name="FormChecknSet" output="No" returntype="struct" access="public"
	displayname="Form Check and Set"
	hint="Uses the supplied form name and field structure to check if it exists and has the correct structure
				Creates as needed if no match"
				>
	<!--- this function needs.... --->
	<cfargument name="FormName" type="string" default="" hint="the name of the form" />
	<cfargument name="FieldSessionStruct" type="struct" default="" hint="struct of the fields in the form" />
	<cfargument name="FormDetails" type="struct" default="" hint="the status structure for the form" />
	<cfargument name="SubSiteID" type="numeric" required="yes" hint="the ID of the subsite to refresh">

	<!--- now all of the var declarations, first the arguments which need manipulation --->
	<cfset var theFormName = trim(arguments.FormName) />
	<cfset var theSubSiteID = trim(arguments.SubSiteID) />
	<!--- now vars that will get filled as we go --->
	<cfset var thisFormatName = "" /> <!--- temp var --->
	<cfset var thisFormatLen = 0 /> <!--- temp var --->
	<cfset var theTableName = "" />	<!--- name of the database table --->
	<cfset var lcntr = 0 />	<!--- temp loop counter --->
	<cfset var temp = "" />	<!--- temp/throwaway var --->
	<cfset var FullFormExists = False />	<!--- temp/throwaway var, flags if we have the form in our local full list, ie there is a table for it and a template --->
	<cfset var TemplateExists = False />	<!--- temp/throwaway var, flags if we have the form in our local template list, ie there is a template for it --->
	<cfset var TableDoesnotExist = True />	<!--- temp/throwaway var, flags if the form database table exists, not :-) --->
	<cfset var theColumnsToAdd = "" />	<!--- temp/throwaway var, what columns to add to the database table --->
	<cfset var thisColumn = "" />	<!--- temp/throwaway var, the column to add to the database table from above list --->
	<cfset var theQueryString = "" />		<!--- temp/throwaway var, the string to run in the query to build the columns --->
	<cfset var CallResult = StructNew() />	<!--- this is the return from something --->
	<cfset var acfquery = "" /> <!--- temp query result --->
	<cfset var qryGetTables = "" /> <!--- temp query result --->
	<cfset var createFormTable = "" /> <!--- temp query result --->
	<cfset var FlagCheckTableColumns = False />	<!--- temp/throwaway var, flags if we need to check the columns in our database --->
	<cfset var qryGetColumns = "" /> <!--- temp query result --->
	<cfset var theListPos = "" />	<!--- temp/throwaway var --->
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorContext = "FormHandling CFC: FormChecknSet()" />
	<cfset ret.error.ErrorText = "" />
	<cfset ret.Data = "" />

	<cfset thisFormatName = "SLCMS_Site_#theSubSiteID#_FormData_" /> <!--- the first part of the name of the table that we are looking for --->
	<cfset thisFormatLen = Len(thisFormatName) />	
	<cfif left(theFormName, thisFormatLen) neq thisFormatName>	<!--- if this is not on the front then stick it on --->
		<cfset theTableName = thisFormatName & theFormName />
	<cfelse>
		<cfset theTableName = theFormName />
	</cfif>
	<!--- lose dodgy characters in the table name --->
	<cfset theTableName = replace(theTableName, "/", "_", "all") />	<!--- we are always going to get one of these --->
	<cfset theTableName = replace(theTableName, '"', "_", "all") />	<!--- we shouldn't get these, filtered out b4 this but why take chances --->
	<cfif len(theTableName) gt 15>
		<!--- wrap the whole thing in a try/catch in case something breaks --->
		<cftry>
			<!--- we have lots of possibilities, the form and table might exist, or only one or neither depending on when the form came into existance so check both  --->
			<cfif ListFindNoCase(variables["SubSite_#theSubSiteID#"].FullFormList, theFormName)>
				<cfset FullFormExists = True />
				<!--- it is there as a full form so check to see if the columns in the table match what we now have --->
				<cfset TableDoesnotExist = False />
				<!--- now we use the changed flag from the form tags to tell us if something changed --->
				<!--- ToDo: check table columns against supplied field list, create if not
				<cfset FlagCheckTableColumns = True />
				 --->
			<cfelse>
				<!--- its not there as a full form so there must be a bit missing, funny that --->
				<cfif not ListFindNoCase(variables["SubSite_#theSubSiteID#"].TemplateList, theFormName)>
					<!--- the template manager does not know about it so it must be newly added to the template folder so reload all the form templates --->
<!---					
					<cflog text='#ret.error.ErrorContext# debug Log before reloadSubTemplateType() call:- , subSiteID: #theSubSiteID#<br>Time: #DateFormat(Now(),"YYYYMMDD")#-#TimeFormat(now(),"HH:mm:ss")#'  file="#application.SLCMS.Logging.theSiteLogName#" type="Error" application="yes">
					<cfset CallResult = application.SLCMS.Core.templates.reloadSubTemplateType(TemplateType="Form", SubSiteID="#theSubSiteID#") />
--->					
					<cfset CallResult = application.SLCMS.Core.templates.reInit(SubSiteID="#theSubSiteID#") />
					<cfset variables["SubSite_#theSubSiteID#"].TemplateList = application.SLCMS.Core.templates.getTemplateList(TemplateType="Form", SubSiteID="#theSubSiteID#") />
				</cfif>
				<!--- the template manager now knows about it but there isn't a table so check and make --->
				<cfquery name="qryGetTables" datasource="#variables.FormDataSource#">
					sp_tables @table_type="'TABLE'"
				</cfquery>
				<cfloop query="qryGetTables">
					<cfif qryGetTables.Table_Name eq theTableName><!--- this is one we want --->
						<cfset TableDoesnotExist = False />
					</cfif>
				</cfloop>
				<cfif TableDoesnotExist>	<!--- we didn't find the table so create it --->
					<cfquery name="createFormTable" datasource="#variables.FormDataSource#">
						CREATE TABLE [dbo].[#theTableName#] (
							[RepID]  uniqueidentifier ROWGUIDCOL  NOT NULL ,
							[EntryID] [int] NOT NULL ,
							[EntryTimeStamp] [datetime] NULL 
						) ON [PRIMARY]
						
						ALTER TABLE [dbo].[#theTableName#] WITH NOCHECK ADD 
							CONSTRAINT [PK_#theTableName#] PRIMARY KEY  CLUSTERED ([RepID])  ON [PRIMARY] 
						
						ALTER TABLE [dbo].[#theTableName#] WITH NOCHECK ADD 
							CONSTRAINT [DF_#theTableName#_RepID] DEFAULT (newid()) FOR [RepID]
						
						ALTER TABLE [dbo].[#theTableName#] WITH NOCHECK ADD 
							CONSTRAINT [DF_#theTableName#_EntryID] DEFAULT (0) FOR [EntryID]
						
						 CREATE  INDEX [IX_#theTableName#] ON [dbo].[#theTableName#] ([EntryID]) ON [PRIMARY]
					</cfquery>
					<!--- now add it to the local lists --->
					<cfset variables["SubSite_#theSubSiteID#"].TableList = ListAppend(variables["SubSite_#theSubSiteID#"].TableList, theFormName) />
				</cfif>
				<cfset variables["SubSite_#theSubSiteID#"].FullFormList = ListAppend(variables["SubSite_#theSubSiteID#"].FullFormList, theFormName) />
				<cfset variables["SubSite_#theSubSiteID#"].FullFormCount = variables["SubSite_#theSubSiteID#"].FullFormCount+1 />
			</cfif>
			<!--- we now have a table there but the contents is not guaranteed so lets see if we need to check it --->
			<cfif TableDoesnotExist or FlagCheckTableColumns or arguments.FormDetails.Status.flagChanged>
				<!--- something changed so lets see what and handle accordingly --->
				<!--- first see if we have a new column to add to the table --->
				<cfif TableDoesnotExist>	<!--- its a newie so add in the lot! --->
					<cfset theColumnsToAdd = arguments.FormDetails.FieldList />
				<cfelseif arguments.FormDetails.Status.flagChanged>	<!--- something changed so work out what --->
					<!--- it could be the first time in and not in appscope yet so find out --->
<!--- 					
					<cfoutput>#arguments.FormDetails.Status.FieldIsNewList#</cfoutput>
					<cfabort>
 --->
					<!--- 
					<cfif arguments.FormDetails.FieldList eq arguments.FormDetails.Status.FieldIsNewList and arguments.FormDetails.flagFirstTimeIn>
						<!--- could be a first time in loading so we need to ignore --->
						<cfset theColumnsToAdd = "" />
					<cfelse>
						<cfset theColumnsToAdd = arguments.FormDetails.Status.FieldIsNewList />
					</cfif>
					 --->
					<cfset theColumnsToAdd = arguments.FormDetails.Status.FieldIsNewList />

				</cfif>
				<cfif theColumnsToAdd neq "">
					<!--- we have some columns to add to the table so lets drop them in --->
					<!--- first see what is already there --->
					<cfquery name="qryGetColumns" datasource="#variables.FormDataSource#">
						sp_columns @table_name='#theTableName#'
					</cfquery>
					<!--- 
					<cfdump var="#qryGetColumns#" expand="false">
					<cfabort>
					 --->
					<cfloop query="qryGetColumns">
						<cfif qryGetColumns.Column_Name neq "RepID" or qryGetColumns.Column_name neq "EntryID" or qryGetColumns.Column_name neq "EntryTimeStamp">
							<cfset theListPos = ListFindNoCase(theColumnsToAdd, qryGetColumns.Column_name)>
							<cfif theListPos gt 0>
								<!--- its already there so remove it from add list --->
								<cfset theColumnsToAdd = ListDeleteAt(theColumnsToAdd, theListPos) />
								<!--- 
								<cfoutput>#theColumnsToAdd#<br></cfoutput>
								 --->
							</cfif>
						</cfif>
					</cfloop>
					<cfif theColumnsToAdd neq "">
						<cfset theQueryString = theQueryString & "ALTER TABLE [dbo].[#theTableName#] WITH NOCHECK ADD " />
						<cfloop list="#theColumnsToAdd#" index="thisColumn">
							<cfif arguments.FormDetails.Fields["#thisColumn#"].database.FieldType neq "">
								<cfset theQueryString = theQueryString & "[#arguments.FormDetails.Fields["#thisColumn#"].database.Fieldname#] " />
								<!--- add in the type and size and whatever parameters --->
								<cfif arguments.FormDetails.Fields["#thisColumn#"].database.FieldType eq "varChar">
									<cfset theQueryString = theQueryString & "nVARCHAR(#arguments.FormDetails.Fields["#thisColumn#"].database.FieldSize#) NULL, " />
								<cfelseif arguments.FormDetails.Fields["#thisColumn#"].database.FieldType eq "memo">
									<cfset theQueryString = theQueryString & "nTEXT NULL, " />
								<cfelseif arguments.FormDetails.Fields["#thisColumn#"].database.FieldType eq "data">
									<cfset theQueryString = theQueryString & "image NULL, " />
								</cfif>
							</cfif>
						</cfloop>
						<!--- now remove the stray comma at the end --->
						<cfif len(theQueryString) gt 1>
							<cfset theQueryString = removeChars(theQueryString, len(theQueryString)-1, 1) />
						<!---  and do it! --->
<!--- 				
				<cfdump var="#theQueryString#">
 --->
							<cfquery name="createFormTable" datasource="#variables.FormDataSource#">
								<cfoutput>#theQueryString#</cfoutput>
							</cfquery>
						</cfif>
					</cfif>
				</cfif>
				<!--- 
				<cfquery name="createFormTable" datasource="#variables.FormDataSource#">
					<cfoutput>#theQueryString#</cfoutput>
				</cfquery>
				 --->
			</cfif>
		<cfcatch type="any">
			<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 128) />
			<cfset ret.error.ErrorText = ret.error.ErrorContext & ' Trapped. Site: #application.SLCMS.Config.base.SiteName#, error message was: #cfcatch.message#, error detail was: #cfcatch.detail#' />
			<cfset ret.error.ErrorExtra =  cfcatch.TagContext />
			<cfif isArray(ret.error.ErrorExtra) and StructKeyExists(ret.error.ErrorExtra[1], "Raw_Trace")>
				<cfset ret.error.ErrorText = ret.error.ErrorText & ", Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#" />
			</cfif>
			<cflog text='#ret.error.ErrorText# - ret.error.ErrorCode: #ret.error.ErrorCode# - Time: #DateFormat(Now(),"YYYYMMDD")#-#TimeFormat(now(),"HH:mm:ss")#'  file="#application.SLCMS.Logging.theSiteLogName#" type="Error" application = "yes">
			<cfif application.SLCMS.Config.debug.debugmode>
				<cfoutput>#ret.error.ErrorContext#</cfoutput> Trapped - error dump:<br>
				<cfdump var="#cfcatch#">
			</cfif>
		</cfcatch>
		</cftry>
	<cfelse>	<!--- this is the error code --->
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 1) />
		<cfset ret.error.ErrorText = ret.error.ErrorText & "Oops! Table name invalid<br>" />
	</cfif>
	
	<cfreturn ret  />
</cffunction>

<cffunction name="SaveData" output="No" returntype="struct" access="public"
	displayname="Save Form Data"
	hint="writes to form field response to the database"
				>
	<!--- this function needs.... --->
	<cfargument name="FormName" type="string" default="" hint="the name of the form" />
	<cfargument name="FieldSessionStruct" type="struct" default="" hint="struct of the fields in the form" />
	<cfargument name="SubSiteID" type="numeric" required="yes" hint="the ID of the subsite to refresh">

	<cfset var loc = {} />	<!--- CFWheels default style for all local variables --->
	<!--- now all of the var declarations, first the arguments which need manipulation --->
	<cfset var theFormName = trim(arguments.FormName) />
	<cfset var theSubSiteID = trim(arguments.SubSiteID) />
	<!--- now vars that will get filled as we go --->
	<cfset var theTableName = "" />
	<cfset var thisFormatName = "" /> <!--- temp var --->
	<cfset var thisFormatLen = 0 /> <!--- temp var --->
	<cfset var lcntr = 0 />	<!--- temp loop counter --->
	<cfset var thisField = "" />	<!--- temp/throwaway var --->
	<cfset var theFileUploadedFields = "" />	<!--- temp/throwaway var --->
	<cfset var theQueryString0 = "" />		<!--- temp/throwaway var, part of the string to run in the query to build the columns --->
	<cfset var theQueryString1 = "" />		<!--- temp/throwaway var, part of the string to run in the query to build the columns --->
	<cfset var theQueryString2 = "" />		<!--- temp/throwaway var, part of the string to run in the query to build the columns --->
	<cfset var updateFormTable = "" /> <!--- temp query --->
	<cfset var loc.temp = "" />
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorContext = "FromHandling CFC: SaveData()" />
	<cfset ret.Data = "" />

	<cfset thisFormatName = "SLCMS_Site_#theSubSiteID#_FormData_" /> <!--- the first part of the name of the table that we are looking for --->
	<cfset thisFormatLen = Len(thisFormatName) />	
	<cfif left(theFormName, thisFormatLen) neq thisFormatName>	<!--- if this is not on the front then stick it on --->
		<cfset theTableName = thisFormatName & theFormName />
	<cfelse>
		<cfset theTableName = theFormName />
	</cfif>
	<!--- lose dodgy characters in the table name --->
	<cfset theTableName = replace(theTableName, "/", "_", "all") />	<!--- we are always going to get one of theses --->
	<cfset theTableName = replace(theTableName, '"', "_", "all") />	<!--- we shouldn't get these, filtered out b4 this but why take chances --->
	<cfif len(theTableName) gt 15>
		<!--- wrap the whole thing in a try/catch in case something breaks --->
		<cftry>
			<!--- generate a save string from the form fields and values --->
			<cfif StructCount(arguments.FieldSessionStruct) gt 1>	<!--- only do it if there are items in the field structure, we have one item that is a string, not a filed struct --->
				<cfset theFileUploadedFields = arguments.FieldSessionStruct.FilesUploaded.FieldList>
				<!--- 
				<cfset theQueryString0 = "INSERT INTO [dbo].[#theTableName#] (" />
				<cfset theQueryString1 = "EntryTimeStamp," />
				<cfset theQueryString2 = "values(#CreateODBCDateTime(now())#," />
				 --->
				<cfloop collection="#arguments.FieldSessionStruct#" item="thisField">
					<cfif thisField neq "FilesUploaded">
						<cfif arguments.FieldSessionStruct["#thisField#"].value neq "">
							<cfset theQueryString1 = theQueryString1 & "#thisField#," />
	<!--- 
							<cfif arguments.FieldSessionStruct["#thisField#"].>
								<cfset theQueryString2 = theQueryString2 & "#'arguments.FieldSessionStruct["#thisField#"].value#'," />
							<cfelse>
	 --->
								<cfif not ListFindNocase(theFileUploadedFields, thisField)>
									<cfset theQueryString2 = theQueryString2 & "'#arguments.FieldSessionStruct["#thisField#"].value#'," />
								<cfelse>
									<cfif arguments.FieldSessionStruct["#thisField#"].FileUploaded>
										<cfset theQueryString2 = theQueryString2 & "'#arguments.FieldSessionStruct["#thisField#"].FileUploaded_FinalFilename#'," />
									<cfelse>
										<cfset theQueryString2 = theQueryString2 & "'#arguments.FieldSessionStruct["#thisField#"].value#'," />
									</cfif>
								</cfif>
<!--- 
						</cfif>
 --->
						</cfif>
					</cfif>
				</cfloop>
				<!--- now remove the stray comma at the end --->
				<cfif len(theQueryString1)>
					<cfset theQueryString1 = removeChars(theQueryString1, len(theQueryString1), 1) />
				</cfif>
				<cfif len(theQueryString2)>
					<cfset theQueryString2 = removeChars(theQueryString2, len(theQueryString2), 1) />
				</cfif>
				<cfif len(theQueryString1) and len(theQueryString2)>
					<cfset theQueryString0 = theQueryString0 & theQueryString1 & ") " & theQueryString2 & ")" />
					<!---  and do it! --->
	<!--- 
						<cfoutput>
							#theQueryString1#<br>
							#theQueryString2#<br>
						</cfoutput>
						 --->
					<cfset loc.Temp = Nexts_ChecknSetNextID(IDname="FormDataID_#theTableName#", IDFormat="NT") />
					<cfquery name="updateFormTable" datasource="#variables.FormDataSource#">
						INSERT INTO [dbo].[#theTableName#] 
											(EntryTimeStamp, EntryID, #theQueryString1#)
							Values	(#CreateODBCDateTime(now())#,#Nexts_getNextID(IDName="FormDataID_#theTableName#")#,#PreserveSingleQuotes(theQueryString2)#)		
					</cfquery>
				</cfif>
<!--- 
					<cfoutput>#theQueryString0#</cfoutput>
 --->

			</cfif>
		<cfcatch type="any">
			<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 128) />
			<cfset ret.error.ErrorText = ret.error.ErrorContext & ' Trapped. Site: #application.SLCMS.Config.base.SiteName#, error message was: #cfcatch.message#, error detail was: #cfcatch.detail#' />
			<cfset ret.error.ErrorExtra =  cfcatch.TagContext />
			<cfif isArray(ret.error.ErrorExtra) and StructKeyExists(ret.error.ErrorExtra[1], "Raw_Trace")>
				<cfset ret.error.ErrorText = ret.error.ErrorText & ", Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#" />
			</cfif>
			<cflog text='#ret.error.ErrorText# - ret.error.ErrorCode: #ret.error.ErrorCode# - Time: #DateFormat(Now(),"YYYYMMDD")#-#TimeFormat(now(),"HH:mm:ss")#'  file="#application.SLCMS.Logging.theSiteLogName#" type="Error" application = "yes">
			<cfif application.SLCMS.Config.debug.debugmode>
				<cfoutput>#ret.error.ErrorContext#</cfoutput> Trapped - error dump:<br>
				<cfdump var="#cfcatch#">
			</cfif>
		</cfcatch>
		</cftry>
	<cfelse>	<!--- this is the error code --->
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 1) />
		<cfset ret.error.ErrorText = ret.error.ErrorText & "Oops! Table name invalid<br>" />
	</cfif>

	<cfreturn ret  />
</cffunction>

<cffunction name="getVariablesScope" output="no" returntype="struct" access="public" 
	displayname="get Variables"
	hint="gets the entire variables scope including the various forms of the navigation structure or specified variables structure"
	>
	<cfargument name="Struct" type="string" required="No" default="" hint="struct to return, defaults to all">	
	<cfif len(arguments.Struct) and StructKeyExists(variables, "#arguments.Struct#")>
		<cfreturn variables["#arguments.Struct#"] />
	<cfelse>
		<cfreturn variables />
	</cfif>
</cffunction>

<cffunction name="LogIt" output="No" returntype="struct" access="Private"
	displayname="Log It"
	hint="Local Function to log info to standard log space via application.SLCMS.Core.SLCMS_Utility.WriteLog_Core(), minimizes log code in individual functions"
	>
	<cfargument name="LogType" type="string" default="" hint="The log to write to" />
	<cfargument name="LogString" type="string" default="" hint="The string to write to the log" />

	<cfset var theLogType = trim(arguments.LogType) />
	<cfset var theLogString = trim(arguments.LogString) />
	<cfset var temps = "" />	<!--- temp/throwaway structure --->
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorText = "" />
	<cfset ret.error.ErrorContext = "SLCMS_Utility CFC: LogIt()" />
	<cfset ret.error.ErrorExtra = "" />
	<cfset ret.Data = "" />	<!--- no data --->

		<!--- validation --->
	<cfif theLogType neq "">
		<cftry>
			<cfset temps = application.SLCMS.Core.SLCMS_Utility.WriteLog_Core(LogType="#theLogType#", LogString="#theLogString#") />
			<cfif temps.error.errorcode neq 0>
				<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 2) />
				<cfset ret.error.ErrorText = ret.error.ErrorText & "Log Write Failed. Error was: #temps.error.ErrorText#<br>" />
			</cfif>
		<cfcatch type="any">
			<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 128) />
			<cfset ret.error.ErrorText = ret.error.ErrorContext & ' Trapped. Site: #application.SLCMS.Config.base.SiteName#, error message was: #cfcatch.message#, error detail was: #cfcatch.detail#' />
			<cfset ret.error.ErrorExtra =  cfcatch.TagContext />
			<cfif isArray(ret.error.ErrorExtra) and StructKeyExists(ret.error.ErrorExtra[1], "Raw_Trace")>
				<cfset ret.error.ErrorText = ret.error.ErrorText & ", Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#" />
			</cfif>
			<cflog text='#ret.error.ErrorText# - ret.error.ErrorCode: #ret.error.ErrorCode# - Time: #DateFormat(Now(),"YYYYMMDD")#-#TimeFormat(now(),"HH:mm:ss")#'  file="#application.SLCMS.Logging.theSiteLogName#" type="Error" application = "yes">
			<cfif application.SLCMS.Config.debug.debugmode>
				<cfoutput>#ret.error.ErrorContext#</cfoutput> Trapped - error dump:<br>
				<cfdump var="#cfcatch#">
			</cfif>
		</cfcatch>
		</cftry>
	<cfelse>	<!--- this is the error code --->
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 1) />
		<cfset ret.error.ErrorText = ret.error.ErrorText & "Oops! Unknown Log<br>" />
	</cfif>

	<cfreturn ret  />
</cffunction>

<cffunction name="TakeErrorCatch" output="Yes" returntype="any" access="private" 
	displayname="Take Error Catch"
	hint="Takes Error Trap in function and logs/displays it, etc"
	>
	<cfargument name="RetErrorStruct" type="struct" required="true" hint="the ret structure from the calling function" />	
	<cfargument name="CatchStruct" type="any" required="true" hint="the catch structure from the calling function" />	
	
	<!--- some temp vars --->
	<cfset var temps = "" />
	<cfset var error = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result it is just the error part of the standard ret struct --->
	<cfset error = StructNew() />
	<cfset error.ErrorCode = 0 />
	<cfset error.ErrorText = "" />
	<cfset error.ErrorContext = "" />
	<cfset error.ErrorExtra = "" />
	<cftry>
		<!--- build the standard return structure using whatever may have been fed in --->
		<cfset ret.error = StructNew() />
		<cfif StructKeyExists(arguments.RetErrorStruct, "ErrorCode")>
			<cfset error.ErrorCode = BitOr(error.ErrorCode, arguments.RetErrorStruct.ErrorCode) />
		</cfif>
		<cfif StructKeyExists(arguments.RetErrorStruct, "ErrorContext")>
			<cfset error.ErrorContext = arguments.RetErrorStruct.ErrorContext />
		</cfif>
		<cfif StructKeyExists(arguments.RetErrorStruct, "ErrorText")>
			<cfset error.ErrorText = arguments.RetErrorStruct.ErrorText />
		</cfif>
		<cfif StructKeyExists(arguments.CatchStruct, "TagContext")>
			<cfset error.ErrorExtra = arguments.CatchStruct.TagContext />
		<cfelse>
			<cfif StructKeyExists(arguments.RetErrorStruct, "ErrorExtra")>
				<cfset error.ErrorExtra = arguments.RetErrorStruct.ErrorExtra />
			</cfif>
		</cfif>
		<cfset error.ErrorText = error.ErrorConText & error.ErrorText & ' Trapped. Site: #application.SLCMS.Config.base.SiteName#, error message was: #arguments.CatchStruct.message#, error detail was: #arguments.CatchStruct.detail#' />
		<cfif isArray(error.ErrorExtra) and StructKeyExists(error.ErrorExtra[1], "Raw_Trace")>
			<cfset error.ErrorText = error.ErrorText & " Line: #ListLast(arguments.CatchStruct.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#" />
		</cfif>
		<cfset temps = LogIt(LogType="CFC_ErrorCatch", LogString='#error.ErrorText# - ErrorCode: #error.ErrorCode#') />
	<cfcatch type="any">
		<cfset error.ErrorCode =  BitOr(error.ErrorCode, 255) />
		<cfset error.ErrorText = error.ErrorContext & ' Trapped. Site: #application.SLCMS.Config.base.SiteName#, error message was: #cfcatch.message#, error detail was: #cfcatch.detail#' />
		<cfset error.ErrorText = error.ErrorText & ' caller error message was: #arguments.CatchStruct.message#, error detail was: #arguments.CatchStruct.detail#' />
		<cfset error.ErrorExtra =  arguments.CatchStruct.TagContext />
		<cfif isArray(error.ErrorExtra) and StructKeyExists(error.ErrorExtra[1], "Raw_Trace")>
			<cfset error.ErrorText = error.ErrorText & ", Line: #ListLast(arguments.CatchStruct.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#" />
		</cfif>
		<cflog text='TakeErrorCatch: Error Catch Caught: #error.ErrorText# - error.ErrorCode: #error.ErrorCode# - Time: #DateFormat(Now(),"YYYYMMDD")#-#TimeFormat(now(),"HH:mm:ss")#'  file="#application.SLCMS.Logging.theSiteLogName#" type="Error" application = "yes">
		<cfif application.SLCMS.Config.debug.debugmode>
			<cfoutput>#error.ErrorContext#</cfoutput> Trapped - error dump:<br>
			<cfdump var="#arguments.CatchStruct#">
		</cfif>
	</cfcatch>
	</cftry>	
	<cfreturn error  />
</cffunction>

</cfcomponent>