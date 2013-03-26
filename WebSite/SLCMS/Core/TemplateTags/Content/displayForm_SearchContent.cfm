<!--- SLCMS base tags to be used in template pages  --->
<!---  --->
<!--- custom tag to display the search form --->
<!--- &copy; mort bay communications --->
<!---  --->
<!--- created:  31st Dec 2006 by Kym K --->
<!--- modified: 31st Dec 2006 -  1st Jan 2007 by Kym K - did stuff --->
<!--- modified: 12th Jun 2007 - 12th Jun 2007 by Kym K - made styling and related attributes consistent across all form template tags --->

<!--- 
 --->
<cfsetting enablecfoutputonly="Yes">
<cfif thisTag.executionMode IS "start">
	<cfparam name="attributes.FormName" type="string" default="">
	<cfparam name="attributes.formaction" type="string" default="#request.RootURL#content.cfm/SearchContent">
	<cfparam name="attributes.formclass" type="string" default="searchform">
	<cfparam name="attributes.legendtext" type="string" default="&nbsp;">
	<cfparam name="attributes.class_fieldset" type="string" default="SearchFldSet">
	<cfparam name="attributes.class_inputfield" type="string" default="txt">
	<cfparam name="attributes.class_button" type="string" default="btn">
	<cfparam name="attributes.ShowAdvancedSearchOptionText" type="any" default=False>
	<cfparam name="attributes.TheAdvancedSearchOptionText" type="string" default="Advanced">
	<cfparam name="attributes.class_ShowAdvancedSearchOptionText" type="string" default="ShowAdvancedOptionText">

	<cfoutput>
	<form<cfif len(attributes.FormName)> name="#attributes.FormName#"</cfif> action="#attributes.formaction#?mode=search" method="post"<cfif len(attributes.formclass)> class="#attributes.formclass#"</cfif>>
	<input type="hidden" name="SimpleSearchRequested" id="SearchRequested" value="yes">
	<fieldset class="#attributes.class_fieldset#">
	<legend>#attributes.legendtext#</legend>
	 Site Search
	<label for="SearchTerm">
	<input type="text" name="SearchTerm" id="SearchTerm" class="#attributes.class_inputfield#" title="enter search term">
	</label>
	<input type="submit" value="Search" title="Search Site" class="#attributes.class_button#">
	<cfif attributes.ShowAdvancedSearchOptionText eq True>
	&nbsp;<a href="#attributes.formaction#?mode=AdvancedSearchRequested" class="#class_ShowAdvancedSearchOptionText#">#attributes.TheAdvancedSearchOptionText#</a>
	</cfif>
	</fieldset>
	</form>
	</cfoutput> 
 
</cfif>

<cfif thisTag.executionMode IS "end">


</cfif>

<cfsetting enablecfoutputonly="No">
