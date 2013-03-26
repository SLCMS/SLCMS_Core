<!--- SLCMS Form Handling --->
<!--- SLCMS Login Form Processor --->
<!--- does the login bit --->
<!--- actually it is done in Application.cfm here the tag just shows the  click to go to admin bit --->
<!---  --->
<!--- created:   6th Jun 2008 by Kym K - mbcomms --->
<!--- modified:  6th Jun 2008 -  6th Jun 2008 by Kym K - mbcomms, initial work on it --->


<cfimport taglib="/SLCMS/Core/TemplateTags/Content/" prefix="slcms">	<!--- grab the CMS functions to display things --->
<cfoutput>
<slcms:displayLoginForm ShowFormTag="No" />
</cfoutput>

