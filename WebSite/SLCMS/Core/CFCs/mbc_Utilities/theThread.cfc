<!--- mbc CFCs  --->
<!--- &copy; mort bay communications --->
<!---  --->
<!--- a common code set of utilities for common thread related code
			supplies functionality for parent/child, one-many-one or many-many relationships --->
<!---  --->
<!--- Cloned:   25th Apr 2008 by Kym K, mbcomms - taken out of the utilities CFC as getting to big and naming issues --->
<!--- Modified:  4th Apr 2008 -  9th Apr 2008 by Kym K, theThread - added theThread functions to provide generic parent-child or many-to-many relationships --->
<!--- modified:  9th Apr 2012 -  9th Apr 2012 by Kym K, mbcomms: V3.0, CFWheels version. All SLCMS in own struct under app scope --->

<cfcomponent 	
	displayname="The Thread" 
	hint="contains functions that are part of a unified linking structure: 1 to 1; 1 to many; many to many; many to 1"
	>
	
	<!--- set up a few persistant things on the way in, these were in a single structure in the Utilites CFC, 
				a bit redundant now but I am not going to change it and break things...... --->
	<cfset variables.Threads = StructNew() />	
	<cfset variables.Threads.dsn = "" />	
	<cfset variables.Threads.ThreadLinkTable = "" />
	<cfset variables.Threads.ThreadMatrixTable = "" />
	<cfset variables.Threads.ThreadSetTable = "" />	
	<cfset variables.Threads.SetsByName = StructNew() />	<!--- this will carry a local copy of all the thread set IDs from their external names --->
	<cfset variables.Threads.SetsByID = StructNew() />	<!--- this will carry a local copy of all the thread sets related by their setID --->

<!--- initialise the various thingies, this should only be called after an app scope frefresh --->
<cffunction name="init" access="public" output="yes" returntype="struct" hint="sets up the internal structures for this component">
	<cfargument name="DefStructure" type="struct" default="">	<!--- the name of the structure that defines everything --->
	<cfargument name="ThreadsDSN" type="string" default="">	<!--- the database dsn name in the config file for where the Threads tables are --->
	<cfargument name="ThreadsLinkTable" type="string" default="theThread_Links">	<!--- the name of the database table for the Thread Links --->
	<cfargument name="ThreadsMatrixTable" type="string" default="theThread_Matrix">	<!--- the name of the database table for the Thread Matrix --->
	<cfargument name="ThreadsSetTable" type="string" default="theThread_Sets">	<!--- the name of the database table for the Thread Sets --->

	<cfset var getThreadSet = "" />	<!--- localise query --->
	<cfset var getThreads = "" />	<!--- localise query --->
	<cfset var thisThreadSetID = "" />	<!--- local var --->
	<cfset var thisThread = "" />	<!--- local var --->
	<cfset var thisSetName = "" />	<!--- local var --->
	
	<!--- dump all of our original data --->
	<cfset variables.Threads = StructNew() />	
	<cfset variables.Threads.dsn = "" />	
	<cfset variables.Threads.ThreadLinkTable = "" />
	<cfset variables.Threads.ThreadMatrixTable = "" />
	<cfset variables.Threads.ThreadSetTable = "" />	
	<cfset variables.Threads.SetsByName = StructNew() />	<!--- this will carry a local copy of all the thread set IDs from their external names --->
	<cfset variables.Threads.SetsByID = StructNew() />	<!--- this will carry a local copy of all the thread sets related by their setID --->

	<cfif IsStruct(arguments.DefStructure)>
		<!--- if we have a definition structure use that it has the key/value pairs form the config.ini file --->
		<cfset variables.Threads.DSN = application.SLCMS.Config.DataSources[arguments.DefStructure.Threads_DSN] />
		<cfset variables.Threads.ThreadLinkTable = arguments.DefStructure.Threads_LinkTable />
		<cfset variables.Threads.ThreadMatrixTable = arguments.DefStructure.Threads_MatrixTable />
		<cfset variables.Threads.ThreadSetTable = arguments.DefStructure.Threads_SetTable />
	<cfelse>
		<cfset variables.Threads.DSN = arguments.ThreadsDSN />
		<cfset variables.Threads.ThreadLinkTable = arguments.ThreadsLinkTable />
		<cfset variables.Threads.ThreadMatrixTable = arguments.ThreadsMatrixTable />
		<cfset variables.Threads.ThreadSetTable = arguments.ThreadsSetTable />
	</cfif>
	<!--- threads are done locally as we don't need a function as never called from anywhere else --->
	<cfquery name="getThreadSet" datasource="#variables.Threads.dsn#">
		Select	ThreadSetID, TableName, Fieldname
			from	#variables.Threads.ThreadSetTable#
	</cfquery>
	<cfloop query="getThreadSet">
		<cfset thisSetName = "#getThreadSet.TableName#_#getThreadSet.FieldName#" />
		<cfset thisThreadSetID = getThreadSet.ThreadSetID />
		<cfset variables.Threads.SetsByName["#thisSetName#"] = StructNew() />	<!--- struct to contain all for this set --->
		<cfset variables.Threads.SetsByName["#thisSetName#"].threadsetID = thisThreadSetID />	<!--- relate the names to their set IDs --->
		<cfset variables.Threads.SetsByID["Set_#thisThreadSetID#"] = StructNew() />	<!--- struct to contain all for this set --->
		<cfset variables.Threads.SetsByID["Set_#thisThreadSetID#"].SetName = thisSetName />	<!--- do it both ways round --->
		<!--- and put the threads into that structure --->
		<cfquery name="getThreads" datasource="#variables.Threads.dsn#">
			Select	ThreadID, ExternalValue
				from	#variables.Threads.ThreadLinkTable#
				where	ThreadSetID = #thisThreadSetID#
		</cfquery>
		<cfloop query="getThreads">
			<cfset variables.Threads.SetsByName["#thisSetName#"]["Thread_#getThreads.ThreadID#"] = getThreads.ExternalValue />	<!--- relate the IDs to their Values --->
			<cfset variables.Threads.SetsByName["#thisSetName#"]["Value_#getThreads.ExternalValue#"] = getThreads.ThreadID />	<!--- relate the Values to their IDs --->
			<cfset variables.Threads.SetsByID["Set_#thisThreadSetID#"]["Thread_#getThreads.ThreadID#"] = getThreads.ExternalValue />
			<cfset variables.Threads.SetsByID["Set_#thisThreadSetID#"]["Value_#getThreads.ExternalValue#"] = getThreads.ThreadID />
		</cfloop>
	</cfloop>

	<cfreturn this />
