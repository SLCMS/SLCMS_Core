
<cfsetting enablecfoutputonly="Yes">
<cfset ErrFlag  = False>
<cfset ErrMsg  = "">
<cfset GoodMsg  = "">
<cfset opnext = "">	<!--- what we do next --->
<cfset theRolePatterns = application.SLCMS.roles />	<!--- the bit patterns we will use for the roles each user can have --->
<!--- DAL related vars we use right thru --->
<cfset theQueryDataArguments = StructNew() />	<!--- temp struct to compose the data clauses of SQL queries --->
<cfset theQueryWhereArguments = StructNew() />	<!--- temp struct to compose the where clauses of SQL queries --->
<cfset theQueryWhereFilters = ArrayNew(1) />	<!--- temp array to compose the filters for where clauses --->

<cfif application.SLCMS.core.UserPermissions.HasSiteAdminPermission()>	<!--- just to keep the hackers out --->
	<!--- as we have portal subsites and different users for each first off we need to work out what (sub)sites this particular logged-in admin user belongs to --->
	<cfset theAllowedSubsiteList = application.SLCMS.core.PortalControl.GetAllowedSubSiteIDList_AllSites(UserID="#session.SLCMS.user.UserID#") />
	<cfset theFullSubsiteList = application.SLCMS.core.PortalControl.GetFullSubSiteIDList() />
	
	<cfif IsDefined("url.mode")>
		<cfset WorkMode1 = url.mode>
		<cfset WorkMode2 = "">
		<cfset DispMode = url.mode>
	<cfelse>
		<cfset WorkMode1 = "">
		<cfset WorkMode2 = "GetUserList">
		<cfset DispMode = "ShowUserList">
	</cfif>
	<cfif isdefined("form.cancel")>	<!--- do nothing if cancelled --->
		<cfset WorkMode1 = "">
		<cfset WorkMode2 = "GetUserList">
		<cfset DispMode = "ShowUserList">
	</cfif>
	
	<cfif WorkMode1 eq "addUser">
		<!--- set up to add a user to the system --->
		<cfif url.SiteID neq "" and IsNumeric(url.SiteID)>
			<cfset theClickedSubSite = url.SiteID />
		<cfelse>
			<cfset theClickedSubSite = 0 />
		</cfif>
		<cfset theDisplayArray = ArrayNew(1) />
		<cfset lcntr = 1 />
		<cfloop list="#theAllowedSubsiteList#" index="thisSubSite">
			<cfset theSubSiteDetails = application.SLCMS.core.PortalControl.GetSubSite(subsiteID="#thisSubSite#") />
			<cfset theDisplayArray[lcntr] = StructNew() />
			<cfset theDisplayArray[lcntr].SubSiteID = thisSubSite />
			<cfset theDisplayArray[lcntr].SubSiteFriendlyName = theSubSiteDetails.data.SubSiteFriendlyName />
			<cfset theDisplayArray[lcntr].UserID = "" />
			<cfset theDisplayArray[lcntr].User_FirstName = "" />
			<cfset theDisplayArray[lcntr].User_LastName = "" />
			<cfset theDisplayArray[lcntr].User_Password = "" />
			<cfset theDisplayArray[lcntr].User_Eddress = "" />
			<cfset theDisplayArray[lcntr].User_Active = 0 />
			<cfset theDisplayArray[lcntr].User_Login = "" />
			<cfset theDisplayArray[lcntr].Global_RoleBits = "00000000000000000000000000000000" />
			<cfset theDisplayArray[lcntr].Global_RoleValue = 0 />
			<cfset theDisplayArray[lcntr].CanManage = False />
			<cfif thisSubSite eq theClickedSubSite>
				<cfset theDisplayArray[lcntr].ThisSubSiteWasClicked = True />
			<cfelse>
				<cfset theDisplayArray[lcntr].ThisSubSiteWasClicked = False />
			</cfif>
			<cfset lcntr = lcntr+1 />
		</cfloop>
		<cfset opnext = "SaveAddUser">	<!--- what we do next --->
		<cfset DispMode = "addUser">
		<cfset backLinkText = "Cancel Adding Staff Member, " />	<!--- hop out link text --->
	
	<cfelseif WorkMode1 eq "SaveAddUser">
		<!--- save a user into the system --->
