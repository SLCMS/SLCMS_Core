<!--- SLCMS CFCs  --->
<!--- &copy; mort bay communications --->
<!---  --->
<!--- all the functions related to displaying wiki-based content --->
<!---  --->
<!---  --->
<!--- Cloned:    8th Feb 2009 by Kym K from the mbcomms' DocsNsops wiki code that came from Australian Antarctic Division that came from... as indicated in the commented section below. --->
<!--- modified:  8th Feb 2009 -  8th Feb 2009 by Kym K - mbcomms: initial integration of wiki into SLCMS --->
<!--- modified:  7th May 2009 -  7th May 2009 by Kym K - mbcomms: V2.2, added subsiteID as a variable --->
<!--- modified: 18th Feb 2011 - 18th Feb 2011 by Kym K - mbcomms: ran varScoper over code and found un-var'd variables! oops :-/  --->

<cfcomponent>

<!---
This is a ColdFusion component that provides basci Wiki functionality. The code was originally written as a set of .cfm scripts by Brian Shearer and others (see http://www.cdsi-solutions.com/cfwiki/).

Ben Raymond
ben.raymond@aad.gov.au

Release history:
11 April 2005 - initial release.

14 April 2005
Added permissions for viewing, editing, uploading files. File upload. View traffic for individual pages.

7 July 2005
Fixed bugs that prevented <img>, <a>, <pre>, and <nowiki> tags being used as the first entry in a page
Added flash-based maths equation viewer. Formulae between $ tags will be rendered as a flash movie, e.g.
$3x^2 / (99+ cos(x^2))$
The Flash equation viewer was adapted from one written by Eric Lin ( http://www.geocities.com/~dr_ericlin/flash/indexgeo.html )
Note that the equation viewer supports only a limited set of maths functions and in some cases does not render correctly.


<!--- cloned from original code by Kym K of mbcomms for inhouse use
			split into 2 CFCs, one for code and one for display, this is the code one --->
<!--- Modified 12th Oct 2006 - 12th Oct 2006 by Kym K, inital work to make it fit us --->
<!--- Modified 14th Oct 2006 - 14th Oct 2006 by Kym K, changed to multi 4K blocks for content so no size limitation --->
<!--- Modified 18th Nov 2006 - 19th Nov 2006 by Kym K, adding breadcrumbs and FCK editor --->
<!--- Modified 11th Dec 2006 - 14th Dec 2006 by Kym K, adding users/roles/permissions, etc --->
<!--- Modified 28th Dec 2006 - 28th Dec 2006 by Kym K, tidied up html(fck) display --->

 
---

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

--->

	<cfset variables.SLCMSDSN = application.SLCMS.Config.datasources.CMS />
	<cfset variables.SubSiteID = "" />
	<cfset variables.TablePath = "" />

<cffunction name="init" access="public" returnType="any" output="true">
	<cfargument name="SubSiteID" default="0" hint="subsite this invokation is in">
	<cfargument name="TablePath" default="" hint="DB table that has the label mapping">
		
	<cfset variables.SubSiteID = arguments.SubSiteID />
	<cfset variables.TablePath = arguments.TablePath />

</cffunction>	

  <cffunction name="sel_showwiki" access="public" returnType="query" output="no" hint="Extract wiki data from DB">
    <cfargument name="doc" type="string" default="#request.cfwiki.defaultDoc#">
    <cfargument name="version" type="string" default="">    
    
    <cfset var sqlString = "" />
    <cfset var showwiki = "" />
		
    <cfif len(trim(version)) >
      <cfset sqlString="SELECT wikiTbl.Label, wikiTbl.Updated, wikiTbl.EditMode, wikiTbl.Author, wikiTbl.Summary FROM #request.cfwiki.database.TableNames.Page_Base# wikiTbl WHERE wikiTbl.Label = '#doc#' AND AppName = '#request.cfwiki.wikiName#' AND wikiTbl.Updated = #CreateODBCDateTime(ParseDateTime(version))# ORDER BY wikiTbl.Updated DESC" >
    <cfelse>
      <cfset sqlString="SELECT wikiTbl.Label, wikiTbl.Updated, wikiTbl.EditMode, wikiTbl.Author, wikiTbl.Summary FROM #request.cfwiki.database.TableNames.Page_Base# wikiTbl WHERE wikiTbl.Label = '#doc#' AND AppName = '#request.cfwiki.wikiName#' ORDER BY wikiTbl.Updated DESC" >
    </cfif>
    <cfquery datasource="#variables.SLCMSDSN#" name="showwiki" maxrows=1 >
      #PreserveSingleQuotes(sqlString)#
    </cfquery>
    <cfreturn showwiki >
  </cffunction>

	<!--- this is a new tag that just gets the content as it is now in chunks --->
  <cffunction name="get_wikicontent" access="public" returnType="string" output="no" hint="Extract wiki content from DB">
    <cfargument name="doc" type="string" default="#request.cfwiki.defaultDoc#">
    <cfargument name="version" type="string" default="">   
    
    <cfset var sqlString = '' />
		<cfset var theContent = '' />
		<cfset var thisPageID = '' />
		<cfset var contentArray = '' />
		<cfset var lcntr = '' />
		<cfset var getPgID = '' />
		<cfset var getContent = '' />
		
		<!--- first find the ID of the content we want ---> 
    <cfif len(trim(version)) >
      <cfset sqlString="SELECT wikiTbl.PageID FROM #request.cfwiki.database.TableNames.Page_Base# wikiTbl WHERE wikiTbl.Label = '#doc#' AND AppName = '#request.cfwiki.wikiName#' AND wikiTbl.Updated = #CreateODBCDateTime(ParseDateTime(version))# ORDER BY wikiTbl.Updated DESC" >
    <cfelse>
      <cfset sqlString="SELECT wikiTbl.PageID FROM #request.cfwiki.database.TableNames.Page_Base# wikiTbl WHERE wikiTbl.Label = '#doc#' AND AppName = '#request.cfwiki.wikiName#' ORDER BY wikiTbl.Updated DESC" >
    </cfif>
    <cfquery datasource="#variables.SLCMSDSN#" name="getPgID" maxrows=1 >
      #PreserveSingleQuotes(sqlString)#
    </cfquery>
		<cfset theContent = "" />
		<cfset thisPageID = getPgID.PageID>
		<!--- now get the content and back into one big bit --->
		<cfif getPgID.RecordCount gt 0 and thisPageID neq 0>	<!--- only get the actual content if there is something to find --->
	    <cfset sqlString="SELECT wikiTbl.PageContentChunk, wikiTbl.PageChunkNumber FROM #request.cfwiki.database.TableNames.Page_Content# wikiTbl WHERE wikiTbl.PageID = #thisPageID# ORDER BY PageChunkNumber">
	    <cfquery datasource="#variables.SLCMSDSN#" name="getContent" >
	      #PreserveSingleQuotes(sqlString)#
	    </cfquery>
			<cfif getContent.RecordCount eq 1>
				<cfset theContent = getContent.PageContentChunk />
			<cfelseif getContent.RecordCount gt 1>	<!--- many chunks so put them back together --->
				<cfset contentArray = Arraynew(1) />
				<cfloop query="getContent">
					<cfset contentArray[getContent.PageChunkNumber] = getContent.PageContentChunk />
				</cfloop>
				<cfloop index="lcntr" from="1" to="#ArrayLen(contentArray)#">
					<cfset theContent = theContent & contentArray[lcntr] />
				</cfloop>
			</cfif>
		</cfif>
    <cfreturn theContent >
  </cffunction>



  <cffunction name="act_wiki" access="public" returnType="string" output="no" hint="I take a wiki document string and convert it to HTML" >
    <!--- based on act_wiki.cfm version .02 by brian@cdsi-solutions.com --->
    <cfargument name="doc" type="string" >
    <cfargument name="showwiki" type="string" >
    
    <cfset var showBlurb= "" >
    
    <!--- if a record is found then load Blurb for processing--->
    <cfif len(arguments.showwiki)>
      <cfset showBlurb = request.wiki_render.RenderPage(PageContent=showwiki, webpath=request.cfwiki.webPath)>
		</cfif>
    <cfreturn showBlurb >
  </cffunction>



  <cffunction name="sel_checklabel" access="public" output="no" returnType="query" hint="" >
    <cfargument name="checkLabel" type="string" >
    <cfargument name="wikiID" type="string" >

    <cfset var qchecklabel= "" >
    
    <cfquery datasource="#variables.SLCMSDSN#" name="qchecklabel" maxrows=1 >
				SELECT Label, wikiID,  DocID
					FROM #variables.TablePath# 
					WHERE Label = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.checkLabel#"> 
						AND WikiID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.wikiID#"> 
    </cfquery>
    <cfreturn qchecklabel>
  </cffunction>


  <cffunction name="ins_traffic" access="public" output="no" >
    <cfargument name="doc" type="string" >

    <cfset var sqlString="INSERT INTO #request.cfwiki.database.TableNames.Hits# ( Doc, HitTime, IP, AppName ) values ('#Doc#', #CreateODBCDateTime(now())#, '#CGI.REMOTE_ADDR#', '#request.cfwiki.wikiName#')" >
    
    <cftry>
      <cfquery datasource="#variables.SLCMSDSN#">
      #PreserveSingleQuotes(sqlString)#
      </cfquery>
      <cfcatch></cfcatch><!--- not really much we can do if the insert fails --->
    </cftry>
  </cffunction>  

  <cffunction name="sel_wikiresults" access="public" output="no" returnType="query" >
    <cfargument name="searchterm" type="string" >
    
    <cfset var theSearchTerm=UCase(arguments.searchterm) >
		<cfset var sqlString = "" />
		<cfset var wikiresults = "" />
    
    <cfquery datasource="#variables.SLCMSDSN#" name="wikiresults" maxrows="100" >
    SELECT wikiTbl.Label, wikiTbl.Summary
			FROM #request.cfwiki.database.TableNames.Page_Base# wikiTbl, #request.cfwiki.database.TableNames.Page_Content# wikiContent
			WHERE wikiTbl.APPNAME = '#request.cfwiki.wikiName#' 
				and	wikiTbl.PageID = wikiContent.PageID
				AND (Upper(wikiContent.PageContentChunk) LIKE '%#theSearchTerm#%' 
				OR Upper(wikiTbl.Label) LIKE '%#theSearchTerm#%') 
			GROUP BY wikiTbl.Label, wikiTbl.Summary
    </cfquery>
    <cfreturn wikiresults >
  </cffunction>    

  <cffunction name="act_updateblurb" access="public" output="no" hint="I update a record in the database." >
    <!--- based on act_updateblurb.cfm by brian@cdsi-solutions.com --->

    <cfargument name="doc" type="string" >
    <cfargument name="Blurb" type="string" >
    <cfargument name="Author" type="string" >
    <cfargument name="Summary" type="string" >
    <cfargument name="EditMode" type="string" >
    
    <cfset var sqlString = '' />
		<cfset var ChunkArray = '' />
		<cfset var Content = '' />
		<cfset var ContentLen = '' />
		<cfset var LoopsToDo = '' />
		<cfset var lcntr = '' />
		<cfset var getPageID = '' />
		<cfset var InsertBase = '' />
		<cfset var InsertContent = '' />

    <!--- Insert --->
    <cftry>
			<!--- find out the ID for this entry --->
	    <cfset sqlString="SELECT Max(wikiTbl.PageID)+1 as NextID FROM #request.cfwiki.database.TableNames.Page_Base# wikiTbl" />
	    <cfquery datasource="#variables.SLCMSDSN#" name="getPageID">
	    #PreserveSingleQuotes(sqlString)#
	    </cfquery>
			
	    <!--- Insert the base data first --->
			<cfset sqlString="INSERT INTO #request.cfwiki.database.TableNames.Page_Base# (PageID,Updated,Label,Author,AppName,Summary,EditMode) values (#getPageID.NextID#,#CreateODBCDateTime(now())#,'#doc#','#Author#','#request.cfwiki.wikiName#','#Summary#','#EditMode#')" >
      <cfquery datasource="#variables.SLCMSDSN#" name="InsertBase">
      #PreserveSingleQuotes(sqlString)#
      </cfquery>
			<!--- then test the content for size and do the 4000 char chunk thing --->
			<cfset ChunkArray = ArrayNew(1) />
			<cfset Content = blurb />
			<cfset ContentLen = len(blurb) />
			<cfset LoopsToDo = ceiling(ContentLen/4000) />
			<cfloop from="1" to="#LoopsToDo#" index="lcntr">
				<cfset ChunkArray[lcntr] = left(Content, 4000) />
				<cfset Content = removeChars(Content, 1, 4000) />
			</cfloop>
	    <!--- and then insert the chunks, however many there are --->
			<cfloop index="lcntr" from="1" to="#ArrayLen(ChunkArray)#">
				<cfset sqlString="INSERT INTO #request.cfwiki.database.TableNames.Page_Content# (PageID,PageContentChunk,PageChunkNumber) values (#getPageID.NextID#,'#ChunkArray[lcntr]#',#lcntr#)" >
	      <cfquery datasource="#variables.SLCMSDSN#" name="InsertContent">
		      INSERT INTO #request.cfwiki.database.TableNames.Page_Content#
										(PageID,PageContentChunk,PageChunkNumber) 
						values (#getPageID.NextID#,'#ChunkArray[lcntr]#',#lcntr#)
	      </cfquery>
			</cfloop>
      <cfcatch>
        Could not save this page. Something broke :-(<!--- could not update the wiki page in the db --->
      </cfcatch> 
    </cftry>
  </cffunction>
	
  <cffunction name="act_updatePermissions" access="public" output="yes" hint="I update the page permissions in the database." >
    <!--- update the permissions for indicated page from form vars --->
    <cfargument name="doc" type="string" >
    
    <cfset var thisRole = '' />
		<cfset var flgView = '' />
		<cfset var flgMod = '' />
		<cfset var flgFull = '' />
		<cfset var thisField = '' />
		<cfset var SetPerm = '' />

		<!--- we will loop over the field names and pick out the radio buttons and set them in the permissions table --->
		<cfloop index="thisField" list="#form.Fieldnames#">
			<cfif left(thisField, 17) eq "PERMISSIONS_ROLE_">
				<cfset thisRole = removeChars(thisField, 1, 17) />
				<cfset flgView = BitAnd(form[thisField], 1) />
				<cfset flgMod = BitAnd(form[thisField], 2) />
				<cfset flgFull = BitAnd(form[thisField], 4) />
				<cfquery name="SetPerm" datasource="#variables.SLCMSDSN#">
					insert into	#request.cfwiki.database.TableNames.Permissions#
										(Page_Label, RoleID, Updated,
										perm_view, perm_write_full, perm_write_moderated)
						values	('#doc#', #thisRole#, #Now()#,
											#flgView#, #flgFull#, #flgMod#)
				</cfquery>
			</cfif>
		</cfloop>
  </cffunction>
	
	<cffunction name="wiki_BreadCrumbUpdate" access="public" output="No" returntype="string" hint="Creates the breadcrumb string used in the page header. Adds current doc name if supplied">
    <cfargument name="doc" type="string" default="" />
		
		<cfset var ret = '' />
		<cfset var thisItem = '' />

	
		<!--- if this is the first time in set up an empty set of breadcrumbs --->
		<!--- the breadrumb array is only the document names, we generate the html links on the fly each time --->
		<cfif not IsDefined("session.Breadcrumbs")>
			<cfset session.Breadcrumbs = StructNew() />
			<cfset session.Breadcrumbs.CrumbStringPages = ArrayNew(1) />
			<cfset session.Breadcrumbs.CrumbStringHTML = "" />
			<cfset ret = ArrayAppend(session.Breadcrumbs.CrumbStringPages, doc) />	<!--- add in this doc as we have just hit the site and there are no breadcrumbs as yet --->
		</cfif>
		<cfif len(doc) and session.Breadcrumbs.CrumbStringPages[ArrayLen(session.Breadcrumbs.CrumbStringPages)] neq doc>
			<!--- if we have a new doc add it to the end of the breadcrumbs but only if it not the same as the last one anyway --->
			<cfif ArrayLen(session.Breadcrumbs.CrumbStringPages) lt application.SLCMS.Config.BreadCrumbLength>
				<!--- if the array is not full just shove it at the end of the array --->
				<cfset ret = ArrayAppend(session.Breadcrumbs.CrumbStringPages, doc) />
			<cfelse>
				<!--- if the array is full then shuffle all down one --->
				<cfloop index="thisItem" from="1" to="#DecrementValue(application.SLCMS.Config.BreadCrumbLength)#">
					<cfset session.Breadcrumbs.CrumbStringPages[thisItem] = session.Breadcrumbs.CrumbStringPages[thisItem+1] />
				</cfloop>
				<cfset session.Breadcrumbs.CrumbStringPages[application.SLCMS.Config.BreadCrumbLength] = doc />
			</cfif>
			<!--- now we have an array which is the last x pages so make them into an HTML string --->
			<cfset session.Breadcrumbs.CrumbStringHTML = '<a href="index.cfm?doc=#URLEncodedFormat(session.Breadcrumbs.CrumbStringPages[1])#">#session.Breadcrumbs.CrumbStringPages[1]#</a>' />
			<cfloop index="thisItem" from="2" to="#DecrementValue(ArrayLen(session.Breadcrumbs.CrumbStringPages))#">
				<cfset session.Breadcrumbs.CrumbStringHTML = session.Breadcrumbs.CrumbStringHTML& ' &gt; <a href="index.cfm?doc=#URLEncodedFormat(session.Breadcrumbs.CrumbStringPages[thisItem])#">#session.Breadcrumbs.CrumbStringPages[thisItem]#</a>' />
			</cfloop>
			<!--- no link on the last item as its this page --->
			<cfset session.Breadcrumbs.CrumbStringHTML = session.Breadcrumbs.CrumbStringHTML& " &gt; #session.Breadcrumbs.CrumbStringPages[ArrayLen(session.Breadcrumbs.CrumbStringPages)]#" />
		</cfif>
	</cffunction>

  <cffunction name="wiki_editAllowed" access="public" output="no" hint="Decides if the user is allowed to edit pages in the wiki." >
    <!--- wiki_editAllowed - Ben, April 2005 --->
    <!--- updated Kym K, Dec 2006 for session-based roles --->
		
    <cfset var editAllowed = False />
		<cfset var idx = '' />
		<cfset var getPerm = '' />

		<cfif session.cfwiki.role.IsAdmin>	<!--- if admin all is OK, allow everything --->
      <cfset editAllowed = True />
		<cfelse>
			<!--- get the permissions for this page --->
			<cfif (not IsDefined("url.doc")) or (IsDefined("url.doc") and (url.doc eq "RecentEdits" or url.doc eq "SiteMap" or url.doc eq request.cfwiki.defaultDoc)) or (isDefined("url.task") and url.task eq "Results")>	<!--- home page and similar special pages are never editable --->
	      <cfset editAllowed = False />
			<cfelse>
				<!--- its a regular page so get its permissions --->
				<cfquery name="getPerm" datasource="#variables.SLCMSDSN#">
					select	top 1	perm_Write_Full, perm_Write_Moderated
						from	#request.cfwiki.database.TableNames.Permissions#
						where	Page_Label = '#url.doc#'
							and	RoleID = #session.cfwiki.role.roleID#
						order by Updated desc
				</cfquery>
				<cfif getPerm.perm_Write_Full neq 0 or getPerm.perm_Write_Moderated neq 0>
		      <cfset editAllowed = True />
				<cfelse>
		      <cfset editAllowed = False />
				</cfif>
			</cfif>
		</cfif>
<!--- 		
    <cfif len(trim(request.cfwiki.roleRequiredToEdit)) >
      <cfif IsDefined("session.user_roles") >
        <cfloop from="1" to="#ListLen(request.cfwiki.roleRequiredToEdit)#" index="idx" >
				  <cfif FindNoCase(ListGetAt(request.cfwiki.roleRequiredToEdit,idx),session.user_roles) >
				    <cfset editAllowed=true >
				  </cfif>
				</cfloop>
      </cfif>
    <cfelse>
      <cfset editAllowed=true >
    </cfif>  
 --->
    <cfreturn editAllowed >
  </cffunction>
  
  <cffunction name="wiki_viewAllowed" access="public" output="no" hint="Decides if the user is allowed to view pages in the wiki." >
    <!--- wiki_viewAllowed - Ben, April 2005 --->
    <!--- updated Ben, Sep 2005 to allow list of valid roles --->
		
    <cfset var viewAllowed = false />
		<cfset var idx = '' />
		<cfset var getPerm = '' />

		<cfif session.cfwiki.role.IsAdmin>	<!--- if admin all is OK, allow everything --->
      <cfset viewAllowed = true />
		<cfelse>
			<!--- get the permissions for this page --->
			<cfif (not IsDefined("url.doc")) or (IsDefined("url.doc") and (url.doc eq "RecentEdits" or url.doc eq "SiteMap" or url.doc eq request.cfwiki.defaultDoc)) or (isDefined("url.task") and url.task eq "Results")>	<!--- home page and similar special pages are always OK --->
	      <cfset viewAllowed = true />
			<cfelse>
				<!--- its a regular page so get its permissions --->
				<cfquery name="getPerm" datasource="#variables.SLCMSDSN#">
					select	perm_View
						from	#request.cfwiki.database.TableNames.Permissions#
						where	Page_Label = '#url.doc#'
							and	RoleID = #session.cfwiki.role.roleID#
				</cfquery>
				<cfif getPerm.perm_View eq 0 or getPerm.perm_View eq "">
		      <cfset viewAllowed = False />
				<cfelse>
		      <cfset viewAllowed = true />
				</cfif>
			</cfif>
		</cfif>	
		
		<!--- original code
    <cfif len(trim(request.cfwiki.roleRequiredToView)) >
      <cfif IsDefined("session.user_roles") >
        <cfloop from="1" to="#ListLen(request.cfwiki.roleRequiredToView)#" index="idx" >
	  <cfif FindNoCase(ListGetAt(request.cfwiki.roleRequiredToView,idx),session.user_roles) >
	    <cfset viewAllowed=true >
	  </cfif>
	</cfloop>
      </cfif>
    <cfelse>
      <cfset viewAllowed=true >
    </cfif>  
		 --->
    <cfreturn viewAllowed >
  </cffunction>
  


  <cffunction name="wiki_uploadAllowed" access="public" output="no" hint="Decides if the user is allowed to upload files to the wiki." >
    <!--- wiki_uploadAllowed - Ben, April 2005 --->
    <!--- updated Ben, Sep 2005 to allow list of valid roles --->
		
    <cfset var uploadAllowed = false >
    <cfset var idx = '' />
    
    <cfif len(trim(request.cfwiki.roleRequiredToUpload)) >
      <cfif IsDefined("session.user_roles") >
        <cfloop from="1" to="#ListLen(request.cfwiki.roleRequiredToUpload)#" index="idx" >
				  <cfif FindNoCase(ListGetAt(request.cfwiki.roleRequiredToUpload,idx),session.user_roles) >
				    <cfset uploadAllowed=true >
				  </cfif>
				</cfloop>
      </cfif>
    <cfelse>
      <cfset uploadAllowed=true >
    </cfif>
    <cfif request.cfwiki.allowFileUploads IS false >
       <cfset uploadAllowed = false >
    </cfif>
    <cfreturn uploadAllowed >
  </cffunction>

  <cffunction name="wiki_isAdmin" access="public" output="no" hint="Decides if the user is administrator." >
    <!--- wiki_isAdmin - Ben, April 2005 --->
    <!--- updated Ben, Sep 2005 to allow list of valid roles --->
		
    <cfset var isAdmin = false >
    <cfset var idx = '' />
    
    <cfif len(trim(request.cfwiki.roleRequiredForAdmin)) >
      <cfif IsDefined("session.user_roles") >
        <cfloop from="1" to="#ListLen(request.cfwiki.roleRequiredForAdmin)#" index="idx" >
				  <cfif FindNoCase(ListGetAt(request.cfwiki.roleRequiredForAdmin,idx),session.user_roles) >
				    <cfset isAdmin=true >
				  </cfif>
				</cfloop>
      </cfif>
    <cfelse>
      <cfset isAdmin=true >
    </cfif>  
    <cfreturn isAdmin >
  </cffunction>


<cfscript>
/**
 * Returns all the matches of a regex from a string.
 * Bug fix by  Ruben Pueyo (ruben.pueyo@soltecgroup.com)
 * 
 * @param str 	 The string to search. (Required)
 * @param regex 	 The regular expression to search for. (Required)
 * @return Returns an array. 
 * @author Raymond Camden (ray@camdenfamily.com) 
 * @version 2, June 6, 2003 
 */
function REGet(str,regex) {
	var results = arrayNew(1);
	var test = REFind(regex,str,1,1);
	var pos = test.pos[1];
	var oldpos = 1;
	while(pos gt 0) {
		arrayAppend(results,mid(str,pos,test.len[1]));
		oldpos = pos+test.len[1];
		test = REFind(regex,str,oldpos,1);
		pos = test.pos[1];
	}
	return results;
}
</cfscript>


</cfcomponent>

