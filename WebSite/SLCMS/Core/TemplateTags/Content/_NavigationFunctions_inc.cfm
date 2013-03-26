<!--- SLCMS base tags to be used in template pages  --->
<!---  --->
<!--- include file of functions used in the custom tags that display a navigation menu or a breadcrumb --->
<!--- &copy; mort bay communications --->
<!---  --->
<!--- created:  30th Dec 2007 by Kym K, mbcomms - cloned from displayNavigation tag --->
<!--- modified: 30th Dec 2007 - 31st Dec 2007 by Kym K, mbcomms: did initial stuff --->
<!--- modified: 20th Feb 2008 - 20th Feb 2008 by Kym K, mbcomms: fixed bug in deep menus in SearchNavArrayPart() --->
<!--- modified: 14th Jul 2008 - 15th Jul 2008 by Kym K, mbcomms: fixed missing ul styling string in loopnavpage and selected item coding and added code for IDs as well as classes in tags --->
<!--- modified: 11th Nov 2008 - 11th Nov 2008 by Kym K, mbcomms: changed params for viewing hidden items in navigation. Now if webpage invisible goes from nav for admins as well --->
<!--- modified: 23rd Mar 2009 - 23rd Mar 2009 by Kym K, mbcomms: V2.2, changing structures to new module-allowing architecture, the core code is now just another module --->
<!--- modified: 27th Apr 2009 - 27th Apr 2009 by Kym K, mbcomms: V2.2, changing template folder structure to portal/sub-site architecture, sites inside the top site, data structures added/changed to match --->
<!--- modified:  1st Oct 2009 -  1st Oct 2009 by Kym K, mbcomms: V2.2, modifying code for session roles, ie the permissions engine --->
<!--- modified:  6th Nov 2009 -  7th Nov 2009 by Kym K, mbcomms: V2.2, debugging SearchNavArrayPart() code for portal-based many level menus and adding top/Home link code --->
<!---
docs: modified: 25th Feb 2012 - 25th Feb 2012 by Kym K, mbcomms: version 2.0.3, core V2.2+, added a top folder attribute so can show a menu for a folder other than its own parent, also added new "docs" documentation
--->

