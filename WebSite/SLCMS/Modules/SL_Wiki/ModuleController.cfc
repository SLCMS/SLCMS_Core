<cfcomponent extends="controller"   
	output="false"
	displayname="Module Definition" 
  hint="Defines what is in this Module and handles Initialisation and related"
	>
<!--- 
docs: startDescription
docs: SLCMS Module CFC - SL Wiki
docs: &copy; 2012 mort bay communications
docs: Module Controller CFC - not persistent
docs: the Module Controller CFC for the SLCMS "SL Wiki" module
docs: provides the needed information for the module to be incorporated into SLCMS and provides global control functions to configure the module
docs: endDescription
docs: 
docs: startParams
docs:	Name: ModuleController
docs:	Type:	CFC - NotPersistent 
docs:	Role:	Module Definition and Initialization - Module 
docs:	Hint: does stuff
docs:	Versions: CFC - 1.0.0; Core - 3.0.0+
docs: endParams
docs: 
docs: startFunctions
docs: getBaseDefinition() - provides the module's config to SLCMS's Module Manager
docs: initModule() - initialises the whole kit and kaboodle, inits all of this module's internal CFCs, CFCs to be stored persistently, etc
docs: ReInitAfter() - reinitialises anything that might need it after an external change of some sort that can affect this module
docs: InstallModule() - does the needed installation work when the module is first included into an SLCMS system
docs: UpdateModule() - brings an installed module up to current version
docs: TakeErrorCatch() - common handler for try/catch logging - private function
docs: LogIt() - sends supplied info to global logging engine - private function
docs: endFunctions
docs: 
docs: startManual
docs:   The above functions are the required minimum function set, you can add your own things with no issues as long as the first three above are there with working code,
docs: those included/coded below those three are cloned from a working module, the SL_Photogallery, after it was developed as the first, 
docs: non database module so some of the comments fit that module as examples.
docs:   As an aside Kym likes to have structures looking pretty when she looks at dumps so she uses the alternate method of defining structs, etc.
docs: 	ret["Error"] = StructNew() instead of ret.Error = StructNew() and similar so it displays as: ret.Error
docs: Note also that this code has evolved all the way from CF 4.5 when it was training code for new mbcomms developers so some constructs are very old fashioned
docs: and when the decision was made to go opensource about the time that OpenBD and Railo appeared neither supported the shorthand struct and array constructors
docs: so when we upgraded the code base and also moved a lot of code to CFCs we left a lot of code as it was, very old-fashioned. But it works :-)
docs: endManual
docs: 
docs: startHistory_Versions
docs: Version 1.0.0.458: 	Initial Coding
docs: Version 1.0.0.383: 	
docs: endHistory_Versions
docs:
docs: startHistory_Coding
docs:	cloned:   11th Nov 2012 from _Empty Module by Kym K, mbcomms
docs:	modified: 11th Nov 2012 -  3rd Dec 2012 by Kym K, mbcomms: initial work on it
docs: endHistory_Coding
 --->

<!--- the ModuleController components are not persistent 
			but we can set up the odd var in the pseudo constructor here to make maintenance easy
			 --->
<cfset variables.Version = "0.0.0.458" /> <!--- the version of this code set --->
<cfset variables.theModuleFormalName = "SL_Wiki" /> <!--- formal name of this module, it _has_ to be the folder name tha the module is within --->
<cfset variables.theModuleFriendlyName = "SL Wiki" /> <!--- friendly name of this module, usually similar to the the folder name but does not have to be. Used in error reporting and menus --->

