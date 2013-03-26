<!--- mbc CFCs  --->
<!--- &copy; 2011 mort bay communications --->
<!---  --->
<!--- a set of utilities for working with the SLCMS page structure --->
<!--- this is the code that worries about the structure of the pages within the site 
			so this will slowly fill as new things come on stream and old code gets updated
			 --->
<!--- Contains:
			init - set up persistent structures for the site structure, etc
			lots more related stuff :-)
			 --->
<!---  --->
<!--- created:  23rd Apr 2007 by Kym K, mbcomms --->
<!--- Modified   4th Aug 2007 - 13th Aug 2007 by Kym K, mbcomms: working on it --->
<!--- Modified: 19th Aug 2007 - 19th Aug 2007 by Kym K, mbcomms: put back field for URL name so to allow for spaces "  > +" --->
<!--- Modified: 27th Aug 2007 - 28th Aug 2007 by Kym K, mbcomms: changed nav array so each item is a struct to make additions/renaming easier --->
<!--- Modified: 22th Oct 2007 - 26th Oct 2007 by Kym K, mbcomms: adding URL>DocID structure for fast decoding of URLS in content.cfm --->
<!--- Modified: 13th Nov 2007 - 13th Nov 2007 by Kym K, mbcomms: added level to nav structure so menus know what to do with indenting, etc --->
<!--- modified:  1st Dec 2008 -  1st Dec 2008 by Kym K, mbcomms: made it silent, all function outputs --->
<!--- modified: 15th Feb 2009 - 17th Feb 2009 by Kym K, mbcomms: integrating wiki into SLCMS --->
<!--- modified: 22nd Feb 2009 - 22nd Feb 2009 by Kym K, mbcomms: adding code for version control --->
<!--- modified:  3rd Mar 2009 -  3rd Mar 2009 by Kym K, mbcomms: add param4 to give more versatility in shops and galleries --->
<!--- modified: 21st Apr 2009 -  7th May 2009 by Kym K, mbcomms: V2.2, changing folder structure to portal/sub-site architecture, sites inside the top site
																																				this involves creating sets of sites and their databases, structures, etc. --->
<!--- modified:  6th Sep 2009 - 29th Sep 2009 by Kym K, mbcomms: changing to user permissions system and adding portal capacity --->
<!--- modified: 24th Oct 2009 - 25th Oct 2009 by Kym K, mbcomms: refining portal-related code --->
<!--- modified:  5th Nov 2009 -  7th Nov 2009 by Kym K, mbcomms: fixing code trashed by eclipse, reinventing the subSite home page bit and improving serial, now subSite-based --->
<!--- modified: 17th Dec 2009 - 26th Dec 2009 by Kym K, mbcomms: V2.2+ now adding DataMgr as a DAL to make the codebase database agnostic
																																				NOTE: things like the DSN are no longer needed as the DAL knows that
																																							now we can just worry about tables and their contents
																																							See Content_DatabaseIO.cfc for DAL conversion examples (straight queries commented out there, not deleted as here) --->
<!--- modified: 12th Nov 2010 - 12th Nov 2010 by Kym K, mbcomms: adding modules, param2 now has "core" or module name added --->
<!--- modified: 28th Nov 2010 - 28th Nov 2010 by Kym K, mbcomms: added RecodeNavName function --->
<!--- modified: 18th Feb 2011 - 18th Feb 2011 by Kym K, mbcomms: ran varScoper over code and found un-var'd variables! oops :-/  --->
<!--- modified: 20th Feb 2011 - 26th Feb 2011 by Kym K, mbcomms: major change to getDocIDFromURL() to handle SEO paths that are longer than the doc for modules like shops, etc --->
<!--- modified:  7th Jun 2011 - 10th Jun 2011 by Kym K, mbcomms: added logging functions so we can have consistent logging outside CF's logs --->
<!--- modified: 10th Jun 2011 - 19th Jun 2011 by Kym K, mbcomms: improving path decoding for subSites when we have modules in the mix --->
<!--- modified:  9th Apr 2012 -  9th Apr 2012 by Kym K, mbcomms: V3.0, CFWheels version. All SLCMS in own struct under app scope --->

<cfcomponent output="no"
	displayname="Site Page Structure Utilities" 
	hint="contains standard utilities to work with the Page Structure"
	>
	
	<!--- set up a few persistant things on the way in. --->
	<cfset variables.SubSiteIDList_Active = "0" />
	<cfset variables.SubSiteIDList_Full = "0" />
	<cfset variables.DataBaseTableNaming = StructNew() />	
	<!--- we are now possibly a portal site so just set up the top site and let the init worry about the rest --->
	<cfset variables.Site_0 = StructNew() />								<!--- this structure carries the full data Site zero, the portal root site --->
	<cfset variables.Site_0.DocStructure = StructNew() />	<!--- this structure carries the full data for each document, mapped on DocIDs --->
	<cfset variables.Site_0.URLStructure = StructNew() />	<!--- this structure maps url paths to DocIDs --->
	<cfset variables.Site_0.NavArray = ArrayNew(1) />			<!--- this is the array that feeds navigation, it is ordered correctly --->
	<cfset variables.Site_0.DocIdList = "" />								<!--- this is the List of DocIDs on thier own --->
	<cfset variables.Site_0.HomePageDocID = 0 />						<!--- this will be the DocID of the Home Page, whatever is flagged as such in the admin --->
	<cfset variables.Site_0.HomePageDocPath = 0 />					<!--- this will be the path to the Home Page, whatever is flagged as such in the admin --->
	<cfset variables.Site_0.Serial = now()>									<!--- this flags changes that have occurred in the site structure so the sessions can pick up that the structure has been changed --->

<!--- initialize the various thingies, this should only be called after an app scope refresh --->
<cffunction name="init" 
	access="public" output="no" returntype="any" 
	displayname="Initializer"
	hint="sets up the internal structures for this component"
	>
	<cfargument name="DatabaseDetails" type="struct" required="true">	<!--- the structure carrying all the naming bits of the db tables --->
	<!--- 
	<cfargument name="PageStructTable" type="string" default="SLCMS_PageStructure">	<!--- the name of the database table for the site's page structure --->
	<cfargument name="wikiMappingTable" type="string" default="SLCMS_wiki_LabelMapping">	<!--- the name of the database table for the documents --->
	 --->
	
	<cfset temps = LogIt(LogType="CFC_Init", LogString="PageStructure Init() Started") />
	<!--- store our set up data --->
	<!--- the naming regime for the DB tables, almost as versatile as we can get it --->
	<cfset variables.DataBaseTableNaming.Delimiter = arguments.DatabaseDetails.TableNaming_Delimiter />
	<cfset variables.DataBaseTableNaming.Base = arguments.DatabaseDetails.TableNaming_Base />
	<cfset variables.DataBaseTableNaming.SiteMarker = arguments.DatabaseDetails.TableNaming_SiteMarker />
	<cfset variables.DataBaseTableNaming.SystemMarker = arguments.DatabaseDetails.TableNaming_SystemMarker />
	<cfset variables.DataBaseTableNaming.TypeMarker = arguments.DatabaseDetails.TableNaming_TypeMarker />
	<cfset variables.DataBaseTableNaming.PageStructureTable = arguments.DatabaseDetails.PageStructureTable />
	<cfset variables.DataBaseTableNaming.wikiMappingTable = arguments.DatabaseDetails.wikiMappingTable />
	<!--- and precalculate a few bits --->
	<cfset variables.DataBaseTableNaming.PreSiteID = variables.DataBaseTableNaming.Base & variables.DataBaseTableNaming.Delimiter & variables.DataBaseTableNaming.SiteMarker & variables.DataBaseTableNaming.Delimiter />
	<!--- grab a base set of subsites, this can change so these calls happen in some functions as well --->
	<cfset variables.SubSiteIDList_Active = application.SLCMS.Core.PortalControl.GetActiveSubSiteIDList() />
	<cfset variables.SubSiteIDList_Full = application.SLCMS.Core.PortalControl.GetFullSubSiteIDList() />

	<cfset RefreshSiteStructures() />	<!--- Refresh all of the the Site structures --->

	<cfset temps = LogIt(LogType="CFC_Init", LogString="PageStructure Init() Finished") />
	<cfreturn variables.Site_0.NavArray />
</cffunction>

<!--- this first is the equivalent to the init above but just refreshes the data from the database after we have edited same and can be safely called externally --->
<cffunction name="RefreshSiteStructures" output="no" returntype="any" access="public" 
	displayname="Refresh Site Structures"
	hint="refreshes the internal sites structures"
	>
	<cfset var thisSubSite = 0 />
	
	<!--- grab the subsite list in case it has changed --->
	<cfset variables.SubSiteIDList_Active = application.SLCMS.Core.PortalControl.GetActiveSubSiteIDList() />
	<cfset variables.SubSiteIDList_Full = application.SLCMS.Core.PortalControl.GetFullSubSiteIDList() />
	<!--- then refresh everything --->
	<cfset RefreshDocumentStructure() />	<!--- load up the Site structure with the latest data --->
	<cfset ReBuildNavArrays() />	<!--- load up the navigation aspects of the Site structure into a big array set for menu creation, etc --->
	<cfset ReBuildURLStructure() />	<!--- load up the Site structure reverse to nav array, ie from a URL perspective --->
	
	<cfloop list="#variables.SubSiteIDList_Active#" index="thisSubSite">
		<cfset variables["Site_#thisSubSite#"].Serial = now() />				<!--- flag the change in site structure so the sessions can pick up that the structure has been changed --->
	</cfloop>
</cffunction>

<!--- following on from the init are the functions that supply complete sets of data --->
<cffunction name="getFullNavArray" output="no" returntype="array" access="public" 
	displayname="getFullNavArray"
	hint="Returns the full page array from a navigation creation perspective"
	>
	<cfargument name="SubSiteID" default="0" type="Numeric">
		
	<cfreturn variables["Site_#arguments.SubSiteID#"].NavArray />
