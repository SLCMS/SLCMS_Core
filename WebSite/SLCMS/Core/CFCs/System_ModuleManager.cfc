<cfcomponent  extends="controller"  
	output="No"
	displayname="System Module Manager" 
	hint="Manages the Modules in SLCMS and their general availability"
	>
<!--- mbc SLCMS Core CFCs  --->
<!--- &copy; 2011 mort bay communications --->
<!---  --->
<!--- System Module Manager CFC - Persistent --->
<!--- Manages the loading of modules into SLCMS
			This CFC is not a good example of encapsulation, it talks to outside persistent scopes like crazy
			in fact you could say that it is a good example of a lack of encapsulation! :-)
			 --->
<!--- Contains:
			init() - finds out all about what modules are available and to whom in the case of a portal, calls the two functions below
			ReadModulesFolder() - reads the module folder and gets each module by calling the ReadModuleFolder function for each one
			ReadModuleFolder() - reads a module's' and gets its definition
			CheckNsetModule2DB() - cross checks the above against DB and sets flags
			ChangeModuleEnableState() - turns a module on/off globally or for specific subSite
			getAvailableModulesFlags() - returns struct of all available modules and their flags
			SystemHasModules() - returns true/false if there are modules installed
			getQuickAvailableModulesList() - returns a list of available modules, quick return - no error struct
			getVariablesScope() - shows the variables scope, often used in debugging
			 --->
<!---  --->
<!--- created:  13th Mar 2010 by Kym K, mbcomms --->
<!--- modified: 13th Mar 2010 - 14th Mar 2010 by Kym K, mbcomms: initial work on it --->
<!--- modified: 29th Oct 2010 - 14th Nov 2010 by Kym K, mbcomms: more work on it --->
<!--- modified:  2nd Dec 2010 -  2nd Dec 2010 by Kym K, mbcomms: even more work on it! --->
<!--- modified: 20th Dec 2010 - 28th Dec 2010 by Kym K, mbcomms: yet more! (yes, I know its Xmas but its the only free time I get!)) --->
<!--- modified: 18th Feb 2011 - 18th Feb 2011 by Kym K, mbcomms: ran varScoper over code and found one un-var'd variables! oops, one too many :-/  --->
<!--- modified:  6th Apr 2011 - 22nd Apr 2011 by Kym K, mbcomms: adding in functions to handle page structure content type selection from modules and a general module/core API handler --->
<!--- modified: 25th Apr 2011 - 27th Apr 2011 by Kym K, mbcomms: renaming some structures to avoid confusion between core admin and module admin --->
<!--- modified: 15th May 2011 - 19th May 2011 by Kym K, mbcomms: improving module loading to detect required-but-not-there modules --->
<!--- modified:  2nd Jun 2011 -  2nd Jun 2011 by Kym K, mbcomms: added function to get preprocessor lists for things to be run before module presentation is called in displayContent.cfm tag --->
<!--- modified:  7th Jun 2011 - 11th Jun 2011 by Kym K, mbcomms: added logging functions so we can have consistent logging outside CF's logs --->
<!--- modified: 19th Nov 2011 - 19th Nov 2011 by Kym K, mbcomms: add core functions to CoreFunctionsReInitGeneratorList so module-less install still works --->
<!--- modified:  9th Apr 2012 -  9th Apr 2012 by Kym K, mbcomms: V3.0, CFWheels version. All SLCMS in own struct under app scope --->

	
	<!--- set up a few persistant things on the way in. --->
	<cfset variables["Local"] = StructNew() />
	<cfset variables.Local["CoreFunctionsReInitGeneratorList"] = "PortalControl" />	<!--- this is a list of the functions in the Core that can affect modules. They will fill it as their Definitions are read as well as the ones the admin uses which we hard code --->
	<cfset variables.Local["DataBaseTableName_ModuleManagement_Base"] = "" />
	<cfset variables.Local["DataBaseTableName_ModuleManagement_Permissions"] = "" />
	<cfset variables.Local["ModuleList_Available"] = "" />	<!--- modules which can be used --->
	<cfset variables.Local["ModuleList_Bad"] = "" />	<!--- will carry a list of any Modules that did not load in properly and must be ignored --->
	<cfset variables.Local["ModuleList_InFolder"] = "" />	<!--- all the modules in the folder, good, bad or ugly --->
	<cfset variables.Local["ModulesBaseFyzPath"] = "" />
	<cfset variables.Local["ModulesBaseURLPath"] = "" />
	<cfset variables.Local["Modules"] = StructNew() />	<!--- we are going to keep management data on the modules here, not the full works --->
	<cfset variables.Local["ModuleSort"] = ArrayNew(1) />	<!--- we are going to keep the init() order of the modules here. Lowest number is last to be init --->

