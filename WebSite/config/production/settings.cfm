<!---
	This file is used to configure specific settings for the "production" environment.
	A variable set in this file will override the one in "config/settings.cfm".
	Example: <cfset set(errorEmailAddress="someone@somewhere.com")>
--->

<!--- include the settings code for SLCMS --->
<cfset $include(template="SLCMS/config/production/settings.cfm") />