</cffunction>

<cffunction name="getFullDocStructure" output="no" returntype="Struct" access="public" 
	displayname="get Full Document Structure"
	hint="Returns the full document structure from a DocID perspective"
	>
	<cfreturn variables.DocStructure />
</cffunction>

<!--- the next three relate to a specific document --->
<cffunction name="getHomePageDocID" output="no" returntype="any" access="public" 
	displayname="get DocID of the Home page"
	hint="Returns the DocID of Home Page, takes subsiteID as argument"
	>
	<cfargument name="SubSiteID" default="0" type="Numeric">
	
	<cfreturn variables["Site_#arguments.SubSiteID#"].HomePageDocID />
</cffunction>

<cffunction name="getHomePageDocPath" 
	access="public" output="no" returntype="any" 
	displayname="get path of the Home page"
	hint="Returns the path of Home Page, takes subsiteID as argument"
	>
	<cfargument name="SubSiteID" default="0" type="Numeric">
	
	<cfreturn variables["Site_#arguments.SubSiteID#"].HomePageDocPath />
</cffunction>

<cffunction name="getDocIDfromURL" output="yes" returntype="struct" access="public" 
	displayname="get DocID from supplied URL"
	hint="Returns the DocID from a URL, returns zero if not found. If subsiteID is zero searches all subsites for match as could be a subsite traversed down from top"
	>
	<cfargument name="URLpath" type="string" required="yes" hint="string that is the path to the document">	
	<cfargument name="SubSiteID" type="string" required="no" default="0" hint="ID of the subsite we are in">	
	<cfargument name="CreateWikiPageIfNeeded" type="boolean" required="no" default="False" hint="should we create a page if its a non-existant wiki page">	
	
	<cfset var theSubSiteID = trim(arguments.SubSiteID) />
	<cfset var thePath = trim(arguments.URLpath) />
	<cfset var pathLen = ListLen(thePath,"/") />
	<cfset var TempS = "" />
	<cfset var thisSubSiteID = "" />
	<cfset var thisSubSite_PageStructureTable = "" />
	<cfset var thisSubSite_wikiMappingTable = "" />
	<cfset var SubSiteParents = "" />	<!--- will carry list and structure of the parent docs for subsites in case we are one (lovey english Kym, where did you grow up?) --->
	<cfset var TempPath = "" />
	<cfset var Pathcntr = "" />
	<cfset var tempPathLen = "" />
	<cfset var theQueryDataArguments = StructNew() />	<!--- temp struct to compose the data clauses of SQL queries --->
	<cfset var theQueryWhereArguments = StructNew() />	<!--- temp struct to compose the where clauses of SQL queries --->
	<cfset var getwikiDocID = "" />
	<cfset var setWikiLabel = "" />
	<cfset var getTopDO = "" />
	<cfset var NewDO = "" />
	<cfset var addWikiPage = "" />
	<cfset var ret = StructNew() />	<!--- set return structure --->
	<cfset ret.DocID = 0 />	<!--- set DocID to zero which means no doc found --->
	<cfset ret.DocPath = "" />	<!--- the path to the containing document, might be a subset of the passed in url if we have a module --->
	<cfset ret.SubSiteID = 0 />	<!--- set SubSiteID to zero which means top site --->
	<cfset ret.ContentTypeID = 0 />	<!--- set ContentTypeID to zero which means no contentType, don't know what it is --->
	<cfset ret.ModuleParams = "" />	<!--- this could be the url params that a module wants, those beyond the page itself --->
	<cfset ret.wikiDocID = 0 />	<!--- set wikiID to zero which means no wiki page found or not a wiki --->
	<cfset ret.wikiHomePath = "" />	<!--- this is the path to the home page of the wiki if it is a wiki --->
	<cfset ret.wikiPageName = "" />	<!--- this is the page of the wiki itself --->
	
	<!--- quick error check and do it --->
	<cfif thePath neq "" and IsNumeric(theSubSiteID)>
	
		<cfset TempS = getQuickDocIDfromURL(SubSiteID="#theSubSiteID#", URLpath="#thePath#") />

		<!---				
		<cfdump var="#TempS#" expand="false" label="TempS">
		<cfabort>
		--->		
		<cfset ret.DocID = TempS.docID />
		<cfset ret.DocPath = TempS.DocPath />
		<cfset ret.SubSiteID = TempS.SubSiteID />
		<cfset ret.ModuleParams = TempS.ModuleParams />
		<cfset ret.ContentTypeID = 1 />
		<cfset ret.wikiDocID = ret.DocID /> 	<!--- this is just for neatness for the home page of a wiki, doesn't matter for straight content --->
		<cfset ret.wikiHomePath = thePath />	<!--- ditto --->
		<!---
		<cfif theSubSiteID neq 0 and StructKeyExists(variables["Site_#theSubSiteID#"].URLStructure, "#thePath#")>
			<!--- this is the simplest, a direct find of a DocID --->
			<cfset ret.DocID = variables["Site_#theSubSiteID#"].URLStructure["#thePath#"].docID />
			<cfset ret.ContentTypeID = 1 />
			<cfset ret.SubSiteID = theSubSiteID />
			<cfset ret.wikiDocID = ret.DocID /> 	<!--- this is just for neatness for the home page of a wiki, doesn't matter for straight content --->
			<cfset ret.wikiHomePath = thePath />	<!--- ditto --->
		<cfelseif theSubSiteID eq 0>
			<!--- its the top site so search from top down until found --->
			<cfloop list="#variables.SubSiteIDList_Active#" index="thisSubSiteID">
				<cfif StructKeyExists(variables["Site_#thisSubSiteID#"].URLStructure, "#thePath#")>
					<cfset ret.DocID = variables["Site_#thisSubSiteID#"].URLStructure["#thePath#"].docID />
					<cfset ret.ContentTypeID = 1 />
					<cfset ret.SubSiteID = thisSubSiteID />
					<cfset ret.wikiDocID = ret.DocID />
					<cfset ret.wikiHomePath = thePath />
				</cfif>
			</cfloop>
		<cfelse>
			<!--- not found so flag that --->
			<cfset ret.DocID = 0 />
			<cfset ret.ContentTypeID = 1 />
			<cfset ret.SubSiteID = theSubSiteID />
			<cfset ret.wikiDocID = ret.DocID /> 	<!--- this is just for neatness for the home page of a wiki, doesn't matter for straight content --->
			<cfset ret.wikiHomePath = thePath />	<!--- ditto --->
		</cfif>	<!--- end find docID --->
		--->
		<cfif ret.DocID neq 0 and ret.ModuleParams eq "">
			<!--- we have a straight doc but is it a entry to a subsite? --->
			<cfset SubSiteParents = application.SLCMS.Core.PortalControl.GetSubSiteParentDocIDData() />
			<cfif ListFind(SubSiteParents.ParentDocIDList, ret.DocID)>
				<!--- yes found a match --->
				<cfset ret.SubSiteID = SubSiteParents["DocID_#ret.DocID#"].SubSiteID />
				<cfset ret.DocID = application.SLCMS.Core.PageStructure.getHomePageDocID(SubSiteID=ret.SubSiteID) />
			</cfif>
		<cfelseif ret.DocID neq 0 and ret.ModuleParams neq "">
			<!--- we have a page and it has a module's path appended to the page path so it could be a blog, forum or wiki page or a module --->
			<!--- we are going to treat the wikis as a special case as it can have pages created on the fly, not like normal pages or in modules --->
			<cfif ret.ModuleParams neq "">
			
				<cfset ret.wikiPageName = ret.ModuleParams />
				<cfset ret.wikiHomePath = ret.DocPath />
				<!--- TempPath pointing at the page above where we are so get its DocID like normal --->
				<cfif theSubSiteID eq 0>
					<!--- its the top site so search from top down until found --->
					<cfloop list="#variables.SubSiteIDList_Active#" index="thisSubSiteID">
						<cfif StructKeyExists(variables["Site_#thisSubSiteID#"].URLStructure, "#ret.wikiHomePath#")>
							<cfset ret.DocID = variables["Site_#thisSubSiteID#"].URLStructure["#ret.wikiHomePath#"].docID />	<!--- this is the parent of all the pages in the wiki --->
							<cfset ret.SubSiteID = thisSubSiteID />
							<cfset ret.ContentTypeID = 5 />
						</cfif>
					</cfloop>
				<cfelse>	<!--- we know where to go --->
					<cfif StructKeyExists(variables["Site_#theSubSiteID#"].URLStructure, "#ret.wikiHomePath#")>
						<cfset ret.DocID = variables["Site_#theSubSiteID#"].URLStructure["#ret.wikiHomePath#"].docID />	<!--- this is the parent of all the pages in the wiki --->
						<cfset ret.SubSiteID = theSubSiteID />
						<cfset ret.ContentTypeID = 5 />
					</cfif>
				</cfif>
				<!--- see if we found a parent page and process if so --->
				<cfif ret.DocID neq 0>
					<!--- that bit was easy, now we get the wikiID for the wiki page itself --->
					<cfset thisSubSite_PageStructureTable = variables.DataBaseTableNaming.PreSiteID & theSubSiteID & variables.DataBaseTableNaming.Delimiter & variables.DataBaseTableNaming.PageStructureTable />
					<cfset thisSubSite_wikiMappingTable = variables.DataBaseTableNaming.PreSiteID & theSubSiteID & variables.DataBaseTableNaming.Delimiter & variables.DataBaseTableNaming.wikiMappingTable />
					<cfset theQueryWhereArguments.wikiID = ret.DocID />
					<cfset theQueryWhereArguments.Label = ret.wikiPageName />
					<cfset getwikiDocID = application.SLCMS.Core.DataMgr.getRecords(tablename="#thisSubSite_wikiMappingTable#", data=theQueryWhereArguments, fieldList="DocID") />
					<!--- 
					<cfquery name="getwikiDocID" datasource="#variables.dsn#">
						select	DocID
							from	#thisSubSite_wikiMappingTable#
							where	wikiID = <cfqueryparam cfsqltype="cf_sql_integer" value="#ret.DocID#"> 
								and	Label = <cfqueryparam cfsqltype="cf_sql_varchar" value="#ret.wikiPageName#">
					</cfquery>
					 --->
					<cfif getwikiDocID.RecordCount>
						<cfset ret.wikiDocID = getwikiDocID.DocID />
					<cfelse>
						<!--- this one does not exist so if the system flags "make a page" lets do that --->
						<cfif arguments.CreateWikiPageIfNeeded>
							<!--- we need to make a page so lets do it. We need to create a mapping and then a blank bit of content (code copied from admin create page area) --->
							<!--- it is going to clone the parent so we don't need a lot of the data --->
							<!--- get the new page into the database --->
							<cfset ret.wikiDocID = Nexts_getNextID("DocID") />	<!--- this is our new page --->
							<!--- work out the Display Position, DO --->
							<cfset StructClear(theQueryDataArguments) />
							<cfset StructClear(theQueryWhereArguments) />
							<cfset theQueryDataArguments.select = "select Max(DO) as TopDO" />
							<cfset theQueryWhereArguments.parentID = ret.DocID />
							<cfset getTopDO = application.SLCMS.Core.DataMgr.getRecords(tablename="#thisSubSite_PageStructureTable#", data=theQueryWhereArguments, fieldList="DocID", advsql=theQueryDataArguments) />
							<!--- 
							<cfquery name="getTopDO" datasource="#variables.dsn#">
								select Max(DO) as TopDO 
									from	#thisSubSite_PageStructureTable#
									WHERE	parentID = #ret.DocID#
							</cfquery>
							 --->
							<cfif getTopDO.RecordCount and getTopDO.TopDO neq "">
								<cfset newDO = getTopDO.TopDO+1 /> <!--- stick it at the bottom --->
							<cfelse>
								<cfset newDO = 1 />
							</cfif>
							<!--- set the page in the site structure --->
							<cfset StructClear(theQueryDataArguments) />
							<cfset theQueryDataArguments.NavName = ret.wikiPageName />
							<cfset theQueryDataArguments.URLName = ret.wikiPageName />
							<cfset theQueryDataArguments.URLNameEncoded = EncodeNavName(ret.wikiPageName) />
							<cfset theQueryDataArguments.HasContent = 1 />
							<cfset theQueryDataArguments.IsParent = 0 />
							<cfset theQueryDataArguments.Param1 = "" />
							<cfset theQueryDataArguments.Param2 = "wiki" />
							<cfset theQueryDataArguments.Param3 = "" />
							<cfset theQueryDataArguments.Param4 = "core" />
							<cfset theQueryDataArguments.DocType = 2 />
							<cfset theQueryDataArguments.DocID = ret.wikiDocID />
							<cfset theQueryDataArguments.ParentID = ret.DocID />
							<cfset theQueryDataArguments.DefaultDocID = ret.wikiDocID />
							<cfset theQueryDataArguments.DO = newDO />
							<cfset theQueryDataArguments.IsHomePage = 0 />
							<cfset theQueryDataArguments.Hidden = 0 />
							<cfset addWikiPage = application.SLCMS.Core.DataMgr.InsertRecord(tablename="#thisSubSite_PageStructureTable#", data=theQueryDataArguments) />
							<!--- 
							<cfquery name="addWikiPage" datasource="#variables.dsn#">
								Insert Into	#thisSubSite_PageStructureTable#
														(NavName, URLName, URLNameEncoded, HasContent, IsParent, Param1, Param2, Param3, Param4, DocType,
														DocID, ParentID, DefaultDocID, DO, IsHomePage, Hidden)
									Values		(<cfqueryparam cfsqltype="cf_sql_varchar" value="#ret.wikiPageName#">,
														<cfqueryparam cfsqltype="cf_sql_varchar" value="#ret.wikiPageName#">,
														<cfqueryparam cfsqltype="cf_sql_varchar" value="#EncodeNavName(ret.wikiPageName)#">,
														<cfqueryparam cfsqltype="cf_sql_bit" value="1">,
														<cfqueryparam cfsqltype="cf_sql_bit" value="0">,
														<cfqueryparam cfsqltype="cf_sql_varchar" value="">,
														<cfqueryparam cfsqltype="cf_sql_varchar" value="wiki">,
														<cfqueryparam cfsqltype="cf_sql_varchar" value="">,
														<cfqueryparam cfsqltype="cf_sql_varchar" value="">,
														<cfqueryparam cfsqltype="cf_sql_integer" value="2">, 
														<cfqueryparam cfsqltype="cf_sql_integer" value="#ret.wikiDocID#">, 
														<cfqueryparam cfsqltype="cf_sql_integer" value="#ret.DocID#">, 
														<cfqueryparam cfsqltype="cf_sql_integer" value="#ret.wikiDocID#">, 
														<cfqueryparam cfsqltype="cf_sql_integer" value="#newDO#">, 
														<cfqueryparam cfsqltype="cf_sql_bit" value="0">,
														<cfqueryparam cfsqltype="cf_sql_integer" value="0">
														)
							</cfquery>
							 --->
							<!--- then make our label --->
							<cfset StructClear(theQueryDataArguments) />
							<cfset theQueryDataArguments.Label = ret.wikiPageName />
							<cfset theQueryDataArguments.DocID = ret.wikiDocID />
							<cfset theQueryDataArguments.WikiID = ret.DocID />
							<cfset theQueryDataArguments.DateCreated = Now() />
							<cfset theQueryDataArguments.flag_CurrentLabel = "1" />
							<cfset setWikiLabel = application.SLCMS.Core.DataMgr.InsertRecord(tablename="#thisSubSite_wikiMappingTable#", data=theQueryDataArguments) />
							<!--- 
							<cfquery name="setWikiLabel" datasource="#variables.dsn#">
								Insert into	#thisSubSite_wikiMappingTable#
														(Label, DocID, WikiID, DateCreated, flag_CurrentLabel)
									values		(<cfqueryparam cfsqltype="cf_sql_varchar" value="#ret.wikiPageName#">,
														<cfqueryparam cfsqltype="cf_sql_integer" value="#ret.wikiDocID#">, 
														<cfqueryparam cfsqltype="cf_sql_integer" value="#ret.DocID#">, 
														<cfqueryparam cfsqltype="cf_sql_date" value="#Now()#">,
														<cfqueryparam cfsqltype="cf_sql_bit" value="1">
														)
							</cfquery>
							 --->
						<cfelse>
							<!--- no creation just return a blank --->
							<cfset ret.wikiDocID = 0 />
						</cfif>
					</cfif>
				<cfelse>
					<!--- oops, no page above either, must be seriously dodgy, we don't want to know --->
					<cfset ret.DocID = 0 />
					<cfset ret.SubSiteID = 0 />
					<cfset ret.ContentTypeID = 0 />
					<cfset ret.wikiDocID = 0 />
				</cfif>	<!--- end: docid not zero inside wiki processing --->
			</cfif>	<!--- end: valid path length test --->
		</cfif>	<!--- end: docID eq zero tests --->
	</cfif>
	
	<cfreturn ret />
