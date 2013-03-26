<!--- SLCMS CFCs  --->
<!--- &copy; mort bay communications --->
<!---  --->
<!--- all the function to shuffle content in and out of Database --->
<!---  --->
<!---  --->
<!--- Created:   4th Jan 2007 by Kym K --->
<!--- Modified:  4th Jan 2007 -  6th Jan 2007 by Kym K, mbcomms: working on it --->
<!--- Modified: 20th Jan 2007 - 25th Jan 2007 by Kym K, mbcomms: adding more functions for blogs and things --->
<!--- Modified: 10th Mar 2007 - 10th Mar 2007 by Kym K, mbcomms: added content type for advanced searching, etc --->
<!--- Modified: 20th May 2007 - 20th May 2007 by Kym K, mbcomms: tidying up local declarations in functions, now failing in BD7 --->
<!--- Modified: 28th Feb 2008 -  1st Apr 2008 by Kym K, mbcomms: adding shop functions --->
<!--- modified:  1st Dec 2008 -  1st Dec 2008 by Kym K, mbcomms: made it silent, all function outputs="No" --->
<!--- modified:  7th Feb 2009 - 16th Feb 2009 by Kym K, mbcomms: adding code to allow integration of a wiki --->
<!--- modified: 22nd Feb 2009 - 28th Feb 2009 by Kym K, mbcomms: adding code for version control --->
<!--- modified:  6th May 2009 -  6th May 2009 by Kym K, mbcomms: V2.2, changing folder structure to portal/sub-site architecture, sites inside the top site
																																				this involves creating sets of sites and their database structures, etc.
																																				with naming changes to match --->
<!--- modified: 29th Oct 2009 - 29th Oct 2009 by Kym K, mbcomms: adding improved version counting for UI to use, now has negative number for pre-published versions --->
<!--- modified: 11th Dec 2009 - 15th Dec 2009 by Kym K, mbcomms: V2.2+ now adding DataMgr as a DAL to make the codebase database agnostic
																																				NOTE: we have left the old straight query code here so the changes for the DAL can be inspected
																																							things like the DSN are no longer needed as the DAL knows that
																																							now we can just worry about tables and their contents --->
<!--- modified:  5th Jun 2010 -  5th Jun 2010 by Kym K, mbcomms: added reInit function for portal changes, etc --->
<!--- modified: 18th Feb 2011 - 18th Feb 2011 by Kym K, mbcomms: ran varScoper over code and found un-var'd variables! oops :-/  --->
<!--- modified:  7th Jun 2011 - 19th Jun 2011 by Kym K, mbcomms: added logging functions so we can have consistent logging outside CF's logs --->
<!--- modified:  9th Apr 2012 -  9th Apr 2012 by Kym K, mbcomms: V3.0, CFWheels version. All SLCMS in own struct under app scope --->

<cfcomponent displayname="Content-Database I/O" hint="Handles Content Input/Output from/to Database" output="false">

	<!--- set up a few persistant things on the way in. --->
	<cfset variables.dsn = "" />
	<cfset variables.DataBaseTableNaming = StructNew() />	
	<cfset variables.DataBaseTableNaming.Parts = StructNew() />	
	<cfset variables.DataBaseTableNaming.PreSiteID = "" />
	<!--- portal related data --->
	<cfset variables.SubSiteControl = StructNew() />
	<cfset variables.SubSiteControl.SubSiteIDList_Full = "0" />
	<cfset variables.SubSiteControl.SubSiteData = StructNew() />

<cffunction name="init" 
	access="public" output="No" returntype="any" 
	displayname="Initializer"
	hint="sets up the internal structures for this component"
	>
	<cfargument name="dsn" type="string" required="yes">	<!--- the name of the database that has the relevant tables such as "Nexts" --->
	<cfargument name="DatabaseDetails" type="struct" required="true">	<!--- the structure carrying all the naming bits of the db tables --->
	
	<cfset var temp = "" />
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorContext = "Content_DatabaseIO CFC: Init()" />
	<cfset ret.Data = "" />

	<cfset temps = LogIt(LogType="CFC_Init", LogString="Content-Database I/O Init() Started") />
	<cftry>
		<!--- store our set up data --->
		<!--- the database connection name --->
		<cfset variables.dsn = arguments.dsn />
		<!--- the naming regime for the DB tables, almost as versatile as we can get it --->
		<cfset variables.DataBaseTableNaming.Parts.Base = arguments.DatabaseDetails.TableNaming_Base />
		<cfset variables.DataBaseTableNaming.Parts.ContentTable = arguments.DatabaseDetails.ContentTable />
		<cfset variables.DataBaseTableNaming.Parts.Delimiter = arguments.DatabaseDetails.TableNaming_Delimiter />
		<cfset variables.DataBaseTableNaming.Parts.DocContentControlTable = arguments.DatabaseDetails.DocContentControlTable />
		<cfset variables.DataBaseTableNaming.Parts.SiteMarker = arguments.DatabaseDetails.TableNaming_SiteMarker />
		<cfset variables.DataBaseTableNaming.Parts.SystemMarker = arguments.DatabaseDetails.TableNaming_SystemMarker />
		<cfset variables.DataBaseTableNaming.Parts.TypeMarker = arguments.DatabaseDetails.TableNaming_TypeMarker />
		<!--- and precalculate a few bits --->
		<cfset variables.DataBaseTableNaming.PreSiteID = 
						variables.DataBaseTableNaming.Parts.Base 
					& variables.DataBaseTableNaming.Parts.Delimiter 
					& variables.DataBaseTableNaming.Parts.SiteMarker 
					& variables.DataBaseTableNaming.Parts.Delimiter /> <!--- default: "SLCMS_Site_" --->
		<!--- grab the subsite data and load into local vars --->
		<cfset temp = reInitAfter(Action="subSite")>	<!--- save some code and use the existing function below --->
	
	<cfcatch type="any">
		<cfset ret.error = TakeErrorCatch(RetErrorStruct=ret.error, CatchStruct=cfcatch) />
	</cfcatch>
	</cftry>

	<cfset temps = LogIt(LogType="CFC_Init", LogString="Content-Database I/O Init() Finished") />
	<cfreturn variables />
</cffunction>

