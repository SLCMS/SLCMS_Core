<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<!--- template for a bare page, very bare --->
<cfimport taglib="/SLCMS/core/templateTags/Content/" prefix="slcms">	<!--- grab the CMS functions to display things --->
<html>
<head>
	<title>Bare Two Column, Table Based SLCMS Template</title>
	<cfoutput>
	<link rel="stylesheet" href="<slcms:insertCurrentPageTemplateSetControlURLpath/>Default_base.css" type="text/css">
	<link rel="stylesheet" href="<slcms:insertCurrentPageTemplateSetControlURLpath/>Default_Forms.css" type="text/css">
	<link rel="stylesheet" href="<slcms:insertSiteBaseURL/>SLCMS/SLCMSstyling/slcms.css" type="text/css">
	</cfoutput>
</head>

<body leftmargin="0" topmargin="0" marginwidth="0" marginheight="0">
<a name="top"></a> 
<table width="80%" border="0" cellspacing="0" cellpadding="0">
	<tr> <!-- header -->
		<td colspan="2" align="center" valign="middle">
		<h2>Bare Two Column, Table Based SLCMS Template</h2>
		</td>
	</tr>
	<tr> <!-- nav and content -->
		<td width="30%" align="left" valign="top">
			<!--- this is the function to display the navigation --->
			<slcms:displayNavigation NavName="LeftHandTopOnly" />
			<p>&nbsp;</p>
			<!--- this is the function to display a login form --->
			<slcms:displayForm_SignIn />
			<!--- 			
			<p><a href="/Admin/AdminHome.cfm" target="_blank">Go to Admin Site (in new window)</a></p>
			 --->			
		</td>
		<td align="left" valign="top">
			<!--- show the path to here --->
			<!--- 
			<p class="breadcrm"><slcms:displaybreadcrumb NavName="BreadTopHorizontal" /></p>
			 --->
			<hr width="90%" size="1">
			<!--- show some content --->
			<slcms:displayContainer id="1" name="" />	
		</td>
	</tr>
</table>
</body>
</html>