</cffunction>

<cffunction name="getQuickDocIDfromURL"	output="No" returntype="Struct" access="public" 
	displayname="get Document ID for supplied path"
	hint="Returns a small struct of the DocID, or 0 for not found, the subSite ID (which might have changed if we did a search down from the top), the doc path param and any possible module path params"
	>
	<cfargument name="SubSiteID" type="string" required="no" default="0" hint="ID of the subsite we are in">	
	<cfargument name="URLpath" type="string" required="yes" hint="string that is the URL's path">	
	
	<cfset var loc = StructNew() />	<!--- local vars --->
	<cfset var ret = StructNew() />	<!--- the return data, its a quick() so no error struct, just direct data --->
	<cfset loc.theSubSiteID = trim(arguments.SubSiteID) />
	<cfset loc.thePath = trim(arguments.URLpath) />
	<cfset loc.pathLen = ListLen(loc.thePath,"/") />
	<cfset loc.TempPath = "" />
	<cfset loc.Pathcntr = "" />
	<cfset loc.tempPathLen = "" />
	<cfset loc.thisSubSiteID = "" />
	<cfset ret.DocID = 0 />
	<cfset ret.DocPath = loc.thePath />
	<cfset ret.SubSiteID = 0 />
	<cfset ret.ModuleParams = "" />

	<cfif loc.thePath neq "" and IsNumeric(loc.theSubSiteID)>
		<cfif loc.theSubSiteID neq 0 and StructKeyExists(variables["Site_#loc.theSubSiteID#"].URLStructure, "#loc.thePath#")>
			<!--- this is the simplest, a direct find of a DocID --->
			<cfset ret.DocID = variables["Site_#loc.theSubSiteID#"].URLStructure["#loc.thePath#"].docID />
			<cfset ret.SubSiteID = loc.theSubSiteID />
		<cfelseif loc.theSubSiteID eq 0>
			<!--- its the top site so search across other subSites until found --->
			<cfloop list="#variables.SubSiteIDList_Active#" index="loc.thisSubSiteID">
				<cfif StructKeyExists(variables["Site_#loc.thisSubSiteID#"].URLStructure, "#loc.thePath#")>
					<cfset ret.DocID = variables["Site_#loc.thisSubSiteID#"].URLStructure["#loc.thePath#"].docID />
					<cfset ret.SubSiteID = loc.thisSubSiteID />
				</cfif>
			</cfloop>
		</cfif>	<!--- end find docID --->
		<cfif ret.DocID eq 0>
			<!--- neither of the direct lookups worked so lets see if we have a module or similar --->
			<cfif loc.pathLen gte 2>
				<!--- we have some form of path so lets wind back up it to look for a real page --->
				<!--- we can chop one off straight away as we won't be here in this bit of code if it was a good path --->
				<cfset ret.ModuleParams = ListLast(loc.thePath, "/") />	<!--- we are going to build up the path that belongs to the module and not the doc and hand that back --->
				<cfset loc.tempPath = ListDeleteAt(loc.thePath, loc.pathLen, "/") />
				<cfset loc.tempPathLen = Listlen(loc.thePath, "/") />
				<cfloop from="#loc.tempPathLen#" to="1" index="loc.Pathcntr" step="-1">
					<cfif loc.theSubSiteID neq 0 and StructKeyExists(variables["Site_#loc.theSubSiteID#"].URLStructure, "#loc.tempPath#")>
						<!--- this is the simplest, a direct find of a DocID --->
						<cfset ret.DocID = variables["Site_#loc.theSubSiteID#"].URLStructure["#loc.tempPath#"].docID />
						<cfset ret.SubSiteID = loc.theSubSiteID />
					<cfelseif loc.theSubSiteID eq 0>
						<!--- its the top site so search from top down until found --->
						<cfloop list="#variables.SubSiteIDList_Active#" index="loc.thisSubSiteID">
							<cfif StructKeyExists(variables["Site_#loc.thisSubSiteID#"].URLStructure, "#loc.tempPath#")>
								<cfset ret.DocID = variables["Site_#loc.thisSubSiteID#"].URLStructure["#loc.tempPath#"].docID />
								<cfset ret.SubSiteID = loc.thisSubSiteID />
							</cfif>
						</cfloop>
					</cfif>
					<cfif ret.DocID neq 0>
						<!--- found something so use that --->
						<cfset ret.DocPath = loc.tempPath />
						<cfbreak>	<!--- and out of the loop --->
					<cfelse>
						<!--- still not found so wind back another --->
						<cfset ret.ModuleParams = ListPrepend(ret.ModuleParams, ListLast(loc.tempPath, "/"), "/") />
						<cfset loc.tempPathLen = Listlen(loc.tempPath, "/") />
						<cfif loc.tempPathLen neq 0>	
							<!--- if we have a failed pick up (bad url), we could get here with no hit so we have to stop a nil delete error on the list --->
							<cfset loc.tempPath = ListDeleteAt(loc.tempPath, loc.tempPathLen, "/") />
						</cfif>
					</cfif>
				</cfloop>	<!--- end: loop over path from end to start --->
			<cfelse>
				<!--- too short path so flag that we have no doc --->
				<cfset ret.DocID = 0 />
				<cfset ret.SubSiteID = loc.theSubSiteID />
			</cfif>	<!--- end: long path test --->
		</cfif>	<!--- end find docID out of sub path --->
	</cfif>	<!--- end valid arguments --->

	<cfreturn ret />