<!--- 		
		<cfdump var="#params#" expand="false" label="params">

		<cfabort>
 --->
		<!--- first check that we have valid input --->
		<cfset OK = True />
		<cfset theUserID = form.UserID />
		<cfset theLogin = form.User_Login />
		<cfif len(theLogin) eq 0>
			<cfset OK = False />
			<cfset ErrFlag  = True>
			<cfset ErrMsg  = ErrMsg & "No Login Supplied<br>">
		</cfif>
		<cfset thePassword = form.User_Password />
		<cfif len(thePassword) eq 0>
			<cfset OK = False />
			<cfset ErrFlag  = True>
			<cfset ErrMsg  = ErrMsg & "No Password Supplied<br>">
		</cfif>
		<cfset theFirstName = form.User_FirstName />
		<cfset theLastName = form.User_LastName />
		<cfif theFirstName eq "" and theLastName eq "">
			<cfset OK = False />
			<cfset ErrFlag  = True>
			<cfset ErrMsg  = ErrMsg & "No Name Supplied<br>">
		</cfif>
		<cfset theEddress = form.User_Eddress />
		<cfif theEddress neq "" and application.SLCMS.mbc_utility.Utilities.IsValidEddress(theEddress) eq False>
			<cfset OK = False />
			<cfset ErrFlag  = True>
			<cfset ErrMsg  = ErrMsg & "Invalid Email Address Supplied<br>">
		</cfif>
		<cfif params.ClickedSubSiteID neq "" and IsNumeric(params.ClickedSubSiteID)>
			<cfset theClickedSubSite = params.ClickedSubSiteID />
		<cfelse>
			<cfset theClickedSubSite = 0 />
		</cfif>
		<cfif IsNumeric(params.ClickedSubSiteID)>
			<!--- see if we are duplicating this user --->
			<cfloop list="#theFullSubSiteList#" index="thisSubSite">
				<cfset theDatabaseTable = application.SLCMS.config.DatabaseDetails.databaseTableNaming_Root_Site
																	& thisSubSite
																	& application.SLCMS.config.DatabaseDetails.databaseTableNaming_Tail_SiteAdminDetail />	<!--- the database table name --->
				<cfset StructClear(theQueryWhereArguments) />
				<cfset theQueryWhereArguments.Staff_SignIn = theLogin />
				<cfset theQueryWhereArguments.Staff_Password = thePassword />
				<cfset getUser = application.SLCMS.core.DataMgr.getRecords(tablename="#theDatabaseTable#", data=theQueryWhereArguments, fieldList="StaffID") />
				<!--- 
				<cfquery name="getUser" datasource="#application.SLCMS.config.datasources.CMS#">
					SELECT	UserID
						FROM	#theDatabaseTable#
						Where User_Login = <cfqueryparam value="#theLogin#" cfsqltype="cf_sql_varchar" list="false" maxlength="50">
							and User_Password = <cfqueryparam value="#thePassword#" cfsqltype="cf_sql_varchar" list="false" maxlength="50">
				</cfquery>
				 --->
				<cfif getUser.RecordCount>
					<cfset OK = False />
					<cfset ErrFlag  = True>
					<cfset ErrMsg  = ErrMsg & "That Login/Password Combination already exists for another user<br>">
					<cfbreak>
				</cfif>
			</cfloop>
		<cfelse>
			<cfset OK = False />
			<cfset ErrFlag  = True>
			<cfset ErrMsg  = ErrMsg & "Bad form return for the chosen site<br>">
		</cfif>
		<!--- valid data so save the poor soul --->
		<cfif OK and form.SubSiteList eq theAllowedSubsiteList>	<!--- check for goodness including broken/hacked return vars --->
			<!--- all is well so loop over the available subsites and enter as required --->
			<cfloop list="#form.SubSiteList#" index="thisSubSite">
				<cfset theDatabaseTable = application.SLCMS.config.DatabaseDetails.databaseTableNaming_Root_Site
																	& thisSubSite
																	& application.SLCMS.config.DatabaseDetails.databaseTableNaming_Tail_SiteAdminDetail />	<!--- the database table name --->
				<cfif form["Site_#thisSubSite#_UserCanManage"] eq 1>
					<!--- and calculate the bits and values for the roles, add the numbers and then convert to bit pattern --->
					<cfset theGlobalRoleValue = 0 />
					<cfif IsDefined("form.Site_#thisSubSite#_IsAdmin_Global") and form["Site_#thisSubSite#_IsAdmin_Global"] eq 1>
						<cfset theGlobalRoleValue = theGlobalRoleValue+theRolePatterns.Core.Global.Admin.RoleValue />
					</cfif>
					<cfif IsDefined("form.Site_#thisSubSite#_IsEditor_Global") and form["Site_#thisSubSite#_IsEditor_Global"] eq 1>
						<cfset theGlobalRoleValue = theGlobalRoleValue+theRolePatterns.Core.Global.Editor.RoleValue />
					</cfif>
					<cfif IsDefined("form.Site_#thisSubSite#_IsAuthor_Global") and form["Site_#thisSubSite#_IsAuthor_Global"] eq 1>
						<cfset theGlobalRoleValue = theGlobalRoleValue+theRolePatterns.Core.Global.Author.RoleValue />
					</cfif>
					<!---
					<cfset theGlobalRoleBits = application.SLCMS.mbc_utility.utilities.IntTo32Bits(theGlobalRoleValue) />
		  		--->
					<!--- 
					<cfif IsDefined("form.Site_#thisSubSite#_IsAdmin_Content") and form["Site_#thisSubSite#_IsAdmin_Content"] eq 1>
						<cfset theGlobalRoleValue = theGlobalRoleValue+theRolePatterns.Core.Content.Admin.RoleValue />
					</cfif>
					 --->
					<cfif IsDefined("form.Site_#thisSubSite#_IsEditor_Content") and form["Site_#thisSubSite#_IsEditor_Content"] eq 1>
						<cfset theGlobalRoleValue = theGlobalRoleValue+theRolePatterns.Core.Content.Editor.RoleValue />
					</cfif>
					<cfif IsDefined("form.Site_#thisSubSite#_IsAuthor_Content") and form["Site_#thisSubSite#_IsAuthor_Content"] eq 1>
						<cfset theGlobalRoleValue = theGlobalRoleValue+theRolePatterns.Core.Content.Author.RoleValue />
					</cfif>
					<cfset theGlobalRoleBits = application.SLCMS.mbc_utility.utilities.IntTo32Bits(theGlobalRoleValue) />
					<!--- then save the new data --->
					<cfset StructClear(theQueryDataArguments) />
					<cfset theQueryDataArguments.StaffID = Nexts_getNextID('UserID') />
					<cfset theQueryDataArguments.Staff_SignIn = theLogin />
					<cfset theQueryDataArguments.Staff_Password = thePassword />
					<cfset theQueryDataArguments.Staff_FirstName = theFirstName />
					<cfset theQueryDataArguments.Staff_LastName = theLastName />
					<cfset theQueryDataArguments.Staff_Eddress = theEddress />
					<cfset theQueryDataArguments.User_Active = form['Site_#thisSubSite#_User_Active'] />
					<cfset theQueryDataArguments.Global_RoleBits = theGlobalRoleBits />
					<cfset theQueryDataArguments.Global_RoleValue = theGlobalRoleValue />
					<cfset addUser = application.SLCMS.core.DataMgr.InsertRecord(tablename="#theDatabaseTable#", data=theQueryDataArguments) />
					<!--- 
					<cfset NewUserID = application.SLCMS.mbc_utility.utilities.getnextID("UserID") />
					<cfquery name="addUser" datasource="#application.SLCMS.config.datasources.CMS#">
						Insert Into	#theDatabaseTable#
											(UserID, User_Login, User_Password, User_Fullname, User_Eddress, User_Active, Global_RoleBits, Global_RoleValue)
							Values	(
											<cfqueryparam value="#NewUserID#" cfsqltype="cf_sql_integer">, 
											<cfqueryparam value="#theLogin#" cfsqltype="cf_sql_varchar" list="false" maxlength="50">, 
											<cfqueryparam value="#thePassword#" cfsqltype="cf_sql_varchar" list="false" maxlength="50">, 
											<cfqueryparam value="#theFullName#" cfsqltype="cf_sql_varchar" list="false" maxlength="50">, 
											<cfqueryparam value="#theEddress#" cfsqltype="cf_sql_varchar" list="false" maxlength="255">, 
											<cfqueryparam value="#form['Site_#thisSubSite#_User_Active']#" cfsqltype="cf_sql_bit">, 
											<cfqueryparam value="#theGlobalRoleBits#" cfsqltype="cf_sql_char">,
											<cfqueryparam value="#theGlobalRoleValue#" cfsqltype="cf_sql_integer">
											)
					</cfquery>
					 --->
				</cfif>	<!--- end: can manage this site --->
			</cfloop>	<!--- end: loop over subsites --->
			<!--- refresh the user management system --->
			<cfset application.SLCMS.Core.UserControl.RefreshAdminDetails() />
			<cfset GoodMsg = "New user &quot;#theFirstName# #theLastName#&quot; saved" />"
			<!--- finished so back to the listing --->
			<cfset WorkMode2 = "GetUserList">
			<cfset DispMode = "ShowUserList">
		<cfelse>
			<!--- It was not good so back to the form with message --->
				<!---				
				<cfdump var="#ErrMsg#">

				<cfabort>
				--->
			<cfset lcntr = 1 />
			<cfloop list="#form.SubsiteList#" index="thisSubSite">
				<cfset theSubSiteDetails = application.SLCMS.core.PortalControl.GetSubSite(subsiteID="#thisSubSite#") />
				<cfset theDisplayArray[lcntr] = StructNew() />
				<cfset theDisplayArray[lcntr].SubSiteID = thisSubSite />
				<cfset theDisplayArray[lcntr].SubSiteFriendlyName = theSubSiteDetails.data.SubSiteFriendlyName />
				<cfset theDisplayArray[lcntr].UserID = "" />
				<cfset theDisplayArray[lcntr].User_FirstName = theFirstName />
				<cfset theDisplayArray[lcntr].User_LastName = theLastName />
				<cfset theDisplayArray[lcntr].User_Password = thePassword />
				<cfset theDisplayArray[lcntr].User_Eddress = theEddress />
				<cfset theDisplayArray[lcntr].User_Active = form["Site_#thisSubSite#_User_Active"] />
				<cfset theDisplayArray[lcntr].User_Login = "" />
				<cfset theDisplayArray[lcntr].CanManage = False />
				<cfif thisSubSite eq theClickedSubSite>
					<cfset theDisplayArray[lcntr].ThisSubSiteWasClicked = True />
				<cfelse>
					<cfset theDisplayArray[lcntr].ThisSubSiteWasClicked = False />
				</cfif>
				<cfif form["Site_#thisSubSite#_UserCanManage"] eq 1>
					<!--- and calculate the bits and values for the roles --->
					<cfset theGlobalRoleValue = 0 />
					<cfif IsDefined("form.Site_#thisSubSite#_IsAdmin_Global") and form["Site_#thisSubSite#_IsAdmin_Global"] eq 1>
						<cfset theGlobalRoleValue = theGlobalRoleValue+theRolePatterns.Core.Global.Admin.RoleValue />
					</cfif>
					<cfif IsDefined("form.Site_#thisSubSite#_IsEditor_Global") and form["Site_#thisSubSite#_IsEditor_Global"] eq 1>
						<cfset theGlobalRoleValue = theGlobalRoleValue+theRolePatterns.Core.Global.Editor.RoleValue />
					</cfif>
					<cfif IsDefined("form.Site_#thisSubSite#_IsAuthor_Global") and form["Site_#thisSubSite#_IsAuthor_Global"] eq 1>
						<cfset theGlobalRoleValue = theGlobalRoleValue+theRolePatterns.Core.Global.Author.RoleValue />
					</cfif>
					<!--- 
					<cfif IsDefined("form.Site_#thisSubSite#_IsAdmin_Content") and form["Site_#thisSubSite#_IsAdmin_Content"] eq 1>
						<cfset theGlobalRoleValue = theGlobalRoleValue+theRolePatterns.Core.Content.Admin.RoleValue />
					</cfif>
					 --->
					<cfif IsDefined("form.Site_#thisSubSite#_IsEditor_Content") and form["Site_#thisSubSite#_IsEditor_Content"] eq 1>
						<cfset theGlobalRoleValue = theGlobalRoleValue+theRolePatterns.Core.Content.Editor.RoleValue />
					</cfif>
					<cfif IsDefined("form.Site_#thisSubSite#_IsAuthor_Content") and form["Site_#thisSubSite#_IsAuthor_Content"] eq 1>
						<cfset theGlobalRoleValue = theGlobalRoleValue+theRolePatterns.Core.Content.Author.RoleValue />
					</cfif>
					<cfset theGlobalRoleBits = application.SLCMS.mbc_utility.utilities.IntTo32Bits(theGlobalRoleValue) />
					<cfset theDisplayArray[lcntr].Global_RoleBits = theGlobalRoleBits />
					<cfset theDisplayArray[lcntr].Global_RoleValue = theGlobalRoleValue />
				<cfelse>
					<cfset theDisplayArray[lcntr].Global_RoleBits = "00000000000000000000000000000000" />
					<cfset theDisplayArray[lcntr].Global_RoleValue = 0 />
				</cfif>
				<cfset lcntr = lcntr+1 />
			</cfloop>
				
			<cfset DispMode = "addUser">
			<cfset opnext = "SaveAddUser">	<!--- what we do next --->
			<cfset backLinkText = "Cancel Adding Staff Member, " />	<!--- hop out link text --->
