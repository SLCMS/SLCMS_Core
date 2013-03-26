<!---  --->
<!--- A simple CMS system by Mort Bay Communications Pty Ltd --->
<!--- Copyright 2002-2007 --->
<!---  --->
<!--- SiteStructure Management Home Page --->
<!--- include file with the main code processing --->
<!---  --->
<!--- Created:   5th Jan 2008 by Kym Kovan, cloned from original single file --->
<!--- modified: 16th May 2008 - 17th May 2008 by Kym K - mbcomms: added Home Page flag functionality that went missing somewhere along the line --->
<!---  --->
<!--- modified:  6th Sep 2008 -  6th Sep 2008 by Kym K, mbcomms: V2.1 , new architecture separating presentation from SLCMS code --->
<!--- modified:  9th Sep 2008 -  9th Sep 2008 by Kym K, mbcomms: changed a hard coded path to template folders with the site variable --->
<!--- modified: 25th Mar 2009 - 25th Mar 2009 by Kym K, mbcomms: V2.2, changing structures to new module-allowing architecture, the core code is now just another module --->
<!--- modified: 29th Mar 2009 - 30th Apr 2009 by Kym K, mbcomms: V2.2, changing structures to portal/sub-site architecture, sites inside site --->
<!--- modified:  6th Sep 2009 - 25th Sep 2009 by Kym K, mbcomms: V2.2, changing to user permissions system and adding portal capacity --->
<!--- modified:  2nd Oct 2009 -  5th Oct 2009 by Kym K, mbcomms: V2.2, added theAllowedSubsiteList and subsite changing --->
<!--- modified:  6th Nov 2009 -  7th Nov 2009 by Kym K, mbcomms: V2.2, adding subSite home page choosing --->
<!---  --->
<!--- modified: 18th Dec 2009 - 26th Dec 2009 by Kym K, mbcomms: V2.2+ now adding DataMgr as a DAL to make the codebase database agnostic
																																				NOTE: things like the DSN are no longer needed as the DAL knows that
																																							now we can just worry about tables and their contents
																																							See Content_DatabaseIO.cfc for DAL conversion examples (straight queries commented out there, not deleted as here) --->
<!--- modified:  5th Jun 2010 -  5th Jun 2010 by Kym K, mbcomms: V2.2+, bug fixes, still finding them!!! --->
<!--- modified: 11th Nov 2010 - 21st Nov 2010 by Kym K, mbcomms: V2.2+, adding modules, param4 added and param2 is now a list with first item being "core" or module name --->
<!--- modified: 23rd Mar 2011 - 22nd Apr 2011 by Kym K, mbcomms: V2.2+, adding code to decode module-specific params so we can choose deep objects in a module for page display, driven by jQuery in PageStructure admin --->
<!--- modified: 22nd May 2011 - 22nd May 2011 by Kym K, mbcomms: V2.2+, adding code to handle modules that do not have a front end --->
<!--- modified:  9th Jun 2011 -  9th Jun 2011 by Kym K, mbcomms: V2.2+, bugfix: added DocContentControlTable to request scope and changed queries to match (was not handling subsites properly) --->
<!--- modified:  2nd Jan 2012 -  2nd Jan 2012 by Kym K, mbcomms: V2.2+, changed the way templates are handled, changed template manager init() calls here to match --->

<!--- set up a few display functions for our nested tables, etc --->

<cfset ErrFlag  = False />
<cfset ErrMsg  = "" />
<cfset GoodMsg  = "" />
<cfset theQueryDataArguments = StructNew() />	<!--- temp struct to compose the data clauses of SQL queries --->
<cfset theQueryWhereArguments = StructNew() />	<!--- temp struct to compose the where clauses of SQL queries --->
<cfset theQueryWhereFilters = ArrayNew(1) />	<!--- temp array to compose the filters for where clauses --->
<!--- generic items done now set the page specific things --->
<cfset OpNext = "" />
<cfset backLinkText = "" />	<!--- when we hop out --->
<cfset DoUpdate = False />
<cfset bShowBreadCrumbLinks = False />
<cfset theURLPathToHere = "" />
<cfset dOriginalOption = "" />
<cfset request.SLCMS.ItemChangedFlag = StructNew() />	<!--- used to indicate if something has changed when going back to main display, format can vary but it often a struct of docID and name of changed paramater --->
<cfset request.SLCMS.ItemChangedFlag.ID = 0 />
<cfset request.SLCMS.ItemChangedFlag.Name = "" />
<cfset SubSiteParentage = StructNew() />	<!--- will carry all the bits we need to know about subsite parents and home pages --->
<!--- and strings for the id and classes used by jquery and the html --->
<cfset thejQueryOnReadyString = "" />
<cfset CRLF = chr(13)&chr(10) />
<cfset jqIdCoreNothingSelected = "$('##CoreNothingSelected')" /> 
<cfset jqIdCoreNothingSelectedInput = "$('##CoreNothingSelectedInput')" /> 
<cfset jqIdCoreFormSelected = "$('##CoreFormSelected')" /> 
<cfset jqIdCoreFormSelectedInput = "$('##CoreFormSelectedInput')" /> 
<!--- these are strings used in modules that don't exist in core but the html is there, but hidden --->
<cfset dModuleFriendlyName = "" />
<cfset dModuleSelectedHint = "" />
<cfset dPopURL = "" />
<cfset dDropOptions = "" />

<cfif IsDefined("url.mode")>
	<cfset WorkMode0 = url.mode />	<!--- code to run before the main set to work out the subsite we are in --->
	<cfset WorkMode = url.mode />
	<cfset DispMode = url.mode />
<cfelse>
	<cfset WorkMode0 = "" />
	<cfset WorkMode = "" />
	<cfset DispMode = "" />
</cfif>
<cfif isdefined("form.cancel")>	<!--- do nothing if cancelled --->
	<cfset WorkMode0 = "" />
	<cfset WorkMode = "" />
	<cfset DispMode = "" />
</cfif>


<!--- first some portal related code --->
<cfset request.SLCMS.PortalAllowed = application.SLCMS.Core.PortalControl.IsPortalAllowed() />
<cfif request.SLCMS.PortalAllowed>
	<cfset theAllowedSubsiteList = application.SLCMS.Core.PortalControl.GetAllowedSubSiteIDList_AllSites(UserID="#session.SLCMS.user.UserID#") />
	<cfif WorkMode0 eq "ChangeSubSite" and IsDefined("url.NewSubSiteID") and IsNumeric(url.NewSubSiteID)>
		<!--- set a new current state --->
		<cfset session.SLCMS.Currents.Admin.PageStructure.CurrentSubSiteID = url.NewSubSiteID />
		<cfset session.SLCMS.Currents.Admin.PageStructure.CurrentSubSiteFriendlyName = application.SLCMS.Core.PortalControl.GetSubSite(url.NewSubSiteID).data.SubSiteFriendlyName />
		<!--- work out the database tables --->		
		<cfset request.SLCMS.PageStructTable = application.SLCMS.config.DatabaseDetails.databaseTableNaming_Root_Site
																		&	session.SLCMS.Currents.Admin.PageStructure.CurrentSubSiteID
																		&	application.SLCMS.config.DatabaseDetails.databaseTableNaming_Tail_PageStructure />
		<!--- this code below is cloned in App.cfc in OnRequestStart to make sure we have something first time in (using site_0) --->
		<cfset session.SLCMS.pageAdmin.NavState = StructNew()/>	<!--- dump all old data --->
		<!--- set up our vars to display the structure from --->
		<cfset session.SLCMS.pageAdmin.NavState.theOriginalNavArray = Duplicate(application.SLCMS.Core.PageStructure.getFullNavArray(SubSiteID=session.SLCMS.Currents.Admin.PageStructure.CurrentSubSiteID)) />
		<cfset session.SLCMS.pageAdmin.NavState.theCurrentNavArray = Duplicate(application.SLCMS.Core.PageStructure.getFullNavArray(SubSiteID=session.SLCMS.Currents.Admin.PageStructure.CurrentSubSiteID)) />
		<cfset session.SLCMS.pageAdmin.NavState.dispRowCounter = 0 />
		<cfset session.SLCMS.Currents.Admin.PageStructure.FlushExpansionFlags = True />
		<cfset WorkMode = "" />
		
	<cfelseif WorkMode0 eq "xxx" >	<!--- next workmode0 --->
	
	<cfelse>	<!--- no workmode0 so set up defaults/currents --->
		<cfset request.SLCMS.PageStructTable = application.SLCMS.config.DatabaseDetails.databaseTableNaming_Root_Site
																		&	session.SLCMS.Currents.Admin.PageStructure.CurrentSubSiteID
																		&	application.SLCMS.config.DatabaseDetails.databaseTableNaming_Tail_PageStructure />
	</cfif>
<cfelse>
	<!--- no portal ability so force to site zero --->
	<cfset theAllowedSubsiteList = "0" />
	<cfset session.SLCMS.Currents.Admin.PageStructure.CurrentSubSiteID = 0 />
	<cfset request.SLCMS.PageStructTable = application.SLCMS.config.DatabaseDetails.TableName_Site_0_PageStruct />
</cfif>

<!--- square off the display flags and things --->
<cfif session.SLCMS.Currents.Admin.PageStructure.FlushExpansionFlags>
	<!--- and initialise the nav tree expansion flag structure with all collapsed --->
	<cfset session.SLCMS.pageAdmin.NavState.ExpansionFlags = StructNew()/>
	<cfset StructClear(theQueryWhereArguments) />
	<cfset getAllDocIDs = application.SLCMS.Core.DataMgr.getRecords(tablename="#request.SLCMS.PageStructTable#", data=theQueryWhereArguments, fieldList="DocID") />
	<!--- 
	<cfquery name="getAllDocs" datasource="#application.SLCMS.config.datasources.CMS#">
		select	DocID
			from	#request.SLCMS.PageStructTable#
	</cfquery>
	 --->
	<cfloop query="getAllDocIDs">
		<cfset session.SLCMS.pageAdmin.NavState.ExpansionFlags[getAllDocIDs.DocID] = False />
	</cfloop>
	<cfset session.SLCMS.Currents.Admin.PageStructure.FlushExpansionFlags = False />
</cfif>



<!--- 
<cfif StructKeyExists(session, "CurrentFolder")>
	<cfset CurrentFolder = session.SLCMS.Currents.Admin.PageStructure.CurrentFolder>
