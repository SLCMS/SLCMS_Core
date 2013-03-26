<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<!--- &copy; 2007 mort bay communications --->

<!--- Error Handling Page --->
<!---  --->
<!--- created:  26th Jun 2008 by Kym K, mbcomms --->
<!--- Modified: 26th Jun 2008 - 26th Jun 2008 by Kym K, mbcomms - initial work --->
<!--- Modified: 21st Sep 2009 - 21st Sep 2009 by Kym K, mbcomms - added cflog to record error --->


<cfif IsDefined("Application.Logging.theSiteLogName")>
	<cfset theLogName = Application.Logging.theSiteLogName />
<cfelse>
	<cfset theLogName = "SLCMS_UnHandledAnywhereElse_Errors" />
</cfif>
<cflog file="#theLogName#" type="error" text="Content.cfm Function Error, function was: #TheFunctionCall#">

<!--- 
<cfoutput>
diagnostics of error is: #error.diagnostics#<br>
content was: #error.generatedcontent#
</cfoutput>
 --->

<html>
<head>
	<title>SLCMS::Error Caught</title> 
	<link rel="STYLESHEET" type="text/css" href="/Global/slcms.css">
</head>
<body>
<div class="ErrorHandlerWrapper">
	<p>
	Oops! Something has gone horribly wrong and we couldn't handle it. The error message is:
	</p>
	<p>#error.diagnostics#</p>
	<p>
	<a href="/content.cfm">Back to the Home Page</a>
	</p>
</div>
</body>
</html>



