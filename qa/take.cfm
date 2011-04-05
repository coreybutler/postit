<cfsilent>
	<cfsavecontent variable="workaround">
		<script type="text/javascript">/* <![CDATA[ */_cf_loadingtexthtml="<img alt=' ' src='/CFIDE/scripts/ajax/resources/cf/images/loading.gif'/>";
		_cf_contextpath="";
		_cf_ajaxscriptsrc="/CFIDE/scripts/ajax";
		_cf_jsonprefix='//';
		_cf_clientid='4D61D1CC047F606CAA80CC506F3BF625';/* ]]> */</script>
		<script type="text/javascript" src="/CFIDE/scripts/ajax/yui/yahoo-dom-event/yahoo-dom-event.js"></script>
		<script type="text/javascript" src="/CFIDE/scripts/ajax/messages/cfmessage.js"></script>
		<script type="text/javascript" src="/CFIDE/scripts/ajax/package/cfajax.js"></script>
		<script type="text/javascript" src="/CFIDE/scripts/ajax/yui/animation/animation-min.js"></script>
		<script type="text/javascript" src="/CFIDE/scripts/ajax/ext/adapter/yui/ext-yui-adapter.js"></script>
		<script type="text/javascript" src="/CFIDE/scripts/ajax/ext/ext-all.js"></script>
		<script type="text/javascript" src="/CFIDE/scripts/ajax/package/cfmessagebox.js"></script>
		<link rel="stylesheet" type="text/css" href="/CFIDE/scripts/ajax/resources/ext/css/ext-all.css" />
		<link rel="stylesheet" type="text/css" href="/CFIDE/scripts/ajax/resources/cf/cf.css" />
		<script type="text/javascript" src="/CFIDE/scripts/ajax/package/cfslider.js"></script>
		<style>
			DIV.pageNote {border: 1px dotted maroon; font-weight: bold; color: #CCC; padding: 3px; margin: 2px;}
		</style>
		<script type="text/javascript">/* <![CDATA[ */
			ColdFusion.Ajax.importTag('CFMESSAGEBOX');
		/* ]]> */</script>

		<script type="text/javascript">/* <![CDATA[ */
			var _cf_messagebox_init_1259513098722=function()
			{
				var _cf_messagebox=ColdFusion.MessageBox.init('thanks','alert','Thanks for taking test! Your answers will now be submitted.<br/><br/>Please wait while they are processed.','Processing test',null,null,null,null,false,true,submit,'info',null,null,null,null,null);
			};ColdFusion.Event.registerOnLoad(_cf_messagebox_init_1259513098722);
		/* ]]> */</script>

		<script type="text/javascript">/* <![CDATA[ */
			var _cf_messagebox_init_1259513098723=function()
			{
				var _cf_messagebox=ColdFusion.MessageBox.init('done','alert','Thanks for waiting. Your answers have been processed.','Finished Processing test',null,null,null,null,false,true,finished,'info',null,null,null,null,null);
			};ColdFusion.Event.registerOnLoad(_cf_messagebox_init_1259513098723);
		/* ]]> */</script>

		<script type="text/javascript">/* <![CDATA[ */
			var _cf_messagebox_init_1259513098724=function()
			{
				var _cf_messagebox=ColdFusion.MessageBox.init('error','alert','There was an error. Please check the action page of the form.','Error',null,null,null,null,false,true,null,'error',null,null,null,null,null);
			};ColdFusion.Event.registerOnLoad(_cf_messagebox_init_1259513098724);
		/* ]]> */</script>

		<script type="text/javascript">/* <![CDATA[ */
			ColdFusion.Ajax.importTag('CFSLIDER');
		/* ]]> */</script>

		<script type="text/javascript">/* <![CDATA[ */
			var _cf_slider_init_1259513098725=function()
			{
				var _cf_slider=ColdFusion.Slider.init('_cfslider_6E93C8F03FFA02B1EE3CEE8FBA6432B8','6E93C8F03FFA02B1EE3CEE8FBA6432B8',false,null,20,1,1.0,5.0,false,1,true,null,null);
			};ColdFusion.Event.registerOnLoad(_cf_slider_init_1259513098725);
		/* ]]> */</script>
	</cfsavecontent>
	<cfscript>
		//Use the survey path as a cache key
		key = replace(replace(replace(url.survey,"\","/","ALL"),"/","","ALL"),":","","ALL");

		//Look for the complete form in the cache.
		html = cacheGet("html_"&key);

		if (not isdefined("html") or StructKeyExists(url,"restart")) {
			if (StructKeyExists(url,"restart"))
				cacheRemove(key);

			//Look in cache for survey object.
			s = cacheGet(key);

			//If survey object isn't cached, create & cache it.
			if (not isdefined("s") or StructKeyExists(url,"restart")) {
				s = new Survey(url.survey);
				cachePut(key,s);
			}

			//Some helper variables to simplify output
			q = s.getQuestions();
			n = 0;
			hidden = 0;
			survey = s;
		}
	</cfscript>

	<cfif not isdefined("html") or StructKeyExists(url,"restart")>

		<!--- Create & cache HTML --->
		<cfsavecontent variable="htmlpage">
			<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
			<html>
				<head>
					<meta http-equiv="Cache-Control" content="no-cache"/>
					<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
					<meta http-equiv="Pragma" content="no-cache"/>
					<meta http-equiv="Abstract" content=""/>
					<meta http-equiv="Author" content="Ecor Systems, LLC"/>
					<meta http-equiv="Copyright" content="Copyright <cfoutput>#datepart('yyyy',now())#</cfoutput> Ecor Systems, LLC. All Rights Reserved."/>
					<meta http-equiv="Description" content="<cfoutput>#survey.getDescription()#</cfoutput>"/>
					<meta http-equiv="Distribution" content="Global"/>
					<meta http-equiv="Expires" content="0"/>
					<meta http-equiv="Revisit-After" content="7"/>
					<meta http-equiv="Keywords" content=""/>
					<meta http-equiv="Content-Language" content="en-us"/>
					<meta http-equiv="Robots" content="index,follow"/>
					<title><cfoutput>#survey.getTitle()#</cfoutput></title>
					<script type="text/javascript">
						var mask = new Ext.LoadMask(Ext.getBody(),{msg:'Processing Survey...'});
						var submit = function(btn) {
							mask.show();
							ColdFusion.Ajax.submitForm('form','<cfoutput>#JSStringFormat(survey.getAction())#</cfoutput>',callMB,errorMB);
						}

						function callMB() {
							ColdFusion.MessageBox.show('done');
							mask.hide();
						}

						function errorMB(code,msg) {
							ColdFusion.MessageBox.show('error');
							mask.hide();
						}

						function showThanks(mbox) {
							ColdFusion.MessageBox.show(mbox);
						}

						var finished = function(btn) {
							history.go(-1);
						}
					</script>
				</head>
				<body>
					<div class="main">
					<cfoutput>
					<div class="description">
						<img src="./postit.png" align="left" hspace="4" class="logo"/>
						<h1>#survey.getTitle()#</h1>
						#survey.getDescription()#
					</div>
					<div class="nav">
						<a href="./">Home</a> | Download As: <cfoutput><a href="./download.cfm?survey=#url.survey#&type=xls">Excel Spreadsheet</a><!---  - <a href="./download.cfm?survey=#url.survey#&type=pdf">Acrobat File (pdf)</a> ---></cfoutput>
					</div>
					<div class="break"></div>
					<br/>
					<div class="survey" style="padding: 15px; border: 1px dotted ##336699; width: 99%;">
						<form action="#survey.getAction()#" method="post" id="form">
							<input type="hidden" name="_survey" value="<cfoutput>#url.survey#</cfoutput>"/>
							<cfmessagebox name="thanks" title="Processing #survey.getTitle()#" icon="info" type="alert" message="Thanks for taking #survey.getTitle()#! Your answers will now be submitted.<br/><br/>Please wait while they are processed." callbackhandler="submit"/>
							<cfmessagebox name="done" title="Finished Processing #survey.getTitle()#" icon="info" type="alert" message="Thanks for waiting. Your answers have been processed." callbackhandler="finished"/>
							<cfmessagebox name="error" title="Error" type="alert" icon="error" message="There was an error. Please check the action page of the form."/>
							<cfloop from="1" to="#arraylen(q)#" step="1" index="n">
								<cfif q[n].type is not "hidden">
									<div class="question">
										<div class="title">#(n-hidden)#. #q[n].text#<cfif q[n].required>*</cfif></div>
										<cfif q[n].type is "text">
											<cfif q[n].format is "multi">
											<textarea name="#q[n].id#" cols="50" rows="4">#trim(q[n].default)#</textarea>
											<cfelse>
											<input type="text" name="#q[n].id#" value="#trim(q[n].default)#" size="66"/>
											</cfif>
										<cfelseif q[n].type is "boolean">
											<input type="radio" name="#q[n].id#" value="true"/><cfif q[n].format is "tf">True<cfelse>Yes</cfif><br/>
											<input type="radio" name="#q[n].id#" value="false"/><cfif q[n].format is "tf">False<cfelse>No</cfif>
										<cfelseif q[n].type is "date">
											<!--- This could have a JavaScript selection box to choose a date graphically. --->
											<input type="text" name="#q[n].id#" value="#trim(q[n].default)#" size="66"/>
										<cfelseif q[n].type is "rate">
											<cfslider format="html" name="#q[n].id#" min="#q[n].from#" max="#q[n].to#" increment="1"/>
										<cfelseif q[n].type is "select">
											<cfloop from="1" to="#arraylen(q[n].answer)#" step="1" index="j">
												<cfif q[n].answer[j].format is "text">
												<input type="<cfif q[n].format is 'single'>radio<cfelse>checkbox</cfif>" name="#q[n].id#" value="_T#j#" />#q[n].answer[j].display#&nbsp;<input type="text" name="t#q[n].id#" size="30"/><br/>
												<cfelse>
												<input type="<cfif q[n].format is 'single'>radio<cfelse>checkbox</cfif>" name="#q[n].id#" value="<cfif StructKeyExists(q[n].answer[j],'value')>#q[n].answer[j].value#<cfelse>#q[n].answer[j].display#</cfif>"/>#q[n].answer[j].display#<br/>
												</cfif>
											</cfloop>
										<cfelseif q[n].type is "matrix">
											<table cellpadding="2" cellspacing="2">
												<tr>
													<th></th>
													<cfloop from="1" to="#arraylen(q[n].answer.columns)#" step="1" index="y">
														<th>#q[n].answer.columns[y]#</th>
													</cfloop>
												</tr>
												<cfloop from="1" to="#arraylen(q[n].answer.options)#" step="1" index="y">
												<tr>
													<th>#q[n].answer.options[y].display#</th>
													<cfloop from="1" to="#arraylen(q[n].answer.columns)#" step="1" index="m">
														<td align="center"><input type="<cfif q[n].format is 'single'>radio<cfelse>checkbox</cfif>" name="#q[n].id#_col#m#" value="#q[n].answer.options[y].value#"></td>
													</cfloop>
												</tr>
												</cfloop>
											</table>
										</cfif>
									</div>
								<cfelse>
									<cfset hidden=hidden+1/>
									<input type="hidden" value="#q[n].value#" name="#q[n].name#"/>
								</cfif>
							</cfloop>
							<div align="right" style="padding-right: 15px;"><input type="button" name="submit" value="Submit Answer(s)" id="sbtn" onclick="showThanks('thanks');"></div>
						</form>
					</div>
					</div>
				</body>
			</html>
			</cfoutput>
		</cfsavecontent>
		<cfscript>
			html = htmlpage;
			cachePut("html_"&key,html);
		</cfscript>
	</cfif>

</cfsilent>

<!--- Display pretty looking form --->
<cfhtmlhead text="#workaround#">
<cfoutput>#html#</cfoutput>