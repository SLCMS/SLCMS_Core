<!--- SLCMS CFCs  --->
<!--- &copy; mort bay communications --->
<!--- inspired by and contains code from Ray Camden's Canvas wiki --->
<!---  --->
<!--- all the functions related to displaying wiki-based content --->
<!---  --->
<!---  --->
<!--- Cloned:    8th Feb 2009 by Kym K from the mbcomms' DocsNsops wiki code that came from Australian Antarctic Division that came from... as indicated in the commented section below. --->
<!--- modified:  8th Feb 2009 - 19th Feb 2009 by Kym K - mbcomms: initial integration of wiki into SLCMS --->
<!--- modified: 23rd Mar 2009 - 23rd Mar 2009 by Kym K - mbcomms: V2.2, changing structures to new module-allowing architecture, the core code is now just another module --->
<!--- modified:  7th May 2009 -  7th May 2009 by Kym K - mbcomms: V2.2, added susbiteID as a variable --->
<!--- modified: 18th Feb 2011 - 18th Feb 2011 by Kym K - mbcomms: ran varScoper over code and found un-var'd variables! oops :-/  --->

<cfcomponent displayName="Page Render" output="true" hint="This CFC just handles rendering functions.">

	<cfset variables.SubSiteID = "" />
	<cfset variables.renderMethods = structNew() />
	<cfset variables.variableMethods = structNew() />
	
<cffunction name="init" access="public" returnType="any" output="true">
	<cfargument name="SubSiteID" default="0" hint="subsite this invokation is in">
	<cfargument name="TablePath" default="" hint="DB table that has the label mapping">
	
	<cfset var key = "">
	<cfset var thisFunc = "">
	<cfset var md = "">
	<cfset var s = "">
	<cfset var varDir = getDirectoryFromPath(GetCurrentTemplatePath()) & "/variablecomponents/">
	<cfset var varCFCs = "">
	<cfset var cfcName = "">
	<cfset var functionArray = '' />
	<cfset var lcntr = '' />
	
	<cfset variables.SubSiteID = arguments.SubSiteID />
	<cfset variables.TablePath = arguments.TablePath />
	
	<!--- get my methods --->
	<cfset md = getMetaData("#this#") />
	<cfset functionArray = md.functions />
	<cfloop from="1" to="#ArrayLen(functionArray)#" index="lcntr">
		<cfset thisFunc = functionArray[lcntr] />
		<cfif isCustomFunction(this[thisFunc.name]) and findNoCase("render_", thisFunc.name) is 1>
			<!--- only record it if method is a render method --->
			<!--- just copy name and priority --->
			<cfset s = structNew() />
			<cfset s.name = thisFunc.name />
			<cfif structKeyExists(thisFunc, "priority") and isNumeric(thisFunc.priority)>
				<cfset s.priority = thisFunc.priority />
			<cfelse>
				<cfset s.priority = 1 />
			</cfif>
			<cfset s.instructions = thisFunc.hint />
			<cfset variables.renderMethods[s.name] = duplicate(s) />
		</cfif>
	</cfloop>
<!--- 
	<!--- get my kids --->
	<cfdirectory action="list" name="varCFCs" directory="#varDir#" filter="*.cfc">
	
	<cfloop query="varCFCs">
		<cfset cfcName = listDeleteAt(name, listLen(name, "."), ".")>
		
		<!--- store the name --->
		<cfset variables.variableMethods[cfcName] = structNew()>
		<!--- create an instance of the CFC. It better have a render method! --->
		<cfset variables.variableMethods[cfcName].cfc = createObject("component", "variablecomponents.#cfcName#")>
		<cfset md = getMetaData(variables.variableMethods[cfcName].cfc)>
		<cfif structKeyExists(md, "hint")>
			<cfset variables.variableMethods[cfcName].instructions = md.hint>
		</cfif>
		
	</cfloop>
	 --->
	<cfreturn functionArray>
</cffunction>	
	
<cffunction name="instructions" access="public" returnType="string" output="false"
			hint="Generate dynamic instructions.">		
	<cfset var sorted = "">
	<cfset var x = "">
	<cfset var result = "<ul>">

	<!--- Start parsing... --->
	<!--- sort the render methods --->
	<cfset sorted = structSort(variables.rendermethods, "numeric", "asc", "priority")>

	<cfloop index="x" from="1" to="#arrayLen(sorted)#">
		<cfset result = result & "<li>" & rendermethods[sorted[x]].instructions & "</li>">
	</cfloop>		


	<cfloop item="x" collection="#variables.variableMethods#">
		<cfif structKeyExists(variables.variableMethods[x], "instructions")>
			<cfset result = result & "<li>" & variables.variableMethods[x].instructions & "</li>">
		</cfif>
	</cfloop>		

	<cfset result = result & "</ul>">
	
	<cfreturn result>		

