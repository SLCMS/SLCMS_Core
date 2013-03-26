<!--- SLCMS base tags to be used in template pages  --->
<!--- &copy; 2007 mort bay communications --->
<!---  --->
<!--- custom tag to display a SiteMap --->
<!--- some thing.....
		  --->
<!--- created:  23rd Apr 2007 by Kym K --->
<!--- modified: 23rd Apr 2007 - 23rd Apr 2007 by Kym K, did initial stuff --->

<!--- 
 --->
<cfsetting enablecfoutputonly="Yes">
<cfif thisTag.executionMode IS "start">
	<cfparam name="attributes.fred" type="string" default="">	<!--- no attributes needed I think --->

	<!--- we need to loop thru the entire site and display the pages in some neat structure, nested lists would be the go --->
	
	
	
	
</cfif>	<!--- end: tag execution mode is start --->

<cfif thisTag.executionMode IS "end">
</cfif>
<cfsetting enablecfoutputonly="No">
