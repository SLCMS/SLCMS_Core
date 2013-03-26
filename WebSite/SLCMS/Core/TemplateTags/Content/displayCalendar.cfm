<!--- SLCMS base tags to be used in template pages  --->
<!---  --->
<!--- custom tag to display a calendar, various modes depending on whether in a blog page or whatever --->
<!--- &copy; mort bay communications --->
<!---  --->
<!--- created:   8th Jan 2007 by Kym K --->
<!--- modified:  8th Jan 2007 - 10th Jan 2007 by Kym K, did initial stuff --->
<!--- modified: 22nd Jan 2007 - 26th Jan 2007 by Kym K, added link options for optionally full links on every date --->

<!--- 
<!--- Ensure this file gets compiled using iso-8859-1 charset --->
<cfprocessingdirective pageencoding="iso-8859-1">
 --->
<cfsetting enablecfoutputonly="Yes">
<cfif thisTag.executionMode IS "start">
	<cfparam name="attributes.Type" type="string" default="Plain">	<!--- type of display plain|blog --->
	<cfparam name="attributes.id" type="string" default="">
	<cfparam name="attributes.highlightDates" default="">	<!--- list of dates to highlight --->
	<cfparam name="attributes.nowDay" default="">	<!--- date as a number to highlight as "today" --->
	<cfparam name="attributes.linkTarget" default="">	<!--- link target attribute for opening in new window --->
	<cfparam name="attributes.links" default="">	<!--- whether to show links no all dates, or partialy --->
	<cfparam name="attributes.showDate" default="#Now()#">
<!--- 
	<cfparam name="attributes.id" type="string" default="">
	<cfparam name="attributes.action" type="string" default="">
 <cfdump var="#attributes#">
 --->
 
	<cfsetting enablecfoutputonly="yes">
	<cfif attributes.links eq "all">
		<cfset AllLinks = True />
	<cfelse>
		<cfset AllLinks = False />
	</cfif>

	<cfset DaySelected = Day(attributes.ShowDate) />
	<cfset showDate = attributes.ShowDate>
	<cfset showDate = dateFormat(showDate,'dd-mmm-yyyy')>
	<cfif len(request.theCategory)>
		<cfset linkUrl = "#cgi.script_name#/#request.theCategory#/<YEAR>/<MONTH>/<DAY>">
	<cfelse>
		<cfset linkUrl = "#cgi.script_name#/<YEAR>/<MONTH>/<DAY>">
	</cfif>
	<cfset firstDayOfWeek = DayOfWeek(CreateDate(Year(showDate),Month(showDate),1))>
	<cfset BeginCalendar = 2 - FirstDayOfWeek>
		<cfset prevUrl = linkUrl>
		<cfset prevUrl = ReplaceNoCase(prevUrl,"&day=<day>","","ALL")>
		<cfset nextUrl = linkUrl>
		<cfset nextUrl = ReplaceNoCase(nextUrl,"&day=<day>","","ALL")>
			<cfset prevUrl = replaceNoCase(prevUrl,"<DAY>",Day(DateAdd('m',-1,showDate)),"ALL")>
			<cfset prevUrl = replaceNoCase(prevUrl,"<MONTH>",month(DateAdd('m',-1,showDate)),"ALL")>
			<cfset prevUrl = replaceNoCase(prevUrl,"<YEAR>",year(DateAdd('m',-1,showDate)),"ALL")>
			<cfset nextUrl = replaceNoCase(nextUrl,"<DAY>",Day(DateAdd('m',1,showDate)),"ALL")>
			<cfset nextUrl = replaceNoCase(nextUrl,"<MONTH>",month(DateAdd('m',1,showDate)),"ALL")>
			<cfset nextUrl = replaceNoCase(nextUrl,"<YEAR>",year(DateAdd('m',1,showDate)),"ALL")>
			<cfif isDefined("fullMonth")>
				<cfset prevUrl = prevUrl & "&fullMonth=1">
				<cfset nextUrl = nextUrl & "&fullMonth=1">
			</cfif>
	<cfoutput>
	<table class="cfmcal">
	<tr class="header">
		<td><a href="#URLSessionFormat(prevUrl)#">&lt;&lt;</a></td>
		<td colspan="5">
		#MonthAsString(Month(showDate))#, #Year(showDate)#
		</td>
		<td><a href="#URLSessionFormat(nextUrl)#">&gt;&gt;</a></td>
	</tr>
	<tr class="weekdays">
	<cfloop from="1" to="7" step="1" index="cnt"><td>#ucase(left(dayOfWeekAsString(cnt),1))#</td></cfloop>
	</tr>
	</cfoutput>
	<cfset cnt1 = 0>
	<cfloop from="#beginCalendar#" to="#daysInMonth(showDate)#" step="1" index="cnt">
		<cfif cnt1 is 0>
			<cfoutput><tr class="week"></cfoutput>
		</cfif>
		<cfif linkUrl neq "">
			<cfset thisDayUrl = replaceNoCase(linkUrl,"<DAY>",cnt,"ALL")>
			<cfset thisDayUrl = replaceNoCase(thisDayUrl,"<MONTH>",month(showDate),"ALL")>
			<cfset thisDayUrl = replaceNoCase(thisDayUrl,"<YEAR>",year(showDate),"ALL")>
			<cfset openHref = "<a href=#chr(34)##URLSessionFormat(thisDayUrl)##chr(34)#">
			<cfif attributes.linkTarget neq "">
				<cfset openHref = openHref & " target=#chr(34)##linkTarget##Chr(34)#">
			</cfif>
			<cfset openHref = openHref & ">">
			<cfset closeHref = "</a>">
		<cfelse>
			<cfset openHref = "">
			<cfset closeHref = "">
		</cfif>
