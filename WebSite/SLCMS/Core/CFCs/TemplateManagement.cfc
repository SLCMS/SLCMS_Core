<cfcomponent  extends="controller" 
	output="no"
	displayname="Template Management" 
	hint="contains a set of tools for Template Management"
	>
<!--- mbc SLCMS CFCs  --->
<!--- &copy; 2012 mort bay communications --->
<!---  --->
<!--- a set of utilities for working with SLCMS site templates --->
<!--- finds and loads the various template files that control the site presentation
			A SLCMS form can have one base component with two possible extra components.
			The base component must be named: formname-Form.cfm 
			 with the "formname" part being the common name used as a reference and displayed in selectors, etc.
			 At a minimum it must carry the HTML to display the form.
			The second component is a processing page named: formname-Process.cfm 
			The third component is a control file for field names, validation, etc. named: formname-Control.ini 
			 --->
<!--- Contains:
			init - set up persistent structures for control of the forms in the site
			lots more related stuff :-)
			LogIt() - sends supplied info to global logging engine - private function
			TakeErrorCatch() - common handler for try/catch logging - private function
			 --->
<!---  --->
<!--- created:  16th Sep 2008 by Kym K - mbcomms --->
<!--- modified: 16th Sep 2008 - 16th Sep 2008 by Kym K, mbcomms: initial work --->
<!--- modified: 14th Nov 2008 - 27th Nov 2008 by Kym K, mbcomms: 2nd burst of initial work on it --->
<!--- modified:  1st Dec 2008 -  1st Dec 2008 by Kym K, mbcomms: made it silent, all function outputs --->
<!--- modified: 21st Mar 2009 - 28th Mar 2009 by Kym K, mbcomms: V2.2, changing code folder structure to new module-allowing architecture, the core code is now just another module --->
<!--- modified: 22nd Apr 2009 - 27th Apr 2009 by Kym K, mbcomms: V2.2, changing template folder structure to portal/sub-site architecture, sites inside the top site --->
<!--- modified:  5th Oct 2009 -  5th Oct 2009 by Kym K, mbcomms: V2.2, more of the same with the user permissionm engine --->
<!--- modified: 30th Oct 2009 - 31st Oct 2009 by Kym K, mbcomms: V2.2, reworked naming for portal code and improved error handlers --->
<!--- modified: 19th Nov 2009 - 19th Nov 2009 by Kym K, mbcomms: V2.2, oops! missed a rename in ReloadTemplateType() --->
<!--- modified: 18th Feb 2011 - 18th Feb 2011 by Kym K, mbcomms: V2.2+, ran varScoper over code and found one un-var'd variables! oops, one too many :-/  --->
<!--- modified:  7th Jun 2011 - 19th Jun 2011 by Kym K, mbcomms: V2.2+, added logging functions so we can have consistent logging outside CF's logs --->
<!--- modified: 31st Dec 2011 -  4th Jan 2012 by Kym K, mbcomms: V2.2+, changed the way templates are stored, now we can have the module ones as well and can customize them --->
<!--- modified:  8th Mar 2012 - 11th Mar 2012 by Kym K, mbcomms: V2.2+, added core display tags to mix so they can be modified if needs be --->
<!--- modified: 17th Mar 2012 - 18th Mar 2012 by Kym K, mbcomms: V2.2+, having issues with above. Changing to allow for urlpath and physical are the same these days with physical or url site root on front, no need to worry about reverse slashes --->
<!--- modified:  9th Apr 2012 - 11th Apr 2012 by Kym K, mbcomms: V3.0, CFWheels version. All SLCMS in own struct under app scope. Added subSite argument to ReInit() --->

	
	<!--- set up a few persistant things on the way in. --->
	<!--- the template types and related paths, names and things. Hard code some bits to save having to work out on the fly every time when they are constants --->
	<cfset variables["Lists"] = StructNew() />
	<cfset variables.Lists.CoreTemplateTypeList = "Page,Sub" />	<!--- this carries a list of the Template Types the Core uses --->
	<cfset variables.Lists.SubTemplateMainTypeList = "Form,Tag" />	<!--- this carries a list of the subTemplate Types found --->
	<cfset variables.Lists.FormSubTemplateTypeList = "" />	<!--- this will carry a list of the Form subTemplate found in the system --->
	<cfset variables.Lists.TagSubTemplateTypeList = "" />	<!--- ditto for tag types --->
	<cfset variables.Lists.ModuleTemplateTypeList = "" />	<!--- this carries a list of the subTemplate sets the Core uses --->
	<cfset variables.Lists.ModuleSubTemplateTypeList = "" />	<!--- this will carry a list of the subTemplate Types used by Modules --->
	<cfset variables["TemplateParts"] = StructNew() />
	<cfset variables.TemplateParts.PartList = "Templates,TemplateIncludes,TemplateControl,NavigationControl,TemplateGraphics,StylingGraphics" /> <!--- this is a list of the template's subsets, the bits in a template (note these are not the folder names, just the type of subset) --->
	<cfset variables.TemplateParts.PartCount = ListLen(variables.TemplateParts.PartList) /> <!--- this is the number of parts in a template set --->
	<cfset variables.TemplateParts.ExtensionList = "cfm,cfm,cntrl,ini,gfix,gfix" /> <!--- this is a list of the file extensions to match the list above. gfix means any allowed graphic file --->
	<cfset variables.TemplateParts.gfixExtensionList = "gif,jpg,png,swf" /> <!--- this is a list of the file extensions of allowed graphic files --->
	<cfset variables.TemplateParts.cntrlExtensionList = "css,js" /> <!--- this is a list of the file extensions of allowed template (html) control files --->
	<!--- these next ones define where to find the component parts of a template relative to the  root of the template set we are in --->
	<cfset variables["Paths"] = StructNew() />
	<cfset variables.Paths["PartsPaths"] = StructNew() />
	<cfset variables.Paths.PartsPaths.NavigationControlRelPath = "TemplateControl/NavigationControl/" />	<!--- ini files to define nav --->
	<cfset variables.Paths.PartsPaths.TemplateControlRelPath = "TemplateControl/" />
	<cfset variables.Paths.PartsPaths.StylingGraphicsRelPath = "TemplateControl/StylingGraphics/" />
	<cfset variables.Paths.PartsPaths.TemplatesRelPath = "/" />	<!--- the templates themselves, normaly in the root of the folder set --->	
	<cfset variables.Paths.PartsPaths.TemplateIncludesRelPath = "TemplateIncludes/" />
	<cfset variables.Paths.PartsPaths.TemplateGraphicsRelPath = "TemplateGraphics/" />
	<cfset variables.Paths.CoreFormsRelPath = "CoreForms/" />
	<cfset variables.Paths.CoreTagsRelPath = "CoreTags/" />
	<!--- the base path bits to find things, will get filled by the init() code (here in affabek lauder so easy to find) --->
	<cfset variables.Paths.FormTemplatesRelPath = "" />
	<cfset variables.Paths.PresentationRelPath = "" />
	<cfset variables.Paths.PageTemplatesRelPath = "" />
	<cfset variables.Paths.SubTemplatesRelPath = "" />
	<cfset variables.Paths.SharedRelPath = "" />
	<cfset variables.Paths.SharedBasePhysicalPath = "" />
	<cfset variables.Paths.SitesBasePhysicalPath = "" />
	<cfset variables.Paths.TagTemplatesRelPath = "" />
	<cfset variables.Paths.WebsiteBasePhysicalPath = "" />
	<!--- portal related data --->
	<cfset variables.SubSiteControl = StructNew() />
	<cfset variables.SubSiteControl.ActiveSubSiteIDList = "0" />
	<cfset variables.SubSiteControl.SubSiteIDList_Full = "0" />
	<cfset variables.SubSiteControl.SubSiteData = StructNew() />
	<!--- and module related data --->
	<cfset variables.ModuleControl = StructNew() />
	<cfset variables.ModuleControl.ActiveModuleList = "" />
	<cfset variables.ModuleControl.SubSiteData = StructNew() />

<!--- initialize the various thingies, this is normally called after an app scope refresh --->
<cffunction name="init" output="yes" returntype="any" access="public" 
	displayname="Initializer"
	hint="sets up the internal structures for this component"
	>
	<cfargument name="Config" type="struct" required="yes" hint="the config part of application scope so we can work out all the paths">

	<cfset var theConfig = arguments.config />
	<cfset var thePaths = StructNew() />
	<cfset var theTemplatesPhysicalPath = "" /> <!--- temp var --->
	<cfset var thisTemplateType = "" /> <!--- temp var --->
	<cfset var thisSubSiteID = "" /> <!--- temp var, loop index --->
	<cfset var tempResult = "" /> <!--- temp var --->
	<cfset var temps = "" /> <!--- temp return struct --->
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorText = "" />
	<cfset ret.error.ErrorContext = "TemplateManagement CFC: Init()" />
	<cfset ret.Data = "" />

	<cfset temps = LogIt(LogType="CFC_Init", LogString="TemplateManagement Init() Started") />
	<cftry>
		<!--- set up the base params --->
		<cfset variables.Paths.WebsiteBasePhysicalPath = theConfig.StartUp.SiteBasePath />
		<cfset variables.Paths.SitesBaseRelPath =  theConfig.base.SitesBaseRelPath />
		<cfset variables.Paths.SitesBasePhysicalPath = variables.Paths.WebsiteBasePhysicalPath & variables.Paths.SitesBaseRelPath />
		<cfset variables.Paths.SharedRelPath = theConfig.base.SharedRelPath />
		<cfset variables.Paths.SharedBasePhysicalPath = variables.Paths.WebsiteBasePhysicalPath & variables.Paths.SharedRelPath />
		<cfset variables.Paths.PresentationRelPath = theConfig.base.PresentationRelPath />
		<cfset variables.Paths.PageTemplatesRelPath = theConfig.base.PageTemplatesRelPath />
		<cfset variables.Paths.SubTemplatesRelPath = theConfig.base.SubTemplatesRelPath />
		<cfset variables.Paths.FormTemplatesRelPath = theConfig.base.FormTemplatesRelPath />
		<cfset variables.Paths.TagTemplatesRelPath = theConfig.base.TagTemplatesRelPath />
		<cfset variables.Paths.CoreFormsRelPath = variables.Paths.FormTemplatesRelPath & variables.Paths.CoreFormsRelPath />
		<cfset variables.Paths.CoreFormsAbsPath = variables.Paths.SharedBasePhysicalPath & variables.Paths.CoreFormsRelPath />
		<cfset variables.Paths.CoreTagsRelPath = variables.Paths.TagTemplatesRelPath & variables.Paths.CoreTagsRelPath />
		<cfset variables.Paths.CoreTagsAbsPath = variables.Paths.SharedBasePhysicalPath & variables.Paths.CoreTagsRelPath />
		<!--- now we will grab all of the Core templates and subTemplates so we know what is what and where --->
		<cfset ReInit() />
	<cfcatch type="any">
		<cfset ret.error = TakeErrorCatch(RetErrorStruct=ret.error, CatchStruct=cfcatch) />
	</cfcatch>
	</cftry>
	<cfset temps = LogIt(LogType="CFC_Init", LogString="TemplateManagement Init() Finished") />
	
	<cfreturn ret />
</cffunction>

<cffunction name="reInit" output="no" returntype="struct" access="public"
	displayname="reInitialize Templates"
	hint="reloads the Template sets to pick up new templates that have loaded into system"
				>
	<cfargument name="SubSiteID" type="string" required="no" default="" hint="the ID of the subsite to refresh, or the string 'Shared' for the shared templates. Blank (default) does all)">

	<cfset var theSubSiteID = trim(arguments.SubSiteID) />
	<cfset var ret = StructNew() />
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorText = "" />
	<cfset ret.error.ErrorContext = "Templatemanagement CFC: ReloadTemplateType()" />
	<cfset ret.Data = "" />

	<cftry>
		<cfset temps = LogIt(LogType="CFC_Init", LogString="TemplateManagement ReInit() Started") />
		<!--- we have the common set and then the site-specific ones, which can be standalone or customized versions of the common ones, particularly for module subtemplates
					BUT! at this Init stage we don't have any modules running so we will just do the core stuff and fill in later once the modules are loaded --->
		<!--- first our shared templates --->
		<cfif theSubSiteID eq "Shared" or theSubSiteID eq ""> 
			<cfset temps = RefreshSubSiteTemplateData("Shared") >
		</cfif>
		<cfif temps.error.errorcode neq 0>
			<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 1) />
			<cfset ret.error.ErrorText = ret.error.ErrorText & "Oops! RefreshSubSiteData for the Shared templates failed. Error was: #temps.error.ErrorText#<br>" />
		</cfif>
		<!--- then the subSites so grab the list of them --->
		<cfset variables.SubSiteControl.SubSiteIDList_Active = application.SLCMS.Core.PortalControl.GetActiveSubSiteIDList() />
		<cfset variables.SubSiteControl.SubSiteIDList_Full = application.SLCMS.Core.PortalControl.GetFullSubSiteIDList() />
		<!--- and then loop over them refreshing each in turn --->
		<cfloop list="#variables.SubSiteControl.SubSiteIDList_Full#" index="thisSubSiteID">
			<cfif theSubSiteID eq "" or (isNumeric(thisSubSiteID) and ListFindNoCase(variables.SubSiteControl.SubSiteIDList_Full, thisSubSiteID))> 
				<cfset temps = RefreshSubSiteTemplateData("#thisSubSiteID#") />
				<cfif temps.error.errorcode neq 0>
					<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 2) />
					<cfset ret.error.ErrorText = ret.error.ErrorText & "Oops! RefreshSubSiteData for subsite #thisSubSiteID# failed. Error was: #temps.error.ErrorText#<br>" />
				</cfif>
			</cfif>
		</cfloop>
	<cfcatch type="any">
		<cfset ret.error = TakeErrorCatch(RetErrorStruct=ret.error, CatchStruct=cfcatch) />
	</cfcatch>
	</cftry>
	<cfset temps = LogIt(LogType="CFC_Init", LogString="TemplateManagement ReInit() Finished") />
	
	<cfreturn ret />
