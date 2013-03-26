<cfcomponent displayname="User Handler" hint="Handles Site Admin Permissions and Access" output="False">
<!--- mbc SLCMS CFCs  --->
<!--- &copy; 2011 mort bay communications --->
<!---  --->
<!--- UserControl.cfc  --->
<!--- Handles Site Permisssions and Access --->
<!--- Contains:
			init - set up persistent structures for the site styling, etc but in application scope so the diplay tags can grab easily
			lots more related stuff :-)
			 --->
<!---  --->
<!--- created:  30th Jan 2009 by Kym K, mbcomms --->
<!--- modified: 30th Jan 2009 - 26th Feb 2009 by Kym K, mbcomms: initial work on it --->
<!--- modified: 25th Jul 2009 - 29th Jul 2009 by Kym K, mbcomms: adding login and session setting code --->
<!--- modified: 30th Aug 2009 -  5th Sep 2009 by Kym K, mbcomms: more user functions, less code elsewhere --->
<!--- modified: 27th Sep 2009 -  2nd Oct 2009 by Kym K, mbcomms: added getRolePatterns function, refining function results --->
<!--- modified: 18th Dec 2009 - 18th Dec 2009 by Kym K, mbcomms: V2.2+, now adding DataMgr as a DAL to make the codebase database agnostic
																																				NOTE: things like the DSN are no longer needed as the DAL knows that
																																							now we can just worry about tables and their contents
																																							See Content_DatabaseIO.cfc for DAL conversion examples (straight queries commented out there, not deleted as here) --->
<!--- modified:  7th Jun 2011 -  8th Jun 2011 by Kym K, mbcomms: V2.2+, added logging functions so we can have consistent logging outside CF's logs --->
<!--- modified: 15th Aug 2011 - 17th Aug 2011 by Kym K, mbcomms: V2.2+, we changed admin users to "staff" in DBs, code upgraded here to match --->
<!--- modified:  8th Nov 2011 - 18th Nov 2011 by Kym K, mbcomms: V2.2+, finishing change of LogIn to SignIn in database tables, etc --->
<!--- modified:  4th Mar 2012 -  4th Mar 2012 by Kym K, mbcomms: V2.2+, changed the way roles are stored, now in application scope directly as core alongside any modules we may have --->
<!--- modified:  9th Apr 2012 -  9th Apr 2012 by Kym K, mbcomms: V3.0, CFWheels version. All SLCMS in own struct under app scope --->

	<!--- set up a few persistant things on the way in. --->
	<cfset variables.StaffDetailsBySite = StructNew() />	<!--- struct of full details for staff users, ordered by site --->
	<cfset variables.StaffDetailsByUser = StructNew() />	<!--- struct of full details for staff users, ordered by user --->
	<cfset variables.StaffRoles = StructNew() />	<!--- struct of role details for staff users, ordered by staffID --->
  <!---
	<cfset variables.RolePatterns = StructNew() />	<!--- struct of the bit patterns for each role --->
	--->
<!--- initialize the various thingies, this should only be called after an app scope refresh --->
<cffunction name="init" output="No" returntype="struct" access="public" 
	displayname="Initializer"
	hint="sets up the internal structures for this component"
	>

	<cfset var theQueryDataArguments = StructNew() />	<!--- temp struct to compose the data clauses of SQL queries --->
	<cfset var theQueryWhereArguments = StructNew() />	<!--- temp struct to compose the where clauses of SQL queries --->
	<cfset var theQueryWhereFilters = ArrayNew(1) />	<!--- temp array to compose the filters for where clauses --->
	<cfset var getStaffRoles = "" />	<!--- temp/throwaway query --->
	<cfset var retRefreshAdminDetails = StructNew() />

	<cfset temps = LogIt(LogType="CFC_Init", LogString="UserControl Init() Started") />
	
	<!--- minimal set up as we don't add persistent things in until they are used to keep everything small and fast
				why load a squillion users when most are not going to be used? --->
	<!--- that doesn't apply to the admins, not many of them.... --->
	<cfset retRefreshAdminDetails = RefreshAdminDetails() />
	<!---
	<!--- and we need the bit patterns that defines each role --->
	<cfset getStaffRoles = application.SLCMS.Core.DataMgr.getRecords(tablename="#application.SLCMS.Config.DatabaseDetails.TableName_TypeStaffRolesTable#", data=theQueryWhereArguments, fieldList="staff_RoleName,staff_RoleBits") />
	<cfloop query="getStaffRoles">
		<cfset variables.RolePatterns["#getStaffRoles.staff_RoleName#"] = StructNew() />
		<cfset variables.RolePatterns["#getStaffRoles.staff_RoleName#"].bits = getStaffRoles.staff_RoleBits />
		<cfset variables.RolePatterns["#getStaffRoles.staff_RoleName#"].value = application.mbc_Utility.Utilities.Bits32ToInt(getStaffRoles.staff_RoleBits) />
	</cfloop>
	<!--- 
	<cfset variables.RolePatterns.SuperUser = StructNew() />
	<cfset variables.RolePatterns.SuperUser.bits = "11111111111111111111111111111111" />
	<cfset variables.RolePatterns.SuperUser.value = application.mbc_Utility.Utilities.Bits32ToInt("#variables.RolePatterns.SuperUser.bits#") />
	<cfset variables.Sites= StructNew() />	<!--- a struct to keep the admin logins in --->
	 --->	
	 --->
	<cfset temps = LogIt(LogType="CFC_Init", LogString="UserControl Init() Finished") />
	<cfreturn retRefreshAdminDetails />