<cffunction name="getBaseDefinition" output="yes" returntype="struct" access="public"
	displayname="get Base Definition"
	hint="sends all the config info to SLCMS on a restart/reconfig/flush"
	>
	<!--- this function takes one argument --->
	<cfargument name="ApplicationPaths" required="true" type="struct" hint="the application paths struct to get our paths from">

	<!--- now all of the var declarations, first the standard return structure, I'd be surprised if it errored but use the shape anyway --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, quasi-empty result --->
	<cfset ret["error"] = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorContext = "#variables.theModuleFriendlyName# - Module ModuleController CFC: getBaseDefinition()" />
	<cfset ret.error.ErrorText = "" />
	<cfset ret.error.ErrorExtra = "" />
	<cfset ret["Data"] = StructNew() />	<!--- set up an empty complete struct that will not make the module manager have a pink fit, we will fill in details below as needed for this module --->
	<cfset ret.Data["CoreAdminAPI"] = StructNew() />	<!--- config for where core admin tasks can find things, these are not copied to app scope but handled by the module manager --->
	<cfset ret.Data["Dependencies"] = StructNew() />	<!--- will be the other modules that this module depends on --->
	<cfset ret.Data["DisplayTypes"] = StructNew() />	<!--- struct of what basic displays we can do, most of the time just one --->
	<cfset ret.Data["Flags"] = StructNew() />	<!--- will be carry all of the flags to say we can and can't do stuff --->
	<cfset ret.Data["ModuleAdmin"] = StructNew() />	<!--- related to the admin section of this module --->
	<cfset ret.Data["ModuleNaming"] = StructNew() />	<!--- will be the name definitions --->
	<cfset ret.Data["Paths"] = StructNew() />	<!--- where to find things --->
	<cfset ret.Data["Search"] = StructNew() />	<!--- related to the admin section of this module --->
	<cfset ret.Data["Users"] = StructNew() />	<!--- related to visitors, users and staff --->
	<!--- now fill in blank defaults where we have to have them to stop upstream breaking --->
	<cfset ret.Data.CoreAdminAPI["PageProperties"] = StructNew() />	<!--- we will set blank defaults --->
	<cfset ret.Data.CoreAdminAPI.PageProperties.ContentSelectors = {} />	<!--- struct of types, one for each display type [DropDown|Radio|Checkbox|Popup] - chooses what type of selector display to use --->
	<cfset ret.Data.CoreAdminAPI.PageProperties.SelectorList = "" />	<!--- List of items in display order, has to be from DisplayTypes.TypeList --->
	<cfset ret.Data.CoreAdminAPI["Preprocessor"] = StructNew() />	<!--- these are the frontend tags that can be called before the module is displayed --->
	<cfset ret.Data.CoreAdminAPI.Preprocessor.IncludeList = "" />	<!--- list of includes in calling order --->
	<cfset ret.Data.CoreAdminAPI.Preprocessor.TagList = "" />	<!--- list of tags to call in calling order --->
	<cfset ret.Data.Dependencies["Core"] = StructNew() />	<!--- will be the core functions that this module depends on (used to decide when to call this module's ReInitAfter function if something in the core changes like portals turned on) --->
	<cfset ret.Data.Dependencies["Module"] = StructNew() />	<!--- ditto for other modules --->
	<cfset ret.Data.Dependencies["System"] = StructNew() />	<!--- ditto for system stuff, do we need this? --->
	<cfset ret.Data.Users["Roles"] = StructNew() />	<!--- roles flags related to visitors, users and staff --->
	<cfset ret.Data.Users.Roles.ModuleHasStaffRoles = False />	<!--- whether this module has any roles for staff members --->
	<cfset ret.Data.Users.Roles.ModuleHasPeopleRoles = False />	<!--- whether this module has any roles for Joe Public --->

		
		<!---   ***  this is the bit we edit to make this module go  ***   --->
		
	<cftry>
		<cfif isStruct(arguments.ApplicationPaths) and structkeyexists(arguments.ApplicationPaths, "SitePhysicalRoot")>	<!--- simple check to make sure we have the right data to calculate paths from --->
			<!--- tell SLCMS who we are are and what we do, etc --->
			<cfset ret.Data.Dependencies.Core.ReInitFromCoreCFCList = "PortalControl" />	<!--- list of the core CFCs that this module depends on (used to decide when to call this module's ReInitAfter function) --->
			<cfset ret.Data.Dependencies.Module.NeededModulesList = "" />	<!--- list of other modules that this module depends on, have to be there for this module to work --->
			<cfset ret.Data.Dependencies.Module.ReInitFromModulesList = "" />	<!--- list of other modules that this module depends on (used to decide when to call this module's ReInitAfter function) --->
			<cfset ret.Data.DisplayTypes.HasFrontEnd = True />	<!--- flag to show if the modules has frontend display ability --->
			<cfset ret.Data.DisplayTypes.TypeList = "Content" />	<!--- list of what basic displays we can do. Has to be at least one, if there is a front end --->
			<!--- NOTE! edit these as required and we must manually add in the structure of each display type if more than these --->
			<cfset ret.Data.DisplayTypes.Content = StructNew() />	<!--- first in list of display types we can do --->
			<cfset ret.Data.DisplayTypes.Content.Mode = "Tag" />	<!--- flag to show which to show by default [Template|Tag] --->
			<cfset ret.Data.DisplayTypes.Content.Template = "" />	<!--- filename of the template to display --->
			<cfset ret.Data.DisplayTypes.Content.Tag = "displayWikiContent.cfm" />	<!--- filename of the tag to call from the core --->
			<!--- 
			<cfset ret.Data.DisplayTypes.Type2 = StructNew() />	<!--- list of what basic displays we can do --->
			<cfset ret.Data.DisplayTypes.Type2.Mode = "Template" />	<!--- flag to show which to show by default --->
			<cfset ret.Data.DisplayTypes.Type2.Template = "DisplayType2.cfm" />	<!--- filename of the template to display this type --->
			<cfset ret.Data.DisplayTypes.Type2.Tag = "displayModule2.cfm" />	<!--- filename of the tag to call from the core --->
			 --->
			<cfset ret.Data.Flags.PortalAware = True />	<!--- happy with subsites as just different content --->
			<cfset ret.Data.ModuleAdmin.AdminFolder = "Admin/" />	<!--- the folder that has the admin section --->
			<cfset ret.Data.ModuleAdmin.AdminDefaultPage = "ModuleAdminHome.cfm" />	<!--- the name of the admin home include file for this module that will be called if no other specified --->
			<cfset ret.Data.ModuleNaming.FormalName = variables.theModuleFormalName />	<!--- the name used by the system, must match the folder name it is installed in --->
			<cfset ret.Data.ModuleNaming.FriendlyName = variables.theModuleFriendlyName />	<!--- the name used in menus and admin and the like --->
			<cfset ret.Data.ModuleNaming.Description = "wiki-style content. Mixes in with core's standard content" />	<!--- description of what this module is all about --->
			<cfset ret.Data.Paths.Templates = "Presentation" />	<!--- the folder that has templates to include --->
			<cfset ret.Data.Paths.TemplateList = "" />	<!--- all of the templates that you want to be selected in the page properties drop-down --->
			<cfset ret.Data.Paths.TemplateDefault = "" />	<!--- the name of the default/global/main template include file that will be called if no template specified --->
			<cfset ret.Data.Paths.TemplateTags = "TemplateTags/" />	<!--- the folder that has display tags for templates --->
			<cfset ret.Data.Paths.TemplateTagsDefault = "displayWikiContent.cfm" />	<!--- the name of the default/global/main template include file that will be called if no template specified --->
			<cfset ret.Data.Search.ModuleIsSearchable = True />	<!--- can we search this module? --->
			<cfset ret.Data.Search.Searches = {} />	
			<cfset ret.Data.Users.Roles.ModuleHasStaffRoles = False />	<!--- whether this module has any roles for staff members --->
			<cfset ret.Data.Users.Roles.ModuleHasPeopleRoles = False />	<!--- whether this module has any roles for Joe Public --->
			<!--- now some API stuff --->
			<!--- first the name of the standard CFC that acts as a wrapper for most calls so it is the same everywhere, has to have a standard set of methods in it --->
			<cfset ret.Data.CoreAdminAPI.CoreAPIcfcName = "API_Core" />	<!--- this is the standard API CFC name, we could change it if we want to --->
			<!--- here we set what we can show in the core admin pages like page creation  --->
			<!--- none for the wiki --->
			<!--- if we are going to use a popup selector for content type selector then these are the URLs to reach the popup --->
			<cfset ret.Data.CoreAdminAPI.Pageproperties.PopupURLs = {} />	
			<cfset ret.Data.CoreAdminAPI.Preprocessor.TagList = "" />	<!--- list of tags to call in calling order --->
			<!--- API section finished --->
			
			<!---   ***  end of edited section  ***   --->
			
			<!--- now a few calculated things, change if you are into exotica! :-) --->
			<cfset ret.Data.ModuleAdmin.AdminRootURL_Rel = "#arguments.ApplicationPaths.ModulesRoot_Rel##ret.Data.ModuleNaming.FormalName#/#ret.Data.ModuleAdmin.AdminFolder#" />	<!--- root URL to the admin area --->
			<cfset ret.Data.ModuleAdmin.AdminRootURL_Abs = "#arguments.ApplicationPaths.RootURL##ret.Data.ModuleAdmin.AdminRootURL_Rel#" />	<!--- root URL to the admin area --->
			<cfset ret.Data.ModuleAdmin.AdminDefaultPageURL_Rel_Local = "#ret.Data.ModuleAdmin.AdminFolder##ret.Data.ModuleAdmin.AdminDefaultPage#" />	<!--- URL to this page, relative to this module's root --->
			<cfset ret.Data.ModuleAdmin.AdminDefaultPageURL_Rel = "#ret.Data.ModuleAdmin.AdminRootURL_Rel##ret.Data.ModuleAdmin.AdminDefaultPage#" />	<!--- URL to this page, relative from site root --->
			<cfset ret.Data.ModuleAdmin.AdminDefaultPageURL_Abs = "#arguments.ApplicationPaths.RootURL##ret.Data.ModuleAdmin.AdminDefaultPageURL_Rel#" />	<!--- URL to this page, absolute from site root --->
			<cfset ret.Data.ModuleAdmin.AdminDefaultPagePhys_Abs = "#arguments.ApplicationPaths.SitePhysicalRoot##ret.Data.ModuleAdmin.AdminDefaultPageURL_Rel#" />	<!--- physical path to this page --->
			<cfset ret.Data.ModuleAdmin.HasAdmin = fileExists(ret.Data.ModuleAdmin.AdminDefaultPagePhys_Abs) />	<!--- has an admin section to include in admin area --->
			<cfset ret.Data.Flags.HasAdmin = ret.Data.ModuleAdmin.HasAdmin />
			<cfset ret.Data.Flags.Version = variables.version />
			<cfset ret.Data.Paths.CFCRoot = '#replace("#arguments.ApplicationPaths.ModulesRoot_Rel#", "/", ".", "all")##ret.Data.ModuleNaming.FormalName#.CFCs.' />
		<cfelse>
			<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 1) />
			<cfset ret.error.ErrorText = ret.error.ErrorText & "Oops! No ApplicationBaseConfig argument Supplied<br>" />
			<cflog text='#ret.error.ErrorText# - ret.error.ErrorCode: #ret.error.ErrorCode# - Time: #DateFormat(Now(),"YYYYMMDD")#-#TimeFormat(now(),"HH:mm:ss")#'  file="#Application.SLCMS.Logging.theSiteLogName#" type="Error" application = "yes">
		</cfif>
	<cfcatch type="any">
		<cfset ret.error = TakeErrorCatch(RetErrorStruct=ret.error, CatchStruct=cfcatch) />
		<!--- 
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 128) />
		<cfset ret.error.ErrorText = ret.error.ErrorContext & ' Trapped. Site: #application.SLCMS.config.base.SiteName#, error message was: #cfcatch.message#, error detail was: #cfcatch.detail#' />
		<cfset ret.error.ErrorExtra =  cfcatch.TagContext />
		<cfif isArray(ret.error.ErrorExtra) and StructKeyExists(ret.error.ErrorExtra[1], "Raw_Trace")>
			<cfset ret.error.ErrorText = ret.error.ErrorText & ", Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#" />
		</cfif>
		<cflog text='#ret.error.ErrorText# - ret.error.ErrorCode: #ret.error.ErrorCode# - Time: #DateFormat(Now(),"YYYYMMDD")#-#TimeFormat(now(),"HH:mm:ss")#'  file="#Application.SLCMS.Logging.theSiteLogName#" type="Error" application = "yes">
		<cfif application.SLCMS.config.debug.debugmode>
			getBaseDefinition() Trapped - error dump:<br>
			<cfdump var="#ret.error.ErrorExtra#">
		</cfif>
		 --->
	</cfcatch>
	</cftry>
	
	<!--- return our data structure --->
	<cfreturn ret  />
