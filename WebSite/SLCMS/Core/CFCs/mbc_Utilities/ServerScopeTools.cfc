<!--- ServerScopeTools.cfc --->
<!---  --->
<!--- CFC containing functions that relate to the standard mbc server scope structures --->
<!--- Part of the mbcomms Standard Site Architecture toolkit --->
<!---  --->
<!--- copyright: mbcomms 2010 --->
<!---  --->
<!--- Created:  10th Feb 2007 by Kym K --->
<!--- Modified: 10th Feb 2007 - 15th Feb 2007 by Kym K - mbcomms, working on it --->
<!--- Modified: 18th Mar 2007 - 18th Mar 2007 by Kym K - mbcomms, working on it --->
<!--- Modified: 29th Mar 2007 - 30th Mar 2007 by Kym K - mbcomms, moved to new site and tested from deep, added root paths as BD can't pick properly --->
<!--- Modified:  9th Oct 2007 -  9th Oct 2007 by Kym K - mbcomms, added setOSPathDelim() function to grab the path delimiter for this OS and make it easily available --->
<!--- Modified: 17th Oct 2007 - 17th Oct 2007 by Kym K - mbcomms, oops! setMachineName() returntype was set to void but tried to return thename as string, now is returntype="string" :-)  --->
<!--- Modified: 11th Jan 2009 - 11th Jan 2009 by Kym K - mbcomms, added code to get the versions of OS and CF into useful struct --->
<!--- Modified: 15th Aug 2010 - 29th Aug 2010 by Kym K - mbcomms, changed the machine name gather to a pure java method 
																																	so no more need for tricks in mapping ini file as we will always have a name
																																	also somewhere along the line all cfml platforms now use "/" for OS paths, now need OS path delimiter just for incoming function results --->
<!--- Modified: 27th Jul 2012 - 27th Jul 2012 by Kym K - mbcomms, specific version for running in SLCMS V3+ under CFWheels --->