<cffunction name="ReInitAfter" output="No" returntype="struct" access="public"
	displayname="Re-Init After"
	hint="re-initialize variables after some external change"
	>
	<!--- this function needs.... --->
	<cfargument name="Action" type="string" default="" hint="the action that took place, defines the bits that need re-initializing" />

	<!--- now all of the var declarations, first the arguments which need manipulation --->
	<cfset var theAction = trim(arguments.Action) />
	<!--- now vars that will get filled as we go --->
	<cfset var thisSubSiteID = "" />	<!--- temp/throwaway var --->
	<cfset var temp = "" />	<!--- temp/throwaway var --->
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorContext = "Content_DatabaseIO CFC: ReInitAfter() Action: #theAction#" />
	<cfset ret.error.ErrorText = "" />
	<cfset ret.error.ErrorExtra = "" />
	<cfset ret.Data = "" />	<!--- and no data yet --->

	<cfset temps = LogIt(LogType="CFC_Init", LogString="Content-Database I/O ReInitAfter() Started") />
	<!--- wrap the whole thing in a try/catch in case something breaks --->
	<cftry>
		<!--- try each action in turn --->
		<cfswitch expression="#theAction#">
			<!--- pick action performed and run the relevant refreshes --->
			<cfcase value="subSite">
				<!--- a changed subSite needs to refresh our local list of tables, etc --->
				<cfset variables.SubSiteControl.SubSiteIDList_Full = application.SLCMS.Core.PortalControl.GetFullSubSiteIDList() />
				<!--- and then loop over them refreshing each in turn --->
				<cfloop list="#variables.SubSiteControl.SubSiteIDList_Full#" index="thisSubSiteID">
					<cfset variables.DataBaseTableNaming["SubSite_#thisSubSiteID#"] = StructNew() />
					<cfset variables.DataBaseTableNaming["SubSite_#thisSubSiteID#"].Content_ContentTableName = variables.DataBaseTableNaming.PreSiteID & thisSubSiteID & variables.DataBaseTableNaming.Parts.Delimiter & variables.DataBaseTableNaming.Parts.ContentTable />
					<cfset variables.DataBaseTableNaming["SubSite_#thisSubSiteID#"].Content_ControlTableName = variables.DataBaseTableNaming.PreSiteID & thisSubSiteID & variables.DataBaseTableNaming.Parts.Delimiter & variables.DataBaseTableNaming.Parts.DocContentControlTable />
					<!--- and load the content tables into our DAL --->
					<cfset temp = application.SLCMS.core.DataMgr.loadTable(variables.DataBaseTableNaming["SubSite_#thisSubSiteID#"].Content_ContentTableName) />
					<cfset temp = application.SLCMS.core.DataMgr.loadTable(variables.DataBaseTableNaming["SubSite_#thisSubSiteID#"].Content_ControlTableName) />
				</cfloop>
			</cfcase>
			<cfdefaultcase>
				<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 1) />
				<cfset ret.error.ErrorText = ret.error.ErrorText & "Oops! No Action argument Supplied<br>" />
			</cfdefaultcase>>
		</cfswitch>
		<cfif ret.error.ErrorCode neq 0>
			<cflog text='#ret.error.ErrorText# - ret.error.ErrorCode: #ret.error.ErrorCode# - Time: #DateFormat(Now(),"YYYYMMDD")#-#TimeFormat(now(),"HH:mm:ss")#'  file="#Application.SLCMS.Logging.theSiteLogName#" type="Error" application = "yes">
		</cfif>
	<cfcatch type="any">
		<cfset ret.error = TakeErrorCatch(RetErrorStruct=ret.error, CatchStruct=cfcatch) />
	</cfcatch>
	</cftry>

	<cfset temps = LogIt(LogType="CFC_Init", LogString="Content-Database I/O ReInitAfter() Finished") />
	<cfreturn ret  />
</cffunction>


<!--- this function get the contentID of a container --->
<cffunction name="getContainerContentID" access="public" output="yes" returntype="struct" hint="gets the ContentID and related data for the specified container in a page">
	<cfargument name="PageID" type="numeric" default="" hint="DocumentID of the page">
	<cfargument name="ContainerID" type="numeric" default="0" hint="ID of container on page if different content on each page">
	<cfargument name="ContainerName" type="string" default="" hint="name of container if content same on many pages">
	<cfargument name="ContentVersion" type="string" default="Live" hint="Which ID to get: Latest for last edited; Live for published; and Version_n for a specific version. Defaults to Live">
	<cfargument name="InEditMode" type="boolean" default="False" hint="whether we are editing and so need more info">
	<cfargument name="SubSiteID" type="numeric" required="yes" hint="the ID of the subsite to work with">

	<cfset var loc = StructNew() />
	<cfset var theSubSiteID = trim(arguments.SubSiteID) />

	<cfset var getContentID = "" />	<!--- query to get ContentID --->
	<cfset var GoodParams = True />	<!--- flag we had good incoming data --->
	<cfset var theControlTableName = variables.DataBaseTableNaming["SubSite_#theSubSiteID#"].Content_ControlTableName />
	<cfset var theQueryDataArguments = StructNew() />	<!--- temp struct to compose the data clauses of the SQL query --->
	<cfset var theQueryWhereArguments = StructNew() />	<!--- temp struct to compose the where clauses of the SQL query --->
	<cfset var getVersionLive = "" />	<!--- 2nd query to get version --->
	<cfset var getVersionNotLive = "" />	<!--- 2nd query to get version --->
	<cfset var setHandles = "" />	<!--- 3rd query to set hanldes if we need to --->
	<cfset var ContentControl = StructNew() />	<!--- returned struct of control data --->
	<cfset var theContentVersion = trim(arguments.ContentVersion) />	<!--- type of content to get, latest version for editing or the live content --->
	<cfset var WhereString = "" />
	<cfset var WhereString1 = "" />
	<cfset var WhereString2 = "" />
	<cfset loc.theVersionToFind = 0 />	<!--- version to find in queries --->
	<cfset ContentControl.ContentID = 0 />	<!--- fill it defaults or nulls --->
	<cfset ContentControl.Handle = "" />
	<cfset ContentControl.DocID = 0 />
	<cfset ContentControl.ContentTypeID = 0 />
	<cfset ContentControl.ContainerID = 0 />
	<cfset ContentControl.ContainerName = "" />
	<cfset ContentControl.EditorMode = "WYSIWYG" />
	<cfset ContentControl.ContentStatus = theContentVersion />
	<cfset ContentControl.LiveVersion = 0 />
	<cfset ContentControl.Version = 0 />
	<cfset ContentControl.VersionOutCount = 0 />

	<!--- work out if it is a named container or one (of many) on a page and build our query from there --->
	<cfif len(arguments.ContainerName)>
		<cfset theQueryWhereArguments.ContainerName = arguments.ContainerName />
	<cfelseif len(arguments.ContainerID) and arguments.ContainerID gt 0>
		<cfset theQueryWhereArguments.DocID = arguments.PageID />
		<cfset theQueryWhereArguments.ContainerID = arguments.ContainerID />
	<cfelse>
		<cfset GoodParams = False />	<!--- flag we had bad incoming data --->
	</cfif>
	<cfif theContentVersion eq "Latest">
		<cfset theQueryWhereArguments.Version = 0 />
	<cfelseif theContentVersion eq "Live">
		<cfset theQueryWhereArguments.flag_LiveVersion = 1 />
	<cfelse>
		<cfset loc.theVersionToFind = ListLast(theContentVersion, "_") />
		<cfset theQueryWhereArguments.Version = loc.theVersionToFind />
	</cfif>
