<!--- SLCMS Form Handling --->
<!--- SLCMS Login Form HTML --->
<!--- displays the standard login fields for folks wanting to log into SLCMS itself --->
<!---  --->
<!--- created:   6th Jun 2008 by Kym K - mbcomms --->
<!--- modified:  6th Jun 2008 -  6th Jun 2008 by Kym K - mbcomms, initial work on it --->

<cfimport taglib="/SLCMS/Core/TemplateTags/Content/" prefix="slcms">	<!--- grab the CMS functions to display things --->
<cfoutput> 
<!--- this is the function to display a login form --->
<slcms:displayForm_SignIn legendtext="Login to the Administration Area" ShowFormTag="No" />
<!--- wow! that was hard :-) --->
</cfoutput>