<cfcomponent
	displayname="Server Scope Manager"
	output="yes"
	hint="set and gets the mbc standard server scope vars">

	<cffunction name="Init" output="No" returntype="any">
		<cfset var ret = "" />
		<!--- make sure the server structures are there --->
		<cfif not StructKeyExists(server, "mbc_Utility")>
			<cfset server.mbc_Utility = StructNew() />
		</cfif>
		<cfif not StructKeyExists(server.mbc_Utility, "ServerConfig")>
			<cfset server.mbc_Utility.ServerConfig = StructNew() />
		</cfif>
		<cfif not StructKeyExists(server.mbc_Utility, "CFConfig")>
			<cfset server.mbc_Utility.CFConfig = StructNew() />
		</cfif>
		<cfif not StructKeyExists(server.mbc_Utility, "OSConfig")>
			<cfset server.mbc_Utility.OSConfig = StructNew() />
		</cfif>
		<cfset ret = setMachineName() />	<!--- load in the machine name --->
		<cfset ret = setOSPathDelim() />	<!--- Operating System path deliminatr, bit redundant now --->
		<cfset ret = setVersions() />	<!--- versions of the cfml platform,. just in case we are working outside CFW and need to know --->

		<cfreturn server.mbc_Utility.ServerConfig.MachineName />
	</cffunction>
		
	<cffunction name="setMachineName" output="No" returntype="string" 
		displayname="Machine Name Setter"
		hint="finds the machine name and puts into the server scope mbc structure">
		<!--- this function sees what Operating System we are running then grabs the name of the machine/server
					and puts it in the config scope for the other mbc utilities to use --->
		<cfargument name="UseRegistry" type="boolean" default="False" hint="flag to do it the old way, might need the extra bits in mapper depending on platform. Default is do it new way, using java tools">
		<cfargument name="ConfigPath" type="string" default="" hint="If using Registry and old version of BD then we need this: the path to the config files directory">
		<cfargument name="MapperFilename" type="string" default="Config_Mapper.ini" hint="If using Registry and old version of BD then we need this: the file name of the mapping ini file">

		<cfset var grabbedComputerName = "" />
		<cfset var theHost = "" />
		<cfset server.mbc_Utility.ServerConfig.MachineName = "" />
		<cfif not UseRegistry>
			<cfset theHost = createObject( 'java', 'java.net.InetAddress').getLocalHost()>
			<cfset server.mbc_Utility.ServerConfig.MachineName = theHost.getHostName()>
		<cfelseif UseRegistry and server.os.name contains "Windows" and server.coldfusion.productname eq "MX" or server.coldfusion.productname eq "ColdFusion Server">
			<!--- its a Windows machine running MX+ so grab its name from the registry --->
			<cftry>	<!--- we need to test as it might not be a legit registry key --->
				<cfregistry action="GET" branch="HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\ComputerName\ComputerName" entry="ComputerName" type="String" variable="grabbedComputerName">
				<cfset server.mbc_Utility.ServerConfig.MachineName = grabbedComputerName />
			<cfcatch type="Any">
				<cfset server.mbc_Utility.ServerConfig.MachineName = "oops!" />
			</cfcatch>
			</cftry>
		<cfelseif UseRegistry and server.os.name contains "Windows" and server.coldfusion.productname eq "BlueDragon" and ListFirst(server.coldfusion.productversion) eq "6">
			<!--- its a Windows machine running BD 6.x so its name is not in the registry
						as this version of BD does not use the real registry
						so we save the machine name in the mapping ini file under a section
						called [MachineName] with a variable called "ThisMachine" --->
			<cfif right(arguments.ConfigPath, 1) neq "/">
				<cfset arguments.ConfigPath = arguments.ConfigPath & "/" />
			</cfif>
			<cfset mapperPath = "#arguments.ConfigPath##arguments.MapperFilename#" />
			<!--- and grab the machine name --->
			<cfset server.mbc_Utility.ServerConfig.MachineName = trim(listFirst(getProfileString("#mapperPath#", "MachineName", "ThisMachine"), ";")) />
		</cfif>		
		<cfreturn server.mbc_Utility.ServerConfig.MachineName />
	</cffunction>

	<cffunction name="setOSPathDelim" output="No" returntype="void" 
		displayname="Machine Path Delimiter Setter"
		hint="test the Operating System and sets the Path delim to '\' or '/' in App Scope">
		<!--- this function sees what Operating System we are running then puts (back)slash in the config scope for the other mbc utilities to use --->

		<cfif not StructKeyExists(server, "mbc_Utility")>
			<cfset server.mbc_Utility = StructNew() />
		</cfif>
		<cfif not StructKeyExists(server.mbc_Utility, "ServerConfig")>
			<cfset server.mbc_Utility.ServerConfig = StructNew() />
		</cfif>
		
		<cfif server.os.name contains "Windows" and server.coldfusion.productname eq "MX" or server.coldfusion.productname eq "ColdFusion Server">
			<!--- its a Windows machine running MX so go Windows --->
			<cfset server.mbc_Utility.ServerConfig.OSPathDelim = "\" />
		
		<cfelseif server.os.name contains "Windows" and server.coldfusion.productname eq "BlueDragon" and ListFirst(server.coldfusion.productversion) eq "6">
			<!--- its a Windows machine running BD 6.x so go unix --->
			<cfset server.mbc_Utility.ServerConfig.OSPathDelim = "/" />
		<cfelse>
			<!--- assume unix default --->
			<cfset server.mbc_Utility.ServerConfig.OSPathDelim = "/" />
		</cfif>		
	</cffunction>

	<cffunction name="setVersions" output="No" returntype="void" 
		displayname="CF version Setter"
		hint="sets simple flags and numbers for what version of CF we are running">
			
		<cfset server.mbc_Utility.CFConfig.Platform = "" />
		<cfif server.coldfusion.productname eq "ColdFusion Server">
			<cfset server.mbc_Utility.CFConfig.Platform = "ACF" />
		<cfelseif server.coldfusion.productname eq "BlueDragon">
			<cfset server.mbc_Utility.CFConfig.Platform = "BDc" />
		<cfelseif server.coldfusion.productname eq "Railo">	<!--- ToDo: we need to work these two out... --->
			<cfset server.mbc_Utility.CFConfig.Platform = "Rlo" />
		<cfelseif server.coldfusion.productname eq "BlueDragon">
			<cfset server.mbc_Utility.CFConfig.Platform = "oBD" />
		</cfif>
		<cfset server.mbc_Utility.OSConfig.BaseVersion = ListFirst(server.OS.Version, ".") />
		<cfif server.os.arch eq "x86">
			<cfset server.mbc_Utility.OSConfig.BitMode = "32" />
		<cfelseif server.os.arch eq "x64">
			<cfset server.mbc_Utility.OSConfig.BitMode = "64" />
		<cfelse>
			<cfset server.mbc_Utility.OSConfig.BitMode = "" />
		</cfif>
		<cfset server.mbc_Utility.CFConfig.BaseVersion = ListFirst(server.coldfusion.productversion) />
		<cfif server.mbc_Utility.OSConfig.BitMode eq "32">
			<cfset server.mbc_Utility.CFConfig.BitMode = "32" />	<!--- must be 32 --->
		<cfelseif server.mbc_Utility.OSConfig.BitMode eq "64">
			<cfset server.mbc_Utility.CFConfig.BitMode = "32" />	<!--- could be 32 or 64 but how do we work that out? Does it even matter? --->
		<cfelse>
			<cfset server.mbc_Utility.CFConfig.BitMode = "" />	<!--- Who knows. Does it even matter? --->
		</cfif>
		<cfif server.coldfusion.ProductName eq "ColdFusion Server" or server.coldfusion.ProductName eq "Railo">
			<cfset server.mbc_Utility.CFConfig.DumpHasExpandAttribute = True />
		<cfelse>
			<cfset server.mbc_Utility.CFConfig.DumpHasExpandAttribute = False />
		</cfif>
			
	</cffunction>
	
</cfcomponent>