</cffunction>

<cffunction name="getVariables" output="yes" returntype="struct" access="public"
	displayname="get Variables scope"
	hint="this is quicky to dump the entire variables scope, returns the struct directly"
				>

	<cfreturn variables  />
</cffunction>

<!--- these are the functions relating to threads, ie relationships, parent/child or many-to-many --->
<cffunction name="CreateThreadSet" output="yes" returntype="struct" access="public"
	displayname="Create Thread Set"
	hint="Creates a ThreadSet, 
				supply DB table name or reference and a field name to create an empty set of threads"
				>
	<!--- this function needs.... --->
	<cfargument name="TableName" type="string" default="" />	<!--- the name of the database table the field is in --->
	<cfargument name="FieldName" type="string" default="" />	<!--- the name of the database field --->

	<!--- now all of the var declarations, first the arguments which need manipulation --->
	<cfset var theTableName = trim(arguments.TableName) />
	<cfset var theFieldName = trim(arguments.FieldName) />
	<!--- now vars that will get filled as we go --->
	<cfset var lcntr = 0 />	<!--- temp loop counter --->
	<cfset var theNextSetID = 0 />	<!--- temp/throwaway var --->
	<cfset var setThreadSetID = "" />	<!--- localise query --->
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorText = "CreateThreadSet()<br>" />
	<cfset ret.Data = 0 />
	
	<!--- validate the incoming stuff --->
	<cfif len(theTableName) or len(theFieldName)>
		<!--- we only some sort of naming, don't have to have both --->
		<!--- wrap the whole thing in a try/catch in case something breaks --->
		<cftry>
			<!--- first off see if we have this combo already --->
			<cfif not StructKeyExists(variables.Threads.SetsByName, "#theTableName#_#theFieldName#")>
				<!--- nope so make it --->
				<cfset theNextSetID = Nexts_getNextID(IDName="ThreadSetID") />
				<cfquery name="setThreadSetID" datasource="#variables.Threads.dsn#">
					Insert Into	#variables.Threads.ThreadSetTable#
										(TableName, FieldName, ThreadSetID)
						values	('#theTableName#', '#theFieldName#', #theNextSetID#)
				</cfquery>
				<cfset variables.Threads.SetsByName["#theTableName#_#theFieldName#"] = StructNew() />	<!--- create struct for this thread in the local store --->
				<cfset variables.Threads.SetsByName["#theTableName#_#theFieldName#"].threadsetID = theNextSetID />	<!--- save in the local store --->
				<cfset variables.Threads.SetsByID["Set_#theNextSetID#"] = StructNew() />	<!--- struct to contain all for this set, ID related --->
      	<cfset ret.Data = theNextSetID />  <!--- return the ID --->
			<cfelse>
				<!--- minor oops, we already have one --->
				<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 2) />
				<cfset ret.error.ErrorText = ret.error.ErrorText & 'Oops! The table/field name combination of: #theTableName#/#theFieldName# already exists<br>' />
      	<cfset ret.Data = variables.Threads.SetsByName["#theTableName#_#theFieldName#"].threadsetID />  <!--- return the ID --->
			</cfif>
		<cfcatch type="any">
			<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 128) />
			<cfset ret.error.ErrorText = ret.error.ErrorText & 'Oops! Error Caught, error message was: #cfcatch.message#, error detail was: #cfcatch.detail#<br>' />
			<cfset ret.error.ErrorExtra =  cfcatch />
			<cflog text="CreateThreadSet() Trapped. ret.error.ErrorCode: #ret.error.ErrorCode# - Error Text: #ret.error.ErrorText# - Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#"  file="UtilitiesErrors" type="Error" application = "yes">
			<cfif application.SLCMS.Config.debug.debugmode>
				CreateThreadSet() trapped - error was:<br>
				<cfdump var="#ret.error.ErrorExtra#">
			</cfif>
		</cfcatch>
		</cftry>
	<cfelse>
		<!--- oops no meaningful parameters so return nothing --->
		<cfset ret.error.ErrorCode = 1 />
		<cfset ret.error.ErrorText = "Invalid parameters: - TableName and FieldName are both blank" />
	</cfif> <!--- end: incoming parameters validation check --->

	<cfreturn ret  />
