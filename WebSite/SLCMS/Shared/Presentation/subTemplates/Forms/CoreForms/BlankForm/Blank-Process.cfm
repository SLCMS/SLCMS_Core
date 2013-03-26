<!--- SLCMS Form Handling --->
<!--- Blank Form Processor/Action Page --->
<!---  --->
<!--- 
			This is a sample Processor or action page to use in SLCMS.
			Here you process the form variable sent form the form.
			Validation has taken place in the SLCMS enclosing code to check for correct hidden variables to provide a 
			base level of bot-stopping.
 --->
<!---  --->
<!--- created:  18th Apr 2008 by Kym K - mbcomms, cloned from exiting contact processor as sample code --->
<!--- modified: 18th Apr 2008 - 18th Apr 2008 by Kym K - mbcomms, working on it --->

<!--- 
			you need a <cfoutput> CF tag and its matching end tag to show any html that is wanted to be visible.
			Anything outside the <cfoutput></cfoutput> pair will not be sent to the browser as HTML code.
			Use CF comments, with the extra hyphen, within that space to make comments that are not to be sent to the browser.
 --->

<cfsetting enablecfoutputonly="Yes">

<cfmail to="sales@mbcomms.net.au" from="mbcomms-website@mbcomms.net.au" subject="Contact form from test new mbcomms SLCMS website">
Mail from the mbcomms contact page
From: #form.name#
Of: #form.sender#

Saying:
#form.commments#
</cfmail>
<cfoutput>
	&nbsp;<p>
	Thank you, <br>your query has been sent to mbcomms' sales dept.
	&nbsp;<p>
	&nbsp;<p>
</cfoutput>
<cfsetting enablecfoutputonly="No">

