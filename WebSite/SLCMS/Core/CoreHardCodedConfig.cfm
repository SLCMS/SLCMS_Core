<!--- SLCMS Core --->
<!--- page to insert hard-coded config into where it needs to go --->
<!--- &copy; 2012 mort bay communications --->
<!---  --->
<!--- separate page just to make things neater in the init routines --->
<!--- 
docs: startParams
docs:	Name: CoreHardCodedConfig
docs:	Type:	include file
docs:	Role:	Utility Assist - Core 
docs:	Hint: page to insert hard-coded config into where it needs to go
docs:	Versions: Tag - 1.0.0; Core - 3.0.0+
docs: endParams
docs: 
docs: startAttributes
docs: endAttributes
docs: 
docs: startManual
docs: sets the bit patterns for core roles
docs: endManual
docs: 
docs: startHistory_Versions
docs: Version 1.0.0.360: 	Base 
docs: Version 1.0.0.359: 	added this documentation commenting
docs: endHistory_Versions
docs:
docs: startHistory_Coding
docs:	created:   4th Mar 2012 by Kym K, mbcomms
docs:	modified:  4th Mar 2012 -  4th Mar 2012 by Kym K, mbcomms: initial work on it
docs:	modified:  9th Apr 2012 -  9th Apr 2012 by Kym K, mbcomms: V3.0, CFWheels version. All SLCMS in own struct under app scope
docs: endHistory_Coding
 --->

<!--- first off load in the role bit patterns --->
<cfif not StructKeyExists(application.SLCMS, "Roles")>
	<cfset application.SLCMS["Roles"] = StructNew() />	<!--- done with case preservation so it looks pretty --->
</cfif>
<!--- for the Core ---> 
<cfif not StructKeyExists(application.SLCMS.Roles, "Core")>
	<cfset application.SLCMS.Roles["Core"] = StructNew() />
</cfif> 
<cfset application.SLCMS.Roles.Core.Global = StructNew() />
<cfset application.SLCMS.Roles.Core.Global.Admin = {RoleBits="00000000000000000000000000000100", Name = "Administrator", Description = "Global Administrative Privileges"} />
<cfset application.SLCMS.Roles.Core.Global.Admin.RoleValue = application.SLCMS.mbc_Utility.Utilities.Bits32ToInt(application.SLCMS.Roles.Core.Global.Admin.RoleBits) />
<cfset application.SLCMS.Roles.Core.Global.Editor = {RoleBits="00000000000000000000000000000010", Name = "Editor", Description = "Global Editorial Privileges"} />
<cfset application.SLCMS.Roles.Core.Global.Editor.RoleValue = application.SLCMS.mbc_Utility.Utilities.Bits32ToInt(application.SLCMS.Roles.Core.Global.Editor.RoleBits) />
<cfset application.SLCMS.Roles.Core.Global.Author = {RoleBits="00000000000000000000000000000001", Name = "Editor", Description = "Global Content Creation Privileges"} />
<cfset application.SLCMS.Roles.Core.Global.Author.RoleValue = application.SLCMS.mbc_Utility.Utilities.Bits32ToInt(application.SLCMS.Roles.Core.Global.Author.RoleBits) />
<cfset application.SLCMS.Roles.Core.Content = StructNew() />
<cfset application.SLCMS.Roles.Core.Content.Editor = {RoleBits="00000000000000000000000000001000", Name = "Editor", Description = "Content Only Editorial Privileges"} />
<cfset application.SLCMS.Roles.Core.Content.Editor.RoleValue = application.SLCMS.mbc_Utility.Utilities.Bits32ToInt(application.SLCMS.Roles.Core.Content.Editor.RoleBits) />
<cfset application.SLCMS.Roles.Core.Content.Author = {RoleBits="00000000000000000000000000010000", Name = "Editor", Description = "Content Only Content Creation Privileges"} />
<cfset application.SLCMS.Roles.Core.Content.Author.RoleValue = application.SLCMS.mbc_Utility.Utilities.Bits32ToInt(application.SLCMS.Roles.Core.Content.Author.RoleBits) />
<!--- the base struct for Modules ---> 
<cfif not StructKeyExists(application.SLCMS.Roles, "Modules")>
	<cfset application.SLCMS.Roles["Modules"] = StructNew() />
</cfif> 

