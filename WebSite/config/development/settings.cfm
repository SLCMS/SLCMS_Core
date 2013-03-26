<!---
	This file is used to configure specific settings for the "development" environment.
	A variable set in this file will override the one in "config/settings.cfm".
	Example: <cfset set(dataSourceName="devDB")>
--->

<!--- include the settings code for SLCMS --->
<cfset $include(template="SLCMS/config/development/settings.cfm") />
