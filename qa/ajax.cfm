<cfsilent>
	<cfif StructKeyExists(url,"restart")>
		<cfexit>
	</cfif>
	<cfscript>
		if (not StructKeyExists(session,"files"))
			session.files = StructNew();
	</cfscript>
	<!---
		The GetDirectoryXML function is a modified version of a function posted by Ben Nadel on his blog back in 2007.
	 --->
	<cfsetting requesttimeout="30"/>
	<cfheader statuscode="200"/>
	<cfif lcase(form.get) is "materials">
		<cfcontent type="text/xml; charset=utf-8" reset="true">
	<cfelse>
		<cfcontent type="application/json; charset=utf-8" reset="true">
	</cfif>
	<cffunction name="GetDirectoryXml" access="public" returntype="string" output="false" hint="Gets directory information from a directory File object and returns it in XML format.">
		<cfargument name="Directory" type="any" required="true" hint="The Java FILE object representing a directory."/>
		<cfargument name="Recurse" type="boolean" required="false" default="false" hint="Determines whether we will get child directory information recursively."/>
		<cfargument name="Buffer" type="any" required="false" default="" hint="This is the string buffer to which the result is written before being returned." />
		<cfscript>
			var LOCAL = StructNew();

			LOCAL.Files = ArrayNew( 1 );
			LOCAL.Directories = ArrayNew( 1 );
			LOCAL.Children = ARGUMENTS.Directory.ListFiles();
			LOCAL.ReturnBuffer = IsSimpleValue( ARGUMENTS.Buffer );

			if (IsSimpleValue( ARGUMENTS.Buffer ))
				ARGUMENTS.Buffer = CreateObject("java","java.lang.StringBuffer").Init();

			for (LOCAL.ChildIndex = 1;	LOCAL.ChildIndex LTE ArrayLen( LOCAL.Children ); LOCAL.ChildIndex = (LOCAL.ChildIndex + 1)){
				// Check for file type.
				if (LOCAL.Children[ LOCAL.ChildIndex ].IsDirectory())
			 		ArrayAppend(LOCAL.Directories,LOCAL.Children[ LOCAL.ChildIndex ]);
			 	else
			 		ArrayAppend(LOCAL.Files,LOCAL.Children[ LOCAL.ChildIndex ]);
			}

			ARGUMENTS.Buffer.Append("<directory name=""" & XmlFormat( ARGUMENTS.Directory.GetName() ) &	""" path=""" &XmlFormat( ARGUMENTS.Directory.GetPath() ) &""">");
			ARGUMENTS.Buffer.Append("<directories>");

			for (LOCAL.DirectoryIndex = 1 ;	LOCAL.DirectoryIndex LTE ArrayLen( LOCAL.Directories ) ; LOCAL.DirectoryIndex = (LOCAL.DirectoryIndex + 1)){
				LOCAL.Directory = LOCAL.Directories[ LOCAL.DirectoryIndex ];
				if (ARGUMENTS.Recurse)
					GetDirectoryXml(Directory = LOCAL.Directory,Recurse = ARGUMENTS.Recurse,Buffer = ARGUMENTS.Buffer);
			 	else
					ARGUMENTS.Buffer.Append("<directory name=""" &	XmlFormat( LOCAL.Directory.GetName() ) &""" path=""" &	XmlFormat( LOCAL.Directory.GetPath() ) &""">");
			}

			ARGUMENTS.Buffer.Append("</directories>");
			ARGUMENTS.Buffer.Append("<files>");

			for (LOCAL.FileIndex = 1 ;LOCAL.FileIndex LTE ArrayLen( LOCAL.Files ) ;	LOCAL.FileIndex = (LOCAL.FileIndex + 1)){
				LOCAL.File = LOCAL.Files[ LOCAL.FileIndex ];
				ARGUMENTS.Buffer.Append("<file name=""" &XmlFormat( getSurveyName(LOCAL.File.GetPath()) ) &""" path=""" &XmlFormat( LOCAL.File.GetPath() ) &""" bytes=""" &XmlFormat( LOCAL.File.Length() ) &"""/>");
			}

			ARGUMENTS.Buffer.Append("</files>");
			ARGUMENTS.Buffer.Append("</directory>");

			if (LOCAL.ReturnBuffer)
				return( ARGUMENTS.Buffer.ToString() );
			return( "" );
		</cfscript>
	</cffunction>
	<cffunction name="createDir" hint="Create a JSON Directory" access="private" output="false" returntype="string">
		<cfargument name="xmlnode" hint="The XML node containing the directory contents." type="xml" required="true" />
		<cfscript>
			var xml = arguments.xmlnode;
			var out = "";
			var n = 0;
			var nn = 0;
			var i = 0;
			var nd = "";
			var f = "";
			var curr = "";
			var sub = "";

			//Get other directories and files
			for (i=1; i lte arraylen(xml.XmlChildren); i=i+1) {
				curr = xml.XmlChildren[i];
				if (curr.XmlName is "files") {
					nd = "";
					for (n=1; n lte arraylen(curr.XmlChildren); n=n+1)
						nd = listappend(nd,'{"nm":"#JSStringFormat(curr.XmlChildren[n].XmlAttributes.name)#","sz":#JSStringFormat(curr.XmlChildren[n].XmlAttributes.bytes)#,"pth":"#JSStringFormat(curr.XmlChildren[n].XmlAttributes.path)#"}');
					f = listappend(f,nd);
				} else if (curr.XmlName is "directories") {
					nd = "";
					for (nn=1; nn lte arraylen(curr.XmlChildren); nn=nn+1) {
//						if (StructCount(curr.XmlChildren[nn].XmlAttributes) gt 0)
							nd = listappend(nd,createDir(curr.XmlChildren[nn]));
					}
					sub = listappend(sub,nd);
				}
			}
			out = "{""dir"":"""&JSStringFormat(xml.XmlAttributes['name'])&""",""sub"":["&sub&"],""files"":["&f&"]}";
			return out;
		</cfscript>
	</cffunction>
	<cffunction name="getSurveyName" hint="Gets the pretty name of the survey" access="public" output="false" returntype="string">
		<cfargument name="file" hint="The absolute path of the XML file" type="string" required="true" />
		<cfscript>
			var xml = "";
			var out = "";
			arguments.file = replace(arguments.file,"\","/","ALL");
			if (not application.prettyprint)
				return listlast(arguments.file,"/");
		</cfscript>
		<cffile action="read" file="#arguments.file#" variable="out"/>
		<cfscript>
			xml = XmlParse(out).XmlRoot;
			if (not StructKeyExists(session.files,arguments.file))
				StructInsert(session.files,arguments.file,xml);
			return trim(xml.XmlAttributes['ttl']);
		</cfscript>
		<cfreturn "Unknown"/>
	</cffunction>
	<cffunction name="loadSurvey" hint="Populate session with the survey." access="private" output="false" returntype="void">
		<cfargument name="in" hint="The file path of the survey" type="string" required="true" />
		<cfscript>
			var out = "";
			var file = arguments.in;
			var xml = "";
			var rmt = false;

			if (not findnocase(application.path,file)) {
				if (left(application.path,2) is "\\")
					rmt = true;
				file = replace(replace(application.path,"\","/","ALL")&"/"&file,"//","/","ALL");
				if (rmt)
					file = "\\"&right(file,len(file)-1);
			}
		</cfscript>
		<cfif not StructKeyExists(session.files,file)>
			<cffile action="read" file="#file#" variable="out"/>
			<cfset xml = XmlParse(out).XmlRoot/>
			<cfset session.files[file] = xml/>
		<cfelse>
			<cfset xml = session.files[file]/>
		</cfif>
		<cfscript>
			//Create the object
			session.survey.initxml(xml);
		</cfscript>
	</cffunction>
	<cffunction name="removeFile" hint="Remove a specific file" access="public" output="false" returntype="void">
		<cfargument name="file" hint="The file to remove." type="string" required="true" />
		<cffile action="delete" file="#application.path##arguments.file#"/>
		<cfscript>
			if (StructKeyExists(session,"files")) {
				if (StructKeyExists(session.files,application.path&arguments.file))
					StructDelete(session,application.path&arguments.file);
			}
		</cfscript>
	</cffunction>
	<cffunction name="removeDirectory" hint="Remove a specific directory" access="public" output="false" returntype="void">
		<cfargument name="dir" hint="The directory to remove." type="string" required="true" />
		<cfdirectory action="delete" directory="#application.path##arguments.dir#" recurse="true"/>
		<cfscript>
			session.files=StructNew();
		</cfscript>
	</cffunction>
	<cffunction name="moveDirectory" hint="Moves a directory from one place to another." access="public" output="false" returntype="void">
		<cfargument name="dirin" hint="Directory to move" type="string" required="true" />
		<cfargument name="destin" hint="The destination directory" type="string" required="true" />
		<cfset var dir = application.path&arguments.dirin/>
		<cfset var dest = application.path&arguments.destin/>
		<cfdirectory action="rename" directory="#dir#" newdirectory="#(dest&'/'&listlast(arguments.dirin,'/'))#"/>
	</cffunction>
	<cffunction name="moveFile" hint="Moves a file from one directory to another" access="public" output="false" returntype="void">
		<cfargument name="pthin" hint="File path to move" type="string" required="true" />
		<cfargument name="destin" hint="The destination directory" type="string" required="true" />
		<cfset var dir = application.path&arguments.pthin/>
		<cfset var dest = application.path&arguments.destin/>
		<cffile action="move" source="#dir#" destination="#dest#"/>
	</cffunction>
	<cffunction name="createDirectory" hint="Creates a new empty directory." access="public" output="false" returntype="void">
		<cfargument name="path" hint="Relative path" type="string" required="true" />
		<cfdirectory action="create" directory="#(application.path&trim(arguments.path))#"/>
		<cfreturn/>
	</cffunction>
	<cffunction name="copySurvey" hint="Copy a survey. Returns the relative file path." access="public" output="false" returntype="string">
		<cfargument name="src" hint="Source file" type="string" required="true" />
		<cfargument name="name" hint="New name for the survey" type="string" required="true" />
		<cfscript>
			var id = replace(createuuid(),"-","","ALL");
			var dest = replace(arguments.src,listlast(arguments.src,"/"),id&".xml","ONE");
			var out = "";
			var input = "";
			var currNm = "";
			var currID = "";
		</cfscript>
		<cffile action="read" file="#(application.path&arguments.src)#" variable="input"/>
		<cfscript>
			currNm = listfirst(rereplacenocase(input,'<*.*ttl="',"","ALL"),"""");
			currID = listfirst(rereplacenocase(input,'<*.*id="',"","ALL"),"""");
			out = replace(input,'ttl="'&currNm&'"','ttl="'&trim(arguments.name)&'"','ONE');
			//out = replace(out,'id="'&currID&'"','id="'&id&'"','ONE');
		</cfscript>
		<cffile action="write" file="#(application.path&dest)#" output="#out#"/>
		<cfreturn dest/>
	</cffunction>
	<cffunction name="createSurvey" hint="Create a new empty survey. Returns the path with the new file name." access="public" output="false" returntype="string">
		<cfargument name="nm" hint="The descriptive name of the new form." type="string" required="true" />
		<cfargument name="dsc" hint="A description of the form" type="string" required="true" />
		<cfargument name="pth" hint="The relative path where the file should be created." type="string" required="true" />
		<cfscript>
			var i = 0;
			var id = replace(createuuid(),'-','','ALL');
			var xml = "";
			var dest = application.path&"/"&arguments.pth;
		</cfscript>
		<!--- Create directory if it doesn't already exist --->
		<cfif not DirectoryExistS(dest)>
			<cfloop from="1" to="#listlen(arguments.pth,'/')#" step="1" index="i">
				<cfif not DirectoryExists(application.path&"/"&listgetat(arguments.pth,i,'/'))>
					<cfdirectory action="create" directory="#application.path#/#listgetat(arguments.pth,i,'/')#"/>
				</cfif>
			</cfloop>
		</cfif>
		<!--- Create File Contents --->
		<cfxml variable="xml">
			<?xml version="1.0" encoding="UTF-8"?>
			<survey id="<cfoutput>#id#</cfoutput>" bgn="" end="" moddate="<cfoutput>#dateformat(now(),'mm/dd/yyyy')#</cfoutput>" pwd="" url="" actionurl="" ttl="<cfoutput>#trim(arguments.nm)#</cfoutput>" private="false">
				<dsc><![CDATA[<cfoutput>#trim(arguments.dsc)#</cfoutput>]]></dsc>
				<alrt><![CDATA[]]></alrt>
				<acl/>
				<qa/>
			</survey>
		</cfxml>
		<cffile action="write" file="#dest#/#id#.xml" output="#xml#"/>
		<cfreturn arguments.pth&"/"&id&".xml"/>
	</cffunction>
	<cffunction name="saveSurvey" hint="Saves the survey contents in the specified location." access="public" output="false" returntype="void">
		<cfargument name="xmlin" hint="The survey XML code in string format, passed from the UI to be saved." type="string" required="true" />
		<cfscript>
			var xml = XmlParse(arguments.xmlin).XmlRoot;
			var p = xml.prop;
			var q = xml.qa.XmlChildren;
			var acl = xml.acl.XmlChildren;
			var file = "";
			var i = 0;
			var n = 0;
			var out = "";
			var id = createuuid();
			var rmt = false;
			var cfile = "";
			var tmp = "";

			if (left(application.path,2) is "\\")
				rmt = true;
			file = replace(replace(application.path,"\","/","ALL")&"/"&p.file.XmlText,"//","/","ALL");
			if (rmt)
				file = "\\"&right(file,len(file)-1);
			if (not findnocase(".xml",file))
				file = file &"/"&id&".xml";
		</cfscript>
		<cfxml variable="out">
			<cfoutput><?xml version="1.0" encoding="UTF-8"?>
			<survey bgn="#dateformat(p.start.XmlText,'mm/dd/yyyy')#" end="#dateformat(p.end.XmlText,'mm/dd/yyyy')#" moddate="#dateformat(now(),'mm/dd/yyyy')#" pwd="#p.password.XmlText#" url="#p.url.XmlText#" actionurl="#p.action.XmlText#" ttl="#p.title.XmlText#" private="#p.priv.XmlText#">
				<dsc><![CDATA[#p.dsc.XmlText#]]></dsc>
				<alrt><![CDATA[#p.alert.XmlText#]]></alrt>
				<acl><cfloop from="1" to="#arraylen(acl)#" step="1" index="i"><usr>#trim(acl[i].XmlText)#</usr></cfloop></acl>
				<qa>
					<cfloop from="1" to="#arraylen(q)#" step="1" index="i">
						<cfif q[i].type.XmlText is "hidden">
							<q id="<cfif lcase(q[i].id.XmlText) is 'newq'>#replace(createuuid(),'-','','ALL')#<cfelse>#q[i].id.XmlText#</cfif>" type="hidden" value="#trim(q[i].value.XmlText)#" name="#trim(q[i].name.XmlText)#"/>
						<cfelseif q[i].type.XmlText is "text">
							<q id="<cfif lcase(q[i].id.XmlText) is 'newq'>#replace(createuuid(),'-','','ALL')#<cfelse>#q[i].id.XmlText#</cfif>" type="text" format="#trim(q[i].format.XmlText)#" text="#trim(q[i].text.XmlText)#" required="#trim(q[i].required.XmlText)#"/>
						<cfelseif q[i].type.XmlText is "boolean">
							<q id="<cfif lcase(q[i].id.XmlText) is 'newq'>#replace(createuuid(),'-','','ALL')#<cfelse>#q[i].id.XmlText#</cfif>" type="boolean" format="#trim(q[i].format.XmlText)#" text="#trim(q[i].text.XmlText)#" default="true" required="#trim(q[i].required.XmlText)#"/>
						<cfelseif q[i].type.XmlText is "rate">
							<q id="<cfif lcase(q[i].id.XmlText) is 'newq'>#replace(createuuid(),'-','','ALL')#<cfelse>#q[i].id.XmlText#</cfif>" type="rate" from="#trim(q[i].from.XmlText)#" to="#trim(q[i].to.XmlText)#" increment="#trim(q[i].increment.XmlText)#" text="#trim(q[i].text.XmlText)#" required="#trim(q[i].required.XmlText)#"/>
						<cfelseif q[i].type.XmlText is "date">
							<q id="<cfif lcase(q[i].id.XmlText) is 'newq'>#replace(createuuid(),'-','','ALL')#<cfelse>#q[i].id.XmlText#</cfif>" type="date" text="#trim(q[i].text.XmlText)#" required="#trim(q[i].required.XmlText)#"/>
						<cfelseif q[i].type.XmlText is "select">
							<q id="<cfif lcase(q[i].id.XmlText) is 'newq'>#replace(createuuid(),'-','','ALL')#<cfelse>#q[i].id.XmlText#</cfif>" type="select" format="#trim(q[i].format.XmlText)#" text="#trim(q[i].text.XmlText)#" required="#trim(q[i].required.XmlText)#">
								<cfloop from="1" to="#arraylen(q[i].XmlChildren)#" step="1" index="n">
									<cfif q[i].XmlChildren[n].XmlName is "answer">
										<cfif q[i].XmlChildren[n].format.XmlText is "text">
										<a display="#XmlFormat(trim(q[i].XmlChildren[n].display))#" format="text"/>
										<cfelse>
										<a value="#XmlFormat(trim(q[i].XmlChildren[n].value.XmlText))#" display="#XmlFormat(trim(q[i].XmlChildren[n].display.XmlText))#"/>
										</cfif>
									</cfif>
								</cfloop>
							</q>
						<cfelseif q[i].type.XmlText is "matrix">
							<q id="<cfif lcase(q[i].id.XmlText) is 'newq'>#replace(createuuid(),'-','','ALL')#<cfelse>#q[i].id.XmlText#</cfif>" type="matrix" format="#trim(q[i].format.XmlText)#" text="#trim(q[i].text.XmlText)#" required="#trim(q[i].required.XmlText)#">
								<cfset cols = ""/>
								<cfset opts = ""/>
								<cfloop from="1" to="#arraylen(q[i].answer.XmlChildren)#" step="1" index="n">
									<cfif q[i].answer.XmlChildren[n].XmlName is "columns">
										<cfset cols = cols&'<c name="#q[i].answer.XmlChildren[n].XmlText#"/>'/>
									<cfelse>
										<cfset opts = opts&'<a value="#q[i].answer.XmlChildren[n].value.XmlText#" display="#q[i].answer.XmlChildren[n].display.XmlText#"/>'/>
									</cfif>
								</cfloop>
								<columns>#cols#</columns>
								<options>#opts#</options>
							</q>
						</cfif>
					</cfloop>
				</qa>
			</survey>
			</cfoutput>
		</cfxml>
		<cfif fileexists(file)>
			<cffile action="write" file="#file#.tmp" output="#out#">
			<cffile action="delete" file="#file#"/>
			<cffile action="rename" source="#file#.tmp" destination="#file#">
		<cfelse>
			<cffile action="write" file="#file#" output="#out#">
		</cfif>
		<cfscript>
			//Clear any cached surveys
			if (StructKeyExists(session,"files")) {
				if (StructKeyExists(session.files,file))
					StructDelete(session.files,file);
			}

			//CF9 Cache Features
			tmp = file;
			if (findnocase(":",left(file,2)))
				tmp = replace(replace(replace(right(file,len(file)-2),"\","/","ALL"),"/","","ALL"),":","","ALL");
			if (FileExists("ram://"&tmp))
				FileDelete("ram://"&tmp);
			cfile = replace(replace(replace(file,"\","/","ALL"),"/","","ALL"),":","","ALL");
			cacheRemove(cfile);
			tmp = cacheGet("html_"&cfile);
			if (isdefined("tmp"))
				cacheRemove("html_"&cfile);
		</cfscript>
	</cffunction>
	<cfscript>
		rtn = '{"success":true}';
		switch (lcase(form.get)) {
			case "surveys":
				xml = GetDirectoryXml(createObject('java','java.io.File').init(application.path),true);
				xml = replace(replace(replace(xml,application.path,'/','ALL'),'\','/','ALL'),'//','/','ALL');
				x = XmlParse(xml).XmlRoot;
				str = "";
				sub = "";
				out = "";
				f = "";
				for (i=1; i lte arraylen(x.XmlChildren); i=i+1) {
					curr = x.XmlChildren[i];
					if (curr.XmlName is "files") {
						nd = "";
						for (n=1; n lte arraylen(curr.XmlChildren); n=n+1)
							nd = listappend(nd,'{"nm":"#JSStringFormat(curr.XmlChildren[n].XmlAttributes.name)#","sz":#JSStringFormat(curr.XmlChildren[n].XmlAttributes.bytes)#,"pth":"#JSStringFormat(curr.XmlChildren[n].XmlAttributes.path)#"}');
						f = listappend(f,nd);
					} else if (curr.XmlName is "directories") {
						nd = "";
						for (nn=1; nn lte arraylen(curr.XmlChildren); nn=nn+1)
							nd = listappend(nd,createDir(curr.XmlChildren[nn]));
					}
					if (len(trim(nd)) or len(trim(f))) {
						str = listappend(str,nd);
					}
				}
				rtn = "{""surveys"":["&str&"]}";
				break;
			case "survey":
				loadSurvey(form.path);
				rtn = SerializeJSON(session.survey);
				break;
			case "forceauth":
				rtn = '{"auth":#trim(application.requireauth)#}';
				break;
			case "auth":
				if (request.authenticate(form.j_username,form.j_password))
					rtn = '{"auth":true}';
				else
					rtn = '{"auth":false}';
				break;
			case "removesurvey":
				removeFile(form.path);
				rtn = '{"success":true}';
				break;
			case "removefolder":
				removeDirectory(form.path);
				rtn = '{"success":true}';
				break;
			case "movefolder":
				moveDirectory(form.path,form.newparent);
				rtn = '{"success":true}';
				break;
			case "movesurvey":
				moveFile(form.path,form.newparent);
				rtn = '{"success":true}';
				break;
			case "copysurvey":
				out = copySurvey(form.path,form.name);
				rtn = '{"path":"#JSStringFormat(out)#"}';
				break;
			case "createfolder":
				createDirectory(form.path);
				rtn = '{"success":true}';
				break;
			case "createsurvey":
				pth = createSurvey(trim(form.name),trim(form.dsc),form.path);
				rtn = '{"path":"#JSStringFormat(pth)#"}';
				break;
			case "savesurvey":
				saveSurvey(form.survey);
				rtn = '{"success":true}';
				break;
		}
	</cfscript>
</cfsilent>
<cfoutput>#rtn#</cfoutput>
<cfabort>