</cffunction>

<cffunction name="RefreshSubSiteTemplateData" output="yes" returntype="any" access="public" 
	displayname="Refresh SubSite Data"
	hint="sets up the internal structures for one subsite. called by init or can be called on own for one subsite"
	>
	<cfargument name="SubSiteID" type="string" required="yes" hint="the ID of the subsite to refresh, or the string 'Shared' for the shared templates">

	<cfset var theSubSiteID = trim(arguments.SubSiteID) />
	<cfset var theTemplatesRelURLPath = "" /> <!--- temp var in loop --->
	<cfset var theTemplatesPhysicalPath = "" /> <!--- temp var in loop --->
	<cfset var theTemplatesBaseURLPath = "" /> <!--- temp var in loop --->
	<cfset var thisTemplateType = "" /> <!--- temp var, loop index --->
	<cfset var theSubSiteFoldername = "" /> <!--- temp var carrying the subsite shortname whilst doing folder lookups --->
	<cfset var thissubTemplateMainType = "" />
	<cfset var thissubTemplateType = "" />
	<cfset var theWorkingDirectory = "" />
	<cfset var qryThisMainsubTemplateDirectory = "" />
	<cfset var tempResult = "" /> <!--- temp var --->
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorText = "" />
	<cfset ret.error.ErrorContext = "Templatemanagement CFC: RefreshSubSiteTemplateData()" />
	<cfset ret.Data = "" />

	<cftry>
	<cfif theSubSiteID neq "">
		<cfif theSubSiteID eq "Shared" or (isNumeric(theSubSiteID) and ListFindNoCase(variables.SubSiteControl.SubSiteIDList_Full, theSubSiteID))>	
			<!--- good subsiteID --->
			<cfset variables["SubSite_#theSubSiteID#"] = StructNew() />	<!--- this structure carries the full data for all page template --->
			<!--- calculate the paths we need to read this subsite --->
			<cfif theSubSiteID eq "Shared">
				<cfset theSubSiteFoldername = "" />
				<cfset variables.SubSite_Shared.BaseRelURLpath = variables.Paths.SharedRelPath & variables.Paths.PresentationRelPath />	<!--- this is the full relative URL path to the shared template sets from the site root --->
				<cfset variables.SubSite_Shared.PresentationPhysicalPath = variables.Paths.SharedBasePhysicalPath & variables.Paths.PresentationRelPath />	<!--- this is the full physical path to the shared template sets --->
			<cfelse>
				<!--- not the shared templates so store this subSite's portal data --->
				<cfset variables.SubSiteControl.SubSiteData["SubSite_#theSubSiteID#"] = StructNew() />
				<cfset variables.SubSiteControl.SubSiteData["SubSite_#theSubSiteID#"] = duplicate(application.SLCMS.Core.PortalControl.GetSubSite(SubSiteID="#theSubSiteID#").data) />
				<!--- and work out the paths from that --->
				<cfset theSubSiteFoldername = variables.SubSiteControl.SubSiteData["SubSite_#theSubSiteID#"].SubSiteShortName />
				<cfset variables["SubSite_#theSubSiteID#"].BaseRelURLpath = variables.Paths.SitesBaseRelPath & theSubSiteFoldername & "/" & variables.Paths.PresentationRelPath />	<!--- this is the full relative URL path to the subSite template sets from the site root --->
				<cfset variables["SubSite_#theSubSiteID#"].PresentationPhysicalPath = variables.Paths.WebsiteBasePhysicalPath & variables["SubSite_#theSubSiteID#"].BaseRelURLpath />	<!--- this is the full physical path to the subSite template sets --->
			</cfif>
			<!--- now we loop over the template types and add in what we find --->
			<cfloop list="#variables.Lists.CoreTemplateTypeList#" index="thisTemplateType">
				<cfif thisTemplateType neq "Sub">	<!--- don't do for subTemplates, they have their own code below --->
					<!--- set up a fresh structure for it for starters --->
					<cfset variables["SubSite_#theSubSiteID#"]["#thisTemplateType#_Templates"] = StructNew() />	<!--- this structure carries the full data for all page template --->
					<cfset variables["SubSite_#theSubSiteID#"]["#thisTemplateType#_Templates"].TemplateSetList = "" />	<!--- this carries a list of the Page Template Sets available --->
					<cfset variables["SubSite_#theSubSiteID#"]["#thisTemplateType#_Templates"].TemplateSetCount = 0 />	<!--- this carries how many Page Template Sets there are --->
					<cfset variables["SubSite_#theSubSiteID#"]["#thisTemplateType#_Templates"].TemplateSets = StructNew() />	<!--- this structure carries the full data for each set of templates --->
					<cfset variables["SubSite_#theSubSiteID#"]["#thisTemplateType#_Templates"].TemplateGraphicsRelPath = variables.Paths.PartsPaths.TemplateGraphicsRelPath />	<!--- relative to the template set we are in --->
					<cfset variables["SubSite_#theSubSiteID#"]["#thisTemplateType#_Templates"].TemplateIncludesRelPath = variables.Paths.PartsPaths.TemplateIncludesRelPath />
					<cfset variables["SubSite_#theSubSiteID#"]["#thisTemplateType#_Templates"].TemplateControlRelPath = variables.Paths.PartsPaths.TemplateControlRelPath />
					<cfset variables["SubSite_#theSubSiteID#"]["#thisTemplateType#_Templates"].StylesheetGraphicsRelPath = variables.Paths.PartsPaths.StylingGraphicsRelPath />
					<cfset variables["SubSite_#theSubSiteID#"]["#thisTemplateType#_Templates"].NavigationControlRelPath = variables.Paths.PartsPaths.NavigationControlRelPath />
					<!--- we need path to templates: site root+subsitenaming+ --->
					<cfset variables["SubSite_#theSubSiteID#"]["#thisTemplateType#_Templates"].TemplatesBaseURLPath = variables["SubSite_#theSubSiteID#"].BaseRelURLPath & variables.Paths["#thisTemplateType#TemplatesRelPath"] />
					<cfset theTemplatesPhysicalPath = variables["SubSite_#theSubSiteID#"].PresentationPhysicalPath & variables.Paths["#thisTemplateType#TemplatesRelPath"] />	<!--- this is the physical path to where the Templates hang out --->
					<cfset variables["SubSite_#theSubSiteID#"]["#thisTemplateType#_Templates"].TemplatesBasePhysicalPath = theTemplatesPhysicalPath />
					<cfif DirectoryExists(theTemplatesPhysicalPath)>
						<!--- we have a Template path so grab what is in it, old stuff got cleared out above --->
						<!--- grab the templates straight into the variables scope, only check for errors back --->
						<cfset tempResult = LoadTemplateType(TemplateType="#thisTemplateType#", PhysPath2templates="#theTemplatesPhysicalPath#", URLPath2templates="#variables["SubSite_#theSubSiteID#"]["#thisTemplateType#_Templates"].TemplatesBaseURLPath#", SubSiteID="#theSubSiteID#") />
					<cfelse>
						<!--- oops! --->
						<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 1) />
						<cfset ret.error.ErrorText = ret.error.ErrorText & "Oops! The TemplatesPhysicalPath argument was incorrect, the folder does not exist.<br>The path supplied was: #theTemplatesPhysicalPath#" />
					</cfif>
				</cfif>
			</cfloop>	<!--- end: loop over template types --->
			<!--- now do it all again for the subTemplates, this time as a loop in a loop as we have the main types and then the real sets below that, an extra layer compared with the page templates --->
			<cfloop list="#variables.Lists.SubTemplateMainTypeList#" index="thissubTemplateMainType">
				<cfset variables["SubSite_#theSubSiteID#"]["#thissubTemplateMainType#_Templates"] = StructNew() />	<!--- this structure carries the full data for all the templates in this main type --->
				<cfset variables["SubSite_#theSubSiteID#"]["#thissubTemplateMainType#_Templates"].HasTemplateSets = False />	<!--- flag for empty sets --->
				<cfset theWorkingDirectory = variables["SubSite_#theSubSiteID#"].PresentationPhysicalPath & variables.Paths.SubTemplatesRelPath & variables.Paths["#thissubTemplateMainType#TemplatesRelPath"] />
				<cfdirectory action="list" name="qryThisMainsubTemplateDirectory" directory="#theWorkingDirectory#" type="dir" />
					<cfloop query="qryThisMainsubTemplateDirectory">
					<cfset variables["SubSite_#theSubSiteID#"]["#thissubTemplateMainType#_Templates"].HasTemplateSets = True />	<!--- flag no longer empty --->
					<cfset thissubTemplateType = qryThisMainsubTemplateDirectory.name />
					<cfset variables["SubSite_#theSubSiteID#"]["#thissubTemplateMainType#_Templates"]["#thissubTemplateType#_Templates"] = StructNew() />
					<cfset variables["SubSite_#theSubSiteID#"]["#thissubTemplateMainType#_Templates"]["#thissubTemplateType#_Templates"].TemplateSetList = "" />
					<cfset variables["SubSite_#theSubSiteID#"]["#thissubTemplateMainType#_Templates"]["#thissubTemplateType#_Templates"].TemplateSetCount = 0 />
					<cfset variables["SubSite_#theSubSiteID#"]["#thissubTemplateMainType#_Templates"]["#thissubTemplateType#_Templates"].TemplateSets = StructNew() />
					<cfset variables["SubSite_#theSubSiteID#"]["#thissubTemplateMainType#_Templates"]["#thissubTemplateType#_Templates"].TemplateGraphicsRelPath = variables.Paths.PartsPaths.TemplateGraphicsRelPath />	<!--- relative to the template set we are in --->
					<cfset variables["SubSite_#theSubSiteID#"]["#thissubTemplateMainType#_Templates"]["#thissubTemplateType#_Templates"].TemplateIncludesRelPath = variables.Paths.PartsPaths.TemplateIncludesRelPath />
					<cfset variables["SubSite_#theSubSiteID#"]["#thissubTemplateMainType#_Templates"]["#thissubTemplateType#_Templates"].TemplateControlRelPath = variables.Paths.PartsPaths.TemplateControlRelPath />
					<cfset variables["SubSite_#theSubSiteID#"]["#thissubTemplateMainType#_Templates"]["#thissubTemplateType#_Templates"].StylesheetGraphicsRelPath = variables.Paths.PartsPaths.StylingGraphicsRelPath />
					<cfset variables["SubSite_#theSubSiteID#"]["#thissubTemplateMainType#_Templates"]["#thissubTemplateType#_Templates"].NavigationControlRelPath = variables.Paths.PartsPaths.NavigationControlRelPath />
					<cfset theTemplatesRelURLPath = variables.Paths.SubTemplatesRelPath & variables.Paths["#thissubTemplateMainType#TemplatesRelPath"] & thissubTemplateType & "/" />
					<cfset theTemplatesBaseURLPath = variables["SubSite_#theSubSiteID#"].BaseRelURLPath & theTemplatesRelURLPath />
					<cfset variables["SubSite_#theSubSiteID#"]["#thissubTemplateMainType#_Templates"]["#thissubTemplateType#_Templates"].TemplatesBaseURLPath = theTemplatesBaseURLPath />
					<cfset theTemplatesPhysicalPath = variables.Paths.WebsiteBasePhysicalPath & theTemplatesBaseURLPath />
					<cfset variables["SubSite_#theSubSiteID#"]["#thissubTemplateMainType#_Templates"]["#thissubTemplateType#_Templates"].TemplatesBasePhysicalPath = theTemplatesPhysicalPath />
					<cfif DirectoryExists(theTemplatesPhysicalPath)>
						<cfset tempResult = LoadSubTemplateType(subTemplateMainType="#thissubTemplateMainType#", subTemplateType="#thissubTemplateType#", PhysPath2templates="#theTemplatesPhysicalPath#", URLPath2templates="#theTemplatesBaseURLPath#", SubSiteID="#theSubSiteID#") />
					<cfelse>
						<!--- oops! --->
						<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 1) />
						<cfset ret.error.ErrorText = ret.error.ErrorText & "Oops! The TemplatesPhysicalPath argument was incorrect, the folder does not exist.<br>The path supplied was: #theTemplatesPhysicalPath#" />
					</cfif>
				</cfloop>	<!--- end: loop over template types --->
			</cfloop>	<!--- end: loop over template types --->
		<cfelse>
			<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 2) />
			<cfset ret.error.ErrorText = ret.error.ErrorText & "Oops! Invalid subsiteID supplied to RefreshSubSiteTemplateData(), was: #thisSubSiteID#<br>" />
		</cfif>	<!--- end: good subSite defined test --->
	<cfelse>
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 2) />
		<cfset ret.error.ErrorText = ret.error.ErrorText & "Oops! No subsiteID supplied to RefreshSubSiteTemplateData()<br>" />
	</cfif>	<!--- end: no subSite defined test --->
	<cfcatch type="any">
		<cfset ret.error = TakeErrorCatch(RetErrorStruct=ret.error, CatchStruct=cfcatch) />
	</cfcatch>
	</cftry>
	
	<cfreturn ret />
