<!---  --->
<!--- A simple CMS system by Mort Bay Communications Pty Ltd --->
<!--- Copyright 2002-2008 --->
<!---  --->
<!--- SiteStructure Management Home Page --->
<!--- include file with the functions --->
<!---  --->
<!--- Created:   5th Jan 2008 by Kym Kovan - mbcomms, cloned from original single file --->
<!--- Modified: 23rd Jan 2008 - 23rd Jan 2008 by Kym K - mbcomms, cosmetic improvements --->
<!--- modified: 24th May 2008 - 24th May 2008 by Kym K - mbcomms: added Home Page flag --->
<!--- modified: 17th Feb 2009 - 17th Feb 2009 by Kym K - mbcomms: changed to allow for wiki pages --->
<!--- modified: 25th Mar 2009 - 25th Mar 2009 by Kym K - mbcomms: V2.2, changing structures to new module-allowing architecture, the core code is now just another module --->
<!--- modified:  1st Apr 2009 -  1st Apr 2009 by Kym K - mbcomms: bugfix on wiki page changes --->
<!--- modified:  2nd Oct 2009 -  4th Oct 2009 by Kym K - mbcomms: adding Subsite functionality --->
<!---  --->

<!--- set up a few display functions for our nested tables, etc --->
<cffunction name="dispNavPage" 
	access="public" output="No" returntype="any" 
	displayname="display for one Page in the site"
	hint="shows the full line on the table of one page in the site taken from the nav array"
	>
	<cfargument name="ArrayItem" required="true">	<!--- the item that we want to show --->
	<cfargument name="ArrayLocation" required="true">	<!--- the place in the nav array of the item that we want to show --->

	<cfset var ShowExpandControl = False />
	<cfset var theLinkText = "" />
	<cfset var theExpandImage = "" />
	<cfset var theExpandControl = "" />
	<cfset var theSubContent = "" />
	<cfset var theHTML = "" />	<!--- this will carry the html as we generate it --->
	<cfset var theMode = "" />
	<cfset var tempString = "" />
	<cfset var theLevelTemp = 1 />
	<cfset var stylings = StructNew() />	<!--- carries the syling strings as a struct so we can make the names dynamic --->
	 
	<!--- if it has children decide what control to show --->
	<cfif ArrayItem.IsParent eq true and session.SLCMS.pageAdmin.NavState.ExpansionFlags[ArrayItem.DocID] eq True>
		<cfset ShowExpandControl = True />
		<cfset theExpandImage = "Minus16.gif" />
		<cfset theExpandControl = "CollapseArm" />
	<cfelseif ArrayItem.IsParent eq true and session.SLCMS.pageAdmin.NavState.ExpansionFlags[ArrayItem.DocID] eq False>
		<cfset ShowExpandControl = True />
		<cfset theExpandImage = "Plus16.gif" />
		<cfset theExpandControl = "ExpandArm" />
	<cfelse>
		<cfset ShowExpandControl = False />
	</cfif>
	<!--- set up styling for flagging a change of some form --->
	<!--- we only have style for 4 levels for doa force for really deep stuff --->
	<cfif ArrayItem.ThisLevel gt 4>
		<cfset theLevelTemp = 4 />
	<cfelse>
		<cfset theLevelTemp = ArrayItem.ThisLevel />
	</cfif>
	<cfset stylings.CellClassString_PP = "WorkTableRowColour#theLevelTemp#" />
	<cfset stylings.CellClassString_MV = "WorkTableRowColour#theLevelTemp#" />
	<cfset stylings.CellClassString_DV = "WorkTableRowColour#theLevelTemp#" />
	<cfset stylings.CellClassString_EX = "WorkTableRowColour#theLevelTemp#" />
	<cfset stylings.CellClassString_Up = "WorkTableRowColour#theLevelTemp#" />
	<cfset stylings.CellClassString_Down = "WorkTableRowColour#theLevelTemp#" />
	<cfif ArrayItem.DocID eq request.SLCMS.ItemChangedFlag.ID>
		<cfif request.SLCMS.ItemChangedFlag.Name is not "">
			<cfset stylings["CellClassString_#request.SLCMS.ItemChangedFlag.Name#"] = "WorkTableRowChangedColour" />
		</cfif>
	</cfif>
	<!--- set the html strings in the first colums as a variable to avoid white space mucking up the layout --->
	<cfif ShowExpandControl>
		<cfset theSubContent = repeatString('<img src="#application.slcms.Paths_Admin.GraphicsPath_ABS#Blank16.gif" height="16" width="16" border="0">', ArrayItem.ThisLevel-1) />
		<cfset theLinkText = '<img src="#application.slcms.Paths_Admin.GraphicsPath_ABS##theExpandImage#" width="16" height="16" border="0">' />
		<cfset theSubContent = theSubContent & '#linkTo(text="#theLinkText#", controller="slcms.adminPages", action="index", params="#PageContextFlags.ReturnLinkParams#&amp;mode=#theExpandControl#&DocID=#ArrayItem.DocID#", class="WorkTableNavExpand")#' />
		<!--- 
		<cfset theSubContent = theSubContent & '<a href="Admin_PageStructure.cfm?mode=#theExpandControl#&amp;DocID=#ArrayItem.DocID#" class="WorkTableNavExpand"><img src="#application.slcms.Paths_Admin.GraphicsPath_ABS##theExpandImage#" width="16" height="16" border="0"></a>' />
		 --->
	<cfelse>
		<cfset theSubContent = '<span class="WorkTableNavExpand"><img src="#application.slcms.Paths_Admin.GraphicsPath_ABS#Blank16.gif" height="16" width="16" border="0"></span>' & repeatString('<img src="#application.slcms.Paths_Admin.GraphicsPath_ABS#Blank16.gif" height="16" width="16" border="0">', ArrayItem.ThisLevel-1) />
	</cfif>
	<cfif ArrayItem.HasContent neq 0>
		<cfset theSubContent = theSubContent & '<img src="#application.slcms.Paths_Admin.GraphicsPath_ABS#document16.gif" height="16" width="16" border="0">' />
	<cfelse><!--- <img src="images/Blank13.gif" height="13" width="13" border="0"> --->
		<cfset theSubContent = theSubContent & '<img src="#application.slcms.Paths_Admin.GraphicsPath_ABS#Blank16.gif" height="16" width="16" border="0">' />
	</cfif>
	<cfif ArrayItem.IsParent neq 0>
		<cfset theSubContent = theSubContent & '<img src="#application.slcms.Paths_Admin.GraphicsPath_ABS#folder16.gif" height="16" width="16" border="0" hspace="2">' />
	</cfif>
	<cfset theHTML = '<tr><td colspan="1" class="#stylings.CellClassString_EX#" valign="middle">' />
	<cfif BitAnd(ArrayItem.Hidden,2) eq 2>
		<cfset theNavNameClass = "WorkTableNavNameColourOff" />
	<cfelseif ArrayItem.Hidden eq 1>
		<cfset theNavNameClass = "WorkTableNavNameColourMid" />
	<cfelse>
		<cfset theNavNameClass = "WorkTableNavNameColourOn" />
	</cfif>
	<cfset theHTML = theHTML & '#theSubContent#<span class="#theNavNameClass#">#ArrayItem.NavName#' />
	<cfif ArrayItem.IsHomePage>
		<cfset theHTML = theHTML & ' <strong>*</strong>' />
	</cfif>
	<cfset theHTML = theHTML & '</span></td>' />
		<!--- 
		<td>#session.SLCMS.pageAdmin.NavState.dispRowCounter#</td>
		 --->
		<!--- 
		<td class="WorkTableRowColour#ArrayItem.ThisLevel#">
			<cfif ShowExpandControl>
				<a href="Admin_PageStructure.cfm?mode=#theExpandControl#&DocID=#ArrayItem.DocID#"><img src="images/#theExpandImage#" width="13" height="13" border="0"></a>
			<cfelse>
				&nbsp;
			</cfif>
		</td>
		 --->
		
			<!--- 
			<cfif ShowExpandControl>
				#repeatString('<img src="images/Blank13.gif" height="13" width="13" border="0">', ArrayItem.ThisLevel-1)#<a href="Admin_PageStructure.cfm?mode=#theExpandControl#&DocID=#ArrayItem.DocID#"><img src="images/#theExpandImage#" width="13" height="13" border="0"></a>
			<cfelse>
				#repeatString('<img src="images/Blank13.gif" height="13" width="13" border="0">', ArrayItem.ThisLevel)#
			</cfif>
			<cfif ArrayItem.IsParent neq 0><img src="images/folder16.gif" height="16" width="16" border="0"></cfif>
			<cfif ArrayItem.HasContent neq 0><img src="images/document16.gif" height="16" width="16" border="0">
			<cfelse><!--- <img src="images/Blank13.gif" height="13" width="13" border="0"> --->
			</cfif>
			 --->
	<cfset theHTML = theHTML & '<td align="center" class="WorkTableRowColour#theLevelTemp#">#ArrayItem.ThisLevel#</td>' />
	<cfset theHTML = theHTML & '<td align="center" class="#stylings.CellClassString_PP#">' />
	<cfset theHTML = theHTML & '#linkTo(text="Page Properties", controller="slcms.adminPages", action="index", params="#PageContextFlags.ReturnLinkParams#&amp;mode=editPage&CurrentParentID=#ArrayItem.ParentID#&CurrentDocID=#ArrayItem.DocID#")#' />
	<cfset theHTML = theHTML & '</td>' />
	<!--- 
	<cfset theHTML = theHTML & '<a href="Admin_PageStructure.cfm?mode=editPage&amp;CurrentParentID=#ArrayItem.ParentID#&amp;CurrentDocID=#ArrayItem.DocID#">Page Properties</a></td>' />
	 --->
	<cfset theHTML = theHTML & '<td align="center" class="#stylings.CellClassString_MV#">' />
	<cfif BitAnd(ArrayItem.Hidden,1) eq 1>
		<cfset theHTML = theHTML & 'Hidden' />
		<cfset theMode = "UnHideInMenu" />
	<cfelse>
		<cfset theHTML = theHTML & 'Visible&nbsp;' />
		<cfset theMode = "HideInMenu" />
	</cfif>
	<cfset theHTML = theHTML & '#linkTo(text="Change", controller="slcms.adminPages", action="index", params="#PageContextFlags.ReturnLinkParams#&amp;mode=#theMode#&HidVal=#ArrayItem.Hidden#&DocID=#ArrayItem.DocID#")#' />
	<!--- 
	<cfset theHTML = theHTML & '<a href="Admin_PageStructure.cfm?mode=#theMode#&amp;HidVal=#ArrayItem.Hidden#&amp;DocID=#ArrayItem.DocID#">Change</a>' />
	 --->
	<cfset theHTML = theHTML & '</td>' />
	<cfif application.SLCMS.core.UserPermissions.IsAdmin(SubSiteID=session.SLCMS.Currents.Admin.PageStructure.CurrentSubSiteID)>
		<cfset theHTML = theHTML & '<td align="center" class="#stylings.CellClassString_DV#">' />
		<!--- only show the deeper hidden control if we have content --->
		<cfif ArrayItem.HasContent neq 0>
			<cfif BitAnd(ArrayItem.Hidden,2) eq 2>
				<cfset theHTML = theHTML & 'Hidden' />
				<cfset theMode = "UnHide" />
			<cfelse>
				<cfset theHTML = theHTML & 'Visible&nbsp;' />
				<cfset theMode = "Hide" />
			</cfif>
			<cfset theHTML = theHTML & '#linkTo(text="Change", controller="slcms.adminPages", action="index", params="#PageContextFlags.ReturnLinkParams#&amp;mode=#theMode#&HidVal=#ArrayItem.Hidden#&DocID=#ArrayItem.DocID#")#' />
			<!--- 
			<cfset theHTML = theHTML & '<a href="Admin_PageStructure.cfm?mode=#theMode#&amp;HidVal=#ArrayItem.Hidden#&amp;DocID=#ArrayItem.DocID#">Change</a>' />
			 --->
		<cfelse>
			<cfset theHTML = theHTML & '&nbsp;' />
		</cfif>
		<cfset theHTML = theHTML & '</td>' />
	</cfif>
	<cfset theHTML = theHTML & '<td align="center" class="WorkTableRowColour#theLevelTemp#">' />
	<cfif ArrayItem.IsParent eq 0>
		<cfset tempString = tempString & "Are you sure you want to archive the page: " />
		<cfset tempString = tempString & JSStringFormat(ArrayItem.NavName) />
		<cfset tempString = tempString & "?" />
		<cfset theHTML = theHTML & '#linkTo(text="Archive Page", controller="slcms.adminPages", action="index", params="#PageContextFlags.ReturnLinkParams#&amp;mode=del&DocID=#ArrayItem.DocID#", confirm="#tempString#")#' />
		<!--- 
		<cfset theHTML = theHTML & '<a href="Admin_PageStructure.cfm?mode=del&amp;DocID=#ArrayItem.DocID#" onclick="return confirm(' />
		<cfset theHTML = theHTML & "'Are you sure you want to move to the archives the page: #JSStringFormat(ArrayItem.NavName)#?\nIt will not longer be visible in the website'" />
		<cfset theHTML = theHTML & ')">Archive Page</a>' />
		 --->
	<cfelse>
		<cfset theHTML = theHTML & '&nbsp;' />
	</cfif>
	<cfset theHTML = theHTML & '</td><td align="center" class="#stylings.CellClassString_Up#">' />
	<cfif session.SLCMS.pageAdmin.NavState.dispRowCounter gt 1>	<!--- can only go up if we are not at the top row --->
		<cfset theHTML = theHTML & '#linkTo(text="Up", controller="slcms.adminPages", action="index", params="#PageContextFlags.ReturnLinkParams#&amp;mode=up&ParentID=#ArrayItem.ParentID#&pos=#session.SLCMS.pageAdmin.NavState.dispRowCounter#&DocID=#ArrayItem.DocID#")#' />
		<!--- 
		<cfset theHTML = theHTML & '<a href="Admin_PageStructure.cfm?mode=up&amp;ParentID=#ArrayItem.ParentID#&amp;pos=#session.SLCMS.pageAdmin.NavState.dispRowCounter#&amp;DocID=#ArrayItem.DocID#">Up</a>' />
		 --->
	<cfelse>
		<cfset theHTML = theHTML & '&nbsp;' />
	</cfif>
	<cfset theHTML = theHTML & '</td><td align="center" class="#stylings.CellClassString_Down#">' />
		<cfset theHTML = theHTML & '#linkTo(text="Down", controller="slcms.adminPages", action="index", params="#PageContextFlags.ReturnLinkParams#&amp;mode=down&ParentID=#ArrayItem.ParentID#&pos=#session.SLCMS.pageAdmin.NavState.dispRowCounter#&DocID=#ArrayItem.DocID#")#' />
		<!--- 
		<cfset theHTML = theHTML & '<a href="Admin_PageStructure.cfm?mode=down&amp;ParentID=#ArrayItem.ParentID#&amp;pos=#session.SLCMS.pageAdmin.NavState.dispRowCounter#&amp;DocID=#ArrayItem.DocID#">Down</a>' />
		 --->
		<!--- ToDo - work out how to do this, mark the bottom that is  --->
		<!--- 
		<cfif session.SLCMS.pageAdmin.NavState.dispRowCounter lt ArrayLen(session.SLCMS.pageAdmin.NavState.displayedRowArray)>	<!--- can only go down if we are not at the bottom row --->
			<a href="Admin_PageStructure.cfm?mode=down&ParentID=#ArrayItem.ParentID#&pos=#session.SLCMS.pageAdmin.NavState.dispRowCounter#&DocID=#ArrayItem.DocID#">Down</a>
		<cfelse>
			&nbsp;
		</cfif>
		 --->
	<cfif ArrayItem.Param2 neq "wiki">
		<cfset theHTML = theHTML & '</td><td align="center" class="WorkTableRowColour#theLevelTemp#RHCol">' />
		<cfif application.SLCMS.core.PortalControl.IsPortalAllowed() and 1 eq 0>
			<!--- ToDo: test for this page flagged as a portal home page --->
			<cfset theHTML = theHTML & '#linkTo(text="Go to Home Page of Sub-Site", controller="slcms.adminPages", action="index", params="#PageContextFlags.ReturnLinkParams#&amp;mode=GoToSubSite&SubSiteID=0&CurrentPage=#ArrayItem.DocID#")#' />
			<!--- 
			<cfset theHTML = theHTML & '<a href="Admin_PageStructure.cfm?mode=GoToSubSite&amp;SubSiteID=0&amp;CurrentPage=#ArrayItem.DocID#">Go to Home Page of Sub-Site</a></td></tr>' />
			 --->
		<cfelse>
			<cfset theHTML = theHTML & '#linkTo(text="Add Below Here (Level #ArrayItem.ThisLevel+1#)", controller="slcms.adminPages", action="index", params="#PageContextFlags.ReturnLinkParams#&amp;mode=AddPage&CurrentPage=#ArrayItem.DocID#")#' />
			<!--- 
			<cfset theHTML = theHTML & '<a href="Admin_PageStructure.cfm?mode=AddPage&amp;CurrentPage=#ArrayItem.DocID#">Add Page Below Here in Level #ArrayItem.ThisLevel+1#</a></td>' />
			 --->
		</cfif>
	<cfelse>
		<cfset theHTML = theHTML & '</td><td align="center" class="WorkTableRowColour#theLevelTemp#RHCol">&nbsp;</td>' />
	</cfif>
	<cfset theHTML = theHTML & '</tr>#chr(13)##chr(10)#' />
	
	<cfreturn theHTML />
