<!--- this page set the parameters that the CFFM file manager uses
			Basically we take the incoming url params and turn them into something useful for CFFM
			Editor_Resource_Type has the type of file browsing we are doing, eg file/image/etc
 --->
<!--- created:  23rd Jan 2009 by Kym K - mbcomms: --->
<!--- modified: 23rd Jan 2009 - 23rd Jan 2009 by Kym K - mbcomms: initial work --->
<!--- modified: 30th Oct 2009 -  7th Oct 2009 by Kym K - mbcomms: V2.2+ portal-awareness added --->
<!--- modified:  7th Nov 2009 - 16th Nov 2009 by Kym K - mbcomms: V2.2+ made more sophisticated for better cosmetics and path calculations --->

<!--- a work area for ourselves --->
<cfset variables.slscmsMods = StructNew() />
<cfset variables.slscmsMods.FullPathToWorkingFolder = "" />	<!--- our working folder taken from variables.workingDirectoryWeb when it gets created later --->
<cfset variables.slscmsMods.ShortPathToWorkingFolder = "" />	<!--- will have short version without "/sites/subsite_nn/Resources" at front --->
<cfset variables.slscmsMods.SubSiteShortName = "" />	<!--- will have short version without "/sites/subsite_nn/Resources" at front --->
<cfif IsDefined("url.mode")>
	<cfset WorkMode = url.mode />
	<cfset DispMode = url.mode />
<cfelse>
	<cfset WorkMode = "" />
	<cfset DispMode = "" />
</cfif>
<cfif isdefined("form.cancel")>	<!--- do nothing if cancelled --->
	<cfset WorkMode = "" />
	<cfset DispMode = "" />
</cfif>

<!--- set up some defaults --->
<!--- we need to make a session that we can live with that is independent of everything else as the local session could be gone as this is all in iFrames and messy --->
<!--- the first time in we will be given a content handle that we can use to keep ourselves unique and also the subSite we are in for finding the paths and things --->
<cfif StructKeyExists(url, "ContentHandle") and not StructKeyExists(session, "ContentHandle")>
	<cfset session.WYSIWYGEditor.CurrentContentHandle = url.ContentHandle />
	<cfset session.WYSIWYGEditor["#session.WYSIWYGEditor.CurrentContentHandle#"] = StructNew() />
	<cfset session.WYSIWYGEditor["#session.WYSIWYGEditor.CurrentContentHandle#"].FileMode = "ShowFiles" />
	<cfset session.WYSIWYGEditor["#session.WYSIWYGEditor.CurrentContentHandle#"].dispRowCounter = 0 />
	<cfset session.WYSIWYGEditor["#session.WYSIWYGEditor.CurrentContentHandle#"].displayedRowArray = ArrayNew(2) />
	<cfset session.WYSIWYGEditor["#session.WYSIWYGEditor.CurrentContentHandle#"].theCurrentNavArray = ArrayNew(2) />
	<cfset variables.slscmsMods.ContentHandle = url.ContentHandle />
<cfelse>
	<cfset variables.slscmsMods.ContentHandle = session.WYSIWYGEditor.CurrentContentHandle />
</cfif>
<cfif StructKeyExists(url, "SubSiteID")>
	<cfset session.WYSIWYGEditor.CurrentSubSiteID = url.SubSiteID />
	<cfset session.WYSIWYGEditor["#session.WYSIWYGEditor.CurrentContentHandle#"]['SubSite_#url.SubSiteID#'] = StructNew() />
	<cfset session.WYSIWYGEditor["#session.WYSIWYGEditor.CurrentContentHandle#"]['SubSite_#url.SubSiteID#'].FileBrowseBasePath = "" />
	<cfset session.WYSIWYGEditor["#session.WYSIWYGEditor.CurrentContentHandle#"]['SubSite_#url.SubSiteID#'].FileBrowseBaseURL = "" />
</cfif>
<cfif StructKeyExists(url, "EDITOR_RESOURCE_TYPE")>
	<cfset session.WYSIWYGEditor["#session.WYSIWYGEditor.CurrentContentHandle#"].ResourceType = url.EDITOR_RESOURCE_TYPE />