<!---
			<cfset dUserID = 0 />
			<cfset dUser_FullName = "#theFirstName# #theLastName#" />
			<cfset dUser_Eddress = theEddress />
			<cfset dUser_Password = thePassword />
			<cfset dUser_Login = theLogin />
			<cfset dUser_Active = form.User_Active />
			<cfset dGlobal_RoleValue = theRoleValue />
--->
		</cfif>
	
	<cfelseif WorkMode1 eq "EditUser">
			<!--- we need to run the display gather afterwards as the save edit validation might throw back and we need the display array, etc --->
			<cfset WorkMode2 = "EditUser">
			<cfset backLinkText = "Cancel Editing Staff Member, " />	<!--- hop out link text --->

	<cfelseif WorkMode1 eq "SaveEditUser">
		<!--- save an edited user into the system --->
<!--- 
		<cfdump var="#application.slcms#" label="application.slcms" expand="false" />
		<cfdump var="#params#" label="params" expand="false" />

		<cfabort>
 --->

		<!--- first check that we have valid input --->
		<cfset OK = True />
		<cfset theGlobalRoleValue = 0 />
		<cfset theUserID = form.UserID />
		<cfset theLogin = form.User_Login />
		<cfif len(theLogin) eq 0>
			<cfset OK = False />
			<cfset ErrFlag  = True>
			<cfset ErrMsg  = ErrMsg & "No Login Supplied<br>">
		</cfif>
		<cfset thePassword = form.User_Password />
		<cfif len(thePassword) eq 0>
			<cfset OK = False />
			<cfset ErrFlag  = True>
			<cfset ErrMsg  = ErrMsg & "No Password Supplied<br>">
		</cfif>
		<cfset theFirstName = form.User_FirstName />
		<cfset theLastName = form.User_LastName />
		<cfif theFirstName eq "" and theLastName eq "">
			<cfset OK = False />
			<cfset ErrFlag  = True>
			<cfset ErrMsg  = ErrMsg & "No Name Supplied<br>">
		</cfif>
		<cfset theEddress = form.User_Eddress />
		<cfif theEddress neq "" and application.SLCMS.mbc_utility.Utilities.IsValidEddress(theEddress) eq False>
			<cfset OK = False />
			<cfset ErrFlag  = True>
			<cfset ErrMsg  = ErrMsg & "Invalid Email Address Supplied<br>">
		</cfif>
		<cfif IsNumeric(form.ClickedSubSiteID)>
			<!--- we now have relevant bits so see if we are duplicating --->
			<cfloop list="#theFullSubSiteList#" index="thisSubSite">
				<cfset theDatabaseTable = application.SLCMS.config.DatabaseDetails.databaseTableNaming_Root_Site
																	& thisSubSite
																	& application.SLCMS.config.DatabaseDetails.databaseTableNaming_Tail_SiteAdminDetail />	<!--- the database table name --->
				<cfset StructClear(theQueryWhereArguments) />
				<cfset ArrayClear(theQueryWhereFilters) />
				<cfset theQueryWhereArguments.Staff_SignIn = theLogin />
				<cfset theQueryWhereArguments.Staff_Password = thePassword />
				<cfset theQueryWhereFilters[1] = {field="StaffId", operator="<>", value="#theUserID#"} />
				<cfset getUser = application.SLCMS.core.DataMgr.getRecords(tablename="#theDatabaseTable#", data=theQueryWhereArguments, filters=theQueryWhereFilters, fieldList="StaffID") />
				<!--- 
				
				<cfdump var="#theQueryWhereArguments#" expand="false" label="theQueryWhereArguments" > 
				<cfdump var="#theQueryWhereFilters#" expand="false" label="theQueryWhereFilters" > 
				

				<cfdump var="#getUser#" expand="false" label="getUser" > 

				<cfquery name="getUser" datasource="#application.SLCMS.config.datasources.CMS#">
					SELECT	UserID
						FROM	#theDatabaseTable#
						Where User_Login = <cfqueryparam value="#theLogin#" cfsqltype="cf_sql_varchar" list="false" maxlength="50">
							and User_Password = <cfqueryparam value="#thePassword#" cfsqltype="cf_sql_varchar" list="false" maxlength="50">
							and UserID <> <cfqueryparam value="#theUserID#" cfsqltype="cf_sql_integer">
				</cfquery>
				 --->
				<cfif getUser.RecordCount>
					<cfset OK = False />
					<cfset ErrFlag  = True>
					<cfset ErrMsg  = ErrMsg & "That Login/Password Combination already exists for another user<br>">
					<cfbreak>
				</cfif>
			</cfloop>
		<cfelse>
			<cfset OK = False />
			<cfset ErrFlag  = True>
			<cfset ErrMsg  = ErrMsg & "Bad form return for the chosen site<br>">
		</cfif>
		<cfif OK and form.SubSiteList eq theAllowedSubsiteList>	<!--- check for goodness including broken/hacked return vars --->
			<!--- all is well so loop over the available subsites and enter as required --->
			<cfloop list="#form.SubSiteList#" index="thisSubSite">
				<cfset theDatabaseTable = application.SLCMS.config.DatabaseDetails.databaseTableNaming_Root_Site
																	& thisSubSite
																	& application.SLCMS.config.DatabaseDetails.databaseTableNaming_Tail_SiteAdminDetail />	<!--- the database table name --->
				<cfif form["Site_#thisSubSite#_UserCanManage"] eq 1>
					<!--- and calculate the bits and values for the roles --->
					<cfset theGlobalRoleValue = 0 />
					<cfif IsDefined("form.Site_#thisSubSite#_IsAdmin_Global") and form["Site_#thisSubSite#_IsAdmin_Global"] eq 1>
						<cfset theGlobalRoleValue = theGlobalRoleValue+theRolePatterns.Core.Global.Admin.RoleValue />
					</cfif>
					<cfif IsDefined("form.Site_#thisSubSite#_IsEditor_Global") and form["Site_#thisSubSite#_IsEditor_Global"] eq 1>
						<cfset theGlobalRoleValue = theGlobalRoleValue+theRolePatterns.Core.Global.Editor.RoleValue />
					</cfif>
					<cfif IsDefined("form.Site_#thisSubSite#_IsAuthor_Global") and form["Site_#thisSubSite#_IsAuthor_Global"] eq 1>
						<cfset theGlobalRoleValue = theGlobalRoleValue+theRolePatterns.Core.Global.Author.RoleValue />
					</cfif>
					<!--- 
					<cfset theGlobalRoleBits = application.SLCMS.mbc_utility.utilities.IntTo32Bits(theGlobalRoleValue) />
					<cfif IsDefined("form.Site_#thisSubSite#_IsAdmin_Content") and form["Site_#thisSubSite#_IsAdmin_Content"] eq 1>
						<cfset theGlobalRoleValue = theGlobalRoleValue+theRolePatterns.Core.Content.Admin.RoleValue />
					</cfif>
					 --->
					<cfif IsDefined("form.Site_#thisSubSite#_IsEditor_Content") and form["Site_#thisSubSite#_IsEditor_Content"] eq 1>
						<cfset theGlobalRoleValue = theGlobalRoleValue+theRolePatterns.Core.Content.Editor.RoleValue />
					</cfif>
					<cfif IsDefined("form.Site_#thisSubSite#_IsAuthor_Content") and form["Site_#thisSubSite#_IsAuthor_Content"] eq 1>
						<cfset theGlobalRoleValue = theGlobalRoleValue+theRolePatterns.Core.Content.Author.RoleValue />
					</cfif>
					<cfset theGlobalRoleBits = application.SLCMS.mbc_utility.utilities.IntTo32Bits(theGlobalRoleValue) />
					<!--- then so save the edited data --->
					<!--- the user might be already here or a new user for this particular subsite --->
					<!--- the old code was the standard triple query select-and-then-choose-an-insert-or-update, now its much easier --->
					<!--- set up our params for the query --->
					<cfset StructClear(theQueryDataArguments) />
					<cfset StructClear(theQueryWhereArguments) />
					<cfset theQueryDataArguments.StaffId = theUserID />	<!--- this is the primary key that the DAL will use to choose to insert or update --->
					<cfset theQueryDataArguments.Staff_SignIn = theLogin />
					<cfset theQueryDataArguments.Staff_Password = thePassword />
					<cfset theQueryDataArguments.Staff_FirstName = theFirstName />
					<cfset theQueryDataArguments.Staff_LastName = theLastName />
					<cfset theQueryDataArguments.Staff_Eddress = theEddress />
					<cfset theQueryDataArguments.User_Active = form['Site_#thisSubSite#_User_Active'] />
					<cfset theQueryDataArguments.Global_RoleBits = theGlobalRoleBits />
					<cfset theQueryDataArguments.Global_RoleValue = theGlobalRoleValue />
					<!--- now do it --->
					<cfset application.SLCMS.core.DataMgr.SaveRecord(tablename="#theDatabaseTable#", data=theQueryDataArguments) />
					<!--- 
					<cfquery name="getUser" datasource="#application.SLCMS.config.datasources.CMS#">
						SELECT	UserID
							FROM	#theDatabaseTable#
							where UserID = <cfqueryparam value="#theUserID#" cfsqltype="cf_sql_integer">
					</cfquery>
					<cfif getUser.RecordCount>
						<cfquery name="SaveEditedUser" datasource="#application.SLCMS.config.datasources.CMS#">
							Update	#theDatabaseTable#
								set		User_Login = <cfqueryparam value="#theLogin#" cfsqltype="cf_sql_varchar" list="false" maxlength="50">,  
											User_Password = <cfqueryparam value="#thePassword#" cfsqltype="cf_sql_varchar" list="false" maxlength="50">,  
											User_Fullname = <cfqueryparam value="#theFullname#" cfsqltype="cf_sql_varchar" list="false" maxlength="255">,  
											User_Eddress = 	<cfqueryparam value="#theEddress#" cfsqltype="cf_sql_varchar" list="false" maxlength="255">, 
											User_Active = 	<cfqueryparam value="#form['Site_#thisSubSite#_User_Active']#" cfsqltype="cf_sql_bit">, 
											Global_RoleBits = <cfqueryparam value="#theGlobalRoleBits#" cfsqltype="cf_sql_char">,
											Global_RoleValue = <cfqueryparam value="#theGlobalRoleValue#" cfsqltype="cf_sql_integer">
								where	UserId = <cfqueryparam value="#theUserID#" cfsqltype="cf_sql_integer">
						</cfquery>
					<cfelse>
						<!--- nope not there so do an insert --->
						<cfquery name="addUser" datasource="#application.SLCMS.config.datasources.CMS#">
							Insert Into	#theDatabaseTable#
												(UserID, User_Login, User_Password, User_Fullname, User_Eddress, User_Active, Global_RoleBits, Global_RoleValue)
								Values	(
												<cfqueryparam value="#theUserID#" cfsqltype="cf_sql_integer">, 
												<cfqueryparam value="#theLogin#" cfsqltype="cf_sql_varchar" list="false" maxlength="50">, 
												<cfqueryparam value="#thePassword#" cfsqltype="cf_sql_varchar" list="false" maxlength="50">, 
												<cfqueryparam value="#theFullName#" cfsqltype="cf_sql_varchar" list="false" maxlength="50">, 
												<cfqueryparam value="#theEddress#" cfsqltype="cf_sql_varchar" list="false" maxlength="255">, 
												<cfqueryparam value="#form['Site_#thisSubSite#_User_Active']#" cfsqltype="cf_sql_bit">, 
												<cfqueryparam value="#theGlobalRoleBits#" cfsqltype="cf_sql_char">,
												<cfqueryparam value="#theGlobalRoleValue#" cfsqltype="cf_sql_integer">
												)
						</cfquery>
					</cfif>
					 --->
				<cfelse>
					<!--- user cannot manage this site so remove any details that might be there --->
					<cfset StructClear(theQueryWhereArguments) />
					<cfset theQueryWhereArguments.StaffId = theUserID />
					<cfset delUser = application.SLCMS.core.DataMgr.deleteRecords(tablename="#theDatabaseTable#", data=theQueryWhereArguments) />
					<!--- 
					<cfquery name="EditUser" datasource="#application.SLCMS.config.datasources.CMS#">
						Delete from	#theDatabaseTable#
							where	UserId = <cfqueryparam value="#theUserID#" cfsqltype="cf_sql_integer">
					</cfquery>
					 --->
				</cfif>	<!--- end: can manage this site --->
			</cfloop>	<!--- end: loop over subsites --->
			<!--- refresh the user management system --->
			<cfset application.SLCMS.Core.UserControl.RefreshAdminDetails() />
			<cfset GoodMsg = "Edits to Staff Member &quot;#theFirstName# #theLastName#&quot; have been saved" />"
			<!--- finished so back to the listing --->
			<cfset WorkMode2 = "GetUserList">
			<cfset DispMode = "ShowUserList">
		<cfelse>
			<!--- It was not good so back to the form with message --->
			
			<!--- ToDo: this is all wrong, legacy code... --->
			
			<cfset opnext = "SaveEditUser">	<!--- what we do next --->
			<cfset dUserID = form.userId />
			<cfset dUser_FullName = "#theFirstName# #theLastName#" />
			<cfset dUser_Password = thePassword />
			<cfset dUser_Login = theLogin />
			<cfset dGlobal_RoleValue = theGlobalRoleValue />
			<cfset DispMode = "EditUser">
			<cfset WorkMode2 = "EditUser_ValidationFailed">
			<cfset backLinkText = "Cancel Editing Staff Member, " />	<!--- hop out link text --->
		</cfif>
	 
	<cfelseif WorkMode1 eq "DeleteUser">
		<cfset theDatabaseTable = application.SLCMS.config.DatabaseDetails.databaseTableNaming_Root_Site
																& params.SiteID
																& application.SLCMS.config.DatabaseDetails.databaseTableNaming_Tail_SiteAdminDetail />	<!--- the database table name --->
		<!--- delete a user from the system --->
		<cfset StructClear(theQueryWhereArguments) />
		<cfset theQueryWhereArguments.StaffId = params.userId />
		<cfset delUser = application.SLCMS.core.DataMgr.deleteRecords(tablename="#theDatabaseTable#", data=theQueryWhereArguments) />
		<!--- 
		<cfquery name="EditUser" datasource="#application.SLCMS.config.datasources.CMS#">
			Delete from	#request.SLCMS.UserSourceTable_Admin#
				where	UserId = <cfqueryparam value="#url.userId#" cfsqltype="cf_sql_integer">
		</cfquery>
		 --->
		<cfset GoodMsg = "User Deleted" />"
		<cfset WorkMode2 = "GetUserList">
		<cfset DispMode = "ShowUserList">
		
	</cfif>
	<!--- now do the second-pass stuff --->
	<cfif WorkMode2 eq "zzz">
		<!--- do things --->
		<cfset DispMode = "yyy">
		
	<cfelseif WorkMode2 eq "EditUser" or WorkMode2 eq "EditUser_ValidationFailed">
		<!--- set up to edit a user in the system --->
		<!--- this user could be scattered over all sorts of subsites so build a map of what this admin can manage --->
		<cfif IsDefined("url.SiteID") and url.SiteID neq "" and IsNumeric(url.SiteID)>
			<cfset theClickedSubSite = url.SiteID />
		<cfelseif IsDefined("form.ClickedSubSiteID") and form.ClickedSubSiteID neq "" and IsNumeric(form.ClickedSubSiteID)>
			<cfset theClickedSubSite = form.ClickedSubSiteID />
		<cfelse>
			<cfset theClickedSubSite = 0 />
		</cfif>
		<cfif IsDefined("url.userId") and url.SiteID neq "" and IsNumeric(url.userId)>
			<cfset theUserId = url.userId />
		<cfelseif IsDefined("form.userId") and form.userId neq "" and IsNumeric(form.userId)>
			<cfset theUserId = form.userId />
		<cfelse>
			<cfset theUserId = 0 />
		</cfif>
		<cfset theDisplayArray = ArrayNew(1) />
		<cfset lcntr = 1 />
		<!--- make an array of the subsites with the user's details in each --->
		<cfloop list="#theAllowedSubsiteList#" index="thisSubSite">
			<cfset theSubSiteDetails = application.SLCMS.core.PortalControl.GetSubSite(subsiteID="#thisSubSite#") />
			<cfset theDisplayArray[lcntr] = StructNew() />
			<cfset theDisplayArray[lcntr].SubSiteID = thisSubSite />
			<cfset theDisplayArray[lcntr].SubSiteFriendlyName = theSubSiteDetails.data.SubSiteFriendlyName />
			<cfset theDatabaseTable = application.SLCMS.config.DatabaseDetails.databaseTableNaming_Root_Site
																& thisSubSite 
																& application.SLCMS.config.DatabaseDetails.databaseTableNaming_Tail_SiteAdminDetail />	<!--- the database table name --->
			<cfset StructClear(theQueryWhereArguments) />
			<cfset theQueryWhereArguments.StaffId = theUserId />
			<cfset getUser = application.SLCMS.core.DataMgr.getRecords(tablename="#theDatabaseTable#", data=theQueryWhereArguments, fieldList="StaffID,Staff_SignIn,Staff_Password,Staff_FirstName,Staff_LastName,Staff_Eddress,User_Active,Global_RoleBits,Global_RoleValue") />
			<!--- 
			<cfquery name="getUser" datasource="#application.SLCMS.config.datasources.CMS#">
				SELECT	UserID, User_Login, User_Password, User_Fullname, User_Eddress, User_Active, Global_RoleBits, Global_RoleValue
					FROM	#theDatabaseTable#
					Where UserId = <cfqueryparam value="#url.userId#" cfsqltype="cf_sql_integer">
			</cfquery>
			 --->
			<cfif getUser.RecordCount>
				<cfset theDisplayArray[lcntr].UserID = getUser.StaffID />
				<cfset theDisplayArray[lcntr].User_FirstName = getUser.Staff_FirstName />
				<cfset theDisplayArray[lcntr].User_LastName = getUser.Staff_LastName />
				<cfset theDisplayArray[lcntr].User_Password = getUser.Staff_Password />
				<cfset theDisplayArray[lcntr].User_Eddress = getUser.Staff_Eddress />
				<cfset theDisplayArray[lcntr].User_Active = getUser.User_Active />
				<cfset theDisplayArray[lcntr].User_Login = getUser.Staff_SignIn />
				<!--- a bit of legacy handling for null bit patterns --->
				<cfif getUser.Global_RoleBits neq "">
					<cfset theDisplayArray[lcntr].Global_RoleBits = getUser.Global_RoleBits />
					<cfset theDisplayArray[lcntr].Global_RoleValue = getUser.Global_RoleValue />
				<cfelse>
					<cfset theDisplayArray[lcntr].Global_RoleBits = "00000000000000000000000000000000" />
					<cfset theDisplayArray[lcntr].Global_RoleValue = 0 />
				</cfif>
				<!--- and we had a database record so the user is allowed to manage this one so set flag for display purposes --->
				<cfset theDisplayArray[lcntr].CanManage = True />
			<cfelse>
				<cfset theDisplayArray[lcntr].UserID = "" />
				<cfset theDisplayArray[lcntr].User_FirstName = "" />
				<cfset theDisplayArray[lcntr].User_LastName = "" />
				<cfset theDisplayArray[lcntr].User_Password = "" />
				<cfset theDisplayArray[lcntr].User_Eddress = "" />
				<cfset theDisplayArray[lcntr].User_Active = 0 />
				<cfset theDisplayArray[lcntr].User_Login = "" />
				<cfset theDisplayArray[lcntr].Global_RoleBits = "00000000000000000000000000000000" />
				<cfset theDisplayArray[lcntr].Global_RoleValue = 0 />
				<cfset theDisplayArray[lcntr].CanManage = False />
			</cfif>
			<cfif thisSubSite eq theClickedSubSite>
				<cfset dUser_FullName = "#getUser.Staff_FirstName# #getUser.Staff_LastName#" />
				<cfset theDisplayArray[lcntr].ThisSubSiteWasClicked = True />
			<cfelse>
				<cfset theDisplayArray[lcntr].ThisSubSiteWasClicked = False />
			</cfif>
			
			<cfset lcntr = lcntr+1 />
		</cfloop>
		
		<cfset opnext = "SaveEditUser">	<!--- what we do next --->
		<cfset DispMode = "EditUser">

	<cfelseif WorkMode2 eq "GetUserList">
		<!--- get stuff we need to show the users and their roles --->
