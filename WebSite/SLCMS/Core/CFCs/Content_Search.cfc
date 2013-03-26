<!--- mbc CFCs  --->
<!--- &copy; 2008 mort bay communications --->
<!---  --->
<!--- a set of utilities for working with the SLCMS site structure --->
<!--- this is the tool set to do searching,  
			the actual collection management and querying
			 --->
<!--- Contains:
			init - set up persistent structures for the collections, etc
			 --->
<!---  --->
<!--- created:  28th Mar 2008 by Kym K --->
<!--- modified: 28th Mar 2008 - 28th Mar 2008 by Kym K, mbcomms: did initial stuff --->
<!--- modified:  1st Dec 2008 -  1st Dec 2008 by Kym K, mbcomms: made it silent, all function outputs --->
<!--- modified: 19th Nov 2009 - 28th Nov 2009 by Kym K, mbcomms: V2.2+ now multiple subSites so more collections, etc --->
<!--- modified: 18th Feb 2011 - 18th Feb 2011 by Kym K, mbcomms: ran varScoper over code and found un-var'd variables! oops :-/  --->
<!--- modified:  7th Jun 2011 - 19th Jun 2011 by Kym K, mbcomms: added logging functions so we can have consistent logging outside CF's logs --->
<!--- modified: 20th Mar 2012 - 21st Mar 2012 by Kym K, mbcomms: added contentID option to update method to enable update of single block of content --->
<!--- modified:  9th Apr 2012 -  9th Apr 2012 by Kym K, mbcomms: V3.0, CFWheels version. All SLCMS in own struct under app scope --->

<cfcomponent output="no"
	displayname="Site Search Utilities" 
	hint="contains standard utilities to work with the Site Se"
	>
	
	<!--- set up a few persistant things on the way in. --->
	<cfset variables.ContentTypeList = "Body,File" />	<!--- the legitimate type of content we build collections for --->
	<cfset variables.CollectionsPath = "" />
	<cfset variables.Names = StructNew() />	
	<cfset variables.Names.DataBase = StructNew() />	
	<cfset variables.Names.Collections = StructNew() />	
	<cfset variables.Paths = StructNew() />	<!--- all the prefixes and suffixes of the paths concatenated from their component parts --->
	<cfset variables.Sites = StructNew() />	<!--- struct of subsites --->
	<cfset variables.Names.SiteName = "" />
	<cfset variables.SiteStructure = StructNew() />	
	<cfset variables.SubSiteIdList = "" />

