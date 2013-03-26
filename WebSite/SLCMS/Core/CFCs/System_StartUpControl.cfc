<!--- mbc SLCMS CFCs  --->
<!--- &copy; 2010 mort bay communications --->
<!---  --->
<!--- System Startup Control CFC  --->
<!--- the functions get called more or less in the order they are here --->
<!--- Contains:
			init - no persistent stuff here as this is just called on startup
			lots more related stuff :-)
			 --->
<!---  --->
<!--- created:  13th Mar 2010 by Kym K, mbcomms --->
<!--- modified: 21st Apr 2010 - 21st Apr 2010 by Kym K, mbcomms: more work on it --->
<!--- modified: 18th Feb 2011 - 18th Feb 2011 by Kym K, mbcomms: ran varScoper over code and found one un-var'd variable! oops, one too many :-/  --->
<!--- modified: 15th Aug 2011 - 15th Aug 2011 by Kym K, mbcomms: add logging to TestDBGood() to help maintenance --->
<!--- modified:  9th Apr 2012 -  9th Apr 2012 by Kym K, mbcomms: V3.0, CFWheels version. All SLCMS in own struct under app scope --->

<cfcomponent output="No"
	displayname="Site Startup Utilities" 
	hint="contains functions to compact the code used in the site startup. No encapsulation worth bothing about, talks to persistent scopes directly"
	>
	
	<!--- set up a few persistant things on the way in. --->
	<cfset variables.theName = "NavigationStyling" />	<!--- do the "force the struct name to camelcase trick" --->


<cffunction name="SetAppScopeDatabaseNames" output="no" returntype="void" access="public"
	displayname="Set Application Scope Database Names"
	hint="reads the startup structures and builds the database name strings used commonly about the place"
	>
		<cfset application.SLCMS.Config.DatabaseDetails.databaseTableNaming_Root_System = 
						application.SLCMS.Config.DatabaseDetails.TableNaming_Base 
					& application.SLCMS.Config.DatabaseDetails.TableNaming_Delimiter
					& application.SLCMS.Config.DatabaseDetails.TableNaming_SystemMarker
					& application.SLCMS.Config.DatabaseDetails.TableNaming_Delimiter />
					
		<cfset application.SLCMS.Config.DatabaseDetails.databaseTableNaming_Root_Site = 
						application.SLCMS.Config.DatabaseDetails.TableNaming_Base 
					& application.SLCMS.Config.DatabaseDetails.TableNaming_Delimiter
					& application.SLCMS.Config.DatabaseDetails.TableNaming_SiteMarker
					& application.SLCMS.Config.DatabaseDetails.TableNaming_Delimiter />
					
		<cfset application.SLCMS.Config.DatabaseDetails.databaseTableNaming_Root_Type = 
						application.SLCMS.Config.DatabaseDetails.TableNaming_Base 
					& application.SLCMS.Config.DatabaseDetails.TableNaming_Delimiter
					& application.SLCMS.Config.DatabaseDetails.TableNaming_TypeMarker
					& application.SLCMS.Config.DatabaseDetails.TableNaming_Delimiter />
					
		<cfset application.SLCMS.Config.DatabaseDetails.databaseTableNaming_Tail_SiteAdminDetail = 
						application.SLCMS.Config.DatabaseDetails.TableNaming_Delimiter 
					& application.SLCMS.Config.DatabaseDetails.UserDetailTable_Admin /> 
					
		<cfset application.SLCMS.Config.DatabaseDetails.databaseTableNaming_Tail_SiteAdminRole = 
						application.SLCMS.Config.DatabaseDetails.TableNaming_Delimiter 
					& application.SLCMS.Config.DatabaseDetails.UserRoleTable_Admin /> 
					
		<cfset application.SLCMS.Config.DatabaseDetails.databaseTableNaming_Tail_PageStructure = 
						application.SLCMS.Config.DatabaseDetails.TableNaming_Delimiter 
					& application.SLCMS.Config.DatabaseDetails.PageStructureTable /> 
					
		<cfset application.SLCMS.Config.DatabaseDetails.databaseTableNaming_Tail_Content_Content = 
						application.SLCMS.Config.DatabaseDetails.TableNaming_Delimiter 
					& application.SLCMS.Config.DatabaseDetails.ContentTable /> 
					
		<cfset application.SLCMS.Config.DatabaseDetails.databaseTableNaming_Tail_ContentControl_Doc = 
						application.SLCMS.Config.DatabaseDetails.TableNaming_Delimiter 
					& application.SLCMS.Config.DatabaseDetails.DocContentControlTable /> 
					
		<cfset application.SLCMS.Config.DatabaseDetails.databaseTableNaming_Tail_ContentControl_Blog = 
						application.SLCMS.Config.DatabaseDetails.TableNaming_Delimiter 
					& application.SLCMS.Config.DatabaseDetails.BlogContentControlTable /> 
					
		<!--- and final table names --->
		<cfset application.SLCMS.Config.DatabaseDetails.TableName_SystemAdminDetailsTable = 
						application.SLCMS.Config.DatabaseDetails.databaseTableNaming_Root_System 
					& application.SLCMS.Config.DatabaseDetails.UserDetailTable_Admin />
					
		<cfset application.SLCMS.Config.DatabaseDetails.TableName_SystemAdminRolesTable = 
						application.SLCMS.Config.DatabaseDetails.databaseTableNaming_Root_System 
					& application.SLCMS.Config.DatabaseDetails.UserRoleTable_Admin />
					
		<cfset application.SLCMS.Config.DatabaseDetails.TableName_TypeStaffRolesTable = 
						application.SLCMS.Config.DatabaseDetails.databaseTableNaming_Root_Type
					& application.SLCMS.Config.DatabaseDetails.StaffRolesTypeTable />
					
		<cfset application.SLCMS.Config.DatabaseDetails.TableName_Site_0_PageStruct = 
						application.SLCMS.Config.DatabaseDetails.databaseTableNaming_Root_Site
					& "0"
					& application.SLCMS.Config.DatabaseDetails.TableNaming_Delimiter
					& application.SLCMS.Config.DatabaseDetails.PageStructureTable />
					
		<cfset application.SLCMS.Config.DatabaseDetails.TableName_PortalControlTable = 
						application.SLCMS.Config.DatabaseDetails.databaseTableNaming_Root_System
					& application.SLCMS.Config.DatabaseDetails.PortalControlTable />
					
		<cfset application.SLCMS.Config.DatabaseDetails.TableName_PortalURLTable = 
						application.SLCMS.Config.DatabaseDetails.databaseTableNaming_Root_System
					& application.SLCMS.Config.DatabaseDetails.PortalURLTable />
					
		<cfset application.SLCMS.Config.DatabaseDetails.TableName_PortalParentDocTable = 
						application.SLCMS.Config.DatabaseDetails.databaseTableNaming_Root_System
					& application.SLCMS.Config.DatabaseDetails.PortalParentDocTable />

