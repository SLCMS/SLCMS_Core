<cfcomponent extends="controllers.Controller">
	
	<cffunction name= "init">
		<!--- code development switches --->
  	<cfif get("environment") eq "design">
			<cfset variables.CodeDevMode = True />	<!--- speeds up dev by using a set of predefined values for the wizard entry fields to save typing every time --->
  	<cfelse>
			<cfset variables.CodeDevMode = False />	<!--- standard 'user enters everything' mode --->
  	</cfif>
		<!--- set up a few persistant things on the way in. --->
		<cfset variables.StartStep = 1 />
		<!--- set up paths, we do it here so there is one place to change if a non-standard setup is being used, these are the defaults --->
		<cfset variables.Paths = StructNew() />
		<cfset variables.Paths.theRootURL = application.SLCMS.Paths_Common.ContentRootURL />
		<cfset variables.Paths.SLCMSBasePath = "#application.wheels.webpath#SLCMS/" />
		<cfset variables.Paths.theSLCMS3rdPartyPath = "#application.SLCMS.config.Base.SLCMS3rdPartyPath_Abs#" />
		<cfset variables.Paths.JqueryPath = "#variables.Paths.theSLCMS3rdPartyPath#jQuery/jquery.min.js" />
		<cfset variables.Paths.DataMgr_Phys = "#variables.Paths.theSLCMS3rdPartyPath#DataMgr/DataMgr.cfc" />
		<cfset variables.Paths.DataMgrDotted = "SLCMS.3rdParty.DataMgr.DataMgr" />
		<cfset variables.Paths.HelpBasePath = application.SLCMS.Paths_Common.HelpBasePath_Abs />
		<cfset variables.Paths.HelpGraphicsPath = "#variables.Paths.HelpBasePath#Graphics/" />
		<cfset variables.Paths.HelpTipJsPath = application.SLCMS.Paths_Common.HelpJs_Abs />
		<cfset variables.Paths.Form2WizJsPath = "#variables.Paths.HelpBasePath#formToWizard.js" />
		<cfset variables.Paths.installAssistPath = "#variables.Paths.SLCMSBasePath#installAssist/" />
		<cfset variables.Paths.WizGraphicsFolderPath = "#variables.Paths.installAssistPath#Graphics/" />
		<cfset variables.Paths.WizTipsPath = "#variables.Paths.HelpBasePath#Tips/InitialInstallationWizard/" />
		<cfset variables.Paths.AJAXURL = application.SLCMS.Paths_Admin.ajaxURL_ABS />
		<cfset variables.Paths.LogFile = "#application.SLCMS.config.startup.LogPath#InstallationWizard.log" />
		<!--- set up all of our messages --->
		<cfset variables.BaseFlow = StructNew() />
		<cfset variables.BaseFlow.BottomStep = 1 />
		<cfset variables.BaseFlow.TopStep = 1 />
		<cfset variables.BaseFlow.StepTexts["Step_1"] = StructNew() />
		<cfset variables.BaseFlow.StepTexts["Step_1"].YesFirst = "Yes, this is the first time. We have just installed the site" />
		<cfset variables.BaseFlow.StepTexts["Step_1"].NotFirst = "No, the site has run before or we have run this wizard before" />
		<cfset variables.MainFlow = StructNew() />
		<cfset variables.MainFlow.BottomStep = 1 />
		<cfset variables.MainFlow.TopStep = 5 />
		<cfset variables.MainFlow.StepTexts = StructNew() />
		<cfset variables.MainFlow.StepTexts["Step_1"] = StructNew() />
		<cfset variables.MainFlow.StepTexts["Step_1"].Submit = "Start the Setup Wizard" />
		<cfset variables.MainFlow.StepTexts["Step_1"].Back1Step = "Back to Start Page" />
		<cfset variables.MainFlow.StepTexts["Step_1"].Forward1Step = "Start the Setup Wizard" />
		<cfset variables.MainFlow.StepTexts["Step_2"] = StructNew() />
		<cfset variables.MainFlow.StepTexts["Step_2"].Submit = "Review Entries" />
		<cfset variables.MainFlow.StepTexts["Step_2"].Back1Step = "Back to Start Page" />
		<cfset variables.MainFlow.StepTexts["Step_2"].Forward1Step = "Next" />
		<cfset variables.MainFlow.StepTexts["Step_3"] = StructNew() />
		<cfset variables.MainFlow.StepTexts["Step_3"].Submit = "Set Up System" />
		<cfset variables.MainFlow.StepTexts["Step_3"].Back1Step = "Back to Settings Entry" />
		<cfset variables.MainFlow.StepTexts["Step_3"].Forward1Step = "Next" />
		<cfset variables.MainFlow.StepTexts["Step_4"] = StructNew() />
		<cfset variables.MainFlow.StepTexts["Step_4"].Submit = "Set Up SuperUser" />
		<cfset variables.MainFlow.StepTexts["Step_4"].Back1Step = "Back to Settings Review" />
		<cfset variables.MainFlow.StepTexts["Step_4"].Forward1Step = "Continue" />
		<cfset variables.MainFlow.StepTexts["Step_5"] = StructNew() />
		<cfset variables.MainFlow.StepTexts["Step_5"].Submit = "Start the site" />
		<cfset variables.MainFlow.StepTexts["Step_5"].Back1Step = "Back to Settings Entry" />
		<cfset variables.MainFlow.StepTexts["Step_5"].Forward1Step = "Start the site" />
		<cfset variables.SecondFlow = StructNew() />
		<cfset variables.SecondFlow.BottomStep = 1 />
		<cfset variables.SecondFlow.TopStep = 2 />
		<cfset variables.SecondFlow.StepTexts = StructNew() />
		<cfset variables.SecondFlow.StepTexts["Step_1"] = StructNew() />
		<cfset variables.SecondFlow.StepTexts["Step_1"].TryAgain = "It should be OK. Restart and try again" />
		<!--- set up all of our flow structures but only once on wizard startup --->
		<cfset application.SLCMS.config.startup.initialization.ErrorCode = 0 />
		<cfset application.SLCMS.config.startup.initialization.ErrorMessage = "" />
		<cfif not StructKeyExists(application.SLCMS.config.startup.initialization, "installationTemp")>
			<cfset application.SLCMS.config.startup.initialization.installationTemp = StructNew() />	<!--- a fresh temp structure that we can dump when its finished --->
			<cfset application.SLCMS.config.startup.initialization.installationTemp.NextStepNumber = 1 />
			<cfset application.SLCMS.config.startup.initialization.installationTemp.NextStepMode = "Display"  />
			<cfset application.SLCMS.config.startup.initialization.installationTemp.NextFlow = "BaseFlow" />
			<cfset application.SLCMS.config.startup.initialization.installationTemp.CurrentStepNumber = 1 />
			<cfset application.SLCMS.config.startup.initialization.installationTemp.CurrentStepMode = "Display"  />
			<cfset application.SLCMS.config.startup.initialization.installationTemp.CurrentFlow = "BaseFlow" />
			<cfset application.SLCMS.config.startup.initialization.installationTemp.LastStepNumber = 1 />
			<cfset application.SLCMS.config.startup.initialization.installationTemp.LastStepMode = "Display"  />
			<cfset application.SLCMS.config.startup.initialization.installationTemp.LastFlow = "BaseFlow" />
			<cfset application.SLCMS.config.startup.initialization.installationTemp.BaseFlow = StructNew() />
			<cfset application.SLCMS.config.startup.initialization.installationTemp.BaseFlow.Steps = StructNew() />
			<cfset application.SLCMS.config.startup.initialization.installationTemp.BaseFlow.Steps["Step_0"] = StructNew() />
			<cfset application.SLCMS.config.startup.initialization.installationTemp.BaseFlow.Steps["Step_0"].StepNumber = 0 />
			<cfset application.SLCMS.config.startup.initialization.installationTemp.BaseFlow.HighestStepVisited = 1 />
			<cfset application.SLCMS.config.startup.initialization.installationTemp.MainFlow = StructNew() />
			<cfset application.SLCMS.config.startup.initialization.installationTemp.MainFlow.steps = StructNew() />
			<cfset application.SLCMS.config.startup.initialization.installationTemp.MainFlow.HighestStepVisited = 1 />
			<cfset application.SLCMS.config.startup.initialization.installationTemp.SecondFlow = StructNew() />
			<cfset application.SLCMS.config.startup.initialization.installationTemp.SecondFlow.steps = StructNew() />
			<cfset application.SLCMS.config.startup.initialization.installationTemp.SecondFlow.HighestStepVisited = 1 />
		</cfif>
		<!--- log everything --->
		<cffile action="append" file="#variables.Paths.LogFile#" output="Installation Wizard Init() called - Time: #DateFormat(Now(),"YYYYMMDD")#-#TimeFormat(now(),"HH:mm:ss")#." addnewline="true" />
		<!--- what might come back --->
		<cfset provides("html,json")>
	</cffunction>