<!--- initialize the various thingies, this should only be called after an app scope refresh --->
<cffunction name="init" output="No" returntype="any"	access="public" 
	displayname="Initializer"
	hint="loads up all the modules, their functions and definitions"
	>
	<!--- this function needs.... --->
	<cfargument name="ApplicationConfig" type="struct" required="true" hint="the configuration structure, normally the application.SLCMS.Config struct" />	
	
	<!--- some temp vars --->
	<cfset var Initialization = StructNew() />
	<cfset var RFM = StructNew() />	<!--- return from module folder read --->
	<cfset var RMDB = StructNew() />	<!--- ditto for DB read --->
	<cfset var theQueryDataArguments = StructNew() />	<!--- temp struct to compose the data clauses of the SQL query --->
	<cfset var theQueryWhereArguments = StructNew() />	<!--- temp struct to compose the where clauses of the SQL query --->
	<cfset var temp = "" />	<!--- as temp as you can get :-) --->
	<cfset var thisModule = "" />	<!--- loop temp --->
	<cfset var thisModuleInitList = "" />	<!--- loop temp --->
	<cfset var thisModuleInner = "" />	<!--- loop temp --->
	<cfset var thisLevel = 1 />	<!--- temp: pos in array as ordering --->
	<cfset var topLevel = 1 />	<!--- temp: highest pos in array --->
	<cfset var oneMovedUp = True />	<!--- temp: flag to show one has moved up --->
	<cfset var beenMovedUpList = "" />	<!--- temp: list of modules already moved up for a particular level so we don't try to move one twice --->
	<cfset var ModuleInitGet = "" />	<!--- temp for the individual module init() return --->
	<cfset var temps = "" />
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorContext = "System_ModuleManager CFC: init()" />
	<cfset ret.error.ErrorText = ret.error.ErrorContext />
	<cfset ret.error.ErrorExtra = "" />
	<cfset ret.Data = "" />	<!--- and no data yet --->

	<cfset temps = LogIt(LogType="CFC_Init", LogString="System_ModuleManager Init() Started") />

	<cftry>
		<!--- simply we search for modules in the modules folder and compare with database and set up modules in the system --->
		<cflog text='Modules Load Started in Init() - Time: #DateFormat(Now(),"YYYYMMDD")#-#TimeFormat(now(),"HH:mm:ss.L")#'  file="#Application.SLCMS.Logging.theSiteLogName#" type="Information" application="yes">
		<cfset variables.Local.ModuleList_Available = "" />
		<cfset variables.Local.ModuleList_Bad = "" />
		<cfset variables.Local.ModuleList_InFolder = "" />
		<cfset variables.Local.ModulesBaseFyzPath = arguments.applicationConfig.StartUp.SiteBasePath & arguments.applicationConfig.base.SLCMSModulesBaseRelPath />
		<cfset variables.Local.ModulesBaseURLPath = arguments.applicationconfig.base.MapURL & arguments.applicationconfig.base.SLCMSModulesBaseRelPath />
		<cfset variables.Local.DataBaseTableName_ModuleManagement_Base = arguments.applicationConfig.DatabaseDetails.DataBaseTableNaming_Root_System & arguments.applicationConfig.DatabaseDetails.ModuleBaseTable />
		<cfset variables.Local.DataBaseTableName_ModuleManagement_Permissions = arguments.applicationConfig.DatabaseDetails.DataBaseTableNaming_Root_System & arguments.applicationConfig.DatabaseDetails.ModulePermissionsTable />
		<!--- firstly we search the "modules" folder for folders within it, which should be modules, funnily enuf --->
		<cfset RFM = ReadModulesFolder() />
		<!--- we can return with errors flagged that came from some bad modules but others are good, the only real error is bit 128 as that was a crash --->
		<cfif BitAnd(RFM.error.errorcode, 128) neq 0>
			<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 2) />
			<cfset ret.error.ErrorText = ret.error.ErrorText & ' ReadModulesFolder() Failed. Error message was: #RFM.error.errortext#' />
		<cfelse>
			<!--- no drastic error but might be minor that stops some modules but not others --->
			<cfif BitAnd(RFM.error.errorcode, 64) eq 64>
				<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 2) />
				<cfset ret.error.ErrorText = ret.error.ErrorText & ' Module Dependency error. Error message was: #RFM.error.errortext#' />
			</cfif>
			<!--- we have a set of usable modules so now we have to work out their init() order and then initialize them by calling their init()s in the correct order --->
			<!--- first just shove everything in the array --->
			<cfset variables.Local.ModuleSort[thisLevel] = StructNew() />
			<cfloop list="#variables.Local.ModuleList_Available#" index="thisModule">
				<cfset variables.Local.ModuleSort[thisLevel]["#thisModule#"] = StructNew() />
				<cfset variables.Local.ModuleSort[thisLevel]["#thisModule#"].ReInitAfterList_Core = variables.Local.Modules["#thisModule#"].Dependencies.Core.ReInitFromCoreCFCList />
				<cfset variables.Local.ModuleSort[thisLevel]["#thisModule#"].ReInitAfterList_Module = variables.Local.Modules["#thisModule#"].Dependencies.Module.ReInitFromModulesList />
				<!---
				<cfif variables.Local.Modules["#thisModule#"].Dependencies.Module.ReInitFromModulesList neq "">
					<cfset variables.Local.ModuleSort[thisLevel]["#thisModule#"].ReInitAfterList = ListAppend(variables.Local.ModuleSort[thisLevel]["#thisModule#"].ReInitAfterList, variables.Local.Modules["#thisModule#"].Dependencies.Module.ReInitFromModulesList) />
				</cfif>
				--->
			</cfloop>
			<!--- now we loop over a level and see if there is anything that needs something to be already inited
						if there is then we move that something up a level so it will get called first
						we repeat this until we don't move anything up and we should be right --->
			<cfloop condition="oneMovedUp eq True">
				<cfset oneMovedUp = False />
				<cfset thisModuleInitList = "" />
				<cfset beenMovedUpList = "" />
				<cfloop collection="#variables.Local.ModuleSort[thisLevel]#" item="thisModule">
					<!--- grab the list of priors for this module --->
					<!--- note we are only fussing about the relative order between modules, not the core --->
					<cfset thisModuleInitList = variables.Local.ModuleSort[thisLevel]["#thisModule#"].ReInitAfterList_Module />
					<!--- and see if we need to move anything --->
					<cfloop list="#thisModuleInitList#" index="thisModuleInner">
						<cfif not ListFindNoCase(beenMovedUpList, thisModuleInner)>
							<!--- yes found one --->
							<cfif topLevel lte thisLevel>
								<!--- make a new level if we need to --->
								<cfset topLevel = thisLevel+1 />
								<cfset variables.Local.ModuleSort[topLevel] = StructNew() />
							</cfif>
							<!--- add to the new level --->
							<cfset variables.Local.ModuleSort[topLevel]["#thisModuleInner#"] = StructNew() />
							<cfset variables.Local.ModuleSort[topLevel]["#thisModuleInner#"].ReInitAfterList_Core = variables.Local.Modules["#thisModuleInner#"].Dependencies.Core.ReInitFromCoreCFCList />
							<cfset variables.Local.ModuleSort[topLevel]["#thisModuleInner#"].ReInitAfterList_Module = variables.Local.Modules["#thisModuleInner#"].Dependencies.Module.ReInitFromModulesList />
							<!---
							<cfif variables.Local.Modules["#thisModuleInner#"].Dependencies.Module.ReInitFromModulesList neq "">
								<cfset variables.Local.ModuleSort[topLevel]["#thisModuleInner#"].ReInitAfterList = ListAppend(variables.Local.ModuleSort[topLevel]["#thisModuleInner#"].ReInitAfterList, variables.Local.Modules["#thisModuleInner#"].Dependencies.Module.ReInitFromModulesList) />
							</cfif>
							--->
							<!--- and take away from this one --->
							<cfset temp = StructDelete(variables.Local.ModuleSort[thisLevel], thisModuleInner) />
							<!--- and flag that we have shuffled --->
							<cfset beenMovedUpList = ListAppend(beenMovedUpList, thisModuleInner) />
							<cfset oneMovedUp = True />
						</cfif>	<!--- end: test to see if we need to move this one up --->
					</cfloop>	<!--- end: loop over a particular module's reinit list --->
				</cfloop>	<!--- end: loop over all modules in this level --->
				<cfif oneMovedUp>	<!--- and if we moved any up then go there and scan again --->
					<cfset thisLevel = topLevel />
				</cfif>
			</cfloop>	<!--- end: loop until we don't move any --->
			<!--- 
			yay! we have an array of modules in init order so lets init them all
			we do this from the top down in the way we have built this stack
			 --->
			<cfloop from="#ArrayLen(variables.Local.ModuleSort)#" to="1" index="thisLevel" step="-1">
				<cfloop collection="#variables.Local.ModuleSort[thisLevel]#" item="thisModule">
					<cflog text='Module Init() Called - Module #thisModule# - Time: #DateFormat(Now(),"YYYYMMDD")#-#TimeFormat(now(),"HH:mm:ss.L")#'  file="#Application.SLCMS.Logging.theSiteLogName#" type="Information" application="yes">
					<cfset ModuleInitGet = StructNew() />	<!--- just in case clear out junk from previous loops --->
					<cfinvoke component="#application.SLCMS.Modules['#thisModule#'].Paths.ModuleRootURLpath#ModuleController" method="initModule" returnvariable="ModuleInitGet">
						<cfinvokeargument name="ApplicationConfig" value="#application.SLCMS.Config#">
						<cfinvokeargument name="ModuleConfig" value="#application.SLCMS.Modules['#thisModule#']#">
					</cfinvoke>
				</cfloop>
			</cfloop>
		</cfif>
		<cfif ret.error.ErrorCode>
			<cflog text='#ret.error.ErrorText# - ret.error.ErrorCode: #ret.error.ErrorCode# - Time: #DateFormat(Now(),"YYYYMMDD")#-#TimeFormat(now(),"HH:mm:ss")#'  file="#Application.SLCMS.Logging.theSiteLogName#" type="Error" application = "yes">
		</cfif>
		<cflog text='Modules Load Finished in Init() - Time: #DateFormat(Now(),"YYYYMMDD")#-#TimeFormat(now(),"HH:mm:ss.L")#'  file="#Application.SLCMS.Logging.theSiteLogName#" type="Information" application="yes">
	<cfcatch type="any">
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 128) />
		<cfset ret.error.ErrorText = ret.error.ErrorText & ' Trapped. Site: #application.SLCMS.Config.base.SiteName#, error message was: #cfcatch.message#, error detail was: #cfcatch.detail#' />
		<cfset ret.error.ErrorExtra =  cfcatch.TagContext />
		<cfif isArray(ret.error.ErrorExtra) and StructKeyExists(ret.error.ErrorExtra[1], "Raw_Trace")>
			<cfset ret.error.ErrorText = ret.error.ErrorText & ", Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#" />
		</cfif>
		<cflog text='#ret.error.ErrorText# - ret.error.ErrorCode: #ret.error.ErrorCode# - Time: #DateFormat(Now(),"YYYYMMDD")#-#TimeFormat(now(),"HH:mm:ss")#'  file="#Application.SLCMS.Logging.theSiteLogName#" type="Error" application = "yes">
		<cfif application.SLCMS.Config.debug.debugmode>
			<cfoutput>#ret.error.ErrorContext#</cfoutput> Trapped - error dump:<br>
			<cfdump var="#cfcatch#">
		</cfif>
	</cfcatch>
	</cftry>	
	<cfset temps = LogIt(LogType="CFC_Init", LogString="System_ModuleManager Init() Finished") />
	<!--- return the standard struct --->
	<cfreturn Ret  />
</cffunction>

