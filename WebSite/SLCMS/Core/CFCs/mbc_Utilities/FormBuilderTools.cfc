<!--- FormBuilderTools.cfc --->
<!---  --->
<!--- CFC containing functions that relate to the mbcomms Form Building engine --->
<!---  --->
<!--- &copy; mortbay communications 2007 --->
<!---  --->
<!--- Created:  09th Apr 2007 by Kym K --->
<!--- Modified: 09th Apr 2007 - 14th Apr 2007 by Kym K, working on it  --->


<cfcomponent output="no"
	displayname="FormBuilder Tools"
	hint="set of tools to create FormBuilder structures and display them">

	<!--- set up a few persistant things on the way in. --->
	<cfset variables.Forms = StructNew() />	<!--- this will persistently contain all of the form structures --->

<!--- initialise the various thingies, this should only be called after an app scope refresh or similar --->
<cffunction name="init" access="public" output="yes" returntype="struct" hint="sets up the internal structures for this component">
</cffunction>

<cffunction name="getForm" output="yes" returntype="string" access="public"
	displayname="get Form"
	hint="gets the specified form if it exists, else creates a an empty struct and returns handle">
	<!--- this function needs an ini file path, the supplied structure is optional --->
	<cfargument name="Name" type="string" default="">	<!--- the friendly name of the form --->
	<cfargument name="Serial" type="string" default="">	<!--- the serial of the form --->
	<cfargument name="Version" type="string" default="">	<!--- the version number of the form --->

	<cfset var ret = "" />
	<cfset var theName = trim(arguments.Name) />
	<cfset var theSerial = trim(arguments.Serial) />
	<cfset var theVersion = trim(arguments.Version) />
	<cfset var FormFullName = "FormBuilder_Form_#theName#_#theSerial#_#theVersion#" />
	
	<!--- we are just creating new form everytime for the moment until we get the save function working --->
	<cfset variables.Forms[FormFullName] = Structnew() />
	<cfset variables.Forms[FormFullName].Specification = StructNew() />
	<cfset variables.Forms[FormFullName].Specification.Mode = StructNew() />
	<cfset variables.Forms[FormFullName].Specification.Mode.Status = "CreationInProgress" />
	<cfset variables.Forms[FormFullName].Specification.Mode.Designer = StructNew() />
	<cfset variables.Forms[FormFullName].Specification.Mode.Designer.mode = "CreationInProgress" />
	<cfset variables.Forms[FormFullName].Specification.Mode.Designer.activePane = 1 />
	<cfset variables.Forms[FormFullName].Specification.Mode.Designer.activeTab = 1 />
	<cfset variables.Forms[FormFullName].Specification.Mode.Designer.activeRow = 1 />

	<cfreturn FormFullName  />
</cffunction>

<cffunction name="getFormDataItem" output="yes" returntype="any" access="public"
	displayname="Get a Specific Data Item"
	hint="Returns the requested data item, returns an empty string if it doesn't exist yet
				Items available:- 
				All: returns the entire Form structure
				FormName: returns HTML/DOM Form Name
				">
	<!--- this function needs.... --->
	<cfargument name="FormFullName" type="string" default="" />	<!--- the name of the form structure --->
	<cfargument name="DataItem" type="string" default="All" />	<!--- the name of the item to return --->

	<cfset var ret = StructNew() />
	<cfset ret.Error = StructNew() />
	<cfset ret.Data = StructNew() />
	<cfset ret.Error.Code = 0 />
	<cfset ret.Error.Data = "" />
	
	<cfswitch expression="#arguments.DataItem#">
		<cfcase value="All">
			<cfset ret.Data = variables.Forms />
			<!--- 
			<cfset ret = variables.Forms[arguments.FormFullName] />
			 --->
		</cfcase>
		<cfcase value="FormName">
			<cfset ret.Data = variables.Forms[arguments.FormFullName].Specification.FormName />
		</cfcase>
		<cfdefaultcase>
			<cfset ret.Error.Code = -1 />
			<cfset ret.Error.Data = "No Data Item Supplied" />
		</cfdefaultcase>
	</cfswitch>

	<cfreturn ret  />
</cffunction>

