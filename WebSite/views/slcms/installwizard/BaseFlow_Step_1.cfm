<cfoutput>#includePartial("InstallWiz_PageTop")#

<!--- 
  			      install wiz stage 1 page<br>

							<cfoutput>variables.mytestvar: #mytestvar#</cfoutput><br>
 --->

	<cfif application.SLCMS.config.startup.initialization.ErrorCode>
		<!--- oops, something didn't init, show relevant message --->
		<cfif BitAND(application.SLCMS.config.startup.initialization.ErrorCode, 1) eq 1>
			<!--- DataMgr test load failed --->
			<div id="jsCheckParas">
				<p class="HeadingParaOrangeBackgound">
					The preliminary checks failed.
				</p>
				<p>
					As indicated in the error message above we could not load the Data Manager, 
					an item that will be used later in the configuration of this SLCMS site.
					This error will need to be corrected before we can continue.
				</p>
				<p>
					The most probable causes are that either your web host does not allow the use of the CreateObject function or
					possibly the path to the Data Manager was not correct. It should have been found under the site root here: #variables.Paths.DataMgr_Phys#
				</p>
				<p>
					The default configuration of SLCMS assumes it is installed in the root of the website, ie. it probably <b>is</b> the main website. 
					To use SLCMS at a lower level in the folder structure of an existing site then the configuration has to be done manually.
					See <a href="http://docs.slcms.info">the SLCMS documentation</a> for more detail.
				</p>
			</div>
		</cfif>
	<cfelse>
		<!--- show the standard starting page --->
		<script type="text/javascript">
			$(document).ready(function() {
				// this is the landing page, check to make sure we have js and AJAX running
				// there are what appear to be redundant show()s in the start but that is in case we do a page refresh
				// the flow order is
				// 1. show the javascript text as bad and ajax para is blank
				// 2. delay and then show the javascript text as good
				// 3. short delay and then show the ajax para and as bad
				// 4. delay and then show the good para and hide warning colouring 
				// 5. delay and then show the ajax as good
				var AJAXurl_Test = '#variables.Paths.AJAXURL#';
				// 1. show the javascript text as bad and ajax para is blank
				$('##ajaxHeadingPara_OK').hide();		// these first 4 are needed for refreshes, the css sets up correctly first off
				$('##ajaxHeadingPara_NotOK').hide();
				$('##ajaxHeadingParaDummy').show();
				$('##ajaxHeadingPara').hide();
				$('##jsHeadingPara').show();
				// 2. delay and then show the javascript text as good
				$('##jsHeadingPara_NotOK').delay(800).hide(20);
				$('##jsHeadingPara_OK').delay(850).show(20);
				// 3. short delay and then show the ajax para and as bad
				$('##ajaxHeadingParaDummy').delay(820).hide(20);
				$('##ajaxHeadingPara').delay(820).show(20);
				$('##ajaxHeadingPara_NotOK').delay(840).show(20);
				$('##ajaxHeadingPara_OK').delay(880).hide(20);
				// 4. delay again and then hide js warning 
				$('##jsCheckParas').delay(1800).hide(10);
				var el = $('##disappearHeadPara'); 
				el.html(el.html().replace(/\s+have/ig, ""));
				el.html(el.html().replace(/disappeared/ig, "disappear"));
				// 5. delay and then show the ajax as good
				$.ajax({
					type:'GET',
					url: AJAXurl_Test,
					data: {Job: 'TestComms', Name: 'InstallWizard', Value: '#CreateUUID()#'},
					success: function(stuffBack){
					//	var theResponseString = $.trim(stuffBack);
						if(stuffBack.MESSAGE == 'Good UUID') {
							$('##ajaxHeadingPara_NotOK').delay(1200).hide(20);
							$('##ajaxHeadingPara_OK').delay(1300).show(20);
							$('##ShouldSeeThisParas').delay(2500).show(20);
							$('##AJAXCheckParas').css("background-color", "##E1F9FF" ).delay(1800).hide(10);
						} else {
							$('##ajaxHeadingPara_OK').hide();
							$('##ajaxHeadingPara_NotOK').show();
							$('##ShouldSeeThisParas').delay(2500).hide(20);
							$('##AJAXCheckParas').delay(1800).show(10);
						}
					}
				});
			});
		</script>
		<div class="HeadingParaHead">
			System Check
		</div>
		<div>
			<p id="ConfigFileLoad">
				<cfif application.SLCMS.config.startup.initialization.ConfigFileLoadFailed>
					Loading of System Configuration files <span id="ConfigFileLoad_NotOK">&nbsp;&nbsp;FAILED&nbsp;&nbsp;</span>
				<cfelse>
					Loading of System Configuration files <span id="ConfigFileLoad_OK">&nbsp;&nbsp;OK&nbsp;&nbsp;</span>
				</cfif>
			</p>
		</div>
		<div>
			<p id="jsHeadingPara">
				Checking Correct javascript functionality <span id="jsHeadingPara_OK">&nbsp;&nbsp;OK&nbsp;&nbsp;&nbsp;</span><span id="jsHeadingPara_NotOK">&nbsp;&nbsp;NOT OK&nbsp;&nbsp;</span>
			</p>
		</div>
		<div>
			<p id="ajaxHeadingParaDummy">&nbsp;</p>
			<p id="ajaxHeadingPara">
				Checking Correct AJAX functionality <span id="ajaxHeadingPara_OK">&nbsp;&nbsp;OK&nbsp;&nbsp;&nbsp;</span><span id="ajaxHeadingPara_NotOK">&nbsp;&nbsp;NOT OK&nbsp;&nbsp;</span>
			</p>
		</div>
		<div class="HeadingParaHead">
				Check Result
		</div>
		<div id="jsCheckParas">
			<p class="HeadingParaOrangeBackgound" id="disappearHeadPara">
				This paragraph should have disappeared within two seconds.
			</p>
			<p>
				If you are still seeing this text after 2 seconds then the javascript on this page did not run, either because you have javascript turned off or the path to the javascript files was not correct.
			</p>
			<p>
				If you have javascript turned off then you will need to turn it on to be able to manage this SLCMS website. If you are concerned about security then be reassured. 
				SLCMS uses the well-known and documented &quot;jQuery&quot; javascript libraries and serves them from right here as part of this installation, not via a remote, possibly untrusted, service.
			</p>
			<p>
				If you have javascript turned on then possibly the path to the javascript libraries was not correct. 
				This Initial Installation Wizard assumes that you are serving SLCMS from the website's root directory, 
				ie the path to the jQuery javascript is &quot;/SLCMS/3rdParty/jQuery/jquery.min.js&quot;
				and this Wizard's helper javascript files are in: &quot;/SLCMS/Help/&quot;.
				If this is not the case then you will have to manually change the code initialization variables to point to the correct directories.
				See <a href="http://docs.slcms.info">the SLCMS documentation</a> for more detail.
			</p>
			<p>
				Similarly if this page is not styled (it should have a pale blue background with this section's background being amber coloured) then the style sheet has not been found. 
				It can be found here: &quot;/SLCMS/installAssist/InitialInstallationWizard.css&quot;.
			</p>
		</div>
		<div id="AJAXCheckParas">
			<p class="HeadingParaOrangeBackgound" id="disappearHeadPara">
				This paragraph should have disappeared within two seconds.
			</p>
			<p>
				If you are still seeing this text after 2 seconds then the AJAX check on this page did not run, possibly because AJAX functionality is being blocked. Jacascript is working otherwise you would not have got this far in the checks.
			</p>
		</div>
		<div id="ShouldSeeThisParas">
		<cfif application.SLCMS.config.startup.initialization.ConfigFileLoadFailed>
			<p>
				This Wizard's internal system checks were OK but the main SLCMS engine did not load its configuration files.
			</p>
		<cfelse>
			<p>
				All the initial system checks were OK.
			</p>
			<p>
				If you are seeing this page then you are seeing the Initial Installation Wizard because when SLCMS started it could not find the database attached to this website 
				or it thinks the database is empty. 
			</p>
		</cfif>
			<p>
				We will use this Wizard to work out what is happening and guide you through the installation process or whatever else needs to be done.
				You will be able to back-pedal and change your mind and we will try to help as much as possible.
			</p>
			<p>
				As we don't know at this stage whether there is a working installation of the site's code we cannot use the site's nice friendly validation routines to check your entries as you make them,
				but we will perform some simple validation as you step through the first, detail entry stage in the Wizard and validate everything fully at the review stage so you can go back and fix things. 
			</p>
			<p>&nbsp;</p>
			<p>
				<strong>First we will ask the obvious question: </strong>
			</p>
			<p>
				<strong>Is this the first time you have run SLCMS, ie this is the initial installation of this website?</strong>
			</p>
			<form action="#application.SLCMS.Paths_Admin.AdminBaseURL#install-wizard" method="get">
				<input type="hidden" name="StepCount" value="Step_1">
				<input type="hidden" name="StepWork" value="Process">
				<input type="submit" name="FirstTime" value="#variables.BaseFlow.StepTexts["Step_1"].YesFirst#">
				<input type="submit" name="NotFirstTime" value="#variables.BaseFlow.StepTexts["Step_1"].NotFirst#">
			</form>
		</div>
	</cfif>


#includePartial("InstallWiz_PageBottom")#
</cfoutput>
