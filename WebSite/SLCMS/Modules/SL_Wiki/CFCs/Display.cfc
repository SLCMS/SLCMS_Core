<!--- mbc SLCMS CFCs  --->
<!--- &copy; 2009 mort bay communications --->
<!---  --->
<!--- a set of utilities for working with the SLCMS Shop --->
<!--- Contains:
			init - set up persistent structures (CFC is in application scope so the diplay tags can grab easily)
			lots more related stuff :-)
			 --->
<!---  --->
<!--- created:   2nd Apr 2008 by Kym K - mbcomms --->
<!--- modified:  2nd Apr 2008 -  7th Apr 2008 by Kym K - mbcomms - initial work --->
<!--- Modified:  2nd Mar 2009 -  2nd Mar 2009 by Kym K, big pause, now more work on it, changed style to non-generic objects --->

<cfcomponent output="yes" extends="Controller"
	displayname="Shop Control Utilities" 
	hint="contains standard utilities to work with the Shop"
	>
	<!--- set up a few persistant things on the way in. --->
	<cfset variables.Global = StructNew() />
	<cfset variables.Global.DSN = "" />
	<cfset variables.Global.ThreadSetID = "" />
	<cfset variables.Global.ThreadSetName = "" />
	<cfset variables.Global.ObjectControlTable = "" />
	<cfset variables.Global.ShopProductDataTable = "" />
	<cfset variables.Global.ShopMasterTable = "" />
	
<!--- initialize the various thingies, this should only be called after an app scope refresh --->
<cffunction name="init" 
	access="public" output="yes" returntype="any" 
	displayname="Initializer"
	hint="sets up the internal structures for this component"
	>

	<cfargument name="DSN" type="string" required="yes">	<!--- the datasource for the shop tables --->
	<cfargument name="ObjectControlTable" type="string" required="yes">	<!--- the table name for the shop category definitions --->
	<cfargument name="ShopProductDataTable" type="string" required="yes">	<!--- the table name for the shop category definitions --->
	<cfargument name="ShopMasterTable" type="string" required="yes">	<!--- the table name for the shop category descriptions --->

	<cfset var temps = StructNew() /> <!--- temp var --->
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorText = "Init()<br>" />
	<cfset ret.Data = "" />
	
	<!--- set up our global thingies --->
	<cfset variables.Global.DSN = trim(arguments.DSN) />
	<cfset variables.Global.ObjectControlTable = trim(arguments.ObjectControlTable) />
	<cfset variables.Global.ShopProductDataTable = trim(arguments.ShopProductDataTable) />
	<cfset variables.Global.ShopMasterTable = trim(arguments.ShopMasterTable) />
	
	<cfif variables.Global.DSN eq "">
		<!--- test for DB name --->
		<cfthrow type="Custom" detail="DataStore DSN Not Supplied!" message="Init(): The Datastore DSN passed to the component was blank">
	</cfif>	<!--- end: path valid OK to initialize --->

  <!--- set up our threadSet for mapping categories, if it already exists it will just do nothing and return --->
  <cfset temps = application.mbc_utility.theThread.CreateThreadSet(TableName="#variables.Global.ObjectControlTable#", FieldName="ItemID") >
  <cfif temps.data neq 0><!--- check for goodness of return --->
  	<cfset variables.Global.ThreadSetID = temps.data />
  	<cfset variables.Global.ThreadSetName = "#variables.Global.ObjectControlTable#_ItemID" />
  </cfif>

	<cfreturn ret />
</cffunction>

<cffunction name="getVariables" output="yes" returntype="struct" access="public"
	displayname="get Variables scope"
	hint="this is quicky to dump the entire variables scope, returns the struct directly"
				>

	<cfreturn variables  />
</cffunction>

