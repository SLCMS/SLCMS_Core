<cfsetting enablecfoutputonly="Yes">
<!--- SLCMS base tags to be used in template pages  --->
<!---  --->
<!--- custom tag to display a navigation menu --->
<!--- &copy; mort bay communications --->
<!--- 
docs: startParams
docs:	Name: displayNavigation
docs:	Type:	Custom Tag 
docs:	Role:	Content Display Tag - Core 
docs:	Hint: display a navigation menu as per the site structure and with params defined here and/or in a xxx _NavigationDefinition ini file
docs:	Versions: Tag - 1.0.3; Core - 2.2.0+
docs: endParams
docs: 
docs: startAttributes
docs:	name="attributes.NavName" type="string" default="Default"								; name of the menu, translates to the thisname_NavigationDefinition.ini file which can have a full definition of the navigation html and styling
docs:	name="attributes.TreeStyle" type="string" default=""
docs:	name="attributes.Format" type="string" default=""
docs:	name="attributes.Stylesheet" type="string" default=""
docs:	name="attributes.js" type="string" default=""
docs:	name="attributes.WrapperClass" type="string" default=""
docs:	name="attributes.WrapperId" type="string" default=""
docs:	name="attributes.LevelToStartAt" type="string" default=""								;	where to start: 1 is home page level, 2 often used to show a menu of pages within the parent folder at the top level 
docs:	name="attributes.LevelsToShow" type="string" default=""									;	show one level or more
docs:	name="attributes.FolderToStartAt" type="string" default=""							;	used when you want to show a menu other than your wn arent, eg a set submeny regardless of where you are in the site
docs:	name="attributes.SkipFirstElements" type="string" default="0"						;	these next three control if you are showing all elements and whether you want to ul/table tag round the outside
docs:	name="attributes.SkipLastElements" type="string" default="0"
docs:	name="attributes.ShowWrappingElement" type="string" default="Yes"
docs:	name="attributes.ContentPage" type="string" default="content.cfm"				;	the page that provides the normal content
docs:	name="attributes.useURLSessionFormat" type="boolean" default="False"		;	formatting of the URL
docs:	name="attributes.HidePortalHomeLink" type="boolean" default="False"			;	used to force the default behaviour of showing a link to the top home page when in a subsite
docs:	name="attributes.dumper" type="string" default=""												;	if a string is here and is the name of a viable scope then it will be dumped at the end of the tag
docs: endAttributes
docs: 
docs: startManual
docs: 
docs: endManual
docs: 
docs: startHistory_Versions
docs: Version 1.0.0: 	Base tag
docs: Version 1.0.1:	handles new flexi site structure, attributes
docs: Version 2.0.1:	file handling changed, attributes renamed
docs: Version 2.0.2:	added portal handling for subsites and multiple subSites open in same browser
docs: Version 2.0.3:	added "FolderToStartAt" attribute to make engine more flexible
docs: endHistory_Versions
docs: 
docs: startHistory_Coding
docs: created:   1st Dec 2006 by Kym K, mbcomms
docs: modified:  1st Dec 2006 - 10th Dec 2006 by Kym K, mbcomms: did initial stuff
docs: modified: 30th Dec 2006 - 30th Dec 2006 by Kym K, mbcomms: made into mutli-style with includes for different style of display
docs: modified: 25th Mar 2007 - 25th Mar 2007 by Kym K, mbcomms: added tree display style for how to show the navigation tree
docs: modified: 13th Jun 2007 - 13th Jun 2007 by Kym K, mbcomms: version 1.0.0, made styling and related attributes consistent with other tags
docs: modified: 19th Aug 2007 -  1st Sep 2007 by Kym K, mbcomms: version 1.0.1, changing to the new flexi type site structure
docs: modified: 26th Oct 2007 - 28th Oct 2007 by Kym K, mbcomms: version 1.0.1, changing to the new flexi type site structure
docs: modified: 27th Nov 2007 - 27th Nov 2007 by Kym K, mbcomms: version 1.0.1, added  "string" to display styles for simple linear navigations
docs: modified: 27th Dec 2007 - 29th Dec 2007 by Kym K, mbcomms: version 2.0.1, changed to different structures of control info with one file per nav, parameters renamed, etc
docs: modified: 20th Feb 2008 - 20th Feb 2008 by Kym K, mbcomms: version 2.0.1, changed format of final output to handle empty menues
docs: modified: 20th Dec 2008 - 21st Dec 2008 by Kym K, mbcomms: version 2.0.2, added attributes to not show specified number of first and/or last elements for menus nesting inside other code
docs: modified: 24th Mar 2009 - 25th Mar 2009 by Kym K, mbcomms: version 2.0.2, core V2.2, added a js definition for active menus
docs: modified: 27th Apr 2009 - 27th Apr 2009 by Kym K, mbcomms: version 2.0.2, core V2.2, changing template folder structure to portal/sub-site architecture, sites inside the top site, data structures added/changed to match
docs: modified:  1st Sep 2009 -  1st Oct 2009 by Kym K, mbcomms: version 2.0.2, core V2.2, modifying code for session roles, ie the permissions engine
docs: modified:  7th Nov 2009 -  7th Nov 2009 by Kym K, mbcomms: version 2.0.2, core V2.2, changed navigation structures to include all subsites so we can have multiple windows open
docs: modified: 25th Feb 2012 - 25th Feb 2012 by Kym K, mbcomms: version 2.0.3, core V2.2+, added a top folder attribute so can show a menu for a folder other than its own parent, also added new "docs" documentation
docs: endHistory_Coding
 --->
