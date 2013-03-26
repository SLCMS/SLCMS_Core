
<!--- a few UDFs that we are going to use in several spots --->
<cffunction name="getSystemTablesfromINI" access="public" output="false">
	<!--- grab a list of the database system tables as defined in the version ini file --->
	<cfset var theTables = "" >
	<cfset var theiniPath_DBTables = application.SLCMS.config.startup.DataFolderPath & "Versions/Current_Version/DatabaseTables_Current.ini" />
	<cfset var ret = application.SLCMS.mbc_Utility.iniTools.iniSection2List(FilePath="#theiniPath_DBTables#", SectionName="System") />
	<cfif ret.error.errorcode eq 0>
		<cfset theTables = ListSort(ret.data,"TextNoCase", "asc") />
	</cfif>
	<cfreturn theTables>
</cffunction>
<cffunction name="getSubSiteTablesfromINI" access="public" output="false">
	<!--- grab a list of the database subSite tables as defined in the version ini file --->
	<cfset var theTables = "" >
	<cfset var theiniPath_DBTables = application.SLCMS.config.startup.DataFolderPath & "Versions/Current_Version/DatabaseTables_Current.ini" />
	<cfset var ret = application.SLCMS.mbc_Utility.iniTools.iniSection2List(FilePath="#theiniPath_DBTables#", SectionName="subSite") />
	<cfif ret.error.errorcode eq 0>
		<cfset theTables = ListSort(ret.data,"TextNoCase", "asc") />
	</cfif>
	<cfreturn theTables>
</cffunction>
<cffunction name="createBaseSiteFolderStructure" access="private" output="false">
	<!---  we are going to create the base folders for SLCMS V 2.2+, just the main folders and empty holders for stuff coming and going --->
	<!--- there is an awful lot of it so to save clutter we have it in an include file --->
	<cfset var theFolderStructIncPath = "DeveloperTemp/__BaseFolderStructure_inc.cfm" />
	<cfset var theSiteFolderStructure = StructNew() >
	<cfinclude template="#theFolderStructIncPath#" >
	<cfreturn theSiteFolderStructure>
</cffunction>

<cfsetting enablecfoutputonly="Yes">

<cfset theiniPath_DBTables = application.SLCMS.config.startup.DataFolderPath & "Versions/Current_Version/DatabaseTables_Current.ini" />
<cfset theXMLDumpFilePath = "#application.SLCMS.config.startup.SiteBasePath#admin/DeveloperTemp/DAL_XML_DBDumps/" />
<cfset theTestDSN = "SLCMS_Dev_InitialInstallTest" />

<cfif IsDefined("params.mode")>
	<cfset WorkMode0 = params.mode />	<!--- code to run before the main set to work out the subsite we are in --->
	<cfset WorkMode1 = params.mode />
	<cfset DispMode = params.mode />
<cfelseif IsDefined("form.task")>
	<cfset WorkMode0 = form.task />	<!--- code to run before the main set to work out the subsite we are in --->
	<cfset WorkMode1 = form.task />
	<cfset DispMode = form.task />
<cfelse>
	<cfset WorkMode0 = "" />
	<cfset WorkMode1 = "" />
	<cfset DispMode = "" />
</cfif>