</cffunction>

<cffunction name="loopNavPage" 
	access="public" output="No" returntype="any" 
	displayname="loop for one Page"
	hint="re-entrant - loops over the page and its children"
	>
	<cfargument name="ArrayPart" required="true">	<!--- the item that we want to show --->

	<cfset var theHTML = "" />	<!--- this will carry the html as we generate it --->
	<cfset var lcntr = 1>	<!--- localise the counter as we are going to be re-entrant --->
	<cfloop from="1" to="#ArrayLen(ArrayPart)#" index="lcntr">
		<!--- keep a count going on how far down the display table we are, displayed rows not all rows
					and keep a tab on what docID is above and below
					[1] is the one above, [2] is this docid, [3] is the one below --->
		<cfset session.SLCMS.pageAdmin.NavState.dispRowCounter = session.SLCMS.pageAdmin.NavState.dispRowCounter+1 />
		<cfset session.SLCMS.pageAdmin.NavState.displayedRowArray[session.SLCMS.pageAdmin.NavState.dispRowCounter][2] = arguments.ArrayPart[lcntr].DocID />
		<cfif session.SLCMS.pageAdmin.NavState.dispRowCounter gt 1>
			<!--- if we are not at the first row grab the one above and load that in --->
			<cfset session.SLCMS.pageAdmin.NavState.displayedRowArray[session.SLCMS.pageAdmin.NavState.dispRowCounter][1] = session.SLCMS.pageAdmin.NavState.displayedRowArray[session.SLCMS.pageAdmin.NavState.dispRowCounter-1][2] />
		<cfelse>
			<!--- if we at the top --->
			<cfset session.SLCMS.pageAdmin.NavState.displayedRowArray[session.SLCMS.pageAdmin.NavState.dispRowCounter][1] = 0 />
		</cfif>
		<!--- set up a blank one below until we get there in the next loop --->
		<cfset session.SLCMS.pageAdmin.NavState.displayedRowArray[session.SLCMS.pageAdmin.NavState.dispRowCounter][3] = 0 />
		<cfif session.SLCMS.pageAdmin.NavState.dispRowCounter gte 2>
			<!--- if we are up to the second row load this row into the row above as the below item --->
			<cfset session.SLCMS.pageAdmin.NavState.displayedRowArray[session.SLCMS.pageAdmin.NavState.dispRowCounter-1][3] = session.SLCMS.pageAdmin.NavState.displayedRowArray[session.SLCMS.pageAdmin.NavState.dispRowCounter][2] />
		</cfif>
		<!--- now display that row in the table --->
		<cfset theHTML = theHTML & dispNavPage(ArrayItem=arguments.ArrayPart[lcntr], ArrayLocation=lcntr)>
		<!--- see if we have any children and display if we are expanded --->
		<cfif arguments.ArrayPart[lcntr].IsParent neq 0 and session.SLCMS.pageAdmin.NavState.ExpansionFlags[arguments.ArrayPart[lcntr].DocID] eq True>
			<cfset theHTML = theHTML & loopNavPage(arguments.ArrayPart[lcntr].Children)>
		</cfif>
	</cfloop>

	<cfreturn theHTML />