</cffunction>

<cffunction name="getThreadSetID" output="yes" returntype="struct" access="public"
	displayname="gets a Thread Set"
	hint="Gets ThreadSetID from the supplied DB table reference and a field name"
				>
	<!--- this function needs.... --->
	<cfargument name="TableName" type="string" default="" />	<!--- the name of the database table the field is in --->
	<cfargument name="FieldName" type="string" default="" />	<!--- the name of the database field --->

	<!--- now all of the var declarations, first the arguments which need manipulation --->
	<cfset var theTableName = trim(arguments.DatabaseName) />
	<cfset var theFieldName = trim(arguments.FieldName) />
	<!--- now vars that will get filled as we go --->
	<cfset var lcntr = 0 />	<!--- temp loop counter --->
	<cfset var theNextSetID = 0 />	<!--- temp/throwaway var --->
	<cfset var setThreadSetID = "" />	<!--- localise query --->
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorText = "CreateThreadSet()<br>" />
	<cfset ret.Data = 0 />
	
	<!--- validate the incoming stuff --->
	<cfif len(theTableName) or len(theFieldName)>
		<!--- we only some sort of naming, don't have to have both --->
		<!--- wrap the whole thing in a try/catch in case something breaks --->
		<cftry>
			<!--- first off see if we have this combo --->
			<cfif StructKeyExists(variables.Threads.SetsByName, "#theTableName#_#theFieldName#")>
				<cfset ret.Data = variables.Threads.SetsByName["#theTableName#_#theFieldName#"].threadsetID />
			<cfelse>
				<!--- oops, not there --->
				<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 2) />
				<cfset ret.error.ErrorText = ret.error.ErrorText & "Oops! The table/field name combination of: #theTableName#_#theFieldName# didn't exist<br>"/>
			</cfif>
		<cfcatch type="any">
			<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 128) />
			<cfset ret.error.ErrorText = ret.error.ErrorText & 'Oops! Error Caught, error message was: #cfcatch.message#, error detail was: #cfcatch.detail#<br>' />
			<cfset ret.error.ErrorExtra =  cfcatch.TagContext />
			<cflog text="emptyFunction() Trapped. ret.error.ErrorCode: #ret.error.ErrorCode# - Error Text: #ret.error.ErrorText# - Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#"  file="UtilitiesErrors" type="Error" application = "yes">
			<cfif application.SLCMS.Config.debug.debugmode>
				CreateThreadSet() trapped - error was:<br>
				<cfdump var="#ret.error.ErrorExtra#">
			</cfif>
		</cfcatch>
		</cftry>
	<cfelse>
		<!--- oops no meaningful parameters so return nothing --->
		<cfset ret.error.ErrorCode = 1 />
		<cfset ret.error.ErrorText = "Invalid parameters: - TableName and FieldName are both blank" />
	</cfif> <!--- end: incoming parameters validation check --->

	<cfreturn ret  />
</cffunction>