<!--- initialize the various thingies, this should only be called after an app scope refresh --->
<cffunction name="init" output="yes" returntype="struct" access="public" 
	displayname="Initializer"
	hint="sets up the internal structures for this component, creates collections if they don't exist"
	>
	<cfargument name="config" type="struct" required="yes">	<!--- the config structure that has almost all we need to look after all of the collections --->

	<cfset var theApplicationConfig = arguments.config />	<!--- carries the config stuff --->
	<cfset var theExistingCollections = "" />	<!--- will be the query --->
	<cfset var theExistingCollectionList = "" />	<!--- will be the resulting list --->
	<cfset var theSubSites = application.SLCMS.Core.PortalControl.GetAllSubSites() />	<!--- temp grab the full subsite set so we can get their folder names, etc --->
	<cfset var thisSubsite = "" />
	<cfset var thisSubsiteID = 0 />
	<cfset var thisType = 0 />
	<cfset var SiteConfigVars = "" />
	<cfset var rets = Structnew() />
	<cfset var ret = Structnew() />
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorContext = "Content Search CFC: init()" />
	<cfset ret.error.ErrorText = "" />
	<cfset ret.error.ErrorExtra = "" />
	<cfset ret.Data = StructNew() />	<!--- and no data yet --->
	
	<cfset temps = LogIt(LogType="CFC_Init", LogString="ContentSearch I/O Started") />
	<cftry>
		<!--- get the list of existing collections for testing against the ones we need --->
		<cfcollection action="list" name="theExistingCollections">
		<cfset theExistingCollectionList = ValueList(theExistingCollections.Name) />
		
		<!--- first off grab the list of subSites so we can mind all of them --->
		<cfset variables.SubSiteIdList = application.SLCMS.Core.PortalControl.GetActiveSubSiteIDList() />
		<!--- then build the name strings we need for the collection names and database tables --->
		<cfset variables.Names.SiteName = theApplicationConfig.base.SiteAbbreviatedname />
		<cfset variables.Names.DataBase.dsn = theApplicationConfig.Datasources.cms />
		<cfset variables.Names.DataBase.TableNaming_Site_Prefix = 
						theApplicationConfig.DatabaseDetails.TableNaming_Base 
					& theApplicationConfig.DatabaseDetails.TableNaming_Delimiter
					& theApplicationConfig.DatabaseDetails.TableNaming_SiteMarker
					& theApplicationConfig.DatabaseDetails.TableNaming_Delimiter />
		<cfset variables.Names.DataBase.TableNaming_PageStructure_Suffix = 
						theApplicationConfig.DatabaseDetails.TableNaming_Delimiter 
					& theApplicationConfig.DatabaseDetails.PageStructureTable />
		<cfset variables.Names.DataBase.TableNaming_ContentTable_Suffix = 
						theApplicationConfig.DatabaseDetails.TableNaming_Delimiter 
					& theApplicationConfig.DatabaseDetails.ContentTable />
		<cfset variables.Names.DataBase.TableNaming_DocContentControlTable_Suffix = 
						theApplicationConfig.DatabaseDetails.TableNaming_Delimiter 
					& theApplicationConfig.DatabaseDetails.DocContentControlTable />
		<cfset variables.Names.Collections.CollectionNaming_Site_Prefix = 
						theApplicationConfig.DatabaseDetails.TableNaming_Base 
					& theApplicationConfig.DatabaseDetails.TableNaming_Delimiter
					& variables.Names.SiteName
					& theApplicationConfig.DatabaseDetails.TableNaming_Delimiter
					& theApplicationConfig.DatabaseDetails.TableNaming_SiteMarker
					& theApplicationConfig.DatabaseDetails.TableNaming_Delimiter />
		<!--- then the physical/URL paths to things to search docs and the like --->
		<!--- build the prefixes and suffixes --->
		<cfset variables.Paths.CollectionsPath = theApplicationConfig.StartUp.CollectionsPath />
		<cfset variables.Paths.DocumentPhysicalPath_Prefix = theApplicationConfig.StartUp.SiteBasePath & theApplicationConfig.base.SitesBaseRelPath />
		<cfset variables.Paths.DocumentPhysicalPath_Suffix = theApplicationConfig.base.ResourcesFileRelPath />
		<cfset variables.Paths.DocumentURLPath_Prefix = theApplicationConfig.base.rootURL & theApplicationConfig.base.SitesBaseRelPath />
		<cfset variables.Paths.DocumentURLPath_Suffix = theApplicationConfig.base.ResourcesFileRelPath />
		<!--- we need to strip off our trailing slashes as Verity gets confused --->
		<cfif right(variables.Paths.DocumentPhysicalPath_Suffix,1) eq "\">
			<cfset variables.Paths.DocumentPhysicalPath_Suffix = removeChars(variables.Paths.DocumentPhysicalPath_Suffix, len(variables.Paths.DocumentPhysicalPath_Suffix)-1, 1) />
		</cfif>
		<cfif right(variables.Paths.DocumentURLPath_Suffix,1) eq "\">
			<cfset variables.Paths.DocumentURLPath_Suffix = removeChars(variables.Paths.DocumentURLPath_Suffix, len(variables.Paths.DocumentURLPath_Suffix)-1, 1) />
		</cfif>
		<!--- then make the full paths for each subSite --->
		<!--- loopy thing here, time for a coffee break to get my head into gear, 
					ouch! I got a double shot from the new barrista, now I'm going to write some mean code!!! --->
		<!--- 					
					<cfdump var="#theExistingCollectionList#" expand="false">
					<cfabort>
		 ---> 		
		<cfsetting requesttimeout="360" />	<!--- make sure we have time to set up all of the collections --->
		<cfloop collection="#theSubSites#" item="thisSubsite">
			<cfset thisSubsiteID = theSubSites["#thisSubsite#"].subSiteID />	<!--- firstly get the subSiteID --->
			<cfset variables.Sites["subSite_#thisSubsiteID#"] = StructNew() />	<!--- then save the needed data for Ron --->
			<cfset variables.Sites["subSite_#thisSubsiteID#"].subSiteID = thisSubsiteID />
			<cfset variables.Sites["subSite_#thisSubsiteID#"].subSiteShortName = theSubSites["#thisSubsite#"].subSiteShortName />
			<!--- now we build the full paths and things --->
			<cfset variables.Sites["subSite_#thisSubsiteID#"].DocumentPhysicalPath = 
							variables.Paths.DocumentPhysicalPath_Prefix 
						& variables.Sites["subSite_#thisSubsiteID#"].subSiteShortName
						& "/"
						&	variables.Paths.DocumentPhysicalPath_Suffix />
			<cfset variables.Sites["subSite_#thisSubsiteID#"].DocumentURLPath = 
							variables.Paths.DocumentURLPath_Prefix 
						& variables.Sites["subSite_#thisSubsiteID#"].subSiteShortName
						& "/"
						&	variables.Paths.DocumentURLPath_Suffix />
			<!--- build the final names, do it as a loop so we can add content types later --->
			<cfloop list="#variables.ContentTypeList#" index="thisType">
			<cfset variables.Sites["subSite_#thisSubsiteID#"]["#thisType#ContentCollection"] = structNew() />
			<cfset variables.Sites["subSite_#thisSubsiteID#"]["#thisType#ContentCollection"].Name = 
							variables.Names.Collections.CollectionNaming_Site_Prefix
						&	thisSubsiteID
						& theApplicationConfig.DatabaseDetails.TableNaming_Delimiter
						&	"#thisType#Content" />
			<cfset variables.Sites["subSite_#thisSubsiteID#"].ContentTable = 
							variables.Names.DataBase.TableNaming_Site_Prefix
						&	thisSubsiteID
						& variables.Names.DataBase.TableNaming_ContentTable_Suffix />
			<cfset variables.Sites["subSite_#thisSubsiteID#"].DocContentControlTable = 
							variables.Names.DataBase.TableNaming_Site_Prefix
						&	thisSubsiteID
						& variables.Names.DataBase.TableNaming_DocContentControlTable_Suffix />
				<!--- check to see if we have a set of search collections for this subsite --->
				<cfif not ListFindNoCase(theExistingCollectionList, variables.Sites["subSite_#thisSubsiteID#"]["#thisType#ContentCollection"].Name)>
					<cfcollection action="create" collection="#variables.Sites['subSite_#thisSubsiteID#']["#thisType#ContentCollection"].Name#" path="#variables.Paths.CollectionsPath#" />
					<cfset rets = RefreshCollection(name="#thisType#", subSiteID="#thisSubsiteID#") />
				</cfif>