<cffunction name="CreateForm" output="yes" returntype="string" access="public"
	displayname="Create Form"
	hint="Creates a base, viable form structure, ie a completely empty form">
	<cfargument name="FormFullName" type="string" default="" />	<!--- the name of the form structure --->
	<cfargument name="DOMname" type="string" default="" />
	<cfargument name="DOMid" type="string" default="#arguments.DOMname#" />
	<cfargument name="WrapperDivID" type="string" default="" />
	<cfargument name="ErrorDivID" type="string" default="errorDisplay" />
	<cfargument name="ActionSource" type="string" default="self" />
	<cfargument name="ActionValue" type="string" default="#cgi.script_name#" />
	<cfargument name="ActionScope" type="string" default="" />
	<cfargument name="SubmitPosition" type="string" default="Below" />
	<cfargument name="SubmitName" type="string" default="Submit" />
	<cfargument name="SubmitValue" type="string" default="Save" />
	<cfargument name="SubmitDivID" type="string" default="SubmitDisplayDiv" />
	<cfargument name="ActivePane" type="string" default="" />
	<cfargument name="ActiveTab" type="string" default="" />
	
	<!--- set up the base form actions, etc --->
	<cfset variables.Forms[arguments.FormFullName].Specification.FormName = arguments.DOMname />
	<cfset variables.Forms[arguments.FormFullName].Specification.Formid = arguments.DOMid />
	<cfset variables.Forms[arguments.FormFullName].Specification.WrapperDivID = arguments.WrapperDivID />
	<cfset variables.Forms[arguments.FormFullName].Specification.ErrorDivID = arguments.ErrorDivID />
	<cfset variables.Forms[arguments.FormFullName].Specification.FormAction = StructNew()>
	<cfset variables.Forms[arguments.FormFullName].Specification.FormAction.Source = arguments.ActionSource>	<!--- self|string|variable --->
	<cfset variables.Forms[arguments.FormFullName].Specification.FormAction.value = arguments.ActionValue>		<!--- string or variable name --->
	<cfset variables.Forms[arguments.FormFullName].Specification.FormAction.Scope = arguments.ActionScope>	<!--- if a variable this is the scope of it variables|application|session, etc --->
	
	<!--- set up the submit button structure --->
	<cfset variables.Forms[arguments.FormFullName].Specification.Submit = StructNew() />
	<cfif arguments.SubmitPosition eq "Above" or arguments.SubmitPosition eq "Both">
		<cfset variables.Forms[arguments.FormFullName].Specification.Submit.ShowSubmitAbove = True />
	<cfelse>
		<cfset variables.Forms[arguments.FormFullName].Specification.Submit.ShowSubmitAbove = False />
	</cfif>
	<cfif arguments.SubmitPosition eq "Below" or arguments.SubmitPosition eq "Both">
		<cfset variables.Forms[arguments.FormFullName].Specification.Submit.ShowSubmitBelow = true />
	<cfelse>
		<cfset variables.Forms[arguments.FormFullName].Specification.Submit.ShowSubmitBelow = False />
	</cfif>
	<cfset variables.Forms[arguments.FormFullName].Specification.Submit.Value = arguments.SubmitValue />
	<cfset variables.Forms[arguments.FormFullName].Specification.Submit.Name = arguments.SubmitName />
	<cfset variables.Forms[arguments.FormFullName].Specification.Submit.SubmitDivID = arguments.SubmitDivID />
	<!--- set up the default viewing space of defined --->
	<cfif len(arguments.ActivePane)>
		<cfset variables.Forms[FormFullName].Specification.Mode.Designer.activePane = arguments.ActivePane />
	</cfif>
	<cfif len(arguments.activeTab)>
		<cfset variables.Forms[FormFullName].Specification.Mode.Designer.activeTab = arguments.activeTab />
	</cfif>
	<!--- lastly a couple of placeholders for later --->
	<cfset variables.Forms[arguments.FormFullName].Specification.HiddenFieldCount = 0 />
	<cfset variables.Forms[arguments.FormFullName].PaneCount = 0 />
	
	<cfreturn arguments.FormFullName  />
</cffunction>

<cffunction name="AddPane" output="yes" returntype="string" access="public"
	displayname="Add a Pane"
	hint="add a pane to the named form, returns its number">
	<cfargument name="FormFullName" type="string" default="" />	<!--- the name of the form structure --->
	<cfargument name="PaneStyle" type="string" default="Tab" />	<!--- display style, tabs or accordian --->
	<cfargument name="PaneClass" type="string" default="" />		<!--- the stylesheet class for the pane wrapper div, if any --->
	<cfargument name="PaneID" type="string" default="" />				<!--- the stylesheet id for the pane wrapper div, if any --->
	<cfargument name="TabsClass" type="string" default="" />		<!--- the stylesheet class for the tabs themselves, if any --->
	<cfargument name="TabsID" type="string" default="" />				<!--- the stylesheet id for the tabs themselves, if any --->

	<cfset var PaneNumber = variables.Forms[arguments.FormFullName].PaneCount+1 />
	<cfset variables.Forms[arguments.FormFullName].PaneCount = PaneNumber />
	<cfset variables.Forms[arguments.FormFullName]["Pane#PaneNumber#"] = StructNew() />
	<cfset variables.Forms[arguments.FormFullName]["Pane#PaneNumber#"].PaneType = arguments.PaneStyle />
	<cfset variables.Forms[arguments.FormFullName]["Pane#PaneNumber#"].PaneClass = arguments.PaneClass />
	<cfset variables.Forms[arguments.FormFullName]["Pane#PaneNumber#"].PaneID = arguments.PaneID />
	<cfset variables.Forms[arguments.FormFullName]["Pane#PaneNumber#"].TabCount = "0" />
	<cfset variables.Forms[arguments.FormFullName]["Pane#PaneNumber#"].TabsClass = arguments.TabsClass />
	<cfset variables.Forms[arguments.FormFullName]["Pane#PaneNumber#"].TabsID = arguments.TabsID />
	<cfset variables.Forms[arguments.FormFullName].Specification.Mode.Designer.activePane = PaneNumber />

	<cfreturn PaneNumber  />
</cffunction>

<cffunction name="AddTab" output="yes" returntype="string" access="public"
	displayname="Add a Tab"
	hint="add a pane to the named form, returns its number">
	<cfargument name="FormFullName" type="string" default="" />	<!--- the name of the form structure --->
	<cfargument name="PaneNumber" type="string" default="" />
	<cfargument name="TabType" type="string" default="Table" />
	<cfargument name="TabLabel" type="string" default="" />
	<cfargument name="TabTitle" type="string" default="" />
	<cfargument name="TabClass" type="string" default="" />
	<cfargument name="TabId" type="string" default="" />
	<cfargument name="ColumnCount" type="numeric" default=2 />

	<cfset var TabNumber = variables.Forms[arguments.FormFullName]["Pane#PaneNumber#"].TabCount+1 />
	<cfset variables.Forms[arguments.FormFullName]["Pane#PaneNumber#"].TabCount = TabNumber />
	<cfset variables.Forms[arguments.FormFullName]["Pane#PaneNumber#"]["Tab#TabNumber#"] = StructNew() />
	<cfset variables.Forms[arguments.FormFullName]["Pane#PaneNumber#"]["Tab#TabNumber#"].Type = arguments.TabType />
	<cfset variables.Forms[arguments.FormFullName]["Pane#PaneNumber#"]["Tab#TabNumber#"].Label = arguments.TabLabel />
	<cfset variables.Forms[arguments.FormFullName]["Pane#PaneNumber#"]["Tab#TabNumber#"].Title = arguments.TabTitle />
	<cfset variables.Forms[arguments.FormFullName]["Pane#PaneNumber#"]["Tab#TabNumber#"].TabClass = arguments.TabClass />
	<cfset variables.Forms[arguments.FormFullName]["Pane#PaneNumber#"]["Tab#TabNumber#"].TabID = arguments.TabID />
	<cfset variables.Forms[arguments.FormFullName]["Pane#PaneNumber#"]["Tab#TabNumber#"].ColumnCount = arguments.ColumnCount />
	<!--- and set/rejig a couple of defaults --->
	<cfset variables.Forms[arguments.FormFullName]["Pane#PaneNumber#"]["Tab#TabNumber#"].RowCount = 0 />
	<cfset variables.Forms[arguments.FormFullName].Specification.Mode.Designer.activeTab = TabNumber />

	<cfreturn TabNumber  />
