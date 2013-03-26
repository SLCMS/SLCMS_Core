<cfsilent>
<!--- SLCMS base tags to be used in template pages  --->
<!--- &copy; mort bay communications --->
<!---  --->
<!--- custom tag include to set the category and date from SEF URL variables --->
<!--- --->
<!--- created:  22nd Jan 2007 by Kym K --->
<!--- modified: 22nd Jan 2007 - 28th Jan 2007 by Kym K, did initial stuff --->
<!--- modified: 23rd Mar 2009 - 23rd Mar 2009 by Kym K - mbcomms: V2.2, changing structures to new module-allowing architecture, the core code is now just another module --->
<!--- modified: 29th Apr 2009 - 29th Apr 2009 by Kym K - mbcomms: V2.2, changing database table structure to portal/sub-site architecture, sites inside site --->

<!--- a very few defaults --->
<cfset theEntryName = "" />

<!--- firstly see if we have a page that is defined as a blog page --->
<cfset thisPage = cgi.script_name />
<cfif left(thisPage, 1) eq "/">
	<cfset thisPage = removechars(thisPage, 1, 1) />
</cfif>
<cfset matchPos = ListFindNocase(application.config.blogs.blogPageNames, thisPage) />
<cfif matchPos gt 0>
	<!--- yes we do so find out which.... --->
	<cfset PageBlogName = ListgetAt(application.config.blogs.blogNames, matchPos) />
	<!--- next see if it is different to the exiting session, ie have we changed pages? --->
	<cfif PageBlogName neq session.Sites.Site_0.Blogs.CurrentBlogName>
		<!--- it has changed so change our current session vars to this page's stored ones --->
		<cfset session.Sites.Site_0.Blogs.CurrentBlogName = PageBlogName />	<!--- this will always exist and be "main" from a restart or fresh user --->
		<!--- i thought there was going to be stuff to do here so this cfif block is wasted... --->
	</cfif>
</cfif> <!--- end we have match of page name with a config blog page --->

<!--- now we see if the page SEF path is null if so then use the above and session info, 
			otherwise work out what we want to see --->
<!--- we first do a wrinkle to compensate for the behavious of IIS compared with Apache --->
<cfset theScriptLen = len(cgi.script_name) />
<cfif left(cgi.path_info, theScriptLen) eq cgi.script_name>
	<!--- the left part of the path info is the page's name so we have to strip it out, this is IIS  --->
	<cfset theParams = removeChars(cgi.path_info, 1, theScriptLen) />
<cfelse>	
	<cfset theParams = cgi.path_info />
</cfif>
<!--- see if we have anything left to work with --->
<cfif len(theParams)>
	<cfif left(theParams, 1) eq "/">
		<cfset theParams = removeChars(theParams, 1, 1) />
	</cfif>
	<!--- we have stuff in the path that could be a blog SEO path so parse it out and allow for junk entries --->
	<!--- blogname first, should be the first item --->
	<cfset theBlogList = application.Core.Control_Blogs.getBlogs().Blog_URLlist />	<!--- get the list of categories --->
	<cfset thePossibleBlog = ListFirst(theParams, "/") /> <!--- get the first path item, could be a blogname --->
	<cfif ListFindNoCase(theBlogList, thePossibleBlog, ",") ><!--- see if the first path item is a matching blog --->
		<cfset theBlog = thePossibleBlog />	<!--- we got a match so this is our blog --->
		<cfset session.Sites.Site_0.Blogs.CurrentBlogName = theBlog />	<!--- save the new blog for posterity --->
		<cfset theParams = ListDeleteAt(theParams, 1, "/") />	<!--- dump the first item as we had a match --->
		<cfset flagFoundtheBlog = True />	<!--- flag that we got a match so the first item was a blogname --->
	<cfelseif StructKeyExists(session.Sites, "Site_#request.pageParams.subSiteID#")>
		<cfset theBlog = session.Sites["Site_#request.pageParams.subSiteID#"].Blogs.CurrentBlogName />	<!--- we didn't match but there was stuff there so stay as we were --->