<!--- 	
	<!--- work out if it is a named container or one (of many) on a page and build our query from there --->
	<cfif len(arguments.ContainerName)>
		<cfset WhereString1 = "ContainerName = '#arguments.ContainerName#'" />
	<cfelseif len(arguments.ContainerID) and arguments.ContainerID gt 0>
		<cfset WhereString1 = "DocID = #arguments.PageID# and ContainerID = #arguments.ContainerID#" />
	<cfelse>
		<!--- change: we are now using a null wherestring as the test for bad params input 
		<cfset WhereString = "1 = 0" />
		 --->
	</cfif>
	<cfif theContentVersion eq "Latest">
		<cfset WhereString2 = WhereString1 & "and Version = 0" />
	<cfelseif theContentVersion eq "Live">
		<cfset WhereString2 = WhereString1 & "and flag_LiveVersion = 1" />
	<cfelse>
		<cfset theVersionToFind = ListLast(theContentVersion, "_") />
		<cfset WhereString2 = WhereString1 & "and Version = #theVersionToFind#" />
	</cfif>
	<cfif len(WhereString2)>
		<!--- get the ID for the content --->
		<cfquery name="getContentID" datasource="#variables.dsn#">
			select	ContentID, DocID, ContainerID, ContainerName, ContentHandle, ContentTypeID, EditorMode, flag_LiveVersion, Version
				from	#variables.DataBaseTableNaming["SubSite_#thisSubSiteID#"].Content_ControlTableName#
				where	#PreserveSingleQuotes(WhereString2)#
		</cfquery>
 --->	
	<cfif GoodParams>
		<cfset getContentID = application.SLCMS.core.DataMgr.getRecords(tablename="#theControlTableName#", data=theQueryWhereArguments, fieldList="ContentID,DocID,ContainerID,ContainerName,ContentHandle,ContentTypeID,EditorMode,flag_LiveVersion,Version") />
		<!--- process according to goodness --->
		<cfif getContentID.RecordCount eq 1>
			<!--- we have a content ID that we can use so return it --->
			<cfset ContentControl.ContentID = getContentID.ContentID />
			<cfset ContentControl.Handle = getContentID.ContentHandle />
			<cfset ContentControl.DocID = getContentID.DocID />
			<cfset ContentControl.ContentTypeID = getContentID.ContentTypeID />
			<cfset ContentControl.ContainerID = getContentID.ContainerID />
			<cfset ContentControl.ContainerName = getContentID.ContainerName />
			<cfset ContentControl.EditorMode = getContentID.EditorMode />
			<cfset ContentControl.LiveVersion = getContentID.flag_LiveVersion />
			<cfset ContentControl.Version = getContentID.version />
			<cfif ContentControl.Version eq 0>
				<cfset ContentControl.ContentStatus = "Latest" />
			<cfelseif getContentID.flag_LiveVersion>
				<cfset ContentControl.ContentStatus = "Live" />
			<cfelse>
				<cfset ContentControl.ContentStatus = theContentVersion />
			</cfif>
			<!--- check to see if we are editing or just looking and if so grab the latest to see how many versions out we are, if anything --->
			<cfif arguments.InEditMode>
				<!--- if editing we need to count how many version from published to latest --->
				<!--- so tickle the query params to get version number of the published content --->
				<cfset theQueryWhereArguments.flag_LiveVersion = 1 />
				<cfset StructDelete(theQueryWhereArguments, "Version")>	<!--- get rid of params we don't need now --->

				<cfset getVersionLive = application.SLCMS.core.DataMgr.getRecords(tablename="#theControlTableName#", data=theQueryWhereArguments, fieldList="Version") />

				<!--- 
				<cfquery name="getVersionLive" datasource="#variables.dsn#">
					select	Version
						from	#theControlTableName#
						where	DocID = <cfqueryparam value="#getContentID.DocID#" cfsqltype="cf_sql_integer" />
							and ContainerID = <cfqueryparam value="#getContentID.DocID#" cfsqltype="cf_sql_integer" />
							and	flag_LiveVersion = 1
				</cfquery>
				 --->
				<!--- test for goodness of result --->
				<cfif getVersionLive.version eq "">
					<!--- if we have a broken system or nothing is published yet we will get a null return so make the version the biggest, ie the first written ---> 
					<cfset theQueryWhereArguments.flag_LiveVersion = 0 />
					<cfset getVersionLive = application.SLCMS.Core.DataMgr.getRecords(tablename="#theControlTableName#", data=theQueryWhereArguments, fieldList="Version") />
					<cfset ContentControl.VersionOutCount = getVersionLive.RecordCount />
				<cfelse>
					<!--- we have something published so use that --->
					<cfset ContentControl.VersionOutCount = getVersionLive.version - loc.theVersionToFind />
				</cfif>
			</cfif>
			<!--- now we do a legacy data catchup for sites that did not use the handle, we'll put one in --->
			<cfif ContentControl.Handle eq "">
				<!--- its not a UUID so put one in for all entries for this content --->
				<cfset StructDelete(theQueryWhereArguments, "flag_LiveVersion")>	<!--- get rid of params we don't need now --->
				<cfset theQueryDataArguments.ContentHandle = CreateUUID() />
				<cfset setHandles = application.SLCMS.Core.DataMgr.UpdateRecords(tablename="#theControlTableName#", data_set=theQueryDataArguments, data_where=theQueryWhereArguments) />
				<!--- 
				<cfquery name="setHandles" datasource="#variables.dsn#">
					update	#variables.DataBaseTableNaming["SubSite_#thisSubSiteID#"].Content_ControlTableName#
						set		ContentHandle = '#CreateUUID()#'
						where	#PreserveSingleQuotes(WhereString1)#
				</cfquery>
				 --->
			</cfif>

		<cfelseif getContentID.RecordCount eq 0>
			<!--- we either have not yet published or there is no content yet so we need to work out which
						so lets check to see if there is anything and show the latest if there is --->
			<cfif arguments.InEditMode>
				<cfset StructDelete(theQueryWhereArguments, "flag_LiveVersion")>	<!--- get rid of params we don't need now --->
				<cfset StructDelete(theQueryWhereArguments, "Version")>	<!--- get rid of params we don't need now --->
				<cfset getVersionNotLive = application.SLCMS.Core.DataMgr.getRecords(tablename="#theControlTableName#", data=theQueryWhereArguments, fieldList="ContentID,DocID,ContainerID,ContainerName,ContentHandle,ContentTypeID,EditorMode,flag_LiveVersion,Version,VersionTimeStamp", orderby="VersionTimeStamp desc") />
				<!--- 
				<cfquery name="getVersionNotLive" datasource="#variables.dsn#">
					select	ContentID, DocID, ContainerID, ContainerName, ContentHandle, ContentTypeID, EditorMode, flag_LiveVersion, Version, VersionTimeStamp
						from	#variables.DataBaseTableNaming["SubSite_#thisSubSiteID#"].Content_ControlTableName#
						where	#PreserveSingleQuotes(WhereString1)#
						order by	VersionTimeStamp desc
				</cfquery>
				 --->
				<cfif getVersionNotLive.RecordCount gt 0>
					<!--- there is stuff but nothing published so flag something as latest --->
					<cfset ContentControl.ContentID = getVersionNotLive.ContentID />
					<cfset ContentControl.Handle = getVersionNotLive.ContentHandle />
					<cfset ContentControl.DocID = getVersionNotLive.DocID />
					<cfset ContentControl.ContentTypeID = getVersionNotLive.ContentTypeID />
					<cfset ContentControl.ContainerID = getVersionNotLive.ContainerID />
					<cfset ContentControl.ContainerName = getVersionNotLive.ContainerName />
					<cfset ContentControl.EditorMode = getVersionNotLive.EditorMode />
					<cfset ContentControl.LiveVersion = getVersionNotLive.flag_LiveVersion />
					<cfset ContentControl.Version = 0 />
					<cfset ContentControl.ContentStatus = "Latest" />
					<cfset ContentControl.VersionOutCount = getVersionNotLive.RecordCount />
				<cfelse>
					<!--- nothing there so flag new content --->
					<cfset ContentControl.ContentID = 0 />
				</cfif>
			</cfif>
		<cfelse>
			<!--- flag error, ie duplicates --->
			<cfset ContentControl.ContentID = -2 />
		</cfif>
	<cfelse>
		<!--- flag error, ie bad params --->
		<cfset ContentControl.ContentID = -1 />
	</cfif>

	<cfreturn ContentControl />
