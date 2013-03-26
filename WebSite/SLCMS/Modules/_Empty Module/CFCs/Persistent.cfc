<cfcomponent output="yes" extends="Controller"
	displayname="A Module Persistent Functions" 
	hint="contains functions the Module needs to be persistent"
	>
<!---
<!--- mbc SLCMS Module CFCs  --->
<!--- &copy; 2013 mort bay communications --->
<!---  --->
<!--- a set of utilities for working with the a module --->
<!--- Contains:
			init - set up persistent structures (CFC is in application scope so the display tags can grab easily)
			lots more related stuff :-)
			 --->
<!---  --->
<!--- created:  10th May 2011 by Kym K, mbcomms --->
<!--- modified: 10th May 2011 - 10th May 2011 by Kym K, mbcomms: initial work on it --->
--->
	<!--- set up a few persistant things on the way in. --->
	<cfset variables.theModuleFormalName = "A_Module" />
	<cfset variables.theModuleFriendlyName = "A Module" />
	<cfset variables.ActivesubSiteList = "" />

<!--- initialize the various thingies, this should only be called after an app scope refresh --->
<cffunction name="init" 
	access="public" output="no" returntype="any" 
	displayname="Initializer"
	hint="sets up the internal structures for this component"
	>

<!--- these are typical, not compulsory --->

	<cfargument name="ModuleFormalname" type="string" required="yes" default="" hint="the formal name of this module">

	<cfset var temps = StructNew() /> <!--- temp var --->
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorText = "#variables.theModuleFormalName# Persistent CFC Init()<br>" />
	<cfset ret.Data = "" />
	
	<!--- set up our global thingies --->
	<cfset variables.ActivesubSiteList = application.core.PortalControl.GetActiveSubSiteIDList() />
	<cfset variables.theModuleFormalName = trim(arguments.ModuleFormalname) />
	<cfif variables.theModuleFormalName eq "">
		<!--- test for Formal name --->
		<cfthrow type="Custom" detail="ModuleFormalName Not Supplied!" message="Init(): The ModuleFormalName passed to the component was blank">
	</cfif>	<!--- end: path valid, OK to initialize --->

	<cfreturn ret />
</cffunction>

<cffunction name="getVariablesScope" output="No" returntype="struct" access="public"
	displayname="get Variables scope"
	hint="this is a quicky to dump the entire variables scope, returns the struct directly"
				>
	<cfreturn variables  />
</cffunction>

</cfcomponent>