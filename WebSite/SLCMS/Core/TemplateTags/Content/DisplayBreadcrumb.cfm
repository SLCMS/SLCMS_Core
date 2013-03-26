<!--- SLCMS base tags to be used in template pages  --->
<!--- &copy; mort bay communications --->
<!---  --->
<!--- custom tag to display a breadcrumb string --->
<!--- it takes the same parameters as the displaynav tag, just works at a simpler level
			only one level in fact! ho funny :-) that was pathetic Kym.... --->
<!--- --->
<!--- created:   4th Dec 2007 by Kym K of mbcomms --->
<!--- modified:  4th Dec 2007 -  4th Dec 2007 by Kym K of mbcomms, did initial stuff --->
<!--- modified: 20th Dec 2008 - 21st Dec 2008 by Kym K - added attributes to not show specified number of first and/or last elements for menus nesting inside other code, needed to match changes in displaynavigation tag --->
<!--- modified: 23rd Mar 2009 - 23rd Mar 2009 by Kym K - mbcomms: V2.2, changing structures to new module-allowing architecture, the core code is now just another module --->

<!--- 
 --->
<cfsetting enablecfoutputonly="Yes">
<cfif thisTag.executionMode IS "start">
	<cfparam name="attributes.NavName" type="string" default="Default">
	<cfparam name="attributes.TreeStyle" type="string" default="">
	<cfparam name="attributes.Format" type="string" default="">
	<cfparam name="attributes.style" type="string" default="">
	<cfparam name="attributes.WrapperClass" type="string" default="">
	<cfparam name="attributes.WrapperId" type="string" default="">
	<cfparam name="attributes.LevelToStartAt" type="string" default="">
	<cfparam name="attributes.LevelsToShow" type="string" default="">
	<cfparam name="attributes.SkipFirstElements" type="string" default="0">	<!--- these next three control if you are showing all elements and whether you want to ul/table tag round the outside --->
	<cfparam name="attributes.SkipLastElements" type="string" default="0">
	<cfparam name="attributes.ShowWrappingElement" type="string" default="Yes">
	<cfparam name="attributes.ContentPage" type="string" default="content.cfm">	<!--- the page that provides the normal content --->
	<cfparam name="attributes.useURLSessionFormat" type="boolean" default="False" />	<!--- formatting of the URL --->

	<!--- first off lets see if the specified Navigation Style is available (ie has been entered into config files) --->
	<cfif not StructKeyExists(request.PageParams.Navigation, attributes.NavName)>
		<!--- we don't know about it so return a message to say so --->
		<cfoutput>No Matching Navigation Definition found with the name of: #attributes.NavName#</cfoutput>
		<cfexit method="exittag">
	</cfif>
	
	
	<cfinclude template="_NavigationFunctions_inc.cfm">
	<cfinclude template="_NavigationParams_inc.cfm">
	
