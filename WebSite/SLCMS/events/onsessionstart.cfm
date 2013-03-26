<!--- __OnSessionStart_inc.cfm --->
<!--- include file for Application.cfc for the code that runs in OnSessionStart() --->
<!--- for SLCMS --->
<!---  --->
<!--- &copy; mort bay communications 2009 --->
<!---  --->
<!--- Cloned from new CFC-driven standard site code:  25th Jul 2009 by Kym K --->
<!--- this is all V2.2.0+ code --->
<!--- modified: 30th Aug 2009 -  1st Sep 2009 by Kym K, mbcomms: adding code for session roles, ie the permissions engine --->
<!--- modified:  4th Oct 2009 -  4th Oct 2009 by Kym K, mbcomms: added structs for current states --->
<!--- modified:  4th Oct 2009 -  4th Oct 2009 by Kym K, mbcomms: added structs for current states --->
<!--- modified:  7th Nov 2009 -  7th Nov 2009 by Kym K, mbcomms: cleaning up session flags as it breaks now we have one session for all open windows, moving flags to req scope --->
<!--- modified: 13th Feb 2010 - 13th Feb 2010 by Kym K, mbcomms: working on installer code: db test on startup flags, etc. --->
<!--- modified: 22nd Nov 2010 - 22nd Nov 2010 by Kym K, mbcomms: added module struct for modules to use funnily enuf --->
<!--- modified: 14th Jan 2011 - 14th Jan 2011 by Kym K, mbcomms: adding base module structs, the individual modules supply the detail --->
<!--- modified:  3rd Apr 2011 -  3rd Apr 2011 by Kym K, mbcomms: added "httponly" to session cookies now that all browsers support it --->
<!--- modified: 29th Apr 2011 - 12th May 2011 by Kym K, mbcomms: improved startup debugging displays and more error handling for missing moduleparts, etc --->

<!--- put code here that has to happen when a session starts --->

<!--- this first section is needed for code development as we need to make sure everything is there before we run the session start code
			makes sense as we can call OnSessionStart outside a normal page call if there has been a system update or similar
			see if we need to do a flush (this could be refined, codewise, but this is easier to read and covers everything in an understandable way) --->
<cfset this.variables.SLCMS.SSdebugString = "<br>" />
<!--- 
<cfif application.SLCMS.Config.StartUp.FlushSerial eq "yes">
 --->
<cfif application.SLCMS.Config.StartUp.FlushSerial neq this.variables.SLCMS.snFlushAppscope 
			or StructKeyExists(application.SLCMS.Config.StartUp, "FlushAppGlobals") 
			or application.SLCMS.config.StartUp.FlushSerialFromInitWiz eq "Yes">	<!--- check the flags that can force a restart --->
	<!--- run SLCMS's application start code --->
	<!--- <cfset $include(template="SLCMS/config/settings.cfm") /> --->
	<cfset $include(template="SLCMS/events/onapplicationstart.cfm") />
	<cfset this.variables.SLCMS.SSdebugString = this.variables.SLCMS.SSdebugString & "Flush requested. Application started from OnSessionStart.<br>" />
</cfif>

	<!--- 
<cfelse>
	<!--- run SLCMS's application start code --->
	<cfset $include(template="SLCMS/events/onapplicationstart.cfm") />
	<cfset this.variables.SLCMS.SSdebugString = this.variables.SLCMS.SSdebugString & "No app config struct. Application started from OnSessionStart.<br>" />
</cfif>
	 --->
<cfif this.variables.SLCMS.CodingMode>
	<strong>in OnSessionStart -</strong><br><em>this.variables.SLCMS.SSdebugString:</em>
	<cfif this.variables.SLCMS.SSdebugString neq "<br>">
		<cfoutput>#this.variables.SLCMS.SSdebugString#</cfoutput>
	<cfelse>
		Is empty<br>
	</cfif>
</cfif>

<!--- force our session cookies to be HTTP only to stop js hijacking --->
<cfheader name="Set-Cookie" value="CFID=#session.CFID#;path=/;HTTPOnly">
<cfheader name="Set-Cookie" value="CFTOKEN=#session.CFTOKEN#;path=/;HTTPOnly">

<!--- some flags to handle restarts and things, useful if there has been a structural update somewhere, it will allow sessions to catchup --->
<cfset session.SLCMS["Logging"] = StructNew() />
<cfset session.SLCMS.Logging.SessionStarted = Now() />
<!--- 
<cfset session.SLCMS.Flags = StructNew() />
<cfset session.SLCMS.Flags.FormsSessionSet = False />
<cfset session.SLCMS.Flags.FrontEndSessionSet = False />
<cfset session.SLCMS.Flags.PortalSessionSet = False />
<cfset session.SLCMS.Flags.SecuritySessionSet = False />
<cfset session.SLCMS.Flags.SitesSessionSet = False />
<cfset session.SLCMS.Flags.UserSessionSet = False />
 --->
<!--- 
<cfdump	var="#application#" expand =false label="application" />
<cfabort>

 --->
<!--- ToDo: browser detector for bots and spiders and thingies to set session short --->

