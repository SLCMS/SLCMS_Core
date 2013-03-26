

<cfsetting enablecfoutputonly="Yes">
<cfset ErrFlag  = False>
<cfset ErrMsg  = "">
<cfset GoodMsg  = "">
<cfset opnext = "">	<!--- what we do next --->
<!--- DAL related vars we use right thru --->
<cfset theQueryDataArguments = StructNew() />	<!--- temp struct to compose the data clauses of SQL queries --->
<cfset theQueryWhereArguments = StructNew() />	<!--- temp struct to compose the where clauses of SQL queries --->
<cfset theQueryWhereFilters = ArrayNew(1) />	<!--- temp array to compose the filters for where clauses --->

<cfif IsDefined("url.job")>
	<cfset WorkMode1 = url.job>
	<cfset WorkMode2 = "">
	<cfset DispMode = url.job>
<cfelse>
	<cfset WorkMode1 = "">
	<cfset WorkMode2 = "GetBaseDisplayItems">
	<cfset DispMode = "ShowBaseDisplayItems">
</cfif>

<cfif WorkMode1 eq "RefreshSubSite">
	<!--- toggle whether subsites can be used or not --->
	<cfif StructKeyExists(form, "Function") and form.function eq "RefreshPortal">
		<cfset ret = application.SLCMS.Core.PortalControl.Refresh() />
		<cfset ret = application.SLCMS.Core.ModuleController.ReInitAfter(Action="subSite") />	<!--- this makes everything else pick up the changes --->
		<cfset GoodMsg = "Portal Status and Subsites have been Refreshed" />"
	</cfif>
	<cfset WorkMode2 = "GetBaseDisplayItems">
	<cfset DispMode = "ShowBaseDisplayItems">
	
<cfelseif WorkMode1 eq "AddTopURL">
	<!--- set up to add a subsite URL --->
	<cfset theURLdataGet = application.SLCMS.Core.PortalControl.GetSubSite(SubSiteID=0) />
	<cfif theURLdataGet.error.errorcode eq 0>
		<cfset theURLdata = theURLdataGet.data />
		<cfset dURL = application.SLCMS.Core.PortalControl.GetPortalHomeURL() /> 	<!--- load up with the base URL --->
		<cfset dURLID = "" />	<!--- we don't need this one but the common display code for the form does --->
		<cfset dSubSiteFriendlyName = theURLdata.SubSiteFriendlyName />
		<cfset dSubSiteID = 0 />
		<cfset opnext = "SaveAddTopURL">	<!--- what we do next --->
		<cfset DispMode = "AddTopURL">
	<cfelse>
		<cfset ErrFlag  = True>
		<cfset ErrMsg  = "Site data get failed.">
		<cfset WorkMode2 = "GetBaseDisplayItems">
		<cfset DispMode = "ShowBaseDisplayItems">
	</cfif>

<cfelseif WorkMode1 eq "SaveAddTopURL">
	<!--- save a new Top Site URL into the system --->
	<!--- first check that we have valid input --->
	<cfset OK = True />
	<cfif len(form.SubSiteURL) eq 0>
		<cfset OK = False />
		<cfset ErrFlag  = True>
		<cfset ErrMsg  = ErrMsg & "No URL Entered<br>">
	<cfelseif not application.SLCMS.mbc_utility.utilities.IsValidDomainName(form.SubSiteURL)>
		<cfset OK = False />
		<cfset ErrFlag  = True>
		<cfset ErrMsg  = ErrMsg & "Bad Domain Name/URL Entered<br>">
	<cfelse>
		<cfset theSubSiteURL = form.SubSiteURL />
	</cfif>
	<!--- we now have relevant bits so see if we are duplicating --->
	<cfset StructClear(theQueryWhereArguments) />
	<cfset theQueryWhereArguments.SubSiteURL = theSubSiteURL />
	<cfset theQueryWhereArguments.SubSiteId = 0 />
	<cfset getSubSiteURL = application.SLCMS.core.DataMgr.getRecords(tablename="#application.SLCMS.config.DatabaseDetails.TableName_PortalURLTable#", data=theQueryWhereArguments, fieldList="SubSiteURLID") />
	<!--- 
	<cfquery name="getSubSiteURL" datasource="#application.SLCMS.config.datasources.CMS#">
		SELECT	SubSiteURLID
			FROM	#application.SLCMS.config.DatabaseDetails.TableName_PortalURLTable#
			Where SubSiteURL = <cfqueryparam value="#theSubSiteURL#" cfsqltype="cf_sql_varchar" list="false" maxlength="255">
				and SubSiteId = <cfqueryparam value="0" cfsqltype="cf_sql_integer">
	</cfquery>
	 --->
	<cfif getSubSiteURL.RecordCount>
		<cfset OK = False />
		<cfset ErrFlag  = True>
		<cfset ErrMsg  = ErrMsg & "That URL already exists<br>">
	</cfif>
	<!--- validated so throw it in --->
	<cfif OK>
		<cfset StructClear(theQueryDataArguments) />
		<cfset theQueryDataArguments.SubSiteURL = theSubSiteURL />
		<cfset theQueryDataArguments.SubSiteID = 0 />
		<cfset theQueryDataArguments.SubSiteURLId = Nexts_getNextID('SubSiteURLId') />
		<cfset setSubSiteURL = application.SLCMS.core.DataMgr.InsertRecord(tablename="#application.SLCMS.config.DatabaseDetails.TableName_PortalURLTable#", data=theQueryDataArguments) />
		<!--- 
		<cfset theNextSubSiteURLId = application.SLCMS.mbc_utility.utilities.getNextID('SubSiteURLId') />
		<cfquery name="setSubSiteURL" datasource="#application.SLCMS.config.datasources.CMS#">
			Insert into	#application.SLCMS.config.DatabaseDetails.TableName_PortalURLTable#
								(SubSiteURL, SubSiteID, SubSiteURLId)
				values	(<cfqueryparam value="#theSubSiteURL#" cfsqltype="cf_sql_varchar" list="false" maxlength="255">,
								<cfqueryparam value="0" cfsqltype="cf_sql_integer" >,
								<cfqueryparam value="#theNextSubSiteURLId#" cfsqltype="cf_sql_integer">)
		</cfquery>
		 --->
		<cfset GoodMsg = "New URL for Subsite &quot;#form.SubSiteFriendlyName#&quot; has been saved" />"
		<!--- finished so refresh the structures and then back to the listing --->
		<cfset ret = application.SLCMS.Core.PortalControl.Refresh() />
		<cfset WorkMode2 = "GetBaseDisplayItems">
		<cfset DispMode = "ShowBaseDisplayItems">
	<cfelse>
		<!--- It was not good so back to the form with message --->
		<cfset dURLID = form.SubSiteURLID />
		<cfset dURL = form.SubSiteURL />
		<cfset dSubSiteFriendlyName = form.SubSiteFriendlyName />
		<cfset dSubSiteID = form.SubSiteID />
		<cfset opnext = "SaveEditSubSiteURL">	<!--- what we do next --->
		<cfset DispMode = "EditSubSiteURL">
	</cfif>

<cfelseif WorkMode1 eq "EditTopSiteURL">
	<!--- set up to edit a top URL --->
	<cfset theURLdataGet = application.SLCMS.Core.PortalControl.GetSubSite(SubSiteID=0) />
	<cfif theURLdataGet.error.errorcode eq 0>
		<cfset theURLdata = theURLdataGet.data />
		<cfset dURLID = theURLdata.URLs.Details["URLID_#url.SubSiteURLID#"].SubSiteURLID />
		<cfset dURL = theURLdata.URLs.Details["URLID_#url.SubSiteURLID#"].SubSiteURL />
		<cfset dSubSiteFriendlyName = theURLdata.SubSiteFriendlyName />
		<cfset dSubSiteID = 0 />
		<cfset opnext = "SaveEditTopSiteURL">	<!--- what we do next --->
		<cfset DispMode = "EditTopSiteURL">
	<cfelse>
		<cfset ErrFlag  = True>
		<cfset ErrMsg  = "Site data get failed.">
		<cfset WorkMode2 = "GetBaseDisplayItems">
		<cfset DispMode = "ShowBaseDisplayItems">
	</cfif>
	
