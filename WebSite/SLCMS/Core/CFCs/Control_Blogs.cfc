<!--- SLCMS CFCs  --->
<!--- &copy; 2009 mort bay communications --->
<!---  --->
<!--- a set of blog-related management utilities --->
<!--- Contains:
			not much it seems
			 --->
<!---  --->
<!--- Created:  21st Jan 2007 by Kym K --->
<!--- Modified: 21st Jan 2007 - 28th Jan 2007 by Kym K, mbcomms: working on it --->
<!--- Modified: 20th May 2007 - 20th May 2007 by Kym K, mbcomms: tidying up local declarations in functions, now failing in BD7 --->
<!--- modified:  1st Dec 2008 -  1st Dec 2008 by Kym K, mbcomms: made it silent, all function outputs --->
<!--- modified: 23rd Mar 2009 - 23rd Mar 2009 by Kym K, mbcomms: V2.2, changing structures to new module-allowing architecture, the core code is now just another module --->
<!--- modified: 24th Oct 2009 - 24th Oct 2009 by Kym K, mbcomms: V2.2, adding error handlers as we need them now. missing blogs names, etc --->
<!--- modified: 18th Feb 2011 - 18th Feb 2011 by Kym K, mbcomms: ran varScoper over code and found un-var'd variables! oops :-/  --->
<!--- modified:  7th Jun 2011 - 19th Jun 2011 by Kym K, mbcomms: added logging functions so we can have consistent logging outside CF's logs --->

<cfcomponent displayname="SLCMS Blog Utilities" hint="contains managment utilities for blogs such as Category creation/deletion/etc">
	
	<!--- set up a few persistant things on the way in. --->
	<cfset variables.DefaultBlog = "" />	
	<cfset variables.BlogNames = StructNew() />	
	<cfset variables.Blogs = StructNew() />	
	<cfset variables.Blogs.Today = DateFormat(Now(), "YYYYMMDD") />	
	<!--- make an empty blog to handle sites that don't have blogs --->
	<cfset variables.Blogs["0"] = StructNew() />	<!--- this one has the fine detail below the ID --->
	<cfset variables.Blogs["0"].BlogID = 0 />
	<cfset variables.Blogs["0"].BlogTitle = "" />
	<cfset variables.Blogs["0"].BlogNavName = "" />
	<cfset variables.Blogs["0"].BlogURLName = "" />
	<cfset variables.Blogs["0"].BlogDescription = "" />
	<cfset variables.Blogs["0"].DisplayOrder = "" />
	<cfset variables.Blogs["0"].categories = StructNew() />	
	<cfset variables.Blogs["0"].categories.Category_Struct = StructNew() />	
	<cfset variables.Blogs["0"].categories.Category_Array = ArrayNew(2) />	
	<cfset variables.Blogs["0"].categories.Category_URLlist = "" />	