<cffunction name="RunStep" output="yes" returntype="struct" access="public"
	displayname="Display Step"
	hint="Displays specified step in the Wizard, calling relevant CFCs, etc"
	>
	<!--- this function needs.... --->
	<cfargument name="Step" type="any" required="false" default="" />	<!--- the number of the step to perform --->
	<cfargument name="Flow" type="any" required="false" default="" />	<!--- the workflow we are in --->

	<!--- now all of the var declarations, first the arguments which need manipulation --->
	<cfset var theStep = trim(arguments.Step) />
	<cfset var theFlow = trim(arguments.Flow) />	<!--- temp just to keep the name short --->
	<!--- now vars that will get filled as we go --->
	<cfset var theFunc = "" />	<!--- temp/throwaway function! --->
	<cfset var temp = "" />	<!--- temp/throwaway var --->
	<cfset var tempa = ArrayNew(1) />	<!--- temp/throwaway array --->
	<cfset var temps = StructNew() />	<!--- temp/throwaway structure --->
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var theNextStep = theStep />	<!--- this is the return to the caller, normally the next step in the sequence, initially set to this one --->
	<!--- and then the error handling structure --->
	<cfset var ret = StructNew() />
	<!--- and load it up with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorContext = "Initial Installation Wizard: Run
	Step()" />
	<cfset ret.error.ErrorText = "" />
	<cfset ret.error.ErrorExtra = "" />
	<cfset ret.Data = StructNew() />	<!--- and no data yet --->

	<!--- validation --->
	<cfif theStep eq "">
		<!--- if no supplied step use the system one --->
		<cfset theStep = application.SLCMS.config.startup.initialization.installationTemp.CurrentStepNumber />
	</cfif>
	<cfif theFlow eq "">
		<!--- if no supplied workflow use the system one --->
		<cfset theFlow = application.SLCMS.config.startup.initialization.installationTemp.CurrentFlow />
	</cfif>
	<cfif theStep neq "" and IsNumeric(theStep)>
		<cftry>
			<!--- set up the base temp data struct for this step, what goes in it is step dependent --->
			<cfset CheckNsetStepDataStruct(Step=theStep, Flow=theFlow) />
			<!---  first off we have to work out what it is we want to show or process --->
			<cfif application.SLCMS.config.startup.initialization.installationTemp.CurrentStepMode eq "process">
					<!--- 
					processor hit! Workflow:#theFlow# Step:#theStep#<br>
					<cfdump var="#request.wheels.params#" expand="false" label="request.wheels.params vars">
					 --->

				<!--- we process first in this logic flow as if a current page's submission was we want to step to the next page --->
				<cfif StructKeyExists(request.wheels.params, "StepWork") and request.wheels.params.StepWork eq "Process" and StructKeyExists(request.wheels.params, "StepCount") and request.wheels.params.StepCount eq "Step_#application.SLCMS.config.startup.initialization.installationTemp.CurrentStepNumber#">
					<!--- work out which page process function to call and load in the function --->
					<cfset theFunc = variables["ProcessPage_#theFlow#_Step_#theStep#"]>
					<!--- and call it --->
					<cfset theFunc()>
					<!--- that was a cute trick wasn't it? Thank Terence ryan for that one (http://www.terrenceryan.com/blog/post.cfm/cheap-and-easy-dynamic-method-calling-in-cfscript) --->
				<cfelseif StructKeyExists(request.wheels.params, "StepWork") and request.wheels.params.StepWork eq "BackForward" and StructKeyExists(request.wheels.params, "StepCount") and (StructKeyExists(request.wheels.params, "Forward1Step") or StructKeyExists(request.wheels.params, "Back1Step"))>
					<!--- or change page if the navigation buttons have been pressed --->
					<cfset application.SLCMS.config.startup.initialization.installationTemp.CurrentStepMode = "Display">
					<cfif StructKeyExists(request.wheels.params, "Back1Step")>
						<cfif request.wheels.params.StepCount eq "Step_1" and request.wheels.params.Back1Step eq variables["#theFlow#"].StepTexts["Step_1"].Back1Step >
							<!--- we are at the start of a flow so go back to start (base) --->
							<cfset application.SLCMS.config.startup.initialization.installationTemp.CurrentFlow = "BaseFlow" />
							<cfset application.SLCMS.config.startup.initialization.installationTemp.CurrentStepNumber = variables.StartStep />
						<cfelse>
							<!---  a simple "back to previous page" --->
							<cfset theStep = application.SLCMS.config.startup.initialization.installationTemp.CurrentStepNumber />
							<cfset theStep = theStep-1 />	<!--- wind back one step --->
							<cfset application.SLCMS.config.startup.initialization.installationTemp.CurrentStepNumber = theStep />
							<cfif theStep lt variables["#theFlow#"].BottomStep>	<!--- make sure don't go too far --->
								<cfset theStep = variables["#theFlow#"].BottomStep />
								<cfset application.SLCMS.config.startup.initialization.installationTemp.CurrentStepNumber = theStep />
							</cfif>
						</cfif>
					<cfelseif StructKeyExists(request.wheels.params, "Forward1Step")>
							<cfset theStep = application.SLCMS.config.startup.initialization.installationTemp.CurrentStepNumber />
							<cfset theStep = theStep+1 />	<!--- wind up one step --->
							<cfset application.SLCMS.config.startup.initialization.installationTemp.CurrentStepNumber = theStep />
						<cfif theStep gt variables["#theFlow#"].TopStep>	<!--- make sure don't go too far --->
							<cfset theStep = variables["#theFlow#"].TopStep />
							<cfset application.SLCMS.config.startup.initialization.installationTemp.CurrentStepNumber = theStep />
						</cfif>
					<cfelse>
					</cfif>
				<cfelse>
					<!--- no valid request.wheels.params vars, might have just hot refresh so flip back to display for this same step --->
					<cfset application.SLCMS.config.startup.initialization.installationTemp.CurrentStepMode = "Display">
				</cfif>
				<cfset theStep = application.SLCMS.config.startup.initialization.installationTemp.CurrentStepNumber />	<!--- things might have changed... --->
				<cfset theFlow = application.SLCMS.config.startup.initialization.installationTemp.CurrentFlow />
			</cfif>
			<!--- processing done display what we have to --->
			<cfif application.SLCMS.config.startup.initialization.installationTemp.CurrentStepMode eq "Display">
				<!--- spit out the html for the page header --->
				<!---
				<cfset displayPageHeading()>
			runstep display mode - flow:#theFlow# step:#theStep#<br>
				--->
				<!--- 
				<cfset theFunc = variables["displayPageBody_#theFlow#_Step_#theStep#"]>
				<cfset theFunc()>
				<!--- display happened so set for the next happening, process the page results! --->
				<cfset application.SLCMS.config.startup.initialization.installationTemp.CurrentStepMode = "Process" />
				<cfset application.SLCMS.config.startup.initialization.installationTemp.NextStepMode = "Display" />
				 --->
			<!--- 
				<cfset displayPageFooter()>
 				--->
			</cfif>

				<!--- 	
					<cfoutput><p>this is the end of the RunStep function in the <em>Initial Installation Wizard</em> showing application.SLCMS.config.startup.initialization:</p></cfoutput>
					<cfdump var="#application.SLCMS.config.startup.initialization#" expand="false" label="application.SLCMS.config.startup.initialization from end of Wiz RunStep()">
 				--->

		<cfcatch type="any">
			<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 128) />
			<cfset ret.error.ErrorText = ret.error.ErrorContext & ' Trapped. error message was: #cfcatch.message#, error detail was: #cfcatch.detail#' />
			<cfset ret.error.ErrorExtra =  cfcatch.TagContext />
			<cfif isArray(ret.error.ErrorExtra) and StructKeyExists(ret.error.ErrorExtra[1], "Raw_Trace")>
				<cfset ret.error.ErrorText = ret.error.ErrorText & ", Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#" />
			</cfif>
			<cflog text='#ret.error.ErrorText# - ret.error.ErrorCode: #ret.error.ErrorCode# - Time: #Dateformat(Now(),"YYYYMMDD")#-#Timeformat(now(),"HH:mm:ss")#'  file="SLCMS_Common" type="Error" application = "yes">
			<cfoutput>#ret.error.ErrorContext#</cfoutput> Trapped - error dump:<br>
			<cfdump var="#cfcatch#">
			<cfabort>
		</cfcatch>
		</cftry>
	<cfelse>	<!--- this is the error code --->
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 1) />
		<cfset ret.error.ErrorText = ret.error.ErrorText & "Oops! Invalid Step number supplied<br>" />
		<cfset theNextStep = theStep />	<!--- try this one again --->
	</cfif>

	<!--- return our next step --->
	<cfreturn ret  />
</cffunction>

