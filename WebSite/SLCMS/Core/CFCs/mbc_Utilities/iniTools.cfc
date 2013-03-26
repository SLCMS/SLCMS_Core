<!--- iniTools.cfc --->
<!---  --->
<!--- CFC containing functions that relate to the standard mbc ini/structure manipulators --->
<!---  --->
<!--- &copy; mort bay communications 2007 --->
<!---  --->
<!--- Created:  18th Mar 2007 by Kym K --->
<!--- Modified:  1st Sep 2007 -  1st Sep 2007 by Kym K, added code to handle value strings with  "=" in them --->
<!--- Modified:  4th Sep 2007 -  4th Sep 2007 by Kym K, added code to handle partrial trimming for strings with  " " in them --->
<!--- Modified: 11th Jan 2009 - 11th Jan 2009 by Kym K, changed behaviour for CF8 as ReadLines2Query does not work on Win2008 --->
<!--- Modified:  1st Dec 2009 -  1st Dec 2009 by Kym K, added "StringTerminator" as alternative name for the string delim in partial strings --->
<!--- modified: 17th Jan 2010 - 17th Jan 2010 by Kym K - mbcomms: added iniSection2List --->


<cfcomponent
	displayname="ini File Tools"
	output="no"
	hint="sets and gets structures to/from structures">

<cffunction name="ini2Struct" output="no" returntype="struct" 
	displayname="ini file to structure"
	hint="reads named ini file into structure, copies in named structure if it has content and returns the combo">
	<!--- this function needs an ini file path, the supplied structure is optional --->
	<cfargument name="FilePath" type="string" default="">	<!--- this is the full path to the ini file --->
	<cfargument name="ipStructName" type="string" default="">	<!--- this is the name of the structure the ini file is fed into --->
	<cfargument name="TrimWhiteSpace" type="string" default="Yes">	<!--- flag to clean as we go, partially trim or no trim [yes|partial|no] --->

	<cfset var strTempStruct = StructNew() />	<!--- this will be the returned structure --->
	<cfset var ReadLineLines = "" />	<!--- hide the line reading query --->
	<cfset var theSections = "" />	<!--- struct to carry the sections if read by CF8+ --->
	<cfset var CurrentSection = "">						<!--- temp store --->
	<cfset var thisSectionKeys = "" />
	<cfset var thisLine = "" />
	<cfset var ret = "" />
	<cfset var item = "" />
	<cfset var partialDelim = "" />	<!--- carries the delimiter if we have one --->
	<cfset var theDelimPos = 0 />	<!--- where it sits in the string --->
	<cfset var value = "" />
	<cfset var SaveFlag = True />	<!--- flags if to store this read item --->

	<cfset strTempStruct.data = StructNew() />	<!--- this will be the returned data structure --->
	<cfset strTempStruct.error = StructNew() />	<!--- this will be the returned error structure --->
	<cfset strTempStruct.Error.errorCode = 0 />
	<cfset strTempStruct.Error.errorText = "" />
	
	<cfif len(arguments.FilePath) and FileExists(arguments.FilePath)>
	
