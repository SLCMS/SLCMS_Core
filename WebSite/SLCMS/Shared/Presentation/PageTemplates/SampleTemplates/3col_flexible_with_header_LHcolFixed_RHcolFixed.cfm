<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<!--- this is a sample SLCMS template for a 3 column flexible page with the left and right columns fixed width --->
<cfimport taglib="/SLCMS/core/templateTags/Content/" prefix="slcms">	<!--- grab the CMS functions to display things --->
<html>
<head>
	<title>Sample SLCMS Template - Three Column Flexible, Left &amp; Right Static</title>
	<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
	<meta http-equiv="PRAGMA" content="NO-CACHE" />
	<link rel="stylesheet" type="text/css" href="<slcms:insertCurrentPageTemplateSetControlURLpath/>reset.css">
	<link rel="stylesheet" type="text/css" href="<slcms:insertCurrentPageTemplateSetControlURLpath/>3col-flexible-with-header-LHcolFixed-RHcolFixed_layout.css">
	<link rel="stylesheet" type="text/css" href="<slcms:insertCurrentPageTemplateSetControlURLpath/>Common_Presentation_NonEditable.css">
	<link rel="stylesheet" type="text/css" href="<slcms:insertCurrentPageTemplateSetControlURLpath/>Common_Presentation_EditableAreas.css">
</head>

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

<div id="container">

	<div id="leftColumn"><div class="column-in">
		<!--- this is the function to display the navigation --->
		<slcms:displayNavigation NavName="VerticalMenu_Sample_3Level" />
	</div></div>

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
		<!--- this is the function to display the content --->
		<!--- tag uses either id or name attribute, not both. 
					id is the container number on the page: 1,2,3, etc 
					(that means you can have several containers on one page) and 
					"name"" is a named container that has the same content on every page --->
		<slcms:displayContent id="1" name="" EditorStyleSheet="Common_Presentation_EditableAreas.css" />	
	</div></div>

	<div class="cleaner">&nbsp;</div>

</div>
<div id="footer">
	<div id="footerPowered">
	<a href="<slcms:insertSiteBaseURL/>content.cfm/login" title="Login">Login</a>
	<a href="http://www.slcms.net" title="Powered by SLCMS">Powered by SLCMS</a>
	</div>
  <p>Copyright &copy; <slcms:insertThisYear /> </p>
</div>

</body>
</html>