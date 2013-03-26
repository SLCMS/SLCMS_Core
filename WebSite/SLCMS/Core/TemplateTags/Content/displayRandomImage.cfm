<!--- SLCMS base tags to be used in template pages  --->
<!--- &copy; 2009 mort bay communications --->
<!---  --->
<!--- custom tag to display a random image --->
<!--- 
			outputs an html image tag straight or wrapped in an iframe
			can either grab a single image and spit it out or 
			spit out an iFrame with a randomly changing image in it
		  --->
<!--- created:  20th Jun 2008 by Kym K, mbcomms --->
<!--- modified: 20th Jun 2008 - 20th Jun 2008 by Kym K, mbcomms - did initial stuff --->

<!--- 
 --->
<cfsetting enablecfoutputonly="Yes">
<cfif thisTag.executionMode IS "start">
	<cfparam name="attributes.someName" type="string" default="">	<!---  --->

</cfif>	<!--- end: tag execution mode is start --->

<cfif thisTag.executionMode IS "end">
</cfif>
<cfsetting enablecfoutputonly="No">