</cffunction>

<!--- initialize the various thingies, this should only be called after an app scope refresh --->
<cffunction name="initModule" 
	access="public" output="yes" returntype="any" 
	displayname="Initializer"
	hint="sets up the internal structures for this component"
	>
	<!--- this function needs.... --->
	<cfargument name="ApplicationConfig" type="struct" required="true" />	<!--- the configuration structure, normally the application.SLCMS.config struct --->
	<cfargument name="ModuleConfig" type="struct" required="true" />	<!--- the configuration structure for this module, needed as this method is called cold at startup, this CFC is not persistent --->

	<!--- create the return structure, compulsory when talking to SLCMS core --->
	<cfset var ret = StructNew() />
	<!--- and load it up with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorContext = "#variables.theModuleFriendlyName# Module ModuleController CFC: initModule()" />
	<cfset ret.error.ErrorText = "" />
	<cfset ret.error.ErrorExtra = "" />
	<cfset ret.Data = StructNew() />	<!--- and no data yet but it will probaly be a huge structure --->

	<cfset variables.theConfig = arguments.ApplicationConfig />
	<!--- first lets load in our persistent CFCs, etc --->
	<cfset application.SLCMS.Modules["#variables.theModuleFormalname#"].functions = StructNew() />
	<cfset application.SLCMS.Modules["#variables.theModuleFormalname#"].functions.wiki_code = createObject("component","#arguments.ModuleConfig.paths.moduleRootURLpath#CFCs/wiki_code") /><!--- base code functions --->
	<cfset application.SLCMS.Modules["#variables.theModuleFormalname#"].functions.wiki_disp = createObject("component","#arguments.ModuleConfig.paths.moduleRootURLpath#CFCs/wiki_disp") /><!--- display functions --->
	<cfset application.SLCMS.Modules["#variables.theModuleFormalname#"].functions.wiki_render = createObject("component","#arguments.ModuleConfig.paths.moduleRootURLpath#CFCs/wiki_render") /><!--- rendering functions, text formatting, etc. --->
	<cfset ret.Data.PersistentInit_code = application.SLCMS.Modules["#variables.theModuleFormalname#"].functions.wiki_code.init(ModuleFormalname="#variables.theModuleFormalname#") />
	<!--- again copied from the photogallery, tickle as needed for your module --->
	<!--- first lets load in our persistent CFCs, etc --->
	<!--- we drop then directly into the app scope, this module is quasi-dumb with no database or anything --->
	<!--- first we set OnS variables as the init()s below use them --->
	<!--- 
	<cfset application.SLCMS.Modules["#variables.theModuleFormalname#"].Paths.FileUploadPath_Phys = application.SLCMS.Paths_Common.UploadTempFolder_Phys & variables.theModuleFormalname & "/"  /> 
	<cfset application.SLCMS.Modules["#variables.theModuleFormalname#"].functions = StructNew() />
	<cfset application.SLCMS.Modules["#variables.theModuleFormalname#"].functions.Utilities_Persistent = createObject("component","#arguments.ModuleConfig.paths.moduleRootURLpath#CFCs/Persistent") /><!--- this CFC has functions and data that we need to be persistent --->
	<cfset ret.Data.GalleryPersistentInit = application.SLCMS.Modules["#variables.theModuleFormalname#"].functions.Utilities_Persistent.init(ModuleFormalname="#variables.theModuleFormalname#") />
	<cfset application.SLCMS.Modules["#variables.theModuleFormalname#"].functions.ImageManager = createObject("component","#arguments.ModuleConfig.paths.moduleRootURLpath#CFCs/ImageManager") /><!--- all the base, wrapper functions and data that we need to run frmo anywhere, not just within the module --->
	<cfset ret.Data.ImageManagerInit = application.SLCMS.Modules["#variables.theModuleFormalname#"].functions.ImageManager.init(ModuleFormalname="#variables.theModuleFormalname#") />
	 --->
	<!--- and then check to make sure we have a folder structure or two to put the media in --->
