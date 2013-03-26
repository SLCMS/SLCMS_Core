<!--- SLCMS --->
<!---  --->
<!--- A Simple Light CMS system by Mort Bay Communications Pty Ltd --->
<!--- Copyright 2002-2011 --->
<!---  --->
<!--- include file --->
<!--- this page is included into content.cfm
			It shows a workflow to get started when there is no content in the site and no admin users --->
<!---  --->
<!--- Created   24th Sep 2009 by Kym Kovan - mbcomms --->
<!--- modified: 24th Sep 2009 - 27th Sep 2009 by Kym K - mbcomms: initial work on it --->
<!--- modified:  6th Aug 2011 - 12th Aug 2011 by Kym K - mbcomms: 2nd burst as we now have an Installation Wizard, thius should only get called in emergencies --->


<!--- we have ended up here and that normally means that content.cfm has included it as the site is empty, 
			or initial install with no Superuser and this page will create one
			but a hacker could call it directly so lets run some tests and hop out if we are not empty --->

<!--- if we have a correct entry to this page we have set the session.user.security.NewInstallation flag to True --->
<cfparam name="session.SLCMS.user.security.NewInstallation" default="False">	<!--- this will create it and force it off if that flag was not set --->
<cfparam name="errmsg" default="">	<!--- this will be an error message of the save user fails --->
<cfset WizTipsURL = "#application.SLCMS.Paths_Common.HelpTipsPath_Abs#EmptySiteFoundWizard/" />
<cfset HelpGraphicURL = "#application.SLCMS.Paths_Common.HelpTipGraphics_Abs#help.png" />

<cfquery name="getUser" datasource="#application.SLCMS.config.datasources.CMS#">
	SELECT	StaffID
		FROM	#application.SLCMS.config.DatabaseDetails.TableName_SystemAdminDetailsTable#
</cfquery>
<cfquery name="getPages" datasource="#application.SLCMS.config.datasources.CMS#">
	select DocID from	#application.SLCMS.config.DatabaseDetails.TableName_Site_0_PageStruct#
</cfquery>
<cfif getUser.RecordCount and getPages.Recordcount>
	<!--- oops we have a set up site in there so tell 'em to nik off --->
	<html>
	<head>
		<title><cfoutput>#application.SLCMS.config.base.SiteName#</cfoutput> site administration</title>
		<cfoutput><link href="#application.SLCMS.config.Base.rootURL#Global/slcms.css" rel="STYLESHEET" type="text/css"></cfoutput>
	</head>
	<body>
	<p>There is stuff in this site and we have admin users so how did you get here? I suspect you are a hacker so go away!</p>
	</body></head></html>
	<cfabort>
</cfif>

