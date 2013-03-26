<cfsetting enablecfoutputonly="Yes">
<!--- SLCMS Core - base tags to be used in template pages  --->
<!--- &copy; 2012 mort bay communications --->
<!---  --->
<!--- custom tag to display the Signin/Signout form as a popup --->
<!--- 
docs: startParams
docs:	Name: displayPopSignIn
docs:	Type:	Custom Tag 
docs:	Role:	Content Display Tag - Core 
docs:	Hint: displays a pop up style Sign In/Out panel
docs:	Versions: Tag - 1.0.0; Core - 2.2.1+
docs:	<cfparam name="attributes.someParam1" type="string" default="">	an attribute
docs:	<cfparam name="attributes.someParam2" type="string" default="">	another attribute
docs: endParams
docs: 
docs: startAttributes
docs:	name="PopDirection"		type="string" default="Down,Left"	;	defines which way the panel pops. options [Up|Down|Left|Right], 2 needed, hopefully sensible ones :-)
docs:	name="myIntAttribute" type="numeric" default="0"				;	a number, this bit is free form
docs:	name="myBoolAttribute" type="boolean" default="False"		;	flag something, this bit is free form
docs: endAttributes
docs: 
docs: startManual
docs:	A very cut down version of the displayForm_LogIn tag with mosat attributes removed as a specific role, to provide a twitter style sign-in panel
docs: 
docs: Has options to enable it to go in any part of the page, it will pop up the panel to the left or right of the signin icon and above or below
docs: endManual
docs: 
docs: startHistory_Versions
docs: Version 1.0.0.359: 	Base tag
docs: Version 1.0.0.359: 	added something
docs: endHistory_Versions
docs:
docs: startHistory_Coding
docs: cloned:   18th Feb 2012 by Kym K, mbcomms from the displayForm_LogIn tag. V2.2+ from the start
docs: modified: 18th Feb 2012 -  3rd Mar 2012 by Kym K, mbcomms: upgrade to allow for a pop modal style using jQuery
Docs: endHistory_Coding
 --->