<!--- 
		<cfset theBlog = session.Sites.Site_0.Blogs.CurrentBlogName />	<!--- we didn't match but there was stuff there so stay as we were --->
 --->
		<cfset flagFoundtheBlog = False />
	<cfelse>
		<cfset theBlog = 0 />	<!--- nothing at all --->
		<cfset flagFoundtheBlog = False />
	</cfif>
	<!--- category next, could be the second item but could be missing or could be first if blog was missing --->
	<cfset theCatList = application.Core.Control_Blogs.getCategories(BlogName="#theBlog#").Category_URLlist />	<!--- get the list of categories --->
	<cfif flagFoundtheBlog>
		<cfset thePossibleCat1 = ListFirst(theParams, "/") /> <!--- get the first path item as the first was a blog name and got removed so list is shorter --->
		<cfset thePossibleCat2 = "" /> <!--- no second path item in this context as we have sucked out the blogname and only one text item should be left --->
	<cfelse>
		<cfset thePossibleCat1 = ListFirst(theParams, "/") /> <!--- get the first path item, could be a category --->
		<cfif ListLen(theParams, "/") gte 2>
			<cfset thePossibleCat2 = ListGetAt(theParams, 2, "/") /> <!--- get the second path item as the first could have been a blog name that didn't match --->
		<cfelse>
			<cfset thePossibleCat2 = "" /> <!--- no second path item --->
		</cfif>
	</cfif>
	<cfif thePossibleCat1 eq  "ShowAllCats"><!--- see if we want to drop single category and go to all categories --->
		<cfset theCategory = "" />	<!--- we got a match so this is our category --->
		<cfset theParams = ListDeleteAt(theParams, 1, "/") />	<!--- dump the first item as we had a match as a category --->
	<cfelseif thePossibleCat2 eq  "ShowAllCats"><!--- see if we want to drop single category and go to all categories --->
		<cfset theCategory = "" />	<!--- we got a match so this is our category --->
		<cfset theParams = ListDeleteAt(theParams, 2, "/") />	<!--- dump the second item as we had a match as a category --->
	<cfelseif ListFindNoCase(theCatList, thePossibleCat1, ",") ><!--- see if the first path item is a matching category --->
		<cfset theCategory = thePossibleCat1 />	<!--- we got a match so this is our category --->
		<cfset theParams = ListDeleteAt(theParams, 1, "/") />	<!--- dump the first item as we had a match as a category --->
	<cfelseif ListFindNoCase(theCatList, thePossibleCat2, ",") ><!--- see if the second path item is a matching category --->
		<cfset theCategory = thePossibleCat2 />	<!--- we got a match so this is our category --->
		<cfset theParams = ListDeleteAt(theParams, 2, "/") />	<!--- dump the second item as we had a match as a category --->
	<cfelse>
		<cfset theCategory = session.Sites.Site_0.Blogs.blog[session.Sites.Site_0.Blogs.CurrentBlogName].category />	<!--- we didn't match but there was stuff there so stay as we were --->
	</cfif>
	<!--- then the dates, should be either year/month/day or year/month/day/blogentryname
				as any correct blogname or category name has been removed
				so the first thing we need to do is sort that lot out --->
	<cfif ListLen(theParams, "/") gt 3>
		<cfset theEntryName = ListLast(theParams, "/") />
		<cfset theParams = ListDeleteAt(theParams, ListLen(theParams, "/"), "/") />	<!--- dump the last item as we we have grabbed it as the entry name --->
	<cfelseif ListLen(theParams, "/") eq 3>
		<!--- its just the date set or broken so set up for that --->
	<cfelse>
		<!--- the only correct option is just an entry name --->
		<cfset theYearPos = 0 />
		<cfset theEntryName = ListLast(theParams, "/") />
	</cfif>
				
	<cfif ListLen(theParams, "/") eq 5>
		<cfset theYearPos = 3 />
		<cfset theMonthPos = 4 />
		<cfset theDayPos = 5 />
	<cfelseif ListLen(theParams, "/") eq 4>
		<cfset theYearPos = 2 />
		<cfset theMonthPos = 3 />
		<cfset theDayPos = 4 />
	<cfelseif ListLen(theParams, "/") eq 3>
		<cfset theYearPos = 1 />
		<cfset theMonthPos = 2 />
		<cfset theDayPos = 3 />
	<cfelse>	<!--- missing date or crook format so go with existing --->
		<cfset theYearPos = 0 />
	</cfif>
	<cfif theYearPos gt 0>
		<!--- we have what could be a valid date set so load them up --->
		<cfset theYear = ListgetAt(theParams, theYearPos, "/") />
		<cfset theMonth = ListgetAt(theParams, theMonthPos, "/") />
		<cfset theDay = ListgetAt(theParams, theDayPos, "/") />
	<cfelse>	<!--- missing date or crook format so go with existing --->
		<cfset theYear = Year(session.Sites.Site_0.Blogs.blog[session.Sites.Site_0.Blogs.CurrentBlogName].date) />
		<cfset theMonth = Month(session.Sites.Site_0.Blogs.blog[session.Sites.Site_0.Blogs.CurrentBlogName].date) />
		<cfset theDay = Day(session.Sites.Site_0.Blogs.blog[session.Sites.Site_0.Blogs.CurrentBlogName].date) />
	</cfif>
	<cfif not (IsNumeric(theYear) and IsNumeric(theMonth) and IsNumeric(theDay))>
		<!--- not all numbers so go with existing --->
		<cfset theYear = Year(session.Sites.Site_0.Blogs.blog[session.Sites.Site_0.Blogs.CurrentBlogName].date) />
		<cfset theMonth = Month(session.Sites.Site_0.Blogs.blog[session.Sites.Site_0.Blogs.CurrentBlogName].date) />
		<cfset theDay = Day(session.Sites.Site_0.Blogs.blog[session.Sites.Site_0.Blogs.CurrentBlogName].date) />
	</cfif>
	<cfset theDate = CreateDate(theYear, theMonth, theDay) />
	<cfset session.Sites.Site_0.Blogs.blog[session.Sites.Site_0.Blogs.CurrentBlogName].category = theCategory />
	<cfset session.Sites.Site_0.Blogs.blog[session.Sites.Site_0.Blogs.CurrentBlogName].Date = theDate />