<cffunction name="ReadModulesFolder" output="No" returntype="any" access="public" 
	displayname="Initializer"
	hint="loads up all the modules found in the Modules folder, their functions and definitions"
	>
	
	<!--- some temp vars --->
	<cfset var Initialization = StructNew() />	<!--- this is the return to the caller --->
	<cfset var temp = "" />
	<cfset var thisAvailableModule = "" />
	<cfset var theNeeds = "" />
	<cfset var thisNeed = "" />
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorContext = "System_ModuleManager CFC: ReadModulesFolder()" />
	<cfset ret.error.ErrorText = "" />
	<cfset ret.error.ErrorExtra = "" />
	<cfset ret.Data = "" />	<!--- and no data yet --->

	<cftry>
		<!--- simply we search the "modules" folder for folders within it, which should be modules, funnily enuf --->
		<cfset variables.Local.ModuleList_Available = "" />
		<cfset variables.Local.ModuleList_InFolder = "" />
		<cfset variables.Local.ModuleList_Bad = "" />
		<cfdirectory action="list" directory="#variables.Local.ModulesBaseFyzPath#" name="Initialization.ModuleDirectoryQuery">
		<cfloop query="Initialization.ModuleDirectoryQuery">
			<cfset Initialization.thisModuleFilename = Initialization.ModuleDirectoryQuery.Name />
			<cfif Initialization.ModuleDirectoryQuery.Type eq "dir" and Initialization.thisModuleFilename neq ".svn" and Not (FindNoCase(" ", Initialization.thisModuleFilename) or FindNoCase("H", Initialization.ModuleDirectoryQuery.attributes))>
				<!--- we have what could be a module directory so lets check for a ModuleController CFC and load the module into the system if we find one --->
				<cfset Initialization.ModuleFyzPath = "#variables.Local.ModulesBaseFyzPath##Initialization.thisModuleFilename#/" />
				<cfset Initialization.ModuleURLPath = "#variables.Local.ModulesBaseURLPath##Initialization.thisModuleFilename#/" />
				<cfset Initialization.ModuleDefFyzPath = "#Initialization.ModuleFyzPath#ModuleController.cfc" />
				<cfset Initialization.ModuleDefURLPath = "#Initialization.ModuleURLPath#ModuleController" />
				<cfif FileExists(Initialization.ModuleDefFyzPath)>
					<!--- we've got a definition cfc --->
					<cfset variables.Local.ModuleList_InFolder = ListAppend(variables.Local.ModuleList_InFolder, Initialization.thisModuleFilename) />
					<!--- let's call it and see what it says --->
					<cfset Initialization.ret1 = StructNew() />	<!--- set up an empty struct to handle the return from the module load --->
					<cfset Initialization.ret1 = ReadModuleFromFolder(Initialization.thisModuleFilename) />
					<cfif Initialization.ret1.error.errorcode eq 0>
						<!--- a good load so lets check against the database --->
						<cfset Initialization.ret2 = StructNew() />	<!--- set up an empty struct to handle the return from the function --->
						<cfset Initialization.ret2 = CheckNsetModule2DB("#Initialization.thisModuleFilename#") />
						<cfif Initialization.ret2.error.errorcode eq 0>
						<cfelse>
							<cfset ret.error.ErrorCode =  BitOr(Initialization.ret2.error.ErrorCode, 4) />
							<cfset ret.error.ErrorText = ret.error.ErrorText & ' CheckNsetModule2DB("#Initialization.thisModuleFilename#") Failed. error message was: #Initialization.ret2.error.errortext#' />
						</cfif>
					<cfelse>
						<!--- oops! the module load returned an error --->
						<!--- ToDo: error handler here --->
						<!--- something went wrong. The detail is already logged so just log the general fact here --->
						<cfset ret.error.ErrorText = ret.error.ErrorText & ' ReadModuleFromFolder(#Initialization.thisModuleFilename#) failed. Error was: #Initialization.ret1.error.ErrorText#' />
						<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 1) />
						<cflog text='ReadModuleFromFolder(#Initialization.thisModuleFilename#) failed. Error was: #Initialization.ret1.error.ErrorText# - Time: #DateFormat(Now(),"YYYYMMDD")#-#TimeFormat(now(),"HH:mm:ss")#'  file="#Application.SLCMS.Logging.theSiteLogName#" type="Error" application = "yes">
					</cfif>	<!--- end: test for good return from ReadModuleFromFolder() --->
				<cfelse>
					<!--- oops! the folder did not have a ModuleController.cfc in it --->
					<!--- ToDo: error handler here --->
					<cfset ret.error.ErrorText = ret.error.ErrorText & ' ReadModuleFromFolder(#Initialization.thisModuleFilename#) failed. No ModuleController.cfc Found' />
					<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 1) />
					<cflog text='ReadModuleFromFolder(#Initialization.thisModuleFilename#) failed. No ModuleController.cfc Found - Time: #DateFormat(Now(),"YYYYMMDD")#-#TimeFormat(now(),"HH:mm:ss")#'  file="#Application.SLCMS.Logging.theSiteLogName#" type="Error" application = "yes">
				</cfif>	<!--- end: test for definition cfc existing --->
			</cfif>
		</cfloop>
		<cfif ret.error.ErrorCode>
			<!--- oops, something failed so flag for debug --->
			<cflog text='#ret.error.ErrorText# - ret.error.ErrorCode: #ret.error.ErrorCode# - Time: #DateFormat(Now(),"YYYYMMDD")#-#TimeFormat(now(),"HH:mm:ss")#'  file="#Application.SLCMS.Logging.theSiteLogName#" type="Error" application = "yes">
		<cfelse>
			<!--- all seems good and all loaded that can be so check that we have all that we need, a module might need another and its not there --->
			<cfset temp = variables.Local.ModuleList_Available />	<!--- grab the list of hopefully good modules and put in temp var as we are going to mangle the original list as we go if we find bad ones --->
			<cfloop list="#temp#" index="thisAvailableModule">
				<!--- grab the modules that each module needs to be able to run and check it exists --->
				<cfset theNeeds =  variables.Local.Modules["#thisAvailableModule#"].Dependencies.Module.NeededModulesList />
				<cfloop list="#theNeeds#" index="thisNeed">
					<cfif not StructKeyExists(application.SLCMS.Modules, "#thisNeed#")>
						<!--- poo it is not there --->
						<cfset variables.Local.ModuleList_Bad = ListAppend(variables.Local.ModuleList_Bad, thisAvailableModule) />
						<cfif ListFind(ModuleList_Available, thisAvailableModule)>
							<cfset variables.Local.ModuleList_Available = ListDeleteAt(variables.Local.ModuleList_Available, ListFind(ModuleList_Available, thisAvailableModule)) />
						</cfif>
						<cflog text='Missing Module Need. Module #thisAvailableModule# needs module #thisNeed# to run and its not there. - Time: #DateFormat(Now(),"YYYYMMDD")#-#TimeFormat(now(),"HH:mm:ss")#'  file="#Application.SLCMS.Logging.theSiteLogName#" type="Error" application = "yes">
						<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 64) />
						<cfset ret.error.ErrorText = 'Missing Module Need. Module #thisAvailableModule# needs module #thisNeed# to run and its not there.' />
					</cfif>
				</cfloop>
			</cfloop>
		</cfif>
		<!--- we now have all of the modules that can be loaded and initialised so tell the system happy things --->
		<cfset application.SLCMS.System.ModuleList_Available = variables.Local.ModuleList_Available />
		<cfset application.SLCMS.System.ModuleList_Bad = variables.Local.ModuleList_Bad />
		<cfset application.SLCMS.System.ModuleList_InFolder = variables.Local.ModuleList_InFolder />
		<cfcatch type="any">
			<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 128) />
			<cfset ret.error.ErrorText = ret.error.ErrorContext & ' Trapped. Site: #application.SLCMS.Config.base.SiteName#, error message was: #cfcatch.message#, error detail was: #cfcatch.detail#' />
			<cfset ret.error.ErrorExtra =  cfcatch.TagContext />
			<cfif isArray(ret.error.ErrorExtra) and StructKeyExists(ret.error.ErrorExtra[1], "Raw_Trace")>
				<cfset ret.error.ErrorText = ret.error.ErrorText & ", Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#" />
			</cfif>
			<cflog text='#ret.error.ErrorText# - ret.error.ErrorCode: #ret.error.ErrorCode# - Time: #DateFormat(Now(),"YYYYMMDD")#-#TimeFormat(now(),"HH:mm:ss")#'  file="#Application.SLCMS.Logging.theSiteLogName#" type="Error" application = "yes">
			<cfif application.SLCMS.Config.debug.debugmode>
				<cfoutput>#ret.error.ErrorContext#</cfoutput> Trapped - error dump:<br>
				<cfdump var="#cfcatch#">
			</cfif>
		</cfcatch>
	</cftry>	
	<!--- return the standard struct --->
	<cfreturn Ret  />
</cffunction>

