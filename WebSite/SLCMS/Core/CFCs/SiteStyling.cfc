<!--- mbc SLCMS CFCs  --->
<!--- &copy; 2007 mort bay communications --->
<!---  --->
<!--- a set of utilities for working with the SLCMS site navigation/menu styling --->
<!--- finds and load the various ini files that control menu and their styling, etc --->
<!--- Contains:
			init - set up persistent structures for the site styling, etc but in application scope so the diplay tags can grab easily
			lots more related stuff :-)
			 --->
<!---  --->
<!--- created:  25th Nov 2007 by Kym K --->
<!--- modified: 27th Dec 2007 - 28th Dec 2007 by Kym K - changed to different structures of navigation control info with one file per nav --->

<cfcomponent output="yes"
	displayname="Site Styling Utilities" 
	hint="contains standard utilities to work with the Menu/Nav/Site Styling"
	>
	
	<!--- set up a few persistant things on the way in. --->
	<cfset theName = "NavigationStyling" />	<!--- do the "force the struct name to camelcase trick" --->
	<cfset application.SLCMS.Config["#theName#"] = StructNew() />	<!--- this structure carries the styles to use un navigation/menus --->

<!--- initialize the various thingies, this should only be called after an app scope refresh --->
<cffunction name="init" 
	access="public" output="yes" returntype="any" 
	displayname="Initializer"
	hint="sets up the internal structures for this component"
	>
		<!--- 
	<cfargument name="SitePath" type="string" required="yes">	<!--- the path to the top of the site so we can get the ini files --->
 --->
	<cfset var TemplateTopPath = application.SLCMS.Config.StartUp.SiteBasePath & application.SLCMS.Config.base.SLCMSPageTemplatesRelPath />
	<cfset var SharedTemplateTopPath = application.SLCMS.Config.StartUp.SiteBasePath & application.SLCMS.Config.Base.SLCMSSharedRelPath & application.SLCMS.Config.Base.SLCMSPageTemplatesRelPath />
	<cfset var theTemplateSets = "" /> <!--- this will have the query result of the template sets available from above --->
	<cfset var theTemplateSetList = "" /> <!--- this will have a list of the template sets available from above --->
	<cfset var NavSetPath = "" /> <!--- temp path to one set of menu definition files --->
	<cfset var theNavSets = "" /> <!--- this will have a query of the navigation def sets available from above --->
	<cfset var theNavDefFile = "" />	<!--- the name of one def fiule as we read it --->
	<cfset var lcntr = 1 /> <!--- temp for loops --->
	<cfset var tempPath = "" /> <!--- temp var --->

	<cfif DirectoryExists(TemplateTopPath)>
		<cfdirectory action="list" name="theTemplateSets" directory="#TemplateTopPath#" />
		<!--- we want a list of directories as that is effectively a list of template sets --->
		<cfloop query="theTemplateSets">
			<cfif theTemplateSets.type eq "Dir" and theTemplateSets.Name neq ".svn">
				<cfset theTemplateSetList = ListAppend(theTemplateSetList, theTemplateSets.Name) />
			</cfif>
		</cfloop>
		<cfset application.SLCMS.Config.NavigationStyling.TemplateSets = theTemplateSetList />	<!--- save the sets for easy grab later --->
		<!--- we now have a list of template sets so drop into them and grab the detail --->
		<cfloop list="#theTemplateSetList#" index="lcntr">
			<cfset application.SLCMS.Config.NavigationStyling["#lcntr#"] = StructNew() />	<!--- create a struct  for this template set --->
			<!--- now see how many control files we have, one per menu used hopefully :-) --->
			<cfset NavSetPath = TemplateTopPath & lcntr & "/TemplateControl/NavigationControl/" />
			<cfdirectory action="list" name="theNavSets" directory="#NavSetPath#" filter="*_NavigationDefinition.ini" />
			<!--- we should now have a query of every nav def file --->
			<cfloop query="theNavSets">
				<cfif theNavSets.type eq "File" and theNavSets.Name neq "NavigationDefinition_Blank.ini">
				<cfset theNavDefFile = left(theNavSets.Name, len(theNavSets.Name)-25) />
				<cfset tempPath = TemplateTopPath & lcntr & "/TemplateControl/NavigationControl/#theNavSets.Name#" />
				<cfif FileExists(tempPath)>
 					<cfset application.SLCMS.Config.NavigationStyling["#lcntr#"]["#theNavDefFile#"] = application.mbc_Utility.iniTools.ini2Struct(FilePath="#tempPath#", TrimWhiteSpace="Partial").data />
<!---
 					<cfset application.SLCMS.Config.NavigationStyling["#lcntr#"]["#theNavDefFile#"] = application.mbc_Utility.iniTools.ini2Struct(FilePath="#tempPath#", ipStructName="application.SLCMS.Config.NavigationStyling.#lcntr#", TrimWhiteSpace="Partial").data />
 --->				</cfif>
				</cfif>
			</cfloop>
		</cfloop>
	<cfelse>
		<!--- oops! --->
	</cfif>
	
	<cfreturn theTemplateSetList />
</cffunction>


<!--- this function is empty, ready to clone for new ones --->
<cffunction name="getxxx" 
	access="public" output="yes" returntype="struct" 
	displayname=""
	hint=""
	>
	<!---  --->
	<cfargument name="IDname" type="string" required="yes" hint="name of ID variable to return">	

	<cfset var ret = "" />								<!--- two standard return variables for local function calls, etc --->
	<cfset var rets = Structnew() />
	<cfset var Returner = Structnew() />	<!--- the standard structure for returning function calls --->
	<cfset Returner.Error = Structnew() /><!--- two returns, an error structure and data, assumed to be a struct but could be anything --->
	<cfset Returner.Error.code = 0 />
	<cfset Returner.Error.text = "" />
	<cfset Returner.Data = Structnew() />	<!--- data return, assumed to be a struct but can be anything --->

	<cfreturn Returner />
</cffunction>

</cfcomponent>