<cfif getUser.RecordCount eq 0>
	<!--- we don't have a superuser yet so lets make one --->
	<!--- force that we are logged in and go to the "Create Admin User" page --->
	<cfset session.SLCMS.user.security.LoggedIn = True />
	<cfset session.SLCMS.user.security.LoginAttempted = True />
	<cfset session.SLCMS.user.security.thisPageSecurityID = CreateUUID()>
	<cfset session.SLCMS.user.UserID = 0 />
	<cfset session.SLCMS.user.IsStaff = True />
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head><cfoutput>
	<title>#application.SLCMS.config.base.SiteName# Site Startup</title>
	<!--- 
	<link href="#application.SLCMS.Paths_Admin.StylingRootPath_Abs#slcms_backend.css" rel="STYLESHEET" type="text/css">
	 --->
	<link href="#application.SLCMS.Paths_Common.SLCMSfolder_Abs#installAssist/InitialInstallationWizard.css" rel="STYLESHEET" type="text/css">
	<script src='#application.SLCMS.Paths_Common.jQueryJsPath_Abs#' type='text/javascript'></script>
	<script src="#application.SLCMS.Paths_Common.HelpJs_Abs#" type="text/javascript"></script>
	<script type="text/javascript">
		$(document).ready(function() {
			var AJAXurl = '#application.SLCMS.Paths_Common.SLCMSfolder_Abs#installAssist/ClientComms.cfm?format=html';</cfoutput>
			// Help tips plugin
			JT_init();
			// handlers
			$('#LastName').blur(function(){
				var theFirstName = $('#FirstName').val();
				var theLastName = $('#LastName').val();
				var theSignIn = $('#SignIn_Empty').val();
				if (theSignIn == '') {
					$.ajax({
						type:'GET',
						url: AJAXurl,
						data: {Job: 'MakeSignInWord', FirstName: theFirstName, LastName: theLastName},
						success: function(data){
							var theSignIn = $.trim(data)
							$('#SignIn_Empty').val(theSignIn);
						}
					});
				}
			});
			$('#Password_2').blur(function(){
				var thePassword_2 = $('#Password_2_Empty').val();
				if (thePassword_2 == '') {
					alert('Password Cannot Be Blank!');
					return false;
				}
				CheckPassWord();
			});
			$('#CreateSuperUserButton').click(function(){
				return CheckPassWord();
			});
			function CheckPassWord() {
				var thePassword_1 = $('#Password_1_Empty').val();
				var thePassword_2 = $('#Password_2_Empty').val();
				if (thePassword_1 != thePassword_2) {
					alert('Passwords Do Not Match!');
					return false;
				}
				return true;
			}
		});
	</script>