<!--- 

	<cfset temp1 = aCommonInitFunctionForExample() />
	<cfdump var="#arguments#" expand="false">

 --->
	
	<cfreturn ret  />
</cffunction>

<cffunction name="ReInitAfter" output="yes" returntype="struct" access="public"
	displayname="Re-Init After"
	hint="re-initialize Module components after some external change"
	>
	<!--- this function needs.... --->
	<cfargument name="Action" type="string" default="" hint="the action that took place in the caller, used to define the components that need re-initializing" />

	<!--- now all of the var declarations, first the arguments which need manipulation --->
	<cfset var theAction = trim(arguments.Action) />
	<!--- now vars that will get filled as we go --->
	<cfset var temp1 = False />	<!--- temp/throwaway var --->
	<cfset var tempStruct2 = StructNew() />	<!--- temp/throwaway structure --->
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorContext = "#variables.theModuleFriendlyName# Module ModuleController CFC: ReInitAfter(#theAction#)" />
	<cfset ret.error.ErrorText = "" />
	<cfset ret.error.ErrorExtra = "" />
	<cfset ret.Data = "" />	<!--- and no data yet --->

	<!--- wrap the whole thing in a try/catch in case something breaks --->
	<cftry>
		<!--- try each action in turn --->
		<cfswitch expression="#theAction#">
			<!--- pick action performed and run the relevant refreshes --->
			<cfcase value="subSite">
				<!--- a changed subSite needs to refresh CFCs that relate to that --->
				<!--- see the core reInitAfter for sample code --->
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

	<!--- return our data structure --->
	<cfreturn ret  />
