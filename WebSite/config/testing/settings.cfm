<!---
	This file is used to configure specific settings for the "testing" environment.
	A variable set in this file will override the one in "config/settings.cfm".
	Example: <cfset set(cacheQueries=false)>
--->


<!--- include the settings code for SLCMS --->
<cfset $include(template="SLCMS/config/testing/settings.cfm") />
