<cfoutput>#includePartial("InstallWiz_PageTop")#
	<cfset theRootURL = "/" />
	<cfset theMainData = application.SLCMS.config.startup.initialization.installationTemp['MainFlow'].Steps['Step_1'].data />
	<cfset thisStepData = application.SLCMS.config.startup.initialization.installationTemp['MainFlow'].Steps['Step_5'].data />
	<cfset lastStepErrors = application.SLCMS.config.startup.initialization.installationTemp["MainFlow"].Steps["Step_2"].error />
	<script type="text/javascript">
		$(document).ready(function() {
			var AJAXurl = '#variables.Paths.AJAXURL#';
			// Help tips plugin
			JT_init();
			// handlers
			$('##LastName').blur(function(){
				var theFirstName = $('##FirstName').val();
				var theLastName = $('##LastName').val();
				var theSignIn = $('##SignIn').val();
				if (theSignIn == '') {
					$.ajax({
						type:'GET',
						url: AJAXurl,
						data: {Job: 'MakeSignInWord', FirstName: theFirstName, LastName: theLastName},
						success: function(data){
							var theSignIn = $.trim(data)
							$('##SignIn').val(theSignIn);
						}
					});
				}
			});
			$('##Password_2').blur(function(){
				var thePassword_2 = $('##Password_2').val();
				if (thePassword_2 == '') {
					alert('Password Cannot Be Blank!');
					return false;
				}
				CheckPassWord();
			});
			$('##CreateSuperUserButton').click(function(){
				return CheckPassWord();
			});
			function CheckPassWord() {
				var thePassword_1 = $('##Password_1').val();
				var thePassword_2 = $('##Password_2').val();
				if (thePassword_1 != thePassword_2) {
					alert('Passwords Do Not Match!');
					return false;
				}
				return true;
			}
		});
	</script>
	<div id="WizHeading">Initialization, Stage 3 of 3 - SuperUser Settings Entry</div>
	<form id="SupUserForm" action="#application.SLCMS.Paths_Admin.AdminBaseURL#install-wizard" method="get">
		<input type="hidden" name="StepCount" value="Step_5">
		<input type="hidden" name="StepWork" value="Process">
		<fieldset class="fieldSet">
			<legend class="legend">SuperUser Creation</legend>
			<dl>
				<dt class="labelCol labelColEmptySite"><label for="FirstName">First Name: </label></dt>
				<dd class="inputCol inputColEmptySite">
					<input type="text" class="inputField" name="FirstName" value="" id="FirstName" tabindex="1" maxlength="64">
					<a href="#variables.Paths.WizTipsPath#Help_FirstName.html?width=350" class="helpTip" id="h1" name="
						This is the first name of the SuperUser.
					" tabindex="10"><img src="#variables.Paths.HelpGraphicsPath#help.png" width="16" height="16" border="0" alt="help popup button" class="helpPopupButton"></a>
				</dd>
				<dt class="labelCol labelColEmptySite"><label for="LastName">Last Name: </label></dt>
				<dd class="inputCol inputColEmptySite">
					<input type="text" class="inputField" name="LastName" value="" id="LastName" tabindex="2" maxlength="64">
					<a href="#variables.Paths.WizTipsPath#Help_LastName.html?width=350" class="helpTip" id="h2" name="
						This is the last name of the SuperUser.
					" tabindex="11"><img src="#variables.Paths.HelpGraphicsPath#help.png" width="16" height="16" border="0" alt="help popup button" class="helpPopupButton"></a>
				</dd>
				<dt class="labelCol labelColEmptySite"><label for="SignIn">Sign In Name: </label></dt>
				<dd class="inputCol inputColEmptySite">
					<input type="text" class="inputField" name="SignIn" value="" id="SignIn" tabindex="3" maxlength="64">
					<a href="#variables.Paths.WizTipsPath#Help_SignInName.html?width=350" class="helpTip" id="h3" name="
						This is the word used to sign in to the website.
					" tabindex="12"><img src="#variables.Paths.HelpGraphicsPath#help.png" width="16" height="16" border="0" alt="help popup button" class="helpPopupButton"></a>
				</dd>
				<dt class="labelCol labelColEmptySite"><label for="Password_1">Password: </label></dt>
				<dd class="inputCol inputColEmptySite">
					<input type="Password" class="inputField" name="Password" value="" id="Password_1" tabindex="4" maxlength="64">
					<a href="#variables.Paths.WizTipsPath#Help_Password.html?width=350" class="helpTip" id="h4" name="
						This is the password.
					" tabindex="13"><img src="#variables.Paths.HelpGraphicsPath#help.png" width="16" height="16" border="0" alt="help popup button" class="helpPopupButton"></a>
				</dd>
				<dt class="labelCol labelColEmptySite"><label for="Password_2">Password again: </label></dt>
				<dd class="inputCol inputColEmptySite">
					<input type="Password" class="inputField" name="Password_2" value="" id="Password_2" tabindex="5" maxlength="64">
					<a href="#variables.Paths.WizTipsPath#Help_PasswordVerify.html?width=350" class="helpTip" id="h5" name="
						Verify the password.
					" tabindex="14"><img src="#variables.Paths.HelpGraphicsPath#help.png" width="16" height="16" border="0" alt="help popup button" class="helpPopupButton"></a>
				</dd>
				<dt class="labelCol labelColEmptySite"><label for="Eddress">Email Address: </label></dt>
				<dd class="inputCol inputColEmptySite">
					<input type="text" class="inputField" name="Eddress" value="" id="Eddress" tabindex="6" maxlength="255">
					<a href="#variables.Paths.WizTipsPath#Help_Eddress.html?width=350" class="helpTip" id="h6" name="
						This is the email address of the SuperUser.
					" tabindex="14"><img src="#variables.Paths.HelpGraphicsPath#help.png" width="16" height="16" border="0" alt="help popup button" class="helpPopupButton"></a>
				</dd>
			</dl>
			<!---
			<dl>
				<dt class="labelCol"><label for="addr1">First Name: </label></dt>
				<dd class="inputCol">
					<input type="text" class="inputField" name="FirstName" value="#thisStepData.FirstName.Data#" id="SiteName">
					<a href="#variables.Paths.theRootURL#Global/Help/Tips/InitialInstallationWizard/Help_SiteName.html?width=350" class="helpTip" id="h1" name="
						This is the name of the website.
					"><img src="#variables.Paths.HelpGraphicsPath#help.png" width="16" height="16" border="0" alt="help popup button" class="helpPopupButton"></a>
				</dd>
				<dt class="labelCol"><label for="addr2">Last Name: </label></dt>
				<dd class="inputCol">
					<input type="text" class="inputField" name="LastName" value="#thisStepData.LastName.Data#" id="SiteAbbreviatedName">
					<a href="#variables.Paths.theRootURL#Global/Help/Tips/InitialInstallationWizard/Help_AbbrvName.html?width=350" class="helpTip" id="h2" name="
						This is the abbreviated name of the website.
					"><img src="#variables.Paths.HelpGraphicsPath#help.png" width="16" height="16" border="0" alt="help popup button" class="helpPopupButton"></a>
				</dd>
				<dt class="labelCol"><label for="suburb">Sign In Name: </label></dt>
				<dd class="inputCol">
					<input type="text" class="inputField" name="BaseDomainName" value="#theData.BaseDomainName.Data#">
					<a href="#variables.Paths.theRootURL#Global/Help/Tips/InitialInstallationWizard/Help_DomainName.html?width=350" class="helpTip" id="h3" name="
						This is the domain name of the website.
					"><img src="#variables.Paths.HelpGraphicsPath#help.png" width="16" height="16" border="0" alt="help popup button" class="helpPopupButton"></a>
				</dd>
				<dt class="labelCol"><label for="suburb">Password: </label></dt>
				<dd class="inputCol">
					<input type="text" class="inputField" name="BaseDomainName" value="#theData.BaseDomainName.Data#">
					<a href="#variables.Paths.theRootURL#Global/Help/Tips/InitialInstallationWizard/Help_DomainName.html?width=350" class="helpTip" id="h3" name="
						This is the domain name of the website.
					"><img src="#variables.Paths.HelpGraphicsPath#help.png" width="16" height="16" border="0" alt="help popup button" class="helpPopupButton"></a>
				</dd>
				<dt class="labelCol"><label for="suburb">Password again: </label></dt>
				<dd class="inputCol">
					<input type="text" class="inputField" name="BaseDomainName" value="#theData.BaseDomainName.Data#">
					<a href="#variables.Paths.theRootURL#Global/Help/Tips/InitialInstallationWizard/Help_DomainName.html?width=350" class="helpTip" id="h3" name="
						This is the domain name of the website.
					"><img src="#variables.Paths.HelpGraphicsPath#help.png" width="16" height="16" border="0" alt="help popup button" class="helpPopupButton"></a>
				</dd>
				<dt class="labelCol"><label for="suburb">Email Address: </label></dt>
				<dd class="inputCol">
					<input type="text" class="inputField" name="BaseDomainName" value="#theData.BaseDomainName.Data#">
					<a href="#variables.Paths.theRootURL#Global/Help/Tips/InitialInstallationWizard/Help_DomainName.html?width=350" class="helpTip" id="h3" name="
						This is the domain name of the website.
					"><img src="#variables.Paths.HelpGraphicsPath#help.png" width="16" height="16" border="0" alt="help popup button" class="helpPopupButton"></a>
				</dd>
			</dl>
			--->
		</fieldset>
		<fieldset class="fieldSetControl">
			<div id="SubmitWrapper">
				<input type="submit" id="GoToNextStepButton" class="FormButton" name="Forward1Step" value="#variables.MainFlow.StepTexts['Step_5'].Submit#">
				<p id="GoToNextStepText">
					We will now set up the SuperUser and then this site will ready to use.<br>
					Press the &quot;#variables.MainFlow.StepTexts['Step_5'].Submit#&quot; 
			   	button on the right to restart the system and you will then be able to log in to the administration area and set up your SLCMS site.<br>
					Enjoy!
				</p>
			</div>
		</fieldset>
	</form>

#includePartial("InstallWiz_PageBottom")#
</cfoutput>