<!--- set up the display functions as we are going to be reentrant, can't do it in one codeset --->
<cffunction name="showNavItem" 
						access="private" output="yes" returntype="string" 
						hint="returns formatted html for one menu line">
	<cfargument name="displayStyling" type="string" default="Default" />	<!--- the style set to use --->
	<cfargument name="displayFormat" type="string" default="Li" />	<!--- the html type to use divs/tables --->
	<cfargument name="ThisLevel" type="boolean" default=1 />	<!--- depth into the nav structure --->
	<cfargument name="FirstDocAtThisLevel_Flag" type="boolean" default="True" />	<!--- flag for if this is the first doc at this level --->
	<cfargument name="LastDocAtThisLevel_Flag" type="boolean" default="True" />		<!--- flag for if this is the last doc at this level --->
	<cfargument name="useURLSessionFormat" type="boolean" default="True" />	<!--- formatting of the URL --->
	<cfargument name="LinkURL" type="string" default="" />	<!--- the link href --->
	<cfargument name="LinkText" type="string" default="" />	<!--- the link text --->
	<cfargument name="HasContent" type="string" default=False />	<!--- is their content in this? --->
	<cfargument name="HasChildren" type="string" default=False />	<!--- is their content below this? --->
	<cfargument name="ShowingChildren" type="boolean" default="False" />	<!--- whether to allow for dropping down a row --->
	<cfargument name="IsHiddenItem" type="boolean" default="False" />	<!--- whether to style as a normally hidden item but being shown as logged in --->
	<cfargument name="IsSelectedItem" type="boolean" default="False" />	<!--- whether to use the selected item styling --->

	<!--- predefine all of the variables to keep MX happy --->
	<cfset var theDisplayStyling = trim(arguments.displayStyling) />
	<cfset var theDisplayFormat = trim(arguments.DisplayFormat) />
	<cfset var theLevel = trim(arguments.ThisLevel) />	<!--- depth into the nav structure --->
	<cfset var theLinktext = trim(arguments.LinkText) />
	<cfset var theLinkURL = trim(arguments.LinkURL) />
	<!--- the vars we fill as we go --->
	<cfset var theStyleController = "" />
	<cfset var theSelectedController = "" />
	<cfset var theLinkClass =  "" />
	<cfset var theLinkAttributeString =  "" />
	<cfset var theLinkPrepend = "" />
	<cfset var theLinkAppend = "" />
	<cfset var theTagClass =  "" />
	<cfset var theTagAttributeString =  "" />
	<cfset var theDelimiter =  "" />
	<cfset var theAString =  "" />
	<!--- the result to return --->
	<cfset var theLinkHTML =  "" />	
	
	<cfif arguments.useURLSessionFormat>
		<cfset theLinkURL = URLSessionFormat(theLinkURL) />
	</cfif>
	
	<!--- set up what styling string we want to use --->
	<cfif arguments.HasChildren and arguments.HasContent>
		<cfset theStyleController = "HasBoth" />
	<cfelseif arguments.HasChildren>
		<cfset theStyleController = "HasChildren" />
	<cfelseif arguments.HasContent>
		<cfset theStyleController = "HasContent" />
	<cfelse>
		<cfset theStyleController = "HasNeither" />
	</cfif>
	<!--- get the strings passed to us that belong to this template --->
	<cfif arguments.IsSelectedItem>
		<cfset theSelectedController = "Selected" />
	</cfif>
	<!--- add an id for the selected link but only if we have the definition for the id --->
	<cfif arguments.IsSelectedItem and StructKeyExists(request.SLCMS.PageParams.Navigation.Styling["#theDisplayStyling#"].NavigationStyling_Strings, '#theStyleController#Linkid#theSelectedController#')>
		<cfset theLinkAttributeString = ' id="#request.SLCMS.PageParams.Navigation.Styling['#theDisplayStyling#'].NavigationStyling_Strings['#theStyleController#Linkid#theSelectedController#']#"' />
	<cfelse>
		<cfset theLinkAttributeString = "" />
	</cfif>
	<!--- test for the selected definition as it is new, old menu defs won't have it --->
	<cfif StructKeyExists(request.SLCMS.PageParams.Navigation.Styling["#theDisplayStyling#"].NavigationStyling_Strings, "#theStyleController#Linkclass#theSelectedController#")>
		<cfset theLinkClass = request.SLCMS.PageParams.Navigation.Styling["#theDisplayStyling#"].NavigationStyling_Strings["#theStyleController#Linkclass#theSelectedController#"] />
	<cfelse>
		<cfset theLinkClass = request.SLCMS.PageParams.Navigation.Styling["#theDisplayStyling#"].NavigationStyling_Strings["#theStyleController#Linkclass"] />
	</cfif>
	<cfset theLinktextPrepend = request.SLCMS.PageParams.Navigation.Styling["#theDisplayStyling#"].NavigationStyling_Strings["#theStyleController#LinktextPrepend"] />
	<cfif arguments.IsHiddenItem>
		<cfset theLinktextPrepend =  '<span class="emphNavItem">' & theLinktextPrepend />
	</cfif>
	<cfset theLinktextAppend = request.SLCMS.PageParams.Navigation.Styling["#theDisplayStyling#"].NavigationStyling_Strings["#theStyleController#LinktextAppend"] />
	<cfif arguments.IsHiddenItem>
		<cfset theLinktextAppend =  theLinktextAppend & '</span>' />
	</cfif>
	<!--- add an id for the selected item but only if we have the definition for the id --->
	<cfif arguments.IsSelectedItem and StructKeyExists(request.SLCMS.PageParams.Navigation.Styling["#theDisplayStyling#"].NavigationStyling_Strings, '#theStyleController#LIid#theSelectedController#')>
		<cfset theTagAttributeString = ' id="#request.SLCMS.PageParams.Navigation.Styling['#theDisplayStyling#'].NavigationStyling_Strings['#theStyleController#LIid#theSelectedController#']#"' />
	<cfelse>
		<cfset theTagAttributeString = "" />
	</cfif>
	<!--- set up the class for this item. If we have defined the individual styling for this level use that, if we have defined a standard class add that to the end  --->
	<cfif StructKeyExists(request.SLCMS.PageParams.Navigation.Styling["#theDisplayStyling#"].NavigationStyling_Strings, "#theStyleController#LIclass#theSelectedController#")>
		<cfset theTagClass = request.SLCMS.PageParams.Navigation.Styling["#theDisplayStyling#"].NavigationStyling_Strings["#theStyleController#LIclass#theSelectedController#"] />
	<cfelse>
		<cfset theTagClass = request.SLCMS.PageParams.Navigation.Styling["#theDisplayStyling#"].NavigationStyling_Strings["#theStyleController#LIclass"] />
	</cfif>
	<cfif len(theLevel) and StructKeyExists(request.SLCMS.PageParams.Navigation.Styling["#theDisplayStyling#"].NavigationStyling, "LIclassLevel#theLevel#")>
		<cfset theTagClass = theTagClass & request.SLCMS.PageParams.Navigation.Styling["#theDisplayStyling#"].NavigationStyling["LIclassLevel#theLevel#"]>
	</cfif>
	<cfset theDelimiter = request.SLCMS.PageParams.Navigation.Styling["#theDisplayStyling#"].NavigationStyling_Strings["#theStyleController#Delimiter"] />
	<!--- for the class strings that got created make into HTMl to add to tag --->
	<cfif Len(theTagClass)>
		<cfset theTagAttributeString = ' class="#theTagClass#"#theTagAttributeString#' />
	</cfif>
	<cfif Len(theLinkClass)>
		<cfset theLinkAttributeString = ' class="#theLinkClass#"' />
	</cfif>
	<cfset theAString =  theAString & '<a href="#theLinkURL#"#theLinkAttributeString#>#theLinktextPrepend##theLinktext##theLinktextAppend#</a>' />
	<!--- now we know what we want to show, create the final HTML string --->
	<cfif arguments.FirstDocAtThisLevel_Flag>
		<cfif theDisplayFormat eq "Li">
			<!--- <cfset theLinkHTML =  theLinkHTML &'<ul>' /> --->
		<cfelseif theDisplayFormat eq "Td">
			<!--- <cfset theLinkHTML =  theLinkHTML &'<tr>' /> --->
		</cfif>
	</cfif>
	<cfif theDisplayFormat eq "Li">
		<cfset theLinkHTML =  "<li#theTagAttributeString#>" & theAString />
		<cfif not arguments.ShowingChildren>