</cffunction>

<cffunction name="getContainerContentTypeID" access="public" output="No" returntype="struct" hint="gets the ContentTypeID for the specified DocID">
	<cfargument name="DocID" type="numeric" default="">
	<cfargument name="SubSiteID" type="numeric" required="yes" hint="the ID of the subsite to work with">

	<cfset var theSubSiteID = trim(arguments.SubSiteID) />
	<cfset var theControlTableName = variables.DataBaseTableNaming["SubSite_#theSubSiteID#"].Content_ControlTableName />
	<cfset var theQueryDataArguments = StructNew() />	<!--- temp struct to compose the data clauses of the SQL query --->
	<cfset var theQueryWhereArguments = StructNew() />	<!--- temp struct to compose the where clauses of the SQL query --->
	
	<cfset var result = 1 />	<!--- returned data, default to standard page content --->
	<cfset var getContentTypeID = "" />	<!--- query to get ContentTypeID --->

	<cfset theQueryWhereArguments.DocID = arguments.DocID />
	<cfset theQueryWhereArguments.Version = 0 />
	
	<!--- get the ID for the content --->
	<cfset getContentTypeID = application.SLCMS.Core.DataMgr.getRecords(tablename="#theControlTableName#", data=theQueryWhereArguments, fieldList="ContentTypeID") />
	<!--- 
	<cfquery name="getContentTypeID" datasource="#variables.dsn#">
		select	ContentTypeID
			from	#request.ShopContentControlTable#
			where	DocID = #arguments.DocID#
				and	Version = 0
	</cfquery>
	 --->
	<!--- process according to goodness --->
	<cfif getContentTypeID.RecordCount eq 1>
		<!--- we have a content ID that we can use so return it --->
		<cfset result = getContentTypeID.ContentTypeID />
	<cfelseif getContentID.RecordCount eq 0>
		<!--- flag new content --->
		<cfset result = 0 />
	<cfelse>
		<!--- flag error, ie duplicates --->
		<cfset result = -1 />
	</cfif>

	<cfreturn result />
</cffunction>

<cffunction name="setContainerPublishedContent" access="public" output="No" returntype="string" hint="this function resets the published flags for the content of a container">
	<cfargument name="PageID" type="numeric" default="" hint="DocumentID of the page">
	<cfargument name="ContainerID" type="numeric" default="0" hint="ID of container on page if different content on each page">
	<cfargument name="ContainerName" type="string" default="" hint="name of container if content same on many pages">
	<cfargument name="ContentID" type="string" default="Live" hint="The ID of the content that is to be published">
	<cfargument name="UserID" type="string" required="yes" hint="ID of user doing the save">
	<cfargument name="SubSiteID" type="numeric" required="yes" hint="the ID of the subsite to work with">

	<cfset var theSubSiteID = trim(arguments.SubSiteID) />

	<cfset var theControlTableName = variables.DataBaseTableNaming["SubSite_#theSubSiteID#"].Content_ControlTableName />
	<cfset var theContentTableName = variables.DataBaseTableNaming["SubSite_#theSubSiteID#"].Content_ContentTableName />
	<cfset var theQueryDataArguments = StructNew() />	<!--- temp struct to compose the data clauses of the SQL query --->
	<cfset var theQueryWhereArguments = StructNew() />	<!--- temp struct to compose the where clauses of the SQL query --->
	<cfset var ret = "" />	<!--- the default var to return stuff in, often dumped --->
	<cfset var getOldContentID = "" />	<!--- stupid MX, why do I have to do this? --->
	<cfset var SetVersionContent1 = "" />	<!--- query to set things --->
	<cfset var SetVersionControl1 = "" />	<!--- query to set things --->
	<cfset var SetVersionContent2 = "" />	<!--- query to set things --->
	<cfset var SetVersionControl2 = "" />	<!--- query to set things --->
	<cfset var verWhereString = "" />	<!--- temp string to compose SQL query --->

	<!--- 	
	<cfdump var="#arguments.ContentControlData#"><cfabort>
 --->	

	<cfif arguments.contentID neq 0>	<!--- a new page has an ID of zero --->
		<!--- set the string to find our set of contents --->
		<cfif trim(arguments.containerName) neq "">	
			<cfset theQueryWhereArguments.containerName = arguments.containerName />
			<!--- 
			<cfset verWhereString = "containerName = '#arguments.containerName#'" />
			 --->
		<cfelse>
			<cfset theQueryWhereArguments.containerID = arguments.containerID />
			<!--- 
			<cfset verWhereString = "containerID = #arguments.containerID#" />
			 --->
		</cfif>
		<!--- first find the contentID of the current published content so we can reset it --->
		<cfset theQueryWhereArguments.DocID = arguments.PageID />
		<cfset theQueryWhereArguments.flag_LiveVersion = 1 />
		<cfset getOldContentID = application.SLCMS.Core.DataMgr.getRecords(tablename="#theControlTableName#", data=theQueryWhereArguments, fieldList="ContentID") />
		<!--- 
		<cfquery name="getOldContentID" datasource="#variables.dsn#">
			select	ContentID
				from	#variables.DataBaseTableNaming["SubSite_#thisSubSiteID#"].Content_ControlTableName#
				where	DocID = #arguments.PageID#
					and	#PreserveSingleQuotes(verWhereString)#
					and	flag_LiveVersion = 1
		</cfquery>
		 --->
		<cfif getOldContentID.RecordCount>	<!--- allow for new, never-been-published content --->
			<!--- and flag that as unpublished in content table and control table --->
			<cfset theQueryWhereArguments.contentID = getOldContentID.contentID />	<!--- point to the old contentID --->
			<cfset StructClear(theQueryDataArguments) />	<!--- get rid of previous data --->
			<!--- clear the current version flag right thru for this contentID --->
			<cfset theQueryDataArguments.flag_CurrentVersion = 0 />
			<cfset SetVersionContent1 = application.SLCMS.Core.DataMgr.UpdateRecords(tablename="#theContentTableName#", data_set=theQueryDataArguments, data_where=theQueryWhereArguments) />
			<cfset StructClear(theQueryDataArguments) />	<!--- get rid of previous data --->
			<!--- clear the live version flag right thru for this contentID --->
			<cfset theQueryDataArguments.flag_LiveVersion = 0 />
			<cfset SetVersionContent1 = application.SLCMS.Core.DataMgr.UpdateRecords(tablename="#theControlTableName#", data_set=theQueryDataArguments, data_where=theQueryWhereArguments) />
			<!--- 
			<cfquery name="SetVersionContent1" datasource="#variables.dsn#">
				update	#variables.DataBaseTableNaming["SubSite_#thisSubSiteID#"].Content_ContentTableName#
					set		flag_CurrentVersion = 0
					where	contentID = #getOldContentID.contentID#
			</cfquery>
			<cfquery name="SetVersionControl1" datasource="#variables.dsn#">
				update	#variables.DataBaseTableNaming["SubSite_#thisSubSiteID#"].Content_ControlTableName#
					set		flag_LiveVersion = 0
					where	contentID = #getOldContentID.contentID#
			</cfquery>
			 --->
		</cfif>
		<!--- then publish the new version --->
		<cfset StructClear(theQueryWhereArguments) />	<!--- get rid of previous data --->
		<cfset StructClear(theQueryDataArguments) />	<!--- get rid of previous data --->
		<!--- set the new published in the content table --->
		<cfset theQueryWhereArguments.contentID = arguments.contentID />
		<cfset theQueryDataArguments.flag_CurrentVersion = 1 />
		<cfset SetVersionContent2 = application.SLCMS.Core.DataMgr.UpdateRecords(tablename="#theContentTableName#", data_set=theQueryDataArguments, data_where=theQueryWhereArguments) />
		<!--- and the control table --->
		<cfset StructClear(theQueryDataArguments) />	<!--- get rid of previous data --->
		<cfset theQueryDataArguments.flag_LiveVersion = 1 />
		<cfset theQueryDataArguments.userID_PublishedBy = arguments.UserID />
		<cfset SetVersionContent2 = application.SLCMS.Core.DataMgr.UpdateRecords(tablename="#theControlTableName#", data_set=theQueryDataArguments, data_where=theQueryWhereArguments) />
		<!--- 
		<cfquery name="SetVersionContent2" datasource="#variables.dsn#">
			update	#variables.DataBaseTableNaming["SubSite_#thisSubSiteID#"].Content_ContentTableName#
				set		flag_CurrentVersion = 1
				where	contentID = #arguments.contentID#
		</cfquery>
		<cfquery name="SetVersionControl2" datasource="#variables.dsn#">
			update	#variables.DataBaseTableNaming["SubSite_#thisSubSiteID#"].Content_ControlTableName#
				set		flag_LiveVersion = 1,
							userID_PublishedBy = #arguments.UserID#
				where	contentID = #arguments.contentID#
		</cfquery>
		 --->
	</cfif>