<cffunction name="CreateThread" output="yes" returntype="struct" access="public"
	displayname="Create Thread"
	hint="Creates a Thread within a thread set, 
				supply threadsetID and external value to create a thread"
				>
	<!--- this function needs.... --->
	<cfargument name="ThreadSetID" type="string" default="" hint="the set the thread has to be in" />
	<cfargument name="ExternalValue" type="string" default="" hint="the value/id of the thread" />

	<!--- now all of the var declarations, first the arguments which need manipulation --->
	<cfset var theThreadSetID = trim(arguments.ThreadSetID) />
	<cfset var theExternalValue = trim(arguments.ExternalValue) />
	<!--- now vars that will get filled as we go --->
	<cfset var thisSetName = "" />	<!--- temp/throwaway var --->
	<cfset var theNextSetID = 0 />	<!--- temp/throwaway var --->
	<cfset var setThreadID = "" />	<!--- localise query --->
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorText = "CreateThread()<br>" />
	<cfset ret.Data = 0 />
	
	<!--- validate the incoming stuff --->
	<cfif len(theThreadSetID) and len(theFieldValue) and IsNumeric(theFieldValue)>
		<!--- we need both arguments --->
		<!--- wrap the whole thing in a try/catch in case something breaks --->
		<cftry>
			<!--- first off see if we have this combo already --->
			<cfif not StructKeyExists(variables.Threads.SetsByID, "Set_#theThreadSetID#")>
				<!--- nope so make it --->
				<cfset theNextThreadID = Nexts_getNextID(IDName="ThreadID") />
				<cfset ret.Data = theNextThreadID />	<!--- tell the new ID in our return --->
				<cfquery name="setThreadID" datasource="#variables.Threads.dsn#">
					Insert Into	#variables.Threads.ThreadLinkTable#
										(ThreadSetID, ExternalValue, ThreadID)
						values	('#theThreadSetID#', '#theExternalValue#', #theNextThreadID#)
				</cfquery>
				<cfset thisSetName = variables.Threads.SetsByID["Set_#thisThreadSetID#"].SetName />	<!--- grab the name of the set so we can load up our structures with the new threadID --->
				<cfset variables.Threads.SetsByName["#thisSetName#"]["Thread_#theNextThreadID#"] = theExternalValue />	<!--- relate the IDs to their Values --->
				<cfset variables.Threads.SetsByName["#thisSetName#"]["Value_#theExternalValue#"] = theNextThreadID />	<!--- relate the Values to their IDs --->
				<cfset variables.Threads.SetsByID["Set_#theThreadSetID#"]["Thread_#theNextThreadID#"] = theExternalValue />
				<cfset variables.Threads.SetsByID["Set_#theThreadSetID#"]["Value_#theExternalValue#"] = theNextThreadID />
			<cfelse>
				<!--- oops, we already have one --->
				<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 2) />
				<cfset ret.error.ErrorText = ret.error.ErrorText & 'Oops! The thread Value of: #ExternalValue# for threadset #ThreadSetID# already exists<br>' />
			</cfif>
		<cfcatch type="any">
			<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 128) />
			<cfset ret.error.ErrorText = ret.error.ErrorText & 'Oops! Error Caught, error message was: #cfcatch.message#, error detail was: #cfcatch.detail#<br>' />
			<cfset ret.error.ErrorExtra =  cfcatch.TagContext />
			<cflog text="CreateThread() Trapped. ret.error.ErrorCode: #ret.error.ErrorCode# - Error Text: #ret.error.ErrorText# - Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#"  file="UtilitiesErrors" type="Error" application = "yes">
			<cfif application.SLCMS.Config.debug.debugmode>
				CreateThreadSet() trapped - error was:<br>
				<cfdump var="#ret.error.ErrorExtra#">
			</cfif>
		</cfcatch>
		</cftry>
	<cfelse>
		<!--- oops no meaningful parameters so return nothing --->
		<cfset ret.error.ErrorCode = 1 />
		<cfset ret.error.ErrorText = "Invalid parameters: - TableName or FieldName are both blank or FieldName is not numeric. Thy were:- SetID: #theThreadSetID#; Value: #theFieldValue#" />
	</cfif> <!--- end: incoming parameters validation check --->

	<cfreturn ret  />
</cffunction>

<cffunction name="getThreadID" output="yes" returntype="struct" access="public"
	displayname="get Thread ID"
	hint="Returns the ThreadID within a thread set, 
				supply threadsetID and external value to find the threadID"
				>
	<!--- this function needs.... --->
	<cfargument name="ThreadSetID" type="string" default="" hint="the set the thread is in" />
	<cfargument name="ExternalValue" type="string" default="" hint="the value/id of the thread" />

	<!--- now all of the var declarations, first the arguments which need manipulation --->
	<cfset var theThreadSetID = trim(arguments.ThreadSetID) />
	<cfset var theExternalValue = trim(arguments.ExternalValue) />
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorText = "getThreadID()<br>" />
	<cfset ret.Data = 0 />
	
	<!--- validate the incoming stuff --->
	<cfif len(theThreadSetID) and len(theExternalValue) and IsNumeric(theExternalValue)>
		<!--- we need both arguments --->
		<!--- wrap the whole thing in a try/catch in case something breaks --->
		<cftry>
			<!--- first off see if we have this combo --->
			<cfif StructKeyExists(variables.Threads.SetsByID, "Set_#theThreadSetID#") and StructKeyExists(variables.Threads.SetsByID["Set_#theThreadSetID#"], "Value_#theExternalValue#")>
				<!--- grab the ID --->
				<cfset ret.Data = variables.Threads.SetsByID["Set_#theThreadSetID#"]["Value_#theExternalValue#"] />
			<cfelse>
				<!--- oops, not there --->
				<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 2) />
				<cfset ret.error.ErrorText = ret.error.ErrorText & 'Oops! The thread Value of: #theExternalValue# for threadset #theThreadSetID# did not exist<br>' />
			</cfif>
		<cfcatch type="any">
			<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 128) />
			<cfset ret.error.ErrorText = ret.error.ErrorText & 'Oops! Error Caught, error message was: #cfcatch.message#, error detail was: #cfcatch.detail#<br>' />
			<cfset ret.error.ErrorExtra =  cfcatch.TagContext />
			<cflog text="getThreadID() Trapped. ret.error.ErrorCode: #ret.error.ErrorCode# - Error Text: #ret.error.ErrorText# - Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#"  file="UtilitiesErrors" type="Error" application = "yes">
			<cfif application.SLCMS.Config.debug.debugmode>
				CreateThreadSet() trapped - error was:<br>
				<cfdump var="#ret.error.ErrorExtra#">
			</cfif>
		</cfcatch>
		</cftry>
	<cfelse>
		<!--- oops no meaningful parameters so return nothing --->
		<cfset ret.error.ErrorCode = 1 />
		<cfset ret.error.ErrorText = "Invalid parameters: - the ThreadSetID or ExternalValue are both blank or ExternalValue is not numeric. They were:- SetID: #theThreadSetID#; Value: #theExternalValue#" />
	</cfif> <!--- end: incoming parameters validation check --->

	<cfreturn ret  />
