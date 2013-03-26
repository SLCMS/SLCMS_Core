<!--- SLCMS Form Handling --->
<!--- Blank Form HTML --->
<!---  --->
<!--- 
			This is a sample form to use in SLCMS.
			All you need here is the HTML to make the form presentation itself.
			The form tags and some hidden input fields are in the enclosing SLCMS code.
			You can use whatever form fields you wish, with css if needed, here or in the template area,
			The form processing, or action, page will be presented will all of the fields here as standard form variables
 --->
<!---  --->
<!--- created:  18th Apr 2008 by Kym K - mbcomms, cloned from exiting contact form as a sample Form --->
<!--- modified: 18th Apr 2008 - 18th Apr 2008 by Kym K - mbcomms, working on it --->

<!--- 
			this <cfoutput> CF tag and its matching end tag needs to be here, wrapping the entire html that is wanted to be visible.
			Anything outside the <cfoutput></cfoutput> pair will not be sent to the browser as HTML code.
			Use CF comments, with the extra hyphen, within that space to make comments that are not to be sent to the browser.
 --->
<cfoutput> 
<!--- this is the HTML code from the ContactUs form as a table-based sample from the dark past --->
<table id="Table1" border="0" cellspacing="0" cellpadding="6" width="100%">
	<tr valign=top>
		<td width=160 height=22 align="right">Your Name:</td>
		<td><input type=text name="Name" value="" size=39 maxlength=100></td>
	</tr>
	<tr valign=top>
		<td width=160 height=22 align=right>Email Address:</td>
		<td><input type=text name="Sender" value="" size=39 maxlength=128></td>
	</tr>
	<tr valign=top>
		<td width=160 height=79 align=right>Your Query:</td>
		<td><textarea wrap="hard" name="Commments" rows=6 cols=40></textarea></td>
	</tr>
	<tr valign=top>
		<td><input type=reset name="FormsButton3" value="Clear" id="FormsButton3"></td>
		<td height=24><p><input type=submit name="FormHandler2" value="Send Message" id="FormHandler2"></td>
	</tr>
</table>
</cfoutput>