</cffunction>

<cffunction name="RefreshAdminDetails" output="No" returntype="struct" access="public"
	displayname="Refresh Admin Details"
	hint="Reads Admin Login details into variables scope, called by init() and should be called if users are edited in any way
				fills two scopes: one for full details sorted by site; one by staffID for fast permssions lookup"
	>
	<!--- this function needs ....nothing.... --->

	<!--- now vars that will get filled as we go --->
	<cfset var lcntr = 0 />	<!--- temp loop counter --->
	<cfset var theDatabaseTable = "" />	<!--- temp/throwaway var --->
	<cfset var thisSubSite = "" />	<!--- temp/throwaway loop index --->
	<cfset var thisLogin = "" />	<!--- temp/throwaway loop index --->
	<cfset var theQueryDataArguments = StructNew() />	<!--- temp struct to compose the data clauses of SQL queries --->
	<cfset var theQueryWhereArguments = StructNew() />	<!--- temp struct to compose the where clauses of SQL queries --->
	<cfset var theQueryWhereFilters = ArrayNew(1) />	<!--- temp array to compose the filters for where clauses --->
	<cfset var getUser = "" />	<!--- temp/throwaway query --->
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorContext = "UserControl CFC: RefreshAdminDetails()" />
	<cfset ret.error.ErrorText = "" />
	<cfset ret.error.ErrorExtra = "" />
	<cfset ret.Data = "" />	<!--- and no data yet --->

	<!--- wrap the whole thing in a try/catch in case something breaks --->
	<cftry>
		<!--- we hit this twice, once for the UberAdmin in the system table and then again looping over all of the subsites
					and each section we do twice, once to fill the full details struct and once to add in a staffID --->
		<cfset theQueryWhereArguments.user_Active = 1 />
		<cfset getUser = application.SLCMS.Core.DataMgr.getRecords(tablename="#application.SLCMS.Config.DatabaseDetails.TableName_SystemAdminDetailsTable#", data=theQueryWhereArguments, fieldList="staffID,staff_SignIn,staff_Password,Global_RoleBits,Global_RoleValue,staff_FirstName,staff_LastName,staff_Eddress,user_Active") />
		<!--- 
		<cfquery name="getUser" datasource="#application.SLCMS.Config.datasources.CMS#">
			SELECT	staffID, staff_SignIn, staff_Password, Global_RoleBits, Global_RoleValue, staff_FullName, staff_Eddress, user_Active
				FROM	#application.SLCMS.Config.DatabaseDetails.TableName_SystemAdminDetailsTable#
				Where user_Active = 1
		</cfquery>
		 --->
		<cfset variables.StaffDetailsBySite.System = StructNew() />	<!--- struct of names for UberAdmin users --->
		<cfloop query="getUser">
			<cfset variables.StaffDetailsBySite.System["staff_#getUser.staffID#"] = duplicate(CreateBlankUserStruct_Variables()) />	<!--- a struct to keep the UberAdmin logins in --->
			<cfset variables.StaffDetailsBySite.System["staff_#getUser.staffID#"].LoginDetails.staffID = getUser.staffID />
			<cfset variables.StaffDetailsBySite.System["staff_#getUser.staffID#"].LoginDetails.staff_SignIn = getUser.staff_SignIn />
			<cfset variables.StaffDetailsBySite.System["staff_#getUser.staffID#"].LoginDetails.staff_Password = getUser.staff_Password />
			<cfset variables.StaffDetailsBySite.System["staff_#getUser.staffID#"].LoginDetails.staff_FirstName = getUser.staff_FirstName />
			<cfset variables.StaffDetailsBySite.System["staff_#getUser.staffID#"].LoginDetails.staff_LastName = getUser.staff_LastName />
			<cfset variables.StaffDetailsBySite.System["staff_#getUser.staffID#"].NameDetails.staffID = getUser.staffID />
			<cfset variables.StaffDetailsBySite.System["staff_#getUser.staffID#"].NameDetails.staff_FirstName = getUser.staff_FirstName />
			<cfset variables.StaffDetailsBySite.System["staff_#getUser.staffID#"].NameDetails.staff_LastName = getUser.staff_LastName />
			<cfset variables.StaffDetailsBySite.System["staff_#getUser.staffID#"].NameDetails.staff_FullName = getUser.staff_FirstName & " " & getUser.staff_LastName />
			<cfset variables.StaffDetailsBySite.System["staff_#getUser.staffID#"].NameDetails.staff_Eddress = getUser.staff_Eddress />
			<cfset variables.StaffDetailsBySite.System["staff_#getUser.staffID#"].Roles.Global_RoleBits = getUser.Global_RoleBits />
			<cfset variables.StaffDetailsBySite.System["staff_#getUser.staffID#"].Roles.Global_RoleValue = getUser.Global_RoleValue />
			<!--- now the details into a quick details table --->
			<cfif not StructKeyExists(variables.StaffDetailsByUser, "staff_#getUser.staffID#")>
				<cfset variables.StaffDetailsByUser["staff_#getUser.staffID#"] = StructNew() />
				<cfset variables.StaffDetailsByUser["staff_#getUser.staffID#"].LoginDetails.staffID = getUser.staffID />
				<cfset variables.StaffDetailsByUser["staff_#getUser.staffID#"].LoginDetails.staff_SignIn = getUser.staff_SignIn />
				<cfset variables.StaffDetailsByUser["staff_#getUser.staffID#"].LoginDetails.staff_Password = getUser.staff_Password />
				<cfset variables.StaffDetailsByUser["staff_#getUser.staffID#"].LoginDetails.staff_FirstName = getUser.staff_FirstName />
				<cfset variables.StaffDetailsByUser["staff_#getUser.staffID#"].LoginDetails.staff_LastName = getUser.staff_LastName />
				<cfset variables.StaffDetailsByUser["staff_#getUser.staffID#"].NameDetails.staffID = getUser.staffID />
				<cfset variables.StaffDetailsByUser["staff_#getUser.staffID#"].NameDetails.staff_FirstName = getUser.staff_FirstName />
				<cfset variables.StaffDetailsByUser["staff_#getUser.staffID#"].NameDetails.staff_LastName = getUser.staff_LastName />
				<cfset variables.StaffDetailsByUser["staff_#getUser.staffID#"].NameDetails.staff_FullName = getUser.staff_FirstName & " " & getUser.staff_LastName />
				<cfset variables.StaffDetailsByUser["staff_#getUser.staffID#"].NameDetails.staff_Eddress = getUser.staff_Eddress />
			</cfif>
			<!--- now the detail done see if we have this user in the quick roles table --->
			<cfif not StructKeyExists(variables.StaffRoles, "staff_#getUser.staffID#")>
				<cfset variables.StaffRoles["staff_#getUser.staffID#"] = StructNew() />
				<cfset variables.StaffRoles["staff_#getUser.staffID#"].IsStaff = True />
				<cfset variables.StaffRoles["staff_#getUser.staffID#"].IsSuper = True />
				<cfset variables.StaffRoles["staff_#getUser.staffID#"].system = StructNew() />
				<cfset variables.StaffRoles["staff_#getUser.staffID#"].system.Global_RoleBits = getUser.Global_RoleBits />
				<cfset variables.StaffRoles["staff_#getUser.staffID#"].system.Global_RoleValue = getUser.Global_RoleValue />
			</cfif>
		</cfloop>
		<!--- now the subsites, not UberAdmins --->
		<cfset StructClear(theQueryWhereArguments) />
		<cfset theQueryWhereArguments.user_Active = 1 />
		<cfloop list="#application.SLCMS.Core.PortalControl.GetActiveSubSiteIDList()#" index="thisSubSite">
			<cfset variables.StaffDetailsBySite["Site_#thisSubSite#"] = StructNew() />	<!--- struct for this subsite to keep the admin logins data --->
			<cfset theDatabaseTable = application.SLCMS.Config.DatabaseDetails.databaseTableNaming_Root_Site
																& thisSubSite 
																& application.SLCMS.Config.DatabaseDetails.databaseTableNaming_Tail_SiteAdminDetail />	<!--- the database table name --->
			<cfset getUser = application.SLCMS.Core.DataMgr.getRecords(tablename="#theDatabaseTable#", data=theQueryWhereArguments, fieldList="staffID,staff_SignIn,staff_Password,Global_RoleBits,Global_RoleValue,staff_FirstName,staff_LastName,staff_Eddress,user_Active") />
			<!--- 
			<cfquery name="getUser" datasource="#application.SLCMS.Config.datasources.CMS#">
				SELECT	staffID, staff_SignIn, staff_Password, Global_RoleBits, Global_RoleValue, staff_FullName, staff_Eddress, user_Active
					FROM	#theDatabaseTable#
					Where user_Active = 1
			</cfquery>
			 --->
			<cfloop query="getUser">
				<cfset variables.StaffDetailsBySite["Site_#thisSubSite#"]["staff_#getUser.staffID#"] = duplicate(CreateBlankUserStruct_Variables()) />	<!--- a struct to keep the Site admin logins in --->
				<cfset variables.StaffDetailsBySite["Site_#thisSubSite#"]["staff_#getUser.staffID#"].LoginDetails.staffID = getUser.staffID />
				<cfset variables.StaffDetailsBySite["Site_#thisSubSite#"]["staff_#getUser.staffID#"].LoginDetails.staff_SignIn = getUser.staff_SignIn />
				<cfset variables.StaffDetailsBySite["Site_#thisSubSite#"]["staff_#getUser.staffID#"].LoginDetails.staff_Password = getUser.staff_Password />
				<cfset variables.StaffDetailsBySite["Site_#thisSubSite#"]["staff_#getUser.staffID#"].LoginDetails.staff_FirstName = getUser.staff_FirstName />
				<cfset variables.StaffDetailsBySite["Site_#thisSubSite#"]["staff_#getUser.staffID#"].LoginDetails.staff_lastName = getUser.staff_LastName />
				<cfset variables.StaffDetailsBySite["Site_#thisSubSite#"]["staff_#getUser.staffID#"].NameDetails.staffID = getUser.staffID />
				<cfset variables.StaffDetailsBySite["Site_#thisSubSite#"]["staff_#getUser.staffID#"].NameDetails.staff_FirstName = getUser.staff_FirstName />
				<cfset variables.StaffDetailsBySite["Site_#thisSubSite#"]["staff_#getUser.staffID#"].NameDetails.staff_LastName = getUser.staff_LastName />
				<cfset variables.StaffDetailsBySite["Site_#thisSubSite#"]["staff_#getUser.staffID#"].NameDetails.staff_FullName = getUser.staff_FirstName & " " & getUser.staff_LastName />
				<cfset variables.StaffDetailsBySite["Site_#thisSubSite#"]["staff_#getUser.staffID#"].NameDetails.staff_Eddress = getUser.staff_Eddress />
				<cfset variables.StaffDetailsBySite["Site_#thisSubSite#"]["staff_#getUser.staffID#"].Roles.Global_RoleBits = getUser.Global_RoleBits />
				<cfset variables.StaffDetailsBySite["Site_#thisSubSite#"]["staff_#getUser.staffID#"].Roles.Global_RoleValue = getUser.Global_RoleValue />
				<!--- now the details into a quick details table --->
				<cfif not StructKeyExists(variables.StaffDetailsByUser, "staff_#getUser.staffID#")>
					<cfset variables.StaffDetailsByUser["staff_#getUser.staffID#"] = StructNew() />
					<cfset variables.StaffDetailsByUser["staff_#getUser.staffID#"].LoginDetails = StructNew() />
					<cfset variables.StaffDetailsByUser["staff_#getUser.staffID#"].LoginDetails.staffID = getUser.staffID />
					<cfset variables.StaffDetailsByUser["staff_#getUser.staffID#"].LoginDetails.staff_SignIn = getUser.staff_SignIn />
					<cfset variables.StaffDetailsByUser["staff_#getUser.staffID#"].LoginDetails.staff_Password = getUser.staff_Password />
					<cfset variables.StaffDetailsByUser["staff_#getUser.staffID#"].LoginDetails.staff_FirstName = getUser.staff_FirstName />
					<cfset variables.StaffDetailsByUser["staff_#getUser.staffID#"].LoginDetails.staff_LastName = getUser.staff_LastName />
					<cfset variables.StaffDetailsByUser["staff_#getUser.staffID#"].NameDetails = StructNew() />
					<cfset variables.StaffDetailsByUser["staff_#getUser.staffID#"].NameDetails.staffID = getUser.staffID />
					<cfset variables.StaffDetailsByUser["staff_#getUser.staffID#"].NameDetails.staff_FirstName = getUser.staff_FirstName />
					<cfset variables.StaffDetailsByUser["staff_#getUser.staffID#"].NameDetails.staff_LastName = getUser.staff_LastName />
					<cfset variables.StaffDetailsByUser["staff_#getUser.staffID#"].NameDetails.staff_FullName = getUser.staff_FirstName & " " & getUser.staff_LastName />
					<cfset variables.StaffDetailsByUser["staff_#getUser.staffID#"].NameDetails.staff_Eddress = getUser.staff_Eddress />
				</cfif>
				<!--- now the detail done see if we have this user in the quick roles table --->
				<cfif not StructKeyExists(variables.StaffRoles, "staff_#getUser.staffID#")>
					<cfset variables.StaffRoles["staff_#getUser.staffID#"] = StructNew() />
					<!--- if we are here this user did not get created as a system user so make a non-role struct there --->
					<cfset variables.StaffRoles["staff_#getUser.staffID#"].IsStaff = True />
					<cfset variables.StaffRoles["staff_#getUser.staffID#"].IsSuper = False />
					<cfset variables.StaffRoles["staff_#getUser.staffID#"].system.Global_RoleBits = "00000000"&"00000000"&"00000000"&"00000000" />
					<cfset variables.StaffRoles["staff_#getUser.staffID#"].system.Global_RoleValue = 0 />
				</cfif>
				<!--- then then for this site --->
				<cfif not StructKeyExists(variables.StaffRoles["staff_#getUser.staffID#"], "Site_#thisSubSite#")>
					<cfset variables.StaffRoles["staff_#getUser.staffID#"]["Site_#thisSubSite#"] = StructNew() />
				</cfif>
				<cfset variables.StaffRoles["staff_#getUser.staffID#"]["Site_#thisSubSite#"].Global_RoleBits = getUser.Global_RoleBits />
				<cfset variables.StaffRoles["staff_#getUser.staffID#"]["Site_#thisSubSite#"].Global_RoleValue = getUser.Global_RoleValue />
			</cfloop>
		</cfloop>
		<!--- and the Uber Admin in case she is in there doing stuff, it needs logging just like regular staff --->
		<cfset variables.StaffDetailsByUser["staff_0"] = StructNew() />
		<cfset variables.StaffDetailsByUser["staff_0"].LoginDetails = StructNew() />
		<cfset variables.StaffDetailsByUser["staff_0"].LoginDetails.staffID = 0 />
		<cfset variables.StaffDetailsByUser["staff_0"].LoginDetails.staff_SignIn = "" />
		<cfset variables.StaffDetailsByUser["staff_0"].LoginDetails.staff_Password = "" />
		<cfset variables.StaffDetailsByUser["staff_0"].LoginDetails.staff_FirstName = "Uber" />
		<cfset variables.StaffDetailsByUser["staff_0"].LoginDetails.staff_LastName = "Admin" />
		<cfset variables.StaffDetailsByUser["staff_0"].NameDetails = StructNew() />
		<cfset variables.StaffDetailsByUser["staff_0"].NameDetails.staffID = 0 />
		<cfset variables.StaffDetailsByUser["staff_0"].NameDetails.staff_FirstName = "Uber" />
		<cfset variables.StaffDetailsByUser["staff_0"].NameDetails.staff_LastName = "Admin" />
		<cfset variables.StaffDetailsByUser["staff_0"].NameDetails.staff_FullName = "Uber Admin" />
		<cfset variables.StaffDetailsByUser["staff_0"].NameDetails.staff_Eddress = "" />
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

	<!--- return our data structure --->
	<cfreturn ret  />
