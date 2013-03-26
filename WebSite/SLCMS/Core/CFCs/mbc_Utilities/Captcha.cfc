<!--- captcha.cfc --->
<!---  --->
<!--- CFC containing functions that captcha validation --->
<!---  --->
<!--- copyright: mortbay communications 2007 --->
<!---  --->
<!--- Created:   8th Jul 2007 by Kym K --->
<!--- Modified:  8th Jul 2007 -  8th Jul 2007 by Kym K, working on it  --->


<cfcomponent output="no"
	displayname="Captcha validation"
	hint="set of functions for captcha validation">

	<!--- set up a few persistant things on the way in. --->
	<cfset variables.DataStores = StructNew() />	<!--- this will persistently contain all of the stores as structures --->
	<cfset variables.DataStoreNameList = "" />	<!--- this will persistently contain a list of all of the stores --->

<!--- initialise the various thingies, this should only be called after an app scope refresh or similar --->
<cffunction name="init" access="public" output="yes" returntype="struct" 
	description="The Initializer"
	hint="">

	<cfargument name="DataStorePath" type="string" default="" hint="full physical path to where the RRD databases live" />	<!--- path to the db directory --->

	<cfargument name="FormFullName" type="string" default="" />	<!--- the name of the form structure --->

	<!--- now all of the var declarations, first the arguments which need manipulation --->
	<cfset var theCounterName = trim(arguments.CounterName) />	
	<!--- now vars that will get filled as we go --->
	<cfset var thisTableName = "" />	<!--- temp name of table in the code --->
	<cfset var theCounterNumber = 0 />	<!--- the position of the counter in dimension [2] of the data array --->
	<cfset var theDatastructure = Structnew() />
	<cfset var l = 0 />	<!--- temp loop counter --->
	<cfset var lcntr = 0 />	<!--- temp loop counter --->
	<cfset var temp = "" />	<!--- temp/throwaway var --->
	<!--- lastly the return structure if we need it --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorText = "" />
	<cfset ret.Data = "" />

	<cfreturn ret  />
</cffunction>


<cffunction name="emptyFunction" output="yes" returntype="struct" access="public"
	displayname="Nothing"
	hint="this is just a shell to copy, can be deleted once coding has finished, and turn off output if we don't need it to save whitespace">
	<!--- this function needs.... --->
	<cfargument name="FormFullName" type="string" default="" />	<!--- the name of the form structure --->

	<!--- now all of the var declarations, first the arguments which need manipulation --->
	<cfset var theCounterName = trim(arguments.CounterName) />	
	<!--- now vars that will get filled as we go --->
	<cfset var thisTableName = "" />	<!--- temp name of table in the code --->
	<cfset var theCounterNumber = 0 />	<!--- the position of the counter in dimension [2] of the data array --->
	<cfset var theDatastructure = Structnew() />
	<cfset var l = 0 />	<!--- temp loop counter --->
	<cfset var lcntr = 0 />	<!--- temp loop counter --->
	<cfset var temp = "" />	<!--- temp/throwaway var --->
	<!--- lastly the return structure if we need it --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorText = "" />
	<cfset ret.Data = "" />

	<cfreturn ret  />
</cffunction>

</cfcomponent>
	
	
	