</cffunction>

<cffunction name="MakeWikiPage" output="No" returntype="struct" access="public" 
	displayname="get DocID from supplied URL"
	hint="Returns the DocID from a URL, returns zero if not found. If subsiteID is zero searches all subsites for match as could be a subsite traversed down from top"
	>
	<cfargument name="DocID" type="string" required="yes"hint="ID of parent WikiDoc">	
	<cfargument name="WikiPath" type="string" required="yes" hint="string that is the path to the wiki page inside the wiki">	
	<cfargument name="SubSiteID" type="string" required="no" default="0" hint="ID of the subsite we are in">	
	
	<cfset var theDocID = trim(arguments.DocID) />
	<cfset var theSubSiteID = trim(arguments.SubSiteID) />
	<cfset var thePath = trim(arguments.WikiPath) />
	<cfset var pathLen = ListLen(thePath,"/") />
	<cfset var TempS = "" />
	<cfset var thisSubSiteID = "" />
	<cfset var thisSubSite_PageStructureTable = "" />
	<cfset var thisSubSite_wikiMappingTable = "" />
	<cfset var SubSiteParents = "" />	<!--- will carry list and structure of the parent docs for subsites in case we are one (lovey english Kym, where did you grow up?) --->
	<cfset var TempPath = "" />
	<cfset var Pathcntr = "" />
	<cfset var tempPathLen = "" />
	<cfset var theQueryDataArguments = StructNew() />	<!--- temp struct to compose the data clauses of SQL queries --->
	<cfset var theQueryWhereArguments = StructNew() />	<!--- temp struct to compose the where clauses of SQL queries --->
	<cfset var getwikiDocID = "" />
	<cfset var setWikiLabel = "" />
	<cfset var getTopDO = "" />
	<cfset var NewDO = "" />
	<cfset var addWikiPage = "" />
	<cfset var ret = StructNew() />	<!--- set return structure --->
	<cfset ret.DocID = 0 />	<!--- set DocID to zero which means no doc found --->
	<cfset ret.DocPath = "" />	<!--- the path to the containing document, might be a subset of the passed in url if we have a module --->
	<cfset ret.SubSiteID = 0 />	<!--- set SubSiteID to zero which means top site --->
	<cfset ret.ContentTypeID = 0 />	<!--- set ContentTypeID to zero which means no contentType, don't know what it is --->
	<cfset ret.ModuleParams = "" />	<!--- this could be the url params that a module wants, those beyond the page itself --->
	<cfset ret.wikiDocID = 0 />	<!--- set wikiID to zero which means no wiki page found or not a wiki --->
	<cfset ret.wikiHomePath = "" />	<!--- this is the path to the home page of the wiki if it is a wiki --->
	<cfset ret.wikiPageName = "" />	<!--- this is the page of the wiki itself --->
	
	<!--- quick error check and do it --->
	<cfif thePath neq "" and IsNumeric(theSubSiteID) and IsNumeric(theDocID) and theDocID neq 0>
	<!---	
		<cfset TempS = getQuickDocIDfromURL(SubSiteID="#theSubSiteID#", URLpath="#thePath#") />
		
		<cfdump var="#TempS#" expand="false" label="TempS">
		<cfabort>
		
		<cfset ret.DocID = TempS.docID />
		<cfset ret.DocPath = TempS.DocPath />
		<cfset ret.SubSiteID = TempS.SubSiteID />
		<cfset ret.ModuleParams = TempS.ModuleParams />
		<cfset ret.ContentTypeID = 1 />
		<cfset ret.wikiDocID = ret.DocID /> 	<!--- this is just for neatness for the home page of a wiki, doesn't matter for straight content --->
		<cfset ret.wikiHomePath = thePath />	<!--- ditto --->
	--->
		<!---
		<cfif theSubSiteID neq 0 and StructKeyExists(variables["Site_#theSubSiteID#"].URLStructure, "#thePath#")>
			<!--- this is the simplest, a direct find of a DocID --->
			<cfset ret.DocID = variables["Site_#theSubSiteID#"].URLStructure["#thePath#"].docID />
			<cfset ret.ContentTypeID = 1 />
			<cfset ret.SubSiteID = theSubSiteID />
			<cfset ret.wikiDocID = ret.DocID /> 	<!--- this is just for neatness for the home page of a wiki, doesn't matter for straight content --->
			<cfset ret.wikiHomePath = thePath />	<!--- ditto --->
		<cfelseif theSubSiteID eq 0>
			<!--- its the top site so search from top down until found --->
			<cfloop list="#variables.SubSiteIDList_Active#" index="thisSubSiteID">
				<cfif StructKeyExists(variables["Site_#thisSubSiteID#"].URLStructure, "#thePath#")>
					<cfset ret.DocID = variables["Site_#thisSubSiteID#"].URLStructure["#thePath#"].docID />
					<cfset ret.ContentTypeID = 1 />
					<cfset ret.SubSiteID = thisSubSiteID />
					<cfset ret.wikiDocID = ret.DocID />
					<cfset ret.wikiHomePath = thePath />
				</cfif>
			</cfloop>
		<cfelse>
			<!--- not found so flag that --->
			<cfset ret.DocID = 0 />
			<cfset ret.ContentTypeID = 1 />
			<cfset ret.SubSiteID = theSubSiteID />
			<cfset ret.wikiDocID = ret.DocID /> 	<!--- this is just for neatness for the home page of a wiki, doesn't matter for straight content --->
			<cfset ret.wikiHomePath = thePath />	<!--- ditto --->
		</cfif>	<!--- end find docID --->
		--->
	<!---
		<cfif theDocID neq 0 and thePath neq "">
			<!--- we have a straight doc but is it a entry to a subsite? --->
			<cfset SubSiteParents = application.SLCMS.Core.PortalControl.GetSubSiteParentDocIDData() />
			<cfif ListFind(SubSiteParents.ParentDocIDList, ret.DocID)>
				<!--- yes found a match --->
				<cfset ret.SubSiteID = SubSiteParents["DocID_#ret.DocID#"].SubSiteID />
				<cfset ret.DocID = application.SLCMS.Core.PageStructure.getHomePageDocID(SubSiteID=ret.SubSiteID) />
			</cfif>
		<cfelseif ret.DocID neq 0 and ret.ModuleParams neq "">
	--->
			<!--- we have a page and it has a module's path appended to the page path so it could be a blog, forum or wiki page or a module --->
			<!--- we are going to treat the wikis as a special case as it can have pages created on the fly, not like normal pages or in modules --->
			<!---
			<cfif 1 eq 0 and ret.ModuleParams neq "">
				<cfset ret.wikiPageName = ret.ModuleParams />
				<cfset ret.wikiHomePath = ret.DocPath />
				<!--- TempPath pointing at the page above where we are so get its DocID like normal --->
				<cfif theSubSiteID eq 0>
					<!--- its the top site so search from top down until found --->
					<cfloop list="#variables.SubSiteIDList_Active#" index="thisSubSiteID">
						<cfif StructKeyExists(variables["Site_#thisSubSiteID#"].URLStructure, "#ret.wikiHomePath#")>
							<cfset ret.DocID = variables["Site_#thisSubSiteID#"].URLStructure["#ret.wikiHomePath#"].docID />	<!--- this is the parent of all the pages in the wiki --->
							<cfset ret.SubSiteID = thisSubSiteID />
							<cfset ret.ContentTypeID = 5 />
						</cfif>
					</cfloop>
				<cfelse>	<!--- we know where to go --->
					<cfif StructKeyExists(variables["Site_#theSubSiteID#"].URLStructure, "#ret.wikiHomePath#")>
						<cfset ret.DocID = variables["Site_#theSubSiteID#"].URLStructure["#ret.wikiHomePath#"].docID />	<!--- this is the parent of all the pages in the wiki --->
						<cfset ret.SubSiteID = theSubSiteID />
						<cfset ret.ContentTypeID = 5 />
					</cfif>
				</cfif>
				<!--- see if we found a parent page and process if so --->
				<cfif ret.DocID neq 0>
				--->
					<!--- that bit was easy, now we get the wikiID for the wiki page itself --->
					<cfset thisSubSite_PageStructureTable = variables.DataBaseTableNaming.PreSiteID & theSubSiteID & variables.DataBaseTableNaming.Delimiter & variables.DataBaseTableNaming.PageStructureTable />
					<cfset thisSubSite_wikiMappingTable = variables.DataBaseTableNaming.PreSiteID & theSubSiteID & variables.DataBaseTableNaming.Delimiter & variables.DataBaseTableNaming.wikiMappingTable />
					<cfset theQueryWhereArguments.wikiID = theDocID />
					<cfset theQueryWhereArguments.Label = thePath />
					<cfset getwikiDocID = application.SLCMS.Core.DataMgr.getRecords(tablename="#thisSubSite_wikiMappingTable#", data=theQueryWhereArguments, fieldList="DocID") />
					<!--- 
					<cfquery name="getwikiDocID" datasource="#variables.dsn#">
						select	DocID
							from	#thisSubSite_wikiMappingTable#
							where	wikiID = <cfqueryparam cfsqltype="cf_sql_integer" value="#ret.DocID#"> 
								and	Label = <cfqueryparam cfsqltype="cf_sql_varchar" value="#ret.wikiPageName#">
					</cfquery>
					 --->
					<!---
					<cfif getwikiDocID.RecordCount>
						<cfset ret.wikiDocID = getwikiDocID.DocID />
					<cfelse>
						<!--- this one does not exist so if the system flags "make a page" lets do that --->
						<cfif arguments.CreateWikiPageIfNeeded>
					--->	
							<!--- we need to make a page so lets do it. We need to create a mapping and then a blank bit of content (code copied from admin create page area) --->
							<!--- it is going to clone the parent so we don't need a lot of the data --->
							<!--- get the new page into the database --->
							<cfset ret.wikiDocID = Nexts_getNextID("DocID") />	<!--- this is our new page --->
							<!--- work out the Display Position, DO --->
							<cfset StructClear(theQueryDataArguments) />
							<cfset StructClear(theQueryWhereArguments) />
							<cfset theQueryDataArguments.select = "select Max(DO) as TopDO" />
							<cfset theQueryWhereArguments.parentID = ret.DocID />
							<cfset getTopDO = application.SLCMS.Core.DataMgr.getRecords(tablename="#thisSubSite_PageStructureTable#", data=theQueryWhereArguments, fieldList="DocID", advsql=theQueryDataArguments) />
							<!--- 
							<cfquery name="getTopDO" datasource="#variables.dsn#">
								select Max(DO) as TopDO 
									from	#thisSubSite_PageStructureTable#
									WHERE	parentID = #ret.DocID#
							</cfquery>
							 --->
							<cfif getTopDO.RecordCount and getTopDO.TopDO neq "">
								<cfset newDO = getTopDO.TopDO+1 /> <!--- stick it at the bottom --->
							<cfelse>
								<cfset newDO = 1 />
							</cfif>
							<!--- set the page in the site structure --->
							<cfset StructClear(theQueryDataArguments) />
							<cfset theQueryDataArguments.NavName = thePath />
							<cfset theQueryDataArguments.URLName = thePath />
							<cfset theQueryDataArguments.URLNameEncoded = EncodeNavName(thePath) />
							<cfset theQueryDataArguments.HasContent = 1 />
							<cfset theQueryDataArguments.IsParent = 0 />
							<cfset theQueryDataArguments.Param1 = "" />
							<cfset theQueryDataArguments.Param2 = "core,wiki" />
							<cfset theQueryDataArguments.Param3 = "" />
							<cfset theQueryDataArguments.Param4 = "" />
							<cfset theQueryDataArguments.DocType = 2 />
							<cfset theQueryDataArguments.DocID = ret.wikiDocID />
							<cfset theQueryDataArguments.ParentID = theDocID />
							<cfset theQueryDataArguments.DefaultDocID = ret.wikiDocID />
							<cfset theQueryDataArguments.DO = newDO />
							<cfset theQueryDataArguments.IsHomePage = 0 />
							<cfset theQueryDataArguments.Hidden = 0 />
							<cfset addWikiPage = application.SLCMS.Core.DataMgr.InsertRecord(tablename="#thisSubSite_PageStructureTable#", data=theQueryDataArguments) />
							<!--- 
							<cfquery name="addWikiPage" datasource="#variables.dsn#">
								Insert Into	#thisSubSite_PageStructureTable#
														(NavName, URLName, URLNameEncoded, HasContent, IsParent, Param1, Param2, Param3, Param4, DocType,
														DocID, ParentID, DefaultDocID, DO, IsHomePage, Hidden)
									Values		(<cfqueryparam cfsqltype="cf_sql_varchar" value="#ret.wikiPageName#">,
														<cfqueryparam cfsqltype="cf_sql_varchar" value="#ret.wikiPageName#">,
														<cfqueryparam cfsqltype="cf_sql_varchar" value="#EncodeNavName(ret.wikiPageName)#">,
														<cfqueryparam cfsqltype="cf_sql_bit" value="1">,
														<cfqueryparam cfsqltype="cf_sql_bit" value="0">,
														<cfqueryparam cfsqltype="cf_sql_varchar" value="">,
														<cfqueryparam cfsqltype="cf_sql_varchar" value="wiki">,
														<cfqueryparam cfsqltype="cf_sql_varchar" value="">,
														<cfqueryparam cfsqltype="cf_sql_varchar" value="">,
														<cfqueryparam cfsqltype="cf_sql_integer" value="2">, 
														<cfqueryparam cfsqltype="cf_sql_integer" value="#ret.wikiDocID#">, 
														<cfqueryparam cfsqltype="cf_sql_integer" value="#ret.DocID#">, 
														<cfqueryparam cfsqltype="cf_sql_integer" value="#ret.wikiDocID#">, 
														<cfqueryparam cfsqltype="cf_sql_integer" value="#newDO#">, 
														<cfqueryparam cfsqltype="cf_sql_bit" value="0">,
														<cfqueryparam cfsqltype="cf_sql_integer" value="0">
														)
							</cfquery>
							 --->
							<!--- then make our label --->
							<cfset StructClear(theQueryDataArguments) />
							<cfset theQueryDataArguments.Label = ret.wikiPageName />
							<cfset theQueryDataArguments.DocID = ret.wikiDocID />
							<cfset theQueryDataArguments.WikiID = ret.DocID />
							<cfset theQueryDataArguments.DateCreated = Now() />
							<cfset theQueryDataArguments.flag_CurrentLabel = "1" />
							<cfset setWikiLabel = application.SLCMS.Core.DataMgr.InsertRecord(tablename="#thisSubSite_wikiMappingTable#", data=theQueryDataArguments) />
							<!--- 
							<cfquery name="setWikiLabel" datasource="#variables.dsn#">
								Insert into	#thisSubSite_wikiMappingTable#
														(Label, DocID, WikiID, DateCreated, flag_CurrentLabel)
									values		(<cfqueryparam cfsqltype="cf_sql_varchar" value="#ret.wikiPageName#">,
														<cfqueryparam cfsqltype="cf_sql_integer" value="#ret.wikiDocID#">, 
														<cfqueryparam cfsqltype="cf_sql_integer" value="#ret.DocID#">, 
														<cfqueryparam cfsqltype="cf_sql_date" value="#Now()#">,
														<cfqueryparam cfsqltype="cf_sql_bit" value="1">
														)
							</cfquery>
							 --->
				<!---
						<cfelse>
							<!--- no creation just return a blank --->
							<cfset ret.wikiDocID = 0 />
						</cfif>
					</cfif>
				<cfelse>
					<!--- oops, no page above either, must be seriously dodgy, we don't want to know --->
					<cfset ret.DocID = 0 />
					<cfset ret.SubSiteID = 0 />
					<cfset ret.ContentTypeID = 0 />
					<cfset ret.wikiDocID = 0 />
				</cfif>	<!--- end: docid not zero inside wiki processing --->
			</cfif>	<!--- end: valid path length test --->
		</cfif>
				--->
	</cfif>	<!--- end: docID eq zero and valid path length tests --->
	
	<cfreturn ret />
