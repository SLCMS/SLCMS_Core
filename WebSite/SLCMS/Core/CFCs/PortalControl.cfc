<!--- mbc SLCMS CFCs  --->
<!--- &copy; 2009 mort bay communications --->
<!---  --->
<!--- PortalControl.cfc  --->
<!--- Handles Portal related functions --->
<!--- Contains:
			init - set up persistent structures for the site styling, etc but in application scope so the diplay tags can grab easily
			lots more related stuff :-)
			LogIt() - sends supplied info to global logging engine - private function
			TakeErrorCatch() - common handler for try/catch logging - private function
			 --->
<!---  --->
<!--- created:   1st Apr 2009 by Kym K, mbcomms --->
<!--- modified:  1st Apr 2009 - 23rd Apr 2009 by Kym K, mbcomms: initial work on it --->
<!--- modified:  6th Sep 2009 -  6th Sep 2009 by Kym K, mbcomms: adding portal parent Doc capacity --->
<!--- modified:  2nd Oct 2009 -  2nd Oct 2009 by Kym K, mbcomms: added allowedSubSites functions --->
<!--- modified: 30th Oct 2009 - 30th Oct 2009 by Kym K, mbcomms: added HomeURL for whatever, sessions, etc. --->
<!--- modified:  4th Nov 2009 -  4th Nov 2009 by Kym K, mbcomms: updating to make sure we have a common parent domain and subbies for consistent sessions for logged in users --->
<!--- modified: 16th Dec 2009 - 16th Dec 2009 by Kym K, mbcomms: V2.2+ now adding DataMgr as a DAL to make the codebase database agnostic
																																				NOTE: things like the DSN are no longer needed as the DAL knows that
																																							now we can just worry about tables and their contents
																																							See Content_DatabaseIO.cfc for DAL conversion examples (straight queries commented out there, not deleted as here) --->
<!--- modified:  6th Jun 2010 -  6th Jun 2010 by Kym K, mbcomms: changed DataMgr method to deleteRecords (plural) in setSubSiteParentage to allow for empty table/PK issue --->
<!--- modified: 13th Nov 2010 - 13th Nov 2010 by Kym K, mbcomms: ditto for clearSubSiteParentage to allow for empty table/PK issue --->
<!--- modified: 31st Dec 2010 - 31st Dec 2010 by Kym K, mbcomms: added GetQuickSubSiteFriendlyName() as we want just the friendly name for display on its own too often --->
<!--- modified: 10th Feb 2011 - 10th Feb 2011 by Kym K, mbcomms: added GetQuickSubSiteShortName() ditto to grab the folder name for URL path generation --->
<!--- modified: 18th Feb 2011 - 18th Feb 2011 by Kym K, mbcomms: ran varScoper over code and found un-var'd variables! oops :-/  --->
<!--- modified:  7th Jun 2011 -  8th Jun 2011 by Kym K, mbcomms: added logging functions so we can have consistent logging outside CF's logs --->
<!--- modified: 10th Jun 2011 - 19th Jun 2011 by Kym K, mbcomms: improving path decoding for subSites when we have modules in the mix --->
<!--- modified:  9th Apr 2012 -  9th Apr 2012 by Kym K, mbcomms: V3.0, CFWheels version. All SLCMS in own struct under app scope --->

<cfcomponent displayname="Portal Control" hint="Handles Portal functions, subsite control, etc" output="false">
	
	<!--- set up a few persistant things on the way in. --->
	<cfset variables.ParentDocsToSubSites = StructNew() />	<!--- struct of parent Docs and which subsite live in each --->
	<cfset variables.ParentDocsToSubSites.ParentDocIDList = "" />	<!--- list of parent Docs --->
	<cfset variables.PortalControlTable = "" />
	<cfset variables.PortalURLTable = "" />
	<cfset variables.PortalParentDocTable = "" />
	<cfset variables.PortalEnabled = False />	<!--- flag for whether this is a portal site --->
	<cfset variables.PortalHomeURL = "" />	<!--- this will get filled with the base URL for site_0 --->
	<cfset variables.SubSiteCount = 0 />		
	<cfset variables.SubSiteIDList_Active = "" />
	<cfset variables.SubSiteIDList_Full = "" />
	<cfset variables.SubSiteShortNameList = "" />
	<cfset variables.Sites = StructNew() />	<!--- struct of subsites --->
	<cfset variables.URLs = StructNew() />	<!--- struct of the URLs of subsites, ie the above inside out --->