</cffunction>

<cffunction name="AddRow" output="yes" returntype="string" access="public"
	displayname="Add a Tab"
	hint="add a pane to the named form, returns its number">
	<cfargument name="FormFullName" type="string" default="" />	<!--- the name of the form structure --->
	<cfargument name="PaneNumber" type="string" default="1" />
	<cfargument name="TabNumber" type="numeric" default="1" />
	<cfargument name="Type" type="string" default="" />
	<cfargument name="Source" type="string" default="" />
	<cfargument name="Value" type="string" default="" />
	<cfargument name="Scope" type="string" default="" />
	<cfargument name="ColumnStart" type="numeric" default=1 />
	<cfargument name="ColumnCount" type="numeric" default=2 />

	<cfset var RowNumber = variables.Forms[arguments.FormFullName]["Pane#PaneNumber#"]["Tab#TabNumber#"].RowCount+1 />
	<cfset variables.Forms[arguments.FormFullName]["Pane#PaneNumber#"]["Tab#TabNumber#"].RowCount = RowNumber />
	<cfset variables.Forms[arguments.FormFullName]["Pane#PaneNumber#"]["Tab#TabNumber#"]["Row#RowNumber#"] = StructNew() />
	<cfset variables.Forms[arguments.FormFullName]["Pane#PaneNumber#"]["Tab#TabNumber#"]["Row#RowNumber#"].ColStart = arguments.ColumnStart />
	<cfset variables.Forms[arguments.FormFullName]["Pane#PaneNumber#"]["Tab#TabNumber#"]["Row#RowNumber#"].ColCount = arguments.ColumnCount />
	<cfset variables.Forms[arguments.FormFullName]["Pane#PaneNumber#"]["Tab#TabNumber#"]["Row#RowNumber#"].Type = arguments.Type />
	<cfset variables.Forms[arguments.FormFullName]["Pane#PaneNumber#"]["Tab#TabNumber#"]["Row#RowNumber#"][arguments.Type] = StructNew() />
	<cfset variables.Forms[arguments.FormFullName]["Pane#PaneNumber#"]["Tab#TabNumber#"]["Row#RowNumber#"][arguments.Type].Value = StructNew() />
	<cfset variables.Forms[arguments.FormFullName]["Pane#PaneNumber#"]["Tab#TabNumber#"]["Row#RowNumber#"][arguments.Type].Value.Source = arguments.Source />
	<cfset variables.Forms[arguments.FormFullName]["Pane#PaneNumber#"]["Tab#TabNumber#"]["Row#RowNumber#"][arguments.Type].Value.Value = arguments.Value />
	<cfset variables.Forms[arguments.FormFullName]["Pane#PaneNumber#"]["Tab#TabNumber#"]["Row#RowNumber#"][arguments.Type].Value.Scope = arguments.Scope />

	<cfreturn RowNumber  />
</cffunction>

<cffunction name="ShowHeadLinks" output="yes" returntype="string" access="public"
	displayname="get the HTML Head"
	hint="gets the styles and js links for the page">
	<!--- this function needs.... --->
	<cfargument name="Config" type="struct" required="Yes" />	<!--- the config structure that has the paths, etc --->

	<cfset var ret = "" />
	<cfif len(arguments.Config.ValidatorStylesURL)>
		<cfset ret = ret & '<link href="#arguments.Config.ValidatorStylesURL#" rel="stylesheet" type="text/css" />' & chr(13) & chr(10) />
	</cfif>
	<cfif len(arguments.Config.FormStylesURL)>
		<cfset ret = ret & '<link href="#arguments.Config.FormStylesURL#" rel="stylesheet" type="text/css" />' & chr(13) & chr(10) />
	</cfif>
	<cfif len(arguments.Config.FormjsURL)>
		<cfset ret = ret & '<script src="#arguments.Config.FormjsURL#" type="text/javascript"></script>' & chr(13) & chr(10) />
	</cfif>
	<cfif len(arguments.Config.ErrorDisplayjsURL)>
		<cfset ret = ret & '<script src="#arguments.Config.ErrorDisplayjsURL#" type="text/javascript"></script>' & chr(13) & chr(10) />
	</cfif>
	<cfif len(arguments.Config.ValidatorjsURL)>
		<cfset ret = ret & '<script src="#arguments.Config.ValidatorjsURL#" type="text/javascript"></script>' & chr(13) & chr(10) />
	</cfif>

	<cfreturn ret  />
</cffunction>

<cffunction name="ShowForm" output="yes" returntype="string" access="public"
	displayname="Displays Form"
	hint="this function shows the entire form, calling lots of other functions in the process">
	<!--- this function needs the form name as a minimum, nothing else --->
	<cfargument name="FormFullName" type="string" default="" />	<!--- the name of the form structure --->

	<cfset var ret = "" />	<!--- this will become the content as it is created --->
	<cfset var theForm = variables.Forms[arguments.FormFullName]>
	
	<cfset ret = FormWrap(FormStruct=theForm, place="Before")>
	<cfloop index="thisPane" from="1" to="#theForm.PaneCount#">
		<cfif StructKeyExists(theForm, "Pane#thisPane#")>
			<cfset ret = ret & ShowPane(PaneData="#theForm['Pane#thisPane#']#", FormSpecification="#theForm.Specification#", PaneNumber="#thisPane#")>
		</cfif>
	</cfloop>
	<cfset ret = ret & FormWrap(FormStruct=theForm, place="After")>
	
	<cfreturn ret  />