<!--- 	
	<cfset baseURL = application.config.base.RootURL & attributes.ContentPage />	<!--- page is always at the root in flexi --->
	<cfset theNavstyle = trim(attributes.Navstyle) />
	<!--- work out what the shape of the menu tree is --->
	<cfif len(attributes.TreeStyle) eq 0>
		<cfset theTreeStyle = request.PageParams.Navigation.NavigationStyling_Control["#attributes.Navstyle#_TreeStyle"] />
	<cfelse>
		<cfset theTreeStyle = trim(attributes.Format) />
	</cfif>
	<!--- work out what format to use for the HTML if it is not specified as an attribute --->
	<cfif len(attributes.Format) eq 0>
		<cfset theFormat = request.PageParams.Navigation.NavigationStyling_Control["#attributes.Navstyle#_Format"] />
	<cfelse>
		<cfset theFormat = attributes.Format />
	</cfif>
	<!--- work out what style class to use for the HTML if it is not specified as an attribute --->
	<cfif len(attributes.WrapperClass) eq 0>
		<cfset theWrapperClass = request.PageParams.Navigation.NavigationStyling_Control["#attributes.Navstyle#_WrapperClass"] />
	<cfelse>
		<cfset theWrapperClass = attributes.Format />
	</cfif>
	<!--- work out what levels to show if it is not specified as an attribute --->
	<cfif len(attributes.LevelToStartAt) eq 0>
		<cfset theStartLevel = request.PageParams.Navigation.NavigationStyling_Levels["#attributes.Navstyle#^Levels^Top"] />
	<cfelse>
		<cfset theStartLevel = attributes.LevelToStartAt />
	</cfif>
	<cfif len(attributes.LevelsToShow) eq 0>
		<cfset theLevelsToShow = request.PageParams.Navigation.NavigationStyling_Levels["#attributes.Navstyle#^Levels^Max"] />
	<cfelse>
		<cfset theLevelsToShow = attributes.LevelsToShow />
	</cfif>
	<!--- now expand where we are if needs be --->
	<!--- ToDo, switch with nav style thingo, for the moment it is just a toggle --->
	<cfif structKeyExists(session.FrontEnd.NavState.ExpansionFlags, "#session.FrontEnd.CurrentDocID#")>
		<cfset session.FrontEnd.NavState.ExpansionFlags[session.FrontEnd.CurrentDocID] = not session.FrontEnd.NavState.ExpansionFlags[session.FrontEnd.CurrentDocID] />
	<cfelse>
		<cfset session.FrontEnd.NavState.ExpansionFlags[session.FrontEnd.CurrentDocID] = True />
	</cfif>

	<!--- set up the display functions as we are going to be reentrant, can't do it in one codeset --->
	<cffunction name="showNavItem" 
							access="public" output="yes" returntype="string" 
							hint="returns formatted html for one menu line">
		<cfargument name="argumentdisplayStyling" type="string" default="Default" />	<!--- the style set to use --->
		<cfargument name="displayFormat" type="string" default="Li" />	<!--- the html type to use divs/tables --->
		<cfargument name="ThisLevel" type="boolean" default=1 />	<!--- depth into the nav structure --->
		<cfargument name="FirstDocAtThisLevel_Flag" type="boolean" default="True" />	<!--- flag for if this is the first doc at this level --->
		<cfargument name="LastDocAtThisLevel_Flag" type="boolean" default="True" />		<!--- flag for if this is the last doc at this level --->
		<cfargument name="Selected_Flag" type="boolean" default="False" />	<!--- flag for if link is selected --->
		<cfargument name="useURLSessionFormat" type="boolean" default="True" />	<!--- formatting of the URL --->
		<cfargument name="LinkURL" type="string" default="" />	<!--- the link href --->
		<cfargument name="LinkText" type="string" default="" />	<!--- the link text --->

		<!--- predefine all of the variables to keep MX happy --->
		<cfset var theDisplayStyling = trim(arguments.displayStyling) />
		<cfset var theDisplayFormat = trim(arguments.DisplayFormat) />
		<cfset var theLevel = trim(arguments.ThisLevel) />	<!--- depth into the nav structure --->
		<cfset var theLinktext = trim(arguments.LinkText) />
		<cfset var theLinkURL = trim(arguments.LinkURL) />
		<!--- the vars we fill as we go --->
		<cfset var theLinkClass =  ""/>
		<cfset var theLinkPrepend = "" />
		<cfset var theLinkAppend = "" />
		<cfset var theTagClass =  ""/>
		<cfset var theDelimiter =  ""/>
		<!--- the result to return --->
		<cfset var theLinkHTML =  ""/>	
		