</cffunction>

<cffunction name="getParentThreadIDfromThreadID" output="yes" returntype="struct" access="public"
	displayname="get Parent Thread ID from a ThreadID"
	hint="Returns the Parent ThreadID(s) for the specified threadID"
				>
	<!--- this function needs.... --->
	<cfargument name="ThreadSetID" type="string" default="" hint="the set the thread is in" />
	<cfargument name="ThreadID" type="string" default="" hint="the threadID we want to get the parent of" />

	<!--- now all of the var declarations, first the arguments which need manipulation --->
	<cfset var theThreadSetID = trim(arguments.ThreadSetID) />
	<cfset var theThreadID = trim(arguments.ThreadID) />
	<!--- now vars that will get filled as we go --->
	<cfset var getThreadIDs = "" />	<!--- localise query --->
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorText = "getParentThreadID()<br>" />
	<cfset ret.Data = "" />
	
	<!--- validate the incoming stuff --->
	<cfif len(theThreadSetID) and IsNumeric(theThreadSetID) and len(theThreadID) and IsNumeric(theThreadID)>
		<!--- we need both arguments --->
		<!--- wrap the whole thing in a try/catch in case something breaks --->
		<cftry>
			<!--- grab all of the IDs that are parents --->
			<cfquery name="getThreadIDs" datasource="#variables.Threads.dsn#">
				Select	ThreadID_Left
					from	#variables.Threads.ThreadMatrixTable#
					where	ThreadSetID = #theThreadSetID#
            and	ThreadID_Right = #theThreadID#
			</cfquery>
			<cfif getThreadIDs.RecordCount>
				<!--- grab the ID, can be more than one if we have a many-many thing going --->
				<cfset ret.Data = ValueList(getThreadIDs.ThreadID_Left) />
			</cfif>
		<cfcatch type="any">
			<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 128) />
			<cfset ret.error.ErrorText = ret.error.ErrorText & 'Oops! Error Caught, error message was: #cfcatch.message#, error detail was: #cfcatch.detail#<br>' />
			<cfset ret.error.ErrorExtra =  cfcatch.TagContext />
			<cflog text="getParentThreadID() Trapped. ret.error.ErrorCode: #ret.error.ErrorCode# - Error Text: #ret.error.ErrorText# - Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#"  file="UtilitiesErrors" type="Error" application = "yes">
			<cfif application.SLCMS.Config.debug.debugmode>
				getParentThreadID() trapped - error was:<br>
				<cfdump var="#ret.error.ErrorExtra#">
			</cfif>
		</cfcatch>
		</cftry>
	<cfelse>
		<!--- oops no meaningful parameters so return nothing --->
		<cfset ret.error.ErrorCode = 1 />
		<cfset ret.error.ErrorText = "Invalid parameters: - the ThreadSetID or ThreadID are either blank or not numeric. They were:- SetID: #theThreadSetID#; ThreadID: #theThreadID#" />
	</cfif> <!--- end: incoming parameters validation check --->

	<cfreturn ret  />
</cffunction>

