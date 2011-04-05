<cfprocessingdirective suppresswhitespace="true" pageencoding="utf-8">
<cfsilent>
	<cfif findnocase(cgi.path_info,"ajax.cfm") or findnocase(cgi.path_info,"process.cfm") or findnocase(cgi.path_info,"download.cfm") or findnocase(cgi.path_info,"report.cfm") or findnocase(cgi.path_info,"map.cfm")>
		<style>
			DIV.main {
				margin:auto; width:800px;
				font-family:tahoma,sans-serif,arial;
				font-size: small;
				font-color: #333;
			}
			IMG.logo {margin-right: 8px; margin-top: -10px;}
			DIV.nav {width: 100%; float: left; background:#eee; border: 1px dotted #999; margin-top: 4px; padding: 10px; font-size: medium;}
			DIV.break {clear: both;}
			FIELDSET {padding: 10px; padding-left:30px; border: 1px dotted #eee;}
			FIELDSET LEGEND {font-weight: bold; color: navy; padding: 4px; font-size: medium;}
		</style>
		<cfexit>
	</cfif>

</cfsilent>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
	<head>
		<!--- <link href="skin/current/basic.css" rel="stylesheet" type="text/css" /> --->
			<style>
				HTML,BODY {margin:0;}
				DIV.pageNote {border: 1px dotted maroon; font-weight: bold; color: #CCC; padding: 3px; margin: 2px;}

				DIV.main {
					margin:auto; width:800px;
					font-family:tahoma,sans-serif,arial;
					font-size: small;
					font-color: #333;
				}
				IMG.logo {margin-right: 8px; margin-top: -10px;}
				DIV.nav {width: 100%; float: left; background:#eee; border: 1px dotted #999; margin-top: 4px; padding: 10px; font-size: medium;}
				DIV.break {clear: both;}
				FIELDSET {padding: 10px; padding-left:30px; border: 1px dotted #eee;}
				FIELDSET LEGEND {font-weight: bold; color: navy; padding: 4px; font-size: medium;}
				FORM INPUT, FORM TEXTAREA {margin-bottom: 8px; margin-left: 20px; color: navy;}
				FORM SUBMIT, FORM BUTTON {font-weight: bold; border: 1px solid navy; background: #336699; color: #fff; font-size: medium;}
				DIV.question {margin-top: 6px; margin-bottom: 10px;}
				DIV.question DIV.title {font-weight: bold; font-size: medium; color: #666;}
			</style>
		</head>
		<body>
		<cfif StructKeyExists(server,"type")>
		<!--- Assumes Server.cfc is used --->
		<cfif server.type is "dev">
			<div style="width:99%;background:#336699;color:#fff;font-weight:bold;padding:8px;font-size:medium">Development Server</div><br/>
		</cfif>
	</cfif>
</cfprocessingdirective>