<!--- 		
		<cfoutput>
		shownav - Arguments: <cfdump var="#Arguments#">
		</cfoutput>
 --->		
		<cfif arguments.useURLSessionFormat>
			<cfset theLinkURL = URLSessionFormat(theLinkURL) />
		</cfif>
		
		<!--- set up what styling string we want to use --->
		<cfset theStyleController = "HasBoth" />
		<!--- get the strings passed to us that belong to this template --->
		<cfif arguments.Selected_Flag>
			<cfset theLinkClass = request.PageParams.Navigation.NavigationStyling_Strings["#theDisplayStyling#^#theStyleController#^LinkclassSelected"] />
		<cfelse>
			<cfset theLinkClass = request.PageParams.Navigation.NavigationStyling_Strings["#theDisplayStyling#^#theStyleController#^Linkclass"] />
		</cfif>
		<cfset theLinktextPrepend = request.PageParams.Navigation.NavigationStyling_Strings["#theDisplayStyling#^#theStyleController#^LinktextPrepend"] />
		<cfset theLinktextAppend = request.PageParams.Navigation.NavigationStyling_Strings["#theDisplayStyling#^#theStyleController#^LinktextAppend"] />
		<cfset theTagClass = request.PageParams.Navigation.NavigationStyling_Strings["#theDisplayStyling#^#theStyleController#^LIclass"] />
		<cfif len(theLevel) and StructKeyExists(request.PageParams.Navigation.NavigationStyling_Levels, "#theDisplayStyling#^Level#theLevel#^LIclass")>
			<cfset theTagClass = theTagClass & request.PageParams.Navigation.NavigationStyling_Levels["#theDisplayStyling#^Level#theLevel#^LIclass"]>
		</cfif>
		<cfset theDelimiter = request.PageParams.Navigation.NavigationStyling_Strings["#theDisplayStyling#^#theStyleController#^Delimiter"] />
		<!--- for the class strings that got created make into HTMl to add to tag --->
		<cfif Len(theTagClass)>
			<cfset theTagClass = ' class="#theTagClass#"' />
		</cfif>
		<cfif Len(theLinkClass)>
			<cfset theLinkClass = ' class="#theLinkClass#"' />
		</cfif>
		<!--- now we know what we want to show, create the final HTML string --->
		<cfif arguments.FirstDocAtThisLevel_Flag>
			<cfif theDisplayFormat eq "Li">
				<cfset theLinkHTML =  theLinkHTML &'<ul>' />
			<cfelseif theDisplayFormat eq "Td">
				<cfset theLinkHTML =  theLinkHTML &'<tr>' />
			</cfif>
		</cfif>
		<cfif theDisplayFormat eq "Li">
			<cfset theLinkHTML =  '<li#theTagClass#><a href="#theLinkURL#"#theLinkClass#>#theLinktextPrepend##theLinktext##theLinktextAppend#</a>' />
			<cfif arguments.ShowingChildren>
				<cfset theLinkHTML =  theLinkHTML &'<ul>' />
			<cfelse>
				<cfset theLinkHTML =  theLinkHTML &'</li>' />
			</cfif>
		<cfelseif theDisplayFormat eq "Td">
			<cfset theLinkHTML =  '<td#theTagClass#><a href="#theLinkURL#"#theLinkClass#>#theLinktextPrepend##theLinktext##theLinktextAppend#</a>' />
			<cfif arguments.ShowingChildren>
				<cfset theLinkHTML =  theLinkHTML &'</td></tr>' />
			<cfelse>
				<cfset theLinkHTML =  theLinkHTML &'</td></tr>' />
			</cfif>
		<cfelseif theDisplayFormat eq "">
			<cfset theLinkHTML =  '<a href="#theLinkURL#"#theLinkClass#>#theLinktextPrepend##theLinktext##theLinktextAppend#</a>' />
		</cfif>
		<cfif arguments.LastDocAtThisLevel_Flag>
			<!--- if we have finished and about to rise a level then tidy up our list elements --->
			<cfif theFormat eq "Li">
				<cfset theLinkHTML =  theLinkHTML &'</ul>' />
			<cfelseif theFormat eq "Td">
				<cfset theLinkHTML =  theLinkHTML &'' />
			</cfif>
		<cfelse>
			<cfif theDisplayFormat eq "">
				<!--- if it is not the last item and its a string then show the delimiter text, if any --->
				<cfset theLinkHTML =  theLinkHTML & theDelimiter />
			</cfif>
		</cfif>
		
		<cfreturn theLinkHTML />
	</cffunction>

	<cffunction name="loopNavPage" 
							access="public" output="yes" returntype="any" 
							displayname="loop for one Page"
							hint="re-entrant - loops over the page and its children"
							>
		<cfargument name="ArrayPart" required="true">	<!--- the item that we want to show --->
		<cfargument name="displayStyling" type="string" default="Default" />	<!--- the style set to use --->
		<cfargument name="displayFormat" type="string" default="Li" />	<!--- the html type to use divs/tables --->
		<cfargument name="ThisLevel" type="boolean" default=1 />	<!--- depth into the nav structure --->
		<cfargument name="PathToThisLevel" type="string" default="" />	<!--- the down to where we are if we didn't start at the top --->
		<cfargument name="FirstDocAtThisLevel_Flag" type="boolean" default="False" />	<!--- flag for if this is the first doc at this level --->
		<cfargument name="LastDocAtThisLevel_Flag" type="boolean" default="False" />		<!--- flag for if this is the last doc at this level --->
		<cfargument name="useURLSessionFormat" type="boolean" default="True" />	<!--- formatting of the URL --->
		<cfargument name="LinkURL" type="string" default="" />	<!--- the link href --->
		<cfargument name="LinkText" type="string" default="" />	<!--- the link text --->
		<cfargument name="HasChildren" type="string" default=False />	<!--- is their content below this? --->
		<cfargument name="HasContent" type="string" default=False />	<!--- is their content in this? --->
		<cfargument name="useLiCloser" type="boolean" default="True" />	<!--- whether to close the Li element --->

		<cfset var theNavHTML =  "" />	<!--- the result to return --->
		<cfset var lcntr = 1>	<!--- localise the counter as we are going to be re-entrant --->
		<cfset var theLevel = arguments.ThisLevel />	<!--- depth into the nav structure --->
		<cfset var FirstDocAtThisLevel = arguments.FirstDocAtThisLevel_Flag />	<!--- initial setting of where we are in the nesting, first item or not --->
		<cfset var LastDocAtThisLevel = arguments.LastDocAtThisLevel_Flag />		<!--- initial setting of where we are in the nesting, last item or not --->
		<cfset var theLinkURL = arguments.LinkURL />	<!--- link that has to be calculated --->
		<cfset var ShowKids = False />	<!--- flag for droppping a level and showing children of document --->
		<cfset var LoopLength = ArrayLen(ArrayPart) />	<!--- just a local var for how long the loop is as we use it several times --->
		<cfset var SecondItemPos = 0 />	<!--- where the first shown item is --->
		<cfset var LastItemPos = LoopLength />	<!--- where the last shown item is --->