</cffunction>

<!--- these next three functions are used by init to load up a set of templates and related items ,it is called over and over for each template type: Page templates; Form templates; etc --->
<cffunction name="LoadTemplateType" output="no" returntype="any" access="public" 
	displayname="Load Template Type"
	hint="sets up the internal structures for the specified template type. Loads results into variables scope directly so is more of an include file than a function"
	>
	<cfargument name="TemplateType" type="string" default="" hint="the type of Template to grab">
	<cfargument name="PhysPath2templates" type="string" required="yes" hint="physical path to find templates">
	<cfargument name="URLPath2templates" type="string" required="no" default="" hint="where to find templates, URL-wise. just used to fill struct with final path">
	<cfargument name="SubSiteID" type="string" required="yes" hint="the ID of the subsite to refresh">

	<cfset var theTemplateType = trim(arguments.TemplateType) />
	<cfset var theTemplatesPhysicalPath = trim(arguments.PhysPath2templates) />	<!--- this will be the actual path we are going to scan --->
	<cfset var theURLPath2templates = trim(arguments.URLPath2templates) />
	<cfset var theSubSiteID = trim(arguments.SubSiteID) />
	<cfset var temps = StructNew() />
	<cfset var LoadTemplateSetsArguments = StructNew() />
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorText = "" />
	<cfset ret.error.ErrorContext = "Templatemanagement CFC: LoadTemplateType()" />
	<cfset ret.Data = StructNew() />

	<!--- set up the argumants for the template set loading function --->
	<cfset LoadTemplateSetsArguments.PhysPath2templates = "#theTemplatesPhysicalPath#" />
	<cfset LoadTemplateSetsArguments.URLPath2templates = "#theURLPath2templates#" />
	<!--- default set of filter params, works for most files --->
	<cfset LoadTemplateSetsArguments.Filtermask = "*" />
	<cfset LoadTemplateSetsArguments.ActiveCharsToRemove = 3 />
	<cfset LoadTemplateSetsArguments.InActiveCharsToRemove = 3 />
	<cfif theTemplateType eq "something">
		<cfset LoadTemplateSetsArguments.Filtermask = "*" />
		<cfset LoadTemplateSetsArguments.ActiveCharsToRemove = 3 />
		<cfset LoadTemplateSetsArguments.InActiveCharsToRemove = 3 />
	</cfif>

	<cftry>
		<cfif DirectoryExists(theTemplatesPhysicalPath)>
			<!--- we have a Template path so grab what is in it, clear out old stuff first --->
			<!--- now we have set up the base structure fill it with the templates --->
			<cfset temps = LoadTemplateSets(ArgumentCollection=LoadTemplateSetsArguments) />
	  	<cfif temps.error.errorcode eq 0>
				<cfset variables["SubSite_#theSubSiteID#"]["#theTemplateType#_Templates"].TemplateSets = temps.data />
				<cfset variables["SubSite_#theSubSiteID#"]["#theTemplateType#_Templates"].TemplateSetList = temps.DataMgmnt.TemplateSetList />
				<cfset variables["SubSite_#theSubSiteID#"]["#theTemplateType#_Templates"].TemplateSetCount = temps.DataMgmnt.TemplateSetCount />
	  	</cfif>
		</cfif>
	<cfcatch type="any">
		<cfset ret.error = TakeErrorCatch(RetErrorStruct=ret.error, CatchStruct=cfcatch) />
	</cfcatch>
	</cftry>

	<cfreturn ret />
</cffunction>

<cffunction name="LoadSubTemplateType" output="no" returntype="any" access="public" 
	displayname="Load Template Type"
	hint="sets up the internal structures for the specified template type. Loads results into variables scope directly so is more of an include file than a function"
	>
	<cfargument name="subTemplateMainType" type="string" default="" hint="the main type of subTemplate to grab">
	<cfargument name="subTemplateType" type="string" default="" hint="the type of subTemplate to grab">
	<cfargument name="PhysPath2templates" type="string" required="yes" hint="physical path to find templates">
	<cfargument name="URLPath2templates" type="string" required="yes" hint="where to find templates, URL-wise. just used to fill struct with final path">
	<cfargument name="SubSiteID" type="string" required="yes" hint="the ID of the subsite to refresh">

	<cfset var theSubTemplateMainType = trim(arguments.subTemplateMainType) />
	<cfset var theSubTemplateType = trim(arguments.subTemplateType) />
	<cfset var theTemplatesPhysicalPath = trim(arguments.PhysPath2templates) />	<!--- this will be the actual path we are going to scan --->
	<cfset var theURLPath2templates = trim(arguments.URLPath2templates) />
	<cfset var theSubSiteID = trim(arguments.SubSiteID) />
	<cfset var temps = StructNew() />
	<cfset var LoadTemplateSetsArguments = StructNew() />
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorText = "" />
	<cfset ret.error.ErrorContext = "Templatemanagement CFC: LoadSubTemplateType()" />
	<cfset ret.Data = StructNew() />

	<!--- set up the argumants for the template set loading function --->
	<cfset LoadTemplateSetsArguments.PhysPath2templates = "#theTemplatesPhysicalPath#" />
	<cfset LoadTemplateSetsArguments.URLPath2templates = "#theURLPath2templates#" />
	<!--- default set of filter params, works for most files --->
	<cfset LoadTemplateSetsArguments.Filtermask = "*" />
	<cfset LoadTemplateSetsArguments.ActiveCharsToRemove = 3 />
	<cfset LoadTemplateSetsArguments.InActiveCharsToRemove = 3 />
	<cfif theSubTemplateMainType eq "something">
		<cfset LoadTemplateSetsArguments.Filtermask = "*" />
		<cfset LoadTemplateSetsArguments.ActiveCharsToRemove = 3 />
		<cfset LoadTemplateSetsArguments.InActiveCharsToRemove = 3 />
	<cfelseif theSubTemplateMainType eq "Form">
		<cfset LoadTemplateSetsArguments.theFiltermask = "*-Form" /> 
		<cfset LoadTemplateSetsArguments.theActiveCharsToRemove = 8 />	
		<cfset LoadTemplateSetsArguments.theInActiveCharsToRemove = 8 />
	</cfif>
	<cftry>
		<cfif DirectoryExists(theTemplatesPhysicalPath)>
			<!--- we have a Template path so grab what is in it, clear out old stuff first --->
			<!--- now we have set up the base structure fill it with the templates --->
			<cfset temps = LoadTemplateSets(ArgumentCollection=LoadTemplateSetsArguments) />
	  	<cfif temps.error.errorcode eq 0>
				<cfset variables["SubSite_#theSubSiteID#"]["#theSubTemplateMainType#_Templates"]["#thesubTemplateType#_Templates"].TemplateSets = temps.data />
				<cfset variables["SubSite_#theSubSiteID#"]["#theSubTemplateMainType#_Templates"]["#thesubTemplateType#_Templates"].TemplateSetList = temps.DataMgmnt.TemplateSetList />
				<cfset variables["SubSite_#theSubSiteID#"]["#theSubTemplateMainType#_Templates"]["#thesubTemplateType#_Templates"].TemplateSetCount = temps.DataMgmnt.TemplateSetCount />
	  	</cfif>
		</cfif>
	<cfcatch type="any">
		<cfset ret.error = TakeErrorCatch(RetErrorStruct=ret.error, CatchStruct=cfcatch) />
	</cfcatch>
	</cftry>
  

	<cfreturn ret />
</cffunction>

