<cfsilent>
<!--- SLCMS base tags to be used in template pages  --->
<!--- &copy; mort bay communications --->
<!---  --->
<!--- custom tag to display an include file such as a footer in a template --->
<!---  --->
<!---  --->
<!--- Created:   3rd Jan 2007 by Kym K --->
<!--- Modified:  3rd Jan 2007 -  3rd Jan 2007 by Kym K, working in it --->
<!--- Modified: 26th Apr 2009 - 26th Apr 2009 by Kym K, V2.2 paths changes with portal code - new param pointing to include file directly --->


</cfsilent><cfif thisTag.executionMode IS "start"><cfparam name="attributes.Include" type="string" default=""><cfinclude template="#request.SLCMS.PageParams.Paths.URL.thisPageTemplateIncludesURLpath##attributes.Include#.cfm"></cfif>
