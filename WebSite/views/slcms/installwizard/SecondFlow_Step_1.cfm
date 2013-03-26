<cfoutput>#includePartial("InstallWiz_PageTop")#
	<form action="#application.SLCMS.Paths_Admin.AdminBaseURL#install-wizard" method="get">
		<input type="hidden" name="StepCount" value="Step_1">
		<input type="hidden" name="StepWork" value="Process">
	<fieldset class="fieldSet">
		<legend class="legend">The Site Has Run Before</legend>
		<p>
			SLCMS started and it could not find the database attached to this website or it thought the database is empty
			but you said that this is not the first time that SLCMS has run.
		</p>
	</fieldset>
	<fieldset class="fieldSet">
		<p style="float:left;">
			There has just been a hiccup, it should be all right.
		</p>
		<input type="submit" id="GoToNextStepButton" class="FormButton" name="FirstTime" value="#variables.SecondFlow.StepTexts['Step_1'].TryAgain#">
	</fieldset>
	</form>
	<!--- 
	<p>
		So here are some questions to find out what has happened.
	</p>
	<form action="#application.SLCMS.Paths_Admin.AdminBaseURL#install-wizard" method="get">
		<input type="hidden" name="StepCount" value="Step_1">
		<input type="hidden" name="StepWork" value="Process">
		<input type="submit" name="FirstTime" value="#variables.SecondFlow.StepTexts['Step_1'].Q1#">
		<input type="submit" name="NotFirstTime" value="#variables.SecondFlow.StepTexts['Step_1'].Q2#">
	</form>
	 --->

#includePartial("InstallWiz_PageBottom")#
</cfoutput>

