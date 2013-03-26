<!--- SLCMS base tags to be used in template pages  --->
<!---  --->
<!--- include file for the WYSIWYG editors used in custom tags to display content --->
<!--- &copy; mort bay communications --->
<!---  --->
<!--- cloned:   28th Feb 2008 by Kym K -mbcomms from displayContainer.cfm --->
<!--- modified: 28th Feb 2008 - 28th Feb 2008 by Kym K - mbcomms: moved editors into include file --->
<!--- modified: 20th Nov 2008 - 20th Nov 2008 by Kym K - mbcomms: updated TinyMCE code, added styling variables --->
<!--- modified: 13th Dec 2008 - 13th Dec 2008 by Kym K - mbcomms: added modified version of Rick Root's cffm file manager for fck and tinymce editors to use --->
<!--- modified: 17th Feb 2009 - 17th Feb 2009 by Kym K - mbcomms: tiny tickle of text areas as used in wiki within SLCMS --->
<!--- modified: 27th Apr 2009 - 27th Apr 2009 by Kym K - mbcomms: V2.2, changing template folder structure to portal/sub-site architecture, sites inside the top site, data structures added/changed to match --->
<!--- modified: 31st Oct 2009 -  1st Nov 2009 by Kym K - mbcomms: V2.2, updated both editors to latest versions and also cffm the same CKEditor v3.0.1, TinyMCE v3.3.0, cffm v1.3.7 --->
<!--- modified:  8th Nov 2009 - 14th Nov 2009 by Kym K - mbcomms: V2.2, editors to multi editor modes, full-on and basic, etc --->
<!--- modified: 12th May 2011 - 12th May 2011 by Kym K - mbcomms: V2.2, we are no using jQuery all over the place and the various control buttons fail if some js libararies are called, 
																																				form params are not the same so now detecting with StructKeyExists() not IsDefined()
																																				also moved a few vars into the thisTag struct to clen up the variables scope --->
<!--- modified: 28th Oct 2011 - 28th Oct 2011 by Kym K - mbcomms: tidy up of editors' look'n'feel --->

<cfset EditorBaseURL = "#request.SLCMS.EditorControl.EditorBaseURL##request.SLCMS.EditorControl.EditorToUse#/" />
<cfset EditorBasePath = "#request.SLCMS.EditorControl.EditorBaseURL##request.SLCMS.EditorControl.EditorToUse#/" />
<cfif request.SLCMS.pageParams.EditorStyleSheet neq "">
	<cfset EditorStyleSheetPath = request.SLCMS.pageParams.Paths.URL.thisPageTemplateControlURLPath & request.SLCMS.pageParams.EditorStyleSheet />
<cfelse>
	<cfset EditorStyleSheetPath = request.SLCMS.pageParams.Paths.URL.thisPageTemplateControlURLPath & thisTag.theEditorStyleSheet />
</cfif>
<!--- make a fresh struct of this editor as we might have been here before and flag what doc we are working on and the mode we are in
			(only one allowed at a time but we might call the file manager several times in this editing session) --->
<cfset session.SLCMS.WYSIWYGEditor.CurrentContentHandle = thisTag.theContentControlData.Handle />
<cfset session.SLCMS.WYSIWYGEditor.CurrentSubSiteID = request.SLCMS.pageParams.SubSiteID />
<cfset session.SLCMS.WYSIWYGEditor["#thisTag.theContentControlData.Handle#"] = StructNew() />
<cfset session.SLCMS.WYSIWYGEditor["#thisTag.theContentControlData.Handle#"]['SubSite_#request.SLCMS.pageParams.SubSiteID#'] = StructNew() />
<cfset session.SLCMS.WYSIWYGEditor["#thisTag.theContentControlData.Handle#"]['SubSite_#request.SLCMS.pageParams.SubSiteID#'].FileBrowseBasePath = "" />
<cfset session.SLCMS.WYSIWYGEditor["#thisTag.theContentControlData.Handle#"]['SubSite_#request.SLCMS.pageParams.SubSiteID#'].FileBrowseBaseURL = "" />
<cfset session.SLCMS.WYSIWYGEditor["#thisTag.theContentControlData.Handle#"].FileMode = "ShowFiles" />
<cfset session.SLCMS.WYSIWYGEditor["#thisTag.theContentControlData.Handle#"].ResourceType = "" />
<cfset session.SLCMS.WYSIWYGEditor["#thisTag.theContentControlData.Handle#"].dispRowCounter = 0 />
<cfset session.SLCMS.WYSIWYGEditor["#thisTag.theContentControlData.Handle#"].displayedRowArray = ArrayNew(2) />