<!---  as the function flow in RunStep is "Process then Display the Next" we will have those functions in the same order here --->
<!--- first all of the page processing functions --->
<cffunction name="ProcessPage_Baseflow_Step_1" output="yes" returntype="struct" access="public"
	displayname="ProcessPage - Baseflow Step 1"
	hint="Process the form submission from base page, step 1"
	>
	<!--- this function needs takes no arguments, everything is in external scopes --->

	<!--- now all of the var declarations, first the vars that will get filled as we go --->
	<cfset var theFlow = "Baseflow" />	<!--- temp just to keep the name short --->
	<cfset var lcntr = 0 />	<!--- temp loop counter --->
	<cfset var temp = "" />	<!--- temp/throwaway var --->
	<cfset var tempa = ArrayNew(1) />	<!--- temp/throwaway array --->
	<cfset var temps = StructNew() />	<!--- temp/throwaway structure --->
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorContext = "InitialInstalationWizard ProcessPage_Baseflow_Step_1()" />
	<cfset ret.error.ErrorText = "" />
	<cfset ret.error.ErrorExtra = "" />
	<cfset ret.Data = "" />	<!--- and no data yet --->

	<!--- wrap the whole thing in a try/catch in case something breaks --->
	<cftry>
		<cffile action="append" file="#variables.Paths.LogFile#" output="Installation Wizard ProcessPage_Baseflow_Step_1() called - Time: #DateFormat(Now(),"YYYYMMDD")#-#TimeFormat(now(),"HH:mm:ss")#." addnewline="true" />
		<!--- this is almost embarassing after all this error checking, there is almost no code needed here. No longer true! I have put lots of stuff in now!!! --->
		<cfif structKeyExists(request.wheels.params, "FirstTime") and request.wheels.params.FirstTime eq variables.BaseFlow.StepTexts["Step_1"].YesFirst>
			<!--- we have a match for a "first time in" --->
			<cfset application.SLCMS.config.startup.initialization.installationTemp.CurrentStepMode = "Display" />	<!--- display next page --->
			<cfset application.SLCMS.config.startup.initialization.installationTemp.CurrentStepNumber = "1" />	<!--- flag back the next step in the regular flow --->
			<cfset application.SLCMS.config.startup.initialization.installationTemp.CurrentFlow = "MainFlow" />
			<!---  now we have the step set up lets grab the info we need for it --->
			<cfset CheckNsetStepDataStruct(Step="1", Flow="Mainflow") />
			<cfif not StructKeyExists(application.SLCMS.config.startup.initialization.installationTemp.Mainflow.Steps["Step_1"].data, "DataValid")>
				<cfset application.SLCMS.config.startup.initialization.installationTemp.Mainflow.Steps["Step_1"].data.DataValid = True />
			</cfif>
			<cfif not StructKeyExists(application.SLCMS.config.startup.initialization.installationTemp.Mainflow.Steps["Step_1"].data, "MachineName")>
				<cfset application.SLCMS.config.startup.initialization.installationTemp.Mainflow.Steps["Step_1"].data.MachineName = {Data="#server.os.MachineName#", Valid=True, ErrorText=""} />
			</cfif>
			<cfif application.SLCMS.config.startup.initialization.installationTemp.Mainflow.Steps["Step_1"].data.MachineName.Data eq "#server.os.MachineName#">
				<!--- 
				<cfif application.SLCMS.config.startup.initialization.ConfigFileLoadFailed and StructKeyExists(server.mbc_Utility.ServerConfig, "MachineName")>
					if we had a config file load fail then there is not much in the app scope so revert back to where it came from, the server scope load should have run anyway
					<cfset application.SLCMS.config.startup.initialization.installationTemp.Mainflow.Steps["Step_1"].data.MachineName.Data = server.mbc_Utility.ServerConfig.MachineName />
				</cfif>
				 --->
			</cfif>
			<cfif not StructKeyExists(application.SLCMS.config.startup.initialization.installationTemp.Mainflow.Steps["Step_1"].data, "SiteName")>
				<cfset application.SLCMS.config.startup.initialization.installationTemp.Mainflow.Steps["Step_1"].data.SiteName = {Data="", Valid=True, ErrorText=""} />
				<cfif variables.CodeDevMode>
					<cfset application.SLCMS.config.startup.initialization.installationTemp.Mainflow.Steps["Step_1"].data.SiteName.Data = "Test Site" />
				</cfif>
			</cfif>
			<cfif not StructKeyExists(application.SLCMS.config.startup.initialization.installationTemp.Mainflow.Steps["Step_1"].data, "SiteAbbreviatedName")>
				<cfset application.SLCMS.config.startup.initialization.installationTemp.Mainflow.Steps["Step_1"].data.SiteAbbreviatedName = {Data="", Valid=True, ErrorText=""} />
				<cfif variables.CodeDevMode>
					<cfset application.SLCMS.config.startup.initialization.installationTemp.Mainflow.Steps["Step_1"].data.SiteAbbreviatedName.Data = "Test_Site" />
				</cfif>
			</cfif>
			<cfif not StructKeyExists(application.SLCMS.config.startup.initialization.installationTemp.Mainflow.Steps["Step_1"].data, "BaseDomainName")>
				<cfset application.SLCMS.config.startup.initialization.installationTemp.Mainflow.Steps["Step_1"].data.BaseDomainName = {Data="", Valid=True, ErrorText=""} />
				<cfif variables.CodeDevMode>
					<cfset application.SLCMS.config.startup.initialization.installationTemp.Mainflow.Steps["Step_1"].data.BaseDomainName.Data = "test.com.au" />
				</cfif>
			</cfif>
			<cfif not StructKeyExists(application.SLCMS.config.startup.initialization.installationTemp.Mainflow.Steps["Step_1"].data, "SSLOnly")>
				<cfset application.SLCMS.config.startup.initialization.installationTemp.Mainflow.Steps["Step_1"].data.SSLOnly = {Data="No", Valid=True, ErrorText=""} />
			</cfif>
			<cfif not StructKeyExists(application.SLCMS.config.startup.initialization.installationTemp.Mainflow.Steps["Step_1"].data, "Role")>
				<cfset application.SLCMS.config.startup.initialization.installationTemp.Mainflow.Steps["Step_1"].data.Role = {Data="Production", Valid=True, ErrorText=""} />
				<cfif variables.CodeDevMode>
					<cfset application.SLCMS.config.startup.initialization.installationTemp.Mainflow.Steps["Step_1"].data.Role.Data = "Design" />
				</cfif>
			</cfif>
			<cfif not StructKeyExists(application.SLCMS.config.startup.initialization.installationTemp.Mainflow.Steps["Step_1"].data, "MixedMode")>
				<cfset application.SLCMS.config.startup.initialization.installationTemp.Mainflow.Steps["Step_1"].data.MixedMode = {Data="No", Valid=True, ErrorText=""} />
				<cfif variables.CodeDevMode>
					<cfset application.SLCMS.config.startup.initialization.installationTemp.Mainflow.Steps["Step_1"].data.MixedMode.Data = "Yes" />
				</cfif>
			</cfif>
			<cfif not StructKeyExists(application.SLCMS.config.startup.initialization.installationTemp.Mainflow.Steps["Step_1"].data, "BasePort")>
				<cfset application.SLCMS.config.startup.initialization.installationTemp.Mainflow.Steps["Step_1"].data.BasePort = {Data="80", Valid=True, ErrorText=""} />
			</cfif>
			<cfif not StructKeyExists(application.SLCMS.config.startup.initialization.installationTemp.Mainflow.Steps["Step_1"].data, "BaseProtocol")>
				<cfset application.SLCMS.config.startup.initialization.installationTemp.Mainflow.Steps["Step_1"].data.BaseProtocol = {Data="http://", Valid=True, ErrorText=""} />
			</cfif>
			<cfif not StructKeyExists(application.SLCMS.config.startup.initialization.installationTemp.Mainflow.Steps["Step_1"].data, "DSN_SLCMS")>
				<cfset application.SLCMS.config.startup.initialization.installationTemp.Mainflow.Steps["Step_1"].data.DSN_SLCMS = {Data="", Valid=True, ErrorText=""} />
				<cfif variables.CodeDevMode>
					<cfset application.SLCMS.config.startup.initialization.installationTemp.Mainflow.Steps["Step_1"].data.DSN_SLCMS.Data = "SLCMS_Core_Dev_local_mySQL" />
				</cfif>
			</cfif>
			<cfif not StructKeyExists(application.SLCMS.config.startup.initialization.installationTemp.Mainflow.Steps["Step_1"].data, "InDebugMode")>
				<cfset application.SLCMS.config.startup.initialization.installationTemp.Mainflow.Steps["Step_1"].data.InDebugMode = {Data="No", Valid=True, ErrorText=""} />
				<cfif variables.CodeDevMode>
					<cfset application.SLCMS.config.startup.initialization.installationTemp.Mainflow.Steps["Step_1"].data.InDebugMode.Data = "Yes" />
				</cfif>
			</cfif>
			<cfif not StructKeyExists(application.SLCMS.config.startup.initialization.installationTemp.Mainflow.Steps["Step_1"].data, "Debug_ShowStatus")>
				<cfset application.SLCMS.config.startup.initialization.installationTemp.Mainflow.Steps["Step_1"].data.Debug_ShowStatus = {Data="No", Valid=True, ErrorText=""} />
				<cfif variables.CodeDevMode>
					<cfset application.SLCMS.config.startup.initialization.installationTemp.Mainflow.Steps["Step_1"].data.Debug_ShowStatus.Data = "Yes" />
				</cfif>
			</cfif>
			<cfif not StructKeyExists(application.SLCMS.config.startup.initialization.installationTemp.Mainflow.Steps["Step_1"].data, "errorEmailTo")>
				<cfset application.SLCMS.config.startup.initialization.installationTemp.Mainflow.Steps["Step_1"].data.errorEmailTo = {Data="", Valid=True, ErrorText=""} />
				<cfif variables.CodeDevMode>
					<cfset application.SLCMS.config.startup.initialization.installationTemp.Mainflow.Steps["Step_1"].data.errorEmailTo.Data = "test@slcms.net" />
				</cfif>
			</cfif>
			<cfif not StructKeyExists(application.SLCMS.config.startup.initialization.installationTemp.Mainflow.Steps["Step_1"].data, "testEddress")>
				<cfset application.SLCMS.config.startup.initialization.installationTemp.Mainflow.Steps["Step_1"].data.testEddress = {Data="", Valid=True, ErrorText=""} />
				<cfif variables.CodeDevMode>
					<cfset application.SLCMS.config.startup.initialization.installationTemp.Mainflow.Steps["Step_1"].data.testEddress.Data = "dev@mbcomms.net.au" />
				</cfif>
			</cfif>
		<cfelseif structKeyExists(request.wheels.params, "NotFirstTime") and request.wheels.params.NotFirstTime eq variables.BaseFlow.StepTexts["Step_1"].NotFirst>
			<!--- we have a match for a "been here before" --->
			<cfset application.SLCMS.config.startup.initialization.installationTemp.CurrentStepMode = "Display" />	<!--- display next page --->
			<cfset application.SLCMS.config.startup.initialization.installationTemp.CurrentStepNumber = "1" />	<!--- flag back the first step for "not firet time in, what an earth happened" --->
			<cfset application.SLCMS.config.startup.initialization.installationTemp.CurrentFlow = "SecondFlow" />
			<cfset theFlow = application.SLCMS.config.startup.initialization.installationTemp.CurrentFlow />	<!--- temp just to keep the name short --->
		<cfelse>
			<cfset application.SLCMS.config.startup.initialization.ErrorCode =  BitOr(application.SLCMS.config.startup.initialization.ErrorCode, 1) />
			<cfset application.SLCMS.config.startup.initialization.ErrorMessage = application.SLCMS.config.startup.initialization.ErrorMessage & "Oops! No relevant parameter submitted!<br>" />
			<cfset application.SLCMS.config.startup.initialization.installationTemp.CurrentStepMode = "Display" />	<!--- flag back the same step for its display page --->
		</cfif>
	<cfcatch type="any">
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 128) />
		<cfset ret.error.ErrorText = ret.error.ErrorContext & ' Trapped. error message was: #cfcatch.message#, error detail was: #cfcatch.detail#' />
		<cfset ret.error.ErrorExtra =  cfcatch.TagContext />
		<cfif isArray(ret.error.ErrorExtra) and StructKeyExists(ret.error.ErrorExtra[1], "Raw_Trace")>
			<cfset ret.error.ErrorText = ret.error.ErrorText & ", Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#" />
		</cfif>
		<cflog text='#ret.error.ErrorText# - ret.error.ErrorCode: #ret.error.ErrorCode# - Time: #DateFormat(Now(),"YYYYMMDD")#-#TimeFormat(now(),"HH:mm:ss")#'  file="SLCMS_Common" type="Error" application = "yes">
		<cfoutput>#ret.error.ErrorContext#</cfoutput> Trapped - error dump:<br>
		<cfdump var="#cfcatch#">
		<cfabort>
	</cfcatch>
	</cftry>

		<cfdump var="#application.SLCMS.config.startup.initialization#" expand="false" label="application.SLCMS.config.startup.initialization from end of Wiz ProcessPage_Baseflow_Step_1()">

	<!--- return our data structure --->
	<cfreturn ret  />
