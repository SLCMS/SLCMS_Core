
<cfsetting enablecfoutputonly="Yes">
<!--- default behaviour --->
<!--- 
<cfdump var="#request.wheels.params#" label="request.wheels.params" expand="true" />
<cfdump var="#request.SLCMS.flags#" label="request.SLCMS.flags" expand="true" />
<cfdump var="#PageContextFlags#" label="PageContextFlags" expand="false" />
 --->
<cfif IsDefined("params.task")>
	<cfset WorkMode1 = params.task>
</cfif>
<cfif WorkMode1 eq "SubSiteToggle">
	<!--- toggle whether subsites can be used or not --->
	<cfif StructKeyExists(params, "CurrentState") and StructKeyExists(params, "Function") and params.function eq "SubSiteToggle">
		<cfset theNewState = not params.CurrentState />
		<cfset ret = application.SLCMS.Core.PortalControl.setPortalAllowedStatus(theNewState) />
		<cfset ret = application.SLCMS.System.ModuleManager.ReInitModulesAfter(InitiatingModule="Core", InitiatingFunction="PortalControl", Action="subSiteChange") />
		<cfif ret.error.errorcode neq 0>
			<cfset ErrMsg  = "Module ReInitialisation After Portal Change Failed" />
			<cfif application.SLCMS.config.debug.debugmode>
				<cfoutput>#ret.error.ErrorContext#</cfoutput> Errored - error dump:<br>
				<cfdump var="#ret#">
			</cfif>
		</cfif>
		<cfif theNewState eq False>
			<cfset GoodMsg = "Subsites have been disallowed" />
		<cfelse>
			<cfset GoodMsg = "Subsites have been allowed" />
		</cfif>
	</cfif>
	<cfset WorkMode2 = "GetBaseDisplayItems" />
	<cfset DispMode = "ShowBaseDisplayItems" />

<cfelseif WorkMode1 eq "SetPageTemplateMode">
	<!--- set whether we can use just templates or all of the options in content.cfm --->
	<cfif StructKeyExists(params, "Function") and params.Function eq "SetPageTemplateMode" and StructKeyExists(params, "TemplatesOnly")>
		<cfif params.TemplatesOnly eq "yes">
			<cfset theValue = True />
		<cfelse>
			<cfset theValue = False />
		</cfif>
	</cfif>
	<cfset ret = application.SLCMS.core.SLCMS_Utility.setSystemFlag(FlagName="PagesHaveTemplatesOnly", FlagValue=theValue) />
	<cfif ret.error.errorcode neq 0>
		<cfset ErrMsg  = "SetPageTemplateMode Failed" />
		<cfif application.SLCMS.config.debug.debugmode>
			<cfoutput>#ret.error.ErrorContext#</cfoutput> Errored - error dump:<br>
			<cfdump var="#ret#">
		</cfif>
	</cfif>
	<cfset WorkMode2 = "GetBaseDisplayItems" />
	<cfset DispMode = "ShowBaseDisplayItems" />

<cfelseif WorkMode1 eq "Enable">
	<!--- we are going to enable a module globally --->
	<cfset ModuleData = application.SLCMS.System.ModuleManager.ChangeModuleEnableState(Modulename=params.module, Change="Enable") />
	<cfset ret = application.SLCMS.System.ModuleManager.ReInitModulesAfter(InitiatingModule="Core", InitiatingFunction="PortalControl", Action="subSiteChange") />
	<cfif ret.error.errorcode neq 0>
		<cfset ErrMsg  = "Module ReInitialisation After Enabling Failed" />
		<cfif application.SLCMS.config.debug.debugmode>
			<cfoutput>#ret.error.ErrorContext#</cfoutput> Errored - error dump:<br>
			<cfdump var="#ret#">
		</cfif>
	</cfif>
	<cfset WorkMode2 = "GetBaseDisplayItems" />
	<cfset DispMode = "ShowBaseDisplayItems" />

<cfelseif WorkMode1 eq "disable">
	<!--- we are going to enable a module globally --->
	<cfset ModuleData = application.SLCMS.System.ModuleManager.ChangeModuleEnableState(Modulename=params.module, Change="Disable") />
	<cfset ret = application.SLCMS.System.ModuleManager.ReInitModulesAfter(InitiatingModule="Core", InitiatingFunction="PortalControl", Action="subSiteChange") />
	<cfif ret.error.errorcode neq 0>
		<cfset ErrMsg  = "Module ReInitialisation After Disabling Failed" />
		<cfif application.SLCMS.config.debug.debugmode>
			<cfoutput>#ret.error.ErrorContext#</cfoutput> Errored - error dump:<br>
			<cfdump var="#ret#">
		</cfif>
	</cfif>
	<cfset WorkMode2 = "GetBaseDisplayItems" />
	<cfset DispMode = "ShowBaseDisplayItems" />

