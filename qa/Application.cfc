<cfcomponent displayname="Application" hint="Configures the application.">

	<cfscript>
		this.Name = "postit";
		this.SessionManagement = true;
		//this.SessionTimeout = createtimespan(0,2,0,0);
		//this.ApplicationTimeout = createtimespan(30,0,0,0);
		this.ScriptProtect = "all";
		this.SetClientCookies = true;
   		this.SetDomainCookies = true;
   		this.ClientManagement = false;
   		//CF9-specific properties
   		this.ormenabled = true;
   		this.datasource="postit2";

   		//this.ormSettings = {
   		//	datasource="postit2"
   		//};
   		this.smtpserversettings = StructNew();
   		this.mappings["/ram"]="ram://";
   		//init();
	</cfscript>

	<cffunction name="init" access="private" hint="Initialize application parameters">
		<cfargument name="dsn" type="string" required="false" default=""/>
		<cfargument name="smtp" type="struct" required="false"/>
		<cfscript>
			this.datasource = arguments.dsn;
      		if (StructKeyExists(arguments,"smtp")) {
      			this.smtpserversettings = {
					server=arguments.smtp.server,
					username=arguments.smtp.username,
					password=arguments.smtp.password
				};
      		}
		</cfscript>
	</cffunction>

	<cffunction name="OnApplicationStart" access="public" hint="Configures the application." output="false" returntype="void">
		<cfscript>
			//Config File & Properties
			application.cfg = expandpath("./config.ini");
			application.path = expandpath("/"&getprofilestring(application.cfg,"default","datastoremap")); //Checks for a CF mapping
			if (not DirectoryExists(application.path))
				application.path = expandpath(getprofilestring(application.cfg,"default","datastoremap")); //Checks for a relative directory
			if (not DirectoryExists(application.path))
				application.path = getprofilestring(application.cfg,"default","datastoremap"); //Last resort (Assumes absolute directory)
			application.prettyprint = getprofilestring(application.cfg,"default","prettyprint"); //Determines whether to show the file name or survey name
			application.requireauth = getprofilestring(application.cfg,"default","auth"); //Require authorization
			application.com = getprofilestring(application.cfg,"default","com"); //Component Path
			application.cfaasurl = getprofilestring(application.cfg,"default","cfaasurl"); //CFaaS
			if (left(trim(application.com),1) is ".")
				application.com = right(trim(application.com),len(trim(applicaiton.com))-1);
			else if (len(trim(application.com)))
				application.com = application.com&".";
			//Default DSN/Email Settings
			application.dsn = getprofilestring(application.cfg,"default","dsn");
			application.smtp.server=getprofilestring(application.cfg,"smtp","server");
			application.smtp.username=getprofilestring(application.cfg,"smtp","username");
			application.smtp.password=getprofilestring(application.cfg,"smtp","password");
			init(getprofilestring(application.cfg,"default","dsn"),application.smtp);
			ORMReload();
		</cfscript>
	</cffunction>

	<cffunction name="onRequestStart">
		<cfargument name="requestname" required=true/>
		<cfscript>
			if (structkeyexists(url,"restart")) {
				if (not StructKeyExists(url,"reinstall"))
					this.ormSettings.dbCreate="update";
				//OnApplicationEnd();
				OnApplicationStart();
				if (StructKeyExists(session,"survey"))
					StructDelete(session,"survey");
				if (StructKeyExists(session,"files"))
					StructDelete(session,"files");
				OnSessionStart();
			} else
				init(application.dsn,application.smtp);
			Request.authenticate = This.authenticate;
			if (not findnocase(".cfc",CGI.PATH_INFO) and not findnocase("/js/",CGI.PATH_INFO) and not findnocase("/data/",CGI.PATH_INFO))
				include("_header.cfm");
		</cfscript>
	</cffunction>

	<cffunction name="onSessionStart">
		<cfscript>
			session.survey = createObject("component",application.com&"survey");
			session.files = StructNew();
		</cfscript>
	</cffunction>

	<cffunction name="include" access="package" hint="A function mimicking the cfinclude tag.">
		<cfargument name="template" required="true" type="string" hint="Template name to include."/>
		<cfinclude template="#arguments.template#"/>
	</cffunction>

	<cffunction name="authenticate" hint="Authenticate a user based on username and password." access="public" output="false" returntype="boolean">
		<cfargument name="username" hint="Username" type="string" required="true" />
		<cfargument name="password" hint="Password" type="string" required="true" />
		<!--- TODO: Your authentication logic goes here. --->
		<cfreturn true/>
	</cffunction>
</cfcomponent>