<h1>Nexts v0.2</h1>
<h3>an engine to provide an incrementing ID value independent of autoincrementing fields in databases</h3>

<p>
		There are two types of Nexts values, an integer or a character string, both represent an increasing value up to a defined limit where they roll over. Normally used as a referenceID or similar. 
</p>
<p>
<strong>Nexts_getNextID()</strong> is the primary function to call. It supplies the next free value for the specified variable name and then in the background increments it ready for the next Nexts_getNextID() function call and then updates the database for persistence. The Nexts_getNextID() function takes two parameters, the name of the ID variable and optionally the type of ID required.
</p>
<p>
	The Next value can be:<br> 
	A straight integer, 32bit so max is 4G: 4,294,967,295<br>
	A string representing a value in a human friendly way or in a less friendly way if big numbers are needed and there is no need for the friendly factor.<br>
	All strings except the shortest versions have a check character and can be checked for correct string length so provide a small degree of protection against ID hacking/spoofing.
</p>
<strong>The possible types are:-</strong>
<table cellpadding=3>
	<thead>
		<tr>
			<th>Name</th>
			<th>Type</th>
			<th>looks like</th>
			<th>number<br>of values</th>
			<th>approx</th>
			<th></th>
		</tr>
	</thead>
	<tbody>
		<tr>
			<td style="vertical-align:top;">
			Integer
			</td><td>
				&quot;NT&quot;
			</td><td>
				&quot;123&quot; 
			</td><td>
				4,294,967,295
			</td><td>
				~4G
			</td>
			<td></td>
		</tr>
		<tr>
			<td style="vertical-align:top;">
			Friendly-short
			</td><td>
				&quot;FS&quot;
			</td><td>
				&quot;bab&quot; 
			</td><td>
				2,400   
			</td><td>
				~2K
			</td>
			<td></td>
		</tr>
		<tr>
			<td style="vertical-align:top;">
			Friendly-long
			</td><td>
				&quot;FL&quot;
			</td><td>
				&quot;fizabab&quot; 
			</td><td>
				5,760,000   
			</td><td>
				~6M
			</td>
			<td><em>Default Type</em></td>
		</tr>
		<tr>
			<td style="vertical-align:top;">
			Friendly-extra long
			</td><td>
				&quot;FX&quot;
			</td><td>
				&quot;sysfizabab&quot; 
			</td><td>
				13,824,000,000
			</td><td>
				~14G
			</td>
			<td></td>
		</tr>
		<tr>
			<td style="vertical-align:top;">
			Extended-short
			</td><td>
				&quot;ES&quot;
			</td><td>
				&quot;bAZ&quot;
			</td><td>
				14,400  
			</td><td>
				~14K
			</td>
		</tr>
		<tr>
			<td style="vertical-align:top;">
			Extended-long
			</td><td>
				&quot;EL&quot;
			</td><td>
				&quot;fizabaZ&quot;
			</td><td>
				207,360,000   
			</td><td>
				~207M
			</td>
			<td></td>
		</tr>
		<tr>
			<td style="vertical-align:top;">
			Extended-extra long
			</td><td>
				&quot;EX&quot;
			</td><td>
				&quot;BebfizabaZ&quot; 
			</td><td>
				2,985,984,000,000   
			</td><td>
				~3T
			</td>
			<td></td>
		</tr>
	</tbody>
</table>
<br>
<strong>Public Functions Available:</strong>
<table cellpadding=5>
	<thead>
		<tr>
			<th>Function</th>
			<th>Description</th>
		</tr>
	</thead>
	<tbody>
		<tr>
			<td style="vertical-align:top;">
			getNextID(IDname="myID", IDFormat="FL")
			</td><td>
				the main call. <br>
				call it with IDName of existing ID and it will return the next free value (then in background updates system to next value). 
				An unknown ID name will create that ID in the system (in the type supplied in the IDFormat argument).
			</td>
		</tr>
		<tr>
			<td style="vertical-align:top;">
		 ChecknSetNextID(IDname="myID", IDFormat="FL")
			</td><td>
		 ensures an ID exists, creates one if not there, returns the current or initial value, does not increment it internally. <br>
		 										(Used by initialization code and getNextID() to ensure an ID exists.)
			</td>
		</tr>
		<tr>
			<td style="vertical-align:top;">
		 setNextID(IDname="myID", Value="bababab")
			</td><td>
		 forces an ID to a specific value with error checking if appropriate (then in background updates database). The IDname must exist.
		<!--- 
		NB, there is a related function that uses the same code base:
			getFriendlyPassword - returns a random FL-type string for use as easy-to-remember passwords.
														not incremental but the check character is valid
		 --->
			</td>
		</tr>
	</tbody>
</table>
<h2>Usage/Examples</h2>
<p>
	Any existing ID data will load when CFWheels reloads. It is then useful to check that all ids exist by calling the ChecknSetNextID() function in yuor application's initialzation code. Then any new ID will get automatically added in.
</p>
<pre>
&lt;!--- In site's Init code make sure an ID exists, 3 versions ---&gt;
&lt;cfset ChecknSetNextID(IDname="anID", IDFormat="NT") /&gt; &lt;!--- a standard integer ID type, first ID is 1 ---&gt;
&lt;cfset ChecknSetNextID(IDname="anotherID") /&gt; &lt;!--- default FL ID type, first ID is &quot;fizabab&quot; ---&gt;
&lt;cfset ChecknSetNextID(IDname="yetanotherID", IDFormat="EL") /&gt; &lt;!--- EL ID type for larger range, first ID is &quot;fizabaZ&quot; ---&gt;
</pre>
<p>
	In the site code a simple call of getNextID("myID") will return the next ID value.
</p>
<pre>
&lt;cfset theNewID = getNextID("myID") /&gt;
</pre>
<h2>Current Nexts data</h2>
<cfdump var="#Nexts_getPersistentData()#" expand="false" />


