<!--- mbc SLCMS CFCs  --->
<!--- &copy; 2011 mort bay communications --->
<!---  --->
<!--- security.cfc  --->
<!--- Handles Site Permisssions and Access --->
<!--- this CFC contains no data it just is a set of functions that gather data from wherever needed and passes back results
			as a result all of the functions here do not pass back the usual data structure with error coded, mostly they will pass back a simple true/false
			ie, these functions are the ones called by display tags and the like to see if a user has permission to do something. --->
<!--- Contains:
			init - set up persistent structures 
			lots more related stuff :-)
			 --->
<!---  --->
<!--- created:   1st Sep 2009 by Kym K, mbcomms --->
<!--- modified:  1st Sep 2009 -  5th Sep 2009 by Kym K, mbcomms: initial work --->
<!--- modified: 27th Sep 2009 - 27th Sep 2009 by Kym K, mbcomms: changed role patterns to get from UserControl CFC, changed SuperUser test as CF makes all bits eq -1 so "gt 0" fails --->
<!--- modified: 18th Dec 2009 - 18th Dec 2009 by Kym K, mbcomms: V2.2+ now adding DataMgr as a DAL to make the codebase database agnostic
																																				NOTE: things like the DSN are no longer needed as the DAL knows that
																																							now we can just worry about tables and their contents
																																							See Content_DatabaseIO.cfc for DAL conversion examples (straight queries commented out there, not deleted as here) --->
<!--- modified:  7th Jun 2011 -  8th Jun 2011 by Kym K, mbcomms: added logging functions so we can have consistent logging outside CF's logs --->
<!--- modified: 15th Aug 2011 - 15th Aug 2011 by Kym K, mbcomms: we changed admin users to "staff" in DBs to differentiate from general site users, code upgraded here to match --->
<!--- modified:  4th Mar 2012 -  4th Mar 2012 by Kym K, mbcomms: V2.2+, changed the way roles are stored, now in application scope directly as core alongside any modules we may have --->
<!--- modified:  9th Apr 2012 -  9th Apr 2012 by Kym K, mbcomms: V3.0, CFWheels version. All SLCMS in own struct under app scope --->

<cfcomponent displayname="User Permissions" hint="Handles Site Admin Permissions and Access" output="False">
	
	<!--- set up a few persistant things on the way in. --->
  <!---	
	<cfset variables.RolePatterns = StructNew() />	<!--- this will contain all the bit patterns and related values for each role in the system --->
	--->
	<cfset variables.PermissionScopes = "Global,Content" />	<!--- these are the various scopes that we can test for --->
	<cfset variables.ValidRoles = "Admin,Editor,Author" />	<!--- these are the valid core roles in the system --->
	
<!--- initialize the various thingies, this should only be called after an app scope refresh, 
			it doesn't need to be called after a user added or anything like that as there is no user type data stored here --->
<cffunction name="init" output="No" returntype="boolean" access="public" 
	displayname="Initializer"
	hint="sets up the internal structures for this component"
	>
	<cfset var InitOK = True />
	<cfset var temps = LogIt(LogType="CFC_Init", LogString="UserPermission Init() Started") />
	<!--- minimal set up as we don't actually save anything here apart from the bit patterns that relate to each role --->
	<!---
	<cfset variables.RolePatterns = application.SLCMS.Core.UserControl.getRolePatterns() />
	--->
	<cfset variables.SubSiteIDList_Active = application.SLCMS.Core.PortalControl.GetActiveSubSiteIDList() />	<!--- update it in case we have added/removed a subsite --->
	<cfset variables.SubSiteIDList_Full = application.SLCMS.Core.PortalControl.GetFullSubSiteIDList() />	<!--- update it in case we have added/removed a subsite --->
					
	<cfset temps = LogIt(LogType="CFC_Init", LogString="UserPermission Init() Finished") />
	<cfreturn InitOK />
</cffunction>

