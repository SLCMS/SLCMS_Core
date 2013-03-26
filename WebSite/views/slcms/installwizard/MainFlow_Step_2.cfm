<cfoutput>#includePartial("InstallWiz_PageTop")#
	<cfset theData = application.SLCMS.config.startup.initialization.installationTemp['MainFlow'].Steps['Step_1'].data />
	<cfset theNoString = "" />
	<cfset theYesString = "" />
  <!---
  <cfdump var="#theData#" expand="false" label="application.SLCMS.config.startup.initialization.installationTemp['MainFlow'].Steps['Step_1'].data">
--->
	<script type="text/javascript">
		$(document).ready(function() {
			var AJAXurl = '#variables.Paths.AJAXURL#';
			// Help tips plugin
			JT_init();
			// collapse the form to a wizard
			$("##MainFlow_Step_2").formToWizard({ submitButton: 'SubmitWrapper' })
			// handlers
			$('##SiteName').blur(function(){
				var theSiteName = $('##SiteName').val();
				var theSiteAbbreviatedName = $('##SiteAbbreviatedName').val();
				if (theSiteAbbreviatedName == '') {
					$.ajax({
						type:'GET',
						url: AJAXurl,
						data: {Job: 'CleanName', Name: theSiteName},
						success: function(data){
							var theSiteAbbreviatedName = $.trim(data)
							$('##SiteAbbreviatedName').val(theSiteAbbreviatedName);
						}
					});
				}
			});
			$('##DataSource').blur(function(){
				var theDataSource = $('##DataSource').val();
				if (theDataSource == '') {
					alert('Datasource Cannot Be Blank!')
				}
			});
		});
	</script>
	<div id="WizHeading">Initialization, Stage 1 of 3 - Site Settings Entry</div>
	<form id="MainFlow_Step_2" action="#application.SLCMS.Paths_Admin.AdminBaseURL#install-wizard" method="get">
		<input type="hidden" name="StepCount" value="Step_2">
		<input type="hidden" name="StepWork" value="Process">
		<fieldset class="fieldSet">
			<legend class="legend">Names</legend>
			<dl>
				<dt class="labelCol"><label for="addr1">This website's Name will be: </label></dt>
				<dd class="inputCol">
					<input type="text" class="inputField" name="SiteName" value="#theData.Sitename.Data#" id="SiteName">
					<a href="#variables.Paths.WizTipsPath#Help_SiteName.html?width=350" class="helpTip" id="h1" name="
						This is the name of the website.
					"><img src="#variables.Paths.HelpGraphicsPath#help.png" width="16" height="16" border="0" alt="help popup button" class="helpPopupButton"></a>
				</dd>
				<dt class="labelCol"><label for="addr2">This website's Abbreviated Name will be: </label></dt>
				<dd class="inputCol">
					<input type="text" class="inputField" name="SiteAbbreviatedName" value="#theData.SiteAbbreviatedName.Data#" id="SiteAbbreviatedName">
					<a href="#variables.Paths.WizTipsPath#Help_AbbrvName.html?width=350" class="helpTip" id="h2" name="
						This is the abbreviated name of the website.
					"><img src="#variables.Paths.HelpGraphicsPath#help.png" width="16" height="16" border="0" alt="help popup button" class="helpPopupButton"></a>
				</dd>
				<dt class="labelCol"><label for="suburb">The site's Domain Name will be: </label></dt>
				<dd class="inputCol">
					<input type="text" class="inputField" name="BaseDomainName" value="#theData.BaseDomainName.Data#">
					<a href="#variables.Paths.WizTipsPath#Help_DomainName.html?width=350" class="helpTip" id="h3" name="
						This is the domain name of the website.
					"><img src="#variables.Paths.HelpGraphicsPath#help.png" width="16" height="16" border="0" alt="help popup button" class="helpPopupButton"></a>
				</dd>
				<dt class="labelColRadio">
					<label for="MixedMode"><div class="RadioQ2Label">Is this a normally accessable website<br> or only accessable by being fully secured with SSL?</div></label>
				</dt>
				<dd class="inputColRadio"><cfsilent>
					<cfif theData.SSLOnly.Data>
		  			<cfset theNoString = '' />
		  			<cfset theYesString = ' checked="checked"' />
					<cfelse>
		  			<cfset theNoString = ' checked="checked"' />
		  			<cfset theYesString = '' />
					</cfif></cfsilent>
					<div class="RadioFieldWrap">
					<input type="radio" name="SSLOnly" value="No" class="inputFieldRadio"#theNoString#>Normal<br>
					<input type="radio" name="SSLOnly" value="Yes" class="inputFieldRadio"#theYesString#>SSL only
					</div>
					<a href="#variables.Paths.WizTipsPath#Help_HTTPSq.html?width=350" class="helpTip" id="h4" name="
						Can the website accessed by normal web connections or only with SSL securing the connection.
					"><img src="#variables.Paths.HelpGraphicsPath#help.png" width="16" height="16" border="0" alt="help popup button" class="helpPopupButton"></a>
					<div class="ClearLeft"></div>
				</dd>
			</dl>
		</fieldset>
		<fieldset class="fieldSet">
			<legend class="legend">Role</legend>
			<dl>
				<dt class="labelColTopS">The machine's Name is: </dt>
				<dd class="inputColNoField">
					#theData.MachineName.Data#
					<a href="#variables.Paths.WizTipsPath#Help_MachineName.html?width=350" class="helpTip" id="h5" name="
						This is the name of the computer this site is running on.
					"><img src="#variables.Paths.HelpGraphicsPath#help.png" width="16" height="16" border="0" alt="help popup button" class="helpPopupButton"></a>
					<div class="ClearLeft"></div>
				</dd>
				<dt class="labelColRadio">
					<label for="Role"><div class="RadioQMultiLabel">How do you want this installation of SLCMS to behave?</div></label>
					<a href="#variables.Paths.WizTipsPath#Help_Roles.html?width=350" class="helpTip" id="h6" name="
						This is the way the site works.
					"><img src="#variables.Paths.HelpGraphicsPath#help.png" width="16" height="16" border="0" alt="help popup button" class="helpPopupButton"></a>
				</dt>
				<dd class="inputColRadio">
					<div>
					<input type="radio" name="Role" value="Production" class="inputFieldRadio"<cfif theData.Role.Data eq "Production"> checked="checked"</cfif>>Production Site<br>
					<input type="radio" name="Role" value="Maintenance" class="inputFieldRadio"<cfif theData.Role.Data eq "Maintenance"> checked="checked"</cfif>>Maintenance<br>
					<input type="radio" name="Role" value="Testing" class="inputFieldRadio"<cfif theData.Role.Data eq "Testing"> checked="checked"</cfif>>Testing<br>
					<input type="radio" name="Role" value="Development" class="inputFieldRadio"<cfif theData.Role.Data eq "Development"> checked="checked"</cfif>>Development<br>
					<input type="radio" name="Role" value="Design" class="inputFieldRadio"<cfif theData.Role.Data eq "Design"> checked="checked"</cfif>>Design<br>
					</div>
					<div class="ClearLeft"></div>
				</dd>
				<!--- 
				<dt class="labelColRadio">
					<label for="MixedMode"><div class="RadioQ2Label">Are there multiple installations of SLCMS performing different roles on this machine?</div></label>
					<a href="#variables.Paths.WizTipsPath#Help_MultiRoles.html?width=450" class="helpTip" id="h7" name="
						Are there copies of SLCMS doing different roles?
					"><img src="#variables.Paths.HelpGraphicsPath#help.png" width="16" height="16" border="0" alt="help popup button" class="helpPopupButton"></a>
				</dt>
				<dd class="inputColRadio">
					<div class="RadioFieldWrap">
					<input type="radio" name="MixedMode" value="No" class="inputFieldRadio"<cfif theData.MixedMode.Data eq "No"> checked="checked"</cfif>>No<br>
					<input type="radio" name="MixedMode" value="Yes" class="inputFieldRadio"<cfif theData.MixedMode.Data eq "Yes"> checked="checked"</cfif>>Yes<br>
					<input type="radio" name="MixedMode" value="Unknown" class="inputFieldRadio"<cfif theData.MixedMode.Data eq "Unknown"> checked="checked"</cfif>>Don't Know
					</div>
					<div class="ClearLeft"></div>
				</dd>
				 --->
			</dl>
		</fieldset>
		<fieldset class="fieldSet">
			<legend class="legend">Database</legend>
			<dl>
				<dt class="labelCol"><label for="fname">ColdFusion Datasource: </label></dt>
				<dd class="inputCol">
					<input type="text" class="inputField" name="DSN_SLCMS" value="#theData.DSN_SLCMS.Data#" id="DataSource">
					<a href="#variables.Paths.WizTipsPath#Help_DSN.html?width=350" class="helpTip" id="h8" name="
						This is the name of the Datasource set up in the ColdFusion Administrator for this website.
					"><img src="#variables.Paths.HelpGraphicsPath#help.png" width="16" height="16" border="0" alt="help popup button" class="helpPopupButton"></a>
					<div class="ClearLeft"></div>
				</dd>
			</dl>
		</fieldset>
		<fieldset class="fieldSet">
			<legend class="legend">Messages</legend>
			<dl>
				<dt class="labelCol"><label for="fname">Email Address for Regular System Messages: </label></dt>
				<dd class="inputCol">
					<input type="text" class="inputField" name="ErrorEmailTo" value="#theData.ErrorEmailTo.Data#">
					<a href="#variables.Paths.WizTipsPath#Help_ErrorEddress.html?width=350" class="helpTip" id="h9" name="
						This is the email address that system and error messages are sent to.
					"><img src="#variables.Paths.HelpGraphicsPath#help.png" width="16" height="16" border="0" alt="help popup button" class="helpPopupButton"></a>
					<div class="ClearLeft"></div>
				</dd>
				<dt class="labelCol"><label for="fname">Email Address for Test Messages: </label></dt>
				<dd class="inputCol">
					<input type="text" class="inputField" name="TestEddress" value="#theData.TestEddress.Data#">
					<a href="#variables.Paths.WizTipsPath#Help_TestEddress.html?width=350" class="helpTip" id="h9a" name="
						This is the email address that system and error messages are sent to when in Debug Mode.
					"><img src="#variables.Paths.HelpGraphicsPath#help.png" width="16" height="16" border="0" alt="help popup button" class="helpPopupButton"></a>
					<div class="ClearLeft"></div>
				</dd>
				<dt class="labelColRadio">
					<label for="DebugStatus"><div class="RadioQ2Label">Do you want debug status information shown?</div></label>
				</dt>
				<dd class="inputColRadio">
					<div class="RadioFieldWrap">
					<input type="radio" name="Debug_ShowStatus" value="No" class="inputFieldRadio"<cfif theData.Debug_ShowStatus.Data eq "No"> checked="checked"</cfif>>No<br>
					<input type="radio" name="Debug_ShowStatus" value="Yes" class="inputFieldRadio"<cfif theData.Debug_ShowStatus.Data eq "Yes"> checked="checked"</cfif>>Yes
					</div>
					<a href="#variables.Paths.WizTipsPath#Help_DebugStatus.html?width=350" class="helpTip" id="h10" name="
						Showing Debugging information.
					"><img src="#variables.Paths.HelpGraphicsPath#help.png" width="16" height="16" border="0" alt="help popup button" class="helpPopupButton"></a>
					<div class="ClearLeft"></div>
				</dd>
				<dt class="labelColRadio">
					<label for="DebugMode"><div class="RadioQ2Label">Do you want debugging information shown in any error that might occur?</div></label>
				</dt>
				<dd class="inputColRadio">
					<div class="RadioFieldWrap">
					<input type="radio" name="InDebugMode" value="No" class="inputFieldRadio"<cfif theData.InDebugMode.Data eq "No"> checked="checked"</cfif>>No<br>
					<input type="radio" name="InDebugMode" value="Yes" class="inputFieldRadio"<cfif theData.InDebugMode.Data eq "Yes"> checked="checked"</cfif>>Yes
					</div>
					<a href="#variables.Paths.WizTipsPath#Help_DebugMode.html?width=350" class="helpTip" id="h11" name="
						Verbose Debugging Information or not?
					"><img src="#variables.Paths.HelpGraphicsPath#help.png" width="16" height="16" border="0" alt="help popup button" class="helpPopupButton"></a>
					<div class="ClearLeft"></div>
				</dd>
			</dl>
		</fieldset>
		<div class="fieldSetControl">
			<div id="SubmitWrapper">
				<input type="submit" id="GoToNextStepButton" class="FormButton" name="Forward1Step" value="#variables.MainFlow.StepTexts['Step_2'].Submit#">
				<p id="GoToNextStepText">
				We have now gathered enough information to set up this installation of SLCMS. 
				Press the &quot;#variables.MainFlow.StepTexts['Step_2'].Submit#&quot; 
		   	button to review the entered information before the set up routine is run.
		   	</p>
			</div>
		</div>
	</form>
	<div id="BackToStartWrapper">
		<form action="#application.SLCMS.Paths_Admin.AdminBaseURL#install-wizard" method="get">
			<input type="hidden" name="StepCount" value="Step_1">
			<input type="hidden" name="StepWork" value="BackForward">
			<input type="submit" class="FormButton" name="Back1Step" value="#variables.MainFlow.StepTexts['Step_2'].Back1Step#">
		</form>
	</div>

#includePartial("InstallWiz_PageBottom")#
</cfoutput>

