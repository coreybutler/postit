<cfsilent>
	<cfscript>
		//Account for ExtJS not knowing the root path.
		url.survey = expandpath("./data/"&url.survey);

		key = replace(replace(replace(url.survey,"\","/","ALL"),"/","","ALL"),":","","ALL");

		//Look in cache for survey object.
		s = cacheGet(key);

		//If survey object isn't cached, create & cache it.
		if (not isdefined("s") or StructKeyExists(url,"restart")) {
			s = new Survey(url.survey);
			cachePut(key,s);
		}
		q = s.getQuestions();
	</cfscript>

	<cfif StructKeyExists(url,"detail")>
		<cfquery name="qry">
			SELECT 	distinct taker, date, location
			FROM	result
		</cfquery>
	<cfelse>
		<cfquery name="qryc">
			SELECT 	distinct location, count(distinct taker) as ct
			FROM	result
			group by location
		</cfquery>
	</cfif>
</cfsilent>
<cfif StructKeyExists(url,"detail")>
	<style>
		TABLE.form {border: 1px solid #CCC;margin-top:10px;margin-bottom:15px;}
		TABLE.survey TD {padding: 5px;}
		TABLE.survey TD.u {background:##eee; font-weight:bold;}
		TABLE.form TH {text-decoration:italic;}
		DIV.space {padding: 10px;}
	</style>
	<div class="space">
	<table class="survey" cellpadding="6" cellspacing="0" border="0">
		<cfoutput query="qry">
		<tr>
			<td class="u">Participant #qry.currentrow#</td>
			<td class="u">#dateformat(date,'mm/dd/yyyy')#</td>
			<td class="u">#location#</td>
		</tr>
		<tr>
			<td colspan="3">
				<cfscript>
					writeoutput("<table cellpadding='2' cellspacing='2' border='0' class='form' width='100%'>");
					for (i=1; i lte arraylen(q); i++) {
						tmp = EntityLoad('result',{taker=trim(qry.taker),questionid=q[i].id});
						if (not listcontainsnocase("matrix,hidden",q[i].type)) {
							try {
								writeoutput("<tr><th>"&trim(q[i].text)&"</th><td>"&tmp[1].getAnswer()&"</td></tr>");
							} catch (any e) {
								writeoutput("<tr><th>Unidentified Question</th><td></td></tr>");
							}
						} else if (q[i].type is "hidden") {
							writeoutput("<tr><th>"&trim(q[i].name)&"</th><td>Unanswered (Hidden)</td></tr>");
						} else {
							col = "";
							for (n=1; n lte arraylen(q[i].answer.columns); n++) {
								tmp = EntityLoad('result',{taker=qry.taker, questionid=q[i].id&'_COL'&n});
								try {
									if (len(trim(tmp[1].getAnswer())))
										col = col & tmp[1].getAnswer() & "<br/>";
								} catch (any e) {}
							}
							writeoutput("<tr><td valign='top'>"&q[i].text&"</td><td>"&col&"</td></tr>");
						}
					}
					writeoutput("</table>");
				</cfscript>
			</td>
		</tr>
		</cfoutput>
	</table>
	</div>
<cfelse>
	<table cellpadding="5" cellspacing="5" border="0">
		<tr>
			<td>
				<cfchart format="png" xaxistitle="Participants" yaxistitle="Location" chartwidth="300" chartheight="300">
					<cfchartseries type="pie"
						query="qryc"
						itemcolumn="location"
						valuecolumn="ct" />
				</cfchart>
			</td>
			<td>
				<cfchart format="png" xaxistitle="Participants" yaxistitle="Location" chartwidth="600" chartheight="300">
					<cfchartseries type="bar"
						query="qryc"
						itemcolumn="location"
						valuecolumn="ct" />
				</cfchart>
			</td>
		</tr>
	</table>
</cfif>
<cfabort>
