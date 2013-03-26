<!--- this code runs within OnApplicationStart, included by /config/settings.cfm which is included in CFWheels' OnApplicationStart code, the CFW enviroment has been set by now --->
<!---
	Here we set all of the base config vars for SLCMS and a couple of defaults 
	which should get overwritten in the specific environment's settings.cfm file
--->
<cfset set(URLRewriting="Partial")>	<!--- we want to use the 'content.cfm/a/page/to/view' style so we push that we are running cfml --->

<!--- ToDo: get rid of this --->
<cfinvoke component="#application.wheels.RootComponentPath#slcms.core.cfcs.mbc_utilities.ServerScopeTools" method="init">
<!--- 
<cfset server.mbc_utility.serverconfig.OSPathDelim = "\" /> <!--- its in every catch handler :-( --->
 --->
<!--- 
	in V3 using wheels we just cloned the original ini files as now most things are fixed we have taken away a lot of the default versatility.
	We can that back in by making specific overrides in individual environemtn settings, 
	or here for that matter but the other will get driven by the installation wizard
 --->
 <!--- 
	as we migrate more completely into wheels these might wind down in number, 
	right now we put them all in so the original code will run
 --->
 
<cfset application.SLCMS.config["Base"] = StructNew() />
<!---; who are we?--->
<cfset application.SLCMS.config.Base["SiteName"] = "Core Code Development" />
<cfset application.SLCMS.config.Base["SiteAbbreviatedname"] = "Core_Dev" />
<cfset application.SLCMS.config.Base["BaseDomainName"] = "127.0.0.1" />
<cfset application.SLCMS.config.Base["BasePort"] = "8854" />
<cfset application.SLCMS.config.Base["BaseProtocol"] = "http://" />
<!---; and our super-user login details, well hashed versions of them--->
<cfset application.SLCMS.config.Base["SuperUser_Login"] = "22C2EB5FFEAB8B73CB0F345D6EF2DA67" />
<cfset application.SLCMS.config.Base["SuperUser_Password"] = "F8F469757E711E78BC14E5191B193599" />
<cfset application.SLCMS.config.Base["SuperUser_UserName"] = "mbcomms UberAdmin" />
<!---; first control flags--->
<cfset application.SLCMS.config.Base["AllowDirectDocIDs"] = "No"	 /><!---; flag to allow url.docid access to pages--->
<cfset application.SLCMS.config.Base["UserSource"] = "local"			 /><!---; local | external   the source of users for login, local or from an external source such as K2O--->
<!---; then mappings--->
<cfset application.SLCMS.config.Base["CFMapURL"] = "/" />
<cfset application.SLCMS.config.Base["RootURL"] = "#application.wheels.webpath#" />
<cfset application.SLCMS.config.Base["MapURL"] = "/" />
<!---; and paths to things--->
<!---;the code--->
<cfset application.SLCMS.config.Base["cfwURL"] = "#application.SLCMS.config.Base.RootURL#index.cfm/" />
<cfset application.SLCMS.config.Base["SLCMSPath_Phys"] = application.SLCMS.config.startup.SLCMSBasePath />
<cfset application.SLCMS.config.Base["SLCMSPath_Rel"] = "slcms/" />
<cfset application.SLCMS.config.Base["SLCMSPath_Abs"] = application.wheels.webpath & application.SLCMS.config.Base.SLCMSPath_Rel />
<cfset application.SLCMS.config.Base["SLCMS3rdPartyPath_Abs"] = "#application.SLCMS.config.Base.SLCMSPath_Abs#3rdParty/" />
<cfset application.SLCMS.config.Base["SLCMS3rdPartyPath_Rel"] = "#application.SLCMS.config.Base.SLCMSPath_Rel#3rdParty/" />
<cfset application.SLCMS.config.Base["SLCMSCoreRelPath"] = "#application.SLCMS.config.Base.SLCMSPath_Rel#Core/" />
<cfset application.SLCMS.config.Base["SLCMSHelpBaseRelPath"] = "#application.SLCMS.config.Base.SLCMSPath_Rel#Help/" />
<cfset application.SLCMS.config.Base["SLCMSModulesBaseRelPath"] = "#application.SLCMS.config.Base.SLCMSPath_Rel#Modules/" />
<!---;the templates and resources--->
<cfset application.SLCMS.config.Base["ContentURL"] = "content.cfm" />
<cfset application.SLCMS.config.Base["SharedRelPath"] = "#application.SLCMS.config.Base.SLCMSPath_Rel#Shared/" />
<cfset application.SLCMS.config.Base["SitesBaseRelPath"] = "#application.SLCMS.config.Base.SLCMSPath_Rel#Sites/" />
<cfset application.SLCMS.config.Base["Top_SiteRelPath"] = "Root/" />
<cfset application.SLCMS.config.Base["PresentationRelPath"] = "Presentation/" />
<cfset application.SLCMS.config.Base["PageTemplatesRelPath"] = "PageTemplates/" />
<cfset application.SLCMS.config.Base["SubTemplatesRelPath"] = "SubTemplates/" />
<cfset application.SLCMS.config.Base["FormTemplatesRelPath"] = "Forms/" />
<cfset application.SLCMS.config.Base["TagTemplatesRelPath"] = "Tags/" />
<cfset application.SLCMS.config.Base["ResourcesBaseRelPath"] = "resources/" />
<cfset application.SLCMS.config.Base["ResourcesFileRelPath"] = "resources/Files/" />
<cfset application.SLCMS.config.Base["ResourcesFlashRelPath"] = "resources/Flash/" />
<cfset application.SLCMS.config.Base["ResourcesImageRelPath"] = "resources/Images/" />
<cfset application.SLCMS.config.Base["ResourcesMediaRelPath"] = "resources/Media/" />
<cfset application.SLCMS.config.Base["ResourcesFormUploadsRelPath"] = "resources/FormUploads/" />