<!--- initialize the various thingies, this should only be called after an app scope refresh --->
<cffunction name="init" 
	access="public" output="No" returntype="any" 
	displayname="Initializer"
	hint="sets up the internal structures for this component"
	>
	<cfargument name="PortalControlTable" type="string" default="" />
	<cfargument name="PortalParentDocTable" type="string" default="" />
	<cfargument name="PortalURLTable" type="string" default="" />

	<cfset var getTopSiteURLs = "" />	<!--- temp query --->
	<cfset var setTopSiteURL = "" />	<!--- temp query --->
	<cfset var temp = "" />	<!--- temp/throwaway var --->
	<cfset var theBaseDomainName = application.SLCMS.Config.base.BaseDomainName />	<!--- for calculating a root url if we need one --->
	<cfset var theQueryDataArguments = StructNew() />	<!--- temp struct to compose the data clauses of SQL queries --->
	<cfset var theQueryWhereArguments = StructNew() />	<!--- temp struct to compose the where clauses of SQL queries --->
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorText = "" />
	<cfset ret.error.ErrorContext = "PortalControl CFC: Init()" />
	<cfset ret.error.ErrorExtra = "" />
	<cfset ret.Data = False />	<!---  --->

	<cfset temps = LogIt(LogType="CFC_Init", LogString="PortalControl Init() Started") />

	<cfset variables.PortalControlTable = trim(arguments.PortalControlTable) />
	<cfset variables.PortalParentDocTable = trim(arguments.PortalParentDocTable) />
	<cfset variables.PortalURLTable = trim(arguments.PortalURLTable) />

	<!--- see if this is the first time run, if so there will not be a root url for the portal/top site --->
	<cfset theQueryWhereArguments.SubSiteID = 0 />
	<cfset getTopSiteURLs = application.SLCMS.Core.DataMgr.getRecords(tablename="#variables.PortalControlTable#", data=theQueryWhereArguments, fieldList="BaseURL") />
	<cfif getTopSiteURLs.RecordCount eq 0>
		<!--- nothing there so add in the default data from the config ini file --->
		<cfif application.SLCMS.Config.base.BasePort neq "" and application.SLCMS.Config.base.BasePort neq "80">
			<cfset theBaseDomainName = theBaseDomainName & ":" & application.SLCMS.Config.base.BasePort />
		</cfif>
		<cfset theQueryDataArguments.SubSiteFriendlyName = "Top" />
		<cfset theQueryDataArguments.BaseURL = theBaseDomainName />
		<cfset theQueryDataArguments.SubSiteID = 0 />
		<cfset theQueryDataArguments.DO = 0 />
		<cfset setTopSiteURL = application.SLCMS.Core.DataMgr.InsertRecord(tablename="#variables.PortalControlTable#", data=theQueryDataArguments) />
	</cfif>
	<!--- now we have a base data set lets load it up into our persistent structs --->
	<cfset temp = Refresh() />
	<cfif temp.error.errorcode eq 0>
		<!--- now we have refreshed the data in our structures we need to do a specific check --->
		
	<cfelse>
		<cfset ret.error.ErrorCode = BitOr(ret.error.ErrorCode, 1) />
		<cfset ret.error.ErrorText = ret.error.ErrorText & "Oops! Portal Refresh failed, Reason was:<br>" & temp.error.errorText &"<br>" />
	</cfif>
	
	<cfset temps = LogIt(LogType="CFC_Init", LogString="PortalControl Init() Finished") />
	<cfreturn variables />
</cffunction>

<cffunction name="Refresh" output="No" returntype="struct" access="public"
	displayname="Refresh Subsites"
	hint="refreshes local persistent data for main site and SubSites"
	>
	<!--- this function needs no arguments and returns directly with a  struct --->
	<cfset var temp = "" />	<!--- temp/throwaway var --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorText = "" />
	<cfset ret.error.ErrorContext = "PortalControl CFC: Refresh()" />
	<cfset ret.error.ErrorExtra = "" />
	<cfset ret.Data = False />	<!--- start as "Off" --->

	<cfset temp = getPortalAllowedFromDB() />
	<cfif temp.error.errorcode eq 0>
		<cfset variables.PortalEnabled = temp.data />
	<cfelse>	<!--- this is the error code --->
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 1) />
		<cfset ret.error.ErrorText = ret.error.ErrorText & "Oops! Portal Control DB get failed<br>" />
	</cfif>
	<cfset temp = getSubSitesFromDB() />
	<cfif temp.error.errorcode eq 0>
		<cfset variables.PortalHomeURL = temp.data.HomeURL />
		<cfset variables.Sites = duplicate(temp.data.Sites) />
		<cfset variables.URLs = duplicate(temp.data.URLs) />
		<cfset variables.SubSiteCount = temp.data.Global.SubSiteCount />		
		<cfset variables.SubSiteIDList_Active = temp.data.Global.SubSiteIDList_Active />		
		<cfset variables.SubSiteIDList_Full = temp.data.Global.SubSiteIDList_Full />		
		<cfset variables.SubSiteShortNameList = temp.data.Global.SubSiteShortNameList />		
	<cfelse>	<!--- this is the error code --->
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 2) />
		<cfset ret.error.ErrorText = ret.error.ErrorText & "Oops! (Sub)Site DB get failed<br>" />
	</cfif>
	
	<cfreturn ret /> 
</cffunction>

<cffunction name="getPortalAllowedFromDB" output="No" returntype="struct" access="private"
	displayname="Gets whether Allowed Make Subsites from database"
	hint="Gets subsite permission from database"
	>
	<!--- this function needs no arguments --->

	<!--- now vars that will get filled as we go --->
	<cfset var theQueryDataArguments = StructNew() />	<!--- temp struct to compose the data clauses of SQL queries --->
	<cfset var theQueryWhereArguments = StructNew() />	<!--- temp struct to compose the where clauses of SQL queries --->
	<cfset var getPortalMode = "" />	<!--- temp query --->
	<cfset var temp = "" />	<!--- temp/throwaway var --->
	<cfset var tempa = ArrayNew(1) />	<!--- temp/throwaway array --->
	<cfset var temps = StructNew() />	<!--- temp/throwaway structure --->
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorContext = "PortalControl CFC: getPortalAllowedFromDB()" />
	<cfset ret.error.ErrorExtra = "" />
	<cfset ret.Data = False />	<!--- start as "Off" --->

	<cfif len(variables.PortalControlTable)>
		<!--- validated so go for it --->
		<!--- wrap the whole thing in a try/catch in case something breaks --->
		<cftry>
			<!--- grab the flag from the top site, this defines if we can make any at all --->
			<cfset theQueryWhereArguments.SubSiteID = 0 />
			<cfset getPortalMode = application.SLCMS.Core.DataMgr.getRecords(tablename="#variables.PortalControlTable#", data=theQueryWhereArguments, fieldList="flagAllowSubSite") />
			<!--- 
			<cfquery name="getPortalMode" datasource="#variables.DataSourceName#">
				Select	flagAllowSubSite
					from	#variables.PortalControlTable#
					where	SubSiteID = 0
			</cfquery>
			 --->
			<cfif getPortalMode.RecordCount eq 1>
				<cfif getPortalMode.flagAllowSubSite neq 0>
					<cfset ret.Data = True />	<!--- flag subsites allowed --->
				</cfif>
			<cfelse>
				<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 2) />
				<cfset ret.error.ErrorText = ret.error.ErrorText & "Oops! RecordCount of Portal control search for top site was not 1, returned: #getPortalMode.RecordCount#<br>" />
			</cfif>
		<cfcatch type="any">
			<cfset ret.error = TakeErrorCatch(RetErrorStruct=ret.error, CatchStruct=cfcatch) />
		</cfcatch>
		</cftry>
	<cfelse>	<!--- this is the error code --->
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 1) />
		<cfset ret.error.ErrorText = ret.error.ErrorText & "Oops! Portal Control Table not defined<br>" />
	</cfif>

	<!--- return our data structure --->
	<cfreturn ret  />