</cffunction>

<cffunction name="getSingleDocStructure" output="no" returntype="Struct" access="public" 
	displayname="get Document Structure for one Document"
	hint="Returns the full document structure for a single DocID"
	>
	<cfargument name="DocID" required="true" default="0">
	<cfargument name="SubSiteID" default="0" type="Numeric">

	<cfset var ret = StructNew() />

	<cfif StructKeyExists(variables["Site_#arguments.SubSiteID#"].DocStructure, arguments.DocID)>
		<cfset ret = variables["Site_#arguments.SubSiteID#"].DocStructure[arguments.DocID] />
	</cfif>
	<cfreturn ret />
</cffunction>

<cffunction name="ReBuildNavArrays" output="no" returntype="string" access="public" 
	displayname="Build Navigation-related Arrays of Site Structure from database"
	hint="refreshes the persistent local nav array from the database and recalculates children, etc"
	>
	<!--- 
		this function gets the site structure from the database. 
		We make it independent (not in the init functions)
		as it will get called by the admin area when the structure is changed
		in the current hybrid architecture
		 --->
	<cfset var ret = "" />
	<cfset var rets = Structnew() />
	<cfset var Success = True />
	<cfset var thisSubSite = "" />
	
	<!--- the site structure is going to be of unknown depth so we will use a re-entrant function to dig it all out --->
	<cfset var ParentLevel = 1 />	<!--- set the parent level so we get all of this level's children --->
	<cfset var ParentArray = ArrayNew(2) />	<!--- set the parent structure so we can add to it --->
	
	<!--- we are going to do this for each subsite so we simply loop over the subsiteIdList --->
	<cfloop list="#variables.SubSiteIDList_Active#" index="thisSubSite">
		<cfset variables["Site_#thisSubSite#"].NavArray = ArrayNew(1) />	<!--- dump the old array and make a new one --->
		<!--- ToDo: code here to pick the parentID for the subsite --->
		<cfset variables["Site_#thisSubSite#"].NavArray = getNavStructureArm(ParentID="0", SubSiteID="#thisSubSite#", ThisLevel="1") />
	</cfloop>
	
	<cfreturn Success />
