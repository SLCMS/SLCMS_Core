<!--- SLCMS base tags to be used in template pages  --->
<!--- SLShop part of SLCMS &copy; mort bay communications --->
<!---  --->
<!--- custom tag to display a shop template --->
<!---  --->
<!---  --->
<!--- Created:   1st Apr 2008 by Kym K --->
<!--- Modified:  1st Apr 2008 - 25th Apr 2008 by Kym K, initial work on it --->
<!--- Modified:  2nd Mar 2009 -  2nd Mar 2009 by Kym K, big pause, now more work on it, added wrapper divs --->

<!--- 
 --->
<cfsetting enablecfoutputonly="Yes">
<cfif thisTag.executionMode IS "start">
	<cfparam name="attributes.ShopName" type="string" default="">	<!--- the name of this shop --->
	<cfparam name="attributes.TemplateSet" type="string" default="">	<!--- the template set to look in, defaults to the caller's set --->
	<cfparam name="attributes.Template" type="string" default="">	<!--- the template to call --->
	<cfparam name="attributes.Level" type="string" default="">	<!--- level to start at, defaults to the current level, ie you have to force the top level in the calling template --->
	<cfparam name="attributes.EditHeading" type="string" default="">

	<!--- firstly we need to see if we are at the top of the shop and if so reset the session parameters --->
  <cfif attributes.Level eq "Entry">
    <cfset session.shop.currentCategoryID = 0 />
  </cfif>
  <!--- then fix the template set to use --->
	<cfif attributes.TemplateSet eq "">
		<cfset thisTag.TemplateSet = request.PageParams.TemplateSetName />
	<cfelse>
		<cfset thisTag.TemplateSet = attributes.TemplateSet />
	</cfif>
	<!--- then the workflow --->
	<cfset thisTag.theShopName = trim(attributes.ShopName) />
	<cfset thisTag.theEditHeading = trim(attributes.EditHeading) />
	<cfset thisTag.EditMode = False />
<!--- 
<cfdump var="#request.PageParams#" expand="false">
 --->
	<cfif thisTag.theShopName neq "">
	<cftry>
		<!--- first off we must see if this shop exists and create it if not --->
		<cfset thisTag.ret_ShopCreate = 1 />
		<!--- no we know there is something, even if its blank, we can display the shop template --->
		<cfset thepath = "#application.config.base.RootURL##application.config.base.SLCMSShopTemplatesRelPath##thisTag.TemplateSet#/#attributes.Template#.cfm" />
		<cfoutput>
	  <div class="ContentContainer_Wrapper">
		<cfif session.user.IsAuthor>
			<div class="ContentContainer_Marker">
		</cfif>
		<cfif not thisTag.EditMode>
			<div class="ContentContainer_Controls">
				<form action="#application.config.Base.rootURL#content.cfm#request.pageparams.PagePathEncoded#" method="post" name="ShopEditControls">
					<!--- 
					<input type="hidden" name="DocID" value="#thePageID#">
					<input type="hidden" name="ContentID" value="#theContentControlData.ContentID#">
					<input type="hidden" name="ContentHandle" value="#theContentControlData.Handle#">
					<input type="hidden" name="ContainerName" value="#attributes.Name#">
					<input type="hidden" name="ContainerID" value="#attributes.ID#">
					<input type="hidden" name="ContentVersion" value="#theContentControlData.Version#">
					 --->
					<input type="hidden" name="FCKSubmission" value="No">
					<input type="hidden" name="Edit" value="EditContainer">
				<div class="ContentContainer_Controls_EditButton">	<!--- the edit button floats to the right --->
					<input type="submit" name="AddCategory" value="Add Category"> | 
					<input type="submit" name="AddProduct" value="Add Product">
				</div>
				<div class="ContentContainer_Controls_Heading">#thisTag.theEditHeading#</div>	<!--- the text heading on the left --->
				</form>
				<!--- we see the floated tool buttons so push the content below them --->
				<div class="ContentContainer_Controls_Clear"></div>
			</div>
		</cfif>
		<cfinclude template="#thepath#">
		<cfif session.user.IsAuthor>
			</div>
		</cfif>
		</div>
		</cfoutput>
	<cfcatch type="any">
		<cfoutput>
		ERROR! The shop template: &quot;#attributes.Template#&quot; could not be found.<br>I was looking in: #thepath#
		<cfif application.config.base.debugMode eq True>
			<br>Error dump is: <cfdump var="#cfcatch#">
		</cfif>
		</cfoutput>
	</cfcatch>
	</cftry>
	<cfelse>
		<cfoutput>
		ERROR! <br>There is no name for the shop, I don't know where to look. <br>This page's template needs fixing.
		</cfoutput>
	</cfif>
</cfif>

<cfif thisTag.executionMode IS "end">
</cfif>
<cfsetting enablecfoutputonly="No">