</cffunction>

<cffunction name="getSubSitesFromDB" output="No" returntype="struct" access="private"
	displayname="Gets Subsites from database"
	hint="Gets subsite data from DB into local scope"
	>
	<!--- this function needs no arguments --->

	<!--- now vars that will get filled as we go --->
	<cfset var theQueryDataArguments = StructNew() />	<!--- temp struct to compose the data clauses of SQL queries --->
	<cfset var theQueryWhereArguments = StructNew() />	<!--- temp struct to compose the where clauses of SQL queries --->
	<cfset var getSubSites = "" />	<!--- temp query --->
	<cfset var getSubSiteParentDocs = "" />	<!--- temp query --->
	<cfset var getSubSiteURLs = "" />	<!--- temp query --->
	<cfset var temp = "" />	<!--- temp/throwaway var --->
	<cfset var thisSubSiteID = "" />	<!--- temp/throwaway --->
	<cfset var thisSubSiteURL = "" />	<!--- temp/throwaway --->
	<cfset var thisSubSiteURLID = 0 />	<!--- temp/throwaway --->
	<!--- 
	<cfset var thisRootDocID = "" />
	 --->
	<cfset var temps = StructNew() />	<!--- temp/throwaway structure --->
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorContext = "PortalControl CFC: getSubSitesFromDB()" />
	<cfset ret.error.ErrorExtra = "" />
	<cfset ret.Data = StructNew() />	<!--- start as Emptyish struct --->
	<cfset ret.Data.HomeURL = application.SLCMS.Config.base.BaseDomainName />	<!--- this is the domain name specified in the config, it might not be correct if we are a portal --->
	<cfset ret.Data.Global = StructNew() />
	<cfset ret.Data.Sites = StructNew() />
	<cfset ret.Data.URLs = StructNew() />
	<cfset ret.Data.Global.SubSiteCount = 0 />
	<cfset ret.Data.Global.SubSiteIDList_Active = "" />
	<cfset ret.Data.Global.SubSiteIDList_Full = "" />
	<cfset ret.Data.Global.SubSiteShortNameList = "" />

	<cfif len(variables.PortalControlTable)>
		<!--- validated so go for it --->
		<!--- wrap the whole thing in a try/catch in case something breaks --->
		<cftry>
			<cfset getSubSites = application.SLCMS.Core.DataMgr.getRecords(tablename="#variables.PortalControlTable#", data=theQueryWhereArguments, fieldList="SubSiteID,SubSiteFriendlyName,SubSiteNavName,BaseURL,flagAllowSubSite,SubSiteShortName,SubSiteActive", orderby="SubSiteID") />
			<!--- 
			<cfquery name="getSubSites" datasource="#variables.DataSourceName#">
				Select	SubSiteID, SubSiteFriendlyName, SubSiteNavName, BaseURL, flagAllowSubSite, SubSiteShortName, SubSiteActive
					from	#variables.PortalControlTable#
					order by SubSiteID
			</cfquery>
			 --->
			<cfset ret.Data.Global.SubSiteCount = getSubSites.RecordCount />
			<cfloop query="getSubSites">
				<cfset thisSubSiteID = getSubSites.SubSiteID />
				<!--- 
				<cfset thisRootDocID = getSubSites.RootDocID />
				 --->
				<cfset ret.Data.Global.SubSiteShortNameList = ListAppend(ret.Data.Global.SubSiteShortNameList, "#getSubSites.SubSiteShortName#") />
				<cfset ret.Data.Global.SubSiteIDList_Full = ListAppend(ret.Data.Global.SubSiteIDList_Full, "#thisSubSiteID#") />
				<cfif getSubSites.SubSiteActive>
					<cfset ret.Data.Global.SubSiteIDList_Active = ListAppend(ret.Data.Global.SubSiteIDList_Active, "#thisSubSiteID#") />
				</cfif>
				<cfset ret.Data.Sites["SubSite_#thisSubSiteID#"] = StructNew() />
				<cfset ret.Data.Sites["SubSite_#thisSubSiteID#"].SubSiteID = thisSubSiteID />
				<cfset ret.Data.Sites["SubSite_#thisSubSiteID#"].SubSiteFriendlyName = getSubSites.SubSiteFriendlyName />
				<cfset ret.Data.Sites["SubSite_#thisSubSiteID#"].SubSiteNavName = getSubSites.SubSiteNavName />
				<cfset ret.Data.Sites["SubSite_#thisSubSiteID#"].flagAllowSubSite = getSubSites.flagAllowSubSite />
				<cfset ret.Data.Sites["SubSite_#thisSubSiteID#"].SubSiteShortName = getSubSites.SubSiteShortName />
				<cfset ret.Data.Sites["SubSite_#thisSubSiteID#"].SubSiteActive = getSubSites.SubSiteActive />
				<cfif thisSubSiteID eq 0>	<!--- only subsite_0 --->
					<cfset ret.Data.HomeURL = getSubSites.BaseURL />
				</cfif>
				<!--- now we have the base data grab the URLs that belong to this subsite --->
				<cfset StructClear(theQueryWhereArguments) />
				<cfset theQueryWhereArguments.SubSiteID = thisSubSiteID />
				<cfset getSubSiteURLs = application.SLCMS.Core.DataMgr.getRecords(tablename="#variables.PortalURLTable#", data=theQueryWhereArguments, fieldList="SubSiteID,SubSiteURLID,SubSiteURL") />
				<!--- 
				<cfquery name="getSubSiteURLs" datasource="#variables.DataSourceName#">
					Select	SubSiteID, SubSiteURLID, SubSiteURL
						from	#variables.PortalURLTable#
						where	SubSiteID = <cfqueryparam cfsqltype="cf_sql_integer" value="#thisSubSiteID#">
				</cfquery>
				 --->
				<cfset ret.Data.Sites["SubSite_#thisSubSiteID#"].URLs = StructNew() />
				<cfset ret.Data.Sites["SubSite_#thisSubSiteID#"].URLs.Array = ArrayNew(1) />
				<cfset ret.Data.Sites["SubSite_#thisSubSiteID#"].URLs.Details = StructNew() />
				<cfset ret.Data.Sites["SubSite_#thisSubSiteID#"].URLs.List = "" />
				<cfloop query="getSubSiteURLs">
					<cfset thisSubSiteURLID = getSubSiteURLs.SubSiteURLID />
					<cfset thisSubSiteURL = getSubSiteURLs.SubSiteURL />
					<cfset ret.Data.Sites["SubSite_#thisSubSiteID#"].URLs.List = ListAppend(ret.Data.Sites["SubSite_#thisSubSiteID#"].URLs.List, getSubSiteURLs.SubSiteURL) />
					<cfset ret.Data.Sites["SubSite_#thisSubSiteID#"].URLs.Details["URLid_#thisSubSiteURLID#"] = StructNew() />
					<cfset ret.Data.Sites["SubSite_#thisSubSiteID#"].URLs.Details["URLid_#thisSubSiteURLID#"].SubSiteURLID = thisSubSiteURLID />
					<cfset ret.Data.Sites["SubSite_#thisSubSiteID#"].URLs.Details["URLid_#thisSubSiteURLID#"].SubSiteURL = getSubSiteURLs.SubSiteURL />
					<cfset temp = ArrayAppend(ret.Data.Sites["SubSite_#thisSubSiteID#"].URLs.Array, getSubSiteURLs.SubSiteURL) />
					<cfset ret.Data.Urls["#thisSubSiteURL#"] = StructNew() />
					<cfset ret.Data.Urls["#thisSubSiteURL#"].SubSiteID = thisSubSiteID />
					<cfset ret.Data.Urls["#thisSubSiteURL#"].SubSiteURLID = thisSubSiteURLID />
					<!--- 
					<cfset ret.Data.Urls["#thisSubSiteURL#"].RootDocID = thisRootDocID />
					 --->
					<!--- 
					<!--- then a bit to work out what our highest url is for the session engine --->
					<cfif thisSubSiteID eq 0 and ret.Data.HomeURL neq thisSubSiteURL>	<!--- only subsite_0 and not as is --->
						<cfif ListLen(thisSubSiteURL, ".") lt ListLen(ret.Data.HomeURL, ".") and ret.Data.HomeURL contains thisSubSiteURL>
							<!--- a shorter path and a subset of the longer --->
							<cfset ret.Data.HomeURL = thisSubSiteURL />
						</cfif>
					</cfif>
					 --->
				</cfloop>	<!--- end: loop over subsite URLs --->
				<!--- then we can grab the Docs that this subsite lives under --->
				<cfset StructClear(theQueryWhereArguments) />
				<cfset theQueryWhereArguments.SubSiteID = thisSubSiteID />
				<cfset getSubSiteParentDocs = application.SLCMS.Core.DataMgr.getRecords(tablename="#variables.PortalParentDocTable#", data=theQueryWhereArguments, fieldList="SubSiteID,ParentDocID") />
				<!--- 
				<cfquery name="getSubSiteParentDocs" datasource="#variables.DataSourceName#">
					Select	SubSiteID, ParentDocID
						from	#variables.PortalParentDocTable#
						where	SubSiteID = <cfqueryparam cfsqltype="cf_sql_integer" value="#thisSubSiteID#">
				</cfquery>
				 --->
				<cfset ret.Data.Sites["SubSite_#thisSubSiteID#"].ParentDocIDs = StructNew() />
				<cfset ret.Data.Sites["SubSite_#thisSubSiteID#"].ParentDocIDs.Array = ArrayNew(1) />
				<cfset ret.Data.Sites["SubSite_#thisSubSiteID#"].ParentDocIDs.List = "" />
				<cfloop query="getSubSiteParentDocs">
					<cfset ret.Data.Sites["SubSite_#thisSubSiteID#"].ParentDocIDs.List = ListAppend(ret.Data.Sites["SubSite_#thisSubSiteID#"].ParentDocIDs.List, getSubSiteParentDocs.ParentDocID) />
					<cfset temp = ArrayAppend(ret.Data.Sites["SubSite_#thisSubSiteID#"].ParentDocIDs.Array, getSubSiteParentDocs.ParentDocID) />
					<!--- now add this parent to the reverse table for the frontend lookups --->
					<cfif not StructKeyExists(variables.ParentDocsToSubSites, "DocID_#getSubSiteParentDocs.ParentDocID#")>
						<cfset variables.ParentDocsToSubSites["DocID_#getSubSiteParentDocs.ParentDocID#"] = StructNew() />
					</cfif>
					<cfset variables.ParentDocsToSubSites["DocID_#getSubSiteParentDocs.ParentDocID#"].SubSiteID = thisSubSiteID />
					<cfset variables.ParentDocsToSubSites.ParentDocIDList = ListAppend(variables.ParentDocsToSubSites.ParentDocIDList, getSubSiteParentDocs.ParentDocID) />
				</cfloop>	<!--- end: loop over parent docs --->
			</cfloop>	<!--- end: loop over subsites --->
		<cfcatch type="any">
			<cfset ret.error = TakeErrorCatch(RetErrorStruct=ret.error, CatchStruct=cfcatch) />
		</cfcatch>
		</cftry>
	<cfelse>	<!--- this is the error code --->
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 1) />
		<cfset ret.error.ErrorText = ret.error.ErrorText & "Oops! Portal Control Table not defined<br>" />
	</cfif>

	<!--- return our data structure --->
	<cfreturn ret  />