<!--- first some portal related code --->
<cfset request.SLCMS.PortalAllowed = application.SLCMS.Core.PortalControl.IsPortalAllowed() />
<cfif request.SLCMS.PortalAllowed>
	<cfset theAllowedSubsiteList = application.SLCMS.core.PortalControl.GetAllowedSubSiteIDList_AllSites(UserID="#session.SLCMS.user.UserID#") />
	<cfif WorkMode0 eq "ChangeSubSite" and IsDefined("params.NewSubSiteID") and IsNumeric(params.NewSubSiteID)>
		<!--- set a new current state --->
		<cfset session.SLCMS.Currents.Admin.PageStructure.CurrentSubSiteID = params.NewSubSiteID />
		<cfset session.SLCMS.Currents.Admin.PageStructure.CurrentSubSiteFriendlyName = application.SLCMS.core.PortalControl.GetSubSite(params.NewSubSiteID).data.SubSiteFriendlyName />
		<!--- work out the database tables --->		
		<cfset request.SLCMS.PageStructTable = application.SLCMS.config.DatabaseDetails.databaseTableNaming_Root_Site
																		&	session.SLCMS.Currents.Admin.PageStructure.CurrentSubSiteID
																		&	application.SLCMS.config.DatabaseDetails.databaseTableNaming_Tail_PageStructure />
		<!--- this code below is cloned in App.cfc in OnRequestStart to make sure we have something first time in (using site_0) --->
		<cfset session.pageAdmin.NavState = StructNew()/>	<!--- dump all old data --->
		<!--- set up our vars to display the structure from --->
		<cfset session.pageAdmin.NavState.theOriginalNavArray = Duplicate(application.SLCMS.Core.PageStructure.getFullNavArray(SubSiteID=session.SLCMS.Currents.Admin.PageStructure.CurrentSubSiteID)) />
		<cfset session.pageAdmin.NavState.theCurrentNavArray = Duplicate(application.SLCMS.Core.PageStructure.getFullNavArray(SubSiteID=session.SLCMS.Currents.Admin.PageStructure.CurrentSubSiteID)) />
		<cfset session.pageAdmin.NavState.dispRowCounter = 0 />
		<cfset session.SLCMS.Currents.Admin.PageStructure.FlushExpansionFlags = True />
		<cfset WorkMode = "" />
		<cfset DispMode = "" />
		
	<cfelseif WorkMode0 eq "xxx" >	<!--- next workmode0 --->
	
	<cfelse>	<!--- no workmode0 so set up defaults/currents --->
		<cfset request.SLCMS.PageStructTable = application.SLCMS.config.DatabaseDetails.databaseTableNaming_Root_Site
																		&	session.SLCMS.Currents.Admin.PageStructure.CurrentSubSiteID
																		&	application.SLCMS.config.DatabaseDetails.databaseTableNaming_Tail_PageStructure />
	</cfif>
<cfelse>
	<!--- no portal ability so force to site zero --->
	<cfset theAllowedSubsiteList = "0" />
	<cfset request.SLCMS.PageStructTable = application.SLCMS.config.DatabaseDetails.TableName_Site_0_PageStruct />
</cfif>

<cfif WorkMode1 eq "ViewDatabaseStructs">
	<cfset DispMode = "ViewDatabaseStructs" />
	
<cfelseif WorkMode1 eq "WorkonDatabaseTable">
	<cfset DispMode = "ChooseDatabaseTable" />
	<cfset theDBTableStruct_theDalData = application.SLCMS.Core.DataMgr.getTableData()>

<cfelseif WorkMode1 eq "TtTDTCwLoadXML">
	<cfset opNext = "ActionDatabaseXML" />
	<cfset DispMode = "ChooseDatabaseXML" />
	<cfdirectory action="list" directory="#theXMLDumpFilePath#" filter="*.xml" name="theXMLFiles"  /> 

<cfelseif WorkMode1 eq "ActionDatabaseXML">
	<cfif application.SLCMS.config.base.sitemode eq "development"and StructKeyExists(form, "LoadXML") and form.LoadXML eq "Load this XML">
	
		<cfset theFullFilePath = theXMLDumpFilePath & form.FileToLoad />
		<cfif FileExists(theFullFilePath)>
			<cffile action="read" file="#theFullFilePath#" variable="theXML" >
			<cfset theDataMgrPath = application.SLCMS.Config.base.SLCMS3rdPartyFrameworksandLibsRelPath & "DataMgr/" />
			<cfset variables.DataMgr = createObject("component","#application.SLCMS.Config.base.MapURL##theDataMgrPath#DataMgr").init(datasource="#theTestDSN#") /><!--- this CFC family manages database access, its the Database Abstraction Layer --->
			<cfset ret = variables.DataMgr.loadXML(xmldata=theXML, docreate=True, addcolumns=True)>
		<!---
			<cfdump var="#ret#" expand="false" label="ret from loadXML" />
		--->	
		</cfif>
		<cfset DispMode = "" />
	</cfif>