<cffunction name="LoadTemplateSets" output="no" returntype="any" access="public" 
	displayname="Load Template Sets"
	hint="sets up the internal structures for the specified template type. returns results in structure at template level"
	>
	<cfargument name="PhysPath2templates" type="string" required="yes" hint="where to find templates">
	<cfargument name="URLPath2templates" type="string" required="no" default="" hint="where to find templates, URL-wise. just used to fill struct with final path">
	<cfargument name="Filtermask" type="string" default="*" hint="directory scan filter mask">
	<cfargument name="ActiveCharsToRemove" type="string" default="3" hint="how many trailing chars to remov for the active folders">
	<cfargument name="InActiveCharsToRemove" type="string" default="6" hint="how many trailing chars to remove for inactive sets">

	<cfset var theTemplatePhysicalPath = trim(arguments.PhysPath2templates) />	<!--- this will be the actual path we are going to scan --->
	<cfset var theURLPath2templates = trim(arguments.URLPath2templates) />
	<cfset var theFiltermask = trim(arguments.Filtermask) />  <!--- this is the mask for the directory reads --->
	<cfset var theActiveCharsToRemove = trim(arguments.ActiveCharsToRemove) />	
	<cfset var theInActiveCharsToRemove = trim(arguments.InActiveCharsToRemove) />
	<cfset var qryTemplateDirectories = "" /> <!--- this will have the query result of the page template sets available from above path --->
	<cfset var theWorkingDirectory = "" /> <!--- this will have the path to the template folder we are looking at --->
	<cfset var qryThisTemplateDirectory = "" /> <!--- this will have the query result of the page templates available from above folders --->
	<cfset var temp = "" /> <!--- temp var --->
	<cfset var thisTemplateFolder = "" /> <!--- temp for loops --->
	<cfset var thisPageTemplate = "" /> <!--- temp for loops --->
	<cfset var SubSetLoopCount = "" /> <!--- temp for loops --->
	<cfset var thisSubSet = "" /> <!--- temp for loops --->
	<cfset var thisExtension = "" /> <!--- temp for loops --->
	<cfset var thisTemplateName = "" /> <!--- temp for loops --->
	<cfset var thisTemplateFileName = "" /> <!--- temp for loops --->
	<cfset var thisTemplateExtension = "" /> <!--- temp for loops --->
	<cfset var NavSetPath = '' />
	<cfset var theNavDefFile = '' />
	<cfset var tempPath = '' />
	<cfset var lcntr = '' />
	<cfset var theNavSets = '' />
	<cfset var extlen = 0 /> <!--- temp for loops --->
	<cfset var BackNum = 0 /> <!--- temp for loops --->
	<cfset var tempName = "" /> <!--- temp var --->
	<cfset var theNavDefName = "" /> <!--- temp var for the stripped name of a nav file, ie the navigation name --->
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorText = "" />
	<cfset ret.error.ErrorContext = "Templatemanagement CFC: LoadTemplateSets()" />
	<cfset ret.Data = StructNew() />
	<cfset ret.DataMgmnt = StructNew() />

	<cftry>
		<cfif DirectoryExists(theTemplatePhysicalPath)>
			<cfset ret.DataMgmnt.TemplateSetList = "" />
			<cfset ret.DataMgmnt.TemplateSetCount = 0 />
			<!--- find what sets we have for this type --->
			<cfdirectory action="list" name="qryTemplateDirectories" directory="#theTemplatePhysicalPath#" sort="directory asc" />
			<!--- loop over the folders as each folder represents a set of templates --->
			<cfloop query="qryTemplateDirectories">
				<cfif qryTemplateDirectories.type eq "Dir" and qryTemplateDirectories.Attributes does not contain "H">
					<!--- its a folder and it is not hidden (to skip .svn folders for a start) so it should be a template set --->
					<cfset thisTemplateFolder = qryTemplateDirectories.name />
					<!--- having found a set loop over the various subsets within to find the template, their includes, stylesheets, etc --->
					<!--- first create the variables structure for the whole kit and kaboodle and add to count, list etc --->
					<cfset temp = CreateBlankTemplateSetStructure() />
					<cfif temp.error.ErrorCode eq 0>
						<!--- good creation so copy in the base structures --->
						<!--- create overall stuff --->
						<cfset ret.DataMgmnt.TemplateSetList = ListAppend(ret.DataMgmnt.TemplateSetList, thisTemplateFolder) />
						<cfset ret.DataMgmnt.TemplateSetCount = ret.DataMgmnt.TemplateSetCount+1 />
						<!--- and put in the new structure --->
						<cfset ret.Data["#thisTemplateFolder#"] = StructNew() />
		  			<cfset ret.Data["#thisTemplateFolder#"] = temp.data /> 
						<cfset ret.Data["#thisTemplateFolder#"].TemplatesPhysicalPath = theTemplatePhysicalPath & thisTemplateFolder & "/" />
						<cfset ret.Data["#thisTemplateFolder#"].TemplatesRelURLPath = theURLPath2templates & thisTemplateFolder & "/" />
						<!--- now loop over the subSet of template and parts, styling, etc. --->
						<cfloop from="1" to="#variables.TemplateParts.PartCount#" index="SubSetLoopCount">
							<cfset thisSubSet = ListGetAt(variables.TemplateParts.PartList, SubSetLoopCount)>
							<cfset thisExtension = ListGetAt(variables.TemplateParts.ExtensionList, SubSetLoopCount)>
							<!--- ToDo: have a proper pickup of extensions --->
							<cfif thisExtension eq "gfix" or thisExtension eq "cntrl">
								<cfset thisExtension = "*" />
							</cfif>
							<!--- all OK so grab the files in this folder and process according to type (the extension being used to work out what is what) --->
							<cfset theWorkingDirectory = '#ret.Data["#thisTemplateFolder#"].TemplatesPhysicalPath##variables.paths.PartsPaths["#thisSubSet#RelPath"]#' />
							<cfdirectory action="list" name="qryThisTemplateDirectory" directory="#theWorkingDirectory#" filter="#theFiltermask#.#thisExtension#" sort="file asc" />
							<!--- *.cfm files are working templates or includes, *.ini are navigation control, the rest follow their subset type, css etc --->
							<cfloop query="qryThisTemplateDirectory">
								<cfif qryThisTemplateDirectory.type eq "File" and qryThisTemplateDirectory.Attributes does not contain "H">
									<cfset thisTemplateFileName = qryThisTemplateDirectory.name />
									<cfset thisTemplateName = removeChars(thisTemplateFileName, len(thisTemplateFileName)-theActiveCharsToRemove, theActiveCharsToRemove+1) />
									<cfset ret.Data["#thisTemplateFolder#"]["#thisSubSet#"].Active.ItemList = ListAppend(ret.Data["#thisTemplateFolder#"]["#thisSubSet#"].Active.ItemList, thisTemplateName) />
									<cfset ret.Data["#thisTemplateFolder#"]["#thisSubSet#"].Active.ItemCount = IncrementValue(ret.Data["#thisTemplateFolder#"]["#thisSubSet#"].Active.ItemCount) />
									<cfset ret.Data["#thisTemplateFolder#"]["#thisSubSet#"].Active.Items["#thisTemplateName#"] = StructNew() />
									<cfset ret.Data["#thisTemplateFolder#"]["#thisSubSet#"].Active.Items["#thisTemplateName#"].FileName = thisTemplateFileName />
									<cfset ret.Data["#thisTemplateFolder#"]["#thisSubSet#"].Active.Items["#thisTemplateName#"].ItemName = thisTemplateName />
									<cfset ret.Data["#thisTemplateFolder#"]["#thisSubSet#"].Active.Items["#thisTemplateName#"].BackupCount = 0 />
									<cfset ret.Data["#thisTemplateFolder#"]["#thisSubSet#"].Active.Items["#thisTemplateName#"].BackupExtensionList = "" />
									<cfset ret.Data["#thisTemplateFolder#"]["#thisSubSet#"].Active.Items["#thisTemplateName#"].BackupExtensionNextNumber = 1 />
									<!--- now we have the base data we check to see if we are in the navigation bit and if so we read the nav ini files --->
									<cfif thisSubSet eq "NavigationControl" and thisTemplateName neq "NavigationDefinition_Blank">
										<cfset theNavDefName = left(thisTemplateName, len(thisTemplateName)-21) />	<!--- strip off the "_NavigationDefinition" bit of a proper nav filename --->
										<cfset ret.Data["#thisTemplateFolder#"]["#thisSubSet#"].ActiveNavStyling["#theNavDefName#"] = application.SLCMS.mbc_Utility.iniTools.ini2Struct(FilePath="#theWorkingDirectory##thisTemplateFileName#", TrimWhiteSpace="Partial").data />
									</cfif>
								</cfif>
							</cfloop>
							<!--- now we have the Active Templates lets see how many of them are backed up --->
							<cfdirectory action="list" name="qryThisTemplateDirectory" directory="#theWorkingDirectory#" filter="#theFiltermask#.bak*" sort="file asc" />
							<cfloop query="qryThisTemplateDirectory">
								<cfif qryThisTemplateDirectory.type eq "File" and qryThisTemplateDirectory.Attributes does not contain "H">
									<cfset thisTemplateFileName = qryThisTemplateDirectory.name />
									<cfset thisTemplateExtension = ListLast(thisTemplateFileName,".") /> <!--- the length of the extension as it can vary with these backup files --->
									<cfset ExtLen = len(thisTemplateExtension) /> <!--- the length of the extension as it can vary with these backup files --->
									<cfset thisTemplateName = removeChars(thisTemplateFileName, len(thisTemplateFileName)-ExtLen, ExtLen+1) />
									<cfset BackNum = removeChars(thisTemplateExtension,1,3) />
									<cfif BackNum eq "">
										<cfset BackNum = 0 />
									</cfif>
									<!--- check to see if it exists as an Active or Inactive template --->
									<cfif StructKeyExists(ret.Data["#thisTemplateFolder#"]["#thisSubSet#"].Active.Items, "#thisTemplateName#")>
										<cfset ret.Data["#thisTemplateFolder#"]["#thisSubSet#"].Active.Items["#thisTemplateName#"].BackupExtensionList = ListAppend(ret.Data["#thisTemplateFolder#"]["#thisSubSet#"].Active.Items["#thisTemplateName#"].BackupExtensionList, thisTemplateExtension) />
										<cfset ret.Data["#thisTemplateFolder#"]["#thisSubSet#"].Active.Items["#thisTemplateName#"].BackupCount = IncrementValue(ret.Data["#thisTemplateFolder#"]["#thisSubSet#"].Active.Items["#thisTemplateName#"].BackupCount) />
										<cfif ret.Data["#thisTemplateFolder#"]["#thisSubSet#"].Active.Items["#thisTemplateName#"].BackupExtensionNextNumber lt BackNum+1>
											<cfset ret.Data["#thisTemplateFolder#"]["#thisSubSet#"].Active.Items["#thisTemplateName#"].BackupExtensionNextNumber = BackNum+1 />
										</cfif>
									<cfelse>
										<!--- it doesn't so its an orphan so save that independently --->
										<cfset ret.Data["#thisTemplateFolder#"]["#thisSubSet#"].Orphans.ItemList = ListAppend(ret.Data["#thisTemplateFolder#"]["#thisSubSet#"].Orphans.ItemList, thisTemplateName) />
										<cfset ret.Data["#thisTemplateFolder#"]["#thisSubSet#"].Orphans.ItemCount = IncrementValue(ret.Data["#thisTemplateFolder#"]["#thisSubSet#"].Orphans.ItemCount) />
										<cfset ret.Data["#thisTemplateFolder#"]["#thisSubSet#"].Orphans.Items["#thisTemplateName#"] = StructNew() />
										<cfset ret.Data["#thisTemplateFolder#"]["#thisSubSet#"].Orphans.Items["#thisTemplateName#"].BackupCount = 0 />
										<cfset ret.Data["#thisTemplateFolder#"]["#thisSubSet#"].Orphans.Items["#thisTemplateName#"].BackupExtensionList = "" />
										<cfset ret.Data["#thisTemplateFolder#"]["#thisSubSet#"].Orphans.Items["#thisTemplateName#"].BackupExtensionNextNumber = 0 />
										<cfset ret.Data["#thisTemplateFolder#"]["#thisSubSet#"].Orphans.Items["#thisTemplateName#"].FileName = thisTemplateFileName />
										<cfset ret.Data["#thisTemplateFolder#"]["#thisSubSet#"].Orphans.Items["#thisTemplateName#"].ItemName = thisTemplateName />
									</cfif>
								</cfif>
							</cfloop>	<!--- end: active backup loop --->
							<!--- now we step down to the Inactive templates sitting in their own folder --->
							<cfset theWorkingDirectory = "#theTemplatePhysicalPath##thisTemplateFolder#/#variables.paths.PartsPaths['#thisSubSet#RelPath']#Inactive/" />
							<cfdirectory action="list" name="qryThisTemplateDirectory" directory="#theWorkingDirectory#" filter="#theFiltermask#.#thisExtension#" sort="file asc" />
							<!--- these are ones marked as inactive --->
							<cfloop query="qryThisTemplateDirectory">
								<cfif qryThisTemplateDirectory.type eq "File" and qryThisTemplateDirectory.Attributes does not contain "H">
									<cfset thisTemplateFileName = qryThisTemplateDirectory.name />
									<cfset thisTemplateName = removeChars(thisTemplateFileName, len(thisTemplateFileName)-theInActiveCharsToRemove, theInActiveCharsToRemove+1) />
									<cfset ret.Data["#thisTemplateFolder#"]["#thisSubSet#"].Inactive.ItemList = ListAppend(ret.Data["#thisTemplateFolder#"]["#thisSubSet#"].Inactive.ItemList, thisTemplateName) />
									<cfset ret.Data["#thisTemplateFolder#"]["#thisSubSet#"].Inactive.ItemCount = IncrementValue(ret.Data["#thisTemplateFolder#"]["#thisSubSet#"].Inactive.ItemCount) />
									<cfset ret.Data["#thisTemplateFolder#"]["#thisSubSet#"].Inactive.Items["#thisTemplateName#"] = StructNew() />
									<cfset ret.Data["#thisTemplateFolder#"]["#thisSubSet#"].Inactive.Items["#thisTemplateName#"].FileName = thisTemplateFileName />
									<cfset ret.Data["#thisTemplateFolder#"]["#thisSubSet#"].Inactive.Items["#thisTemplateName#"].ItemName = thisTemplateName />
									<cfset ret.Data["#thisTemplateFolder#"]["#thisSubSet#"].Inactive.Items["#thisTemplateName#"].BackupCount = 0 />
									<cfset ret.Data["#thisTemplateFolder#"]["#thisSubSet#"].Inactive.Items["#thisTemplateName#"].BackupExtensionList = "" />
									<cfset ret.Data["#thisTemplateFolder#"]["#thisSubSet#"].Inactive.Items["#thisTemplateName#"].BackupExtensionNextNumber = 1 />
								</cfif>
							</cfloop>
							<!--- now we have the Inactive Templates lets see how many of them are backed up --->
							<cfdirectory action="list" name="qryThisTemplateDirectory" directory="#theWorkingDirectory#" filter="#theFiltermask#.bak*" sort="file asc" />
							<cfloop query="qryThisTemplateDirectory">
								<cfif qryThisTemplateDirectory.type eq "File" and qryThisTemplateDirectory.Attributes does not contain "H">
									<cfset thisTemplateFileName = qryThisTemplateDirectory.name />
									<cfset thisTemplateExtension = ListLast(thisTemplateFileName,".") /> <!--- the length of the extension as it can vary with these backup files --->
									<cfset ExtLen = len(thisTemplateExtension) /> <!--- the length of the extension as it can vary with these backup files --->
									<cfset thisTemplateName = removeChars(thisTemplateFileName, len(thisTemplateFileName)-ExtLen, ExtLen+1) />
									<cfset BackNum = removeChars(thisTemplateExtension,1,3) />
									<cfif BackNum eq "">
										<cfset BackNum = 0 />
									</cfif>
									<!--- check to see if it exists as an Active or Inactive template --->
									<cfif StructKeyExists(ret.Data["#thisTemplateFolder#"]["#thisSubSet#"].Inactive.Items, "#thisTemplateName#")>
					  				<cfset ret.Data["#thisTemplateFolder#"]["#thisSubSet#"].Inactive.Items["#thisTemplateName#"].BackupExtensionList = ListAppend(ret.Data["#thisTemplateFolder#"]["#thisSubSet#"].Inactive.Items["#thisTemplateName#"].BackupExtensionList, thisTemplateExtension) />
										<cfset ret.Data["#thisTemplateFolder#"]["#thisSubSet#"].Inactive.Items["#thisTemplateName#"].BackupCount = IncrementValue(ret.Data["#thisTemplateFolder#"]["#thisSubSet#"].Inactive.Items["#thisTemplateName#"].BackupCount) />
										<cfif ret.Data["#thisTemplateFolder#"]["#thisSubSet#"].Inactive.Items["#thisTemplateName#"].BackupExtensionNextNumber lt BackNum+1>
											<cfset ret.Data["#thisTemplateFolder#"]["#thisSubSet#"].Inactive.Items["#thisTemplateName#"].BackupExtensionNextNumber = BackNum+1 />
										</cfif>
									<cfelse>
										<!--- it doesn't so its an orphan so save that independently --->
										<cfset ret.Data["#thisTemplateFolder#"]["#thisSubSet#"].Orphans.ItemList = ListAppend(ret.Data["#thisTemplateFolder#"]["#thisSubSet#"].Orphans.ItemList, thisTemplateName) />
										<cfset ret.Data["#thisTemplateFolder#"]["#thisSubSet#"].Orphans.ItemCount = IncrementValue(ret.Data ["#thisTemplateFolder#"]["#thisSubSet#"].Orphans.ItemCount) />
										<cfset ret.Data["#thisTemplateFolder#"]["#thisSubSet#"].Orphans.Items["#thisTemplateName#"] = StructNew() />
										<cfset ret.Data["#thisTemplateFolder#"]["#thisSubSet#"].Orphans.Items["#thisTemplateName#"].BackupCount = 0 />
										<cfset ret.Data["#thisTemplateFolder#"]["#thisSubSet#"].Orphans.Items["#thisTemplateName#"].BackupExtensionList = "" />
										<cfset ret.Data["#thisTemplateFolder#"]["#thisSubSet#"].Orphans.Items["#thisTemplateName#"].BackupExtensionNextNumber = 0 />
										<cfset ret.Data["#thisTemplateFolder#"]["#thisSubSet#"].Orphans.Items["#thisTemplateName#"].FileName = thisTemplateFileName />
										<cfset ret.Data["#thisTemplateFolder#"]["#thisSubSet#"].Orphans.Items["#thisTemplateName#"].ItemName = thisTemplateName />
									</cfif>
								</cfif>
							</cfloop>	<!--- end: inactive backup loop --->
						</cfloop>	<!--- end: subset loop --->
					<cfelse>
						<!--- structure creation failed --->
						<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 2) />
						<cfset ret.error.ErrorText = ret.error.ErrorText & temp.error.ErrorText />
					</cfif>
				</cfif>
			</cfloop>
		<cfelse>
			<!--- oops! --->
			<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 1) />
			<cfset ret.error.ErrorText = ret.error.ErrorText & "Oops! The FormsPhysicalPath argument was incorrect, the folder does not exist.<br>The path supplied was: #theTemplatePhysicalPath#." />
			<cflog text='#ret.error.ErrorContext# #ret.error.ErrorText# - ret.error.ErrorCode: #ret.error.ErrorCode# - Time: #DateFormat(Now(),"YYYYMMDD")#-#TimeFormat(now(),"HH:mm:ss")#'  file="#Application.Logging.theSiteLogName#" type="Error" application = "yes">
		</cfif>
	<cfcatch type="any">
		<cfset ret.error = TakeErrorCatch(RetErrorStruct=ret.error, CatchStruct=cfcatch) />
	</cfcatch>
	</cftry>
	
	<cfreturn ret />