</cffunction>

<cffunction name="CreateBlankUserStruct_Variables" output="No" returntype="struct" access="public"
	displayname="Create Blank UserStruct for use in this CFC's variables scope"
	hint="returns an empty struct of the form needed to be used in a users session scope"
	>
	<!--- this function needs.... --->

	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.LoginDetails = duplicate(CreateBlankUserStruct_LoginDetails()) />	<!--- a struct to keep the login details in --->
	<cfset ret.NameDetails = duplicate(CreateBlankUserStruct_NameDetails()) />	<!--- a struct to keep the login details in --->
	<cfset ret.Roles = duplicate(CreateBlankUserStruct_Roles()) />	<!--- a struct to keep the role details in --->

	<!--- return our data structure --->
	<cfreturn ret  />
</cffunction>

<cffunction name="CreateBlankUserStruct_Session" output="No" returntype="struct" access="public"
	displayname="Create Blank UserStruct Session"
	hint="returns an empty struct of the form needed to be used in the session.user scope"
	>
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.userID = "" />
	<cfset ret.IsLoggedIn = False />
	<cfset ret.IsStaff = False />
	<cfset ret.IsSuper = False />
	<cfset ret.IsEmulatingUser = False />
	<cfset ret.LoginDetails = duplicate(CreateBlankUserStruct_LoginDetails()) />	<!--- a struct to keep the login details in --->
	<cfset ret.NameDetails = duplicate(CreateBlankUserStruct_NameDetails()) />	<!--- a struct to keep the login details in --->
	<cfset ret.Roles = duplicate(CreateBlankUserStruct_Roles()) />
	<cfset ret.Security = duplicate(CreateBlankUserStruct_SecurityStatus()) />
	<cfset ret.Roles.CurrentState = "00000000"&"00000000"&"00000000"&"00000000" />
	<cfset ret.StaffDetails = StructNew() />	<!--- this is a safe haven for a staff member's details if they are emulating a user --->
	<cfset ret.StaffDetails.StaffID = "" />
	<cfset ret.StaffDetails.LoginDetails = duplicate(CreateBlankUserStruct_LoginDetails()) />
	<cfset ret.StaffDetails.NameDetails = duplicate(CreateBlankUserStruct_NameDetails()) />
	<cfset ret.StaffDetails.Roles = duplicate(CreateBlankUserStruct_Roles()) />
	<cfreturn ret  />
