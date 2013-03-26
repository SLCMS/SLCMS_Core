<!--- this is the code that handles logins as part of OnRequestStart --->

<cfsetting enablecfoutputonly="No">
<!---
<cfsilent>
--->	

  	<!--- now the login handler --->
	<!--- check to see if the login pod/page has been filled in --->
	<cfif IsDefined("form.aFiled")>
		<cfset this.variables.SLCMS.Temp.SignInFormField = form.aFiled />
		<cfset this.variables.SLCMS.Temp.StaffSignInAttempt = True />
	<cfelseif IsDefined("form.SignInAttempt_GeneralUser")>
		<cfset this.variables.SLCMS.Temp.SignInFormField = form.SignInAttempt_GeneralUser />
		<cfset this.variables.SLCMS.Temp.StaffSignInAttempt = False />
	<cfelseif IsDefined("form.SignInAttempt_StaffUser")>
		<cfset this.variables.SLCMS.Temp.SignInFormField = form.SignInAttempt_StaffUser />
		<cfset this.variables.SLCMS.Temp.StaffSignInAttempt = True />
	<cfelse>
		<cfset this.variables.SLCMS.Temp.SignInFormField = "" />
		<cfset this.variables.SLCMS.Temp.StaffSignInAttempt = False />
	</cfif>
	<cfif this.variables.SLCMS.Temp.SignInFormField neq "">	
		<!--- a bit of an audit trail --->
		<cfset this.variables.SLCMS.Initialization.LoginHandler = StructNew() />
		<cfif IsDefined("form.username")>
			<cfset this.variables.SLCMS.Initialization.LoginHandler.user = form.username />
		<cfelseif IsDefined("form.SignIn_Username")>
			<cfset this.variables.SLCMS.Initialization.LoginHandler.user = form.SignIn_Username />
		<cfelse>
			<cfset this.variables.SLCMS.Initialization.LoginHandler.user = session.SLCMS.user.NameDetails.User_FullName />
		</cfif>
		<cfif IsDefined("form.txtPassword")>
			<cfset this.variables.SLCMS.Initialization.LoginHandler.Password = form.txtPassword />
		<cfelseif IsDefined("form.SignIn_Password")>
			<cfset this.variables.SLCMS.Initialization.LoginHandler.Password = form.SignIn_Password />
		<cfelse>
			<cfset this.variables.SLCMS.Initialization.LoginHandler.Password = "" />
		</cfif>
		<cfset this.variables.SLCMS.Initialization.LoginHandler.EntryTime = Now() />
		<cfset this.variables.SLCMS.Initialization.LoginHandler.Role = 0 />
		<cfset session.SLCMS.security.LoginAttempted = False  />
		<cfif form.aFiled eq "LoggingIn">
			<!--- it has so set up the session for this user --->
			<cfset session.SLCMS.user.IsLoggedIn = False />
			<cfset session.SLCMS.user.security.LoggedIn = False />
			<cfset session.SLCMS.user.security.LoginAttempted = True />
			<cfset session.SLCMS.user.security.AttemptedUserName = this.variables.SLCMS.Initialization.LoginHandler.user />
			<cfset session.SLCMS.user.security.AttemptedPassword = this.variables.SLCMS.Initialization.LoginHandler.Password />
			<!--- see if this user has a login --->
			<cfset RetCheckUserLogin = application.SLCMS.Core.UserControl.checkNsetUserLogin(UserName="#this.variables.SLCMS.Initialization.LoginHandler.user#", UserPassword="#this.variables.SLCMS.Initialization.LoginHandler.Password#")> <!--- returns the user's details if there is one --->
			<cfset session.SLCMS.user.UserID = RetCheckUserLogin.UserID />
			<cfset session.SLCMS.user.LoginDetails.UserID = RetCheckUserLogin.UserID />
			<cfset session.SLCMS.user.LoginDetails.User_Login = this.variables.SLCMS.Initialization.LoginHandler.user />
			<cfset session.SLCMS.user.LoginDetails.User_Password = this.variables.SLCMS.Initialization.LoginHandler.Password />
			<cfif RetCheckUserLogin.UserID neq "">
				<!--- we've got a user so lets load up our user session --->
				<cfset session.SLCMS.user.IsLoggedIn = True />
				<cfset session.SLCMS.user.security.LoggedIn = True />
				<cfset session.SLCMS.user.IsStaff = RetCheckUserLogin.IsStaff />
				<cfset session.SLCMS.user.IsSuper = RetCheckUserLogin.IsSuper />
				<cfset session.SLCMS.user.LoginDetails.UserID = RetCheckUserLogin.UserID />
				<cfset session.SLCMS.user.NameDetails.UserID = RetCheckUserLogin.UserID />
				<cfset session.SLCMS.user.NameDetails.User_FirstName = RetCheckUserLogin.User_FirstName />	<!--- full name as per user database(s) --->
				<cfset session.SLCMS.user.NameDetails.User_LastName = RetCheckUserLogin.User_LastName />	<!--- full name as per user database(s) --->
				<cfset session.SLCMS.user.NameDetails.User_FullName = RetCheckUserLogin.User_FullName />	<!--- full name as per user database(s) --->
				<cfset session.SLCMS.user.Roles = RetCheckUserLogin.Roles />	<!--- load up the roles struct with what they can do --->
				<cfif not session.SLCMS.user.IsEmulatingUser>
					<cfset session.SLCMS.user.StaffDetails = Duplicate(RetCheckUserLogin.StaffDetails) />	<!--- can be various things in here so just copy --->
				</cfif>
			<cfset session.SLCMS.Currents.Admin.PageStructure.CurrentSubSiteID = ListFirst(application.SLCMS.Core.PortalControl.GetAllowedSubSiteIDList_AllSites(UserID="#session.SLCMS.user.UserID#")) />
				<!--- in some contexts we could have a staff member that has accesss turned off to all sites so check for a null here --->
				<cfif session.SLCMS.Currents.Admin.PageStructure.CurrentSubSiteID neq "">
					<cfset session.SLCMS.Currents.Admin.PageStructure.CurrentSubSiteFriendlyName = application.SLCMS.Core.PortalControl.GetSubSite(session.SLCMS.Currents.Admin.PageStructure.CurrentSubSiteID).data.SubSiteFriendlyName />
				</cfif>
				<cfset session.SLCMS.Currents.Admin.PageStructure.FlushExpansionFlags = True />
				<!--- 
				<cfset session.SLCMS.Currents.Admin.PageStructure.CurrentSubSiteID = ListFirst(application.SLCMS.Core.PortalControl.GetAllowedSubSiteIDList_AllSites(UserID="#session.SLCMS.user.UserID#")) />
				<cfset session.SLCMS.Currents.Admin.PageStructure.CurrentSubSiteFriendlyName = application.SLCMS.Core.PortalControl.GetSubSite(session.SLCMS.Currents.Admin.PageStructure.CurrentSubSiteID).data.SubSiteFriendlyName />
				 --->
				<cfset session.SLCMS.Currents.Admin.Templates.CurrentSubSiteID = session.SLCMS.Currents.Admin.PageStructure.CurrentSubSiteID  />
				<cfset session.SLCMS.Currents.Admin.Templates.CurrentSubSiteFriendlyName = session.SLCMS.Currents.Admin.PageStructure.CurrentSubSiteFriendlyName />
				<cfset session.SLCMS.Currents.Admin.Templates.FlushExpansionFlags = True />
			<cfelse>
				<cfset session.SLCMS.user.IsStaff = False />
				<cfset session.SLCMS.user.IsSuper = False />
			</cfif>
			<!--- now a bit of audit trail --->
			<cfif session.SLCMS.user.UserID eq "">
				<cfset this.variables.SLCMS.Initialization.LoginHandler.Role = "0" />
				<cfset this.variables.SLCMS.Initialization.LoginHandler.Direction = "Login Failed" />
			<cfelseif session.SLCMS.user.IsSuper>
				<cfset this.variables.SLCMS.Initialization.LoginHandler.Direction = "Supervisor Logged In" />
				<cfset session.SLCMS.user.security.LoginAttempted = False />
				<cfset session.SLCMS.user.security.AttemptedUserName = "" />
				<cfset session.SLCMS.user.security.AttemptedPassword = "" />
			<cfelseif session.SLCMS.user.UserID neq "" and session.SLCMS.user.IsStaff>
				<cfset this.variables.SLCMS.Initialization.LoginHandler.Direction = "Staff Logged In" />
				<cfset session.SLCMS.user.security.LoginAttempted = False />
				<cfset session.SLCMS.user.security.AttemptedUserName = "" />
				<cfset session.SLCMS.user.security.AttemptedPassword = "" />
			</cfif>
			<cfset this.variables.SLCMS.Initialization.LoginHandler.Role = "Staff, #YesNoFormat(RetCheckUserLogin.IsStaff)#" />
			
		<cfelseif form.aFiled eq "LoggingOut">
			<cfset this.variables.SLCMS.Initialization.LoginHandler.Direction = "Logging Out" />
			<cfset session.SLCMS.user = duplicate(application.SLCMS.Core.UserControl.CreateBlankUserStruct_Session())  />
			<cfset session.pageAdmin = Structnew()/>	<!--- dump all backend stuff so fresh on next login --->
		</cfif>	<!--- end: type of login in or out --->
		<!--- write the audit trail to datastore --->
		<!--- this is a text file for the moment, V2.n will use the abstract datastore --->
		<cfset this.variables.SLCMS.Initialization.LoginHandler.LogTextString = '#DateFormat(this.variables.SLCMS.Initialization.LoginHandler.EntryTime, "YYYYMMDD")# #TimeFormat(this.variables.SLCMS.Initialization.LoginHandler.EntryTime, "HH:MM:SS")#' />
		<cfif not session.SLCMS.user.IsSuper>
			<cfset this.variables.SLCMS.Initialization.LoginHandler.LogTextString = this.variables.SLCMS.Initialization.LoginHandler.LogTextString &  ' User: "#this.variables.SLCMS.Initialization.LoginHandler.user#" - Password: "#this.variables.SLCMS.Initialization.LoginHandler.password#"' />
		<cfelse>
			<cfset this.variables.SLCMS.Initialization.LoginHandler.LogTextString = this.variables.SLCMS.Initialization.LoginHandler.LogTextString &  ' User: SuperUser ' />
		</cfif>
		<cfset this.variables.SLCMS.Initialization.LoginHandler.LogTextString = this.variables.SLCMS.Initialization.LoginHandler.LogTextString & ' Roles: "#this.variables.SLCMS.Initialization.LoginHandler.Role#" - Activity: "#this.variables.SLCMS.Initialization.LoginHandler.Direction#"' />
		<cfset this.variables.SLCMS.Initialization.LoginHandler.LogTextString = this.variables.SLCMS.Initialization.LoginHandler.LogTextString & ' - Browser IP Address: "#cgi.REMOTE_ADDR#"' />
		<cfset temps = application.SLCMS.Core.SLCMS_Utility.WriteLog_Core(LogType="Audit_Signin", LogString="#this.variables.SLCMS.Initialization.LoginHandler.LogTextString#") />
	</cfif>	<!--- end: do we have a login form field --->
