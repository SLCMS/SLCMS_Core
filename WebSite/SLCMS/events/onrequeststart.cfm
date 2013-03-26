<!--- Place code here that should be executed on the "onRequestStart" event. --->
	<!--- 
	<cfdump var="#this.variables#" expand="false" label="variables">
		

	<cfabort>
	 
	<cfdump var="#server#" expand="false" label="server scope" >
	<cfdump var="#application#" expand="false" label="application scope" >
	<cfabort>
	 --->
	
	<!--- this is the standard Mac/IE handler for untidy form fields --->
<cfif request.CGI.REQUEST_METHOD EQ "POST">
	<cfif cgi.http_user_agent CONTAINS "mac" AND cgi.http_user_agent CONTAINS "msie">
		<cfloop list="#fieldnames#" index="field">
		  <!--- set trimmed values, but not with file fields --->
		  <cfif IsSimpleValue(evaluate(field)) AND field NEQ "filename">
		    <cfset "form.#field#" = #trim(evaluate(field))#>
		  </cfif>
		</cfloop>
	</cfif>
</cfif>

<cfset request.SLCMS["pageParams"] = StructNew() />
<cfset request.SLCMS["flags"] = StructNew() />	<!--- this will carry all the 'flags' as to what we are doing (some might not be boolean) --->

<!--- first we fix our sessions so we have one sessions state across all subSites
			but we can only do a nice trick if we are browsing to a domain name, it won't work for an IP address
			so for IP addresses we have to live with standard sessions --->
<cfif not IsNumeric(replace(cgi.Server_Name,".","","all"))>
	<!--- find out our top url and use that for our session cookies --->
	<cfif application.SLCMS.Sites.Site_0.HomeURL neq "">
		<cfset this.variables.SLCMS.Temp.HomeURL = application.SLCMS.Sites.Site_0.HomeURL />
	<cfelse>
		<cfset this.variables.SLCMS.Temp.HomeURL = cgi.Server_Name />
	</cfif>
	<!--- this Kills Session this.variables.SLCMS When Browser is Closed by making the cookie expire immediately
				and we are forcing domain cookies to work over all subSites/subdomains --->
	<cfcookie name="cfid" domain="#this.variables.SLCMS.Temp.HomeURL#" value="#session.cfid#">
	<cfcookie name="cftoken" domain="#this.variables.SLCMS.Temp.HomeURL#" value="#session.cftoken#">
	<cfcookie name="jsessionid" domain="#this.variables.SLCMS.Temp.HomeURL#" value="#session.sessionid#">
	<!--- note with the above we are not adding the httponly command, we suggest IP address only sites move to domain names or accept the slight risk of Xsite scripting session hijack from js --->
<cfelse>
	<!--- here we are just working with standard sessions --->
	<cfif isdefined("cookie.cfid") and isdefined("cookie.cftoken")>
<!---
		<cfset this.variables.SLCMS.Temp.cfid_local = cookie.cfid />
		<cfset this.variables.SLCMS.Temp.cftoken_local = cookie.cftoken />
		<cfcookie name="cfid" value="#this.variables.SLCMS.Temp.cfid_local#">
		<cfcookie name="cftoken" value="#this.variables.SLCMS.Temp.cftoken_local#">
--->
     <cfheader name="Set-Cookie" value="CFID=#session.CFID#;path=/;HTTPOnly">
     <cfheader name="Set-Cookie" value="CFTOKEN=#session.CFTOKEN#;path=/;HTTPOnly">
	</cfif>
</cfif>

<!--- now we see if we have to restart the application --->
<cfset this.variables.SLCMS.RSdebugString = "<br>" />	<!--- will be added to as things get (possibly) restarted --->
<cfset this.variables.SLCMS.retAppStartGood = True />
<cfset this.variables.SLCMS.retAppStartGood2 = True />
<!--- force the "application.SLCMS.config.startup" struct to be there as well as the "initialization" within it, saves a lot of "StructkeyExists" testing later --->
<cfset this.variables.SLCMS.InitTest =  StructGet("application.SLCMS.config.startup.initialization") />


<!--- this is the code that runs at/before the start of every page --->
<!--- 
			first see if the app start has flagged that we don't have a DB, probably because we have just installed the codebase
			we need to stop everything running until the wizard gets the DB up and where we are right now in terms of page output is flushed content
			ie no output so we will just use the WeNeedToCreateDBTables flag to stop everything until we don't! :-)
			If this.variables.SLCMS.ForceInstallWizard is set then we want to reload the application before we hit the Wizard - THIS IS NOT WORKING!!!!
			 --->