<cffunction name="IsAllowedToViewContent" output="No" returntype="boolean" access="public"
	displayname="Is Allowed To View Content"
	hint="returns true or false according to the user's permissions for the content being viewed XXXX this is a ToDo:"
	>
	<!--- ToDo: the whole thing... --->
	<!--- this function needs.... --->
	<cfargument name="UserID" type="string" default="" required="false" hint="Id of user - Optional: defaults to session.SLCMS.user.UserID" />
	<cfargument name="UserRole_Core" type="string" default="" required="false" hint="Role bits of user for the core - Optional: defaults to session.SLCMS.user.UserRoles.core" />
	<cfargument name="ContainerID" type="string" default="" required="false" hint="Id of content" />			<!--- XXXX this is dodgy.... --->

	<!--- now all of the var declarations, first the arguments which need manipulation --->
	<cfset var theUserID = trim(arguments.UserID) />
	<cfset var theUserRole_Core = trim(arguments.UserRole_Core) />
	<cfset var theContainerID = trim(arguments.ContainerID) />
	<!--- now vars that will get filled as we go --->
	<cfset var lcntr = 0 />	<!--- temp loop counter --->
	<cfset var temp = "" />	<!--- temp/throwaway var --->
	<cfset var tempa = ArrayNew(1) />	<!--- temp/throwaway array --->
	<cfset var temps = StructNew() />	<!--- temp/throwaway structure --->
	<cfset var returner = False />	<!--- this is the return to the caller --->
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is just for the error handler --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorContext = "UserPermissions CFC: IsAllowedToViewContent()" />
	<cfset ret.error.ErrorText = "" />
	<cfset ret.error.ErrorExtra = "" />
	<cfset ret.Data = "" />	<!--- no data --->

		<!--- params handler --->
	<cfif theUserID eq "">
		<cfset theUserID = session.SLCMS.user.UserID />
	</cfif>
	<cfif theUserRole_Core eq "">
		<cfset theUserRole_Core = session.SLCMS.user.UserRoles.core />
	</cfif>
	<!--- wrap the whole thing in a try/catch in case something breaks --->
	<cftry>
	<cfcatch type="any">
		<cfset ret.error = TakeErrorCatch(RetErrorStruct=ret.error, CatchStruct=cfcatch) />
	</cfcatch>
	</cftry>

	<cfreturn returner  />
</cffunction>

<cffunction name="HasSiteAdminPermission" output="No" returntype="boolean" access="public"
	displayname="Has Site Admin Permission"
	hint="returns true or false according to the logged-in user's permissions to go into the site admin area. This is a global backend permisssions checker, not subsite or user specific"
	>
	<!--- this function needs.... --->
	<!--- then the return not our normal error handling one but a straight true/false --->
	<cfset var returner = False />	<!--- this is the return to the caller --->
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is just for the error handler --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorContext = "UserPermissions CFC: HasSiteAdminPermission()" />
	<cfset ret.error.ErrorText = "" />
	<cfset ret.error.ErrorExtra = "" />
	<cfset ret.Data = "" />	<!--- no data --->
	<!--- wrap the whole thing in a try/catch in case something breaks --->
	<cftry>
		<cfif session.SLCMS.user.IsSuper>
			<cfset returner = True />	<!--- its an UberAdmin so its yes by default --->
		<cfelseif session.SLCMS.user.IsStaff>
			<cfset returner = True />
		<cfelse>
			<!--- it wasn't a staff member  --->
		</cfif>
	<cfcatch type="any">
			<cfset ret.error = TakeErrorCatch(RetErrorStruct=ret.error, CatchStruct=cfcatch) />
	</cfcatch>
	</cftry>

	<cfreturn returner  />
</cffunction>

<cffunction name="IsAuthor" output="No" returntype="boolean" access="public"
	displayname="Has Site Author Permission"
	hint="returns true or false according to the user's permissions to be an Author. 
				This is a frontend permissions checker by default unless SubSiteID or UserID passed in when it can be used for specific check"
				>
	<!--- this function needs.... --->
	<cfargument name="ScopeToCheck" type="string" default="Global" required="false" hint="Scope of test: Global|Content" />
	<cfargument name="SubSiteID" type="string" required="False" default="" hint="Id of Subsite to check against - Optional: defaults to any subsite" />
	<cfargument name="UserID" type="string" required="false" default="" hint="Id of user - Optional: defaults to session.SLCMS.user.UserID" />
	<!--- Return not our normal error handling one but a straight true/false from the HasRolePermission function --->
	<cfreturn HasRolePermission(UserID="#arguments.UserID#", RoleToCheck="Author", ScopeToCheck="#arguments.ScopeToCheck#", SubSiteID="#arguments.SubSiteID#")>	


