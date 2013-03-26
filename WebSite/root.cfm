<cftry>
<!--- 	
	<cfdump var="#arguments#" expand="false" label="arguments" />
<cfabort />
	<cfdump var="#application.wheels#" expand="false" label="application.wheels" />
<cfabort />
	<cflog text="root.cfm invocation: #arguments.component#" file="cfwSLCMStest" type="error" />
 ---> 

<!---  
<cfdump var="#application#" expand="false" label="application" />
<cfdump var="#arguments#" expand="false" label="arguments" />
<cfabort />
 --->
	<cfinvoke attributeCollection="#arguments#">
<cfcatch>
	<cfdump var="#arguments#" expand="false" label="arguments" />
	<cflog text="root.cfm caught. Invoked: #arguments.component#" file="cfwSLCMStest" type="error" />
	<cfrethrow  />
</cfcatch>
</cftry>