<!--- 
			<cfif not ListFindNoCase(theExistingCollectionList, variables.Sites["subSite_#thisSubsiteID#"].bodyContentCollectionName)>
				<cfcollection action="create" collection="#variables.Sites['subSite_#thisSubsiteID#'].bodyContentCollectionName#" path="#variables.Paths.CollectionsPath#" />
				<cfset rets = RefreshCollection(name="Body", subSiteID="#thisSubsiteID#") />
			</cfif>
			<cfif not ListFindNoCase(theExistingCollectionList, variables.Sites["subSite_#thisSubsiteID#"].DocumentContentCollectionName)>
				<cfcollection action="create" collection="#variables.Sites['subSite_#thisSubsiteID#'].DocumentContentCollectionName#" path="#variables.Paths.CollectionsPath#" />
				<cfset rets = RefreshCollection(name="Doc", subSiteID="#thisSubsiteID#") />
			</cfif>
 --->
			</cfloop>
			
			<!--- 
			<cfset SiteConfigVars = StructNew() />
			<cfset SiteConfigVars.bodyContentCollectionName = "#variables.SiteName#_BodyContent" />
			<cfset SiteConfigVars.DocContentCollectionName = "#variables.SiteName#_DocContent" />
			<cfset SiteConfigVars.bodyContentExists = False />
			<cfset SiteConfigVars.DocContentExists = False />
			<cfloop query="SiteConfigVars.CollectionList">
				<cfif SiteConfigVars.CollectionList.name eq SiteConfigVars.bodyContentCollectionName>
					<cfset SiteConfigVars.bodyContentExists = True />
				</cfif>
				<cfif SiteConfigVars.CollectionList.name eq SiteConfigVars.DocContentCollectionName>
					<cfset SiteConfigVars.DocContentExists = True />
				</cfif>
			</cfloop>
			<!--- create the ones that are not there --->
			<cfif not SiteConfigVars.bodyContentExists>
				<cfcollection action="create" collection="#variables.Sites['subSite_#thisSubsiteID#'].bodyContentCollectionName#" path="#variables.Paths.CollectionsPath#" />
				<!--- and make sure they are all up-to-date --->
				<cfset rets = RefreshCollection(name="Body") />
			</cfif>
			<cfif not SiteConfigVars.DocContentExists>
				<cfcollection action="create" collection="#variables.Sites['subSite_#thisSubsiteID#'].DocumentContentCollectionName#" path="#variables.Paths.CollectionsPath#" />
				<cfset rets = RefreshCollection(name="Doc") />
			</cfif>
			 --->
		<!--- 			
					<cfdump var="#rets#">
		 --->			
		</cfloop>
	
	<cfcatch type="any">
		<cfset ret.error = TakeErrorCatch(RetErrorStruct=ret.error, CatchStruct=cfcatch) />
	</cfcatch>
	</cftry>
	
	<cfset temps = LogIt(LogType="CFC_Init", LogString="ContentSearch I/O Finished") />
	<cfreturn variables.SiteStructure />
