<cfoutput>#includePartial("InstallWiz_PageTop")#
	<cfset theRootURL = "/" />
	<cfset theMainData = application.SLCMS.config.startup.initialization.installationTemp['MainFlow'].Steps['Step_1'].data />
	<cfset thisStepData = application.SLCMS.config.startup.initialization.installationTemp['MainFlow'].Steps['Step_3'].data />
	<cfset lastStepErrors = application.SLCMS.config.startup.initialization.installationTemp["MainFlow"].Steps["Step_2"].error />
  
  <div id="WizHeading">Initialization, Stage 2 of 3 - Site Creation</div>
	<form id="MainFlow_Step_4" action="#application.SLCMS.Paths_Admin.AdminBaseURL#install-wizard" method="get">
		<input type="hidden" name="StepCount" value="Step_4">
		<input type="hidden" name="StepWork" value="Process">
		<fieldset class="fieldSet">
			<legend class="legend">System Setup, Stage 2 - Site Creation</legend>
			<div>
				<cfif BitAnd(lastStepErrors.ErrorCode, 7) neq 0>
					<p class="ResultText">
						The configuration file creation and updating failed. The Errors were:
					</p>
					<p class="StepErrorText">
						#lastStepErrors.ErrorText#
					</p>
				<cfelse>
					<p class="ResultText">
						The configuration files have now been created according to your settings.
					 <span class="ReviewGoodTick"><img src="#variables.Paths.WizGraphicsFolderPath#tick_green.png" width="22" height="25" alt="Good Tick"></span>
					</p>
				</cfif>
				<cfif BitAnd(lastStepErrors.ErrorCode, 56) neq 0>
					<p class="ResultText">
						The database table creation failed. The Errors were:
					</p>
					<p class="StepErrorText">
						#lastStepErrors.ErrorText#
					</p>
				<cfelse>
					<p class="ResultText">
						The database has been created.
					 <span class="ReviewGoodTick"><img src="#variables.Paths.WizGraphicsFolderPath#tick_green.png" width="22" height="25" alt="Good Tick"></span>
					</p>
				</cfif>
			</div>
		</fieldset>
	</form>
	<cfif lastStepErrors.ErrorCode>
		<form action="#application.SLCMS.Paths_Admin.AdminBaseURL#install-wizard" method="get">
			<input type="hidden" name="StepCount" value="Step_4">
			<input type="hidden" name="StepWork" value="BackForward">
			<fieldset class="fieldSetControl">
				<div id="SubmitWrapper">
					<input type="submit" id="BackToSettingsButton" class="FormButton" name="Back1Step" value="#variables.MainFlow.StepTexts['Step_4'].Back1Step#">
					<div id="BackToSettingsText">
						<span class="BackToSettingsTextWithError">
						We are not be able to continue. <br>
						Press the &quot;#variables.MainFlow.StepTexts['Step_4'].Back1Step#&quot; 
				   	button on the left to return and fix the errors.
						</span>
					</div>
				</div>
			</fieldset>
		</form>
	<cfelse>
		<form action="#application.SLCMS.Paths_Admin.AdminBaseURL#install-wizard" method="get">
			<input type="hidden" name="StepCount" value="Step_4">
			<input type="hidden" name="StepWork" value="Process">
			<fieldset class="fieldSetControl">
				<div id="SubmitWrapper">
					<input type="submit" id="GoToNextStepButton" class="FormButton" name="Forward1Step" value="#variables.MainFlow.StepTexts['Step_4'].Submit#">
					<p id="GoToNextStepText">
						You now have an empty website.<br>
						We will now set up the SuperUser.<br>
						Press the &quot;#variables.MainFlow.StepTexts['Step_4'].Submit#&quot; 
				   	button on the right to continue.
					</p>
				</div>
			</fieldset>
		</form>
	</cfif>	

#includePartial("InstallWiz_PageBottom")#
</cfoutput>