</cffunction>

<cffunction name="getNavStructureArm" output="no" returntype="any" access="public" 
	displayname="get Nav Structure for one Level or Page and children"
	hint="gets the data for specified arm of the Site Structure and puts into an array which it returns"
	>
	<!--- 
		this function gets an "arm" of the site structure and all below it
		by calling itself in a proper re-entrant fashion
		if called from the top level then it will gather the entire site structure
		 --->
	<cfargument name="ParentID" type="numeric" required="yes" hint="ID of parent folder">	
	<cfargument name="SubSiteID" type="numeric" required="yes" hint="ID of subsite">	
	<cfargument name="ThisLevel" type="numeric" required="yes" hint="Level (depth) we are at">	
	
	<cfset var theLevel = arguments.ThisLevel />
	<cfset var theSubSiteID = arguments.SubSiteID />
	<cfset var thisSubSite_PageStructureTable = variables.DataBaseTableNaming.PreSiteID & theSubSiteID & variables.DataBaseTableNaming.Delimiter & variables.DataBaseTableNaming.PageStructureTable />
	<cfset var setParentChildren = "" />
	<cfset var ret = "" />
	<cfset var reta = ArrayNew(1) />
	<cfset var rets = StructNew() />
	<cfset var loca = ArrayNew(1) />
	<cfset var lcntr = 1 />
	<cfset var theQueryDataArguments = StructNew() />	<!--- temp struct to compose the data clauses of SQL queries --->
	<cfset var theQueryWhereArguments = StructNew() />	<!--- temp struct to compose the where clauses of SQL queries --->
	<cfset var theQueryWhereFilters = ArrayNew(1) />	<!--- temp array to compose the filters for where clauses --->
	<cfset var getThisLevelDocs = "" />	<!--- we need to declare the queries locally as the tag is re-entrant --->
	<cfset var Returner = StructNew() />
	<cfset Returner.Error = StructNew() />
	<cfset Returner.Error.code = 0 />
	<cfset Returner.Error.text = "" />
	<cfset Returner.Data = Structnew() />

	<cfset theQueryWhereArguments.ParentID = arguments.ParentID />	<!--- make up the specialist query we need --->
	<cfset theQueryWhereFilters[1] = {field="hidden", operator="<=", value="127"} />
	<cfset getThisLevelDocs = application.SLCMS.Core.DataMgr.getRecords(tablename="#thisSubSite_PageStructureTable#", data=theQueryWhereArguments, filters=theQueryWhereFilters, fieldList="DocID,DefaultDocID,DO,IsParent,HasContent,IsHomePage,Hidden,ParentID,NavName,URLName,URLNameEncoded,Param2", orderby="DO") />
	<!--- 
	<cfquery name="getThisLevelDocs" datasource="#variables.dsn#">
		select	DocID, DefaultDocID, DO, IsParent, HasContent, IsHomePage, Hidden, ParentID, NavName, URLName, URLNameEncoded, Param2
			from	#thisSubSite_PageStructureTable#
			where	ParentID = #arguments.ParentID#
				and	hidden <= 127
			order by	DO
	</cfquery>
	 --->
	 
	<!--- whatever the record count is for this folder that is the children count for the one above --->
	<cfset theQueryDataArguments.Children = getThisLevelDocs.RecordCount />
	<cfset StructClear(theQueryWhereArguments) />	<!--- clear our temp struct to compose the where clauses of SQL queriesas we have new stuff --->
	<cfset theQueryWhereArguments.DocID = arguments.ParentID />
	<cfset setParentChildren = application.SLCMS.Core.DataMgr.UpdateRecords(tablename="#thisSubSite_PageStructureTable#", data_set=theQueryDataArguments, data_where=theQueryWhereArguments) />
	<!--- 
	<cfquery name="setParentChildren" datasource="#variables.dsn#">
		update	#thisSubSite_PageStructureTable#
			set		Children = #getThisLevelDocs.RecordCount#
			where	DocID = #arguments.ParentID#
				and	hidden <= 127
	</cfquery>
	 --->
	<!--- if we have a touch of doc then make this arm's structure --->
	<cfif getThisLevelDocs.RecordCount>
		<cfset lcntr = 1 />	<!--- reset our counter and do it all again for the documents --->
		<cfloop query="getThisLevelDocs">
			<cfset loca[lcntr] = Structnew() />
			<cfset loca[lcntr].DocID = getThisLevelDocs.DocID />
			<cfset loca[lcntr].ParentID = getThisLevelDocs.ParentID />
			<cfset loca[lcntr].DefaultDocID = getThisLevelDocs.DefaultDocID />
			<cfset loca[lcntr].ThisLevel = theLevel />
			<cfset loca[lcntr].HasContent = getThisLevelDocs.HasContent />
			<cfset loca[lcntr].IsParent = getThisLevelDocs.IsParent />
			<cfset loca[lcntr].Hidden = getThisLevelDocs.Hidden />
			<cfset loca[lcntr].IsHomePage = getThisLevelDocs.IsHomePage />
			<cfset loca[lcntr].NavName = getThisLevelDocs.NavName />
			<cfset loca[lcntr].URLName = getThisLevelDocs.URLName />
			<cfset loca[lcntr].URLNameEncoded = getThisLevelDocs.URLNameEncoded />
			<cfset loca[lcntr].Param2 = getThisLevelDocs.Param2 />
			<cfset loca[lcntr].Expanded = False  />	<!--- this is whether the child array is expanded out, used in the session copy --->
			<cfset loca[lcntr].Children = ArrayNew(1)  />
			<!---  if we have kids then re-enter and do them --->
			<cfif getThisLevelDocs.IsParent neq 0>
				<cfset loca[lcntr].Children = getNavStructureArm(ParentID="#getThisLevelDocs.DocID#", SubSiteID="#theSubSiteID#", ThisLevel="#incrementValue(theLevel)#") />
			</cfif>
			<cfset lcntr = lcntr+1 />
		</cfloop>
	</cfif>

	<cfreturn loca />
</cffunction>

<cffunction name="RebuildURLStructure" output="no" returntype="string" access="public" 
	displayname="refresh Document Structure"
	hint="refreshes the persistent local URLStructure structure from the database"
	>
	<!--- 
		this function gets the site structure from the database and makes a flat URL-biased structure to map URLs to DocIDs. 
		We make it independent (not in the init functions)
		as it will get called by the admin area when the structure is changed
		in the current hybrid architecture
		 --->
	<cfset var ret = "" />
	<cfset var rets = Structnew() />
	<cfset var Success = True />
	<cfset var thisSubSite_PageStructureTable = "" />
	<cfset var thisSubSite = "" />
	<!--- 
	<!--- the site structure is going to be of unknown depth so we will use a re-entrant function to dig it all out --->
	<cfset var ParentLevel = 0 />	<!--- set the parent level so we get all of this level's children --->
	<cfset var ParentStructure = variables.SiteStructure />	<!--- set the parent structure so we can add to it --->
	 --->
	<!--- we are going to do this for each subsite so we simply loop over the subsiteIdList --->
	<cfloop list="#variables.SubSiteIDList_Active#" index="thisSubSite">
		<cfset thisSubSite_PageStructureTable = variables.DataBaseTableNaming.PreSiteID & thisSubSite & variables.DataBaseTableNaming.Delimiter & variables.DataBaseTableNaming.PageStructureTable />
		<cfset variables["Site_#thisSubSite#"].URLStructure = StructNew() />	<!--- trash old struct and start over --->
		<cfset rets = getURLStructureArm(ParentID="0", ParentPath_Pure="", SubSiteID="#thisSubSite#", ParentPath_Padd="") />
	</cfloop>

	<cfreturn Success />
</cffunction>

