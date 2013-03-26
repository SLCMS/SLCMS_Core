<cfsetting enablecfoutputonly="Yes">
<!--- SLCMS Core - definition include --->
<!--- &copy; 2012 mort bay communications --->
<!---  --->
<!--- defines what is in the 3rdParty Frameworks and Libs folder --->
<!--- 
Docs: startParams
docs:	Name: 3rdPartyDefinitions
docs:	Type:	UDF Include 
docs:	Role:	Definition file - Core 
docs:	Hint: defines what is in the 3rdParty Frameworks and Libs folder
docs:	Versions: File - 1.0.0; Core - 2.2.0+
Docs: endParams

Docs: startManual
an include file with User Defined Functions within
defines what is in the 3rdParty Frameworks and Libs folder so that functions can confirm legitimate calls
Docs: endManual

Docs: startHistory
created:  21st Feb 2012 by Kym K, mbcomms
modified: 21st Feb 2012 - 21st 2012 by Kym K, mbcomms: initial work on it
Docs: endHistory
 --->

<cffunction name="Definitions_ThirdPartyLibraries" access="public" returntype="Struct" description="Returns Struct of Valid Libraries">
	<cfset var ret = StructNew() />
  
	<cfset ret.jQueryLibs = StructNew() />
  <cfset ret.jQueryLibs.LibList = "colorbox,fancybox" />
	<cfset ret.jQueryLibs.colorbox = StructNew() />
	<cfset ret.jQueryLibs.colorbox.libFolderPath_Rel = "colorbox/" />
	<cfset ret.jQueryLibs.colorbox.libFileName = "jquery.colorbox-min.js" />
	<cfset ret.jQueryLibs.fancybox = StructNew() />
	<cfset ret.jQueryLibs.fancybox.libFolderPath_Rel = "fancybox/" />
	<cfset ret.jQueryLibs.fancybox.libFileName = "jquery.fancybox-1.3.4.pack.js" />
  <cfreturn ret>
</cffunction>
<cfsetting enablecfoutputonly="No">