<!--- 
		<!--- loop over the user tables to grab each set of users that we are allowed to see --->
		<cfloop list="#theAllowedSubsiteList#" index="thisSubSite">
			<cfset theTableName = application.SLCMS.config.DatabaseDetails.DatabasetableNaming_Root_Site & thisSubSite & application.SLCMS.config.DatabaseDetails.tableNaming_Delimiter & application.SLCMS.config.DatabaseDetails.userDetailTable_Admin />
			<cfquery name="getUsers_Site_#thisSubSite#" datasource="#application.SLCMS.config.datasources.CMS#">
				SELECT	UserID, User_Login, User_Password, User_Fullname, User_Eddress, Global_RoleBits, Global_RoleValue
					FROM	#theTableName#
					Order By	User_Fullname
			</cfquery>
		</cfloop>
 --->
		<cfset DispMode = "ShowUserList">
	</cfif>
	
	<!--- get the base display stuff --->
	<cfif StructKeyExists(session, "Super") and session.SLCMS.Super eq "SuperRunning">
		<cfset rEmulateMode = True>
	<cfelse>
		<cfset rEmulateMode = False>
	</cfif>
	
<!--- 		
	<cfoutput>
dump of all portal control cfc variables in admin_Users.cfm:<br>
<cfdump var="#application.SLCMS.Core.PortalControl.GetVariablesScope()#" expand="false">
	theAllowedSubsiteList: #theAllowedSubsiteList#<br>
	dump of all session.SLCMS.User in WorkMode2:<br>
	<cfdump var="#session.SLCMS.User#" expand="false">