<!---; mode--->
<cfset application.SLCMS.config.Base["SiteMode"] = "Development" />

<!---; look--->
<!---;styleSheet_FrontEnd = "global/FrontEnd.css" />--->
<cfset application.SLCMS.config.Base["styleSheet_BackEnd"] = "admin/SLCMS_BackEnd.css" />
<cfset application.SLCMS.config.Base["styleSheet_BackEnd_ExtJSoverRide"] = "admin/SLCMS_BackEnd_ExtJSoverRide.css" />

<!---; things to make it easy for us hardworking developers--->
<cfset application.SLCMS.config.Base["DebugMode"] = "Yes" />

<!---[Datasources]--->
<cfset application.SLCMS.config["Datasources"] = StructNew() />
<cfset application.SLCMS.config.Datasources["CMS"] = "SLCMS_dev" />

<!---[Editors]--->
<cfset application.SLCMS.config["Editors"] = StructNew() />
<cfset application.SLCMS.config.Editors["EditorsRelPath"] = "#application.SLCMS.config.Base.SLCMSPath_Rel#Editors/" />
<cfset application.SLCMS.config.Editors["Editor1"] = "CK_Editor"	 /><!---; do not change this unless the site code/structure has changed--->
<cfset application.SLCMS.config.Editors["Editor2"] = "TinyMCE" />
<cfset application.SLCMS.config.Editors["EditorToUse"] = "Editor2"	 /><!---; one of the listed editors above--->
<cfset application.SLCMS.config.Editors["DefaultEditorStyleSheet"] = "Common_Presentation_EditableAreas.css" /><!---; the stylesheet for the editor to use if none other defined in a template or page definition--->

<!---[Roles]--->
<cfset application.SLCMS.config["Roles"] = StructNew() />
<!--- these are bit patterns, not numbers so have to be a string --->
<cfset application.SLCMS.config.Roles.Author_Global = "00000000000000000000000000000001" />
<cfset application.SLCMS.config.Roles.Editor_Global = "00000000000000000000000000000010" />
<cfset application.SLCMS.config.Roles.Admin_Global = "00000000000000000000000000000100" />
<cfset application.SLCMS.config.Roles.Author_Content = "00000000000000000000000000001000" />
<cfset application.SLCMS.config.Roles.Editor_Content = "00000000000000000000000000010000" />
<cfset application.SLCMS.config.Roles.Admin_Content = "00000000000000000000000000100000" />