</cffunction>

<cffunction name="TestDBGood" output="no" returntype="void" access="public"
	displayname="Test Database Good"
	hint="checks for existence of the main database and flags badnesses"
	>
	<cfset var theVersionTablename = application.SLCMS.Config.DatabaseDetails.databaseTableNaming_Root_System & "VersionControl" />
	<cfset var DBThereTest = "" />
	<!--- a very simple SQL query as we don't have the DAL loaded as yet --->
	<cftry>
		<cfquery name="DBthereTest" datasource="#application.SLCMS.Config.Datasources.CMS#">
			select	VersionNumber_Full
				from	#theVersionTablename#
				where	flag_ActiveVersion = 1
		</cfquery>
		<cfif DBthereTest.RecordCount eq 1>
			<!--- we have a table with one current entry --->
			<!--- ToDo: add tests for goodness and version number, etc. --->
		<cfelse>
			<!--- something wrong, not a single entry --->
			<cfset application.SLCMS.Config.startup.initialization.DBGood = False />
		</cfif>
	<cfcatch type="database">
		<!--- Oops! not there --->
		<!--- this probably means that this is a new install so call the installer --->
		<cfset application.SLCMS.Config.startup.initialization.WeNeedToCreateDBTables = True />
		<cfset application.SLCMS.Config.startup.initialization.DBIsThere = False />
		<cfset application.SLCMS.Config.startup.initialization.DBGood = False />
	  <cflog file="SLCMS_Common" type="Information" text="TestDBGood Caught, DB was: #application.SLCMS.Config.Datasources.CMS#">
	  <cfif application.SLCMS.config.codingMode>
	  	<!--- the assumtion is that we do not want to see the install wizard but want to see the DB error when in coding mode --->
	  	<cfrethrow />
	  </cfif>
	</cfcatch>
	</cftry>

</cffunction>

</cfcomponent>
