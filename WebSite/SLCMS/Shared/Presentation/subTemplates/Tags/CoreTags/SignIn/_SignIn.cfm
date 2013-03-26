<cfsetting enablecfoutputonly="Yes"><cfsilent>
<!--- SLCMS Core - base tags to be used in template pages  --->
<!--- &copy; 2012 mort bay communications --->
<!--- 
docs: startParams
docs:	Name: _SignIn
docs:	Type:	Custom Tag Include 
docs:	Role:	Content Display Tag - Core 
docs:	Hint: include that has the SignIn form html, included into displayForm_SignIn display tag
docs:	Versions: Tag - 1.0.0; Core - 2.2.0+
docs: endParams
docs: 
docs: startAttributes
docs: endAttributes
docs: 
docs: startManual
docs: include that has the SignIn form html, included into displayForm_SignIn display tag
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
<input type="hidden" name="aFiled" value="LoggingIn">
<p>
<label for="username">SignIn</label>
<input id="username" name="SignIn_Username" value="#thisTag.theUserName#" title="username" tabindex="4" type="text" class="#attributes.class_inputfield#">
</p>
<p>
  <label for="password">Password</label>
  <input id="password" name="SignIn_Password" value="#thisTag.thePassword#" title="password" tabindex="5" type="password" class="#attributes.class_inputfield#">
</p>
<p class="remember">
  <input type="submit" id="signin_submit" value="Sign in" tabindex="6">
	<!---
  <input type="checkbox" id="remember" name="remember_me" value="1" tabindex="7">
  <label for="remember">Remember me</label>
	--->
</p>
<!---
<p class="forgot"> <a href="##" id="resend_password_link">Forgot your password?</a> </p>
<p class="forgot-username"> <A id=forgot_username_link title="If you remember your password, try logging in with your email" href="##">Forgot your SignIn?</A> </p>
--->
</cfoutput>
<cfsetting enablecfoutputonly="No">