<!---[Components]--->
<cfset application.SLCMS.config["Components"] = StructNew() />
<!---; Component Availability--->
<cfset application.SLCMS.config.Components.Use_Captcha = "No" /><!---               ; Yes|No or true|false--->
<cfset application.SLCMS.config.Components.Use_Formbuilder = "No" />           
<cfset application.SLCMS.config.Components.Use_RoundRobinDataStores = "No" /> 
<cfset application.SLCMS.config.Components.Use_Search = "Yes" />               
<cfset application.SLCMS.config.Components.Use_Stats = "No" />                 
<!---; Component configs--->
<cfset application.SLCMS.config.Components.Captcha_CaptchaRootRelPath = "SiteConfiguration/Captcha/" /> <!--- ; relative physical path to the root of the character sets from system root--->
<cfset application.SLCMS.config.Components.Captcha_DefaultCharset = "Charset1" />           <!---; name of the default character set to use--->
<cfset application.SLCMS.config.Components.Captcha_ImagePageAbsPath = "/Global/" />  <!---; absolute path from web root to where the imagegenerator page lives.--->
<cfset application.SLCMS.config.Components.RoundRobinDataStores_DatabaseMode = "SQL" />          	<!---; local filesystem, Mixed or SQL, as named below--->
<cfset application.SLCMS.config.Components.RoundRobinDataStores_DataSource = "CMS" />          	<!---; DSN named below to use for SQL or Mixed mode--->
<cfset application.SLCMS.config.Components.RoundRobinDataStores_SaveMode = "Auto" /> 				<!---; Incremental, Auto or Block, whether the data are saved on the fly, at a rate indicated by the caller or at rollover time--->
<cfset application.SLCMS.config.Components.RoundRobinDataStores_Test_NoFileRead = "No" />  <!---; Yes|No or true|false--->
<cfset application.SLCMS.config.Components.RoundRobinDataStores_Test_UseDefaultData = "No" />  <!---; Yes|No or true|false--->
<cfset application.SLCMS.config.Components.Stats_DatabaseMode = "SQL" /> 						<!---; local filesystem, Mixed or SQL, as named below--->
<cfset application.SLCMS.config.Components.Stats_DataSource = "CMS" /> 		<!---; local filesystem or DSN named below--->
<cfset application.SLCMS.config.Components.Stats_SaveMode = "Incremental" /> 				<!---; Incremental or Block, whether the stats are saved on the fly or at rollover time--->
<cfset application.SLCMS.config.Components.Stats_DiskRefreshRate = "9" /> 				<!---; minutes between stats saves to disk or save to db, ignored when SaveMode is Block--->
<cfset application.SLCMS.config.Components.Stats_RefreshURL = "/global/StatsRefresh.cfm" />

<!---[Utilities]--->
<cfset application.SLCMS.config["Utilities"] = StructNew() />
<cfset application.SLCMS.config.Utilities.Nexts_Mode = "CMS" />          <!---	; local or DSN named below--->
<cfset application.SLCMS.config.Utilities.Nexts_UpdatePeriod = "1" />		<!---; rate in days that the tables will cycle--->
<cfset application.SLCMS.config.Utilities.Nexts_Table = "Nexts" />			<!---; name of table in the database--->
<cfset application.SLCMS.config.Utilities.Threads_DSN = "CMS" />         	<!---; a DSN named below (its a db only utility, no local equivalent)--->
<cfset application.SLCMS.config.Utilities.Threads_LinkTable = "theThread_Links" />    
<cfset application.SLCMS.config.Utilities.Threads_MatrixTable = "theThread_Matrix" />
<cfset application.SLCMS.config.Utilities.Threads_SetTable = "theThread_Sets" />

<!---[DatabaseDetails]--->
<cfset application.SLCMS.config["DatabaseDetails"] = StructNew() />
<!---;these first define our table naming regime--->
<cfset application.SLCMS.config.DatabaseDetails.TableNaming_Delimiter = "_" />
<cfset application.SLCMS.config.DatabaseDetails.TableNaming_Base = "SLCMS" />
<cfset application.SLCMS.config.DatabaseDetails.TableNaming_SiteMarker = "Site" />
<cfset application.SLCMS.config.DatabaseDetails.TableNaming_SystemMarker = "System" />
<cfset application.SLCMS.config.DatabaseDetails.TableNaming_TypeMarker = "Type" />
<!---; and these are the name bits that get appended to the above--->
<cfset application.SLCMS.config.DatabaseDetails.BlogBlogsTable = "Blog_Blogs" />
<cfset application.SLCMS.config.DatabaseDetails.BlogCategoryTable = "Blog_Categories" />
<cfset application.SLCMS.config.DatabaseDetails.BlogContentControlTable = "Content_Control_Blog" />
<cfset application.SLCMS.config.DatabaseDetails.ContentTable = "Content_Content" />
<cfset application.SLCMS.config.DatabaseDetails.DocContentControlTable = "Content_Control_Document" />
<cfset application.SLCMS.config.DatabaseDetails.ModuleBaseTable = "ModuleManagement_Base" />
<cfset application.SLCMS.config.DatabaseDetails.ModulePermissionsTable = "ModuleManagement_Permissions" />
<cfset application.SLCMS.config.DatabaseDetails.PageStructureTable = "PageStructure" />
<cfset application.SLCMS.config.DatabaseDetails.PortalControlTable = "PortalControl" />
<cfset application.SLCMS.config.DatabaseDetails.PortalParentDocTable = "PortalParentDocs" />
<cfset application.SLCMS.config.DatabaseDetails.PortalURLTable = "PortalURLs" />
<cfset application.SLCMS.config.DatabaseDetails.StaffRolesTypeTable = "User_StaffRoles" />
<cfset application.SLCMS.config.DatabaseDetails.UserDetailTable_Admin = "Admin_UserDetails" />
<cfset application.SLCMS.config.DatabaseDetails.UserRoleTable_Admin = "Admin_UserRoles" />
<cfset application.SLCMS.config.DatabaseDetails.wikiMappingTable = "wiki_LabelMapping" />