<cfelseif WorkMode1 eq "SaveEditTopSiteURL">
	<!--- save an edited SubSite URL into the system --->
	<!--- first check that we have valid input --->
	<cfset OK = True />
	<cfif len(form.SubSiteURL) eq 0>
		<cfset OK = False />
		<cfset ErrFlag  = True>
		<cfset ErrMsg  = ErrMsg & "No URL Entered<br>">
	<cfelseif not application.SLCMS.mbc_utility.utilities.IsValidDomainName(form.SubSiteURL)>
		<cfset OK = False />
		<cfset ErrFlag  = True>
		<cfset ErrMsg  = ErrMsg & "Bad Domain Name Entered<br>">
	<cfelse>
		<cfset theSubSiteURL = form.SubSiteURL />
	</cfif>
	<!--- we now have relevant bits so see if we are duplicating --->
	<cfset StructClear(theQueryWhereArguments) />
	<cfset ArrayClear(theQueryWhereFilters) />
	<cfset theQueryWhereArguments.SubSiteURL = theSubSiteURL />
	<cfset theQueryWhereArguments.SubSiteId = 0 />
	<cfset theQueryWhereFilters[1] = {field="SubSiteURLId", operator="<>", value="#form.SubSiteURLID#"} />
	<cfset getSubSiteURL = application.SLCMS.core.DataMgr.getRecords(tablename="#application.SLCMS.config.DatabaseDetails.TableName_PortalURLTable#", data=theQueryWhereArguments, filters=theQueryWhereFilters, fieldList="SubSiteURLID") />
	<!--- 
	<cfquery name="getSubSiteURL" datasource="#application.SLCMS.config.datasources.CMS#">
		SELECT	SubSiteURLID
			FROM	#application.SLCMS.config.DatabaseDetails.TableName_PortalURLTable#
			Where SubSiteURL = <cfqueryparam value="#theSubSiteURL#" cfsqltype="cf_sql_varchar" list="false" maxlength="255">
				and	SubSiteURLId <> <cfqueryparam value="#form.SubSiteURLID#" cfsqltype="cf_sql_integer">
				and SubSiteId = <cfqueryparam value="0" cfsqltype="cf_sql_integer">
	</cfquery>
	 --->
	<cfif getSubSiteURL.RecordCount>
		<cfset OK = False />
		<cfset ErrFlag  = True>
		<cfset ErrMsg  = ErrMsg & "That URL already exists<br>">
	</cfif>
	<!--- validated so throw it in --->
	<cfif OK>
		<cfset StructClear(theQueryDataArguments) />
		<cfset StructClear(theQueryWhereArguments) />
		<cfset theQueryDataArguments.SubSiteURL = theSubSiteURL />
		<cfset theQueryWhereArguments.SubSiteURLId = form.SubSiteURLId />
		<cfset setSubSiteURL = application.SLCMS.core.DataMgr.UpdateRecords(tablename="#application.SLCMS.config.DatabaseDetails.TableName_PortalURLTable#", data_set=theQueryDataArguments, data_where=theQueryWhereArguments) />
		<!--- 
		<cfquery name="setSubSiteURL" datasource="#application.SLCMS.config.datasources.CMS#">
			Update	#application.SLCMS.config.DatabaseDetails.TableName_PortalURLTable#
				set		SubSiteURL = <cfqueryparam value="#theSubSiteURL#" cfsqltype="cf_sql_varchar" list="false" maxlength="255">
				where	SubSiteURLId = <cfqueryparam value="#form.SubSiteURLId#" cfsqltype="cf_sql_integer">
		</cfquery>
		 --->
		<cfset GoodMsg = "Edits to URL for site &quot;#form.SubSiteFriendlyName#&quot; have been saved" />"
		<!--- finished so refresh the structures and then back to the listing --->
		<cfset ret = application.SLCMS.Core.PortalControl.Refresh() />
		<cfset WorkMode2 = "GetBaseDisplayItems">
		<cfset DispMode = "ShowBaseDisplayItems">
	<cfelse>
		<!--- It was not good so back to the form with message --->
		<cfset dURLID = form.SubSiteURLID />
		<cfset dURL = form.SubSiteURL />
		<cfset dSubSiteFriendlyName = form.SubSiteFriendlyName />
		<cfset dSubSiteID = form.SubSiteID />
		<cfset opnext = "SaveEditTopSiteURL">	<!--- what we do next --->
		<cfset DispMode = "EditSubSiteURL">
	</cfif>

<cfelseif WorkMode1 eq "EditBaseURL">
	<!--- set up to edit the site's base URL --->
	<cfset theURLdataGet = application.SLCMS.Core.PortalControl.GetSubSite(SubSiteID=0) />
	<cfif theURLdataGet.error.errorcode eq 0>
		<cfset theURLdata = theURLdataGet.data />
		<cfset dURLID = 0 />
		<cfset dURL = application.SLCMS.Core.PortalControl.GetPortalHomeURL() />
		<cfset dSubSiteFriendlyName = "" />
		<cfset dSubSiteID = 0 />
		<cfset opnext = "SaveEditBaseURL">	<!--- what we do next --->
		<cfset DispMode = "EditBaseURL">
	<cfelse>
		<cfset ErrFlag  = True>
		<cfset ErrMsg  = "Site data get failed.">
		<cfset WorkMode2 = "GetBaseDisplayItems">
		<cfset DispMode = "ShowBaseDisplayItems">
	</cfif>
	
<cfelseif WorkMode1 eq "SaveEditBaseURL">
	<!--- save the edited Base URL into the system --->
	<!--- first check that we have valid input --->
	<cfset OK = True />
	<cfif len(form.SubSiteURL) eq 0>
		<cfset OK = False />
		<cfset ErrFlag  = True>
		<cfset ErrMsg  = ErrMsg & "No URL Entered<br>">
	<cfelseif not application.SLCMS.mbc_utility.utilities.IsValidDomainName(form.SubSiteURL)>
		<cfset OK = False />
		<cfset ErrFlag  = True>
		<cfset ErrMsg  = ErrMsg & "Bad Domain Name Entered<br>">
	<cfelse>
		<cfset theBaseURL = form.SubSiteURL />
	</cfif>
	<!--- validated so throw it in --->
	<cfif OK>
		<cfset StructClear(theQueryDataArguments) />
		<cfset StructClear(theQueryWhereArguments) />
		<cfset theQueryDataArguments.BaseURL = theBaseURL />
		<cfset theQueryWhereArguments.SubSiteId = 0 />
		<cfset setBaseURL = application.SLCMS.core.DataMgr.UpdateRecords(tablename="#application.SLCMS.config.DatabaseDetails.TableName_PortalControlTable#", data_set=theQueryDataArguments, data_where=theQueryWhereArguments) />
		<!--- 
		<cfquery name="setBaseURL" datasource="#application.SLCMS.config.datasources.CMS#">
			Update	#application.SLCMS.config.DatabaseDetails.TableName_PortalControlTable#
				set		BaseURL = <cfqueryparam value="#theBaseURL#" cfsqltype="cf_sql_varchar" list="false" maxlength="255">
				where	SubSiteId = <cfqueryparam value="0" cfsqltype="cf_sql_integer">
		</cfquery>
		 --->
		<cfset GoodMsg = "Edits to the Base URL of the portal have been saved" />"
		<!--- finished so refresh the structures and then back to the listing --->
		<cfset ret = application.SLCMS.Core.PortalControl.Refresh() />
		<cfset application.SLCMS.Sites.Site_0.HomeURL = theBaseURL />
		<cfset WorkMode2 = "GetBaseDisplayItems">
		<cfset DispMode = "ShowBaseDisplayItems">
	<cfelse>
		<!--- It was not good so back to the form with message --->
		<cfset dURLID = form.SubSiteURLID />
		<cfset dURL = form.SubSiteURL />
		<cfset dSubSiteFriendlyName = form.SubSiteFriendlyName />
		<cfset dSubSiteID = form.SubSiteID />
		<cfset opnext = "SaveEditTopSiteURL">	<!--- what we do next --->
		<cfset DispMode = "EditSubSiteURL">
	</cfif>

<cfelseif WorkMode1 eq "AddSubSiteURL">
	<!--- set up to add a subsite URL --->
	<cfif structKeyExists(url, "SubSiteID") and IsNumeric(url.SubSiteID)>
		<cfset theURLdataGet = application.SLCMS.Core.PortalControl.GetSubSite(SubSiteID=url.SubSiteID) />
		<cfif theURLdataGet.error.errorcode eq 0>
			<cfset theURLdata = theURLdataGet.data />
			<cfset dURL = application.SLCMS.Core.PortalControl.GetPortalHomeURL() /> 	<!--- load up with the base URL --->
			<cfset dURLID = "" />	<!--- we don't need this one but the common display code for the form does --->
			<cfset dSubSiteFriendlyName = theURLdata.SubSiteFriendlyName />
			<cfset dSubSiteID = url.SubSiteID />
			<cfset opnext = "SaveAddSubSiteURL">	<!--- what we do next --->
			<cfset DispMode = "AddSubSiteURL">
		<cfelse>
			<cfset ErrFlag  = True>
			<cfset ErrMsg  = "SubSite data get failed.">
			<cfset WorkMode2 = "GetBaseDisplayItems">
			<cfset DispMode = "ShowBaseDisplayItems">
		</cfif>
	<cfelse>
		<cfset ErrFlag  = True>
		<cfset ErrMsg  = "Bad SubSiteID URL parameter">
		<cfset WorkMode2 = "GetBaseDisplayItems">
		<cfset DispMode = "ShowBaseDisplayItems">
	</cfif>

<cfelseif WorkMode1 eq "SaveAddSubSiteURL">
	<!--- save a new SubSite URL into the system --->
	<!--- first check that we have valid input --->
	<cfset OK = True />
	<cfset theSubSiteURL = "" />
	<cfif len(form.SubSiteURL) eq 0>
		<cfset OK = False />
		<cfset ErrFlag  = True>
		<cfset ErrMsg  = ErrMsg & "No URL Entered<br>">
	<cfelseif not application.SLCMS.mbc_utility.utilities.IsValidDomainName(form.SubSiteURL)>
		<cfset OK = False />
		<cfset ErrFlag  = True>
		<cfset ErrMsg  = ErrMsg & "Bad Domain Name/URL Entered<br>">
	<cfelse>
		<cfset theSubSiteURL = form.SubSiteURL />
	</cfif>
	<!--- we now have relevant bits so see if we are duplicating --->
	<cfset StructClear(theQueryWhereArguments) />
	<cfset theQueryWhereArguments.SubSiteURL = theSubSiteURL />
	<cfset theQueryWhereArguments.SubSiteId = form.SubSiteID />
	<cfset getSubSiteURL = application.SLCMS.core.DataMgr.getRecords(tablename="#application.SLCMS.config.DatabaseDetails.TableName_PortalURLTable#", data=theQueryWhereArguments, fieldList="SubSiteURLID") />
	<!--- 
	<cfquery name="getSubSiteURL" datasource="#application.SLCMS.config.datasources.CMS#">
		SELECT	SubSiteURLID
			FROM	#application.SLCMS.config.DatabaseDetails.TableName_PortalURLTable#
			Where SubSiteURL = <cfqueryparam value="#theSubSiteURL#" cfsqltype="cf_sql_varchar" list="false" maxlength="255">
				and SubSiteId = <cfqueryparam value="#form.SubSiteID#" cfsqltype="cf_sql_integer">
	</cfquery>
	 --->
	<cfif getSubSiteURL.RecordCount>
		<cfset OK = False />
		<cfset ErrFlag  = True>
		<cfset ErrMsg  = ErrMsg & "That URL already exists<br>">
	</cfif>
	<!--- validated so throw it in --->
	<cfif OK>
		<cfset StructClear(theQueryDataArguments) />
		<cfset theQueryDataArguments.SubSiteURL = theSubSiteURL />
		<cfset theQueryDataArguments.SubSiteID = form.SubSiteID />
		<cfset theQueryDataArguments.SubSiteURLId = Nexts_getNextID('SubSiteURLId') />
		<cfset setSubSiteURL = application.SLCMS.core.DataMgr.InsertRecord(tablename="#application.SLCMS.config.DatabaseDetails.TableName_PortalURLTable#", data=theQueryDataArguments) />
		<!--- 
		<cfset theNextSubSiteURLId = application.SLCMS.mbc_utility.utilities.getNextID('SubSiteURLId') />
		<cfquery name="setSubSiteURL" datasource="#application.SLCMS.config.datasources.CMS#">
			Insert into	#application.SLCMS.config.DatabaseDetails.TableName_PortalURLTable#
								(SubSiteURL, SubSiteID, SubSiteURLId)
				values	(<cfqueryparam value="#theSubSiteURL#" cfsqltype="cf_sql_varchar" list="false" maxlength="255">,
									<cfqueryparam value="#form.SubSiteID#" cfsqltype="cf_sql_integer" >,
									<cfqueryparam value="#theNextSubSiteURLId#" cfsqltype="cf_sql_integer">)
		</cfquery>
		 --->
		<cfset GoodMsg = "New URL for Subsite &quot;#form.SubSiteFriendlyName#&quot; has been saved" />"
		<!--- finished so refresh the structures and then back to the listing --->
		<cfset ret = application.SLCMS.Core.PortalControl.Refresh() />
		<cfset WorkMode2 = "GetBaseDisplayItems">
		<cfset DispMode = "ShowBaseDisplayItems">
	<cfelse>
		<!--- It was not good so back to the form with message --->
		<cfset dURLID = form.SubSiteURLID />
		<cfset dURL = form.SubSiteURL />
		<cfset dSubSiteFriendlyName = form.SubSiteFriendlyName />
		<cfset dSubSiteID = form.SubSiteID />
		<cfset opnext = "SaveEditSubSiteURL">	<!--- what we do next --->
		<cfset DispMode = "EditSubSiteURL">
	</cfif>

