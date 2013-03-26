<!--- 
docs: startDescription
docs: SLCMS Functions Include
docs: &copy; 2012 mort bay communications
docs: Functions include
docs: the Module Controller CFC for a SLCMS module
docs: provides the needed information for the module to be incorporated into SLCMS and provides global control functions to configure the module
docs: endDescription
docs: 
docs: startParams
docs:	Name: EmptyCFC
docs:	Type:	CFC - NotPersistent 
docs:	Role:	Module Definition and Initialization - Module 
docs:	Hint: does stuff
docs:	Versions: CFC - 1.0.0; Core - 3.0.0+
docs: endParams
docs: 
docs: startFunctions
docs: getBaseDefinition() - provides the config to SLCMS's Module Manager
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
docs: Note also that this code has evolved all the way from CF 4.5 when it was training code for new mbcomms developers 
docs: and custon tags were new and CFCs unheard off so some constructs are very old fashioned.
docs: The decision was made to go opensource at about the same time that OpenBD and Railo appeared and neither supported the shorthand struct and array constructors initially
docs: so when we upgraded the code base and also moved a lot of code to CFCs we left a lot of code as it was, very old-fashioned. 
docs: But it works :-)
docs:   Now, late 2012, the code is being migrated to CFWheels as we are now looking at much more complex modules and the CFW framework is going to assist a lot.
docs: This means that we are also moving from a by-configuration to a by-convention architecture so a lot of the path-setting configuration is now going. We are also moving the the CFW coding style where viable as it is is very similar to ours anyway and will assist other folk in their coding efforts as SLCMS becomes a global force!
docs: endManual
docs: 
docs: startHistory_Versions
docs: Version 1.0.0.0  : 	Base CFC
docs: Version 1.0.0.383: 	added this documentation commenting
docs: endHistory_Versions
docs:
docs: startHistory_Coding
docs:	recreated:11th Jun 2011 by Kym K, mbcomms
docs:	modified: 11th Jun 2011 - 19th Jun 2011 by Kym K, mbcomms: initial work on it
docs: modified: 20th Aug 2011 - 24th Aug 2011 by Kym K, mbcomms: added more getBaseDefinition() structs
docs:	modified: 30th Mar 2012 - 30th Mar 2012 by Kym K, mbcomms: updated to include the documentation engine notation
docs:	modified: 11th Nov 2012 - 11th Nov 2012 by Kym K, mbcomms: updated to new CFWheels version 3+ code
docs: endHistory_Coding
 --->


<!--- The functions here are globally available to all things! Act with care :-) --->
<!--- the way CFWheels works is that this file is included in every page request so the functions become available to all direct code processing but not in CFCs, they would have to include this file directly, just as CFW does --->


<cffunction name="SLCMS_getVariablesScope"output="No" returntype="struct" access="public"  
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

<cffunction name="SLCMS_TakeErrorCatch" output="Yes" returntype="any" access="private" 
	displayname="Take Error Catch"
	hint="Takes Error Trap in function and logs/displays it, etc"
	>
	<cfargument name="RetErrorStruct" type="struct" required="true" hint="the ret structure from the calling function" />	
	<cfargument name="CatchStruct" type="any" required="true" hint="the catch structure from the calling function" />	
	
	<!--- our temp vars --->
	<cfset var loc = {} />	<!--- for local variables --->
	<cfset var error = {} />	<!--- this is the return to the caller --->
	<cfset loc.temps = "" />
	<!--- load up the return structure with a clean, empty result it is just the error part of the standard ret struct --->
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
		<cfset loc.temps = LogIt(LogType="CFC_ErrorCatch", LogString='#error.ErrorText# - ErrorCode: #error.ErrorCode#') />
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

<cffunction name="SLCMS_LogIt" output="No" returntype="struct" access="public"
	displayname="Log It"
	hint="Local Function in every CFC to log info to standard log space via SLCMS_Utility.WriteLog_Core(), minimizes log code in individual functions"
	>
	<cfargument name="LogType" type="string" default="" hint="The log to write to" />
	<cfargument name="LogString" type="string" default="" hint="The string to write to the log" />

	<cfset var loc = {} />	<!--- for local variables --->
	<cfset var ret = {} />	<!--- this is the return to the caller --->
	<cfset loc.theLogType = trim(arguments.LogType) />
	<cfset loc.theLogString = trim(arguments.LogString) />
	<cfset loc.temps = StructNew() />	<!--- temp/throwaway structure --->
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorText = "" />
	<cfset ret.error.ErrorContext = "_Empty_Core CFC: LogIt()" />
	<cfset ret.error.ErrorExtra = "" />
	<cfset ret.Data = "" />	<!--- no data --->

	<!--- minimal validation --->
	<cfif loc.theLogType neq "">
		<cftry>
			<cfset loc.temps = application.SLCMS.core.SLCMS_Utility.WriteLog_Core(LogType="#loc.theLogType#", LogString="#loc.theLogString#") />
			<cfif loc.temps.error.errorcode neq 0>
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