</cffunction>

<cffunction name="ProcessPage_Mainflow_Step_1" output="yes" returntype="struct" access="public"
	displayname="ProcessPage - Mainflow Step 1"
	hint="Process the next step from MainFlow page step 1, start the wheel rollinng"
	>
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorContext = "InitialInstallationWizard ProcessPage_Step_Mainflow_1()" />
	<cfset ret.error.ErrorText = "" />
	<cfset ret.error.ErrorExtra = "" />
	<cfset ret.Data = "" />	<!--- and no data yet --->

	<cftry>
		<cffile action="append" file="#variables.Paths.LogFile#" output="Installation Wizard ProcessPage_Mainflow_Step_1() called - Time: #DateFormat(Now(),"YYYYMMDD")#-#TimeFormat(now(),"HH:mm:ss")#." addnewline="true" />
		<cfset application.SLCMS.config.startup.initialization.installationTemp.CurrentStepMode = "Display" />	<!--- display next page --->
		<cfset application.SLCMS.config.startup.initialization.installationTemp.CurrentStepNumber = "2" />	<!--- flag back the next step in the regular flow --->
		<cfset application.SLCMS.config.startup.initialization.installationTemp.CurrentFlow = "MainFlow" />
	<cfcatch type="any">
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 128) />
		<cfset ret.error.ErrorText = ret.error.ErrorContext & ' Trapped. error message was: #cfcatch.message#, error detail was: #cfcatch.detail#' />
		<cfset ret.error.ErrorExtra =  cfcatch.TagContext />
		<cfif isArray(ret.error.ErrorExtra) and StructKeyExists(ret.error.ErrorExtra[1], "Raw_Trace")>
			<cfset ret.error.ErrorText = ret.error.ErrorText & ", Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#" />
		</cfif>
		<cflog text='#ret.error.ErrorText# - ret.error.ErrorCode: #ret.error.ErrorCode# - Time: #DateFormat(Now(),"YYYYMMDD")#-#TimeFormat(now(),"HH:mm:ss")#'  file="SLCMS_Common" type="Error" application = "yes">
		<cfoutput>#ret.error.ErrorContext#</cfoutput> Trapped - error dump:<br>
		<cfdump var="#cfcatch#">
		<cfabort>
	</cfcatch>
	</cftry>

	<!--- return our data structure --->
	<cfreturn ret  />
</cffunction>

