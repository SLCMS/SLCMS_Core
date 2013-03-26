<cfcomponent output="No"
	displayname="SLCMS Utilities" 
	hint="contains standard utilities common to the whole SLCMS architecture such as low level system tools"
	>
	<!--- mbc SLCMS CFCs  --->
	<!--- &copy; 2011 mort bay communications --->
	<!---  --->
	<!--- SLCMS_Utility CFC  --->
	<!--- does utility stuff oddly enuf --->
	<!--- Contains:
				init - sets up 
				createSystemFlag, getSystemFlag, setSystemFlag - handle global system flags
				DoPagesHaveTemplatesOnly - flag
				WriteLog_Core - writes a standard log to log area, used by the two below which are everywhere, in all CFCs
				LogIt() - sends supplied info to global logging engine - private function
				TakeErrorCatch() - common handler for try/catch logging - private function
				 --->
	<!---  --->
	<!--- created:   9th Dec 2008 by Kym K, mbcomms --->
	<!--- modified:  9th Dec 2008 - 13th Dec 2008 by Kym K, mbcomms: initial work on it --->
	<!--- modified: 16th Dec 2009 - 16th Dec 2009 by Kym K, mbcomms: V2.2+ now adding DataMgr as a DAL to make the codebase database agnostic
																																					NOTE: things like the DSN are no longer needed as the DAL knows that
																																								now we can just worry about tables and their contents
																																								See Content_DatabaseIO.cfc for DAL conversion examples (straight queries commented out there, not deleted as here) --->
	<!--- modified: 19th Mar 2011 - 20th Mar 2011 by Kym K, mbcomms: added system flag setting functions in/out of the system flags db table --->
	<!--- modified:  7th Jun 2011 - 19th Jun 2011 by Kym K, mbcomms: added logging functions so we can have consistent logging outside CF's logs --->
	<!--- modified:  9th Apr 2012 -  9th Apr 2012 by Kym K, mbcomms: V3.0, CFWheels version. All SLCMS in own struct under app scope --->

	<!--- set up a few persistant things on the way in. --->
	<cfset variables.SiteBasePath = "" /> <!--- base path to the site, it all lies below here :-) --->
	<cfset variables.DatabasePath = "" /> <!--- below the above, in a manner of speaking, but maybe not... --->
	<cfset variables.LogsPath_Rel = "Logs" /> <!--- below the above, but we choose where, note the lack of a trailing slash --->
	<cfset variables.dsn = "" />	<!--- the main SLCMS database --->
	<cfset variables.DBSystemTableNamePrepend = "" />	<!--- the database table name prepend string built from the config files --->
	<cfset variables.DBFlagTable = "" />	<!--- the database table that has the system flags --->
	<cfset variables.LogTypeDefs = StructNew() />	<!--- a struct of allowed log types, defined so can be read by the outside --->
	<cfset variables.LogTypeDefs["Audit_Signin"] = {Name="Audit_Signin", Description="Logs all sign in and out activity", FileName="Audit_Signin"} />
	<cfset variables.LogTypeDefs["System_Init"] = {Name="System_Init", Description="Logs activity on system initialization", FileName="System_Init"} />
	<cfset variables.LogTypeDefs["CFC_Init"] = {Name="CFC_Init", Description="Logs init calls to CFCs", FileName="CFC_Init"} />
	<cfset variables.LogTypeDefs["CFC_Error"] = {Name="Error", Description="Logs Errors logged in CFCs", FileName="CFC_Error"} />
	<cfset variables.LogTypeDefs["CFC_ErrorCatch"] = {Name="ErrorCatch", Description="Logs Errors caught in CFCs", FileName="CFC_ErrorCatch"} />
	<cfset variables.LogTypeList = StructKeyList(LogTypeDefs) />	<!--- list of the types of log file handled --->
	<cfset variables.LogCyclePeriod = "Monthly" />	<!--- period of each log file before cycled --->
	<cfset variables.LogFolder = "" />	<!--- where the log files are, will get filled by the init code --->
	
	<!--- here we set what flags are used by the core, what type they are and their default value if they have one --->
	<!--- this hard-coded list/struct can be added to as we add functionality --->
	<!--- THIS IS THE REFERENCE FOR THE CORE --->
	<cfset variables.Flags = StructNew() />
	<cfset variables.Flags.FlagTypeList = "text,numb,bool" /> 
	<cfset variables.Flags.Core = StructNew() />
	<cfset variables.Flags.Core.FlagList = "SystemIsConfigured,SystemHasBeenConfigured,PagesHaveTemplatesOnly" />
	<cfset variables.Flags.Core.SystemIsConfigured = {FlagType="bool", Value=False} />	<!--- this new-fangled shortcut notation, started using it now the OpenBD and Railo have caught up --->
	<cfset variables.Flags.Core.SystemHasBeenConfigured = {FlagType="bool", Value=False} />
	<cfset variables.Flags.Core.PagesHaveTemplatesOnly = {FlagType="bool", Value=True} />
	
	
	<!---
	<cfset variables.PluginPath = "" />	<!--- where the version control file is --->
	<cfset variables.VersionControlFilePath = "" />	<!--- where the version control file is --->
	--->

