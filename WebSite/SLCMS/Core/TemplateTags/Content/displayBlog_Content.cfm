<!--- SLCMS base tags to be used in template pages  --->
<!--- &copy; mort bay communications --->
<!---  --->
<!--- custom tag to display a Blog container --->
<!--- some code is common with a standard content container but blog biased
			but it is not as stand-alone as a content contanier as it relies on session variables to
			carry the info related to current category, date, etc.
			It does use standalone CFCs however.
			The flow is simpler as this tag is called once per page ratehr than once per container so 
			identification is easy and there is one action only each pass
			 --->
<!--- created:  21st Jan 2007 by Kym K --->
<!--- modified: 21st Jan 2007 - 29th Jan 2007 by Kym K, did initial stuff --->
<!--- Modified:  8th Feb 2007 -  8th Feb 2007 by Kym K, added "Author" role for edit content only, no backend at all --->
<!--- modified: 31st Oct 2007 - 31st Oct 2007 by Kym K - changed image path to /global/slcmsGraphics folder --->
<!--- modified: 28th Nov 2007 - 29th Nov 2007 by Fiona & Kym K - edited slcmsimages and added clear divs to improve cosmetics when showing edit buttons --->
<!--- modified: 23rd Mar 2009 - 23rd Mar 2009 by Kym K - mbcomms: V2.2, changing structures to new module-allowing architecture, the core code is now just another module --->

<!--- 
 --->
<cfsetting enablecfoutputonly="Yes">
<cfif thisTag.executionMode IS "start">
	<cfparam name="attributes.blog" type="string" default="">	<!--- the name of the blog --->
	<cfparam name="attributes.Category" type="string" default="">	<!--- the name of the category to show if specific --->
	<cfparam name="attributes.EntryType" type="string" default="">	<!--- which entry to show used for specifics: like: "latest" --->
	<cfparam name="attributes.EntryName" type="string" default="">	<!--- the name of a spcific entry to show --->
	<cfparam name="attributes.DisplayParts" type="string" default="All">	<!--- which part of the entry to display. Useful for tiny pods, etc --->
	<cfparam name="attributes.EditPlace" type="string" default="#cgi.script_name#">	<!--- where to edit the blog, defaults to here but can be somewhere like the home page for that blog --->
	<cfparam name="attributes.ShowMore" type="string" default="Auto">	<!--- whether to show the "more" link: "auto" searches for a [more] tag, "yes" always shows, "no" never shows --->
	<cfparam name="attributes.MoreText" type="string" default="more &gt;&gt;">	<!--- what to show in the "more" link --->

	<!--- set up a few vars, default or calculated --->
	<cfset theContent = "" />
	<cfif attributes.blog eq "">	
		<!--- we don't have a defined blog so grab the default, if available, if not make it --->
		<cfif not IsDefined("request.theBlog")>
			<cfinclude template="displayBlog_inc_Set_Blog-Category-Date.cfm">
		</cfif>
		<cfset theBlogName = request.theBlog />
	<cfelse>
		<cfset theBlogName = attributes.blog />
	</cfif>
	
	<cfif attributes.Category eq "">	
		<!--- we don't have a defined Category so grab the default, if available, if not make it --->
		<cfif not IsDefined("request.theCategory")>
			<cfinclude template="displayBlog_inc_Set_Blog-Category-Date.cfm">
		</cfif>
		<cfset theCategoryName = request.theCategory />
	<cfelse>
		<cfset theCategoryName = attributes.Category />
	</cfif>
	
	<cfif attributes.EntryType eq "Latest">
		<cfset ShowMode = "Single"/>
		<cfset EntryToShow = "Latestx1x1x1"/>
		<cfset theMaxRows = 1 />
	<cfelse>
		<cfset ShowMode = "Normal"/>
		<cfset EntryToShow = ""/>
		<cfset theMaxRows = 99 />	<!--- something big - maybe a config thing later, how many to show per page? --->
	</cfif>

	<cfif Len(attributes.EntryName)>
		<cfset ShowMode = "Single"/>
		<cfset EntryToShow = attributes.EntryName />
		<cfset theMaxRows = 1 />
	<cfelseif Len(request.theEntryName)>>
		<cfset ShowMode = "Single"/>
		<cfset EntryToShow = request.theEntryName />
		<cfset theMaxRows = 1 />
	</cfif>

	<!--- fix any dodgy urls and things --->
	<cfset theEditPlaceURL = request.rootURL & attributes.EditPlace />
	<cfif left(theEditPlaceURL, 2) eq "//">	<!--- can happen depending on what the cgi. gives up --->
		<cfset theEditPlaceURL = removeChars(theEditPlaceURL, 1, 1) />
	</cfif>
	
	<!--- now we have refined the why's and wherefores see if we are 
				adding a new entry, 
				editing an existing one or 
				just showing what we have got --->
	
	<cfif application.core.UserPermissions.IsAuthor() and IsDefined("form.mode")>	<!--- this should flag what we are up to --->
		<cfif form.mode eq "AddBlogEntry">
			<cfset SaveMode = False />
			<cfset EditMode = False />
			<cfset AddMode = True />
		<cfelseif form.mode eq "SaveBlogEntry">
			<cfset SaveMode = True />
			<cfset EditMode = False />
			<cfset AddMode = True />
		<cfelseif form.mode eq "EditBlogEntry">
			<cfset SaveMode = False />
			<cfset EditMode = True />
			<cfset AddMode = False />
		<cfelse>	<!--- don't recognise it so just show --->
			<cfset SaveMode = False />
			<cfset EditMode = False />
			<cfset AddMode = False />
		</cfif>
	<cfelse>
		<!--- no mode so we are just looking --->
		<cfset SaveMode = False />
		<cfset EditMode = False />
		<cfset AddMode = False />
	</cfif>
	
	<!--- if in save mode we can just save the entry and then show a full page, 
				no complications for this type of content --->	
	<cfif SaveMode>
		<cfset theContent = trim(form.content) />	<!--- this is just to tidy it up --->
		<cfset theContentControlData = StructNew() />	<!--- a struct of info the saving engine needs --->
		<cfset theContentControlData.contentID = form.ContentID />
		<cfset theContentControlData.BlogID = form.BlogID />
		<cfset theContentControlData.CategoryID = form.CategoryID />
		<cfset theContentControlData.EntryID = form.EntryID />
		<cfif theContentControlData.contentID eq 0>
			<!--- its a new entry so default its date to whatever the blog is set to. Use this now not the previous as editing might have taken time --->
			<cfset theContentControlData.EntryDate = request.theDate />
		<cfelse>
			<cfset theContentControlData.EntryDate = form.EntryDate />
		</cfif>
		<!--- save the content it will return the new contentID --->
		<cfset newContentID = application.Core.Content_DatabaseIO.saveBlogContent(content="#theContent#", ContentControlData="#theContentControlData#", SubSiteID="#request.PageParams.SubSiteID#") />
		<!--- and the Summary and Title --->
		<cfset theContentControlData.contentID = newContentID />
		<cfset ret = application.Core.Control_Blogs.saveEntrySummary_Title(Title="#trim(form.Title)#", summary="#trim(form.summary)#", ContentControlData="#theContentControlData#") />
		<!--- and flag done if this flag is used anywhere else --->
		<cfset SaveMode = False />
		<cfset AddMode = False />
	</cfif>
	
