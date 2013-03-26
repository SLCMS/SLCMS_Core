
<!--- html outer code is in layout.cfm under the SLCMS folder, ie common to all backend views --->
<cfsavecontent variable="theHeadStuff">
<cfif DispMode eq "addpage" or DispMode eq "editpage"><cfsilent>
	<!--- a couple of preliminary string things so we can get the path filling to work nicely --->
	<!--- actually they have all gone, we write tidy code!, Kym pats herself on the back :-) --->
	<!--- but now we have moved some flag setters up here as CF was making too much white space --->
	<cfif dHasContent>
		<cfset theHasContentflag = 'true' />
	<cfelse>
		<cfset theHasContentflag = 'false' />
	</cfif>
	<cfif dIsParent>
		<cfset theHasChildrenflag = 'true' />
	<cfelse>
		<cfset theHasChildrenflag = 'false' />
	</cfif>
	<cfif DispMode eq "addpage">	<!--- we only want to force an update of the URL if we are creating first time and only once --->
		<cfset theNavNameDunItflag = 'false' />
	<cfelse>
		<cfset theNavNameDunItflag = 'true' />
	</cfif>
	<!--- here we set up for what is to show on entry. Hide everything by default and then turn on which one matches the page --->
	<cfset jsCoreNothingSelected = "hide" />
	<cfset jsCoreFormSelected = "hide" />
	<cfif cDispType eq "Form">
		<cfset jsCoreFormSelected = "show" />
	</cfif>
	<cfif cDispType eq "" and application.SLCMS.Core.SLCMS_Utility.DoPagesHaveTemplatesOnly()>
		<cfset jsCoreNothingSelected = "show" />
	</cfif>
	</cfsilent>
	<script language="JavaScript" type="text/javascript">
	//standard var we need, put at very top as var declarations because they probably will get overwritten by the CF loaded code below or the jquery AJAX even later
	var theNavName = '';
	var theURLName = '';
	var theCleanedURLName = '';
	var theSelectedVal = '';
	var theResponse = '';
	var theSelectedModuleFriendlyName = '';
	var theSelectedModuleHintText = '';
	var theSelectedModuleWhatText = '';
	var theSelectedModuleSelectionText = '';
	var	theOriginalSelectionHintText = '';
<cfoutput><!--- put the things that need CF filling at the top if we can so that we do not have ## issues down in the jquery --->
  var AJAXurl = '#application.SLCMS.Paths_Admin.ajaxURL_ABS#';
	var PrePath = '#application.SLCMS.Paths_Common.ContentRootURL##theURLPathToHere#';
	var thesubSiteID = '#session.SLCMS.Currents.Admin.PageStructure.CurrentSubSiteID#';
	var theUserID = '#session.SLCMS.user.UserID#';
	var flgHasContent = #theHasContentflag#;
	var flgHasChildren = #theHasChildrenflag#;
	var NavNameDunIt = #theNavNameDunItflag#;