</cffunction>

<!--- this function creates a collection --->
<cffunction name="CreateCollection" output="No" returntype="struct" access="public" 
	displayname="Create Collection"
	hint="creates specified Collection"
	>
	<!---  --->
	<cfargument name="Name" type="string" required="yes" hint="name of Collection">	
	<cfargument name="SubSiteID" type="numeric" required="yes" hint="ID of subSite Collection is for">	

	<cfset var theName = trim(arguments.Name) />	<!--- the name that we use to derive the actual collection name --->
	<cfset var theSubSiteID = trim(arguments.SubSiteID) />	<!--- the subSite where the collection lives --->
	<cfset var theSubSiteIDList = application.SLCMS.Core.PortalControl.GetFullSubSiteIDList() />	<!--- a list of all the subSites so we can check that we are calling a legit one --->
	<cfset var theCollections = "" />									<!--- localise --->
	<cfset var theCollectionName = "" />									<!--- localise --->
	<cfset var CollectionExists = False />
	<cfset var ret = Structnew() />	<!--- the standard structure for returning function calls --->
	<cfset ret.Error = Structnew() /><!--- two returns, an error structure and data, assumed to be a struct but could be anything --->
	<cfset ret.Error.Errorcode = 0 />
	<cfset ret.error.ErrorContext = "Content Search CFC: CreateCollection()" />
	<cfset ret.error.ErrorText = "" />
	<cfset ret.error.ErrorExtra = "" />
	<cfset ret.Data = Structnew() />	<!--- data return, assumed to be a struct but can be anything --->

	<cftry>
		<cfif ListFindNoCase(variables.ContentTypeList, theName) and ListFindNoCase(theSubSiteIDList, theSubSiteID)>
			<cfset theCollectionName = variables.Sites["subSite_#theSubsiteID#"]["#theName#ContentCollection"].Name />	<!--- set the actual name of the collection --->
			<!--- see if it exists already --->
			<cfcollection action="list" name="theCollections">
			<cfloop query="theCollectionList">
				<cfif theCollections.name eq theCollectionName>
					<cfset CollectionExists = True />
				</cfif>
			</cfloop>
		<!--- create if not there --->
			<cfif not CollectionExists>
				<cfcollection action="create" collection="#theCollectionName#" path="#variables.Paths.CollectionsPath#" />
			<cfelse>
				<cfset Ret.Error.ErrorCode = 2 />
				<cfset Ret.Error.ErrorText = Ret.Error.ErrorText & "The Collection for #theName# already existed" />
			</cfif>
		<cfelse>
			<cfset Ret.Error.ErrorCode = 1 />
			<cfset Ret.Error.ErrorText = Ret.Error.ErrorText & "Invalid Collection Name or subSiteID Supplied" />
		</cfif>
	<cfcatch type="any">
		<cfset ret.error = TakeErrorCatch(RetErrorStruct=ret.error, CatchStruct=cfcatch) />
	</cfcatch>
	</cftry>

	<cfreturn Ret />