<!--- 		
		<cfset thisHighlight = attributes.highlightDates[cnt] />
 --->		
		<cfif cnt gte 1 and cnt lte 31 and attributes.highlightDates[cnt] neq "">
			<!--- we have a string for this date so we will show it --->
			<cfset isHighlight = True />
		<cfelse>
			<cfset isHighlight = False />
		</cfif>
		<cfif attributes.nowDay eq cnt>
			<cfset isNow = True />
		<cfelse>
			<cfset isNow = False />
		</cfif>
		<cfif cnt lt 1>
			<cfoutput><td class="day_blank">&nbsp;</td></cfoutput>
		<cfelseif DaySelected eq cnt and not isHighlight>
			<cfif AllLinks>
				<cfoutput><td class="day_selected" onClick="window.location.href='#URLSessionFormat(thisDayUrl)#';" title="Selected Date">#openHref##cnt##closeHref#</td></cfoutput>
			<cfelse>
				<cfoutput><td class="day_selected">#cnt#</td></cfoutput>
			</cfif>
		<cfelseif DaySelected eq cnt and isHighlight>
			<cfif AllLinks>
				<cfoutput><td class="day_selected_highlighted" onClick="window.location.href='#URLSessionFormat(thisDayUrl)#';" title="Selected Date - #attributes.highlightDates[cnt]#">#openHref##cnt##closeHref#</td></cfoutput>
			<cfelse>
				<cfoutput><td class="day_selected_highlighted">#cnt#</td></cfoutput>
			</cfif>
		<cfelseif isNow and not isHighlight>
			<cfif AllLinks>
				<cfoutput><td class="day_now" onClick="window.location.href='#URLSessionFormat(thisDayUrl)#';" title="Today">#openHref##cnt##closeHref#</td></cfoutput>
			<cfelse>
				<cfoutput><td class="day_now">#cnt#</td></cfoutput>
			</cfif>
		<cfelseif isHighlight>
			<cfoutput><td class="day_highlighted" onClick="window.location.href='#URLSessionFormat(thisDayUrl)#';" title="#attributes.highlightDates[cnt]#">#openHref##cnt##closeHref#</td></cfoutput>
		<cfelse>
			<cfif AllLinks>
				<cfoutput><td class="day" onClick="window.location.href='#URLSessionFormat(thisDayUrl)#';">#openHref##cnt##closeHref#</td></cfoutput>
			<cfelse>
				<cfoutput><td class="day">#cnt#</td></cfoutput>
			</cfif>
		</cfif>
		<cfif cnt1 gt 5>
			<cfoutput></tr>#Chr(10)#</cfoutput>
			<cfset cnt1 = 0>
		<cfelse>
			<cfset cnt1 = cnt1 + 1>
		</cfif>
	</cfloop>
	<cfif cnt1 lt 7 and cnt1 gt 0>
		<cfloop from="#cnt1#" to="6" step="1" index="cnt2">
			<cfoutput><td class="day_blank"></td></cfoutput>
		</cfloop>
		<cfoutput></tr>#Chr(10)#</cfoutput>
	</cfif>
	<cfoutput></table>
	</cfoutput>

	<cfsetting enablecfoutputonly="no">

 
 
</cfif>

<cfif thisTag.executionMode IS "end">


</cfif>

<cfsetting enablecfoutputonly="No">