<!--- 		
		<cfdump var="#server#" expand="false"><br>
		<cfdump var="#GetProfileSections(arguments.FilePath)#" expand="false">
 --->
		<!--- work out if we can use our quick cfx tag to read the file or have to do it the hard way --->
		<cfif 1 eq 1 or server.mbc_Utility.CFConfig.BaseVersion gte 8>
			<!--- we might be running 64 bit so find the sections using the new tag and loop over them --->
			<cfset theSections = GetProfileSections(arguments.FilePath) />
			<!--- see if the supplied destination structure has content and if so copy it in --->
			<cftry>
				<!--- see if we have an input structuse with stuff in it --->
				<cfif len(ipStructName) and not StructIsEmpty(evaluate("#arguments.ipStructName#"))>
					<cfset strTempStruct.data = Duplicate(evaluate("#arguments.ipStructName#"))>
				</cfif>
			<cfcatch></cfcatch>
			</cftry>
			<!--- then loop over our read structure --->
			<cfloop collection="#theSections#" item="CurrentSection">
				<cfset strTempStruct.data["#CurrentSection#"] = StructNew()>
				<!--- and over the items in each section --->
				<cfloop list="#theSections[CurrentSection]#" index="item">
					<cfset value = GetProfileString(arguments.FilePath, CurrentSection, item) /> 
					<!--- then produce the value which is dependent on how we are trimming white space --->
					<cfif arguments.TrimWhiteSpace eq "No">
						<!--- don't trim white space at all --->
						<cfset value = listFirst(value, ";") />	<!--- strip away comment if we have it --->
					<cfelseif arguments.TrimWhiteSpace eq "Partial">
						<!--- only trim white space outside the specified delimiter if supplied --->
						<!--- see if this item is the delimiter definition itself --->
						<cfif item eq "partialDelimiter" or item eq "StringTerminator">
							<cfset partialDelim = rtrim(listFirst(value, ";")) />	<!--- strip away comment if we have it --->
							<cfset SaveFlag = False />
						<cfelse>
							<!--- its not the definition so trim according to the delim supplied, if any. 
										Note we ignore normal comment trimming as value could have a  ";" in it such a &nbsp;
										but if there is no spec then trim as normal --->
							<cfif partialDelim neq "">
								<cfset theDelimPos = Find(partialDelim, value) />	<!--- find where the delimiter text string lives --->
								<cfif theDelimPos gt 1>
									<cfset value = left(value, theDelimPos-1) />	<!--- the value up to that position --->
								<cfelse>
									<!---  no delim so take the value trimmmed like normal --->
									<cfset value = trim(listFirst(value, ";")) />	<!--- strip comments away if we have them and any the spaces that result --->
								</cfif>
							<cfelse>
								<!---  no delim so take the value trimmmed like normal --->
								<cfset value = trim(listFirst(value, ";")) />	<!--- strip comments away if we have them and any the spaces that result --->
							</cfif>
						</cfif>
					<cfelse>
						<!--- no command so trim white space fully --->
						<cfset value = trim(listFirst(value, ";")) />	<!--- strip comments away if we have them and any the spaces that result --->
					</cfif>
					<cfset strTempStruct.data["#CurrentSection#"]["#item#"] = value />
				</cfloop>
			</cfloop>
<!--- 
		<cfdump var="#strTempStruct.data#" expand="false"><br>
	
		<cfabort>
	
 --->				
		<cfelse>
			<!--- read the file with the CFX tag and loop of the query --->
			<cfx_Readlines2Query file="#arguments.FilePath#" maxlines="9999" skipblanklines="0">
			<cfif len(ReadLineError) eq 0 or ReadLineError eq "End of File">
				<!--- see if the supplied destination structure has content and if so copy it in --->
				<cfif len(ipStructName) and not StructIsEmpty(evaluate("#arguments.ipStructName#"))>
					<cfset strTempStruct.data = Duplicate(evaluate("#arguments.ipStructName#"))>
				</cfif>
<!--- 				
				<cfoutput><cfdump var="#strTempStruct#"></cfoutput>
 --->				
				<!--- loop over the result set and turn it into a structure --->
				<cfloop query="ReadLineLines">
					<cfset SaveFlag = True />	<!--- reste the flag to save data as it can be changed each time round loop --->
					<cfset thisLine = trim(ReadLineLines.line) />
					<cfif Left(thisLine, 1) eq "[">	<!--- this line is a section specifier --->
						<cfset CurrentSection = mid(thisLine, 2, Len(thisLine)-2)>
						<cfset "strTempStruct.data.#CurrentSection#" = StructNew()>
						<!--- reset the partial delimiter until it gets set for this section --->
						<cfset partialDelim = "" />
					<cfelseif trim(thisLine) eq "">	<!--- this is a blank line so ignore --->
					<cfelseif Left(thisLine, 1) eq ";"> <!--- this is a comment line so ignore --->
					<cfelse>
						<!--- this is a simple line to go into the relevant structure --->
						<!--- first work out the item --->
						<cfset item = trim(listFirst(thisLine, "="))>	<!--- the item, they can't have wrapping spaces so always trim --->
						<cfset value = listRest(thisLine, "=") />	<!--- the value without any processing or trimming --->
						<!--- then get the value which is dependent on how we are trimming white space --->
						<cfif arguments.TrimWhiteSpace eq "No">
							<!--- don't trim white space at all --->
							<cfset value = listFirst(value, ";") />	<!--- strip away comment if we have it --->
						<cfelseif arguments.TrimWhiteSpace eq "Partial">
							<!--- only trim white space outside the specified delimiter if supplied --->
							<!--- see if this item is the delimiter definition itself --->
							<cfif item eq "partialDelimiter" or item eq "StringTerminator">
								<cfset partialDelim = rtrim(listFirst(value, ";")) />	<!--- strip away comment if we have it --->
								<cfset SaveFlag = False />
							<cfelse>
								<!--- its not the definition so trim according to the delim supplied, if any. 
											Note we ignore normal comment trimming as value could have a  ";" in it such a &nbsp;
											but if there is no spec then trim as normal --->
								<cfif partialDelim neq "">
									<cfset theDelimPos = Find(partialDelim, value) />	<!--- find where the delimiter text string lives --->
									<cfif theDelimPos gt 1>
										<cfset value = left(value, theDelimPos-1) />	<!--- the value up to that position --->
									<cfelse>
										<!---  no delim so take the value trimmmed like normal --->
										<cfset value = trim(listFirst(value, ";")) />	<!--- strip comments away if we have them and any the spaces that result --->
									</cfif>
								<cfelse>
									<!---  no delim so take the value trimmmed like normal --->
									<cfset value = trim(listFirst(value, ";")) />	<!--- strip comments away if we have them and any the spaces that result --->
								</cfif>
							</cfif>
						<cfelse>
							<!--- no command so trim white space fully --->
							<cfset value = trim(listFirst(value, ";")) />	<!--- strip comments away if we have them and any the spaces that result --->
						</cfif>

						<cfif len(CurrentSection) and SaveFlag>
							<cfset ret = StructInsert(strTempStruct.data[CurrentSection], item, value) />
						</cfif>
					</cfif>
				</cfloop>
			<cfelse>
				<cfset strTempStruct.Error.errorcode = -1 />
				<cfset strTempStruct.Error.errorText = ReadLineError />
			</cfif>
		</cfif>
	<cfelse>
		<cfset strTempStruct.Error.errorcode = -1 />
		<cfset strTempStruct.Error.errorText = "No path Supplied" />
	</cfif>

	<cfreturn strTempStruct  />
