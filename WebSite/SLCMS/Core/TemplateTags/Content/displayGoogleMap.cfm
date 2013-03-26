<cfsetting enablecfoutputonly="Yes">
<!--- SLCMS Core - base tags to be used in template pages  --->
<!--- &copy; 2012 mort bay communications --->
<!---  --->
<!--- displayGoogleMap: custom tag to display a Google Map in a page using V3 API --->
<!--- 
docs: startParams
docs:	Name: displayGoogleMap
docs:	Type:	Custom Tag 
docs:	Role:	Content Display Tag - Core 
docs:	Hint: display Google Maps in a page using the GoogleMap V3 API
docs:	Versions: Tag - 1.0.0; Core - 2.2.0+
docs: endParams
docs: 
docs: startAttributes
docs:	name="Latitude"					type="numeric"	default="0"				;	starting Latitude, default - equator
docs:	name="Longitude" 				type="numeric"	default="0"				;	starting Longitude, default - 0, ie Greenwich meridian
docs:	name="Zoom" 						type="string" 	default="9"				;	starting zoom level, default - 9, half way in zoom range, options: 1-18
docs:	name="ViewType" 				type="string" 	default="ROADMAP"	;	starting view style, default - ROADMAP, options: [ROADMAP|SATELLITE|HYBRID|TERRAIN]
docs:	name="width" 						type="string" 	default="400px"		;	width of map viewport, default - 300px
docs:	name="height" 					type="string" 	default="300px"		;	height of map viewport, default - 300px
docs:	name="APIKey" 					type="string" 	default=""				;	GoogleMap API key, not needed for low traffic site
docs:	name="ShowMarker" 			type="boolean" 	default="True"		;	show a marker on the map latlng, default - on
docs:	name="MarkerTitleText" 	type="string"		default=""				;	show the marker's title text
docs: endAttributes
docs: 
docs: startManual
docs: This tag displays a simple Google Map such as is used on ContactUs or AboutUs pages to show where a place is.
docs: It places a div on the page and uses javascript to do the work which it places in the html head area.
docs: 
docs: Minimal parameters needed are the latitude and longitude which will define the centre of the map at first showing.
docs: Addition parameters define the zoom level, from 1-18 with 14 as a good starter for showing a street in a suburb, 
docs: the width and height of the div that the map is displayed in, what type of initial display, defaulting to a standard road map.
docs: It is capable of displaying a single Marker, with optional Title text, at the specified latitude and longitude.
docs: 
docs: Latitude and longitude need to be specified as a decimal number, not degrees, minutes and seconds. 
docs: endManual
docs: 
docs: startHistory_Versions
docs: Version 1.0.0.326: 	Base tag - didn't last long :-)
docs: Version 1.0.1.348: 	added attributes for marker capability, added styling and API key for high traffic sites
docs: endHistory_Versions
docs: 
docs: startHistory_Coding
docs: created:  14th Dec 2011 by Kym K, mbcomms
docs: modified: 11th Feb 2012 - 18th Feb 2012 by Kym K, mbcomms: version 1.0.1, 2nd pass with more attributes for marker, width, height and API key
docs: modified: 25th Feb 2012 - 25th Feb 2012 by Kym K, mbcomms: version 1.0.1, added new "docs" documentation
docs: endHistory_Coding
 --->

<cfif NOT IsDefined("thisTag.executionMode")>
	<cfabort showerror="Must be called as customtag.">
</cfif>
<cfif thisTag.executionMode IS "start">
	<cfparam name="attributes.Latitude" type="numeric" default="0">
	<cfparam name="attributes.Longitude" type="numeric" default="0">
	<cfparam name="attributes.Zoom" type="string" default="9">
	<cfparam name="attributes.ViewType" type="string" default="ROADMAP">
	<cfparam name="attributes.width" type="string" default="400px">
	<cfparam name="attributes.height" type="string" default="300px">
	<cfparam name="attributes.APIKey" type="string" default="">
	<cfparam name="attributes.ShowMarker" type="boolean" default="True">
	<cfparam name="attributes.MarkerTitleText" type="string" default="">

	<cfif IsNumeric(attributes.Zoom) and attributes.Zoom lte 18 and attributes.Zoom gte 0>
		<cfset thisTag.Zoom = attributes.Zoom />
	<cfelse>
		<cfset thisTag.Zoom = 9 />
	</cfif>
	<cfif IsNumeric(attributes.Latitude) and attributes.Latitude lte 90 and attributes.Latitude gte -90>
		<cfset thisTag.Latitude = attributes.Latitude />
	<cfelse>
		<cfset thisTag.Latitude = 0 />
	</cfif>
	<cfif IsNumeric(attributes.Longitude) and attributes.Longitude lte 180 and attributes.Longitude gte -180>
		<cfset thisTag.Longitude = attributes.Longitude />
	<cfelse>
		<cfset thisTag.Longitude = 0 />
	</cfif>
	<cfif ListFindNoCase("ROADMAP,SATELLITE,HYBRID,TERRAIN", attributes.ViewType)>
		<cfset thisTag.ViewType = uCase(attributes.ViewType) />
	<cfelse>
		<cfset thisTag.ViewType = "ROADMAP" />
	</cfif>
	<cfif attributes.width gt 0>
		<cfset thisTag.width = attributes.width />
	<cfelse>
		<cfset thisTag.width = "400px" />
	</cfif>
	<cfif attributes.height gt 0>
		<cfset thisTag.height = attributes.height />
	<cfelse>
		<cfset thisTag.height = "300px" />
	</cfif>
	<cfif attributes.APIKey neq "">
		<cfset thisTag.APIKeyString = "&key=#attributes.APIKey#" />
	<cfelse>
		<cfset thisTag.APIKeyString = "" />
	</cfif>


	<cfoutput><div id="GoogleMap_canvas" style="width: #thisTag.width#; height: #thisTag.height#"></div></cfoutput>
	<cfsaveContent variable="TheJS"><cfoutput>
	<script type="text/javascript">
		function initializeGoogleMap() {
		  var latlng = new google.maps.LatLng(#thisTag.Latitude#, #thisTag.Longitude#);
		  var myOptions = {
		    zoom: #thisTag.Zoom#,
		    center: latlng,
		    mapTypeId: google.maps.MapTypeId.#thisTag.ViewType#
		  };
		  var map = new google.maps.Map(document.getElementById("GoogleMap_canvas"), myOptions);
			<cfif attributes.ShowMarker>
			  var marker = new google.maps.Marker({
			      position: latlng,
			      map: map,
			      title:"#attributes.MarkerTitleText#"
			  });
		  </cfif>
		}
		function loadGoogleMapScript() {
		var script = document.createElement("script");
		script.type = "text/javascript";
		script.src = "http://maps.googleapis.com/maps/api/js?callback=initializeGoogleMap&sensor=false#thisTag.APIKeyString#";
		document.body.appendChild(script);
		}
		window.onload = loadGoogleMapScript;
	</script></cfoutput>
	</cfsaveContent><cfhtmlHead text="#TheJS#" />
</cfif><!--- end: tag execution mode is start --->
<cfsetting enablecfoutputonly="No">