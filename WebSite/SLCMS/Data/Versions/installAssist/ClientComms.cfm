<cfsilent>
<!--- mbc SL_PhotoGallery Module  --->
<!--- &copy; 2011 mort bay communications --->
<!---  --->
<!--- wrapper for all AJAX work done by the install wizard --->
<!--- as we could have a partial install we have to be completely internal, we cannot use standard core SLCMS routines --->
<!--- Contains:
			stuff :-)
			 --->
<!---  --->
<!--- created:  17th Jul 2011 by Kym K, mbcomms --->
<!--- modified: 17th Jul 2011 -  8th Aug 2011 by Kym K, mbcomms: initial work --->

<cflog text='ClientComms Install Wizard AJAX call. URL Params:#cgi.query_string# - Time: #DateFormat(Now(),"YYYYMMDD")#-#TimeFormat(now(),"HH:mm:ss")#'  file="InstallWizardAJAX" type="Information" application = "yes">

<cfif StructKeyExists(url, "Job") and url.job eq "TestComms">
	<cfif StructKeyExists(url, "Name") and url.Name eq "InstallWizard">
		<cfif StructKeyExists(url, "Value") and IsValid("UUID",url.Value)>
			<cfset theOutput = "Good UUID" />
		<cfelse>	
			<cfset theOutput = "invalid params" />
		</cfif>
	<cfelse>	
		<cfset theOutput = "invalid params" />
	</cfif>

<cfelseif StructKeyExists(url, "Job") and url.job eq "CleanName">
	<cfif StructKeyExists(url, "Name")>
		<cfset theOutput = trim(url.Name) />
		<cfset theOutput = Replace(theOutput, " ", "_", "all") />
	<cfelse>	
		<cfset theOutput = "No Name param" />
	</cfif>

<cfelseif StructKeyExists(url, "Job") and url.job eq "MakeSignInWord">
	<cfif StructKeyExists(url, "FirstName") and StructKeyExists(url, "LastName")>
		<cfset theFirstName = trim(url.FirstName) />
		<cfset theLastName = trim(url.LastName) />
		<cfset theOutput = theFirstName & left(theLastName, 1) />
	<cfelse>	
		<cfset theOutput = "Not correct params" />
	</cfif>
			
<!--- 
<cfelseif StructKeyExists(url, "Job") and url.job eq "PublishChanges">
	<cfif StructKeyExists(url, "AlbumUID")>
		<cfset theAlbumUID = trim(url.AlbumUID) />
		<cfset theOutput = application.Modules.SL_PhotoGallery.Functions.ImageManager.PublishChanges(AlbumUID="#theAlbumUID#").data />
	<cfelse>	
		<cfset theOutput = "Not correct params" />
	</cfif>
<cfelseif StructKeyExists(url, "Job") and url.job eq "SetPreference">
	<cfif StructKeyExists(url, "Name") and StructKeyExists(url, "Value")>
	<cfelse>	
		<cfset theOutput = "Not correct params" />
	</cfif>
 --->

<cfelse>
	<cfset theOutput = "No Job param" />
</cfif>

</cfsilent>
<cfcontent reset="Yes"><cfoutput>#theOutput#</cfoutput>