<!--- 
			<cfset theLinkHTML =  theLinkHTML &'<ul>' />
		<cfelse>
 --->
			<cfset theLinkHTML =  theLinkHTML &'</li>' />
		</cfif>
	<cfelseif theDisplayFormat eq "Td">
		<cfset theLinkHTML =  "<tr><td#theTagAttributeString#>" />
		<cfif arguments.ShowingChildren>
			<cfset theLinkHTML =  theLinkHTML & theAString />
			<!--- <cfset theLinkHTML =  theLinkHTML & "&nbsp;" & theAString /> why did we do this? --->
		<cfelse>
			<cfset theLinkHTML =  theLinkHTML & theAString />
			<!--- <cfset theLinkHTML =  theLinkHTML &'</td></tr>' /> --->
		</cfif>
		<cfset theLinkHTML =  theLinkHTML &'</td></tr>' />
	<cfelseif theDisplayFormat eq "">
		<cfset theLinkHTML =  theAString />
	</cfif>
	<cfif not arguments.LastDocAtThisLevel_Flag and theDisplayFormat eq "">
		<!--- if it is not the last item and its a string then show the delimiter text, if any --->
		<cfset theLinkHTML =  theLinkHTML & theDelimiter />
	</cfif>
	
	<cfreturn theLinkHTML />
</cffunction>