</cffunction>

<cffunction name="InstallModule" output="yes" returntype="struct" access="public"
	displayname="Install Module"
	hint="runs needed code to install Module, db table creation, etc."
	>

</cffunction>

<cffunction name="UpdateModule" output="yes" returntype="struct" access="public"
	displayname="Update Module"
	hint="runs needed code to update module to latest version"
	>

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

<cffunction name="TakeErrorCatch" output="Yes" returntype="any" access="private" 
	displayname="Take Error Catch"
	hint="Takes Error Trap in function and logs/displays it, etc"
	>
	<cfargument name="RetErrorStruct" type="struct" required="true" hint="the ret structure from the calling function" />	
	<cfargument name="CatchStruct" type="any" required="true" hint="the catch structure from the calling function" />	
	
	<!--- our temp vars --->
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
		<cfset error.ErrorText = error.ErrorConText & error.ErrorText & ' Trapped. Site: #application.SLCMS.config.base.SiteName#, error message was: #arguments.CatchStruct.message#, error detail was: #arguments.CatchStruct.detail#' />
		<cfif isArray(error.ErrorExtra) and StructKeyExists(error.ErrorExtra[1], "Raw_Trace")>
			<cfset error.ErrorText = error.ErrorText & " Line: #ListLast(arguments.CatchStruct.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#" />
		</cfif>
		<cfset temps = LogIt(LogType="CFC_ErrorCatch", LogString='#error.ErrorText# - ErrorCode: #error.ErrorCode#') />
	<cfcatch type="any">
		<cfset error.ErrorCode =  BitOr(error.ErrorCode, 255) />
		<cfset error.ErrorText = error.ErrorContext & ' Trapped. Site: #application.SLCMS.config.base.SiteName#, error message was: #cfcatch.message#, error detail was: #cfcatch.detail#' />
		<cfset error.ErrorText = error.ErrorText & ' caller error message was: #arguments.CatchStruct.message#, error detail was: #arguments.CatchStruct.detail#' />
		<cfset error.ErrorExtra =  arguments.CatchStruct.TagContext />
		<cfif isArray(error.ErrorExtra) and StructKeyExists(error.ErrorExtra[1], "Raw_Trace")>
			<cfset error.ErrorText = error.ErrorText & ", Line: #ListLast(arguments.CatchStruct.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#" />
		</cfif>
		<cflog text='TakeErrorCatch: Error Catch Caught: #error.ErrorText# - error.ErrorCode: #error.ErrorCode# - Time: #DateFormat(Now(),"YYYYMMDD")#-#TimeFormat(now(),"HH:mm:ss")#'  file="#Application.SLCMS.Logging.theSiteLogName#" type="Error" application = "yes">
		<cfif application.SLCMS.config.debug.debugmode>
			<cfoutput>#error.ErrorContext#</cfoutput> Trapped - error dump:<br>
			<cfdump var="#arguments.CatchStruct#">
		</cfif>
	</cfcatch>
	</cftry>	
	<cfreturn error  />
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
	<cfset ret.error.ErrorContext = "_Empty_Core CFC: LogIt()" />
	<cfset ret.error.ErrorExtra = "" />
	<cfset ret.Data = "" />	<!--- no data --->

	<!--- minimal validation --->
	<cfif theLogType neq "">
		<cftry>
			<cfset temps = application.SLCMS.core.SLCMS_Utility.WriteLog_Core(LogType="#theLogType#", LogString="#theLogString#") />
			<cfif temps.error.errorcode neq 0>
				<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 2) />
				<cfset ret.error.ErrorText = ret.error.ErrorText & "Log Write Failed. Error was: #temps.error.ErrorText#<br>" />
			</cfif>
		<cfcatch type="any">
			<!--- we cannot use our error catcher as it is using this function, we would have an infinite loop! --->
			<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 128) />
			<cfset ret.error.ErrorText = ret.error.ErrorContext & ' Trapped. Site: #application.SLCMS.config.base.SiteName#, error message was: #cfcatch.message#, error detail was: #cfcatch.detail#' />
			<cfset ret.error.ErrorExtra =  cfcatch.TagContext />
			<cfif isArray(ret.error.ErrorExtra) and StructKeyExists(ret.error.ErrorExtra[1], "Raw_Trace")>
				<cfset ret.error.ErrorText = ret.error.ErrorText & ", Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#" />
			</cfif>
			<cflog text='#ret.error.ErrorText# - ret.error.ErrorCode: #ret.error.ErrorCode# - Time: #DateFormat(Now(),"YYYYMMDD")#-#TimeFormat(now(),"HH:mm:ss")#'  file="#Application.SLCMS.Logging.theSiteLogName#" type="Error" application = "yes">
			<cfif application.SLCMS.config.debug.debugmode>
				<cfoutput>#ret.error.ErrorContext#</cfoutput> Trapped - error dump:<br>
				<cfdump var="#cfcatch#">
			</cfif>
		</cfcatch>
		</cftry>
	<cfelse>	<!--- this is the error code --->
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 1) />
		<cfset ret.error.ErrorText = ret.error.ErrorText & "Oops! No Log Type<br>" />
	</cfif>

	<cfreturn ret  />
</cffunction>

</cfcomponent>