<!--- initialise the various thingies, this should only be called after an app scope refresh --->
<cffunction name="init" output="No" returntype="struct" access="public" 
	hint="sets up the internal structures for this component"
	>
	<cfargument name="dsn" type="string" required="yes">	<!--- the name of the database that has the relevant tables --->
	<cfargument name="BlogsTable" type="string" default="BlogsTable">	<!--- the name of the Blog Control database table  --->
	<cfargument name="CategoriesTable" type="string" default="Blogs">	<!--- the name of the database table that has the Blog Categories --->
	<cfargument name="ControlTable" type="string" default="BlogControl">	<!--- the name of the Blog Control database table  --->

	<cfset var ret = "" />
	<cfset var thisID = "" />
	<cfset var defaultBlog = "" />
	<cfset var getBlogs = "" />	<!--- internal query that musn't get out --->
	<!--- set up our persistent variables with the db config --->
	<cfset variables.dsn = arguments.dsn />
	<cfset variables.BlogsTable = arguments.BlogsTable />
	<cfset variables.ControlTable = arguments.ControlTable />
	<cfset variables.CategoriesTable = arguments.CategoriesTable />

	<cfset temps = LogIt(LogType="CFC_Init", LogString="Control_Blogs Started") />
	<!--- first lets find out what blogs we have --->	
	<cfquery name="getBlogs" datasource="#variables.dsn#">
		select	*
			from	#variables.BlogsTable#
			where	DO <> 0
			order by DO
	</cfquery>
	<!--- and loop over them and create the categories and everything else below each one --->
	<cfloop query="getBlogs">
		<cfif getBlogs.DO eq 1>	
			<!--- this is the first blog, ie the default one --->
			<cfset defaultBlog = BlogURLname />
		</cfif>
		<cfset thisID = getBlogs.BlogID />
		<cfset variables.BlogNames[getBlogs.BlogURLName] = thisID />	<!--- this one has the name for easy finding of the ID --->
		<cfset variables.Blogs[thisID] = StructNew() />	<!--- this one has the fine detail below the ID --->
		<cfset variables.Blogs[thisID].BlogID = thisID />
		<cfset variables.Blogs[thisID].BlogTitle = getBlogs.BlogTitle />
		<cfset variables.Blogs[thisID].BlogNavName = getBlogs.BlogNavName />
		<cfset variables.Blogs[thisID].BlogURLName = getBlogs.BlogURLname />
		<cfset variables.Blogs[thisID].BlogDescription = getBlogs.BlogDescription />
		<cfset variables.Blogs[thisID].DisplayOrder = getBlogs.DO />
		<cfset variables.Blogs[thisID].categories = StructNew() />	
		<cfset variables.Blogs[thisID].categories.Category_Struct = StructNew() />	
		<cfset variables.Blogs[thisID].categories.Category_Array = ArrayNew(2) />	
		<cfset variables.Blogs[thisID].categories.Category_URLlist = "" />	

		<cfset ret = refreshBlogCategories(BlogID=thisID) />	<!--- load up the Blogs structure with the latest data --->
	</cfloop>
	<!--- and some global stuff --->
	<cfset variables.Blog_URLlist = valueList(getBlogs.BlogURLName) />	
	<cfset variables.Blog_Navlist = valueList(getBlogs.BlogNavName) />	
	<cfset variables.DefaultBlog = defaultBlog />	

	<cfset temps = LogIt(LogType="CFC_Init", LogString="Control_Blogs Finished") />
	<cfreturn variables.Blogs />
</cffunction>

<!--- this function returns all of the blogs' hi-end details --->
<cffunction name="getBlogs" output="No" returntype="struct" access="public" 
	hint="gets all the blogs in various forms"
	>
	
	<cfreturn variables />
</cffunction>

<!--- this function returns a short form of all the blogs normally loaded into session scope for state tracking --->
<cffunction name="getBlogsShort" output="No" returntype="struct" access="public" 
	hint="gets short form of the blogs"
	>

	<cfset var thisBlog = "" />
	<!--- we want to return a structure that has the available blogs and placeholders for the current category and date in each --->
	<cfset var theBlogs = StructNew() />
	<cfset theBlogs.Blog = StructNew()  />	<!--- this will have the details of each blog --->
	<!--- loop over the blogs and set up the structures --->
	<cfloop collection="#variables.BlogNames#" item="thisBlog">
		<cfset theBlogs.Blog[thisBlog] = StructNew()  />
		<cfset theBlogs.Blog[thisBlog].BlogName = thisBlog />
		<cfset theBlogs.Blog[thisBlog].BlogID = variables.BlogNames[thisBlog] />
		<cfset theBlogs.Blog[thisBlog].Category = variables.Blogs[variables.BlogNames[thisBlog]].categories.Category_Array[1][4] />	<!--- grab the first as default, DO earns its keep :-) --->
		<cfset theBlogs.Blog[thisBlog].Date = Now() />	<!--- we are setting up so default to today --->
	</cfloop>
	<cfset theBlogs.CurrentBlogName = "" />	<!--- set a default starting blog --->
	<cfset theBlogs.DefaultBlog = variables.DefaultBlog />	
	
	<cfreturn theBlogs />