</cffunction>

<cffunction name="getContainerContentVersions" access="public" output="No" returntype="query" hint="this function gets all versions of content in a container">
	<cfargument name="PageID" type="numeric" default="" hint="DocumentID of the page">
	<cfargument name="ContainerID" type="numeric" default="0" hint="ID of container on page if different content on each page">
	<cfargument name="ContainerName" type="string" default="" hint="name of container if content same on many pages">
	<cfargument name="SubSiteID" type="numeric" required="yes" hint="the ID of the subsite to work with">

	<cfset var theSubSiteID = trim(arguments.SubSiteID) />

	<cfset var theControlTableName = variables.DataBaseTableNaming["SubSite_#theSubSiteID#"].Content_ControlTableName />
	<cfset var theQueryWhereArguments = StructNew() />	<!--- temp struct to compose the where clauses of the SQL query --->
	<cfset var ret = "" />	<!--- the default var to return stuff in, often dumped --->
	<cfset var getVersionContent = "" />	<!--- query to set things --->
	<cfset var verWhereString = "" />	<!--- temp string to compose SQL query --->

	<!--- 	
	<cfdump var="#arguments.ContentControlData#"><cfabort>
 	--->	

	<!--- set the string to find our set of contents --->
	<cfif trim(arguments.containerName) neq "">	
		<cfset theQueryWhereArguments.containerName = arguments.containerName />
		<!--- 
		<cfset verWhereString = "containerName = '#arguments.containerName#'" />
		 --->
	<cfelse>
		<cfset theQueryWhereArguments.containerID = arguments.containerID />
		<!--- 
		<cfset verWhereString = "containerID = #arguments.containerID#" />
		 --->
	</cfif>
	<cfset theQueryWhereArguments.DocID = arguments.PageID />
	<!--- find all the versions for this container --->
	<cfset getVersionContent = application.SLCMS.Core.DataMgr.getRecords(tablename="#theControlTableName#", data=theQueryWhereArguments, fieldList="ContentID,flag_LiveVersion,VersionTimeStamp,UserID_EditedBy,UserID_PublishedBy,Version", OrderBy="VersionTimeStamp desc") />
	<!--- 	 
	 <cfdump var="#getVersionContent#" expand="false">
	 <cfabort>
 	--->	 
	 
	<!--- 
	<cfquery name="getVersionContent" datasource="#variables.dsn#">
		select	ContentID, flag_LiveVersion, VersionTimeStamp, UserID_EditedBy, UserID_PublishedBy, Version
			from	#variables.DataBaseTableNaming["SubSite_#thisSubSiteID#"].Content_ControlTableName#
			where	DocID = #arguments.PageID#
				and	#PreserveSingleQuotes(verWhereString)#
			order by	VersionTimeStamp desc
	</cfquery>
	 --->
	<cfreturn getVersionContent> 
</cffunction>