</cffunction>

<cffunction name="FormWrap" output="yes" returntype="string" access="public"
	displayname="Form Wrapper"
	hint="show the html code wrapping the form including the form tag itself">
	<!--- this function needs.... --->
	<cfargument name="FormStruct" type="struct" default="" />	<!--- the form structure --->
	<cfargument name="Place" type="string" default="" />	<!--- the the top or the bottom bit --->

	<cfset var ret = "" />
	<cfset var theForm = arguments.FormStruct />
<!--- 
	<cfdump var="#theForm#"><cfabort>
 --->
	<cfif IsStruct(theForm.Specification) and (StructIsEmpty(theForm.Specification) or not StructKeyExists(theForm.Specification, "wrapperDivID"))>
		<cfthrow message="Missing keys in theForm data structure" type="formTag">
	</cfif>
	
	<cfif arguments.Place eq "Before">
		<cfif theForm.Specification.FormAction.source eq "self">
			<cfset theAction = cgi.script_name />
		<cfelseif theForm.Specification.FormAction.source eq "string">
			<cfset theAction = theForm.Specification.FormAction.value />
		<cfelse>
			<cfset theAction = evaluate("#theForm.Specification.FormAction.scope#.#theForm.Specification.FormAction.value#") />
		</cfif>
		<!--- now start making content --->
		<cfSaveContent variable="ret">
		<cfoutput>
		<div id="#theForm.Specification.wrapperDivID#">
		<form action="#theAction#" name="#theForm.Specification.FormName#" id="#theForm.Specification.formid#" method="post" vldt:validate="true" vldt:callback="displayError">
		<cfif theForm.Specification.HiddenFieldCount neq 0>
			<cfloop index="thisFld" from="1" to="#theForm.Specification.HiddenFieldCount#">
				<!--- we have to work out what to put in the name and value fields --->
				<!--- first the name then repeat for the value --->
				<cfif theForm.Specification.hiddenFields['Field#thisFld#'].Name.source eq "static">
					<!--- the value is a static item so its right there --->
					<cfset theName = theForm.Specification.hiddenFields['Field#thisFld#'].Name.value />
				<cfelse>
					<!--- the value is dynamic so work it out --->
					<cfset theScope = theForm.Specification.hiddenFields['Field#thisFld#'].Name.scope>
					<cfset theVariableName = theForm.Specification.hiddenFields['Field#thisFld#'].Name.value>
					<cfif theScope eq "session">
						<cfset theName = session[theVariableName] />
					<cfelseif theScope eq "request">
						<cfset theName = request[theVariableName] />
					<cfelseif theScope eq "application">
						<cfset theName = application[theVariableName] />
					<cfelseif theScope eq "form">
						<cfset theName = form[theVariableName] />
					<cfelseif theScope eq "url">
						<cfset theName = url[theVariableName] />
					<cfelseif theScope eq "server">
						<cfset theName = server[theVariableName] />
					<cfelseif theScope eq "variables">
						<cfset theName = variables[theVariableName] />
					<cfelse>
						<cfset theName = "" />
					</cfif>
					<!--- <cfset theValue = evaluate(thisRowSpec.Input.Value.value) /> 
					<cfset theName = evaluate("attributes.hiddenFields['Field#thisFld#'].Name.scope[attributes.hiddenFields['Field#thisFld#'].Name.value]") />
					<cfset theValue = evaluate("[]") />--->
				</cfif>
				<!--- now we do it again for the value --->
				<cfif theForm.Specification.hiddenFields['Field#thisFld#'].value.source eq "static">
					<!--- the value is a static item so its right there --->
					<cfset theValue = theForm.Specification.hiddenFields['Field#thisFld#'].Value.value />
				<cfelse>
					<!--- the value is dynamic so work it out --->
					<cfset theScope = theForm.Specification.hiddenFields['Field#thisFld#'].Value.scope>
					<cfset theVariableName = theForm.Specification.hiddenFields['Field#thisFld#'].Value.value>
					<cfif theScope eq "session" and StructKeyExists(session, theVariableName)>
						<cfset theValue = session[theVariableName] />
					<cfelseif theScope eq "request" and StructKeyExists(request, theVariableName)>
						<cfset theValue = request[theVariableName] />
					<cfelseif theScope eq "application" and StructKeyExists(application, theVariableName)>
						<cfset theValue = application[theVariableName] />
					<cfelseif theScope eq "form" and StructKeyExists(form, theVariableName)>
						<cfset theValue = form[theVariableName] />
					<cfelseif theScope eq "url" and StructKeyExists(url, theVariableName)>
						<cfset theValue = url[theVariableName] />
					<cfelseif theScope eq "server" and StructKeyExists(server, theVariableName)>
						<cfset theValue = server[theVariableName] />
					<cfelseif theScope eq "variables" and StructKeyExists(variables, theVariableName)>
						<cfset theValue = variables[theVariableName] />
					<cfelse>
						<cfset theValue = "" />
					</cfif>
				</cfif>
				<input type="hidden" name="#theName#" value="#theValue#" />
			</cfloop>
		</cfif>
		<cfif IsStruct(theForm.Specification.Submit) and  theForm.Specification.Submit.ShowSubmitAbove>
			<cfoutput>
			<div id="#theForm.Specification.Submit.SubmitDivID#">
			<input type="submit" value="#theForm.Specification.Submit.Value#" name="#theForm.Specification.Submit.Name#" />
			</div></cfoutput>
		</cfif>
		</cfoutput>
		</cfsavecontent>
	
	<cfelseif arguments.Place eq "After">
		<!--- the code to complete the form --->
		<cfSaveContent variable="ret">
		<cfif IsStruct(theForm.Specification.Submit) and  theForm.Specification.Submit.ShowSubmitBelow>
			<cfoutput>
			<div id="#theForm.Specification.Submit.SubmitDivID#">
			<input type="submit" value="#theForm.Specification.Submit.Value#" name="#theForm.Specification.Submit.Name#" />
			</div></cfoutput>
		</cfif>
		</form><cfoutput>
		<div id="#theForm.Specification.ErrorDivID#"><span></span></div>
		</div>
		</cfoutput>
		</cfsavecontent>

	<cfelse>
		<!--- error in argument --->	
		<cfthrow message="Bad Place Argument, not &quot;Before&quot; or &quot;After&quot;." type="formTag">
	</cfif>

	<cfreturn ret  />