<cfelseif WorkMode1 eq "DALtask">
	<cfif StructKeyExists(form, "DALbuttonPushed") and form.DALbuttonPushed eq "YesSir">
		<cfset DispMode = "ViewDatabaseStructs">
		<!--- we want to do something with the DAL so lets see what --->
		<cfif StructKeyExists(form, "RefreshSystem") and form.RefreshSystem eq "Refresh according to control file">
			<!--- we want to load up the DAL with everything that is system related from the ini file --->
			<cfset theDBTableLists_theiniSystemList = getSystemTablesfromINI() />
			<!--- now we have a struct of the system table names so lets load each one into the DAL --->
			<cfloop list="#theDBTableLists_theiniSystemList#" index="thisTable">
				<cfset ret = application.SLCMS.Core.DataMgr.loadTable(thisTable)>
			</cfloop>

		<cfelseif StructKeyExists(form, "RefreshSubSite") and form.RefreshSubSite eq "Refresh according to control file">
			<!--- we want to load up the DAL with everything that is subSite related from the ini file --->
			<cfset theDBTableLists_theiniSubSiteList = getSubSiteTablesfromINI() />
			<cfloop list="#theDBTableLists_theiniSubSiteList#" index="thisTable">
				<cfset theTableName = "SLCMS_Site_0_#thisTable#" />	<!--- when doing this deployment stuff force to standard naming --->
				<cfset ret = application.SLCMS.Core.DataMgr.loadTable(theTableName)>
			</cfloop>

		<cfelseif StructKeyExists(form, "SaveTableToFile") and form.SaveTableToFile eq "Save this Table to File">
			<!--- we are going to save one of the tables to a file with the xml describing the specified table within --->
			<cfset theTable = form.TableToSave />
			<cfset theXML = application.SLCMS.core.DataMgr.getXML(theTable) />
			<cfset theFullFilePath = "#application.SLCMS.config.startup.SiteBasePath#admin/DeveloperTemp/DAL_XML_DBDumps/XML_Definition_Table-#theTable#.xml" />
			<cffile action="write" file="#theFullFilePath#" output="#theXML#">

		<cfelseif StructKeyExists(form, "DumpSystem") and form.DumpSystem eq "Save All System Tables to Single XML File">
			<!--- we are going to save all of the tables to a file with the xml describing all of the tables within --->
			<cfset theXML = XMLParse(lcase(application.SLCMS.core.DataMgr.getXML())) />
			<!--- we now have everything so loop over the XML and delete the nodes that we don't want --->
			<!--- the XML search is case sensitive so we force all to lowercase to make sure we get matches --->
			<cfset ret = application.SLCMS.mbc_Utility.iniTools.ini2Struct(FilePath="#theiniPath_DBTables#") />
			<cfif ret.error.errorcode eq 0>
				<cfset theDBTableStruct_theiniSubSiteData = ret.data.subSite />
				<!--- this could include several subsites so lets crudely delete a bunch  --->
				<cfloop from="1" to="4" index="thissubSite">
					<cfset thesubSiteNumber = numberFormat(thissubSite-1, "0") /> <!--- we want "0" to "3" --->
					<cfloop collection="#theDBTableStruct_theiniSubSiteData#" item="thisTable">
						<cfset theTableName = lCase("SLCMS_Site_#thesubSiteNumber#_#thisTable#") />	<!--- when doing this deployment stuff force to standard naming --->
						<cfset arrTheSubSite = XmlSearch(theXML, "/tables/table[@name = '#theTableName#']") />
						<cfif not ArrayIsEmpty(arrTheSubSite)>
							<cfset ret = application.SLCMS.mbc_Utility.XMLtools.XmlDeleteNodes(theXML, arrTheSubSite) />
						</cfif>
					</cfloop>
				</cfloop>
			</cfif>
			<cfset TheRollRound = Nexts_getNextID("XML_Definition_AllTables") />
			<cfif TheRollRound gt 99>
				<cfset TheRollRound = "00" />
				<cfset Nexts_setNextID(IDName="XML_Definition_AllTables", Value="01") />
			<cfelse>
				<cfset TheRollRound = NumberFormat(TheRollRound, "00") />	<!--- format to 2 digit string --->
			</cfif>
			<cfset theFileName = 'XML_Definition_AllTables-System-#DateFormat(Now(), "YYYYMMDD")##TheRollRound#.xml' />
			<cfset theFullFilePath = theXMLDumpFilePath & theFileName />
			<cfset theOutPutString = toString(theXML) />
			<cfset theOutPutString = replaceNoCase(theOutPutString, chr(10), chr(13)&chr(10), "all") />
			<!---
			<cfset theOutPutString = replaceNoCase(theOutPutString, chr(62), chr(62)&chr(13)&chr(10), "all") />
			--->
			<cffile action="write" file="#theFullFilePath#" output="#theOutPutString#">

		<cfelseif StructKeyExists(form, "DumpSubSite") and form.DumpSubSite eq "Save subSite 0 and System Tables to XML File">
			<!--- we are going to save all of the tables that belong to the System and subSite0 to a file with the xml describing all of the tables within
	  				we cannot do just subSite0 as the xml from DataMgr is malformed in some contexts and the XMLsearch breaks --->
			<cfset theXML = XMLParse(lcase(application.SLCMS.core.DataMgr.getXML())) />
			<!--- we now have everything so loop over the XML and delete the nodes that we don't want --->
			<!--- the XML search is case sensitive so we force all to lowercase to make sure we get matches --->
			<cfset ret = application.SLCMS.mbc_Utility.iniTools.ini2Struct(FilePath="#theiniPath_DBTables#") />
			<cfif ret.error.errorcode eq 0>
				<cfset theDBTableStruct_theiniSubSiteData = ret.data.subSite />
				<!--- this could include several subsites so lets crudely delete a bunch  --->
				<cfloop from="1" to="3" index="thissubSite">
					<cfloop collection="#theDBTableStruct_theiniSubSiteData#" item="thisTable">
						<cfset theTableName = lCase("SLCMS_Site_#thissubSite#_#thisTable#") />	<!--- when doing this deployment stuff force to standard naming --->
						<cfset arrTheSubSite = XmlSearch(theXML, "/tables/table[@name = '#theTableName#']") />
						<cfif not ArrayIsEmpty(arrTheSubSite)>
							<cfset ret = application.SLCMS.mbc_Utility.XMLtools.XmlDeleteNodes(theXML, arrTheSubSite) />
						</cfif>
					</cfloop>
				</cfloop>
			</cfif>
			<cfset TheRollRound = Nexts_getNextID("XML_Definition_subSiteZeroTables") />
			<cfif TheRollRound gt 99>
				<cfset TheRollRound = "00" />
				<cfset Nexts_setNextID(IDName="XML_Definition_subSiteZeroTables", Value="01") />
			<cfelse>
				<cfset TheRollRound = NumberFormat(TheRollRound, "00") />	<!--- format to 2 digit string --->
			</cfif>
			<cfset theFileName = 'XML_Definition_AllTables-subSiteZeroTables_and_System-#DateFormat(Now(), "YYYYMMDD")##TheRollRound#.xml' />
			<cfset theFullFilePath = theXMLDumpFilePath & theFileName />
			<cfset theOutPutString = toString(theXML) />
			<cfset theOutPutString = replaceNoCase(theOutPutString, chr(10), chr(13)&chr(10), "all") />
			<!---
			<cfset theOutPutString = replaceNoCase(theOutPutString, chr(62), chr(62)&chr(13)&chr(10), "all") />
			--->
			<cffile action="write" file="#theFullFilePath#" output="#theOutPutString#">

		<cfelse>
			<cfset ErrFlag  = True />
			<cfset ErrMsg  = "Invalid form data from DAL task, no task matched" />
			<cfset DispMode = "ViewDatabaseStructs" />
		</cfif>
	<cfelse>
		<cfset ErrFlag  = True />
		<cfset ErrMsg  = "Invalid form button push from DAL task" />
		<cfset DispMode = "ViewDatabaseStructs" />
	</cfif>
	
