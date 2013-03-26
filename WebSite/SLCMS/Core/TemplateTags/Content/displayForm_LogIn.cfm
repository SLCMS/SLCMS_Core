<cfsetting enablecfoutputonly="Yes">

<!--- THIS TAG IS DEPRECATED - IT IS FOR LEGACY, PRE v2.2, INSTALLaTIONS THAT HAVE THIS TAG IN THEIR TEMPLATES --->

<!--- SLCMS base tags to be used in template pages  --->
<!---  --->
<!--- custom tag to display the login/logout form --->
<!--- &copy; mort bay communications --->
<!---  --->
<!--- created:  15th Dec 2006 by Kym K --->
<!--- modified: 15th Dec 2006 - 15th Dec 2006 by Kym K, mbcomms: did initial stuff --->
<!--- Modified:  8th Feb 2007 -  8th Feb 2007 by Kym K, mbcomms: added "Author" role for edit content only, no backend at all --->
<!--- modified: 12th Jun 2007 - 12th Jun 2007 by Kym K, mbcomms: made styling and related attributes consistent across all form template tags --->
<!--- modified:  6th Jun 2008 -  6th Jun 2008 by Kym K, mbcomms: made styling and related attributes consistent across all form template tags --->
<!--- modified: 23rd Mar 2009 - 23rd Mar 2009 by Kym K, mbcomms: V2.2, changing structures to new module-allowing architecture, the core code is now just another module --->
<!--- modified: 30th Aug 2009 -  1st Sep 2009 by Kym K, mbcomms: V2.2+, modifying code for session roles, ie the permissions engine --->
<cfif thisTag.executionMode IS "start">
	<cfparam name="attributes.formname" type="string" default="login">
	<cfparam name="attributes.ShowFormTag" type="string" default="Yes">
	<cfparam name="attributes.formaction" type="string" default="">
	<cfparam name="attributes.formclass" type="string" default="loginform">
	<cfparam name="attributes.legendtext" type="string" default="&nbsp;">
	<cfparam name="attributes.ShowGoToAdmin" type="string" default="Yes">
	<cfparam name="attributes.UserName" type="string" default="">
	<cfparam name="attributes.Password" type="string" default="">
	<cfparam name="attributes.LoginFailedMsg" type="string" default="Login failed. Please check your Username and Password.">
	<cfparam name="attributes.class_fieldset" type="string" default="loginFldSet">
	<cfparam name="attributes.class_inputfield" type="string" default="txt">
	<cfparam name="attributes.class_button" type="string" default="btn">
	<cfparam name="attributes.class_LoggedInMsg" type="string" default="LoggedInMsg">
	<cfparam name="attributes.class_LoginFailedMsg" type="string" default="LoginFailedMsg">

	<cfset tempdata.theFormAction = trim(attributes.formaction) />
	<cfif application.slcms.core.UserPermissions.IsLoggedin() eq False and session.slcms.user.security.LoginAttempted>
		<cfset tempdata.theUserName = session.slcms.user.security.AttemptedUserName />
		<cfset tempdata.thePassword = session.slcms.user.security.AttemptedPassword />
	<cfelse>
		<cfset tempdata.theUserName = trim(attributes.UserName) />
		<cfset tempdata.thePassword = trim(attributes.Password) />
	</cfif>

	<cfset tempdata.theFromPlace = "" />

	<!--- work out where we have to submit our form to
				normal logins would submit back to the page that the login link was clicked from --->
	<cfif tempdata.theFormAction eq "" and ListFirst(request.slcms.PageParams.PageQueryString, "=") eq "from">
		<cfset tempdata.theFromPlace =  ListLast(request.slcms.PageParams.PageQueryString, "=")>
		<cfif application.slcms.Core.PageStructure.getDocIDfromURL(URLpath="#tempdata.theFromPlace#", SubSiteID="#request.slcms.PageParams.SubSiteID#").DocID neq 0>
			<cfset tempdata.theFormAction = "/content.cfm#tempdata.theFromPlace#" />
		<cfelse>
			<cfset tempdata.theFormAction = "/content.cfm" />
		</cfif>
	</cfif>
	<cfoutput>
	<cfif attributes.ShowFormTag eq "Yes">
		<form<cfif len(attributes.FormName)> name="#attributes.FormName#"</cfif> action="#tempdata.theFormAction#" method="post"<cfif len(attributes.formclass)> class="#attributes.formclass#"</cfif>>
	</cfif>
	<fieldset class="#attributes.class_fieldset#">
	<legend>#attributes.legendtext#</legend>
	<cfif application.slcms.core.UserPermissions.IsLoggedin() eq False>
		<cfif session.slcms.user.security.LoginAttempted>
			<p class="#attributes.class_LoginFailedMsg#">#attributes.LoginFailedMsg#</p>
		</cfif>
		<label for="username">Username
		<input type="text" class="#attributes.class_inputfield#" id="username" name="username" title="your username" value="#tempdata.theUserName#">
		</label>
		<label for="txtPassword">Password
		<input type="password" class="#attributes.class_inputfield#" id="txtPassword" name="txtPassword" title="your password" value="#tempdata.thePassword#">
		</label>
		<input type="hidden" name="aFiled" value="LoggingIn">
		<input type="submit" value="Log In" title="Log in to site" class="#attributes.class_button#">
	<cfelse>
		<p class="#attributes.class_LoggedInMsg#">You are logged in as: #session.slcms.user.NameDetails.User_FullName#</p>
		<cfif attributes.ShowGoToAdmin eq "yes" and session.slcms.user.IsStaff>
			<p class="#attributes.class_LoggedInMsg#"><a href="#request.slcms.RootURL#Admin/AdminHome.cfm" target="_blank">Go to Administration Area (in new tab/window)</a></p>
		</cfif>
		<input type="hidden" name="aFiled" value="LoggingOut">
		<input type="submit" value="Log Out" title="Log out from site" class="#attributes.class_button#">
	</cfif>
	</fieldset>
	<cfif attributes.ShowFormTag eq "Yes">
		</form>
	</cfif>
	</cfoutput> 
 
</cfif>
<cfif thisTag.executionMode IS "end">

</cfif>
<cfsetting enablecfoutputonly="No">

