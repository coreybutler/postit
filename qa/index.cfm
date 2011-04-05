<cfsilent>
	<cfset ct = 0/>
	<cfdirectory action="list" directory="#application.path#" recurse="true" sort="name ASC" name="dir"/>
	<cffunction name="getSurveyName">
		<cfargument name="pth" type="string" required="true"/>
		<cfscript>
			var tmp = "";
			if (not StructKeyExists(session,"nm") or StructKeyExists(url,"restart"))
				session.nm = StructNew();
			if (not StructKeyExists(session.nm,arguments.pth) or StructKeyExists(url,"restart")) {
				tmp = new Survey(arguments.pth);
				StructInsert(session.nm,arguments.pth,tmp.getTitle());
			}
			return session.nm[arguments.pth];
		</cfscript>
	</cffunction>

</cfsilent>
<div class="main">
	<br/>
	<div>
		<img src="./postit.png" align="left" class="logo"/>
		<br/><h1>PostIt! Survey System</h1>
		<div class="nav">
			<a href="./admin.htm" target="_blank">Survey Manager</a> |
			<a href="./cache.cfm">Cache Manager</a> |
			<a href="./install">Installation</a>
		</div>
		<div class="break"></div>
	</div>

<br/>
<fieldset class="surveys">
	<legend>Active Surveys</legend>
	<cfoutput query="dir">
		<cfset ct=ct+1/>
		<cfif type is not "Dir"><li><a href="take.cfm?survey=#dir.directory#/#dir.name#">#getSurveyName(dir.directory&'/'&dir.name)#</a></li></cfif>
	</cfoutput>
	<cfif ct eq 0>No Active Surveys.</cfif>
</fieldset>
</div>