</cfif>
<cfif StructKeyExists(url, "FileMode")>
	<cfset session.WYSIWYGEditor["#session.WYSIWYGEditor.CurrentContentHandle#"].FileMode = url.FileMode />
</cfif>
<!--- 
<cfoutput>
<cfdump var="#session#" expand="false">
</cfoutput>
<cfabort>
 --->
<cfset theIncludeBaseDir = application.Sites["Site_#session.WYSIWYGEditor.CurrentSubSiteID#"].Paths.ResourcePaths.ResourceBase />
<cfset theIncludeBaseURL = application.Sites["Site_#session.WYSIWYGEditor.CurrentSubSiteID#"].Paths.ResourceURLs.ResourceBase />
<cfif right(theIncludeBaseDir,1) eq "/">
	<cfset theIncludeBaseDir = left(theIncludeBaseDir,len(theIncludeBaseDir)-1) />
</cfif>
<cfif right(theIncludeBaseURL,1) eq "/">
	<cfset theIncludeBaseURL = left(theIncludeBaseURL,len(theIncludeBaseURL)-1) />
</cfif>
<cfparam name="session.WYSIWYGEditor['#variables.slscmsMods.ContentHandle#']['SubSite_#session.WYSIWYGEditor.CurrentSubSiteID#'].FileBrowseBasePath" default="#theIncludeBaseDir#">
<cfparam name="session.WYSIWYGEditor['#variables.slscmsMods.ContentHandle#']['SubSite_#session.WYSIWYGEditor.CurrentSubSiteID#'].FileBrowseBaseURL" default="#theIncludeBaseURL#">

<cfset variables.slscmsMods.SubSiteShortName = application.core.PortalControl.GetSubSite(SubSiteID="#session.WYSIWYGEditor.CurrentSubSiteID#").data.SubSiteShortName />

<!--- then set the path to the folder we want to look in, both physical and as a URL --->
<cfif StructKeyExists(url, "Editor_Resource_Type")>
	<cfswitch expression="#url.Editor_Resource_Type#">
		<cfcase value="File">
			<!--- if its set as file it could be an external link or a link to an internal page, which we asist to get the correct path --->
			<cfset theIncludeBaseDir = application.Sites["Site_#session.WYSIWYGEditor.CurrentSubSiteID#"].Paths.ResourcePaths.FileResources />
			<cfset theIncludeBaseURL = application.Sites["Site_#session.WYSIWYGEditor.CurrentSubSiteID#"].Paths.ResourceURLs.FileResources />
		</cfcase>
		<cfcase value="Image">
			<cfset theIncludeBaseDir = application.Sites["Site_#session.WYSIWYGEditor.CurrentSubSiteID#"].Paths.ResourcePaths.ImageResources />
			<cfset theIncludeBaseURL = application.Sites["Site_#session.WYSIWYGEditor.CurrentSubSiteID#"].Paths.ResourceURLs.ImageResources />
		</cfcase>
		<cfcase value="Flash">
			<cfset theIncludeBaseDir = application.Sites["Site_#session.WYSIWYGEditor.CurrentSubSiteID#"].Paths.ResourcePaths.FlashResources />
			<cfset theIncludeBaseURL = application.Sites["Site_#session.WYSIWYGEditor.CurrentSubSiteID#"].Paths.ResourceURLs.FlashResources />
		</cfcase>
		<cfcase value="Media">
			<cfset theIncludeBaseDir = application.Sites["Site_#session.WYSIWYGEditor.CurrentSubSiteID#"].Paths.ResourcePaths.MediaResources />
			<cfset theIncludeBaseURL = application.Sites["Site_#session.WYSIWYGEditor.CurrentSubSiteID#"].Paths.ResourceURLs.MediaResources />
		</cfcase>
		<cfdefaultcase>
			<cfset theIncludeBaseDir = application.Sites["Site_#session.WYSIWYGEditor.CurrentSubSiteID#"].Paths.ResourcePaths.ResourceBase />
			<cfset theIncludeBaseURL = application.Sites["Site_#session.WYSIWYGEditor.CurrentSubSiteID#"].Paths.ResourceURLs.ResourceBase />
		</cfdefaultcase>
	</cfswitch>
	<cfset theIncludeBaseDir = application.config.startup.SiteBasePath & theIncludeBaseDir />
	<!--- this stupid code won't allow for trailing slashes so we fix up here --->
	<cfif right(theIncludeBaseDir,1) eq "/">
		<cfset theIncludeBaseDir = left(theIncludeBaseDir,len(theIncludeBaseDir)-1) />
	</cfif>
	<cfif right(theIncludeBaseURL,1) eq "/">
		<cfset theIncludeBaseURL = left(theIncludeBaseURL,len(theIncludeBaseURL)-1) />
	</cfif>
	<!--- now we know what we are doing save the top path for Ron --->
	<cfset session.WYSIWYGEditor['#variables.slscmsMods.ContentHandle#']["SubSite_#session.WYSIWYGEditor.CurrentSubSiteID#"].FileBrowseBasePath = theIncludeBaseDir />
	<cfset session.WYSIWYGEditor['#variables.slscmsMods.ContentHandle#']["SubSite_#session.WYSIWYGEditor.CurrentSubSiteID#"].FileBrowseBaseURL = theIncludeBaseURL />
