<!--- this is the banner section of all of the admin pages --->
<cfparam name="PageContextFlags.Banner2ndString" type="string" default="" />
<cfparam name="ErrMsg" type="string" default="" />
<cfparam name="GoodMsg" type="string" default="" />
<cfif request.slcms.flags.PoppedAdminPage>
	<!--- no banner for the popped up admin pages --->
	<cfif len(ErrMsg) or len(GoodMsg)>
		<div class="MsgTopBorder">
		<cfif len(ErrMsg)><span class="errrColour">Error: #ErrMsg#</span></cfif>
		<cfif len(GoodMsg)><span class="goodColour">Command Result: #GoodMsg#</span></cfif>
		</div>
	</cfif>
	<cfif not PageContextFlags.IsAdminHomePage>
		<cfoutput>#linkTo(text="Back to Site Administration Home Page", controller="slcms.adminHome", action="index", params="#PageContextFlags.ReturnLinkParams#")#</cfoutput>
	</cfif>
<cfelse>
	<!--- backend admin has logo and heading and back link --->
	<cfoutput>
	<div>
		<a href="#application.SLCMS.Paths_Admin.AdminBaseURL#Admin-Home"><img src="#application.SLCMS.Paths_Admin.GraphicsPath_ABS#slcmsLogo2.gif" alt="SLCMS Admin Page Logo and Link" border="0" style="float:left;margin:5px;"></a>
	  <p class="majorheading" style="padding-top:20px;">#PageContextFlags.BannerHeadString#</p>
	  <cfif len(PageContextFlags.Banner2ndString)>
	  	<p>#PageContextFlags.Banner2ndString#</p>
	  </cfif>
	</div>
	<div class="HeadNavigation" style="clear:both;"><!--- 
	 ---><cfif len(ErrMsg) or len(GoodMsg)>
		<div class="MsgTopBorder">
		<cfif len(ErrMsg)><span class="errrColour">Error: #ErrMsg#</span></cfif>
		<cfif len(GoodMsg)><span class="goodColour">Command Result: #GoodMsg#</span></cfif>
		</div>
	</cfif>
	<cfif PageContextFlags.ShowGoToSiteLink>
		<p><a href="#application.SLCMS.Paths_Common.ContentRootURL#">Leave the administration area and go to the website homepage</a></p>
	</cfif>
	<cfif PageContextFlags.ShowSignInLink>
		<!--- shouldn't be here so show that and abort all processing --->
		You are not Logged in: 
		<cfoutput>#linkTo(text="Go to Log In Page", controller="slcms.adminHome", action="adminLogin", params="#PageContextFlags.ReturnLinkParams#")#</cfoutput>
	</cfif>
	</div>
	<cfif application.slcms.core.UserPermissions.IsLoggedin() and not PageContextFlags.IsAdminHomePage>
		#linkTo(text="Back to Site Administration Home Page", controller="slcms.adminHome", action="index", params="#PageContextFlags.ReturnLinkParams#")#
	</cfif>
	</cfoutput>
</cfif>