</cffunction>
	
	<cffunction name="RenderPage" access="public" returnType="string" output="true"
				hint="I do the heavy lifting of transforming a page body into the display.">
		<cfargument name="PageContent" type="string" required="true">
		<cfargument name="webpath" type="string" required="true">
		
		<cfset var body = arguments.PageContent>
		<cfset var sorted = "">
		<cfset var x = "">
		<cfset var tokens = "">
		<cfset var token = "">
		<cfset var cfcName = "">
		<cfset var result = "">
		
		<cfif not len(body)>
			<cfsavecontent variable="body">			
			<cfoutput>
			This wiki page has no content yet.
			<!--- 
			<br>
			<a href="#arguments.webpath#/index.cfm?doc=#url.doc#&task=edit">Edit this Page</a>
			 --->
			</cfoutput>
			</cfsavecontent>
			<cfreturn body>
		</cfif>
		
		<!--- tidy up CR/linefeeds and things so our sorts/parsers can operate consistently
					as we are only outputting to the page just strip all LF and only leave CRs --->
		<!--- CR only is OK, CR/LF pairs take back to just CR, LF left ver is that other OS so change to CR as well --->
<!--- 
		<cfset body = Replace(body, chr(13)&chr(10), chr(13), "all")>	<!--- CRLFpair > CR  --->
		<cfset body = Replace(body, chr(10), chr(13), "all")>	<!--- remove the solo LFs --->
 --->
		<!--- Start parsing... --->
		<!--- sort the render methods --->
		<cfset sorted = structSort(variables.rendermethods, "numeric", "asc", "priority")>
		<!--- and run them in turn on the body text --->
		<cfloop index="x" from="1" to="#arrayLen(sorted)#">
			<cfif sorted[x] neq "render_paragraphs">	<!--- we do the para last as we lose the line delims otherwise --->
				<cfinvoke method="#sorted[x]#" string="#body#" webpath="#arguments.webpath#" returnVariable="body">
			</cfif>
		</cfloop>		
		<cfinvoke method="render_paragraphs" string="#body#" webpath="#arguments.webpath#" returnVariable="body">

		<!--- now look for {variables} --->
		<cfset tokens = reFindAll("{.*?}", body)>
		<cfif tokens.pos[1] is not 0>
			<cfloop index="x" from="#arrayLen(tokens.pos)#" to="1" step="-1">
				<cfset token = mid(body, tokens.pos[x], tokens.len[x])>
				<!--- token is {...} --->
				<cfset cfcName = reReplace(token,"[{}]", "", "all")>
				<cflog file="wiki" text="cfcname=#cfcname#">
				<!--- do we have a component for it? --->
				<cfif structKeyExists(variables.variableMethods, cfcName)>
					<cfinvoke component="#variables.variableMethods[cfcName].cfc#" method="render" pageBean="#arguments.pageBean#" returnVariable="result">
					<cflog file="wiki" text="result=#result#">
					<cflog file="wiki" text="left=#left(body, tokens.pos[x]-1)#">
					<cflog file="wiki" text="right=#mid(body, tokens.pos[x]+tokens.len[x], len(body))#">
					<cfset body = left(body, tokens.pos[x]-1) & result & mid(body, tokens.pos[x]+tokens.len[x], len(body))>
				</cfif>
			</cfloop>
		</cfif>
				
		<cfreturn body>		

	</cffunction>
	
	<!---
	
	CUSTOMIZE THE METHODS BELOW TO MODIFY YOUR WIKI
	
	See documentation for help.
	
	--->
	
	<cffunction name="render_links" output="false" returnType="string" priority="2" 
				hint="Links are rendered using [[url]] or [[url|label]] format. <br>URLs can be:<ul><li>external, fully qualified URLs;</li><li>links within this site in the form /content.cfm/path/to/page;</li><li>or internal URLs to this wiki in the form of [[pagename]]</li></ul>">
		<cfargument name="string" type="string" required="true">
		<cfargument name="webpath" type="string" required="true" hint="this should point to the HomePage of the wiki">
    <cfargument name="wikiID" type="string" required="false" default="#request.SLCMS.pageParams.DocID#" hint="defaults to the DocID which should be the Home Page of the wiki pages">
		
		<!--- First test, URLS in the form of [[label]] --->
		<cfset var matches = reFindAll("\[\[[^<>]+?\]\]",arguments.string)>
		<cfset var x = "">
		<cfset var match = "">
		<cfset var label = "">
		<cfset var location = "">
		<cfset var newString = "">
    <cfset var locationList = "" />
		<cfset var checklabelquery = '' />
		
		<cfif matches.pos[1] gt 0>
			<cfloop index="x" to="1" from="#arrayLen(matches.pos)#" step="-1">
				<cfset match = mid(arguments.string, matches.pos[x], matches.len[x])>
				<!--- remove [[ and ]] --->
				<cfset match = mid(match, 3, len(match)-4)>
				<!--- Two kinds of matches: path or path|label
				Also, path can be a URL or a internal match. --->
				<cfif listLen(match, "|") gte 2>
					<cfset label = listLast(match, "|")>
					<cfset location = listFirst(match, "|")>
				<cfelse>
					<cfset label = match>
					<cfset location = match>
				</cfif>
				<cfset location = replaceNoCase(location,"?","","all") />
				
				<!--- external link --->
				<cfif findNoCase("http", location)>
					<cfset newString = '<a href="#location#">#label#</a>' />
				<cfelse>
		    	<!--- see if this page exists already --->
	        <cfset checklabelquery = request.wiki_code.sel_checklabel(checklabel="#location#", wikiID="#arguments.wikiID#" ) >
	        <!--- if it exists in the database... --->
	        <cfif checklabelquery.recordcount>
	          <!--- make a straight link to the doc --->
						<cfset newString = '<a href="#arguments.webpath##application.SLCMS.Core.PageStructure.EncodeNavName(location)#">#label#</a>' />
	        <cfelse>		
						<!--- make a new doc string, the name with indicators to get there --->
						<cfset newString = '<a href="#arguments.webpath##application.SLCMS.Core.PageStructure.EncodeNavName(location)#?task=create" class="wikiEditLink">#label#</a>' />
					</cfif>


				</cfif>
				
				<cfif matches.pos[x] gt 1>
					<cfset arguments.string = left(arguments.string, matches.pos[x]-1) & newString & 
						mid(arguments.string, matches.pos[x]+matches.len[x], len(arguments.string))>
				<cfelse>
					<cfset arguments.string = newString & 
						mid(arguments.string, matches.pos[x]+matches.len[x], len(arguments.string))>
				</cfif>
								
			</cfloop>
		</cfif>
	
		<cfreturn arguments.string>
	</cffunction>

	<cffunction name="render_headers" output="false" returnType="string" priority="30" hint="Use [h]...[/h] for headings. Example: [h]Foo[/h].<br>To create a smaller headers, you can add more Hs, for up to 6. So for a &lt;h3&gt; tag, use [hhh]">
		<cfargument name="string" type="string" required="true">
		<cfargument name="webpath" type="string" required="true">

		<cfset arguments.string =  rereplaceNoCase(arguments.string,"\[h\](.*?)\[/h\]", "<h1>\1</h1>", "all")>
		<cfset arguments.string =  rereplaceNoCase(arguments.string,"\[hh\](.*?)\[/hh\]", "<h2>\1</h2>", "all")>
		<cfset arguments.string =  rereplaceNoCase(arguments.string,"\[hhh\](.*?)\[/hhh\]", "<h3>\1</h3>", "all")>
		<cfset arguments.string =  rereplaceNoCase(arguments.string,"\[hhhh\](.*?)\[/hhhh\]", "<h4>\1</h4>", "all")>
		<cfset arguments.string =  rereplaceNoCase(arguments.string,"\[hhhhh\](.*?)\[/hhhhh\]", "<h5>\1</h5>", "all")>
		<cfset arguments.string =  rereplaceNoCase(arguments.string,"\[hhhhhh\](.*?)\[/hhhhhh\]", "<h6>\1</h6>", "all")>
		
		<cfreturn arguments.string>	
	</cffunction>

	<cffunction name="render_bold" output="false" returnType="string" priority="32" hint="Use [b]...[/b] for bold. Example: [b]Foo[/b].">
		<cfargument name="string" type="string" required="true">
		<cfargument name="webpath" type="string" required="true">