</cffunction>

<!--- this function creates a collection --->
<cffunction name="DeleteCollection" output="No" returntype="struct" access="public" 
	displayname="Delete Collection"
	hint="Delete specified Collection"
	>
	<!---  --->
	<cfargument name="Name" type="string" required="yes" hint="name of Collection">	
	<cfargument name="SubSiteID" type="numeric" required="yes" hint="ID of subSite Collection is for">	

	<cfset var theName = trim(arguments.Name) />	<!--- the name that we use to derive the actual collection name --->
	<cfset var theSubSiteID = trim(arguments.SubSiteID) />	<!--- the subSite where the collection lives --->
	<cfset var theSubSiteIDList = application.SLCMS.Core.PortalControl.GetFullSubSiteIDList() />	<!--- a list of all the subSites so we can check that we are calling a legit one --->
	<cfset var theCollections = "" />									<!--- localise --->
	<cfset var theCollectionName = "" />									<!--- localise --->
	<cfset var CollectionExists = False />
	<cfset var ret = Structnew() />	<!--- the standard structure for returning function calls --->
	<cfset ret.Error = Structnew() /><!--- two returns, an error structure and data, assumed to be a struct but could be anything --->
	<cfset ret.Error.Errorcode = 0 />
	<cfset ret.error.ErrorContext = "Content Search CFC: DeleteCollection()" />
	<cfset ret.error.ErrorText = "" />
	<cfset ret.error.ErrorExtra = "" />
	<cfset ret.Data = Structnew() />	<!--- data return, assumed to be a struct but can be anything --->

	<cftry>
		<cfif ListFindNoCase(variables.ContentTypeList, theName) and ListFindNoCase(theSubSiteIDList, theSubSiteID)>
			<cfset theCollectionName = variables.Sites["subSite_#theSubsiteID#"]["#theName#ContentCollection"].Name />	<!--- set the actual name of the collection --->
			<!--- see if it exists already --->
			<cfcollection action="list" name="theCollections">
			<cfloop query="theCollections">
				<cfif theCollections.name eq theCollectionName>
					<cfset CollectionExists = True />
				</cfif>
			</cfloop>
		<!--- create the ones that are not there --->
			<cfif CollectionExists>
				<cfcollection action="delete" collection="#theCollectionName#" />
			<cfelse>
				<cfset Ret.Error.ErrorCode = 2 />
				<cfset Ret.Error.ErrorText = Ret.Error.ErrorText & "The Collection for #theName# didn't exist" />
			</cfif>
		<cfelse>
			<cfset Ret.Error.ErrorCode = 1 />
			<cfset Ret.Error.ErrorText = Ret.Error.ErrorText & "Invalid Collection Name Supplied" />
		</cfif>
	<cfcatch type="any">
		<cfset ret.error = TakeErrorCatch(RetErrorStruct=ret.error, CatchStruct=cfcatch) />
	</cfcatch>
	</cftry>

	<cfreturn Ret />
</cffunction>