<cfelseif WorkMode1 eq "ViewFileStructs">
	<cfset DispMode = "ViewFileStructs" />

<cfelseif WorkMode1 eq "">
	<!--- must be the entry, show basic stuff so grab the version state, etc --->
	<cfset theVersionData = application.SLCMS.Core.Versions_Master.getVersionMasterConfig() />
	<cfset DispMode = "" />
</cfif>

<cfif DispMode eq "ViewDatabaseStructs">
	<!--- we want to see what we know about the database so lets grab lots of stuff --->
	<!--- first see if we have a set of ini files for the two main table sets --->
	<cfset DBTableFileRead = False />	<!--- preset to nothing meaningful found --->
	<cfset DBTableFileHasBothSets = False />
	<cfset DBTableFileHasSystemSet = False />
	<cfset DBTableFileHasSubSiteSet = False />
	<cfif FileExists(theiniPath_DBTables)>
		<cfset ret = application.SLCMS.mbc_Utility.iniTools.ini2Struct(FilePath="#theiniPath_DBTables#") />
		<cfif ret.error.errorcode eq 0>
			<cfset theDBTableStruct_theiniData = ret.data />
			<cfset DBTableFileRead = True />	<!--- something in there, don't know what yet --->
		</cfif>
		<cfif not StructIsEmpty(theDBTableStruct_theiniData)>
			<cfif StructKeyExists(theDBTableStruct_theiniData, "System")>
				<cfset DBTableFileHasSystemSet = True />
			</cfif>
			<cfif StructKeyExists(theDBTableStruct_theiniData, "subSite")>
				<cfset DBTableFileHasSubSiteSet = True />
			</cfif>
			<cfif DBTableFileHasSystemSet and DBTableFileHasSubSiteSet>
				<cfset DBTableFileHasBothSets = True />
			</cfif>			
		</cfif>
	</cfif>
	<!--- then grab what the DAL sees --->
	<cfset theDBTableStruct_theDalData = application.SLCMS.Core.DataMgr.getTableData()>

<cfelse>
	<cfset theVersionData = application.SLCMS.Core.Versions_Master.getVersionMasterConfig() />