</cffunction>

<!--- this function returns the detail of a particular blog itself, but not the entries --->
<cffunction name="getBlogDetail" output="No" returntype="struct" access="public" 
	hint="gets all the blog's top-level details, blog and categories"
	>
	<cfargument name="name" type="string" required="yes">	<!--- the name of the blog that we want --->

	<cfset var theBlogID = variables.BlogNames[arguments.Name] />
	
	<cfreturn variables.Blogs[theBlogID] />
</cffunction>

<!--- this function returns the available Categories in the specified blog --->
<cffunction name="getCategories" output="No" returntype="struct" access="public" 
	hint="gets all the blog categories"
	>
	<cfargument name="BlogID" default="0">
	<cfargument name="BlogName" default="">

	<cfset var theBlogID = 0 />
	<!--- get the id of the blog --->
	<cfif len(arguments.BlogName) and StructKeyExists(variables.BlogNames, "#arguments.BlogName#")>
		<cfset theBlogID = variables.BlogNames[arguments.BlogName] />
	<cfelseif IsNumeric(arguments.BlogID)>
		<cfset theBlogID = arguments.BlogID />
	</cfif>
	<!--- and return the related categories --->
	<cfreturn variables.Blogs[theBlogID].categories />
</cffunction>

<!--- this function returns the details of a specified category --->
<cffunction name="getCategory" output="No" returntype="struct" access="public" 
	hint="gets the details of the specified blog category"
	>
	<cfargument name="name" type="string" default="" hint="name of category">	
	<cfargument name="BlogName" type="string" required="Yes" hint="name of the Blog that the category is in">	
	<cfargument name="ID" type="string" default="" hint="ID of category">	

	<cfset var theBlog = "" />
	<cfset var theCategory = StructNew() />
	<cfset var theCatFindResult = "" />
	<cfset var theCatID = 0 />
	
	<!--- actually we need the blog's name ID --->
	<cfset theBlog = getBlogDetail(name="#arguments.BlogName#")/>	<!--- returns a structure of the blog and its categories --->
	<cfif len(arguments.name)>
		<cfset theCatFindResult = StructFindValue(variables.Blogs[theBlog.BlogID].categories.Category_Struct, arguments.name) />
		<cfif not ArrayIsEmpty(theCatFindResult)>
			<cfset theCatID = theCatFindResult[1].owner.CategoryID />	
		<cfelse>
			<cfset theCatID = 0 />	
		</cfif>
	<cfelse>
		<cfset theCatID = arguments.ID />	
	</cfif>
	<cfif StructKeyExists(variables.Blogs[theBlog.BlogID].categories.Category_Struct, theCatID)>
		<cfset theCategory = variables.Blogs[theBlog.BlogID].categories.Category_Struct[theCatID] />
	<cfelse>
		<!--- just return an empty structure if nothing found
		<cfset theCategory.CategoryID = 0 />
		 --->
	</cfif>
	
	<cfreturn theCategory />
</cffunction>

<!--- this function returns all of the items for a specified category and date --->
<cffunction name="getBlogEntriesRange" output="No" returntype="any" access="public" 
	hint="returns structure of all blog items for this category and the specified date range"
	>
	<cfargument name="BlogName" type="string" default="" hint="name ofblog">	
	<cfargument name="Category" type="string" default="" hint="name of category">	
	<cfargument name="BeginDate" type="string" default="" hint="Start Date of range items to display">	
	<cfargument name="EndDate" type="string" default="" hint="Finish Date of range items to display">	
	
	<cfset var theseBlogEntries = "" />
	<cfset var theEntries = Structnew() />
	<cfset var SpanDays = 0 />
	<cfset var thisDate = "" />
	<cfset var thisDay = 0 />
	
	<!--- we have to allow for a null category or date --->
	<cfif len(arguments.BeginDate) and not len(arguments.EndDate) >
		<cfset arguments.EndDate = arguments.BeginDate />	
	<cfelseif len(arguments.EndDate) and not len(arguments.BeginDate) >
		<cfset arguments.BeginDate = arguments.EndDate />	
	<cfelseif not len(arguments.EndDate) and not len(arguments.BeginDate) >
		<!--- if both are null then make them the currenly selected date --->
		<cfset arguments.BeginDate = request.theDate />	
		<cfset arguments.EndDate = request.theDate />	
	<cfelse>
	</cfif>
