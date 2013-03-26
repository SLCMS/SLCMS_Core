<!--- SLCMS base tags to be used in template pages  --->
<!--- &copy; mort bay communications --->
<!---  --->
<!--- custom tag to display a Blog categories --->
<!---  --->
<!---  --->
<!--- Created:  13th Jan 2007 by Kym K --->
<!--- Modified: 21st Jan 2007 - 25th Jan 2007 by Kym K, working in it --->
<!--- modified: 23rd Mar 2009 - 23rd Mar 2009 by Kym K - mbcomms: V2.2, changing structures to new module-allowing architecture, the core code is now just another module --->

<!--- 
 --->
<cfsetting enablecfoutputonly="Yes">
<cfif thisTag.executionMode IS "start">
	<cfparam name="attributes.Include" type="string" default="">
	<!--- get the available categories --->
	<cfset theCats = application.Core.Control_Blogs.getCategories(BlogName="#request.theBlog#") />
	<!--- and display them --->
	<cfoutput>
	<div class="BlogCategories">
	<ul>
	<cfloop index="thisCat" from="1" to="#ArrayLen(theCats.Category_Array)#">
		<cfif theCats.Category_Array[thisCat][3] eq request.theCategory>
			<cfset theTitle = "The Selected Category" />
		<cfelse>	
			<cfset theTitle = "Change to this Category, #theCats.Category_Array[thisCat][2]#" />
		</cfif>
		<li><a href="#cgi.script_name#/#theCats.Category_Array[thisCat][3]#" title="#theTitle#">#theCats.Category_Array[thisCat][2]#</a></li>
	</cfloop>
	<cfif len(request.thecategory)>	<!--- if we are in a specific category then offer an opt out --->
		<li><a href="#cgi.script_name#/ShowAllCats">Show All Categories</a></li>
	</cfif>
	</ul>
	<cfif 1 eq 0 and application.core.UserPermissions.IsLoggedin() and session.user.IsSuper>
	Add Category
	</cfif>
	</div>
	</cfoutput>
</cfif>

<cfif thisTag.executionMode IS "end">
</cfif>
<cfsetting enablecfoutputonly="No">