<!--- 	
	<cfexit>
 --->	
	<!--- get the the items for the specified category and date, return is a struct with a query in it --->
	<cfif ShowMode eq "Normal">
		<cfset theBlogEntries = application.Core.Control_Blogs.getBlogEntries(BlogName="#theBlogName#", Category="#theCategoryName#", Date="#request.theDate#") />
	<cfelse>
		<!--- get the appropriate entrie(s) --->
		<cfif EntryToShow eq "Latestx1x1x1">
			<cfset theBlogEntries = application.Core.Control_Blogs.getBlogEntryLatest(BlogName="#theBlogName#", Category="#theCategoryName#") />
		<cfelse>
			<cfset theBlogEntries = application.Core.Control_Blogs.getBlogEntryIDSpecific(BlogName="#theBlogName#", Category="#theCategoryName#", EntryURLName="#EntryToShow#") />
		</cfif>
	</cfif>
	<!--- see if we have any --->
	<cfif theBlogEntries.RecordCount eq 0>
		<cfset flagNoBlogItems = True />
		<cfif ShowMode eq "Normal">
			<cfset NoEntryResultsText = "There are no Entries for this date" />
		<cfelseif ShowMode eq "Single">
			<cfif EntryToShow eq "Latest">
				<cfset NoEntryResultsText = "There are no #attributes.blog# Entries" />
			<cfelse>
				<cfset NoEntryResultsText = "There is no Entry" />
			</cfif>
		<cfelse>
		</cfif>
	<cfelse>
		<cfset flagNoBlogItems = False />
		<!--- get the items into something useful for display --->
	</cfif>