<!--- 
<cfdump var="#form#" expand="false">
 --->
<cfif request.SLCMS.EditorControl.EditorToUse eq "FCK_editor">
	<!--- this is for CKEditor V3.0+ --->
	<cfoutput>
	<cfset theHeadScript = '<script type="text/javascript" src="#EditorBaseURL#/ckeditor.js"></script>' />
	<cfhtmlhead text="#theHeadScript#" />
	<textarea name="Content" class="EditorSpace" rows="14">#thisTag.theContent#</textarea>
	<script type="text/javascript">
		CKEDITOR.replace( 'Content',
		{
		filebrowserBrowseUrl : '#request.SLCMS.EditorControl.EditorBaseURL#FileManager/cffm.cfm?editorType=cke&EDITOR_RESOURCE_TYPE=file',
		filebrowserImageBrowseUrl : '#request.SLCMS.EditorControl.EditorBaseURL#FileManager/cffm.cfm?editorType=cke&EDITOR_RESOURCE_TYPE=image',
		filebrowserFlashBrowseUrl : '#request.SLCMS.EditorControl.EditorBaseURL#FileManager/cffm.cfm?editorType=cke&EDITOR_RESOURCE_TYPE=flash',
		filebrowserUploadUrl : '#request.SLCMS.EditorControl.EditorBaseURL#FileManager/cffm.cfm?action=QuickUpload&editorType=cke&EDITOR_RESOURCE_TYPE=file',
		filebrowserImageUploadUrl : '#request.SLCMS.EditorControl.EditorBaseURL#FileManager/cffm.cfm?action=QuickUpload&editorType=cke&EDITOR_RESOURCE_TYPE=image',
		filebrowserFlashUploadUrl : '#request.SLCMS.EditorControl.EditorBaseURL#FileManager/cffm.cfm?action=QuickUpload&editorType=cke&EDITOR_RESOURCE_TYPE=flash'
		}
		);
	</script>
	</cfoutput>

<cfelseif request.SLCMS.EditorControl.EditorToUse eq "tinyMCE">
<!--- 
	<cfset theHeadScript = '<script language="javascript" type="text/javascript" src="#EditorBaseURL#/jscripts/tiny_mce/tiny_mce.js"></script>' />
 --->
	<cfset theHeadScript = '<script language="javascript" type="text/javascript" src="#EditorBaseURL#tiny_mce.js"></script>' />
	<cfhtmlhead text="#theHeadScript#" />
	<!--- 
						plugins : "safari,pagebreak,style,table,save,advhr,advimage,advlink,emotions,iespell,inlinepopups,insertdatetime,preview,media,searchreplace,print,contextmenu,paste,directionality,fullscreen,noneditable,visualchars,nonbreaking,xhtmlxtras,template",
	 --->

	<cfoutput>
	<script language="javascript" type="text/javascript">
function cffmCallback(field_name, url, type, win)
{
	// Do custom browser logic
	url = '#application.SLCMS.Paths_Common.Editors.contentEditorControllerURL#?task=&amp;editorType=mce&SubSiteID=#request.SLCMS.pageParams.SubSiteID#&ContentHandle=#form.ContentHandle#&EDITOR_RESOURCE_TYPE=' + type;
	x = 750;
	y = 500;
	win2 = win;
	cffmWindow = window.open(url,"","width="+x+",height="+y+",left=20,top=20,bgcolor=white,resizable,scrollbars,menubar=0");
	if ( cffmWindow != null )
	{
		cffmWindow.focus();
	}
	//win.document.forms[0].elements[field_name].value = 'my browser value';
}