<cffunction name="getChildThreadIDfromThreadID" output="yes" returntype="struct" access="public"
	displayname="get Child Thread ID from a ThreadID"
	hint="Returns the Child ThreadID(s) for the specified threadID"
				>
	<!--- this function needs.... --->
	<cfargument name="ThreadSetID" type="string" default="" hint="the set the thread is in" />
	<cfargument name="ThreadID" type="string" default="" hint="the threadID we want to get the parent of" />

	<!--- now all of the var declarations, first the arguments which need manipulation --->
	<cfset var theThreadSetID = trim(arguments.ThreadSetID) />
	<cfset var theThreadID = trim(arguments.ThreadID) />
	<!--- now vars that will get filled as we go --->
	<cfset var getThreadIDs = "" />	<!--- localise query --->
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorText = "getParentThreadID()<br>" />
	<cfset ret.Data = "" />
	
	<!--- validate the incoming stuff --->
	<cfif len(theThreadSetID) and IsNumeric(theThreadSetID) and len(theThreadID) and IsNumeric(theThreadID)>
		<!--- we need both arguments --->
		<!--- wrap the whole thing in a try/catch in case something breaks --->
		<cftry>
			<!--- grab all of the IDs that are parents --->
			<cfquery name="getThreadIDs" datasource="#variables.Threads.dsn#">
				Select	ThreadID_Right
					from	#variables.Threads.ThreadMatrixTable#
					where	ThreadSetID = #theThreadSetID#
            and	ThreadID_Left = #theThreadID#
			</cfquery>
			<cfif getThreadIDs.RecordCount>
				<!--- grab the ID, can be more than one if we have a many-many thing going --->
				<cfset ret.Data = ValueList(getThreadIDs.ThreadID_Right) />
			</cfif>
		<cfcatch type="any">
			<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 128) />
			<cfset ret.error.ErrorText = ret.error.ErrorText & 'Oops! Error Caught, error message was: #cfcatch.message#, error detail was: #cfcatch.detail#<br>' />
			<cfset ret.error.ErrorExtra =  cfcatch.TagContext />
			<cflog text="getParentThreadID() Trapped. ret.error.ErrorCode: #ret.error.ErrorCode# - Error Text: #ret.error.ErrorText# - Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#"  file="UtilitiesErrors" type="Error" application = "yes">
			<cfif application.SLCMS.Config.debug.debugmode>
				getParentThreadID() trapped - error was:<br>
				<cfdump var="#ret.error.ErrorExtra#">
			</cfif>
		</cfcatch>
		</cftry>
	<cfelse>
		<!--- oops no meaningful parameters so return nothing --->
		<cfset ret.error.ErrorCode = 1 />
		<cfset ret.error.ErrorText = "Invalid parameters: - the ThreadSetID or ThreadID are either blank or not numeric. They were:- SetID: #theThreadSetID#; ThreadID: #theThreadID#" />
	</cfif> <!--- end: incoming parameters validation check --->

	<cfreturn ret  />
</cffunction>

<cffunction name="getThreadValue" output="yes" returntype="struct" access="public"
	displayname="get Thread ID"
	hint="Returns the ThreadID within a thread set, 
				supply threadsetID and external value to find the threadID"
				>
	<!--- this function needs.... --->
	<cfargument name="ThreadSetID" type="string" default="" hint="the set the thread is in" />
	<cfargument name="ThreadID" type="string" default="" hint="the id of the thread" />

	<!--- now all of the var declarations, first the arguments which need manipulation --->
	<cfset var theThreadSetID = trim(arguments.ThreadSetID) />
	<cfset var theThreadID = trim(arguments.ThreadID) />
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorText = "getThreadID()<br>" />
	<cfset ret.Data = 0 />
	
	<!--- validate the incoming stuff --->
	<cfif len(theThreadSetID) and IsNumeric(theThreadSetID) and len(theThreadID) and IsNumeric(theThreadID)>
		<!--- we need both arguments --->
		<!--- wrap the whole thing in a try/catch in case something breaks --->
		<cftry>
			<!--- first off see if we have this combo --->
			<cfif StructKeyExists(variables.Threads.SetsByID, "Set_#theThreadSetID#") and StructKeyExists(variables.Threads.SetsByID["Set_#theThreadSetID#"], "Thread_#ThreadID#")>
				<!--- grab the ID --->
				<cfset ret.Data = variables.Threads.SetsByID["Set_#theThreadSetID#"]["Thread_#ThreadID#"] />
			<cfelse>
				<!--- oops, not there --->
				<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 2) />
				<cfset ret.error.ErrorText = ret.error.ErrorText & 'Oops! The thread ID of: #theThreadID# for threadset #theThreadSetID# did not exist<br>' />
			</cfif>
		<cfcatch type="any">
			<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 128) />
			<cfset ret.error.ErrorText = ret.error.ErrorText & 'Oops! Error Caught, error message was: #cfcatch.message#, error detail was: #cfcatch.detail#<br>' />
			<cfset ret.error.ErrorExtra =  cfcatch.TagContext />
			<cflog text="getThreadID() Trapped. ret.error.ErrorCode: #ret.error.ErrorCode# - Error Text: #ret.error.ErrorText# - Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#"  file="UtilitiesErrors" type="Error" application = "yes">
			<cfif application.SLCMS.Config.debug.debugmode>
				CreateThreadSet() trapped - error was:<br>
				<cfdump var="#ret.error.ErrorExtra#">
			</cfif>
		</cfcatch>
		</cftry>
	<cfelse>
		<!--- oops no meaningful parameters so return nothing --->
		<cfset ret.error.ErrorCode = 1 />
		<cfset ret.error.ErrorText = "Invalid parameters: - the ThreadSetID or ThreadID are either blank or not numeric. They were:- SetID: #theThreadSetID#; ThreadID: #theThreadID#" />
	</cfif> <!--- end: incoming parameters validation check --->

	<cfreturn ret  />
</cffunction>