<cffunction name="ProcessPage_Mainflow_Step_2" output="yes" returntype="struct" access="public"
	displayname="ProcessPage - Mainflow Step 2"
	hint="Process the form submission from MainFlow page step 2"
	>
	<!--- this function needs takes no arguments, everything is in external scopes --->

	<!--- now all of the var declarations, first the vars that will get filled as we go --->
	<cfset var theFlow = "MainFlow" />	<!--- temp just to keep the name short --->
	<cfset var lcntr = 0 />	<!--- temp loop counter --->
	<cfset var temp = "" />	<!--- temp/throwaway var --->
	<cfset var tempa = ArrayNew(1) />	<!--- temp/throwaway array --->
	<cfset var temps = StructNew() />	<!--- temp/throwaway structure --->
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorContext = "InitialInstalationWizard ProcessPage_Step_Mainflow_2()" />
	<cfset ret.error.ErrorText = "" />
	<cfset ret.error.ErrorExtra = "" />
	<cfset ret.Data = "" />	<!--- and no data yet --->

	<cftry>
		<cffile action="append" file="#variables.Paths.LogFile#" output="Installation Wizard ProcessPage_Mainflow_Step_2() called - Time: #DateFormat(Now(),"YYYYMMDD")#-#TimeFormat(now(),"HH:mm:ss")#." addnewline="true" />
		<cfif structKeyExists(request.wheels.params, "Role") and request.wheels.params.Role neq "">
			<!--- tuck the variables away, we already have the machine name --->
			<cfset application.SLCMS.config.startup.initialization.installationTemp.CurrentStepMode = "Display" />	<!--- display next page --->
			<cfset application.SLCMS.config.startup.initialization.installationTemp.CurrentStepNumber = "3" />	<!--- flag back the next step in the regular flow --->
			<cfset application.SLCMS.config.startup.initialization.installationTemp.CurrentFlow = "MainFlow" />
			<cfset theFlow = application.SLCMS.config.startup.initialization.installationTemp.CurrentFlow />	<!--- temp just to keep the name short --->
			<!---  make sure step 1 structs are there (should be but just in case) and load in our form variables --->
			<cfset CheckNsetStepDataStruct(Step="1", Flow="Mainflow") />
			<cfset application.SLCMS.config.startup.initialization.installationTemp.Mainflow.Steps["Step_1"].data.SiteName.Data = request.wheels.params.SiteName />
			<cfset application.SLCMS.config.startup.initialization.installationTemp.Mainflow.Steps["Step_1"].data.SiteAbbreviatedName.Data = request.wheels.params.SiteAbbreviatedName />
			<cfset application.SLCMS.config.startup.initialization.installationTemp.Mainflow.Steps["Step_1"].data.BaseDomainName.Data = request.wheels.params.BaseDomainName />
			<cfset application.SLCMS.config.startup.initialization.installationTemp.Mainflow.Steps["Step_1"].data.SSLOnly.Data = request.wheels.params.SSLOnly />
			<cfset application.SLCMS.config.startup.initialization.installationTemp.Mainflow.Steps["Step_1"].data.Role.Data = request.wheels.params.Role />
			<cfset application.SLCMS.config.startup.initialization.installationTemp.Mainflow.Steps["Step_1"].data.DSN_SLCMS.Data = request.wheels.params.DSN_SLCMS />
			<cfset application.SLCMS.config.startup.initialization.installationTemp.Mainflow.Steps["Step_1"].data.errorEmailTo.Data = request.wheels.params.errorEmailTo />
			<cfset application.SLCMS.config.startup.initialization.installationTemp.Mainflow.Steps["Step_1"].data.TestEddress.Data = request.wheels.params.TestEddress />
			<cfset application.SLCMS.config.startup.initialization.installationTemp.Mainflow.Steps["Step_1"].data.Debug_ShowStatus.Data = request.wheels.params.Debug_ShowStatus />
			<cfset application.SLCMS.config.startup.initialization.installationTemp.Mainflow.Steps["Step_1"].data.InDebugMode.Data = request.wheels.params.InDebugMode />
			<!--- now we have loaded data check for goodness and rest the valid flags for ones that were bad before and now good --->
			<cfset application.SLCMS.config.startup.initialization.installationTemp.Mainflow.Steps["Step_1"].data.DataValid = True />
			<cfif application.SLCMS.config.startup.initialization.installationTemp.Mainflow.Steps["Step_1"].data.SiteName.Data eq "">
				<cfset application.SLCMS.config.startup.initialization.installationTemp.Mainflow.Steps["Step_1"].data.SiteName.Valid = False />
				<cfset application.SLCMS.config.startup.initialization.installationTemp.Mainflow.Steps["Step_1"].data.SiteName.ErrorText = "The Site Name Cannot be Blank" />
				<cfset application.SLCMS.config.startup.initialization.installationTemp.Mainflow.Steps["Step_1"].data.DataValid = False />
			<cfelse>
				<cfset application.SLCMS.config.startup.initialization.installationTemp.Mainflow.Steps["Step_1"].data.SiteName.Valid = True />
			</cfif>
			<cfif application.SLCMS.config.startup.initialization.installationTemp.Mainflow.Steps["Step_1"].data.SiteAbbreviatedName.Data eq "">
				<cfset application.SLCMS.config.startup.initialization.installationTemp.Mainflow.Steps["Step_1"].data.SiteAbbreviatedName.Valid = False />
				<cfset application.SLCMS.config.startup.initialization.installationTemp.Mainflow.Steps["Step_1"].data.SiteAbbreviatedName.ErrorText = "The Abbreviated Site Name Cannot be Blank" />
				<cfset application.SLCMS.config.startup.initialization.installationTemp.Mainflow.Steps["Step_1"].data.DataValid = False />
			<cfelse>
				<cfset application.SLCMS.config.startup.initialization.installationTemp.Mainflow.Steps["Step_1"].data.SiteAbbreviatedName.Valid = True />
			</cfif>
			<cfif application.SLCMS.config.startup.initialization.installationTemp.Mainflow.Steps["Step_1"].data.DSN_SLCMS.Data eq "">
				<cfset application.SLCMS.config.startup.initialization.installationTemp.Mainflow.Steps["Step_1"].data.DSN_SLCMS.Valid = False />
				<cfset application.SLCMS.config.startup.initialization.installationTemp.Mainflow.Steps["Step_1"].data.DSN_SLCMS.ErrorText = "The Datasource Cannot be Blank" />
				<cfset application.SLCMS.config.startup.initialization.installationTemp.Mainflow.Steps["Step_1"].data.DataValid = False />
			<cfelse>
				<cfset application.SLCMS.config.startup.initialization.installationTemp.Mainflow.Steps["Step_1"].data.DSN_SLCMS.Valid = True />
			</cfif>
			<cfset temp = application.SLCMS.config.startup.initialization.installationTemp.Mainflow.Steps["Step_1"].data.errorEmailTo.Data />	<!--- just to make the next line a bit easier to read! --->
			<!--- do some very simple eddress checks: not null; stuff before and after @; at least one dot in domain name --->
			<cfif temp eq "">
				<cfset application.SLCMS.config.startup.initialization.installationTemp.Mainflow.Steps["Step_1"].data.errorEmailTo.Valid = False />
				<cfset application.SLCMS.config.startup.initialization.installationTemp.Mainflow.Steps["Step_1"].data.errorEmailTo.ErrorText = "It is strongly suggested that you have an email address to send messages to" />
	  	<cfelseif ListLen(temp, "@") neq 2 or  not ListLen(ListLast(temp, "@"), ".") gt 1>
				<cfset application.SLCMS.config.startup.initialization.installationTemp.Mainflow.Steps["Step_1"].data.errorEmailTo.Valid = False />
				<cfset application.SLCMS.config.startup.initialization.installationTemp.Mainflow.Steps["Step_1"].data.errorEmailTo.ErrorText = "Invalid Email Address" />
				<!--- note no global invalid flag, the system will run so just advise user --->
			<cfelse>
				<cfset application.SLCMS.config.startup.initialization.installationTemp.Mainflow.Steps["Step_1"].data.errorEmailTo.Valid = True />
			</cfif>
			<cfset temp = application.SLCMS.config.startup.initialization.installationTemp.Mainflow.Steps["Step_1"].data.TestEddress.Data />
			<cfif temp eq "">
				<cfset application.SLCMS.config.startup.initialization.installationTemp.Mainflow.Steps["Step_1"].data.TestEddress.Valid = False />
				<cfset application.SLCMS.config.startup.initialization.installationTemp.Mainflow.Steps["Step_1"].data.TestEddress.ErrorText = "It is strongly suggested that you have an email address to send messages to" />
	  	<cfelseif ListLen(temp, "@") neq 2 or  not ListLen(ListLast(temp, "@"), ".") gt 1>
				<cfset application.SLCMS.config.startup.initialization.installationTemp.Mainflow.Steps["Step_1"].data.TestEddress.Valid = False />
				<cfset application.SLCMS.config.startup.initialization.installationTemp.Mainflow.Steps["Step_1"].data.TestEddress.ErrorText = "Invalid Email Address" />
				<!--- note no global invalid flag, the system will run so just advise user --->
			<cfelse>
				<cfset application.SLCMS.config.startup.initialization.installationTemp.Mainflow.Steps["Step_1"].data.TestEddress.Valid = True />
			</cfif>
			<!--- then set up for the next step if we are just walking thru --->
			<cfset CheckNsetStepDataStruct(Step="2", Flow="Mainflow") />
			<!--- no sample bit of data until we actually write some here --->
		<cfelse>
			<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 1) />
			<cfset ret.error.ErrorText = ret.error.ErrorText & "Oops! No relevant parameter submitted!<br>" />
			<cfset application.SLCMS.config.startup.initialization.installationTemp.CurrentStepMode = "Display" />	<!--- flag back the same step for its display page --->
		</cfif>
		<!--- 		
		<cfdump var="#application.SLCMS.config.startup.initialization#" expand="false" label="application.SLCMS.config.startup.initialization">
		<cfabort>
 			--->
	<cfcatch type="any">
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 128) />
		<cfset ret.error.ErrorText = ret.error.ErrorContext & ' Trapped. error message was: #cfcatch.message#, error detail was: #cfcatch.detail#' />
		<cfset ret.error.ErrorExtra =  cfcatch.TagContext />
		<cfif isArray(ret.error.ErrorExtra) and StructKeyExists(ret.error.ErrorExtra[1], "Raw_Trace")>
			<cfset ret.error.ErrorText = ret.error.ErrorText & ", Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#" />
		</cfif>
		<cflog text='#ret.error.ErrorText# - ret.error.ErrorCode: #ret.error.ErrorCode# - Time: #DateFormat(Now(),"YYYYMMDD")#-#TimeFormat(now(),"HH:mm:ss")#'  file="SLCMS_Common" type="Error" application = "yes">
		<cfoutput>#ret.error.ErrorContext#</cfoutput> Trapped - error dump:<br>
		<cfdump var="#cfcatch#">
		<cfabort>
	</cfcatch>
	</cftry>

	<!--- return our data structure --->
	<cfreturn ret  />
</cffunction>

