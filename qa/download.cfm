<cfsilent>
	<cfset filein = replace(url.survey,"\","/","ALL")/>
	<cfset root = expandpath("./downloads")/>
	<cfif not DirectoryExists(root)>
		<cfdirectory action="create" directory="#root#"/>
	</cfif>
	<cfset root = replace(root,"\","/","ALL")/>
	<cffunction name="survey2qry">
		<cfargument name="s" type="string" required="true" hint="survey path"/>
		<cfscript>
			var xmlin = XmlParse(FileRead(arguments.s)).XmlRoot;
			var xml = xmlin.qa;
			var qry = QueryNew("row","varchar");
			var i = 0;

			for (i=1; i lte arraylen(xml.xmlchildren); i++) {
				QueryAddRow(qry,i);
				if (xml.XmlChildren[i].XmlAttributes['type'] is not "hidden")
					QuerySetCell(qry,"row",xml.XmlChildren[i].XmlAttributes['text'],i);
				else
					QuerySetCell(qry,"row",xml.XmlChildren[i].XmlAttributes['name']&" (hidden)",i);
			}

			return qry;
		</cfscript>
	</cffunction>
	<cfscript>
		qryp = survey2qry(url.survey);
		if (url.type is "xls") {
			xls = SpreadsheetNew("survey");
			SpreadsheetAddRows(xls,qryp);
		/* Ignored for Demo
		} else {
			str = "<table cellpadding='0' cellspacing='0' border='0' padding='4'><tr><th colspan='2' align='left'>Question</th><th align='left'>Answer</th></tr>";
			for (i=1; i lte qryp.recordcount; i++)
				str = str & "<tr><td>"&i&".</td><td>"&qryp.row[i]&"</td><td style='border-bottom:1px sollid black; width: 400px;'></td></tr>";
			str = str & "</table>";
		*/
		}
		pth = "#root#/#replace(replace(listlast(filein,'/'),'.xml','.'&url.type),' ','_','ALL')#";
	</cfscript>
</cfsilent>

<cfif url.type is "xls">
	<cfspreadsheet action="write" filename="#pth#" name="xls" sheetname="Questions" overwrite="true"/>
	<cfheader name="Content-Type" value="#lcase(url.type)#">
	<cfheader name="Content-Disposition" value="attachment; filename=#replace(replace(listlast(filein,'/'),'.xml','.'&url.type),' ','_','ALL')#"/>
	<cfcontent type="application/#lcase(url.type)#" file="#pth#"/>
<!--- <cfelse>
	<cfheader name="Content-Disposition" value="attachment;filename=#replace(replace(listlast(filein,'/'),'.xml','.'&url.type),' ','_','ALL')#;">
	<cfdocument format="PDF" filename="#replace(replace(listlast(filein,'/'),'.xml','.'&url.type),' ','_','ALL')#" pagetype="letter" orientation="portrait" name="out"><cfoutput>#str#</cfoutput></cfdocument>
	<cfcontent type="application/pdf" variable="#out#"> --->
</cfif>