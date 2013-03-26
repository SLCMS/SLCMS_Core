<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<!--- base html for admin pages, this layout will not be called for ajax responses --->
<html>
<head><cfoutput>
	<title>#PageContextFlags.HeadTitleString#</title>
	<script src='#application.SLCMS.Paths_Common.jQueryJsPath_Abs#' type='text/javascript'></script>
	<script src='#application.SLCMS.Paths_Common.jQueryUIPath_Abs#' type='text/javascript'></script>
	<script src="#application.SLCMS.Paths_Common.RootURL##application.SLCMS.Paths_Common.ThirdPartyPath_Rel#jquery/rails.js" type="text/javascript"></script>
	<script src="#application.SLCMS.Paths_Common.RootURL##application.SLCMS.Paths_Common.ThirdPartyPath_Rel#fancybox/jquery.fancybox-1.3.4.pack.js" type="text/javascript"></script>
	<script src="#application.SLCMS.Paths_Common.RootURL##application.SLCMS.Paths_Common.ThirdPartyPath_Rel#jquery/jquery.easing-1.3.pack.js" type="text/javascript"></script>
	<script src="#application.SLCMS.Paths_Common.RootURL##application.SLCMS.Paths_Common.ThirdPartyPath_Rel#fancybox/DD_roundies_0.0.2a-min.js" type="text/javascript"></script>
	<link href="#application.SLCMS.Paths_Admin.adminBackEndWrapperStyleSheet_Abs#" rel="STYLESHEET" type="text/css">
	<link href="#application.SLCMS.Paths_Common.RootURL##application.SLCMS.Paths_Common.ThirdPartyPath_Rel#jquery/UI_Theme_css/start/jquery-ui-1.8.10.custom.css" type="text/css" media="screen" rel="stylesheet" />
	<link href="#application.SLCMS.Paths_Common.RootURL##application.SLCMS.Paths_Common.ThirdPartyPath_Rel#fancybox/jquery.fancybox-1.3.4.css" type="text/css" rel="stylesheet" media="screen" />
</head>
<body class="body">
#includeContent()#
</body>
</html>
</cfoutput>