</cffunction>

<cffunction name="getTemplateTypeDataStruct" output="no" returntype="struct" access="public"
	displayname="get a Template Type Data"
	hint="returns the full data Structure for the specified type, no error handling"
				>
	<cfargument name="TemplateType" type="string" required="yes">	<!--- the type of Template to grab --->
	<cfargument name="SubSiteID" type="string" required="yes" hint="the ID of the subsite to use">

	<cfset var theTemplateType = trim(arguments.TemplateType) />
	<cfset var theSubSiteID = trim(arguments.SubSiteID) />
	<cfset var ret = StructNew() />
	
	<cfif StructKeyExists(variables["SubSite_#theSubSiteID#"], "#theTemplateType#_Templates")>
		<cfreturn variables["SubSite_#theSubSiteID#"]["#theTemplateType#_Templates"] />
	<cfelse>
		<cfreturn ret />
	</cfif>
</cffunction>

<cffunction name="getTemplateList" output="no" returntype="string" access="public"
	displayname="get list of templates"
	hint="returns the list of templates for the specified type, including the set name, no error handling"
				>
	<cfargument name="TemplateType" type="string" required="yes">	<!--- the type of Template to grab --->
	<cfargument name="SubSiteID" type="string" required="yes" hint="the ID of the subsite to use">

	<cfset var theTemplateType = trim(arguments.TemplateType) />
	<cfset var theSubSiteID = trim(arguments.SubSiteID) />
	<cfset var thisSet = "" />
	<cfset var thisSetList = "" />
	<cfset var thisTemplate = "" />
	<cfset var ret = "" />
	
	<cfif StructKeyExists(variables["SubSite_#theSubSiteID#"], "#theTemplateType#_Templates") and StructKeyExists(variables["SubSite_#theSubSiteID#"]["#theTemplateType#_Templates"], "TemplateSetList")>
		<cfloop list="#variables["SubSite_#theSubSiteID#"]['#theTemplateType#_Templates'].TemplateSetList#" index="thisSet">
			<cfset thisSetList = variables["SubSite_#theSubSiteID#"]['#theTemplateType#_Templates'].TemplateSets["#thisSet#"].Templates.Active.ItemList &"," />
			<cfloop list="#thisSetList#" index="thisTemplate">
				<cfset ret = ListAppend(ret, "#thisSet#/#thisTemplate#") />	<!--- make up a list --->
			</cfloop>
		</cfloop>
	<cfelse>
	</cfif>
	
	<cfreturn ret />
</cffunction>

<cffunction name="getTemplateTypeList" output="no" returntype="string" access="public"
						displayname="get Template Type List"
						hint="returns list of the template types available"
						>
	
	<cfreturn variables.Lists.CoreTemplateTypeList  />
</cffunction>

<cffunction name="getTemplateSubsetTypeList" output="no" returntype="string" access="public"
						displayname="get Template Subset Type List"
						hint="returns list of the sub sets of template sets. Templates, TemplateIncludes, Stylesheets, etc"
						>	
	<cfreturn variables.TemplateParts.PartList  />
</cffunction>

<cffunction name="getTemplatesBasePhysicalPath" output="no" returntype="string" access="public"
						displayname="get Templates Base Physical Path"
						hint="returns Physical Path to the folder carrying all template sets or null for an error"
						>
	<cfargument name="TemplateType" type="string" default="Page" hint="the type of the template set: Page, Sub, etc" />
	<cfargument name="SubSiteID" type="string" required="yes" hint="the ID of the subsite to use">

	<cfset var theTemplateType = trim(arguments.TemplateType) />
	<cfset var theSubSiteID = trim(arguments.SubSiteID) />
	<cfset var theSetPath = "" />
	
	<cfif StructkeyExists(variables["SubSite_#theSubSiteID#"], "#theTemplateType#_Templates")>
		<cfset theSetPath = variables["SubSite_#theSubSiteID#"]["#theTemplateType#_Templates"].TemplatesBasePhysicalPath />
	</cfif>
	<cfreturn theSetPath />
</cffunction>

<cffunction name="getTemplateSetPhysicalPath" output="no" returntype="string" access="public"
						displayname="get Template Set Physical Path"
						hint="returns Physical Path to the folder of a template set or null for an error"
						>
	<cfargument name="Subset" type="string" default="Templates" />	<!--- the name of the subset it is in, templates, stylesheets, whatever --->
	<cfargument name="TemplateSet" type="string" default="" required="true" hint="the name of the template set" />
	<cfargument name="TemplateType" type="string" default="Page" hint="the type of the template set: Page, etc" />
	<cfargument name="SubSiteID" type="string" required="yes" hint="the ID of the subsite to use">

	<cfset var theSubset = trim(arguments.Subset) />
	<cfset var theTemplateSet = trim(arguments.TemplateSet) />
	<cfset var theTemplateType = trim(arguments.TemplateType) />
	<cfset var theSubSiteID = trim(arguments.SubSiteID) />
	<cfset var theSetPath = "" />
	
	<cfif ListFindNoCase(variables.Lists.CoreTemplateTypeList, theTemplateType) and ListFindNoCase(variables.TemplateParts.PartList, theSubset)>
		<cfset theSetPath = getTemplateSetURLPath(ArgumentCollection=arguments) />
		<cfif theSetPath neq "">
			<cfset theSetPath = variables.Paths.WebsiteBasePhysicalPath & theSetPath />
		</cfif>
	</cfif>
	<cfreturn theSetPath />
</cffunction>

<cffunction name="getTemplateSetURLPath" output="no" returntype="string" access="public"
	displayname="get Template Set URL Path"
	hint="returns URL Path to the folder of a template set or null for an error"
				>
	<cfargument name="Subset" type="string" default="Templates" hint="the name of the subset it is in, templates, stylesheets, whatever" />
	<cfargument name="TemplateSet" type="string" default="" required="true" hint="the name of the template set" />
	<cfargument name="TemplateType" type="string" default="Page" hint="the type of the template set: Page, etc" />
	<cfargument name="SubSiteID" type="string" required="yes" hint="the ID of the subsite to use">

	<cfset var theSubset = trim(arguments.Subset) />
	<cfset var theTemplateSet = trim(arguments.TemplateSet) />
	<cfset var theTemplateType = trim(arguments.TemplateType) />
	<cfset var theSubSiteID = trim(arguments.SubSiteID) />
	<cfset var theSetPath = "" />
	
	<!--- do a mega check for goodness as this can indirectly come from template where someone has typo'd a name --->
	<cfif theTemplateType neq "Sub" and ListFindNoCase(variables.Lists.CoreTemplateTypeList, theTemplateType) and ListFindNoCase(variables.TemplateParts.PartList, theSubset) and ListFind(variables.SubSiteControl.ActiveSubSiteIDList, theSubSiteID)>
		<!--- we do a double lookup as the template might not exist in the template set or subSite, it could be a shared template --->
		<cfif ListFindNoCase(variables["SubSite_#theSubSiteID#"]["#theTemplateType#_Templates"].TemplateSetList, "#theTemplateSet#")>
			<cfset theSetPath = '#variables["SubSite_#theSubSiteID#"].BaseRelURLpath##theTemplateType#Templates/#theTemplateSet#/#variables.paths.PartsPaths["#theSubSet#RelPath"]#' />
		</cfif>
		<cfif theSetPath eq "" and StructkeyExists(variables["SubSite_Shared"]["#theTemplateType#_Templates"].TemplateSets, "#theTemplateSet#")>
			<cfset theSetPath = '#variables["SubSite_Shared"].BaseRelURLpath##theTemplateType#Templates/#theTemplateSet#/#variables.paths.PartsPaths["#theSubSet#RelPath"]#' />
		</cfif>
	</cfif>

	<cfreturn theSetPath />
</cffunction>

<cffunction name="getSubTemplateSetPhysicalPath" output="no" returntype="string" access="public"
						displayname="get subTemplate Set Physical Path"
						hint="returns Physical Path to the folder of a subTemplate set or null for an error"
						>
	<cfargument name="Subset" type="string" default="Templates" hint="the name of the subset it is in, templates, stylesheets, whatever" />
	<cfargument name="TemplateSet" type="string" default="" required="true" hint="the name of the individual template set" />
	<cfargument name="TemplateType" type="string" default="" hint="the type of the template set: Page, etc" />
	<cfargument name="TemplateSubType" type="string" default="" hint="the subtype of the template set: often a set of templates" />
	<cfargument name="TemplateSubTypeFallBack" type="string" default="" hint="the subtype of the template set to fall back to if not found in subType: CoreForm, CoreTag, etc" />
	<cfargument name="SubSiteID" type="string" required="yes" hint="the ID of the subsite to use">

	<cfset var theSubset = trim(arguments.Subset) />
	<cfset var theTemplateSet = trim(arguments.TemplateSet) />
	<cfset var theTemplateType = trim(arguments.TemplateType) />
	<cfset var theTemplateSubType = trim(arguments.TemplateSubType) />
	<cfset var theTemplateSubTypeFallBack = trim(arguments.TemplateSubTypeFallBack) />
	<cfset var theSubSiteID = trim(arguments.SubSiteID) />
	<cfset var theSetPath = "" />

	<cftry>
		<!--- do a mega check for goodness as this can indirectly come from template where someone has typo'd a name --->
		<cfif ListFindNoCase(variables.Lists.SubTemplateMainTypeList, theTemplateType) and ListFindNoCase(variables.TemplateParts.PartList, theSubset) and ListFind(variables.SubSiteControl.ActiveSubSiteIDList, theSubSiteID)>
			<!--- we do a quadruple lookup as the subTemplate might not exist in the subSite Template set but it could be a shared subTemplate or even nowhere except the base core --->
			<cfif variables["SubSite_#theSubSiteID#"]["#theTemplateType#_Templates"].HasTemplateSets and StructkeyExists(variables["SubSite_#theSubSiteID#"]["#theTemplateType#_Templates"], "#TemplateSubType#_Templates")>
				<cfset theSetPath = variables["SubSite_#theSubSiteID#"]["#theTemplateType#_Templates"]["#TemplateSubType#_Templates"].TemplateSets["#theTemplateSet#"].TemplatesPhysicalPath />
			</cfif>
			<cfif theSetPath eq "" and variables["SubSite_#theSubSiteID#"]["#theTemplateType#_Templates"].HasTemplateSets and StructkeyExists(variables["SubSite_#theSubSiteID#"]["#theTemplateType#_Templates"], "#TemplateSubType#_Templates")>
				<cfset theSetPath = variables["SubSite_#theSubSiteID#"]["#theTemplateType#_Templates"]["#theTemplateSubTypeFallBack#_Templates"].TemplateSets["#theTemplateSet#"].TemplatesPhysicalPath />
			</cfif>
			<!--- not in the subSite so try the shared templates --->
			<cfif theSetPath eq "" and variables["SubSite_Shared"]["#theTemplateType#_Templates"].HasTemplateSets and StructkeyExists(variables["SubSite_Shared"]["#theTemplateType#_Templates"], "#TemplateSubType#_Templates")>
				<cfset theSetPath = variables["SubSite_Shared"]["#theTemplateType#_Templates"]["#TemplateSubType#_Templates"].TemplateSets["#theTemplateSet#"].TemplatesPhysicalPath />
			</cfif>
			<!--- not there either so revert to the core --->
			<cfif theSetPath eq "" and StructkeyExists(variables["SubSite_Shared"]["#theTemplateType#_Templates"], "#theTemplateSubTypeFallBack#_Templates")>
				<cfset theSetPath = variables["SubSite_Shared"]["#theTemplateType#_Templates"]["#theTemplateSubTypeFallBack#_Templates"].TemplateSets["#theTemplateSet#"].TemplatesPhysicalPath />
			</cfif>
		</cfif>
	<cfcatch></cfcatch>	<!--- just return a null if we asked for something ridiculous --->
	</cftry>

	<cfreturn theSetPath />