</cffunction>

<cffunction name="Struct2ini" output="No" returntype="struct" 
	displayname="structure to ini file"
	hint="writes named structure into named ini file">
	<!--- this function needs an ini file path, the supplied structure is optional --->
	<cfargument name="FilePath" type="string" default="">	<!--- this is the full path to the ini file --->
	<cfargument name="StructName" type="string" default="">	<!--- this is the name of the structure the ini file is created from --->

	<cfset var ErrorRet = StructNew() />
	<cfset var strTmpIniStruct = StructNew() />	<!--- this will be the returned structure --->
	<cfset var txtOPFile = "" />
	<cfset var BadWrite = False />
	<cfset var CRLF = chr(13)&chr(10) />
	<cfset var listSectionList = "" />
	<cfset var listSectionContentsList = "" />
	
	<cfset ErrorRet.ErrorCode = 0 />
	<cfset ErrorRet.ErrorString = "" />


	<cfif len(arguments.FilePath)>
		<!--- now we make an ini file from the structure --->
		<cfset strTmpIniStruct = StructCopy(arguments.rStructName) />
		<!--- make a list of the sections in the ini file from the structure --->
		<cfset listSectionList = StructKeyList(strTmpIniStruct) />
		<cfloop index="thisSection" list="#listSectionList#">
			<cfif IsStruct(strTmpIniStruct[thisSection])>	<!--- only do it if the variable is a structure, ie not top level --->
				<cfset txtOPFile = txtOPFile & "[#thisSection#]#CRLF#">
				<cfset listSectionContentsList = StructKeyList(strTmpIniStruct[thisSection]) />
				<cfloop index="thisSectionContents" list="#listSectionContentsList#">
					<cfset txtOPFile = txtOPFile & "#thisSectionContents#=#strTmpIniStruct[thisSection][thisSectionContents]##CRLF#" />
				</cfloop>
				<cfset txtOPFile = txtOPFile & CRLF />
			</cfif>
		</cfloop>
		<!--- now we write the ini file --->
		<cftry>
			<cffile action="WRITE" file="#arguments.FilePath#" output="#txtOPFile#" addnewline="No" />
			<cfcatch type="Any">
				<cfset ErrorRet.ErrorCode = -1 />
				<cfset ErrorRet.ErrorString = "File Write Failed" />
			</cfcatch>
		</cftry>
	<cfelse>
		<cfset ErrorRet.ErrorCode = 1 />
		<cfset ErrorRet.ErrorString = "No path Supplied or Bad Structure" />
	</cfif>
		
</cffunction>