</cffunction>

<cffunction name="CreateBlankUserStruct_LoginDetails" output="No" returntype="struct" access="private"
	displayname="Create Blank User LoginDetails Struct"
	hint="returns an empty struct of the bits needed to be used in a user's login details"
	>
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with an empty result --->
	<cfset ret.UserID = "" />
	<cfset ret.User_SignIn = "" />
	<cfset ret.User_Password = "" />
	<cfreturn ret  />
</cffunction>

<cffunction name="CreateBlankUserStruct_NameDetails" output="No" returntype="struct" access="private"
	displayname="Create Blank User LoginDetails Struct"
	hint="returns an empty struct of the bits needed to be used in a user's login details"
	>
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<cfset ret.UserID = "" />
	<cfset ret.User_FirstName = "" />
	<cfset ret.User_LastName = "" />
	<cfset ret.User_FullName = "" />
	<cfreturn ret  />
</cffunction>

<cffunction name="CreateBlankUserStruct_Roles" output="No" returntype="struct" access="private"
	displayname="Create Blank User Roles Struct"
	hint="returns an empty struct of the bits needed to be used in a user's role details"
	>
	<cfset var SubSiteIDList_Active = "" />	<!--- this will be a list of active subsites --->
	<cfset var thisSubSite = "" />	<!--- this subsite being processed --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with an empty result --->
	<cfset ret.system = StructNew() />
	<cfset ret.system.Global_RoleBits = "00000000"&"00000000"&"00000000"&"00000000" />
	<cfset ret.system.Global_RoleValue = 0 />
	<cfset ret.site_0 = StructNew() />
	<cfset ret.site_0.Global_RoleBits = "00000000"&"00000000"&"00000000"&"00000000" />
	<cfset ret.site_0.Global_RoleValue = 0 />
	<cfif application.SLCMS.Core.PortalControl.IsPortalAllowed()>
		<cfset SubSiteIDList_Active = application.SLCMS.Core.PortalControl.GetActiveSubSiteIDList() />	<!--- grab subsite list --->
		<cfloop list="#SubSiteIDList_Active#" index="thisSubSite">
			<cfset ret["Site_#thisSubSite#"] = StructNew() />	<!--- new structure for each subsite --->
			<cfset ret["Site_#thisSubSite#"].Global_RoleBits = "00000000"&"00000000"&"00000000"&"00000000" />
			<cfset ret["Site_#thisSubSite#"].Global_RoleValue = 0 />
		</cfloop>
	</cfif>
	
	<cfreturn ret  />
