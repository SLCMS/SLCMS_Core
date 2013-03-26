<!--- inserts the standard html no cache tags plus the matching http protocol ones
 ---><cfif thisTag.executionMode IS "start">
<cfheader name="Pragma" value="no-cache">
<cfheader name="Expires" value="#GetHttpTimeString(Now())#">
<cfheader name="cache-control" value="no-cache, no-store, must-revalidate">
<cfset thisTag.OurContent = '<META HTTP-EQUIV="Pragma" CONTENT="no-cache"><META HTTP-EQUIV="Expires" CONTENT="01 Apr 1995 01:10:10 GMT"><META HTTP-EQUIV="Cache-Control" CONTENT="no-cache,  no-store, must-revalidate">' /></cfif><!--- 
 ---><cfif thisTag.executionMode IS "end"><cfset thisTag.GeneratedContent = "" /><cfoutput>#thisTag.OurContent#</cfoutput></cfif>