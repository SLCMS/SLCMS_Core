<!--- SLCMS base tags to be used in template pages  --->
<!--- &copy; mort bay communications --->
<!---  --->
<!--- custom tag to display a name of a page's parent --->
<!--- --->
<!--- created:   4th Dec 2007 by Kym K of mbcomms --->
<!--- modified:  4th Dec 2007 -  4th Dec 2007 by Kym K of mbcomms, did initial stuff --->
<!--- modified: 23rd Mar 2009 - 23rd Mar 2009 by Kym K - mbcomms: V2.2, changing structures to new module-allowing architecture, the core code is now just another module --->

<!--- 
 --->
<cfsetting enablecfoutputonly="Yes">
<cfif thisTag.executionMode IS "start">
	<cfparam name="attributes.ShowURLName" type="string" default="False">	<!--- flag to show the URL Name rater than the Nav Name --->
<!--- 
<cfdump var="#application.SLCMS.Core.PageStructure.getVariablesScope()#">
 --->
	<cfif request.PageParams.ParentID gt 0>
		<cfoutput>
		<cfif attributes.ShowURLName>			#application.SLCMS.Core.PageStructure.getSingleDocStructure(request.PageParams.ParentID).URLName#
		<cfelse>
			#application.SLCMS.Core.PageStructure.getSingleDocStructure(request.PageParams.ParentID).NavName#
		</cfif>
		</cfoutput>
	</cfif>

</cfif>	<!--- end: tag execution mode is start --->

<cfif thisTag.executionMode IS "end">
</cfif>
<cfsetting enablecfoutputonly="No">
