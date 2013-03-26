<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<!--- &copy; 2007 mort bay communications --->

<!--- Error Handling Page --->
<!---  --->
<!--- created:  26th Jun 2008 by Kym K, mbcomms --->
<!--- Modified: 26th Jun 2008 - 26th Jun 2008 by Kym K, mbcomms - initial work --->
<!--- Modified: 14th Aug 2008 - 14th Aug 2008 by Kym K, mbcomms - added cfif so error email only if not debugging --->
<!--- Modified:  9th Jul 2009 -  9th Jul 2009 by Kym K, mbcomms - added cflog to record error --->



<!--- 
<cfoutput>
diagnostics of error is: #error.diagnostics#<br>
content was: #error.generatedcontent#
</cfoutput>
 --->
<cfif IsDefined("Application.Logging.theSiteLogName")>
	<cfset theLogName = Application.Logging.theSiteLogName />
<cfelse>
	<cfset theLogName = "SLCMS_UnHandledAnywhereElse_Errors" />
</cfif>
<cflog file="#theLogName#" type="error" text="Content.cfm General Error, message was: #cfcatch.message#">

<html>
<head>
	<title>SLCMS::Error Caught</title> 
	<link rel="STYLESHEET" type="text/css" href="/Global/slcms.css">
</head>
<body>
<div class="ErrorHandlerWrapper">
	<p>
	Oops! A confusion has occurred. The webmistress has been informed
	</p>
	<p>
	<a href="/content.cfm">Back to the Home Page</a>
	</p>
<cfsavecontent variable="theErrorDump"><cfdump var="#cfcatch#"></cfsavecontent>
<cfif application.SLCMS.config.DeBug.DebugMode eq True>
	<cfoutput>
	Unhandled Error in content.cfm on SLCMS site: #application.SLCMS.config.base.SiteName#<br>
	#theErrorDump#
	</cfoutput>
<cfelse>
	<cfmail to="#application.SLCMS.config.DeBug.errorEmailTo#" from="SLCMS" subject="SLCMS Error in Content.cfm" type="html">
	Unhandled Error in content.cfm on SLCMS site: #application.SLCMS.config.base.SiteName#
	#theErrorDump#
	</cfmail>
</cfif>
</div>
</body>
</html>