<cffunction name="getParentValue" output="yes" returntype="struct" access="public"
	displayname="get Parent Value"
	hint="Returns the Parent's Value for the specified Value"
				>
	<!--- this function needs.... --->
	<cfargument name="ThreadSetID" type="string" default="" hint="the set the thread is in" />
	<cfargument name="ExternalValue" type="string" default="" hint="the value we want to get the parent of" />

	<!--- now all of the var declarations, first the arguments which need manipulation --->
	<cfset var theThreadSetID = trim(arguments.ThreadSetID) />
	<cfset var theExternalValue = trim(arguments.ExternalValue) />
	<!--- now vars that will get filled as we go --->
	<cfset var temps1 = StructNew />	<!--- temp/throwaway struct --->
	<cfset var temps2 = StructNew />	<!--- temp/throwaway struct --->
	<cfset var thisParentID = "" />	<!--- temp/throwaway var --->
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorText = "getParentValue()<br>" />
	<cfset ret.Data = "" />
	
	<!--- validate the incoming stuff, we need both params --->
	<cfif len(theThreadSetID) and IsNumeric(theThreadSetID) and len(theValue) and IsNumeric(theValue)>
		<!--- we need both arguments --->
		<!--- wrap the whole thing in a try/catch in case something breaks --->
		<cftry>
			<!--- first off see if we have this combo --->
			<cfset temps1 = getThreadID(ThreadSetID="#theThreadSetID#", ExternalValue="#theExternalValue#")>
			<cfif temps1.Error.errorCode eq 0 >
				<!--- we have a threadID for this input value so get its parent(s) --->
				<cfset temps2 = getParentThreadIDfromThreadID(ThreadSetID="#theThreadSetID#", ThreadID="#temps1.data#")>
				<cfif temps2.Error.errorCode eq 0 >
					<!--- we have a parent response that can be a null for nor parent or a single id or a list if there are many parents --->
					<cfif temps2.data neq "">
						<cfloop list="#temps2.data#" index="thisParentID">	<!--- loop over results and make list of parent values --->
							<cfset ret.Data = ListAppend(ret.Data, getThreadValue(ThreadSetID="#theThreadSetID#", ThreadID="#thisParentID#")) />
						</cfloop>
					<cfelse>
						<!--- no parent, do nothing, return a null --->
					</cfif>
				<cfelse>
					<!--- oops, parent find broke --->
					<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 4) />
					<cfset ret.error.ErrorText = ret.error.ErrorText & temps2.error.ErrorText />
				</cfif>
			<cfelse>
				<!--- oops, not a legit input set of vars --->
				<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 2) />
				<cfset ret.error.ErrorText = ret.error.ErrorText & temps1.error.ErrorText />
			</cfif>
		<cfcatch type="any">
			<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 128) />
			<cfset ret.error.ErrorText = ret.error.ErrorText & 'Oops! Error Caught, error message was: #cfcatch.message#, error detail was: #cfcatch.detail#<br>' />
			<cfset ret.error.ErrorExtra =  cfcatch.TagContext />
			<cflog text="getParentValue() Trapped. ret.error.ErrorCode: #ret.error.ErrorCode# - Error Text: #ret.error.ErrorText# - Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#"  file="UtilitiesErrors" type="Error" application = "yes">
			<cfif application.SLCMS.Config.debug.debugmode>
				getParentValue() trapped - error was:<br>
				<cfdump var="#ret.error.ErrorExtra#">
			</cfif>
		</cfcatch>
		</cftry>
	<cfelse>
		<!--- oops no meaningful parameters so return nothing --->
		<cfset ret.error.ErrorCode = 1 />
		<cfset ret.error.ErrorText = "Invalid parameters: - the ThreadSetID or ExternalValue are either blank or not numeric. They were:- SetID: #theThreadSetID#; ExternalValue: #theExternalValue#" />
	</cfif> <!--- end: incoming parameters validation check --->

	<cfreturn ret  />
</cffunction>