<!--- 
<cfoutput>loopNavPage Arguments</cfoutput>
<cfdump var="#arguments#" expand="false">
 --->
		<!--- we need to work out our first and last shown items as a random set can be hidden which can muck up our fist'n;last calculations --->
		<cfloop to="1" from="#LoopLength#" step="-1" index="lcntr">
			<!--- keep a tabs going on how far down the display table we are, displayed rows not all rows --->
			<cfif lcntr eq LoopLength>
				<cfset FirstDocAtThisLevel = True />
			</cfif>
			<cfif lcntr eq 1>
				<cfset LastDocAtThisLevel = True />
			</cfif>
			
			
			<cfif  ArrayPart[lcntr].Hidden eq 0>	<!--- only show the item if it is flagged to be visible in the Front End --->
				<!--- work out what to show in this menu row --->
				<cfset theLinkURL = arguments.LinkURL & "/" />	<!--- link that has to be calculated --->
				<cfif len(ArrayPart[lcntr].URLnameEncoded)>
					<cfset theLinkURL = theLinkURL & ArrayPart[lcntr].URLnameEncoded />
				<cfelse>
					<cfset theLinkURL = theLinkURL & application.Core.PageStructure.EncodeNavName(ArrayPart[lcntr].NavName) />
				</cfif>
				<!--- now display that row in the table --->
				<cfset theNavHTML = theNavHTML & showNavItem(displayStyling = arguments.displayStyling,
																												displayFormat = arguments.displayFormat,
																												ThisLevel = theLevel,
																												FirstDocAtThisLevel_Flag = FirstDocAtThisLevel,
																												LastDocAtThisLevel_Flag = LastDocAtThisLevel,
																												Selected_Flag = LastDocAtThisLevel,
																												useURLSessionFormat = arguments.useURLSessionFormat,
																												LinkURL = theLinkURL,
																												LinkText = ArrayPart[lcntr].NavName) />
				
			</cfif>
		</cfloop>
		
		<cfreturn theNavHTML />
	</cffunction>
 --->	

	<!--- now we have defined our display functions lets show the navigation --->
	<cfset theNavHTML = '<div class="NavContainer">' />	<!--- a global wrapping div, same as all nav areas --->
	<!--- then the appropriate starting element for the style of nav --->
	<cfif theFormat eq "Li">
		<cfset theNavHTML = theNavHTML & '<div#theWrapperClass##theWrapperId#>' />
	<cfelseif theFormat eq "Td">
		<cfset theNavHTML = theNavHTML & '<table#theWrapperClass##theWrapperId#>' />
	<cfelseif theFormat eq "">
		<cfset theNavHTML = theNavHTML & '<div#theWrapperClass##theWrapperId#>' />
	</cfif>

	<cfif ArrayLen(request.PageParams.Navigation.Breadcrumbs.Fixed)>
		<cfset session.FrontEnd["SubSite_#request.pageparams.SubSiteID#"].NavState.dispRowCounter = 0 />
		<cfset session.FrontEnd["SubSite_#request.pageparams.SubSiteID#"].NavState.displayedRowArray = ArrayNew(2) />
		<!--- now we are ready to show stuff  --->
		<cfset theArrayPart = request.PageParams.Navigation.Breadcrumbs.Fixed />
		<!---  --->
		<cfif theTreeStyle eq "IncludeHome">
			<cfset theNavHTML = theNavHTML & showNavItem(displayStyling = theNavstyle,
																										displayFormat = theFormat,
																										ThisLevel = 1,
																										FirstDocAtThisLevel_Flag = True,
																										LastDocAtThisLevel_Flag = False,
																										Selected_Flag = False,
																										useURLSessionFormat = attributes.useURLSessionFormat,
																										LinkURL = baseURL,
																										LinkText = "Home") />
		
			<cfset theFirstDocAtThisLevel = False>
		<cfelse>
			<cfset theFirstDocAtThisLevel = True>
		</cfif>
		<!--- drop into standard re-entrant function to show this one row with relevant formatting --->
		<cfset theNavHTML = theNavHTML & loopNavPage(ArrayPart=theArrayPart, 
																									displayMode="Breadcrumb", 
																									displayFormat=theFormat, 
																									displayStyling=theNavstyle,
																									ThisLevel = theStartLevel,
																									BottomLevel = theBottomLevel,
																									FirstDocAtThisLevel_Flag = theFirstDocAtThisLevel,
																									LastDocAtThisLevel_Flag = False,
																									LinkURL = baseURL,
																									useURLSessionFormat = attributes.useURLSessionFormat) />
	<cfelse>
		<cfset theNavHTML = theNavHTML & "The site has no pages in it yet." />
	</cfif>
	<cfif theFormat eq "Li">
		<cfset theNavHTML = theNavHTML & '</div>' />
	<cfelseif theFormat eq "Td">
		<cfset theNavHTML = theNavHTML & '</table>' />
	<cfelseif theFormat eq "">
		<cfset theNavHTML = theNavHTML & '</div>' />
	</cfif>
	<cfset theNavHTML = theNavHTML & '</div>' />
	<!--- now we have a full html string so display it --->
	<cfoutput>#theNavHTML#</cfoutput>

</cfif>	<!--- end: tag execution mode is start --->

<cfif thisTag.executionMode IS "end">
</cfif>
<cfsetting enablecfoutputonly="No">
