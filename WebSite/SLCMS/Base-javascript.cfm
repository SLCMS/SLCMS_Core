<!--- js for the co-lo cost calculator --->
<!--- created 14th Apr 2003 by Kym K --->


<script language="JavaScript">
<!--
	function MakeInfoWindow(template,mode,info) {
		infoWindow = window.open(template+'?mode='+mode+'&info='+info, 'infoWindow', 'height=200,width=440,menubar=no,status=no,toolbar=no,scrollbars=yes,resizable=yes');
		return false;
	}
	
	function MakeDetailWindow(template,mode,info) {
		detailWindow = window.open(template+'?mode='+mode+'&info='+info, 'infoWindow', 'height=300,width=540,menubar=no,status=no,toolbar=no,scrollbars=yes,resizable=yes');
		return false;
	}
	
	function PopUpClose(wind) {
		if (typeof infoWindow != "undefined"){
			infoWindow.close();
		}
		if (typeof detailWindow != "undefined"){
			detailWindow.close();
		}
	}

	function ReLoadParent(template){
		opener.location.href = template
		return false
	}
//-->
</script>