</cffunction>

<cffunction name="ShowPane" output="yes" returntype="string" access="public"
	displayname="Show  Pane"
	hint="show the specified pane in the specified Form">
	<!--- this function needs.... --->
	<cfargument name="PaneData" type="struct" required="Yes" />	<!--- the Pane structure --->
	<cfargument name="FormSpecification" type="struct" required="Yes" />	<!--- the specification of the form --->
	<cfargument name="PaneNumber" type="numeric" required="Yes" />	<!--- the number of this pane --->

	<cfset var ret = "" />
	<cfset var i = 0 />
	<cfset var thisTab = "" />
	<cfset var PaneclassStr = "" />
	<cfset var PaneidStr = "" />
	<cfset var TabsclassStr = "" />
	<cfset var TabsidStr = "" />
	
	<cfif len(arguments.PaneData.PaneClass)>
		<cfset PaneclassStr = ' class="#arguments.PaneData.PaneClass#"' />
	</cfif>
	<cfif len(arguments.PaneData.PaneID)>
		<cfset PaneidStr = ' id="#arguments.PaneData.PaneID#"' />
	</cfif>
	<cfif len(arguments.PaneData.TabsClass)>
		<cfset TabsClassStr = ' class="#arguments.PaneData.TabsClass#"' />
	</cfif>
	<cfif len(arguments.PaneData.TabsID)>
		<cfset TabsidStr = ' id="#arguments.PaneData.TabsID#"' />
	</cfif>

	<cfset ret = ret & '<div#PaneclassStr##PaneidStr#>'>	<!--- wrap the pane in a div --->
	<cfif arguments.PaneData.TabCount gt 0>	<!--- only show the pane if it has content --->
		<!--- show the tabs themselves --->
		<cfset ret = ShowPaneTabs(PaneData=arguments.PaneData, selectedtab="#arguments.FormSpecification.Mode.Designer.ActiveTab#") />
		<!--- <bldf:tabgroup selectedtab="#attributes.FormSpecification.Mode.Designer.ActiveTab#"> --->
		<cfset ret = ret & '<div#TabsClassStr##TabsidStr#>'>	<!--- wrap the total tab content in a div --->
		<cfloop index="thisTab" from="1" to="#arguments.PaneData.TabCount#">
			<!--- and wrap each tab panel in its div and make visble the the selected one, by default they are all off in the style sheet --->
			<cfif i EQ arguments.FormSpecification.Mode.Designer.ActiveTab>
				<cfset ret = ret & '<div class="tmtPanel" style="display:block;">'>
			<cfelse>
				<cfset ret = ret & '<div class="tmtPanel">'>
			</cfif>
			<cfset ret = ret & ShowTabContent(TabData="#arguments.PaneData['Tab#thisTab#']#", FormSpecification="#arguments.FormSpecification#", PaneNumber="#arguments.PaneNumber#", TabNumber="#thisTab#") />
			<!--- <bldf:ShowTab TabData="#attributes.PaneData['Tab#thisTab#']#" FormSpecification="#attributes.FormSpecification#" PaneNumber="#attributes.PaneNumber#" TabNumber="#thisTab#" /> --->
			<cfset ret = ret & "</div>" />
		</cfloop>
		<!--- close the Tab wrapper div --->
		<cfset ret = ret & "</div>" />
		<cfset ret = ret & ShowTabControl(PaneData=arguments.PaneData, selectedtab="#arguments.FormSpecification.Mode.Designer.ActiveTab#") />
		<!--- </bldf:tabgroup> --->
	</cfif>
	<!--- close the Pane wrapper div --->
	<cfset ret = ret & "</div>" />
	
	<cfreturn ret  />
</cffunction>

