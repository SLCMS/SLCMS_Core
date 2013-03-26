<cfoutput>#includePartial("InstallWiz_PageTop")#
	<cfset theRootURL = "/" />
	<cfset theData = application.SLCMS.config.startup.initialization.installationTemp['MainFlow'].Steps['Step_1'].data />
  <!---
  <cfdump var="#theData#" expand="false" label="application.SLCMS.config.startup.initialization.installationTemp['MainFlow'].Steps['Step_1'].data">
--->
	<div id="WizHeading">Initialization, Stage 1 of 3 - Site Settings Review</div>
	<form id="MainFlow_Step_3" action="#application.SLCMS.Paths_Admin.AdminBaseURL#install-wizard" method="get">
		<input type="hidden" name="StepCount" value="Step_3">
		<input type="hidden" name="StepWork" value="Process">
		<fieldset class="fieldSet">
			<legend class="legend">Settings Review</legend>
			<div>
				<p>
					These are the settings you have entered for this SLCMS installation
					<cfif not theData.SiteName.Valid> <br><span class="StepErrorText"> (Note, there are errors that need to be fixed)</span></cfif>:
				</p>
				<dl>
					<dt class="ReviewText">The friendly internal name is </dt>
						<dd class="ReviewDetail">
							#theData.SiteName.Data#
							<cfif not theData.SiteName.Valid>
							 <span class="StepErrorText">*#theData.SiteName.ErrorText#*</span>
							 <span class="ReviewBadTick"><img src="#variables.Paths.WizGraphicsFolderPath#error_red.gif" width="32" height="32" alt="Good Tick"></span>
							<cfelse>
							 <span class="ReviewGoodTick"><img src="#variables.Paths.WizGraphicsFolderPath#tick_green.png" width="22" height="25" alt="Good Tick"></span>
							</cfif>
							</dd>
					<dt class="ReviewText">The short version of the name is </dt>
						<dd class="ReviewDetail">
							#theData.SiteAbbreviatedName.Data#
							<cfif not theData.SiteAbbreviatedName.Valid>
							 <span class="ReviewErrorText">*#theData.SiteAbbreviatedName.ErrorText#*</span>
							 <span class="ReviewBadTick"><img src="#variables.Paths.WizGraphicsFolderPath#error_red.gif" width="32" height="32" alt="Good Tick"></span>
							<cfelse>
							 <span class="ReviewGoodTick"><img src="#variables.Paths.WizGraphicsFolderPath#tick_green.png" width="22" height="25" alt="Good Tick"></span>
							</cfif>
							</dd>
					<dt class="ReviewText">The site's running mode is going to be</dt>
						<dd class="ReviewDetail">
							#theData.Role.Data#
							<cfif not theData.Role.Valid>
							 <span class="StepErrorText">*You must select a Role*</span>
							 <span class="ReviewBadTick"><img src="#variables.Paths.WizGraphicsFolderPath#error_red.gif" width="32" height="32" alt="Good Tick"></span>
							<cfelse>
							 <span class="ReviewGoodTick"><img src="#variables.Paths.WizGraphicsFolderPath#tick_green.png" width="22" height="25" alt="Good Tick"></span>
							</cfif>
							</dd>
					<dt class="ReviewText">and the Datasource is</dt>
						<dd class="ReviewDetail">
							#theData.DSN_SLCMS.Data#
							<cfif not theData.DSN_SLCMS.Valid>
							 <span class="StepErrorText">*#theData.DSN_SLCMS.ErrorText#*</span>
							 <span class="ReviewBadTick"><img src="#variables.Paths.WizGraphicsFolderPath#error_red.gif" width="32" height="32" alt="Good Tick"></span>
							<cfelse>
							 <span class="ReviewGoodTick"><img src="#variables.Paths.WizGraphicsFolderPath#tick_green.png" width="22" height="25" alt="Good Tick"></span>
							</cfif>
							</dd>
					<dt class="ReviewText">Error emails when not in debug mode would be sent to</dt>
						<dd class="ReviewDetail">
							#theData.ErrorEmailTo.Data#
							<cfif not theData.ErrorEmailTo.Valid>
							 <span class="StepErrorText">*#theData.ErrorEmailTo.ErrorText#*</span>
							 <span class="ReviewBadTick"><img src="#variables.Paths.WizGraphicsFolderPath#error_red.gif" width="32" height="32" alt="Good Tick"></span>
							<cfelse>
							 <span class="ReviewGoodTick"><img src="#variables.Paths.WizGraphicsFolderPath#tick_green.png" width="22" height="25" alt="Good Tick"></span>
							</cfif>
							</dd>
					<cfif theData.InDebugMode.Data>
						<dt class="ReviewText">But the site will be in debug mode so emails will be sent to</dt>
							<dd class="ReviewDetail">
								#theData.TestEddress.Data#
								<cfif not theData.TestEddress.Valid>
								 <span class="StepErrorText">*#theData.TestEddress.ErrorText#*</span>
								 <span class="ReviewBadTick"><img src="#variables.Paths.WizGraphicsFolderPath#error_red.gif" width="32" height="32" alt="Good Tick"></span>
								<cfelse>
								 <span class="ReviewGoodTick"><img src="#variables.Paths.WizGraphicsFolderPath#tick_green.png" width="22" height="25" alt="Good Tick"></span>
								</cfif>
								</dd>
					<cfelse>
						<dt class="ReviewText">If the site is switched to debug mode then emails will be sent to</dt>
							<dd class="ReviewDetail">
								#theData.TestEddress.Data#
								<cfif not theData.TestEddress.Valid>
								 <span class="StepErrorText">*#theData.TestEddress.ErrorText#*</span>
								 <span class="ReviewBadTick"><img src="#variables.Paths.WizGraphicsFolderPath#error_red.gif" width="32" height="32" alt="Good Tick"></span>
								<cfelse>
								 <span class="ReviewGoodTick"><img src="#variables.Paths.WizGraphicsFolderPath#tick_green.png" width="22" height="25" alt="Good Tick"></span>
								</cfif>
								</dd>
					</cfif>
				</dl>
			</div>
		</fieldset>
		<cfif theData.DataValid>
			<fieldset class="fieldSetControl">
				<div id="SubmitWrapper">
					<input type="submit" id="GoToNextStepButton" class="FormButton" name="Forward1Step" value="#variables.MainFlow.StepTexts['Step_3'].Submit#">
					<p id="GoToNextStepText">
					If you are satisfied with the above information we can now set up this installation of SLCMS. <br>
					Press the &quot;#variables.MainFlow.StepTexts['Step_3'].Submit#&quot; 
			   	button to set up this SLCMS system.
			   	</p>
				</div>
			</fieldset>
		</cfif>
	</form>
	<form id="MainFlow_Step_3b" action="#application.SLCMS.Paths_Admin.AdminBaseURL#install-wizard" method="get">
		<input type="hidden" name="StepCount" value="Step_3">
		<input type="hidden" name="StepWork" value="BackForward">
		<fieldset class="fieldSetControl">
			<div id="BackToSettingsWrapper">
				<input type="submit" id="BackToSettingsButton" class="FormButton" name="Back1Step" value="#variables.MainFlow.StepTexts['Step_3'].Back1Step#">
				<div id="BackToSettingsText">
				<cfif theData.DataValid>
					If you are not satisfied with the above configuration information you can change it. <br>
					Press the &quot;#variables.MainFlow.StepTexts['Step_3'].Back1Step#&quot; 
			   	button on the left to return to the settings pages.
				<cfelse>
					<span class="BackToSettingsTextWithError">
					The above information was inadequate for us to be able to continue. <br>
					Press the &quot;#variables.MainFlow.StepTexts['Step_3'].Back1Step#&quot; 
			   	button on the left to return and fix the errors.
					</span>
				</cfif>
				</div>
			</div>
		</fieldset>
	</form>

#includePartial("InstallWiz_PageBottom")#
</cfoutput>

