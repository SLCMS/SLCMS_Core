<cfcomponent extends="controller" displayname="SLCMS AJAX Client Communications" hint="handles all SLCMS ajax calls" output="false">

<cffunction name= "init">
	<cfset provides("html,json")>
</cffunction>

<cffunction name= "index">
	<!--- these handlers cover AJAX calls that come in as XHR GET requests --->
	<cfset var theOutput = {STATUS="OK", MESSAGE=""} />	<!--- minimum straucture needed for a return, gets added to in some functions --->
	<cfif StructKeyExists(params, "Job")>
		<!--- this one is a comms check for the Installation Wizard --->
		<cfif params.job eq "TestComms">
			<cfif StructKeyExists(params, "Name") and params.Name eq "InstallWizard">
				<cfif StructKeyExists(params, "Value") and IsValid("UUID",params.Value)>
					<cfset theOutput.message = "Good UUID" />
				<cfelse>	
					<cfset theOutput.message = "invalid params" />
					<cfset theOutput.status = "FAIL" />
				</cfif>
			<cfelse>	
				<cfset theOutput.message = "invalid params" />
				<cfset theOutput.status = "FAIL" />
			</cfif>
		<!--- a simple function to make a name url-friendly, used everywhere --->
		<cfelseif params.job eq "CleanName">
			<cfif StructKeyExists(params, "Name")>
				<cfset theOutput.message = trim(params.Name) />
				<cfset theOutput.message = Replace(theOutput.message, " ", "_", "all") />
			<cfelse>	
				<cfset theOutput.message = "No Name param" />
				<cfset theOutput.status = "FAIL" />
			</cfif>
		<!--- a simple function to concatenate two names to one, used everywhere --->
		<cfelseif params.job eq "MakeSignInWord">
			<cfif StructKeyExists(params, "FirstName") and StructKeyExists(params, "LastName")>
				<cfset theFirstName = trim(params.FirstName) />
				<cfset theLastName = trim(params.LastName) />
				<cfset theOutput.message = theFirstName & left(theLastName, 1) />
			<cfelse>	
				<cfset theOutput.message = "Not correct params" />
				<cfset theOutput.status = "FAIL" />
			</cfif>
		<!--- used by admin-pages --->
		<cfelseif params.job eq "ContentTypeSelChanged">
			<!--- this is a biggy where we have (de)selected a module as the page content type so we need to work out what to show.
						jQuery on the Page Properties page is doing most of the work but we need to tell it if it needs to show the 
						module-driven selection popup or a simple selector or whatever and feed the data if the latter or the popup's params if the former --->
			<!--- the return struct must be of the form as a minumum
						{Status="Good|Error Message", ModuleFormalName="", ModuleFriendlyName="", DisplayType=""}
						NB, uppercase all key names to avoid case nasties in and out of JSON, we are also forcing core/module names to lowercase in the client for the same reason
						 --->
			<cfset theOutput = {STATUS="OK", ISMODULEFLAG="core", MODULEFORMALNAME="core", MODULEFRIENDLYNAME="Core", SELECTDISPLAYMODE="", POPparams="", DROPDOWNDATA=""} />
			<cfif StructKeyExists(params, "NewVal")>
				<cfset theNewVal = lcase(params.NewVal) />	<!--- we have to be careful, JSON is case sensitive --->
				<cfset theModule = ListFirst(theNewVal) />
				<cfif theModule eq "core">	
					<!--- we have a simple core thing, the system knows how to handle that so flick it straight back --->
					<cfset theOutput.SELECTDISPLAYMODE = lCase(ListLast(theNewVal)) />
				<cfelse>
					<!--- assume it must be a module, so module stuff here. If it isn't a valid, available module then the module manager will report back that fact --->	
					<cfset theOutput.ISMODULEFLAG = "module" />
					<cfset theOutput.MODULEFORMALNAME = theModule />
					<cfset theOutput.MODULEFRIENDLYNAME = application.modules["#theModule#"].FriendlyName />
					<!--- grab what we need to do --->
					<cfset retModuleContentType = application.system.ModuleManager.getModuleContentTypeSelector(Module="#theModule#", ContentType="#ListLast(theNewVal)#", subSiteID="#params.subSiteID#", UserID="#params.UserID#") />
					<cfif retModuleContentType.error.errorCode eq 0>
						<cfset theOutput.MODULEFORMALNAME = theModule />
						<cfset theOutput.MODULEFRIENDLYNAME = application.modules["#theModule#"].FriendlyName />
						<cfset theOutput.SELECTDISPLAYMODE = lcase(retModuleContentType.data.SelectDisplayMode) />
						<cfset theOutput.MODULEHINTTEXT = retModuleContentType.data.ModuleSelectedHint />
						<cfif theOutput.SELECTDISPLAYMODE eq "popup">
							<cfset theOutput.POPparams = retModuleContentType.data.Popparams />
						<cfelseif theOutput.SELECTDISPLAYMODE eq "dropdown">
							<cfset theOutput.DROPDOWNDATA = retModuleContentType.data.OptionArray />
						</cfif>
					<cfelse>
						<cfset theOutput.Status = "Error from Module Manager:- Code: #retModuleContentType.error.ErrorCode#, Detail: #retModuleContentType.error.errorText#" />
					</cfif>
					<!---
					<cfset Part1 = lCase(ListFirst(theNewVal)) />
					<cfset Part2 = lCase(ListLast(theNewVal)) />
					--->
				</cfif>
			<cfelse>	
				<cfset theOutput.Status = "FAIL" />
				<cfset theOutput.Status = "Error: No work param" />
			</cfif>	<!--- end:  --->
		<cfelseif params.job eq "toggle">
			<cfif StructKeyExists(params, "work")>
				<cfif params.work eq "containereditcontrolsshowing">
					<cfset session.SLCMS.Currents.Admin.FrontEnd.ContainerEditControlsShowing = not session.SLCMS.Currents.Admin.FrontEnd.ContainerEditControlsShowing />
					<cfif session.SLCMS.Currents.Admin.FrontEnd.ContainerEditControlsShowing>
						<cfset theOutput.message = "showing" />
					<cfelse>
						<cfset theOutput.message = "hidden" />
					</cfif>
				</cfif>
			</cfif>
		<cfelse>
			<cfset theOutput.status = "FAIL" />
			<cfset theOutput.message = "Job param not recognised" />
		</cfif>
	<cfelse>
		<cfset theOutput.Status = "FAIL" />
		<cfset theOutput.Status = "Error: No job param supplied" />
	</cfif>
	<cfset renderWith(theOutput) />
</cffunction>

<cffunction name= "hello">
	<!--- Prepare the message for the user --->
	<cfset greeting = {} />
	<cfset greeting["message"] = "Hi there" />
	<cfset greeting["time"] = Now() />
	<!--- Respond to all requests with `renderWith()` --->
	<cfset renderWith(greeting) />
</cffunction>
	<!--- from the docs where we ned to use a partial to generate the response
	<cfset comment = model"(comment").create(params.newCommen>t)
	<cfset renderPartial(comment>)
		<cfset renderPage(layout=false, hideDebugInformation=true) />
  --->
</cfcomponent>