</cfif>

<cfsetting enablecfoutputonly="No">

<cfoutput>#includePartial("/slcms/adminbanner")#<!--- show the banner if we are in the backend, returns nothing if we are popped up --->

<div id="WorkingMsg"><p>Gathering Data</p></div>
 
<table border="0" cellpadding="3" cellspacing="0">	<!--- this table has the page/menu content --->
<cfif len(ErrMsg) or len(GoodMsg)>
	<tr><td colspan="3"></td></tr>
</cfif>
<cfif len(ErrMsg)><tr><td align="center" colspan="3" class="warnColour">Error:- #ErrMsg#</td></tr></cfif>
<cfif len(GoodMsg)><tr><td align="center" colspan="3" class="goodColour">Result:- #GoodMsg#</td></tr></cfif>
<cfif DispMode eq "">
	<tr><td colspan="3"></td></tr>
	<tr><td colspan="3">
		<div>
			<strong>Where we are at:</strong>
		</div>
		<div>
			The site code is Version: #theVersionData.CurrentVersion.VersionNumber_Full#
		</div>
		<div>
		<cfif theVersionData.CurrentVersion.VersionNumber_Full eq "Unknown">
			This is an older version of SLCMS, before Version 2.2 when automatic updating was included.<br>It will need semi-manually upgrading.
		<cfelse>
			It was installed on: 
			<cfif theVersionData.CurrentVersion.InstallDate neq "">
				#DateFormat(theVersionData.CurrentVersion.InstallDate, "dd-mmm-yyyy")#
			<cfelse>
				Installed but not yet configured
			</cfif>
		</cfif>
		</div>
		<div class="SuperDashboardSmallHeading"><p>The mode of this SLCMS site is: #application.SLCMS.config.base.sitemode#</p></div>
	</td></tr>
	<tr><td colspan="3"><hr></td></tr>
	<cfif application.SLCMS.config.base.sitemode eq "development">
		<tr><td colspan="3">
			<div class="SuperDashboardSmallHeading">Development and Deployment Tools</div>
		</td></tr>
		<tr><td colspan="3">
			<div class="SuperDashboardSmallHeading">Codebase</div>
		</td></tr>
		<tr>
			<td colspan="3">
				<a href="Admin_DevelopersTools.cfm?mode=ViewFileStructs">View and Dump Site File Structures</a>
			</td>
		</tr>
		<tr><td colspan="3">
			<div class="SuperDashboardSmallHeading">Database</div>
		</td></tr>
		<tr>
			<td colspan="3">
				<a href="Admin_DevelopersTools.cfm?mode=ViewDatabaseStructs">View and Dump Database Structures</a>
			</td>
		</tr>
		<tr>
			<td colspan="3">
				<a href="Admin_DevelopersTools.cfm?mode=WorkonDatabaseTable">Work on a Specific Database Table</a>
			</td>
		</tr>
		<tr>
			<td colspan="3">
				<a href="Admin_DevelopersTools.cfm?mode=TtTDTCwLoadXML">Tools to Test Database Table Creation with LoadXML()</a>
			</td>
		</tr>
		<tr><td colspan="3"><hr></td></tr>
		<tr><td colspan="3"><strong>Tools to see what is going on</strong></td></tr>
		<tr><td colspan="3"></td></tr>
		<tr><td colspan="3"><u>Global or General Tools</u></td></tr>
		<tr><td colspan="3">Dumps of the Variables Scope in a specific set of functions (a CFC) in the system code:</td></tr>
		<tr><td colspan="3">
			#linkTo(text="View the Module Management CFC", controller="slcms.developers", action="index", params="#PageContextFlags.ReturnLinkParams#&amp;mode=ViewVariablesScope&amp;Set=System&amp;CFC=ModuleManager")#
<!--- 
			<a href="Admin_DevelopersTools.cfm?mode=ViewVariablesScope&amp;Set=System&amp;CFC=ModuleManager">View the Module Management CFC</a>
			 --->
			</td></tr>
		<tr><td colspan="3"></td></tr>
		<tr><td colspan="3">General Scope Dumps:</td></tr>
		<tr><td colspan="3">
			#linkTo(text="View the Application Scope", controller="slcms.developers", action="index", params="#PageContextFlags.ReturnLinkParams#&amp;mode=ViewAppScope")#
		</td></tr>
		<tr><td colspan="3">
			#linkTo(text="View the Session Scope", controller="slcms.developers", action="index", params="#PageContextFlags.ReturnLinkParams#&amp;mode=ViewSessionScope")#
	</td></tr>
		<tr><td colspan="3">
			#linkTo(text="View the Server Scope", controller="slcms.developers", action="index", params="#PageContextFlags.ReturnLinkParams#&amp;mode=ViewServerScope")#
		</td></tr>
		<tr><td colspan="3"></td></tr>
	<cfelse>
		<tr><td colspan="3" class="SuperDashboardSmallHeading">This Site is not set up in Development Mode, not much to do here...</td></tr>
		<tr><td colspan="3"><hr></td></tr>
	</cfif>
	