<cffunction name="ShowPaneTabs" output="yes" returntype="string" access="public"
	displayname="Shows a the Tabs in a Pane"
	hint="loops over the tabs in the specified pane and generates the Tab HTML, not the content itself">
	<!--- this function needs.... --->
	<cfargument name="PaneData" type="struct" required="Yes" />	<!--- data structure for this set of tabs --->
	<cfargument name="selectedtab" type="numeric" default="1" />	<!--- which tab is selected --->

	<cfset var ret = "" />
	<cfset var ret1 = "" />
	<cfset var i = 0 />
	<cfset var classStr = "" />
	<cfset var idStr = "" />
	<cfset var titleStr = "" />
	
	<cfif len(arguments.PaneData.TabsClass)>
		<cfset classStr = ' class="#arguments.PaneData.TabsClass#"' />
	</cfif>
	<cfif len(arguments.PaneData.TabsID)>
		<cfset idStr = ' id="#arguments.PaneData.TabsID#"' />
	</cfif>

	<!--- Ensure selectedtab is in range --->
	<cfif arguments.selectedtab gt arguments.PaneData.tabCount or arguments.selectedtab lt 1>
		<cfthrow message="ShowPaneTabs: selectedtab attribute is out of range" type="ShowPaneTabs">
	</cfif>

	<cfset ret = '<div#classStr##idStr#>'>

	<cfSaveContent variable="ret1" >
		<!--- Print tabs --->
		<cfloop index="i" from="1" to="#arguments.PaneData.tabCount#">
			<cfset classStr = "" />
			<cfset idStr = "" />
			<cfset titleStr = "" />
			<cfif len(arguments.PaneData["Tab#i#"].TabClass)>
				<cfif i EQ arguments.selectedtab>
					<!--- This tab should be visible by default --->
					<cfset classStr = ' class="tmtTabselected #arguments.PaneData['Tab#i#'].TabClass#"'>
				<cfelse>
					<cfset classStr = ' class="#arguments.PaneData['Tab#i#'].TabClass#"'>
				</cfif>
			</cfif>
			<cfif len(arguments.PaneData['Tab#i#'].Tabid)>
				<cfset idStr = ' id="#arguments.PaneData['Tab#i#'].Tabid#"'>
			</cfif>
			<cfif len(arguments.PaneData['Tab#i#'].title)>
				<cfset titleStr = ' title="#arguments.PaneData['Tab#i#'].title#"'>
			</cfif>
			<cfoutput>
			<a href="javascript:;" onclick="tmt_tabSwitch(this, 'tmtTabselected')"#classStr##idStr##titleStr#>#arguments.PaneData['Tab#i#'].label#</a>
			</cfoutput>
		</cfloop>
	</cfsavecontent>
	
	<cfset ret = ret & ret1 & "</div>" />
	<cfreturn ret  />
</cffunction>

<cffunction name="ShowTabContent" output="yes" returntype="string" access="public"
	displayname="Shows the content of a Group of Tabs in a Pane"
	hint="loops over the tabs in the specified pane and generates the content HTML">
	<!--- this function needs.... --->
	<cfargument name="TabData" type="struct" required="Yes" />	<!--- data structure for this tab --->
	<cfargument name="FormSpecification" type="struct" required="Yes" />	<!--- the specification of the form --->
	<cfargument name="PaneNumber" type="numeric" required="Yes" />	<!--- the number of this pane --->
	<cfargument name="TabNumber" type="numeric" default="1" />			<!--- which tab is this one --->

	<cfset var ret = "" />
	<cfset var i = 0 />
	<cfset var thisRow = 0 />
	<cfset var thisRowSpec = StructNew()/>
	<cfset var theValue = "" />
	<cfset var theArray = ArrayNew(1) />
	<cfset var theQuery = QueryNew("c") />
	<cfset var theStructure = StructNew()/>
	<cfset var padColcnt = 0 />
	<cfset var optVal = 0 />
	<cfset var lcntr = 0 />
	<cfset var itemChecked = "" />
	<cfset var itemSelected = "" />

	<cfSaveContent variable="ret"><cfoutput>
		<cfif arguments.FormSpecification.Mode.designer.mode eq "Design">
			<table border="0" cellpadding="0" cellspacing="0" width="100%"><cfoutput>
			<tr>
				<td><cfif arguments.TabNumber neq arguments.Mode.Designer.ActiveTab><a href="formBuilder.cfm?task=makeTabActive&Iam=#arguments.Iam#">Make this Tab the Active Tab</a> | </cfif><a href="formBuilder.cfm?task=editTab&Iam=#arguments.Iam#">Edit Tab Configuration</a>
				</td>
				<td align="right"><a href="formBuilder.cfm?task=AddTab&Iam=#arguments.Iam#">Add Tab</a> | <a href="formBuilder.cfm?task=AddRow&Iam=#arguments.Iam#">Add Row to this Tab</a>
				</td>
				</tr>
			</table></cfoutput>
		</cfif>
		<cfif arguments.TabData.Type eq "Table">
			<table border="0" cellpadding="0" cellspacing="0">
		<cfelse>
			<div>
		</cfif>
<!--- 	
<cfdump var="#arguments.TabData#">
 --->
		<cfloop index="thisRow" from="1" to="#arguments.TabData.RowCount#">
			<cfset thisRowSpec = arguments.TabData["Row#thisRow#"]>
			<cfif thisRowSpec.Type eq "Input" and ListFindNoCase("text,hidden,textarea,checkbox,radio", thisRowSpec.Input.FieldType)>
				<cfif thisRowSpec.Input.value.source eq "static">
					<cfset theValue = thisRowSpec.Input.Value.value />
				<cfelse>
					<!--- <cfset theValue = evaluate(thisRowSpec.Input.Value.value) /> --->
					<cfset theValue = getValue(thisRowSpec.Input.Value.scope, thisRowSpec.Input.Value.value) />
					<!--- <cfset theScope = thisRowSpec.Input.Value.scope>
					<cfset thisValue = thisRowSpec.Input.Value.value>
					<cfset theValue = request[thisRowSpec.Input.Value.value]> --->
					<!--- <cfset theValue = [theScope]["##"] /> --->
					<!--- <cfset theValue = StructFind(thisRowSpec.Input.Value.scope, thisRowSpec.Input.Value.value) /> --->
				</cfif>
			<cfelseif thisRowSpec.Type eq "Note">
				<cfif thisRowSpec.Note.value.source eq "static">
					<cfset theValue = thisRowSpec.Note.Value.value />
				<cfelse>
					<cfset theValue = getValue(thisRowSpec.Note.Value.scope, thisRowSpec.Note.Value.value) />
				</cfif>
			</cfif>