</cffunction>

<cffunction name="CreateBlankUserStruct_SecurityStatus" output="No" returntype="struct" access="private"
	displayname="Create Blank User Roles Struct"
	hint="returns an empty struct of the bits needed to be used in a user's role details"
	>
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with an empty result --->
	<cfset ret.LoggedIn = False />
	<cfset ret.LoginAttempted = False />
	<cfset ret.AttemptedUserName = "" />
	<cfset ret.AttemptedPassword = "" />
	<cfset ret.SessionStartTime = Now() />
	<cfreturn ret  />
</cffunction>

<!---<cffunction name="getRolePatterns" output="No" returntype="struct" access="public"
	displayname="get Role Patternss"
	hint="gets the Role patterns that are used to define who can do what"
	>
	<cfreturn variables.RolePatterns  />
</cffunction>
--->
<cffunction name="getRoles_Staff" output="No" returntype="struct" access="public"
	displayname="get Roles - Staff"
	hint="gets the Roles struct of a staff member, ie its stored in the local variables scope
				returns an empty struct is user not found, ie not a staff body"
	>
	<cfargument name="staffID" type="string" default="" />	
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with role of there is one --->
	<cfif StructKeyExists(variables.StaffRoles, "staff_#arguments.staffID#")>
		<cfset ret = variables.StaffRoles["staff_#arguments.staffID#"] />
	</cfif>
	<cfreturn ret  />