<cfif thisTag.executionMode IS "start">
	<cfparam name="attributes.NavName" type="string" default="Default">
	<cfparam name="attributes.TreeStyle" type="string" default="">
	<cfparam name="attributes.Format" type="string" default="">
	<cfparam name="attributes.Stylesheet" type="string" default="">
	<cfparam name="attributes.js" type="string" default="">
	<cfparam name="attributes.WrapperClass" type="string" default="">
	<cfparam name="attributes.WrapperId" type="string" default="">
	<cfparam name="attributes.FolderToStartAt" type="string" default="">
	<cfparam name="attributes.LevelToStartAt" type="string" default="">
	<cfparam name="attributes.LevelsToShow" type="string" default="">
	<cfparam name="attributes.SkipFirstElements" type="string" default="0">
	<cfparam name="attributes.SkipLastElements" type="string" default="0">
	<cfparam name="attributes.ShowWrappingElement" type="string" default="Yes">
	<cfparam name="attributes.ContentPage" type="string" default="content.cfm">
	<cfparam name="attributes.useURLSessionFormat" type="boolean" default="False" />
	<cfparam name="attributes.HidePortalHomeLink" type="boolean" default="False" />
	<cfparam name="attributes.dumper" type="string" default="">
	
<!--- 	
<cfoutput>attributes:	</cfoutput><cfdump var="#attributes#" expand="false">
<cfoutput>start nav array:	</cfoutput><cfdump var="#session.FrontEnd["SubSite_#request.SLCMS.PageParams.SubSiteID#"].NavState.theCurrentNavArray#" expand="false">
 --->
	<!--- first off lets see if the specified Navigation Style is available (ie has been entered into config files) --->
	<cfif not StructKeyExists(request.SLCMS.PageParams.Navigation.Styling, attributes.NavName)>
		<!--- we don't know about it so return a message to say so --->
		<cfoutput>No Navigation Definition found with the name of: #attributes.NavName#</cfoutput>
		<cfexit method="exittag">
	</cfif>

	
	<cfinclude template="_NavigationFunctions_inc.cfm">
	<cfinclude template="_NavigationParams_inc.cfm">
	

	<!--- now we have defined our display functions and worked out our parameters lets show the navigation --->
	<!--- first we will get the actual navigation content as we need to see if it is empty
				as that will affect what wrapping we put round it --->
	<cfif ArrayLen(session.SLCMS.FrontEnd["SubSite_#request.SLCMS.PageParams.subSiteID#"].NavState.theCurrentNavArray)>
		<cfif theStylesheet neq "">	<!--- if we have specified some stylesheet then drop it into the head --->
			<cfloop list="#theStylesheet#" index="thisTag.thisStylesheet">
				<cfif not ListFindNoCase(request.SLCMS.PageParams.HeadContent.End.FileList, "#request.SLCMS.PageParams.Paths.URL.thisPageTemplateControlURLpath##trim(thisTag.thisStylesheet)#")> <!--- make sure we don't add it twice --->
					<cfset thisTag.ret = ArrayAppend(request.SLCMS.PageParams.HeadContent.End.Strings, '<link rel="stylesheet" href="#request.SLCMS.PageParams.Paths.URL.thisPageTemplateControlURLPath##trim(thisTag.thisStylesheet)#" type="text/css">') />
					<cfset request.SLCMS.PageParams.HeadContent.End.FileList = ListAppend(request.SLCMS.PageParams.HeadContent.End.FileList, "#request.SLCMS.PageParams.Paths.URL.thisPageTemplateControlURLPath##trim(thisTag.thisStylesheet)#") />
				</cfif>
			</cfloop>
		</cfif>
		<cfif theJS neq "">	<!--- if we have specified some js then drop it into the head --->
			<cfloop list="#theJS#" index="thisTag.thisJS">
				<cfif not ListFindNoCase(request.SLCMS.PageParams.HeadContent.End.FileList, "#request.SLCMS.PageParams.Paths.URL.thisPageTemplateControlURLPath##trim(thisTag.thisJS)#")> <!--- make sure we don't add it twice --->
					<cfset thisTag.ret = ArrayAppend(request.SLCMS.PageParams.HeadContent.End.Strings, '<script src="#request.SLCMS.PageParams.Paths.URL.thisPageTemplateControlURLPath##trim(thisTag.thisJS)#" type="text/javascript"></script>') />
					<cfset request.SLCMS.PageParams.HeadContent.End.FileList = ListAppend(request.SLCMS.PageParams.HeadContent.End.FileList, "#request.SLCMS.PageParams.Paths.URL.thisPageTemplateControlURLPath##trim(thisTag.thisJS)#") />
				</cfif>
			</cfloop>
		</cfif>
		<cfset session.SLCMS.FrontEnd["SubSite_#request.SLCMS.PageParams.SubSiteID#"].NavState.dispRowCounter = 0 />
		<cfset session.SLCMS.FrontEnd["SubSite_#request.SLCMS.PageParams.SubSiteID#"].NavState.displayedRowArray = ArrayNew(2) />
		<!--- almost ready to show stuff we just need the nav array, either the natural one or a defined folder to use as the top --->
		<cfif attributes.FolderToStartAt neq "">
			<!--- we have hard-defined a top folder so grab its nav array and the path to it --->
			<cfset theArrayPart = application.SLCMS.core.pagestructure.getNavStructureArm(ParentID="#attributes.FolderToStartAt#", ThisLevel="#theStartLevel#", SubSiteID="#request.SLCMS.PageParams.SubSiteID#") />
			<cfset baseURL = baseURL & "/" & application.SLCMS.core.pagestructure.getSingleDocStructure(DocID="#attributes.FolderToStartAt#", SubSiteID=request.SLCMS.PageParams.SubSiteID).URLName />
		<cfelse>
			<cfset theArrayPart = session.SLCMS.FrontEnd["SubSite_#request.SLCMS.PageParams.subSiteID#"].NavState.theCurrentNavArray />
		<!--- now we are ready to show stuff but we need to see where we are starting for menus that are not starting at the top level --->
			<cfif theStartLevel gt 1>
				<!--- not at top so wind down to the one above what we want --->
				<cfset temp = SearchNavArrayPart(ArrayInput=theArrayPart, PathToHere=baseURL, thisLevel=1, LeveltoGoTo=theStartLevel) />
				<cfset theArrayPart = temp.ArrayPart />
				<cfset baseURL = temp.PathToHere />
			</cfif>
		</cfif>
		<!--- "theArrayPart" now has the top array we are going to show so work out how many items we want to show --->
		<cfif theFirstElementsToSkip gt 0 and theLastElementsToSkip gt 0>
			<!--- we need to strip off some elements at the front of the back
						we have to allow for elements that are hidden --->
			<cfset theArrayPartLen = ArrayLen(theArrayPart) />
			<cfset theArrayPart1 = ArrayNew(1) />
			<cfloop from="1" to="#theArrayPartLen#" index="lcntr">
				<cfif theArrayPart[lcntr].Hidden eq 0 or (session.user.UserRole gt 0 and theArrayPart[lcntr].Hidden lt 3)>	<!--- only copy across if it is not hidden --->
					<cfset ret = ArrayAppend(theArrayPart1, theArrayPart[lcntr]) />
				</cfif>
			</cfloop>
			<!--- we now have an array with hidden nav items removed so we calculate and loop again to remove the skipped ones --->
			<cfset theArrayPartLen = ArrayLen(theArrayPart1) />
			<cfif theArrayPartLen gt theFirstElementsToSkip>
				<cfset theArrayCopyStartPos = theFirstElementsToSkip+1 />
			<cfelse>
				<!--- not enuf bits to show --->
				<cfset theArrayCopyStartPos = theArrayPartLen />
			</cfif>
	<!--- 
			theArrayPartLen: <cfdump var="#theArrayPartLen#"><br>
			theArrayCopyStartPos: <cfdump var="#theArrayCopyStartPos#"><br>
	 --->
			<!--- now we know where to start strip the front bits off --->
			<cfset theArrayPart2 = ArrayNew(1) />
			<cfloop from="#theArrayCopyStartPos#" to="#theArrayPartLen#" index="lcntr">
				<cfset ret = ArrayAppend(theArrayPart2, theArrayPart1[lcntr]) />
			</cfloop>