<!--- 
	application.SLCMS.config.DatabaseDetails: <br>
	<cfdump var="#application.SLCMS.config.DatabaseDetails#" expand="false">
 --->
	theRolePatterns: <br>
	<cfdump var="#theRolePatterns#" expand="false">
	</cfoutput>

	<cfabort>
 --->	
	
	
	
</cfif>	<!--- end: IsAdmin() test --->
<cfsetting enablecfoutputonly="No">
<cfoutput>#includePartial("/slcms/adminbanner")#</cfoutput><!--- show the banner if we are in the backend, returns nothing if we are popped up --->
<!--- 
<html>
<head>
	<title><cfoutput>#application.SLCMS.config.base.SiteName#</cfoutput> site administration</title>
	<cfoutput><link href="#request.SLCMS.styleSheet#" rel="STYLESHEET" type="text/css"></cfoutput>
</head>

<body class="body">

<a href="AdminHome.cfm"><img src="graphics/slcmsLogo1.gif" alt="SLCMS Logo and Link" border="0"></a>
<div class="majorheading">Staff Member Management for the <span class="AdminHeadingSiteName"><cfoutput>#application.SLCMS.config.base.SiteName#</cfoutput></span> website</div>

<div>This means all of the people that can manage the website not the website subscribers, general users, etc.</div>
<div class="HeadNavigation">
<cfif application.SLCMS.core.UserPermissions.IsLoggedin()>
	<a href="AdminHome.cfm">Back to Site Administration Home Page</a><!--- any other menu items --->
