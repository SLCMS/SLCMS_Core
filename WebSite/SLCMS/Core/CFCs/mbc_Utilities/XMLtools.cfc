<!--- mbc ToolSet CFCs  --->
<!--- quasi-&copy; 2010 mort bay communications --->
<!---  --->
<!--- XMLtools.cfc --->
<!--- a CFC to play with XML --->
<!--- a lot of the finctions here are utilities out in the public domain rolled into one package
			they various functions are credited as appropriate, 
			unnamed functions are by Kym Kovan of mbcomms
			 --->
<!--- some of the code has been wound back to allow functioning across most CFML application platforms, eg back to StructNew() instead of {}
			The base code level is CF7+ for OpenBD
			 --->
<!--- Contains:
			XmlImport - By Ben Nadel - imports XML nodes into an existing XML document
			XmlDeleteNodes - By Ben Nadel - deleted nodes in an existing XML document
			 --->
<!---  --->
<!--- created:  15th Jan 2010 by Kym K, mbcomms --->
<!--- modified: 15th Jan 2010 - 17th Jan 2010 by Kym K, mbcomms - initial work on it --->

<cfcomponent output="yes"
	displayname="XML Manipulation Utilities" 
	hint="contains standard utilities to work with XML documents"
	>

<cffunction name="init" access="public" output="no" returntype="any">		
	<cfset variables.TabUtils =	createObject('component', 'AnythingToXML.TabUtils').init() />		
	<cfset variables.XMLutils =	createObject('component', 'AnythingToXML.XMLutils').init() />			
	<cfset variables.StructToXML = createObject('component','AnythingToXML.StructToXML').init(XMLutils,TabUtils) />
	<cfset variables.QueryToXML = createObject('component','AnythingToXML.QueryToXML').init(XMLutils,TabUtils) />
	<cfset variables.ArrayToXML = createObject('component','AnythingToXML.ArrayToXML').init(XMLutils,TabUtils) />
	<cfset variables.ObjectToXML = createObject('component','AnythingToXML.ObjectToXML').init(XMLutils,TabUtils) />
			
	<cfset variables.StructToXML.setAnythingToXML(this) />
	<cfset variables.QueryToXML.setAnythingToXML(this) />
	<cfset variables.ArrayToXML.setAnythingToXML(this) />
	<cfset variables.ObjectToXML.setAnythingToXML(this) />											
	<cfreturn this>
</cffunction>

<cffunction name="ToXML" access="public" output="no" returntype="string" hint="This function converts simple types, arrays, queries, structures, objects with properties, or any combination of these to XML">
	<cfargument name="ThisItem" type="any" required="yes" hint="simple type, array, query, structure, object with properties, or any combination of previous">
	<cfargument name="NodeName" type="string" required="no" default="XML_ELEMENT" hint="name of a node">	
	<cfargument name="AttributeList" type="string" required="no" default="" hint="List of Column Names/Struct Keys that should become Attributes of the XML Node" />	
	<cfset var returnstring = "">				

	<!---initalize cfc if it is not  --->	
	<cfif not structkeyexists(variables, "TabUtils") >
		<cfset init() />
	</cfif>

	<!--- If this is the 1st time add XML encoding. Comment this out for Debugging --->
	<cfif variables.TabUtils.tabs eq 0 >
		<cfcontent type="text/xml; charset=utf-8">
		<cfset returnstring = '<?xml version="1.0" encoding="utf-8"?>' />
	</cfif>

	<!--- Decide how to create the XML --->
	<cfif isSimpleValue(ThisItem) >
		<cfset returnstring = returnstring & "#variables.TabUtils.printtabs()#<#arguments.NodeName#>#ThisItem#</#arguments.NodeName#>" />	
	<cfelseif isArray(ThisItem)>
		<cfset returnstring = returnstring & variables.ArrayToXML.ArrayToXML(arguments.ThisItem,arguments.NodeName,arguments.AttributeList)>		
	<cfelseif isQuery(ThisItem)>		
		<cfset returnstring = returnstring & variables.QueryToXML.QueryToXML(arguments.ThisItem,arguments.NodeName,arguments.AttributeList)>
	<cfelseif structkeyexists(getMetaData(ThisItem), "properties") > 				
		<cfset returnstring = returnstring & variables.ObjectToXML.ObjectToXML(arguments.ThisItem,arguments.NodeName,arguments.AttributeList)>
	<cfelseif isStruct(ThisItem)>
		<cfset returnstring = returnstring & variables.StructToXML.StructToXML(arguments.ThisItem,arguments.NodeName,arguments.AttributeList)>
	<cfelse>
		<cfset returnstring = returnstring & "#variables.TabUtils.printtabs()#<ERROR>Unable to Convert this element to XML</ERROR>" />--->
	</cfif>
	
	<cfreturn returnstring>
</cffunction>


