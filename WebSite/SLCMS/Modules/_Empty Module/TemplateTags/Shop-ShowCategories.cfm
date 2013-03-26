<!--- SLCMS base tags to be used in template pages  --->
<!--- SLShop part of SLCMS &copy; mort bay communications --->
<!---  --->
<!--- custom tag to display a list of shop categories --->
<!---  --->
<!---  --->
<!--- Created:   1st Apr 2008 by Kym K --->
<!--- Modified:  1st Apr 2008 - 25th Apr 2008 by Kym K, initial work on it --->

<!--- 
 --->
<cfsetting enablecfoutputonly="Yes">
<cfif thisTag.executionMode IS "start">
	<cfparam name="attributes.ParentObject" type="string" default="">
	<cfparam name="attributes.ParentObjectID" type="string" default="">
	<cfparam name="attributes.Style" type="string" default="">
	<cfparam name="attributes.LinkPath" type="string" default="/content.cfm#request.PageParams.PagePathEncoded#">
	<cfparam name="attributes.LinkClass" type="string" default="">
	<cfparam name="attributes.ULclass" type="string" default="">
	<cfparam name="attributes.LIclass" type="string" default="">

	<cftry>
		<!--- make a tidy place to work --->
		<cfset session.shop.temp.Showcat = StructNew() />
		<!--- deduce what data we have to get our categories from --->
		<cfif len(attributes.ParentObjectID) and IsNumeric(attributes.ParentObjectID)>
			<cfset session.shop.temp.Showcat.ParentObjectID = attributes.ParentObjectID />
			<cfset session.shop.temp.Showcat.ParentObject = "" />
		<cfelseif len(attributes.ParentObject) and IsSimplevalue(attributes.ParentObject)>
			<cfset session.shop.temp.Showcat.ParentObject = attributes.ParentObject />
			<cfset session.shop.temp.Showcat.ParentObjectID = "" />
		<cfelse>
			<cfset session.shop.temp.Showcat.ParentObjectID = session.shop.currentObjectID />
			<cfset session.shop.temp.Showcat.ParentObject = "" />
		</cfif>
		<!--- and get them --->
		<cfif session.shop.temp.Showcat.ParentObject eq "">
			<cfset session.shop.temp.getObjects = application.SLShop.getChildObjects(ParentObjectID="#session.shop.temp.Showcat.ParentObjectID#") />	<!--- returns a struct with query within --->
		<cfelse>
			<cfset session.shop.temp.getObjects = application.SLShop.getChildObjects(ParentObject="#session.shop.temp.Showcat.ParentObject#") />	<!--- returns a struct with query within --->
		</cfif>
		
		<cfif session.shop.temp.getObjects.error.errorcode eq 0>
	
			<!--- output details according to specified styling --->
			<cfif len(attributes.LinkClass)>
				<cfset theLinkClass = ' class="#attributes.LinkClass#"'>
			<cfelse>
				<cfset theLinkClass = "">
			</cfif>
			<cfif attributes.Style eq "UnorderedList">
				<cfif len(attributes.ULclass)>
					<cfset theULclass = ' class="#attributes.ULclass#"'>
				<cfelse>
					<cfset theULclass = "">
				</cfif>
				<cfif len(attributes.LIclass)>
					<cfset theLIclass = ' class="#attributes.LIclass#"'>
				<cfelse>
					<cfset theLIclass = "">
				</cfif>
				<cfoutput>
					<ul#theULclass#>
				<cfloop query="session.shop.temp.getObjects.data">
					<li#theLIclass#><a href="#attributes.LinkPath#?CatID=#session.shop.temp.getObjects.data.ObjectID#"#theLinkClass#>#session.shop.temp.getObjects.data.ShortDescription#</li>
				</cfloop>
				</ul>
				</cfoutput>
				
			<cfelse>
			</cfif>
		<cfelse>
			<cfoutput>
			ERROR! The shop Object display failed.
			<cfif application.config.base.debugMode eq True>
				<br>Error message was: <br>#session.shop.temp.getObjects.error.errorText#<br>
			</cfif>
			</cfoutput>
		</cfif>
	<cfcatch type="any">
		<cfoutput>
		ERROR! The shop Object display failed.
		<cfif application.config.base.debugMode eq True>
			<br>Error dump is: <cfdump var="#cfcatch#">
		</cfif>
		</cfoutput>
	</cfcatch>
	</cftry>
</cfif>

<cfif thisTag.executionMode IS "end">
</cfif>
<cfsetting enablecfoutputonly="No">