<!--- 
	<cfargument name="ScopeToCheck" type="string" required="false" default="Global" hint="Scope of test: Global|Content - Optional: defaults to Global" />
	<cfargument name="SubSiteID" type="string" required="False" default="" hint="Id of Subsite to check against - Optional: defaults to any subsite" />
	<cfargument name="UserID" type="string" required="false" default="" hint="Id of user - Optional: defaults to session.SLCMS.user.UserID" />
	<!--- now all of the var declarations, first the arguments which need manipulation/validation --->
	<cfset var theSubSiteID = trim(arguments.SubSiteID) />
	<cfset var theUserID = trim(arguments.UserID) />
	<!--- now all of the var declarations, first the arguments which need manipulation/validation --->
	<cfset var theScope = trim(arguments.ScopeToCheck) />
	<!--- now vars that will get filled as we go --->
	<cfset var theRoles = "" />
	<!--- then the return not our normal error handling one but a straight true/false --->
	<cfset var ret = False />	<!--- this is the return to the caller, no permission by default --->
	<!--- wrap the whole thing in a try/catch in case something breaks --->
	<cftry>
		<cfif theUserID eq "">
			<cfset theUserID = session.SLCMS.user.UserID />
		</cfif>
		<cfif theSubSiteID eq "">
			<cfset theSubSiteID = request.SLCMS.pageParams.SubSiteID />
		</cfif>
		<cfset variables.SubSiteIDList_Full = application.SLCMS.Core.PortalControl.GetFullSubSiteIDList() />	<!--- update it in case we have added/removed a subsite --->
		<cfif session.SLCMS.user.IsStaff and ListFindNoCase(variables.PermissionScopes, theScope)>
			<!--- first see if we are logged in with any permissions at all anyway --->
			<cfif session.SLCMS.user.IsSuper>
				<cfset ret = True />	<!--- its the UberAdmin so its yes to everything --->
			<cfelseif theUserID neq "" and session.SLCMS.user.security.LoggedIn>
				<!--- we are logged as something so grab the roles to this body --->
				<cfset theRoles = application.SLCMS.Core.UserControl.getRoles_Staff("#theUserID#") />
				<cfif theRoles.system.Global_Rolevalue gt 0>
					<!--- some sort of system user so check at this level --->
					<cfif BitAnd(theRoles.system.Global_RoleValue, variables.RolePatterns.Author_Global.value) gt 0>
						<cfset ret = True />	<!--- has the everything role --->
					<cfelseif BitAnd(theRoles.system["#theScope#_RoleValue"], variables.RolePatterns["Author_#theScope#"].value) gt 0>
						<cfset ret = True />	<!--- has the role in this scope --->
					</cfif>
				<cfelse>
					<!--- not the uberadmin or a system user so must be a regular site staff member so see if the user is in the current subsite and go from there --->
					<cfif StructKeyExists(theRoles, "Site_#theSubSiteID#")>
						<cfif BitAnd(theRoles["Site_#theSubSiteID#"].Global_RoleValue, variables.RolePatterns.Author_Global.value) gt 0>
							<cfset ret = True />
						<cfelseif StructKeyExists(theRoles["Site_#theSubSiteID#"], "#theScope#_RoleValue") and BitAnd(theRoles["Site_#theSubSiteID#"]["#theScope#_RoleValue"], variables.RolePatterns["Author_#theScope#"].value) gt 0>
							<cfset ret = True />
						</cfif>
					</cfif>
				</cfif>
			<cfelse>
				<!--- not logged in so do nothing and return false --->
			</cfif>
		<cfelse>
			<!--- it wasn't a staff member or a bad scope fed in so pass back no permission --->
		</cfif>

	<cfcatch type="any">
		<cflog text="UserPermissions CFC: IsAuthor() Trapped. Site: #application.SLCMS.Config.base.SiteName#. Error Text: 'Oops! Error Caught, error message was: #cfcatch.message#, error detail was: #cfcatch.detail#<br>' - Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#"  file="#Application.Logging.theSiteLogName#" type="Error" application = "yes">
		<cfif application.SLCMS.Config.debug.debugmode>
			UserPermissions CFC: IsAuthor() Trapped - error dump:<br>
			<cfdump var="#cfcatch#">
		</cfif>
	</cfcatch>
	</cftry>

	<cfreturn ret  />
 --->