<cffunction	name="XmlImport"	access="public"	returntype="any"	output="false"
	hint="I import the given XML data into the given XML document so that it can inserted into the node tree.">
 
	<cfargument name="ParentDocument" type="xml" required="true" hint="I am the parent XML document into which the given nodes will be imported." />
	<cfargument name="Nodes" type="any" required="true" hint="I am the XML tree or array of XML nodes to be imported. NOTE: If you pass in an array, each array index is treated as it's own separate node tree and any relationship between node indexes is ignored." />
 
	<cfset var LOCAL = StructNew() />
 
 <!---
		Check to see how the XML nodes were passed to us. If it
		was an array, import each node index as its own XML tree.
		If it was an XML tree, import recursively.
	--->
	<cfif IsArray( ARGUMENTS.Nodes )>
	 	<!--- Create a new array to return imported nodes. --->
		<cfset LOCAL.ImportedNodes = ArrayNew(1) />
		<!--- Loop over each node and import it. --->
		<cfloop index="LOCAL.Node" array="#ARGUMENTS.Nodes#">
			<!--- Import and append to return array. --->
			<cfset ArrayAppend(LOCAL.ImportedNodes, XmlImport(ARGUMENTS.ParentDocument, LOCAL.Node)) />
		</cfloop>
		<!--- Return imported nodes array. --->
		<cfreturn LOCAL.ImportedNodes />
	<cfelse>
		<!---
			We were passed an XML document or nodes or XML string.
			Either way, let's copy the top level node and then copy and append any children.
 			NOTE: Add ( ARGUMENTS.Nodes.XmlNsURI ) as second argument if you are dealing with name spaces.
		--->
		<cfset LOCAL.NewNode = XmlElemNew(ARGUMENTS.ParentDocument, ARGUMENTS.Nodes.XmlName) />
 		<!--- Append the XML attributes. --->
		<cfset StructAppend(LOCAL.NewNode.XmlAttributes, ARGUMENTS.Nodes.XmlAttributes) />
		<!--- Copy simple values. --->
		<!---
		<cfset LOCAL.NewNode.XmlNsPrefix = ARGUMENTS.Nodes.XmlNsPrefix />
		<cfset LOCAL.NewNode.XmlNsUri = ARGUMENTS.Nodes.XmlNsUri />
		--->
		<cfset LOCAL.NewNode.XmlText = ARGUMENTS.Nodes.XmlText />
		<cfset LOCAL.NewNode.XmlComment = ARGUMENTS.Nodes.XmlComment />
		<!---
			Loop over the child nodes and import them as well and then append them to the new node.
		--->
		<cfloop index="LOCAL.ChildNode" array="#ARGUMENTS.Nodes.XmlChildren#">
			<!--- Import and append. --->
			<cfset ArrayAppend(LOCAL.NewNode.XmlChildren, XmlImport(ARGUMENTS.ParentDocument, LOCAL.ChildNode)) />
		</cfloop>
		<!--- Return the new, imported node. --->
		<cfreturn LOCAL.NewNode />
	</cfif>
</cffunction>

<cffunction name="XmlDeleteNodes" access="public" returntype="void" output="false"
	hint="I remove a node or an array of nodes from the given XML document.">
 
	<cfargument name="XmlDocument" type="any" required="true" hint="I am a ColdFusion XML document object." />
	<cfargument name="Nodes" type="any" required="false" hint="I am the node or an array of nodes being removed from the given document." />
 
	<cfset var LOCAL = StructNew() />
 
	<!---
		Check to see if we have a node or array of nodes. If we
		only have one node passed in, let's create an array of
		it so we can assume an array going forward.
		--->
	<cfif NOT IsArray( ARGUMENTS.Nodes )>
		<!--- Get a reference to the single node. --->
		<cfset LOCAL.Node = ARGUMENTS.Nodes />
		<!--- Convert single node to array. --->
		<cfset ARGUMENTS.Nodes = [LOCAL.Node] />
	</cfif>
	<!---
		Flag nodes for deletion. We are going to need to delete these via the XmlChildren array of the parent, 
		so we need to be able to differentiate them from siblings.
		Also, we only want to work with actual ELEMENT nodes, not attributes or anything, 
		so let's remove any nodes that are not element nodes.
		--->
	<cfloop index="LOCAL.NodeIndex" from="#ArrayLen( ARGUMENTS.Nodes )#" to="1" step="-1">
		<!--- Get a node short-hand. --->
		<cfset LOCAL.Node = ARGUMENTS.Nodes[LOCAL.NodeIndex] />
		<!---
			Check to make sure that this node has an XmlChildren element. 
			If it does, then it is an element node. If not, then we want to get rid of it.
			--->
		<cfif StructKeyExists( LOCAL.Node, "XmlChildren" )>
			<!--- Set delete flag. --->
			<cfset LOCAL.Node.XmlAttributes["delete-me-flag"] = "true" />
		<cfelse>
			<!--- This is not an element node. Delete it from out list of nodes to delete. --->
			<cfset ArrayDeleteAt(ARGUMENTS.Nodes, LOCAL.NodeIndex) />
		</cfif>
	</cfloop>
	<!---
		Now that we have flagged the nodes that need to be deleted, we can loop over them to find their parents.
		All nodes should have a parent, except for the root node, which we cannot delete.
		--->
	<cfloop index="LOCAL.Node" array="#ARGUMENTS.Nodes#">
		<!--- Get the parent node. --->
		<cfset LOCAL.ParentNodes = XmlSearch(LOCAL.Node, "../") />
 		<!---
			Check to see if we have a parent node. We can't delete the root node, 
			and we also be deleting other elements as well - make sure it is all playing nicely together. 
			As a final check, make sure that our parent has children (only happens if we are
			dealing with the root document element).
			--->
		<cfif ArrayLen(LOCAL.ParentNodes) AND StructKeyExists(LOCAL.ParentNodes[1], "XmlChildren")>
			<!--- Get the parent node --->
			<cfset LOCAL.ParentNode = LOCAL.ParentNodes[1] />
 			<!---
				Now that we have a parent node, we want to loop over it's children to one the nodes flagged as
				deleted (and delete them). As we do this, we want to loop over the children backwards so that
				we don't go out of bounds as we start to remove child nodes.
				--->
			<cfloop index="LOCAL.NodeIndex" from="#ArrayLen( LOCAL.ParentNode.XmlChildren )#" to="1" step="-1">
 				<!--- Get the current node shorthand. --->
				<cfset LOCAL.Node = LOCAL.ParentNode.XmlChildren[LOCAL.NodeIndex] />
				<!--- Check to see if this node has been flagged for deletion. --->
				<cfif StructKeyExists(LOCAL.Node.XmlAttributes, "delete-me-flag")>
					<!--- Delete this node from parent. --->
					<cfset ArrayDeleteAt(LOCAL.ParentNode.XmlChildren, LOCAL.NodeIndex) />
					<!---
						Clean up the node by removing the deletion flag. 
						This node might still be used by another part of the program.
						--->
					<cfset StructDelete(LOCAL.Node.XmlAttributes, "delete-me-flag") />
 				</cfif>	<!--- end: delete test --->
			</cfloop>	<!--- end: loop over all children --->
		</cfif>	<!--- end: test parent has children --->
	</cfloop>	<!--- end: loop over nodes to delete --->
	<cfreturn />