</cffunction>

<cffunction name="IsPortalAllowed" output="No" returntype="boolean" access="public"
	displayname="Is Allowed Make Subsites"
	hint="returns true or false according to whether the supervisor has allowed subsites"
	>
	<!--- this function needs no arguments and returns directly with a boolean, no struct --->
	<!--- return our data directly --->
	<cfreturn variables.PortalEnabled  />
</cffunction>

<cffunction name="GetSubSiteCount" output="No" returntype="numeric" access="public"
	displayname="Get SubSite Count"
	hint="Gets Count of SubSites"
	>
	<!--- this function needs no arguments and returns directly with a numeric, no struct --->
	<!--- return our data directly --->
	<cfreturn variables.SubSiteCount  />
</cffunction>

<cffunction name="GetFullSubSiteIDList" output="No" returntype="String" access="public"
	displayname="Get Full SubSite ID List"
	hint="Gets List of all SubSite IDs"
	>
	<!--- this function needs no arguments and returns directly with a string, no struct --->
	<!--- return our data directly --->
	<cfreturn variables.SubSiteIDList_Full />
</cffunction>

<cffunction name="GetActiveSubSiteIDList" output="No" returntype="String" access="public"
	displayname="Get SubSite ID List"
	hint="Gets List of SubSite IDs for Subsites that are active"
	>
	<!--- this function needs no arguments and returns directly with a string, no struct --->
	<!--- return our data directly --->
	<cfreturn variables.SubSiteIDList_Active />