<!--- initialize the various thingies, this need only be called after an app scope refresh --->
<cffunction name="init" output="No" returntype="any" access="public" 
	displayname="Initializer"
	hint="sets up the internal structures for this component"
	>
	<!--- this function needs.... --->
	<cfargument name="StartUpPaths" type="struct" default="" hint="Struct of the absolute physical paths to the top of the website" />	
	<cfargument name="dsn" type="string" required="yes" hint="the name of the database that has the relevant tables such as 'Nexts'">
	<cfargument name="DatabaseDetails" type="struct" required="true" hint="the structure carrying all the naming bits of the db tables">

	<cfset var theQueryDataArguments = StructNew() />	<!--- temp struct to compose the data clauses of the SQL query --->
	<cfset var theQueryWhereArguments = StructNew() />	<!--- temp struct to compose the where clauses of the SQL query --->
	<cfset var qryFullFlags = "" /> <!--- DataMgr query return --->
	<cfset var FullFlagListfromQry = "" />
	<cfset var thisFlag = "" />
	<cfset var qryTemp = "" />
	<cfset var theFlagType = "" />
	<cfset var theDBvalue = "" />
	<!--- create the return structure --->
	<cfset var ret = StructNew() />
	<!--- and load it up with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorText = "" />
	<cfset ret.error.ErrorContext = "SLCMS_Utility CFC: Init()" />
	<cfset ret.error.ErrorExtra = "" />
	<cfset ret.Data = "" />	<!--- and no data yet --->
	
	<cftry>
		<!--- first the simple vars --->
		<cfset variables.dsn = arguments.dsn />
		<cfset variables.SiteBasePath = arguments.StartUpPaths.SiteBasePath />
		<cfset variables.LogFolder = arguments.StartUpPaths.LogPath />
		<!--- check that the log folder exists --->
		<cfif not DirectoryExists(variables.LogFolder)>
			<cfdirectory action="create" directory="#variables.LogFolder#">
		</cfif>
		<cfset variables.LogFolder = variables.LogFolder & "/" />	<!--- tidy up to our "always have a trailing slash" standard ---> 
		<cfset variables.LogTypeDefs["Audit_Signin"].FilePrePath = "#variables.LogFolder#Audit_Signin_" />
		<cfset variables.LogTypeDefs["System_Init"].FilePrePath = "#variables.LogFolder#System_Init_" />
		<cfset variables.LogTypeDefs["CFC_Init"].FilePrePath = "#variables.LogFolder#CFC_Init_" />
		<cfset variables.LogTypeDefs["CFC_Error"].FilePrePath = "#variables.LogFolder#CFC_Error_" />
		<cfset variables.LogTypeDefs["CFC_ErrorCatch"].FilePrePath = "#variables.LogFolder#CFC_ErrorCatch_" />
	
		<cfset temps = LogIt(LogType="CFC_Init", LogString="SLCMS_Utility Init() after variables.LogFolder set") />

		<!--- then the naming regime for the DB tables, almost as versatile as we can get it --->
		<!--- precalculate a few bits --->
		<cfset variables.DBSystemTableNamePrepend = arguments.DatabaseDetails.DatabaseTableNaming_Root_System /> <!--- default: "SLCMS_System_" --->
		<cfset variables.DBFlagTable = "#variables.DBSystemTableNamePrepend#Flags" />
		<!--- check the system flags table and load in the flags, creating new ones on the fly if we need to --->
		<!--- first get the db flag list --->
		<cfset theQueryDataArguments = StructNew() />
		<cfset theQueryWhereArguments = StructNew() />
		<cfset qryFullFlags = application.SLCMS.Core.DataMgr.getRecords(tablename="#variables.DBFlagTable#", data=theQueryWhereArguments, fieldList="FlagName,FlagType,State") />
		<cfset FullFlagListfromQry = ValueList(qryFullFlags.FlagName) />
		<!--- and update our local struct --->
		<!--- this is a full init so overwrite with the db values as we might be away from the defaults --->
		<cfloop query="qryFullFlags">
			<cfif not StructKeyExists(variables.Flags.Core, "#qryFullFlags.FlagName#")>
				<cfset variables.Flags.Core["#qryFullFlags.FlagName#"] = StructNew() />
				<cfset variables.Flags.Core.FlagList = ListAppend(variables.Flags.Core.FlagList, "#qryFullFlags.FlagName#") />
			</cfif>
			<cfset variables.Flags.Core["#qryFullFlags.FlagName#"].FlagType = qryFullFlags.FlagType />
			<cfif qryFullFlags.FlagType eq "bool">
				<cfif qryFullFlags.State eq "No" or qryFullFlags.State eq 0 or qryFullFlags.State eq "">
					<cfset variables.Flags.Core["#qryFullFlags.FlagName#"].Value = False /> 
				<cfelse>
					<cfset variables.Flags.Core["#qryFullFlags.FlagName#"].Value = True /> 
				</cfif>
			<cfelse>
				<cfset variables.Flags.Core["#qryFullFlags.FlagName#"].Value = qryFullFlags.State /> 
			</cfif> 
		</cfloop>
		<!--- now we need to check if we have done an update or something and we have new flags hard coded up above
					so we will do the loop in reverse and fill the db with the new flags --->
		<cfloop list="#variables.Flags.Core.FlagList#" index="thisFlag">
			<cfif not ListFindNoCase(FullFlagListfromQry, thisFlag)>
				<!--- oo, we have a local one not in the db --->
				<cfset theFlagType = variables.Flags.Core["#thisFlag#"].FlagType />
				<cfset theFlagValue = variables.Flags.Core["#thisFlag#"].Value />
				<cfif theFlagType eq "bool">
					<cfset theDBvalue = YesNoFormat(theFlagValue) />
				<cfelse>
					<cfset theDBvalue = theFlagValue />
				</cfif>
				<cfset theQueryDataArguments = StructNew() />
				<cfset theQueryWhereArguments = StructNew() />
				<cfset theQueryDataArguments.FlagName = thisFlag />
				<cfset theQueryDataArguments.FlagType = theFlagType />
				<cfset theQueryDataArguments.State = theDBvalue />
				<cfset qryTemp = application.SLCMS.Core.DataMgr.InsertRecord(tablename="#variables.DBFlagTable#", data=theQueryDataArguments) />
			</cfif>
		</cfloop>
			
	<!--- 
	<cfargument name="PluginRelPath" type="string" default="" />	<!--- The relative path to the plugins folder --->
	<cfargument name="VersionRelFile" type="string" default="" />	<!--- the relative path to the version control file itself --->
	 --->
	<!--- 
	<cfset var theVersionControlFilePath = trim(arguments.SiteBasePath) & trim(arguments.VersionRelFile) />
	<cfset var thePluginPath = trim(arguments.SiteBasePath) & trim(arguments.PluginRelPath) />
	 --->

	<cfcatch type="any">
		<cfset ret.error = TakeErrorCatch(RetErrorStruct=ret.error, CatchStruct=cfcatch) />
	</cfcatch>
	</cftry>
	
	<cfset temps = LogIt(LogType="CFC_Init", LogString="SLCMS_Utility Init() Finished") />
	<cfreturn ret />