<!--- update according to note in forums from 24 jul 2008
   function cffmCallback(field_name, url, type, win){
      tinyMCE.activeEditor.windowManager.open({
         url :       '<cfoutput>#request.SLCMS.EditorControl.EditorBaseURL#</cfoutput>FileManager/cffm.cfm?editorType=mce&EDITOR_RESOURCE_TYPE=' + type,
         width :      750,
         height :    500,
         movable :    true,
         inline :    true,
         close_previous : "no"
       }, {
           window : win,
           input : field_name
       });      
	}
	 --->

	tinyMCE.init({
    // General options
		elements : "absurls",		
    theme : "advanced",
 		mode : "textareas",
    skin : "o2k7",
    skin_variant : "o2k7",
		convert_urls : "absolute",
		relative_urls : false,
		remove_script_host : true,
		apply_source_formatting : true,
//		plugins : "safari,pagebreak,style,table,save,advhr,advlink,advimage,emotions,iespell,inlinepopups,insertdatetime,preview,media,searchreplace,print,contextmenu,paste,directionality,fullscreen,noneditable,visualchars,nonbreaking,xhtmlxtras,template",
//    plugins : "safari,spellchecker,pagebreak,style,layer,table,save,advhr,advimage,advlink,emotions,iespell,inlinepopups,insertdatetime,preview,media,searchreplace,print,contextmenu,paste,directionality,fullscreen,noneditable,visualchars,nonbreaking<!---,xhtmlxtras,template,imagemanager,filemanager--->",
    plugins : "autolink,lists,spellchecker,pagebreak,style,layer,table,save,advhr,advimage,advlink,emotions,iespell,inlinepopups,insertdatetime,preview,media,searchreplace,print,contextmenu,paste,<!---directionality,--->fullscreen,noneditable,visualchars,nonbreaking<!---,xhtmlxtras,template--->",
		// Theme options
		theme : "advanced",
		theme_advanced_buttons1 : "save,newdocument,|,print,|,bold,italic,underline,strikethrough,|,justifyleft,justifycenter,justifyright,justifyfull,|,styleselect,formatselect,fontselect<!---,fontsizeselect--->,|,sub,sup",
		theme_advanced_buttons2 : "cut,copy,paste,pastetext,pasteword,|,search,replace,|,bullist,numlist,|,outdent,indent,blockquote,|,undo,redo,|,link,unlink,anchor,image,|,insertdate,inserttime<!---,preview--->,|,forecolor,backcolor",
		theme_advanced_buttons3 : "tablecontrols,|,charmap,emotions,iespell,media,advhr,<!---,|,ltr,rtl,|hr--->,removeformat,visualaid,|,fullscreen,cleanup,visualchars,code<cfif application.SLCMS.config.Base.SiteMode eq "Development">,help</cfif>",
//		theme_advanced_buttons4 : "cite,abbr,acronym,del,ins<!---,attribs--->,|,nonbreaking<!---,template--->,pagebreak",
		theme_advanced_toolbar_location : "top",
		theme_advanced_toolbar_align : "left",
		theme_advanced_statusbar_location : "bottom",
		theme_advanced_resize_horizontal : false,
		theme_advanced_resizing : true,
		// plugin controls
	  plugin_insertdate_dateFormat : "%Y-%m-%d",
	  plugin_insertdate_timeFormat : "%H:%M:%S",
	  //
	  file_browser_callback : "cffmCallback",
		// Drop lists for link/image/media/template dialogs
		template_external_list_url : "#EditorBaseURL#lists/template_list.js",
		external_link_list_url : "#EditorBaseURL#lists/link_list.js",
		external_image_list_url : "#EditorBaseURL#lists/image_list.js",
		media_external_list_url : "#EditorBaseURL#lists/media_list.js",
		spellchecker_languages : "+English=en,Danish=da,Dutch=nl,Finnish=fi,French=fr,German=de,Italian=it,Polish=pl,Portuguese=pt,Spanish=es,Swedish=sv",
		// css supplied from the template
		content_css : "#EditorStyleSheetPath#?day=#DayOfWeek(Now())#"<!--- the day bit is just to force a refresh in case style sheet has changed --->
	});
	</script>
	</cfoutput>
<!--- the original
	  cffmWindow = window.open(url,"","width="+win_x+",height="+win_y+",left=50,top=50,bgcolor=white,resizable,scrollbars,menubar=0");
 --->		