</cffunction>

<cffunction name="getUserDetails_Staff" output="No" returntype="struct" access="public"
	displayname="get User Details - Staff"
	hint="gets the Details struct of a staff member, ie its stored in the local variables scope with username, password, etc., but not the role details
				returns an empty struct is user not found, ie not a staff body"
	>
	<cfargument name="staffID" type="string" default="" />	
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with role of there is one --->
	<cfif StructKeyExists(variables.StaffDetailsByUser, "staff_#arguments.staffID#")>
		<cfset ret = variables.StaffDetailsByUser["staff_#arguments.staffID#"] />
	</cfif>
	<cfreturn ret  />
</cffunction>

<cffunction name="checkNsetUserLogin" output="No" returntype="struct" access="public"
	displayname="check'n'Set User Login"
	hint="checks user login and returns either their user details, roles, etc., or a blank 'I am a guest' set.
				that means that there is no standard error structure returned"
	>
	<!--- this function needs.... --->
	<cfargument name="UserName" type="string" default="" hint="the Sign In Name of the user" />
	<cfargument name="UserPassword" type="string" default="" hint="the related password" />

	<!--- now all of the var declarations, first the arguments which need manipulation --->
	<cfset var theUserName = trim(arguments.UserName) />
	<cfset var theUserPassword = trim(arguments.UserPassword) />
	<!--- now vars that will get filled as we go --->
	<cfset var lcntr = 0 />	<!--- temp loop counter --->
	<cfset var thisResultPassword = "" />	<!--- temp/throwaway var --->
	<cfset var tempa = ArrayNew(1) />	<!--- temp/throwaway array --->
	<cfset var theReturn = StructNew() />	<!--- structure to send back, it is a blank set at the least --->
	<!--- then the standard return structure, not used as such but used to keep error stuff if this code barfs --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the error structure with a clean, empty result. NOTE: this is not the return structure in this case --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorContext = "UserControl CFC: checkNsetUserLogin() " />
	<cfset ret.error.ErrorText = "" />
	<cfset ret.error.ErrorExtra = "" />

	<!--- set up a default set of nothing, the body is a guest --->
	<!--- but don't trash the staffdetails as we might be an emulator testing something --->
	<cfset theReturn.IsStaff = False />	<!--- flag if an staff user --->
	<cfset theReturn.IsSuper = False />	<!--- flag if an staff user --->
	<cfset theReturn.UserID = "" />	<!--- the user's ID --->
	<cfset theReturn.User_FirstName = "" />	<!--- the user's first name --->
	<cfset theReturn.User_LastName = "" />	<!--- the user's last name --->
	<cfset theReturn.User_FullName = "" />	<!--- the user's full name --->
	<cfset theReturn.Roles = CreateBlankUserStruct_Roles() />
	<cfset theReturn.StaffDetails = StructNew() />
		<!--- validation --->
	<cfif theUserName neq "" and theUserPassword neq "">
		<!--- at this version we are just looking for staff members we don't have module users in the system yet --->
		<cftry>
			<cfif hash(theUserName) eq application.SLCMS.Config.base.SuperUser_LogIn and hash(theUserPassword) eq application.SLCMS.Config.base.SuperUser_Password>
				<!--- its the Uber Doober person, make it nice for them --->
				<cfset theReturn.IsStaff = True />	<!--- flag if an staff user --->
				<cfset theReturn.IsSuper = True />	<!--- flag as the SuperUser --->
				<cfset theReturn.UserID = 0 />	<!--- the Uber user's ID is zero --->
				<cfset theReturn.User_FirstName = ListFirst(application.SLCMS.Config.base.SuperUser_UserName, " ") />
				<cfset theReturn.User_LastName = ListLast(application.SLCMS.Config.base.SuperUser_UserName, " ") />
				<cfset theReturn.User_FullName = application.SLCMS.Config.base.SuperUser_UserName />
				<cfset theReturn.StaffDetails.StaffID = theReturn.UserID />
				<cfset theReturn.StaffDetails.IsSuper = True />	<!--- flag as the SuperUser --->
				<cfset theReturn.StaffDetails.User_FirstName = theReturn.User_FirstName />
				<cfset theReturn.StaffDetails.User_LastName = theReturn.User_LastName />
				<cfset theReturn.StaffDetails.User_FullName = theReturn.User_FullName />
				<!---
				<cfset theReturn.StaffDetails.Roles = variables.StaffRoles["staff_#theReturn.UserID#"] />
				--->
			<cfelse>
				<cfset tempa = StructFindValue(variables.StaffDetailsBySite, theUserName) />	<!--- grab any users with this login name --->
				<cfif ArrayLen(tempa) gt 0>
					<cfloop from="1" to="#ArrayLen(tempa)#" index="lcntr">
						<cfset thisResultPassword = tempa[lcntr].owner.Staff_password />
						<cfif thisResultPassword eq theUserPassword>
							<!--- we have a match so load up as a staff member and grab their roles in the system and the various subsites --->
							<cfset theReturn.IsStaff = True />
							<cfset theReturn.UserID = tempa[lcntr].owner.staffID />
							<cfset theReturn.User_FirstName = variables.StaffDetailsByUser["staff_#theReturn.UserID#"].NameDetails.staff_FirstName />
							<cfset theReturn.User_LastName = variables.StaffDetailsByUser["staff_#theReturn.UserID#"].NameDetails.staff_LastName />
							<cfset theReturn.User_FullName = variables.StaffDetailsByUser["staff_#theReturn.UserID#"].NameDetails.staff_FullName />
							<cfset theReturn.Roles = variables.StaffRoles["staff_#theReturn.UserID#"] />
							<cfif theReturn.Roles.system.Global_RoleBits eq variables.RolePatterns.SuperUser.bits>
								<cfset theReturn.IsSuper = True />	<!--- flag as a SuperUser --->
								<cfset theReturn.StaffDetails.IsSuper = True />
							<cfelse>
								<cfset theReturn.StaffDetails.IsSuper = False />
							</cfif>
							<cfset theReturn.StaffDetails.StaffID = theReturn.UserID />
							<cfset theReturn.StaffDetails.User_FirstName = theReturn.User_FirstName />
							<cfset theReturn.StaffDetails.User_LastName = theReturn.User_LastName />
							<cfset theReturn.StaffDetails.User_FullName = theReturn.User_FullName />
							<cfset theReturn.StaffDetails.Roles = variables.StaffRoles["staff_#theReturn.UserID#"] />
							<cfbreak>
						</cfif>
					</cfloop>
				<cfelse>
					<!--- nothing there so we had a miss to just return with the blank structure --->
				</cfif>
			</cfif>

<!--- 			
<cfoutput>userControl CFC: checkNsetUserLogin(): <br>request:<br></cfoutput>
<cfdump var="#request#" expand="false">
<cfoutput>session:<br></cfoutput>
<cfdump var="#session#" expand="false">
<cfoutput>search result:<br></cfoutput>
<cfdump var="#tempa#" expand="false">

<cfabort>
 --->
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
	<cfelse>
		<!--- no user name or password, can't be real so return a blank --->
	</cfif>

	<!--- return our data structure --->
	<cfreturn theReturn  />
</cffunction>

<cffunction name="LogIt" output="No" returntype="struct" access="Private"
	displayname="Log It"
	hint="Local Function to log info to standard log space via application.SLCMS.Core.SLCMS_Utility.WriteLog_Core(), minimizes log code in individual functions"
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
	<cfset ret.error.ErrorContext = "UserControl CFC: LogIt()" />
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