<!---[Debug]--->
<cfset application.SLCMS.config["Debug"] = StructNew() />
<cfset application.SLCMS.config.Debug.DebugMode = True />
<cfset application.SLCMS.config.Debug.errorEmailTo = "test@slcms.net" />
<cfset application.SLCMS.config.Debug.testEddress = "dev@mbcomms.net.au" />

<!--- stuff migrated from V2.2 SLCMS's OnApplicationStart --->
<!--- firstly set up all the structures we will use --->
<cfset application.SLCMS["flags"] = StructNew() />	<!--- a nice place to put control flags and things --->
<cfset application.SLCMS.flags["RunInstallWizard"] = False />	<!--- gets set on startup if we don't have a configured system with working database --->
<cfset application.SLCMS["Logging"] = StructNew() />
<cfset application.SLCMS["Sites"] = StructNew() />	<!--- this is the base for all of the subSites' persistent data --->
<cfset application.SLCMS["Paths_Admin"] = StructNew() />	<!--- this is the base for all of the frequently accessed paths used in the admin area --->
<cfset application.SLCMS["Paths_Common"] = StructNew() />	<!--- this is the base for all of the frequently accessed paths used around the place like in URLs --->
<!--- fill in the ones that are stright calculations or hard-coded folder names, in Affabeck Lorder except where dependencies break that --->
<cfset application.SLCMS.Paths_Common.RootURL = application.SLCMS.config.base.RootURL />
<cfset application.SLCMS.Paths_Common.ContentRootURL = "#application.SLCMS.config.base.RootURL##application.SLCMS.config.base.ContentURL#" />
<cfset application.SLCMS.Paths_Common.CoreRoot_Rel = application.SLCMS.config.base.slcmsCoreRelPath />
<cfset application.SLCMS.Paths_Common.CoreTagsSubTemplateURL = "#application.SLCMS.config.base.RootURL##application.SLCMS.config.base.SharedRelPath##application.SLCMS.config.base.Presentationrelpath#SubTemplates/Tags/CoreTags/" />
<cfset application.SLCMS.Paths_Common.ModulesRoot_Rel = application.SLCMS.config.base.slcmsModulesBaseRelPath />
<cfset application.SLCMS.Paths_Common.SitePhysicalRoot = application.SLCMS.config.startup.SiteBasePath />
<cfset application.SLCMS.Paths_Common.SLCMSfolder_Rel = application.SLCMS.config.Base.SLCMSPath_Rel />
<cfset application.SLCMS.Paths_Common.SLCMSfolder_Abs = application.SLCMS.Paths_Common.RootURL & application.SLCMS.Paths_Common.SLCMSfolder_Rel />
<cfset application.SLCMS.Paths_Common.SLCMSfolderPhysicalRoot = application.SLCMS.Paths_Common.SitePhysicalRoot & application.SLCMS.Paths_Common.SLCMSfolder_Rel />
<cfset application.SLCMS.Paths_Common.StylingRootPath_ABS = "#application.SLCMS.Paths_Common.RootURL##application.SLCMS.Paths_Common.SLCMSfolder_Rel#SLCMSstyling/" />
<cfset application.SLCMS.Paths_Common.Icons_Abs = "#application.SLCMS.Paths_Common.StylingRootPath_ABS#famfamfam/" />
<cfset application.SLCMS.Paths_Common.HelpBasePath_Abs = "#application.SLCMS.Paths_Common.SLCMSfolder_Abs#Help/" />
<cfset application.SLCMS.Paths_Common.HelpJs_Abs = "#application.SLCMS.Paths_Common.HelpBasePath_Abs#helpTip.js" />
<cfset application.SLCMS.Paths_Common.HelpTipsPath_Abs = "#application.SLCMS.Paths_Common.HelpBasePath_Abs#Tips/" />
<cfset application.SLCMS.Paths_Common.HelpTipGraphics_Abs = "#application.SLCMS.Paths_Common.SLCMSfolder_Abs#Help/Graphics/" />
<cfset application.SLCMS.Paths_Common.UploadTempFolder_Phys = GetTempDirectory() />	<!--- use the temp folder of the cfml app server as that should be unreachable --->
<cfset application.SLCMS.Paths_Admin.AdminBaseURL = application.SLCMS.config.Base.cfwURL & application.SLCMS.Paths_Common.SLCMSfolder_Rel />
<cfset application.SLCMS.Paths_Admin.ajaxURL_ABS = '#application.SLCMS.Paths_Admin.AdminBaseURL#client-Comms?format=json' />
<cfset application.SLCMS.Paths_Admin.StylingRootPath_ABS = "#application.SLCMS.Paths_Common.StylingRootPath_ABS#Admin/" />
<cfset application.SLCMS.Paths_Admin.GraphicsPath_ABS = "#application.SLCMS.Paths_Admin.StylingRootPath_ABS#Graphics/" />
<cfset application.SLCMS.Paths_Admin.adminBackEndWrapperStyleSheet_Abs = "#application.SLCMS.Paths_Admin.StylingRootPath_ABS#adminBackEndWrapper.css" />
<cfset application.SLCMS.Paths_Admin.AdminPopWrapperjs_Abs = "#application.SLCMS.Paths_Admin.StylingRootPath_ABS#AdminPanelPopper.js" />
<cfset application.SLCMS.Paths_Admin.AdminPopWrapperStyleSheet_Abs = "#application.SLCMS.Paths_Admin.StylingRootPath_ABS#AdminPanelPop.css" />
<!--- next some html snippets to save loading the same thing over and over again --->
<cfset application.SLCMS["HTMLParts"] = StructNew() />
<cfset application.SLCMS.HTMLParts["AdminPopWrapper"] = "" />
<!--- 
<!--- if someone is logged in then the admin wrapper is going to be called every page hit so put the base html here to save a file read/savecontent every page hit --->
<cffile action="read" variable="application.SLCMS.HTMLParts.AdminPopWrapper" file="#application.SLCMS.Paths_Common.SLCMSfolderPhysicalRoot#_AdminPopWrapper_inc.cfm" />
 --->