</head><cfoutput>
<body class="body">
	<form name="EmptySiteWizForm" action="#application.SLCMS.Paths_Admin.AdminBaseURL#Admin-SuperUsers.cfm?mode=SaveAddUser" method="post">
		<input type="hidden" name="SourcePage" value="FromEmptySiteWorkflow">
		<input type="hidden" name="SecID" value="#session.SLCMS.user.security.thisPageSecurityID#">
		<div  style="padding-top:0px;">
			<img src="#application.SLCMS.Paths_Common.HelpTipGraphics_Abs#slcmsLogo1.gif" alt="SLCMS Logo and Link" border="0" style="float:left;">
			<div class="WarnHeading" style="margin-left:210px;width:450px;">
				<p>Empty Website found, named: <span class="AdminHeadingSiteName">#application.SLCMS.config.base.SiteName#</span></p>
				<p>It also has no Administrators at all including the SuperUser.</p>
			</div>
		</div>
		<div>Error: #ErrMsg#</div>
		<fieldset class="EmptySiteParas">
			<legend class="legend">Create a SuperUser</legend>
			<p>That means a user that has overall Supervisory control over everything.</p>
			<p>Once created this user can create and manage regular administrators and other staff members for the whole site or parts of it.</p>
			<p>
				Fill out the form below and submit it with the &quot;Create SuperUser&quot; button. 
				The SuperUser will be created and you will be taken to the Administration Login page where you can sign in as that SuperUser.
				You can then administer the site, create staff members if you wish and create a home page for the site.
				Once a home page is created you will be able to access the site normally and you will not see this page again..
			</p>
			<dl>
				<dt class="labelCol labelColEmptySite"><label for="FirstName">First Name: </label></dt>
				<dd class="inputCol inputColEmptySite">
					<input type="text" class="inputField" name="FirstName" value="" id="FirstName" tabindex="1" maxlength="64">
					<a href="#WizTipsURL#Help_FirstName.html?width=350" class="helpTip" id="h1" name="
						This is the first name of the SuperUser.
					" tabindex="10"><img src="#HelpGraphicURL#" width="16" height="16" border="0" alt="help popup button" class="helpPopupButton"></a>
				</dd>
				<dt class="labelCol labelColEmptySite"><label for="LastName">Last Name: </label></dt>
				<dd class="inputCol inputColEmptySite">
					<input type="text" class="inputField" name="LastName" value="" id="LastName" tabindex="2" maxlength="64">
					<a href="#WizTipsURL#Help_LastName.html?width=350" class="helpTip" id="h2" name="
						This is the last name of the SuperUser.
					" tabindex="11"><img src="#HelpGraphicURL#" width="16" height="16" border="0" alt="help popup button" class="helpPopupButton"></a>
				</dd>
				<dt class="labelCol labelColEmptySite"><label for="SignIn_Empty">Sign In Name: </label></dt>
				<dd class="inputCol inputColEmptySite">
					<input type="text" class="inputField" name="SignIn_Empty" value="" id="SignIn_Empty" tabindex="3" maxlength="64">
					<a href="#WizTipsURL#Help_SignInName.html?width=350" class="helpTip" id="h3" name="
						This is the word used to sign in to the website.
					" tabindex="12"><img src="#HelpGraphicURL#" width="16" height="16" border="0" alt="help popup button" class="helpPopupButton"></a>
				</dd>
				<dt class="labelCol labelColEmptySite"><label for="Password_1_Empty">Password: </label></dt>
				<dd class="inputCol inputColEmptySite">
					<input type="Password" class="inputField" name="Password_Empty" value="" id="Password_1_Empty" tabindex="4" maxlength="64">
					<a href="#WizTipsURL#Help_Password.html?width=350" class="helpTip" id="h4" name="
						This is the password.
					" tabindex="13"><img src="#HelpGraphicURL#" width="16" height="16" border="0" alt="help popup button" class="helpPopupButton"></a>
				</dd>
				<dt class="labelCol labelColEmptySite"><label for="Password_2_Empty">Password again: </label></dt>
				<dd class="inputCol inputColEmptySite">
					<input type="Password" class="inputField" name="Password_2_Empty" value="" id="Password_2_Empty" tabindex="5" maxlength="64">
					<a href="#WizTipsURL#Help_PasswordVerify.html?width=350" class="helpTip" id="h5" name="
						Verify the password.
					" tabindex="14"><img src="#HelpGraphicURL#" width="16" height="16" border="0" alt="help popup button" class="helpPopupButton"></a>
				</dd>
				<dt class="labelCol labelColEmptySite"><label for="Eddress">Email Address: </label></dt>
				<dd class="inputCol inputColEmptySite">
					<input type="text" class="inputField" name="Eddress" value="" id="Eddress" tabindex="6" maxlength="255">
					<a href="#WizTipsURL#Help_Eddress.html?width=350" class="helpTip" id="h6" name="
						This is the email address of the SuperUser.
					" tabindex="14"><img src="#HelpGraphicURL#" width="16" height="16" border="0" alt="help popup button" class="helpPopupButton"></a>
				</dd>
			</dl>
			<div id="SubmitWrapper">
				<input type="submit" id="CreateSuperUserButton" class="FormButton" name="Forward1Step" value="Create SuperUser" tabindex="9">
				<p id="GoToNextStepText">
					
				</p>
			</div>
		</fieldset>
	</form>
</body>
</html></cfoutput>
<cfabort>
</cfif>

<cfif getUser.RecordCount gt 0 and getPages.Recordcount eq 0>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head><cfoutput>
	<title>#application.SLCMS.config.base.SiteName# Site Startup</title>
	<link href="#application.SLCMS.config.Base.rootURL#Admin/slcms_backend.css" rel="STYLESHEET" type="text/css">
</head>
<body class="body">
	<img src="#application.SLCMS.config.Base.rootURL#Admin/graphics/slcmsLogo1.gif" alt="SLCMS Logo and Link" border="0"></cfoutput>
<p>
	There is nothing in the site yet. Go to Admin area first, login as an Admin User and then create a Home Page.
</p>
<p>
	<a href="#application.SLCMS.Paths_Admin.AdminBaseURL#admin-home">Go to the Administration Area</a>
</p>
</body></head></html>
</cfif>