<!--- 	
	<cfdump var="#arguments#">
 --->	
	<!--- now we have two good dates to loop over --->
	<!--- we have to do some messy sums to keep a date as well as an easy loop --->
	
	<!--- this does not handle year roll-overs!!!!!!! --->
	
	<cfset SpanDays = DayOfYear(arguments.EndDate)-DayOfYear(arguments.BeginDate)+1 />
	<cfloop index="thisDay" from="1" to="#SpanDays#">
		<cfset thisDate = DateAdd("d", thisDay-1, arguments.BeginDate) />	<!--- now we have the date of this time round in the loop --->
		<!--- get the the items for the specified category and date, return is a struct with a query in it --->
		<cfset theseBlogEntries = application.Core.Control_Blogs.getBlogEntries(BlogName="#arguments.BlogName#", Category="#arguments.Category#", Date="#thisDate#") />
		<cfif theseBlogEntries.RecordCount gt 0>	<!--- we have entries on this day so add them in --->
			<cfset theEntries[thisDay] = theseBlogEntries />
			<cfset theEntries[thisDay].day = thisDay />
			<cfset theEntries[thisDay].date = thisDate />
		</cfif>
	</cfloop>
	
	<cfreturn theEntries />
</cffunction>

<!--- this function returns the single latest item for a specified category --->
<cffunction name="getBlogEntryLatest" output="No" returntype="any" access="public" 
	hint="returns structure of all blog items for this category and the specified date range"
	>
	<cfargument name="BlogName" type="string" default="" hint="name ofblog">	
	<cfargument name="Category" type="string" default="" hint="name of category">	

	<cfset var theEntry = Structnew() />
	<cfset var theEntries = Structnew() />

	<!--- get all of the latest entries --->
	<cfset theEntries = getBlogEntriesLatest(BlogName=arguments.BlogName, Category=arguments.category) />
	<cfif theEntries.RecordCount gte 1>
		<cfset theEntry = duplicate(theEntries) />
		<!--- 
	<cfelseif theEntries.RecordCount gt 1>
		<cfset theEntry = duplicate(theEntries) />
		 --->
	<cfelse>
		<!--- no record count so this category can't have anything in it  --->
		<cfset theEntry.RecordCount = 0 />
	</cfif>	
	
	<cfreturn theEntry />	
</cffunction>

<!--- this function returns all the latest entries for a specified category --->
<cffunction name="getBlogEntriesLatest" output="No" returntype="any" access="public" 
	hint="returns structure of all blog items for this category and the specified date range"
	>
	<cfargument name="BlogName" type="string" default="" hint="name ofblog">	
	<cfargument name="Category" type="string" default="" hint="name of category">	
	
	<cfset var getLatest = "" />
	<cfset var theEntries = Structnew() />
	<cfset var thisCategory = "" />
	<cfset var thisCatID = 0 />
	
	<cfset thisCategory = getCategory(blogname="#arguments.BlogName#", name="#arguments.Category#") />
	<cfif not StructIsEmpty(thisCategory)>
		<cfset thisCatID = thisCategory.CategoryID />
	</cfif>
