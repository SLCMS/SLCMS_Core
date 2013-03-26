<!--- mbc CFCs  --->
<!--- &copy; 2007 mort bay communications --->
<!---  --->
<!--- a set of utilities for working with the SLCMS site structure --->
<!--- this is a complete set of code existing about the site 
			so this will slowly fill as new things come on stream and old code gets updated
			 --->
<!--- Contains:
			init - set up persistent structures for the site structure, etc
			 --->
<!---  --->
<!--- created:  23rd Apr 2007 by Kym K --->
<!--- modified: 23rd Apr 2007 - 23rd Apr 2007 by Kym K, did initial stuff --->

<cfcomponent output="no"
	displayname="Site Structure Utilities" 
	hint="contains standard utilities to work with the Site Structure"
	>
	
	<!--- set up a few persistant things on the way in. --->
	<cfset variables.SiteStructure = StructNew() />	
	<cfset variables.DataBase = StructNew() />	
	<cfset variables.DataBase.Names = StructNew() />	

<!--- initialize the various thingies, this should only be called after an app scope refresh --->
<cffunction name="init" 
	access="public" output="yes" returntype="struct" 
	displayname="Initializer"
	hint="sets up the internal structures for this component"
	>
	<cfargument name="dsn" type="string" required="yes">	<!--- the name of the database that has the relevant tables such as "Nexts" --->
	<cfargument name="SiteStructureTable" type="string" default="SLCMS_SiteStructure">	<!--- the name of the database table for the site structure --->
	<cfargument name="DocumentBaseTable" type="string" default="SLCMS_Document_Base">	<!--- the name of the database table for the documents --->

	<cfset variables.DataBase.Names.dsn = arguments.dsn />
	<cfset variables.DataBase.Names.SiteStructureTable = arguments.SiteStructureTable />
	<cfset variables.DataBase.Names.DocumentBaseTable = arguments.DocumentBaseTable />
	
	<cfset refreshSiteStructure() />	<!--- load up the Site structure with the latest data --->
	
	<cfreturn variables.SiteStructure />
</cffunction>




<!--- this function is empty, ready to clone for new ones --->
<cffunction name="getxxx" 
	access="public" output="yes" returntype="string" 
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