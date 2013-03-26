<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<!--- this is a sample SLCMS template for a 2 column flexible page with the left-hand column fixed width --->
<cfimport taglib="/SLCMS/core/templateTags/Content/" prefix="slcms">	<!--- grab the CMS functions to display things --->
<slcms:SetEditorStyleSheet Stylesheet="Common_Presentation_EditableAreas.css" IncludeInPageStyling="yes" />
<html>
<head>
	<title>Sample SLCMS Template - Two Column, Left Fixed</title>
	<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
	<meta http-equiv="PRAGMA" content="NO-CACHE" />
	<link rel="stylesheet" type="text/css" href="<slcms:insertCurrentPageTemplateSetControlURLpath/>reset.css">
	<link rel="stylesheet" type="text/css" href="<slcms:insertCurrentPageTemplateSetControlURLpath/>2col-flexible-with-header-LHcolFixed_layout.css">
	<link rel="stylesheet" type="text/css" href="<slcms:insertCurrentPageTemplateSetControlURLpath/>Common_Presentation_NonEditable.css">
	<!---
	<link rel="stylesheet" type="text/css" href="<slcms:insertCurrentPageTemplateSetControlURLpath/>Common_Presentation_EditableAreas.css">
	--->
	<cfoutput>
    	
		<script src='#application.Paths_Common.jQueryJsPath_Abs#' type='text/javascript'></script>
		
    </cfoutput>
	<!---
	<slcms:UsejQuery />
	--->
</head>

<body>
<!---	
	&nbsp;<cfdump var="#application.core.pagestructure.getSingleDocStructure(DocID="92", SubSiteID=request.pageparams.SubSiteID)#" >
--->	
<!-- Header -->
<div id="hdr">
	<div id="hdr-Logo">
	<a href="<slcms:insertSiteBaseURL/>" title="Go to home page"><img src="<slcms:insertCurrentPageTemplateSetGraphicsURLpath/>slcmsLogo2.gif" alt="" border="0" width="200" height="70" /></a>
	</div>
<!---
	<div id="hdrRightHand">
		<slcms:displayPopForm_SignIn />
	</div>
--->
	<!---
	<div>
		<slcms:displayForm_SignIn PopDirection="Down,Right" />
	</div>
	--->

	<div id="hdrContent">Sample SLCMS Page Templates</div>
</div>
<!-- left column -->
<div>
<div id="lh-col"><br />
	<!--- this is the function to display the navigation --->
	<slcms:displayNavigation NavName="VerticalMenu_Sample_3Level" FolderToStartAt="92" LevelToStartAt="2" LevelsToShow="1" />
</div>
<!-- end of left column -->
<!-- right column -->
<div id="rh-col">
	<p>This page is currently being used to test new tags.</p>
	
	<p>Here is the GoogleMap tag</p>
	<slcms:displayGoogleMap Latitude="-34" Longitude="151" zoom="10" MarkerTitleText="test" />
	
	<p>
		Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec dapibus interdum leo in consectetur. Aenean scelerisque dapibus nibh sed volutpat. Vivamus at diam ut dui dignissim sollicitudin? Phasellus laoreet, erat quis iaculis varius, magna urna hendrerit mi, non aliquam est nisl id nulla. Donec convallis auctor eros. Ut sapien nisi, lobortis at posuere vel, eleifend sit amet tortor. Etiam dapibus, sapien ut vestibulum porta, odio nisi porttitor magna, ut cursus magna lacus et arcu.
Donec orci est, pretium non elementum id, dictum at lorem. Integer ac augue dolor; in imperdiet sem. Integer fermentum convallis lorem; eget porta augue vehicula et. Sed a felis at arcu molestie ultricies. Fusce venenatis, neque sit amet tempus imperdiet, tortor velit blandit diam, eget varius felis sem eget leo! Praesent quis mi at massa fringilla malesuada quis id tortor? Quisque semper placerat ipsum sit amet tempus!
	</p>
	<!--- this is the function to display the content --->
	<!--- tag uses either id or name attribute, not both. 
				id is the container number on the page: 1,2,3, etc 
				(that means you can have several containers on one page) and 
				"name"" is a named container that has the same content on every page --->
		
	<slcms:displayContent id="1" name="" EditorStyleSheet="Common_Presentation_EditableAreas.css" />	
	
</div>
<!-- end of right column -->
<div id="footer" style="clear:both;">
<!---
	<div>
		<slcms:displayPopForm_SignIn PopDirection="Up,Right" />
	</div>
--->
	<div id="footerPowered">
<!---		
	<a href="<slcms:insertSiteBaseURL/>content.cfm/login" title="Login">Login</a>
--->	
	<a href="http://www.slcms.net" title="Powered by SLCMS">Powered by SLCMS</a>
	</div>
  <p>Copyright &copy; <slcms:insertThisYear /> </p>

	<div id="hdrRightHand">
		<slcms:displayPopForm_SignIn PopDirection="Up,Left" />
	</div>

</div>
</div>
<!---
<cfdump var="#cgi#" expand="false" label="cgi scope">
--->
<!---
<cfabort>
--->

</body>
</html>