</cffunction>

<cffunction name="GetAllowedSubSiteIDList_AllSites" output="No" returntype="String" access="public"
	displayname="Get Allowed SubSite ID List for all subsites"
	hint="Returns List of all SubSite IDs allowed to be seen by this user"
	>
	<!--- this function needs one argumentsthe userID --->
	<cfargument name="UserID" type="string" required="false" default="0" hint="User that we want the list for, defaults to all sites" />

	<cfset var theUserID = trim(arguments.UserID) />
	<cfset var thisSubSite = "" />
	<cfset var theReturn = "" />	<!--- the response --->
	
	<cfif theUserID neq "" and IsNumeric(theUserID) and theUserID neq 0>
		<!--- not the uberadmin and a valid number --->
		<cfloop list="#variables.SubSiteIDList_Full#" index="thisSubsite">
			<cfif application.SLCMS.Core.UserPermissions.IsAdmin(UserID=theUserID, SubSiteID=thisSubsite) 
						or application.SLCMS.Core.UserPermissions.IsEditor(UserID=theUserID, SubSiteID=thisSubsite) 
						or application.SLCMS.Core.UserPermissions.IsAuthor(UserID=theUserID, SubSiteID=thisSubsite)
						or application.SLCMS.Core.UserPermissions.IsSuper(UserID=theUserID, SubSiteID=thisSubsite)>
				<cfset theReturn = ListAppend(theReturn, thisSubsite) />
			</cfif>
		</cfloop>
	<cfelse>
		<cfset theReturn = variables.SubSiteIDList_Active />
	</cfif>
	<!--- return our data directly --->
	<cfreturn theReturn />
</cffunction>

<cffunction name="GetAllowedSubSiteIDList_ActiveSites" output="No" returntype="String" access="public"
	displayname="Get Allowed SubSite ID List for active subsites"
	hint="Returns List of active SubSite IDs allowed to be seen by this user"
	>
	<!--- this function needs one argumentsthe userID --->
	<cfargument name="UserID" type="numeric" required="false" default="0" hint="User that we want the list for, defaults to all sites" />

	<cfset var theUserID = trim(arguments.UserID) />
	<cfset var thisSubSite = "" />
	<cfset var theReturn = "" />	<!--- the response --->
	
	<cfif theUserID neq "" and IsNumeric(theUserID) and theUserID neq 0>
		<!--- not the uberadmin and a valid number --->
		<cfloop list="#variables.SubSiteIDList_Active#" index="thisSubsite">
			<cfif application.SLCMS.Core.UserPermissions.IsAdmin(UserID=theUserID, SubSiteID=thisSubsite)>
				<cfset theReturn = ListAppend(theReturn, thisSubsite) />
			</cfif>
		</cfloop>
	<cfelse>
		<cfset theReturn = variables.SubSiteIDList_Active />
	</cfif>
	<!--- return our data directly --->
	<cfreturn theReturn />