<cfelse>
	You are not Signed in: <a href="AdminLogin.cfm">Go to Sign In Page</a>
	</div></body></html>	<!--- tidy up the html so we still have a green tick --->
	<cfabort>
</cfif>
</div>
 --->
<cfif DispMode eq "AddUser" or DispMode eq "EditUser">
	<cfoutput>
	| #linkTo(text="#backLinkText#Back to Staff Administration", controller="slcms.adminStaff", action="index", params="#PageContextFlags.ReturnLinkParams#")#</cfoutput>
</cfif>
<cfif application.SLCMS.core.UserPermissions.HasSiteAdminPermission()>
	<table border="0" cellpadding="3" cellspacing="0" >	<!--- this table has the page/menu content --->
<!--- 
	<cfif len(ErrMsg)><tr><td align="left" colspan="3" class="warnColour">Error:- <cfoutput>#ErrMsg#</cfoutput></td></tr></cfif>
	<cfif len(GoodMsg)><tr><td align="left" colspan="3" class="goodColour">Result:- <cfoutput>#GoodMsg#</cfoutput></td></tr></cfif>
	<tr><td colspan="3"></td></tr>
 --->
	<cfif DispMode eq ""><cfoutput>
		<tr><td></td><td colspan="2"></td></tr>
		<tr><td colspan="3" align="left"></cfoutput>
	<cfelseif DispMode eq "AddUser" or DispMode eq "EditUser">
		<cfoutput>
		<form name="theForm" action="#application.SLCMS.Paths_Admin.AdminBaseURL#admin-staff?#PageContextFlags.ReturnLinkParams#&amp;mode=#opnext#" method="post">
		<input type="hidden" name="SubsiteList" value="#theAllowedSubsiteList#">
		</cfoutput>
		<table border="0" cellpadding="3" cellspacing="0" align="left">
		<cfloop from="1" to="#ArrayLen(theDisplayArray)#" index="lcntr">
			<cfif theDisplayArray[lcntr].ThisSubSiteWasClicked><cfoutput>
				<input type="hidden" name="ClickedSubSiteID" value="#theClickedSubSite#">
				<input type="hidden" name="UserID" value="#theDisplayArray[lcntr].UserID#">
				<input type="hidden" name="OldFirstName" value="#theDisplayArray[lcntr].User_FirstName#">
				<input type="hidden" name="OldLastName" value="#theDisplayArray[lcntr].User_LastName#">
				<input type="hidden" name="OldLogin" value="#theDisplayArray[lcntr].User_Login#">
				<input type="hidden" name="OldPassword" value="#theDisplayArray[lcntr].User_Password#"></cfoutput>
				<tr><td colspan="3" align="center"><span class="minorheadingText">
					<cfif DispMode eq "AddUser">Adding a New Staff Member
					<cfelse>Properties of Staff Member:<span class="minorheadingName"><cfoutput> #dUser_FullName#</cfoutput></span>
					</cfif>
					</span></td></tr>
				<tr><td colspan="3"></td></tr>
				<!--- the common data --->
				<tr>
					<td colspan="1">First Name: </td>
					<td colspan="2"><input type="text" name="user_FirstName" value="<cfoutput>#theDisplayArray[lcntr].User_FirstName#</cfoutput>" size="40" maxlength="64"></td></tr>
				<tr>
					<td colspan="1">Last Name: </td>
					<td colspan="2"><input type="text" name="user_LastName" value="<cfoutput>#theDisplayArray[lcntr].User_LastName#</cfoutput>" size="40" maxlength="64"></td></tr>
				<tr>
					<td colspan="1">Sign In: </td>
					<td colspan="2"><input type="text" name="User_Login" value="<cfoutput>#theDisplayArray[lcntr].User_Login#</cfoutput>" size="40" maxlength="64"></td></tr>
				<tr>
					<td colspan="1">Password: </td>
					<td colspan="2"><input type="text" name="User_Password" value="<cfoutput>#theDisplayArray[lcntr].User_Password#</cfoutput>" size="40" maxlength="64"></td></tr>
				<tr>
					<td colspan="1">Email Address: </td>
					<td colspan="2"><input type="text" name="User_Eddress" value="<cfoutput>#theDisplayArray[lcntr].User_Eddress#</cfoutput>" size="40" maxlength="255"></td></tr>
			</cfif>
		</cfloop>
		<tr><td colspan="3"></td></tr>
		<!--- now the roles per site --->
		<tr><td colspan="3" align="center"><span class="minorheadingText">
			<cfif DispMode eq "AddUser">Roles for the New User per Site
			<cfelse>Roles for <cfoutput>#dUser_FullName#</cfoutput> per Site
			</cfif>
			</span></td></tr>
		<cfloop from="1" to="#ArrayLen(theDisplayArray)#" index="lcntr"><cfoutput>
			<tr><td colspan="3"><u><strong>Site: #theDisplayArray[lcntr].SubSiteFriendlyName#</strong></u></td></tr>
			<tr>
				<td colspan="1">Can Manage this site </td>
				<td align="right">Yes: </td>
				<td colspan="1">
					<input type="radio" name="Site_#theDisplayArray[lcntr].SubSiteID#_UserCanManage" value="1"<cfif theDisplayArray[lcntr].CanManage> checked="checked"</cfif>>
					|
					<input type="radio" name="Site_#theDisplayArray[lcntr].SubSiteID#_UserCanManage" value="0"<cfif not theDisplayArray[lcntr].CanManage> checked="checked"</cfif>>
					:No
				</td>
			</tr>
			<tr>
				<td colspan="1">Active for this site </td>
				<td align="right">Enabled: </td>
				<td colspan="1">
					<input type="radio" name="Site_#theDisplayArray[lcntr].SubSiteID#_User_Active" value="1"<cfif theDisplayArray[lcntr].User_Active> checked="checked"</cfif>>
					|
					<input type="radio" name="Site_#theDisplayArray[lcntr].SubSiteID#_User_Active" value="0"<cfif not theDisplayArray[lcntr].User_Active> checked="checked"</cfif>>
					:Disabled
				</td>
			</tr>
			<tr><td colspan="3"><strong>Global Roles that apply across all aspects</strong></td></tr>
			<tr>
				<td colspan="1">Has Administrator Role: </td>
				<td colspan="2">
					Yes <input type="radio" name="Site_#theDisplayArray[lcntr].SubSiteID#_IsAdmin_Global" value="1"<cfif BitAnd(theDisplayArray[lcntr].Global_RoleValue, theRolePatterns.core.Global.Admin.RoleValue) neq 0> checked=checked</cfif>> &nbsp;| &nbsp;
					No <input type="radio" name="Site_#theDisplayArray[lcntr].SubSiteID#_IsAdmin_Global" value="0"<cfif BitAnd(theDisplayArray[lcntr].Global_RoleValue, theRolePatterns.core.Global.Admin.RoleValue) eq 0> checked=checked</cfif>>
				</td></tr>
			<tr>
				<td colspan="1">Has Editor Role: </td>
				<td colspan="2">
					Yes <input type="radio" name="Site_#theDisplayArray[lcntr].SubSiteID#_IsEditor_Global" value="1"<cfif BitAnd(theDisplayArray[lcntr].Global_RoleValue, theRolePatterns.core.Global.Editor.RoleValue) neq 0> checked=checked</cfif>> &nbsp;| &nbsp;
					No <input type="radio" name="Site_#theDisplayArray[lcntr].SubSiteID#_IsEditor_Global" value="0"<cfif BitAnd(theDisplayArray[lcntr].Global_RoleValue, theRolePatterns.core.Global.Editor.RoleValue) eq 0> checked=checked</cfif>>
				</td></tr>
			<tr>
				<td colspan="1">Has Author Role: </td>
				<td colspan="2">
					Yes <input type="radio" name="Site_#theDisplayArray[lcntr].SubSiteID#_IsAuthor_Global" value="1"<cfif BitAnd(theDisplayArray[lcntr].Global_RoleValue, theRolePatterns.core.Global.Author.RoleValue) neq 0> checked=checked</cfif>> &nbsp;| &nbsp;
					No <input type="radio" name="Site_#theDisplayArray[lcntr].SubSiteID#_IsAuthor_Global" value="0"<cfif BitAnd(theDisplayArray[lcntr].Global_RoleValue, theRolePatterns.core.Global.Author.RoleValue) eq 0> checked=checked</cfif>>
				</td></tr>
			<tr><td colspan="3"></td></tr>
			<tr><td colspan="3"><strong>Content-only Management Roles</strong></td></tr>
			<tr>
				<td colspan="1">Has Editor Role: </td>
				<td colspan="2">
					Yes <input type="radio" name="Site_#theDisplayArray[lcntr].SubSiteID#_IsEditor_Content" value="1"<cfif BitAnd(theDisplayArray[lcntr].Global_RoleValue, theRolePatterns.core.Content.Editor.RoleValue) neq 0> checked=checked</cfif>> &nbsp;| &nbsp;
					No <input type="radio" name="Site_#theDisplayArray[lcntr].SubSiteID#_IsEditor_Content" value="0"<cfif BitAnd(theDisplayArray[lcntr].Global_RoleValue, theRolePatterns.core.Content.Editor.RoleValue) eq 0> checked=checked</cfif>>
				</td></tr>
			<tr>
				<td colspan="1">Has Author Role: </td>
				<td colspan="2">
					Yes <input type="radio" name="Site_#theDisplayArray[lcntr].SubSiteID#_IsAuthor_Content" value="1"<cfif BitAnd(theDisplayArray[lcntr].Global_RoleValue, theRolePatterns.core.Content.Author.RoleValue) neq 0> checked=checked</cfif>> &nbsp;| &nbsp;
					No <input type="radio" name="Site_#theDisplayArray[lcntr].SubSiteID#_IsAuthor_Content" value="0"<cfif BitAnd(theDisplayArray[lcntr].Global_RoleValue, theRolePatterns.core.Content.Author.RoleValue) eq 0> checked=checked</cfif>>
				</td></tr>
			<tr><td colspan="3"></td></tr></cfoutput>
		</cfloop>	<!--- end: loop over subsites --->
		<tr>
			<td><!--- <input type="submit" name="Cancel" value="Cancel/Back"> ---></td>
			<td colspan="2"><input type="submit" name="Save" value="<cfif DispMode is 'AddUser'>Create New Staff Member<cfelse>Save Changes</cfif>" onClick="return checkEmpty('User')"></td>
			</tr>
		</table>
		</form>
		</td></tr>
	<cfelseif DispMode eq "ShowUserList">
		<!--- loop over the user tables to grab each set of users that we are allowed to see --->
		<tr><td colspan="3">
		<table border="0" cellpadding="3" cellspacing="0" width="100%">
		<cfset StructClear(theQueryWhereArguments) />	<!--- just clear it once before the loop as we are just grabbing everything each time --->
		<cfloop list="#theAllowedSubsiteList#" index="thisSubSite">
			<cfset theTableName = application.SLCMS.config.DatabaseDetails.DatabasetableNaming_Root_Site 
														& thisSubSite 
														& application.SLCMS.config.DatabaseDetails.databaseTableNaming_Tail_SiteAdminDetail />
			<cfset getUsers = application.SLCMS.core.DataMgr.getRecords(tablename="#theTableName#", data=theQueryWhereArguments, fieldList="StaffID,Staff_SignIn,Staff_Password,Staff_FirstName,Staff_LastName,Staff_Eddress,User_Active,Global_RoleBits,Global_RoleValue", orderby="Staff_LastName") />
			<!--- 
			<cfquery name="getUsers" datasource="#application.SLCMS.config.datasources.CMS#">
				SELECT	UserID, User_Login, User_Password, User_Fullname, User_Eddress, User_Active, Global_RoleBits, Global_RoleValue
					FROM	#theTableName#
					Order By	User_Fullname
			</cfquery>
			 --->
			<cfset theSubSiteDetails = application.SLCMS.core.PortalControl.GetSubSite(subsiteID="#thisSubSite#") />
			<tr><td colspan="13"><strong>Site: <cfoutput>#theSubSiteDetails.data.SubSiteFriendlyName#</cfoutput></strong></td></tr>
			<tr>
				<td rowspan="2" class="WorkTableTopRow">User's Full Name</td>
				<td rowspan="2" class="WorkTableTopRow">Sign In</td>
				<td rowspan="2" class="WorkTableTopRow">Password</td>
				<td rowspan="2" class="WorkTableTopRow">Email Address</td>
				<td rowspan="2" class="WorkTableTopRow">Active</td>
				<td colspan="3" align="center" class="WorkTableTopRow">Global Roles</td>
				<td colspan="2" align="center" class="WorkTableTopRow">Content-only Roles</td>
				<td colspan="2" rowspan="2" class="WorkTableTopRowRHCol" align="center">
					<cfoutput>#linkTo(text="Add a Staff Member", controller="slcms.admin-staff", action="index", params="#PageContextFlags.ReturnLinkParams#&amp;mode=addUser&amp;SiteID=#thisSubSite#")#</cfoutput>
					<!--- 
					<a href="Admin_Users.cfm?mode=addUser&amp;SiteID=<cfoutput>#thisSubSite#</cfoutput>">Add a User</a>
					 --->
				</td>
			</tr>
			<tr>
				<td class="WorkTable2ndRow">Administrator</td>
				<td class="WorkTable2ndRow">Editor</td>
				<td class="WorkTable2ndRow">Author</td>
				<td class="WorkTable2ndRow">Editor</td>
				<td class="WorkTable2ndRow">Author</td>
			</tr>
			<cfif getUsers.RecordCount>
				<cfoutput query="getUsers">
					<cfset thisUserFullName = "#getUsers.Staff_FirstName# #getUsers.Staff_LastName#" />