<cfelse>
	<!--- we don't have the url param but we could be looping about inside CFFM so use the last stored value in the session --->
	<cfset theIncludeBaseDir = session.WYSIWYGEditor['#variables.slscmsMods.ContentHandle#']["SubSite_#session.WYSIWYGEditor.CurrentSubSiteID#"].FileBrowseBasePath />
	<cfset theIncludeBaseURL = session.WYSIWYGEditor['#variables.slscmsMods.ContentHandle#']["SubSite_#session.WYSIWYGEditor.CurrentSubSiteID#"].FileBrowseBaseURL />
</cfif>
<!--- almost done, we set up the nav structures for when selecting pages --->
<cfif WorkMode eq "ExpandArm">
	<!--- expand the specified arm of the navigation --->
	<cfset session.WYSIWYGEditor["#session.WYSIWYGEditor.CurrentContentHandle#"].ExpansionFlags[url.DocID] = True>
	<!--- and tell the world we had a change with view back to the listing --->
	<cfset request.ItemChangedFlag.ID = url.DocID />
	<cfset request.ItemChangedFlag.Name = "EX" />
<cfelseif WorkMode eq "CollapseArm">
	<!--- collapse the specified arm of the navigation --->
	<cfset session.WYSIWYGEditor["#session.WYSIWYGEditor.CurrentContentHandle#"].ExpansionFlags[url.DocID] = False>
	<!--- and tell the world we had a change with view back to the listing --->
	<cfset request.ItemChangedFlag.ID = url.DocID />
	<cfset request.ItemChangedFlag.Name = "EX" />
	<cfset DispMode = "">
</cfif>
<cfif session.WYSIWYGEditor["#session.WYSIWYGEditor.CurrentContentHandle#"].FileMode eq "ShowPages">
	<cfset session.WYSIWYGEditor["#session.WYSIWYGEditor.CurrentContentHandle#"].theCurrentNavArray = session.FrontEnd["SubSite_#session.WYSIWYGEditor.CurrentSubSiteID#"].NavState.theCurrentNavArray />
	<cfset session.WYSIWYGEditor["#session.WYSIWYGEditor.CurrentContentHandle#"].ExpansionFlags = session.FrontEnd["SubSite_#session.WYSIWYGEditor.CurrentSubSiteID#"].NavState.ExpansionFlags />
</cfif>
<!--- lastly shuffle a few things into the main cffm.cfm codespace --->
<cfset variables.FileMode = session.WYSIWYGEditor["#session.WYSIWYGEditor.CurrentContentHandle#"].FileMode />