</cfoutput>
	$(document).ready(function() {
// first set up the basic look
	ChangeSubWarnMsgVisibility();
	HideOriginalSelectionHintText();
	<cfoutput>#thejQueryOnReadyString#</cfoutput><!--- a whole bunch of jQuery js code built up in CF in __Admin_PageStructure-Code.cfm, mainly setting up the field visibility for the initial page hit --->
// now handle the actions
	$('#NavName').blur(function(){
		theNavName = $('#NavName').val();
		if (theNavName == '') {
			alert('You have not entered a Page Name');
		}
		if (NavNameDunIt == false) {
			$.ajax({
				type: 'GET',
				url: AJAXurl,
				data: {Job:'CleanName', Name:theNavName},
				success: function(stuffBack){
					if (stuffBack.STATUS == 'OK') {
						theCleanedURLName = stuffBack.MESSAGE
						// put response in URLPath text entry field
						$('#URLName').val(theCleanedURLName);
						// and in the full-path area
						$('#FullPathShow').text(PrePath + theCleanedURLName);
						NavNameDunIt = true
						}
					}
			});
		}
	});
	$('#URLName').blur(function(){
		theURLName = $('#URLName').val();
		if (theURLName == '') {
			alert('You have not entered a URL Path');
		}
			$.ajax({
				type: 'GET',
				url: AJAXurl,
				data: {Job:'ReCleanName', Name:theURLName},
				success: function(stuffBack){
					if (stuffBack.STATUS == 'OK') {
						theCleanedURLName = stuffBack.MESSAGE
						// put response in URLPath text entry field
						$('#URLName').val(theCleanedURLName);
						// and in the full-path area
						$('#FullPathShow').text(PrePath + theCleanedURLName);
						}
					}
			});
	});
	//now the radio button handlers
	$('#HasContentOn').click(function(){
		flgHasContent = true;
		ChangeSubWarnMsgVisibility();
	})
	$('#HasContentOff').click(function(){
		flgHasContent = false;
		ChangeSubWarnMsgVisibility();
	})
	$('#IsParentOn').click(function(){
		flgHasChildren = true;
		ChangeSubWarnMsgVisibility();
	})
	$('#IsParentOff').click(function(){
		flgHasChildren = false;
		ChangeSubWarnMsgVisibility();
	})
	// then the display type handlers to show dependent input fields
	$('#DisplayTypeSel').change(function(){
		theSelectedVal = $('#DisplayTypeSel').val();
		// turn off all fields, in the ajax response we will turn the chosen one(s) on
		HideThemAll();
		//but show the original slection hint text as we have now changed to something else
		ShowOriginalSelectionHintText();
		// then get the new selection via AJAX
		$.getJSON(AJAXurl, {Job:'ContentTypeSelChanged', NewVal:theSelectedVal, subSiteID:thesubSiteID, UserID:theUserID}, function(data){
			var items= [];
			console.log(data);
				if (data.STATUS == 'FAIL') {
					alert('Bad Response from server\n\rResponse was:'+ data.MESSAGE);
				}
				else {
					var theModuleFormalName = data.MODULEFORMALNAME; 
					var IsAModule = data.ISMODULEFLAG; 
					IsAModule = IsAModule.toLowerCase(); 
					theModuleFormalName = theModuleFormalName.toLowerCase(); 
					var theDisplayType = data.SELECTDISPLAYMODE; 
					theDisplayType = theDisplayType.toLowerCase(); 
					theSelectedModuleFriendlyName = data.MODULEFRIENDLYNAME;
					if (IsAModule == 'core' && theDisplayType == 'form') {
						ShowFormSelected();
						HideNoParam3Needed()
					}
					if (IsAModule == 'module') {
						HideCoreParts();
						UpdateModuleHintText(data.MODULEHINTTEXT);
						// now fill with the config we have been given
//					alert('Response from server was:'+ data.MODULEFORMALNAME + ', ' + theDisplayType + ', ' + data.POPURL);
						if (theDisplayType == 'dropdown') {
							var theDisplayData = data.DROPDOWNDATA;	//this should be an array of what to show
							ShowModuleDropDown(theDisplayData);
						}
						if (theDisplayType == 'popup') {
							ShowPopupMode(data.POPURL);
						}
					}
				}
//			$.each(data, function(theKey,theValue) {
//				alert('Response from server was:- Key: '+ theKey + ' - Value: ' + theValue);
//			});
		});
	});	
	// O & S functions
	function ChangeSubWarnMsgVisibility() {
		if (flgHasContent == false && flgHasChildren == true) {
			$('#SubWarnMsg').show();
			$('#SubWarnLabel').show();
		}
		else {
			$('#SubWarnMsg').hide();
			$('#SubWarnLabel').hide();
		}
	}
	//top level commands downwards
	function HideThemAll() {
		HideCoreDropDownSelectBox();
		HideCoreNothingSelected();
		HideFormSelected();
		HideModuleSelected();
		HideOriginalSelectionHintText();
		HidePopupMode();
		ShowNoParam3Needed();
	}
	function HideCoreParts() {
		HideNoParam3Needed();
		HideCoreNothingSelected();
		HideCoreDropDownSelectBox();
		HideFormSelected();
	}
	function ShowPopupMode(theURL) {
		ShowModuleSelected();
		HideModuleDropDownSelectBox();
		ShowPopupLink();
		ShowWhatSelectedHintText();
		$('#PopModuleSelector').attr('href',theURL);
	}
	function HidePopupMode() {
		HideModuleSelected();
		HidePopupLink();
		HideWhatSelectedHintText();
}
	function	ShowModuleDropDown(theArray) {
		ShowModuleSelected();
		HidePopupLink();
		HideWhatSelectedHintText();
		ShowModuleDropDownSelectBox();
		var options = [];
    for (var i = 0; i < theArray.length; i++) {
        options.push('<option value="',
          theArray[i].VALUE, '">',
          theArray[i].DISPLAY, '</option>');
		};
    $("#ModuleDropDownSelectBoxInput").html(options.join(''));
	}
	// then the actual ones that drive DOM elements
	function ShowCoreNothingSelected() {
		$('#CoreNothingSelectedP3').show();
		$('#CoreNothingSelectedInputP3').removeAttr("disabled");
		$('#CoreNothingSelectedP4').show();
		$('#CoreNothingSelectedInputP4').removeAttr("disabled");
	}
	function HideCoreNothingSelected() {
		$('#CoreNothingSelectedP3').hide();
		$('#CoreNothingSelectedInputP3').attr("disabled", true);
		$('#CoreNothingSelectedP4').hide();
		$('#CoreNothingSelectedInputP4').attr("disabled", true);
	}
	function ShowCoreDropDownSelectBox() {
		$('#CoreDropDownSelectBox').show();
		$('#CoreDropDownSelectBoxInput').removeAttr("disabled");
		$('#CoreSelectedInputP4').removeAttr("disabled");
	}
	function HideCoreDropDownSelectBox() {
		$('#CoreDropDownSelectBox').hide();
		$('#CoreDropDownSelectBoxInput').attr("disabled", true);
		$('#CoreSelectedInputP4').attr("disabled", true);
	}
	function ShowFormSelected() {
		$('#CoreFormSelected').show();
		$('#CoreFormSelectedInput').removeAttr("disabled");
		$('#ModuleSelectedInputP4').removeAttr("disabled");
	}
	function HideFormSelected() {
		$('#CoreFormSelected').hide();
		$('#CoreFormSelectedInput').attr("disabled", true);
		$('#CoreFormSelectedInputP3').attr("disabled", true);
		$('#CoreFormSelectedInputP4').attr("disabled", true);
	}
	function ShowModuleSelected() {
		$('#ModuleSelectedPrompt').text(theSelectedModuleFriendlyName);
		$('#ModuleSelected1').show();
		$('#ModuleSelected2').show();
		$('#ModuleSelectedHint').show();
	}
	function HideModuleSelected() {
		$('#ModuleSelected1').hide();
		$('#ModuleSelected2').hide();
		$('#ModuleSelectedHint').hide();
		$('#ModuleSelectedInputP3').attr("disabled", true);
		$('#ModuleSelectedInputP4').attr("disabled", true);
	}
	function UpdateModuleHintText(theString1) {
		theSelectedModuleHintText = theString1;
		$('#ModuleSelectedHint').text(theSelectedModuleHintText);
	}
	function UpdateSelectedItemsText(theString2) {
		theSelectedModuleSelectionText = theString2;
		$('#TheSelectedItems').text(theSelectedModuleSelectionText);
	}
	function ShowOriginalSelectionHintText() {
//		theOriginalSelectionHintText = theOtext;
//		$('#TheOriginalItems').text(theOtext);
		$('#TheOriginalHint').show();
		$('#TheOriginalItems').show();
	}
	function HideOriginalSelectionHintText() {
		$('#TheOriginalItems').hide();
		$('#TheOriginalHint').hide();
	}
	function ShowPopupLink() {
		$('#PopModuleSelector').show();
		$('#ModuleSelectedInputP3').removeAttr("disabled");
		$('#ModuleSelectedInputP4').removeAttr("disabled");
		$('#ModuleSelectedInputP3').show();
		$('#ModuleSelectedInputP4').show();
		$('#ModuleSelectedHint').text(theSelectedModuleHintText);
		$('#ModuleSelectedHint').show();
	}
	function HidePopupLink() {
		$('#PopModuleSelector').hide();
		$('#ModuleSelectedInputP3').attr("disabled", true);
		$('#ModuleSelectedInputP4').attr("disabled", true);
		$('#ModuleSelectedInputP3').hide();
		$('#ModuleSelectedInputP4').hide();
	}
	function ShowModuleDropDownSelectBox() {
		$('#ModuleDropDownSelectBoxInput').show();
		$('#ModuleDropDownSelectBoxInput').removeAttr("disabled");
		$('#ModuleSelectedInputP3').hide();
		$('#ModuleSelectedInputP3').attr("disabled", true);
		$('#ModuleSelectedInputP4').hide();
		$('#ModuleSelectedInputP4').attr("disabled", true);
	}
	function HideModuleDropDownSelectBox() {
		$('#ModuleDropDownSelectBoxInput').hide();
		$('#ModuleDropDownSelectBoxInput').attr("disabled", true);
		$('#ModuleSelectedInputP4').attr("disabled", true);
	}
	function ShowWhatSelectedHintText() {
		$('#WhatSelectedHint').show();
		$('#TheSelectedItems').show();
	}
	function HideWhatSelectedHintText() {
		$('#WhatSelectedHint').hide();
		$('#TheSelectedItems').hide();
	}
	function ShowNoParam3Needed() {
		// we never really show this nothingness, it is just to get dummy, blank param3 & 4 input fields
		$('#NoParam3Needed').hide();
		$('#NoParam3NeededInput').removeAttr("disabled");
		$('#NoParam4NeededInput').removeAttr("disabled");
	}
	function HideNoParam3Needed() {
		$('#NoParam3Needed').hide();
		$('#NoParam3NeededInput').attr("disabled", true);
		$('#NoParam4NeededInput').attr("disabled", true);
	}
	// this brings up the selector pop up to choose module-specific things
	$("#PopModuleSelector").fancybox({
		'titlePosition' :  'inside',
		'transitionIn'	:	'fade',
		'transitionOut'	:	'fade',
		'speedIn'		:	200, 
		'speedOut'		:	100, 
		'overlayShow'	:	true,
		'width':800,
		'height':600,
	  'onComplete': function(){
		DD_roundies.addRule('#fancybox-content', '10px', true);
		DD_roundies.addRule('#fancybox-outer', '15px', true);
    DD_roundies.addRule('#fancybox-wrap', '20px', true);
		}
	});
});	<!--- jQuery OnReady end --->		