<!--- 	
	<cfdump var="#thisCatID#"><cfabort>
 --->	
	<!--- discover the latest day that has an entry --->
	<cfquery name="getLatest" datasource="#variables.dsn#">
		select	Max(EntryDate) as LatestDate
			from	#variables.ControlTable#
			where	BlogID = <cfqueryparam value="#variables.BlogNames[arguments.BlogName]#" cfsqltype="CF_SQL_INTEGER">
				and	BlogCategoryID = <cfqueryparam value="#thisCatID#" cfsqltype="CF_SQL_INTEGER">
				and	Version = 0
	</cfquery>

	<cfset theEntries = application.Core.Control_Blogs.getBlogEntries(BlogName="#arguments.BlogName#", Category="#arguments.Category#", Date="#getLatest.LatestDate#") />
	
	<cfreturn theEntries />
</cffunction>

<!--- this function returns the single specific item for the specified category --->
<cffunction name="getBlogEntryIDSpecific" output="No" returntype="any" access="public" 
	hint="returns structure of the specified blog item for this blog/category"
	>
	<cfargument name="BlogName" type="string" default="" hint="name of blog">	
	<cfargument name="Category" type="string" default="" hint="name of category">	
	<cfargument name="EntryURLName" type="string" default="" hint="URL name of the entry to get">	

	<cfset var getEntry = "" />	<!--- internal query, not to escape --->
	<cfset var theItems = Structnew() />
	<cfset var theEntry = Structnew() />

	<!--- work out what we want to select --->
	<cfset theItems = getCategory(blogname="#arguments.BlogName#", name="#arguments.Category#") />
	<cfif StructIsEmpty(theItems)>
		<cfset theItems.CategoryID = 0 />
	</cfif>
	<!--- get the entryID --->
	<cfquery name="getEntry" datasource="#variables.DSN#">
		select	*
			from	#variables.ControlTable#
			where	blogId					= <cfqueryparam value="#variables.BlogNames[arguments.BlogName]#" cfsqltype="CF_SQL_INTEGER">
				and	blogCategoryID	=	<cfqueryparam value="#theItems.CategoryID#" cfsqltype="CF_SQL_INTEGER">
				and	blogURL					=	<cfqueryparam value="#arguments.EntryURLName#" cfsqltype="CF_SQL_VARCHAR">
				and	version 				= <cfqueryparam value="0" cfsqltype="CF_SQL_INTEGER">
			order by	VersionTimeStamp desc
	</cfquery>
	<cfset theEntry.RecordCount = getEntry.RecordCount />
	<cfset theEntry.query = duplicate(getEntry) />
	
	<cfreturn theEntry />	
</cffunction>

<!--- this function returns all of the items for a specified category and date --->
<cffunction name="getBlogEntries" output="No" returntype="any" access="public" 
	hint="returns structure of all blog items for this category and date"
	>
	<cfargument name="BlogName" type="string" default="" hint="name of blog">	
	<cfargument name="Category" type="string" default="" hint="name of category">	
	<cfargument name="Date" type="string" default="" hint="date of items to display">	

	<!--- we have to allow for a null category or date --->
	<cfset var theItems = Structnew() />
	<cfset var theBlogID = variables.BlogNames[arguments.BlogName] />
	<cfset var thisCategory = "" />
	<cfset var WhereString = "BlogID = #theBlogID#" />
	<cfset var getEntries = "" />
	
	<!--- work out what we want to select --->
	<cfif len(arguments.Category)>
		<cfif arguments.Category neq "any">
			<!--- if we don't want to sleect fomr any category in this blog then we have to work out what --->
			<cfset thisCategory = getCategory(blogname="#arguments.BlogName#", name="#arguments.Category#") />
			<cfif StructIsEmpty(thisCategory)>
				<cfset theItems.CategoryID = 0 />
			</cfif>
			<cfset WhereString = WhereString& " and BlogCategoryID = #thisCategory.CategoryID#" />
		<cfelse>
			<cfset theItems.CategoryID = "" />
		</cfif>
	<cfelse>
		<cfset theItems.CategoryID = "" />
	</cfif>
	<cfif len(arguments.Date)>
		<cfset WhereString = WhereString& " and EntryDate = #createODBCDate(arguments.Date)#" />
	</cfif>