</cffunction>

<cffunction name="GetSubSiteParentDocIDData" output="No" returntype="Struct" access="public"
	displayname="Get SubSite ParentID List"
	hint="Gets List of Parent DocIDs for Subsites"
	>
	<!--- this function needs no arguments and returns directly with a struct --->
	<!--- return our data directly --->
	<cfreturn variables.ParentDocsToSubSites />
</cffunction>

<cffunction name="GetPortalHomeURL" output="No" returntype="String" access="public"
	displayname="Get Portal Home URL"
	hint="Gets the Home URL of the whole portal if there is one defined"
	>
	<!--- this function needs no arguments and returns directly with a string --->
	<!--- return our data directly --->
	<cfreturn variables.PortalHomeURL />
</cffunction>

<cffunction name="GetSubSiteShortNameList" output="No" returntype="String" access="public"
	displayname="Get SubSite Short Name List"
	hint="Gets List of all SubSite ShortNames"
	>
	<!--- this function needs no arguments and returns directly with a string, no struct --->
	<!--- return our data directly --->
	<cfreturn variables.SubSiteShortNameList />
</cffunction>

<cffunction name="GetSubSiteIDfromURL" output="No" returntype="numeric" access="public"
	displayname="Get SubSiteID from URL"
	hint="Gets the SubSiteID related to a particular URL, returns zero if no match. No error handling or ret structure"
	>
	<!--- this function needs.... --->
	<cfargument name="URLtoCheck" type="string" default="" hint="the URL string to test" />	<!--- one or the other --->

	<!--- now all of the var declarations, first the arguments which need manipulation --->
	<cfset var theURLtoCheck = trim(arguments.URLtoCheck) />	
	<cfset var ret = StructNew() />	<!--- temp for try catch --->
	<cfset var theResult = 0 />	<!--- this is the return to the caller, zero is nothing found which is subSite 0, the portal/top/only site --->
	<cfset ret.error = Structnew() />
	<cfset ret.error.errorContext = "PortalControl CFC: getSubSiteIDFromURL()" />

	<cfif theURLtoCheck neq "">
		<cftry>
			<cfif StructKeyExists(variables.URLs, "#theURLtoCheck#")>
				<cfset theResult = variables.URLs["#theURLtoCheck#"].SubSiteID />
			</cfif>
		<cfcatch type="any">
			<cfset ret.error = TakeErrorCatch(RetErrorStruct=ret.error, CatchStruct=cfcatch) />
		</cfcatch>
		</cftry>
	<cfelse>
		<!--- no URL supplied, return zero --->
	</cfif>
	
	<cfreturn theResult  />
</cffunction>

<cffunction name="GetSubSite" output="No" returntype="struct" access="public"
	displayname="Get SubSite"
	hint="Gets data related to a SubSite"
	>
	<!--- this function needs.... --->
	<cfargument name="SubSiteID" type="string" default="" hint="the subsite as an ID" />	<!--- one or the other --->
	<cfargument name="SubSiteName" type="string" default="" hint="the subsite as a short name" />	<!--- ID wins --->

	<!--- now all of the var declarations, first the arguments which need manipulation --->
	<cfset var theSubSiteID = trim(arguments.SubSiteID) />	<!--- the desired SubSite --->
	<cfset var theSubSiteName = trim(arguments.SubSiteName) />	<!--- the desired SubSite --->
	<cfset var theNewStatus = False />	<!--- the new status --->
	<cfset var setStatusInDB = "" />	<!--- temp query --->
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorContext = "PortalControl CFC: getSubSite()" />
	<cfset ret.error.ErrorText = "" />
	<cfset ret.error.ErrorExtra = "" />
	<cfset ret.Data = StructNew() />	<!--- and no data yet --->

	<cfif not (theSubSiteName eq "" and theSubSiteID eq "")>
		<cftry>
			<cfif theSubSiteName neq "" and ListFindNoCase(variables.SubSiteShortNameList, theSubSiteName)>
				<cfset theSubSiteID = ListGetAt(variables.SubSiteIDList_Full, ListFindNoCase(variables.SubSiteShortNameList, theSubSiteName)) />
			<cfelseif ListFindNoCase(variables.SubSiteIDList_Full, theSubSiteID)>
				<!--- we put this in to make sure there's a match one way or the other --->
			<cfelse>
				<cfset theSubSiteID = "" />
			</cfif>
			<cfif theSubSiteID neq "" and structKeyExists(variables.sites, "SubSite_#theSubSiteID#")>
				<cfset ret.Data = variables.sites["SubSite_#theSubSiteID#"] />
			<cfelse>
				<!--- bad ID supplied --->
				<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 2) />
				<cfset ret.error.ErrorText = ret.error.ErrorText & "Oops! (Sub)Site identifier not matched. the calculated ID was: theSubSiteID<br>" />
			</cfif>
		
		<cfcatch type="any">
			<cfset ret.error = TakeErrorCatch(RetErrorStruct=ret.error, CatchStruct=cfcatch) />
		</cfcatch>
		</cftry>
	<cfelse>
		<!--- no ID supplied --->
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 1) />
		<cfset ret.error.ErrorText = ret.error.ErrorText & "Oops! (Sub)Site identifier not supplied<br>" />
	</cfif>
	
	
	
	<cfreturn ret  />
</cffunction>