</cffunction>

<cffunction name="IsEditor" output="No" returntype="boolean" access="public"
	displayname="Has Site Edit Permission"
	hint="returns true or false according to the user's permissions to be an Editor. This is a frontend permissions checker"
	>
	<!--- this function needs.... --->
	<cfargument name="ScopeToCheck" type="string" default="Global" required="false" hint="Scope of test: Global|Content" />
	<cfargument name="SubSiteID" type="string" required="False" default="" hint="Id of Subsite to check against - Optional: defaults to any subsite" />
	<cfargument name="UserID" type="string" required="false" default="" hint="Id of user - Optional: defaults to session.SLCMS.user.UserID" />
	<!--- Return not our normal error handling one but a straight true/false from the HasRolePermission function --->
	<cfreturn HasRolePermission(UserID="#arguments.UserID#", RoleToCheck="Editor", ScopeToCheck="#arguments.ScopeToCheck#", SubSiteID="#arguments.SubSiteID#") />	
</cffunction>

<cffunction name="IsAdmin" output="No" returntype="boolean" access="public"
	displayname="Has Site Admin Permission"
	hint="returns true or false according to the user's permissions to be an Administrator. This is a frontend permissions checker"
	>
	<!--- this function needs.... --->
	<cfargument name="ScopeToCheck" type="string" default="Global" required="false" hint="Scope of test: Global|Content" />
	<cfargument name="SubSiteID" type="string" required="False" default="" hint="Id of Subsite to check against - Optional: defaults to any subsite" />
	<cfargument name="UserID" type="string" required="false" default="" hint="Id of user - Optional: defaults to session.SLCMS.user.UserID" />
	<!--- Return not our normal error handling one but a straight true/false from the HasRolePermission function --->
	<cfreturn HasRolePermission(UserID="#arguments.UserID#", RoleToCheck="Admin", ScopeToCheck="#arguments.ScopeToCheck#", SubSiteID="#arguments.SubSiteID#") />	
</cffunction>

<cffunction name="IsSuper" output="No" returntype="boolean" access="public"
	displayname="Has Super Admin Permission"
	hint="returns true or false according to the user's permissions to be an Uber Admin"
	>
	<!--- this function needs.... --->
	<cfargument name="UserID" type="string" required="false" default="" hint="Id of user - Optional: defaults to session.SLCMS.user.UserID" />
	<!--- Return not our normal error handling one but a straight true/false from the HasRolePermission function --->
	<cfreturn HasRolePermission(UserID="#arguments.UserID#", RoleToCheck="Super", SubSiteID="any")>	
</cffunction>