</cffunction>

<!--- this function is empty, ready to clone for new ones --->
<cffunction name="emptyFunction" output="yes" returntype="struct" access="public"
	displayname="Nothing"
	hint="this is just a shell to copy, can be deleted once coding has finished, and turn off output if we don't need it to save whitespace"
	>
	<!--- this function needs.... --->
	<cfargument name="FormFullName" type="string" default="" />	<!--- the name of the form structure --->

	<!--- now all of the var declarations, first the arguments which need manipulation --->
	<cfset var theFormFullName = trim(arguments.FormFullName) />
	<!--- now vars that will get filled as we go --->
	<cfset var lcntr = 0 />	<!--- temp loop counter --->
	<cfset var temp = "" />	<!--- temp/throwaway var --->
	<cfset var tempa = ArrayNew(1) />	<!--- temp/throwaway array --->
	<cfset var temps = StructNew() />	<!--- temp/throwaway structure --->
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorContext = "theComponentName CFC: theFunctionName()" />
	<cfset ret.error.ErrorText = "" />
	<cfset ret.error.ErrorExtra = "" />
	<cfset ret.Data = "" />	<!--- and no data yet --->

		<!--- validation --->
	<cfif left(theDataBaseName, 9) neq "mbcStats_">
		<cfset theDataBaseName = "mbcStats_" & theDataBaseName />
	</cfif>
	<cfif len(theDataBaseName) gt 9>
		<!--- validated so go for it --->
		<!--- wrap the whole thing in a try/catch in case something breaks --->
		<cftry>
		<cfcatch type="any">
			<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 128) />
			<cfset ret.error.ErrorText = ret.error.ErrorContext & ' Trapped. Site: #application.SLCMS.config.base.SiteName#, error message was: #cfcatch.message#, error detail was: #cfcatch.detail#' />
			<cfset ret.error.ErrorExtra =  cfcatch.TagContext />
			<cfif isArray(ret.error.ErrorExtra) and StructKeyExists(ret.error.ErrorExtra[1], "Raw_Trace")>
				<cfset ret.error.ErrorText = ret.error.ErrorText & ", Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#" />
			</cfif>
			<cflog text='#ret.error.ErrorText# - ret.error.ErrorCode: #ret.error.ErrorCode# - Time: #DateFormat(Now(),"YYYYMMDD")#-#TimeFormat(now(),"HH:mm:ss")#'  file="#Application.Logging.theSiteLogName#" type="Error" application = "yes">
			<cfif application.SLCMS.config.debug.debugmode>
				<cfoutput>#ret.error.ErrorContext#</cfoutput> Trapped - error dump:<br>
				<cfdump var="#cfcatch#">
			</cfif>
		</cfcatch>
		</cftry>
	<cfelse>	<!--- this is the error code --->
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 1) />
		<cfset ret.error.ErrorText = ret.error.ErrorText & "Oops!<br>" />
	</cfif>

	<!--- return our data structure --->
	<cfreturn ret  />
</cffunction>

</cfcomponent>