<!--- 			
			<cfdump var="#thisRowSpec#"><cfabort>
 --->			
			<cfoutput>
			<tr>
			<cfif thisRowSpec.Type eq "Blank">
				<td colspan="#thisRowSpec.ColCount#"><cfif arguments.Mode.flgInDesignMode>this is a blank row <a href="formBuilder.cfm?task=editRow&Iam=#arguments.Iam#,Row#thisRow#">edit</a></cfif></td>
			<cfelseif thisRowSpec.Type eq "Note">
				<cfset padColcnt = thisRowSpec.ColStart-1>
				<cfif padColcnt gt 0>
					<td colspan="#padColcnt#"></td>
				<cfelse>
				</cfif>
				<td colspan="#thisRowSpec.ColCount#">#theValue#</td>
			<cfelseif thisRowSpec.Type eq "Input">
				<cfif thisRowSpec.Input.FieldType eq "text">
					<td align="#thisRowSpec.input.LabelAlign#"><label for="#thisRowSpec.Input.id#">#thisRowSpec.Input.LabelText#</label></td>
					<td align="#thisRowSpec.input.FieldAlign#">
						<input type="text" 
							<cfif len(thisRowSpec.Input.id)> id="#thisRowSpec.Input.id#"</cfif>
							<cfif len(thisRowSpec.Input.name)> name="#thisRowSpec.Input.name#" </cfif>
							<cfif len(thisRowSpec.Input.class)> class="#thisRowSpec.Input.class#" </cfif>
							value="#theValue#"
							<cfif thisRowSpec.Input.validate>
								vldt:required="#thisRowSpec.Input.validator.required#" 
								vldt:errorclass="#thisRowSpec.Input.validator.errorclass#" 
								vldt:message="#thisRowSpec.Input.validator.message#" 
								vldt:filters="#thisRowSpec.Input.validator.filters#" 
								<cfif len(thisRowSpec.Input.validator.pattern)>
									vldt:pattern="#thisRowSpec.Input.validator.pattern#" 
									vldt:minnumber="#thisRowSpec.Input.validator.patternDetail.minNumber#" 
									vldt:maxnumber="#thisRowSpec.Input.validator.patternDetail.maxNumber#" 
								</cfif>
							</cfif>
							 />
						</td>
				<cfelseif thisRowSpec.Input.FieldType eq "hidden">
					<td align="#thisRowSpec.input.LabelAlign#"><label for="#thisRowSpec.Input.id#">#thisRowSpec.Input.LabelText#</label></td>
					<td align="#thisRowSpec.input.FieldAlign#">
						<input type="hidden" 
							<cfif len(thisRowSpec.Input.id)> id="#thisRowSpec.Input.id#"</cfif>
							<cfif len(thisRowSpec.Input.name)> name="#thisRowSpec.Input.name#" </cfif>
							<cfif len(thisRowSpec.Input.class)> class="#thisRowSpec.Input.class#" </cfif>
							value="#theValue#"
							 />
						</td>
				<cfelseif thisRowSpec.Input.FieldType eq "textarea">
					<td align="#thisRowSpec.input.LabelAlign#"><label for="#thisRowSpec.Input.id#">#thisRowSpec.Input.LabelText#</label></td>
					<td align="#thisRowSpec.input.FieldAlign#">
						<textarea
							<cfif len(thisRowSpec.Input.id)> id="#thisRowSpec.Input.id#"</cfif>
							<cfif len(thisRowSpec.Input.name)> name="#thisRowSpec.Input.name#" </cfif>
							<cfif len(thisRowSpec.Input.class)> class="#thisRowSpec.Input.class#" </cfif>
							<cfif len(thisRowSpec.Input.cols)> cols="#thisRowSpec.Input.cols#"</cfif>
							<cfif len(thisRowSpec.Input.rows)> rows="#thisRowSpec.Input.rows#"</cfif>
							<cfif thisRowSpec.Input.validate>
								vldt:required="#thisRowSpec.Input.validator.required#" 
								vldt:errorclass="#thisRowSpec.Input.validator.errorclass#" 
								vldt:message="#thisRowSpec.Input.validator.message#" 
								vldt:filters="#thisRowSpec.Input.validator.filters#" 
								<cfif len(thisRowSpec.Input.validator.pattern)>
									vldt:pattern="#thisRowSpec.Input.validator.pattern#" 
									vldt:minnumber="#thisRowSpec.Input.validator.patternDetail.minNumber#" 
									vldt:maxnumber="#thisRowSpec.Input.validator.patternDetail.maxNumber#" 
								</cfif>
							</cfif>
							>#theValue#</textarea>
						</td>
				<cfelseif thisRowSpec.Input.FieldType eq "radio">
					<td align="#thisRowSpec.input.LabelAlign#"><label for="#thisRowSpec.Input.id#">#thisRowSpec.Input.LabelText#</label></td>
					<td align="#thisRowSpec.input.FieldAlign#">
						<cfset itemChecked = "#thisRowSpec.input.checked#">
						<input type="radio" name="#thisRowSpec.Input.name#" value="#theValue#"<cfif len(thisRowSpec.Input.id)> id="#thisRowSpec.Input.id#"</cfif><cfif len(thisRowSpec.Input.class)> class="#thisRowSpec.Input.class#"</cfif><cfif itemChecked eq True> checked</cfif> />
						</td>
				<cfelseif thisRowSpec.Input.FieldType eq "checkbox">
					<td align="#thisRowSpec.input.LabelAlign#"><label for="#thisRowSpec.Input.id#">#thisRowSpec.Input.LabelText#</label></td>
					<td align="#thisRowSpec.input.FieldAlign#">
						<cfset itemSelected = "#thisRowSpec.input.Selected#">
						<input type="checkbox" name="#thisRowSpec.Input.name#" value="#theValue#"<cfif len(thisRowSpec.Input.id)> id="#thisRowSpec.Input.id#"</cfif><cfif len(thisRowSpec.Input.class)> class="#thisRowSpec.Input.class#"</cfif><cfif itemSelected eq True> Selected</cfif> />
						</td>
				<cfelseif thisRowSpec.Input.FieldType eq "Select">
					<td align="#thisRowSpec.input.LabelAlign#"><label for="#thisRowSpec.Input.id#">#thisRowSpec.Input.LabelText#</label></td>
					<td align="#thisRowSpec.input.FieldAlign#">
						<cfset itemSelected = "#thisRowSpec.input.selectedRow#">
						<select name="#thisRowSpec.Input.name#" 
							<cfif len(thisRowSpec.Input.id)> id="#thisRowSpec.Input.id#"</cfif>
							<cfif len(thisRowSpec.Input.class)> class="#thisRowSpec.Input.class#"</cfif>
							<cfif thisRowSpec.Input.multiple> multiple</cfif>
							<cfif len(thisRowSpec.Input.size)> size="#thisRowSpec.Input.size#"</cfif>
							>
							<cfif thisRowSpec.Input.Value.Source eq "static">
								<!--- the selections are hard coded so just evaluate them and go for it --->
								<cfset lcntr = 1>
								<cfloop index="thisItem" list="#thisRowSpec.Input.Value.Value#">
									<cfset optVal = ListGetAt(thisRowSpec.Input.Value.Option, lcntr)>
									<option value="#thisItem#"<cfif lcntr eq itemSelected> SELECTED</cfif>>#optVal#</option>
									<cfset lcntr = lcntr+1>
								</cfloop>
							<cfelseif thisRowSpec.Input.Value.Source eq "query">
								<!--- the selections come from a query so loop over that --->
								<cfset lcntr = 1>
								<cfset theQuery = getValue(thisRowSpec.input.Value.Scope, thisRowSpec.input.Value.Query)>
								<cfloop query="#theQuery#">
									<option value="#theQuery[thisItem][thisRowSpec.Input.Value.value]#"<cfif lcntr eq itemSelected> SELECTED</cfif>>#theQuery[thisItem][thisRowSpec.Input.Value.Option]#</option>
									<cfset lcntr = lcntr+1>
								</cfloop>
							<cfelseif thisRowSpec.Input.Value.Source eq "structure">
								<cfset lcntr = 1>
								<cfset theStructure = getValue(thisRowSpec.input.Value.Scope, thisRowSpec.input.Value.Structure)>
								<cfloop collection="#theStructure#" item="thisItem">
									<option value="#theStructure[thisItem][thisRowSpec.Input.Value.value]#"<cfif lcntr eq itemSelected> SELECTED</cfif>>#theStructure[thisItem][thisRowSpec.Input.Value.Option]#</option>
									<cfset lcntr = lcntr+1>
								</cfloop>
							<cfelseif thisRowSpec.Input.Value.Source eq "array">
								<cfset theArray = getValue(thisRowSpec.input.Value.Scope, thisRowSpec.input.Value.Array)>
								<cfloop from="1" to="#ArrayLen(theArray)#" index="lcntr">
									<!--- 
									<cfdump var="#thisItem#"><cfabort>
									 --->
									<option value="#theArray[lcntr][thisRowSpec.Input.Value.value]#"<cfif lcntr eq itemSelected> SELECTED</cfif>>#theArray[lcntr][thisRowSpec.Input.Value.Option]#</option>
								</cfloop>
							</cfif>
						</select>
						</td>
				</cfif>

			<cfelseif thisRowSpec.Type eq "Submit">
				<td align="#thisRowSpec.Submit.LabelAlign#"><label for="#thisRowSpec.Submit.id#">#thisRowSpec.Submit.LabelText#</label></td>
				<td align="#thisRowSpec.Submit.FieldAlign#">
					<input type="submit" value="#thisRowSpec.Submit.Value#" name="#thisRowSpec.Submit.Name#" />
				</td>
			<cfelse>
			</cfif>
			</tr>
			</cfoutput>
		</cfloop>

		<cfif arguments.TabData.Type eq "Table">
			</table>
		<cfelse>
			</div>
		</cfif>
		</cfoutput>
		</cfsavecontent>
		
	<cfreturn ret  />
