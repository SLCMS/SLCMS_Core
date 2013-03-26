<cfcomponent output="false" extends="Controller" 
	displayname="Core API" 
	hint="API for general purpose calls from the core">
<!--- mbc SL_PhotoGallery CFCs  --->
<!--- &copy; 2011 mort bay communications --->
<!---  --->
<!--- API CFC for the gallery, 
			handles calls to let the module relate to the core admin code
			this is not persistent, each method call must stand alone
			 --->
<!--- Contains:
			makeQuickFriendlyStringFromParamSet - returns a suitably friendly string for this module for the page params
			makeStringFriendly - converts a suplied horrid string to something nice according to this module's style
			 --->
<!---  --->
<!--- created:  22nd Apr 2011 by Kym K, mbcomms --->
<!--- modified: 22nd Apr 2011 - 23rd Apr 2011 by Kym K, mbcomms: initial work on it --->
<!--- modified: 29th Apr 2011 - 29th Apr 2011 by Kym K, mbcomms: first pass finished, taking all CFCs to no output, etc., for test --->
<!--- modified:  2nd May 2011 -  2nd May 2011 by Kym K, mbcomms: bug fixes, 
																																changed getQuickRelURL to getQuickRelPath as we are using it for physical paths as well as URLs now that all cfml platforms work with a slash for any OS, 
																																ditto for getQuickBaseURL now getQuickBasePath with flag to show which to return, URL or physcal path
																																 --->

	
	<cfset variables.makeStringFriendly_FormatList = "param2,param3,param4" />	<!--- list of legitimate formats that can be used --->
	<cfset variables.makeStringFriendly_ContextList = "PageProperties" />	<!--- list of legitimate contexts that can be used --->
	<cfset variables.ACAPPComponent = "#application.modules.SL_PhotoGallery.Paths.CFCroot#.API_CoreAdmin_PageProperties" />

<!--- not persistent so not much to do to init the thing --->
<cffunction name="init" 
	access="public" output="no" returntype="any" 
	displayname="Initializer"
	hint="sets up the internal structures for this component"
	>
	<cfreturn this />
</cffunction>

<cffunction name="makeQuickFriendlyStringFromParamSet" output="no" returntype="string" access="public"
	displayname="make Friendly String From Param Set"
	hint="turns a page's set of params into friendly string. Quick return, no error handling as garbage in gives nulls out :-)"
	>
	<cfset var theDataStruct = "" />
	<cfset var theRelString = "" />
	<cfset var retFormattedString = "" />
	<cfset var ret = "" />	<!--- Quick function so just a string back --->

	<!--- hard to check for anything as could get just about anything you care to name so we will look for valid combinations and ignore the rest --->
	<cfif StructKeyExists(arguments, "Param4") and StructKeyExists(arguments, "Param3") and IsValid("UUID", arguments.param3)>
		<!--- we have what is probably an ID set for album, collection or gallery --->
		<cfif arguments.param4 eq "Album">
			<!--- this means that param3 should have the Album's UID --->
			<cfif StructKeyExists(application.modules.SL_PhotoGallery.Lookups.AlbumUIDs, "#arguments.param3#")>
				<!--- we have viable things so lets work out what to do with these params --->
				<cfset theDataStruct = application.modules.SL_PhotoGallery.Lookups.AlbumUIDs["#arguments.param3#"] />
				<cfset theRelString = "#application.Modules.SL_PhotoGallery.Functions.Utilities_Persistent.getQuickRelPath(subSiteID="#theDataStruct.SubSiteID#", GalleryID="#theDataStruct.GalleryID#", CollectionID="#theDataStruct.CollectionID#", AlbumID="#theDataStruct.AlbumID#", MakeFriendly=True)#" />
			</cfif>
		<cfelseif arguments.param4 eq "Collection">
			<cfif StructKeyExists(application.modules.SL_PhotoGallery.Lookups.CollectionUIDs, "#arguments.param3#")>
				<cfset theDataStruct = application.modules.SL_PhotoGallery.Lookups.CollectionUIDs["#arguments.param3#"] />
				<cfset theRelString = "#application.Modules.SL_PhotoGallery.Functions.Utilities_Persistent.getQuickRelPath(subSiteID="#theDataStruct.SubSiteID#", GalleryID="#theDataStruct.GalleryID#", CollectionID="#theDataStruct.CollectionID#", MakeFriendly=True)#" />
			</cfif>
		<cfelseif arguments.param4 eq "Gallery">
			<cfif StructKeyExists(application.modules.SL_PhotoGallery.Lookups.GalleryUIDs, "#arguments.param3#")>
				<cfset theDataStruct = application.modules.SL_PhotoGallery.Lookups.GalleryUIDs["#arguments.param3#"] />
				<cfset theRelString = "#application.Modules.SL_PhotoGallery.Functions.Utilities_Persistent.getQuickRelPath(subSiteID="#theDataStruct.SubSiteID#", GalleryID="#theDataStruct.GalleryID#", MakeFriendly=True)#" />
			</cfif>
		</cfif>
		<cfset retFormattedString = makeStringFriendly(String="#theRelString#", format="Param3") />
		<cfif retFormattedString.error.errorcode eq 0>
			<cfset ret = retFormattedString.data />
		</cfif>
	</cfif>

	<!--- return our data structure --->
	<cfreturn ret  />