<cfif thisTag.executionMode IS "start">
	<cfparam name="attributes.PopDirection" type="string" default="Down,Left">
	<cfparam name="attributes.formname" type="string" default="signin">
	<cfparam name="attributes.formclass" type="string" default="signinform">
	<cfparam name="attributes.ShowGoToAdmin" type="string" default="Yes">
	<cfparam name="attributes.UserName" type="string" default="">
	<cfparam name="attributes.Password" type="string" default="">
	<cfparam name="attributes.LoginFailedMsg" type="string" default="Login failed. Please check your Username and Password.">
	<cfparam name="attributes.class_fieldset" type="string" default="loginFldSet">
	<cfparam name="attributes.class_inputfield" type="string" default="">
	<cfparam name="attributes.class_button" type="string" default="btn">
	<cfparam name="attributes.class_LoggedInMsg" type="string" default="LoggedInMsg">
	<cfparam name="attributes.class_LoginFailedMsg" type="string" default="LoginFailedMsg">

	<cfset thisTag.TagTemplateBasePath = "#application.SLCMS.Paths_Common.CoreTagsSubTemplateURL#SignIn/" />  
	<cfset thisTag.Ret = application.SLCMS.Core.ContentCFMfunctions.AddHeadContent(Place="Bottom", Type="Stylesheet", Path="#thisTag.TagTemplateBasePath#TemplateControl/SignInForm_Defaults.css") />	<!--- load in stylesheet --->

	<cfif application.SLCMS.core.UserPermissions.IsLoggedin() eq False and session.SLCMS.user.security.LoginAttempted>
		<cfset thisTag.theUserName = session.SLCMS.user.security.AttemptedUserName />
		<cfset thisTag.thePassword = session.SLCMS.user.security.AttemptedPassword />
	<cfelse>
		<cfset thisTag.theUserName = trim(attributes.UserName) />
		<cfset thisTag.thePassword = trim(attributes.Password) />
	</cfif>
	<cfif attributes.formname eq "">
		<cfset thisTag.theFormName = "signin" />
	<cfelse>
		<cfset thisTag.theFormName = attributes.formname />
	</cfif>
	<cfif attributes.formclass eq "">
		<cfset thisTag.theFormClass = "signinform" />
	<cfelse>
		<cfset thisTag.theFormClass = attributes.formclass />
	</cfif>
	<cfif ListFindNoCase(attributes.PopDirection, "Left") and ListFindNoCase(attributes.PopDirection, "Down")>
  	<cfset thisTag.thePopClass = "signin_DownLeft" />
  	<cfset thisTag.theSignLinkClassAppend = "Down" />
	<cfelseif ListFindNoCase(attributes.PopDirection, "Left") and ListFindNoCase(attributes.PopDirection, "Up")>
  	<cfset thisTag.thePopClass = "signin_UpLeft" />
  	<cfset thisTag.theSignLinkClassAppend = "Up" />
	<cfelseif ListFindNoCase(attributes.PopDirection, "Right") and ListFindNoCase(attributes.PopDirection, "Down")>
  	<cfset thisTag.thePopClass = "signin_DownRight" />
  	<cfset thisTag.theSignLinkClassAppend = "Down" />
	<cfelseif ListFindNoCase(attributes.PopDirection, "Right") and ListFindNoCase(attributes.PopDirection, "Up")>
  	<cfset thisTag.thePopClass = "signin_UpRight" />
  	<cfset thisTag.theSignLinkClassAppend = "Up" />
	<cfelse>
  	<cfset thisTag.thePopClass = "signin_DownLeft" />
  	<cfset thisTag.theSignLinkClassAppend = "Down" />
	</cfif>
	<cfoutput>
	<div id="SignInContainer">
		<cfif application.SLCMS.core.UserPermissions.IsLoggedin()>
			<div id="SignInNav" class="SignInNav"><a href="login" class="signin#thisTag.theSignLinkClassAppend#"><span>Sign Out</span></a> </div>
		<cfelse>
			<div id="SignInNav" class="SignInNav"><a href="login" class="signin#thisTag.theSignLinkClassAppend#"><span>Sign In</span></a> </div>
		</cfif>
		<form name="#thisTag.theFormName#" action="#cgi.script_name##cgi.path_info#" method="post" id="signin" class="#thisTag.theFormClass#">
		<fieldset id="signin_menu" class="#thisTag.thePopClass#">
		<cfif not application.SLCMS.core.UserPermissions.IsLoggedin()>
			<cfinclude template="#thisTag.TagTemplateBasePath#_SignIn.cfm" >
		<cfelse>
			<cfinclude template="#thisTag.TagTemplateBasePath#_SignOut.cfm" >
		</cfif>
		</fieldset>
		</form>
	</div>		
	</cfoutput>
	<cfsaveContent variable="TheJS"><cfoutput>
	<script type="text/javascript">
		$(document).ready(function() {
	    $(".signin#thisTag.theSignLinkClassAppend#").click(function(e) {
	        e.preventDefault();
	        $("fieldset##signin_menu").toggle();
	        $(".signin#thisTag.theSignLinkClassAppend#").toggleClass("menu-open");
	    });
	    $("fieldset##signin_menu").mouseup(function() {
	        return false
	    });
	    $(document).mouseup(function(e) {
	        if($(e.target).parent("a.signin#thisTag.theSignLinkClassAppend#").length==0) {
	            $(".signin#thisTag.theSignLinkClassAppend#").removeClass("menu-open");
	            $("fieldset##signin_menu").hide();
	        }
	    });            
		});
	</script></cfoutput>
	</cfsaveContent><cfhtmlHead text="#TheJS#" />
</cfif>
<cfsetting enablecfoutputonly="No">