<cffunction name="HasRolePermission" output="No" returntype="boolean" access="public"
	displayname="Has a Site Role Permission"
	hint="returns true or false according to the user's permissions according to specified context. 
				Used by all the normally called IsRole-type functions to do the deep work"
				>
	<!--- this function needs.... --->
	<cfargument name="RoleToCheck" type="string" required="True" hint="Role to test against" />
	<cfargument name="ScopeToCheck" type="string" required="false" default="Global" hint="Scope of test: Global|Content - Optional: defaults to Global" />
	<cfargument name="SubSiteID" type="string" required="False" default="" hint="Id of Subsite to check against - Optional: defaults to current frontend subsite. 'any' scanns all subsites" />
	<cfargument name="UserID" type="string" required="false" default="" hint="Id of user - Optional: defaults to session.SLCMS.user.UserID" />
	<!--- now all of the var declarations, first the arguments which need manipulation/validation --->
	<cfset var theRole2Check = trim(arguments.RoleToCheck) />
	<cfset var theScope = trim(arguments.ScopeToCheck) />
	<cfset var theSubSiteID = trim(arguments.SubSiteID) />
	<cfset var theUserID = trim(arguments.UserID) />
	<!--- now vars that will get filled as we go --->
	<cfset var theRoles = "" />
	<cfset var theSubSiteList = "" />	<!--- will contain list of how many subsites to look in --->
	<cfset var theUserIsStaff = False />
	<cfset var theUserIsSuper = False />
	<cfset var theUserIsLoggedIn = False />
	<cfset var thisSubSite = "" />	<!--- loop var, will contain subsiteID being looked in --->
	<!--- then the return not our normal error handling one but a straight true/false --->
	<cfset var returner = False />	<!--- this is the return to the caller, no permission by default --->
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is just for the error handler --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorContext = "UserPermissions CFC: HasRolePermission()" />
	<cfset ret.error.ErrorText = "" />
	<cfset ret.error.ErrorExtra = "" />
	<cfset ret.Data = "" />	<!--- no data --->
	<!--- wrap the whole thing in a try/catch in case something breaks --->
	<cftry>
		<cfif theSubSiteID eq "">
			<!--- no subsite means it is a generic front-end request so grab the current page context --->
			<cfset theSubSiteID = request.SLCMS.pageParams.SubSiteID />
		</cfif>
		<cfif theUserID eq "">
			<!--- no user means it is a generic front-end request so grab the current user's context --->
			<cfset theUserID = session.SLCMS.user.UserID />
			<cfset theUserIsStaff = session.SLCMS.user.IsStaff />
			<cfset theUserIsSuper = session.SLCMS.user.IsSuper />
			<cfset theUserIsLoggedIn = session.SLCMS.user.security.LoggedIn />
			<cfset theRoles = application.SLCMS.Core.userControl.getRoles_Staff(theUserID) />
		<cfelse>
			<!--- we have specified a user so grab their roles, etc --->
			<cfset theRoles = application.SLCMS.Core.userControl.getRoles_Staff(theUserID) />
			<cfif not StructIsEmpty(theRoles)>
				<cfset theUserIsStaff = theRoles.IsStaff />
				<cfset theUserIsSuper = theRoles.IsSuper />
				<cfset theUserIsLoggedIn = True />	<!--- assume logged in as we are asking about someone else other than us --->
			<cfelse>
				<cfset theUserIsStaff = False />
				<cfset theUserIsSuper = False />
				<cfset theUserIsLoggedIn = False />
			</cfif>
		</cfif>
		<cfif theUserIsSuper>
			<cfset returner = True />	<!--- its the UberAdmin so its yes to everything --->
		<cfelseif theUserIsStaff and theUserIsLoggedIn>
			<!---  a staff member of some form so do our sums --->
			<cfset variables.SubSiteIDList_Full = application.SLCMS.Core.PortalControl.GetFullSubSiteIDList() />	<!--- update it in case we have added/removed a subsite --->
			<cfif theSubSiteID eq "any">
				<!--- we don't care which subsite, just find anything --->
				<cfset theSubSiteList = variables.SubSiteIDList_Full />
			<cfelse>
				<cfset theSubSiteList = theSubSiteID />
			</cfif>
			<cfif ListFindNoCase(variables.ValidRoles, theRole2Check) and ListFindNoCase(variables.PermissionScopes, theScope)>
				<!--- we are logged as something so we should have the roles to this body from above --->
				<cfif theRoles.system.Global_Rolevalue gt 0>
					<!--- some sort of system user so check at this level --->
					<cfif BitAnd(theRoles.system.Global_RoleValue, application.SLCMS.Roles.Core.Global["#theRole2Check#"].RoleValue) gt 0>
						<cfset returner = True />	<!--- has the everything role --->
					<cfelseif BitAnd(theRoles.system["#theScope#_RoleValue"], application.SLCMS.Roles.Core["#theScope#"]["#theRole2Check#"].RoleValue) gt 0>
						<cfset returner = True />	<!--- has the role in this scope --->
					</cfif>
				<cfelse>
					<!--- not the uberadmin or a system user so must be a regular site staff member so see if the user is in the current subsite and go from there --->
					<cfloop list="#theSubSiteList#" index="thisSubsite">
						<cfif StructKeyExists(theRoles, "Site_#thisSubsite#")>
							<cfif BitAnd(theRoles["Site_#thisSubsite#"].Global_RoleValue, application.SLCMS.Roles.Core.Global["#theRole2Check#"].RoleValue) gt 0>
								<cfset returner = True />
							<cfelseif StructKeyExists(theRoles["Site_#thisSubsite#"], "#theScope#_RoleValue") and BitAnd(theRoles["Site_#thisSubsite#"]["#theScope#_RoleValue"], application.SLCMS.Roles.Core["#theScope#"]["#theRole2Check#"].RoleValue) gt 0>
								<cfset returner = True />
							</cfif>
						</cfif>	<!--- end: has a role in this subsite check --->
					</cfloop>
				</cfif>	<!--- end: has a system role check --->
			<cfelse>
				<!--- not logged in so do nothing and return false --->
			</cfif>
		<cfelse>
			<!--- it wasn't a staff member or a bad scope fed in so pass back no permission --->
		</cfif>

	<cfcatch type="any">
		<cfset ret.error = TakeErrorCatch(RetErrorStruct=ret.error, CatchStruct=cfcatch) />
	</cfcatch>
	</cftry>

	<cfreturn returner  />