</cffunction>

<cffunction name="makeStringFriendly" output="no" returntype="struct" access="public"
	displayname="make String Friendly"
	hint="convert supplied string to friendly format"
	>
	<!--- this function needs.... --->
	<cfargument name="String" type="string" default="" hint="The string we want to make friendly" />
	<cfargument name="Format" type="string" default="" hint="The format we want it in" />
	<cfargument name="Context" type="string" default="PageProperties" hint="[PageProperties] The context of the place we want this, can affect the format" />

	<!--- now all of the var declarations, first the arguments which need manipulation --->
	<cfset var theString = trim(arguments.String) />
	<cfset var theFormat = trim(arguments.Format) />
	<cfset var theContext = trim(arguments.Context) />
	<!--- now vars that will get filled as we go --->
	<cfset var theFormattedString = "" />
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorContext = "SL Photo Gallery Core API CFC: makeStringFriendly()" />
	<cfset ret.error.ErrorText = "" />
	<cfset ret.error.ErrorExtra = "" />
	<cfset ret.Data = theString />	<!--- if we don't hit hit anything return the string untouched --->

		<!--- check for a viable format request --->
	<cfif ListFindNoCase(variables.makeStringFriendly_FormatList, theFormat)>
		<cfif ListFindNoCase(variables.makeStringFriendly_ContextList, theContext)>
			<!--- we have viable things so lets work out what to do with this string --->
			<cftry>
				<cfif theContext eq "PageProperties">
					<!--- call the formatter in the pageProperties CFC as we already have code to do this --->
					<cfinvoke component="#variables.ACAPPComponent#" method="makeQuickParamFriendly" returnvariable="theFormattedString">
						<cfinvokeargument name="ParamString" value="#theString#">
						<cfinvokeargument name="Format" value="#theFormat#">
					</cfinvoke>
					<cfset ret.Data = theFormattedString />
				<cfelse>
				</cfif>
			<cfcatch type="any">
				<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 128) />
				<cfset ret.error.ErrorText = ret.error.ErrorContext & ' Trapped. Site: #application.config.base.SiteName#, error message was: #cfcatch.message#, error detail was: #cfcatch.detail#' />
				<cfset ret.error.ErrorExtra =  cfcatch.TagContext />
				<cfif isArray(ret.error.ErrorExtra) and StructKeyExists(ret.error.ErrorExtra[1], "Raw_Trace")>
					<cfset ret.error.ErrorText = ret.error.ErrorText & ", Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#" />
				</cfif>
				<cflog text='#ret.error.ErrorText# - ret.error.ErrorCode: #ret.error.ErrorCode# - Time: #DateFormat(Now(),"YYYYMMDD")#-#TimeFormat(now(),"HH:mm:ss")#'  file="#Application.Logging.theSiteLogName#" type="Error" application = "yes">
				<cfif application.config.debug.debugmode>
					<cfoutput>#ret.error.ErrorContext#</cfoutput> Trapped - error dump:<br>
					<cfdump var="#cfcatch#">
				</cfif>
			</cfcatch>
			</cftry>
		<cfelse>	<!--- this is the error code --->
			<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 2) />
			<cfset ret.error.ErrorText = ret.error.ErrorText & "Invalid Context Supplied. Context was: #theContext#" />
		</cfif>
	<cfelse>	<!--- this is the error code --->
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 1) />
		<cfset ret.error.ErrorText = ret.error.ErrorText & "Invalid Format Supplied. Format was: #theFormat#" />
	</cfif>

	<!--- return our data structure --->
	<cfreturn ret  />
</cffunction>

</cfcomponent>