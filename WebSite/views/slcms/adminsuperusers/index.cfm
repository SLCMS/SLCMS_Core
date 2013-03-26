
<!--- security check code, bots fail here --->
<cfif StructKeyExists(params, "SecID")>
	<cfset theInboundSecurityID = params.SecID />
<cfelse>
	<cfset theInboundSecurityID = "" />
</cfif>

<cfif (application.SLCMS.core.UserPermissions.HasSiteAdminPermission() or (structKeyExists(params, "SourcePage") and params.SourcePage eq "FromEmptySiteWorkflow")) and theInboundSecurityID eq session.SLCMS.user.security.thisPageSecurityID>
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
		<cfset opnext = "SaveAddUser">	<!--- what we do next --->
		<cfset dstaffID = 0 />
		<cfset dstaff_Eddress = "" />
		<cfset dstaff_Firstname = "" />
		<cfset dstaff_Lastname = "" />
		<cfset dstaff_SignIn = "" />
		<cfset dstaff_Password = "" />
		<cfset dstaff_Login = "" />
		<cfset dUser_Active = 0 />
		<cfset DispMode = "addUser">
		<cfset backLinkText = "Cancel Adding Super Administrators, " />	<!--- cancel link at top --->
	
	<cfelseif WorkMode1 eq "SaveAddUser">
		<!--- save a user into the system --->
		<cfparam name="form.SourcePage" default="Local">
		<!--- first check that we have valid input --->
		<cfset OK = True />
		<cfif form.SourcePage eq "FromEmptySiteWorkflow">
			<cfset theLogin = form.SignIn_Empty />
			<cfset thePassword = form.Password_Empty />
		<cfelse>
			<cfset theLogin = form.SignIn />
			<cfset thePassword = form.Password />
		</cfif>
		<cfif len(theLogin) eq 0>
			<cfset OK = False />
			<cfset ErrFlag  = True>
			<cfset ErrMsg  = ErrMsg & "No Login Supplied<br>">
		</cfif>
		<cfif len(thePassword) eq 0>
			<cfset OK = False />
			<cfset ErrFlag  = True>
			<cfset ErrMsg  = ErrMsg & "No Password Supplied<br>">
		</cfif>
		<cfset theFirstName = form.FirstName />
		<cfset theLastName = form.LastName />
		<cfif len(theFirstName) eq 0 and len(theLastName) eq 0>
			<cfset OK = False />
			<cfset ErrFlag  = True>
			<cfset ErrMsg  = ErrMsg & "No Name Supplied<br>">
		</cfif>
		<cfset theEddress = form.Eddress />
		<cfif theEddress neq "" and application.SLCMS.mbc_utility.Utilities.IsValidEddress(theEddress) eq False>
			<cfset OK = False />
			<cfset ErrFlag  = True>
			<cfset ErrMsg  = ErrMsg & "Invalid Email Address Supplied<br>">
		</cfif>
		<cfif form.SourcePage eq "FromEmptySiteWorkflow">
			<cfset theActiveBit = 1 />	<!--- as this is our inital UberAdmin we need to turn them straight on --->
			<cfset DispSubMode1 = "FromEmptySiteWorkflow" />	<!--- change to flag we came from the EmptySiteWorkflow startup page --->
		<cfelse>
			<cfset theActiveBit = form.User_Active />	<!--- inactive is the default, turned on when ready --->
		</cfif>
		<!--- we now have relevant bits so see if we are duplicating --->
		<cfset StructClear(theQueryWhereArguments) />
		<cfset theQueryWhereArguments.staff_SignIn = theLogin />
		<cfset theQueryWhereArguments.staff_Password = thePassword />
		<cfset getUser = application.SLCMS.core.DataMgr.getRecords(tablename="#application.SLCMS.config.DatabaseDetails.TableName_SystemAdminDetailsTable#", data=theQueryWhereArguments, fieldList="staffID,staff_SignIn") />
		<!--- 
		<cfquery name="getUser" datasource="#application.config.datasources.CMS#">
			SELECT	UserID
				FROM	#application.config.DatabaseDetails.TableName_SystemAdminDetailsTable#
				Where User_Login = <cfqueryparam value="#theLogin#" cfsqltype="cf_sql_varchar" list="false" maxlength="50">
					and User_Password = <cfqueryparam value="#thePassword#" cfsqltype="cf_sql_varchar" list="false" maxlength="50">
		</cfquery>
		 --->
		<cfif getUser.RecordCount>
			<cfset OK = False />
			<cfset ErrFlag  = True>
			<cfset ErrMsg  = ErrMsg & "That Login/Password Combination already exists<br>">
		</cfif>
		<!--- and calculate the bits and values for the roles --->
		<cfset theRoleBits = "11111111111111111111111111111111" />	<!--- that's everything :-) --->
		<cfset theRoleValue = application.SLCMS.mbc_utility.Utilities.Bits32ToInt(theRoleBits) />
		<cfif OK>
			<!--- all OK so save the user --->
			<cfset StructClear(theQueryDataArguments) />
			<cfset theQueryDataArguments.staffID = Nexts_getNextID('UserID') />
			<cfset theQueryDataArguments.staff_SignIn = theLogin />
			<cfset theQueryDataArguments.staff_Password = thePassword />
			<cfset theQueryDataArguments.staff_FirstName = theFirstName />
			<cfset theQueryDataArguments.staff_LastName = theLastName />
			<cfset theQueryDataArguments.staff_Eddress = theEddress />
			<cfset theQueryDataArguments.Global_RoleBits = theRoleBits />
			<cfset theQueryDataArguments.Global_RoleValue = theRoleValue />
			<cfset theQueryDataArguments.User_Active = theActiveBit />
			<cfset addUser = application.SLCMS.core.DataMgr.InsertRecord(tablename="#application.SLCMS.config.DatabaseDetails.TableName_SystemAdminDetailsTable#", data=theQueryDataArguments) />
			<!--- 
			<cfset NewUserID = application.SLCMS.mbc_utility.utilities.getnextID("UserID") />
			<cfquery name="addUser" datasource="#application.config.datasources.CMS#">
				Insert Into	#application.config.DatabaseDetails.TableName_SystemAdminDetailsTable#
									(UserID, User_Login, User_Password, User_Fullname, User_Eddress, Global_RoleBits, Global_RoleValue, User_Active)
					Values	(#NewUserID#, 
									<cfqueryparam value="#theLogin#" cfsqltype="cf_sql_varchar" list="false" maxlength="50">, 
									<cfqueryparam value="#thePassword#" cfsqltype="cf_sql_varchar" list="false" maxlength="50">, 
									<cfqueryparam value="#theFullName#" cfsqltype="cf_sql_varchar" list="false" maxlength="50">, 
									<cfqueryparam value="#theEddress#" cfsqltype="cf_sql_varchar" list="false" maxlength="255">, 
									'#theRoleBits#', #theRoleValue#, #theActiveBit#)
			</cfquery>
			 --->
			<!--- refresh the user managment system --->
			<cfset application.SLCMS.core.UserControl.RefreshAdminDetails() />
			<cfset GoodMsg = "New Supervisor &quot;#theFirstName# #theLastName#&quot; saved" />"
			<!--- finished so back to the listing --->
			<cfset WorkMode2 = "GetUserList">
			<cfset DispMode = "ShowUserList">
			<cfset backLinkText = "" />
		<cfelse>
			<!--- It was not good so back to the form with message --->
			<cfif form.SourcePage eq "FromEmptySiteWorkflow">
				<cfset $include(template="SLCMS/_EmptySiteWorkflow_inc.cfm") />
				<cfabort>
			<cfelseif form.SourcePage eq "local">
				<cfset opnext = "SaveAddUser">	<!--- what we do next --->
				<cfset dstaffID = 0 />
				<cfset dstaff_Eddress = theEddress />
				<cfset dstaff_Firstname = theFirstName />
				<cfset dstaff_Lastname = theLastName />
				<cfset dstaff_SignIn = theLogin />
				<cfset dstaff_Password = thePassword />
				<cfset dUser_Active = theActiveBit />
				<cfset DispMode = "addUser">
				<cfset backLinkText = "Cancel Adding Super Administrators, " />	<!--- cancel link at top --->
			</cfif>
		</cfif>
	
	<cfelseif WorkMode1 eq "EditUser">
		<!--- set up to edit a user to the system --->
		<cfset StructClear(theQueryWhereArguments) />
		<cfset theQueryWhereArguments.staffID = url.staffID />
		<cfset getUser = application.SLCMS.core.DataMgr.getRecords(tablename="#application.SLCMS.config.DatabaseDetails.TableName_SystemAdminDetailsTable#", data=theQueryWhereArguments, fieldList="staffID,staff_SignIn,staff_Password,staff_Firstname,staff_Lastname,staff_Eddress,User_Active,Global_RoleBits,Global_RoleValue") />
		<!--- 
		<cfquery name="getUser" datasource="#application.config.datasources.CMS#">
			SELECT	UserID, User_Login, User_Password, User_Fullname, User_Eddress, User_Active, Global_RoleBits, Global_RoleValue
				FROM	#application.config.DatabaseDetails.TableName_SystemAdminDetailsTable#
				Where UserId = <cfqueryparam value="#url.userId#" cfsqltype="cf_sql_integer">
		</cfquery>
		 --->
		<cfset opnext = "SaveEditUser">	<!--- what we do next --->
		<cfset dstaffID = getUser.staffID />
		<cfset dstaff_Firstname = getUser.staff_FirstName />
		<cfset dstaff_Lastname = getUser.staff_LastName />
		<cfset dstaff_Password = getUser.staff_Password />
		<cfset dstaff_Eddress = getUser.staff_Eddress />
		<cfset dUser_Active = getUser.User_Active />
		<cfset dstaff_SignIn = getUser.staff_SignIn />
		<cfset dGlobal_RoleValue = getUser.Global_RoleValue />
		<cfset DispMode = "EditUser">
		<cfset backLinkText = "Cancel Editing a Super Administrator, " />	<!--- cancel link at top --->
	
	<cfelseif WorkMode1 eq "SaveEditUser">
		<!--- save an edited user into the system --->
		<!--- first check that we have valid input --->
		<cfset OK = True />
		<cfset theLogin = form.SignIn />
		<cfif len(theLogin) eq 0>
			<cfset OK = False />
			<cfset ErrFlag  = True>
			<cfset ErrMsg  = ErrMsg & "No Login Supplied<br>">
		</cfif>
		<cfset thePassword = form.Password />
		<cfif len(thePassword) eq 0>
			<cfset OK = False />
			<cfset ErrFlag  = True>
			<cfset ErrMsg  = ErrMsg & "No Password Supplied<br>">
		</cfif>
		<cfset theFirstName = form.FirstName />
		<cfset theLastName = form.LastName />
		<cfif len(theFirstName) eq 0 and len(theLastName) eq 0>
			<cfset OK = False />
			<cfset ErrFlag  = True>
			<cfset ErrMsg  = ErrMsg & "No Name Supplied<br>">
		</cfif>
		<cfset theEddress = form.Eddress />
		<cfif theEddress neq "" and application.SLCMS.mbc_utility.Utilities.IsValidEddress(theEddress) eq False>
			<cfset OK = False />
			<cfset ErrFlag  = True>
			<cfset ErrMsg  = ErrMsg & "Invalid Email Address Supplied<br>">
		</cfif>
		<!--- we now have relevant bits so see if we are duplicating --->
		<cfset StructClear(theQueryWhereArguments) />
		<cfset ArrayClear(theQueryWhereFilters) />
		<cfset theQueryWhereArguments.staff_SignIn = theLogin />
		<cfset theQueryWhereArguments.staff_Password = thePassword />
		<cfset theQueryWhereFilters[1] = {field="staffId", operator="<>", value="#form.staffId#"} />
		<cfset getUser = application.SLCMS.core.DataMgr.getRecords(tablename="#application.SLCMS.config.DatabaseDetails.TableName_SystemAdminDetailsTable#", data=theQueryWhereArguments, filters=theQueryWhereFilters, fieldList="staffID") />
		<!--- 
		<cfquery name="getUser" datasource="#application.config.datasources.CMS#">
			SELECT	UserID
				FROM	#application.config.DatabaseDetails.TableName_SystemAdminDetailsTable#
				Where User_Login = <cfqueryparam value="#theLogin#" cfsqltype="cf_sql_varchar" list="false" maxlength="50">
					and User_Password = <cfqueryparam value="#thePassword#" cfsqltype="cf_sql_varchar" list="false" maxlength="50">
					and UserId <> <cfqueryparam value="#form.userId#" cfsqltype="cf_sql_integer">
		</cfquery>
		 --->
		<cfif getUser.RecordCount>
			<cfset OK = False />
			<cfset ErrFlag  = True>
			<cfset ErrMsg  = ErrMsg & "That Login/Password Combination already exists for another User<br>">
		</cfif>
		<!--- and calculate the bits and values for the roles --->
		<cfset theRoleBits = "11111111111111111111111111111111" />	<!--- that's everything :-) --->
		<cfset theRoleValue = application.SLCMS.mbc_utility.Utilities.Bits32ToInt(theRoleBits) />
		<cfif OK>
			<!--- all OK so save the edits --->
			<cfset StructClear(theQueryDataArguments) />
			<cfset StructClear(theQueryWhereArguments) />
			<cfset theQueryDataArguments.staff_SignIn = theLogin />
			<cfset theQueryDataArguments.staff_Password = thePassword />
			<cfset theQueryDataArguments.staff_Firstname = theFirstName />
			<cfset theQueryDataArguments.staff_Lastname = theLastName />
			<cfset theQueryDataArguments.staff_Eddress = theEddress />
			<cfset theQueryDataArguments.User_Active = form.User_Active />
			<cfset theQueryDataArguments.Global_RoleBits = theRoleBits />
			<cfset theQueryDataArguments.Global_RoleValue = theRoleValue />
			<cfset theQueryWhereArguments.staffID = form.staffID />
			<cfset addUser = application.SLCMS.core.DataMgr.UpdateRecords(tablename="#application.SLCMS.config.DatabaseDetails.TableName_SystemAdminDetailsTable#", data_set=theQueryDataArguments, data_where=theQueryWhereArguments) />
			<!--- 
			<cfquery name="EditUser" datasource="#application.config.datasources.CMS#">
				Update	#application.config.DatabaseDetails.TableName_SystemAdminDetailsTable#
					set		User_Login = <cfqueryparam value="#theLogin#" cfsqltype="cf_sql_varchar" list="false" maxlength="50">,  
								User_Password = <cfqueryparam value="#thePassword#" cfsqltype="cf_sql_varchar" list="false" maxlength="50">,  
								User_Fullname = <cfqueryparam value="#theFullname#" cfsqltype="cf_sql_varchar" list="false" maxlength="255">,  
								User_Eddress = 	<cfqueryparam value="#theEddress#" cfsqltype="cf_sql_varchar" list="false" maxlength="255">, 
								User_Active = 	<cfqueryparam value="#form.User_Active#" cfsqltype="cf_sql_bit">, 
								Global_RoleBits = '#theRoleBits#',
								Global_RoleValue = #theRoleValue#
					where	UserId = <cfqueryparam value="#form.userId#" cfsqltype="cf_sql_integer">
			</cfquery>
			 --->
			<!--- refresh the user managment system --->
			<cfset application.SLCMS.core.UserControl.RefreshAdminDetails() />
			<cfset GoodMsg = "Edits to Supervisor &quot;#theFirstName# #theLastName#&quot; have been saved" />"
			<!--- finished so back to the listing --->
			<cfset WorkMode2 = "GetUserList">
			<cfset DispMode = "ShowUserList">
			<cfset backLinkText = "" />
		<cfelse>
			<!--- It was not good so back to the form with message --->
			<cfif form.SourcePage eq "FromEmptySiteWorkflow">
				<cfinclude template="#application.SLCMS.config.Base.rootURL#__EmptySiteWorkflow.cfm">
				<cfabort>
			<cfelseif form.SourcePage eq "local">
				<cfset opnext = "SaveEditUser">	<!--- what we do next --->
				<cfset dstaffID = form.userId />
				<cfset dstaff_Eddress = theEddress />
				<cfset dstaff_Firstname = theFirstName />
				<cfset dstaff_Lastname = theLastName />
				<cfset dstaff_SignIn = theLogin />
				<cfset dstaff_Password = thePassword />
				<cfset dUser_Active = theActiveBit />
<!--- 
			<cfset dUserID = form.userId />
			<cfset dUser_FirstName = theFirstName />
			<cfset dUser_LastName = theLastName />
			<cfset dUser_Password = thePassword />
			<cfset dUser_Eddress = theEddress />
			<cfset dUser_Login = theLogin />
			<cfset dUser_Active = form.User_Active />
			<cfset dGlobal_RoleValue = theRoleValue />
			 --->
				<cfset DispMode = "EditUser">
				<cfset backLinkText = "Cancel Editing a Super Administrator, " />	<!--- cancel link at top --->
			</cfif>
		</cfif>
	
	<cfelseif WorkMode1 eq "DeleteUser">
		<!--- delete a user from the system --->
		<cfset StructClear(theQueryWhereArguments) />
		<cfset theQueryWhereArguments.staffId = url.staffId />
		<cfset delUser = application.SLCMS.core.DataMgr.deleteRecords(tablename="#application.SLCMS.config.DatabaseDetails.TableName_SystemAdminDetailsTable#", data=theQueryWhereArguments) />
		<!--- 
		<cfquery name="EditUser" datasource="#application.config.datasources.CMS#">
			Delete from	#application.config.DatabaseDetails.TableName_SystemAdminDetailsTable#
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
	<cfelseif WorkMode2 eq "GetUserList">
		<!--- do things --->
		<cfquery name="getUsers" datasource="#application.SLCMS.config.datasources.CMS#">
			SELECT	staffID, staff_SignIn, staff_Password, staff_Firstname, staff_Lastname, staff_Eddress, User_Active, Global_RoleBits, Global_RoleValue
				FROM	#application.SLCMS.config.DatabaseDetails.TableName_SystemAdminDetailsTable#
				Order By	staff_LastName
		</cfquery>
		<cfset DispMode = "ShowUserList">
	</cfif>
</cfif>	<!--- end: HasSiteAdminPermission --->

<cfsavecontent variable="headStuff">
	<script type="text/javascript">
		$(document).ready(function() {
			var AJAXurl = <cfoutput>'#application.SLCMS.Paths_Common.RootURL#global/installAssist/ClientComms.cfm';</cfoutput>
			// Help tips plugin
			JT_init();
			// handlers
			$('#LastName').blur(function(){
				var theFirstName = $('#FirstName').val();
				var theLastName = $('#LastName').val();
				var theSignIn = $('#SignIn').val();
				if (theSignIn == '') {
					$.ajax({
						type:'GET',
						url: AJAXurl,
						data: {Job: 'MakeSignInWord', FirstName: theFirstName, LastName: theLastName},
						success: function(data){
							var theSignIn = $.trim(data)
							$('#SignIn').val(theSignIn);
						}
					});
				}
			});
			$('#Password_2').blur(function(){
				var thePassword_2 = $('#Password_2').val();
				if (thePassword_2 == '') {
					alert('Password Cannot Be Blank!');
					return false;
				}
				CheckPassWord();
			});
			$('#CreateSuperUserButton').click(function(){
				return CheckPassWord();
			});
			function CheckPassWord() {
				var thePassword_1 = $('#Password_1').val();
				var thePassword_2 = $('#Password_2').val();
				if (thePassword_1 != thePassword_2) {
					alert('Passwords Do Not Match!');
					return false;
				}
				return true;
			}
		});
	</script>
</cfsavecontent>
<cfhtmlhead text="#headStuff#">

<cfsetting enablecfoutputonly="No">
<cfoutput>#includePartial("/slcms/adminbanner")#</cfoutput><!--- show the banner if we are in the backend, returns nothing if we are popped up --->
<cfif DispMode eq "AddUser" or DispMode eq "EditUser">
	<cfoutput>| #linkTo(text="#backLinkText#Back to Super Adminstration", controller="slcms.adminSuperusers", action="index", params="#PageContextFlags.ReturnLinkParams#")#</cfoutput>
</cfif>
<!--- 
<cfif application.SLCMS.core.UserPermissions.IsLoggedin()>
<div class="majorheading">SuperUser Management for the <span class="AdminHeadingSiteName"><cfoutput>#application.SLCMS.config.base.SiteName#</cfoutput></span> website</div>
<div>That means all of the users that have Supervisory control over the whole website, not subsites or website subscribers, etc.</div>
 --->
<cfif application.SLCMS.core.UserPermissions.HasSiteAdminPermission()>
	<table border="0" cellpadding="3" cellspacing="0" >	<!--- this table has the page/menu content --->
	<cfif DispMode eq ""><cfoutput>
		<tr><td></td><td colspan="2"></td></tr>
		<tr><td colspan="3" align="left"></cfoutput>
	<cfelseif DispMode eq "AddUser" or DispMode eq "EditUser">
		<cfoutput>
		<form name="theForm" action="#application.SLCMS.Paths_Admin.AdminBaseURL#admin-Superusers?#PageContextFlags.ReturnLinkParams#&amp;mode=#opnext#" method="post">
		<!--- 
		<form name="theForm" action="Admin_SuperUsers.cfm?mode=#opnext#" method="post">
			 --->
		<input type="hidden" name="SecID" value="#theInboundSecurityID#">
		<input type="hidden" name="staffID" value="#dstaffID#">
		<input type="hidden" name="OldFirstName" value="#dstaff_FirstName#">
		<input type="hidden" name="OldLastName" value="#dstaff_LastName#">
		<input type="hidden" name="OldLogin" value="#dstaff_SignIn#">
		<input type="hidden" name="OldPassword" value="#dstaff_Password#">
		</cfoutput>
		<table border="0" cellpadding="3" cellspacing="0" align="left">
		<tr><td colspan="5" align="center"><span class="minorheadingText">
			<cfif DispMode eq "AddUser">Adding a New SuperUser
			<cfelse>Properties of SuperUser:<span class="minorheadingName"><cfoutput> #dstaff_FirstName# #dstaff_LastName#</cfoutput></span>
			</cfif>
			</span></td></tr>
		<tr><td colspan="5"></td></tr>
		<tr>
			<td colspan="1">First Name: </td>
			<td colspan="4"><input type="text" name="FirstName" value="<cfoutput>#dstaff_FirstName#</cfoutput>" size="40" maxlength="255"></td></tr>
		<tr>
			<td colspan="1">Last Name: </td>
			<td colspan="4"><input type="text" name="LastName" value="<cfoutput>#dstaff_LastName#</cfoutput>" size="40" maxlength="255"></td></tr>
		<tr>
			<td colspan="1">Login: </td>
			<td colspan="4"><input type="text" name="SignIn" value="<cfoutput>#dstaff_SignIn#</cfoutput>" size="40" maxlength="50"></td></tr>
		<tr>
			<td colspan="1">Password: </td>
			<td colspan="4"><input type="text" name="Password" value="<cfoutput>#dstaff_Password#</cfoutput>" size="40" maxlength="50"></td></tr>
		<tr>
			<td colspan="1">Email Address: </td>
			<td colspan="4"><input type="text" name="Eddress" value="<cfoutput>#dstaff_Eddress#</cfoutput>" size="40" maxlength="255"></td></tr>
		<tr>
			<td align="right">Enabled: </td>
			<td colspan="4">
				<input type="radio" name="User_Active" value="1"<cfif dUser_Active> checked="checked"</cfif>>
				|
				<input type="radio" name="User_Active" value="0"<cfif not dUser_Active> checked="checked"</cfif>>
				:Disabled
			</td>
		</tr>
		<tr><td colspan="3"></td></tr>
		<tr>
			<td colspan="2"><!--- <input type="submit" name="Cancel" value="Cancel/Back"> ---></td>
			<td colspan="2"><input type="submit" name="Save" value="<cfif DispMode is 'AddUser'>Create New User<cfelse>Save Changes</cfif>"<!---  onClick="return checkEmpty('User')" --->></td>
			</tr>
		</table>
		</form>
		</td></tr>
		
	<cfelseif DispMode eq "ShowUserList"><cfoutput>
		<tr><td colspan="3" class="minorheading">
			#linkTo(text="Add a SuperUser", controller="slcms.admin-superusers", action="index", params="#PageContextFlags.ReturnLinkParams#&amp;mode=addUser")#
		</td></tr>
	  </cfoutput>
		<tr><td colspan="3"></td></tr>
		<tr><td colspan="3">
		<table border="0" cellpadding="3" cellspacing="0" class="worktable">
		<tr>
			<td rowspan="1" class="WorkTableTopRow">User's Full Name</td>
			<td rowspan="1" class="WorkTableTopRow">Login</td>
			<td rowspan="1" class="WorkTableTopRow">Password</td>
			<td rowspan="1" class="WorkTableTopRow">Email Address</td>
			<td rowspan="1" class="WorkTableTopRow">Status</td>
			<td colspan="2" rowspan="1" class="WorkTableTopRowRHcol">&nbsp;</td>
		</tr>
		<cfif getUsers.RecordCount>
			<cfoutput query="getUsers">
			<cfif BitAnd(getUsers.Global_RoleValue, 128) eq 128>
			<tr>
				<td class="WorkTableRowColour1">#getUsers.staff_Firstname# #getUsers.staff_Lastname#</td>
				<td class="WorkTableRowColour1">#getUsers.staff_SignIn#</td>
				<td class="WorkTableRowColour1">#getUsers.staff_Password#</td>
				<td class="WorkTableRowColour1">#getUsers.staff_Eddress#</td>
				<td class="WorkTableRowColour1"><cfif getUsers.User_Active>Active<cfelse>Inactive</cfif></td>
				<td class="WorkTableRowColour1">
					#linkTo(text="Edit", controller="slcms.adminSuperusers", action="index", params="#PageContextFlags.ReturnLinkParams#&amp;mode=EditUser&amp;staffID=#getUsers.staffID#")#
				</td>
				<td class="WorkTableRowColour1withRH">
					#linkTo(text="Delete", controller="slcms.adminSuperusers", action="index", params="#PageContextFlags.ReturnLinkParams#&amp;mode=DeleteUser&amp;staffID=#getUsers.staffID#")#
				</td>
			</tr>
			</cfif>
			</cfoutput>
		<cfelse>
			<tr><td colspan="7">There are no SuperUsers yet</td></tr>
		</cfif>

		</table>
		</td></tr>
	</cfif>
	</table>
</cfif>	<!--- end: has permission --->
</body>
</html>