</cffunction>

<cffunction name="getSubTemplateSetURLPath" output="yes" returntype="string" access="public"
	displayname="get Template Set URL Path"
	hint="returns URL Path to the folder of a subTemplate set or null for an error"
				>
	<cfargument name="Subset" type="string" default="Templates" hint="the name of the subset it is in, templates, stylesheets, whatever" />
	<cfargument name="TemplateSet" type="string" default="" required="true" hint="the name of the individual template set" />
	<cfargument name="TemplateType" type="string" default="" hint="the type of the template set: Page, etc" />
	<cfargument name="TemplateSubType" type="string" default="" hint="the subtype of the template set: often a set of templates" />
	<cfargument name="TemplateSubTypeFallBack" type="string" default="" hint="the subtype of the template set to fall back to if not found in subType: CoreForm, CoreTag, etc" />
	<cfargument name="SubSiteID" type="string" required="yes" hint="the ID of the subsite to use">

	<cfset var theSubset = trim(arguments.Subset) />
	<cfset var theTemplateSet = trim(arguments.TemplateSet) />
	<cfset var theTemplateType = trim(arguments.TemplateType) />
	<cfset var theTemplateSubType = trim(arguments.TemplateSubType) />
	<cfset var theTemplateSubTypeFallBack = trim(arguments.TemplateSubTypeFallBack) />
	<cfset var theSubSiteID = trim(arguments.SubSiteID) />
	<cfset var theSetPath = "" />

	<cftry>
		<!--- do a mega check for goodness as this can indirectly come from template where someone has typo'd a name --->
		<cfif ListFindNoCase(variables.Lists.SubTemplateMainTypeList, theTemplateType) and ListFindNoCase(variables.TemplateParts.PartList, theSubset) and ListFind(variables.SubSiteControl.ActiveSubSiteIDList, theSubSiteID)>
			<!--- we do a quadruple lookup as the subTemplate might not exist in the subSite Template set but it could be a shared subTemplate or even nowhere except the base core --->
			<cfif variables["SubSite_#theSubSiteID#"]["#theTemplateType#_Templates"].HasTemplateSets and StructkeyExists(variables["SubSite_#theSubSiteID#"]["#theTemplateType#_Templates"], "#TemplateSubType#_Templates")>
				<cfset theSetPath = variables["SubSite_#theSubSiteID#"]["#theTemplateType#_Templates"]["#TemplateSubType#_Templates"].TemplateSets["#theTemplateSet#"].TemplatesRelURLPath />
			</cfif>
			<cfif theSetPath eq "" and variables["SubSite_#theSubSiteID#"]["#theTemplateType#_Templates"].HasTemplateSets and StructkeyExists(variables["SubSite_#theSubSiteID#"]["#theTemplateType#_Templates"], "#TemplateSubType#_Templates")>
				<cfset theSetPath = variables["SubSite_#theSubSiteID#"]["#theTemplateType#_Templates"]["#theTemplateSubTypeFallBack#_Templates"].TemplateSets["#theTemplateSet#"].TemplatesRelURLPath />
			</cfif>
			<!--- not in the subSite so try the shared templates --->
			<cfif theSetPath eq "" and variables["SubSite_Shared"]["#theTemplateType#_Templates"].HasTemplateSets and StructkeyExists(variables["SubSite_Shared"]["#theTemplateType#_Templates"], "#TemplateSubType#_Templates")>
				<cfset theSetPath = variables["SubSite_Shared"]["#theTemplateType#_Templates"]["#TemplateSubType#_Templates"].TemplateSets["#theTemplateSet#"].TemplatesRelURLPath />
			</cfif>
			<!--- not there either so revert to the core --->
			<cfif theSetPath eq "" and StructkeyExists(variables["SubSite_Shared"]["#theTemplateType#_Templates"], "#theTemplateSubTypeFallBack#_Templates")>
				<cfset theSetPath = variables["SubSite_Shared"]["#theTemplateType#_Templates"]["#theTemplateSubTypeFallBack#_Templates"].TemplateSets["#theTemplateSet#"].TemplatesRelURLPath />
			</cfif>
		</cfif>
	<cfcatch></cfcatch>	<!--- just return a null if we asked for something ridiculous --->
	</cftry>
<!---	
	
	<cfargument name="Subset" type="string" default="Templates" hint="the name of the subset it is in, templates, stylesheets, whatever" />
	<cfargument name="TemplateSet" type="string" default="" required="true" hint="the name of the template set" />
	<cfargument name="TemplateType" type="string" default="" hint="the type of the template set: Form, Tag, etc" />
	<cfargument name="TemplateSubType" type="string" default="" hint="the subtype of the template set: CoreForm, CoreTag, etc" />
	<cfargument name="SubSiteID" type="string" required="yes" hint="the ID of the subsite to use">

	<cfset var theSubset = trim(arguments.Subset) />
	<cfset var theTemplateSet = trim(arguments.TemplateSet) />
	<cfset var theTemplateType = trim(arguments.TemplateType) />
	<cfset var theTemplateSubType = trim(arguments.TemplateSubType) />
	<cfset var theSubSiteID = trim(arguments.SubSiteID) />
	<cfset var theSetPath = "" />

	<!--- do a mega check for goodness as this can indirectly come from template where someone has typo'd a name --->
	<cfif ListFindNoCase(variables.Lists.SubTemplateMainTypeList, theTemplateType) and ListFindNoCase(variables.TemplateParts.PartList, theSubset) and ListFind(variables.SubSiteControl.ActiveSubSiteIDList, theSubSiteID)>
		<!--- we do a double lookup as the subTemplate might not exist in the subTemplate set or subSite, it could be a shared subTemplate --->
		<cfif variables["SubSite_#theSubSiteID#"]["#theTemplateType#_Templates"].HasTemplateSets and ListFindNoCase(variables["SubSite_#theSubSiteID#"]["#theTemplateType#_Templates"], "#theTemplateSet#_Templates")>
			<cfset theSetPath = variables["SubSite_#theSubSiteID#"]["#theTemplateType#_Templates"]["#theTemplateSet#_Templates"].TemplatesBaseURLPath />
		</cfif>
		<!--- not in the subSite so try the shared templates --->
		<cfif theSetPath eq "" and variables["SubSite_Shared"]["#theTemplateType#_Templates"].HasTemplateSets and StructkeyExists(variables["SubSite_Shared"]["#theTemplateType#_Templates"], "#theTemplateSet#_Templates")>
			<cfset theSetPath = variables["SubSite_Shared"]["#theTemplateType#_Templates"]["#theTemplateSet#_Templates"].TemplatesBaseURLPath />
		</cfif>
		<!--- not there either so revert to the core --->
		<cfif theSetPath eq "" and StructkeyExists(variables["SubSite_Shared"]["#theTemplateType#_Templates"], "#theTemplateSubType#_Templates")>
			<cfset theSetPath = variables["SubSite_Shared"]["#theTemplateType#_Templates"]["#theTemplateSubType#_Templates"].TemplatesBaseURLPath />
		</cfif>
	</cfif>
--->
	<cfreturn theSetPath />
</cffunction>

<cffunction name="getNavigationStyling_All" output="no" returntype="struct" access="public"
	displayname="get Navigation Styling All"
	hint="returns navigation styling structure for specified template set or null for an error"
				>
	<cfargument name="TemplateSet" type="string" default="" required="true" hint="the name of the template set" />
	<cfargument name="SubSiteID" type="string" required="yes" hint="the ID of the subsite to use">

	<cfset var theTemplateSet = trim(arguments.TemplateSet) />
	<cfset var theSubSiteID = trim(arguments.SubSiteID) />
	<cfset var temp = "" />	<!--- temp/throwaway var --->
	<cfset var ret = StructNew() />	<!--- returned structure --->
	
	<cftry>
		<cfif StructkeyExists(variables["SubSite_#theSubSiteID#"].Page_Templates.TemplateSets, "#theTemplateSet#")>
			<cfset ret = variables["SubSite_#theSubSiteID#"].Page_Templates.TemplateSets["#theTemplateSet#"].NavigationControl.ActiveNavStyling />	<!--- return the nav styling structure --->
		</cfif>
	<cfcatch><cfset ret.bad = "bad"><cfset ret.theSubSiteID = theSubSiteID><cfset ret.theTemplateSet = theTemplateSet></cfcatch>
	</cftry>
	<cfreturn ret />
</cffunction>

<cffunction name="CreateTemplateSet" output="no" returntype="struct" access="public"
	displayname="Create Template Set"
	hint="Creates placeholders and a new folder structure to put a set of templates in"
				>
	<!--- this function needs.... --->
	<cfargument name="SetName" type="string" default="" required="true" hint="the name of the template set" />
	<cfargument name="TemplateType" type="string" default="Page" hint="the type of the template set: Page, Form, Data, etc" />
	<cfargument name="SubSiteID" type="string" required="yes" hint="the ID of the subsite to put the set in">

	<!--- now all of the var declarations, first the arguments which need manipulation --->
	<cfset var theSetName = trim(arguments.SetName) />
	<cfset var theTemplateType = trim(arguments.TemplateType) />
	<cfset var theSubSiteID = trim(arguments.SubSiteID) />
	<!--- now vars that will get filled as we go --->
	<cfset var thePath = "" />	<!--- temp/throwaway var --->
	<cfset var temp = "" />	<!--- temp/throwaway var --->
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorText = "" />
	<cfset ret.error.ErrorContext = "Templatemanagement CFC: CreateTemplateSet()" />
	<cfset ret.Data = "" />

	<cfif len(theSetName)>
		<!--- do some checks to make sure we don't already exist --->
		<cfset thePath = variables["SubSite_#theSubSiteID#"]["#theTemplateType#_Templates"].TemplatesPhysicalPath & theSetName />
		<cfif not (StructkeyExists(variables["SubSite_#theSubSiteID#"]["#theTemplateType#_Templates"], "#theSetName#") or DirectoryExists("#thePath#"))>
			<!--- we have params and nothing there so lets create a folder and new structs as needed --->
			<!--- wrap the whole thing in a try/catch in case something breaks --->
			<cftry>
				<!--- first the variables structure --->
				<cfset temp = CreateBlankTemplateSetStructure(SetName="#theSetName#", TemplateType="#theTemplateType#", SubSiteID="#theSubSiteID#") />
				<cfif temp.error.ErrorCode eq 0>
					<!--- all OK so then the physical folders --->
					<cfdirectory action="create" directory="#thePath#">
					<cfdirectory action="create" directory="#thePath#/Inactive">
					<cfdirectory action="create" directory="#thePath#/TemplateGraphics">
					<cfdirectory action="create" directory="#thePath#/TemplateGraphics/Inactive">
					<cfdirectory action="create" directory="#thePath#/TemplateIncludes">
					<cfdirectory action="create" directory="#thePath#/TemplateIncludes/Inactive">
					<cfdirectory action="create" directory="#thePath#/TemplateControl">
					<cfdirectory action="create" directory="#thePath#/TemplateControl/Inactive">
					<cfdirectory action="create" directory="#thePath#/TemplateControl/StylingGraphics">
					<cfdirectory action="create" directory="#thePath#/TemplateControl/StylingGraphics/Inactive">
					<cfdirectory action="create" directory="#thePath#/TemplateControl/NavigationControl">
					<cfdirectory action="create" directory="#thePath#/TemplateControl/NavigationControl/Inactive">
					<cfdirectory action="create" directory="#thePath#/Originals">
					<cfdirectory action="create" directory="#thePath#/Originals/TemplateGraphics">
					<cfdirectory action="create" directory="#thePath#/Originals/TemplateIncludes">
					<cfdirectory action="create" directory="#thePath#/Originals/TemplateControl">
					<cfdirectory action="create" directory="#thePath#/Originals/TemplateControl/StylingGraphics">
					<cfdirectory action="create" directory="#thePath#/Originals/TemplateControl/NavigationControl">
				<cfelse>
					<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 4) />
					<cfset ret.error.ErrorText = ret.error.ErrorText & temp.error.ErrorText />
				</cfif>
				<!--- done --->
			<cfcatch type="any">
				<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 128) />
				<cfset ret.error.ErrorText = ret.error.ErrorText & 'Oops! Error Caught, error message was: #cfcatch.message#, error detail was: #cfcatch.detail#<br>' />
				<cfset ret.error.ErrorExtra =  cfcatch.TagContext />
				<cflog text="CreateTemplateSet() Trapped. Site: #application.SLCMS.Config.base.SiteName#. ret.error.ErrorCode: #ret.error.ErrorCode# - Error Text: #ret.error.ErrorText# - Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#"  file="SLCMSerrors" type="Error" application = "yes">
				<cfif application.SLCMS.Config.debug.debugmode>
					CreateTemplateSet() Trapped - error dump:<br>
					<cfdump var="#ret.error.ErrorExtra#">
				</cfif>
			</cfcatch>
			</cftry>
		<cfelse>
			<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 2) />
			<cfset ret.error.ErrorText = ret.error.ErrorText & "Oops! Set Name Supplied already exists<br>" />
		</cfif>
	<cfelse>	<!--- this is the error code --->
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 1) />
		<cfset ret.error.ErrorText = ret.error.ErrorText & "Oops! No Name Supplied for the Set<br>" />
	</cfif>
	
	<cfreturn ret  />
