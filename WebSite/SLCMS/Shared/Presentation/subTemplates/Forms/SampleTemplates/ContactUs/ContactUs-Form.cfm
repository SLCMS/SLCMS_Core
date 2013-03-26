<!--- Contact Form Body Content --->
<!--- modified: 10th Sep 2008 - 10th Sep 2008 by Kym K, mbcomms - updated to coding to match new form tag coding. Now form tags, are in wrapper, this is just the form inner html only and using the form-related SLCMS tags --->
<cfimport taglib="/SLCMS/Core/TemplateTags/Form/" prefix="slcmsForm">	<!--- grab the CMS functions to display things --->
<slcmsForm:setFormStyles StyleSheet="Default/DefaultFormStyles" />

<cfoutput>
<table id="Table1" border="0" cellspacing="0" cellpadding="6" width="100%">
	<tr valign=top>
		<td width=160 height=22 align="right">Your Name:</td>
		<td>
			<slcmsForm:showInputTag type="text" name="Name" value="" size=39 maxlength=100 required="yes" allowblank="No" />
		</td>
	</tr>
	<tr valign=top>
		<td width=160 height=22 align=right>Your Email Address:</td>
		<td>
			<slcmsForm:showInputTag type="text" name="Sender" value="" size=39 maxlength=100 required="yes" allowblank="No" validate="email" />
		</td>
	</tr>
	<tr valign=top>
		<td width=160 height=50 align=right valign="top">Your Query:</td>
		<td>
			<slcmsForm:showtextAreaTag name="Commments" rows=6 cols=40 required="yes" />
		</td>
	</tr>
	<tr valign=top>
		<td>
			<!---
			<slcmsForm:showInputTag type="reset" name="ResetButton" value="Clear" id="ResetButton" />
			--->
		</td>
		<td height=22>
			<slcmsForm:showInputTag type="submit" name="SubmitButton" value="Send Message" id="SubmitButton" />
		</td>
	</tr>
</table>
</cfoutput>