<!--- 
			theArrayPart2Len: <cfdump var="#ArrayLen(theArrayPart2)#"><br>
 --->

			<!--- then take of the tail end parts --->
			<cfset theArrayPart2Len = ArrayLen(theArrayPart2) />
			<cfif theArrayPart2Len gt theLastElementsToSkip>
				<cfset theArrayDeleteEndPos = theArrayPart2Len-theLastElementsToSkip+1 />
			<cfelse>
				<!--- not enuf bits to show --->
				<cfset theArrayDeleteEndPos = theArrayPart2Len />
			</cfif>
			<cfloop from="#theArrayPart2Len#" to="#theArrayDeleteEndPos#" step="-1" index="lcntr">
				<cfset ret = ArrayDeleteAt(theArrayPart2, lcntr) />
			</cfloop>
			<!--- 
			theArrayDeleteEndPos: <cfdump var="#theArrayDeleteEndPos#"><br>
			theArrayPart2Len: <cfdump var="#ArrayLen(theArrayPart2)#"><br>
 --->
		<cfelse>
			<!--- we are not shrinking so just copy our array to the final array --->
			<cfset theArrayPart2 = theArrayPart />
		</cfif>
		
<!--- 		
			<cfdump var="#theArrayPart2#" expand="false">
			<cfabort>
		<cfoutput>
		theStartLevel: #theStartLevel# -
		theBottomLevel: #theBottomLevel#
		</cfoutput>
 --->		

		<!--- drop into re-entrant functions to show each row with relevant formatting --->
		<cfset theNavHTML2 = loopNavPage(ArrayPart=theArrayPart2, 
																			displayMode="Navigation", 
																			displayFormat=theFormat, 
																			displayStyling=theNavstyle,
																			ThisLevel = theStartLevel,
																			BottomLevel = theBottomLevel,
																			FirstDocAtThisLevel_Flag = True,
																			LastDocAtThisLevel_Flag = False,
																			LinkURL = baseURL,
																			useURLSessionFormat = attributes.useURLSessionFormat,
																			ShowTopHomeLink	= flgShowTopHomeLink) />
	
		<cfif theNavHTML2 neq "" and attributes.ShowWrappingElement eq "Yes">
			<!--- we have content so wrap it up nicely --->
			<cfset theNavHTML = '<div class="NavContainer">' />
			<cfif theFormat eq "Li">
				<cfset theNavHTML = theNavHTML & '<div#theWrapperClass##theWrapperId#>' />
			<cfelseif theFormat eq "Td">
				<cfset theNavHTML = theNavHTML & '<table#theWrapperClass##theWrapperId#>' />
			<cfelseif theFormat eq "">
				<cfset theNavHTML = theNavHTML & '<div#theWrapperClass##theWrapperId#>' />
			</cfif>
			<!--- add the wrapper round the geberated nav html --->
			<cfset theNavHTML = theNavHTML & theNavHTML2 />
			<!--- and them add on the tail of the wrapper --->
			<cfif theFormat eq "Li">
				<cfset theNavHTML = theNavHTML & '</div>' />
			<cfelseif theFormat eq "Td">
				<cfset theNavHTML = theNavHTML & '</table>' />
			<cfelseif theFormat eq "">
				<cfset theNavHTML = theNavHTML & '</div>' />
			</cfif>
			<cfset theNavHTML = theNavHTML & '</div>' />

		<cfelseif theNavHTML2 neq "" and attributes.ShowWrappingElement eq "No">	<!--- we just want the navigation html without stuff round it --->
			<cfset theNavHTML = theNavHTML2 />
		<cfelseif theNavHTML2 eq "" and attributes.ShowWrappingElement eq "No">	<!--- no navigation html (empty folder or whatever) without stuff round it --->
			<cfset theNavHTML = '' />
		<cfelse>	<!--- no navigation html (empty folder or whatever) with standard stuff round it --->
			<cfset theNavHTML = '<div class="NavContainer"></div>' />
		</cfif>
	<cfelse>
		<cfset theNavHTML = '<div class="NavContainer">The site has no pages in it yet.</div>' />
	</cfif>
	<!--- now we have a full html string so display it --->
	<cfoutput>#theNavHTML#</cfoutput>
	<cfif len(attributes.dumper)>
		<cfdump var="#evaluate(attributes.dumper)#" expand="false" label="#attributes.dumper#">
	</cfif>
	
</cfif>

<cfif thisTag.executionMode IS "end">
</cfif>

<cfsetting enablecfoutputonly="No">
