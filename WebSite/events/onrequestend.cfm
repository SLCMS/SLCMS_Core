<!--- Place code here that should be executed on the "onRequestEnd" event. --->
<!--- run SLCMS's OnRequestStart code if we are in the SLCMS space --->
<cfif listLast(request.cgi.script_name, "/") eq "content.cfm">
	<cfset $include(template="SLCMS/events/onrequestend.cfm") />
</cfif>
 