<!--- 
<cfdump var="#theBlogEntries#">	
<cfabort>
 --->	
 
 <!--- as there could be many entries treat like multiple containers as in content tags --->
 <!--- loop over the entries if we are not adding or editing
 				if we are adding or editing then drop back to a single edit box --->
	<cfif EditMode or AddMode>
		<cfset theBlogEntry = StructNew() />
	 	<cfif AddMode>
			<!--- if we are adding an entry then create a blank structure as there is nothing to grab --->
			<cfset theBlogEntry.BlogID = application.Core.Control_Blogs.getBlogDetail(name="#theBlogName#").BlogID />
			<cfset theBlogEntry.CategoryID = application.Core.Control_Blogs.getCategory(BlogName="#theBlogName#", name="#theCategoryName#").CategoryID />
			<cfset theBlogEntry.ContentID = 0 />
			<cfset theBlogEntry.EntryID = application.mbc_Utility.Utilities.getNextID("BlogEntryID") />
			<cfset theBlogEntry.EntryDate = Now() />
			<cfset theBlogEntry.Summary = "" />
			<cfset theBlogEntry.Title = "" />
			<cfset theContent = "" />
		<cfelse>
			<cfset theBlogEntry.BlogID = form.BlogID />
			<cfset theBlogEntry.CategoryID = form.CategoryID />
			<cfset theBlogEntry.ContentID = form.ContentID />
			<cfset theBlogEntry.EntryID = form.EntryID />
			<cfset theBlogEntry.EntryDate = form.EntryDate />
			<cfset theBlogEntry.Summary = form.Summary />
			<cfset theBlogEntry.Title = form.Title />
			<cfset theContent = application.Core.Content_DatabaseIO.getContent(ContentID="#form.ContentID#", SubSiteID="#request.PageParams.SubSiteID#") />
		</cfif>
<!--- 		
		<cfdump var="#theBlogEntry#">
 --->		
	 	<!--- show the content to edit --->
		<cfoutput>
		<form action="#cgi.script_name##cgi.path_info#" method="post" class="ContentContainer_ControlButtons">
		<input type="hidden" name="mode" value="SaveBlogEntry">
		<input type="hidden" name="ContentID" value="#theBlogEntry.ContentID#">
		<input type="hidden" name="blogID" value="#theBlogEntry.BlogID#">
		<input type="hidden" name="CategoryID" value="#theBlogEntry.CategoryID#">
		<input type="hidden" name="EntryID" value="#theBlogEntry.EntryID#">
		<input type="hidden" name="EntryDate" value="#theBlogEntry.EntryDate#">
		<input type="hidden" name="FCKSubmission" value="Yes">
		<input type="hidden" name="Edit" value="EditContainer">
		<!--- an input field for the summary --->
		Entry Title: <input type="text" name="Title" value="#theBlogEntry.Title#" class="txt" maxlength="255">
		Entry Summary: <input type="text" name="Summary" value="#theBlogEntry.Summary#" class="txt" maxlength="255">

		
		<cfinclude template="_wysiwygEditors_inc.cfm">