<!--- load up the session structure with a blank user dataset if we are a running/viable system --->
<cfif not application.SLCMS.Config.startup.initialization.WeNeedToCreateDBTables>
	<cfset session.SLCMS.user = duplicate(application.SLCMS.Core.UserControl.CreateBlankUserStruct_Session())  />
	<!--- set up the base structures that are subSite-based --->
	<cfset session.SLCMS["PortalControl"] = StructNew() />	<!--- carries subSite data --->
	<cfset session.SLCMS.PortalControl.SubSiteIDList_Active = application.SLCMS.core.portalControl.GetAllowedSubSiteIDList_ActiveSites() />
	<cfset session.SLCMS["FrontEnd"] = StructNew() />	<!--- carries the nav data for the menus --->
	<cfset session.SLCMS["WYSIWYGEditor"] = StructNew() />	<!--- carries path info, which editor to use, etc --->
	<cfloop list="#session.SLCMS.PortalControl.SubSiteIDList_Active#" index="thisSubSiteID">
		<cfset session.SLCMS.FrontEnd["SubSite_#thisSubSiteID#"] = StructNew() />
		<cfset session.SLCMS.WYSIWYGEditor["SubSite_#thisSubSiteID#"] = StructNew() />
		<cfset session.SLCMS.WYSIWYGEditor["SubSite_#thisSubSiteID#"].FileBrowseBasePath = "" />	<!--- where we are browsing in the file browser as a path to get back there in 3rd party tools --->
	</cfloop>
	<!--- this is to put module session data in, can be anything per module --->
	<cfset session.SLCMS["Modules"] = StructNew()  />
	<!--- get a list of valid modules and create a struct for each --->
	<cfloop list="#Application.SLCMS.System.ModuleManager.getQuickAvailableModulesList()#" index="thisModule">
		<cfset session.SLCMS.Modules["#thisModule#"] = StructNew()  />
		<!--- and fill with detail from the module directly, if it wants to that is --->
		<cfif isObject('application.SLCMS.Modules["#thisModule#"].Functions.Utilities_Persistent')>
			<cftry>
				<cfset session.SLCMS.Modules["#thisModule#"] = duplicate(application.SLCMS.Modules["#thisModule#"].Functions.Utilities_Persistent.CreateBlankStruct_Session()) />
			<cfcatch>
				<cfset session.SLCMS.Modules["#thisModule#"] = StructNew() />
			</cfcatch>
			</cftry>
		</cfif>
	</cfloop>
	<!--- and drop in the admin stuff --->
	<cfset session.SLCMS["pageAdmin"] = Structnew()/>
	<cfset session.SLCMS.pageAdmin["NavState"] = StructNew()/>
	<!--- set up our vars to display the structure from --->
	<cfset session.SLCMS.pageAdmin.NavState.theOriginalNavArray = Duplicate(application.SLCMS.Core.PageStructure.getFullNavArray(SubSiteID=0)) />
	<cfset session.SLCMS.pageAdmin.NavState.theCurrentNavArray = Duplicate(application.SLCMS.Core.PageStructure.getFullNavArray(SubSiteID=0)) />
	<!--- 
	<cfset session.SLCMS.pageAdmin.NavState.theOriginalNavArray = Duplicate(application.SLCMS.Core.PageStructure.getFullNavArray(SubSiteID=session.SLCMS.Currents.Admin.PageStructure.CurrentSubSiteID)) />
	<cfset session.SLCMS.pageAdmin.NavState.theCurrentNavArray = Duplicate(application.SLCMS.Core.PageStructure.getFullNavArray(SubSiteID=session.SLCMS.Currents.Admin.PageStructure.CurrentSubSiteID)) />
	<cfset request.SLCMS.PageStructTable = application.SLCMS.config.DatabaseDetails.databaseTableNaming_Root_Site
																	&	session.SLCMS.Currents.Admin.PageStructure.CurrentSubSiteID
																	&	application.SLCMS.config.DatabaseDetails.databaseTableNaming_Tail_PageStructure />
	<cfset request.SLCMS.DocContentControlTable = application.SLCMS.config.DatabaseDetails.databaseTableNaming_Root_Site
																	&	session.SLCMS.Currents.Admin.PageStructure.CurrentSubSiteID
																	&	application.SLCMS.config.DatabaseDetails.databaseTableNaming_Tail_ContentControl_Doc />
	 --->
	<cfset session.SLCMS.pageAdmin.NavState.dispRowCounter = 0 />
	<cfset request.SLCMS.PageStructTable = application.SLCMS.config.DatabaseDetails.databaseTableNaming_Root_Site
																	&	"0"
																	&	application.SLCMS.config.DatabaseDetails.databaseTableNaming_Tail_PageStructure />
	<cfset request.SLCMS.DocContentControlTable = application.SLCMS.config.DatabaseDetails.databaseTableNaming_Root_Site
																	&	"0"
																	&	application.SLCMS.config.DatabaseDetails.databaseTableNaming_Tail_ContentControl_Doc />
	<!--- and initialise the nav tree expansion flag structure with all collapsed --->
	<cfset session.SLCMS.pageAdmin.NavState["ExpansionFlags"] = StructNew()/>
	<cfquery name="getAllDocs" datasource="#application.SLCMS.config.datasources.CMS#">
		select	DocID
			from	#request.SLCMS.PageStructTable#
	</cfquery>
	<cfloop query="getAllDocs">
		<cfset session.SLCMS.pageAdmin.NavState.ExpansionFlags[getAllDocs.DocID] = False />
	</cfloop>