<!--- 
				<cfif BitAnd(getUsers.Global_RoleValue, 128) eq 0>
 --->
				<tr>
					<td class="WorkTableRowColour1">#thisUserFullName#</td>
					<td class="WorkTableRowColour1">#getUsers.Staff_SignIn#</td>
					<td class="WorkTableRowColour1">#getUsers.Staff_Password#</td>
					<td class="WorkTableRowColour1">#getUsers.Staff_Eddress#</td>
					<td align="center" class="WorkTableRowColour1">#YesNoFormat(User_Active)#</td>
					<td align="center" class="WorkTableRowColour1"><cfif BitAnd(getUsers.Global_RoleValue, theRolePatterns.core.Global.Admin.RoleValue) gt 0>Yes<cfelse>No</cfif></td>
					<td align="center" class="WorkTableRowColour1"><cfif BitAnd(getUsers.Global_RoleValue, theRolePatterns.core.Global.Editor.RoleValue) gt 0>Yes<cfelse>No</cfif></td>
					<td align="center" class="WorkTableRowColour1"><cfif BitAnd(getUsers.Global_RoleValue, theRolePatterns.core.Global.Author.RoleValue) gt 0>Yes<cfelse>No</cfif></td>
					<td align="center" class="WorkTableRowColour1"><cfif BitAnd(getUsers.Global_RoleValue, theRolePatterns.core.Content.Editor.RoleValue) gt 0>Yes<cfelse>No</cfif></td>
					<td align="center" class="WorkTableRowColour1"><cfif BitAnd(getUsers.Global_RoleValue, theRolePatterns.core.Content.Author.RoleValue) gt 0>Yes<cfelse>No</cfif></td>
					<td align="center" class="WorkTableRowColour1">
						#linkTo(text="Change", controller="slcms.admin-staff", action="index", params="#PageContextFlags.ReturnLinkParams#&amp;mode=EditUser&amp;UserID=#getUsers.StaffID#&amp;SiteID=#thisSubSite#")#
						<!--- 
						<a href="Admin_Users.cfm?mode=EditUser&amp;UserID=#getUsers.StaffID#&amp;SiteID=#thisSubSite#">Change</a>
						 --->
					</td>
					<td align="center" class="WorkTableRowColour1withRH">
						#linkTo(text="Delete", controller="slcms.admin-staff", action="index", params="#PageContextFlags.ReturnLinkParams#&amp;mode=DeleteUser&amp;UserID=#getUsers.StaffID#&amp;SiteID=#thisSubSite#", confirm="Are you sure you want to Delete user: #thisUserFullName#?")#
						<!--- 
						<a href="Admin_Users.cfm?mode=DeleteUser&amp;UserID=#getUsers.StaffID#&amp;SiteID=#thisSubSite#"  onclick="return confirm('Are you sure you want to Delete user: #thisUserFullName#?')">Delete</a>
						 --->
					</td>
				</tr>
<!--- 
				</cfif>		
 --->
				</cfoutput>
			<cfelse>
				<tr><td colspan="13">There are no Site Management Staff yet for site: <cfoutput>#theSubSiteDetails.data.SubSiteFriendlyName#</cfoutput></td></tr>
			</cfif>
			<tr><td colspan="13">&nbsp;</td></tr>
		</cfloop>
		</table>
		</td></tr>
	</cfif>
	</table>
</cfif>	<!--- end: HasSiteAdminPermission --->
</body>
</html>
