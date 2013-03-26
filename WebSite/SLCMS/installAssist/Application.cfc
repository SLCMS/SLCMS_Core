<cfcomponent displayname="Dummy App CFC" hint="stops main application.cfc from running" output="false">
<!--- 
	this is a dummy application.cfm to kill the real site one so that the ajax part installation wizard can work
	if we don't have it then the ajax calls get treated as another site call and we get another instance of the Wiz and down we go... 
	 --->
	<cfset This.Name = "SLCMS_Install_Wizard" />
	<cfset This.setclientcookies = False />
	<cfset This.Sessionmanagement = True />
	<cfset This.setDomainCookies = False />
	<cfset This.Sessiontimeout = "#createtimespan(0,2,0,0)#" />
	<cfset This.Applicationtimeout = "#createtimespan(2,0,0,0)#" />

</cfcomponent>