<cfelseif WorkMode1 eq "EditSubSiteURL">
	<!--- set up to edit a subsite URL --->
	<cfif structKeyExists(url, "SubSiteID") and IsNumeric(url.SubSiteID)>
		<cfset theURLdataGet = application.SLCMS.Core.PortalControl.GetSubSite(SubSiteID=url.SubSiteID) />
		<cfif theURLdataGet.error.errorcode eq 0>
			<cfset theURLdata = theURLdataGet.data />
			<cfset dURLID = theURLdata.URLs.Details["URLid_#url.SubSiteURLID#"].SubSiteURLID />
			<cfset dURL = theURLdata.URLs.Details["URLid_#url.SubSiteURLID#"].SubSiteURL />
			<cfset dSubSiteFriendlyName = theURLdata.SubSiteFriendlyName />
			<cfset dSubSiteID = url.SubSiteID />
			<cfset opnext = "SaveEditSubSiteURL">	<!--- what we do next --->
			<cfset DispMode = "EditSubSiteURL">
		<cfelse>
			<cfset ErrFlag  = True>
			<cfset ErrMsg  = "SubSite data get failed. Error message was: #theURLdataGet.error.errortext#">
			<cfset WorkMode2 = "GetBaseDisplayItems">
			<cfset DispMode = "ShowBaseDisplayItems">
		</cfif>
	<cfelse>
		<cfset ErrFlag  = True>
		<cfset ErrMsg  = "Bad SubSiteID URL parameter">
		<cfset WorkMode2 = "GetBaseDisplayItems">
		<cfset DispMode = "ShowBaseDisplayItems">
	</cfif>
	
<cfelseif WorkMode1 eq "SaveEditSubSiteURL">
	<!--- save an edited SubSite URL into the system --->
	<!--- first check that we have valid input --->
	<cfset OK = True />
	<cfset theSubSiteURL = "" />
	<cfif len(form.SubSiteURL) eq 0>
		<cfset OK = False />
		<cfset ErrFlag  = True>
		<cfset ErrMsg  = ErrMsg & "No URL Entered<br>">
	<cfelseif not application.SLCMS.mbc_utility.utilities.IsValidDomainName(form.SubSiteURL)>
		<cfset OK = False />
		<cfset ErrFlag  = True>
		<cfset ErrMsg  = ErrMsg & "Bad Domain Name Entered<br>">
	<cfelse>
		<cfset theSubSiteURL = form.SubSiteURL />
	</cfif>
	<!--- we now have relevant bits so see if we are duplicating --->
	<cfset StructClear(theQueryWhereArguments) />
	<cfset ArrayClear(theQueryWhereFilters) />
	<cfset theQueryWhereArguments.SubSiteURL = theSubSiteURL />
	<cfset theQueryWhereArguments.SubSiteId = form.SubSiteID />
	<cfset theQueryWhereFilters[1] = {field="SubSiteURLId", operator="<>", value="#form.SubSiteURLID#"} />
	<cfset getSubSiteURL = application.SLCMS.core.DataMgr.getRecords(tablename="#application.SLCMS.config.DatabaseDetails.TableName_PortalURLTable#", data=theQueryWhereArguments, filters=theQueryWhereFilters, fieldList="SubSiteURLID") />
	<!--- 
	<cfquery name="getSubSiteURL" datasource="#application.SLCMS.config.datasources.CMS#">
		SELECT	SubSiteURLID
			FROM	#application.SLCMS.config.DatabaseDetails.TableName_PortalURLTable#
			Where SubSiteURL = <cfqueryparam value="#theSubSiteURL#" cfsqltype="cf_sql_varchar" list="false" maxlength="255">
				and	SubSiteURLId <> <cfqueryparam value="#form.SubSiteURLID#" cfsqltype="cf_sql_integer">
				and SubSiteId = <cfqueryparam value="#form.SubSiteID#" cfsqltype="cf_sql_integer">
	</cfquery>
	 --->
	<cfif getSubSiteURL.RecordCount>
		<cfset OK = False />
		<cfset ErrFlag  = True>
		<cfset ErrMsg  = ErrMsg & "That URL already exists<br>">
	</cfif>
	<!--- validated so throw it in --->
	<cfif OK>
		<cfset StructClear(theQueryDataArguments) />
		<cfset StructClear(theQueryWhereArguments) />
		<cfset theQueryDataArguments.SubSiteURL = theSubSiteURL />
		<cfset theQueryWhereArguments.SubSiteURLId = form.SubSiteURLId />
		<cfset setSubSiteURL = application.SLCMS.core.DataMgr.UpdateRecords(tablename="#application.SLCMS.config.DatabaseDetails.TableName_PortalURLTable#", data_set=theQueryDataArguments, data_where=theQueryWhereArguments) />
		<!--- 
		<cfquery name="setSubSiteURL" datasource="#application.SLCMS.config.datasources.CMS#">
			Update	#application.SLCMS.config.DatabaseDetails.TableName_PortalURLTable#
				set		SubSiteURL = <cfqueryparam value="#theSubSiteURL#" cfsqltype="cf_sql_varchar" list="false" maxlength="255">
				where	SubSiteURLId = <cfqueryparam value="#form.SubSiteURLId#" cfsqltype="cf_sql_integer">
		</cfquery>
		 --->
		<cfset GoodMsg = "Edits to URL for Subsite &quot;#form.SubSiteFriendlyName#&quot; have been saved" />"
		<!--- finished so refresh the structures and then back to the listing --->
		<cfset ret = application.SLCMS.Core.PortalControl.Refresh() />
		<cfset WorkMode2 = "GetBaseDisplayItems">
		<cfset DispMode = "ShowBaseDisplayItems">
	<cfelse>
		<!--- It was not good so back to the form with message --->
		<cfset dURLID = form.SubSiteURLID />
		<cfset dURL = form.SubSiteURL />
		<cfset dSubSiteFriendlyName = form.SubSiteFriendlyName />
		<cfset dSubSiteID = form.SubSiteID />
		<cfset opnext = "SaveEditSubSiteURL">	<!--- what we do next --->
		<cfset DispMode = "EditSubSiteURL">
	</cfif>

<cfelseif WorkMode1 eq "DeleteURL">
	<!--- delete a URL from the system --->
	<cfset StructClear(theQueryWhereArguments) />
	<cfset theQueryWhereArguments.SubSiteURLId = url.SubSiteURLId />
	<cfset delURL = application.SLCMS.core.DataMgr.DeleteRecords(tablename="#application.SLCMS.config.DatabaseDetails.TableName_PortalURLTable#", data=theQueryWhereArguments) />
	<!--- 
	<cfquery name="delURL" datasource="#application.SLCMS.config.datasources.CMS#">
		Delete from	#application.SLCMS.config.DatabaseDetails.TableName_PortalURLTable#
			where	SubSiteURLId = <cfqueryparam value="#url.SubSiteURLId#" cfsqltype="cf_sql_integer">
	</cfquery>
	 --->
	<cfset GoodMsg = "URL Deleted" />"
	<!--- finished so refresh the structures and then back to the listing --->
	<cfset ret = application.SLCMS.Core.PortalControl.Refresh() />
	<cfset WorkMode2 = "GetBaseDisplayItems">
	<cfset DispMode = "ShowBaseDisplayItems">

