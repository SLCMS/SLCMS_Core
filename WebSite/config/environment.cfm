<!---
	The environment setting can be set to "design", "development", "testing", "maintenance" or "production".
	For example, set it to "design" or "development" when you are building your application and to "production" when it's running live.
--->
<!---
<cfset set(environment="design")>
--->
<!--- let SLCMS decide what environment from the server name--->
<cfset $include(template="SLCMS/config/environment.cfm") />