<!--- 	
	<cfoutput>WhereString: #WhereString#<br></cfoutput>
 --->	
	<cfquery name="getEntries" datasource="#variables.DSN#">
		select	*
			from	#variables.ControlTable#
			where	#PreserveSingleQuotes(WhereString)#
				and	version = 0
			order by	VersionTimeStamp desc
	</cfquery>
<!--- 	
	<cfdump var="#getEntries#">
 --->	
	<cfset theItems.RecordCount = getEntries.RecordCount />
	<cfset theItems.query = duplicate(getEntries) />
	
	<cfreturn theItems />
</cffunction>

<!--- this function updates a Blog entry's Title/summary/url fields field --->
<cffunction name="saveEntrySummary_Title" output="No" returntype="void" access="public"
	hint="updates the summary and Title details in the DB"
	>
	<cfargument name="summary" type="string" default="" hint="the Summary text for update">	
	<cfargument name="Title" type="string" default="" hint="the Title text for update">	
	<cfargument name="ContentControlData" type="struct" required="yes" hint="structure defining the entry to update">	
	<!--- update the summary field --->
	
	<cfset var setSummary = "" />
	<cfset var theBlogURL = left(replaceNoCase(arguments.Title, " ", "_", "all"), 128) /> --->

	<!--- set the next id in the DB --->
	<cfquery name="setSummary" datasource="#variables.dsn#">
		Update	#variables.ControlTable#
			set		Summary 	= <cfqueryparam value="#arguments.summary#" cfsqltype="CF_SQL_VARCHAR">,
						Title		 	= <cfqueryparam value="#arguments.Title#" cfsqltype="CF_SQL_VARCHAR">,
						BlogURL		 	= <cfqueryparam value="#theBlogURL#" cfsqltype="CF_SQL_VARCHAR">
			where	ContentID = <cfqueryparam value="#ContentControlData.ContentID#" cfsqltype="CF_SQL_INTEGER">
	</cfquery>
	
</cffunction>

<!--- this function grabs the current Blog categories from the DB --->
<cffunction name="refreshBlogCategories" output="No" returntype="void" access="public" 
	hint="internal use, refreshes the Blog Categories structure from the DB"
	>
	<cfargument name="BlogID" default="0">

	<cfset var thisID = arguments.BlogID />
	<cfset var thisCatID = 0 />
	<cfset var getBlogCategories = "" />
	
	<cfquery name="getBlogCategories" datasource="#variables.dsn#">
		select	*
			from	#variables.CategoriesTable#
			where	BlogID = #thisID#	
				and	version = 0
				and	DO <> 0
			order by DO
	</cfquery>
	<cfloop query="getBlogCategories">
		<cfset thisCatID = getBlogCategories.BlogCategoryID />
		<cfset variables.Blogs[thisID].categories.Category_Struct[thisCatID] = StructNew() />	
		<cfset variables.Blogs[thisID].categories.Category_Struct[thisCatID].CategoryID = thisCatID />	
		<cfset variables.Blogs[thisID].categories.Category_Struct[thisCatID].CategoryTitle = getBlogCategories.BlogCategoryTitle />	
		<cfset variables.Blogs[thisID].categories.Category_Struct[thisCatID].CategoryNavName = getBlogCategories.BlogCategoryNavName />	
		<cfset variables.Blogs[thisID].categories.Category_Struct[thisCatID].CategoryURLName = getBlogCategories.BlogCategoryURLName />	
		<cfset variables.Blogs[thisID].categories.Category_Struct[thisCatID].CategoryDescription = getBlogCategories.BlogCategoryDescription />	
		<cfset variables.Blogs[thisID].categories.Category_Array[getBlogCategories.CurrentRow][1] = thisCatID />	
		<cfset variables.Blogs[thisID].categories.Category_Array[getBlogCategories.CurrentRow][2] = getBlogCategories.BlogCategoryTitle />	
		<cfset variables.Blogs[thisID].categories.Category_Array[getBlogCategories.CurrentRow][3] = getBlogCategories.BlogCategoryNavName />	
		<cfset variables.Blogs[thisID].categories.Category_Array[getBlogCategories.CurrentRow][4] = getBlogCategories.BlogCategoryURLName />	
		<cfset variables.Blogs[thisID].categories.Category_Array[getBlogCategories.CurrentRow][5] = getBlogCategories.BlogCategoryDescription />	
		<cfset variables.Blogs[thisID].categories.Category_URLlist = valueList(getBlogCategories.BlogCategoryURLName) />	
	</cfloop>
