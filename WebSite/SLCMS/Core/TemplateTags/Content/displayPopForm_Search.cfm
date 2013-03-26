<!--- SLCMS base tags to be used in template pages  --->
<!---  --->
<!--- custom tag to display the search form --->
<!--- &copy; mort bay communications --->
<!---  --->
<!--- created:  31st Dec 2006 by Kym K --->
<!--- modified: 31st Dec 2006 -  1st Jan 2007 by Kym K - did stuff --->
<!--- modified: 12th Jun 2007 - 12th Jun 2007 by Kym K - made styling and related attributes consistent across all form template tags --->
<!---
docs: modified: 13th Mar 2012 - 18th Mar 2012 by Kym K, mbcomms: upgrade to allow for a pop modal style using jQuery
--->
<!--- 
 --->
<cfsetting enablecfoutputonly="Yes">
<cfif thisTag.executionMode IS "start">
	<cfparam name="attributes.PodStyle" type="string" default="False">
	<cfparam name="attributes.FormName" type="string" default="">
	<cfparam name="attributes.formaction" type="string" default="#request.SLCMS.RootURL#content.cfm/Search">
	<cfparam name="attributes.formclass" type="string" default="searchform">
	<cfparam name="attributes.legendtext" type="string" default="&nbsp;">
	<cfparam name="attributes.class_fieldset" type="string" default="SearchFldSet">
	<cfparam name="attributes.class_inputfield" type="string" default="txt">
	<cfparam name="attributes.class_button" type="string" default="btn">
	<cfparam name="attributes.buttontext" type="string" default="Search">
	<cfparam name="attributes.ShowAdvancedSearchOptionText" type="any" default=False>
	<cfparam name="attributes.TheAdvancedSearchOptionText" type="string" default="Advanced">
	<cfparam name="attributes.class_ShowAdvancedSearchOptionText" type="string" default="ShowAdvancedOptionText">

	<cfset thisTag.TagTemplateBasePath = "#application.SLCMS.Paths_Common.CoreTagsSubTemplateURL#Search/" />  
	<cfset thisTag.Ret = application.SLCMS.Core.ContentCFMfunctions.AddHeadContent(Place="Bottom", Type="Stylesheet", Path="#thisTag.TagTemplateBasePath#TemplateControl/SearchPopForm_Defaults.css") />	<!--- load in stylesheet --->

	<cfif attributes.PodStyle is True>
		<cfoutput>
		<div id="SearchPodContainer">
		<form<cfif len(attributes.FormName)> name="#attributes.FormName#"</cfif> id="PodForm" action="#attributes.formaction#?mode=search" method="post"<cfif len(attributes.formclass)> class="#attributes.formclass#"</cfif>>
			<input type="hidden" name="SimpleSearchRequested" id="SearchRequested" value="yes">
			<a href="##" id="SearchPod_submit" class="">&nbsp;</a>
			<div id="SearchInputWrap">
			<input type="text" name="SearchTerm" id="SearchPodTerm" class="#attributes.class_inputfield#" title="enter search term">
			</div>
			<!---
			<input type="submit" id="SearchPod_submit" value="#attributes.buttontext#" title="Search Site" class="#attributes.class_button#">
			--->
		</form>
		</div>
		</cfoutput>
		<cfsaveContent variable="TheJS"><cfoutput>
		<script type="text/javascript">
			$(document).ready(function() {
		    $("##SearchPod_submit").click(function(e) {
		    	$("##PodForm").submit();
		    });
			});
		</script></cfoutput>
		</cfsaveContent><cfhtmlHead text="#TheJS#" />
	<cfelse>
		<cfoutput>
	  <div id="SearchContainer">
		<form<cfif len(attributes.FormName)> name="#attributes.FormName#"</cfif> action="#attributes.formaction#?mode=search" method="post"<cfif len(attributes.formclass)> class="#attributes.formclass#"</cfif>>
		<input type="hidden" name="SimpleSearchRequested" id="SearchRequested" value="yes">
		<input type="submit" id="Search_submit" value="#attributes.buttontext#" title="Search Site" class="#attributes.class_button#">
		<fieldset class="#attributes.class_fieldset#">
		<legend>#attributes.legendtext#</legend>
		<span id="SearchPreText">Site Search</span>
		<label for="SearchTerm">
		<input type="text" name="SearchTerm" id="SearchTerm" class="#attributes.class_inputfield#" title="enter search term">
		</label>
		<cfif attributes.ShowAdvancedSearchOptionText eq True>
		&nbsp;<a href="#attributes.formaction#?mode=AdvancedSearchRequested" class="#class_ShowAdvancedSearchOptionText#">#attributes.TheAdvancedSearchOptionText#</a>
		</cfif>
		</fieldset>
		</form>
		</div>
		</cfoutput> 
	</cfif>

 
</cfif><cfsetting enablecfoutputonly="No">