</cffunction>

<cffunction name="ShowTabControl" output="yes" returntype="string" access="public"
	displayname="Shows a Group of Tabs in a Pane"
	hint="loops over the tabs in the specified pane and generates the display HTML">
	<!--- this function needs.... --->
	<cfargument name="PaneData" type="struct" required="Yes" />	<!--- data structure for this set of tabs --->
	<cfargument name="selectedtab" type="numeric" default="1" />	<!--- which tab is selected --->

	<cfset var ret = "</div>" />

	<cfreturn ret  />
</cffunction>

<cffunction name="getScope" output="No" returntype="struct" access="private" 
	displayname="get a scope" 
	hint="returns the scope specified in the argument"
	>
	<cfargument name="scopeName" type="string" required="true" hint="the scope the variable is in">
	<cfscript>
		  switch(arguments.scopeName)
		  {
		      case "application":
		         return application;
		      break;
		      case "request":
		         return request;
		      break;
		      case "session":
		         return session;
		      break;
		      case "server":
		         return server;
		      break;
		      case "variables":
		         return variables;
		      break;
		      case "form":
		         return form;
		      break;
		      case "url":
	         return url;
		      break;
		  }
	</cfscript>
</cffunction>

<cffunction name="getValue" output="No" access="private" 
	displayname="Get a Value"
	hint="gets the variable specified in the two Value and Scope struct items"
	>
	<cfargument name="ScopeName" type="string" required="true" hint="the scope the variable is in">
	<cfargument name="VarName" type="string" required="true" hint="the key for the variable, or the variable name">
	<cfscript>
		var scope = getScope(arguments.ScopeName);
		return scope[arguments.VarName];
	</cfscript>
</cffunction>

<cffunction name="emptyFunction" output="yes" returntype="string" access="public"
	displayname="Nothing"
	hint="this is just a shell to copy, can be deleted once coding has finished, and turn off output if we don't need it to save whitespace">
	<!--- this function needs.... --->
	<cfargument name="FormFullName" type="string" default="" />	<!--- the name of the form structure --->

	<cfset var ret = "" />

	<cfreturn ret  />
</cffunction>

</cfcomponent>
	
	
	