<cfif StructIsEmpty(this.variables.SLCMS.InitTest) or application.SLCMS.config.startup.initialization.WeNeedToCreateDBTables neq True or StructkeyExists(application.SLCMS.config.StartUp, "FlushSerialFromInitWiz")>
	<!--- all that testing means that we are not in any part of Initialization Wizard processing itself
				or we have just finished the Initialization and need to restart normally
				so see if we need to do a flush (this could be refined, codewise but this is easy to read and covers everything) --->
	<cfif application.SLCMS.config.StartUp.FlushSerial neq this.variables.SLCMS.snFlushAppscope or StructKeyExists(application.SLCMS.config.StartUp, "FlushAppGlobals")>
		<cfset this.variables.SLCMS.Initialization.AppWasRestarted = True />
		<cfset application.SLCMS.config.StartUp.WorkMsg = "" />
		<!--- run SLCMS's application start code --->
		<cfset $include(template="SLCMS/events/_onapplicationstart_inc.cfm") />
		<cfset session.SLCMS.user = duplicate(application.SLCMS.Core.UserControl.CreateBlankUserStruct_Session())  />	<!--- make sure of base session --->
		<cfset this.variables.SLCMS.RSdebugString = this.variables.SLCMS.RSdebugString & "Flush requested.<br>Application started from OnRequestStart.<br>" />
		<!--- we have restarted, if coding we might want to reset the session scope --->
		<cfif this.variables.SLCMS.CodingMode and application.SLCMS.config.Debug.DebugMode eq True>
  		<!--- only do this when coding, we don't want to dump sessions on a config re-read --->
			<cfset this.variables.SLCMS.retAppStartGood2 = onSessionStart() />	
			<cfset this.variables.SLCMS.RSdebugString = this.variables.SLCMS.RSdebugString & "and then: Session was restarted from OnRequestStart, forced by Debugmode=True.<br>" />
		</cfif>
	</cfif>
	<!--- now we are ready to get the page so clear out all whitespace from everything we have run so far and output any messages we have --->
	<cfif not this.variables.SLCMS.CodingMode><cfcontent reset="yes"></cfif>
	<!--- all output so far dumped if we are not looking at our startup coding messages, 
				it will be dumped again immediately before template output when in production mode --->
	<cfif this.variables.SLCMS.CodingMode and this.variables.SLCMS.Initialization.AppWasRestarted>
		<cfoutput><strong>in OnRequestStart</strong> - <br><em>this.variables.SLCMS.RSdebugString:</em>
		<cfif this.variables.SLCMS.RSdebugString neq "<br>">
			#this.variables.SLCMS.RSdebugString#
		<cfelse>
			Is empty<br>
		</cfif>
		<cfif structKeyExists(this.variables.SLCMS, "retAppStartGood2")>
			<em>and retAppStartGood2:</em><br>
		<cfdump var="#this.variables.SLCMS.retAppStartGood2#" expand="false"><br>
		</cfif></cfoutput>
	</cfif>
	<!--- tidy up at the end --->
	<cfif application.SLCMS.config.StartUp.FlushSerialFromInitWiz eq "yes">
		<cfset application.SLCMS.config.startup.initialization.WeNeedToCreateDBTables = False />
		<cfset application.SLCMS.config.StartUp.FlushSerial = dateFormat(now(), "yyyymmdd") & timeFormat(now(), "ss") />
		<cfset application.SLCMS.config.StartUp.FlushSerialFromInitWiz eq "No" />
		<cfset application.SLCMS.flags.RunInstallWizard = False />
		<cflocation url="#cgi.script_name#?#cgi.path_info#" addtoken="false">
	</cfif>
</cfif>


<!--- untouched code --->

<!--- now we have got this far we have either a vaguely running system or one that needs setting up. --->
<cfif application.SLCMS.config.startup.initialization.WeNeedToCreateDBTables or this.variables.SLCMS.ForceInstallWizard>
	<!--- we are going to run the wizard and see what we need to do to get a DB up and running --->	
	<cfset application.SLCMS.flags.RunInstallWizard = True />