<!--- 
	now we have done all of that we have a system capable of running but it might not be in the right mode and some details are not site-specific 
	so now we read the Config_Base ini file and set them up
	We will read everything that can be tweaked/set in the Install Wizard and only update if there is a value there, otherwise use the default from above.
	 --->
<cfif FileExists(application.SLCMS.config.startup.BaseConfigPath)>
	<cfloop list="SiteName,SiteAbbreviatedname,BaseDomainName,BasePort,BaseProtocol" index="this.variables.SLCMS.Temp.thisConfigItem">
		<cfset this.variables.SLCMS.Temp.ReadItem = GetProfileString("#application.SLCMS.config.startup.BaseConfigPath#", "Base", "#this.variables.SLCMS.Temp.thisConfigItem#") />
		<cfif this.variables.SLCMS.Temp.ReadItem neq "">
			<cfset application.SLCMS.config.Base["#this.variables.SLCMS.Temp.thisConfigItem#"] = this.variables.SLCMS.Temp.ReadItem />
		</cfif>
	</cfloop>
</cfif>

<!--- 
	Now the system is really setup so lets fill in a few details or defaults before the core and modules boot themselves up
 --->
<cfset application.SLCMS.Sites.Site_0 = {HomeURL=""} />

<!--- this will have the site name (if it exists in the config) added to it so the logging is more identifiable
			all of this runs before our SLCMS OnApplicationStart so we have nice names and params for everything --->
<cfif len(application.SLCMS.config.base.SiteAbbreviatedname)>
	<cfset this.variables.SLCMS.theSiteLogName = this.variables.SLCMS.theSiteName & "_" & application.SLCMS.config.base.SiteAbbreviatedname />
<cfelse>
	<cfset this.variables.SLCMS.theSiteLogName = this.variables.SLCMS.theSiteName />
</cfif>
<cfset Application.SLCMS.Logging["theSiteLogName"] = this.variables.SLCMS.theSiteLogName />
<cfset Application.SLCMS.Logging["CommonLogName"] = this.variables.SLCMS.theSLCMSCommonLogName />

