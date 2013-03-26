<!--- SLCMS base tags to be used in template pages  --->
<!--- &copy; mort bay communications --->
<!---  --->
<!--- custom tag to display the tools (header|footer|item) on a blog page --->
<!---  --->
<!---  --->
<!--- Created:  22nd Jan 2007 by Kym K --->
<!--- Modified: 22nd Jan 2007 - 29th Jan 2007 by Kym K, working in it --->
<!--- modified: 31st Oct 2007 - 31st Oct 2007  by Kym K - changed image path to /global/SLCMSgraphics folder --->
<!--- modified: 23rd Mar 2009 - 23rd Mar 2009 by Kym K - mbcomms: V2.2, changing structures to new module-allowing architecture, the core code is now just another module --->

<!--- 
 --->
<cfsetting enablecfoutputonly="Yes">
<cfif thisTag.executionMode IS "start">
	<cfparam name="attributes.mode" type="string" default="">	<!--- top, middle, bottom type of thing --->
	<cfparam name="attributes.submode" type="string" default="">	<!--- how much of what we show in specified section default is everything --->
	<cfparam name="attributes.EditPlace" type="string" default="#cgi.script_name#">	<!--- where to edit the blog, defaults to here but can be somewhere like the home page for that blog --->

	<!--- set up for what to show, one thing at the moment, more can be added with ease :-) --->
	<cfset showButton = True />
	<cfif attributes.submode eq "AddFolderOnly">
		<cfset showHeaderText = False />
		<cfset AlwaysShowAddButton = False />
	<cfelseif attributes.submode eq "AlwaysAddFolderOnly">
		<cfset showHeaderText = False />
		<cfset AlwaysShowAddButton = True />
	<cfelse>
		<cfset showHeaderText = True />
		<cfset AlwaysShowAddButton = False />
	</cfif>
	<!--- if we are actually adding an entry we don't want the add button --->
	<cfif IsDefined("form.mode") and (form.mode eq "AddBlogEntry" or form.mode eq "EditBlogEntry")>
		<cfset showButton = False />
	</cfif>
	
	<!--- fix any dodgy urls and things --->
	<cfset theEditPlaceURL = request.rootURL & attributes.EditPlace />
	<cfif left(theEditPlaceURL, 2) eq "//">	<!--- can happen depending on what the cgi. gives up --->
		<cfset theEditPlaceURL = removeChars(theEditPlaceURL, 1, 1) />
	</cfif>
	
	<cfif attributes.mode eq "Header">
<!--- 
		<!--- this is to set the session vars before we start using them --->
		<cfinclude template="displayBlog_inc_Set_Category-Date.cfm">
 --->
		<cfset thisCategory = application.Core.Control_Blogs.getCategory(name="#request.theCategory#", blogname="#request.theBlog#") />
		<!--- check to see if we got anything back, could be nothing if just started in and nothing in session yet --->
		<cfif StructIsEmpty(thisCategory)>
			<cfset theCatTitle = "All Category" />
		<cfelse>
			<cfset theCatTitle = thisCategory.CategoryTitle />
		</cfif>
	
		<cfif application.core.UserPermissions.IsAuthor() and (len(request.theCategory) or AlwaysShowAddButton)>
			<!--- show the heading with the add button if editing and we are in a category --->
			<cfoutput>
			<form action="#theEditPlaceURL#" method="post">
			<input type="hidden" name="mode" value="AddBlogEntry">
			<div class="BlogHeaderToolsUpper">
			<cfif showHeaderText>
				<div class="BlogHeaderDisplay">
				#theCatTitle# Entries for #Day(request.theDate)# #MonthAsString(month(request.theDate))# #Year(request.theDate)#
				</div>
			</cfif>
			<cfif showButton>
			<div class="BlogAddEntryButton">
			<input type="image" name="Edit" value="AddBlogEntryImage" src="#request.rootURL#SLCMS/SLCMSstyling/nbutton_addEntry.gif" border="0" title="Add a Blog Entry" alt="Add an Entry" >
			</div>
			</cfif>
			</div>
			</form>
			<div class="BlogHeaderToolsLower"></div>
			</cfoutput>
		<cfelse>
			<cfif showHeaderText>
				<cfoutput>
				<div class="BlogHeaderToolsUpper">
				<div class="BlogHeaderDisplay">
				#theCatTitle# Entries for #Day(request.theDate)# #MonthAsString(month(request.theDate))# #Year(request.theDate)#
				</div>
				</div>
				<div class="BlogHeaderToolsLower"></div>
				</cfoutput>
			</cfif>
		</cfif>
		
	<cfelseif attributes.mode eq "Item">
	<cfoutput>
	<p>
	ping talk and other stuff we don'tndertasnad yet
	</p>
	</cfoutput>
	<cfelseif attributes.mode eq "Footer">
	<cfoutput>
	
	</cfoutput>
	<cfelse>
	
	</cfif>
	
	
</cfif>

<cfif thisTag.executionMode IS "end">
</cfif>
<cfsetting enablecfoutputonly="No">