<!--- 
		<cfset arguments.string =  rereplaceNoCase(arguments.string,"\[b\](.*?)\[/b\]", "<strong>\1</strong>", "all")>
 --->		
		<cfset arguments.string =  replaceNoCase(arguments.string,"[b]", "<strong>", "all")>
		<cfset arguments.string =  replaceNoCase(arguments.string,"[/b]", "</strong>", "all")>
		<cfreturn arguments.string>	
	</cffunction>

	<cffunction name="render_image" output="false" returnType="string" priority="41" hint="Use [img]...[/img] to show an uploaded image of the indicated filename. Example: [img]logo.gif[/img].">
		<cfargument name="string" type="string" required="true">
		<cfargument name="webpath" type="string" required="true">
		<cfset arguments.string =  replaceNoCase(arguments.string,"[img]", '<img src="#application.SLCMS.Config.base.RootURL##application.SLCMS.Config.base.ResourcesImageRelPath#image/', "all")>
		<cfset arguments.string =  replaceNoCase(arguments.string,"[/img]", '">', "all")>
		<cfreturn arguments.string>	
	</cffunction>

	<cffunction name="render_italics" output="true" returnType="string" priority="32" hint="Use [i]...[/i] for italics. Example: [i]Foo[/i].">
		<cfargument name="string" type="string" required="true">
		<cfargument name="webpath" type="string" required="true">

		<cfset arguments.string =  rereplaceNoCase(arguments.string,"\[i\](.*?)\[/i\]", "<i>\1</i>", "all")>

		<cfreturn arguments.string>	
	</cffunction>

	<cffunction name="render_code" output="false" returnType="string" priority="54" 
			hint="Use [code] for code. Example: [code]&lt;!-- Foo--&gt;[/code]">
		<cfargument name="string" type="string" required="true">
		<cfargument name="webpath" type="string" required="true">
		<cfset var match = 0 />
		<cfset var strMatch = "" />
		
		<cfloop condition="true">
			<!--- find the next code block in the string --->
			<cfset match = reFindNoCase("(?m)(\[code\])(.*?)(\[/code\])", arguments.string, 0, true) />
			
			<!--- if no matches, break --->
			<cfif NOT match.len[1]>
				<cfbreak />
			</cfif>
			
			<cfset strMatch = Trim(Mid(arguments.string, match.pos[3], match.len[3])) />
			<cfset strMatch = replace(strMatch, "<", "&lt;", "all") />
			<cfset strMatch = replace(strMatch, ">", "&gt;", "all") />
			<cfset strMatch = replace(strMatch, chr(13), "<br>", "all") />
			
			<cfset arguments.string = Mid(arguments.string, 1, match.pos[1] - 1) & "<div class=""code"">" & strMatch & "</div>" & Mid(arguments.string, match.pos[4] + match.len[4], Len(arguments.string) - match.pos[4] + match.len[4]) />
			
		</cfloop>
		
		<cfreturn arguments.string>
	</cffunction>
	
	<cffunction name="render_bullets" output="false" returnType="string" priority="22" hint="Bulleted lists can be created using an asterisk: *">
		<cfargument name="string" type="string" required="true">
		<cfargument name="webpath" type="string" required="true">

		<!--- This should REALLY be a regex. But I couldn't figure it out. --->
		<cfset var newStr = "" />
		<cfset var inList = false />
		<cfset var line = "" />
		<cfset var shortLine = "" />
		
		<cfloop index="line" list="#trim(arguments.string)#" delimiters="#chr(13)#">
			<cfset shortLine = trim(line)>
			<cfif left(shortLine,1) is "*">
				<cfif not inList>
					<cfset newStr = newStr & "<ul>">
					<cfset inList = true>
				</cfif>
				<cfset newStr = newStr & "<li>" & removeChars(shortLine, 1, 1) & "</li>">
			<cfelse>
				<cfif inList>
					<cfset newStr = newStr & "</ul>">
					<cfset inList = false>
				</cfif>
				<cfset newStr = newStr & line & chr(13)>
			</cfif>
			<!--- 
			<cfset newStr = newStr & chr(13)>
			 --->
		</cfloop>
		<cfif inList>
			<cfset newStr = newStr & "</ul>">
		</cfif>

		<cfreturn newStr>	
	</cffunction>

	<cffunction name="render_orderedlists" output="false" returnType="string" priority="21" hint="Ordered lists can be created using a hash mark: ##">
		<cfargument name="string" type="string" required="true">
		<cfargument name="webpath" type="string" required="true">

		<cfset var newStr = "">
		<cfset var inList = false>
		<cfset var line = "">
		<cfset var shortLine = "" />
		
		<cfloop index="line" list="#trim(arguments.string)#" delimiters="#chr(13)#">
			<cfset shortLine = trim(line)>
			<cfif left(shortLine,1) is "##">
				<cfif not inList>
					<cfset newStr = newStr & "<ol>">
					<cfset inList = true>
				</cfif>
				<cfset newStr = newStr & "<li>" & removeChars(shortLine, 1, 1) & "</li>">
			<cfelse>
				<cfif inList>
					<cfset newStr = newStr & "</ol>">
					<cfset inList = false>
				</cfif>
				<cfset newStr = newStr & line & chr(13)>
			</cfif>
			<!--- 
			<cfset newStr = newStr & chr(13)>
			 --->
		</cfloop>
		<cfif inList>
			<cfset newStr = newStr & "</ol>">
		</cfif>
		
		<cfreturn newStr>	
	</cffunction>
	
	<cffunction name="render_paragraphs" output="false" returnType="string" priority="1" hint="Paragraph: Any double line break will be rendered as a new paragraph.">
		<cfargument name="string" type="string" required="true">
		<cfargument name="webpath" type="string" required="true">
		
		<!--- kym's go at it..... --->
		<!--- replace all CR with a <br> and then replace <br> pairs with reversed para tags and wrap whole --->
		<cfset var newString = replaceNoCase(arguments.string, Chr(13), "<br/>", "all")>		
		<cfset newString = replaceNoCase(newString, "<br/><br/>", "</p><p>", "all")>
