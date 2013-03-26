<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<!--- this is a sample SLCMS template for a 2 column flexible page with the left-hand column fixed width --->
<cfimport taglib="/SLCMS/core/templateTags/Content/" prefix="slcms">	<!--- grab the CMS functions to display things --->
<html>
<head>
	<title>Sample SLCMS Template - Two Column, Left Fixed</title>
	<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
	<meta http-equiv="PRAGMA" content="NO-CACHE" />
	<link rel="stylesheet" type="text/css" href="<slcms:insertCurrentPageTemplateSetControlURLpath/>reset.css">
	<link rel="stylesheet" type="text/css" href="<slcms:insertCurrentPageTemplateSetControlURLpath/>2col-flexible-with-header-LHcolFixed_layout.css">
	<link rel="stylesheet" type="text/css" href="<slcms:insertCurrentPageTemplateSetControlURLpath/>Common_Presentation_NonEditable.css">
	<link rel="stylesheet" type="text/css" href="<slcms:insertCurrentPageTemplateSetControlURLpath/>Common_Presentation_EditableAreas.css">
</head>
<slcms:SetEditorStyleSheet Stylesheet="Common_Presentation_EditableAreas.css" />
<body>
<!-- Header -->
<div id="hdr">
	<div id="hdr-Logo">
	<a href="<slcms:insertSiteBaseURL/>" title="Go to home page"><img src="<slcms:insertCurrentPageTemplateSetGraphicsURLpath/>slcmsLogo2.gif" alt="" border="0" width="200" height="70" /></a>
	</div>
	<div id="hdrRightHand">
	Link 1 | Link 2 | Link 3 | Link 4
	</div>
	<div id="hdrContent">Sample SLCMS Page Templates</div>
</div>
<!-- left column -->
<div id="lh-col"><br />
	<!--- this is the function to display the navigation --->
	<slcms:displayNavigation NavName="LHMenu" LevelToStartAt="2" LevelsToShow="1" />
	<!---
	<slcms:displayNavigation NavName="VerticalMenu_Sample_3Level" />
	--->
</div>
<!-- end of left column -->
<!-- right column -->
<div id="rh-col">
	<!-- 
	<p>words at the top just to show we can have non-editable content outside the content container.</p>
	 -->
	<!--- this is the function to display the content --->
	<!--- tag uses either id or name attribute, not both. 
				id is the container number on the page: 1,2,3, etc 
				(that means you can have several containers on one page) and 
				"name"" is a named container that has the same content on every page --->
	<slcms:displayContent id="1" name="" EditorStyleSheet="Common_Presentation_EditableAreas.css" />	
</div>
<!-- end of right column -->
<div id="footer">
	<div id="footerPowered">
	<a href="<slcms:insertSiteBaseURL/>content.cfm/login" title="Login">Login</a>
	<a href="http://www.slcms.net" title="Powered by SLCMS">Powered by SLCMS</a>
	</div>
  <p>Copyright &copy; <slcms:insertThisYear /> </p>
</div>

</body>
</html>