<!--- this function refreshes a collection --->
<cffunction name="RefreshCollection" output="No" returntype="struct" access="public" 
	displayname="Refresh Collection"
	hint="purges and reUpdates specified Collection"
	>
	<!---  --->
	<cfargument name="Name" type="string" required="yes" hint="name of Collection">	
	<cfargument name="SubSiteID" type="numeric" required="yes" hint="ID of subSite Collection is for">	

	<cfset var theName = trim(arguments.Name) />	<!--- the name that we use to derive the actual collection name --->
	<cfset var theSubSiteID = trim(arguments.SubSiteID) />	<!--- the subSite where the collection lives --->
	<cfset var theSubSiteIDList = application.SLCMS.Core.PortalControl.GetFullSubSiteIDList() />	<!--- a list of all the subSites so we can check that we are calling a legit one --->
	<cfset var theCollectionName = "" />									<!--- localise --->
	<cfset var getContent = "" />	
	<cfset var ret = Structnew() />	<!--- the standard structure for returning function calls --->
	<cfset ret.Error = Structnew() /><!--- two returns, an error structure and data, assumed to be a struct but could be anything --->
	<cfset ret.Error.Errorcode = 0 />
	<cfset ret.error.ErrorContext = "Content Search CFC: RefreshCollection()" />
	<cfset ret.error.ErrorText = "" />
	<cfset ret.error.ErrorExtra = "" />
	<cfset ret.Data = Structnew() />	<!--- data return, assumed to be a struct but can be anything --->

	<cftry>
		<cfif ListFindNoCase(variables.ContentTypeList, theName) and ListFindNoCase(theSubSiteIDList, theSubSiteID)>
			<cfset theCollectionName = variables.Sites["subSite_#theSubsiteID#"]["#theName#ContentCollection"].Name />	<!--- set the actual name of the collection --->
			<cfif theName eq "File">
				<!--- we are going to update from the physical file set --->
				<cftry>
					<cfindex collection="#theCollectionName#"
				  	action="refresh" type="path" key="#variables.Sites['subSite_#theSubsiteID#'].DocumentPhysicalPath#" urlpath="#variables.Sites['subSite_#theSubsiteID#'].DocumentURLPath#"
				  	extensions=".*" recurse="true"
						>
				<cfcatch type="searchengine">
					<cfset Ret.Error.ErrorCode = 2 />
					<cfset Ret.Error.ErrorText = Ret.Error.ErrorText & "Document Collection Refresh Failed, message was: #cfcatch.message#" />
					<cflog text='#ret.error.ErrorText# - ret.error.ErrorCode: #ret.error.ErrorCode# - Time: #DateFormat(Now(),"YYYYMMDD")#-#TimeFormat(now(),"HH:mm:ss")#'  file="#Application.Logging.theSiteLogName#" type="Error" application = "yes">
				</cfcatch>
				</cftry>
			<cfelseif theName eq "Body">
				<!--- we are going to update from the body content --->
				<cfquery name="getContent" datasource="#variables.Names.DataBase.dsn#">
					select	dbt.ContentChunk as Content, dct.DocID, dct.VersionTimeStamp
						from	#variables.Sites["subSite_#theSubsiteID#"].ContentTable# dbt, #variables.Sites["subSite_#theSubsiteID#"].DocContentControlTable# dct
						where	dbt.ContentID = dct.ContentID
							and	dbt.flag_CurrentVersion = 1
							and	dct.Version = 0
							and	dbt.ContentTypeID = 1
				</cfquery>
				<cftry>
					<cfindex collection="#theCollectionName#"
				  	action="refresh" type="Custom" query="getContent" key="DocID"
				  	title="Content" body="Content" custom1="VersionTimeStamp"
						>
				<cfcatch type="searchengine">
					<cfset Ret.Error.ErrorCode = 2 />
					<cfset Ret.Error.ErrorText = Ret.Error.ErrorText & "Collection Refresh Failed" />
				</cfcatch>
				</cftry>
			</cfif>
		<cfelse>
			<cfset Ret.Error.ErrorCode = 1 />
			<cfset Ret.Error.ErrorText = Ret.Error.ErrorText & "Invalid Collection Name Supplied" />
		</cfif>
	<cfcatch type="any">
		<cfset ret.error = TakeErrorCatch(RetErrorStruct=ret.error, CatchStruct=cfcatch) />
	</cfcatch>
	</cftry>

	<cfreturn Ret />
</cffunction>

