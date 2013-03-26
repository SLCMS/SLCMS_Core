<!---  Body Content --->
<!--- first edited:  12th Mar 2003 by Kym, initial entry --->
<!--- last edited:  27th Jan 2006 by Kym, cloned to new SLCMS site, added a tad of security --->
<!--- modified: 18th Apr 2008 - 18th Apr 2008 by Kym K, updated to coding to match new form tag coding. Now security test is in wrapper, this is just the processing code only --->

<cfsetting enablecfoutputonly="Yes">

<cfmail to="sales@mbcomms.net.au" from="mbcomms-website@mbcomms.net.au" subject="Contact form from test new SLCMS website">
Mail from the sample contact page
From: #form.name#
Of: #form.sender#

Saying:
#form.commments#
</cfmail>
<cfoutput>
	&nbsp;<p>
	Thank you, <br>your query has been sent to the SLCMS crew.
	&nbsp;<p>
	&nbsp;<p>
</cfoutput>
<cfsetting enablecfoutputonly="No">

