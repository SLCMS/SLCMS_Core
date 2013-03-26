<!--- SLCMS CFCs  --->
<!--- &copy; mort bay communications --->
<!---  --->
<!--- all the functions related to displaying wiki-based content --->
<!---  --->
<!---  --->
<!--- Cloned:    8th Feb 2009 by Kym K from the mbcomms' DocsNsops wiki code that came from Australian Antarctic Division that came from... as indicated in the commented section below. --->
<!--- modified:  8th Feb 2009 -  8th Feb 2009 by Kym K - mbcomms: initial integration of wiki into SLCMS, needs to be done properly and all unused stuff removed, or functionality added to SLCMS --->
<!--- modified: 18th Feb 2011 - 18th Feb 2011 by Kym K - mbcomms: ran varScoper over code and found un-var'd variables! oops :-/  --->

<cfcomponent>

<!---
This is a ColdFusion component that provides basic Wiki functionality. The code was originally written as a set of .cfm scripts by Brian Shearer and others (see http://www.cdsi-solutions.com/cfwiki/).

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
			split into 2 CFCs, one for code and one for display, this is the display one --->
<!--- Modified 12th Oct 2006 - 12th Oct 2006 by Kym K, inital work to make it fit us --->
<!--- Modified 14th Oct 2006 - 15th Oct 2006 by Kym K, changed to multi 4K blocks for content so no size limitation --->
<!--- Modified 18th Nov 2006 - 19th Nov 2006 by Kym K, adding breadcrumbs and FCK editor --->
<!--- Modified 22nd Nov 2006 - 22nd Nov 2006 by Kym K, added sitemap --->
<!--- Modified 11th Dec 2006 - 18th Dec 2006 by Kym K, adding users/roles/permissions, etc --->
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

	<cfset variables.SubSiteID = "" />
	<cfset variables.TablePath = "" />

<cffunction name="init" access="public" returnType="any" output="true">
	<cfargument name="SubSiteID" default="0" hint="subsite this invokation is in">
	<cfargument name="TablePath" default="" hint="DB table that has the label mapping">
		
	<cfset variables.SubSiteID = arguments.SubSiteID />
	<cfset variables.TablePath = arguments.TablePath />

</cffunction>	

<cffunction name="dsp_head" access="public" output="yes" hint="outputs header for wiki pages" >
  <cfargument name="doc" type="string" />
  <cfargument name="logopath" type="string" default="" />
	
	<cfset var theCrumb = '' />
	<cfset var strBreadCrumb = '' />
	<cfset var editAllowed = '' />
	<cfset var uploadAllowed = '' />
	<cfset var doc_url = '' />


  <!--- we don't want to update the breadcrumbs if not just viewing --->
	<cfif (isDefined("url.task") and url.task neq "display") or doc eq "RecentEdits">
		<cfset theCrumb = "" />
	<cfelse>
		<cfset theCrumb = doc />
	</cfif>
	<cfset strBreadCrumb = request.wiki_code.wiki_BreadCrumbUpdate(theCrumb) />

  <cfset editAllowed = request.wiki_code.wiki_editAllowed() />
  <cfset uploadAllowed = request.wiki_code.wiki_uploadAllowed() />
	<cfset doc_url = URLEncodedFormat(doc) />	<!--- this is for the links in the header --->

  <cfif request.cfwiki.useAADCHeader >
    <cfmodule template="/aadc_tags/header.cfm" heading="#doc#" >
  <cfelse><!--- not using AADC header, so need to output html header and css here --->
<!---       <!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN"> --->
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
	"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">      <html>
      <head>
				<title><cfoutput>#doc#</cfoutput></title>
				<LINK REL="stylesheet" TYPE="text/css" HREF="wiki.css" />
				<link type="text/css" href="style3.css" rel="stylesheet" />      
			</head>
      <body bgcolor="white">
    </cfif>

    <cfoutput>
<!--- add in script that allows resizing of flash objects, for maths equations --->
<script type="text/javascript" >
<!--
function setFlashWidth(divid, newW){
	document.getElementById(divid).style.width = newW+"px";
}
function setFlashHeight(divid, newH){
	document.getElementById(divid).style.height = newH+"px";		
}
function setFlashSize(divid, newW, newH){
	setFlashWidth(divid, newW);
	setFlashHeight(divid, newH);
}
function canResizeFlash(){
	var ua = navigator.userAgent.toLowerCase();
	var opera = ua.indexOf("opera");
	if( document.getElementById ){
		if(opera == -1) return true;
		else if(parseInt(ua.substr(opera+6, 1)) >= 7) return true;
	}
	return false;
}
-->
</script>

    <div class="wikiheader">

			<!--- 
			    <h1 class="wikiheader">#request.cfwiki.defaultDoc#<cfif doc NEQ request.cfwiki.DefaultDoc>: #doc#</cfif></h1>
			    <cfif len(trim(logopath)) ><img src="#logopath#" alt="[Home]" border=0 align="right"></cfif>
			 --->
			<table width="100%" cellspacing="0" cellpadding="10" border="0" class="HdrTbl">
			<tbody>
			<tr>
			<td width="200" class="HdrLeft" colspan="1"><a href="index.cfm?doc=#URLEncodedFormat(request.cfwiki.defaultDoc)#">
			<img width="171" height="100" border="0" title="mbcomms home" alt="mbcomms logo" src="/images/toplogover171x100.gif" />
			</a>
			</td>
			<td valign="middle" class="HdrMid">
			
			<h1>#request.cfwiki.defaultDoc#<cfif doc NEQ request.cfwiki.DefaultDoc>: 
			<cfif IsDefined("url.task") and (url.task eq "edit" or url.task eq "permissions")>
				<a href="index.cfm?doc=#doc_url#">#doc#</a>
			<cfelse>
				#doc#
			</cfif>
			</cfif></h1>
			<br />
			#session.Breadcrumbs.CrumbStringHTML#&nbsp;
			</td>
			<td width="200" valign="middle" align="right" class="HdrRight" colspan="1">
			
			    <cfif (url.doc eq "RecentEdits" or url.doc eq "SiteMap") or (isDefined("url.task") and url.task eq "Results")><!---edit not Allowed ---><!--- show this even if not allowed to do it, so that user can see that this action should be possible if they were sufficiently privileged --->
			     (Page is Read Only) 
					<cfelseif not request.wiki_code.wiki_editAllowed() or not request.wiki_code.wiki_viewAllowed()>
						(you do not have edit permission for this page)
			    <cfelse>
		    		<a href="index.cfm?doc=#doc_url#&amp;task=edit" class="wikipagelink">Edit this page</a>
						<cfif session.cfwiki.role.IsAdmin and not ((url.doc eq "RecentEdits" or url.doc eq "SiteMap" or url.doc eq request.cfwiki.defaultDoc) or (isDefined("url.task") and url.task eq "Results"))>
							<!--- only show the perms to admins and not the home page --->
							<br />
			    		<a href="index.cfm?doc=#doc_url#&amp;task=permissions" class="wikipagelink">Set Permissions for this page</a>
				    </cfif>
			    </cfif>
					<br />
			    <a href="index.cfm?doc=#doc_url#&amp;task=versionlist" class="wikipagelink">Page History</a>
					<br />
			    <a href="index.cfm?doc=RecentEdits" class="wikipagelink">Recent Edits</a>
			    <cfif request.cfwiki.allowFileUploads >
			      <!--- if this wiki allows uploads, show this option even if the user is not allowed to do it, so that user can see that this action should be possible if they were sufficiently privileged --->
			     <br /><a href="index.cfm?task=upload" class="wikipagelink">Upload a file</a>&nbsp;
			    </cfif>
					<br />
			    <a href="index.cfm?doc=#doc_url#&amp;task=results" class="wikipagelink">Search</a>
					<!--- <br /> --->&nbsp;&nbsp;&nbsp;&nbsp;
			    <a href="index.cfm?doc=SiteMap" class="wikipagelink">SiteMap</a>
			</td>
			</tr>
			</tbody>
			</table>
<!--- 
    <a href="index.cfm?doc=#request.cfwiki.defaultDoc#" class="wikipagelink">Home</a> &nbsp; | &nbsp;
    <a href="index.cfm?doc=RecentEdits" class="wikipagelink">Recent Edits</a> &nbsp; | &nbsp;
    <cfif 1><!---editAllowed ---><!--- show this even if not allowed to do it, so that user can see that this action should be possible if they were sufficiently privileged --->
     <a href="index.cfm?doc=#doc#&task=edit" class="wikipagelink">Edit this page</a>
    <cfelse>
     (Read only) 
    </cfif>
    <a href="index.cfm?doc=#doc#&task=results" class="wikipagelink">Search</a> &nbsp; | &nbsp;
    <cfif request.cfwiki.allowFileUploads >
      <!--- if this wiki allows uploads, show this option even if the user is not allowed to do it, so that user can see that this action should be possible if they were sufficiently privileged --->
     &nbsp; | &nbsp; <a href="index.cfm?task=upload" class="wikipagelink">Upload a file</a>
    </cfif>
    <br />
    <hr class=wikilineheader></div>
		 --->
    </div>
    </cfoutput>
  </cffunction>

	
<cffunction name="dsp_ShowBlurb" access="public" output="yes" >
  <cfargument name="doc" type="string" >
	<!--- just shows the content specified --->
	<cfset var showwiki=request.wiki_code.get_wikicontent(doc="#doc#") />
	<cfset var thiswiki = request.wiki_code.sel_showwiki(doc="#doc#") />
  <cfset var showBlurb =  "" />
	<!--- 
	<cfoutput>
	<cfdump var="#showwiki#"><cfabort>
	</cfoutput>
	 --->
	<cfif thiswiki.EditMode eq 'wiki'>
		<!--- render the wiki tags into html --->
	  <cfset showBlurb = request.wiki_code.act_wiki(doc="#doc#", showwiki=showwiki) >
	<cfelseif thiswiki.EditMode eq 'fck'>
		<!--- its full html so just show it --->
	  <cfset showBlurb =  showwiki>
		<cfset showBlurb = request.wiki_render.render_links(string=showwiki, webpath=request.cfwiki.webPath)>
	<cfelse>
	  <cfset showBlurb =  "">
	</cfif>
	<cfif len(trim(ShowBlurb)) >
		<div class="wikibody" ><cfoutput>#showBlurb#</cfoutput></div>
	</cfif>
</cffunction>

	
	
  <cffunction name="dsp_recentedits" access="public" output="yes" >
		
		<cfset var recentedits = '' />
		<cfset var sqlString = "SELECT Max(wikiTbl.Updated) AS Updated, wikiTbl.Label, wikiTbl.Author, Count(wikiTbl.Label) AS EditCount FROM #request.cfwiki.database.TableNames.Page_Base# wikiTbl WHERE (((wikiTbl.AppName)='#request.cfwiki.wikiName#')) GROUP BY wikiTbl.Label, wikiTbl.Author HAVING (((Max(wikiTbl.Updated))>#CreateODBCDateTime(Now())#-7)) ORDER BY Max(wikiTbl.Updated) DESC" />
		
    <cfquery name="recentedits" datasource="#request.cfwiki.database.datasource#" >
    #PreserveSingleQuotes(sqlString)#
    </cfquery>


    <table class="wikitable" width="95%" >
			<tr>
				<th align="left" valign="top" colspan="4" class="wikitable">
					Pages that have been edited in the last 7 days:</th>
			</tr>
			<tr>
				<th class="wikitable">Label</th>
				<th class="wikitable">Total Edits</th>
				<th class="wikitable">Recent Edits</th>
				<th class="wikitable">Last Edit</th>
				<th class="wikitable">Author</th>
			</tr>
			<cfoutput query="recentedits">
			<tr>
				<td align="left" class="wikitable"><a href="index.cfm?doc=#URLEncodedFormat(recentedits.label)#">#recentedits.label#</a></td>
				<td align="center" class="wikitable">#recentedits.EditCount#</td>
				<td align="center" class="wikitable">#recentedits.RecordCount#</td>
				<td align="left" class="wikitable" nowrap>#DateFormat(recentedits.updated,"yyyy.mm.dd")# | #TimeFormat(recentedits.updated,"HH:mm:ss")#</td>
				<td align="left" class="wikitable">#recentedits.Author#</td>
			</tr>
			</cfoutput>
    </table>
  </cffunction>
  
  <cffunction name="dsp_lastedited" access="public" output="yes" >
    <cfargument name="doc" type="string" >

		<cfset var recentedits = '' />
    <cfset var sqlString="SELECT wikiTbl.Updated, wikiTbl.Author FROM #request.cfwiki.database.TableNames.Page_Base# wikiTbl WHERE wikiTbl.Label = '#doc#' AND AppName = '#request.cfwiki.wikiName#' ORDER BY wikiTbl.Updated DESC" >

    <cfquery name="recentedits" datasource="#request.cfwiki.database.datasource#" maxrows=1>
    #PreserveSingleQuotes(sqlString)#
    </cfquery>
    <cfif IsDefined("recentedits") AND IsQuery(recentedits) >
    <cfoutput query="recentedits">
      <div class="wikifooter">This page last edited on #DateFormat(Updated, "dd mmm yyyy")# at #TimeFormat(Updated, "HH:mm:ss")# by: #Author#

    <cfif request.wiki_code.wiki_isAdmin() >
        <br /><a href="index.cfm?task=traffic&amp;doc=#URLEncodedFormat(doc)#">View recent traffic</a> for this page
    </cfif>

    </div>
    </cfoutput>
    </cfif>
  </cffunction>

  <cffunction name="dsp_SiteMap" access="public" output="yes" >
    
		<cfset var thislabel = '' />
		<cfset var getSiteMap1 = '' />
		<cfset var getSiteMap2 = '' />
		<cfset var sqlString="SELECT Distinct wikiTbl.label FROM #request.cfwiki.database.TableNames.Page_Base# wikiTbl WHERE AppName = '#request.cfwiki.wikiName#' ORDER BY wikiTbl.label" >
    
		<cfquery name="getSiteMap1" datasource="#request.cfwiki.database.datasource#">
    #PreserveSingleQuotes(sqlString)#
    </cfquery>
    <table class="wikitable" width="95%" >
		<tr><cfoutput>
			<th align="left" valign="top" colspan="2" class="wikitable">
				Site Map of all pages in alphabetical order. there are: #getSiteMap1.RecordCount# pages</th>
		</tr></cfoutput>
		<tr>
			<th class="wikitable">Label</th>
			<th class="wikitable">Summary</th>
		</tr>
    <cfoutput query="getSiteMap1">
		<cfset thislabel = getSiteMap1.label>
    <cfset sqlString="SELECT wikiTbl.updated, wikiTbl.Summary FROM #request.cfwiki.database.TableNames.Page_Base# wikiTbl WHERE wikiTbl.label = '#thislabel#' ORDER BY wikiTbl.updated desc" >
    <cfquery name="getSiteMap2" datasource="#request.cfwiki.database.datasource#" maxrows="1">
    #PreserveSingleQuotes(sqlString)#
    </cfquery>
		<tr>
		<td align="left" class="wikitable"><a href="index.cfm?doc=#URLEncodedFormat(thislabel)#">#thislabel#</a></td>
		<td align="left" class="wikitable">#getSiteMap2.Summary#</td>
		</tr>
    </cfoutput>
		</table
  </cffunction>

  <cffunction name="dsp_traffic" access="public" output="yes" >
    <cfargument name="doc" type="string" >
		
		<cfset var hits = '' />
    <cfset var sqlString="select HitTime, IP from #request.cfwiki.database.TableNames.Hits# where Doc='#doc#' order by HitTime DESC" >

    <cftry>
      <cfquery datasource="#request.cfwiki.database.datasource#" maxrows=10 name="hits" >
      #PreserveSingleQuotes(sqlString)#
      </cfquery>
      <cfcatch></cfcatch>
    </cftry>
    <cfoutput>
    <table><tr><th colspan="2">Recent hits on page #doc#</th></tr>
    <tr><th>Date</th><th>IP address</th></tr>
    <cfloop query=hits >
      <tr><td>#HitTime#</td><td>#IP#</td></tr>
    </cfloop>
      </cfoutput>
      </table>
  </cffunction>  

  <cffunction name="frm_search" access="public" output="yes" >
    <cfargument name="searchterm" default="" >
    <table width="95%" align="center" cellpadding="0" cellspacing="12" border="0">
	<tr><td>
	<form action="index.cfm?task=results" method="post">
	<input type="text" name="searchterm" size="25" maxlength="255" value="#searchterm#" >
	<input type="submit" name="submit" value="Search">
	</form>
	</td></tr>
    </table>
  </cffunction>

  <cffunction name="dsp_results" access="public" output="yes" >
    <cfargument name="wikiresults" type="query" >
    <table width="95%" align="center" cellpadding="3" cellspacing="0" border="0" bgcolor="white">
	<tr><th>Documents matching/containing &quot;<cfoutput>#searchterm#</cfoutput>&quot;</th></tr>
	<cfoutput query="wikiresults">
	<tr><td>
	  <a href="index.cfm?doc=#URLEncodedFormat(wikiresults.Label)#">#wikiresults.Label#</a><cfif len(Summary)> | #Summary#</cfif>
	</td></tr>
	</cfoutput>
    </table>
  </cffunction>


  <cffunction name="dsp_version" access="public" output="yes" >
    <cfargument name="showwiki" type="query" >
    <cfargument name="content" type="string" >
		
    <cfset var editAllowed = request.wiki_code.wiki_editAllowed() >
		
    <table width="95%" align="center" cellpadding="0" cellspacing="1" border="0">
      <tr><td>
	<cfoutput>
	  <h3>Version: #showwiki.Updated#</h3> Summary: #showwiki.Summary#
		<hr />
	  <cfif len(trim(arguments.content)) >
			<div class="wikibody" >
			<cfif editAllowed>
				<form action="index.cfm?task=update&amp;doc=#URLEncodedFormat(showwiki.Label)#" method="post">
			  <cfoutput>#arguments.content#</cfoutput>
				<hr />
		    <input type="hidden" name="Label" value="#showwiki.Label#"><br />
		    <input type="submit" value="Revert to this version">
				&nbsp;&nbsp;OR&nbsp;&nbsp;&nbsp;select another version from the list below
				</form>
				<cfelse>
			  <cfoutput>#arguments.content#</cfoutput>
			</cfif>
			</div>
		</cfif>
		<!--- 
	  <cfif editAllowed >
            <form action="index.cfm?task=update&doc=#showwiki.Label#" method="post">
            <input type="hidden" name="Author" value="#showwiki.Author#">
            <textarea cols="70" rows="15" name="Blurb">#arguments.content#</textarea>
            <input type="hidden" name="Label" value="#showwiki.Label#"><br />
            <input type="submit" value="Revert to this version">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
            </form>
	  <cfelse>
	    <textarea cols="70" rows="15" name="blurb">#arguments.content#</textarea>
	  </cfif>
		 --->
	  </cfoutput><br />
	</td></tr>
    </table>
  </cffunction>

  <cffunction name="frm_wiki" access="public" output="yes" hint="I am a form that allows the user to change the contents of a document" >
    <cfargument name="doc" type="string" >
    <!--- based on frm_wiki.cfm by brian@cdsi-solutions.com --->

    <cfset var editAllowed = request.wiki_code.wiki_editAllowed() >
		<cfset var showwiki = '' />
		<cfset var showBlurb = '' />
		<cfset var dSummary = '' />
		<cfset var Author = '' />
		<cfset var basePath = '' />
		<cfset var fckEditor = '' />
		
    <cfif editAllowed >
      <p>
      <cfif 1 eq 1 or doc EQ request.cfwiki.defaultDoc OR REFind("([^[:space:]]*[[:upper:]][^[:space:]]*[[:upper:]][^[:space:]]*)",doc) >

        <!--- look up doc--->
        <cfset showwiki = request.wiki_code.sel_showwiki(doc="#URL.doc#") />
        <!--- and its content --->
				<cfset showBlurb=request.wiki_code.get_wikicontent(doc="#URL.doc#") >
				<cfif len(showBlurb) eq 0>
	        <cfset showBlurb="This is a new page. Enter content for &quot;#doc#&quot; here. (And don't forget to remove this text)" ><!--- default page text (will appear for new pages on first edit --->
				</cfif>
  			<cfif len(showwiki.Summary) eq 0>
	        <cfset dSummary="#doc#" >
				<cfelse>
	        <cfset dSummary=showwiki.Summary >
				</cfif>
        <!--- if a record is found then --->
        <cfif IsDefined("session.username") AND len(trim(session.username))>
          <cfset Author = session.username />
        <cfelseif IsDefined("session.full_name") AND len(trim(session.full_name))>
          <cfset Author = session.full_name />
        <cfelseif IsDefined("session.cfwiki.role.user") AND len(trim(session.cfwiki.role.user))>
          <cfset Author = session.cfwiki.role.user />
        <cfelseif IsDefined("cgi.remote_user") AND len(trim(cgi.remote_user))>
          <cfset Author = cgi.remote_user />
        <cfelseif IsDefined("cgi.remote_addr") AND len(trim(cgi.remote_addr))>
          <cfset Author = cgi.remote_addr />
        <cfelseif len(showwiki.Author)>
          <cfset Author = showwiki.Author />
        <cfelse>
          <cfset Author = "Unknown" />
        </cfif>
				

        <cfoutput>
				<div>
					<cfif showwiki.EditMode eq 'wiki'>
	          <form action="index.cfm?task=update&amp;doc=#URLEncodedFormat(doc)#" method="post">
						<input type="hidden" name="Label" value="#doc#">
	          <textarea cols="80" rows="15" name="Blurb">#showBlurb#</textarea>
						<input type="hidden" name="EditModeFlag" value="wiki">
					<cfelseif showwiki.EditMode eq 'fck'>
	          <form action="index.cfm?task=update&amp;doc=#URLEncodedFormat(doc)#" method="post">
						<input type="hidden" name="Label" value="#doc#">
						<cfscript>
							// Calculate basepath for FCKeditor. It's in the folder right below us
							basePath = request.cfwiki.basePath&'fckeditor/';
						
							fckEditor = createObject("component", "#basePath#fckeditor");
							fckEditor.instanceName	= "Blurb";
							fckEditor.value			= '#showBlurb#';
							fckEditor.basePath		= basePath;
							fckEditor.width			= "95%";
							fckEditor.height		= 400;
							fckEditor.create(); // create the editor.
						</cfscript>
						<input type="hidden" name="EditModeFlag" value="fck">
					<cfelse>
	          <form action="index.cfm?task=update&amp;nextTask=edit&amp;doc=#URLEncodedFormat(doc)#" method="post">
						<input type="hidden" name="Label" value="#doc#">
						This is a new page or a page with no edit mode configured, 
						I don't know what to show you, please select an edit mode below
						<input type="hidden" name="EditModeFlag" value="NoMode">
						<input type="hidden" name="Blurb" value="">
						</cfif>
					<br />
					<table>
					<tr>
						<td align="right">Author: </td>
						<td><input type="text" name="Author" value="#Author#"></td>
						<td width="10">&nbsp;</td>
						<td align="right"> Edit using wiki tags <input type="radio" name="EditMode" value="wiki"<cfif showwiki.EditMode eq 'wiki'> checked</cfif>></td>
						</tr>
          <tr>
						<td align="right">Summary: </td>
						<td><input type="text" name="Summary" value="#dSummary#"></td>
						<td></td>
	          <td align="right"> Edit using WYSIWYG editor <input type="radio" name="EditMode" value="fck"<cfif showwiki.EditMode eq 'fck'> checked</cfif>></td>
						</tr>
					<cfif showwiki.EditMode neq 'fck' or 1 eq 1>
					<tr>
          <td></td>
					<td><input type="submit" value="save"></td>
					<td></td>
					</tr>
					</cfif>
					</table>
          </form>
        </div>
				</cfoutput>
        <br />
				<cfif showwiki.EditMode eq 'wiki'>
        <div align="right" class="edithelp">
        	<b>Text Formatting Hints:</b><br />
					#request.wiki_render.instructions()#
					<!--- 
        	To create a new document first make a link to it in an existing document<br />
        	by surrounding the link word with double square brackets <br />
					Examples: [[Valid Document]], [[ValidDocumentName]]<br /><br />
        	Leave a blank line between paragraphs to create a paragraph break<br /><br />
        	Text surrounded in **double asterix** converts to <b>bold</b>, text surrounded in //double slashes// converts to <i>italic</i><br /><br />
					Text surrounded by $dollar signs$ converts to a mathematical formula (rendered in Flash)<br /><br />
        	Starting a line off with a * creates a bullet, starting a line off with a : creates an indent<br /><br />
        	Four dashes ---- creates a horizontal line divider<br /><br />
        	URL's (e.g. <i>http://www.gnauga.com</i> or <i>[http://www.gnauga.com Link Text]</i>) are converted to links. <br /><br />
        	Enter "mailto:" before an email addresses to make it a link (mailto:gnauga@gnauga.com)<br /><br />
					 --->
        </div>
				</cfif>
      <cfelse>
        Sorry, <b><cfoutput>#doc#</cfoutput></b> is not a valid document name.<br />
        <!--- A valid document name must be one word that contains at least two uppercase characters.<br />
        Examples: <b>ValidName</b>, <b>ValidDocumentName</b>, <b>validDOC</b>, <b>VDN</b> --->
      </cfif>
      </p>
    <cfelse><!--- not allowed to edit given user roles --->
      <cfset dsp_notAllowed(action="edit") >
    </cfif>
  </cffunction>

  <cffunction name="frm_permissions" access="public" output="yes" hint="I show the permissions for a page" >
    <cfargument name="doc" type="string" >
		<!--- get the current permissions --->
		<cfset var thisRole = '' />
		<cfset var NoPerms = '' />
		<cfset var PernSum = '' />
		<cfset var editAllowed = '' />
		<cfset var getRoles = '' />
		<cfset var getPerms = '' />
		
		<cfquery name="getRoles" datasource="#request.cfwiki.database.datasource#">
			select	RoleID, Role_Description
				from	#request.cfwiki.database.TableNames.Roles#
				order by	RoleID
		</cfquery>

		<div class="wikibody" >
	<cfoutput>
	  <h3>Permissions for this page:</h3>
		<form action="index.cfm?task=updatePermissions&amp;doc=#URLEncodedFormat(doc)#" method="post">
    <table width="95%" align="center" cellpadding="0" cellspacing="1" border="0">
		<tr>
			<td align="right"><strong>Role</strong></td>
			<td align="center"><strong>None</strong></td>
			<td align="center"><strong>View Only</strong></td>
			<td align="center"><strong>View and Moderated Editing</strong></td>
			<td align="center"><strong>View and Full Editing</strong></td>
		</tr>
	  <cfloop query="getRoles">
			<cfset thisRole = getRoles.RoleID />
			<cfif thisRole neq 1>	<!--- not much point doing it for the admins :-) --->
				<cfquery name="getPerms" datasource="#request.cfwiki.database.datasource#">
					select top 1	pm.perm_Write_Full, pm.perm_Write_Moderated, pm.perm_View, pm.Updated
						from	#request.cfwiki.database.TableNames.Permissions# pm
						where	pm.RoleID = #thisRole#
							and	pm.Page_Label = '#url.doc#'
						order by	pm.Updated desc
				</cfquery>
				<cfif getPerms.RecordCount and (getPerms.perm_View neq 0 or getPerms.perm_Write_Moderated neq 0 or getPerms.perm_Write_Full neq 0)>
					<cfset NoPerms = False />
					<cfset PernSum = getPerms.perm_View + getPerms.perm_Write_Moderated + getPerms.perm_Write_Full  />
				<cfelse>
					<cfset NoPerms = True />
					<cfset PernSum = 0  />
				</cfif>
				<!--- 
				<cfdump var="#getPerms#">
				 --->
			<tr>
				<td align="right">#getRoles.Role_Description#: </td>
				<td align="center"><input type="radio" name="Permissions_Role_#thisRole#" value="0"<cfif NoPerms> checked</cfif> /></td>
				<td align="center"><input type="radio" name="Permissions_Role_#thisRole#" value="1"<cfif PernSum eq 1> checked</cfif> /></td>
				<td align="center"><input type="radio" name="Permissions_Role_#thisRole#" value="3"<cfif PernSum eq 3> checked</cfif> /></td>
				<td align="center"><input type="radio" name="Permissions_Role_#thisRole#" value="5"<cfif PernSum eq 5> checked</cfif> /></td>
			</tr>
			</cfif>
		</cfloop>
		<tr><td colspan="4">
    <input type="hidden" name="Label" value="#doc#" />
    <input type="submit" value="Set Permissions" />
		</td></tr>
		<!--- the old code cut down
    <cfset editAllowed = request.wiki_code.wiki_editAllowed() >
	  <cfif editAllowed >
	  <cfelse>
	  </cfif>
		 --->
	  </cfoutput>
    </table>
		</form>
		</div>
  </cffunction>

  <cffunction name="dsp_versionlist" access="public" output="yes" >
    <cfargument name="doc" type="string" >

    <cfset var sqlString="SELECT wikiTbl.Updated, wikiTbl.Summary, wikiTbl.Author FROM #request.cfwiki.database.TableNames.Page_Base# wikiTbl WHERE wikiTbl.Label = '#doc#' AND AppName = '#request.cfwiki.wikiName#' ORDER BY wikiTbl.Updated DESC" />
		<cfset var versionlist = '' />
		
    <cfquery datasource="#request.cfwiki.database.datasource#" name="versionlist" maxrows=30 >
    #PreserveSingleQuotes(sqlString)#
    </cfquery>
    <table width="95%" align="left" cellpadding="3" cellspacing="0" border="0" bgcolor="white">
	<tr>
		<td>Version Date <br />(Most recent at top)</td>
		<td>Summary</td>
		<td>Author</td>
		<td width="50%">&nbsp;</td>
	</tr>
	<cfoutput query="versionlist">
	<tr>
		<td><a href="index.cfm?task=version&amp;doc=#URLEncodedFormat(doc)#&amp;version=#versionlist.updated#" class="versionlisting">#DateFormat(versionlist.updated,"yyyy.mm.dd")# #TimeFormat(versionlist.updated,"HH:mm:ss")#</a></td>
		<td><cfif len(Summary)>#Summary#<cfelse>-No Summary Text Entered-</cfif></td>
		<td>#versionlist.Author#</td>
		<td></td>
	</tr>
	</cfoutput>
    </table>
  </cffunction>


  <cffunction name="frm_upload" access="public" output="yes" hint="Displays a form that allows the user to upload a file to the wiki." >
    <!--- frm_upload - Ben, April 2005 --->
    <cfif request.wiki_code.wiki_uploadAllowed() >
    <table width="95%" align="center" cellpadding="0" cellspacing="12" border="0" bgcolor="white">
	<tr><td>
	<form action="index.cfm?task=upload" method="post" enctype="multipart/form-data" >
	<strong>Your file:</strong> <input type="file" name="userFilename" size="80"><br /><br />
	<input type="radio" name="FileType" value="Image" checked> Put this file in the &quot;Image&quot; folder<br />
	<input type="radio" name="FileType" value="File"> Put this file in the &quot;File&quot; folder<br />
	<input type="submit" value="Upload">
	</form>
	</td></tr>
    </table>
    <cfelse>
      <cfset dsp_notAllowed(action="upload files to") >
    </cfif>
  </cffunction>
  
  <cffunction name="dsp_notAllowed" access="public" output="yes" hint="Displays a message to let the user know that they do not have sufficient privileges to perform a particular action." >
    <!--- dsp_notAllowed - Ben, April 2005 --->
    <cfargument name="action" type="string" default="do that to" >
		
    <cfset var thisPath=ExpandPath('.') >
    <cfset thisPath=ReplaceNoCase(thisPath,'d:\data','') >
    <cfset thisPath=Replace(thisPath,'\','/',"ALL") >
    <div class="wikibody" >
    <cfoutput>
    <p>
		You do not have permission to #action# this page. 
		</p>
    </cfoutput>
    </div>
  </cffunction>


  <cffunction name="math_swfHTML" access="public" output="no" hint="Creates HTML required to include SWF of equation." >
    <!--- math_swfHTML - Ben, June 2005 --->
    <cfargument name="equationText" type="string" >
    <cfargument name="equationDivID" type="string" >
    <cfargument name="bgColor" type="string" default="##ffffff" >
		
		<cfset var htmlString = '' />

    <cfsavecontent variable="htmlString">
    <cfoutput>
    <div id="#equationDivID#" style="width:600px; height:200px;" >
    <script type="text/javascript" >
      <!--
      e = canResizeFlash();
      document.write('<object codebase="http://download.macromedia.com/pub/shockwave/cabs/flash/swflash.cab##version=6,0,0,0" id="mathTypePub" width="100%" height="100%" >');
      document.write('  <param name="movie" value="mathTypePub.swf?divid=#equationDivID#&equationText=#equationText#" />');
      document.write('  <param name="FlashVars" value="allowResize='+e+'" />');
      document.write('  <embed src="mathTypePub.swf?divid=#equationDivID#&equationText=#equationText#" width="100%" height="100%" allowScriptAccess="sameDomain" pluginspage="http://www.macromedia.com/go/getflashplayer" />');
      document.write('</object>');
      -->
    </script>
    <noscript>Javascript must be enabled</noscript>
    </div>
    </cfoutput>
    </cfsavecontent>
    <cfreturn htmlString >
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