<cffunction name="GetQuickSubSiteFriendlyName" output="No" returntype="string" access="public"
	displayname="Get SubSite's Friendly Name"
	hint="Gets friendly name related to a SubSiteID, returns null if not found"
	>
	<!--- this function needs.... --->
	<cfargument name="SubSiteID" type="string" default="" hint="the subsite as an ID" />

	<cfset var theSubSiteID = trim(arguments.SubSiteID) />	<!--- the desired SubSite --->
	<cfset var theSubSiteFName = "" />	<!--- will be the friendly name --->
	<cftry>
		<cfif theSubSiteID neq "" and structKeyExists(variables.sites, "SubSite_#theSubSiteID#")>
			<cfset theSubSiteFName = variables.sites["SubSite_#theSubSiteID#"].subSiteFriendlyName />
		</cfif>
	<cfcatch></cfcatch>
	</cftry>
	
	<cfreturn theSubSiteFName />
</cffunction>

<cffunction name="GetQuickSubSiteShortName" output="No" returntype="string" access="public"
	displayname="Get SubSite's Friendly Name"
	hint="Gets friendly name related to a SubSiteID, returns null if not found"
	>
	<!--- this function needs.... --->
	<cfargument name="SubSiteID" type="string" default="" hint="the subsite as an ID" />

	<cfset var theSubSiteID = trim(arguments.SubSiteID) />	<!--- the desired SubSite --->
	<cfset var theSubSiteShortName = "" />	<!--- will be the URL --->
	<cftry>
		<cfif theSubSiteID neq "" and structKeyExists(variables.sites, "SubSite_#theSubSiteID#")>
			<cfset theSubSiteShortName = variables.sites["SubSite_#theSubSiteID#"].SubSiteShortName />
		</cfif>
	<cfcatch></cfcatch>
	</cftry>
	
	<cfreturn theSubSiteShortName />
</cffunction>

<cffunction name="setPortalAllowedStatus" output="No" returntype="struct" access="public"
	displayname="Set Portal Allowed Status"
	hint="sets the system status as to whether we allow subsites or not"
	>
	<!--- this function needs.... --->
	<cfargument name="NewStatus" type="boolean" default="False" />	<!--- the is the status we want to set --->

	<!--- now all of the var declarations, first the arguments which need manipulation --->
	<cfset var theQueryDataArguments = StructNew() />	<!--- temp struct to compose the data clauses of SQL queries --->
	<cfset var theQueryWhereArguments = StructNew() />	<!--- temp struct to compose the where clauses of SQL queries --->
	<cfset var theNewStatus = False />	<!--- the new status --->
	<cfset var SetVersionControl = "" />	<!--- temp query --->
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorContext = "PortalControl CFC: setPortalAllowedStatus()" />
	<cfset ret.error.ErrorExtra = "" />
	<cfset ret.Data = "" />	<!--- and no data yet --->

	<!--- wrap the whole thing in a try/catch in case something breaks --->
	<cftry>
		<cfif arguments.NewStatus eq True>
			<cfset theNewStatus = 1 />
			<cfset variables.PortalEnabled = True />
		<cfelse>
			<cfset theNewStatus = 0 />
			<cfset variables.PortalEnabled = False />
		</cfif>
		<cfset theQueryDataArguments.flagAllowSubsite = theNewStatus />	<!--- data set clause of the SQL query --->
		<cfset theQueryWhereArguments.SubSiteID = 0 />	<!--- the where clause of the SQL query --->
		<cfset SetVersionControl = application.SLCMS.Core.DataMgr.UpdateRecords(tablename="#variables.PortalControlTable#", data_set=theQueryDataArguments, data_where=theQueryWhereArguments) />
	<cfcatch type="any">
			<cfset ret.error = TakeErrorCatch(RetErrorStruct=ret.error, CatchStruct=cfcatch) />
	</cfcatch>
	</cftry>

	<!--- return our data structure --->
	<cfreturn ret  />
</cffunction>