<cffunction name="ReadModuleFromFolder" output="No" returntype="any" access="public" 
	displayname="Initializer"
	hint="loads up all the modules, their functions and definitions"
	>
	<!--- this function needs.... --->
	<cfargument name="Modulename" type="string" required="true" hint="the formal name of the module to check" />
	
	<cfset var theModulename = trim(arguments.Modulename) />
	<!--- some temp vars --->
	<cfset var thisCFC = "" />
	<cfset var Initialization = StructNew() />	<!--- this is the return to the caller --->
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorContext = "System_ModuleManager CFC: ReadModuleFromFolder()" />
	<cfset ret.error.ErrorText = "" />
	<cfset ret.error.ErrorExtra = "" />
	<cfset ret.Data = "" />	<!--- and no data yet --->

	<cftry>
		<cfif theModulename neq "">
			<!--- we are reading the "modules" folder for folders within it, which should be modules, funnily enuf --->
			<!--- we have what could be a module folder so lets read ModuleController CFC --->
			<cfset Initialization.ModuleFyzPath = "#variables.Local.ModulesBaseFyzPath##theModulename#/" />
			<cfset Initialization.ModuleURLPath = "#variables.Local.ModulesBaseURLPath##theModulename#/" />
			<cfset Initialization.ModuleDefFyzPath = "#Initialization.ModuleFyzPath#ModuleController.cfc" />
			<cfset Initialization.ModuleDefURLPath = "#Initialization.ModuleURLPath#ModuleController" />
			<!--- we know we've got a definition cfc otherwise we wouldn't have got this far --->
			<!--- let's call it and see what it says --->
			<cfset Initialization.ModuleDefGet = StructNew() />	<!--- just in case clear out junk from previous loops --->
			<cfinvoke component="#Initialization.ModuleDefURLPath#" method="getBaseDefinition" returnvariable="Initialization.ModuleDefGet">
				<cfinvokeargument name="ApplicationPaths" value="#application.SLCMS.Paths_Common#">
    	</cfinvoke>
			<!--- we need to be ridiculously careful in case someone puts complete junk instead of a properly behaving module --->
			<cfif StructKeyExists(Initialization.ModuleDefGet, "error") and StructKeyExists(Initialization.ModuleDefGet.error, "errorcode") and Initialization.ModuleDefGet.error.errorcode eq 0>
				<!---  no error so far so set up our modules definitions if we have one --->
				<cfif StructKeyExists(Initialization.ModuleDefGet, "data") 
							and StructKeyExists(Initialization.ModuleDefGet.data, "ModuleNaming") 
							and StructKeyExists(Initialization.ModuleDefGet.data.ModuleNaming, "FormalName") 
							and Initialization.ModuleDefGet.data.ModuleNaming.FormalName neq ""
							and StructKeyExists(Initialization.ModuleDefGet.data, "Dependencies") 
							and StructKeyExists(Initialization.ModuleDefGet.data, "Flags") 
							and StructKeyExists(Initialization.ModuleDefGet.data, "Paths") 
							>
					<!--- set up the local defs needed to manage the modules --->
					<cfset variables.Local.ModuleList_Available = ListAppend(variables.Local.ModuleList_Available, theModulename) />	<!--- its good so add it to the list of workable modules --->
					<cfset variables.Local.Modules["#theModulename#"] = StructNew() />
					<!--- for these we need to duplicate to avoid forcing the module to become quasi persistent as its internals are being referenced --->
					<cfset variables.Local.Modules["#theModulename#"] = duplicate(Initialization.ModuleDefGet.data) />	
					<!--- and set up the global things that modules can use, quite often modules will not be persistent so this is the store that carries persistent stuff that everyone might need --->
					<!--- this first is flagging what core CFCs we need to worry about for ReInit work --->
					<cfloop list="#variables.Local.Modules["#theModulename#"].Dependencies.Core.ReInitFromCoreCFCList#" index="thisCFC">
						<cfif not ListFindNoCase(variables.Local.CoreFunctionsReInitGeneratorList, thisCFC)>
							<cfset variables.Local.CoreFunctionsReInitGeneratorList = ListAppend(variables.Local.CoreFunctionsReInitGeneratorList, thisCFC) />
						</cfif>
					</cfloop>
					<!--- shuffle the supplied data from the module into the App scope --->
					<cfset application.SLCMS.Modules["#theModulename#"] = StructNew() />
					<cfset application.SLCMS.Modules["#theModulename#"].FormalName = theModulename />
					<cfset application.SLCMS.Modules["#theModulename#"].FriendlyName = variables.Local.Modules["#theModulename#"].ModuleNaming.FriendlyName />
					<cfset application.SLCMS.Modules["#theModulename#"].Description = variables.Local.Modules["#theModulename#"].ModuleNaming.Description />
					<cfset application.SLCMS.Modules["#theModulename#"].DisplayTypes = duplicate(Initialization.ModuleDefGet.data.DisplayTypes) />
					<cfset application.SLCMS.Modules["#theModulename#"].ModuleAdmin = duplicate(Initialization.ModuleDefGet.data.ModuleAdmin) />
					<cfset application.SLCMS.Modules["#theModulename#"].Paths = duplicate(Initialization.ModuleDefGet.data.Paths) />
					<cfset application.SLCMS.Modules["#theModulename#"].Paths.ModuleRootPhysicalPath = Initialization.ModuleFyzPath />
					<cfset application.SLCMS.Modules["#theModulename#"].Paths.ModuleRootURLPath = Initialization.ModuleURLPath />
					<cfset application.SLCMS.Modules["#theModulename#"].Paths.ApplicationModulesStructureName = "application.SLCMS.Modules" />
					<cfset application.SLCMS.Modules["#theModulename#"].Paths.ApplicationModulesThisStructureName = "#theModulename#" />
					<!--- and add to that with a few peers (spelling? peer as in take a look, peek as in stickybeak) into folders --->
					<cfset application.SLCMS.Modules["#theModulename#"].Paths.PresentationURLRoot = application.SLCMS.Modules["#theModulename#"].Paths.ModuleRootURLPath & application.SLCMS.Modules["#theModulename#"].Paths.Templates />
					<cfset Initialization.TemplateFyzPath = "#Initialization.ModuleFyzPath##application.SLCMS.Modules["#theModulename#"].Paths.Templates#" />
					<cfset Initialization.TemplateTagsFyzPath = "#Initialization.ModuleFyzPath##application.SLCMS.Modules["#theModulename#"].Paths.TemplateTags#" />
					<cfset application.SLCMS.Modules["#theModulename#"].Templates = "" />
					<cfdirectory action="list" directory="#Initialization.TemplateFyzPath#" type="file" filter="*.cfm" name="Initialization.TemplateDirectoryQuery">
					<cfloop query="Initialization.TemplateDirectoryQuery">
						<cfif Initialization.TemplateDirectoryQuery.Name neq ".svn" and Not (FindNoCase(" ", Initialization.TemplateDirectoryQuery.Name) or FindNoCase("H", Initialization.TemplateDirectoryQuery.attributes))>
							<cfset application.SLCMS.Modules["#theModulename#"].Templates = ListAppend(application.SLCMS.Modules["#theModulename#"].Templates, Initialization.TemplateDirectoryQuery.Name) />
						</cfif>
					</cfloop>
					<cfset application.SLCMS.Modules["#theModulename#"].TemplateTags = "" />
					<cfdirectory action="list" directory="#Initialization.TemplateTagsFyzPath#" type="file" filter="*.cfm" name="Initialization.TemplateTagsDirectoryQuery">
					<cfloop query="Initialization.TemplateTagsDirectoryQuery">
						<cfif Initialization.TemplateTagsDirectoryQuery.Name neq ".svn" and Not (FindNoCase(" ", Initialization.TemplateTagsDirectoryQuery.Name) or FindNoCase("H", Initialization.TemplateTagsDirectoryQuery.attributes))>
							<cfset application.SLCMS.Modules["#theModulename#"].TemplateTags = ListAppend(application.SLCMS.Modules["#theModulename#"].TemplateTags, Initialization.TemplateTagsDirectoryQuery.Name) />
						</cfif>
					</cfloop>
				<cfelse>
					<!--- oops! the module definition returned a bad structure --->
					<!--- ToDo: error handler here --->
					<cfset variables.Local.ModuleList_Bad = ListAppend(variables.Local.ModuleList_Bad, theModulename) />
					<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 2) />
					<cfset ret.error.ErrorText = ret.error.ErrorText & ' Bad data structure returned from Module: #theModuleName#' />
					<cflog text='Bad data structure returned from Module: #theModulename# - Time: #DateFormat(Now(),"YYYYMMDD")#-#TimeFormat(now(),"HH:mm:ss")#'  file="#Application.SLCMS.Logging.theSiteLogName#" type="Error" application = "yes">
				</cfif>	<!--- end: test for good return struct --->
			<cfelse>
				<!--- oops! the module returned an error --->
				<!--- ToDo: error handler here --->
				<cfset variables.Local.ModuleList_Bad = ListAppend(variables.Local.ModuleList_Bad, theModulename) />
				<cfset ret.error.ErrorText = ret.error.ErrorText & ' Bad error structure returned from Module: #theModuleName#' />
				<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 1) />
				<cflog text='Bad error structure returned from Module: #theModuleName# - Time: #DateFormat(Now(),"YYYYMMDD")#-#TimeFormat(now(),"HH:mm:ss")#'  file="#Application.SLCMS.Logging.theSiteLogName#" type="Error" application = "yes">
			</cfif>	<!--- end: error from definition get --->
		<cfelse>	
			<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 64) />
			<cfset ret.error.ErrorText = ret.error.ErrorContext & ' No Module Name supplied' />
		</cfif>
		<cfcatch type="any">
			<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 128) />
			<cfset ret.error.ErrorText = ret.error.ErrorContext & ' Trapped. Site: #application.SLCMS.Config.base.SiteName#, error message was: #cfcatch.message#, error detail was: #cfcatch.detail#' />
			<cfset ret.error.ErrorExtra =  cfcatch.TagContext />
			<cfif isArray(ret.error.ErrorExtra) and StructKeyExists(ret.error.ErrorExtra[1], "Raw_Trace")>
				<cfset ret.error.ErrorText = ret.error.ErrorText & ", Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#" />
			</cfif>
			<cflog text='#ret.error.ErrorText# - ret.error.ErrorCode: #ret.error.ErrorCode# - Time: #DateFormat(Now(),"YYYYMMDD")#-#TimeFormat(now(),"HH:mm:ss")#'  file="#Application.SLCMS.Logging.theSiteLogName#" type="Error" application = "yes">
			<cfif application.SLCMS.Config.debug.debugmode>
				<cfoutput>#ret.error.ErrorContext#</cfoutput> Trapped - error dump:<br>
				<cfdump var="#cfcatch#">
			</cfif>
		</cfcatch>
	</cftry>	
	<!--- return the standard struct --->
	<cfreturn Ret  />
</cffunction>

<cffunction name="CheckNsetModule2DB" output="No" returntype="any" access="public" 
	displayname="Initializer"
	hint="loads up specified module, its flags and things"
	>
	<!--- this function needs.... --->
	<cfargument name="Modulename" type="string" required="true" hint="the formal name of the module to check" />

	<cfset var theModulename = trim(arguments.Modulename) />
	<!--- some temp vars --->
	<cfset var theQueryDataArguments = StructNew() />	<!--- temp struct to compose the data clauses of the SQL query --->
	<cfset var theQueryWhereArguments = StructNew() />	<!--- temp struct to compose the where clauses of the SQL query --->
	<cfset var getModuleFromDB = "" />	<!--- query to get ModuleIDs of all in DB --->
	<cfset var theEnabledModules = "" />	<!--- list of modules that are enabled --->
	<cfset var InsertModule = "" />
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorContext = "System_ModuleManager CFC: CheckNsetModule2DB()" />
	<cfset ret.error.ErrorText = "" />
	<cfset ret.error.ErrorExtra = "" />
	<cfset ret.Data = "" />	<!--- and no data yet --->

	<cftry>
		<cfif theModulename neq "">
			<!--- lets compare with the database and set things up as we need --->
			<cfset theQueryWhereArguments.ModuleFormalName = theModulename />
			<cfset getModuleFromDB = application.SLCMS.Core.DataMgr.getRecords(tablename="#variables.Local.DataBaseTableName_ModuleManagement_Base#", data=theQueryWhereArguments, fieldList="ModuleID,ModuleFormalName,Enabled_Global,Enabled_subSiteList,Removed") />
			<cfif getModuleFromDB.RecordCount eq 0>
				<!--- its not in the database so it must be a new module, lets add it in --->
				<!--- first locally --->
				<cfset variables.Local.Modules["#theModulename#"].Flags.Enabled_Global = False />
				<cfset variables.Local.Modules["#theModulename#"].Flags.Enabled_subSiteList = "" />
				<!--- then the database --->
				<cfset StructClear(theQueryWhereArguments) />
				<cfset theQueryDataArguments.ModuleID = Nexts_GetNextID("ModuleID") />
				<cfset theQueryDataArguments.ModuleFormalName = theModulename />
				<cfset theQueryDataArguments.Enabled = False />
				<cfset theQueryDataArguments.Removed = False />
				<cfset InsertModule = application.SLCMS.Core.DataMgr.InsertRecord(tablename="#variables.Local.DataBaseTableName_ModuleManagement_Base#", data=theQueryDataArguments) />
			<cfelseif getModuleFromDB.RecordCount eq 1>
				<!--- found it so set up the flags for what it can do, etc --->
				<cfset variables.Local.Modules["#theModulename#"].Flags.Enabled_Global = getModuleFromDB.Enabled_Global />
				<cfset variables.Local.Modules["#theModulename#"].Flags.Enabled_subSiteList = getModuleFromDB.Enabled_subSiteList />
			<cfelse>
				<!--- oops! more than one, lets see why --->
			</cfif>

			<!---
			<cfdump var="#theEnabledDBModuleIDs#" label="theEnabledDBModuleIDs">
			--->
		<cfelse>	
			<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 64) />
			<cfset ret.error.ErrorText = ret.error.ErrorContext & ' No Module Name supplied' />
		</cfif>
		<cfcatch type="any">
			<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 128) />
			<cfset ret.error.ErrorText = ret.error.ErrorContext & ' Trapped. Site: #application.SLCMS.Config.base.SiteName#, error message was: #cfcatch.message#, error detail was: #cfcatch.detail#' />
			<cfset ret.error.ErrorExtra =  cfcatch.TagContext />
			<cfif isArray(ret.error.ErrorExtra) and StructKeyExists(ret.error.ErrorExtra[1], "Raw_Trace")>
				<cfset ret.error.ErrorText = ret.error.ErrorText & ", Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#" />
			</cfif>
			<cflog text='#ret.error.ErrorText# - ret.error.ErrorCode: #ret.error.ErrorCode# - Time: #DateFormat(Now(),"YYYYMMDD")#-#TimeFormat(now(),"HH:mm:ss")#'  file="#Application.SLCMS.Logging.theSiteLogName#" type="Error" application = "yes">
			<cfif application.SLCMS.Config.debug.debugmode>
				<cfoutput>#ret.error.ErrorContext#</cfoutput> Trapped - error dump:<br>
				<cfdump var="#cfcatch#">
			</cfif>
		</cfcatch>
	</cftry>	
	<!--- return the standard struct --->
	<cfreturn Ret  />