<cffunction name="getChildObjects" 
	access="public" output="yes" returntype="struct" 
	displayname="get Categories"
	hint="returns the categories in the specified level or parent category"
	>
	<!---  --->
	<cfargument name="ParentObject" type="string" required="no" default="" hint="parent name of wanted level">	
	<cfargument name="ParentObjectID" type="string" required="no" default="" hint="parent Object ID of wanted level">	

	<cfset var theParentID = "" />
	<cfset var getThisObject = "" />
	<cfset var getChildren = "" />	<!--- struct return from the children function --->
	<cfset var theChildren = "" />
	<cfset var getObject = "" />	<!--- localise query --->
	<cfset var rets = Structnew() />
	<cfset var Returner = Structnew() />	<!--- the standard structure for returning function calls --->
	<cfset Returner.Error = Structnew() /><!--- two returns, an error structure and data, assumed to be a struct but could be anything --->
	<cfset Returner.Error.errorcode = 0 />
	<cfset Returner.Error.errortext = "getChildObjects()<br>" />
	<cfset Returner.Data = "" />	<!--- data return, a query --->

	<cftry>
		<cfif len(arguments.ParentObject)>
			<cfquery name="getThisObject" datasource="#variables.Global.DSN#">
				select	ObjectID
					from	#variables.Global.ShopObjectDescriptionTable#
					where	ObjectName = '#arguments.ParentObject#'
			</cfquery>
			<cfset theParentID = getThisObject.ObjectID />
		<cfelseif len(arguments.ParentObjectID) and IsNumeric(arguments.ParentObjectID)>
			<cfset theParentID = arguments.ParentObjectID />
		<cfelse>
			<cfset Returner.error.ErrorCode =  BitOr(Returner.error.ErrorCode, 2) />
			<cfset Returner.error.ErrorText = Returner.error.ErrorText & 'Oops! No Object supplied<br>' />
		</cfif>
		<cfif Returner.error.ErrorCode eq 0>
			<!--- now we have a cat ID so get the children of it --->
			<cfset getChildren = application.mbc_utility.theThread.getChildValue(ThreadSetID="#variables.Global.ThreadSetID#", ExternalValue="#theParentID#") />
			<cfif getChildren.error.errorcode eq 0>
				<cfset theChildren = getChildren.data />
				<cfif len(theChildren)>
<!--- 			
			<cfdump var="#theChildren#">
			<cfabort>
 --->			
					<cfquery name="getObject" datasource="#variables.Global.DSN#">
						select	ShortDescription, LongDescription, ObjectID
							from	#variables.Global.ShopObjectDescriptionTable#
							where	ObjectID IN (#theChildren#)
								and	DO <> 0
							order by DO
					</cfquery>
					<cfset Returner.Data = getObject />
				<cfelse>
					<cfset Returner.error.ErrorCode =  BitOr(Returner.error.ErrorCode, 4) />
					<cfset Returner.error.ErrorText = Returner.error.ErrorText & 'Oops! getChildValue() returned no children<br>passed in variables were:<br>ThreadSetID=&quot;#variables.Global.ThreadSetID#&quot;; ExternalValue=&quot;#theParentID#&quot;' />
				</cfif>
			<cfelse>
				<cfset Returner.error.ErrorCode =  BitOr(Returner.error.ErrorCode, 2) />
				<cfset Returner.error.ErrorText = Returner.error.ErrorText & 'Oops! getChildValue() failed<br>error was: #getChildren.error.errorText#' />
			</cfif>
		</cfif>
	<cfcatch type="any">
		<cfset Returner.error.ErrorCode =  BitOr(Returner.error.ErrorCode, 128) />
		<cfset Returner.error.ErrorText = Returner.error.ErrorText & 'Oops! Error Caught, error message was: #cfcatch.message#, error detail was: #cfcatch.detail#<br>' />
		<cfset Returner.error.ErrorExtra =  cfcatch.TagContext />
		<cflog text="getChildObjects() Trapped. Returner.error.ErrorCode: #Returner.error.ErrorCode# - Error Text: #Returner.error.ErrorText# - Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#"  file="UtilitiesErrors" type="Error" application = "yes">
		<cfif application.SLCMS.config.debug.debugmode>
			getChildCategories() trapped - error was:<br>
			<cfdump var="#cfcatch#">
		</cfif>
	</cfcatch>
	</cftry>	
	<cfreturn Returner />
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
	<cfset Returner.Error.errorcode = 0 />
	<cfset Returner.Error.errortext = "getxxx()<br>" />
	<cfset Returner.Data = Structnew() />	<!--- data return, assumed to be a struct but can be anything --->

	<cftry>
		<!--- this is where we do stuff --->
	<cfcatch type="any">
		<cfset Returner.error.ErrorCode =  BitOr(Returner.error.ErrorCode, 128) />
		<cfset Returner.error.ErrorText = Returner.error.ErrorText & 'Oops! Error Caught, error message was: #cfcatch.message#, error detail was: #cfcatch.detail#<br>' />
		<cfset Returner.error.ErrorExtra =  cfcatch.TagContext />
		<cflog text="getxxx() Trapped. Returner.error.ErrorCode: #Returner.error.ErrorCode# - Error Text: #Returner.error.ErrorText# - Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#"  file="UtilitiesErrors" type="Error" application = "yes">
		<cfif application.SLCMS.config.debug.debugmode>
			getxxx() trapped - error was:<br>
			<cfdump var="#cfcatch#">
		</cfif>
	</cfcatch>
	</cftry>

	<cfreturn Returner />
</cffunction>

</cfcomponent>