<cffunction name="loopNavPage" 
						access="private" output="yes" returntype="any" 
						displayname="loop for one Page"
						hint="re-entrant - loops over the page and its children"
						>
	<cfargument name="ArrayPart" required="true">	<!--- the item that we want to show --->
	<cfargument name="displayMode" type="string" default="Navigation" />	<!--- control flag for whether we are showing a breadcrumb or a menu as the input array data is different --->
	<cfargument name="displayStyling" type="string" default="Default" />	<!--- the style set to use --->
	<cfargument name="displayFormat" type="string" default="Li" />	<!--- the html type to use divs/tables --->
	<cfargument name="ThisLevel" type="numeric" default=1 />	<!--- depth into the nav structure --->
	<cfargument name="BottomLevel" type="numeric" default=1 />	<!--- what level to stop at --->
	<cfargument name="PathToThisLevel" type="string" default="" />	<!--- the down to where we are if we didn't start at the top --->
	<cfargument name="FirstDocAtThisLevel_Flag" type="boolean" default="True" />	<!--- flag for if this is the first doc at this level --->
	<cfargument name="LastDocAtThisLevel_Flag" type="boolean" default="True" />		<!--- flag for if this is the last doc at this level --->
	<cfargument name="useURLSessionFormat" type="boolean" default="True" />	<!--- formatting of the URL --->
	<cfargument name="ShowTopHomeLink" type="boolean" default="False" />	<!--- force show of link to top home page, only ever do it once on first hit of this function --->
	<cfargument name="LinkURL" type="string" default="" />	<!--- the link href --->
	<cfargument name="LinkText" type="string" default="" />	<!--- the link text --->
	<cfargument name="HasChildren" type="string" default=False />	<!--- is there content below this? --->
	<cfargument name="HasContent" type="string" default=False />	<!--- is there content in this? --->
	<cfargument name="useLiCloser" type="boolean" default="True" />	<!--- whether to close the Li element --->

	<cfset var flagInNavigationMode = True />	<!--- control flag for whether we are showing a breadcrumb or a menu as the input array data is different --->
	<cfset var theNavHTML =  "" />	<!--- the result to return --->
	<cfset var lcntr = 1>	<!--- localise the counter as we are going to be re-entrant --->
	<cfset var tt = 1>	<!--- localise the counter as we are going to be re-entrant --->
	<cfset var theLevel = arguments.ThisLevel />	<!--- depth into the nav structure --->
	<cfset var FirstDocAtThisLevel = arguments.FirstDocAtThisLevel_Flag />	<!--- initial setting of where we are in the nesting, first item or not --->
	<cfset var LastDocAtThisLevel = arguments.LastDocAtThisLevel_Flag />		<!--- initial setting of where we are in the nesting, last item or not --->
	<cfset var theLinkURL = arguments.LinkURL />	<!--- link that has to be calculated --->
	<cfset var ShowKids = False />	<!--- flag for droppping a level and showing children of document --->
	<cfset var LoopLength = ArrayLen(ArrayPart) />	<!--- just a local var for how long the loop is as we use it several times --->
	<cfset var SecondItemPos = 0 />	<!--- where the first shown item is --->
	<cfset var LastItemPos = LoopLength />	<!--- where the last shown item is --->
	<cfset var flagHasChildren = "Yes" />	<!--- do we have kids? --->
	<cfset var theStyleController = "" />
	<cfset var flgShowHidden = False />	<!--- filter value for the hidden field on docs, whether to show or not --->
	<cfset var theHiddenItem = False />	<!--- flag to show nav item to style it is hidden according to above var --->
	<cfset var theTagClass = "" />	<!--- used for tag styling --->
	<cfset var flgShowTopHomeLink = arguments.ShowTopHomeLink />
	
	<!---  now set a few flags and vars from our input arguments --->
	<cfif arguments.displayMode eq "Breadcrumb">
		<cfset flagInNavigationMode = False />
	</cfif>
	<cfif application.SLCMS.Core.UserPermissions.IsAuthor() or application.SLCMS.Core.UserPermissions.IsEditor() or application.SLCMS.Core.UserPermissions.IsAdmin()>
		<!--- if we are a logged in user with some role or other we need to see the menu-hidden pages to edit them --->
		<cfset flgShowHidden = True />	<!--- 15 gives us author and editor  --->
	</cfif>
	<!--- set up what styling string we want to use --->
	<cfif arguments.HasChildren and arguments.HasContent>
		<cfset theStyleController = "HasBoth" />
	<cfelseif arguments.HasChildren>
		<cfset theStyleController = "HasChildren" />
	<cfelseif arguments.HasContent>
		<cfset theStyleController = "HasContent" />
	<cfelse>
		<cfset theStyleController = "HasNeither" />
	</cfif>

	<cfif flagInNavigationMode>
		<!--- we need to work out our first and last shown items as a random set can be hidden which can muck up our first'n;last calculations --->
		<cfloop from="1" to="#LoopLength#" index="lcntr">
			<cfif  ArrayPart[lcntr].Hidden eq 0>	<!--- test if it is flagged to be visible in the Front End --->
				<cfset SecondItemPos = lcntr+1 />
				<cfbreak>
			</cfif>
		</cfloop>
		<cfif LoopLength gt 1>
			<cfloop from="#LoopLength#" to="1" step="-1" index="lcntr">
				<cfif  ArrayPart[lcntr].Hidden eq 0>	<!--- test if it is flagged to be visible in the Front End --->
					<cfset LastItemPos = lcntr />
					<cfbreak>
				</cfif>
			</cfloop>
		</cfif>
	</cfif>
	<!--- lastly we work out if we have to add class or id statements to the row opening html tag --->
	<cfset theTagClass = request.SLCMS.PageParams.Navigation.Styling["#arguments.DisplayStyling#"].NavigationStyling_Strings["#theStyleController#ULclass"] />
	<cfif len(theLevel) and StructKeyExists(request.SLCMS.PageParams.Navigation.Styling["#arguments.DisplayStyling#"].NavigationStyling, "ULclassLevel#theLevel#")>
		<cfset theTagClass = theTagClass & request.SLCMS.PageParams.Navigation.Styling["#arguments.DisplayStyling#"].NavigationStyling["ULclassLevel#theLevel#"]>
	</cfif>
	<!--- for the class strings that got created make into HTMl to add to tag --->
	<cfif Len(theTagClass)>
		<cfset theTagClass = ' class="#theTagClass#"' />
	</cfif>
	<!--- now we have all our parameters start making HTML --->
	<!--- start this row at this level with the relevant starter code --->
	<cfif theFormat eq "Li">
		<cfset theNavHTML =  theNavHTML &'<ul#theTagClass#>' />
	<cfelseif theFormat eq "Td">
		<!--- <cfset theNavHTML =  theNavHTML & '<tr>' /> --->
	</cfif>
	<cfloop from="1" to="#LoopLength#" index="lcntr">
		<cfif flagInNavigationMode>
			<!--- do the nav/bread differences: set up some mode flags --->
			<cfset flagHasChildren = YesNoFormat(ArrayLen(ArrayPart[lcntr].Children)) />
		<cfelse>
			<cfset flagHasChildren = "No" />
		</cfif>
		<!--- keep a tabs going on how far down the display table we are, displayed rows not all rows --->
		<cfif lcntr eq SecondItemPos>
			<cfset FirstDocAtThisLevel = False />
		</cfif>
		<cfif lcntr eq LastItemPos>
			<cfset LastDocAtThisLevel = True />
		</cfif>
		
		<cfif ArrayPart[lcntr].Hidden eq 0 or (flgShowHidden and ArrayPart[lcntr].Hidden lt 3)>	<!--- only show the item if it is flagged to be visible in the Front End --->
			<!--- work out what to show in this menu row --->
			<cfif flagInNavigationMode>
				<!--- in a nav menu we reset the link for each pass round the loop as we are at the same level --->
				<cfset theLinkURL = arguments.LinkURL />	<!--- link that has to be calculated --->
			</cfif>
			<cfif len(ArrayPart[lcntr].URLnameEncoded)>
				<cfset theLinkURL = theLinkURL & "/" & ArrayPart[lcntr].URLnameEncoded />
			<cfelse>
				<cfset theLinkURL = theLinkURL & "/" & application.SLCMS.Core.PageStructure.EncodeNavName(ArrayPart[lcntr].NavName) />
			</cfif>
			<cfif flgShowHidden and ArrayPart[lcntr].Hidden neq 0>
				<!--- its normally hidden but we are logged in so flag that for special styling --->
				<cfset theHiddenItem = True />
			<cfelse>
				<cfset theHiddenItem = False />
			</cfif>
			<!--- work out if the current document is the selected one, ie the one showing --->
			<cfif arguments.ArrayPart[lcntr].DocID eq request.SLCMS.PageParams.DocID>
				<cfset theSelectedItem = True />
			<cfelse>
				<cfset theSelectedItem = False />
			</cfif>