<cfelse>
	<!--- there is no path info so take the stored session vars --->
	<cfset theBlog = session.Sites.Site_0.Blogs.CurrentBlogName />	<!--- this will always exist and be "main" from a restart or fresh user --->
	<cfif StructKeyExists(session.Sites.Site_0.Blogs.blog, session.Sites.Site_0.Blogs.CurrentBlogName)>
		<cfset theCategory = session.Sites.Site_0.Blogs.blog[session.Sites.Site_0.Blogs.CurrentBlogName].category />	<!--- this will always exist and be null from a restart or fresh user --->
		<cfset theDate = session.Sites.Site_0.Blogs.blog[session.Sites.Site_0.Blogs.CurrentBlogName].Date />	<!--- this will always exist and be today from a restart or fresh user --->
	<cfelse>
		<cfset theCategory = "" />
		<cfset theDate = "" />
	</cfif>
</cfif>	<!--- end: do we have cgi.path_info? --->
<cfif theDate eq "">	<!--- we have not got a date yet so default to today --->
	<cfset theDate = Now() />
</cfif>

<!--- we have moved this to the app scope as otherwise it has to be everywhere 
			so put the vars in the request scope --->
<cfset request.theBlog = theBlog />
<cfset request.theCategory = theCategory />
<cfset request.theDate = theDate />
<cfset request.theEntryName = theEntryName />

</cfsilent>