</cffunction>

<cffunction name="IsLoggedIn" output="No" returntype="boolean" access="public"
	displayname="Is Logged In"
	hint="returns true or false according to whether the user is logged in"
	>
	<!--- this function needs.... --->
	<!--- then the return not our normal error handling one but a straight true/false --->
	<cfset var ret = session.SLCMS.user.security.LoggedIn />	<!--- this is the return to the caller, whatever is set in the user's session scope --->
	<cfreturn ret  />
</cffunction>

<cffunction name="getAdminName" output="No" returntype="struct" access="public"
	displayname="Get Staff Name"
	hint="gets the username of a staff member from the UserID"
	>
	<!--- this function needs.... --->
	<cfargument name="UserID" type="string" default="" hint="the ID of the user we want to find" />
	<cfargument name="SubSiteID" type="numeric" required="yes" hint="the ID of the subsite to use">

	<!--- now all of the var declarations, first the arguments which need manipulation --->
	<cfset var theUserID = trim(arguments.UserID) />
	<cfset var theSubSiteID = trim(arguments.SubSiteID) />
	<cfset var theQueryDataArguments = StructNew() />	<!--- temp struct to compose the data clauses of SQL queries --->
	<cfset var theQueryWhereArguments = StructNew() />	<!--- temp struct to compose the where clauses of SQL queries --->
	<cfset var theQueryWhereFilters = ArrayNew(1) />	<!--- temp array to compose the filters for where clauses --->
	<cfset var getFullName = "" />	<!--- temp/throwaway var --->
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorContext = "UserPermissions CFC: getAdminName()" />
	<cfset ret.error.ErrorText = "" />
	<cfset ret.error.ErrorExtra = "" />
	<cfset ret.Data = "" />	<!--- and no data yet --->

		<!--- validation --->
	<cfif theUserID eq 1 >
		<cfset ret.Data = "Uber Admin" />
	<cfelseif theUserID neq "" and IsNumeric(theUserID) and IsNumeric(theSubSiteID)>
		<!--- validated so go for it --->
		<!--- wrap the whole thing in a try/catch in case something breaks --->
		<cftry>
			<!--- we might not have what we want so check 'n' set --->
			<cfif not StructKeyExists(variables, "SubSite_#theSubSiteID#")>
				<cfset variables["SubSite_#theSubSiteID#"] = StructNew() />
				<cfset variables["SubSite_#theSubSiteID#"].UserNames = StructNew() />
			</cfif>
			<cfif StructKeyExists(variables["SubSite_#theSubSiteID#"].UserNames, "User_#theUserID#")>
				<!--- if we have the user locally then just grab it --->
				<cfset ret.Data = variables["SubSite_#theSubSiteID#"].UserNames["User_#theUserID#"].Username />
			<cfelse>
				<!--- else find the user in the database --->
				<cfset theQueryWhereArguments.staffID = theUserID />
				<cfset getFullName = application.SLCMS.Core.DataMgr.getRecords(tablename="SLCMS_Site_#theSubSiteID#_Admin_Users", data=theQueryWhereArguments, fieldList="staff_FirstName,staff_LastName") />
				<!--- 
				<cfquery name="getFullName" datasource="#application.SLCMS.Config.datasources.CMS#">
					select	User_FullName
						from	SLCMS_Site_#theSubSiteID#_Admin_Users
						where	UserID = #theUserID#
				</cfquery>
				 --->
				<!--- return it --->
				<cfset ret.Data = "#getFullName.User_FirstName# #getFullName.User_LastName#" />
				<!--- and set in our local persistent scope to save time next time --->
				<cfset variables["SubSite_#theSubSiteID#"].UserNames["User_#theUserID#"] = StructNew() />
				<cfset variables["SubSite_#theSubSiteID#"].UserNames["User_#theUserID#"].UserID = theUserID />
				<cfset variables["SubSite_#theSubSiteID#"].UserNames["User_#theUserID#"].UserName = ret.Data />
			</cfif>
		<cfcatch type="any">
			<cfset ret.error = TakeErrorCatch(RetErrorStruct=ret.error, CatchStruct=cfcatch) />
		</cfcatch>
		</cftry>
	<cfelse>	<!--- this is the error code --->
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 1) />
		<cfset ret.error.ErrorText = ret.error.ErrorText & "Oops! NOt a meaningful UserID<br>" />
	</cfif>

	<!--- return our data structure --->
	<cfreturn ret  />
