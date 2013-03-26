<cfif this.variables.SLCMS.CodingMode>
	<cfoutput>OnApplicationStart: starting SLCMS section<br></cfoutput>
</cfif>

<!--- tell the world the start code has been called --->
<cflog text='Application #this.variables.SLCMS.theSiteName# - SLCMS/events/OnApplicationStart started Time: #DateFormat(Now(),"YYYYMMDD")#-#TimeFormat(now(),"HH:mm:ss.L")#. FlushSerial: #this.variables.SLCMS.snFlushAppscope#' type="Information" file="#this.variables.SLCMS.theSLCMSCommonLogName#">

<cfset application.SLCMS.Config.StartUp.FlushSerial = this.variables.SLCMS.snFlushAppscope />

<!--- include the main application setting code, its an include as it can be called from OnRequestStart as well --->
<cfset $include(template="SLCMS/events/_onapplicationstart_inc.cfm") />

<!--- we set the datasource in the above include file depending on the running environment, 
			it can be overridden here if needs be
 --->
<!---
<cfset set(dataSourceName="someDSNname")>
--->

<cflog text='Application SLCMS/events/OnApplicationStart finished - Time: #DateFormat(Now(),"YYYYMMDD")#-#TimeFormat(now(),"HH:mm:ss.L")#'  file="#this.variables.SLCMS.theSiteLogName#" type="Information" application="yes">
	