</cffunction>

<cffunction name="UpdateNavArrays"
	access="public" output="No" returntype="Any"
	displayname="Udate Navigation Arrays"
	hint="refreshes the navigation arrays after a change in the site structure"
	>

	<cfset application.SLCMS.core.PageStructure.RefreshSiteStructures() />
	<cfset session.SLCMS.pageAdmin.NavState.theCurrentNavArray = Duplicate(application.SLCMS.core.PageStructure.getFullNavArray(SubSiteID=session.SLCMS.Currents.Admin.PageStructure.CurrentSubSiteID)) />
	<cfset session.SLCMS.pageAdmin.DocIdList = application.SLCMS.core.PageStructure.getDocIdList(SubSiteID=session.SLCMS.Currents.Admin.PageStructure.CurrentSubSiteID) />
	<!--- and put any new documents as open into the expansion structure --->
	<cfloop list="#session.SLCMS.pageAdmin.DocIdList#" index="thisDocID">
		<cfif not StructKeyExists(session.SLCMS.pageAdmin.NavState.ExpansionFlags, thisDocID)>
			<cfset session.SLCMS.pageAdmin.NavState.ExpansionFlags[thisDocID] = True />
		</cfif>
	</cfloop>
	<cfset session.SLCMS.pageAdmin.NavSerial = application.SLCMS.core.PageStructure.getSerial() />
</cffunction>



