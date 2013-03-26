<!--- set the intial view state of the controls --->
<script type="text/javascript">
	$(document).ready(function() {
		var AJAXurl = <cfoutput>'#application.SLCMS.Paths_Admin.AjaxURL_Abs#'</cfoutput>;
		$("#EditControls a").click(function () {
			$("#EditControls a").toggle();
			$(".ContentContainer_Controls").toggle();
			$.ajax({
				type:'GET',
				url: AJAXurl,
				data: {Job: 'toggle', Work: 'containereditcontrolsshowing'},
				success: function(stuffBack){
					if(stuffBack.MESSAGE == 'showing') {
						$(".ContentContainer_Controls").show();
					} else {
						$(".ContentContainer_Controls").hide();
					}
				}
			});
		});		
	<cfif session.SLCMS.Currents.Admin.FrontEnd.ContainerEditControlsShowing>
		<cfset tempO = "none" />	<!--- just below us --->
		<cfset tempC = "inline" />	<!--- just below us --->
		$(".ContentContainer_Controls").show();
	<cfelse>
		<cfset tempO = "inline" />
		<cfset tempC = "none" />
		$(".ContentContainer_Controls").hide();
	</cfif>
	});
</script>
<cfoutput>
<div id="AdminPanelWrapper">
	<div id="AdminPanel">
		<div class="content clearfix">
			<iframe src="#application.SLCMS.Paths_Admin.AdminBaseURL#admin-home?#request.SLCMS.flags.PoppedAdminURLFlagString#" id="PopAdminiFrame"></iframe>
		</div>
	</div>
	<div class="tab">
		<ul class="login">
			<li class="left">&nbsp;</li>
			<li>&nbsp;</li>
			<li id="toggleAdminPanel">
				<a id="open" class="open" href="##">Show Admin Panel</a>
				<a id="close" style="display: none;" class="close" href="##">Hide Admin Panel</a>			
			</li>
		</ul> 
		<div class="BaseControls">
			<div id="EditControls">
				<a id="ECopen" style="display: #tempO#;" class="ECopen" href="##">Show Edit Controls</a>
				<a id="ECclose" style="display: #tempC#;" class="ECclose" href="##">Hide Edit Controls</a>			
			</div>
		</div>
	</div>
</div>
</cfoutput>