<!--- this function updates a collection --->
<cffunction name="UpdateCollection" output="No" returntype="struct" access="public" 
	displayname="Update Collection"
	hint="Updates specified Collection"
	>
	<cfargument name="Name" type="string" required="yes" hint="name of Collection">	
	<cfargument name="Item" type="string" required="no" default="" hint="item to be added: filename or docid depending on collection name">	
	<cfargument name="ContentID" type="numeric" required="no" default="" hint="ContentID when updating a single content block">	
	<cfargument name="SubSiteID" type="numeric" required="yes" hint="ID of subSite Collection is for">	

	<cfset var theName = trim(arguments.Name) />	<!--- the name that we use to derive the actual collection name --->
	<cfset var theItem = trim(arguments.Item) />	<!--- the item to add in --->
	<cfset var theContentID = trim(arguments.ContentID) />	<!--- ContentID of the item to add in --->
	<cfset var theSubSiteID = trim(arguments.SubSiteID) />	<!--- the subSite where the collection lives --->
	<cfset var theSubSiteIDList = application.SLCMS.Core.PortalControl.GetFullSubSiteIDList() />	<!--- a list of all the subSites so we can check that we are calling a legit one --->
	<cfset var getContent = "" />									<!--- localise --->
	<cfset var ThreadAttributes = Structnew() />	<!--- the standard structure for returning function calls --->
	<cfset var Ret = Structnew() />	<!--- the standard structure for returning function calls --->
	<cfset ret.Error = Structnew() /><!--- two returns, an error structure and data, assumed to be a struct but could be anything --->
	<cfset ret.Error.Errorcode = 0 />
	<cfset ret.error.ErrorContext = "Content Search CFC: UpdateCollection()" />
	<cfset ret.error.ErrorText = "" />
	<cfset ret.error.ErrorExtra = "" />
	<cfset ret.Data = Structnew() />	<!--- data return, assumed to be a struct but can be anything --->
	<cfset ThreadAttributes.CollectionName = "" />	<!--- stuff we are going to pass to the thread --->
	<cfset ThreadAttributes.DocPath = "" />					
	<cfset ThreadAttributes.theItem = theItem />					
	<cfset ThreadAttributes.urlPath = variables.Sites['subSite_#theSubsiteID#'].DocumentURLPath />
	<cfset ThreadAttributes.ContentTable = variables.Sites["subSite_#theSubsiteID#"].ContentTable />
	<cfset ThreadAttributes.DocContentControlTable = variables.Sites["subSite_#theSubsiteID#"].DocContentControlTable />
	<cfset ThreadAttributes.ContentID = theContentID />					


	<cftry>
		<cfif ListFindNoCase(variables.ContentTypeList, theName) and ListFindNoCase(theSubSiteIDList, theSubSiteID) and (len(theItem) or (len(theContentID) and IsNumeric(theContentID)))>
			<cfset ThreadAttributes.CollectionName = variables.Sites["subSite_#theSubsiteID#"]["#theName#ContentCollection"].Name />	<!--- set the actual name of the collection --->
			<cfset ThreadAttributes.CollectionSubName = theName />
			<cfset ThreadAttributes.DocPath = "#variables.Sites['subSite_#theSubsiteID#'].DocumentPhysicalPath#\#theItem#" />
			<cfthread name="UpdateCollection_#theName#" action="run" priority="LOW" attributeCollection="#ThreadAttributes#">
<!---
 				<cflog file="SLCMS_ThreadErrors" text="UpdateCollection() Thread Started. CollectionSubName=#CollectionSubName#, ContentID=#ContentID#, theItem=#theItem#" type="information" >