</cfif>

<!--- now do the second-pass stuff --->
<cfif WorkMode2 eq "zzz">
	<!--- do things --->
	<cfset DispMode = "yyy" />
<cfelseif WorkMode2 eq "GetBaseDisplayItems">
	<!--- get the state of the portal mode --->
	<cfset IsAllowedToBePortal = application.SLCMS.Core.PortalControl.IsPortalAllowed() />
	<cfset ModuleData = application.SLCMS.System.ModuleManager.getAvailableModulesFlags() />
	<cfset retPagesHaveTemplatesOnly = application.SLCMS.core.SLCMS_Utility.getSystemFlag("PagesHaveTemplatesOnly") />
	<cfif retPagesHaveTemplatesOnly.error.errorcode eq 0>
		<cfset PagesHaveTemplatesOnly = retPagesHaveTemplatesOnly.data />
	<cfelse>
		<cfset ErrMsg = "System Flag retrieval failed" /> 
	</cfif>
</cfif>

<!--- get the base display stuff --->
<cfif StructKeyExists(session, "Super") and session.Super eq "SuperRunning">
	<cfset rEmulateMode = True>
<cfelse>
	<cfset rEmulateMode = False>
</cfif>

<cfsetting enablecfoutputonly="No">

<cfoutput>#includePartial("/slcms/adminbanner")#</cfoutput>
<table border="0" cellpadding="3" cellspacing="0" class="worktable">
<cfif DispMode eq ""><cfoutput>
	<tr><td></td><td colspan="2"></td></tr>
	<tr><td colspan="3" align="left"></cfoutput>

<cfelseif DispMode eq "ShowBaseDisplayItems">
	<tr><td colspan="3" class="majorheadingsmaller">Overall System Management</td></tr>
	<tr><td colspan="3"></td></tr>
	<tr><td colspan="3"></td></tr>
	<cfoutput>
	<form name="theForm" action="#application.SLCMS.Paths_Admin.AdminBaseURL#admin-system?#PageContextFlags.ReturnLinkParams#&amp;task=SubSiteToggle" method="post">
<!--- 
	<input type="hidden" name="_method" value="put">
	 --->
	<input type="hidden" name="Function" value="SubSiteToggle">
	<input type="hidden" name="CurrentState" value="#yesNoFormat(IsAllowedToBePortal)#">
	</cfoutput>
	<tr><td colspan="3"></td></tr>
	<tr><td colspan="3" class="minorheadingName">Portal Capability</td></tr>
	<tr><td colspan="3"></td></tr>
	<tr>
		<td colspan="3" class="minorheadingText">
		<cfif IsAllowedToBePortal>
			Sub Sites are allowed
		<cfelse>
			Sub Sites are not allowed
		</cfif>
		</td>
		</tr>
	<tr><td colspan="3"></td></tr>
	<tr>
		<td colspan="3">
		<cfif IsAllowedToBePortal>
			<input type="submit" name="SavePortalMode" value="Disallow Sub Sites" onClick="return confirm('You do really want to stop Sub Sites being used?')">
		<cfelse>
			<input type="submit" name="SavePortalMode" value="Allow Sub Sites" onClick="return confirm('You do really want to allow Sub Sites?')">
		</cfif>
		</td>
		</tr>
	</form>
	<tr><td colspan="3">&nbsp;</td></tr>
	<tr><td colspan="3" class="minorheadingName">Page Control</td></tr>
	<cfoutput>
	<form name="theForm" action="#application.SLCMS.Paths_Admin.AdminBaseURL#admin-system?#PageContextFlags.ReturnLinkParams#&amp;task=SetPageTemplateMode" method="post">