</cfif>
<!--- now things that are across everything --->
<cfset session.SLCMS.WYSIWYGEditor.FileBrowseType = "" />	<!--- what we are browsing in the file browser, file, image, whatever --->

	<!--- ToDo: put this into a call of some form to loop over all subsites, or get rid of it altogether by improving the blog code --->
	<!--- user various things needed by nice browsing like the Blogs, mainly front end but here so the flushes work --->
<!--- 
	<cfset session.SLCMS.Sites.Site_0.Blogs = StructNew() />	<!--- dump the old structures just in case --->
	<cfset session.SLCMS.Sites.Site_0.Blogs = application.Core.Control_Blogs.getBlogsShort() />	<!--- get the structure of blogs/cat --->
	<cfset session.SLCMS.Sites.Site_0.Blogs.CurrentBlogName = session.SLCMS.Sites.Site_0.Blogs.DefaultBlog />	<!--- set the current to the supplied default one --->
	<cfinclude template="/global/Core/TemplateTags/Content/displayBlog_inc_Set_Blog-Category-Date.cfm">
 --->
	
<!--- 
<cfset session.SLCMS.PortalControl = StructNew() />
<cfset session.SLCMS.PortalControl.CurrentSubSiteID = 0 />
<cfset session.SLCMS.PortalControl.CurrentSubSiteTopPath = "" />
<cfset session.SLCMS.Flags.PortalSessionSet = True />
 --->
<cfset session.SLCMS["forms"] = StructNew()  />
<cfset session.SLCMS.forms["temp"] = StructNew()  />
<cfset session.SLCMS.forms.CurrentForm = ""  />	<!--- this will be the short name of the form (in page param3) --->
<cfset session.SLCMS.forms.CurrentFormURL = ""  />	<!--- this will be the url of the form being processed to use in the tags --->
<cfset session.SLCMS.forms.CurrentAction = ""  />	<!--- this will be "Form" or "Process" --->
<cfset session.SLCMS.forms.Confirmer = ""  />	<!--- this will be a random string to help in trapping captcha bots --->

<!--- next the structs that carry current things like where we are, used in front and backend --->
<cfset session.SLCMS["Currents"] = StructNew()  />
<cfset session.SLCMS.Currents["Admin"] = StructNew()  />
<cfset session.SLCMS.Currents["FrontEnd"] = StructNew()  />	<!--- we are going to stop using this, do all in req scope as we can have multiple windows/tabs open --->
<cfset session.SLCMS.Currents.Admin["BackEnd"] = StructNew()  />
<cfset session.SLCMS.Currents.Admin["FrontEnd"] = StructNew()  />
<cfset session.SLCMS.Currents.Admin["PageStructure"] = StructNew()  />
<cfset session.SLCMS.Currents.Admin["Portal"] = StructNew()  />
<cfset session.SLCMS.Currents.Admin["Templates"] = StructNew()  />
<cfset session.SLCMS.Currents.Admin["Users"] = StructNew()  />
<cfset session.SLCMS.Currents.Admin.FrontEnd["ContainerEditControlsShowing"] = False  />	<!--- flag if we want to show the edit controls, ajax-driven --->
<cfset session.SLCMS.Currents.Admin.PageStructure.CurrentFolder = 0  />
<cfset session.SLCMS.Currents.Admin.PageStructure.CurrentParentID = 0  />
<cfset session.SLCMS.Currents.Admin.PageStructure.CurrentSubSiteID = 0  />
<cfset session.SLCMS.Currents.Admin.PageStructure.CurrentSubSiteFriendlyName = "Top" />
<cfset session.SLCMS.Currents.Admin.PageStructure.FlushExpansionFlags = True />
<cfset session.SLCMS.Currents.Admin.Templates.CurrentSubSiteID = 0  />
<cfset session.SLCMS.Currents.Admin.Templates.CurrentSubSiteFriendlyName = "Top" />
<cfset session.SLCMS.Currents.Admin.Templates.FlushExpansionFlags = True />
<cfset session.SLCMS.Currents["InAdminPages"] = False  />	<!--- flag if doing stuff in admin area --->
<cfset session.SLCMS.Currents["InSitePages"] = True  />	<!--- flag if browsing the site --->

		
<cflock timeout="5" throwontimeout="No" type="EXCLUSIVE" scope="SESSION">
	<cfset Application.SLCMS.sessions.NumberActive = Application.SLCMS.sessions.NumberActive + 1>
</cflock>
		<!--- 
    <cflog file="#variables.theSiteLogName#" type="Information" text="Session:
        #session.SLCMS.sessionid# started">
		 --->
 