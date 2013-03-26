<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
	<title>SLCMS Start Up</title>
	<link rel="STYLESHEET" type="text/css" href="<cfoutput>#application.wheels.rootpath#</cfoutput>SLCMS/SLCMSstyling/slcms.css">
	<style>
		body {
			color : #222211;
			background-color: #E1F9FF;
			Margin : 2px 10px 10px 10px;
		}
	</style>
</head>
<body>
	<p><a href="<cfoutput>#application.wheels.rootpath#</cfoutput>content.cfm"><img src="<cfoutput>#application.wheels.rootpath#</cfoutput>SLCMS/SLCMSstyling/slcmsLogo2.gif" alt="SLCMS Admin Page Logo and Link" border="0"></a></p>
	<h2>Welcome to SLCMS</h2>
	<p>
		This is the default home page sitting at the base of the installation. 
		In a pure SLCMS production environment this page will not be seen as you would have been redirected to the home page of the SLCMS system
		but here we are running in the CFWheels <strong><cfoutput>#get("environment")#</cfoutput></strong> environment. You can use the links below to see what you want.
		</p>
	<p>
		This structure is to allow SLCMS to be run alongside other CFWheels applications, 
		in fact if they are written using the same extension architecture then many CFWheels applications can run alongside each other.
		</p>
	<p>
		<a href="<cfoutput>#application.wheels.rootpath#</cfoutput>content.cfm">Go to the SLCMS website</a><br>
		</p>
	<p>
		<a href="<cfoutput>#application.wheels.rootpath#</cfoutput>index.cfm/slcms/admin-home" target="SLCMS_Admin">Go to the SLCMS administration area as a standalone site rather than using the normal pull-down tools</a>
		(opens in a new window/tab)
		</p>
</body>
</html>
<!--- 
<cfdump var="#application#" expand="false" label="application">
<cfdump var="#request#" expand="false" label="request">
 --->