</cffunction>

<cffunction name="ChangeModuleEnableState" output="No" returntype="any" access="public" 
	displayname="(Dis)Enable Module"
	hint="enables or disables the specified module so it can(not) be used, globally or for a subSite"
	>
	<!--- this function needs.... --->
	<cfargument name="Modulename" type="string" required="true" hint="the formal name of the module to enable" />
	<cfargument name="Change" type="string" required="true" hint="the change to make, either enable or disable" />
	<cfargument name="subSite" type="string" default="Global" hint="what to change, either enable or disable" />

	<cfset var theModulename = trim(arguments.Modulename) />
	<cfset var theChange = trim(arguments.Change) />
	<cfset var thesubSite = trim(arguments.subSite) />
	<!--- some temp vars --->
	<cfset var theQueryDataArguments = StructNew() />	<!--- temp struct to compose the data clauses of the SQL query --->
	<cfset var theQueryWhereArguments = StructNew() />	<!--- temp struct to compose the where clauses of the SQL query --->
	<cfset var setModule = "" />
	<cfset var temp1 = "" />
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorContext = "System_ModuleManager CFC: ChangeModuleEnableState()" />
	<cfset ret.error.ErrorText = "" />
	<cfset ret.error.ErrorExtra = "" />
	<cfset ret.Data = "" />	<!--- and no data yet --->

	<cftry>
		<cfif theModulename neq "" and listFindNoCase(variables.Local.ModuleList_Available, theModulename) and theChange eq "Enable" or theChange eq "Disable">
			<cfif theChange eq "Enable" or theChange eq "Disable">
				<cfif thesubSite eq "Global">
					<!--- lets compare with the database and set things up as we need --->
					<!--- first locally --->
					<cfif theChange eq "Enable">
						<cfset variables.Local.Modules["#theModulename#"].Flags.Enabled_Global = True />
						<cfset theQueryDataArguments.Enabled_Global = True />
					<cfelse>
						<cfset variables.Local.Modules["#theModulename#"].Flags.Enabled_Global = False />
						<cfset theQueryDataArguments.Enabled_Global = False />
					</cfif>
					<!--- then the database --->
					<cfset theQueryWhereArguments.ModuleFormalName = theModulename />
					<cfset theQueryDataArguments.Removed = False />
					<cfset setModule = application.SLCMS.Core.DataMgr.UpdateRecords(tablename="#variables.Local.DataBaseTableName_ModuleManagement_Base#", data_set=theQueryDataArguments, data_where=theQueryWhereArguments) />
				<cfelseif ListFind(application.SLCMS.Core.PortalControl.GetFullSubSiteIDList(), thesubSite)>
					<cfif theChange eq "Enable">
						<cfset temp1 = variables.Local.Modules["#theModulename#"].Flags.Enabled_subSiteList />
						<cfset variables.Local.Modules["#theModulename#"].Flags.Enabled_subSiteList = ListAppend(temp1, thesubSite) />
					<cfelse>
						<cfset temp1 = ListFind(variables.Local.Modules["#theModulename#"].Flags.Enabled_subSiteList, thesubSite) />
						<cfset variables.Local.Modules["#theModulename#"].Flags.Enabled_subSiteList = ListDeleteAt(variables.Local.Modules["#theModulename#"].Flags.Enabled_subSiteList, temp1) />
					</cfif>
					<cfset theQueryWhereArguments.ModuleFormalName = theModulename />
					<cfset theQueryDataArguments.Enabled_subSiteList = variables.Local.Modules["#theModulename#"].Flags.Enabled_subSiteList />
					<cfset setModule = application.SLCMS.Core.DataMgr.UpdateRecords(tablename="#variables.Local.DataBaseTableName_ModuleManagement_Base#", data_set=theQueryDataArguments, data_where=theQueryWhereArguments) />
				<cfelse>	
					<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 16) />
					<cfset ret.error.ErrorText = ret.error.ErrorContext & ' Invalid subSite supplied' />
				</cfif>
			<cfelse>	
				<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 32) />
				<cfset ret.error.ErrorText = ret.error.ErrorContext & ' Invalid change command supplied' />
			</cfif>
		<cfelse>	
			<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 64) />
			<cfset ret.error.ErrorText = ret.error.ErrorContext & ' Invalid Module Name supplied' />
		</cfif>
		<cfcatch type="any">
			<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 128) />
			<cfset ret.error.ErrorText = ret.error.ErrorContext & ' Trapped. Site: #application.SLCMS.Config.base.SiteName#, error message was: #cfcatch.message#, error detail was: #cfcatch.detail#' />
			<cfset ret.error.ErrorExtra =  cfcatch.TagContext />
			<cfif isArray(ret.error.ErrorExtra) and StructKeyExists(ret.error.ErrorExtra[1], "Raw_Trace")>
				<cfset ret.error.ErrorText = ret.error.ErrorText & ", Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#" />
			</cfif>
			<cflog text='#ret.error.ErrorText# - ret.error.ErrorCode: #ret.error.ErrorCode# - Time: #DateFormat(Now(),"YYYYMMDD")#-#TimeFormat(now(),"HH:mm:ss")#'  file="#Application.SLCMS.Logging.theSiteLogName#" type="Error" application = "yes">
			<cfif application.SLCMS.Config.debug.debugmode>
				<cfoutput>#ret.error.ErrorContext#</cfoutput> Trapped - error dump:<br>
				<cfdump var="#cfcatch#">
			</cfif>
		</cfcatch>
	</cftry>	
	<!--- return the standard struct --->
	<cfreturn Ret  />
</cffunction>

<cffunction name="getAvailableModulesFlags" output="No" returntype="struct" access="public"
	displayname="get Available Module's Flags"
	hint="returns struct of all available modules and their flags"
	>

	<!--- vars that will get filled as we go --->
	<cfset var lcntr = 0 />	<!--- temp loop counter --->
	<cfset var thisModule = "" />	<!--- temp/throwaway var --->
	<cfset var tempa = ArrayNew(1) />	<!--- temp/throwaway array --->
	<cfset var temps = StructNew() />	<!--- temp/throwaway structure --->
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorContext = "System_ModuleManager CFC: getAvailableModulesFlags()" />
	<cfset ret.error.ErrorText = "" />
	<cfset ret.error.ErrorExtra = "" />
	<cfset ret.Data = StructNew() />	<!--- and no data yet --->
	<cfset ret.Data.ModuleList = variables.Local.ModuleList_Available />	<!---  what modules we can use --->

	<cftry>
	<!--- just grab the list of available modules, make it into a struct and fill with the flags struct for each module --->
	<cfloop list="#variables.Local.ModuleList_Available#" index="thisModule">
		<cfset ret.Data["#thisModule#"] = StructNew() />
		<cfset ret.Data["#thisModule#"].FriendlyName = variables.Local.Modules["#thisModule#"].ModuleNaming.FriendlyName />
		<cfset ret.Data["#thisModule#"].Flags = variables.Local.Modules["#thisModule#"].Flags />
	</cfloop>
	<cfcatch type="any">
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 128) />
		<cfset ret.error.ErrorText = ret.error.ErrorContext & ' Trapped. Site: #application.SLCMS.Config.base.SiteName#, error message was: #cfcatch.message#, error detail was: #cfcatch.detail#' />
		<cfset ret.error.ErrorExtra =  cfcatch.TagContext />
		<cfif isArray(ret.error.ErrorExtra) and StructKeyExists(ret.error.ErrorExtra[1], "Raw_Trace")>
			<cfset ret.error.ErrorText = ret.error.ErrorText & ", Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#" />
		</cfif>
		<cflog text='#ret.error.ErrorText# - ret.error.ErrorCode: #ret.error.ErrorCode# - Time: #DateFormat(Now(),"YYYYMMDD")#-#TimeFormat(now(),"HH:mm:ss")#'  file="#Application.SLCMS.Logging.theSiteLogName#" type="Error" application = "yes">
		<cfif application.SLCMS.Config.debug.debugmode>
			<cfoutput>#ret.error.ErrorContext#</cfoutput> Trapped - error dump:<br>
			<cfdump var="#cfcatch#">
		</cfif>
	</cfcatch>
	</cftry>
	<!--- return our data structure --->
	<cfreturn ret  />
</cffunction>

