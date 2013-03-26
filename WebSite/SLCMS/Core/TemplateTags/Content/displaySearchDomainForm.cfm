<!--- SLCMS base tags to be used in template pages  --->
<!---  --->
<!--- custom tag to display the search form --->
<!--- &copy; mort bay communications --->
<!---  --->
<!--- created:  31st Dec 2006 by Kym K --->
<!--- modified: 15th Dec 2006 - 15th Dec 2006 by Kym K - did stuff --->

<!--- 
 --->
<cfsetting enablecfoutputonly="Yes">
<cfif thisTag.executionMode IS "start">
	<cfparam name="attributes.formName" type="string" default="">
	<cfparam name="attributes.style" type="string" default="">
	<cfparam name="attributes.id" type="string" default="">

	<cfoutput>
	<form name="#attributes.formName#" action="/search.cfm?mode=search" method="post">
	<input type="hidden" name="SearchDomain" id="SearchDomain" value="yes">
	<fieldset class="SearchFldSet">
	<legend>&nbsp;</legend>
	<label for="searchDom"> 
	<input type="text" name="searchDom" id="searchDom" class="txt" title="enter search term">
	</label>
	<input type="submit" value="Search" title="Search for Domain name" class="btn">
	</fieldset>
	</form>
	</cfoutput> 
 
</cfif>

<cfif thisTag.executionMode IS "end">


</cfif>

<cfsetting enablecfoutputonly="No">