</cffunction>

<cffunction name="createSystemFlag" output="No" returntype="struct" access="public"
	displayname="create System Flag"
	hint="creates a System Flag to supplied spec"
	>
	<!--- this function needs.... --->
	<cfargument name="FlagName" type="string" default="" hint="Name of the flag to get value of" />
	<cfargument name="FlagType" type="string" default="" hint="[text|numb|bool] the Type of the flag" />
	<cfargument name="FlagValue" type="any" default="" hint="Value of the flag" />

	<!--- now all of the var declarations, first the arguments which need manipulation --->
	<cfset var theFlagName = trim(arguments.FlagName) />
	<cfset var theFlagType = trim(arguments.FlagType) />
	<cfset var theFlagValue = trim(arguments.FlagValue) />
	<!--- now vars that will get filled as we go --->
	<cfset var theDBvalue = "" />
	<cfset var theQueryDataArguments = StructNew() />	<!--- temp struct to compose the data clauses of the SQL query --->
	<cfset var theQueryWhereArguments = StructNew() />	<!--- temp struct to compose the where clauses of the SQL query --->
	<cfset var qryTemp = "" /> <!--- DataMgr query return --->
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorText = "" />
	<cfset ret.error.ErrorContext = "SLCMS_Utility CFC: createSystemFlag()" />
	<cfset ret.error.ErrorExtra = "" />
	<cfset ret.Data = "" />	<!--- and no data yet --->

	<cfif len(theFlagName) and ListFindNoCase(variables.Flags.FlagTypeList, theFlagType)>
		<!--- feebly validated so go for it --->
		<!--- wrap the whole thing in a try/catch in case something breaks --->
		<cftry>
			<cfif not StructKeyExists(variables.Flags.Core, theFlagName)>
				<!--- no local struct key so throw this one in --->
				<cfset variables.Flags.Core[theFlagName] = StructNew() />
				<cfset variables.Flags.Core[theFlagName].FlagType = theFlagType />
				<cfif theFlagType eq "text" and IsSimpleValue(theFlagValue)>
					<cfset theDBvalue = theFlagValue />
				<cfelseif theFlagType eq "numb"  and IsNumeric(theFlagValue)>
					<cfset theDBvalue = theFlagValue />
				<cfelseif theFlagType eq "bool" and IsBoolean(theFlagValue)>
					<cfset theDBvalue = YesNoFormat(theFlagValue) />
				<cfelse>
					<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 4) />
					<cfset ret.error.ErrorText = ret.error.ErrorText & "Oops! Invalid Flag Data, type did not match value<br>" />
				</cfif>
				<cfif ret.error.ErrorCode eq 0>
					<cfset variables.Flags.Core[theFlagName].Value = theFlagValue />
					<!--- and drop into the database --->
					<cfset theQueryDataArguments.FlagName = theFlagName />
					<cfset theQueryDataArguments.FlagType = theFlagType />
					<cfset theQueryDataArguments.State = theDBvalue />
					<cfset qryTemp = application.SLCMS.Core.DataMgr.InsertRecord(tablename="#variables.DBFlagTable#", data=theQueryDataArguments) />
				</cfif>
			<cfelse>	<!--- this is the error code --->
				<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 2) />
				<cfset ret.error.ErrorText = ret.error.ErrorText & "Oops! Flag Name already exists<br>" />
			</cfif>
		<cfcatch type="any">
			<cfset ret.error = TakeErrorCatch(RetErrorStruct=ret.error, CatchStruct=cfcatch) />
		</cfcatch>
		</cftry>
	<cfelse>	<!--- this is the error code --->
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 1) />
		<cfset ret.error.ErrorText = ret.error.ErrorText & "Oops! No Flag Name supplied or bad type<br>" />
	</cfif>

	<!--- return our data structure --->
	<cfreturn ret  />
