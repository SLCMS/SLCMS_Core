<cfcomponent output="No"
	displayname="Site Admin Controller Helpers CFC" 
	hint="provides presistent functions used by the SLCMS controllers"
	>
<!--- 
docs: startDescription
docs: SLCMS Core CFC
docs: &copy; 2012 mort bay communications
docs: Empty CFC - Persistent, or not
docs: Manages things in SLCMS
docs: words go here to describe what this CFC does
docs: endDescription
docs: 
docs: startParams
docs:	Name: EmptyCFC
docs:	Type:	CFC - Persistent, or not 
docs:	Role:	some functions - Core 
docs:	Hint: does stuff
docs:	Versions: CFC - 1.0.0; Core - 2.2.0+
docs: endParams
docs: 
docs: startFunctions
docs: init() - sets up this CFC
docs: getVariablesScope() - shows the variables scope, often used in debugging
docs: TakeErrorCatch() - common handler for try/catch logging - private function
docs: LogIt() - sends supplied info to global logging engine - private function
docs: endFunctions
docs: 
docs: startManual
docs: 
docs: endManual
docs: 
docs: startHistory_Versions
docs: Version 1.0.0.0  : 	Base tag
docs: Version 1.0.0.383: 	added this documentation commenting
docs: endHistory_Versions
docs:
docs: startHistory_Coding
docs:	recreated:11th Jun 2011 by Kym K, mbcomms
docs:	modified: 11th Jun 2011 - 19th Jun 2011 by Kym K, mbcomms: initial work on it
docs:	modified: 30th Mar 2012 - 30th Mar 2012 by Kym K, mbcomms: updated to include the documentation engine notation
docs: endHistory_Coding
 --->
	
	<!--- set up a few persistant things on the way in. --->
	<cfset variables.something = "" />
	<cfset variables.SomeThingElse = "" />

<!--- initialize the various thingies, this should only be called after an app scope refresh --->
<cffunction name="init" output="No" returntype="any"	access="public" 
	displayname="Initializer"
	hint="Inits whatever needs to be Inited"
	>

	<cfset temps = LogIt(LogType="CFC_Init", LogString="Controller Helpers - Admin: Init() Finished") />
	<!--- return the standard struct --->
	<cfreturn this  />
</cffunction>

<cffunction name="ReInitAfter" output="No" returntype="any" access="public" 
	displayname="ReInitializer"
	hint="used to reinitialize the CFC when system is running after core config has changed"
	>
	
	<!--- some temp vars --->
	<cfset var Initialization = StructNew() />	<!--- this is the return to the caller --->
	<cfset var temps = "" />
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorContext = "Controller Helpers - Admin: ReInitAfter()" />
	<cfset ret.error.ErrorText = "" />
	<cfset ret.error.ErrorExtra = "" />
	<cfset ret.Data = "" />	<!--- and no data yet --->

	<cfset temps = LogIt(LogType="CFC_Init", LogString="Controller Helpers - Admin: ReInit() Started") />
	<cftry>
		<!--- do init stuff here --->
		
		<cfif ret.error.ErrorCode>
			<cfset temps = LogIt(LogType="CFC_Error", LogString='#ret.error.ErrorText# - ret.error.ErrorCode: #ret.error.ErrorCode#') />
		</cfif>
	<cfcatch type="any">
		<cfset ret.error = TakeErrorCatch(RetErrorStruct=ret.error, CatchStruct=cfcatch) />
	</cfcatch>
	</cftry>	
	<cfset temps = LogIt(LogType="CFC_Init", LogString="Controller Helpers: Admin - ReInit() Finished") />
	<cfreturn Ret  />
</cffunction>
<!--- now we have the real functions we want to use --->

<cffunction name="setPageContextFlags"output="No" returntype="struct" access="public"  
	displayname="set Page Context Flags"
	hint="sets the flags used to manage display context, standalone page or popdown over main site"
	>
	<cfargument name="PrependString" type="string" required="no" default="" hint="string to prepend the standard head/title text">
	<cfset PageFlags = {} />
	<cfset PageFlags.IsAdminHomePage = False />
	<cfset PageFlags.BannerHeadString = arguments.PrependString & ' for the <span class="AdminHeadingSiteName">#application.slcms.config.base.SiteName#</span> website' />
	<cfset PageFlags.HeadTitleString = "SLCMS Admin::" & arguments.PrependString & "::#application.slcms.config.base.SiteName#" />
	<cfif application.SLCMS.core.UserPermissions.IsLoggedin()>
		<cfset PageFlags.ShowGoToSiteLink = True />
		<cfset PageFlags.ShowSignInLink = False />
	<cfelse>
		<cfset PageFlags.ShowGoToSiteLink = False />
		<cfset PageFlags.ShowSignInLink = True />
	</cfif>
	<cfif request.SLCMS.flags.PoppedAdminPage>
		<cfset PageFlags.ReturnLinkParams = "&amp;#request.SLCMS.flags.PoppedAdminURLFlagString#" />
	<cfelse>
		<cfset PageFlags.ReturnLinkParams = "" />
	</cfif>
	<!--- as the admin pages can be got at if web server hacked add a second level of security --->
	<cfif not StructKeyExists(session.slcms.user.security, "thisPageSecurityID")>
		<cfset session.slcms.user.security.thisPageSecurityID = CreateUUID()>
	</cfif>
	<cfset PageFlags.ReturnLinkParams = "SecID=#session.slcms.user.security.thisPageSecurityID##PageFlags.ReturnLinkParams#" />
	<cfreturn PageFlags />
</cffunction>


<!--- and then the standard tailend stuff --->
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
		<cflog text='TakeErrorCatch: Error Catch Caught: #error.ErrorText# - error.ErrorCode: #error.ErrorCode# - Time: #DateFormat(Now(),"YYYYMMDD")#-#TimeFormat(now(),"HH:mm:ss")#'  file="#Application.Logging.theSiteLogName#" type="Error" application = "yes">
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
	<cfset ret.error.ErrorContext = "Controller Helpers - Admin: LogIt()" />
	<cfset ret.error.ErrorExtra = "" />
	<cfset ret.Data = "" />	<!--- no data --->

	<!--- minimal validation --->
	<cfif theLogType neq "">
		<cftry>
			<cfset temps = application.core.SLCMS_Utility.WriteLog_Core(LogType="#theLogType#", LogString="#theLogString#") />
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
			<cflog text='#ret.error.ErrorText# - ret.error.ErrorCode: #ret.error.ErrorCode# - Time: #DateFormat(Now(),"YYYYMMDD")#-#TimeFormat(now(),"HH:mm:ss")#'  file="#Application.Logging.theSiteLogName#" type="Error" application = "yes">
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
