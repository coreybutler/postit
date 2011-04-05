<cfsilent>
	<cfscript>
		url.survey = replace(expandpath("./data/"&url.survey),'\','/','ALL');
		clat = "";
		clong = "";
		for (i=1; i lte arraylen(server.city); i++) {
			if (server.city[i].city is "Peoria") {
				clat = server.city[i].lat;
				clong = server.city[i].long;
				break;
			}
		}
	</cfscript>
	<cfquery name="qry">
		SELECT 	*
		FROM	result
		WHERE 	form = <cfqueryparam cfsqltype="cf_sql_varchar" value="#url.survey#"/>
	</cfquery>
	<cfquery name="qryc">
		SELECT	location, count(distinct taker) as ct
		FROM	result
		GROUP BY location
	</cfquery>
</cfsilent>

<cfmap name="rmap" centerlatitude="#clat#" centerlongitude="#clong#"
    doubleclickzoom="true" overview="true" scrollwheelzoom="true"
    showscale="true" tip="Home Office" zoomlevel="2">
	<cfoutput query="qryc">
		<cfscript>
			lat = "";
			long = "";
			for (i=1; i lte arraylen(server.city); i++) {
				if (server.city[i].city is location) {
					lat = server.city[i].lat;
					long = server.city[i].long;
					break;
				}
			}
		</cfscript>
		<cfmapitem name="#location#" latitude="#lat#" longitude="#long#" tip="#location#: #ct# Responses"/>
	</cfoutput>
</cfmap>