<cffunction name="iniSection2List" output="No" returntype="struct" access="public"
	displayname="iniSection 2 List"
	hint="reads a section of an ini file and returns the keys as a list inside the standard return structure"
	>
	<!--- this function needs an ini file path, the supplied structure is optional --->
	<cfargument name="FilePath" type="string" default="" hint="this is the full path to the ini file">
	<cfargument name="SectionName" type="string" default="" hint="this is the name of the required section in the ini file">
	<cfargument name="TrimWhiteSpace" type="string" default="Yes" hint="flag to clean as we go, partially trim or no trim [yes|partial|no]">

	<!--- now all of the var declarations, first the arguments which need manipulation --->
	<cfset var theFilePath = trim(arguments.FilePath) />
	<cfset var theSectionName = trim(arguments.SectionName) />
	<!--- now vars that will get filled as we go --->
	<cfset var lcntr = 0 />	<!--- temp loop counter --->
	<cfset var thisKey = "" />	<!--- temp/throwaway var --->
	<cfset var temps = StructNew() />	<!--- temp/throwaway array --->
	<cfset var retINIstruct = StructNew() />	<!--- temp/throwaway structure --->
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorContext = "iniTools CFC: iniSection2List() " />
	<cfset ret.error.ErrorText = "" />
	<cfset ret.error.ErrorExtra = "" />
	<cfset ret.Data = "" />	<!--- and no data yet --->

		<!--- validation --->
	<cfif not (len(theFilePath) and FileExists(theFilePath))>
		<!--- this is the error code --->
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 1) />
		<cfset ret.error.ErrorText = ret.error.ErrorText & "Oops! Invalid path supplied. Was supplied with: #theFilePath#<br>" />
	<cfelse>
		<cfif theSectionName eq "">
			<!--- this is the error code --->
			<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 2) />
			<cfset ret.error.ErrorText = ret.error.ErrorText & "Oops! No Section Name supplied. Can only list a single ini file section<br>" />
		<cfelse>
			<!--- validated so go for it --->
			<!--- wrap the whole thing in a try/catch in case something breaks --->
			<cftry>
				<!--- firstly grab the ini file contents as a whole --->
				<cfset retINIstruct = ini2Struct(FilePath="#theFilePath#", TrimWhiteSpace="#arguments.TrimWhiteSpace#") />
				<cfif retINIstruct.error.errorcode eq 0>
					<cfif StructKeyExists(retINIstruct.data, "#theSectionName#")>
						<cfset temps = retINIstruct.data["#theSectionName#"] />
						<!--- now we have a struct of the section keys so lets load each one into our output list --->
						<cfset ret.Data = StructKeyList(retINIstruct.data["#theSectionName#"]) />
						<!--- 
						<cfloop collection="#temps#" item="thisKey">
							<cfset ret.Data = ListAppend(ret.Data, thisKey) />
						</cfloop>
						 --->
					<cfelse>
						<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 6) />
						<cfset ret.error.ErrorText = ret.error.ErrorText & "The supplied Section name did not return anything. Name was: #theSectionName#<br>" />
					</cfif>
				<cfelse>
					<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 64) />
					<cfset ret.error.ErrorText = ret.error.ErrorText & "ini2Struct Errored. Error was: #retINIstruct.error.ErrorText#<br>" />
				</cfif>
			<cfcatch type="any">
				<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 128) />
				<cfset ret.error.ErrorText = ret.error.ErrorContext & ' Trapped. Site: #application.SLCMS.config.base.SiteName#, error message was: #cfcatch.message#, error detail was: #cfcatch.detail#' />
				<cfset ret.error.ErrorExtra =  cfcatch.TagContext />
				<cfif isArray(ret.error.ErrorExtra) and StructKeyExists(ret.error.ErrorExtra[1], "Raw_Trace")>
					<cfset ret.error.ErrorText = ret.error.ErrorText & ", Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#" />
				</cfif>
				<cflog text='#ret.error.ErrorText# - ret.error.ErrorCode: #ret.error.ErrorCode# - Time: #DateFormat(Now(),"YYYYMMDD")#-#TimeFormat(now(),"HH:mm:ss")#'  file="#Application.Logging.theSiteLogName#" type="Error" application = "yes">
				<cfif application.SLCMS.config.debug.debugmode>
					<cfoutput>#ret.error.ErrorContext#</cfoutput> Trapped - error dump:<br>
					<cfdump var="#cfcatch#">
				</cfif>
			</cfcatch>
			</cftry>
		</cfif>	<!--- end: section name supplied test --->
	</cfif>	<!--- end: valid filename --->

	<!--- return our data structure --->
	<cfreturn ret  />
</cffunction>
	
</cfcomponent>
	
	
	