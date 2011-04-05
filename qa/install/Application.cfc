<cfcomponent displayname="Application" hint="Configures the application.">
	<cfscript>
		this.Name = "postitinstall";
		this.SessionManagement = true;
		//this.SessionTimeout = createtimespan(0,2,0,0);
		//this.ApplicationTimeout = createtimespan(30,0,0,0);
		this.ScriptProtect = "all";
		this.SetClientCookies = true;
   		this.SetDomainCookies = true;
   		this.ClientManagement = false;
   		//CF9-specific properties

   		this.mappings["/ram"]="ram://";
   		//init();
	</cfscript>

	<cffunction name="onRequestStart">
		<cfargument name="requestname" required=true/>
		<cfscript>
			include("../_header.cfm");
		</cfscript>
	</cffunction>

	<cffunction name="onSessionStart">
		<cfscript>
			session.files = StructNew();
		</cfscript>
	</cffunction>

	<cffunction name="include" access="package" hint="A function mimicking the cfinclude tag.">
		<cfargument name="template" required="true" type="string" hint="Template name to include."/>
		<cfinclude template="#arguments.template#"/>
	</cffunction>
</cfcomponent>