<cffunction name="getChildValue" output="yes" returntype="struct" access="public"
	displayname="get Child Value"
	hint="Returns the Child Value(s) for the specified Value"
				>
	<!--- this function needs.... --->
	<cfargument name="ThreadSetID" type="string" default="" hint="the set the thread is in" />
	<cfargument name="ExternalValue" type="string" default="" hint="the value we want to get the child of" />

	<!--- now all of the var declarations, first the arguments which need manipulation --->
	<cfset var theThreadSetID = trim(arguments.ThreadSetID) />
	<cfset var theExternalValue = trim(arguments.ExternalValue) />
	<!--- now vars that will get filled as we go --->
	<cfset var temps1 = StructNew() />	<!--- temp/throwaway struct --->
	<cfset var temps2 = StructNew() />	<!--- temp/throwaway struct --->
	<cfset var thisChildID = "" />	<!--- temp/throwaway var --->
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorText = "getChildValue()<br>" />
	<cfset ret.Data = "" />
	
	<!--- validate the incoming stuff, we need both params --->
	<cfif len(theThreadSetID) and IsNumeric(theThreadSetID) and len(theExternalValue) and IsNumeric(theExternalValue)>
		<!--- we need both arguments --->
		<!--- wrap the whole thing in a try/catch in case something breaks --->
		<cftry>
			<!--- first off see if we have this combo --->
			<cfset temps1 = getThreadID(ThreadSetID="#theThreadSetID#", ExternalValue="#theExternalValue#")>
			<cfif temps1.Error.errorCode eq 0 >
				<!--- we have a threadID for this input value so get its child(ren) --->
				<cfset temps2 = getChildThreadIDfromThreadID(ThreadSetID="#theThreadSetID#", ThreadID="#temps1.data#")>
				<cfif temps2.Error.errorCode eq 0 >
					<!--- we have a parent response that can be a null for no child or a single id or a list if there are many children --->
					<cfif temps2.data neq "">
						<cfloop list="#temps2.data#" index="thisChildID">	<!--- loop over results and make list of parent values --->
							<cfset ret.Data = ListAppend(ret.Data, getThreadValue(ThreadSetID="#theThreadSetID#", ThreadID="#thisChildID#").data) />
						</cfloop>
					<cfelse>
						<!--- no parent, do nothing, return a null --->
					</cfif>
				<cfelse>
					<!--- oops, parent find broke --->
					<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 4) />
					<cfset ret.error.ErrorText = ret.error.ErrorText & temps2.error.ErrorText />
				</cfif>
			<cfelse>
				<!--- oops, not a legit input set of vars --->
				<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 2) />
				<cfset ret.error.ErrorText = ret.error.ErrorText & temps1.error.ErrorText />
			</cfif>
		<cfcatch type="any">
			<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 128) />
			<cfset ret.error.ErrorText = ret.error.ErrorText & 'Oops! Error Caught, error message was: #cfcatch.message#, error detail was: #cfcatch.detail#<br>' />
			<cfset ret.error.ErrorExtra =  cfcatch.TagContext />
			<cflog text="getChildValue() Trapped. ret.error.ErrorCode: #ret.error.ErrorCode# - Error Text: #ret.error.ErrorText# - Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#"  file="UtilitiesErrors" type="Error" application = "yes">
			<cfif application.SLCMS.Config.debug.debugmode>
				getChildValue() trapped - error was:<br>
				<cfdump var="#ret.error.ErrorExtra#">
			</cfif>
		</cfcatch>
		</cftry>
	<cfelse>
		<!--- oops no meaningful parameters so return nothing --->
		<cfset ret.error.ErrorCode = 1 />
		<cfset ret.error.ErrorText = "Invalid parameters: - the ThreadSetID or ExternalValue are either blank or not numeric. They were:- SetID: #theThreadSetID#; ExternalValue: #theExternalValue#" />
	</cfif> <!--- end: incoming parameters validation check --->

	<cfreturn ret  />
</cffunction>

<cffunction name="emptyFunction" output="yes" returntype="struct" access="public"
	displayname="Nothing"
	hint="this is just a shell to copy, 
				can be deleted once coding has finished, 
				and turn off output if we don't need it to save whitespace"
				>
	<!--- this function needs.... --->
	<cfargument name="DatabaseName" type="string" default="" />	<!--- the name of the database --->

	<!--- now all of the var declarations, first the arguments which need manipulation --->
	<cfset var theDataBaseName = XmlFormat(trim(arguments.DatabaseName)) />
	<!--- now vars that will get filled as we go --->
	<cfset var lcntr = 0 />	<!--- temp loop counter --->
	<cfset var temp = "" />	<!--- temp/throwaway var --->
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorText = "TheFunctionName()<br>" />
	<cfset ret.Data = "" />
	
	<!--- validate the incoming stuff --->
	<cfif 1 eq 0>
		<!--- wrap the whole thing in a try/catch in case something breaks despite all the checking above --->
		<cftry>
		<cfcatch type="any">
			<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 128) />
			<cfset ret.error.ErrorText = ret.error.ErrorText & 'Oops! Error Caught, error message was: #cfcatch.message#, error detail was: #cfcatch.detail#<br>' />
			<cfset ret.error.ErrorExtra =  cfcatch.TagContext />
			<cflog text="emptyFunction() Trapped. ret.error.ErrorCode: #ret.error.ErrorCode# - Error Text: #ret.error.ErrorText# - Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#"  file="UtilitiesErrors" type="Error" application = "yes">
			<cfif application.SLCMS.Config.debug.debugmode>
				setNextID() trapped - error was:<br>
				<cfdump var="#ret.error.ErrorExtra#">
			</cfif>
		</cfcatch>
		</cftry>
	<cfelse>
		<!--- oops no meaningful parameters so return nothing --->
		<cfset ret.error.ErrorCode = 1 />
		<cfset ret.error.ErrorText = "Invalid parameters: - DataBaseName - #theDataBaseName#; CounterName - #theCounterName#; TableName - #theTableName#" />
	</cfif> <!--- end: incoming parameters validation check --->

	<cfreturn ret  />
</cffunction>

</cfcomponent>