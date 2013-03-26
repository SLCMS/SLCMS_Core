<cfsilent>
<!--- SLCMS a Simple Light CMS  --->
<!--- &copy; 2011 mort bay communications --->
<!---  --->
<!--- wrapper for all AJAX work done by the core admin pages --->
<!--- 
			Contains a handler that takes incoming posts from jQuery AJAX calls and feeds back the relevant stuff:
			for the "Name" tasks it just feeds back clean strings as they are normally just cleaned URLs and the like
			for "ContentTypeSelChanged" the return is a structure, JSON encoded, to tell the Page Structure edit form what it needs to do to show a content type selection
			 --->
<!---  --->
<!--- created:  26th Feb 2011 by Kym K - mbcomms --->
<!--- modified: 26th Feb 2011 - 13th Apr 2011 by Kym K - mbcomms - initial work, on & off --->

<cfset theOutput = "If you see this then nothing got hit!" />
<cfif StructKeyExists(url, "Job")>
	<cfif url.job eq "CleanName">
		<cfif StructKeyExists(url, "Name")>
			<cfset theName = trim(url.Name) />
			<cfset theOutput = application.Core.PageStructure.EncodeNavName(theName) />
		<cfelse>	
			<cfset theOutput = "No Name param" />
		</cfif>
	<cfelseif url.job eq "ReCleanName">
		<cfif StructKeyExists(url, "Name")>
			<cfset theName = trim(url.Name) />
			<cfset theOutput = application.Core.PageStructure.RecodeNavName(theName) />
		<cfelse>	
			<cfset theOutput = "No Name param" />
		</cfif>
	<cfelseif url.job eq "ContentTypeSelChanged">
		<!--- this is the biggy where we have (de)selected a module as the page content type so we need to work out what to show.
					jQuery on the Page Properties page is doing most of the work but we need to tell it if it needs to show the 
					module-driven selection popup or a simple selector or whatever and feed the data if the latter or the popup's url if the former --->
		<!--- the return struct must be of the form as a minumum
					{Status="Good|Error Message", ModuleFormalName="", ModuleFriendlyName="", DisplayType=""}
					NB, uppercase all key names to avoid case nasties in and out of JSON, we are also forcing core/module names to lowercase in the client for the same reason
					 --->
		<cfset theOutput = {STATUS="Good", ISMODULEFLAG="core", MODULEFORMALNAME="core", MODULEFRIENDLYNAME="Core", SELECTDISPLAYMODE="", POPURL="", DROPDOWNDATA=""} />
		<cfif StructKeyExists(url, "NewVal")>
			<cfset theNewVal = lcase(url.NewVal) />	<!--- we have to be careful, JSON is case sensitive --->
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
				<cfset retModuleContentType = application.system.ModuleManager.getModuleContentTypeSelector(Module="#theModule#", ContentType="#ListLast(theNewVal)#", subSiteID="#url.subSiteID#", UserID="#url.UserID#") />
				<cfif retModuleContentType.error.errorCode eq 0>
					<cfset theOutput.MODULEFORMALNAME = theModule />
					<cfset theOutput.MODULEFRIENDLYNAME = application.modules["#theModule#"].FriendlyName />
					<cfset theOutput.SELECTDISPLAYMODE = lcase(retModuleContentType.data.SelectDisplayMode) />
					<cfset theOutput.MODULEHINTTEXT = retModuleContentType.data.ModuleSelectedHint />
					<cfif theOutput.SELECTDISPLAYMODE eq "popup">
						<cfset theOutput.POPURL = retModuleContentType.data.PopURL />
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
			<cfset theOutput.Status = "Error: No work param" />
		</cfif>	<!--- end:  --->
		<cfset theOutput = SerializeJSON(theOutput) />
	<cfelse>
		<cfset theOutput = "Job param not recognised" />
	</cfif>
<cfelse>
	<cfset theOutput = "No Job param" />
</cfif>

</cfsilent>
<cfcontent reset="Yes"><cfoutput>#theOutput#</cfoutput><cfsilent>
<!--- other sorts of stuff can go here maybe? --->
</cfsilent>