<!--- 
	<cfset $include(template="SLCMS/events/_onrequeststart_installWizard_inc.cfm") />
	 --->
	<!--- 
	<cflocation url="index.cfm/slcms/install-wizard/" >
	 --->
	
	<!---
	<!--- its not a OO-fanatic CFC it is just an encapsulation of all of the code and html for the wizard in a single unit --->
	<cftry>
		<!--- lets check to see if its already there, ie we are part way thru a wiz, in a manner of speaking :-) --->
		<cfif (not StructKeyExists(application.SLCMS.config.startup.initialization, "installationTemp")) or application.SLCMS.config.startup.flushserial neq this.variables.SLCMS.snFlushAppscope>
			<!--- no temp struct or a flush flagged so we haven't started so lets set it all up --->
			<cfset application.SLCMS.config.startup.flushserial = this.variables.SLCMS.snFlushAppscope />	<!--- square off te flush flag as might not have running onAppStart --->
<!---
			<cfinclude template="../SLCMSinstallation_GlobalCreator-udf.cfm" />	<!--- this includes the CFC creator for the installation code --->
			<cfset application.SLCMS.config.startup.initialization.installationTemp = StructNew() />	<!--- a fresh temp structure that we can dump when its finished --->
			<cfset application.SLCMS.config.startup.initialization.installationTemp.CFcCreator = CreateCFC_in_SLCMS_Installation_Manager />	<!--- copy in the function to make the CFC objects --->
			<cfset application.SLCMS.config.startup.initialization.installationTemp.InitialInstallationWizard = application.SLCMS.config.startup.initialization.installationTemp.CFcCreator("InitialInstallationWizard") />	<!--- create CFC objects for the InitialInstallationWizard --->
--->
			<cfset application.SLCMS.config.startup.initialization.installationTemp = StructNew() />	<!--- a fresh temp structure that we can dump when its finished --->
			<cfset application.SLCMS.config.startup.initialization.installationTemp.InitialInstallationWizard = createObject("component","#application.SLCMS.config.startup.InstallationWizardFolder#InitialInstallationWizard") />	<!--- create CFC object for the InitialInstallationWizard --->
			<!--- the wiz set up the next step number so it can go back and forth so lets initialise and roll into it --->
			<cfset application.SLCMS.config.startup.initialization.installationTemp.retInit = application.SLCMS.config.startup.initialization.installationTemp.InitialInstallationWizard.init() />
		</cfif>
		<!--- we have a struct and a step number so we are now in the midst of the wizard so run the next step --->
		<cfset application.SLCMS.config.startup.initialization.installationTemp.retStep = application.SLCMS.config.startup.initialization.installationTemp.InitialInstallationWizard.RunStep() />
		<cfabort>
	<cfcatch>
		<!--- ToDo: Oops code in here, the wizard could not start or run or its not there! --->
		<cfoutput>Oops! startup wiz failed</cfoutput>
		<cfdump var="#cfcatch#" expand="false" label="catch">
		<cfdump var="#application.SLCMS.config#" expand="false" label="application.SLCMS.config">
	</cfcatch>
	</cftry>
	--->
</cfif><cfsetting enablecfoutputonly="No">
<!---
<cfsilent>
--->	
<!--- now the last of stuff that is startup controlled --->	
<cfif this.variables.SLCMS.Initialization.AppWasRestarted>
	<!--- force a (re)read of the front end session-based nav stuff --->
	<cfset request.SLCMS.flags.FrontEndNavSerial = "" />
</cfif>

<!--- now stuff we want to do every time --->

<!--- sundry global application scope in req scope for legacy code or calculated values --->
<cfset request.SLCMS["rootURL"] = application.SLCMS.config.Base.rootURL />
<cfset request.SLCMS["MapURL"] = application.SLCMS.config.Base.MapURL />
<cfset request.SLCMS["CFMapURL"] = application.SLCMS.config.Base.CFMapURL />
<cfset request.SLCMS["BasePath"] = application.SLCMS.config.StartUp.SiteBasePath />
<cfset request.SLCMS["EditorControl"] = StructNew() />
<cfset request.SLCMS.EditorControl.EditorToUse = application.SLCMS.config.editors["#application.SLCMS.config.editors.EditorToUse#"] />
<cfset request.SLCMS.EditorControl.EditorBaseURL = application.SLCMS.config.Base.rootURL & application.SLCMS.config.Editors.EditorsRelPath>
<cfset request.SLCMS["styleSheet"] = "#application.SLCMS.Paths_Common.StylingRootPath_ABS#SLCMS.css" />
<cfset request.SLCMS.flags.PoppedAdminURLFlagString = "popped=yes" />
<!--- 
<cfset request.SLCMS.styleSheet = "#application.SLCMS.Paths_Common.StylingRootPath_ABS#SLCMS_BackEnd.css" />
 --->
<cfset $include(template="SLCMS/events/_onrequeststart_loginHandler_inc.cfm") />