<!--- 
		<cfset newString = replaceNoCase(arguments.string, Chr(13), "</p><p>", "all")>		
		<cfset newString = replaceNoCase(newString, "<p></p>", "<p>&nbsp;</p>", "all")>
 --->
		<!--- 
		<cfset newString = replaceNoCase(newString, "<br/><br/>", "&nbsp;</p><p>", "all")>
		 --->
		<cfset newString = "<p>" & newString & "</p>">		

		<cfreturn newString>	
		<!--- 	
		<cfscript>
		/**
		 * Returns a XHTML compliant string wrapped with properly formatted paragraph tags.
		 * 
		 * @param string 	 String you want XHTML formatted. 
		 * @param attributeString 	 Optional attributes to assign to all opening paragraph tags (i.e. style=""font-family: tahoma""). 
		 * @return Returns a string. 
		 * @author Jeff Howden (jeff@members.evolt.org) 
		 * @version 1.1, January 10, 2002 
		 */
		 
		var attributeString = '';
		var returnValue = '';
		if(ArrayLen(arguments) GTE 3) attributeString = ' ' & arguments[3];
		if(Len(Trim(string)))
		    returnValue = '<p' & attributeString & '>' & Replace(string, Chr(13) & Chr(10), '</p>' & Chr(13) & Chr(10) & '<p' & attributeString & '>', 'ALL') & '</p>';
		return returnValue;
		</cfscript>

		<cfscript>
		/**
		 * An &quot;enhanced&quot; version of ParagraphFormat.
		 * Added replacement of tab with nonbreaking space char, idea by Mark R Andrachek.
		 * Rewrite and multiOS support by Nathan Dintenfas.
		 * 
		 * @param string 	 The string to format. (Required)
		 * @return Returns a string. 
		 * @author Ben Forta (ben@forta.com) 
		 * @version 3, June 26, 2002 
		 */
		
		//first make Windows style into Unix style
		var str = replace(arguments.string,chr(13)&chr(10),chr(10),"ALL");
		//now make Macintosh style into Unix style
		str = replace(str,chr(13),chr(10),"ALL");
		//now fix tabs
		str = replace(str,chr(9),"&nbsp;&nbsp;&nbsp;","ALL");
		//now return the text formatted in HTML
		//return replace(str,chr(10),"<br />","ALL");
		</cfscript>
		--->
		
	</cffunction>
	<cffunction name="render_strikethrough" output="false" returnType="string" priority="51" hint="Use [s]...[/s] for strikethrough. Example: [s]Foo[/s]">
	   <cfargument name="string" type="string" required="true">
	   <cfargument name="webpath" type="string" required="true">
	
	   <cfset arguments.string = rereplaceNoCase(arguments.string,"\[s\](.*?)\[/s\]", "<span style=""text-decoration:line-through;display:inline;"">\1</span>", "all")>
	   
	   <cfreturn arguments.string>   
	</cffunction>
	
	<cffunction name="render_subscript" output="false" returnType="string" priority="53" hint="Use [sub]...[/sub] for subscript. Example: [sub]Foo[/sub]">
	   <cfargument name="string" type="string" required="true">
	   <cfargument name="webpath" type="string" required="true">
	
	   <cfset arguments.string = rereplaceNoCase(arguments.string,"\[sub\](.*?)\[/sub\]", "<sub>\1</sub>", "all")>
	   
	   <cfreturn arguments.string>   
	</cffunction>
	
	<cffunction name="render_superscript" output="false" returnType="string" priority="52" hint="Use [sup]...[/sup] for superscript. Example: [sup]Foo[/sup]">
	   <cfargument name="string" type="string" required="true">
	   <cfargument name="webpath" type="string" required="true">
	
	   <cfset arguments.string = rereplaceNoCase(arguments.string,"\[sup\](.*?)\[/sup\]", "<sup>\1</sup>", "all")>
	   
	   <cfreturn arguments.string>   
	</cffunction>

	<cffunction name="render_textcolor" output="false" returnType="string" priority="3" hint="Use [<i>color</i>]...[/<i>color</i>] to color text. Example: [red]Foo[/red]. <br>Supported colors: red, blue, green, purple, teal, silver">
	   <cfargument name="string" type="string" required="true">
	   <cfargument name="webpath" type="string" required="true">
	
	   <cfset arguments.string = rereplaceNoCase(arguments.string,"\[red\](.*?)\[/red\]", "<span style=""color:red;"">\1</span>", "all")>
	   <cfset arguments.string = rereplaceNoCase(arguments.string,"\[green\](.*?)\[/green\]", "<span style=""color:green;"">\1</span>", "all")>
	   <cfset arguments.string = rereplaceNoCase(arguments.string,"\[blue\](.*?)\[/blue\]", "<span style=""color:blue;"">\1</span>", "all")>
	   <cfset arguments.string = rereplaceNoCase(arguments.string,"\[purple\](.*?)\[/purple\]", "<span style=""color:purple;"">\1</span>", "all")>
	   <cfset arguments.string = rereplaceNoCase(arguments.string,"\[teal\](.*?)\[/teal\]", "<span style=""color:teal;"">\1</span>", "all")>
	   <cfset arguments.string = rereplaceNoCase(arguments.string,"\[silver\](.*?)\[/silver\]", "<span style=""color:silver;"">\1</span>", "all")>
	   
	   <cfreturn arguments.string>   
	</cffunction>