<cffunction name="getURLStructureArm" output="no" returntype="struct" access="public" 
	displayname="get Document Structure Level"
	hint="gets the data for specified arm of the Site Structure"
	>
	<!--- 
		this function gets an "arm" of the site structure and all below it
		by calling itself in a proper re-entrant fashion
		if called from the top level then it will gather the entire site structure
		 --->
	<cfargument name="ParentID" type="numeric" required="yes" hint="ID of parent folder">	
	<cfargument name="SubSiteID" type="numeric" required="yes" hint="ID of subsite">	
	<cfargument name="ParentPath_Pure" type="string" required="Yes" hint="path to where we are at">	
	<cfargument name="ParentPath_Padd" type="string" required="Yes" hint="path to where we are at">	

	<cfset var theParentID = trim(arguments.ParentID) />
	<cfset var theSubSiteID = arguments.SubSiteID />
	<cfset var thisSubSite_PageStructureTable = variables.DataBaseTableNaming.PreSiteID & theSubSiteID & variables.DataBaseTableNaming.Delimiter & variables.DataBaseTableNaming.PageStructureTable />
	<cfset var theParentPath_Pure = trim(arguments.ParentPath_Pure) />
	<cfset var theParentPath_Padd = trim(arguments.ParentPath_Padd) />
	<cfset var ret = "" />
	<cfset var rets = Structnew() />
	<cfset var NamePure = "" />
	<cfset var NamePadd = "" />
	<cfset var theQueryDataArguments = StructNew() />	<!--- temp struct to compose the data clauses of SQL queries --->
	<cfset var theQueryWhereArguments = StructNew() />	<!--- temp struct to compose the where clauses of SQL queries --->
	<cfset var theQueryWhereFilters = ArrayNew(1) />	<!--- temp array to compose the filters for where clauses --->
	<cfset var getThisLevelDocs = QueryNew("") />
	<cfset var Returner = StructNew() />
	<cfset Returner.Error = StructNew() />
	<cfset Returner.Error.code = 0 />
	<cfset Returner.Error.text = "" />
	<cfset Returner.Data = Structnew() />

	<cfset theQueryWhereArguments.ParentID = theParentID />	<!--- make up the specialist query we need --->
	<cfset theQueryWhereFilters[1] = {field="hidden", operator="<=", value="127"} />
	<cfset getThisLevelDocs = application.SLCMS.Core.DataMgr.getRecords(tablename="#thisSubSite_PageStructureTable#", data=theQueryWhereArguments, filters=theQueryWhereFilters, fieldList="DocID,IsParent,Hidden,ParentID,NavName,URLName,URLNameEncoded") />
	<!--- 
	<cfquery name="getThisLevelDocs" datasource="#variables.dsn#">
		select	DocID, IsParent, Hidden, ParentID, NavName, URLName, URLNameEncoded
			from	#thisSubSite_PageStructureTable#
			where	ParentID = #theParentID#
				and	hidden <= 127
	</cfquery>
	 --->
	<!--- and then fill as appropriate --->
	<cfif getThisLevelDocs.RecordCount>
		<cfloop query="getThisLevelDocs">
			<cfset NamePure = "#theParentPath_Pure#/#getThisLevelDocs.URLName#" />
			<cfset variables["Site_#theSubSiteID#"].URLStructure[NamePure] = StructNew() />
			<cfset variables["Site_#theSubSiteID#"].URLStructure[NamePure].DocID = getThisLevelDocs.DocID />
			<cfset variables["Site_#theSubSiteID#"].URLStructure[NamePure].Hidden = getThisLevelDocs.Hidden />
			<cfset NamePadd = "#theParentPath_Padd#/#getThisLevelDocs.URLNameEncoded#" />
			<cfset variables["Site_#theSubSiteID#"].URLStructure[NamePadd] = StructNew() />
			<cfset variables["Site_#theSubSiteID#"].URLStructure[NamePadd].DocID = getThisLevelDocs.DocID />
			<cfset variables["Site_#theSubSiteID#"].URLStructure[NamePadd].Hidden = getThisLevelDocs.Hidden />
			<!--- simple re-enter if we have children, no ancestry needed as it all goes flat --->
			<cfif getThisLevelDocs.IsParent>
				<cfset ret = getURLStructureArm(ParentID=getThisLevelDocs.DocID, SubSiteID="#theSubSiteID#", ParentPath_Pure="#NamePure#", ParentPath_Padd="#NamePadd#") />
			</cfif>
		</cfloop>
	</cfif>
	
	<cfreturn Returner />
</cffunction>

<cffunction name="RefreshDocumentStructure" output="no" returntype="struct" access="public" 
	displayname="refreshes Document Structure Level"
	hint="refreshes the data for the Site Structure from a DocID perspective"
	>
	<cfset var ret = "" />
	<cfset var rets = Structnew() />
	<cfset var thisSubSite = "" />
	<cfset var thisSubSite_PageStructureTable = "" />
	<cfset var lcntr = 1 />
	<cfset var theQueryDataArguments = StructNew() />	<!--- temp struct to compose the data clauses of SQL queries --->
	<cfset var theQueryWhereArguments = StructNew() />	<!--- temp struct to compose the where clauses of SQL queries --->
	<cfset var theQueryWhereFilters = ArrayNew(1) />	<!--- temp array to compose the filters for where clauses --->
	<cfset var getDocs = QueryNew("") />
	<cfset var Returner = StructNew() />
	<cfset Returner.Error = StructNew() />
	<cfset Returner.Error.code = 0 />
	<cfset Returner.Error.text = "" />
	<cfset Returner.Data = Structnew() />

	<!--- we are going to do this for each subsite so we simply loop over the subsiteIdList --->
	<cfset variables.SubSiteIDList_Active = application.SLCMS.Core.PortalControl.GetActiveSubSiteIDList() />	<!--- update it in case we have added/removed a subsite --->
	<!--- 
	<cfset theQueryWhereArguments.Where = "hidden <= 127" />	<!--- make up the specialist query we need, its the same each time round the loop so set it once --->
	 --->
	<cfset theQueryWhereFilters[1] = {field="hidden", operator="<=", value="127"} />
	<cfloop list="#variables.SubSiteIDList_Active#" index="thisSubSite">
		<cfset thisSubSite_PageStructureTable = variables.DataBaseTableNaming.PreSiteID & thisSubSite & variables.DataBaseTableNaming.Delimiter & variables.DataBaseTableNaming.PageStructureTable />
		<cfset variables["Site_#thisSubSite#"] = StructNew() />	<!--- trash old structure and start over --->
		<cfset variables["Site_#thisSubSite#"].DocStructure = StructNew() />	<!--- trash old structure and start over --->
		<cfset variables["Site_#thisSubSite#"].DocIdList = "" />							<!--- trash old List and start over --->
		<cfset variables["Site_#thisSubSite#"].HomePageDocID = "" />					<!--- trash old HomePage --->
	
		<cfset getDocs = application.SLCMS.Core.DataMgr.getRecords(tablename="#thisSubSite_PageStructureTable#", filters=theQueryWhereFilters, orderby="DocID") />
		<!--- 
		<cfquery name="getDocs" datasource="#variables.dsn#">
			select	*
				from	#thisSubSite_PageStructureTable#
				where	hidden <= 127
				order by DocID
		</cfquery>
		 --->
		<cfloop query="getDocs">
			<cfset variables["Site_#thisSubSite#"].DocStructure[getDocs.DocID] = StructNew()  />
			<cfset variables["Site_#thisSubSite#"].DocStructure[getDocs.DocID].DocID = getDocs.DocID />
			<cfset variables["Site_#thisSubSite#"].DocStructure[getDocs.DocID].NavName = getDocs.NavName />
			<cfset variables["Site_#thisSubSite#"].DocStructure[getDocs.DocID].URLName = getDocs.URLName />
			<cfset variables["Site_#thisSubSite#"].DocStructure[getDocs.DocID].URLNameEncoded = getDocs.URLNameEncoded />
			<cfset variables["Site_#thisSubSite#"].DocStructure[getDocs.DocID].IsHomePage = getDocs.IsHomePage />
			<cfset variables["Site_#thisSubSite#"].DocStructure[getDocs.DocID].Hidden = getDocs.Hidden />
			<cfset variables["Site_#thisSubSite#"].DocStructure[getDocs.DocID].ParentID = getDocs.ParentID />
			<cfset variables["Site_#thisSubSite#"].DocStructure[getDocs.DocID].DefaultDocID = getDocs.DefaultDocID />
			<cfset variables["Site_#thisSubSite#"].DocStructure[getDocs.DocID].DocType = getDocs.DocType />
			<cfset variables["Site_#thisSubSite#"].DocStructure[getDocs.DocID].Param1 = getDocs.Param1 />
			<cfset variables["Site_#thisSubSite#"].DocStructure[getDocs.DocID].Param2 = getDocs.Param2 />
			<cfset variables["Site_#thisSubSite#"].DocStructure[getDocs.DocID].Param3 = getDocs.Param3 />
			<cfset variables["Site_#thisSubSite#"].DocStructure[getDocs.DocID].Param4 = getDocs.Param4 />
			<cfset variables["Site_#thisSubSite#"].DocStructure[getDocs.DocID].HasContent = getDocs.HasContent />
			<cfset variables["Site_#thisSubSite#"].DocStructure[getDocs.DocID].IsParent = getDocs.IsParent />
			<cfset variables["Site_#thisSubSite#"].DocStructure[getDocs.DocID].Children = getDocs.Children />
			<cfset variables["Site_#thisSubSite#"].DocStructure[getDocs.DocID].DO = getDocs.DO  />
			<cfset variables["Site_#thisSubSite#"].DocStructure[getDocs.DocID].SubSiteID = thisSubSite />
			<cfif getDocs.IsHomePage>
				<cfset variables["Site_#thisSubSite#"].HomePageDocID = getDocs.DocID />
				<cfset variables["Site_#thisSubSite#"].HomePageDocPath = getDocs.NavName />	<!--- this is only really valid for subsite home pages --->
			</cfif>
			<cfset variables["Site_#thisSubSite#"].DocIdList = ListAppend(variables["Site_#thisSubSite#"].DocIdList, getDocs.DocID) />
		</cfloop>
		<!--- now we have reloaded everything see if we have a HomePage flagged, 
					if not found set a default one as having none is a bad idea. Grab the first as that is most likely
					 --->
		<cfif variables["Site_#thisSubSite#"].HomePageDocID eq "">
			<cfloop query="getDocs" startrow="1" endrow="1">
				<cfset variables["Site_#thisSubSite#"].HomePageDocID = getDocs.DocID />
			</cfloop>
		</cfif>
	</cfloop>
	<cfreturn Returner />