<cffunction name="SystemHasModules" output="No" returntype="boolean" access="public"
	displayname="System Has Modules"
	hint="Flags if there are modules available to use"
	>
		<cfreturn ListLen(variables.Local.ModuleList_Available) />	<!--- zero/False for none othrwise return how many/True --->
	<!--- 
	<cfif variables.Local.ModuleList_Available neq "">
		<cfreturn True />
	<cfelse>
		<cfreturn False />
	</cfif>
	 --->
</cffunction>

<cffunction name="getQuickAvailableModulesList" output="No" returntype="string" access="public"
	displayname="get List of Modules"
	hint="returns the variables.Local.ModuleList_Available, no error handling"
				>
	<cfreturn variables.Local.ModuleList_Available  />
</cffunction>

<cffunction name="ReInitModulesAfter" output="No" returntype="struct" access="public"
	displayname="ReInitialise the Modules After"
	hint="ReInitialise dependent Modules after a system action that has happened"
	>
	<!--- this function needs.... --->
	<cfargument name="InitiatingModule" type="string" default="" hint="Core or a Module Name" />
	<cfargument name="InitiatingFunction" type="string" default="" hint="Changing Function/CFC" />
	<cfargument name="Action" type="string" default="" hint="what changed" />

	<!--- now all of the var declarations, first the arguments which need manipulation --->
	<cfset var theInitiatingModule = trim(arguments.InitiatingModule) />
	<cfset var theInitiatingFunction = trim(arguments.InitiatingFunction) />
	<cfset var theAction = trim(arguments.Action) />
	<!--- now vars that will get filled as we go --->
	<cfset var thisLevel = 0 />	<!--- temp loop counter --->
	<cfset var thisModule = StructNew() />	<!--- temp/throwaway structure --->
	<cfset var thisReInitList = "" />	<!--- temp/throwaway list --->
	<cfset var ModuleInitGet = StructNew() />	<!--- temp/throwaway struct --->
	<cfset var temps = "" />
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorContext = "System_ModuleManager CFC: ReInitModulesAfter()" />
	<cfset ret.error.ErrorText = "" />
	<cfset ret.error.ErrorExtra = "" />
	<cfset ret.Data = "" />	<!--- and no data yet --->

		<!--- validation --->
	<cfif theInitiatingModule neq "">
		<cfif (theInitiatingModule eq "Core" and ListFindNoCase(variables.Local.CoreFunctionsReInitGeneratorList , theInitiatingFunction)) or (theInitiatingModule neq "Core" and ListFindNoCase(variables.Local.ModuleList_Available , theInitiatingModule))>
			<cfif theAction neq "">
				<!--- validated so go for it --->
				<cftry>
				<cfset temps = LogIt(LogType="CFC_Init", LogString="System_ModuleManager ReInitModulesAfter() Started") />
				<!---
				<cflog text='ReInitModulesAfter Started - Time: #DateFormat(Now(),"YYYYMMDD")#-#TimeFormat(now(),"HH:mm:ss.L")#'  file="#Application.SLCMS.Logging.theSiteLogName#" type="Information" application="yes">
				--->
				<!--- 
				We have an array of modules in init order so lets roll thru them all looking for this action and reinit() if we find any
				we do this from the top down in the way we have built this stack so they reinit in the correct sequence
				 --->
				<cfloop from="#ArrayLen(variables.Local.ModuleSort)#" to="1" index="thisLevel" step="-1">	<!--- step down through array --->
					<cfloop collection="#variables.Local.ModuleSort[thisLevel]#" item="thisModule">	<!--- loop over modules at this level --->
						<cfif theInitiatingModule eq "Core">
							<cfset thisReInitList = variables.Local.ModuleSort[thisLevel]["#thisModule#"].ReInitAfterList_Core />
						<cfelse>
							<cfset thisReInitList = variables.Local.ModuleSort[thisLevel]["#thisModule#"].ReInitAfterList_Module />
						</cfif>
						<cfif ListFindNoCase(thisReInitList, theInitiatingFunction)>
							<!--- this module is dependent on this action so reinit it --->
							<cfset ModuleInitGet = StructNew() />	<!--- just in case clear out junk from previous loops --->
							<cftry>
								<cfinvoke component="#application.SLCMS.Modules['#thisModule#'].Paths.ModuleRootURLpath#ModuleController" method="ReInitAfter" returnvariable="ModuleInitGet">
									<cfinvokeargument name="InitiatingFunction" value="#theInitiatingFunction#">
									<cfinvokeargument name="Action" value="#theAction#">
								</cfinvoke>
							<cfcatch>
								<!--- ToDo: error handler if reinitafter failed, or there wasn't one! --->
								<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 64) />
								<cfset ret.error.ErrorText = ret.error.ErrorText & "Module ReInitAfter method call Trapped!<br>" />
								<cfset ret.error.ErrorExtra =  cfcatch.TagContext />
								<cfif isArray(ret.error.ErrorExtra) and StructKeyExists(ret.error.ErrorExtra[1], "Raw_Trace")>
									<cfset ret.error.ErrorText = ret.error.ErrorText & ", Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#" />
								</cfif>
								<cflog text='#ret.error.ErrorText# - ret.error.ErrorCode: #ret.error.ErrorCode# - Time: #DateFormat(Now(),"YYYYMMDD")#-#TimeFormat(now(),"HH:mm:ss")#'  file="#Application.SLCMS.Logging.theSiteLogName#" type="Error" application = "yes">
								<cfif application.SLCMS.Config.debug.debugmode>
									<cfoutput>#ret.error.ErrorContext#</cfoutput> Trapped - error dump:<br>
									<cfdump var="#cfcatch#">
								</cfif>
							</cfcatch>
							</cftry>
						</cfif>
					</cfloop>
				</cfloop>
				<cflog text='ReInitModulesAfter Finished - Time: #DateFormat(Now(),"YYYYMMDD")#-#TimeFormat(now(),"HH:mm:ss.L")#'  file="#Application.SLCMS.Logging.theSiteLogName#" type="Information" application="yes">
				<cfcatch type="any">
					<cfset ret.error = TakeErrorCatch(RetErrorStruct=ret.error, CatchStruct=cfcatch) />
		<!---
					<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 128) />
					<cfset ret.error.ErrorText = ret.error.ErrorContext & ' Trapped. Site: #application.SLCMS.Config.base.SiteName#, error message was: #cfcatch.message#, error detail was: #cfcatch.detail#' />
					<cfset ret.error.ErrorExtra =  cfcatch.TagContext />
					<cfif isArray(ret.error.ErrorExtra) and StructKeyExists(ret.error.ErrorExtra[1], "Raw_Trace")>
						<cfset ret.error.ErrorText = ret.error.ErrorText & ", Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#" />
					</cfif>
					<cflog text='#ret.error.ErrorText# - ret.error.ErrorCode: #ret.error.ErrorCode# - Time: #DateFormat(Now(),"YYYYMMDD")#-#TimeFormat(now(),"HH:mm:ss")#'  file="#Application.SLCMS.Logging.theSiteLogName#" type="Error" application = "yes">
					<cfif application.SLCMS.Config.debug.debugmode>
						<cfoutput>#ret.error.ErrorContext#</cfoutput> Trapped - error dump:<br>
						<cfdump var="#cfcatch#">
					</cfif>
					--->
				</cfcatch>
				</cftry>
			<cfelse>
				<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 4) />
				<cfset ret.error.ErrorText = ret.error.ErrorText & "Oops! No Action supplied<br>" />
			</cfif>	<!--- end: check action param --->
		<cfelse>
			<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 2) />
			<cfset ret.error.ErrorText = ret.error.ErrorText & "Oops! Bad module name supplied<br>" />
		</cfif>	<!--- end: check for legit module --->
	<cfelse>
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 1) />
		<cfset ret.error.ErrorText = ret.error.ErrorText & "Oops! No module name supplied<br>" />
	</cfif>	<!--- end: check for legit module --->

	<cfset temps = LogIt(LogType="CFC_Init", LogString="System_ModuleManager ReInitModulesAfter() Finished #ret.error.ErrorText#") />
	<!--- return our data structure --->
	<cfreturn ret  />
</cffunction>