<cffunction name="saveContainerContent" access="public" output="No" returntype="string" hint="this function saves the content of a container">
	<cfargument name="Content" type="string" required="yes" hint="Content string to be saved">
	<cfargument name="ContentControlData" type="struct" required="yes" hint="structure of control data for this content">
	<cfargument name="UserID" type="string" required="yes" hint="ID of user doing the save">
	<cfargument name="SubSiteID" type="numeric" required="yes" hint="the ID of the subsite to work with">

	<cfset var theSubSiteID = trim(arguments.SubSiteID) />

	<cfset var theControlTableName = variables.DataBaseTableNaming["SubSite_#theSubSiteID#"].Content_ControlTableName />
	<cfset var theContentTableName = variables.DataBaseTableNaming["SubSite_#theSubSiteID#"].Content_ContentTableName />
	<cfset var theQueryDataArguments = StructNew() />	<!--- temp struct to compose the data clauses of the SQL query --->
	<cfset var theQueryWhereArguments = StructNew() />	<!--- temp struct to compose the where clauses of the SQL query --->
	<cfset var ret = "" />	<!--- the default var to return stuff in, often dumped --->
	<cfset var nextContentID = 0 />	<!--- stupid MX, why do I have to do this? --->
	<cfset var SetContentControl = "" />	<!--- query to set things --->
	<cfset var SetVersionContent = "" />	<!--- query to set things --->
	<cfset var SetVersionControl = "" />	<!--- query to set things --->
	<cfset var verWhereString = "" />	<!--- temp string to compose SQL query --->

	<!--- 	
	<cfdump var="#arguments.ContentControlData#"><cfabort>
 	--->	

	<cfif arguments.ContentControlData.contentID neq 0>	<!--- a new page has an ID of zero --->
		<!--- there is existing content so flag it as old version --->
		<cfset theQueryDataArguments.flag_CurrentVersion = 0 />	<!--- data clause of the SQL query --->
		<cfset theQueryWhereArguments.contentID = arguments.ContentControlData.contentID />	<!--- the where clause of the SQL query --->
		<cfset SetVersionContent = application.SLCMS.Core.DataMgr.UpdateRecords(tablename="#theContentTableName#", data_set=theQueryDataArguments, data_where=theQueryWhereArguments) />
		<!--- 
		<cfquery name="SetVersionContent" datasource="#variables.dsn#">
			update	#variables.DataBaseTableNaming["SubSite_#thisSubSiteID#"].Content_ContentTableName#
				set		flag_CurrentVersion = 0
				where	contentID = #arguments.ContentControlData.contentID#
		</cfquery>
		 --->
		<!--- increment the version in this table, but only for the relevant content --->
		<cfset StructClear(theQueryDataArguments) />
		<cfset StructClear(theQueryWhereArguments) />
		<cfif trim(arguments.ContentControlData.containerName) neq "">
			<!--- 	
			<cfset theQueryWhereArguments.containerName = arguments.ContentControlData.containerName />
			 --->
			<cfset verWhereString = "containerName = '#arguments.ContentControlData.containerName#'" />
		<cfelse>
			<!--- 
			<cfset theQueryWhereArguments.contentID = arguments.ContentControlData.containerID />
			 --->
			<cfset verWhereString = "containerID = #arguments.ContentControlData.containerID#" />
		</cfif>
		<!--- 
		<cfset theQueryWhereArguments.DocID = arguments.ContentControlData.DocID />	<!--- the where clause of the SQL query --->
		<cfset SetVersionControl = application.SLCMS.Core.DataMgr.UpdateRecords(tablename="#theControlTableName#", data_set=theQueryDataArguments, data_where=theQueryWhereArguments) />
		 --->
		<cfquery name="SetVersionControl" datasource="#variables.dsn#">
			update	#variables.DataBaseTableNaming["SubSite_#theSubSiteID#"].Content_ControlTableName#
				set		Version = Version+1
				where	DocID = #arguments.ContentControlData.DocID#
					and	#PreserveSingleQuotes(verWhereString)#
		</cfquery>
	</cfif>
	<!--- now get a new contentid and save the content in chunks --->
	<!--- 
	<cfset nextContentID = application.SLCMS.mbc_Utility.Utilities.getNextID("ContentID") />
	 --->
	<cfset nextContentID = Nexts_getNextID("ContentID") />
	<cfset theQueryDataArguments.DocID = arguments.ContentControlData.DocID />
	<cfset theQueryDataArguments.ContainerID = arguments.ContentControlData.ContainerID />
	<cfset theQueryDataArguments.ContainerName = arguments.ContentControlData.containerName />
	<cfset theQueryDataArguments.VersionTimeStamp = Now() />
	<cfset theQueryDataArguments.ContentID = nextContentID />
	<cfset theQueryDataArguments.ContentHandle = arguments.ContentControlData.Handle />
	<cfset theQueryDataArguments.ContentTypeID = arguments.ContentControlData.ContentTypeID />
	<cfset theQueryDataArguments.EditorMode = arguments.ContentControlData.EditorMode />
	<cfset theQueryDataArguments.flag_LiveVersion = 0 />
	<cfset theQueryDataArguments.UserID_EditedBy = arguments.UserID />
	<!--- and save a new control entry --->
	<cfset SetContentControl = application.SLCMS.Core.DataMgr.InsertRecord(tablename="#theControlTableName#", data=theQueryDataArguments) />
	<!--- 
	<cfquery name="SetContentControl" datasource="#variables.dsn#">
		insert into	#variables.DataBaseTableNaming["SubSite_#thisSubSiteID#"].Content_ControlTableName#
							(DocID, ContainerID, 
								ContainerName, VersionTimeStamp, ContentID,
								ContentHandle, ContentTypeID,
								EditorMode, flag_LiveVersion, UserID_EditedBy)
			values	(#arguments.ContentControlData.DocID#, #arguments.ContentControlData.ContainerID#, 
								'#arguments.ContentControlData.containerName#', #Now()#, #nextContentID#,
								'#arguments.ContentControlData.Handle#', #arguments.ContentControlData.ContentTypeID#,
								'#arguments.ContentControlData.EditorMode#', 0, #arguments.UserID#)
	</cfquery>
	 --->
	<!--- then save the content itself --->
	<cfset ret = saveContent(content="#arguments.Content#", ContentID="#nextContentID#", ContentType="#arguments.ContentControlData.ContentTypeID#", SubSiteID="#theSubSiteID#") />
</cffunction>

<!--- this function get the contentid of a shop category --->
<cffunction name="getShopCategoryContentID" access="public" output="No" returntype="struct" hint="gets the ContentID for the specified shop category">
	<cfargument name="CategoryID" type="numeric" default="">
	<cfargument name="SubSiteID" type="numeric" required="yes" hint="the ID of the subsite to work with">

	<cfset var theSubSiteID = trim(arguments.SubSiteID) />
	
	<cfset var ContentControl = StructNew() />	<!--- returned struct of control data --->
	<cfset var getContentID = "" />	<!--- query to get ContentID --->
	<cfset var WhereString = "" />	<!--- temp string to compose SQL query --->
	
	<!--- get the ID for the content --->
	<cfquery name="getContentID" datasource="#variables.dsn#">
		select	ContentID, CategoryID
			from	#request.ShopContentControlTable#
			where	CategoryID = #arguments.CategoryID#
				and	Version = 0
	</cfquery>
	<!--- process according to goodness --->
	<cfif getContentID.RecordCount eq 1>
		<!--- we have a content ID that we can use so return it --->
		<cfset ContentControl.ContentID = getContentID.ContentID />
		<cfset ContentControl.ContainerID = getContentID.CategoryID />
		<cfset ContentControl.Handle = "" />
	<cfelseif getContentID.RecordCount eq 0>
		<!--- flag new content --->
		<cfset ContentControl.CategoryID = 0 />
		<cfset ContentControl.Handle = "" />
	<cfelse>
		<!--- flag error, ie duplicates --->
		<cfset ContentControl.CategoryID = -1 />
		<cfset ContentControl.Handle = "" />
	</cfif>

	<cfreturn ContentControl />
</cffunction>

<!--- this function saves the descriptive content of a shop catalogue item. 
Its treated as a piece of content just like a standard item, blog, whatever --->
<cffunction name="saveShopDescriptiveContent" access="public" output="No" returntype="string">
	<cfargument name="Content" type="string" required="yes">
	<cfargument name="ContentControlData" type="struct" required="yes">
	<cfargument name="SubSiteID" type="numeric" required="yes" hint="the ID of the subsite to work with">

	<cfset var theSubSiteID = trim(arguments.SubSiteID) />

	<cfset var ret = "" />	<!--- the default var to return stuff in, often dumped --->
	<cfset var nextContentID = 0 />	<!--- stupid MX, why do I have to do this? --->
	<cfset var SetContentControl = "" />	<!--- query to set things --->
	<cfset var SetVersionContent = "" />	<!--- query to set things --->
	<cfset var SetVersionControl = "" />	<!--- query to set things --->
	<cfset var verWhereString = "" />	<!--- temp string to compose SQL query --->

	<!--- 	
	<cfdump var="#arguments.ContentControlData#"><cfabort>
	 --->	

	<cfif arguments.ContentControlData.contentID neq 0>	<!--- a new page has an ID of zero --->
		<!--- there is existing content so flag it as old version --->
		<cfquery name="SetVersionContent" datasource="#variables.dsn#">
			update	#variables.DataBaseTableNaming["SubSite_#theSubSiteID#"].Content_ContentTableName#
				set		flag_CurrentVersion = 0
				where	contentID = #arguments.ContentControlData.contentID#
		</cfquery>
		<!--- increment the version in this table, but only for the relevant content --->
		<cfquery name="SetVersionControl" datasource="#variables.dsn#">
			update	#request.ShopContentControlTable#
				set		Version = Version+1
				where	CategoryID = #arguments.ContentControlData.CategoryID#
		</cfquery>
	</cfif>
	<!--- now get a new contentid and save the content in chunks --->
	<!--- 
	<cfset nextContentID = application.SLCMS.mbc_Utility.Utilities.getNextID("ContentID") />
	 --->
	<cfset nextContentID = Nexts_getNextID("ContentID") />
	<!--- and save a new control entry --->
	<cfquery name="SetContentControl" datasource="#variables.dsn#">
		insert into	#request.ShopContentControlTable#
							(CategoryID, VersionTimeStamp, ContentID)
			values	(#arguments.ContentControlData.CategoryID#, #Now()#, #nextContentID#)
	</cfquery>
	<!--- then save the content itself --->
	<cfset ret = saveContent(content="#arguments.Content#", ContentID="#nextContentID#", ContentType="7", SubSiteID="#theSubSiteID#") />
</cffunction>

<!--- this very similar function saves the content of a blog entry --->
<cffunction name="saveBlogContent" access="public" output="No" returntype="string">
	<cfargument name="Content" type="string" required="yes">
	<cfargument name="ContentControlData" type="struct" required="yes">
	<cfargument name="SubSiteID" type="numeric" required="yes" hint="the ID of the subsite to work with">

	<cfset var theSubSiteID = trim(arguments.SubSiteID) />

	<cfset var ret = "" />	<!--- the default var to return stuff in, often dumped --->
	<cfset var nextContentID = 0 />	<!--- stupid MX, why do I have to do this? --->
	<cfset var SetContentControl = "" />	<!--- query to set things --->
	<cfset var SetVersionContent = "" />	<!--- query to set things --->
	<cfset var SetVersionControl = "" />	<!--- query to set things --->
	<!--- 	
	<cfdump var="#arguments.ContentControlData#"><cfabort>
 --->	

	<cfif arguments.ContentControlData.contentID neq 0>	<!--- a new page has an ID of zero --->
		<!--- there is existing content so flag it as old version --->
		<cfquery name="SetVersionContent" datasource="#variables.dsn#">
			update	#variables.DataBaseTableNaming["SubSite_#theSubSiteID#"].Content_ContentTableName#
				set		flag_CurrentVersion = 0
				where	contentID = #arguments.ContentControlData.contentID#
		</cfquery>
		<!--- increment the version in this table, but only for the relevant content --->
		<cfquery name="SetVersionControl" datasource="#variables.dsn#">
			update	#request.BlogContentControlTable#
				set		Version = Version+1
				where	BlogEntryID = #arguments.ContentControlData.EntryID#
		</cfquery>
	</cfif>
	<!--- now get a new contentid and save the content in chunks --->
	<!--- 
	<cfset nextContentID = application.SLCMS.mbc_Utility.Utilities.getNextID("ContentID") />
	 --->
	<cfset nextContentID = Nexts_getNextID("ContentID") />
	<!--- and save a new control entry --->
	<cfquery name="SetContentControl" datasource="#variables.dsn#">
		insert into	#request.BlogContentControlTable#
							(BlogID, BlogCategoryID, 
								BlogEntryID, VersionTimeStamp, 
								ContentID, EntryDate)
			values	(#arguments.ContentControlData.BlogID#, #arguments.ContentControlData.CategoryID#, 
								'#arguments.ContentControlData.EntryID#', #Now()#, 
								#nextContentID#, #CreateODBCDate(arguments.ContentControlData.EntryDate)#)
	</cfquery>
	<!--- then save the content itself --->
	<cfset ret = saveContent(content="#arguments.Content#", ContentID="#nextContentID#", ContentType="2", SubSiteID="#theSubSiteID#") />
	<cfreturn nextContentID />
</cffunction>

<!--- this function takes the supplied string, carves it into 4K chunks and save them in the database content table --->
<cffunction name="saveContent" access="public" output="No" returntype="string">
	<cfargument name="Content" type="string" required="yes">
	<cfargument name="ContentID" type="numeric" required="yes">
	<cfargument name="ContentType" type="numeric" required="yes">
	<cfargument name="SubSiteID" type="numeric" required="yes" hint="the ID of the subsite to work with">

	<cfset var theSubSiteID = trim(arguments.SubSiteID) />

	<cfset var theControlTableName = variables.DataBaseTableNaming["SubSite_#theSubSiteID#"].Content_ControlTableName />
	<cfset var theContentTableName = variables.DataBaseTableNaming["SubSite_#theSubSiteID#"].Content_ContentTableName />
	<cfset var theQueryDataArguments = StructNew() />	<!--- temp struct to compose the data clauses of the SQL query --->
	<cfset var theQueryWhereArguments = StructNew() />	<!--- temp struct to compose the where clauses of the SQL query --->
	<!--- declare all local vars at the beginning because of dumb MX, BD is OK --->
	<cfset var ChunkArray = Arraynew(1) />
	<cfset var ContentLen = "" />
	<cfset var ContentPart = "" />
	<cfset var InsertContent = "" />	<!--- just a hanger for the query --->
	<cfset var lcntr = 0 />
	<cfset var LoopsToDo = 0 />
	<cfset var theContentType = "" />
	<cfset var theContentTable = "" />
	
	<!--- test the content for size and do the 4000 char chunk save thing --->
	<cfset theQueryDataArguments.ContentID = arguments.ContentID />
	<cfset theQueryDataArguments.ContentTypeID = arguments.ContentType />
	<cfset ContentPart = trim(arguments.content) />	<!--- this will shrink as we save 4K chunks --->
	<cfset ContentLen = len(ContentPart) />
	<cfset LoopsToDo = ceiling(ContentLen/4000) />
	<cfloop from="1" to="#LoopsToDo#" index="lcntr">
		<cfset ChunkArray[lcntr] = left(ContentPart, 4000) />
		<cfset ContentPart = removeChars(ContentPart, 1, 4000) />
	</cfloop>
   <!--- and then insert the chunks, however many there are --->
	<cfloop from="1" to="#ArrayLen(ChunkArray)#" index="lcntr">
		<cfset theQueryDataArguments.ContentChunk = ChunkArray[lcntr] />
		<cfset theQueryDataArguments.ContentChunkNumber = lcntr />
		<!--- current version of DataMgr won't let this happen if it is a loop as it complains about PK restrains from the control table
		<cfset InsertContent = application.SLCMS.Core.DataMgr.InsertRecord(tablename="#theContentTableName#", data=theQueryDataArguments) />
		--->
		<cfquery name="InsertContent" datasource="#variables.dsn#">
      INSERT INTO #theContentTableName#
								(ContentID, ContentTypeID, ContentChunk, ContentChunkNumber) 
				values (#arguments.ContentID#, #arguments.ContentType#,'#ChunkArray[lcntr]#',#lcntr#)
 		</cfquery>
		
	</cfloop>
	<!--- that should be it, with the defaults in the DB for the flags, etc --->				

	<cfreturn ContentPart>
	
</cffunction>

<!--- this function uses the supplied data, and returns the content string --->
<cffunction name="getContent" access="public" output="No" returntype="string">
	<cfargument name="ContentID" type="numeric" required="yes">
	<cfargument name="SubSiteID" type="numeric" required="yes" hint="the ID of the subsite to work with">

	<cfset var theSubSiteID = trim(arguments.SubSiteID) />

	<cfset var theContent = "" />	<!--- this will be the final content --->
	<cfset var getTheContent = "" />	<!--- this will hold the content query --->
	<cfset var contentArray = Arraynew(1) />	<!--- intermediate array of content as it is dechunked --->
	<cfset var theContentTable1 = "" />
	<cfset var theContentTableName = "" />	<!--- db table of content --->
	<cfset var theQueryArguments = StructNew() /> <!--- this will be the arguments to feed into DataMgr to get our result --->
	<cfset var lcntr = "" />
	<!--- 	
	<cfif arguments.ContentType eq "Document">
		<cfset theContentTable1 = variables.DataBaseTableNaming["SubSite_#thisSubSiteID#"].Content_ContentTableName />
	<cfelseif arguments.ContentType eq "Blog">
		<cfset theContentTable1 = request.BlogContentTable />
	<cfelse>
		<cfset theContentTable1 = variables.DataBaseTableNaming["SubSite_#thisSubSiteID#"].Content_ContentTableName />
	</cfif>
	 --->	
	<!--- 	
	<cfquery name="getTheContent" datasource="#variables.dsn#">
		select	ContentChunk, ContentChunkNumber
			from	#variables.DataBaseTableNaming["SubSite_#thisSubSiteID#"].Content_ContentTableName#
			where	ContentID = #arguments.ContentID#
	     order by	ContentChunkNumber
	</cfquery>
 --->	 
	<cfset theContentTableName = variables.DataBaseTableNaming["SubSite_#theSubSiteID#"].Content_ContentTableName />
	<cfset theQueryArguments.ContentID = arguments.ContentID /> 
	<cfset getTheContent = application.SLCMS.Core.DataMgr.getRecords(tablename="#theContentTableName#", data=theQueryArguments, orderby="ContentChunkNumber", fieldList="ContentChunk,ContentChunkNumber") />
	<cfif getTheContent.RecordCount eq 1>
		<cfset theContent = getTheContent.ContentChunk />
	<cfelseif getTheContent.RecordCount gt 1>	<!--- many chunks so put them back together --->
		<cfloop query="getTheContent">
			<cfset contentArray[getTheContent.ContentChunkNumber] = getTheContent.ContentChunk />
		</cfloop>
		<cfloop index="lcntr" from="1" to="#ArrayLen(contentArray)#">
			<cfset theContent = theContent & contentArray[lcntr] />
		</cfloop>
	<cfelse>
		<cfset theContent = "" />
	</cfif>
		
	<cfreturn theContent>

</cffunction>

<cffunction name="getVariablesScope"output="No" returntype="struct" access="public"  
	displayname="get Variables"
	hint="gets the specified variables structure or the entire variables scope"
	>
	<cfargument name="Struct" type="string" required="No" default="" hint="struct to return, defaults to 'all'">	
	<cfif len(arguments.Struct) and StructKeyExists(variables, "#arguments.Struct#")>
		<cfreturn variables["#arguments.Struct#"] />
	<cfelse>
		<cfreturn variables />
	</cfif>
</cffunction>

<cffunction name="LogIt" output="No" returntype="struct" access="private"
	displayname="Log It"
	hint="Local Function in every CFC to log info to standard log space via SLCMS_Utility.WriteLog_Core(), minimizes log code in individual functions"
	>
	<cfargument name="LogType" type="string" default="" hint="The log to write to" />
	<cfargument name="LogString" type="string" default="" hint="The string to write to the log" />

	<cfset var theLogType = trim(arguments.LogType) />
	<cfset var theLogString = trim(arguments.LogString) />
	<cfset var temps = StructNew() />	<!--- temp/throwaway structure --->
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorText = "" />
	<cfset ret.error.ErrorContext = "Content_DatabaseIO CFC: LogIt()" />
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
			<cflog text='#ret.error.ErrorText# - ret.error.ErrorCode: #ret.error.ErrorCode# - Time: #DateFormat(Now(),"YYYYMMDD")#-#TimeFormat(now(),"HH:mm:ss")#'  file="#Application.Logging.theSiteLogName#" type="Error" application = "yes">
			<cfif application.SLCMS.Config.debug.debugmode>
				<cfoutput>#ret.error.ErrorContext#</cfoutput> Trapped - error dump:<br>
				<cfdump var="#cfcatch#">
				<cfrethrow />
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
		<cflog text='TakeErrorCatch: Error Catch Caught: #error.ErrorText# - error.ErrorCode: #error.ErrorCode# - Time: #DateFormat(Now(),"YYYYMMDD")#-#TimeFormat(now(),"HH:mm:ss")#'  file="#Application.Logging.theSiteLogName#" type="Error" application = "yes">
		<cfif application.SLCMS.Config.debug.debugmode>
			<cfoutput>#error.ErrorContext#</cfoutput> Trapped - error dump:<br>
			<cfdump var="#arguments.CatchStruct#">
		</cfif>
	</cfcatch>
	</cftry>	
	<cfreturn error  />
</cffunction>

</cfcomponent>