</script>
<cfelse>
</cfif>
</cfsavecontent>
<cfhtmlhead text="#theHeadStuff#" />
<!---
<cfdump var="#variables#" expand="false" label="variables scope" >
<cfdump var="#form#" expand="false" label="form scope" >
--->

<cfoutput>#includePartial("/slcms/adminbanner")#</cfoutput>
<!--- 
<cfdump var="#session.SLCMS.pageAdmin.NavState.ExpansionFlags#" expand="false" label="session.SLCMS.pageAdmin.NavState.ExpansionFlags">
<cfdump var="#application.SLCMS#" expand="false" label="application.SLCMS">
<cfdump var="#session.SLCMS#" expand="false" label="session.SLCMS">
<cfdump var="#application.SLCMS.Core.PageStructure.getFullNavArray()#" expand="false" label="application.SLCMS.Core.PageStructure.getFullNavArray()">
 --->
<cfif application.SLCMS.core.UserPermissions.IsLoggedin()>
<cfif DispMode eq "AddPage" or DispMode eq "EditPage">
	<cfoutput>
	| #linkTo(text="#backLinkText#Back to Page Administration", controller="slcms.adminPages", action="index", params="#PageContextFlags.ReturnLinkParams#")#
	<form name="theForm" action="#application.SLCMS.Paths_Admin.AdminBaseURL#admin-pages?#PageContextFlags.ReturnLinkParams#&amp;mode=#opnext#" method="post">
	<input type="hidden" name="ParentID" value="#hParentID#">
	<input type="hidden" name="OldNavName" value="#hOldNavName#">
	<cfif WorkMode eq "AddPage">
		<input type="hidden" name="ParentNavName" value="#dParentNavName#">
	</cfif>
	</cfoutput>
	
	<table border="0" cellpadding="3" cellspacing="0">
	<cfif request.SLCMS.PortalAllowed>
		<tr><td colspan="9"><span class="majorheading">Site: <cfoutput>#session.SLCMS.Currents.Admin.PageStructure.CurrentSubSiteFriendlyName#</cfoutput></span></td></tr>
	<cfelse>
		<tr><td colspan="9"><span class="majorheading"></span></td></tr>
	</cfif>
	<tr><td colspan="9" align="center"><span class="minorheadingText">
		<cfif DispMode eq "AddPage">Adding a New Page <cfif hParentID neq 0>below: <span class="minorheadingName"><cfoutput>#dParentNavName#</cfoutput></span><cfelse> at Top Level</cfif>
		<cfelse>Properties of Page:<span class="minorheadingName"><cfoutput> #dNavName#</cfoutput></span>
		</cfif>
		</span></td></tr>
	<tr><td colspan="9"></td></tr>
	<cfif not application.SLCMS.Core.SLCMS_Utility.DoPagesHaveTemplatesOnly()>
	<tr>
		<td colspan="9"><u><strong>Required entries:</strong></u></td></tr>
	</cfif>
	<tr><td colspan="9"></td></tr>
	<tr>
		<td colspan="9"><hr></td></tr>
	<tr>
		<td colspan="2">Page Name<br><span class="HintText">(Seen in the menus/navigation and as the Page Title)</span></td>
		<td colspan="7"><input type="text" name="NavName" id="NavName" value="<cfoutput>#dNavName#</cfoutput>" size="40" maxlength="128"<cfif 1 eq 0 and DispMode eq "addpage"> onblur="doPathFill();"</cfif>></td></tr>
	<tr>
		<td colspan="2">Page Name as seen in URL Path<br><span class="HintText">(Spaces and some punctuation characters are illegal in URL paths,<br>such characters entered here will be encoded before they are used in a URL)</span></td>
		<td colspan="7"><input type="text" name="URLName" id="URLName" value="<cfoutput>#dURLName#</cfoutput>" size="40" maxlength="128"<!--- onblur="EncodeNav()"--->></td></tr>
	<tr>
		<td colspan="2">The absolute Path of this page</td>
		<td colspan="7" nowrap="true"><div id="FullPathShow"><cfoutput>#application.SLCMS.Paths_Common.ContentRootURL##theURLPathToHere#</cfoutput><cfif DispMode eq "EditPage"><cfoutput>#dURLName#</cfoutput></cfif></div></td></tr>
	<tr>	
		<td colspan="9"><hr></td></tr>
	<tr>
		<td colspan="2">Does this page have content?</td>
		<td colspan="7">
			<input type="radio" name="HasContent" id="HasContentOn" value="1"<cfif dHasContent> checked=checked</cfif><!--- onclick="clickContentOn()"--->> Yes | No 
			<input type="radio" name="HasContent" id="HasContentOff" value="0"<cfif not dHasContent> checked=checked</cfif><!--- onclick="clickContentOff()"--->>
		</td></tr>
	<tr>
		<td colspan="2">Does this page have sub pages (pages below it)?</td>
		<td colspan="7">
			<input type="radio" name="IsParent" id="IsParentOn" value="1"<cfif dIsParent> checked=checked</cfif><!--- onclick="clickSubsOn()"--->> Yes | No 
			<input type="radio" name="IsParent" id="IsParentOff" value="0"<cfif not dIsParent> checked=checked</cfif><!--- onclick="clickSubsOff()"--->>
		</td></tr>
	<cfif DispMode eq "EditPage">
	<tr>
		<td colspan="2"><span id="SubWarnLabel">If page has no content and it has pages below<br>then choose page to display instead of this page</span></td>
		<td colspan="7">
			<cfif getChildren.RecordCount>
				<span id="SubWarnMsg">
				<select name="DefaultPage">
					<cfoutput query="getChildren">
						<option value="#DocID#"<cfif DocID eq dDocID> SELECTED</cfif>>#NavName#</option>
					</cfoutput>
				</select>
				</span>
			<cfelse>	
				<span id="SubWarnMsg" name="SubWarnMsg">No Pages below to choose from<br>You must create a page or pages and return to here to select the displayed page</span>
				<input type="hidden" name="DefaultPage" value="<cfoutput>#dDocID#</cfoutput>">
			</cfif>
			</td></tr>
	<cfelse>
		<input type="hidden" name="DefaultPage" value="<cfoutput>#dDocID#</cfoutput>">
		<tr>	
			<td colspan="9"><span id="SubWarnLabel"></span><span id="SubWarnMsg" name="SubWarnMsg">You must create a page or pages below this new page and return to here to select the default page</span></td></tr>
	</cfif>
	<tr>
		<td colspan="2">
			<cfif dIsHomePage>
				This page is the Home Page for the <cfif session.SLCMS.Currents.Admin.PageStructure.CurrentSubSiteID neq 0>Sub</cfif>Site
			<cfelse>
				Make this page the Home Page for the <cfif session.SLCMS.Currents.Admin.PageStructure.CurrentSubSiteID neq 0>Sub<cfelse>whole web </cfif>Site?
			</cfif>
		</td>
		<td colspan="7">
			<cfif dIsHomePage>
				&nbsp;&nbsp;&nbsp;<strong>Home Page</strong>
				<input type="hidden" name="IsHomePage" value="1">
			<cfelse>
				<input type="radio" name="IsHomePage" value="1"> Yes | No 
				<input type="radio" name="IsHomePage" value="0" checked=checked>
			</cfif>
		</td></tr>
	<cfif request.SLCMS.PortalAllowed and not dIsHomePage>
	<tr>
		<td colspan="2">
			<cfif SubSiteParentage.IsParentToSubSite>
				This page is the Home Page for a<cfif session.SLCMS.Currents.Admin.PageStructure.CurrentSubSiteID neq 0>nother</cfif> subSite
			<cfelse>
				Make this page the Home Page for a<cfif session.SLCMS.Currents.Admin.PageStructure.CurrentSubSiteID neq 0>nother</cfif> subSite?
			</cfif>
		</td>
		<td colspan="7">
			<select name="SubSiteParent">
				<option value=""<cfif SubSiteParentage.IsParentToSubSiteID eq ""> SELECTED</cfif>>No</option><cfoutput>
				<cfloop list="#SubSiteParentage.SubSiteList#" index="thisSubSite">
					<option value="#thisSubSite#"<cfif thisSubSite eq SubSiteParentage.IsParentToSubSiteID> SELECTED</cfif>>#SubSiteParentage.SubSiteData["subSite_#thisSubSite#"].SubSiteFriendlyName#</option>
				</cfloop></cfoutput>
			</select>
		</td></tr>
	</cfif>
	<tr>
		<td colspan="9"><hr></td></tr>
	<cfif not application.SLCMS.Core.SLCMS_Utility.DoPagesHaveTemplatesOnly()>
		<tr>
			<td colspan="2">Page Type</td>
			<td colspan="7">
				<select name="PageType">
					<cfoutput query="getDocTypes">
						<option value="#DocType#"<cfif DocType eq dDocType> SELECTED</cfif>>#DocDesc#</option>
					</cfoutput>
				</select>
				</td></tr>
	<cfelse>
		<input type="hidden" name="PageType" value="2" />
	</cfif>
	<cfset bFoundMatchingSelector = False />
	<cfif thePageTemplateCount gt 0>
	<tr>
		<td colspan="2">Choose Template name:
		</td>
		<td colspan="7">
			<select name="param1a" size="1">
				<cfloop index="thisTemplate" from="1" to="#ArrayLen(PageTemplateArray)#">
					<cfif PageTemplateArray[thisTemplate][1] eq dparam1>
						<cfset bFoundMatchingSelector = True />
					</cfif>
					<cfoutput>
					<option value="#PageTemplateArray[thisTemplate][1]#"<cfif PageTemplateArray[thisTemplate][1] eq dparam1> SELECTED</cfif>>#PageTemplateArray[thisTemplate][2]#</option>
					</cfoutput>
				</cfloop>
				<option value=""<cfif DispMode eq "AddPage" or not bFoundMatchingSelector> selected</cfif>>No template selected yet</option>
			</select>
		</td></tr>
	</cfif>
	<cfif not application.SLCMS.Core.SLCMS_Utility.DoPagesHaveTemplatesOnly()>
	<cfif getIncludeFolders.RecordCount>
	<tr>
		<td colspan="2">Choose Include File Name:</td>
		<td colspan="7">
			<select name="param1a" size="1">
				<option value=""<cfif DispMode eq "AddPage"> selected</cfif>>Not an include</option>
					<cfloop index="thisInclude" from="1" to="#ArrayLen(IncludeArray)#">
					<cfif IncludeArray[thisInclude] eq dparam1>
						<cfset bFoundMatchingSelector = True />
					</cfif>
					<cfoutput>
					<option value="#IncludeArray[thisInclude]#"<cfif IncludeArray[thisInclude] eq dparam1> Selected</cfif>>#IncludeArray[thisInclude]#</option>
					</cfoutput>
				</cfloop>
			</select>
		</td></tr>
	</cfif>
	<tr>
		<td colspan="2">If not a Template or Include File enter File name or Tag name: <br>(This is Param1)</td>
		<td colspan="7"><input type="text" name="Param1b" value=<cfoutput>"<cfif not bFoundMatchingSelector>#dparam1#</cfif>"</cfoutput> size="40" maxlength="50"></td></tr>
		<tr>
			<td colspan="9"><hr></td></tr>
		<tr>
			<td colspan="9"><u><strong>Optional entries:</strong></u></td></tr>
	</cfif>
	<!--- Now the page content display type --->
	<tr id="ContentType1">
		<td colspan="2" rowspan="2">
			Content Type
			<cfif not application.SLCMS.Core.SLCMS_Utility.DoPagesHaveTemplatesOnly()>
				<br>(Use this with Templates or Included pages)
			</cfif>
			</td>
		<td colspan="6" rowspan="2">
			<cfset bFoundMatchingSelector = False />
			<cfloop from="1" to="#ArrayLen(theBaseDisplayTypeArray)#" index="thisDisplayType">
			</cfloop>
			<select name="Param2a" id="DisplayTypeSel">
				<cfloop from="1" to="#ArrayLen(theBaseDisplayTypeArray)#" index="thisDisplayType">
					<!--- make a nice format for the options --->
					<cfif theBaseDisplayTypeArray[thisDisplayType][1] neq "Core">	
						<cfset dValue = theBaseDisplayTypeArray[thisDisplayType][1] & "," & theBaseDisplayTypeArray[thisDisplayType][2] /> />
						<cfset dOption = theBaseDisplayTypeArray[thisDisplayType][4] />	<!--- always show the friendly name --->
						<cfif theBaseDisplayTypeArray[thisDisplayType][5] eq True>	<!--- and add in the display type if there is more than one --->
							<cfset dOption = dOption & " | " & theBaseDisplayTypeArray[thisDisplayType][2] />
						</cfif>
					<cfelse>	<!--- default to a core display type --->
						<cfset dValue = "Core,#theBaseDisplayTypeArray[thisDisplayType][2]#" />
						<cfset dOption = theBaseDisplayTypeArray[thisDisplayType][3] />
					</cfif>
					<cfif dValue eq dparam2>	<!--- a flag to show if we need to fill the text box for unknown param2 value --->
						<cfset bFoundMatchingSelector = True />
						<cfset selectstring = ' selected="selected"' />
						<cfset dOriginalOption = dOption />
					<cfelseif ListLen(dValue) gt 1 and ListRest(dValue) eq dparam2>	<!--- code to handle legacy stuff that did not have "core" as the first item --->
						<cfset bFoundMatchingSelector = True />
						<cfset selectstring = ' selected="selected"' />
						<cfset dOriginalOption = dOption />
					<cfelse>
						<cfset selectstring = '' />
					</cfif>
					<cfoutput>
					<option value="#dValue#"#selectstring#>#dOption#</option>
          </cfoutput>
				</cfloop>
				<cfif not bFoundMatchingSelector>
					<!--- nothing matched so probably the initial add or could be that a module is unavailable so show and select the choose option --->
					<option value="Core,Standard" selected="selected"> -- Make a Selection -- </option>
				<cfelse>
					<!--- we did have something there so tell the js so that we can show it --->
					<cfoutput>
					<script language="JavaScript" type="text/javascript">
						theOriginalSelectionHintText = '#dOriginalOption#';
					</script>
          </cfoutput>
				</cfif>
			</select>
		</td>
		<td colspan="1">	<!--- this will be the "what we have selected" message --->
			<cfif DispMode neq "AddPage">
				<span id="TheOriginalHint" class="HintText">Original Content Type was:</span>	<!--- this can get overwritten by the AJAX return --->
			</cfif>
		</td>
		</tr>
	<tr id="ContentType2">
		<td colspan="1">	<!--- this will be the the actual selection --->
			<span id="TheOriginalItems" class="HintText"><cfoutput>#dOriginalOption#</cfoutput></span>	<!--- this probably won't get overwritten by the AJAX return --->
		</td>
		</tr>
	<cfif not application.SLCMS.Core.SLCMS_Utility.DoPagesHaveTemplatesOnly()>
		<tr>
			<td colspan="2">If no Page Display Type selection made above enter Parameter: <br>(This is Param2)</td>
			<td colspan="7"><input type="text" name="Param2b" value=<cfoutput>"<cfif not bFoundMatchingSelector>#dparam2#</cfif>"</cfoutput> size="40" maxlength="50"></td>
			</tr>
	</cfif>
	<!--- now we have a bunch of various form inputs for different types of core and module params using params 3 & 4 --->
	<!--- the visibility is controlled by jquery and the selections for param2, ie the Display Type --->
	<!--- this first one is a dummy as we always need a param3 field. It is blank for display types that don't need a param3 --->
	<tr id="NoParam3Needed"><td colspan="2"></td><td colspan="7"><input type="hidden" id="NoParam3NeededInput" name="Param3" value=""><input type="hidden" id="NoParam4NeededInput" name="Param4" value=""></td></tr>
	<!--- this is where param3 is used for entry, normally when not using a template or manual config --->
	<tr id="CoreNothingSelectedP3">
		<td colspan="2">
			The optional display type to use:
			<cfif not application.SLCMS.Core.SLCMS_Utility.DoPagesHaveTemplatesOnly()>
				<br>(This is Param3)
			</cfif>
			</td>
		<td colspan="7">
			<input type="text" id="CoreNothingSelectedInputP3" name="Param3" value=<cfoutput>"#dparam3#"</cfoutput> size="40" maxlength="50">
		</td></tr>
	<tr id="CoreNothingSelectedP4">
		<td colspan="2">
			The optional display type to use:
			<cfif not application.SLCMS.Core.SLCMS_Utility.DoPagesHaveTemplatesOnly()>
				<br>(This is Param4)
			</cfif>
			</td>
		<td colspan="7">
			<input type="text" id="CoreNothingSelectedInputP4" name="Param4" value=<cfoutput>"#dparam4#"</cfoutput> size="40" maxlength="50">
		</td></tr>
	<!--- for when we need a dropdown select box --->
	<tr id="CoreDropDownSelectBox">
		<td colspan="2">
			Select:	<!--- this can get overwritten by the AJAX return --->
			<input type="hidden" id="CoreSelectedInputP4" name="Param4" value=<cfoutput>"#dparam4#"</cfoutput> size="40" maxlength="50">
			</td>
		<td colspan="7">
			<select name="param3" size="1" id="CoreDropDownSelectBoxInput">
				<option value="">--Select--</option><!--- this will get filled by the AJAX return --->
			</select>
		</td></tr>
	<!--- specific for selecting a form to display. core module --->
	<cfoutput>
	<tr id="CoreFormSelected">
		<td colspan="2">
			The form to use:
			<cfif not application.SLCMS.Core.SLCMS_Utility.DoPagesHaveTemplatesOnly()>
				<br>(This is Param3)
			</cfif>
			</td>
		<td colspan="7">
			<cfset bFoundMatchingSelector = False />
			<select name="param3" size="1" id="CoreFormSelectedInput">
				<cfloop index="thisTemplate" from="1" to="#ArrayLen(FormTemplateArray)#">
					<cfif FormTemplateArray[thisTemplate][2] eq dparam3>
						<cfset bFoundMatchingSelector = True />
					</cfif>
					<cfoutput>
					<option value="#FormTemplateArray[thisTemplate][2]#"<cfif FormTemplateArray[thisTemplate][2] eq dparam3> SELECTED</cfif>>#FormTemplateArray[thisTemplate][2]#</option>
					</cfoutput>
				</cfloop>
				<option value=""<cfif DispMode eq "AddPage" or not bFoundMatchingSelector> selected</cfif>>--Select Form--</option>
			</select>
		</td></tr>
	<!--- and this one is for a module, the selection takes place in a pop up, here shows the result and feeds back params 3 & 4 to be saved --->
	<tr id="ModuleSelected1">
		<td colspan="2" rowspan="2">
			<span id="ModuleSelectedPrompt" class="ModuleSelectedPromptText">#dModuleFriendlyName#:	</span>	<!--- this will get overwritten by the AJAX return --->
			<span class="HintText"> - Use the tool to the right to change what to show
			<br>
			(<span id="ModuleSelectedHint">#dModuleSelectedHint#)</span>)	<!--- as will this --->
			</span>
			</td>
		<td colspan="6" rowspan="2">	<!--- a whole mess of things, only one of which should be shown at any time --->
			<a href="#dPopURL#" id="PopModuleSelector" class="PopModuleSelectorLink">Change Selection</a>	<!--- pop up with module selection code within --->
			<select name="param3" size="1" id="ModuleDropDownSelectBoxInput">
				#dDropOptions#<!--- this will get filled by the AJAX return ---><!--- <option value="">--Select--</option>, etc --->
			</select>
			<input type="hidden" id="ModuleSelectedInputP3" name="Param3" value="#dparam3#" size="40" maxlength="50">
			<input type="hidden" id="ModuleSelectedInputP4" name="Param4" value="#dparam4#" size="40" maxlength="50">
		</td>
		<td colspan="1">	<!--- this will be the "what we have selected" message --->
			<span id="WhatSelectedHint" class="HintText">current selection is:</span>	<!--- this will get overwritten by the AJAX return --->
		</td>
		</tr>
	<tr id="ModuleSelected2">
		<td colspan="1">	<!--- this will be the the actual selection --->
			<span id="TheSelectedItems" class="HintText"></span>	<!--- this will get overwritten by the AJAX return --->
		</td>
		</tr>
	<!--- end of jQuery-driven display sections --->
	<tr>
		<td colspan="9"><hr></td></tr>
	<tr>
		<td colspan="2"><!--- <input type="submit" name="Cancel" value="Cancel/Back"> ---></td>
		<td colspan="7"><input type="submit" name="AddBG" value="<cfif workmode is 'AddPage'>Create New Page<cfelse>Save Changes</cfif>" onClick="return checkEmpty('Page')"></td>
		</tr>
	</table>
	#endFormTag()#
	</cfoutput>
	<!--- 
	</form>
	 --->
</cfif>	<!--- end of displaymode specific --->
<cfif DispMode eq "">
	<!---  showing the main listing --->
		<!--- first the expand/collapse tools to aid seeing the tree --->
		<table border="0" cellpadding="0" cellspacing="0" class="worktable">
		<tr>
			<td>
			<cfif ArrayLen(session.SLCMS.pageAdmin.NavState.theCurrentNavArray)>
			<div id="ExpanderLinksWrapper">
				<table width="140" border="0" cellpadding="4" cellspacing="0"><cfoutput>
	      <tr>
	        <td class="ExpandTableTopRow">
						#linkTo(text="Collapse to level 1", controller="slcms.adminPages", action="index", params="#PageContextFlags.ReturnLinkParams#&amp;mode=CollapseToTop&amp;CurrentPage=0")#
	        </td>
	      </tr>
	      <tr>
	        <td class="ExpandTableRowColour2">
						#linkTo(text="Expand to level 2", controller="slcms.adminPages", action="index", params="#PageContextFlags.ReturnLinkParams#&amp;mode=ExpandtoTwo&amp;CurrentPage=0")#
	        </td>
	      </tr>
	      <tr>
	        <td class="ExpandTableRowColour3">
						#linkTo(text="Expand to level 3", controller="slcms.adminPages", action="index", params="#PageContextFlags.ReturnLinkParams#&amp;mode=ExpandtoThree&amp;CurrentPage=0")#
	        </td>
	      </tr></cfoutput>
		    </table>
			</div>
			</cfif>
			</td>
			<td>
			<cfif request.SLCMS.PortalAllowed>
				<cfif ListLen(theAllowedSubsiteList) gt 1>
					<div id="SubSiteLinksWrapper">
						<cfset lcntr = 0 />
						<p>This website is a portal. You can manage the page structure in the following subsites:</p>
						<p>
						<cfloop list="#theAllowedSubsiteList#" index="thisSubSite">
							<span class="<cfif lcntr eq 0>LeftEnd<cfelseif lcntr mod 2 eq 1>OddNumbered<cfelse>EvenNumbered</cfif>">
							<cfset thisSubsiteDetails = application.SLCMS.Core.PortalControl.GetSubSite(thisSubSite).data />
							<cfoutput>
							<cfif thisSubsiteDetails.SubSiteID eq 0>
								<cfif thisSubsiteDetails.SubSiteFriendlyName eq "Top">
									The <a href="Admin_PageStructure.cfm?mode=ChangeSubSite&amp;NewSubSiteID=0">Top Site</a>
								<cfelse>
									The Top Site (called &quot;<a href="Admin_PageStructure.cfm?#PageContextFlags.ReturnLinkParams#&amp;mode=ChangeSubSite&amp;NewSubSiteID=0">#thisSubsiteDetails.SubSiteFriendlyName#</a>&quot)
								</cfif>
							<cfelse>
								Site: &quot;<a href="Admin_PageStructure.cfm?#PageContextFlags.ReturnLinkParams#&amp;mode=ChangeSubSite&amp;NewSubSiteID=#thisSubsiteDetails.SubSiteID#">#thisSubsiteDetails.SubSiteFriendlyName#</a>&quot
							</cfif>
							</cfoutput> 
							</span>
							<cfset lcntr = lcntr+1 />
						</cfloop>
					</p></div>
					<div>You are currently looking at site: <span class="majorheading"><cfoutput>#session.SLCMS.Currents.Admin.PageStructure.CurrentSubSiteFriendlyName#</cfoutput></span>
					</div>				
				<cfelse>
					<p>This website is a portal.</p>
					<p>You can manage the page structure in the site: <span class="majorheading"><cfoutput>#session.SLCMS.Currents.Admin.PageStructure.CurrentSubSiteFriendlyName#</cfoutput></span></p>
				</cfif>	<!--- end: one of more subsites --->
			</cfif>	<!--- end: portal allowed --->
			</td>
		</tr>
		<tr>
		<td colspan="2">
		<cfif ArrayLen(session.SLCMS.pageAdmin.NavState.theCurrentNavArray)>
			<!--- and then the table of pages and their state/controls --->
			<table border="0" cellpadding="3" cellspacing="0" class="worktable">
			<tr>
				<td colspan="1" rowspan="2" class="WorkTableTopRow" align="center"><u>Page Name</u><br><span style="font-size:0.8em;">* is Home Page</span></td>
				<td colspan="1" rowspan="2" class="WorkTableTopRow"><u>Menu<br>Level</u></td>
				<td colspan="1" rowspan="2" align="center" class="WorkTableTopRow">&nbsp;</td>
				<cfif application.SLCMS.Core.UserPermissions.IsAdmin(SubSiteID=session.SLCMS.Currents.Admin.PageStructure.CurrentSubSiteID)>
					<td colspan="3" align="center" class="WorkTableTopRow"><u>Page Visibility in Website</u></td>
				<cfelse>
					<td colspan="2" align="center" class="WorkTableTopRow"><u>Page Visibility in Website</u></td>
				</cfif>
				<td colspan="2" rowspan="2" align="center" class="WorkTableTopRow"><u>Move</u></td>
				<td colspan="1" rowspan="1" align="center" class="WorkTableTopRowRHCol">
					Add a Page
				</td>
			</tr>
			<tr>
				<td colspan="1" class="WorkTable2ndRow"><u>as menu Item</u></td>
				<td colspan="1" class="WorkTable2ndRow"><u>as Web Page</u></td>
				<cfif application.SLCMS.Core.UserPermissions.IsAdmin(SubSiteID=session.SLCMS.Currents.Admin.PageStructure.CurrentSubSiteID)>
					<td colspan="1" class="WorkTable2ndRow"><u>Remove</u></td>
				<cfelse>
					<td colspan="1" class="WorkTable2ndRow"></td>
				</cfif>
				<td colspan="1" class="WorkTableTopRowRHCol">
					<!--- 
					<a href="Admin_PageStructure.cfm?mode=addPage&amp;CurrentPage=0">Add a Page at Top Level (Level 1)</a>
 					--->
				<cfoutput>#linkTo(text="Add at Top Level", controller="slcms.adminPages", action="index", params="#PageContextFlags.ReturnLinkParams#&amp;mode=addPage&amp;CurrentPage=0")#</cfoutput>
			</td>
			</tr>
				<cfset session.SLCMS.pageAdmin.NavState.dispRowCounter = 0 />
				<cfset session.SLCMS.pageAdmin.NavState.displayedRowArray = ArrayNew(2) />
				<!--- Show all the rows in the display table, this is rentrant --->
				<cfoutput>#loopNavPage(session.SLCMS.pageAdmin.NavState.theCurrentNavArray)#</cfoutput>
			</table>	<!--- end: worktable --->
		<cfelse>
			<p>
			<strong>The site has no pages in it yet.</strong>
			</p><p>
			<cfoutput>#linkTo(text="Add a Page at Top Level (Level 1)", controller="slcms.adminPages", action="index", params="#PageContextFlags.ReturnLinkParams#&amp;mode=addPage&amp;CurrentPage=0")#</cfoutput>
			<!--- 
			<a href="Admin_PageStructure.cfm?mode=addPage&amp;CurrentPage=0"></a>
			 --->
			</p>
		</cfif>
		</td></tr>
	</table>
</cfif>	<!--- end: display modes --->
</cfif>	<!--- end: loggedIn check --->

<!--- 
<cfdump var="#application#" expand="false" label="application">
<cfdump var="#session#" expand="false" label="session scope">
 --->