</cffunction>

<cffunction name="getVariablesScope"output="No" returntype="struct" access="public"  
	displayname="get Variables"
	hint="gets the specified variables structure or the entire variables scope"
	>
	<cfargument name="Struct" type="string" required="No" default="" hint="struct to return, defaults to 'all'">	
	<cfif len(arguments.Struct) and StructKeyExists(variables, "#arguments.Struct#")>
		<cfreturn variables["#arguments.Struct#"] />
	<cfelse>
		<cfreturn variables />
	</cfif>
</cffunction>

<cffunction name="LogIt" output="No" returntype="struct" access="private"
	displayname="Log It"
	hint="Local Function in every CFC to log info to standard log space via SLCMS_Utility.WriteLog_Core(), minimizes log code in individual functions"
	>
	<cfargument name="LogType" type="string" default="" hint="The log to write to" />
	<cfargument name="LogString" type="string" default="" hint="The string to write to the log" />

	<cfset var theLogType = trim(arguments.LogType) />
	<cfset var theLogString = trim(arguments.LogString) />
	<cfset var temps = StructNew() />	<!--- temp/throwaway structure --->
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorText = "" />
	<cfset ret.error.ErrorContext = "Control_Blogs CFC: LogIt()" />
	<cfset ret.error.ErrorExtra = "" />
	<cfset ret.Data = "" />	<!--- no data --->

		<!--- validation --->
	<cfif theLogType neq "">
		<cftry>
			<cfset temps = application.core.SLCMS_Utility.WriteLog_Core(LogType="#theLogType#", LogString="#theLogString#") />
			<cfif temps.error.errorcode neq 0>
				<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 2) />
				<cfset ret.error.ErrorText = ret.error.ErrorText & "Log Write Failed. Error was: #temps.error.ErrorText#<br>" />
			</cfif>
		<cfcatch type="any">
			<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 128) />
			<cfset ret.error.ErrorText = ret.error.ErrorContext & ' Trapped. Site: #application.config.base.SiteName#, error message was: #cfcatch.message#, error detail was: #cfcatch.detail#' />
			<cfset ret.error.ErrorExtra =  cfcatch.TagContext />
			<cfif isArray(ret.error.ErrorExtra) and StructKeyExists(ret.error.ErrorExtra[1], "Raw_Trace")>
				<cfset ret.error.ErrorText = ret.error.ErrorText & ", Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#" />
			</cfif>
			<cflog text='#ret.error.ErrorText# - ret.error.ErrorCode: #ret.error.ErrorCode# - Time: #DateFormat(Now(),"YYYYMMDD")#-#TimeFormat(now(),"HH:mm:ss")#'  file="#Application.Logging.theSiteLogName#" type="Error" application = "yes">
			<cfif application.config.debug.debugmode>
				<cfoutput>#ret.error.ErrorContext#</cfoutput> Trapped - error dump:<br>
				<cfdump var="#cfcatch#">
			</cfif>
		</cfcatch>
		</cftry>
	<cfelse>	<!--- this is the error code --->
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 1) />
		<cfset ret.error.ErrorText = ret.error.ErrorText & "Oops! Unknown Log<br>" />
	</cfif>

	<cfreturn ret  />
</cffunction>