</cffunction>

<cffunction name="CreateBlankTemplateSetStructure" output="yes" returntype="struct" access="private"
						displayname="Create a Blank TemplateSet Structure"
						hint="returns empty structure to put a template into"
						>	
	<!--- this function needs nothing.... --->
	<cfset var thisSubSet = "" />	<!--- temp/throwaway var --->
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorText = "" />
	<cfset ret.error.ErrorContext = "TemplateManagement CFC: CreateBlankTemplateSetStructure()" />
	<cfset ret.Data = StructNew() />

	<cftry>
		<!--- lets make new structs --->
		<cfloop list="#variables.TemplateParts.PartList#" index="thisSubSet">
			<cfset ret.Data["#thisSubSet#"] = StructNew() />
			<cfset ret.Data["#thisSubSet#"].Active = StructNew() />
			<cfset ret.Data["#thisSubSet#"].Active.ItemList = "" />
			<cfset ret.Data["#thisSubSet#"].Active.ItemCount = 0 />
			<cfset ret.Data["#thisSubSet#"].Active.Items = StructNew() />
			<cfset ret.Data["#thisSubSet#"].Inactive = StructNew() />
			<cfset ret.Data["#thisSubSet#"].Inactive.ItemList = "" />
			<cfset ret.Data["#thisSubSet#"].Inactive.ItemCount = 0 />
			<cfset ret.Data["#thisSubSet#"].Inactive.Items = StructNew() />
			<cfset ret.Data["#thisSubSet#"].Orphans = StructNew() />
			<cfset ret.Data["#thisSubSet#"].Orphans.ItemList = "" />
			<cfset ret.Data["#thisSubSet#"].Orphans.ItemCount = 0 />
			<cfset ret.Data["#thisSubSet#"].Orphans.Items = StructNew() />
			<cfset ret.Data["#thisSubSet#"].Originals = StructNew() />
			<cfset ret.Data["#thisSubSet#"].Originals.ItemList = "" />
			<cfset ret.Data["#thisSubSet#"].Originals.ItemCount = 0 />
			<cfset ret.Data["#thisSubSet#"].Originals.Items = StructNew() />
			<!--- now we have the base data we check to see if we are in the navigation bit and add in the bit for the structures created from the nav ini files --->
			<cfif thisSubSet eq "NavigationControl">
				<cfset ret.Data["#thisSubSet#"].ActiveNavStyling = StructNew() />
			</cfif>
		</cfloop>
	<cfcatch type="any">
		<cfset ret.error = TakeErrorCatch(RetErrorStruct=ret.error, CatchStruct=cfcatch) />
	</cfcatch>
	</cftry>
	<cfreturn ret  />
</cffunction>
<!---
<cffunction name="CreateBlankTemplateSetStructureOriginal" output="no" returntype="struct" access="private"
	displayname="Create a Blank TemplateSet Structure"
	hint="Creates empty structure to put a templates into
				can force a clean structure over an existing one"
				>
	<!--- this function needs.... --->
	<cfargument name="SetName" type="string" default="" required="true" hint="the name of the template set" />
	<cfargument name="TemplateType" type="string" default="Page" hint="the type of the template set: Page, Form, Data, etc" />
	<cfargument name="ForceNewStructure" type="boolean" default="False" hint="True to force a new, clean structure over an existing one" />
	<cfargument name="SubSiteID" type="string" required="yes" hint="the ID of the subsite to put the set in">

	<!--- now all of the var declarations, first the arguments which need manipulation --->
	<cfset var theSetName = trim(arguments.SetName) />
	<cfset var theTemplateType = trim(arguments.TemplateType) />
	<cfset var ForceNew = trim(arguments.ForceNewStructure) />
	<cfset var theSubSiteID = trim(arguments.SubSiteID) />
	<!--- now vars that will get filled as we go --->
	<cfset var lcntr = 0 />	<!--- temp loop counter --->
	<cfset var thisSubSet = "" />	<!--- temp/throwaway var --->
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorText = "" />
	<cfset ret.error.ErrorContext = "TemplateManagement CFC: CreateBlankTemplateSetStructure()" />
	<cfset ret.Data = "" />

	<cftry>
		<cfif theSetName neq "" and theTemplateType neq "" and ListFindNoCase(variables.Lists.CoreTemplateTypeList, theTemplateType)>
			<!--- do some checks to make sure we don't already exist if not forcing a new structure --->
			<cfif ForceNew or not StructkeyExists(variables["SubSite_#theSubSiteID#"]["#theTemplateType#_Templates"], "#theSetName#")>
				<!--- we have params so lets make new structs --->
				<cfset variables["SubSite_#theSubSiteID#"]["#theTemplateType#_Templates"].TemplateSetList = ListAppend(variables["SubSite_#theSubSiteID#"]["#theTemplateType#_Templates"].TemplateSetList, theSetName) />
				<cfset variables["SubSite_#theSubSiteID#"]["#theTemplateType#_Templates"].TemplateSetCount = variables["SubSite_#theSubSiteID#"]["#theTemplateType#_Templates"].TemplateSetCount+1 />
				<cfset variables["SubSite_#theSubSiteID#"]["#theTemplateType#_Templates"].TemplateSets["#theSetName#"] = StructNew() />
				<cfloop list="#variables.TemplateSubSetTypeList#" index="thisSubSet">
					<cfset variables["SubSite_#theSubSiteID#"]["#theTemplateType#_Templates"].TemplateSets["#theSetName#"]["#thisSubSet#"] = StructNew() />
					<cfset variables["SubSite_#theSubSiteID#"]["#theTemplateType#_Templates"].TemplateSets["#theSetName#"]["#thisSubSet#"].Active = StructNew() />
					<cfset variables["SubSite_#theSubSiteID#"]["#theTemplateType#_Templates"].TemplateSets["#theSetName#"]["#thisSubSet#"].Active.ItemList = "" />
					<cfset variables["SubSite_#theSubSiteID#"]["#theTemplateType#_Templates"].TemplateSets["#theSetName#"]["#thisSubSet#"].Active.ItemCount = 0 />
					<cfset variables["SubSite_#theSubSiteID#"]["#theTemplateType#_Templates"].TemplateSets["#theSetName#"]["#thisSubSet#"].Active.Items = StructNew() />
					<cfset variables["SubSite_#theSubSiteID#"]["#theTemplateType#_Templates"].TemplateSets["#theSetName#"]["#thisSubSet#"].Inactive = StructNew() />
					<cfset variables["SubSite_#theSubSiteID#"]["#theTemplateType#_Templates"].TemplateSets["#theSetName#"]["#thisSubSet#"].Inactive.ItemList = "" />
					<cfset variables["SubSite_#theSubSiteID#"]["#theTemplateType#_Templates"].TemplateSets["#theSetName#"]["#thisSubSet#"].Inactive.ItemCount = 0 />
					<cfset variables["SubSite_#theSubSiteID#"]["#theTemplateType#_Templates"].TemplateSets["#theSetName#"]["#thisSubSet#"].Inactive.Items = StructNew() />
					<cfset variables["SubSite_#theSubSiteID#"]["#theTemplateType#_Templates"].TemplateSets["#theSetName#"]["#thisSubSet#"].Orphans = StructNew() />
					<cfset variables["SubSite_#theSubSiteID#"]["#theTemplateType#_Templates"].TemplateSets["#theSetName#"]["#thisSubSet#"].Orphans.ItemList = "" />
					<cfset variables["SubSite_#theSubSiteID#"]["#theTemplateType#_Templates"].TemplateSets["#theSetName#"]["#thisSubSet#"].Orphans.ItemCount = 0 />
					<cfset variables["SubSite_#theSubSiteID#"]["#theTemplateType#_Templates"].TemplateSets["#theSetName#"]["#thisSubSet#"].Orphans.Items = StructNew() />
					<!--- now we have the base data we check to see if we are in the navigation bit and if so we read the nav ini files --->
					<cfif thisSubSet eq "NavigationControl">
						<cfset variables["SubSite_#theSubSiteID#"]["#theTemplateType#_Templates"].TemplateSets["#theSetName#"]["#thisSubSet#"].ActiveNavStyling = StructNew() />
					</cfif>
				</cfloop>
			<cfelse>
				<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 2) />
				<cfset ret.error.ErrorText = ret.error.ErrorText & "Oops! Set Name Supplied already exists<br>" />
			</cfif>
		<cfelse>	<!--- this is the error code --->
			<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 1) />
			<cfset ret.error.ErrorText = ret.error.ErrorText & "Oops! No Name Supplied for the Set<br>" />
		</cfif>
	<cfcatch type="any">
		<cfset ret.error = TakeErrorCatch(RetErrorStruct=ret.error, CatchStruct=cfcatch) />
	</cfcatch>
	</cftry>
	
	<cfreturn ret  />
