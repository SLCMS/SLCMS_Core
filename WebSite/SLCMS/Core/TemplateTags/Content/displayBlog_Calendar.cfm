<!--- SLCMS base tags to be used in template pages  --->
<!--- &copy; mort bay communications --->
<!---  --->
<!--- custom tag to display a calendar approrpriately for the Blogs --->
<!---  --->
<!---  --->
<!--- Created:  10th Jan 2007 by Kym K --->
<!--- Modified: 24th Jan 2007 - 24th Jan 2007 by Kym K, working in it --->
<!--- modified: 23rd Mar 2009 - 23rd Mar 2009 by Kym K - mbcomms: V2.2, changing structures to new module-allowing architecture, the core code is now just another module --->

<!--- 
 --->
<cfsetting enablecfoutputonly="Yes">
<cfif thisTag.executionMode IS "start">
	<cfparam name="attributes.Include" type="string" default="">

	<!--- get the dates in this month that have content --->
	<cfset DateList = "" />	<!--- this will be the list of days for this month --->
	<!--- get the the items for the specified category and month, return is a struct with a query in it --->
	<cfset DateStart = Createdate(year(request.theDate), month(request.theDate), 1) />
	<cfset DateFinish = Createdate(year(request.theDate), month(request.theDate), DaysInMonth(request.theDate)) />
	<cfset theBlogEntries = application.Core.Control_Blogs.getBlogEntriesRange(BlogName="#request.theBlog#", Category="#request.theCategory#", BeginDate="#DateStart#", EndDate="#DateFinish#") />
<!--- 
<cfdump var="#theBlogEntries#">
 --->
	<!--- make an array as long as a month and fill it it with nulls
				then we will put the number of entries in for everyday that has one
				and matching text for the generic calendar tag to use --->
	<cfset HighLightDays = ArrayNew(1) />
	<cfset ret = ArraySet(HighLightDays, 1, 31, "") />
	<cfif request.theCategory eq "">
		<cfset theTextTail = " over all Categories"/>
	<cfelse>
		<cfset theTextTail = " in #request.theCategory#" />
	</cfif>
	<cfloop collection="#theBlogEntries#" item="thisBlog">
		<cfif theBlogEntries[thisBlog].RecordCount eq 1>
			<cfset HighLightDays[theBlogEntries[thisBlog].day] = "1 Entry#theTextTail#" />
		<cfelseif theBlogEntries[thisBlog].RecordCount gt 1>
			<cfset HighLightDays[theBlogEntries[thisBlog].day] = "#theBlogEntries[thisBlog].RecordCount# Entries#theTextTail#" />
		</cfif>
	</cfloop>

 	<cfif request.theDate eq "">
		<!--- we have not got a date yet so default to today
		<cfset theShowDate = Now() /> --->
		<cfset theShowDate = 0 />
	<cfelse>
		<cfset theShowDate = request.theDate />
	</cfif>
	<!--- now see if today is within the span we are showing --->
	<cfif (DateCompare(Now(), DateStart) eq 1 and DateCompare(DateFinish, Now()) eq 1) or DateCompare(DateStart, Now()) eq 0 or DateCompare(DateFinish, Now()) eq 0 >
		<cfset thisDay = Day(Now()) />
	<cfelse>
		<cfset thisDay = 0 />
	</cfif>
	
	<cf_displayCalendar highlightDates="#HighLightDays#" nowDay="#thisDay#" showDate="#theShowDate#" links="all">
	
</cfif>

<cfif thisTag.executionMode IS "end">
</cfif>
<cfsetting enablecfoutputonly="No">