<cfelse>
	<cfset CurrentFolder = 0>
</cfif>
<cfif StructKeyExists(session, "CurrentParentID")>
	<cfset CurrentParentID = session.SLCMS.Currents.Admin.PageStructure.CurrentParentID>
<cfelse>
	<cfset CurrentParentID = 0>
</cfif>
 --->

<cfif WorkMode eq "AddPage">
	<!--- set up for add mode --->
	<cfif IsDefined("url.CurrentPage") and IsNumeric(url.CurrentPage) and url.CurrentPage neq 0>
		<cfset hParentID = url.CurrentPage />
		<cfset StructClear(theQueryWhereArguments) />
		<cfset theQueryWhereArguments.DocID = hParentID />
		<cfset GetParentPage = application.SLCMS.Core.DataMgr.getRecords(tablename="#request.SLCMS.PageStructTable#", data=theQueryWhereArguments, fieldList="NavName,URLNameEncoded,ParentID") />
		<!--- 
		<cfquery name="GetParentPage" datasource="#application.SLCMS.config.datasources.CMS#">
			SELECT	NavName, URLNameEncoded, ParentID
				FROM	#request.SLCMS.PageStructTable#
				WHERE	DocID = #hParentID#
		</cfquery>
		 --->
		<cfset dParentNavName = GetParentPage.NavName />
		<cfset theURLPathToHere = GetParentPage.URLNameEncoded />
		<cfset theParentID = GetParentPage.ParentID />
		<!--- see if we are top of tree, if not grab the rest of the parents to show our path down to this page --->
		<cfif theParentID neq 0>
			<cfloop condition="#theParentID# neq 0">
				<cfset StructClear(theQueryWhereArguments) />
				<cfset theQueryWhereArguments.DocID = theParentID />
				<cfset GetParentPage1 = application.SLCMS.Core.DataMgr.getRecords(tablename="#request.SLCMS.PageStructTable#", data=theQueryWhereArguments, fieldList="NavName,URLNameEncoded,ParentID") />
				<!--- 
				<cfquery name="GetParentPage1" datasource="#application.SLCMS.config.datasources.CMS#">
					SELECT	NavName, URLNameEncoded, ParentID
						FROM	#request.SLCMS.PageStructTable#
						WHERE	DocID = #theParentID#
				</cfquery>
				 --->
				<cfset theParentID = GetParentPage1.ParentID />
				<cfset theURLPathToHere = GetParentPage1.URLNameEncoded &"/"& theURLPathToHere />
			</cfloop>
		</cfif>
	<cfelse>
		<cfset theURLPathToHere = "" />
		<cfset hParentID = 0 />
		<cfset dParentNavName = "" />
	</cfif>
	<cfif left(theURLPathToHere,1) neq "/">
		<cfset theURLPathToHere = "/"& theURLPathToHere />
	</cfif>
	<cfif right(theURLPathToHere,1) neq "/">
		<cfset theURLPathToHere = theURLPathToHere & "/" />
	</cfif>
	<!--- done our sums so not create all of the display vars, etc. --->
	<cfset DispMode = "AddPage" />
	<cfset opnext = "SaveAddPage" />	<!--- what we do next --->
	<cfset backLinkText = "Cancel Adding Page, " />	<!--- when we hop out --->
	<cfset dNavName = "" />
	<cfset dURLName = "" />
	<cfset dIsHomePage = False /> <!--- when we create a page make sure its not the home page so we don't break anything, only change this in an edit --->
	<cfset dHasContent = 1 />
	<cfset dIsParent = 0 />
	<cfset dDocType = 2 />
	<cfset dDocID = 0 />
	<cfset dParam1 = "" />
	<cfset dParam2 = "" />
	<cfset dParam3 = "" />
	<cfset dParam4 = "" />
	<cfset hOldNavName = "" />
	<cfset dDoUpdate = False />
	<!--- these are flags used to set up initial display in edit mode, here are just dummies --->
	<cfset cModule = "Core" />
	<cfset cDispType = "Standard" />
	<!--- and here we set up a bunch of strings that will get used down in the jQuery
				we do it this way as a lot of ifs and buts in the html code section creates nasty white space
				and breaks the jquery in some fussy browsers
				Hide everything by default and then the jQuery functions will turn on the param display/input matches the page display
				and remember that one must be on somewhere for params3 upwards so we don't have a missing form field --->
	<cfset thejQueryOnReadyString = thejQueryOnReadyString & "ShowNoParam3Needed();" & CRLF />	<!--- this is our "blank" param3 & 4 --->
	<cfset thejQueryOnReadyString = thejQueryOnReadyString & "HideCoreNothingSelected();" & CRLF />
	<cfset thejQueryOnReadyString = thejQueryOnReadyString & "HideCoreDropDownSelectBox();" & CRLF />
	<cfset thejQueryOnReadyString = thejQueryOnReadyString & "HideFormSelected();" & CRLF />
	<cfset thejQueryOnReadyString = thejQueryOnReadyString & "HideModuleSelected();" & CRLF />
	<cfset thejQueryOnReadyString = thejQueryOnReadyString & "theSelectedModuleFriendlyName = '';" & CRLF />
	