--->
				<cfif CollectionSubName eq "File">
					<!--- we are going to update from the physical file set --->
					<cftry>
						<cfindex collection="#CollectionName#"
					  	action="update" type="file" key="#DocPath#" urlpath="#urlPath#"
							>
					<cfcatch type="searchengine">
		  			<cflog file="SLCMS_ThreadErrors" text="UpdateCollection() File Index caught" type="error">
					</cfcatch>
					</cftry>
				<cfelseif CollectionSubName eq "Body">
					<!--- we are going to update from the body content --->
					<cfif len(ContentID)>
						<cfquery name="getContent" datasource="#variables.Names.DataBase.dsn#">
							select	dbt.ContentChunk as Content, dct.DocID, dct.VersionTimeStamp
								from	#ContentTable# dbt, #DocContentControlTable# dct
								where	dbt.ContentID = dct.ContentID
									and	dbt.flag_CurrentVersion = 1
									and	dct.Version = 0
									and	dbt.ContentTypeID = 1
									and	dct.ContentID = #ContentID#
						</cfquery>
	  			<cfelse>
						<cfquery name="getContent" datasource="#variables.Names.DataBase.dsn#">
							select	dbt.ContentChunk as Content, dct.DocID, dct.VersionTimeStamp
								from	#ContentTable# dbt, #DocContentControlTable# dct
								where	dbt.ContentID = dct.ContentID
									and	dbt.flag_CurrentVersion = 1
									and	dct.Version = 0
									and	dbt.ContentTypeID = 1
									and	dct.DocID = #theItem#
						</cfquery>
					</cfif>
					<cftry>
						<cfindex collection="#CollectionName#"
					  	action="update" type="Custom" query="getContent" key="DocID"
					  	title="Content" body="Content" custom1="VersionTimeStamp"
							>
					<cfcatch type="searchengine">
		  			<cflog file="SLCMS_ThreadErrors" text="UpdateCollection() Body Index caught" type="error">
					</cfcatch>
					</cftry>
				</cfif>
			</cfthread>
		<cfelse>
			<cfset Ret.Error.ErrorCode = 1 />
			<cfset Ret.Error.ErrorText = Ret.Error.ErrorText & "Invalid Collection Name Supplied" />
		</cfif>
	<cfcatch type="any">
		<cfset ret.error = TakeErrorCatch(RetErrorStruct=ret.error, CatchStruct=cfcatch) />
	</cfcatch>
	</cftry>

	<cfreturn Ret />
</cffunction>

<!--- this function updates a collection --->
<cffunction name="SearchCollection" output="No" returntype="query" access="public" 
	displayname="Search Collection"
	hint="Searches specified Collection"
	>
	<!---  --->
	<cfargument name="Name" type="string" required="yes" hint="name of Collection">	
	<cfargument name="SearchTerm" type="string" required="yes" hint="search term to apply">	
	<cfargument name="SubSiteID" type="numeric" required="yes" hint="ID of subSite Collection is for">	

	<cfset var theName = trim(arguments.Name) />	<!--- the name that we use to derive the actual collection name --->
	<cfset var theItem = trim(arguments.SearchTerm) />	<!--- the item to search on --->
	<cfset var theSubSiteID = trim(arguments.SubSiteID) />	<!--- the subSite where the collection lives --->
	<cfset var theSubSiteIDList = application.SLCMS.Core.PortalControl.GetFullSubSiteIDList() />	<!--- a list of all the subSites so we can check that we are calling a legit one --->
	<cfset var search_results = queryNew("key,title,context,score,url,size,rank") />	<!--- an empty query to return just in case --->
	<cfset var theCollectionName = "" />									<!--- localise --->
	<cfset var Ret = Structnew() />	<!--- the standard structure for returning function calls --->
	<cfset ret.Error = Structnew() /><!--- two returns, an error structure and data, assumed to be a struct but could be anything --->
	<cfset ret.Error.Errorcode = 0 />
	<cfset ret.error.ErrorContext = "Content Search CFC: SearchCollection()" />
	<cfset ret.error.ErrorText = "" />
	<cfset ret.error.ErrorExtra = "" />
	<cfset ret.Data = Structnew() />	<!--- data return, assumed to be a struct but can be anything --->

	<cftry>
		<cfif ListFindNoCase(variables.ContentTypeList, theName) and ListFindNoCase(theSubSiteIDList, theSubSiteID)>
			<cfset theCollectionName = variables.Sites["subSite_#theSubsiteID#"]["#theName#ContentCollection"].Name />	<!--- set the actual name of the collection --->
			<cfsearch  collection="#theCollectionName#" name = "search_results"
				criteria = "#theItem#" contextPassages = "1" contextBytes = "200" maxrows = "100"
				>
		<cfelse>
			<cfset Ret.Error.ErrorCode = 1 />
			<cfset Ret.Error.ErrorText = Ret.Error.ErrorText & "Invalid Collection Name Supplied" />
		</cfif>
	<cfcatch type="any">
		<cfset ret.error = TakeErrorCatch(RetErrorStruct=ret.error, CatchStruct=cfcatch) />
	</cfcatch>
	</cftry>

	<cfreturn search_results />
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
	<cfset ret.error.ErrorContext = "Content_Search CFC: LogIt()" />
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