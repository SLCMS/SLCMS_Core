$(document).ready(function() {
	// Expand Panel
	$("#open").click(function(){
		$("div#AdminPanel").slideDown("slow");
	});	
	// Collapse Panel
	$("#close").click(function(){
		$("div#AdminPanel").slideUp("slow");	
	});		
	
	// Switch buttons from "Show" to "Hide" on click
	$("#toggleAdminPanel a").click(function () {
		$("#toggleAdminPanel a").toggle();
	});		
});