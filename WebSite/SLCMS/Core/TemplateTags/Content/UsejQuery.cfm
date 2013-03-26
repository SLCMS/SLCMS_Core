<cfsetting enablecfoutputonly="Yes">
<!--- SLCMS Core - base tags to be used in template pages  --->
<!--- &copy; 2012 mort bay communications --->
<!---  --->
<!--- custom tag to get jQuery and related items loaded into the page --->
<!--- 
Docs: startParams
docs:	Name: UsejQuery
docs:	Type:	Custom Tag 
docs:	Role:	Control Tag - Core 
docs:	Hint: flags system to load jQuery script and any specified related items
docs:	Versions: Tag - 1.0.0; Core - 2.2.0+
docs:	<cfparam name="attributes.LibraryList" type="string" default="">	listof the libraries wanted to be loaded, in listed order
docs:	<cfparam name="attributes.LoadLast" type="boolean" default="False">	flags to load scripts at end of head, jQuery always loads at top
Docs: endParams

Docs: startManual
Will load the latest version of jQuery at the top of the <head> area.
Loads any specified extra jQuery libraries in the order listed. 
They are loaded at the top of the html head area by default before any template defined scripts. 
Loadlast will make them load after any template defined scripts.
Docs: endManual

Docs: startHistory
created:  27th Jan 2008 by Kym K, mbcomms
modified: 20th Feb 2012 - 20th Feb 2012 by Kym K, mbcomms: updated to include the documentation engine notation
Docs: endHistory
 --->

<cfif NOT IsDefined("thisTag.executionMode")>
	<cfabort showerror="Must be called as customtag.">
</cfif>
<cfif thisTag.executionMode IS "start">
	<cfparam name="attributes.LibraryList" type="string" default="">
	<cfparam name="attributes.LoadLast" type="boolean" default="False">

	<cfif attributes.LoadLast>
		<cfset thisTag.Place = "Bottom" />
	<cfelse>
		<cfset thisTag.Place = "Top" />
	</cfif>
	
	<cfinclude template="#application.SLCMS.paths_common.rooturl##application.SLCMS.paths_common.ThirdPartyPath_Rel#3rdPartyDefinitions.cfm" >
	<cfset thisTag.theLibs = Definitions_ThirdPartyLibraries() />
<cfdump var="#thisTag#" expand="false" label="thisTag">
<cfabort>

	<cfset thisTag.Ret = application.SLCMS.Core.ContentCFMfunctions.AddHeadContent(Place="Top", Path="#application.SLCMS.Paths_Common.RootURL##application.SLCMS.Paths_Common.jQueryPath_Rel#") />	<!--- load in jQuery --->
	<cfloop list="#attributes.LibraryList#" index="thisTag.thisLibrary" >
		<cfset thisTag.Ret = application.SLCMS.Core.ContentCFMfunctions.AddHeadContent(Place="#thisTag.Place#", Path="#application.SLCMS.Paths_Common.jQueryJsPath_Abs#") />	<!--- load in jQuery --->
	</cfloop>

</cfif><cfsetting enablecfoutputonly="No">