<cffunction name="ProcessPage_Mainflow_Step_3" output="yes" returntype="struct" access="public"
	displayname="ProcessPage - Mainflow Step 3"
	hint="Process the submission from MainFlow page step 3, the review. It will set up the ini files and the database"
	>
	<!--- this function needs takes no arguments, everything is in external scopes --->

	<!--- now all of the var declarations, first the vars that will get filled as we go --->
	<cfset var theData = application.SLCMS.config.startup.initialization.installationTemp['MainFlow'].Steps['Step_1'].data />
	<cfset var theFlow = "MainFlow" />	<!--- temp just to keep the name short --->
	<cfset var theSiteModeIniFilePath = "" />	<!--- temp var --->
	<cfset var theconfigMapperPath = "" />	<!--- temp var --->
	<cfset var theBaseConfigPath = "" />	<!--- temp var --->
	<cfset var theCurrentVersionPath = "" />	<!--- guess what this is? --->
	<cfset var theRole = "" />
	<cfset var ret1 = "" />	<!--- return string from profile set for SiteMode, is a string if errored, null for good setting --->
	<cfset var ret2 = "" />	<!--- return string from profile set for ConfigMapper --->
	<cfset var ret3 = "" />	<!--- return string from profile set for Config_xxx Ini --->
	<cfset var read1 = "" />	<!--- return string from profile read --->
	<cfset var theErrorString = "" />
	<cfset var temp = "" />
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorContext = "InitialInstalationWizard ProcessPage_Step_Mainflow_3()" />
	<cfset ret.error.ErrorText = "" />
	<cfset ret.error.ErrorExtra = "" />
	<cfset ret.Data = "" />	<!--- and no data yet --->

	<cftry>
		<cffile action="append" file="#variables.Paths.LogFile#" output="Installation Wizard ProcessPage_Mainflow_Step_3() called - Time: #DateFormat(Now(),"YYYYMMDD")#-#TimeFormat(now(),"HH:mm:ss")#." addnewline="true" />
		<cfset theconfigMapperPath = application.SLCMS.config.startup.configMapperPath />
		<cfset theBaseConfigPath = application.SLCMS.config.startup.BaseConfigPath	/>
		<cfset theRole = theData.Role.Data />
		<cfset theMachineName = theData.MachineName.Data />
		<cfset ret2 = ret2 & setProfileString("#theconfigMapperPath#", "Machines", "#theMachineName#", "#theData.Role.Data#") />
		<!--- now the Config Mapper is set up so we can set up the relevant config file
					we have a bunch of them that match the selectable options in this Wiz but we had better check in case and 
					use the fall-back sample one as we did for the Site Mode config file 
					 --->
		<cfif not FileExists(theBaseConfigPath)>
			<!--- we don't have a config so make a blank one --->
			<cfset temp = "[Base]#chr(13)##chr(10)#; #chr(13)##chr(10)#[Datasources]#chr(13)##chr(10)#; #chr(13)##chr(10)#[Debug]#chr(13)##chr(10)#; #chr(13)##chr(10)#" />
			<cffile action="write" file="#theBaseConfigPath#" output="#temp#" addnewline="true">
		</cfif>
		<!--- set the base section params --->
		<cfset ret3 = ret3 & setProfileString("#theBaseConfigPath#", "base", "SiteName", "#theData.SiteName.Data#") />
		<cfset ret3 = ret3 & setProfileString("#theBaseConfigPath#", "base", "SiteAbbreviatedName", "#theData.SiteAbbreviatedName.Data#") />
		<cfset ret3 = ret3 & setProfileString("#theBaseConfigPath#", "base", "BaseDomainName", "#theData.BaseDomainName.Data#") />
		<cfif theData.SSLOnly.Data>
			<cfset ret3 = ret3 & setProfileString("#theBaseConfigPath#", "base", "BasePort", "443") />
			<cfset ret3 = ret3 & setProfileString("#theBaseConfigPath#", "base", "BaseProtocol", "https://") />
		<cfelse>
			<cfset ret3 = ret3 & setProfileString("#theBaseConfigPath#", "base", "BasePort", "80") />
			<cfset ret3 = ret3 & setProfileString("#theBaseConfigPath#", "base", "BaseProtocol", "http://") />
		</cfif>
		<cfset ret3 = ret3 & setProfileString("#theBaseConfigPath#", "base", "SiteMode", "#theData.Role.Data#") />
		<cfset ret3 = ret3 & setProfileString("#theBaseConfigPath#", "base", "DebugMode", "#theData.Debug_ShowStatus.Data#") />
		<!--- then the datasource(s) section params --->
		<cfset ret3 = ret3 & setProfileString("#theBaseConfigPath#", "Datasources", "CMS", "#theData.DSN_SLCMS.Data#") />
		<!--- and the debugging section params to finish it off --->
		<cfif theData.InDebugMode.Data and ListFindNoCase("Design,Development,Testing", theData.Role.Data)>
			<cfset ret3 = ret3 & setProfileString("#theBaseConfigPath#", "Debug", "DebugMode", "True") />
		<cfelse>
			<cfset ret3 = ret3 & setProfileString("#theBaseConfigPath#", "Debug", "DebugMode", "False") />
		</cfif>
		<cfset ret3 = ret3 & setProfileString("#theBaseConfigPath#", "Debug", "errorEmailTo", "#theData.errorEmailTo.Data#") />
		<cfset ret3 = ret3 & setProfileString("#theBaseConfigPath#", "Debug", "testEddress", "#theData.testEddress.Data#") />
		
		<!--- check for failures and flag them so we can display the wrongness --->
		<cfset application.SLCMS.config.startup.initialization.installationTemp["#theFlow#"].Steps["Step_2"].error.errorCode = 0 />
		<cfif Len(ret1)>
			<cfset theErrorString = "Config_SiteMode.ini update Failed. Error was: #ret1#" />
			<cfset application.SLCMS.config.startup.initialization.installationTemp["#theFlow#"].Steps["Step_2"].error.errorCode = 1 />
		</cfif>
		<cfif Len(ret2)>
			<cfif Len(theErrorString)>
				<cfset theErrorString = theErrorString & "<br>" />
			</cfif>
			<cfset theErrorString = theErrorString & "Config_Mapper.ini update Failed. Error was: #ret2#" />
			<cfset application.SLCMS.config.startup.initialization.installationTemp["#theFlow#"].Steps["Step_2"].error.errorCode = BitOr(application.SLCMS.config.startup.initialization.installationTemp["#theFlow#"].Steps["Step_2"].error.errorCode, 2) />
		</cfif>
		<cfif Len(ret3)>
			<cfif Len(theErrorString)>
				<cfset theErrorString = theErrorString & "<br>" />
			</cfif>
			<cfset theErrorString = theErrorString & "Main Config update Failed, attempting to update file: #theBaseConfigPath#. The error was: #ret3#" />
			<cfset application.SLCMS.config.startup.initialization.installationTemp["#theFlow#"].Steps["Step_2"].error.errorCode = BitOr(application.SLCMS.config.startup.initialization.installationTemp["#theFlow#"].Steps["Step_2"].error.errorCode, 4) />
		</cfif>
		<cfset application.SLCMS.config.startup.initialization.installationTemp["#theFlow#"].Steps["Step_2"].error.errorText = "#theErrorString#" />
		<!--- ini files all done so now do database --->
		<cfif theErrorString eq "">
			<!--- this is now already there from the cfw config
			<!--- firstly we sneak in a read of the loaded ini files as further down in the next step we will want to read some of the database tables we are about to create --->
			<!--- its easy to do here because we have the path toall worked out frmo above --->
			<cfset application.SLCMS.config.DatabaseDetails.TableNaming_Base = getProfileString("#theBaseConfigPath#", "DatabaseDetails", "TableNaming_Base") />
			<cfset application.SLCMS.config.DatabaseDetails.TableNaming_Delimiter = getProfileString("#theBaseConfigPath#", "DatabaseDetails", "TableNaming_Delimiter") />
			<cfset application.SLCMS.config.DatabaseDetails.TableNaming_SystemMarker = getProfileString("#theBaseConfigPath#", "DatabaseDetails", "TableNaming_SystemMarker") />
			<cfset application.SLCMS.config.DatabaseDetails.UserDetailTable_Admin = getProfileString("#theBaseConfigPath#", "DatabaseDetails", "UserDetailTable_Admin") />
			<cfset application.SLCMS.config.DatabaseDetails.databaseTableNaming_Root_System = 
							application.SLCMS.config.DatabaseDetails.TableNaming_Base 
						& application.SLCMS.config.DatabaseDetails.TableNaming_Delimiter
						& application.SLCMS.config.DatabaseDetails.TableNaming_SystemMarker
						& application.SLCMS.config.DatabaseDetails.TableNaming_Delimiter />
			<cfset application.SLCMS.config.DatabaseDetails.TableName_SystemAdminDetailsTable = 
							application.SLCMS.config.DatabaseDetails.databaseTableNaming_Root_System 
						& application.SLCMS.config.DatabaseDetails.UserDetailTable_Admin />
			 --->
			<!--- now we have those details for ron we can get on with creating the database --->
			<cfset theCurrentVersionPath = "#application.SLCMS.config.startup.InstallationFilesPath#Versions/Current_Version/" />
			<cfset theVersionIniFilePath = "#theCurrentVersionPath#WorkFlow_NewInstall.ini.cfm" />
			<cfif FileExists(theVersionIniFilePath)>
	  		<cftry>
					<cfset variables.DataMgr = createObject("component","#variables.Paths.DataMgrDotted#").init(datasource="#theData.DSN_SLCMS.data#") />
					<cfset theXMLTableFileCount = getProfileString(theVersionIniFilePath, "DatabaseTables", "ItemCount") />
					<cfif theXMLTableFileCount>
						<!--- we have some definitions to load so lets do it --->
						<cfloop from="1" to="#theXMLTableFileCount#" index="thisItem">
							<cfset theTableDefFileName = getProfileString(theVersionIniFilePath, "DatabaseTables", "Item_#thisItem#") />
							<cfset theTableDefFileName = theCurrentVersionPath & theTableDefFileName & ".xml.cfm" />
							<!--- we are now pointing at a database definition xml file so load into the DAL --->
			  			<cfif FileExists(theTableDefFileName)>
								<cftry>
									<cffile action="read" file="#theTableDefFileName#" variable="theXML" >
									<cfset LoadRet = variables.DataMgr.loadXML(xmldata=theXML, docreate=True, addcolumns=True)>	<!---  with the two true flags this will create tables and columns as needed --->
								<cfcatch>
									<cfset application.SLCMS.config.startup.initialization.installationTemp["#theFlow#"].Steps["Step_2"].error.errorCode = BitOr(application.SLCMS.config.startup.initialization.installationTemp["#theFlow#"].Steps["Step_2"].error.errorCode, 8) />
									<cfset temp = "The Database Definition load of #theTableDefFileName# Failed." />
									<cfset theErrorString = theErrorString & "#temp#<br>" />
									<cfset temp = temp & " - Time: #DateFormat(Now(),"YYYYMMDD")#-#TimeFormat(now(),"HH:mm:ss")#" />
									<cflog text='#temp#' file="InstallWizard" type="Information" application = "yes">
									<cfset temp = temp & "Error Message: #cfcatch.message#; detail: #cfcatch.detail#" />
									<cffile action="append" file="#variables.Paths.LogFile#" output="#temp#" addnewline="true" />
								</cfcatch>
								</cftry>
			  			<cfelse>
								<cfset theErrorString = theErrorString & "Error: The Database XML Definition File is missing!" />
								<cfset theErrorString = theErrorString & '<br>Was looking for: #theTableDefFileName#' />
								<cfset application.SLCMS.config.startup.initialization.installationTemp["#theFlow#"].Steps["Step_2"].error.errorCode = BitOr(application.SLCMS.config.startup.initialization.installationTemp["#theFlow#"].Steps["Step_2"].error.errorCode, 16) />
			  			</cfif>
						</cfloop>
					</cfif>
					<!--- now rinse and repeat for any data we need to load --->
					<!---		
						this does work in current incarnation of DataMgr so we have put the data in the definition files above
						
					<cfset theXMLTableFileCount = getProfileString(theVersionIniFilePath, "TableData", "ItemCount") />
					<cfif theXMLTableFileCount>
						<!--- we have some definitions to load so lets do it --->
						<cfloop from="1" to="#theXMLTableFileCount#" index="thisItem">
							<cfset theTableDefFileName = getProfileString(theVersionIniFilePath, "TableData", "Item_#thisItem#") />
							<cfset theTableDefFileName = theVersionPath & theTableDefFileName & ".xml" />
							<!--- we are now pointing at a data definition xml file so load into the DAL --->
							<cftry>
								<cffile action="read" file="#theTableDefFileName#" variable="theXML" >
								<cfset LoadRet = variables.DataMgr.loadXML(xmldata=theXML, docreate=True, addcolumns=False)>
							<cfcatch>
								<cfset theErrorString = theErrorString & "The Database Data load of #theTableDefFileName# Failed.<br>" />
							</cfcatch>
							</cftry>
						</cfloop>
					</cfif>
					--->
				<cfcatch>
					<cfset theErrorString = theErrorString & "Error: The Database creation failed!" />
					<cfset theErrorString = theErrorString & '<br>Error was: #cfcatch.message#, error detail was: #cfcatch.detail#' />
					<cfset application.SLCMS.config.startup.initialization.installationTemp["#theFlow#"].Steps["Step_2"].error.errorCode = BitOr(application.SLCMS.config.startup.initialization.installationTemp["#theFlow#"].Steps["Step_2"].error.errorCode, 32) />
				</cfcatch>
	  		</cftry>
			<cfelse>
				<cfset application.SLCMS.config.startup.initialization.installationTemp["#theFlow#"].Steps["Step_2"].error.errorCode = BitOr(application.SLCMS.config.startup.initialization.installationTemp["#theFlow#"].Steps["Step_2"].error.errorCode, 4) />
				<cfset theErrorString = theErrorString & "Error: The Database Definition Control File is Missing!" />
				<cfset theErrorString = theErrorString & '<br>Was looking for: #theVersionIniFilePath#' />
			</cfif>
			<cfset application.SLCMS.config.startup.initialization.installationTemp["#theFlow#"].Steps["Step_2"].error.errorText = "#theErrorString#" />
		</cfif>
		<!--- flag the next step in the regular flow - we go forward error or not on this one --->
		<cfset CheckNsetStepDataStruct(Step="4", Flow="Mainflow") />
		<cfset application.SLCMS.config.startup.initialization.installationTemp.CurrentFlow = "MainFlow" />
		<cfset application.SLCMS.config.startup.initialization.installationTemp.CurrentStepNumber = "4" />	
		<cfset application.SLCMS.config.startup.initialization.installationTemp.CurrentStepMode = "Display" />
	<cfcatch type="any">
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 128) />
		<cfset ret.error.ErrorText = ret.error.ErrorContext & ' Trapped. error message was: #cfcatch.message#, error detail was: #cfcatch.detail#' />
		<cfset ret.error.ErrorExtra =  cfcatch.TagContext />
		<cfif isArray(ret.error.ErrorExtra) and StructKeyExists(ret.error.ErrorExtra[1], "Raw_Trace")>
			<cfset ret.error.ErrorText = ret.error.ErrorText & ", Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#" />
		</cfif>
		<cflog text='#ret.error.ErrorText# - ret.error.ErrorCode: #ret.error.ErrorCode# - Time: #DateFormat(Now(),"YYYYMMDD")#-#TimeFormat(now(),"HH:mm:ss")#'  file="SLCMS_Common" type="Error" application = "yes">
		<cfoutput>#ret.error.ErrorContext#</cfoutput> Trapped - error dump:<br>
		<cfdump var="#cfcatch#">
		<cfabort>
	</cfcatch>
	</cftry>

	<cfreturn ret  />