</cffunction>

<!--- this function runs at init time to get the URL-biased nav structure --->
<cffunction name="ReBuildNavStructures" output="no" returntype="struct" access="public" 
	displayname="ReBuild Navigation Structures"
	hint="Builds the URL-biased nav structure, enter URL, return DocID"
	>

	<cfset var thisDoc = "" />
	<cfset var NamePure = "" />
	<cfset var NamePadd = "" />
	<cfset var rets = Structnew() />
	<cfset var Returner = Structnew() />	<!--- the standard structure for returning function calls --->
	<cfset Returner.Error = Structnew() /><!--- two returns, an error structure and data, assumed to be a struct but could be anything --->
	<cfset Returner.Error.code = 0 />
	<cfset Returner.Error.text = "" />
	<cfset Returner.Data = Structnew() />	<!--- data return, assumed to be a struct but can be anything --->


	<cfloop collection="#variables.docStructure#" item="thisDoc">
		<cfset NamePure = variables.docStructure[thisDoc].URLName />
		<cfset NamePadd = variables.docStructure[thisDoc].URLNameEncoded />
		<cfset variables.URLStructure[NamePure] = variables.docStructure[thisDoc].DocID />
		<cfset variables.URLStructure[NamePadd] = variables.docStructure[thisDoc].DocID />
	</cfloop>

	<cfreturn Returner />
</cffunction>

<cffunction name="getSerial" output="No" returntype="date" access="public" 
	displayname="get Serial"
	hint="gets the serial number to compare for structure changes"
	>
	<cfargument name="SubSiteID" default="0" type="Numeric">

	<cfif StructKeyExists(variables, "Site_#arguments.SubSiteID#")>
		<cfreturn variables["Site_#arguments.SubSiteID#"].Serial />
	<cfelse>
		<cfreturn Now() />
	</cfif>
</cffunction>

<cffunction name="getDocIdList" output="No" returntype="string" access="public" 
	displayname="get DocID List"
	hint="get list of DocIDs"
	>
	<cfargument name="SubSiteID" default="0" type="Numeric">

	<cfreturn variables["Site_#arguments.SubSiteID#"].DocIdList />
</cffunction>

<!--- this function is a utility for admin/code-debug, etc --->
<cffunction name="getSiteStruct" output="no" returntype="struct" access="public" 
	displayname="get Variables"
	hint="gets the entire variables scope including the various forms of the navigation structure or specified variables structure"
	>
	<cfargument name="SiteNumber" type="string" required="No" default="0" hint="site to return, defaults to 0 for site zero that always exists">	

	<cfif len(arguments.Struct) and StructKeyExists(variables, "Site_#arguments.Struct#")>
		<cfreturn variables["Site_#arguments.Struct#"] />
	<cfelse>
		<cfreturn variables.Site_0 />
	</cfif>
</cffunction>

<!--- this function is a utility for SEO URL paths --->
<cffunction name="EncodeNavName" output="no" returntype="string" access="public" 
	displayname="Encode Navigation Name"
	hint="replaces space with + and escapes other illegal filename ones"
	>
	<!---  --->
	<cfargument name="NavName" type="string" required="yes" hint="string to encode">	
	<cfargument name="SkipSlashes" type="boolean" required="no" default="False" hint="skip encoding slashes if its a path">	

	<cfset var ret = arguments.NavName />								<!--- return variable --->
	<cfset ret = replace(ret, "^", "^5E", "all") />	<!--- escape our flag char first --->
	<cfset ret = replace(ret, "!", "^21", "all") />
	<cfset ret = replace(ret, "##", "^23", "all") />
	<cfset ret = replace(ret, "%", "^25", "all") />
	<cfset ret = replace(ret, "&", "^26", "all") />
	<cfset ret = replace(ret, "*", "^2A", "all") />
	<cfset ret = replace(ret, "+", "^2B", "all") />
	<cfif not arguments.skipslashes>
		<cfset ret = replace(ret, "/", "^2F", "all") />
	</cfif>
	<cfset ret = replace(ret, "?", "", "all") />	<!--- ? are right out --->
	<cfset ret = replace(ret, " ", "+", "all") />

	<cfreturn Ret />
</cffunction>

<!--- this function is a utility for SEO URL paths --->
<cffunction name="DecodeNavName" output="no" returntype="string" access="public" 
	displayname="Encode Navigation Name"
	hint="replaces encoded/escaped chars with originals"
	>
	<!---  --->
	<cfargument name="NavName" type="string" required="yes" hint="string to decode">	

	<cfset var ret = arguments.NavName />								<!--- return variable --->
	<cfset ret = replace(ret, "^21", "!", "all") />
	<cfset ret = replace(ret, "^23", "##", "all") />
	<cfset ret = replace(ret, "^25", "%", "all") />
	<cfset ret = replace(ret, "^26", "&", "all") />
	<cfset ret = replace(ret, "^2A", "*", "all") />
	<cfset ret = replace(ret, "^2B", "+", "all") />
	<cfset ret = replace(ret, "^2F", "/", "all") />
	<cfset ret = replace(ret, "^3F", "?", "all") />
	<cfset ret = replace(ret, "^5E", "^", "all") />
	<cfset ret = replace(ret, "+", " ", "all") />

	<cfreturn Ret />
</cffunction>

<!--- this function is a utility for SEO URL paths --->
<cffunction name="RecodeNavName" output="no" returntype="string" access="public" 
	displayname="Rencode Navigation Name"
	hint="decodes an encoded nav name and re-encodes"
	>
	<!---  --->
	<cfargument name="NavName" type="string" required="yes" hint="string to decode">	
	<cfargument name="SkipSlashes" type="boolean" required="no" default="False" hint="skip encoding slashes if its a path">	

	<cfset var ret = EncodeNavName(NavName=DecodeNavName(arguments.NavName), SkipSlashes=arguments.SkipSlashes) />								<!--- return variable --->

	<cfreturn Ret />
</cffunction>

<!--- this function returns the breadcrumb/path back to site root for a doc --->
<cffunction name="getFixedBreadcrumb" output="No" returntype="Struct" access="public" 
	displayname=""
	hint=""
	>
	<cfargument name="DocID" type="string" required="yes" hint="ID of doc to return">	
	<cfargument name="SubSiteID" type="string" required="yes" hint="subSiteID of doc">	

	<cfset var theDocID = trim(arguments.DocID) />	<!--- the doc we want to work up from --->
	<cfset var theSubSiteID = trim(arguments.subSiteID) />	<!--- the doc we want to work up from --->
	<cfset var tempID = trim(arguments.DocID) />								<!--- two standard return variables for local function calls, etc --->
	<cfset var ret = "" />								<!--- two standard return variables for local function calls, etc --->
	<cfset var lcntr = 0 />								<!--- localise first loop counter --->
	<cfset var bcntr = 1 />								<!--- localise 2nd loop counter --->
	<cfset var temp1a = ArrayNew(1) />								<!--- two standard return variables for local function calls, etc --->
	<cfset var rets = Structnew() />
	<cfset var Returner = StructNew() />	<!--- returning function call, no error checking --->
	<cfset Returner.detail = ArrayNew(1) />	<!--- an array for the full details --->
	<cfset Returner.URLpath = "" />	<!--- a path ready for use in links --->
	<cfset Returner.NamePath = "" />	<!--- a path ready to show to people --->


	<!--- we have to work from the bottom up from the DocID as we can't trust the URL path
				so the array is backwards first off, then we flip it --->
	<cfset tempID = theDocID />								<!--- two standard return variables for local function calls, etc --->
	<cfloop from="1" to="99" index="lcntr">
		<cfset rets = getSingleDocStructure(DocID="#tempID#", SubSiteID="#theSubSiteID#") />
		<cfif not StructIsEmpty(rets)>
			<cfset temp1a[lcntr] = StructNew() />
			<cfset temp1a[lcntr].DocID = rets.DocID />
			<cfset temp1a[lcntr].NavName = rets.NavName />
			<cfset temp1a[lcntr].URLName = rets.URLName />
			<cfset temp1a[lcntr].URLNameEncoded = rets.URLNameEncoded />
			<cfset temp1a[lcntr].Hidden = rets.Hidden />
			<cfset temp1a[lcntr].IsParent = rets.IsParent />
			<cfset temp1a[lcntr].HasContent = rets.HasContent />
			<cfset temp1a[lcntr].ParentID = rets.ParentID />
			<cfset tempID = rets.ParentID />	<!--- step up one level --->
		<cfelse>
			<cfset tempID = 0 />	<!--- empty struct returned so nothing there, hop out --->
		</cfif>		
			<cfif tempID eq 0><cfbreak></cfif>
	</cfloop>
	<!--- now we copy it across the right way round --->
	<cfloop from="#ArrayLen(temp1a)#" to="1" step="-1" index="lcntr">
		<cfset Returner.detail[bcntr] = temp1a[lcntr] />
		<cfset bcntr = bcntr+1 />
		<cfset Returner.URLpath = Returner.URLpath & "/" &temp1a[lcntr].URLNameEncoded  />		
		<cfset Returner.NamePath = Returner.NamePath & "/" & temp1a[lcntr].NavName />		
	</cfloop>
	<!--- 
	<cfset Returner.URLpath = "/" & Returner.URLpath />		
	<cfset Returner.NamePath = "/" & Returner.NamePath />		
	 --->
	<cfreturn Returner />
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
	<cfset ret.error.ErrorContext = "PageStructure CFC: LogIt()" />
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