</cffunction>

<cffunction name="getSystemFlag" output="No" returntype="struct" access="public"
	displayname="get System Flag"
	hint="gets a System Flag and returns it within our standard structure to handle errors"
	>
	<!--- this function needs.... --->
	<cfargument name="FlagName" type="string" default="" hint="Name of the flag to get value of" />

	<!--- now all of the var declarations, first the arguments which need manipulation --->
	<cfset var theFlagName = trim(arguments.FlagName) />
	<!--- now vars that will get filled as we go --->
	<!--- oo! we haven't got any! :-) --->
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorText = "" />
	<cfset ret.error.ErrorContext = "SLCMS_Utility CFC: getSystemFlag()" />
	<cfset ret.error.ErrorExtra = "" />
	<cfset ret.Data = "" />	<!--- and no data yet --->

	<cfif len(theFlagName)>
		<!--- feebly validated so go for it --->
		<!--- wrap the whole thing in a try/catch in case something breaks --->
		<cftry>
			<cfif StructKeyExists(variables.Flags.Core, theFlagName)>
				<cfset ret.Data = variables.Flags.Core[theFlagName].Value />
				<cfif variables.Flags.Core[theFlagName].FlagType eq "bool" and ret.Data eq "No" or ret.Data eq 0 or ret.Data eq "">
					<cfset ret.Data = False />
				<cfelse> 
					<cfset ret.Data = True />
				</cfif>
			<cfelse>	<!--- this is the error code --->
				<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 2) />
				<cfset ret.error.ErrorText = ret.error.ErrorText & "Oops! Invalid Flag Name<br>" />
			</cfif>
		<cfcatch type="any">
			<cfset ret.error = TakeErrorCatch(RetErrorStruct=ret.error, CatchStruct=cfcatch) />
		</cfcatch>
		</cftry>
	<cfelse>	<!--- this is the error code --->
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 1) />
		<cfset ret.error.ErrorText = ret.error.ErrorText & "Oops! No Flag Name supplied<br>" />
	</cfif>

	<!--- return our data structure --->
	<cfreturn ret  />