<!--- 			
			<!--- now expand where we are if needs be, but only if this navigation menu shows the current document --->
			<cfif not request.SLCMS.PageParams.PageToggles.flagNavExpansionDone and theSelectedItem>
				<cfset request.SLCMS.PageParams.PageToggles.flagNavExpansionDone = True />	<!--- only  --->
				<!--- ToDo: switch with nav style thingo, for the moment it is just a toggle --->
				<cfif structKeyExists(session.SLCMS.frontend.NavState.ExpansionFlags, "#session.SLCMS.frontend.CurrentDocID#")>
					<cfif session.SLCMS.frontend.NavState.ExpansionFlags[session.SLCMS.frontend.CurrentDocID] eq True>
						<cfset session.SLCMS.frontend.NavState.ExpansionFlags[session.SLCMS.frontend.CurrentDocID] = False />
					<cfelse>
						<cfset session.SLCMS.frontend.NavState.ExpansionFlags[session.SLCMS.frontend.CurrentDocID] = True />
					</cfif>
				<cfelse>
					<cfset session.SLCMS.frontend.NavState.ExpansionFlags[session.SLCMS.frontend.CurrentDocID] = True />
				</cfif>
				<!--- and expand the parent if it does --->
				<cfset theParentID = request.SLCMS.PageParams.Navigation.Breadcrumbs.Fixed[ArrayLen(request.SLCMS.PageParams.Navigation.Breadcrumbs.Fixed)].ParentID />
				<cfset session.SLCMS.frontend.NavState.ExpansionFlags[theParentID] = True />
			</cfif>
			<!--- 
			<cfoutput>xflag#session.SLCMS.frontend.CurrentDocID#;
			#session.SLCMS.frontend.NavState.ExpansionFlags[session.SLCMS.frontend.CurrentDocID]# |
			</cfoutput>
			 --->
 --->			 
			<!--- decide if there are kids to show --->
			<cfif flagInNavigationMode and
						arguments.ArrayPart[lcntr].IsParent neq 0 and 
						ArrayLen(arguments.ArrayPart[lcntr].Children) neq 0 and 
						session.SLCMS.frontend["SubSite_#request.SLCMS.PageParams.SubSiteID#"].NavState.ExpansionFlags[arguments.ArrayPart[lcntr].DocID] eq True and
						theLevel lt arguments.BottomLevel>
				<!--- we could be showing kids so one last test to make sure at least one is visible --->
				<cfset ShowKids = False />
				<cfif flgShowHidden>
					<cfset ShowKids = True />
				<cfelse>
					<cfloop from="1" to="#ArrayLen(arguments.ArrayPart[lcntr].Children)#" index="tt">
						<cfif arguments.ArrayPart[lcntr].Children[tt].Hidden eq 0>
							<cfset ShowKids = True />
							<cfbreak>
						</cfif>
					</cfloop>
				</cfif>
			<cfelse>
				<cfset ShowKids = False />
			</cfif>


