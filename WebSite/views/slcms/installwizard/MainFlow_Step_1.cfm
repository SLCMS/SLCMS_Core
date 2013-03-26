<cfoutput>#includePartial("InstallWiz_PageTop")#
<!--- 
<cfdump var="#application.SLCMS.config.startup.initialization#" expand="false" label="application.SLCMS.config.startup.initialization">
<cfabort>
 --->
<cfset theData = application.SLCMS.config.startup.initialization.installationTemp['MainFlow'].Steps['Step_1'].data />
<!--- add the jQuery for this page, mainly its set up help text popups but also some validation and prefilling --->
<!---
<cfdump var="#theData#" expand="false" label="application.SLCMS.config.startup.initialization.installationTemp['MainFlow'].Steps['Step_1'].data">
--->
<div id="WizHeading">Set Up Wizard Preliminary: An Explanation</div>
<form name="MainFlow_Step_1" action="#application.SLCMS.Paths_Admin.AdminBaseURL#install-wizard" method="get">
	<input type="hidden" name="StepCount" value="Step_1">
	<input type="hidden" name="StepWork" value="Process">
	<fieldset class="fieldSet">
		<legend class="legend">Explanation of the Setup Wizard</legend>
		<div>
			<p>
				This Wizard is a 3 stage process where you will enter the details needed to make the site work correctly and the Wizard will set up the site for you.
			</p>
			<p>
				The first stage is a simple 4 step questionaire to get the various names needed for the site, 
				what type of site it is and some email addresses so that the SLCMS engine can send the site's administrator messages when it needs to.
				There are help buttons on every entry field to assist you in entering the correct details and you can move back and forth between the steps.
				At the end of this first stage you review the entries and go back and change them if needs be before you move to the second stage. 
			</p>
			<p>
				The second stage creates the configuration files and/or modifies existing ones depending on your entries
				and then creates the database tables needed to make the site operate.
			</p>
			<p>
				At this point there is a working but empty SLCMS website.
			</p>
			<p>
				The last stage asks for details for a SuperUser so that there is someone who has absolute control over this SLCMS installation
				and has the ability to create regular staff members to operate the site. 
				There is also an option to leave the site blank or to implement a very simple site with some sample templates and helpful pages
				to get the ball rolling.
			</p>
			<p>
				After the SuperUser has been created the SLCMS application will restart itself so that it is behaving as it will normally and you will be taken to the Home Page of the website.
			</p>
		</div>
	</fieldset>
	<fieldset class="fieldSetControl">
		<div id="SubmitWrapper">
			<input type="submit" id="GoToNextStepButton" class="FormButton" name="Forward1Step" value="#variables.MainFlow.StepTexts['Step_1'].Submit#">
			<p id="GoToNextStepText">
			Press the &quot;#variables.MainFlow.StepTexts['Step_1'].Submit#&quot; 
	   	button to start the Wizard to set up this SLCMS system.
	   	</p>
		</div>
		</fieldset>
</form>
<div id="BackToStartWrapper">
	<form action="#application.SLCMS.Paths_Admin.AdminBaseURL#install-wizard" method="get">
		<input type="hidden" name="StepCount" value="Step_1">
		<input type="hidden" name="StepWork" value="BackForward">
		<input type="submit" class="FormButton" name="Back1Step" value="#variables.MainFlow.StepTexts['Step_1'].Back1Step#">
	</form>
</div>



#includePartial("InstallWiz_PageBottom")#
</cfoutput>