</cffunction>

<cffunction name="setSystemFlag" output="No" returntype="struct" access="public"
	displayname="set System Flag"
	hint="sets a System Flag and returns our standard structure to handle errors"
	>
	<!--- this function needs.... --->
	<cfargument name="FlagName" type="string" default="" hint="Name of the flag to set value of" />
	<cfargument name="FlagValue" type="any" default="" hint="Value of the flag" />

	<!--- now all of the var declarations, first the arguments which need manipulation --->
	<cfset var theFlagName = trim(arguments.FlagName) />
	<cfset var theFlagValue = trim(arguments.FlagValue) />
	<!--- now vars that will get filled as we go --->
	<cfset var theFlagType = "" />
	<cfset var theDBvalue = "" />
	<cfset var theQueryDataArguments = StructNew() />	<!--- temp struct to compose the data clauses of the SQL query --->
	<cfset var theQueryWhereArguments = StructNew() />	<!--- temp struct to compose the where clauses of the SQL query --->
	<cfset var qryTemp = "" /> <!--- DataMgr query return --->
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorText = "" />
	<cfset ret.error.ErrorContext = "SLCMS_Utility CFC: setSystemFlag()" />
	<cfset ret.error.ErrorExtra = "" />
	<cfset ret.Data = "" />	<!--- and no data yet --->

	<cfif len(theFlagName)>
		<!--- feebly validated so go for it --->
		<!--- wrap the whole thing in a try/catch in case something breaks --->
		<cftry>
			<cfif StructKeyExists(variables.Flags.Core, theFlagName)>
				<cfset theFlagType = variables.Flags.Core[theFlagName].FlagType />
				<cfif theFlagType eq "text" and IsSimpleValue(theFlagValue)>
					<cfset theDBvalue = theFlagValue />
				<cfelseif theFlagType eq "numb"  and IsNumeric(theFlagValue)>
					<cfset theDBvalue = theFlagValue />
				<cfelseif theFlagType eq "bool" and IsBoolean(theFlagValue)>
					<cfset theDBvalue = YesNoFormat(theFlagValue) />
				<cfelse>
					<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 4) />
					<cfset ret.error.ErrorText = ret.error.ErrorText & "Oops! Invalid Flag Data, type did not match value. FlagType was: #theFlagType#, Value was: #theFlagValue#<br>" />
				</cfif>
				<cfif ret.error.ErrorCode eq 0>
					<cfset variables.Flags.Core[theFlagName].Value = theFlagValue />
					<!--- and drop into the database --->
					<cfset theQueryDataArguments.State = theDBvalue />
					<cfset theQueryWhereArguments.FlagName = theFlagName />
					<cfset qryTemp = application.SLCMS.Core.DataMgr.UpdateRecords(tablename="#variables.DBFlagTable#", data_set=theQueryDataArguments, data_where=theQueryWhereArguments) />
				</cfif>
			<cfelse>	<!--- this is the error code --->
				<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 2) />
				<cfset ret.error.ErrorText = ret.error.ErrorText & "Oops! Invalid Flag Name<br>" />
			</cfif>
		<cfcatch type="any">
			<cfset ret.error = TakeErrorCatch(RetErrorStruct=ret.error, CatchStruct=cfcatch) />
		</cfcatch>
		</cftry>
	<cfelse>	<!--- this is the error code --->
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 1) />
		<cfset ret.error.ErrorText = ret.error.ErrorText & "Oops! No Flag Name supplied<br>" />
	</cfif>

	<!--- return our data structure --->
	<cfreturn ret  />
