<!---
	Here you can add routes to your application and edit the default one.
	The default route is the one that will be called on your application's "home" page.
--->
<!---
<cfset addRoute(name="home", pattern="", controller="wheels", action="wheels")>
--->


<cfscript>
drawRoutes()
	.root(controller="default", action="index")
  // SLCMS administration
  .namespace("slcms")
    .resources("adminHome")
    .resources("adminModule")
    .resources("adminModulesinsubs")
    .resources("adminPages")
    .resources("adminPortal")
    .resources("adminStaff")
    .resources("adminSuperusers")
    .resources("adminSystem")
    .resources("adminTemplates")
    .resources("content")
    .resources("contentEditor")
    .resources("clientComms")
    .resources("developers")
    .resources("installWizard")
    .resources("module")
    .resources("SuperDashboard")
  .end()
  .wildcard()
.end();
</cfscript>