</cffunction>

<cffunction name="checkUserLogin" output="No" returntype="struct" access="public"
	displayname="check User Login"
	hint="Checks the supplied username and password against all userdatabases and returns the UserID"
	>
	<!--- this function needs.... --->
	<cfargument name="UserName" type="string" required="True" hint="Name user" />
	<cfargument name="UserPassword" type="string" required="True" hint="Password for user" />

	<!--- now all of the var declarations, first the arguments which need manipulation --->
	<cfset var theUserName = trim(arguments.UserName) />
	<cfset var theUserPassword = trim(arguments.UserPassword) />
	<!--- now vars that will get filled as we go --->
	<cfset var lcntr = 0 />	<!--- temp loop counter --->
	<cfset var temp = "" />	<!--- temp/throwaway var --->
	<cfset var listSubSiteIDs = application.SLCMS.Core.PortalControl.GetActiveSubSiteIDList() />	<!--- temp list of the subsites --->
	<cfset var temps = StructNew() />	<!--- temp/throwaway structure --->
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorContext = "UserPermissions CFC: checkUserLogin()" />
	<cfset ret.error.ErrorText = "" />
	<cfset ret.error.ErrorExtra = "" />
	<cfset ret.Data = StructNew() />	<!--- and no data yet --->
	<cfset ret.Data.UserID = 0 />	<!--- no user --->
	<cfset ret.Data.UserFullName = 0 />	<!--- no user --->

		<!--- validation --->
	<cfif len(theUserName) gt 0 and len(theUserPassword) gt 0>
		<!--- validated so go for it --->
		<!--- wrap the whole thing in a try/catch in case something breaks --->
		<cftry>
			<!--- what we must do is walk thru all of the user tables to see if we have this one --->
			<!--- but first lets save time if the user is an UberAdmin --->
			<cfif hash(theUserName) eq application.SLCMS.Config.base.SuperUser_Login and hash(theUserPassword) eq application.SLCMS.Config.base.SuperUser_Password>
				<!--- it is so just create an "all on" scenario --->
				<cfset ret.Data.user = CreateSessionUserStruct(MakeSuper=True) />
				<cfset ret.Data.UserID = 0 />
				<cfset ret.Data.UserName = "SLCMS UberAdmin" />
			<cfelse>
				<!--- nope so see if exists anywhere --->
			</cfif>
		<cfcatch type="any">
			<cfset ret.error = TakeErrorCatch(RetErrorStruct=ret.error, CatchStruct=cfcatch) />
		</cfcatch>
		</cftry>
	<cfelse>	<!--- this is the error code --->
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 1) />
		<cfset ret.error.ErrorText = ret.error.ErrorText & "Oops! Username or Password is blank<br>" />
	</cfif>

	<!--- return our data structure --->
	<cfreturn ret  />
