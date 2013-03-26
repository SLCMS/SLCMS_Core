
<cfset theFileName = "testPDF.pdf" />

<cfoutput>

	<!--- this is the core of the statement, use me in the browser and in PDF --->
	<cfsavecontent variable="statementHtml">
		<div class="stmtTitle">Invoice &nbsp;-&nbsp; ThinkIt BuildIt</div>
		<div class="stmtDate">As at #dateFormat(now(),'dd-mmm-yyyy')#</div>
		<br /><br />
<!--- 
		<cfif compareNoCase(event.getValue("statementType"),"vendor") eq 0>
			<cfinclude template="inc_statement_vendor.cfm" />
		<cfelse>
			<cfinclude template="inc_statement_office.cfm" />
		</cfif>
 --->
	</cfsavecontent>
	
	<cfsavecontent variable="cssBlock">
		<style>
			.stmtTitle {font-size:14px;font-weight:bold;float:left;}
			.stmtDate {font-size:12px;font-weight:bold;float:right;}
			.padLeft {padding-left:10px;}
			.padRight {padding-right:10px;}
			.priceCol {padding-right:10px;}
			.vtop {vertical-align:top;}
			.right {text-align:right; padding-right:10px;}
			.bold {font-weight:bold;}
			.bigger {font-size:14px;}
			.framePadLeft {padding-left:16px;}
			.framePadBottom {padding-bottom:16px;}
			
			td.sectionHead {font-size:14px; height:28px; padding-left:10px;}
			tr.data {height:20px;}
			tr.total {height:20px;}
			tr.title > td {font-weight:bold; height:20px;}
			
			.orderedMedium > td {background:##ecf3e4;color:##2A3A1D;}
			table.ordered {border-collapse:collapse;}
			table.ordered tbody > tr > td.sectionHead {background:##dae8c9;color:##2A3A1D;}
			table.ordered tbody > tr > td {border:1px solid ##dae8c9;}
			table.ordered tbody > tr.total {background:##ecf3e4;color:##2A3A1D;}
			
			.notOrderedMedium > td {background:##EFEFEF;color:gray;}
			table.notOrdered {border-collapse:collapse;}
			table.notOrdered tbody > tr > td.sectionHead {background:##D9D9D9;color:##5D5D5D;}
			table.notOrdered tbody > tr > td {border:1px solid ##D9D9D9;}
			table.notOrdered tbody > tr.total {background:##EFEFEF;color:gray;}
			
			.combinedMedium > td {background:##CCC6D2;color:##403850;}
			table.combined {border-collapse:collapse;}
			table.combined tbody > tr > td.sectionHead {background:##CCC6D2;color:##403850;}
			table.combined tbody > tr > td {border:1px solid ##CCCAD5;}
			table.combined tbody > tr.total {background:##E5E2E9;color:##403850;}
			
			.receiptMedium > td {background:##f3ede5;color:##403850;}
			table.receipt {border-collapse:collapse;}
			table.receipt tbody > tr > td.sectionHead {background:##e7ded1;color:##403850;}
			table.receipt tbody > tr > td {border:1px solid ##e7ded1;}
			table.receipt tbody > tr.total {background:##f3ede5;color:##403850;}
			
			.paymentMedium > td {background:##E4E8F3;color:##363C52;}
			table.payment {border-collapse:collapse;}
			table.payment tbody > tr > td.sectionHead {background:##CFDCE9;color:##374051;}
			table.payment tbody > tr > td {border:1px solid ##CFD7E9;}
			table.payment tbody > tr.total {background:##E4E8F3;color:##363C52;}
		</style>
	</cfsavecontent>
	
	<!--- save to pdf rather than screen --->

		<cfsavecontent variable="pdfHtml">
		<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
		<html>
		<head>
			<title></title>
			#variables.cssBlock#
			<style>
				body, table, tr, td, div {font-family:arial,sans-serif;font-size:1em;}
				.padLeft {padding-left:4px;}
				.bigger {font-size:1em;}
				tr.title > td {height:2em;}
				tr.data > td {white-space:nowrap;height:2em;}
				td.sectionHead {font-size:1em;}
				tr.total {height:2em;}
			</style>
		</head>
		<body>
<!--- 
		<cfinclude template="..\vCommon\dsp_insertReportHeading.cfm" />
		 --->
		#statementHtml#
		</body>
		</html>
		</cfsavecontent>
		
		<!--- write the pdf file --->
		<cfdocument format="PDF" filename="#theFileName#" overwrite="true" unit="cm" fontembed="false" orientation="Portrait" pageType="A4" scale="100">#variables.pdfHtml#</cfdocument>
		<!--- write pdf to browser --->
		<cfheader name="Content-Type" value="pdf" />
		<cfheader name="Content-Disposition" value="inline;filename=#theFileName#" />
		<cfcontent type="application/pdf" file="C:\Web_Dev\VersionControlledSpace\SLCMS\SLCMS_Core_Development_Space\WebSite\miscellaneous\#theFileName#" />

</cfoutput>
