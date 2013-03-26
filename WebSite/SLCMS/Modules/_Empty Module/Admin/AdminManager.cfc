<!--- mbc SLCMS CFCs  --->
<!--- &copy; 2010 mort bay communications --->
<!---  --->
<!--- the Module Controller CFC for a SLCMS module --->
<!--- provides the needed information for a module to be incorported into SLCMS and provided global control functions to configure the module --->
<!--- Contains:
			getBaseDefinition() - provides the config to SLCMS
			initModule() - initialises the whole kit and kaboodle, inits all the internal CFCs, etc., of this module, CFCs to be stored persistently, etc
			ReinitModule() - reinitialises anything that might need it after a external change of any sort
			 --->
<!---  --->
<!--- created:  29th May 2010 by Kym K, mbcomms --->
<!--- modified: 29th May 2010 -  6th Jun 2010 by Kym K, mbcomms - initial work on it --->

<cfcomponent displayname="Module Definition" hint="Defines what is in this Module and Initializes it" output="false">

<cffunction name="getBaseDefinition" output="yes" returntype="struct" access="public"
	displayname="get Base Definition"
	hint="sends all the config info to SLCMS on a restart/reconfig/flush"
	>
	<!--- this function takes no arguments --->

	<!--- now all of the var declarations, first the arguments which need manipulation --->
	<cfset var lcntr = 0 />	<!--- temp loop counter --->
	<cfset var temp = "" />	<!--- temp/throwaway var --->
	<cfset var tempa = ArrayNew(1) />	<!--- temp/throwaway array --->
	<cfset var temps = StructNew() />	<!--- temp/throwaway structure --->
	<!--- then the standard return structure, I'd be surprised if it errored but use the shape anyway --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorContext = "Blank Module Definition CFC: getBaseDefinition()" />
	<cfset ret.error.ErrorText = "" />
	<cfset ret.error.ErrorExtra = "" />
	<cfset ret.Data = StructNew() />	<!--- and no data yet --->
	<cfset ret.Data.ModuleNaming = StructNew() />	<!--- will be the name definitions --->
	<cfset ret.Data.CoreDependencies = StructNew() />	<!--- will be the core functions that this module depends on (used to decide when to call the ReInit function) --->
	<cfset ret.Data.ModuleDependencies = StructNew() />	<!--- flags which other modules this module needs to be able to run --->

		<!--- wrap the whole thing in a try/catch in case something breaks --->
		<cftry>
			<!--- tell SLCMS who we are are and what we do, etc --->
			<cfset ret.Data.ModuleNaming.FormalName = "Blank_module" />	<!--- the name used in menus and admin and the like --->
			<cfset ret.Data.ModuleNaming.FriendlyName = "Blank module" />	<!--- the name used in menus and admin and the like --->
			<cfset ret.Data.ModuleNaming.Description = "SLCMS Module as a sample to clone" />	<!--- description of what this module is all about --->
		<cfcatch type="any">
			<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 128) />
			<cfset ret.error.ErrorText = ret.error.ErrorContext & ' Trapped. Site: #application.SLCMS.config.base.SiteName#, error message was: #cfcatch.message#, error detail was: #cfcatch.detail#' />
			<cfset ret.error.ErrorExtra =  cfcatch.TagContext />
			<cflog text="getBaseDefinition() Trapped. Site: #application.SLCMS.config.base.SiteName#. ret.error.ErrorCode: #ret.error.ErrorCode# - Error Text: #ret.error.ErrorText# - Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#"  file="SLCMSerrors" type="Error" application = "yes">
			<cfif application.SLCMS.config.debug.debugmode>
				getBaseDefinition() Trapped - error dump:<br>
				<cfdump var="#ret.error.ErrorExtra#">
			</cfif>
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
	<cfset ret.error.ErrorText = "" />
	<cfset ret.error.ErrorExtra = "" />
	<cfset ret.Data = "" />	<!--- and no data yet --->

	<cfset variables.theConfig = arguments.ApplicationConfig />
<!--- 

	<cfdump var="#arguments#" expand="false">

 --->
	
	<cfreturn ret  />
</cffunction>

<cffunction name="ReInitAfter" output="yes" returntype="struct" access="public"
	displayname="Re-Init After"
	hint="re-initialize Core components after some external change"
	>
	<!--- this function needs.... --->
	<cfargument name="Action" type="string" default="" hint="the action that took place, used to define the components that need re-initializing" />

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
	<cfset ret.error.ErrorContext = "Core ModuleController CFC: ReInitAfter() Action: #theAction#" />
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
			<cflog text='#ret.error.ErrorText# - ret.error.ErrorCode: #ret.error.ErrorCode# - Time: #DateFormat(Now(),"YYYYMMDD")#-#TimeFormat(now(),"HH:mm:ss")#'  file="#Application.Logging.theSiteLogName#" type="Error" application = "yes">
		</cfif>
	<cfcatch type="any">
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 128) />
		<cfset ret.error.ErrorText = ret.error.ErrorContext & ' Trapped. Site: #application.SLCMS.config.base.SiteName#, error message was: #cfcatch.message#, error detail was: #cfcatch.detail#' />
		<cfset ret.error.ErrorExtra =  cfcatch.TagContext />
		<cfif isArray(ret.error.ErrorExtra) and StructKeyExists(ret.error.ErrorExtra[1], "Raw_Trace")>
			<cfset ret.error.ErrorText = ret.error.ErrorText & ", Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#" />
		</cfif>
		<cflog text='#ret.error.ErrorText# - ret.error.ErrorCode: #ret.error.ErrorCode# - Time: #DateFormat(Now(),"YYYYMMDD")#-#TimeFormat(now(),"HH:mm:ss")#'  file="#Application.Logging.theSiteLogName#" type="Error" application = "yes">
		<cfif application.SLCMS.config.debug.debugmode>
			<cfoutput>#ret.error.ErrorContext#</cfoutput> Trapped - error dump:<br>
			<cfdump var="#cfcatch#">
		</cfif>
	</cfcatch>
	</cftry>

	<!--- return our data structure --->
	<cfreturn ret  />
</cffunction>


</cfcomponent>