</cffunction>


<cffunction name="getUsersRoles" output="No" returntype="struct" access="public"
	displayname="get Users Roles"
	hint="takes a UserID and returns a struct of the user's roles in every subsite"
	>
	<!--- this function needs.... --->
	<cfargument name="UserID" type="string" required="True" hint="Id of user" />

	<!--- now all of the var declarations, first the arguments which need manipulation --->
	<cfset var theUserID = trim(arguments.UserID) />
	<!--- now vars that will get filled as we go --->
	<cfset var thisSubSite = "" />	<!--- temp/throwaway var --->
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorContext = "Userpermissions CFC: getUsersRoles" />
	<cfset ret.error.ErrorExtra = "" />
	<cfset ret.Data = "" />	<!--- and no data yet --->
	<cfset ret.Data.BySite = StructNew() />
	<cfset ret.Data.CurrentState = StructNew() />
	<cfset ret.Data.CurrentState.IsSuper = False />
	<cfset ret.Data.CurrentState.IsAdmin = False />
	<cfset ret.Data.CurrentState.IsEditor = False />
	<cfset ret.Data.CurrentState.IsAuthor = False />
	<cfset ret.Data.UserID = 0 />

		<!--- validation --->
	<cfif len(theUserID)>
		<!--- validated so go for it --->
		<!--- wrap the whole thing in a try/catch in case something breaks --->
		<cftry>
			<!--- fudge for the moment,just an "all off" structure --->
			<cfset ret.Data.BySite = StructNew() />
			<cfloop list="#application.SLCMS.Core.PortalControl.GetActiveSubSiteIDList()#" index="thisSubSite">
				<cfset ret.Data.BySite["Site_#thisSubSite#"] = StructNew() />
				<cfset ret.Data.BySite["Site_#thisSubSite#"].rolePattern = "00000000"&"00000000"&"00000000"&"00000000" />
				<cfset ret.Data.BySite["Site_#thisSubSite#"].IsAdmin = False />
				<cfset ret.Data.BySite["Site_#thisSubSite#"].IsEditor = False />
				<cfset ret.Data.BySite["Site_#thisSubSite#"].IsAuthor = False />
			</cfloop>
		<cfcatch type="any">
			<cfset ret.error = TakeErrorCatch(RetErrorStruct=ret.error, CatchStruct=cfcatch) />
		</cfcatch>
		</cftry>
	<cfelse>	<!--- this is the error code --->
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 1) />
		<cfset ret.error.ErrorText = ret.error.ErrorText & "Oops! No UserID supplied<br>" />
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
			<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 128) />
			<cfset ret.error.ErrorText = ret.error.ErrorContext & ' Trapped. Site: #application.SLCMS.Config.base.SiteName#, error message was: #cfcatch.message#, error detail was: #cfcatch.detail#' />
			<cfset ret.error.ErrorExtra =  cfcatch.TagContext />
			<cfif isArray(ret.error.ErrorExtra) and StructKeyExists(ret.error.ErrorExtra[1], "Raw_Trace")>
				<cfset ret.error.ErrorText = ret.error.ErrorText & ", Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#" />
			</cfif>
			<cflog text='#ret.error.ErrorText# - ret.error.ErrorCode: #ret.error.ErrorCode# - Time: #DateFormat(Now(),"YYYYMMDD")#-#TimeFormat(now(),"HH:mm:ss")#'  file="#Application.Logging.theSiteLogName#" type="Error" application = "yes">
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

</cfcomponent>