<cfelseif DispMode eq "ChooseDatabaseXML">
	<tr><td colspan="3"></td></tr>
	<tr><td>
		#linkTo(text="Back to Developer's Toolkit", controller="slcms.developers", action="index", params="#PageContextFlags.ReturnLinkParams#")#
	</td><td colspan="2"></td></tr>
	<tr><td colspan="3"></td></tr>
	<tr><td colspan="3"><strong>Tools to test the database XML through the DAL</strong></td></tr>
	<tr><td colspan="3">The Datasource that the test will run on is: #theTestDSN#</td></tr>
	<tr valign="top">
		<td colspan="3" align="center">
			<table cellpadding="3" cellspacing="0" border="0" class="worktable">
				<tr><th colspan="3" class="WorkTableTopRowColour2Full">XML Files</th></tr>
					<cfloop query="theXMLFiles">
					<form action="Admin_DevelopersTools.cfm" method="post">
						<input type="hidden" name="task" value="#opNext#">
						<input type="hidden" name="FileToLoad" value="#theXMLFiles.name#">
					<tr>
						<td class="WorkTable2ndRow" align="left">
							#theXMLFiles.name#
							</td>
						<td class="WorkTable2ndRowRHcol">
						<input type="Submit" value="Load this XML" name="LoadXML">
							</td>
						</tr>
					</form>
				</cfloop>
			</table>
		</td>
	</tr>
								
<cfelseif DispMode eq "ChooseDatabaseTable">
	<tr><td colspan="3"></td></tr>
	<tr><td>
		#linkTo(text="Back to Developer's Toolkit", controller="slcms.developers", action="index", params="#PageContextFlags.ReturnLinkParams#")#
	</td><td colspan="2"></td></tr>
	<tr><td colspan="3"></td></tr>
	<tr><td colspan="3">No code here yet, just a dump of the current DAL data, ie tables that have been used/loaded since the last restart.</td></tr>
	
	<cfdump var="#theDBTableStruct_theDalData#" expand="false" label="theDBTableStruct_theDalData">


