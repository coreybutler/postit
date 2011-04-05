<cfsilent>
<cfif StructKeyExists(form,"FIELDNAMES")>
	<cfif fileexists(expandpath('../config.ini'))>
		<cffile action="delete" file="#expandpath('../config.ini')#"/>
	</cfif>
	<cfif fileexists(expandpath('../process.cfm'))>
		<cffile action="delete" file="#expandpath('../process.cfm')#"/>
	</cfif>
	<cfif DirectoryExists(expandpath('../data'))>
		<cfdirectory action="delete" recurse="true" directory="#expandpath('../data')#"/>
	</cfif>
	<cfdirectory action="create" directory="#expandpath('../data')#"/>
	<cfdirectory action="create" directory="#expandpath('../data/general')#"/>
	<cffile action="read" file="#expandpath('./config.ini.template')#" variable="out"/>
	<cfscript>
		str = replace(out,"{@DSN}",trim(form.dsn));
		str = replace(str,"{@SMTPSERVER}",trim(form.smtpserver));
		str = replace(str,"{@SMTPUSER}",trim(form.smtpusername));
		str = replace(str,"{@SMTPPWD}",trim(form.smtppwd));
	</cfscript>
	<cffile action="write" file="#expandpath('../config.ini')#" output="#str#"/>
	<cffile action="read" file="#expandpath('./process.cfm.template')#" variable="out"/>
	<cfscript>
		str = replace(out,"{@EML}",trim(form.eml),'ALL');
	</cfscript>
	<cffile action="write" file="#expandpath('../process.cfm')#" output="#str#"/>
	<cffile action="read" file="#expandpath('./demo.template')#" variable="out"/>
	<cfscript>
		pth = replace(replace(CGI.PATH_INFO,listlast(CGI.PATH_INFO,"/"),''),"/install","","ALL");
		str = replace(out,"{@URL}",CGI.SERVER_NAME&"/"&pth,'ONE');
		str = replace(str,'//','/','ALL');
		str = replace(str,'http:/','http://','ALL');
		str = replace(str,"{@EML}",trim(form.eml),'ALL');
	</cfscript>
	<cffile action="write" file="#expandpath('../data/general/demo.xml')#" output="#str#"/>
	<cffile action="read" file="#expandpath('./'&form.dbtype&'.sql')#" variable="sql"/>
	<cftry>
		<cfif form.dbtype is "pgsql">
			<cfquery name="qry" datasource="#form.dsn#">
				select count(*) as ct from pg_class where relname = 'result'
			</cfquery>
			<cfif qry.ct[1] gt 0>
				<cfquery name="qry" datasource="#form.dsn#">
					DROP TABLE result;
				</cfquery>
			</cfif>
		<cfelse>
			<cfquery name="qry" datasource="#form.dsn#">
				DROP TABLE IF EXISTS `result`;
			</cfquery>
		</cfif>
		<cfcatch type="any"></cfcatch>
	</cftry>

	<cfquery name="qry" datasource="#form.dsn#">
		<cfoutput>#sql#</cfoutput>
	</cfquery>
	<cfdirectory action="list" directory="ram://" name="out"/>
	<cfscript>
		for (i=1; i lte out.recordcount; i++)
			FileDelete(out.directory[i]&out.name[i]);
		out = QueryNew("out");
		x = CacheGetAllIds();
		for (i=1; i lte arraylen(x); i++)
			cacheRemove(trim(x[i]));
	</cfscript>
	<cfif StructKeyExists(form,"server")>
		<cfinclude template="server.cfm"/>
	</cfif>
	<cflocation url="../?restart" addtoken="false"/>
</cfif>
</cfsilent>
<div class="main">
	<h1>Installation</h1>
	<form action="<cfoutput>#CGI.PATH_INFO#</cfoutput>" method="post">
	<ol>
		<li>If you want to use the Google map features, make sure your server has an API key configured.</li>
		<br/>
		<li>Create a MySQL or PostgreSQL DB & add a CF data source name for it.</li>
		<dd>CF DSN: <input type="text" name="dsn" size="30"/></dd>
		<dd><input type="radio" value="pgsql" checked="true" name="dbtype"/>PostgreSQL <input type="radio" value="mysql" checked="false" name="dbtype"/>MySQL</dd>
		<br/>
		<li>This tool demonstrates the use of application-specific SMTP servers for sending survey results.</li>
		<dd>SMTP Server: <input type="text" name="smtpserver" size="30"/></dd>
		<dd>SMTP Username: <input type="text" name="smtpusername" size="30"/></dd>
		<dd>SMTP Password: <input type="text" name="smtppwd" size="30"/></dd>
		<br/>
		<li>When a survey is taken, the results can be emailed to you. Please provide your email address if you'd like to use this option.</li>
		<dd>Your Email Address: <input type="text" name="eml" size="30"/></dd>
		<br/>
		<li>This tool makes use of Server.cfc &amp; OnServerStart() to set variables in the server scope (Server.cfc is found in the application root).</li>
		<dd><input type="checkbox" value="true" name="server"/> I do not want to use this. I want the system to configure server variables using an alternative method.</dd>
	</ol>
	<input type="submit" value="Install">
</form>
<hr>
<strong>This tool will create the database (&lt;root&gt;/install/mysql.sql), generate a demo survey (&lt;root&gt;/data/general.demo.xml), and setup the configuration file (&lt;root&gt;/config.ini). If you need to restart for any reason, simply append "?restart" to any url.</strong>
</div>