<cfelseif WorkMode1 eq "EditNavName">
	<!--- set up to edit a subsite's menu name --->
	<cfif structKeyExists(url, "SubSiteID") and IsNumeric(url.SubSiteID)>
		<cfset theURLdataGet = application.SLCMS.Core.PortalControl.GetSubSite(SubSiteID=url.SubSiteID) />
		<cfif theURLdataGet.error.errorcode eq 0>
			<cfset theURLdata = theURLdataGet.data />
			<cfset dSubSiteFriendlyName = theURLdata.SubSiteFriendlyName />
			<cfset dSubSiteNavName = theURLdata.SubSiteNavName />
			<cfset dSubSiteID = url.SubSiteID />
			<cfset opnext = "SaveEditNavName">	<!--- what we do next --->
			<cfset DispMode = "EditNavName">
		<cfelse>
			<cfset ErrFlag  = True>
			<cfset ErrMsg  = "SubSite data get failed. Error message was: #theURLdataGet.error.errortext#">
			<cfset WorkMode2 = "GetBaseDisplayItems">
			<cfset DispMode = "ShowBaseDisplayItems">
		</cfif>
	<cfelse>
		<cfset ErrFlag  = True>
		<cfset ErrMsg  = "Bad SubSiteID URL parameter">
		<cfset WorkMode2 = "GetBaseDisplayItems">
		<cfset DispMode = "ShowBaseDisplayItems">
	</cfif>
	