<cfelseif DispMode eq "ViewDatabaseStructs">
	<tr><td colspan="3"></td></tr>
	<tr><td><a href="Admin_DevelopersTools.cfm">Back to Developers's Toolkit</a></td><td colspan="2"></td></tr>
	<tr><td colspan="3"></td></tr>
	<cfif DBTableFileRead and DBTableFileHasBothSets>
		<tr><td colspan="3">
			This is a listing of what the system thinks it knows about the database tables. 
			If you are preparing for deployment as a new version then everything must match here.
			You must make sure the list of tables in the version ini file is correct and 
			you must make the DAL create the correct XML files to match the table structures and default data.
		</td></tr>
		<tr><td colspan="3">
			<table cellpadding="3" cellspacing="0" border="0" class="worktable">
				<tr valign="top" class="WorkTableTopRow">
					<th colspan="2">The Tables according to:</th>
				</tr>
				<tr valign="top" class="WorkTable2ndRow">
					<th>the control file</th>
					<th>the DAL</th>
				</tr>
				<tr valign="top">
					<td align="center">
						<cfset theSystemTableList_theiniData = "" />
						<table cellpadding="3" cellspacing="0" border="0" class="worktable">
							<tr><th class="WorkTableTopRowColour2Full">System Tables</th></tr>
							<cfloop collection="#theDBTableStruct_theiniData.System#" item="thisTable">
								<cfset theSystemTableList_theiniData = ListAppend(theSystemTableList_theiniData, "#thisTable#") />
								<tr><td class="WorkTableRowColour1withRH">#thisTable#</td></tr>
							</cfloop>
							<tr><th class="WorkTableTopRowColour2Full">subSite Tables</th></tr>
							<cfloop collection="#theDBTableStruct_theiniData.subSite#" item="thisTable">
								<tr><td class="WorkTableRowColour1withRH">#thisTable#</td></tr>
							</cfloop>
						</table>
					</td>
					<td align="center">
						<table cellpadding="3" cellspacing="0" border="0" class="worktable">
							<tr><th colspan="3" class="WorkTableTopRowColour2Full">System Tables</th></tr>
							<cfif DBTableFileHasSystemSet>
								<form action="Admin_DevelopersTools.cfm" method="post">
									<input type="hidden" name="DALbuttonPushed" value="YesSir">
									<input type="hidden" name="task" value="DALtask">
								<tr>
									<td class="WorkTable2ndRow" align="center">
									<input type="submit" name="RefreshSystem" value="Refresh according to control file">
									</td>
									<td colspan="2" class="WorkTable2ndRowRHcol">
									<input type="submit" name="DumpSystem" value="Save All System Tables to Single XML File">
									</td>
								</tr>
								</form>
							</cfif>
							<cfloop collection="#theDBTableStruct_theDalData#" item="thisTable">
								<cfif ListFindNoCase(theSystemTableList_theiniData, "#thisTable#")>
									<form action="Admin_DevelopersTools.cfm" method="post">
										<input type="hidden" name="DALbuttonPushed" value="YesSir">
										<input type="hidden" name="task" value="DALtask">
									<tr>
										<td class="WorkTableRowColour1">#thisTable#</td>
										<cfif server.mbc_Utility.CFConfig.DumpHasExpandAttribute>
											<td class="WorkTableRowColour1" align="center"><cfdump var="#xmlParse(application.SLCMS.core.DataMgr.getXML(thisTable))#" expand="false"></td>
										<cfelse>
											<td class="WorkTableRowColour1" align="center"><cfdump var="#xmlParse(application.SLCMS.core.DataMgr.getXML(thisTable))#"></td>
										</cfif>
										<td class="WorkTableRowColour1withRH">
											<input type="hidden" name="TableToSave" value="#thisTable#">
											<input type="submit" name="SaveTableToFile" value="Save this Table to File">
										</td>
									</tr>
								</form>
								</cfif>
							</cfloop>
							<tr><th colspan="3" class="WorkTableTopRowColour2Full">subSite Tables</th></tr>
							<cfif DBTableFileHasSubSiteSet>
								<form action="Admin_DevelopersTools.cfm" method="post">
									<input type="hidden" name="DALbuttonPushed" value="YesSir">
									<input type="hidden" name="task" value="DALtask">
								<tr>
									<td class="WorkTable2ndRow" align="center">
									<input type="submit" name="RefreshSubSite" value="Refresh according to control file">
									</td>
									</td>
									<td colspan="2" class="WorkTable2ndRowRHcol">
									<input type="submit" name="DumpSubSite" value="Save subSite 0 and System Tables to XML File">
									</td>
									<td class="WorkTable2ndRowRHcol"></td>
								</tr>
								</form>
							</cfif>
							<cfloop collection="#theDBTableStruct_theDalData#" item="thisTable">
								<cfif FindNoCase("Site_0", thisTable)>
									<form action="Admin_DevelopersTools.cfm" method="post">
										<input type="hidden" name="DALbuttonPushed" value="YesSir">
										<input type="hidden" name="task" value="DALtask">
									<tr>
										<td class="WorkTableRowColour1">#thisTable#</td>
										<cfif server.mbc_Utility.CFConfig.DumpHasExpandAttribute>
											<td class="WorkTableRowColour1" align="center"><cfdump var="#xmlParse(application.SLCMS.core.DataMgr.getXML(thisTable))#" expand="false"></td>
										<cfelse>
											<td class="WorkTableRowColour1" align="center"><cfdump var="#xmlParse(application.SLCMS.core.DataMgr.getXML(thisTable))#"></td>
										</cfif>
										<td class="WorkTableRowColour1withRH">
											<input type="hidden" name="TableToSave" value="#thisTable#">
											<input type="submit" name="SaveTableToFile" value="Save this Table to File">
										</td>
									</tr>
								</form>
								</cfif>
							</cfloop>
						</table>
					</td>
					<td></td>
				</tr>
			</table>
		</td></tr>
	<cfelseif DBTableFileRead and not DBTableFileHasBothSets>
		<tr><td colspan="3">The Table control file was read but did not contain meaningful data.</td></tr>
		<tr><td colspan="3"></td></tr>
		<tr><td colspan="3">The filename is &quot;DatabaseTables_Current.ini&quot; and is in the &quot;Versions&quot; folder.<br>The system found it but it did not have the corrcet sections.</td></tr>
		<tr><td colspan="3">You need to find it and edit it. It should have been there with at least two sections: [System] and [subSite].</td></tr>
	<cfelse>
		<tr><td colspan="3">The Table control file was not there to be read.</td></tr>
		<tr><td colspan="3"></td></tr>
		<tr><td colspan="3">The filename is DatabaseTables_Current.ini and should be in the "Versions" folder.<br>The system looked for: #theiniPath_DBTables#</td></tr>
	</cfif>
	