</cffunction>

<cffunction name="ProcessPage_Mainflow_Step_4" output="yes" returntype="struct" access="public"
	displayname="ProcessPage - Mainflow Step 4"
	hint="Process the next step from MainFlow page step 4, it does nothing, we just move to the Superuser setup - step 5"
	>
	<!--- this function needs takes no arguments, everything is in external scopes --->

	<!--- now all of the var declarations, first the vars that will get filled as we go --->
	<cfset var theData = application.SLCMS.config.startup.initialization.installationTemp['MainFlow'].Steps['Step_1'].data />
	<cfset var theFlow = "MainFlow" />	<!--- temp just to keep the name short --->
	<cfset var LoadRet = "" />	<!--- return from the loadXML call --->
	<cfset var theVersionPath = "" />	<!--- temp var --->
	<cfset var theVersionIniFilePath = "" />	<!--- temp var --->
	<cfset var theXMLTableFileCount = "" />
	<cfset var thisItem = "" />	
	<cfset var theTableDefFileName = "" />	<!--- will be the entry in the ini file, the table definition --->
	<cfset var theXML = "" />
	<cfset var ret2 = "" />	<!--- return string from profile set for ConfigMapper --->
	<cfset var ret3 = "" />	<!--- return string from profile set for Config_xxx Ini --->
	<cfset var theErrorString = "" />
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorContext = "InitialInstalationWizard ProcessPage_Step_Mainflow_4()" />
	<cfset ret.error.ErrorText = "" />
	<cfset ret.error.ErrorExtra = "" />
	<cfset ret.Data = "" />	<!--- and no data yet --->

	<cftry>
		<cfif theErrorString eq "">
			<!--- all good so set up for the next step as we are walk thru --->
			<cfset CheckNsetStepDataStruct(Step="5", Flow="Mainflow") />
			<cfset application.SLCMS.config.startup.initialization.installationTemp.CurrentStepMode = "Display" />	<!--- display next page --->
			<cfset application.SLCMS.config.startup.initialization.installationTemp.CurrentStepNumber = "5" />	<!--- flag back the next step in the regular flow --->
			<cfset application.SLCMS.config.startup.initialization.installationTemp.CurrentFlow = "MainFlow" />
		<cfelse>
			<cfset application.SLCMS.config.startup.initialization.installationTemp.CurrentStepMode = "Display" />	<!--- flag back the same step for its display page --->
		</cfif>
		<cffile action="append" file="#variables.Paths.LogFile#" output="Installation Wizard ProcessPage_Mainflow_Step_4() called - Time: #DateFormat(Now(),"YYYYMMDD")#-#TimeFormat(now(),"HH:mm:ss")#." addnewline="true" />
  	<!---
		<cfset theVersionPath = "#application.SLCMS.config.startup.DataFolderPath#Versions/Current_Version/" />
		<cfset theVersionIniFilePath = "#theVersionPath#WorkFlow_NewInstall.ini" />
		<cfif FileExists(theVersionIniFilePath)>
			<cfset variables.DataMgr = createObject("component","#variables.Paths.DataMgrDotted#").init(datasource="#theData.DSN_SLCMS.data#") />
			<cfset theXMLTableFileCount = getProfileString(theVersionIniFilePath, "DatabaseTables", "ItemCount") />
			<cfif theXMLTableFileCount>
				<!--- we have some definitions to load so lets do it --->
				<cfloop from="1" to="#theXMLTableFileCount#" index="thisItem">
					<cfset theTableDefFileName = getProfileString(theVersionIniFilePath, "DatabaseTables", "Item_#thisItem#") />
					<cfset theTableDefFileName = theVersionPath & theTableDefFileName & ".xml" />
					<!--- we are now pointing at a database definition xml file so load into the DAL --->
					<cftry>
						<cffile action="read" file="#theTableDefFileName#" variable="theXML" >
						<cfset LoadRet = variables.DataMgr.loadXML(xmldata=theXML, docreate=True, addcolumns=True)>	<!---  with the two true flags this will create table and columns --->
					<cfcatch>
						<cfset theErrorString = theErrorString & "The Database Definition load of #theTableDefFileName# Failed.<br>" />
					</cfcatch>
					</cftry>
				</cfloop>
			</cfif>
			--->
			<!--- now rinse and repeat for any data we need to load --->
			<!---		
				this does work in current incarnation of DataMgr so we have put the data in the definition files above
				
			<cfset theXMLTableFileCount = getProfileString(theVersionIniFilePath, "TableData", "ItemCount") />
			<cfif theXMLTableFileCount>
				<!--- we have some definitions to load so lets do it --->
				<cfloop from="1" to="#theXMLTableFileCount#" index="thisItem">
					<cfset theTableDefFileName = getProfileString(theVersionIniFilePath, "TableData", "Item_#thisItem#") />
					<cfset theTableDefFileName = theVersionPath & theTableDefFileName & ".xml" />
					<!--- we are now pointing at a data definition xml file so load into the DAL --->
					<cftry>
						<cffile action="read" file="#theTableDefFileName#" variable="theXML" >
						<cfset LoadRet = variables.DataMgr.loadXML(xmldata=theXML, docreate=True, addcolumns=False)>
					<cfcatch>
						<cfset theErrorString = theErrorString & "The Database Data load of #theTableDefFileName# Failed.<br>" />
					</cfcatch>
					</cftry>
				</cfloop>
			</cfif>
			--->
		<!---	
		<cfelse>
			<cfset theErrorString = "Error: The Database Definition Control File is Missing!" />
		</cfif>
		<cfset application.SLCMS.config.startup.initialization.installationTemp["#theFlow#"].Steps["Step_3"].error.errorText = "#theErrorString#" />
		<cfif theErrorString eq "">
			<!--- all good so set up for the next step as we are walk thru --->
			<cfset CheckNsetStepDataStruct(Step="4", Flow="Mainflow") />
			<cfset application.SLCMS.config.startup.initialization.installationTemp.CurrentStepMode = "Display" />	<!--- display next page --->
			<cfset application.SLCMS.config.startup.initialization.installationTemp.CurrentStepNumber = "5" />	<!--- flag back the next step in the regular flow --->
			<cfset application.SLCMS.config.startup.initialization.installationTemp.CurrentFlow = "MainFlow" />
		<cfelse>
			<cfset application.SLCMS.config.startup.initialization.installationTemp.CurrentStepMode = "Display" />	<!--- flag back the same step for its display page --->
		</cfif>
		--->
	<cfcatch type="any">
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 128) />
		<cfset ret.error.ErrorText = ret.error.ErrorContext & ' Trapped. error message was: #cfcatch.message#, error detail was: #cfcatch.detail#' />
		<cfset ret.error.ErrorExtra =  cfcatch.TagContext />
		<cfif isArray(ret.error.ErrorExtra) and StructKeyExists(ret.error.ErrorExtra[1], "Raw_Trace")>
			<cfset ret.error.ErrorText = ret.error.ErrorText & ", Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#" />
		</cfif>
		<cflog text='#ret.error.ErrorText# - ret.error.ErrorCode: #ret.error.ErrorCode# - Time: #DateFormat(Now(),"YYYYMMDD")#-#TimeFormat(now(),"HH:mm:ss")#'  file="SLCMS_Common" type="Error" application = "yes">
		<cfoutput>#ret.error.ErrorContext#</cfoutput> Trapped - error dump:<br>
		<cfdump var="#cfcatch#">
		<cfabort>
	</cfcatch>
	</cftry>

	<!--- return our data structure --->
	<cfreturn ret  />
