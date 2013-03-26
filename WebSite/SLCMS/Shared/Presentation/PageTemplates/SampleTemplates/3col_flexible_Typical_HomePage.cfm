<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<!--- this is a sample SLCMS template for a 3 column typical home page --->
<cfimport taglib="/SLCMS/core/templateTags/Content/" prefix="slcms">	<!--- grab the CMS functions to display things --->
<html>
<head>
	<title><slcms:InsertPageTitle /> :: <slcms:InsertSiteName /></title>
	<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
	<meta http-equiv="PRAGMA" content="NO-CACHE" />
	<link rel="stylesheet" type="text/css" href="<slcms:insertCurrentPageTemplateSetControlURLpath/>reset.css">
	<link rel="stylesheet" type="text/css" href="<slcms:insertCurrentPageTemplateSetControlURLpath/>3col_flexible_Typical_HomePage_Layout.css">
	<link rel="stylesheet" type="text/css" href="<slcms:insertCurrentPageTemplateSetControlURLpath/>Common_Presentation_NonEditable.css">
	<link rel="stylesheet" type="text/css" href="<slcms:insertCurrentPageTemplateSetControlURLpath/>Common_Presentation_EditableAreas.css">
	<link rel="stylesheet" type="text/css" href="<slcms:insertCurrentPageTemplateSetControlURLpath/>SignInForm_Defaults.css">

	<!--- temp for testing until we get the "UsejQuery" tag --->
	<cfset thisTag.Ret = application.SLCMS.Core.ContentCFMfunctions.AddHeadContent(Place="Top", Path="#application.SLCMS.Paths_Common.jQueryJsPath_Abs#") />	<!--- load in jQuery --->
		<!--- 
		<cfoutput>
		<script src='#application.SLCMS.Paths_Common.RootURL##application.SLCMS.Paths_Common.jQueryPath_Rel#' type='text/javascript'></script>
		</cfoutput>
 		 --->
</head>

<body>
<!-- Header -->
<div id="hdr">
	<div id="hdr-Logo">
	<a href="<slcms:insertSiteBaseURL/>" title="Go to home page"><img src="<slcms:insertCurrentPageTemplateSetGraphicsURLpath/>slcmsLogo2.gif" alt="" border="0" width="200" height="70" /></a>
	</div>
	<div id="hdrRightHand">
		<slcms:displayPopForm_SignIn />
		
		<slcms:displayPopForm_Search />
		
		<!---
		<slcms:displayPopForm_Search buttontext="GO!" PodStyle="Yes" />
		<slcms:displayForm_SearchContent FormName="SiteSearch" class_inputfield="TopSearchField" class_button="SrchButton" class_fieldset="SrchSet" />
		--->
	</div>
	<div id="hdrContent">
		<!--- a couple of options: an automatic site and page name; or some simple html. Here it is automatic --->
		<slcms:InsertSiteName /> - <slcms:InsertPageTitle />
		<!--- 
		<h1>Sample SLCMS Page Templates</h1>
		 --->
	</div>
</div>

<div id="container">
	<div id="leftColumn_Wrapper">
		<div id="leftColumn_Upper"><div class="column-in">
			<!--- this is the function to display the navigation --->
			<slcms:displayNavigation NavName="VerticalMenu_Sample_1Level" />
		</div></div>
		<div id="leftColumn_Lower"> 
			<h4>Something relevant goes here</h4>
		</div>
	</div>
	
	<div id="rightColumn"><div class="column-in">
		<h4>Right Col</h4>
		<p lang="en">Lorem ipsum dolor sit amet, consectetuer adipiscing elit. 
		Aenean neque. Sed interdum pede a pede vestibulum faucibus. Morbi ullamcorper sem sit amet nisi. 
		Donec laoreet. Nunc justo. Sed ac lorem. Aliquam ligula neque, consequat dictum, egestas sed, 
		tincidunt vel, felis. Sed at sapien. Morbi ac pede. Nullam malesuada purus sed libero. 
		Duis tortor. Fusce egestas scelerisque lectus.
		</p>
	</div></div>

	<div id="middleColumn"><div class="column-in">
			<!--- this is the function to display a container which is just editable content --->
			<!--- tag uses either id or name attribute, not both. 
						id is the container number on the page: 1,2,3, etc 
						(that means you can have several containers on one page) and 
						"name"" is a named container that has the same content on every page --->
			<slcms:displayContainer id="1" name="" EditorStyleSheet="Common_Presentation_EditableAreas.css" />	
	</div></div>
	<div class="cleaner">&nbsp;</div>
</div>
<div id="footer">
	<div id="footerPowered">
	<a href="http://www.slcms.net" title="Powered by SLCMS">Powered by SLCMS</a>
	</div>
  <p>Copyright &copy; <slcms:insertThisYear /> by someone or other, probably me.</p>
</div>

</body>
</html>