<cffunction name="callModuleCoreAPIcfc" output="No" returntype="struct" access="public"
	displayname="call Module Core API CFC"
	hint="calls a Module's CoreAPI CFC and returns whatever it does"
	>
	<!--- this function needs.... --->
	<cfargument name="Module" type="string" default="" hint="Module Formal Name" />
	<cfargument name="Method" type="string" default="" hint="the method we want to call in the module" />
	<cfargument name="MethodArguments" type="struct" default="" hint="what we want to tell it" />
	<cfargument name="subSiteID" type="string" default="" hint="which subSite we are working in" />
	<cfargument name="UserID" type="string" default="" hint="the user's ID if we have a logged in one" />

	<!--- now all of the var declarations, first the incoming arguments --->
	<cfset var theModule = trim(arguments.Module) />
	<cfset var theMethod = trim(arguments.Method) />
	<cfset var thesubSiteID = trim(arguments.subSiteID) />
	<cfset var theUserID = trim(arguments.UserID) />
	<!--- now vars that will get filled as we go --->
	<cfset var theCoreAPIcfcName = "" />
	<cfset var theComponent = "" />	<!--- the name of the module's api cfc --->
	<cfset var theMethodArguments = {} />
	<cfset var retAPIcall = {} />	<!--- will be the return from the module's api call --->
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret["error"] = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorContext = "System_ModuleManager CFC: callModuleCoreAPIcfc()" />
	<cfset ret.error.ErrorText = "" />
	<cfset ret.error.ErrorExtra = "" />
	<cfset ret["Data"] = {} />	<!--- blank data return struct --->

	<cftry>
		<!--- validation --->
		<cfif theModule neq "">
			<cfif theMethod neq "">
				<cfif ListFindNoCase(variables.Local.ModuleList_Available, theModule)>
					<!--- semi validated so go for it --->
					<cfif StructKeyExists(variables.Local.Modules["#theModule#"].CoreAdminAPI, "CoreAPIcfcName")>
						<cfset theCoreAPIcfcName = variables.Local.Modules["#theModule#"].CoreAdminAPI.CoreAPIcfcName />
						<cfset theComponent = variables.Local.modules['#theModule#'].Paths.CFCroot & theCoreAPIcfcName />
						<cfif IsStruct(arguments.MethodArguments)>
							<cfset theMethodArguments = arguments.MethodArguments />
						</cfif>
						<cftry>
							<!--- call the CFC --->
							<cfinvoke component="#theComponent#" method="#theMethod#" returnvariable="retAPIcall" argumentCollection="#arguments.MethodArguments#">
								<cfinvokeargument name="subSiteID" value="#thesubSiteID#">
								<cfinvokeargument name="UserID" value="#theUserID#">
							</cfinvoke>
							<cfif retAPIcall.error.errorcode eq 0>
								<cfset ret.Data = retAPIcall.data />
								<cfset ret.error.ErrorText = retAPIcall.error.errortext />	<!--- might have stuff in it the the caller needs to know --->
							<cfelse>
								<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 16) />
								<cfset ret.error.ErrorText = ret.error.ErrorText & retAPIcall.error.errortext />
								<cfset ret.Data.Status = retAPIcall.error.errortext />
							</cfif>
						<cfcatch type="any">
							<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 64) />
							<cfset ret.error.ErrorText = ret.error.ErrorContext & ' Method call failed. Method called was: #theMethod#; CFC called was: #theComponent#' />
							<cfset ret.error.ErrorExtra =  cfcatch.TagContext />
							<cflog text='#ret.error.ErrorText# - ret.error.ErrorCode: #ret.error.ErrorCode# - Time: #DateFormat(Now(),"YYYYMMDD")#-#TimeFormat(now(),"HH:mm:ss")#'  file="#Application.SLCMS.Logging.theSiteLogName#" type="Error" application = "yes">
							<cfif application.SLCMS.Config.debug.debugmode>
								<cfoutput>#ret.error.ErrorContext#</cfoutput> Module API Invocation Trapped - error dump:<br>
								<cfdump var="#cfcatch#">
							</cfif>
						</cfcatch>
						</cftry>
					</cfif>
				<cfelse>
					<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 4) />
					<cfset ret.error.ErrorText = ret.error.ErrorText & "Oops! Invalid Module Name supplied<br>" />
				</cfif>
			<cfelse>
				<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 2) />
				<cfset ret.error.ErrorText = ret.error.ErrorText & "Oops! No Method Name supplied<br>" />
			</cfif>	<!--- end: check method --->
		<cfelse>
			<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 1) />
			<cfset ret.error.ErrorText = ret.error.ErrorText & "Oops! Bad no name supplied<br>" />
		</cfif>	<!--- end: check for legit module --->
	<cfcatch type="any">
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 128) />
		<cfset ret.error.ErrorText = ret.error.ErrorContext & ' Trapped. Site: #application.SLCMS.Config.base.SiteName#, error message was: #cfcatch.message#, error detail was: #cfcatch.detail#' />
		<cfset ret.error.ErrorExtra =  cfcatch.TagContext />
		<cfif isArray(ret.error.ErrorExtra) and StructKeyExists(ret.error.ErrorExtra[1], "Raw_Trace")>
			<cfset ret.error.ErrorText = ret.error.ErrorText & ", Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#" />
		</cfif>
		<cflog text='#ret.error.ErrorText# - ret.error.ErrorCode: #ret.error.ErrorCode# - Time: #DateFormat(Now(),"YYYYMMDD")#-#TimeFormat(now(),"HH:mm:ss")#'  file="#Application.SLCMS.Logging.theSiteLogName#" type="Error" application = "yes">
		<cfif application.SLCMS.Config.debug.debugmode>
			<cfoutput>#ret.error.ErrorContext#</cfoutput> Trapped - error dump:<br>
			<cfdump var="#cfcatch#">
		</cfif>
	</cfcatch>
	</cftry>

	<!--- return our data structure --->
	<cfreturn ret  />
</cffunction>

<cffunction name="callQuickModuleCoreAPIcfc" output="No" returntype="string" access="public"
	displayname="call Quick Module Core API CFC"
	hint="calls a Module's CoreAPI CFC as a quick and returns the string it does"
	>
	<!--- this function needs.... --->
	<cfargument name="Module" type="string" default="" hint="Module Formal Name" />
	<cfargument name="Method" type="string" default="" hint="the method we want to call in the module" />
	<cfargument name="MethodArguments" type="struct" default="" hint="what we want to tell it" />
	<cfargument name="subSiteID" type="string" default="" hint="which subSite we are working in" />
	<cfargument name="UserID" type="string" default="" hint="the user's ID if we have a logged in one" />

	<!--- now all of the var declarations, first the incoming arguments --->
	<cfset var theModule = trim(arguments.Module) />
	<cfset var theMethod = trim(arguments.Method) />
	<cfset var thesubSiteID = trim(arguments.subSiteID) />
	<cfset var theUserID = trim(arguments.UserID) />
	<!--- now vars that will get filled as we go --->
	<cfset var theCoreAPIcfcName = "" />
	<cfset var theComponent = "" />	<!--- the name of the module's api cfc --->
	<cfset var theMethodArguments = {} />
	<cfset var retAPIcall = {} />	<!--- will be the return from the module's api call --->
	<cfset var ret = "" />	<!--- this is the return to the caller --->

	<cftry>
		<!--- validation --->
		<cfif theModule neq "">
			<cfif theMethod neq "">
				<cfif ListFindNoCase(variables.Local.ModuleList_Available, theModule)>
					<!--- semi validated so go for it --->
					<cfif StructKeyExists(variables.Local.Modules["#theModule#"].CoreAdminAPI, "CoreAPIcfcName")>
						<cfset theCoreAPIcfcName = variables.Local.Modules["#theModule#"].CoreAdminAPI.CoreAPIcfcName />
						<cfset theComponent = variables.Local.modules['#theModule#'].Paths.CFCroot & theCoreAPIcfcName />
						<cfif IsStruct(arguments.MethodArguments)>
							<cfset theMethodArguments = arguments.MethodArguments />
						</cfif>
						<cftry>
							<!--- call the CFC --->
							<cfinvoke component="#theComponent#" method="#theMethod#" returnvariable="retAPIcall" argumentCollection="#arguments.MethodArguments#">
								<cfinvokeargument name="subSiteID" value="#thesubSiteID#">
								<cfinvokeargument name="UserID" value="#theUserID#">
							</cfinvoke>
							<cfset ret = retAPIcall />
						<cfcatch type="any">
							<cflog text='Method call failed. Method called was: #theMethod#; CFC called was: #theComponent# - Time: #DateFormat(Now(),"YYYYMMDD")#-#TimeFormat(now(),"HH:mm:ss")#'  file="#Application.SLCMS.Logging.theSiteLogName#" type="Error" application = "yes">
							<cfif application.SLCMS.Config.debug.debugmode>
								callQuickModuleCoreAPIcfc Module API Invocation Trapped - error dump:<br>
								<cfdump var="#cfcatch#">
							</cfif>
						</cfcatch>
						</cftry>
					</cfif>
				</cfif>
			</cfif>	<!--- end: check method --->
		</cfif>	<!--- end: check for legit module --->
	<cfcatch type="any">
		<cflog text='System_ModuleManager CFC: callQuickModuleCoreAPIcfc()  Trapped. Site: #application.SLCMS.Config.base.SiteName#, error message was: #cfcatch.message#, error detail was: #cfcatch.detail# - Time: #DateFormat(Now(),"YYYYMMDD")#-#TimeFormat(now(),"HH:mm:ss")#'  file="#Application.SLCMS.Logging.theSiteLogName#" type="Error" application = "yes">
		<cfif application.SLCMS.Config.debug.debugmode>
			callQuickModuleCoreAPIcfc Trapped - error dump:<br>
			<cfdump var="#cfcatch#">
		</cfif>
	</cfcatch>
	</cftry>

	<!--- return our data structure --->
	<cfreturn ret  />
</cffunction>

<cffunction name="getQuickPreProcessorIncludeList" output="No" returntype="string" access="public"
	displayname="getQuick PreProcessor Include List"
	hint="returns list of the preprocessor Include files that need to be Included before content display"
	>
	<!--- this function needs.... --->
	<cfargument name="Module" type="string" required="true" hint="Module Formal Name" />

	<!--- now all of the var declarations, first the incoming arguments --->
	<cfset var theModule = trim(arguments.Module) />
	<!--- now vars that will get filled as we go --->
	<cfset var ret = "" />	<!--- this is the return string to the caller as this is a Quick call --->

	<cftry>
		<!--- validation --->
		<cfif theModule neq "">
				<cfif ListFindNoCase(variables.Local.ModuleList_Available, theModule)>
					<!--- semi validated so go for it --->
					<cfset ret = variables.Local.Modules["#theModule#"].CoreAdminAPI.PreProcessor.IncludeList />
				</cfif>
		</cfif>	<!--- end: check for legit module --->
	<cfcatch type="any">
		<cflog text='System_ModuleManager CFC: getQuickPreProcessorIncludeList()  Trapped. Site: #application.SLCMS.Config.base.SiteName#, error message was: #cfcatch.message#, error detail was: #cfcatch.detail# - Time: #DateFormat(Now(),"YYYYMMDD")#-#TimeFormat(now(),"HH:mm:ss")#'  file="#Application.SLCMS.Logging.theSiteLogName#" type="Error" application = "yes">
		<cfif application.SLCMS.Config.debug.debugmode>
			System_ModuleManager CFC: getQuickPreProcessorIncludeList() Trapped - error dump:<br>
			<cfdump var="#cfcatch#">
		</cfif>
	</cfcatch>
	</cftry>

	<!--- return our data structure --->
	<cfreturn ret  />
