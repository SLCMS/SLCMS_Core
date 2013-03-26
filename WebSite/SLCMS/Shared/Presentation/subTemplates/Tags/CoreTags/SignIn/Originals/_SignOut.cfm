<cfsetting enablecfoutputonly="Yes"><cfsilent>
<!--- SLCMS Core - base tags to be used in template pages  --->
<!--- &copy; 2012 mort bay communications --->
<!--- 
docs: startParams
docs:	Name: _SignOut
docs:	Type:	Custom Tag Include 
docs:	Role:	Content Display Tag - Core 
docs:	Hint: include that has the SignOut form html, included into displayForm_SignIn display tag
docs:	Versions: Tag - 1.0.0; Core - 2.2.0+
docs: endParams
docs: 
docs: startAttributes
docs: endAttributes
docs: 
docs: startManual
docs: include that has the SignOut form html, included into displayForm_SignIn display tag
docs: if changed make sure stylesheet matched and watch out for jQuery id naming
docs: endManual
docs: 
docs: startHistory_Versions
docs: Version 1.0.0.359: 	Base tag
docs: Version 1.0.0.359: 	added this documentation commenting
docs: endHistory_Versions
docs:	
docs: startHistory_Coding
docs:	cloned:    3rd Mar 2012 by Kym K, mbcomms out of displayForm_SignIn 
docs:	modified:  3rd Mar 2012 -  3rd Mar 2012 by Kym K, mbcomms: initial work on it
docs: endHistory_Coding
 --->
</cfsilent><cfoutput>
<input type="hidden" name="aFiled" value="LoggingOut">
<p class="#attributes.class_LoggedInMsg#">You are logged in as: #session.user.NameDetails.User_FullName#</p>
<cfif attributes.ShowGoToAdmin eq "yes" and session.user.IsStaff>
<p class="#attributes.class_LoggedInMsg#"><a href="#request.RootURL#Admin/AdminHome.cfm" target="_blank">Go to Administration Area (in new tab/window)</a></p>
</cfif>
<input type="submit" id="signout_submit" value="Sign Out" title="Sign out from site">
</cfoutput><cfsetting enablecfoutputonly="No">