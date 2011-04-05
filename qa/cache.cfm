<cfsilent>
	<cfdirectory action="list" directory="ram://" name="out"/>
	<cfscript>
		if (StructKeyExists(url,"clear")) {
			for (i=1; i lte out.recordcount; i++)
				FileDelete(out.directory[i]&out.name[i]);
			out = QueryNew("out");
			x = CacheGetAllIds();
			for (i=1; i lte arraylen(x); i++)
				cacheRemove(trim(x[i]));
		}
	</cfscript>
</cfsilent>

<div class="main">
<h1>Cache Manager</h1>
<div class="nav">
	<a href="./">Home</a> |
	<a href="<cfoutput>#CGI.PATH_INFO#</cfoutput>?see">View Cached Surveys</a> |
	<a href="<cfoutput>#CGI.PATH_INFO#</cfoutput>?clear">Clear Caches (VFS & EhCache)</a>
</div>
<cfif isdefined("out")>
	<div class="break"></div>
	<fieldset>
		<legend>Cached Survey Assets</legend>
		<cfscript>
			writedump(out);
			writedump(cacheGetAllIds());
		</cfscript>
	</fieldset>
</cfif>
</div>