</cffunction>

<cffunction name="getQuickPreProcessorTagList" output="No" returntype="string" access="public"
	displayname="getQuick PreProcessor Tag List"
	hint="returns list of the preprocessor tags that need to be called before content display"
	>
	<!--- this function needs.... --->
	<cfargument name="Module" type="string" required="true" hint="Module Formal Name" />

	<!--- now all of the var declarations, first the incoming arguments --->
	<cfset var theModule = trim(arguments.Module) />
	<!--- now vars that will get filled as we go --->
	<cfset var ret = "" />	<!--- this is the return string to the caller as this is a Quick call --->

	<cftry>
		<!--- validation --->
		<cfif theModule neq "">
				<cfif ListFindNoCase(variables.Local.ModuleList_Available, theModule)>
					<!--- semi validated so go for it --->
					<cfset ret = variables.Local.Modules["#theModule#"].CoreAdminAPI.PreProcessor.TagList />
				</cfif>
		</cfif>	<!--- end: check for legit module --->
	<cfcatch type="any">
		<cflog text='System_ModuleManager CFC: getQuickPreProcessorTagList()  Trapped. Site: #application.SLCMS.Config.base.SiteName#, error message was: #cfcatch.message#, error detail was: #cfcatch.detail# - Time: #DateFormat(Now(),"YYYYMMDD")#-#TimeFormat(now(),"HH:mm:ss")#'  file="#Application.SLCMS.Logging.theSiteLogName#" type="Error" application = "yes">
		<cfif application.SLCMS.Config.debug.debugmode>
			System_ModuleManager CFC: getQuickPreProcessorTagList() Trapped - error dump:<br>
			<cfdump var="#cfcatch#">
		</cfif>
	</cfcatch>
	</cftry>

	<!--- return our data structure --->
	<cfreturn ret  />
</cffunction>

<cffunction name="getModuleContentTypeSelector" output="No" returntype="struct" access="public"
	displayname="get Module Content Type Selector"
	hint="gets the config data for the page structure admin to decide what to present to select content for a module"
	>
	<!--- this function needs.... --->
	<cfargument name="Module" type="string" default="" hint="Module Formal Name" />
	<cfargument name="ContentType" type="string" default="" hint="what was chosen in the content type select drop down" />
	<cfargument name="subSiteID" type="string" default="" hint="which subSite we are working in" />
	<cfargument name="UserID" type="string" default="" hint="the user's ID if we have a logged in one" />

	<!--- now all of the var declarations, first the arguments which need manipulation --->
	<cfset var theModule = trim(arguments.Module) />
	<cfset var theContentType = trim(arguments.ContentType) />
	<cfset var thesubSiteID = trim(arguments.subSiteID) />
	<cfset var theUserID = trim(arguments.UserID) />
	<!--- now vars that will get filled as we go --->
	<cfset var strContentType = "" />	<!--- will have the contentType's config struct --->
	<cfset var theCFCname = "" />	<!--- the name of the module's api cfc --->
	<cfset var theMethodName = "" />	<!--- the name of the module's api cfc --->
	<cfset var retAPIcall = {} />	<!--- will be the return from the module's api call --->
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret["error"] = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorContext = "System_ModuleManager CFC: getModuleContentTypeSelector()" />
	<cfset ret.error.ErrorText = "" />
	<cfset ret.error.ErrorExtra = "" />
	<cfset ret["Data"] = {} />	<!--- blank data return struct --->
	<cfset ret.Data.SelectDisplayMode = "" />
	<cfset ret.Data.PopURL = "" />
	<cfset ret.Data.OptionArray = [] />	<!--- empty display array for selectors --->

		<!--- validation --->
	<cfif theModule neq "" and ListFindNoCase(variables.Local.ModuleList_Available , theModule)>
		<cfif theContentType neq "">
			<cfif ListFindNoCase(variables.Local.ModuleList_Available, theModule)>
				<!--- semi validated so go for it --->
				<cftry>
					<cfif StructKeyExists(variables.Local.Modules["#theModule#"].CoreAdminAPI.PageProperties.ContentSelectors, "#theContentType#")>
						<cfset strContentType = variables.Local.Modules["#theModule#"].CoreAdminAPI.PageProperties.ContentSelectors["#theContentType#"] />
						<!--- load the base config --->
						<cfset ret.Data.SelectDisplayMode = strContentType.DisplayType />
						<cfset ret.Data.ModuleSelectedHint = strContentType.ModuleSelectedHintText />
						<!--- and then ask the module what to send in terms of data, if anything --->
						<cfif strContentType.ConnectorType eq "Page">
							<!--- a page is easy as the page code will handle everything --->
							<cfset ret.Data.PopURL = application.SLCMS.Modules["#theModule#"].ModuleAdmin.AdminRootURL_Abs />
							<cfset ret.Data.PopURL = ret.Data.PopURL & strContentType.ConnectorPath />
							<cfset ret.Data.ModuleWhatSelectionHint = strContentType.ModuleWhatSelectionHint />
							<cfset ret.Data.ModuleSelectionHint = "" />
						<cfelseif strContentType.ConnectorType eq "CFC">
							<!--- with a CFC we need to grab the data and pass is back in a form that the PageStructure Admin page can handle --->
							<cfset theCFCname = strContentType.CFC />
							<cfset theMethodName = strContentType.Method />
							<cfinvoke component="#variables.Local.modules['#theModule#'].Paths.CFCroot#.#theCFCname#" method="#theMethodName#" returnvariable="retAPIcall">
								<cfinvokeargument name="subSiteID" value="#thesubSiteID#">
								<cfinvokeargument name="UserID" value="#theUserID#">
							</cfinvoke>
							<cfif retAPIcall.error.errorcode eq 0>
								<cfset ret.Data.SelectDisplayMode = retAPIcall.data.SelectDisplayMode />
								<cfset ret.Data.OptionArray = retAPIcall.data.SelectorArray />
								<cfset ret.Data.ModuleWhatSelectionHint = retAPIcall.data.ModuleWhatSelectionHint />
								<cfset ret.Data.ModuleSelectionHint = retAPIcall.data.ModuleSelectionHintText />
							<cfelse>
								<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 16) />
								<cfset ret.error.ErrorText = ret.error.ErrorText & retAPIcall.error.errortext />
								<cfset ret.Data.Status = retAPIcall.error.errortext />
							</cfif>
						</cfif>
					<cfelse>
						<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 8) />
						<cfset ret.error.ErrorText = ret.error.ErrorText & "Oops! Bad ContentType supplied<br>" />
					</cfif>
				<cfcatch type="any">
					<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 128) />
					<cfset ret.error.ErrorText = ret.error.ErrorContext & ' Trapped. Site: #application.SLCMS.Config.base.SiteName#, error message was: #cfcatch.message#, error detail was: #cfcatch.detail#' />
					<cfset ret.error.ErrorExtra =  cfcatch.TagContext />
					<cfif isArray(ret.error.ErrorExtra) and StructKeyExists(ret.error.ErrorExtra[1], "Raw_Trace")>
						<cfset ret.error.ErrorText = ret.error.ErrorText & ", Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#" />
					</cfif>
					<cflog text='#ret.error.ErrorText# - ret.error.ErrorCode: #ret.error.ErrorCode# - Time: #DateFormat(Now(),"YYYYMMDD")#-#TimeFormat(now(),"HH:mm:ss")#'  file="#Application.SLCMS.Logging.theSiteLogName#" type="Error" application = "yes">
					<cfif application.SLCMS.Config.debug.debugmode>
						<cfoutput>#ret.error.ErrorContext#</cfoutput> Trapped - error dump:<br>
						<cfdump var="#cfcatch#">
					</cfif>
				</cfcatch>
				</cftry>
			<cfelse>
				<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 4) />
				<cfset ret.error.ErrorText = ret.error.ErrorText & "Oops! Invalid Module Name supplied<br>" />
			</cfif>
		<cfelse>
			<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 2) />
			<cfset ret.error.ErrorText = ret.error.ErrorText & "Oops! No ContentType supplied<br>" />
		</cfif>	<!--- end: check action param --->
	<cfelse>
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 1) />
		<cfset ret.error.ErrorText = ret.error.ErrorText & "Oops! Bad module name supplied<br>" />
	</cfif>	<!--- end: check for legit module --->

	<!--- return our data structure --->
	<cfreturn ret  />
</cffunction>

<cffunction name="getVariablesScope"output="No" returntype="struct" access="public"  
	displayname="get Variables"
	hint="gets the specified variables structure or the entire variables scope"
	>
	<cfargument name="Struct" type="string" required="No" default="" hint="struct to return, defaults to 'all'">	

	<cfif len(arguments.Struct) and StructKeyExists(variables, "#arguments.Struct#")>
		<cfreturn variables.local["#arguments.Struct#"] />
	<cfelse>
		<cfreturn variables.local />
	</cfif>
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
	<cfset error.ErrorContext = "System_ModuleManager " />
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
		<cflog text='TakeErrorCatch: Error Catch Caught: #error.ErrorText# - error.ErrorCode: #error.ErrorCode# - Time: #DateFormat(Now(),"YYYYMMDD")#-#TimeFormat(now(),"HH:mm:ss")#'  file="#Application.SLCMS.Logging.theSiteLogName#" type="Error" application = "yes">
		<cfif application.SLCMS.Config.debug.debugmode>
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
	<cfset ret.error.ErrorContext = "System_ModuleManager CFC: LogIt()" />
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
			<cflog text='#ret.error.ErrorText# - ret.error.ErrorCode: #ret.error.ErrorCode# - Time: #DateFormat(Now(),"YYYYMMDD")#-#TimeFormat(now(),"HH:mm:ss")#'  file="#Application.SLCMS.Logging.theSiteLogName#" type="Error" application = "yes">
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

</cfcomponent>