<cffunction name="setSubSiteParentage" output="No" returntype="struct" access="public"
	displayname="Set SubSite parent DocID"
	hint="sets a parent DocID for a subsite"
	>
	<!--- this function needs.... --->
	<cfargument name="SubSiteID" type="any" default="" hint="subSite ID of site we are setting a parent doc to" />
	<cfargument name="ParentDocID" type="numeric" default="0" hint="Doc ID of parent we are setting to a subsite" />

	<!--- now all of the var declarations, first the arguments which need manipulation --->
	<cfset var theSubSiteID = 0 />	<!--- default to nowt b4 we test --->
	<cfset var theParentDocID = arguments.ParentDocID />
	<cfset var theQueryDataArguments = StructNew() />	<!--- temp struct to compose the data clauses of SQL queries --->
	<cfset var theQueryWhereArguments = StructNew() />	<!--- temp struct to compose the where clauses of SQL queries --->
	<cfset var setDB = "" />	<!--- temp query --->
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorContext = "PortalControl CFC: setSubSiteParentage()" />
	<cfset ret.error.ErrorExtra = "" />
	<cfset ret.Data = "" />	<!--- and no data yet --->

	<!--- wrap the whole thing in a try/catch in case something breaks --->
	<cftry>
		<cfif ListFind(variables.SubSiteIDList_Full, arguments.SubSiteID)>
			<cfset theSubSiteID = arguments.SubSiteID />
		<cfelse>
			<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 1) />
			<cfset ret.error.ErrorText = ret.error.ErrorContext & ' Invalid SubSiteID passed in. Was: #arguments.SubSiteID#' />
		</cfif>
		<cfif ret.error.ErrorCode eq 0>
			<!--- update db directly and local variables so we don't need to refresh anything --->
			<!--- we can't be a parent to more than one subsite so remove the old data if any before we add in the new --->
			<cfset theQueryWhereArguments.ParentDocID = theParentDocID />	<!--- the where clause of the SQL query --->
			<cfset setDB = application.SLCMS.Core.DataMgr.DeleteRecords(tablename="#variables.PortalParentDocTable#", data=theQueryWhereArguments) />
			<!--- 
			<cfquery name="setDB" datasource="#application.SLCMS.Config.datasources.CMS#">
				Delete From	#variables.PortalParentDocTable#
					Where		ParentDocID = <cfqueryparam value="#theParentDocID#" cfsqltype="cf_sql_integer">
			</cfquery>
			 --->
			<cfset theQueryDataArguments.SubSiteID = theSubSiteID />
			<cfset theQueryDataArguments.ParentDocID = theParentDocID />
			<cfset setDB = application.SLCMS.Core.DataMgr.InsertRecord(tablename="#variables.PortalParentDocTable#", data=theQueryDataArguments) />
			<!--- 
			<cfquery name="setDB" datasource="#application.SLCMS.Config.datasources.CMS#">
				Insert Into	#variables.PortalParentDocTable#
									(SubsiteID, ParentDocID)
					Values	(<cfqueryparam value="#theSubSiteID#" cfsqltype="cf_sql_integer">,
									<cfqueryparam value="#theParentDocID#" cfsqltype="cf_sql_integer">)
			</cfquery>
			 --->
			<cfif not ListFind(variables.ParentDocsToSubSites.ParentDocIDList, theParentDocID)>
				<cfset variables.ParentDocsToSubSites.ParentDocIDList = ListAppend(variables.ParentDocsToSubSites.ParentDocIDList, theParentDocID) />	<!--- list of parent Docs --->
			</cfif>
			<cfset variables.ParentDocsToSubSites["DocID_#theParentDocID#"] = StructNew() />	<!--- struct of parent Docs and which subsite live in each, this will trash old data if there was any --->
			<cfset variables.ParentDocsToSubSites["DocID_#theParentDocID#"].subSiteID = theSubSiteID />	<!--- struct of parent Docs and which subsite live in each --->
		</cfif>
	<cfcatch type="any">
		<cfset ret.error = TakeErrorCatch(RetErrorStruct=ret.error, CatchStruct=cfcatch) />
	</cfcatch>
	</cftry>

	<!--- return our data structure --->
	<cfreturn ret  />
</cffunction>

<cffunction name="clearSubSiteParentage" output="No" returntype="struct" access="public"
	displayname="Clear SubSite parent DocID"
	hint="clears a parent DocID from a subsite"
	>
	<!--- this function needs.... --->
	<cfargument name="ParentDocID" type="numeric" default="0" hint="Doc ID of parent we are setting to a subsite" />

	<!--- now all of the var declarations, first the arguments which need manipulation --->
	<cfset var theParentDocID = arguments.ParentDocID />
	<cfset var theQueryDataArguments = StructNew() />	<!--- temp struct to compose the data clauses of SQL queries --->
	<cfset var theQueryWhereArguments = StructNew() />	<!--- temp struct to compose the where clauses of SQL queries --->
	<cfset var setDB = "" />	<!--- temp query --->
	<cfset var theListPos = "" />
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorContext = "PortalControl CFC: clearSubSiteParentage()" />
	<cfset ret.error.ErrorExtra = "" />
	<cfset ret.Data = "" />	<!--- and no data yet --->

	<!--- wrap the whole thing in a try/catch in case something breaks --->
	<cftry>
		<cfif ret.error.ErrorCode eq 0>
			<!--- update db directly and local variables so we don't need to refresh anything --->
			<!--- can't use DataMgr as it complains about primary keys 
			<!--- we can't be a parent to more than one subsite so remove the old data if any before we add in the new --->
			<cfset theQueryWhereArguments.ParentDocID = theParentDocID />	<!--- the where clause of the SQL query --->
			<cfset setDB = application.SLCMS.Core.DataMgr.DeleteRecord(tablename="#variables.PortalParentDocTable#", data=theQueryWhereArguments) />
			 --->
			<cfquery name="setDB" datasource="#application.SLCMS.Config.datasources.CMS#">
				Delete From	#variables.PortalParentDocTable#
					Where		ParentDocID = <cfqueryparam value="#theParentDocID#" cfsqltype="cf_sql_integer">
			</cfquery>
			
			<cfset theListPos = ListFind(variables.ParentDocsToSubSites.ParentDocIDList, theParentDocID)>
			<cfif theListPos>
				<cfset variables.ParentDocsToSubSites.ParentDocIDList = ListDeleteAt(variables.ParentDocsToSubSites.ParentDocIDList, theListPos) />	<!--- list of parent Docs --->
			</cfif>
			<cfset StructDelete(variables.ParentDocsToSubSites, "DocID_#theParentDocID#") />	<!--- struct of parent Docs and which subsite live in each, this will trash old data if there was any --->
		</cfif>
	<cfcatch type="any">
		<cfset ret.error = TakeErrorCatch(RetErrorStruct=ret.error, CatchStruct=cfcatch) />
	</cfcatch>
	</cftry>

	<!--- return our data structure --->
	<cfreturn ret  />
</cffunction>

<cffunction name="GetAllSubSites" output="No" returntype="struct" access="public"
	displayname="Get All SubSites"
	hint="returns the Sites struct"
	>
	<!--- this function needs no arguments and returns directly with a struct --->
	<!--- return our data directly --->
	<cfreturn variables.sites  />
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
	<cfset ret.error.ErrorContext = "Portal Control CFC: LogIt()" />
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