<cfelseif DispMode eq "ViewFileStructs">
	<tr><td colspan="3"></td></tr>
	<tr><td>
		#linkTo(text="Back to Developer's Toolkit", controller="slcms.developers", action="index", params="#PageContextFlags.ReturnLinkParams#")#
	</td><td colspan="2"></td></tr>
	<tr><td colspan="3"></td></tr>
	<tr><td colspan="3">No code here yet, this will be the place to look at the file structure.</td></tr>
	
	<cfdump var="#createBaseSiteFolderStructure()#" expand="false" label="createBaseSiteFolderStructure()">
	
<cfelseif DispMode eq "ViewAppScope">
	<tr><td colspan="3"></td></tr>
	<tr><td>
		#linkTo(text="Back to Developer's Toolkit", controller="slcms.developers", action="index", params="#PageContextFlags.ReturnLinkParams#")#
	</td><td colspan="2"></td></tr>
	<tr><td colspan="3">
		the <strong>Application scope</strong> structure: 
		<cfif server.mbc_Utility.CFconfig.DumpHasExpandAttribute>
			<br>(Click to Expand structures)
		</cfif>
	</td></tr>
	<tr><td colspan="3">
		<cfif server.mbc_Utility.CFconfig.DumpHasExpandAttribute>
			<cfdump var='#Application#' expand="false">
		<cfelse>
			<cfdump var='#Application#'>
		</cfif>
	</td></tr>
	
<cfelseif DispMode eq "ViewSessionScope">
	<tr><td colspan="3"></td></tr>
	<tr><td>
		#linkTo(text="Back to Developer's Toolkit", controller="slcms.developers", action="index", params="#PageContextFlags.ReturnLinkParams#")#
	</td><td colspan="2"></td></tr>
	<tr><td colspan="3">
		the <strong>session scope</strong> structure:
		<cfif server.mbc_Utility.CFconfig.DumpHasExpandAttribute>
			<br>(Click to Expand structures)
		</cfif>
	</td></tr>
	<tr><td colspan="3">
		<cfif server.mbc_Utility.CFconfig.DumpHasExpandAttribute>
			<cfdump var='#Session#' expand="false">
		<cfelse>
			<cfdump var='#Session#'>
		</cfif>
	</td></tr>
	
<cfelseif DispMode eq "ViewServerScope">
	<tr><td colspan="3"></td></tr>
	<tr><td>
		#linkTo(text="Back to Developer's Toolkit", controller="slcms.developers", action="index", params="#PageContextFlags.ReturnLinkParams#")#
	</td><td colspan="2"></td></tr>
	<tr><td colspan="3">
		the <strong>Server scope</strong> structure:
		<cfif server.mbc_Utility.CFconfig.DumpHasExpandAttribute>
			<br>(Click to Expand structures)
		</cfif>
	</td></tr>
	<tr><td colspan="3">
		<cfif server.mbc_Utility.CFconfig.DumpHasExpandAttribute>
			<cfdump var='#Server#' expand="false">
		<cfelse>
			<cfdump var='#Server#'>
		</cfif>
	</td></tr>

<cfelseif DispMode eq "ViewVariablesScope">
	<tr><td colspan="3"></td></tr>
	<tr><td>
		#linkTo(text="Back to Developer's Toolkit", controller="slcms.developers", action="index", params="#PageContextFlags.ReturnLinkParams#")#
	</td><td colspan="2"></td></tr>
	<cfif StructKeyExists(url, "CFC") and ListFindNoCase("Content_DatabaseIO,Forms,ModuleManager,PageStructure,PortalControl,SLCMS_Utility,Templates,UserControl,UserPermissions", params.CFC)>
		<tr><td colspan="3">
			the <strong>#params.CFC#</strong> structure:
			<cfif server.mbc_Utility.CFconfig.DumpHasExpandAttribute>
				<br>(Click to Expand structures)
			</cfif>
		</td></tr>
		<tr><td colspan="3">
			<cfif server.mbc_Utility.CFconfig.DumpHasExpandAttribute>
				<cfdump var='#application.SLCMS["#params.Set#"]["#params.CFC#"].getVariablesScope()#' expand="false">
			<cfelse>
				<cfdump var='#application.SLCMS["#params.Set#"]["#params.CFC#"].getVariablesScope()#'>
			</cfif>
		</td></tr>
	<cfelse>
		<tr><td colspan="3">Invalid Function Set Selected</td></tr>
	</cfif>
	
</cfif>
</table>
</cfoutput>