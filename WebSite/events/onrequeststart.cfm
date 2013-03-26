<!--- Place code here that should be executed on the "onRequestStart" event. --->

<!--- run SLCMS's OnRequestStart code if we are in the SLCMS space --->
<cfif this.variables.SLCMS.DoNotLoadSLCMS eq False and (listLast(request.cgi.script_name, "/") eq "content.cfm" or findNoCase("slcms", request.cgi.path_info))>
	<cfset $include(template="SLCMS/events/onrequeststart.cfm") />
</cfif>