</cffunction>
--->
<cffunction name="AddTemplate" output="no" returntype="struct" access="public"
	displayname="Add a Template"
	hint="Add a Template into the system from designated file
				needs the template type, set and filename and which subsite"
				>
	<!--- this function needs.... --->
	<cfargument name="FileName" type="string" default="" />	<!--- the file name of the template --->
	<cfargument name="Subset" type="string" default="Templates" />	<!--- the name of the subset it is in, templates, stylesheets, whatever --->
	<cfargument name="TemplateSet" type="string" default="" />	<!--- the name of the set it is in --->
	<cfargument name="TemplateType" type="string" default="" />	<!--- the type of the template --->
	<cfargument name="TemplateFileSource" type="string" default="" />	<!--- where to find the file on the server --->
	<cfargument name="SubSiteID" type="string" required="yes" hint="the ID of the subsite to put the set in">

	<!--- now all of the var declarations, first the arguments which need manipulation --->
	<cfset var theTemplateFileName = trim(arguments.FileName) />
	<cfset var theSubset = trim(arguments.Subset) />
	<cfset var theTemplateSet = trim(arguments.TemplateSet) />
	<cfset var theTemplateType = trim(arguments.TemplateType) />
	<cfset var theTemplateFileSource = trim(arguments.TemplateFileSource) />
	<cfset var theSubSiteID = trim(arguments.SubSiteID) />
	<!--- now vars that will get filled as we go --->
	<cfset var theTemplateFileNameExtension = ListLast(theTemplateFileName, ".") />
	<cfset var theTemplateName = ListFirst(theTemplateFileName, ".") />
	<cfset var theTemplateBackupFileExtension = "bak" />
	<cfset var theSubSetExtension = "" />
	<cfset var theDestSetPath = '' />
	<cfset var theDestSetInactivePath = '' />
	<cfset var theDestSetActivePath = '' />
	<cfset var theDestFullPath = '' />
	<cfset var temp = "" />	<!--- temp/throwaway var --->
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorText = "" />
	<cfset ret.error.ErrorContext = "TemplateManagement CFC: AddTemplate()" />
	<cfset ret.Data = "" />

	<cftry>
		<!--- first find what it is we are uploading and validate the params --->
		<cfset temp = ListFindNoCase(variables.TemplateSubSetTypeList, theSubset)>
		<cfif temp neq 0>
			<cfset theSubSetExtension = ListGetAt(variables.TemplateSubSetExtensionList, temp)>
			<cfif Listlen(theTemplateFileName, ".") gt 1>
				<cfif theSubSetExtension eq theTemplateFileNameExtension or theSubSetExtension eq "gfix">
					<!--- we have a viable file name so lets make it into a template --->
					<!--- first we will copy the template file over and then make the structures --->
					<!--- work out path according to type (the extension being used to work out what is what) --->
					<cfset theDestSetPath = getTemplateSetPhysicalPath(TemplateType="#theTemplateType#", TemplateSet="#theTemplateSet#", Subset="#theSubset#", subsiteID="#theSubSiteID#") />
					<cfset theDestSetInactivePath = "#theDestSetPath#Inactive/" />
					<cfif not DirectoryExists("#theDestSetInactivePath#")>	<!--- make the InActive folder for legacy 2.1.1- code sites --->
						<cfdirectory action="create" directory="#theDestSetInactivePath#">
					</cfif>
					<cfset theDestSetActivePath = "#theDestSetPath#" />
					<cfset theDestFullPath = theDestSetActivePath & theTemplateFileName />
					<cfif FileExists(theDestFullPath)>
						<!--- there is one already there, this must be an update so back it up --->
						<cfset theTemplateBackupFileExtension = "bak" & variables["SubSite_#theSubSiteID#"]["#theTemplateType#Templates"].TemplateSets["#theTemplateSet#"]["#theSubset#"].Active.Items["#theTemplateName#"].BackupExtensionNextNumber />
						<cfset variables["SubSite_#theSubSiteID#"]["#theTemplateType#Templates"].TemplateSets["#theTemplateSet#"]["#theSubset#"].Active.Items["#theTemplateName#"].BackupExtensionNextNumber = variables["SubSite_#theSubSiteID#"]["#theTemplateType#_Templates"].TemplateSets["#theTemplateSet#"]["#theSubset#"].Active.Items["#theTemplateName#"].BackupExtensionNextNumber+1 />
						<cffile action="rename" source="#theDestFullPath#" destination="#theDestSetActivePath##theTemplateName#.#theTemplateBackupFileExtension#">
						<cfset variables["SubSite_#theSubSiteID#"]["#theTemplateType#_Templates"].TemplateSets["#theTemplateSet#"]["#theSubset#"].Active.Items["#theTemplateName#"].BackupCount = variables["SubSite_#theSubSiteID#"]["#theTemplateType#_Templates"].TemplateSets["#theTemplateSet#"]["#theSubset#"].Active.Items["#theTemplateName#"].BackupCount+1 />
						<cfset variables["SubSite_#theSubSiteID#"]["#theTemplateType#_Templates"].TemplateSets["#theTemplateSet#"]["#theSubset#"].Active.Items["#theTemplateName#"].BackupExtensionList = ListAppend(variables["SubSite_#theSubSiteID#"]["#theTemplateType#_Templates"].TemplateSets["#theTemplateSet#"]["#theSubset#"].Active.Items["#theTemplateName#"].BackupExtensionList, theTemplateBackupFileExtension) />
					<cfelse>
						<!--- its a new template so create the structure --->
						<cfset variables["SubSite_#theSubSiteID#"]["#theTemplateType#_Templates"].TemplateSets["#theTemplateSet#"]["#theSubset#"].Active.ItemList = ListAppend(variables["SubSite_#theSubSiteID#"]["#theTemplateType#_Templates"].TemplateSets["#theTemplateSet#"]["#theSubset#"].Active.ItemList, theTemplateName) />
						<cfset variables["SubSite_#theSubSiteID#"]["#theTemplateType#_Templates"].TemplateSets["#theTemplateSet#"]["#theSubset#"].Active.ItemCount = IncrementValue(variables["SubSite_#theSubSiteID#"]["#theTemplateType#_Templates"].TemplateSets["#theTemplateSet#"]["#theSubset#"].Active.ItemCount) />
						<cfset variables["SubSite_#theSubSiteID#"]["#theTemplateType#_Templates"].TemplateSets["#theTemplateSet#"]["#theSubset#"].Active.Items["#theTemplateName#"] = StructNew() />
						<cfset variables["SubSite_#theSubSiteID#"]["#theTemplateType#_Templates"].TemplateSets["#theTemplateSet#"]["#theSubset#"].Active.Items["#theTemplateName#"].FileName = theTemplateFileName />
						<cfset variables["SubSite_#theSubSiteID#"]["#theTemplateType#_Templates"].TemplateSets["#theTemplateSet#"]["#theSubset#"].Active.Items["#theTemplateName#"].TemplateName = theTemplateName />
						<cfset variables["SubSite_#theSubSiteID#"]["#theTemplateType#_Templates"].TemplateSets["#theTemplateSet#"]["#theSubset#"].Active.Items["#theTemplateName#"].BackupCount = 0 />
						<cfset variables["SubSite_#theSubSiteID#"]["#theTemplateType#_Templates"].TemplateSets["#theTemplateSet#"]["#theSubset#"].Active.Items["#theTemplateName#"].BackupExtensionList = "" />
						<cfset variables["SubSite_#theSubSiteID#"]["#theTemplateType#_Templates"].TemplateSets["#theTemplateSet#"]["#theSubset#"].Active.Items["#theTemplateName#"].BackupExtensionNextNumber = 1 />
					</cfif>
					<!--- Everything ready structure-wise so move the file to its home --->
					<cffile action="move" source="#theTemplateFileSource##theTemplateFileName#" destination="#theDestFullPath#">
				<cfelse>	<!--- this is the error code --->
					<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 4) />
					<cfset ret.error.ErrorText = ret.error.ErrorText & "Oops! File not of the correct extension. Should have been: #theSubSetExtension#, was: #theTemplateFileNameExtension#<br>" />
				</cfif>
			<cfelse>	<!--- this is the error code --->
				<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 2) />
				<cfset ret.error.ErrorText = ret.error.ErrorText & "Oops! Filename not legitmate. Was: #theTemplateFileName#<br>" />
			</cfif>
		<cfelse>
			<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 1) />
			<cfset ret.error.ErrorText = ret.error.ErrorText & "Oops! Invalid template subtype supplied. Was: #theSubset#<br>" />
		</cfif>
	<cfcatch type="any">
		<cfset ret.error = TakeErrorCatch(RetErrorStruct=ret.error, CatchStruct=cfcatch) />
	</cfcatch>
	</cftry>
	
	<cfreturn ret  />
</cffunction>

<cffunction name="ActivateTemplate" output="no" returntype="struct" access="public"
	displayname="Activate a Template"
	hint="Activates an Inactive Template"
				>
	<!--- this function needs.... --->
	<cfargument name="TemplateName" type="string" default="" />	<!--- the name of the template --->
	<cfargument name="Subset" type="string" default="Templates" />	<!--- the name of the set it is in --->
	<cfargument name="TemplateSet" type="string" default="" />	<!--- the name of the set it is in --->
	<cfargument name="TemplateType" type="string" default="" />	<!--- the type of the template --->
	<cfargument name="SubSiteID" type="string" required="yes" hint="the ID of the subsite to put the set in">

	<!--- now all of the var declarations, first the arguments which need manipulation --->
	<cfset var theTemplateName = trim(arguments.TemplateName) />
	<cfset var theSubset = trim(arguments.Subset) />
	<cfset var theTemplateSet = trim(arguments.TemplateSet) />
	<cfset var theTemplateType = trim(arguments.TemplateType) />
	<cfset var theSubSiteID = trim(arguments.SubSiteID) />
	<!--- now vars that will get filled as we go --->
	<cfset var theSetPath = "" />	<!--- temp --->
	<cfset var theFileName = "" />	<!--- temp --->
	<cfset var theSubsetPos = 0 />	<!--- temp/throwaway var --->
	<cfset var theExtension = "" />	<!--- temp/throwaway var --->
	<cfset var temp = "" />	<!--- temp/throwaway var --->
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorText = "" />
	<cfset ret.error.ErrorContext = "TemplateManagement CFC: ActivateTemplate()" />
	<cfset ret.error.ErrorExtra = "" />
	<cfset ret.Data = "" />

	<cfif theTemplateName neq "" and theTemplateSet neq "" and theTemplateType neq "">
		<!--- we have params so move the template from inactive to active --->
		<!--- wrap the whole thing in a try/catch in case something breaks --->
		<cftry>
			<!--- work out the file name and the paths --->
			<cfif theTemplateType eq "Form">
				<cfset theFileName = "#theTemplateName#-Form.cfm" />
			<cfelse>
				<cfset theSubsetPos = ListFindNoCase(variables.TemplateSubSetTypeList, theSubset)>
				<cfset theExtension = ListGetAt(variables.TemplateSubSetExtensionList, theSubsetPos)>
				<cfif theExtension eq "gfix">
					<cfset theFileName = variables["SubSite_#theSubSiteID#"]["#theTemplateType#_Templates"].TemplateSets[theTemplateSet][theSubset].Inactive.Items[theTemplateName].FileName />
				<cfelse>
					<cfset theFileName = "#theTemplateName#.#theExtension#" />
				</cfif>
			</cfif>
			<cfset theSetPath = getTemplateSetPhysicalPath(TemplateType="#theTemplateType#", TemplateSet="#theTemplateSet#", Subset="#theSubset#", subsiteID="#theSubSiteID#") />
			<!--- then move the file --->
			<cffile action="move" source="#theSetPath#Inactive/#theFileName#" destination="#theSetPath##theFileName#">
			<!--- and reread the template structure --->
			<cfset temp = LoadTemplateType(TemplateType="#theTemplateType#", Path2templates="#variables["SubSite_#theSubSiteID#"]['#theTemplateType#_Templates'].TemplatesPhysicalPath#", subsiteID="#theSubSiteID#") />
			
		<cfcatch type="any">
			<cfset ret.error = TakeErrorCatch(RetErrorStruct=ret.error, CatchStruct=cfcatch) />
		</cfcatch>
		</cftry>
	<cfelse>	<!--- this is the error code --->
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 1) />
		<cfset ret.error.ErrorText = ret.error.ErrorText & "Oops! invalid input params<br>" />
	</cfif>
	
	<cfreturn ret  />
</cffunction>

<cffunction name="InactivateTemplate" output="no" returntype="struct" access="public"
	displayname="Inactivate a Template"
	hint="hides an Active Template"
				>
	<!--- this function needs.... --->
	<cfargument name="TemplateName" type="string" default="" />	<!--- the name of the template --->
	<cfargument name="Subset" type="string" default="Templates" />	<!--- the name of the set it is in --->
	<cfargument name="TemplateSet" type="string" default="" />	<!--- the name of the set it is in --->
	<cfargument name="TemplateType" type="string" default="" />	<!--- the type of the template --->
	<cfargument name="SubSiteID" type="string" required="yes" hint="the ID of the subsite to put the set in">

	<!--- now all of the var declarations, first the arguments which need manipulation --->
	<cfset var theTemplateName = trim(arguments.TemplateName) />
	<cfset var theSubset = trim(arguments.Subset) />
	<cfset var theTemplateSet = trim(arguments.TemplateSet) />
	<cfset var theTemplateType = trim(arguments.TemplateType) />
	<cfset var theSubSiteID = trim(arguments.SubSiteID) />
	<!--- now vars that will get filled as we go --->
	<cfset var theSetPath = "" />	<!--- temp --->
	<cfset var theFileName = "" />	<!--- temp --->
	<cfset var theSubsetPos = 0 />	<!--- temp/throwaway var --->
	<cfset var theExtension = "" />	<!--- temp/throwaway var --->
	<cfset var temp = "" />	<!--- temp/throwaway var --->
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorText = "" />
	<cfset ret.error.ErrorContext = "TemplateManagement CFC: InActivateTemplate()" />
	<cfset ret.error.ErrorExtra = "" />
	<cfset ret.Data = "" />

	<cfif theTemplateName neq "" and theTemplateSet neq "" and theTemplateType neq "">
		<!--- we have params so move the template from inactive to active --->
		<!--- wrap the whole thing in a try/catch in case something breaks --->
		<cftry>
			<!--- work out the file name and the paths --->
			<cfif theTemplateType eq "Form">
				<cfset theFileName = "#theTemplateName#-Form.cfm" />
			<cfelse>
				<cfset theSubsetPos = ListFindNoCase(variables.TemplateSubSetTypeList, theSubset)>
				<cfset theExtension = ListGetAt(variables.TemplateSubSetExtensionList, theSubsetPos)>
				<cfif theExtension eq "gfix">
					<cfset theFileName = variables["SubSite_#theSubSiteID#"]["#theTemplateType#_Templates"].TemplateSets[theTemplateSet][theSubset].Active.Items[theTemplateName].FileName />
				<cfelse>
					<cfset theFileName = "#theTemplateName#.#theExtension#" />
				</cfif>
			</cfif>
			<cfset theSetPath = getTemplateSetPhysicalPath(TemplateType="#theTemplateType#", TemplateSet="#theTemplateSet#", Subset="#theSubset#", subsiteID="#theSubSiteID#") />
			<!--- then move the file --->
			<cfif not DirectoryExists("#theSetPath#Inactive")>	<!--- make the InActive folder for legacy 2.1.1- code sites --->
				<cfdirectory action="create" directory="#theSetPath#Inactive">
			</cfif>
			<cffile action="move" source="#theSetPath##theFileName#" destination="#theSetPath#Inactive/#theFileName#">
			<!--- and reread the template structure --->
			<cfset temp = LoadTemplateType(TemplateType="#theTemplateType#", Path2templates="#variables["SubSite_#theSubSiteID#"]['#theTemplateType#_Templates'].TemplatesPhysicalPath#", subsiteID="#theSubSiteID#") />
			
		<cfcatch type="any">
			<cfset ret.error = TakeErrorCatch(RetErrorStruct=ret.error, CatchStruct=cfcatch) />
		</cfcatch>
		</cftry>
	<cfelse>	<!--- this is the error code --->
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 1) />
		<cfset ret.error.ErrorText = ret.error.ErrorText & "Oops! invalid input params<br>" />
	</cfif>
	
	<cfreturn ret  />
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
	<cfset ret.error.ErrorContext = "SLCMS_Utility CFC: LogIt()" />
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
			<cfset ret.error = TakeErrorCatch(RetErrorStruct=ret.error, CatchStruct=cfcatch) />
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
	<cfset error.ErrorCode = 128 />
	<cfset error.ErrorText = "" />
	<cfset error.ErrorContext = "" />
	<cfset error.ErrorExtra = "" />
	<cftry>
		<!--- build the standard return structure using whatever may have been fed in --->
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