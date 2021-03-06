<cfsilent>

	<cffunction name="getLocation" hint="Random location">
		<cfscript>
			var i = randrange(1,arraylen(server.city),"SHA1PRNG");

			return server.city[i].city;
		</cfscript>
	</cffunction>
	<cffunction name="answer">
		<cfargument name="s" hint="Survey" required="true" type="string"/>
		<cfargument name="q" hint="Question" required="true" type="string"/>
		<cfargument name="a" hint="Answer" required="true" type="string"/>
		<cfargument name="l" hint="Location" required="true" type="string"/>
		<cfargument name="t" hint="Participant (Survey Taker)" required="true" type="string"/>
		<cfquery name="qry">
			INSERT INTO result (form,questionid,answer,date,location,taker)
			VALUES (<cfqueryparam cfsqltype="cf_sql_varchar" value="#replace(arguments.s,'\','/','ALL')#">,
					<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.q#">,
					<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.a#">,
					#now()#,
					<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.l#">,
					<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.t#">)
		</cfquery>
	</cffunction>
	<cfscript>
		f = StructKeyArray(form);
		l = getLocation();
		t = createuuid();
		for(i=1; i lte arraylen(f); i++) {
			if (not listcontains("FIELDNAMES,SUBMIT",f[i]) and left(f[i],1) is not "_" and len(f[i]) gt 25)
				answer(form["_survey"],f[i],form[f[i]],l,t);
		}
	</cfscript>
	<cfmail to="corey.butler@ecorsystems.com" from="corey.butler@ecorsystems.com" subject="Survey Completed">A survey was completed. Results are available in the survey manager. In a production application, they would be included here as well.</cfmail>
</cfsilent>