<!--- 			
			<cfoutput>
			expansion flags: #session.SLCMS.frontend.NavState.ExpansionFlags[arguments.ArrayPart[lcntr].DocID]# - ShowKids: #ShowKids# - theLevel: #theLevel# |
			</cfoutput>
 --->			
			<!--- we are about to display an item so if its the very first drop our Top Home Link in first in whatever format we have worked out --->
			<cfif flgShowTopHomeLink>
				<cfset flgShowTopHomeLink = False>
				<cfset theNavHTML = theNavHTML & showNavItem(displayStyling = arguments.displayStyling,
																											displayFormat = arguments.displayFormat,
																											ThisLevel = theLevel,
																											FirstDocAtThisLevel_Flag = FirstDocAtThisLevel,
																											LastDocAtThisLevel_Flag = LastDocAtThisLevel,
																											useURLSessionFormat = arguments.useURLSessionFormat,
																											LinkURL = "http://#application.SLCMS.Core.PortalControl.GetPortalHomeURL()##application.SLCMS.Config.base.BasePortForLinks#",
																											LinkText = application.SLCMS.Core.PortalControl.GetSubSite(SubSiteID=0).data.subSiteNavName,
																											HasContent = True,
																											HasChildren = True,
																											ShowingChildren = False,
																											IsHiddenItem = False,
																											IsSelectedItem = False) />
			</cfif>
			<!--- now display that row in the table --->
			<cfset theNavHTML = theNavHTML & showNavItem(displayStyling = arguments.displayStyling,
																											displayFormat = arguments.displayFormat,
																											ThisLevel = theLevel,
																											FirstDocAtThisLevel_Flag = FirstDocAtThisLevel,
																											LastDocAtThisLevel_Flag = LastDocAtThisLevel,
																											useURLSessionFormat = arguments.useURLSessionFormat,
																											LinkURL = theLinkURL,
																											LinkText = ArrayPart[lcntr].NavName,
																											HasContent = ArrayPart[lcntr].HasContent,
																											HasChildren = flagHasChildren,
																											ShowingChildren = ShowKids,
																											IsHiddenItem = theHiddenItem,
																											IsSelectedItem = theSelectedItem) />
			
			<!--- and any expanded children --->
			<cfif ShowKids>
				<!--- add the new nav html to the existing stuff --->
				<cfset theNavHTML = theNavHTML & loopNavPage(displayStyling = arguments.displayStyling,
																												displayMode=arguments.displayMode, 
																												displayFormat = arguments.displayFormat,
																												ThisLevel = theLevel+1,
																												BottomLevel = arguments.BottomLevel,
																												FirstDocAtThisLevel_Flag = True,
																												LastDocAtThisLevel_Flag = False,
																												useURLSessionFormat = arguments.useURLSessionFormat,
																												LinkURL = theLinkURL,
																												ArrayPart = arguments.ArrayPart[lcntr].Children) />
			</cfif>
		</cfif>
	</cfloop>
	<!--- finished our row at this level so terminate it --->
	<cfif theFormat eq "Li" and len(theNavHTML)>
		<cfset theNavHTML =  theNavHTML &'</ul>' />
	<cfelseif theFormat eq "Td">
		<!--- <cfset theNavHTML =  theNavHTML & '</tr>' /> --->
	</cfif>
	
	
	<cfreturn theNavHTML />