<!--- 		
		<cfscript>
		// Calculate basepath for FCKeditor. It's in the folder right below us
		basePath = request.FCKEditorBaseURL;
		
		fckEditor = createObject("component", "#basePath#fckeditor");
		fckEditor.instanceName	= "Content";
		fckEditor.value			= '#theContent#';
		fckEditor.basePath		= '#request.FCKEditorBaseURL#';
		fckEditor.width			= "100%";
		fckEditor.height		= 400;
		fckEditor.create(); // create the editor.
		</cfscript>
 --->
		</form>
		</cfoutput>
	<cfelse>
	
	 	<!--- just show the entries so loop over what we have to show --->
		<cfif flagNoBlogItems>
			<cfoutput>
			<div class="BlogContainer_Wrapper">
			<!--- <p>&nbsp;</p> --->
			<p>#NoEntryResultsText#</p>
			<div class="BlogLink_Clear"></div>
			</div>
			</cfoutput>
		<cfelse>
		 	<cfloop query="theBlogEntries.query" startrow="1" endrow="#theMaxRows#">
				<!--- do stuff that is entry-dependent --->
					<!--- this chunk of code works out if we have to show a "more" link and what it is --->
					<cfset thisContentID = theBlogEntries.query.ContentID />
					<cfset thisContent = application.Core.Content_DatabaseIO.getContent(ContentID="#thisContentID#", ContentType="Blog", SubSiteID="#request.PageParams.SubSiteID#") />
					<cfif attributes.ShowMore eq "yes">
						<cfset ShowMoreFlag = True />
					<cfelseif attributes.ShowMore eq "auto">
						<cfset MoreFlagPos = FindNoCase("[more]", thisContent) />
						<cfif MoreFlagPos gt 0>	
							<!--- we have a [more] in this text so use it or dump it --->
							<cfif ShowMode eq "single">
								<!--- its a single blog display so show everything, minus the tag --->
								<cfset thisContent = ReplaceNoCase(thisContent, "[more]", "") />
								<cfset ShowMoreFlag = False />
							<cfelse>
								<!--- flag we want the link and chop the content down --->
								<cfset ShowMoreFlag = True />
								<cfset thisContent = left(thisContent, MoreFlagPos-1) />
							</cfif>
						<cfelse>
							<cfset ShowMoreFlag = False />
						</cfif>
					<cfelse>	<!--- do not show the more link --->
						<cfset ShowMoreFlag = False />
					</cfif>
					<!--- now we know if we need to show the link, if we do work out what it is --->
					<!--- firstly work out what the category name of this entry is for the link --->
					<cfset thisCategoryName = application.Core.Control_Blogs.getCategory(BlogName="#theBlogName#", id="#theBlogEntries.query.BlogCategoryID#").CategoryURLName />
					<!--- this is done in bits to allow for missing items and not get stray backslashes drifting about to confuse browsers --->
					<cfif ShowMoreFlag>
						<cfset theMoreLink = "#theEditPlaceURL#/" />
						<cfif len(theBlogName)>
							<cfset theMoreLink = theMoreLink & "#theBlogName#/" />
						</cfif>
						<cfif len(thisCategoryName)>
							<cfset theMoreLink = theMoreLink & "#thisCategoryName#/" />
						</cfif>
						<cfset theDateBit = DateFormat(theBlogEntries.query.EntryDate, "YYYY/MM/DD") />
						<cfif len(theDateBit)>
							<cfset theMoreLink = theMoreLink & "#theDateBit#/" />
						</cfif>
						<cfset theMoreLink = theMoreLink & "#URLEncodedFormat(theBlogEntries.query.BlogURL)#" />
					<cfelse>
						<cfset theMoreLink = "" />	<!--- just in case...... --->
					</cfif>

					<cfoutput>
					<cfif application.core.UserPermissions.IsAuthor()>
						<div class="BlogContainer_Marker">
						<div class="BlogContainer_Controls">
						<form action="#theEditPlaceURL#?#cgi.path_info#" method="post" class="ContentContainer_ControlButtons">
							<input type="hidden" name="mode" value="EditBlogEntry">
							<input type="hidden" name="ContentID" value="#theBlogEntries.query.ContentID#">
							<input type="hidden" name="blogID" value="#theBlogEntries.query.BlogID#">
							<input type="hidden" name="CategoryID" value="#theBlogEntries.query.BlogCategoryID#">
							<input type="hidden" name="EntryID" value="#theBlogEntries.query.BlogEntryID#">
							<input type="hidden" name="EntryDate" value="#theBlogEntries.query.EntryDate#">
							<input type="hidden" name="Summary" value="#theBlogEntries.query.Summary#">
							<input type="hidden" name="Title" value="#theBlogEntries.query.Title#">
							<input type="hidden" name="Edit" value="EditContainer">
							<input type="hidden" name="FCKSubmission" value="No">
							<input type="image" name="Edit" value="EditContainer" src="#request.rootURL#SLCMS/SLCMSstyling/nbutton_edit.gif" border="0" title="Edit Content in this Container">
						</form>
						</div>
					<cfelse>
						<div class="BlogContainer_Wrapper">
					</cfif>
			
					<!--- if we are an author we see the tool buttons so push the content below them --->
					<cfif application.core.UserPermissions.IsAuthor()>
						<div style="clear:right"></div> 
					</cfif>

					<cfif len(theBlogEntries.query.Title) and (ListFindNoCase(attributes.DisplayParts, "Title") or attributes.DisplayParts eq "all")>
					<div class="BlogContainer_Title">
					#theBlogEntries.query.Title#
					</div>
					</cfif>
					<cfif len(theBlogEntries.query.Summary) and (ListFindNoCase(attributes.DisplayParts, "Summary") or attributes.DisplayParts eq "all")>
					<div class="BlogContainer_Summary">
					#theBlogEntries.query.Summary#
					</div>
					</cfif>
					<cfif (ListFindNoCase(attributes.DisplayParts, "Content") or attributes.DisplayParts eq "all")>
					<div class="BlogContainer_Content">
					#thisContent#
					</div>
					</cfif>
					<cfif ShowMoreFlag>	<!--- show the more link --->
					<div class="BlogLink_More">
					<a name="BlogLink-More#theBlogEntries.query.ContentID#" href="#theMoreLink#">#attributes.MoreText#</a>
					</div>
					</cfif>
					<div class="BlogLink_Clear"></div>
					</div>
					</cfoutput> 
			</cfloop>
		</cfif>	<!--- end: entries to show --->
	</cfif>	<!--- end: add/edit mode or display --->
</cfif>	<!--- end: tag execution mode is start --->

<cfif thisTag.executionMode IS "end">
</cfif>
<cfsetting enablecfoutputonly="No">