<!---
 Returns all the matches of a regular expression within a string.
 
 @param regex 	 Regular expression. (Required)
 @param text 	 String to search. (Required)
 @return Returns a structure. 
 @author Ben Forta (ben@forta.com) 
 @version 1, July 15, 2005 
--->
<cffunction name="reFindAll" output="false" returnType="struct">
   <cfargument name="regex" type="string" required="true">
   <cfargument name="text" type="string" required="true">

   <!--- Define local variables --->	
   <cfset var results=structNew()>
   <cfset var pos=1>
   <cfset var subex="">
   <cfset var done=false>
	
   <!--- Initialize results structure --->
   <cfset results.len=arraynew(1)>
   <cfset results.pos=arraynew(1)>

   <!--- Loop through text --->
   <cfloop condition="not done">

      <!--- Perform search --->
      <cfset subex=reFind(arguments.regex, arguments.text, pos, true)>
      <!--- Anything matched? --->
      <cfif subex.len[1] is 0>
         <!--- Nothing found, outta here --->
         <cfset done=true>
      <cfelse>
         <!--- Got one, add to arrays --->
         <cfset arrayappend(results.len, subex.len[1])>
         <cfset arrayappend(results.pos, subex.pos[1])>
         <!--- Reposition start point --->
         <cfset pos=subex.pos[1]+subex.len[1]>
      </cfif>
   </cfloop>

   <!--- If no matches, add 0 to both arrays --->
   <cfif arraylen(results.len) is 0>
      <cfset arrayappend(results.len, 0)>
      <cfset arrayappend(results.pos, 0)>
   </cfif>

   <!--- and return results --->
   <cfreturn results>
</cffunction>
	
</cfcomponent>