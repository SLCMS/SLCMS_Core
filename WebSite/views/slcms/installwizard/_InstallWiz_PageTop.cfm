<!--- The is the top, common section of code for the Installation Wizard --->
<cfoutput>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<!--- 
<!DOCTYPE html>
	 --->
<html>
<head>
	<title>SLCMS Initialization Wizard</title>
	<link href="#application.wheels.webpath#SLCMS/installAssist/InitialInstallationWizard.css" rel="STYLESHEET" type="text/css">
	<script type="text/javascript" src="#variables.Paths.JqueryPath#"></script>
	<script type="text/javascript" src="#variables.Paths.Form2WizJsPath#"></script>
	<script type="text/javascript" src="#variables.Paths.HelpTipJsPath#"></script>
</head>
<body>
	<div id="InitWizPageHead">
		<img src="#application.wheels.webpath#SLCMS/installAssist/graphics/slcmsLogo1.gif" alt="SLCMS Logo and Link" width="200" height="70" border="0" id="BannerLogo">
		<img src="#application.wheels.webpath#SLCMS/installAssist/graphics/installationWizardHeading.png" alt="The SLCMS Initial Installation Wizard" width="400" height="25" border="0" id="BannerText">
	</div>
	<cfif application.SLCMS.config.startup.initialization.ErrorCode>
		<div class="HeadErrorText">Error Occured: #application.SLCMS.config.startup.initialization.ErrorMessage#</div>
	</cfif>
	<div id="WizBodyWrapper">
</cfoutput>