<!--- 
	<input type="hidden" name="_method" value="put">
	 --->
	<input type="hidden" name="Function" value="SetPageTemplateMode">
	</cfoutput>
	<tr>
		<td colspan="3" class="minorheadingText">
		<table border="0" cellpadding="3" cellspacing="0">
		<tr>
			<td>Only allow pages to be SLCMS templates<br>with content from SLCMS functions</td>
			<td>
				<input type="radio" name="TemplatesOnly" id="TemplatesOnlyOn" value="Yes"<cfif PagesHaveTemplatesOnly> checked="checked"</cfif>>
				<input type="radio" name="TemplatesOnly" id="TemplatesOnlyOff" value="No"<cfif not PagesHaveTemplatesOnly> checked="checked"</cfif>>
			</td>
			<td>Allow pages to be include files, straight files, etc. <br>as well as normal SLCMS templates</td>
		</tr>
		</table
		</td>
		</tr>
	<tr>
		<td colspan="3">
			<input type="submit" name="SavePortalMode" value="Save Page Control Status">
		</td>
		</tr>
	</form>
	<tr><td colspan="3"></td></tr>
	<tr><td colspan="3">&nbsp;</td></tr>
	<tr><td colspan="3" class="minorheadingName">Module Control</td></tr>
	<tr><td colspan="3"></td></tr>
	<cfif ModuleData.Error.ErrorCode eq 0>
		<tr><td colspan="3" class="WorkTableTopRowFull"><strong>The following Modules are installed and available in the system:</strong></td></tr>
		<tr>
			<td class="WorkTable2ndRow">Module Name</td>
			<td class="WorkTable2ndRow">Globally Enabled</td>
			<td class="WorkTable2ndRowRHcol"></td>
		</tr>
		<cfset thereIsAnEnabledOne = False />
		<cfloop list="#ModuleData.Data.ModuleList#" index="thisModule">
			<cfif ModuleData.Data["#thisModule#"].Flags.Enabled_Global and ModuleData.Data["#thisModule#"].Flags.PortalAware eq "Yes">
				<cfset thereIsAnEnabledOne = True />
			</cfif>
			<tr valign="top"><cfoutput>
				<td class="WorkTableRowColour2">#ModuleData.Data["#thisModule#"].FriendlyName#</td>
				<td class="WorkTableRowColour2">
				<cfif ModuleData.Data["#thisModule#"].Flags.Enabled_Global>
					Yes. 
				<cfelse>
					No
				</cfif>
				</td>
				<td class="WorkTableRowColour2RHCol">
				<cfif ModuleData.Data["#thisModule#"].Flags.Enabled_Global>
					#linkTo(text="Disable", controller="slcms.admin-system", action="index", params="#PageContextFlags.ReturnLinkParams#&amp;task=Disable&amp;module=#thisModule#")#
				<cfelse>
					#linkTo(text="Enable", controller="slcms.admin-system", action="index", params="#PageContextFlags.ReturnLinkParams#&amp;task=Enable&amp;module=#thisModule#")#
				</cfif>
				</td>
			</tr>
			<tr>
				<td class="WorkTableRowColour1"></td>
				<td class="WorkTableRowColour1">
					<cfif IsAllowedToBePortal>
						<cfif ModuleData.Data["#thisModule#"].Flags.PortalAware eq "Yes" and ModuleData.Data["#thisModule#"].Flags.Enabled_subSiteList neq "">
							<cfset dSubList = "" />
							<cfloop list="#ModuleData.Data['#thisModule#'].Flags.Enabled_subSiteList#" index="thisSubSite">
								<cfset dSubList = ListAppend(dSubList, application.SLCMS.core.PortalControl.GetSubSite(SubSiteID="#thissubSite#").data.SubSiteFriendlyName) /> 
							</cfloop>
							The following subSites have this module turned on:<br>#dSubList#
						<cfelseif ModuleData.Data["#thisModule#"].Flags.PortalAware eq "No">
							This Module is not portal aware, it will only work in the <strong>#application.SLCMS.core.PortalControl.GetSubSite(SubSiteID="0").data.SubSiteFriendlyName#</strong> subSite.
						<cfelse>
							No subSites have this module turned on.
						</cfif>
					</cfif>
				</td>
				<td class="WorkTableRowColour1RHCol"></td></cfoutput>
			</tr>
		</cfloop>
		<cfif thereIsAnEnabledOne and IsAllowedToBePortal>
			<tr>
				<td class="WorkTableRowColour2"></td>
				<td class="WorkTableRowColour2"><cfoutput>
					#linkTo(text="Go to Module Management to change subSites", controller="slcms.admin-modulesinsubs", action="index", params="#PageContextFlags.ReturnLinkParams#")#</cfoutput>
				</td>
				<td class="WorkTableRowColour2RHCol"></td>
			</tr>
		</cfif>
	<cfelse>
		<tr><td colspan="3" class="errrColour">oops! The data collection for the modules failed.</td></tr>
	</cfif>
	
</cfif>
</table>

</body>
</html>