</cffunction>

<cffunction name="ProcessPage_Mainflow_Step_5" output="yes" returntype="struct" access="public"
	displayname="ProcessPage - Mainflow Step 5"
	hint="MainFlow process done, locate to site"
	>
	<cfset var theFlow = "MainFlow" />	<!--- temp just to keep the name short --->
	<cfset var theData = application.SLCMS.config.startup.initialization.installationTemp["#theFlow#"].Steps['Step_1'].data />
	<cfset var theQueryDataArguments = StructNew() />
	<cfset var LoadRet = "" />	<!--- return from the loadXML call --->
	<cfset var OK = True />
	<cfset var theLogin = request.wheels.params.SignIn />
	<cfset var thePassword = "" />
	<cfset var theFirstName = "" />
	<cfset var theLastName = "" />
	<cfset var theEddress = "" />
	<cfset var ErrFlag  = False />
	<cfset var ErrMsg  = "" />
	<!--- this function needs takes no arguments, everything is in external scopes --->
	<cffile action="append" file="#variables.Paths.LogFile#" output="Installation Wizard ProcessPage_Mainflow_Step_5() called - Time: #DateFormat(Now(),"YYYYMMDD")#-#TimeFormat(now(),"HH:mm:ss")#." addnewline="true" />
	<cfif len(theLogin) eq 0>
		<cfset OK = False />
		<cfset ErrFlag  = True />
		<cfset ErrMsg  = ErrMsg & "No Login Supplied<br>" />
	</cfif>
	<cfset thePassword = request.wheels.params.Password />
	<cfif len(thePassword) eq 0>
		<cfset OK = False />
		<cfset ErrFlag  = True>
		<cfset ErrMsg  = ErrMsg & "No Password Supplied<br>">
	</cfif>
	<cfset theFirstName = request.wheels.params.FirstName />
	<cfset theLastName = request.wheels.params.LastName />
	<cfif len(theFirstName) eq 0 and len(theLastName) eq 0>
		<cfset OK = False />
		<cfset ErrFlag  = True>
		<cfset ErrMsg  = ErrMsg & "No Name Supplied<br>">
	</cfif>
	<cfset theEddress = request.wheels.params.Eddress />
	<cfif theEddress neq "">
		<cfset OK = False />
		<cfset ErrFlag  = True>
		<cfset ErrMsg  = ErrMsg & "Invalid Email Address Supplied<br>">
	</cfif>
	<cfset variables.DataMgr = createObject("component","#variables.Paths.DataMgrDotted#").init(datasource="#theData.DSN_SLCMS.data#") />
	<cfset theQueryDataArguments.staffID = 0 />
	<cfset theQueryDataArguments.staff_SignIn = theLogin />
	<cfset theQueryDataArguments.staff_Password = thePassword />
	<cfset theQueryDataArguments.staff_FirstName = theFirstName />
	<cfset theQueryDataArguments.staff_LastName = theLastName />
	<cfset theQueryDataArguments.staff_Eddress = theEddress />
	<cfset theQueryDataArguments.Global_RoleBits = "11111111111111111111111111111111" />
	<cfset theQueryDataArguments.Global_RoleValue = -1 />
	<cfset theQueryDataArguments.User_Active = 1 />
	<cfset addUser = variables.DataMgr.InsertRecord(tablename="#application.SLCMS.config.DatabaseDetails.TableName_SystemAdminDetailsTable#", data=theQueryDataArguments) />
  	<!---
	<cfabort>  	
 --->
  	
	<!--- jump to the home page after clearing flags so we do a reload of application --->
	<cfset application.SLCMS.config.StartUp.FlushSerialFromInitWiz = "yes" />
	<cflocation url="#application.SLCMS.config.Base.RootURL##application.SLCMS.config.Base.ContentURL#" addtoken="false">
	
</cffunction>

<cffunction name="ProcessPage_Secondflow_Step_1" output="yes" returntype="struct" access="public"
	displayname="ProcessPage - Secondflow Step 1"
	hint="Process the form submission from SecondFlow page step 1"
	>
	<!--- this function needs takes no arguments, everything is in external scopes --->

	<!--- now all of the var declarations, first the vars that will get filled as we go --->
	<cfset var theFlow = "SecondFlow" />	<!--- temp just to keep the name short --->
	<cfset var lcntr = 0 />	<!--- temp loop counter --->
	<cfset var temp = "" />	<!--- temp/throwaway var --->
	<cfset var tempa = ArrayNew(1) />	<!--- temp/throwaway array --->
	<cfset var temps = StructNew() />	<!--- temp/throwaway structure --->
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorContext = "InitialInstalationWizard ProcessPage_Step_Secondflow_1()" />
	<cfset ret.error.ErrorText = "" />
	<cfset ret.error.ErrorExtra = "" />
	<cfset ret.Data = "" />	<!--- and no data yet --->

	<cffile action="append" file="#variables.Paths.LogFile#" output="Installation Wizard ProcessPage_Secondflow_Step_1() called - Time: #DateFormat(Now(),"YYYYMMDD")#-#TimeFormat(now(),"HH:mm:ss")#." addnewline="true" />
	<!--- no debugg wiz/help stuff yet, just a restart --->
	<cfset application.SLCMS.config.StartUp.FlushSerialFromInitWiz = "yes" />
	<cflocation url="#variables.Paths.theRootURL#" addtoken="false">
	<!--- return our data structure --->
	<cfreturn ret  />
</cffunction>

<!--- now the display functions --->
<cffunction name="index">
	<!--- work out where we are in the workflow and run the relevant step controller --->
	<cfif not StructKeyExists(variables, "Paths")>
		<cfset init() />
	</cfif>
	<cfset runRet = runStep() />	<!--- this will work out what to do next and call one of the processing functions above directly if relevant --->
<!--- 
<cfdump var="#runRet#" expand="false" label="Ret from runStep()">
<cfdump var="#application.SLCMS.config.startup.initialization#" expand="false" label="application.SLCMS.config.startup.initialization after runStep and b4 renderPage in index.cfm">
 --->

	<cfset theStep = application.SLCMS.config.startup.initialization.installationTemp.CurrentStepNumber />	<!--- things might have changed... --->
	<cfset theFlow = application.SLCMS.config.startup.initialization.installationTemp.CurrentFlow />
	<!--- <cfset variables.mytestvar = "hello me in the SLCMS install wizard index action" />
	variables["displayPageBody_#theFlow#_Step_#theStep#"] --->
	<cfset renderPage(controller="slcms.installWizard", action="#theFlow#_Step_#theStep#", layout="/slcms/installwizard/layout")>	<!--- then render the appropriate view --->
	<!--- display happened so set for the next happening, process the page results! --->
	<cfset application.SLCMS.config.startup.initialization.installationTemp.CurrentStepMode = "Process" />
	<cfset application.SLCMS.config.startup.initialization.installationTemp.NextStepMode = "Display" />
<!--- 
	<cfset renderPage(controller="slcms.installWizard", action="Baseflow_Step_1")>
--->
</cffunction>

<cffunction name="CheckNsetStepDataStruct" output="false" returntype="void" hint="Creates the data structure for supplied step if it does not exist">
	<cfargument name="Step" required="true">
	<cfargument name="Flow" required="true">
	
	<cfset var theStep = arguments.step />
	<cfset var theFlow = arguments.Flow />
	<!--- set up the base temp data struct for this step, what goes in it is step dependent --->
	<cfif not StructKeyExists(application.SLCMS.config.startup.initialization.installationTemp["#theFlow#"].Steps, "Step_#theStep#")>
		<cfset application.SLCMS.config.startup.initialization.installationTemp["#theFlow#"].Steps["Step_#theStep#"] = StructNew() />
		<cfset application.SLCMS.config.startup.initialization.installationTemp["#theFlow#"].Steps["Step_#theStep#"].data = StructNew() />
		<cfset application.SLCMS.config.startup.initialization.installationTemp["#theFlow#"].Steps["Step_#theStep#"].error = StructNew() />
		<cfset application.SLCMS.config.startup.initialization.installationTemp["#theFlow#"].Steps["Step_#theStep#"].error.errorCode = 0 />
		<cfset application.SLCMS.config.startup.initialization.installationTemp["#theFlow#"].Steps["Step_#theStep#"].error.errorText = "" />
		<cfset application.SLCMS.config.startup.initialization.installationTemp["#theFlow#"].Steps["Step_#theStep#"].StepNumber = theStep />
	</cfif>
	<!---
	<cfif not StructKeyExists(application.SLCMS.config.startup.initialization.installationTemp["#theFlow#"].Steps["Step_#theStep#"], "Data")>
		<cfset application.SLCMS.config.startup.initialization.installationTemp["#theFlow#"].Steps["Step_#theStep#"].data = StructNew() />
	</cfif>
	--->
</cffunction>

</cfcomponent>