<cfelseif WorkMode1 eq "SaveEditNavName">
	<!--- save an edited SubSite menu name into the system --->
	<!--- first check that we have valid input for the mere dribble of data here --->
	<cfset OK = True />
	<cfset theSubSiteURL = "" />
	<cfif len(form.SubSiteNavName) eq 0>
		<cfset OK = False />
		<cfset ErrFlag  = True>
		<cfset ErrMsg  = ErrMsg & "No Menu Name Entered<br>">
	<cfelse>
		<cfset theSubSiteNavName = form.SubSiteNavName />
	</cfif>
	<!--- we now have relevant bits so see if we are duplicating another one (don't care if its own unchanged) --->
	<!--- 
	<cfset StructClear(theQueryWhereArguments) />
	<cfset theQueryWhereArguments.SubSiteShortName = theSubSiteNavName />
	<cfset getSubSiteNameN = application.SLCMS.core.DataMgr.getRecords(tablename="#application.SLCMS.config.DatabaseDetails.TableName_PortalControlTable#", data=theQueryWhereArguments, fieldList="SubSiteNavName") />
	 --->
	<cfquery name="getSubSiteNameN" datasource="#application.SLCMS.config.datasources.CMS#">
		SELECT	SubSiteNavName
			FROM	#application.SLCMS.config.DatabaseDetails.TableName_PortalControlTable#
			Where SubSiteShortName = <cfqueryparam value="#theSubSiteNavName#" cfsqltype="cf_sql_varchar" list="false" maxlength="50">
			 and	SubSiteID <> <cfqueryparam value="#form.subSiteID#" cfsqltype="cf_sql_integer">
	</cfquery>
	<cfif getSubSiteNameN.RecordCount>
		<cfset OK = False />
		<cfset ErrFlag  = True>
		<cfset ErrMsg  = ErrMsg & "That Name already exists<br>">
	</cfif>
	<!--- validated so throw it in --->
	<cfif OK>
		<cfset StructClear(theQueryDataArguments) />
		<cfset StructClear(theQueryWhereArguments) />
		<cfset theQueryDataArguments.SubSiteNavName = theSubSiteNavName />
		<cfset theQueryWhereArguments.SubSiteID = form.SubSiteID />
		<cfset setSubSiteDetail = application.SLCMS.core.DataMgr.UpdateRecords(tablename="#application.SLCMS.config.DatabaseDetails.TableName_PortalControlTable#", data_set=theQueryDataArguments, data_where=theQueryWhereArguments) />
		<!--- 
		<cfquery name="setSubSiteDetail" datasource="#application.SLCMS.config.datasources.CMS#">
			Update	#application.SLCMS.config.DatabaseDetails.TableName_PortalControlTable#
				set		SubSiteNavName = <cfqueryparam value="#theSubSiteNavName#" cfsqltype="cf_sql_varchar" list="false" maxlength="50">
				where	SubSiteID = <cfqueryparam value="#form.SubSiteID#" cfsqltype="cf_sql_integer" >
		</cfquery>
		 --->
		<cfset GoodMsg = "Edits to Menu Name for Subsite &quot;#form.SubSiteFriendlyName#&quot; have been saved" />"
		<!--- finished so refresh the structures and then back to the listing --->
		<cfset ret = application.SLCMS.Core.PortalControl.Refresh() />
		<cfset WorkMode2 = "GetBaseDisplayItems">
		<cfset DispMode = "ShowBaseDisplayItems">
	<cfelse>
		<!--- It was not good so back to the form with message --->
		<cfset dURLID = form.SubSiteURLID />
		<cfset dURL = form.SubSiteURL />
		<cfset dSubSiteFriendlyName = form.SubSiteFriendlyName />
		<cfset dSubSiteID = form.SubSiteID />
		<cfset opnext = "SaveEditSubSiteURL">	<!--- what we do next --->
		<cfset DispMode = "EditSubSiteURL">
	</cfif>

<cfelseif WorkMode1 eq "ActivateSubSite">
	<!--- mark a sub site as active --->
	<cfif StructKeyExists(url, "SubSiteID") and IsNumeric(url.SubSiteID)>
		<cfset StructClear(theQueryDataArguments) />
		<cfset StructClear(theQueryWhereArguments) />
		<cfset theQueryDataArguments.SubSiteActive = 1 />
		<cfset theQueryWhereArguments.SubSiteID = url.SubSiteID />
		<cfset setSubSiteActive = application.SLCMS.core.DataMgr.UpdateRecords(tablename="#application.SLCMS.config.DatabaseDetails.TableName_PortalControlTable#", data_set=theQueryDataArguments, data_where=theQueryWhereArguments) />
		<!--- 
		<cfquery name="setSubSiteURL" datasource="#application.SLCMS.config.datasources.CMS#">
			Update	#application.SLCMS.config.DatabaseDetails.TableName_PortalControlTable#
				set		SubSiteActive = <cfqueryparam value="1" cfsqltype="cf_sql_integer">
				where	SubSiteId = <cfqueryparam value="#url.SubSiteId#" cfsqltype="cf_sql_integer">
		</cfquery>
		 --->
		<!--- finished, database updated so refresh the structures and then back to the listing --->
		<cfset GoodMsg = "Subsite has been made Active" />"
		<cfset ret = application.SLCMS.Core.PortalControl.Refresh() />	<!--- this make the portal CFC pick up the changes --->
		<cfset ret = application.SLCMS.Core.ModuleController.ReInitAfter(Action="subSite") />	<!--- this makes everything else pick up the changes --->
		<cfset WorkMode2 = "GetBaseDisplayItems">
		<cfset DispMode = "ShowBaseDisplayItems">
	<cfelse>
		<cfset ErrFlag  = True>
		<cfset ErrMsg  = ErrMsg & "Invalid SubSiteID<br>">
	</cfif>

<cfelseif WorkMode1 eq "InActivateSubSite">
	<!--- mark a sub site as inactive --->
	<cfif StructKeyExists(url, "SubSiteID") and IsNumeric(url.SubSiteID)>
		<cfset StructClear(theQueryDataArguments) />
		<cfset StructClear(theQueryWhereArguments) />
		<cfset theQueryDataArguments.SubSiteActive = 0 />
		<cfset theQueryWhereArguments.SubSiteID = url.SubSiteID />
		<cfset setSubSiteInActive = application.SLCMS.core.DataMgr.UpdateRecords(tablename="#application.SLCMS.config.DatabaseDetails.TableName_PortalControlTable#", data_set=theQueryDataArguments, data_where=theQueryWhereArguments) />
		<!--- 
		<cfquery name="setSubSiteURL" datasource="#application.SLCMS.config.datasources.CMS#">
			Update	#application.SLCMS.config.DatabaseDetails.TableName_PortalControlTable#
				set		SubSiteActive = <cfqueryparam value="0" cfsqltype="cf_sql_integer">
				where	SubSiteId = <cfqueryparam value="#url.SubSiteId#" cfsqltype="cf_sql_integer">
		</cfquery>
		 --->
		<!--- finished so refresh the structures and then back to the listing --->
		<cfset GoodMsg = "Subsite has been made Inactive" />"
		<cfset ret = application.SLCMS.Core.PortalControl.Refresh() />
		<cfset ret = application.SLCMS.Core.ModuleController.ReInitAfter(Action="subSite") />	<!--- this makes everything else pick up the changes --->
		<cfset WorkMode2 = "GetBaseDisplayItems">
		<cfset DispMode = "ShowBaseDisplayItems">
	<cfelse>
		<cfset ErrFlag  = True>
		<cfset ErrMsg  = ErrMsg & "Invalid SubSiteID<br>">
	</cfif>

	<!--- for fun at the end we have the biggy, creating a new subsite --->
<cfelseif WorkMode1 eq "CreateSubSite_Phase1">
	<cfset dFriendlyName = "" />
	<cfset dShortName = "" />
	<cfset dNavName = "" />
	<cfset durl = "" />
	<cfset opNext = "SaveCreateSubSite">
	<cfset DispMode = "DisplayCreateSubSite">
	
	
<cfelseif WorkMode1 eq "SaveCreateSubSite">
	<!--- we are creating a new subsite --->
	<!--- first validation --->
	<cfset OK = True />
	<cfset theSubSiteFriendlyName = "" />
	<cfset theSubSiteShortName = "" />
	<cfset theSubSiteURL = "" />
	<cfif len(form.SubSiteFriendlyName) eq 0>
		<cfset OK = False />
		<cfset ErrFlag  = True>
		<cfset ErrMsg  = ErrMsg & "No Friendly Name Entered<br>">
	<cfelse>
		<cfset theSubSiteFriendlyName = form.SubSiteFriendlyName />
	</cfif>
	<cfif len(form.SubSiteShortName) eq 0>
		<cfset OK = False />
		<cfset ErrFlag  = True>
		<cfset ErrMsg  = ErrMsg & "No Short Name Entered<br>">
	<cfelseif not application.SLCMS.mbc_utility.utilities.IsValidFolderName(form.SubSiteShortName)>
		<cfset OK = False />
		<cfset ErrFlag  = True>
		<cfset ErrMsg  = ErrMsg & "The Short Name is not a legal folder name<br>">
		<cfset theSubSiteShortName = form.SubSiteShortName />
	<cfelse>
		<cfset theSubSiteShortName = form.SubSiteShortName />
	</cfif>
	<cfif len(form.SubSiteNavName) eq 0>
		<cfset OK = False />
		<cfset ErrFlag  = True>
		<cfset ErrMsg  = ErrMsg & "No Menu Name Entered<br>">
	<cfelse>
		<cfset theSubSiteNavName = form.SubSiteNavName />
	</cfif>
	<cfif len(form.SubSiteURL) eq 0>
		<cfset OK = False />
		<cfset ErrFlag  = True>
		<cfset ErrMsg  = ErrMsg & "No URL Entered<br>">
	<cfelseif not application.SLCMS.mbc_utility.utilities.IsValidDomainName(form.SubSiteURL)>
		<cfset OK = False />
		<cfset ErrFlag  = True>
		<cfset ErrMsg  = ErrMsg & "Bad Domain Name Entered<br>">
		<cfset theSubSiteURL = form.SubSiteURL />
	<cfelse>
		<cfset theSubSiteURL = form.SubSiteURL />
	</cfif>
	<cfif OK>
		<!--- we now have relevant bits so see if we are duplicating --->
		<cfset StructClear(theQueryWhereArguments) />
		<cfset theQueryWhereArguments.SubSiteFriendlyName = theSubSiteFriendlyName />
		<cfset getSubSiteNameF = application.SLCMS.core.DataMgr.getRecords(tablename="#application.SLCMS.config.DatabaseDetails.TableName_PortalControlTable#", data=theQueryWhereArguments, fieldList="SubSiteFriendlyName") />
		<!--- 
		<cfquery name="getSubSiteNameF" datasource="#application.SLCMS.config.datasources.CMS#">
			SELECT	SubSiteFriendlyName
				FROM	#application.SLCMS.config.DatabaseDetails.TableName_PortalControlTable#
				Where SubSiteFriendlyName = <cfqueryparam value="#theSubSiteFriendlyName#" cfsqltype="cf_sql_varchar" list="false" maxlength="255">
		</cfquery>
		 --->
		<cfset StructClear(theQueryWhereArguments) />
		<cfset theQueryWhereArguments.SubSiteShortName = theSubSiteShortName />
		<cfset getSubSiteNameS = application.SLCMS.core.DataMgr.getRecords(tablename="#application.SLCMS.config.DatabaseDetails.TableName_PortalControlTable#", data=theQueryWhereArguments, fieldList="SubSiteFriendlyName") />
		<!--- 
		<cfquery name="getSubSiteNameS" datasource="#application.SLCMS.config.datasources.CMS#">
			SELECT	SubSiteShortName
				FROM	#application.SLCMS.config.DatabaseDetails.TableName_PortalControlTable#
				Where SubSiteShortName = <cfqueryparam value="#theSubSiteShortName#" cfsqltype="cf_sql_varchar" list="false" maxlength="255">
		</cfquery>
		 --->
		<cfset StructClear(theQueryWhereArguments) />
		<cfset theQueryWhereArguments.SubSiteNavName = theSubSiteNavName />
		<cfset getSubSiteNameN = application.SLCMS.core.DataMgr.getRecords(tablename="#application.SLCMS.config.DatabaseDetails.TableName_PortalControlTable#", data=theQueryWhereArguments, fieldList="SubSiteFriendlyName") />
		<!--- 
		<cfquery name="getSubSiteNameN" datasource="#application.SLCMS.config.datasources.CMS#">
			SELECT	SubSiteNavName
				FROM	#application.SLCMS.config.DatabaseDetails.TableName_PortalControlTable#
				Where SubSiteShortName = <cfqueryparam value="#theSubSiteNavName#" cfsqltype="cf_sql_varchar" list="false" maxlength="50">
		</cfquery>
		 --->
		<cfset StructClear(theQueryWhereArguments) />
		<cfset theQueryWhereArguments.BaseURL = theSubSiteURL />
		<cfset getSubSiteBaseURL = application.SLCMS.core.DataMgr.getRecords(tablename="#application.SLCMS.config.DatabaseDetails.TableName_PortalControlTable#", data=theQueryWhereArguments, fieldList="SubSiteFriendlyName") />
		<cfset StructClear(theQueryWhereArguments) />
		<cfset theQueryWhereArguments.SubSiteURL = theSubSiteURL />
		<cfset getSubSiteURLs = application.SLCMS.core.DataMgr.getRecords(tablename="#application.SLCMS.config.DatabaseDetails.TableName_PortalURLTable#", data=theQueryWhereArguments, fieldList="SubSiteURL") />
<!---	
		<cfdump var="#theQueryWhereArguments#" expand="false" label="theQueryWhereArguments">
		<cfdump var="#getSubSiteBaseURL#" expand="false" label="getSubSiteBaseURL">
		<cfdump var="#getSubSiteURLs#" expand="false" label="getSubSiteURLs">
		<cfabort>
--->									
		<!--- 
		<cfquery name="getSubSiteURL" datasource="#application.SLCMS.config.datasources.CMS#">
			SELECT	SubSiteURLID
				FROM	#application.SLCMS.config.DatabaseDetails.TableName_PortalURLTable#
				Where SubSiteURL = <cfqueryparam value="#theSubSiteURL#" cfsqltype="cf_sql_varchar" list="false" maxlength="255">
		</cfquery>
		 --->
		<cfif getSubSiteNameF.RecordCount>
			<cfset OK = False />
			<cfset ErrFlag  = True>
			<cfset ErrMsg  = ErrMsg & "That Friendly Name already exists<br>">
		</cfif>
		<cfif getSubSiteNameS.RecordCount>
			<cfset OK = False />
			<cfset ErrFlag  = True>
			<cfset ErrMsg  = ErrMsg & "That Short Name already exists<br>">
		</cfif>
		<cfif getSubSiteNameN.RecordCount>
			<cfset OK = False />
			<cfset ErrFlag  = True>
			<cfset ErrMsg  = ErrMsg & "That Menu Name already exists<br>">
		</cfif>
		<cfif getSubSiteBaseURL.RecordCount or getSubSiteURLs.RecordCount>
			<cfset OK = False />
			<cfset ErrFlag  = True>
			<cfset ErrMsg  = ErrMsg & "That URL already exists<br>">
		</cfif>
	</cfif>
	<!--- fully validated so throw it in --->
	<cfif OK>
		<cfset theNewSubSiteID = Nexts_getNextID("SubSiteID") />
		<cfset StructClear(theQueryDataArguments) />
		<cfset theQueryDataArguments.theSubSiteFriendlyName = theSubSiteFriendlyName />
		<cfset theQueryDataArguments.SubSiteShortName = theSubSiteShortName />
		<cfset theQueryDataArguments.theSubSiteNavName = theSubSiteNavName />
		<cfset theQueryDataArguments.flagAllowSubSite = 0 />
		<cfset theQueryDataArguments.SubSiteActive = 0 />
		<cfset theQueryDataArguments.SubSiteID = theNewSubSiteID />
		<cfset setSubSiteDetail = application.SLCMS.core.DataMgr.InsertRecord(tablename="#application.SLCMS.config.DatabaseDetails.TableName_PortalControlTable#", data=theQueryDataArguments) />
		<!--- 
		<cfquery name="setSubSiteDetail" datasource="#application.SLCMS.config.datasources.CMS#">
			insert into	#application.SLCMS.config.DatabaseDetails.TableName_PortalControlTable#
								(SubSiteFriendlyName, SubSiteShortName, SubSiteNavName, flagAllowSubSite, SubSiteActive, SubSiteID)
				values	(<cfqueryparam value="#theSubSiteFriendlyName#" cfsqltype="cf_sql_varchar" list="false" maxlength="255">,
									<cfqueryparam value="#theSubSiteShortName#" cfsqltype="cf_sql_varchar" list="false" maxlength="255">,
									<cfqueryparam value="#theSubSiteNavName#" cfsqltype="cf_sql_varchar" list="false" maxlength="50">,
									<cfqueryparam value="0" cfsqltype="cf_sql_integer">,
									<cfqueryparam value="0" cfsqltype="cf_sql_integer">,
									<cfqueryparam value="#theNewSubSiteID#" cfsqltype="cf_sql_integer" >)
		</cfquery>
		 --->
		<cfset StructClear(theQueryDataArguments) />
		<cfset theQueryDataArguments.SubSiteURL = theSubSiteURL />
		<cfset theQueryDataArguments.SubSiteID = theNewSubSiteID />
		<cfset theQueryDataArguments.SubSiteURLId = Nexts_getNextID("SubSiteURLID") />
		<cfset setSubSiteURL = application.SLCMS.core.DataMgr.InsertRecord(tablename="#application.SLCMS.config.DatabaseDetails.TableName_PortalURLTable#", data=theQueryDataArguments) />
		<!--- 
		<cfset theNewSubSiteURLID = application.SLCMS.mbc_utility.utilities.GetNextID("SubSiteURLID") />
		<cfquery name="setSubSiteURL" datasource="#application.SLCMS.config.datasources.CMS#">
			insert into	#application.SLCMS.config.DatabaseDetails.TableName_PortalURLTable#
								(SubSiteURL, SubSiteID, SubSiteURLId)
				values	(<cfqueryparam value="#theSubSiteURL#" cfsqltype="cf_sql_varchar" list="false" maxlength="255">,
									<cfqueryparam value="#theNewSubSiteID#" cfsqltype="cf_sql_integer" >,
									<cfqueryparam value="#theNewSubSiteURLId#" cfsqltype="cf_sql_integer">)
		</cfquery>
		 --->
		<!--- now we create a set of tables for this site --->
		<cfset ret = application.SLCMS.Core.Versions_Master.CreateSubSite(SubSiteID="#theNewSubSiteID#", SubSiteShortName="#theSubSiteShortName#") /> 
		<cfif ret.error.errorcode eq 0>
		<cfelse>
		</cfif>
		<!--- 
		<cfset ret = application.SLCMS.Core.PortalControl.CreateSubSiteTableSet(SubSiteID="#theNewSubSiteID#", SubSiteShortName="#theSubSiteShortName#") />
		<cfif ret.error.errorcode eq 0>
		<cfelse>
		</cfif>
		 --->
		<cfset GoodMsg = "New Subsite has been Created" />"
		<cfset ret = application.SLCMS.Core.PortalControl.Refresh() />
		<cfset ret = application.SLCMS.Core.ModuleController.ReInitAfter(Action="subSite") />	<!--- this makes everything else pick up the changes --->
		<cfset WorkMode2 = "GetBaseDisplayItems">
		<cfset DispMode = "ShowBaseDisplayItems">
	
	<cfelse>
		<!--- invalid so have another go --->
		<cfset dFriendlyName = theSubSiteFriendlyName />
		<cfset dShortName = theSubSiteShortName />
		<cfset dNavName = theSubSiteNavName />
		<cfset durl = theSubSiteURL />
		<cfset opNext = "SaveCreateSubSite">
		<cfset DispMode = "DisplayCreateSubSite">
	</cfif>	

</cfif>	<!--- end: WorkMode1 choice --->

<!--- now do the second-pass stuff --->
<cfif WorkMode2 eq "zzz">
	<!--- do things --->
	<cfset DispMode = "yyy">
<cfelseif WorkMode2 eq "GetBaseDisplayItems">
	<!--- get a list of the portal subsites --->
	<cfset theBaseURL = application.SLCMS.Core.PortalControl.GetPortalHomeURL() />
	<cfset theSubSiteCount = application.SLCMS.Core.PortalControl.GetSubSiteCount() />
	<cfset theSubSiteList = application.SLCMS.Core.PortalControl.GetSubSiteShortNameList() />
	<cfset thePortalSite = application.SLCMS.Core.PortalControl.GetSubSite(SubSiteID=0).data />
	<cfset theSubSites = application.SLCMS.Core.PortalControl.GetAllSubSites() />
<!--- 
<cfoutput>
temp dump of thePortalSite struct from workmode2 in admin_portalsubsites.cfm:<br>
</cfoutput>
<cfdump var="#thePortalSite#" expand="false">
 --->

</cfif>

<!--- 
<cfabort>
 --->
<!--- get the base display stuff --->

<cfsetting enablecfoutputonly="No">

<cfoutput>#includePartial("/slcms/adminbanner")#</cfoutput><!--- show the banner if we are in the backend, returns nothing if we are popped up --->
<cfif DispMode neq "ShowBaseDisplayItems">
	<cfoutput>
	| #linkTo(text="Back to Portal Management Home Page", controller="slcms.admin-portal", action="index", params="#PageContextFlags.ReturnLinkParams#")#</cfoutput>
</cfif>

<table border="0" cellpadding="3" cellspacing="0" >	<!--- this table has the page/menu content --->
<tr><td colspan="3"></td></tr>

<cfif DispMode eq "DisplayCreateSubSite">
	<tr><td></td><td colspan="2"></td></tr>
	<tr><td colspan="3" align="left">
	<cfoutput>
	<form name="theForm" action="#application.SLCMS.Paths_Admin.AdminBaseURL#admin-portal?#PageContextFlags.ReturnLinkParams#&amp;job=#opnext#" method="post">
<!--- 
	<input type="hidden" name="SubSiteURLID" value="#dURLID#">
	<input type="hidden" name="SubSiteID" value="#dSubSiteID#">
	<input type="hidden" name="SubSiteFriendlyName" value="#dSubSiteFriendlyName#">
 --->
	</cfoutput>
	<table border="0" cellpadding="3" cellspacing="0" align="left">
	<tr><td colspan="3" align="center"><span class="minorheadingText">
		 Creating a Subsite
		</span></td></tr>
	<tr><td colspan="3"></td></tr>
	<tr><cfoutput>
		<td colspan="1">Subsite Friendly Name: </td>
		<td colspan="2"><input type="text" name="SubSiteFriendlyName" value="#dFriendlyName#" size="40" maxlength="128"></td></tr>
	<tr>
		<td colspan="1">Subsite Short Name: </td>
		<td colspan="2"><input type="text" name="SubSiteShortName" value="#dShortName#" size="40" maxlength="128"></td></tr>
	<tr>
		<td colspan="1">Subsite Menu Name: </td>
		<td colspan="2"><input type="text" name="SubSiteNavName" value="#dNavName#" size="40" maxlength="128"></td></tr>
	<tr>
		<td colspan="1">Subsite URL: </td>
		<td colspan="2"><input type="text" name="SubSiteURL" value="#dURL#" size="40" maxlength="255"></td></tr>
	<tr><td colspan="3"></td></tr>
	<tr>
		<td></td>
		<td colspan="2"><input type="submit" name="Save" value="Create New Subsite" onClick="return confirm('Please Confirm Creation of Subsite')"></td>
		</tr>
		</cfoutput>
	</table>
	</form>
	</td></tr>

<cfelseif DispMode eq "EditNavName">
	<tr><td></td><td colspan="2"></td></tr>
	<tr><td colspan="3" align="left">
	<cfoutput>
	<form name="theForm" action="#application.SLCMS.Paths_Admin.AdminBaseURL#admin-portal?#PageContextFlags.ReturnLinkParams#&amp;job=#opnext#" method="post">
	<input type="hidden" name="SubSiteID" value="#dSubSiteID#">
	<input type="hidden" name="SubSiteFriendlyName" value="#dSubSiteFriendlyName#">
	<table border="0" cellpadding="3" cellspacing="0" align="left">
	<tr><td colspan="3" align="center"><span class="minorheadingText">
		 Editing the Menu (Navigation) Name for Subsite: #dSubSiteFriendlyName#
		</span></td></tr>
	<tr><td colspan="3"></td></tr>
	<tr>
		<td colspan="1">Subsite Menu Name: </td>
		<td colspan="2"><input type="text" name="SubSiteNavName" value="#dSubSiteNavName#" size="40" maxlength="128"></td></tr>
	<tr><td colspan="3"></td></tr>
	<tr>
		<td></td>
		<td colspan="2"><input type="submit" name="Save" value="Save Menu Name"></td>
		</tr>
	</table>
	</form>
	</cfoutput>
	</td></tr>

<cfelseif DispMode eq "AddSubSiteURL" or DispMode eq "EditSubSiteURL" or DispMode eq "AddTopURL" or DispMode eq "EditTopSiteURL" or DispMode eq "EditBaseURL">
	<tr><td></td><td colspan="2"></td></tr>
	<tr><td colspan="3" align="left">
	<cfoutput>
	<form name="theForm" action="#application.SLCMS.Paths_Admin.AdminBaseURL#admin-portal?#PageContextFlags.ReturnLinkParams#&amp;job=#opnext#" method="post">
	<input type="hidden" name="SubSiteURLID" value="#dURLID#">
	<input type="hidden" name="SubSiteID" value="#dSubSiteID#">
	<input type="hidden" name="SubSiteFriendlyName" value="#dSubSiteFriendlyName#">
	</cfoutput>
	<table border="0" cellpadding="3" cellspacing="0" align="left">
	<tr><td colspan="3" align="center"><span class="minorheadingText">
		<cfif DispMode eq "AddTopURL">Adding a New URL to Portal Site:
		<cfelseif DispMode eq "EditTopSiteURL">Editing URL in Portal Site:
		<cfelseif DispMode eq "AddSubSiteURL">Adding a New URL to Subsite:
		<cfelseif DispMode eq "EditBaseURL">Editing Base URL of Portal Site:
		<cfelse>Editing URL in Subsite:
		</cfif>
		 <span class="minorheadingName"><cfoutput> #dSubSiteFriendlyName#</cfoutput></span>
		</span></td></tr>
	<tr><td colspan="3"></td></tr>
	<tr>
		<td colspan="1"><cfif DispMode eq "EditBaseURL">Base URL<cfelse>Subsite URL</cfif>: </td>
		<td colspan="2"><input type="text" name="SubSiteURL" value="<cfoutput>#dURL#</cfoutput>" size="40" maxlength="255"></td></tr>
	<tr><td colspan="3"></td></tr>
	<tr>
		<td></td>
		<td colspan="2"><input type="submit" name="Save" value="<cfif DispMode is 'AddSubSiteURL' or DispMode eq 'AddTopURL'>Create New URL<cfelse>Save Changes</cfif>"></td>
		</tr>
	</table>
	</form>
	</td></tr>

<cfelseif DispMode eq "ShowBaseDisplayItems">
	<cfoutput>
	<form name="theForm" action="#application.SLCMS.Paths_Admin.AdminBaseURL#admin-portal?#PageContextFlags.ReturnLinkParams#&amp;job=RefreshSubSite" method="post">
	<input type="hidden" name="Function" value="RefreshPortal">
	<!--- 	
	<input type="hidden" name="CurrentState" value="#yesNoFormat(thePortalsAreAllowed)#">
	 --->
	<tr><td colspan="3"></td></tr>
	<tr><td colspan="3" class="minorheadingName">Portal Capability</td></tr>
	<tr><td colspan="3"></td></tr>
	<tr>
		<td colspan="3"><p>In order that users which have logged in to the portal can maintain their state as they navigate across any subSite
			 and do not have to log in again there has to be a parent domain name for the entire portal and all subSites must have at least one URL that is a subdomain under this parent domain name.</p>
		 	<p>For example: Parent Domain is slcms.net; top site is www.slcms.net; one subSite is docs.slcms.net; another subSite is coders.slcms.net</p>
		 	<p>Anyone who browses to the parent domain name is shown the top/portal website. 
			 Other domain names can be used for the top or any subSite but 
			 if a user logs in having browsed to the subSite using such a domain name then they will be relocated to the relevant subdomain.</p>
			<p>If a common domain name is not set then the top site and subSites will still work but session state will not be maintained.</p>
		</td></tr>
	<tr><td colspan="3">
		<!--- first we show the details of the top, the portal itself --->
		<table border="0" cellpadding="3" cellspacing="0" class="worktable">
			<tr>
				<td colspan="6"><span class="minorheadingText">The Base Domain Name:-</span></td>
			</tr>
			<tr>
				<td colspan="3" rowspan="2" class="WorkTableTopRow" align="right">
					This URL should be the<br>base to all subSites:
				</td>
				<td colspan="1" class="WorkTableTopRow" align="center"><u>URL</u></td>
				<td colspan="2" class="WorkTableTopRowRHCol" align="right"></td>
			</tr>
			<tr>
<!--- 
				<td colspan="2" class="WorkTableRowColour1">
				</td>
 --->
				<td colspan="1" class="WorkTableRowColour1">
					#theBaseURL#
				</td>
				<td colspan="2" class="WorkTableRowColour1RHCol" align="center">
					#linkTo(text="Edit Base URL", controller="slcms.admin-portal", action="index", params="#PageContextFlags.ReturnLinkParams#&amp;job=EditBaseURL")#
					<!--- 
					<a href="Admin_PortalSubSites.cfm?job=EditBaseURL">Edit URL</a>
					 --->
				</td>
			</tr>
			<tr>
				<td colspan="6"><span class="minorheadingText">The Portal site:-</span></td>
			</tr>
			<tr>
				<td colspan="1" class="WorkTableTopRow" align="center"><u>Admin Name</u></td>
				<td colspan="1" class="WorkTableTopRow" align="center"><u>Folder Name</u></td>
				<td colspan="1" class="WorkTableTopRow" align="center"><u>Menu Name</u></td>
				<td colspan="1" class="WorkTableTopRow" align="center"><u>URL(s)</u></td>
				<td colspan="2" class="WorkTableTopRowRHCol" align="right">
					#linkTo(text="Add URL", controller="slcms.admin-portal", action="index", params="#PageContextFlags.ReturnLinkParams#&amp;job=AddTopURL")#
					<!--- 
					<a href="Admin_PortalSubSites.cfm?job=AddTopURL">Add URL</a>
					 --->
				</td>
			</tr>
			<cfset flagFirstLine = True />
			<cfloop collection="#thePortalSite.URLs.Details#" item="thisURL">
				<tr>
					<cfif flagFirstLine>
						<td colspan="1" rowspan="#ArrayLen(thePortalSite.URLs.Array)#" class="WorkTableRowColour1" align="center" valign="top"><span class="minorheadingName">#thePortalSite.SubSiteFriendlyName#</span></td>
						<td colspan="1" rowspan="#ArrayLen(thePortalSite.URLs.Array)#" class="WorkTableRowColour1" align="center" valign="top"><strong>#thePortalSite.SubSiteShortName#</strong></td>
						<td colspan="1" rowspan="#ArrayLen(thePortalSite.URLs.Array)#" class="WorkTableRowColour1" align="center" valign="top">
							<strong>#thePortalSite.SubSiteNavName#</strong><br>(#linkTo(text="Edit", controller="slcms.admin-portal", action="index", params="#PageContextFlags.ReturnLinkParams#&amp;job=EditNavName&amp;SubsiteID=0")#)
							<!--- 
							<a href="Admin_PortalSubSites.cfm?job=EditNavName&amp;SubsiteID=0">Edit</a>
							 --->
						</td>
						<cfset flagFirstLine = False />
					</cfif>
					<td colspan="1" class="WorkTableRowColour1">
						#thePortalSite.URLs.Details["#thisURL#"].SubSiteURL#
					</td>
					<td colspan="1" class="WorkTableRowColour1" align="center">
						#linkTo(text="Edit URL", controller="slcms.admin-portal", action="index", params="#PageContextFlags.ReturnLinkParams#&amp;job=EditTopSiteURL&amp;SubsiteURLID=#thePortalSite.URLs.Details['#thisURL#'].SubSiteURLID#")#
						<!--- 
						<a href="Admin_PortalSubSites.cfm?job=EditTopSiteURL&amp;SubsiteURLID=#thePortalSite.URLs.Details['#thisURL#'].SubSiteURLID#">Edit URL</a>
						 --->
					</td>
					<td colspan="1" class="WorkTableRowColour1RHCol" align="center">
						#linkTo(text="Delete URL", controller="slcms.admin-portal", action="index", params="#PageContextFlags.ReturnLinkParams#&amp;job=DeleteURL&amp;SubsiteURLID=#thePortalSite.URLs.Details['#thisURL#'].SubSiteURLID#", confirm='You do really want to Delete the URL: #thePortalSite.URLs.Details["#thisURL#"].SubSiteURL#?')#
						<!--- 
						<a href="Admin_PortalSubSites.cfm?job=DeleteURL&amp;SubsiteURLID=#thePortalSite.URLs.Details['#thisURL#'].SubSiteURLID#" onClick="return confirm('You do really want to Delete the URL:\n\r #thePortalSite.URLs.Details["#thisURL#"].SubSiteURL#?')">Delete URL</a>
						 --->
					</td>
				</tr>
			</cfloop>
			<!--- now we have shown the portal site we can do the subsites, if any --->
			<tr>
				<td colspan="6">&nbsp;</td>
			</tr>
			<tr>
				<td colspan="6"><span class="minorheadingText">The following Subsites exist in the portal:-</span></td>
			</tr>
			<tr>
				<td colspan="1" class="WorkTableTopRow" align="center"><u>Admin Name</u></td>
				<td colspan="1" class="WorkTableTopRow" align="center"><u>Folder Name</u></td>
				<td colspan="1" class="WorkTableTopRow" align="center"><u>Menu Name</u></td>
				<td colspan="1" class="WorkTableTopRow" align="center"><u>URL(s)</u></td>
				<td colspan="2" class="WorkTableTopRowRHCol" align="right">
					#linkTo(text="Add a Subsite", controller="slcms.admin-portal", action="index", params="#PageContextFlags.ReturnLinkParams#&amp;job=CreateSubSite_Phase1", confirm='You do really want to Create a New Subsite? This is Heavy Banana stuff so you will get the chance to opt out')#
					<!--- 
					<a href="Admin_PortalSubSites.cfm?job=CreateSubSite_Phase1" onClick="return confirm('You do really want Create a New Subsite?\n\rThis is Heavy Banana stuff, you will get the chance to opt out')">Add a Subsite</a>
					 --->
				</td>
			</tr>
			<tr>
				<td colspan="3" class="WorkTableRowColour1">Active Subsites</td>
				<td colspan="3" class="WorkTableRowColour1RHCol">&nbsp;</td>
			</tr>
			<cfset flagNoSubsites = True />
			<cfloop collection="#theSubSites#" item="thisSubSite">
				<cfif theSubSites["#thisSubSite#"].SubSiteActive and theSubSites["#thisSubSite#"].SubSiteID neq 0>
					<cfset flagNoSubsites = False />
					<tr>
						<td colspan="1" rowspan="#IncrementValue(ArrayLen(theSubSites['#thisSubSite#'].URLs.Array))#" class="WorkTableRowColour1" align="center" valign="top"><span class="minorheadingName">#theSubSites["#thisSubSite#"].SubSiteFriendlyName#</span></td>
						<td colspan="1" rowspan="#IncrementValue(ArrayLen(theSubSites['#thisSubSite#'].URLs.Array))#" class="WorkTableRowColour1" align="center" valign="top"><strong>#theSubSites["#thisSubSite#"].SubSiteShortName#</strong></td>
						<td colspan="1" rowspan="#IncrementValue(ArrayLen(theSubSites['#thisSubSite#'].URLs.Array))#" class="WorkTableRowColour1" align="center" valign="top">
							<strong>#theSubSites["#thisSubSite#"].SubSiteNavName#</strong><br>(#linkTo(text="Edit", controller="slcms.admin-portal", action="index", params="#PageContextFlags.ReturnLinkParams#&amp;job=EditNavName&amp;SubsiteID=#theSubSites["#thisSubSite#"].SubSiteID#")#)
							<!--- 
							<a href="Admin_PortalSubSites.cfm?job=EditNavName&amp;SubsiteID=#theSubSites["#thisSubSite#"].SubSiteID#">Edit</a>
							 --->
						</td>
						<td colspan="1" class="WorkTableRowColour1">
							#linkTo(text="Add URL", controller="slcms.admin-portal", action="index", params="#PageContextFlags.ReturnLinkParams#&amp;job=AddSubSiteURL&amp;SubsiteID=#theSubSites['#thisSubSite#'].SubSiteID#")#
							<!--- 
							<a href="Admin_PortalSubSites.cfm?job=AddSubSiteURL&amp;SubsiteID=#theSubSites['#thisSubSite#'].SubSiteID#">Add URL</a>
							 --->
						</td>
						<td colspan="2" class="WorkTableRowColour1RHCol" align="center">
							#linkTo(text="Make Subsite Inactive", controller="slcms.admin-portal", action="index", params="#PageContextFlags.ReturnLinkParams#&amp;job=InactivateSubSite&amp;SubsiteID=#theSubSites['#thisSubSite#'].SubSiteID#", confirm='You do really want to Deactivate the Subsite: #theSubSites['#thisSubSite#'].SubSiteFriendlyName#?')#
							<!--- 
							<a href="Admin_PortalSubSites.cfm?job=InactivateSubSite&amp;SubsiteID=#theSubSites['#thisSubSite#'].SubSiteID#" onClick="return confirm('You do really want Deactivate the Subsite: #theSubSites['#thisSubSite#'].SubSiteFriendlyName#?')">Make Subsite Inactive</a>
							 --->
						</td>
					</tr>
					<!--- 
					<cfloop from="1" to="#ArrayLen(theSubSites["#thisSubSite#"].URLs.Array)#" index="lcntr">
					 --->
					<cfloop collection="#theSubSites["#thisSubSite#"].URLs.Details#" item="thisURL">
						<tr>
							<td colspan="1" class="WorkTableRowColour1">
								#theSubSites["#thisSubSite#"].URLs.Details["#thisURL#"].SubSiteURL#
							</td>
							<td colspan="1" class="WorkTableRowColour1" align="center">
								#linkTo(text="Edit URL", controller="slcms.admin-portal", action="index", params="#PageContextFlags.ReturnLinkParams#&amp;job=EditSubSiteURL&amp;SubsiteID=#theSubSites['#thisSubSite#'].SubSiteID#&amp;SubsiteURLID=#theSubSites["#thisSubSite#"].URLs.Details['#thisURL#'].SubSiteURLID#")#
								<!--- 
								<a href="Admin_PortalSubSites.cfm?job=EditSubSiteURL&amp;SubsiteID=#theSubSites['#thisSubSite#'].SubSiteID#&amp;SubsiteURLID=#theSubSites["#thisSubSite#"].URLs.Details['#thisURL#'].SubSiteURLID#">Edit URL</a>
								 --->
							</td>
							<td colspan="1" class="WorkTableRowColour1RHCol" align="center">
								#linkTo(text="Delete URL", controller="slcms.admin-portal", action="index", params="#PageContextFlags.ReturnLinkParams#&amp;job=DeleteURL&amp;SubsiteURLID=#theSubSites['#thisSubSite#'].URLs.Details['#thisURL#'].SubSiteURLID#", confirm='You do really want to Delete the URL: #theSubSites['#thisSubSite#'].URLs.Details["#thisURL#"].SubSiteURL#?')#
								<!--- 
								<a href="Admin_PortalSubSites.cfm?job=DeleteURL&amp;SubsiteURLID=#theSubSites['#thisSubSite#'].URLs.Details['#thisURL#'].SubSiteURLID#" onClick="return confirm('You do really want to Delete the URL:\n\r #theSubSites['#thisSubSite#'].URLs.Details["#thisURL#"].SubSiteURL#?')">Delete URL</a>
								 --->
							</td>
						</tr>
					</cfloop>	<!--- end: loop over URLs --->
				</cfif>	<!--- end: active check --->
			</cfloop>	<!--- end: loop over subsites --->
			<cfif flagNoSubsites>
			<tr>
				<td colspan="1" class="WorkTableRowColour1">&nbsp;</td>
				<td colspan="1" class="WorkTableRowColour1" align="center"><strong>None</strong></td>
				<td colspan="1" class="WorkTableRowColour1">&nbsp;</td>
				<td colspan="3" class="WorkTableRowColour1RHCol">&nbsp;</td>
			</tr>
			</cfif>
			<!--- now do it again for the inactive subsites --->
			<cfset flagNoSubsites = True />
			<tr><td colspan="6" class="WorkTableRowColour1RHCol"></td></tr>
			<tr>
				<td colspan="3" class="WorkTableRowColour1">InActive Subsites</td>
				<td colspan="3" class="WorkTableRowColour1RHCol">&nbsp;</td>
			</tr>
			<cfloop collection="#theSubSites#" item="thisSubSite">
				<cfif theSubSites["#thisSubSite#"].SubSiteActive eq False and theSubSites["#thisSubSite#"].SubSiteID neq 0>
					<cfset flagNoSubsites = False />
					<tr>
						<td colspan="1" rowspan="#IncrementValue(ArrayLen(theSubSites['#thisSubSite#'].URLs.Array))#" class="WorkTableRowColour1" align="center" valign="top"><span class="minorheadingName">#theSubSites["#thisSubSite#"].SubSiteFriendlyName#</span></td>
						<td colspan="1" rowspan="#IncrementValue(ArrayLen(theSubSites['#thisSubSite#'].URLs.Array))#" class="WorkTableRowColour1" align="center" valign="top"><strong>#theSubSites["#thisSubSite#"].SubSiteShortName#</strong></td>
						<td colspan="1" rowspan="#IncrementValue(ArrayLen(theSubSites['#thisSubSite#'].URLs.Array))#" class="WorkTableRowColour1" align="center" valign="top">
							<strong>#theSubSites["#thisSubSite#"].SubSiteNavName#</strong><br>(#linkTo(text="Edit", controller="slcms.admin-portal", action="index", params="#PageContextFlags.ReturnLinkParams#&amp;job=EditNavName&amp;SubsiteID=#theSubSites["#thisSubSite#"].SubSiteID#")#)
							<!--- 
								<a href="Admin_PortalSubSites.cfm?job=EditNavName&amp;SubsiteID=#theSubSites["#thisSubSite#"].SubSiteID#">Edit</a>
							 --->
						</td>
						<td colspan="1" class="WorkTableRowColour1">
							#linkTo(text="Add URL", controller="slcms.admin-portal", action="index", params="#PageContextFlags.ReturnLinkParams#&amp;job=AddSubSiteURL&amp;SubsiteID=#theSubSites['#thisSubSite#'].SubSiteID#")#
							<!--- 
							<a href="Admin_PortalSubSites.cfm?job=AddSubSiteURL&amp;SubsiteID=#theSubSites['#thisSubSite#'].SubSiteID#">Add URL</a>
							 --->
						</td>
						<td colspan="2" class="WorkTableRowColour1RHCol" align="center">
							#linkTo(text="Make Subsite active", controller="slcms.admin-portal", action="index", params="#PageContextFlags.ReturnLinkParams#&amp;job=ActivateSubSite&amp;SubsiteID=#theSubSites['#thisSubSite#'].SubSiteID#", confirm='You do really want to Aactivate the Subsite: #theSubSites['#thisSubSite#'].SubSiteFriendlyName#?')#
							<!--- 
							<a href="Admin_PortalSubSites.cfm?job=ActivateSubSite&amp;SubsiteID=#theSubSites['#thisSubSite#'].SubSiteID#" onClick="return confirm('You do really want Activate the Subsite: #theSubSites['#thisSubSite#'].SubSiteFriendlyName#?')">Make Subsite Active</a>
							 --->
						</td>
					</tr>
					<cfloop collection="#theSubSites["#thisSubSite#"].URLs.Details#" item="thisURL">
						<tr>
							<td colspan="1" class="WorkTableRowColour1">
								#theSubSites["#thisSubSite#"].URLs.Details["#thisURL#"].SubSiteURL#
							</td>
							<td colspan="1" class="WorkTableRowColour1" align="center">
								#linkTo(text="Edit URL", controller="slcms.admin-portal", action="index", params="#PageContextFlags.ReturnLinkParams#&amp;job=EditSubSiteURL&amp;SubsiteID=#theSubSites['#thisSubSite#'].SubSiteID#&amp;SubsiteURLID=#theSubSites["#thisSubSite#"].URLs.Details['#thisURL#'].SubSiteURLID#")#
								<!--- 
								<a href="Admin_PortalSubSites.cfm?job=EditSubSiteURL&amp;SubsiteID=#theSubSites['#thisSubSite#'].SubSiteID#&amp;SubsiteURLID=#theSubSites["#thisSubSite#"].URLs.Details['#thisURL#'].SubSiteURLID#">Edit URL</a>
								 --->
							</td>
							<td colspan="1" class="WorkTableRowColour1RHCol" align="center">
								#linkTo(text="Delete URL", controller="slcms.admin-portal", action="index", params="#PageContextFlags.ReturnLinkParams#&amp;job=DeleteURL&amp;SubsiteURLID=#theSubSites['#thisSubSite#'].URLs.Details['#thisURL#'].SubSiteURLID#", confirm='You do really want to Delete the URL: #theSubSites['#thisSubSite#'].URLs.Details["#thisURL#"].SubSiteURL#?')#
								<!--- 
								<a href="Admin_PortalSubSites.cfm?job=DeleteURL&amp;SubsiteURLID=#theSubSites['#thisSubSite#'].URLs.Details['#thisURL#'].SubSiteURLID#" onClick="return confirm('You do really want to Delete the URL:\n\r #theSubSites['#thisSubSite#'].URLs.Details["#thisURL#"].SubSiteURL#?')">Delete URL</a>
								 --->
							</td>
						</tr>
					</cfloop>	<!--- end: loop over URLs --->
				</cfif>	<!--- end: inactive check --->
			</cfloop>	<!--- end: loop over subsites --->
			<cfif flagNoSubsites>
			<tr>
				<td colspan="1" class="WorkTableRowColour1">&nbsp;</td>
				<td colspan="1" class="WorkTableRowColour1" align="center"><strong>None</strong></td>
				<td colspan="1" class="WorkTableRowColour1">&nbsp;</td>
				<td colspan="3" class="WorkTableRowColour1RHCol">&nbsp;</td>
			</tr>
			</cfif>
		</table>
	</cfoutput>
		
		</td></tr>

<!--- 
	<tr>
		<td colspan="1" class="minorheadingText">
			Active Subsites:<br>
			<cfloop collection="#theSubSites#" item="thisSubSite">
				<cfif theSubSites["#thisSubSite#"].SubSiteActive>
					<cfoutput>
					#theSubSites["#thisSubSite#"].SubSiteFriendlyName#<br>
					</cfoutput>
				</cfif>
			</cfloop>
			InActive Subsites:<br>
			<cfset WeDontHaveAnInactiveSubsite = True />
			<cfloop collection="#theSubSites#" item="thisSubSite">
				<cfif theSubSites["#thisSubSite#"].SubSiteActive eq False>
					<cfset WeDontHaveAnInactiveSubsite = False />
					<cfoutput>
					#theSubSites["#thisSubSite#"].SubSiteFriendlyName#<br>
					</cfoutput>
				</cfif>
			</cfloop>
			<cfif WeDontHaveAnInactiveSubsite>None<br></cfif>
		<!--- 	
		<cfif thePortalsAreAllowed>
			Sub Sites are allowed
		<cfelse>
			Sub Sites are not allowed
		</cfif>
		 --->
		</td>
		</tr>
 --->		
	<tr><td colspan="3"></td></tr>
	<tr>
			<!--- 
		<td>
			<input type="submit" name="Cancel" value="Cancel/Back">
		</td>
			 --->
		<td colspan="3">
			<input type="submit" name="RefreshPortals" value="Update SubSites in System" onClick="return confirm('You do really want to Update the Sub Sites in the system?')">
		</td>
		</tr>
	</form>
</cfif>
</table>
<!--- 
<cfdump var="#cgi#" expand="false">
 --->
</body>
</html>
