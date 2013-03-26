<!--- Place code here that should be executed on the "onApplicationStart" event. ---> 

<cfset application.pluginManager.requirePassword = false>

<!--- run SLCMS's application start code. The cfif is to allow framework tests to be run from startup with SLCMS getting in the way, DoNotLoadSLCMS flag set in SLCMS/config/app.cfm--->
<cfif this.variables.SLCMS.DoNotLoadSLCMS eq False and (listLast(request.cgi.script_name, "/") eq "content.cfm" or findNoCase("slcms", request.cgi.path_info))>
	<cfset $include(template="SLCMS/events/onapplicationstart.cfm") />
</cfif>
	