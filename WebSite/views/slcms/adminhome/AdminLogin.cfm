<cfsilent>
<!---  --->
<!--- A Simple, Light CMS system by Mort Bay Communications Pty Ltd --->
<!--- Copyright 2002-2012 --->
<!---  --->
<!--- Site Management SignIn Page --->
<!---  --->
<!--- Created:  23rd May 2008 by Kym K --->
<!--- modified:  5th Sep 2009 -  5th Sep 2009 by Kym K, mbcomms: changing to user permissions system and adding portal capacity --->
<!--- modified: 23rd Nov 2009 - 23rd Nov 2009 by Kym K, mbcomms: changlogin tag to <slcms:displayForm_SignIn --->
<!--- modified: 15th Aug 2011 - 15th Aug 2011 by Kym K, mbcomms: we now have Empty Site and New Installation Wizards, code upgraded here to match --->
<cfimport taglib="/slcms/Core/TemplateTags/Content/" prefix="slcms">	<!--- grab the CMS functions to display things --->
</cfsilent>
<cfoutput>#includePartial("/slcms/adminbanner")#</cfoutput>

<cfif application.slcms.core.UserPermissions.IsLoggedin()>
	<div>&nbsp;</div>
	<!--- show the login form --->
	<slcms:displayForm_LogIn formaction="#application.SLCMS.Paths_Admin.AdminBaseURL#admin-home?#PageContextFlags.ReturnLinkParams#&amp;action=adminlogin" ShowGoToAdmin="No" legendtext="Administration Area Login Control" class_fieldset="AdminloginFldSetLoggedIn" class_inputfield="AdminloginInput" />
<cfelse>
	<!--- show the login form --->
	<div>&nbsp;</div>
	<slcms:displayForm_LogIn formaction="#application.SLCMS.Paths_Admin.AdminBaseURL#admin-home?#PageContextFlags.ReturnLinkParams#&amp;action=adminlogin" ShowGoToAdmin="No" legendtext="Login" class_fieldset="AdminloginFldSetLoggedOut" class_inputfield="AdminloginInput" />
</cfif>

</body>
</html>