</cffunction>

<cffunction name="SearchNavArrayPart" 
						access="public" output="yes" returntype="struct" 
						displayname="Search Partial NavArray"
						hint="re-entrant - searches nav array to find correct parent and tree below that"
						>
	<cfargument name="ArrayInput" type="array" />	<!---  --->
	<cfargument name="PathToHere" type="string" />	<!---  --->
	<cfargument name="thisLevel" type="numeric" />	<!--- what level we are at --->
	<cfargument name="LeveltoGoTo" type="numeric" />	<!--- what level to drop to --->
	<cfargument name="ForcedParentDocID" type="string" required="false" default=""/>	<!--- overriding parent DocID if doing a nav menu away from our own natural parent --->
	
	<cfset var ncntr = 1 />
	<cfset var thisDocId = request.SLCMS.PageParams.Navigation.Breadcrumbs.Fixed[arguments.thisLevel].DocID />
	<cfset var thisPathToHere = request.SLCMS.PageParams.Navigation.Breadcrumbs.Fixed[arguments.thisLevel].URLNameEncoded />
	<cfset var ret = StructNew() />
	<cfset ret.ArrayPart = ArrayNew(1) />
	<cfset ret.PathToHere = "" />

	<cftry>
		<cfif arguments.ForcedParentDocID neq "">
			<cfset thisDocId = arguments.ForcedParentDocID />
		</cfif>

		<cfloop from="1" to="#ArrayLen(arguments.ArrayInput)#" index="ncntr">
			<!--- look in the fixed breadcrumbs to get the Id of the doc at that level --->
			<cfif arguments.ArrayInput[ncntr].DocID eq thisDocId>
	<!--- 
			<cfif arguments.ArrayInput[ncntr].DocID eq thisDocId or session.SLCMS.frontend["SubSite_#request.SLCMS.PageParams.SubSiteID#"].NavState.theCurrentNavArray[ncntr].DocID eq thisDocId>
			<cfif session.SLCMS.frontend["SubSite_#request.SLCMS.PageParams.SubSiteID#"].NavState.theCurrentNavArray[ncntr].DocID eq thisDocId>
	 --->		
				<!--- found the right section at this level so move into it --->
				<cfset ret.ArrayPart = arguments.ArrayInput[ncntr].Children />
				<cfset ret.PathToHere = arguments.PathToHere & "/" & thisPathToHere />
				<cfif arguments.thisLevel lt arguments.LeveltoGoTo>
					<!--- not deep enuf yet so drop down again --->
					<cfset ret = SearchNavArrayPart(ArrayInput=ret.ArrayPart, PathToHere=ret.PathToHere, thisLevel=arguments.thisLevel+1, LeveltoGoTo=arguments.LeveltoGoTo, ForcedParentDocID=arguments.ForcedParentDocID) />
				</cfif>
				<cfbreak>
			</cfif>
		</cfloop>	

	<cfcatch>
<!--- 
				<cfoutput>SearchNavArrayPart caught when calling level: #arguments.thisLevel#<br>LeveltoGoTo was: #arguments.LeveltoGoTo#<br>ArrayInput:<cfdump var="#arguments.ArrayInput#" expand=false></cfoutput>
 --->
	</cfcatch>
	</cftry>

	<cfreturn ret />
</cffunction>