</cffunction>

<cffunction name="DoPagesHaveTemplatesOnly" output="No" returntype="boolean" access="public" 
	displayname="Do Pages Have Templates Only"
	hint="Directly returns true/false as to whether we have more than templates or not"
	>
	<!--- unecessarily complicated but it works on all cfml platforms, boolean flags are stored as yes/no string --->
	<cfset var ret = variables.Flags.Core.PagesHaveTemplatesOnly.Value /> 
	<cfif ret eq "yes">
		<cfset ret = True />
	<cfelse>
		<cfset ret = False />
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
	<!--- this function needs.... --->
	<cfargument name="LogType" type="string" default="" hint="The log to write to" />
	<cfargument name="LogString" type="string" default="" hint="The string to write to the log" />

	<!--- now all of the var declarations, first the arguments which need manipulation --->
	<cfset var theLogType = trim(arguments.LogType) />
	<cfset var theLogString = trim(arguments.LogString) />
	<!--- now vars that will get filled as we go --->
	<cfset var temps = StructNew() />	<!--- temp/throwaway structure --->
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorText = "" />
	<cfset ret.error.ErrorContext = "SLCMS_Utility CFC: LogIt()" />
	<cfset ret.error.ErrorExtra = "" />
	<cfset ret.Data = "" />	<!--- and no data yet --->

		<!--- validation --->
	<cfif theLogType neq "">
		<cftry>
			<!--- this is for other CFCs, we can copy from here
			<cfset temps = application.SLCMS.Core.SLCMS_Utility.WriteLog_Core(LogType="#theLogType#", LogString="#theLogString#") />
			--->
			<cfset temps = WriteLog_Core(LogType="#theLogType#", LogString="#theLogString#") />
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

	<!--- return our data structure --->
	<cfreturn ret  />
</cffunction>

<cffunction name="WriteLog_Core" output="No" returntype="struct" access="public"
	displayname="Write Log for Core"
	hint="Global Function for every CFC to log info to standard log space, minimizes log code in individual functions"
	>
	<!--- this function needs.... --->
	<cfargument name="LogType" type="string" default="" hint="The log to write to" />
	<cfargument name="LogString" type="string" default="" hint="The string to write to the log" />

	<!--- now all of the var declarations, first the arguments which need manipulation --->
	<cfset var theLogType = trim(arguments.LogType) />
	<cfset var theLogString = trim(arguments.LogString) />
	<!--- now vars that will get filled as we go --->
	<cfset var FileLineTextString = "" />
	<cfset var FileNameDateString = "" />
	<cfset var FileNameFinal = "" />
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorText = "" />
	<cfset ret.error.ErrorContext = "SLCMS_Utility CFC: WriteLog_Core()" />
	<cfset ret.error.ErrorExtra = "" />
	<cfset ret.Data = "" />	<!--- and no data yet --->

		<!--- validation --->
	<cfif StructKeyExists(variables.LogTypeDefs, "#theLogType#")>
		<!--- validated so go for it --->
		<!--- wrap the whole thing in a try/catch in case something breaks, got to be acreful so we don't try to call ourself if an error --->
		<cftry>
			<cfset FileLineTextString = "#DateFormat(Now(), "YYYYMMDD")# #TimeFormat(Now(), "HH:mm:ss.L")# - " />
			<cfset FileLineTextString = FileLineTextString & theLogString />	<!--- we take the incoming string as is, could have anything in it but it is a string --->
			<!--- work out the filename append for the appropriate date --->
			<cfset FileNameDateString = DateFormat(Now(), "YYYYMM") />
			<cfif variables.LogCyclePeriod eq "Monthly">
			<cfelseif variables.LogCyclePeriod eq "Weekly">
				<cfset FileNameDateString = FileNameDateString & "W" & Week(Now()) />
			<cfelseif variables.LogCyclePeriod eq "Daily">
				<cfset FileNameDateString = FileNameDateString & DateFormat(Now(), "DD") />
			</cfif>
			<cfset FileNameFinal = variables.LogTypeDefs["#theLogType#"].FilePrePath & FileNameDateString & ".log" />
			<cffile action="append" file="#FileNameFinal#" output="#FileLineTextString#" addnewline="true" />
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

	<!--- return our data structure --->
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