<cffunction name="TakeErrorCatch" output="Yes" returntype="any" access="private" 
	displayname="Take Error Catch"
	hint="Takes Error Trap in function and logs/displays it, etc"
	>
	<cfargument name="RetErrorStruct" type="struct" required="true" hint="the ret structure from the calling function" />	
	<cfargument name="CatchStruct" type="any" required="true" hint="the catch structure from the calling function" />	
	
	<!--- some temp vars --->
	<cfset var temps = "" />
	<cfset var error = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result it is just the error part of the standard ret struct --->
	<cfset error = StructNew() />
	<cfset error.ErrorCode = 0 />
	<cfset error.ErrorText = "" />
	<cfset error.ErrorContext = "" />
	<cfset error.ErrorExtra = "" />
	<cftry>
		<!--- build the standard return structure using whatever may have been fed in --->
		<cfset ret.error = StructNew() />
		<cfif StructKeyExists(arguments.RetErrorStruct, "ErrorCode")>
			<cfset error.ErrorCode = BitOr(error.ErrorCode, arguments.RetErrorStruct.ErrorCode) />
		</cfif>
		<cfif StructKeyExists(arguments.RetErrorStruct, "ErrorContext")>
			<cfset error.ErrorContext = arguments.RetErrorStruct.ErrorContext />
		</cfif>
		<cfif StructKeyExists(arguments.RetErrorStruct, "ErrorText")>
			<cfset error.ErrorText = arguments.RetErrorStruct.ErrorText />
		</cfif>
		<cfif StructKeyExists(arguments.CatchStruct, "TagContext")>
			<cfset error.ErrorExtra = arguments.CatchStruct.TagContext />
		<cfelse>
			<cfif StructKeyExists(arguments.RetErrorStruct, "ErrorExtra")>
				<cfset error.ErrorExtra = arguments.RetErrorStruct.ErrorExtra />
			</cfif>
		</cfif>
		<cfset error.ErrorText = error.ErrorConText & error.ErrorText & ' Trapped. Site: #application.config.base.SiteName#, error message was: #arguments.CatchStruct.message#, error detail was: #arguments.CatchStruct.detail#' />
		<cfif isArray(error.ErrorExtra) and StructKeyExists(error.ErrorExtra[1], "Raw_Trace")>
			<cfset error.ErrorText = error.ErrorText & " Line: #ListLast(arguments.CatchStruct.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#" />
		</cfif>
		<cfset temps = LogIt(LogType="CFC_ErrorCatch", LogString='#error.ErrorText# - ErrorCode: #error.ErrorCode#') />
	<cfcatch type="any">
		<cfset error.ErrorCode =  BitOr(error.ErrorCode, 255) />
		<cfset error.ErrorText = error.ErrorContext & ' Trapped. Site: #application.config.base.SiteName#, error message was: #cfcatch.message#, error detail was: #cfcatch.detail#' />
		<cfset error.ErrorText = error.ErrorText & ' caller error message was: #arguments.CatchStruct.message#, error detail was: #arguments.CatchStruct.detail#' />
		<cfset error.ErrorExtra =  arguments.CatchStruct.TagContext />
		<cfif isArray(error.ErrorExtra) and StructKeyExists(error.ErrorExtra[1], "Raw_Trace")>
			<cfset error.ErrorText = error.ErrorText & ", Line: #ListLast(arguments.CatchStruct.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#" />
		</cfif>
		<cflog text='TakeErrorCatch: Error Catch Caught: #error.ErrorText# - error.ErrorCode: #error.ErrorCode# - Time: #DateFormat(Now(),"YYYYMMDD")#-#TimeFormat(now(),"HH:mm:ss")#'  file="#Application.Logging.theSiteLogName#" type="Error" application = "yes">
		<cfif application.config.debug.debugmode>
			<cfoutput>#error.ErrorContext#</cfoutput> Trapped - error dump:<br>
			<cfdump var="#arguments.CatchStruct#">
		</cfif>
	</cfcatch>
	</cftry>	
	<cfreturn error  />
</cffunction>

</cfcomponent>