<!--- 
	function ibrowseCallback(field_name, url, type, win) {
	  url = '#request.SLCMS.EditorControl.EditorBaseURL#FileManager/cffm.cfm?editorType=mce&EDITOR_RESOURCE_TYPE=' + type;
	  win_ref = win; // not sure why this works for IE, but it does.
	  win_x = 750; win_y = 500; // adjust these variables to fit your desired window size
	  cffmWindow = window.open(url,"SitenFileBrowser","width="+win_x+",height="+win_y+",bgcolor=white,resizable,scrollbars,menubar=0");
	  if ( cffmWindow != null ) {
	    cffmWindow.focus();
	  }
	function ibrowseCallback(field_name, url, type, win) {
	  url = '#EditorBaseURL#/cf_ibrowser/index.cfm?editorType=mce&EDITOR_RESOURCE_TYPE=' + type;
	  win_ref = win; // not sure why this works for IE, but it does.
	  win_x = 750; win_y = 500; // adjust these variables to fit your desired window size
	  cffmWindow = window.open(url,"SitenFileBrowser","width="+win_x+",height="+win_y+",bgcolor=white,resizable,scrollbars,menubar=0");
	  if ( cffmWindow != null ) {
	    cffmWindow.focus();
	  }
 --->
	<cfoutput>
	<textarea name="Content" class="EditorSpace" rows="14">#thisTag.theContent#</textarea>
	</cfoutput>

<cfelseif request.SLCMS.EditorControl.EditorToUse eq "TinyMCE3">
	<script language="javascript" type="text/javascript">
	<cfoutput>	
		// adjust this variable to point to the file "CJFileBrowser.html" for your settings
<!--- 
		var browser_path = "/assets/jss/tiny_mce/plugins/cjfilebrowser/CJFileBrowser.html";
 --->
		var browser_path = "#request.SLCMS.EditorControl.EditorBaseURL##request.SLCMS.EditorControl.EditorToUse#/plugins/cjfilebrowser/CJFileBrowser.html";
		
		// This is the location of the user upload folder. (This folder should exist)
		var upload_dir 	 = "#application.SLCMS.Sites['Site_#request.SLCMS.pageParams.subSiteID#'].Paths.ResourceURLs.FileResources#";
		var base_url     = "/";
		var content_css  = "#EditorStyleSheetPath#";
	</cfoutput>	
		tinyMCE.init({
		
			// this tells tinyMCE to apply to form fields with this classname
			mode : "textareas",
			editor_selector : "Content", 
			
			// settings.
			theme : "advanced",
			width: 600,
			plugins : "table,save,contextmenu,paste,noneditable,cjfilebrowser",
			entity_encoding : "raw",
			theme_advanced_toolbar_location : "top",
			theme_advanced_toolbar_align : "left",
			theme_advanced_path_location : "bottom",
			theme_advanced_buttons1 : "bold,italic,formatselect,bullist,numlist,del,separator,outdent,indent,separator,undo,redo,separator,link,unlink,anchor,cleanup,removeformat,charmap,code,help,image",
			theme_advanced_buttons2 : "",
			theme_advanced_buttons3 : "",
			theme_advanced_blockformats : "p,h2,h3,h4",
			theme_advanced_disable : "styleselect",
			extended_valid_elements : "span[class|style],code[class]",
			theme_advanced_resize_horizontal : false,
			theme_advanced_resizing : true,
			relative_urls : false,
			remove_linebreaks : false,
			trim_span_elements : true,
			verify_css_classes : true,
			verify_html : true,
			remove_script_host : true,
			auto_cleanup_word : true,
			cleanup_on_startup : true,
			paste_create_paragraphs : true,
			paste_create_linebreaks : false,
			paste_use_dialog : true,
			paste_remove_spans : true,
			paste_remove_styles : true,
			paste_strip_class_attributes : "all",
			paste_auto_cleanup_on_paste : true,
			paste_convert_middot_lists : true,
			paste_convert_headers_to_strong : false,
			
			// some optional settings
			document_base_url : base_url,
			content_css : content_css,
			
			// cjfilebrowser defined settings
			plugin_cjfilebrowser_browseurl : browser_path,
			plugin_cjfilebrowser_assetsUrl: upload_dir, 
			file_browser_callback : "CJFileBrowser_browse"
		});
	</script>
	<cfoutput>
	<textarea name="Content" class="EditorSpace" rows="14">#thisTag.theContent#</textarea>
	</cfoutput>
	
<cfelse>
	<cfoutput>
	<textarea name="Content" class="EditorSpace" rows="14">#thisTag.theContent#</textarea>
	</cfoutput>
</cfif>