<cfelseif WorkMode eq "SaveAddPage">	<!--- save the new Page --->
	<cfset OK = True>	<!--- tyhis flag will go false if we have anything wrong --->
	<!--- work out the parameters according to selections (its overly complicated to handle missing form fields) --->
	<cfparam name="form.param3" default="" type="string" />
	<cfparam name="form.param4" default="" type="string" />
	<cfif IsDefined("form.param1a") and len(trim(form.param1a))>
		<cfset theParam1 = trim(form.param1a) />
	<cfelseif IsDefined("form.param1b") and len(trim(form.param1b))>
		<cfset theParam1 = trim(form.param1b) />
	<cfelse>
		<cfset theParam1 = "" />
	</cfif>
	<cfif IsDefined("form.param2a") and len(trim(form.param2a))>
		<cfset theParam2 = trim(form.param2a) />
	<cfelseif IsDefined("form.param2b") and len(trim(form.param2b))>
		<cfset theParam2 = trim(form.param2b) />
	<cfelse>
		<cfset theParam2 = "" />
	</cfif>
	<cfset theParam3 = trim(form.param3) />
	<cfset theParam4 = trim(form.param4) />
	<cfif IsDefined("form.IsParent") and form.IsParent eq 1>
		<cfset bIsParent = 1 />
	<cfelse>
		<cfset bIsParent = 0 />
	</cfif>
	<cfif IsDefined("form.HasContent") and form.HasContent eq 1>
		<cfset bHasContent = 1 />
	<cfelse>
		<cfset bHasContent = 0 />
	</cfif>
	<cfif theParam1 eq "" and theParam2 eq "">
		<cfset errmsg = "No Page Parameters selected or entered. ">
		<cfset ok = false>
	</cfif>
	<!--- 1st test for legit stuff --->
	<cfif form.NavName eq "">
		<cfset errmsg = errmsg & "No Page Name entered. ">
		<cfset ok = false>
	<!--- 
	<cfelseif form.PageNameURL contains " ">
		<cfset errmsg = "Page Name cannot contain spaces">
		<cfset ok = false>
	 --->
	</cfif>
	<!--- 
	<cfif form.PageType eq 2 and form.PageNameURL eq theParam1>
		<cfset errmsg = "If an included file the URL Page Name cannot be the same as the actual file name">
		<cfset ok = false>
	</cfif>
	 --->
	<!--- check to see if we have changed to folder's name --->
	<!--- its different so check that new name is OK --->
	<cfset FNameChanged = True>
	<!--- check duplicate Page names --->
	<cfset StructClear(theQueryWhereArguments) />
	<cfset theQueryWhereArguments.NavName = trim(form.NavName) />
	<cfset theQueryWhereArguments.parentID = form.parentID />
	<cfset checkDup = application.SLCMS.Core.DataMgr.getRecords(tablename="#request.SLCMS.PageStructTable#", data=theQueryWhereArguments, fieldList="NavName") />
	<!--- 
	<cfquery name="checkDup" datasource="#application.SLCMS.config.Datasources.CMS#">
		select * from	#request.SLCMS.PageStructTable#
			WHERE	NavName = '#trim(form.NavName)#' and parentID = #form.parentID#
	</cfquery>
	 --->
	<cfif checkDup.recordcount>
		<cfset errmsg = errmsg & "The Page name you have just entered has already been assigned in this folder. ">
		<cfset ok = false>
	</cfif>
	<cfif ok>
		<!--- work out the Display Position, DO --->
		<!--- 
		<cfset StructClear(theQueryDataArguments) />
		<cfset StructClear(theQueryWhereArguments) />
		<cfset theQueryWhereArguments.Select = "Max(DO) as TopDO" />
		<cfset theQueryWhereArguments.Where = "parentID = #form.parentID#" />
		<!--- 
		<cfset theQueryWhereArguments.parentID = form.parentID />
		 --->
		<cfset getTopDO = application.SLCMS.Core.DataMgr.getRecords(tablename="#request.SLCMS.PageStructTable#", advsql=theQueryWhereArguments, fieldlist="DocID") />
		 --->
		<!--- 
		<cfoutput>getTopDO: <cfdump var="#getTopDO#"></cfoutput>
		<cfabort>
		 --->
		<cfquery name="getTopDO" datasource="#application.SLCMS.config.Datasources.CMS#">
			select Max(DO) as TopDO 
				from	#request.SLCMS.PageStructTable#
				WHERE	parentID = #form.parentID#
		</cfquery>
		<cfif getTopDO.RecordCount and getTopDO.TopDO neq "">
			<cfset newDO = getTopDO.TopDO+1 /> <!--- stick it at the bottom --->
		<cfelse>
			<cfset newDO = 1 />
		</cfif>
		<!--- get the straight version of the URLName to be friendly --->
		<cfset theURLNameDecoded = application.SLCMS.Core.PageStructure.DecodeNavName(form.URLName)>
		<!--- 
		<cfset newDocID = application.SLCMS.mbc_utility.utilities.getnextID("DocID") />
		 --->
		<cfset newDocID = Nexts_getNextID("DocID") />
		<!--- get the new page into the database --->
		<cfset StructClear(theQueryDataArguments) />
		<cfset theQueryDataArguments.NavName = form.NavName />
		<cfset theQueryDataArguments.URLName = theURLNameDecoded />
		<cfset theQueryDataArguments.HasContent = bHasContent />
		<cfset theQueryDataArguments.IsParent = bIsParent />
		<cfset theQueryDataArguments.Param1 = theParam1 />
		<cfset theQueryDataArguments.Param2 = theParam2 />
		<cfset theQueryDataArguments.Param3 = theParam3 />
		<cfset theQueryDataArguments.Param4 = theParam4 />
		<cfset theQueryDataArguments.DocType = form.PageType />
		<cfset theQueryDataArguments.DocID = newDocID />
		<cfset theQueryDataArguments.ParentID = form.parentID />
		<cfset theQueryDataArguments.DefaultDocID = newDocID />
		<cfset theQueryDataArguments.DO = newDO />
		<cfset theQueryDataArguments.IsHomePage = 0 />
		<cfset theQueryDataArguments.Hidden = 1 />
		<cfset theQueryDataArguments.URLNameEncoded = form.URLName />
		<cfset addPage = application.SLCMS.Core.DataMgr.InsertRecord(tablename="#request.SLCMS.PageStructTable#", data=theQueryDataArguments) />
		<!--- 
		<cfquery name="addPage" datasource="#application.SLCMS.config.Datasources.CMS#">
			Insert Into	#request.SLCMS.PageStructTable#
								(NavName, URLName, HasContent, IsParent, Param1, Param2, Param3,
								DocType, DocID, ParentID, DefaultDocID, DO, IsHomePage, Hidden, URLNameEncoded)
				Values	('#form.NavName#', '#theURLNameDecoded#', '#bHasContent#', '#bIsParent#', '#theParam1#', '#theParam2#', '#form.Param3#',
									#form.PageType#, #NewDocID#, #form.parentID#, #NewDocID#, #newDO#, 0, 1, '#form.URLName#')
		</cfquery>
		 --->
		<!--- and tell the parent it has a child --->
		<!--- 
		<cfset StructClear(theQueryDataArguments) />
		<cfset StructClear(theQueryWhereArguments) />
		<cfset theQueryDataArguments.IsParent = 1 />
		<cfset SetParent = application.SLCMS.Core.DataMgr.UpdateRecords(tablename="#request.SLCMS.PageStructTable#", data_set=theQueryDataArguments, data_where=theQueryWhereArguments) />
		 --->
		<cfquery name="SetParent" datasource="#application.SLCMS.config.Datasources.CMS#">
			update	#request.SLCMS.PageStructTable#
				set	IsParent = 1,
						Children = Children+1
				where	DocID = #form.parentID#
		</cfquery>
		<!--- if the parent wasn't expanded make it so now as it has gained a child --->
		<cfset session.SLCMS.pageAdmin.NavState.ExpansionFlags[form.parentID] = True>
		<!--- all done so refresh the site structures and create a stats instance for it --->
		<cfset UpdateNavArrays() />
		<cfif application.SLCMS.config.Components.Use_Stats eq "yes">
			<cfset temp = application.SLCMS.mbc_Utility.Stats.AddHit(SiteName="Page_Hit_ID_#NewDocID#")>
		</cfif>
		<!--- and tell the world we had a change with view back to the listing --->
		<cfset request.SLCMS.ItemChangedFlag.ID = NewDocID />
		<cfset request.SLCMS.ItemChangedFlag.Name = "PP" />
		<cfset DispMode = "" />
	<cfelse>	<!--- not OK entry so reset form --->
		<cfset backLinkText = "Cancel Adding Page, " />	<!--- when we hop out --->
		<cfset dNavName = form.NavName />
		<cfset dURLName = form.URLName />
		<cfset dDocType = form.PageType />
		<cfset dDocID = "" />
		<cfset dIsHomePage = False />
		<cfset dIsParent = bIsParent />
		<cfset dHasContent = bHasContent />
		<cfset dParam1 = theParam1 />
		<cfset dParam2 = theParam2 />
		<cfset dParam3 = theParam3 />
		<cfset dParam4 = theParam4 />
		<cfset hParentID = form.ParentID />
		<cfset dParentNavName = form.ParentNavName />
		<cfset hOldNavName = "" />
		<cfset DoUpdate = False />
		<cfset cModule = "Core" />
		<cfset cDispType = "Standard" />
		<cfset DispMode = "AddPage" />
	</cfif>
	
<cfelseif WorkMode eq "editPage">
	<cfset CurrentPage = url.CurrentDocID>
	<cfset session.SLCMS.CurrentPage = CurrentPage>
	<!--- get data to edit --->
	<cfset StructClear(theQueryWhereArguments) />
	<cfset theQueryWhereArguments.DocID = CurrentPage />
	<cfset GetPage = application.SLCMS.Core.DataMgr.getRecords(tablename="#request.SLCMS.PageStructTable#", data=theQueryWhereArguments) />
	<!--- 
	<cfquery name="GetPage" datasource="#application.SLCMS.config.datasources.CMS#">
		SELECT	*
			FROM	#request.SLCMS.PageStructTable#
			WHERE	DocID = #CurrentPage#
	</cfquery>
	 --->
	<cfset StructClear(theQueryWhereArguments) />
	<cfset theQueryWhereArguments.ParentID = CurrentPage />
	<cfset getChildren = application.SLCMS.Core.DataMgr.getRecords(tablename="#request.SLCMS.PageStructTable#", data=theQueryWhereArguments, fieldList="NavName,DocID", orderby="DO") />
	<!--- 
	<cfquery name="getChildren" datasource="#application.SLCMS.config.datasources.CMS#">
		select	NavName, DocID
			from	#request.SLCMS.PageStructTable#
			where	ParentID = #CurrentPage#
			order by	DO
	</cfquery>
	 --->
	<!--- find the path to here so we can show it for copying, etc --->
	<cfif GetPage.ParentID neq 0>
		<cfset StructClear(theQueryWhereArguments) />
		<cfset theQueryWhereArguments.DocID = GetPage.ParentID />
		<cfset GetParentPage = application.SLCMS.Core.DataMgr.getRecords(tablename="#request.SLCMS.PageStructTable#", data=theQueryWhereArguments, fieldList="NavName,URLNameEncoded,ParentID") />
		<!--- 
		<cfquery name="GetParentPage" datasource="#application.SLCMS.config.datasources.CMS#">
			SELECT	NavName, URLNameEncoded, ParentID
				FROM	#request.SLCMS.PageStructTable#
				WHERE	DocID = #GetPage.ParentID#
		</cfquery>
		 --->
		<cfset theURLPathToHere = GetParentPage.URLNameEncoded />
		<cfset theParentID = GetParentPage.ParentID />
	<cfelse>
		<cfset theURLPathToHere = "" />
		<cfset theParentID = 0 />
	</cfif>
	<!--- see if we are top of tree, if not grab the rest of the parents to show our path down to this page --->
	<cfif theParentID neq 0>
		<cfloop condition="#theParentID# neq 0">
			<cfset StructClear(theQueryWhereArguments) />
			<cfset theQueryWhereArguments.DocID = theParentID />
			<cfset GetParentPage1 = application.SLCMS.Core.DataMgr.getRecords(tablename="#request.SLCMS.PageStructTable#", data=theQueryWhereArguments, fieldList="NavName,URLNameEncoded,ParentID") />
			<!--- 
			<cfquery name="GetParentPage1" datasource="#application.SLCMS.config.datasources.CMS#">
				SELECT	NavName, URLNameEncoded, ParentID
					FROM	#request.SLCMS.PageStructTable#
					WHERE	DocID = #theParentID#
			</cfquery>
			 --->
			<cfset theParentID = GetParentPage1.ParentID />
			<cfset theURLPathToHere = GetParentPage1.URLNameEncoded &"/"& theURLPathToHere />
		</cfloop>
	</cfif>
	<cfif left(theURLPathToHere,1) neq "/">
		<cfset theURLPathToHere = "/"& theURLPathToHere />
	</cfif>
	<cfif right(theURLPathToHere,1) neq "/">
		<cfset theURLPathToHere = theURLPathToHere & "/" />
	</cfif>
	<cfset dNavName = GetPage.NavName>
	<cfset dURLName = GetPage.URLNameEncoded>
	<cfset backLinkText = "Cancel Editing Page, " />	<!--- when we hop out --->
	<cfset dIsHomePage = GetPage.IsHomePage />
	<cfset dIsParent = GetPage.IsParent>
	<cfset dHasContent = GetPage.HasContent>
	<!--- 
	<cfset dAbbrvName = GetPage.AbbrvName>
	 --->
	<cfset dDocType = GetPage.DocType />
	<cfset dDocID = GetPage.DefaultDocID />
	<cfset dParam1 = GetPage.Param1 />
	<cfset dParam2 = GetPage.Param2 />
	<cfset dParam3 = GetPage.Param3 />
	<cfset dParam4 = GetPage.Param4 />
	<cfset hOldNavName = GetPage.NavName />
	<cfset hParentID = GetPage.ParentID />
	<cfset DoUpdate = False />
	<cfset opnext = "SaveEditPage" />
	<!--- these are flags used to set up initial display --->
	<cfif ListLen(dParam2) gt 1>
		<cfset cModule = ListFirst(dParam2) />
		<cfset cDispType = ListLast(dParam2) />
	<cfelse>	<!--- for legacy databases --->
		<cfset cModule = "Core" />
		<cfset cDispType = dParam2 />
	</cfif>
	<!--- and here we set up a bunch of strings that will get used down in the jQuery
				we do it this way as a lot of ifs and buts in the html code section creates nasty white space
				and breaks the jquery in some fussy browsers
				Hide everything by default and then turn on which one matches the page
				and remember that one must be on somewhere for params3 and upwards so we don't have a missing form field --->
	<cfif cModule eq "Core">
		<cfif cDispType eq "">
			<!--- no params to guide us --->
			<cfif application.SLCMS.Core.SLCMS_Utility.DoPagesHaveTemplatesOnly()>
				<cfset thejQueryOnReadyString = thejQueryOnReadyString & 'HideCoreNothingSelected();' & CRLF />
				<cfset thejQueryOnReadyString = thejQueryOnReadyString & 'ShowNoParam3Needed();' & CRLF />	<!--- blank param3 here --->
			<cfelse>
				<cfset thejQueryOnReadyString = thejQueryOnReadyString & 'ShowCoreNothingSelected();' & CRLF />	<!--- param3 here --->
				<cfset thejQueryOnReadyString = thejQueryOnReadyString & 'HideNoParam3Needed();' & CRLF />
			</cfif>
			<cfset thejQueryOnReadyString = thejQueryOnReadyString & 'HideCoreDropDownSelectBox();' & CRLF />
			<cfset thejQueryOnReadyString = thejQueryOnReadyString & 'HideFormSelected();' & CRLF />
			<cfset thejQueryOnReadyString = thejQueryOnReadyString & 'HideModuleSelected();' & CRLF />
		<!--- we do have params so show the relevant bits --->
		<cfelseif cDispType eq "Form">	<!--- core form page --->
			<cfset thejQueryOnReadyString = thejQueryOnReadyString & 'ShowFormSelected();' & CRLF />	<!--- param3 here, form dropdown selector --->
			<cfset thejQueryOnReadyString = thejQueryOnReadyString & 'HideNoParam3Needed();' & CRLF />
			<cfset thejQueryOnReadyString = thejQueryOnReadyString & 'HideCoreNothingSelected();' & CRLF />
			<cfset thejQueryOnReadyString = thejQueryOnReadyString & 'HideCoreDropDownSelectBox();' & CRLF />
			<cfset thejQueryOnReadyString = thejQueryOnReadyString & 'HideModuleSelected();' & CRLF />
		<cfelse> <!--- nothing we can use --->
			<cfset thejQueryOnReadyString = thejQueryOnReadyString & 'ShowNoParam3Needed();' & CRLF />	<!--- this is our "blank" param3 --->
			<cfset thejQueryOnReadyString = thejQueryOnReadyString & 'HideCoreNothingSelected();' & CRLF />
			<cfset thejQueryOnReadyString = thejQueryOnReadyString & 'HideCoreDropDownSelectBox();' & CRLF />
			<cfset thejQueryOnReadyString = thejQueryOnReadyString & 'HideFormSelected();' & CRLF />
			<cfset thejQueryOnReadyString = thejQueryOnReadyString & 'HideModuleSelected();' & CRLF />
		</cfif>
	<cfelse> <!--- not core so presumably a module --->
		<cfset thejQueryOnReadyString = thejQueryOnReadyString & 'HideCoreParts();' & CRLF />
		<cfset dModuleFriendlyName = "" />
		<cfset dPopURL = "" />
		<cfset dDropOptions = "" />
		<!--- lets see what we need to set up --->
		<cfset retModuleContentType =application.SLCMS.System.ModuleManager.getModuleContentTypeSelector(Module="#cModule#", ContentType="#cDispType#", subSiteID="#session.SLCMS.Currents.Admin.PageStructure.CurrentSubSiteID#", UserID="#session.SLCMS.user.UserID#") />
		<cfif retModuleContentType.error.errorCode eq 0>
			<!--- good module data so set up the display strings --->
			<cfset thejQueryOnReadyString = thejQueryOnReadyString & "theSelectedModuleFriendlyName = '#application.SLCMS.modules["#cModule#"].FriendlyName#';" & CRLF />
			<cfset thejQueryOnReadyString = thejQueryOnReadyString & "theSelectedModuleHintText = '#retModuleContentType.data.ModuleSelectedHint#';" & CRLF />
			<cfset thejQueryOnReadyString = thejQueryOnReadyString & "theSelectedModuleWhatText = '#retModuleContentType.data.ModuleWhatSelectionHint#';" & CRLF />
			<cfset thejQueryOnReadyString = thejQueryOnReadyString & "theSelectedModuleSelectionText = '#retModuleContentType.data.ModuleSelectionHint#';" & CRLF />
			<cfset dModuleFriendlyName = application.SLCMS.modules["#cModule#"].FriendlyName />
			<cfset dModuleSelectedHint = retModuleContentType.data.ModuleSelectedHint />
			<cfset dModuleFriendlyName = application.SLCMS.modules["#cModule#"].FriendlyName />
			<cfset dModuleSelectedHint = retModuleContentType.data.ModuleSelectedHint />
			<!--- and then set the initial display depending on type --->
			<cfif lcase(retModuleContentType.data.SelectDisplayMode) eq "popup">
				<cfset dPopURL = retModuleContentType.data.PopURL />
				<cfset theAPICallArguments = {Param2=dparam2, Param3=dparam3, Param4=dparam4} />
				<cfset FriendlySelectedItemString =application.SLCMS.System.ModuleManager.callQuickModuleCoreAPIcfc(Module="#cModule#", Method="makeQuickFriendlyStringFromParamSet", MethodArguments="#theAPICallArguments#", subSiteID="#session.SLCMS.Currents.Admin.PageStructure.CurrentSubSiteID#", UserID="#session.SLCMS.user.UserID#") />
<!---
				<cfset FriendlySelectedItemString = "test" />
--->
				<cfset thejQueryOnReadyString = thejQueryOnReadyString & "UpdateSelectedItemsText('#jsStringFormat(FriendlySelectedItemString)#');" & CRLF />
				<cfset thejQueryOnReadyString = thejQueryOnReadyString & "HideModuleDropDownSelectBox();" & CRLF />
				<cfset thejQueryOnReadyString = thejQueryOnReadyString & "ShowPopupMode();" & CRLF />
			<cfelseif lcase(retModuleContentType.data.SelectDisplayMode) eq "dropdown">
				<cfloop from="1" to="#ArrayLen(retModuleContentType.data.OptionArray)#" index="thisOption">
					<cfset theOptionValue = retModuleContentType.data.OptionArray[thisOption].Value />
					<cfif theOptionValue eq dParam3>
						<cfset OptionChecked = ' selected="selected"' />
					<cfelse>
						<cfset OptionChecked = "" />
					</cfif>
					<cfset dDropOptions = dDropOptions & '<option value="#theOptionValue#"#OptionChecked#>#retModuleContentType.data.OptionArray[thisOption].Display#</option>' />
				</cfloop>
				<cfset thejQueryOnReadyString = thejQueryOnReadyString & "HidePopupMode();" & CRLF />
				<cfset thejQueryOnReadyString = thejQueryOnReadyString & "ShowModuleDropDownSelectBox();" & CRLF />
			</cfif>
<!---
			<cfset theOutput.MODULEFORMALNAME = theModule />
			<cfset theOutput.MODULEFRIENDLYNAME = application.SLCMS.modules["#theModule#"].FriendlyName />
			<cfset theOutput.SELECTDISPLAYMODE = lcase(retModuleContentType.data.SelectDisplayMode) />
			<cfif theOutput.SELECTDISPLAYMODE eq "popup">
				<cfset theOutput.POPURL = retModuleContentType.data.PopURL />
			<cfelseif theOutput.SELECTDISPLAYMODE eq "dropdown">
				<cfset theOutput.DROPDOWNDATA = retModuleContentType.data.OptionArray />
			</cfif>
--->
		<cfelse>
			<!--- no module found or an error --->
			<cfset dPopURL = "" />
			<cfset dDropOptions = "<option value="">-- N/A --</option>" />
			<cfset dModuleFriendlyName = "Error from Module Manager:- Code: #retModuleContentType.error.ErrorCode#, Detail: #retModuleContentType.error.errorText#" />
			<cfset thejQueryOnReadyString = thejQueryOnReadyString & "" />
			<cfset thejQueryOnReadyString = thejQueryOnReadyString & "theSelectedModuleFriendlyName = 'Error from Module Manager:- Code: #retModuleContentType.error.ErrorCode#, Detail: #retModuleContentType.error.errorText#';" & CRLF />
		</cfif>
		<!--- all sorted so turn on the module display --->
		<cfset thejQueryOnReadyString = thejQueryOnReadyString & 'ShowModuleSelected();' & CRLF />	<!--- the module selection details, params 3 & 4 --->
	</cfif>
	
<cfelseif WorkMode eq "SaveEditPage">	<!--- save the edited Page --->
	<!--- work out the parameters according to selections --->
	<!--- some of this is over the top but allows for missing form fields, etc --->
	<cfparam name="form.param3" default="" type="string" />
	<cfparam name="form.param4" default="" type="string" />
	<cfif len(trim(form.param1a))>
		<cfset theParam1 = trim(form.param1a) />
	<cfelse>
		<cfset theParam1 = trim(form.param1b) />
	</cfif>
	<cfif len(trim(form.param2a))>
		<cfset theParam2 = trim(form.param2a) />
	<cfelse>
		<cfset theParam2 = trim(form.param2b) />
	</cfif>
	<cfset theParam3 = trim(form.param3) />
	<cfset theParam4 = trim(form.param4) />
	<cfif IsDefined("form.IsHomePage") and form.IsHomePage eq 1>
		<cfset bIsHomePage = 1 />
	<cfelse>
		<cfset bIsHomePage = 0 />
	</cfif>
	<cfif IsDefined("form.IsParent") and form.IsParent eq 1>
		<cfset bIsParent = 1 />
	<cfelse>
		<cfset bIsParent = 0 />
	</cfif>
	<cfif IsDefined("form.HasContent") and form.HasContent eq 1>
		<cfset bHasContent = 1 />
	<cfelse>
		<cfset bHasContent = 0 />
	</cfif>
	<cfif IsDefined("form.SubSiteParent") and form.SubSiteParent neq "">
		<cfset bIsSubSiteParent = 1 />
		<cfset ParentOfSubSiteID = form.SubSiteParent />
	<cfelse>
		<cfset bIsSubSiteParent = 0 />
		<cfset ParentOfSubSiteID = "" />
	</cfif>
	<!--- 1st test for legit stuff --->
	<cfset OK = True>
	<cfif form.NavName eq "">
		<cfset errmsg = "No Page Name entered">
		<cfset ok = false>
	<!--- 
	<cfelseif form.PageNameURL contains " ">
		<cfset errmsg = "Page Name cannot contain spaces">
		<cfset ok = false>
	 --->
	</cfif>
	<!--- 
	<cfif form.PageType eq 2 and form.PageNameURL eq theParam1>
		<cfset errmsg = "If an included file the URL Page Name cannot be the same as the actual file name">
		<cfset ok = false>
	</cfif>
	 --->
	<!--- check to see if we have changed to folder's name --->
	<cfif form.NavName neq form.OldNavName>
		<!--- its different so check that new name is OK --->
		<cfset FNameChanged = True>
		<!--- check duplicate Page names --->
		<cfset StructClear(theQueryWhereArguments) />
		<cfset theQueryWhereArguments.NavName = trim(form.NavName) />
		<cfset theQueryWhereArguments.parentID = form.parentID />
		<cfset checkDup = application.SLCMS.Core.DataMgr.getRecords(tablename="#request.SLCMS.PageStructTable#", data=theQueryWhereArguments, fieldList="NavName") />
		<!--- 
		<cfquery name="checkDup" datasource="#application.SLCMS.config.Datasources.CMS#">
			select * from	#request.SLCMS.PageStructTable#
				WHERE	NavName = '#trim(form.NavName)#' and parentID = #form.parentID#
		</cfquery>
		 --->
		<cfif checkDup.recordcount>
			<cfset errmsg = errmsg & "The Page name you have just entered has already been assigned in this folder.">
			<cfset ok = false>
		</cfif>
	<cfelse>	
		<cfset FNameChanged = False>
	</cfif>
	<cfif ok>
		<cfif bIsSubSiteParent>
			<cfset ret = application.SLCMS.Core.PortalControl.setSubSiteParentage(subSiteID=ParentOfSubSiteID, ParentDocID=session.SLCMS.CurrentPage)>
		<cfelse>
			<cfset ret = application.SLCMS.Core.PortalControl.clearSubSiteParentage(ParentDocID=session.SLCMS.CurrentPage)>
		</cfif>
		<cfset theURLNameDecoded = application.SLCMS.Core.PageStructure.DecodeNavName(form.URLName)>
		<cfset StructClear(theQueryDataArguments)>
		<cfset StructClear(theQueryWhereArguments)>
		<cfset theQueryDataArguments.NavName = form.NavName />
		<cfset theQueryDataArguments.URLNameEncoded = form.URLName />
		<cfset theQueryDataArguments.URLName = theURLNameDecoded />
		<cfset theQueryDataArguments.HasContent = bHasContent />
		<cfset theQueryDataArguments.IsHomePage = bIsHomePage />
		<cfset theQueryDataArguments.IsParent = bIsParent />
		<cfset theQueryDataArguments.DefaultDocID = form.DefaultPage />
		<cfset theQueryDataArguments.Param1 = theParam1 />
		<cfset theQueryDataArguments.Param2 = theParam2 />
		<cfset theQueryDataArguments.Param3 = theParam3 />
		<cfset theQueryDataArguments.Param4 = theParam4 />
		<cfset theQueryDataArguments.DocType = form.PageType />
		<cfset theQueryWhereArguments.DocID = session.SLCMS.CurrentPage />
		<cfset SetPage = application.SLCMS.Core.DataMgr.UpdateRecords(tablename="#request.SLCMS.PageStructTable#", data_set=theQueryDataArguments, data_where=theQueryWhereArguments) />
		<!--- 
		<cfquery name="SetPage" datasource="#application.SLCMS.config.Datasources.CMS#">
			update	#request.SLCMS.PageStructTable#
				set	NavName = '#form.NavName#',
						URLNameEncoded = '#form.URLName#',
						URLName = '#theURLNameDecoded#',
						HasContent = '#bHasContent#',
						IsHomePage = '#bIsHomePage#',
						IsParent = '#bIsParent#',
						DefaultDocID = #form.DefaultPage#,
						Param1 = '#theParam1#',
						Param2 = '#theParam2#',
						Param3 = '#form.Param3#',
						DocType = #form.PageType#
				where	DocID = #session.SLCMS.CurrentPage#
		</cfquery>
		 --->
		<!--- then if we have flagged this one as the home page flick all of the flags --->
		<cfif bIsHomePage eq 1>
			<cfset StructClear(theQueryDataArguments)>
			<cfset StructClear(theQueryWhereArguments)>
			<cfset theQueryDataArguments.IsHomePage = 0 />	<!--- set all to off --->
			<cfset SetHomePage1 = application.SLCMS.Core.DataMgr.UpdateRecords(tablename="#request.SLCMS.PageStructTable#", data_set=theQueryDataArguments, data_where=theQueryWhereArguments) />
			<!--- 
			<cfquery name="SetHomePage1" datasource="#application.SLCMS.config.Datasources.CMS#">
				update	#request.SLCMS.PageStructTable#
					set	IsHomePage = 0
			</cfquery>
			 --->
			<cfset theQueryDataArguments.IsHomePage = 1 />	<!--- then the new HP to On --->
			<cfset theQueryWhereArguments.DocID = session.SLCMS.CurrentPage />
			<cfset SetHomePage2 = application.SLCMS.Core.DataMgr.UpdateRecords(tablename="#request.SLCMS.PageStructTable#", data_set=theQueryDataArguments, data_where=theQueryWhereArguments) />
			<!--- 
			<cfquery name="SetHomePage2" datasource="#application.SLCMS.config.Datasources.CMS#">
				update	#request.SLCMS.PageStructTable#
					set	IsHomePage = 1
					where	DocID = #session.SLCMS.CurrentPage#
			</cfquery>
			 --->
		</cfif>
		<!--- all done so refresh the site structures --->
		<cfset UpdateNavArrays() />
		<!--- and tell the world we had a change with view back to the listing --->
		<cfset request.SLCMS.ItemChangedFlag.ID = session.SLCMS.CurrentPage />
		<cfset request.SLCMS.ItemChangedFlag.Name = "PP" />
		<cfset DispMode = "" />
	<cfelse>	<!--- not OK entry so reset form --->
		<cfset backLinkText = "Cancel Editing Page, " />	<!--- when we hop out --->
		<cfset dNavName = form.NavName>
		<cfset dURLName = form.URLName>
		<cfset dDocType = form.PageType>
		<cfset dIsHomePage = form.IsHomePage />
		<cfset dIsParent = form.IsParent>
		<cfset dHasContent = form.HasContent>
		<cfset dParam1 = form.Param1>
		<cfset dParam2 = form.Param2>
		<cfset dParam3 = form.Param3>
		<cfset DoUpdate = False>
		<cfset DispMode = "EditPage">
	</cfif>

<cfelseif WorkMode eq "ExpandArm">
	<!--- expand the specified arm of the navigation --->
	<cfset session.SLCMS.pageAdmin.NavState.ExpansionFlags[url.DocID] = True>
	<!--- and tell the world we had a change with view back to the listing --->
	<cfset request.SLCMS.ItemChangedFlag.ID = url.DocID />
	<cfset request.SLCMS.ItemChangedFlag.Name = "EX" />
	<cfset DispMode = "">

<cfelseif WorkMode eq "ExpandToTwo">
	<!--- loop over the nav array at its top level setting all expansion flags on and drop to level 2 turning them off --->
	<cfloop from="1" to="#ArrayLen(session.SLCMS.pageAdmin.NavState.theCurrentNavArray)#" index="lcntr1">
		<cfset session.SLCMS.pageAdmin.NavState.ExpansionFlags[session.SLCMS.pageAdmin.NavState.theCurrentNavArray[lcntr1].DocID] = True />
		<cfif session.SLCMS.pageAdmin.NavState.theCurrentNavArray[lcntr1].IsParent gt 0>
			<!--- we could have children under this one so drop down and shut them so we only see the one level down --->
			<cfset theLowerArrayLen = ArrayLen(session.SLCMS.pageAdmin.NavState.theCurrentNavArray[lcntr1].Children)>
			<cfif theLowerArrayLen gt 0>
				<cfloop from="1" to="#theLowerArrayLen#" index="lcntr2">
					<cfset session.SLCMS.pageAdmin.NavState.ExpansionFlags[session.SLCMS.pageAdmin.NavState.theCurrentNavArray[lcntr1].Children[lcntr2].DocID] = False />
				</cfloop>
			</cfif>
		</cfif>
	</cfloop>
	<cfset DispMode = "">

<cfelseif WorkMode eq "ExpandToThree">
	<!--- loop over the nav array at its top level and level 2 setting all expansion flags on and drop to level 3 turning them off --->
	<cfset theLowerArrayLen1 = ArrayLen(session.SLCMS.pageAdmin.NavState.theCurrentNavArray)>
	<cfif theLowerArrayLen1 gt 0>	<!--- only loop if we have some pages ot loop over --->
		<cfloop from="1" to="#theLowerArrayLen1#" index="lcntr1">
			<cfset session.SLCMS.pageAdmin.NavState.ExpansionFlags[session.SLCMS.pageAdmin.NavState.theCurrentNavArray[lcntr1].DocID] = True />
			<cfif session.SLCMS.pageAdmin.NavState.theCurrentNavArray[lcntr1].IsParent gt 0>
				<!--- we could have children under this one so drop down and shut them so we only see the one level down --->
				<cfset theLowerArrayLen2 = ArrayLen(session.SLCMS.pageAdmin.NavState.theCurrentNavArray[lcntr1].Children)>
				<cfif theLowerArrayLen2 gt 0>
					<cfloop from="1" to="#theLowerArrayLen2#" index="lcntr2">
						<cfset session.SLCMS.pageAdmin.NavState.ExpansionFlags[session.SLCMS.pageAdmin.NavState.theCurrentNavArray[lcntr1].Children[lcntr2].DocID] = True />
						<!--- and test again for any level 3 children --->
						<cfif session.SLCMS.pageAdmin.NavState.theCurrentNavArray[lcntr1].Children[lcntr2].IsParent gt 0>
							<!--- we could have children under this one so drop down and shut them so we only see the two level down --->
							<cfset theLowerArrayLen3 = ArrayLen(session.SLCMS.pageAdmin.NavState.theCurrentNavArray[lcntr1].Children[lcntr2].Children)>
							<cfif theLowerArrayLen3 gt 0>
								<cfloop from="1" to="#theLowerArrayLen3#" index="lcntr3">
									<cfset session.SLCMS.pageAdmin.NavState.ExpansionFlags[session.SLCMS.pageAdmin.NavState.theCurrentNavArray[lcntr1].Children[lcntr2].Children[lcntr3].DocID] = False />
								</cfloop>	<!--- end: loop level 3 --->
							</cfif>
						</cfif>	<!--- end: do we loop at level 3 --->
					</cfloop>	<!--- end: loop level 2 --->
				</cfif>
			</cfif>	<!--- end: do we loop at level 2 --->
		</cfloop>	<!--- end: loop top level, level 1 --->
	</cfif>
	<cfset DispMode = "">

<cfelseif WorkMode eq "CollapseArm">
	<!--- collapse the specified arm of the navigation --->
	<cfset session.SLCMS.pageAdmin.NavState.ExpansionFlags[url.DocID] = False>
	<!--- and tell the world we had a change with view back to the listing --->
	<cfset request.SLCMS.ItemChangedFlag.ID = url.DocID />
	<cfset request.SLCMS.ItemChangedFlag.Name = "EX" />
	<cfset DispMode = "">

<cfelseif WorkMode eq "CollapseToTop">
	<!--- collapse to the top levels only --->
	<!--- loop over the nav array at its top level and set all expansion flags off --->
	<cfloop from="1" to="#ArrayLen(session.SLCMS.pageAdmin.NavState.theCurrentNavArray)#" index="lcntr">
		<cfset session.SLCMS.pageAdmin.NavState.ExpansionFlags[session.SLCMS.pageAdmin.NavState.theCurrentNavArray[lcntr].DocID] = False />
	</cfloop>
	<cfset DispMode = "">

<cfelseif WorkMode eq "Del">	<!--- "delete" page --->
	<!--- we don't actually delete a page, 
				just make it as ultimately hidden and 
				wind up all of the version number of its content so there is no version zero --->
	<cfquery name="SetFolder" datasource="#application.SLCMS.config.Datasources.CMS#">
		update	#request.SLCMS.PageStructTable#
			set	Hidden = hidden+128
			WHERE	DocID = <cfqueryparam value="#url.DocID#" cfsqltype="cf_sql_integer">
	</cfquery>
	<cfquery name="SetVersionControl" datasource="#application.SLCMS.config.Datasources.CMS#">
		update	#request.SLCMS.DocContentControlTable#
			set		Version = Version+1
			where	DocID = <cfqueryparam value="#url.DocID#" cfsqltype="cf_sql_integer">
	</cfquery>
	<!--- then refresh the site structures --->
	<cfset UpdateNavArrays() />
	<!--- application.SLCMS.Core.PageStructure.Structure.RefreshSiteStructures() />
	<cfset session.SLCMS.pageAdmin.NavState.theCurapplication.SLCMS.Core.PageStructure..PageStructure.getFullNavArray() />
	 --->
	<cfset DispMode = "">
<!--- 
<cfelseif WorkMode eq "HideSite">	<!--- hide site from front end --->
	<cfquery name="SetFolder" datasource="#application.SLCMS.config.Datasources.CMS#">
		UPDATE	#request.SLCMS.PageStructTable#
			SET	Hidden = 1
			WHERE	DocID = #url.DocID#
	</cfquery>
	<!--- then refresh the site structures --->
	<cfset UpdateNavArrays() /application.SLCMS.Core.PageStructure.ation.PageStructure.RefreshSiteStructures() />
	<cfset session.SLCMS.pageAdmin.NavStapplication.SLCMS.Core.PageStructure.pplication.PageStructure.getFullNavArray() />
	 --->
	<cfset DispMode = "">
 --->
<cfelseif WorkMode eq "HideInMenu">	<!--- hide page in menus --->
	<!--- bit 1 is 0=show/1=hide in menu --->
	<cfset StructClear(theQueryDataArguments)>
	<cfset StructClear(theQueryWhereArguments)>
	<cfset theQueryDataArguments.Hidden = BitOr(url.HidVal,1) />	<!--- set nav bit to hidden --->
	<cfset theQueryWhereArguments.DocID = url.DocID />
	<cfset setNavOff = application.SLCMS.Core.DataMgr.UpdateRecords(tablename="#request.SLCMS.PageStructTable#", data_set=theQueryDataArguments, data_where=theQueryWhereArguments) />
	<!--- 
	<cfquery name="SetFolder" datasource="#application.SLCMS.config.Datasources.CMS#">
		UPDATE	#request.SLCMS.PageStructTable#
			SET	Hidden = #BitOr(url.HidVal,1)#
			WHERE	DocID = #url.DocID#
	</cfquery>
	 --->
	<!--- all done so refresh the site structures --->
	<cfset UpdateNavArrays() />
	<!--- and tell the world we had a change with view back to the listing --->
	<cfset request.SLCMS.ItemChangedFlag.ID = url.DocID />
	<cfset request.SLCMS.ItemChangedFlag.Name = "MV" />
	<cfset DispMode = "" />

<cfelseif WorkMode eq "UnHideInMenu">	<!--- show page in menus --->
	<!--- bit 1 is 0=show/1=hide in menu --->
	<!--- but if it is in menu it must be viewable as a page so force other bit --->
	<cfset StructClear(theQueryDataArguments)>
	<cfset StructClear(theQueryWhereArguments)>
	<cfset theQueryDataArguments.Hidden = 0 />	<!--- set nav bit to viewable --->
	<cfset theQueryWhereArguments.DocID = url.DocID />
	<cfset setNavOn = application.SLCMS.Core.DataMgr.UpdateRecords(tablename="#request.SLCMS.PageStructTable#", data_set=theQueryDataArguments, data_where=theQueryWhereArguments) />
	<!--- 
	<cfquery name="SetFolder" datasource="#application.SLCMS.config.Datasources.CMS#">
		UPDATE	#request.SLCMS.PageStructTable#
			SET	Hidden = 0
			WHERE	DocID = #url.DocID#
	</cfquery>
	 --->
	<!--- all done so refresh the site structures --->
	<cfset UpdateNavArrays() />
	<!--- and tell the world we had a change with view back to the listing --->
	<cfset request.SLCMS.ItemChangedFlag.ID = url.DocID />
	<cfset request.SLCMS.ItemChangedFlag.Name = "MV" />
	<cfset DispMode = "" />

<cfelseif WorkMode eq "Hide">	<!--- stop page from being seen by any path --->
	<!--- bit 2 is 0=can be seen/1=cannot be seen at all, even direct url --->
	<cfset StructClear(theQueryDataArguments)>
	<cfset StructClear(theQueryWhereArguments)>
	<cfset theQueryDataArguments.Hidden = 3 />	<!--- set all view bits to hidden --->
	<cfset theQueryWhereArguments.DocID = url.DocID />
	<cfset setAllOff = application.SLCMS.Core.DataMgr.UpdateRecords(tablename="#request.SLCMS.PageStructTable#", data_set=theQueryDataArguments, data_where=theQueryWhereArguments) />
	<!--- 
	<cfquery name="SetFolder" datasource="#application.SLCMS.config.Datasources.CMS#">
		UPDATE	#request.SLCMS.PageStructTable#
			SET	Hidden = 3
			WHERE	DocID = #url.DocID#
	</cfquery>
	 --->
	<cfset DispMode = "">
	<!--- all done so refresh the site structures --->
	<cfset UpdateNavArrays() />
	<!--- and tell the world we had a change with view back to the listing --->
	<cfset request.SLCMS.ItemChangedFlag.ID = url.DocID />
	<cfset request.SLCMS.ItemChangedFlag.Name = "DV" />
	<cfset DispMode = "" />

<cfelseif WorkMode eq "UnHide">	<!--- allow page to be seen by any path --->
	<!--- bit 2 is 0=can be seen/1=cannot be seen at all, even direct url --->
	<cfset StructClear(theQueryDataArguments)>
	<cfset StructClear(theQueryWhereArguments)>
	<cfset theQueryDataArguments.Hidden = BitAnd(url.HidVal,253) />	<!--- set view bit to unhidden --->
	<cfset theQueryWhereArguments.DocID = url.DocID />
	<cfset setViewableOn = application.SLCMS.Core.DataMgr.UpdateRecords(tablename="#request.SLCMS.PageStructTable#", data_set=theQueryDataArguments, data_where=theQueryWhereArguments) />
	<!--- 
	<cfquery name="SetFolder" datasource="#application.SLCMS.config.Datasources.CMS#">
		UPDATE	#request.SLCMS.PageStructTable#
			SET	Hidden = #BitAnd(url.HidVal,253)#
			WHERE	DocID = #url.DocID#
	</cfquery>
	 --->
	<!--- all done so refresh the site structures --->
	<cfset UpdateNavArrays() />
	<!--- and tell the world we had a change with view back to the listing --->
	<cfset request.SLCMS.ItemChangedFlag.ID = url.DocID />
	<cfset request.SLCMS.ItemChangedFlag.Name = "DV" />
	<cfset DispMode = "" />

<cfelseif WorkMode eq "Select">	<!--- choose a new level --->
	<cfset CurrentFolder = url.NewFolder>
	<cfset DispMode = "">

<cfelseif WorkMode eq "UpLevel">	<!--- move up a level in structure --->
	<cfset StructClear(theQueryWhereArguments)>
	<cfset theQueryWhereArguments.DocID = url.DocID />
	<cfset getParent = application.SLCMS.Core.DataMgr.getRecords(tablename="#request.SLCMS.PageStructTable#", data=theQueryWhereArguments, fieldset="ParentID") />
	<!--- 
	<cfquery name="getParent" datasource="#application.SLCMS.config.Datasources.CMS#" dbtype="ODBC">
		select ParentID from #request.SLCMS.PageStructTable#
			WHERE	DocID = #url.DocID#
	</cfquery>
	 --->
	<cfif getParent.RecordCount>
		<cfset CurrentFolder = getParent.ParentID>
	<cfelse>
		<cfset CurrentFolder = 0>
	</cfif>
	<!--- all done so refresh the site structures --->
	<cfset UpdateNavArrays() />
	<!--- and tell the world we had a change with view back to the listing --->
	<cfset request.SLCMS.ItemChangedFlag.ID = url.DocID />
	<cfset request.SLCMS.ItemChangedFlag.Name = "Up" />
	<cfset DispMode = "" />

<cfelseif WorkMode eq "Up">	<!--- move up in display order --->
	<!--- first get our own data amd the one we are swapping places with --->
	<cfset myDO = application.SLCMS.Core.PageStructure.getSingleDocStructure(SubSiteID="#session.SLCMS.Currents.Admin.PageStructure.CurrentSubSiteID#", DocID="#url.DocID#").DO>
	<cfset AboveDocID = session.SLCMS.pageAdmin.NavState.displayedRowArray[url.Pos][1] />
	<cfset AboveData = application.SLCMS.Core.PageStructure.getSingleDocStructure(SubSiteID="#session.SLCMS.Currents.Admin.PageStructure.CurrentSubSiteID#", DocID="#aboveDocID#")>
	<!--- we now have to do various things according to context --->
	<!--- if the one above has the same parent as us --->
	<cfif AboveData.ParentID eq url.parentID>
		<!--- see if the one above is an expanded parent with no children --->
		<cfif AboveData.IsParent and session.SLCMS.pageAdmin.NavState.ExpansionFlags[AboveDocID] eq True and AboveData.Children eq 0>
			<!--- drop into the one above as a parent rather than walk past it --->
			<cfquery name="setAbove" datasource="#application.SLCMS.config.Datasources.CMS#" dbtype="ODBC">
				update #request.SLCMS.PageStructTable#
					set Children = Children+1
				where DocID = #AboveDocID#
			</cfquery>
			<cfset StructClear(theQueryDataArguments)>
			<cfset StructClear(theQueryWhereArguments)>
			<cfset theQueryDataArguments.DO = 1 />
			<cfset theQueryDataArguments.ParentID = AboveData.DocID />
			<cfset theQueryWhereArguments.DocID = url.DocID />
			<cfset setThis = application.SLCMS.Core.DataMgr.UpdateRecords(tablename="#request.SLCMS.PageStructTable#", data_set=theQueryDataArguments, data_where=theQueryWhereArguments) />
			<!--- 
			<cfquery name="setThis" datasource="#application.SLCMS.config.Datasources.CMS#" dbtype="ODBC">
				update #request.SLCMS.PageStructTable#
					set DO = 1,
							ParentID = #AboveData.DocID#
				where DocID = #url.DocID#
			</cfquery>
			 --->
		<cfelse>
			<!--- its not so simply swap places with one above --->
			<cfset StructClear(theQueryDataArguments)>
			<cfset StructClear(theQueryWhereArguments)>
			<cfset theQueryDataArguments.DO = AboveData.DO+1 />
			<cfset theQueryWhereArguments.DocID = AboveDocID />
			<cfset setAbove = application.SLCMS.Core.DataMgr.UpdateRecords(tablename="#request.SLCMS.PageStructTable#", data_set=theQueryDataArguments, data_where=theQueryWhereArguments) />
			<!--- 
			<cfquery name="setAbove" datasource="#application.SLCMS.config.Datasources.CMS#" dbtype="ODBC">
				update #request.SLCMS.PageStructTable#
					set DO = #AboveData.DO#+1
				where DocID = #AboveDocID#
			</cfquery>
			 --->
			<cfset StructClear(theQueryDataArguments)>
			<cfset StructClear(theQueryWhereArguments)>
			<cfset theQueryDataArguments.DO = AboveData.DO />
			<cfset theQueryWhereArguments.DocID = url.DocID />
			<cfset setThis = application.SLCMS.Core.DataMgr.UpdateRecords(tablename="#request.SLCMS.PageStructTable#", data_set=theQueryDataArguments, data_where=theQueryWhereArguments) />
			<!--- 
			<cfquery name="setThis" datasource="#application.SLCMS.config.Datasources.CMS#" dbtype="ODBC">
				update #request.SLCMS.PageStructTable#
					set DO = #AboveData.DO#
				where DocID = #url.DocID#
			</cfquery>
			 --->
		</cfif>
	<cfelse>
		<!--- not same parent so swap places with one above and allow for change of parentage --->
		<cfquery name="setAbove" datasource="#application.SLCMS.config.Datasources.CMS#" dbtype="ODBC">
			update #request.SLCMS.PageStructTable#
				set DO = #AboveData.DO#+1,
						Children = Children+1
			where DocID = #AboveDocID#
		</cfquery>
		<cfset StructClear(theQueryDataArguments)>
		<cfset StructClear(theQueryWhereArguments)>
		<cfset theQueryDataArguments.DO = AboveData.DO />
		<cfset theQueryDataArguments.ParentID = AboveData.ParentID />
		<cfset theQueryWhereArguments.DocID = url.DocID />
		<cfset setThis = application.SLCMS.Core.DataMgr.UpdateRecords(tablename="#request.SLCMS.PageStructTable#", data_set=theQueryDataArguments, data_where=theQueryWhereArguments) />
		<!--- 
		<cfquery name="setThis" datasource="#application.SLCMS.config.Datasources.CMS#" dbtype="ODBC">
			update #request.SLCMS.PageStructTable#
				set DO = #AboveData.DO#,
						ParentID = #AboveData.ParentID#
			where DocID = #url.DocID#
		</cfquery>
		 --->
	</cfif>
	<!--- all done so refresh the site structures --->
	<cfset UpdateNavArrays() />
	<!--- and tell the world we had a change with view back to the listing --->
	<cfset request.SLCMS.ItemChangedFlag.ID = url.DocID />
	<cfset request.SLCMS.ItemChangedFlag.Name = "Up" />
	<cfset DispMode = "" />

<cfelseif WorkMode eq "Down">	<!--- move down in display order --->
	<!--- first get our own data amd the one we are swapping places with --->
	<cfset myDO = application.SLCMS.Core.PageStructure.getSingleDocStructure(SubSiteID="#session.SLCMS.Currents.Admin.PageStructure.CurrentSubSiteID#", DocID="#url.DocID#").DO>
	<cfset BelowDocID = session.SLCMS.pageAdmin.NavState.displayedRowArray[url.Pos][3] />
	<cfif BelowDocID neq 0>	<!--- if its a zero we have reached the bottom --->
		<cfset BelowDO = application.SLCMS.Core.PageStructure.getSingleDocStructure(SubSiteID="#session.SLCMS.Currents.Admin.PageStructure.CurrentSubSiteID#", DocID="#BelowDocID#").DO>
		<cfset BelowParentID = application.SLCMS.Core.PageStructure.getSingleDocStructure(SubSiteID="#session.SLCMS.Currents.Admin.PageStructure.CurrentSubSiteID#", DocID="#BelowDocID#").ParentID />
		<!--- as we can't detect the bottom row at the moment put a limiter here --->
		<!--- 
		<cfset StructClear(theQueryDataArguments)>
		<cfset StructClear(theQueryWhereArguments)>
		<cfset theQueryDataArguments.select = "select Max(DO) as TopDO" />
		<cfset theQueryWhereArguments.ParentID = BelowParentID />
		<cfset getBottom = application.SLCMS.Core.DataMgr.getRecords(tablename="#request.SLCMS.PageStructTable#", data=theQueryWhereArguments, advsql=theQueryDataArguments) />
		 --->
		<cfquery name="getBottom" datasource="#application.SLCMS.config.Datasources.CMS#" dbtype="ODBC">
			select Max(DO) as Bottom 
				from #request.SLCMS.PageStructTable#
			where ParentID = #BelowParentID#
		</cfquery>
		<cfif BelowDo neq 0 and BelowDo lte getBottom.Bottom >
			<!--- all those below my new pos move down one --->
			<cfquery name="setBelows" datasource="#application.SLCMS.config.Datasources.CMS#" dbtype="ODBC">
				update #request.SLCMS.PageStructTable#
					set DO = DO+1
				where ParentID = #BelowParentID#
					and	DO > #BelowDO#
			</cfquery>
			<!--- and I drop in below the one immediately below --->
			<cfset StructClear(theQueryDataArguments)>
			<cfset StructClear(theQueryWhereArguments)>
			<cfset theQueryDataArguments.DO = BelowDO+1 />
			<cfset theQueryDataArguments.ParentID = BelowParentID />
			<cfset theQueryWhereArguments.DocID = url.DocID />
			<cfset setThis = application.SLCMS.Core.DataMgr.UpdateRecords(tablename="#request.SLCMS.PageStructTable#", data_set=theQueryDataArguments, data_where=theQueryWhereArguments) />
			<!--- 
			<cfquery name="setThis" datasource="#application.SLCMS.config.Datasources.CMS#" dbtype="ODBC">
				update #request.SLCMS.PageStructTable#
					set DO = #BelowDO#+1,
							ParentID = #BelowParentID#
				where DocID = #url.DocID#
			</cfquery>
			 --->
		</cfif>
	</cfif>
	<!--- all done so refresh the site structures --->
	<cfset UpdateNavArrays() />
	<!--- and tell the world we had a change with view back to the listing --->
	<cfset request.SLCMS.ItemChangedFlag.ID = url.DocID />
	<cfset request.SLCMS.ItemChangedFlag.Name = "Down" />
	<cfset DispMode = "" />

<cfelseif WorkMode eq "">
	<!--- first time in so set for top level --->
	<cfset session.SLCMS.Currents.Admin.PageStructure.CurrentFolder = 0>
	<cfset session.SLCMS.Currents.Admin.PageStructure.CurrentParentID = 0>
	<cfset DispMode = "">
	<cfset dFoldername = "">
	<cfset flname = "index.cfm">
	<cfset dAbbrvName = "">
	<cfset DoUpdate = False>

	<!--- set up our vars to display the structure from --->
	<cfset theArrayPointer = 1 />
</cfif>
<!--- 
<cfset session.SLCMS.Currents.Admin.PageStructure.CurrentFolder = CurrentFolder>
<cfset session.SLCMS.Currents.Admin.PageStructure.CurrentParentID = CurrentParentID>
 --->
<cfif DoUpdate>
</cfif>

<!--- above was all the work specific to an add or edit or whatever, now get common stuff --->
<cfif WorkMode eq "AddPage" or WorkMode eq "EditPage" or DispMode eq "AddPage" or DispMode eq "EditPage">
	<cfif WorkMode eq "EditPage" or DispMode eq "EditPage">
		<cfset SubSiteParentage.thisSubSiteHomePageDocID = application.SLCMS.Core.PageStructure.getHomePageDocID(SubSiteID=session.SLCMS.Currents.Admin.PageStructure.CurrentSubSiteID) />
		<cfset SubSiteParentage.SubSiteParentData = application.SLCMS.Core.portalcontrol.GetSubSiteParentDocIDData() />
		<cfset SubSiteParentage.SubSiteParentDocIDList = SubSiteParentage.SubSiteParentData.ParentDocIDList />
<!--- 	
	<cfdump var="#SubSiteParentage#" expand="false">
	<cfabort>
 --->	
		<cfif ListFind(SubSiteParentage.SubSiteParentDocIDList, url.CurrentDocID)>
			<!--- Ooo! we are the parent for a subsite so lets find out which one and flag it --->
			<cfset SubSiteParentage.IsParentToSubSite = True />
			<cfset SubSiteParentage.IsParentToSubSiteID = SubSiteParentage.SubSiteParentData["DocID_#url.CurrentDocID#"].subSiteID />
		<cfelse>
			<cfset SubSiteParentage.IsParentToSubSite = False />
			<cfset SubSiteParentage.IsParentToSubSiteID = "" />
		</cfif>
	<cfelseif WorkMode eq "AddPage">
		<cfset SubSiteParentage.IsParentToSubSite = False />
		<cfset SubSiteParentage.IsParentToSubSiteID = "" />
	</cfif>
	<!--- gather all of the bits we need for an add/edit page --->
	<cfset SubSiteParentage.SubSiteList = application.SLCMS.Core.portalcontrol.GetAllowedSubSiteIDList_AllSites() />
	<cfset SubSiteParentage.SubSiteData = application.SLCMS.Core.portalcontrol.GetAllSubSites() />
	<!--- DocTypes are direct, content only --->
	<cfset StructClear(theQueryWhereArguments)>
	<cfset theQueryWhereArguments.Hidden = 0 />
	<cfset getDocTypes = application.SLCMS.Core.DataMgr.getRecords(tablename="SLCMS_Type_Document", data=theQueryWhereArguments, orderby="DO") />
	<!--- display types are more complex, we have templates from the core and from most modules --->
	<cfset theBaseDisplayTypeArray = ArrayNew(2) />	<!--- 1 is module name, 2 is Type name, 3 is type description/friendly name, 4 is Module friendly name --->
	<cfset theBaseDisplayTypeArrayCntr = 1 />
	<!--- first we will grab all of the types from the core --->
	<cfset StructClear(theQueryWhereArguments)>
	<cfset theQueryWhereArguments.Hidden = 0 />
	<cfset getTemplateTypes = application.SLCMS.Core.DataMgr.getRecords(tablename="SLCMS_Type_Template", data=theQueryWhereArguments, orderby="DO") />
	<cfloop query="getTemplateTypes">
		<cfset theBaseDisplayTypeArray[theBaseDisplayTypeArrayCntr][1] = "core" />
		<cfset theBaseDisplayTypeArray[theBaseDisplayTypeArrayCntr][2] = getTemplateTypes.TemplateType />
		<cfset theBaseDisplayTypeArray[theBaseDisplayTypeArrayCntr][3] = getTemplateTypes.TemplateDesc />
		<cfset theBaseDisplayTypeArray[theBaseDisplayTypeArrayCntr][4] = "" />
		<cfset theBaseDisplayTypeArray[theBaseDisplayTypeArrayCntr][5] = False />
		<cfset theBaseDisplayTypeArrayCntr = theBaseDisplayTypeArrayCntr+1 />
	</cfloop>
	<!--- then add in the modules --->
	<cfset theModules =application.SLCMS.System.ModuleManager.getQuickAvailableModulesList() />
	<cfloop list="#theModules#" index="thisModule">
		<cfif application.SLCMS.modules['#thisModule#'].DisplayTypes.HasFrontEnd and application.SLCMS.modules['#thisModule#'].DisplayTypes.TypeList neq "">
			<!--- we have a front end to select from and the module could have than one display type so loop --->
			<cfif ListLen(application.SLCMS.modules['#thisModule#'].DisplayTypes.TypeList) gt 1>
				<cfset MultiType = True />
			<cfelse>
				<cfset MultiType = False />
			</cfif>
			<cfloop list="#application.SLCMS.modules['#thisModule#'].DisplayTypes.TypeList#" index="thisSubType">
				<cfset theBaseDisplayTypeArray[theBaseDisplayTypeArrayCntr][1] = thisModule />
				<cfset theBaseDisplayTypeArray[theBaseDisplayTypeArrayCntr][2] = thisSubType />	<!--- add in the type --->
				<cfset theBaseDisplayTypeArray[theBaseDisplayTypeArrayCntr][3] = application.SLCMS.modules["#thisModule#"].Description />
				<cfset theBaseDisplayTypeArray[theBaseDisplayTypeArrayCntr][4] = application.SLCMS.modules["#thisModule#"].FriendlyName />
				<cfset theBaseDisplayTypeArray[theBaseDisplayTypeArrayCntr][5] = MultiType />
				<cfset theBaseDisplayTypeArrayCntr = theBaseDisplayTypeArrayCntr+1 />
			</cfloop>
			<cfset theBaseDisplayTypeArrayCntr = theBaseDisplayTypeArrayCntr+1 />
		</cfif>
	</cfloop>


	<!--- get a list of available templates, Page and Form, from both the shared space and this subSite --->
	<cfset PageTemplateArray = ArrayNew(2)>
	<cfset lcntr = 1>
	<cfset theTemplates = application.SLCMS.Core.Templates.getTemplateTypeDataStruct(TemplateType="Page", SubSiteID="#session.SLCMS.Currents.Admin.PageStructure.CurrentSubSiteID#") />
	<cfset thePageTemplateCount = theTemplates.TemplateSetCount />
	<cfloop list="#theTemplates.TemplateSetList#" index="thisFolder">
		<cfloop collection="#theTemplates.TemplateSets[thisFolder].Templates.Active.Items#" item="thisTemplate">
			<cfset PageTemplateArray[lcntr][1] = thisFolder & "/" & theTemplates.TemplateSets[thisFolder].Templates.Active.Items["#thisTemplate#"].FileName>
			<cfset PageTemplateArray[lcntr][2] = thisFolder & "/" & theTemplates.TemplateSets[thisFolder].Templates.Active.Items["#thisTemplate#"].ItemName>
			<cfset lcntr = lcntr+1>
		</cfloop>
	</cfloop>
	<cfset theTemplates = application.SLCMS.Core.Templates.getTemplateTypeDataStruct(TemplateType="Page", SubSiteID="Shared") />
	<cfset thePageTemplateCount = theTemplates.TemplateSetCount />
	<cfloop list="#theTemplates.TemplateSetList#" index="thisFolder">
		<cfloop collection="#theTemplates.TemplateSets[thisFolder].Templates.Active.Items#" item="thisTemplate">
			<cfset PageTemplateArray[lcntr][1] = "Shared/" & thisFolder & "/" & theTemplates.TemplateSets[thisFolder].Templates.Active.Items["#thisTemplate#"].FileName>
			<cfset PageTemplateArray[lcntr][2] = "Shared/" & thisFolder & "/" & theTemplates.TemplateSets[thisFolder].Templates.Active.Items["#thisTemplate#"].ItemName>
			<cfset lcntr = lcntr+1>
		</cfloop>
	</cfloop>
	<cfset FormTemplateArray = ArrayNew(2)>
	<cfset lcntr = 1>
  <!---
	<cfset theForms = application.SLCMS.Core.Templates.getTemplateTypeDataStruct(TemplateType="Form", SubSiteID="#session.SLCMS.Currents.Admin.PageStructure.CurrentSubSiteID#") />
	<cfset theFormTemplateCount = theForms.TemplateSetCount />
	<cfloop list="#theForms.TemplateSetList#" index="thisFolder">
		<cfloop collection="#theForms.TemplateSets[thisFolder].Templates.Active.Items#" item="thisTemplate">
			<cfset FormTemplateArray[lcntr][1] = thisFolder & "/" & theForms.TemplateSets[thisFolder].Templates.Active.Items["#thisTemplate#"].FileName>
			<cfset FormTemplateArray[lcntr][2] = thisFolder & "/" & theForms.TemplateSets[thisFolder].Templates.Active.Items["#thisTemplate#"].ItemName>
			<cfset lcntr = lcntr+1>
		</cfloop>
	</cfloop>
	--->
	<!---
	<cfset theForms = application.SLCMS.Core.Templates.getTemplateTypeDataStruct(TemplateType="Form", SubSiteID="Shared") />
	<cfset theFormTemplateCount = theForms.TemplateSetCount />
	<cfloop list="#theForms.TemplateSetList#" index="thisFolder">
		<cfloop collection="#theForms.TemplateSets[thisFolder].Templates.Active.Items#" item="thisTemplate">
			<cfset FormTemplateArray[lcntr][1] = "Shared/" & thisFolder & "/" & theForms.TemplateSets[thisFolder].Templates.Active.Items["#thisTemplate#"].FileName>
			<cfset FormTemplateArray[lcntr][2] = "Shared/" & thisFolder & "/" & theForms.TemplateSets[thisFolder].Templates.Active.Items["#thisTemplate#"].ItemName>
			<cfset lcntr = lcntr+1>
		</cfloop>
	</cfloop>
	--->
	<!--- 
	<cfdirectory directory="#request.SLCMS.TemplatesBasePath#" name="getTemplateFolders" action="list">
	<cfset TemplateArray = ArrayNew(2)>
	<cfset lcntr = 1>
	<cfloop query="getTemplateFolders">
		<cfif getTemplateFolders.Type eq "Dir" and getTemplateFolders.name neq ".svn">
			<cfset thisFolder = getTemplateFolders.Name&"/">
			<cfdirectory directory="#request.SLCMS.TemplatesBasePath##thisFolder#" name="getTemplateFiles" action="list" filter="*.cfm">
			<cfloop query="getTemplateFiles">
				<cfif getTemplateFiles.Type neq "Dir">
				<cfset TemplateArray[lcntr][1] = thisFolder&getTemplateFiles.name>
				<cfset TemplateArray[lcntr][2] = ListFirst(thisFolder&getTemplateFiles.name,".")>
				<cfset lcntr = lcntr+1>
				</cfif>
			</cfloop>
		</cfif>
	</cfloop>
	 --->
	<cfif not application.SLCMS.Core.SLCMS_Utility.DoPagesHaveTemplatesOnly()>
		<!--- and the available old-style include files --->
		<cfset includeDir = request.SLCMS.BasePath&"global/includes/">
		<cfdirectory directory="#includeDir#" name="getIncludeFolders" action="list">
		<cfset IncludeArray = ArrayNew(1)>
		<cfset lcntr = 1>
		<cfloop query="getIncludeFolders">
			<cfif getIncludeFolders.Type eq "Dir" and getIncludeFolders.name neq ".svn">
				<cfset thisFolder = getIncludeFolders.Name&"/">
				<cfdirectory directory="#includeDir##thisFolder#" name="getIncludeFiles" action="list">
				<cfloop query="getIncludeFiles">
					<cfif getIncludeFiles.Type neq "Dir">
					<cfset IncludeArray[lcntr] = thisFolder&getIncludeFiles.name>
					<cfset lcntr = lcntr+1>
					</cfif>
				</cfloop>
			</cfif>
		</cfloop>
	</cfif>
</cfif>


