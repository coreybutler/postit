
/**
 * @accessors true
 */
component output="false" hint="Survey Object" initmethod="survey" {
	/**
	* @hint Unique Identification Number
	* @type UUID
	*/
	property id;

	/**
	* @hint Start date of the survey.
	* @type date
	*/
	property start;

	/**
	* @hint Expiration date of the survey.
	* @type date
	*/
	property end;

	/**
	* @hint The password used to access the survey.
	* @type string
	*/
	property password;

	/**
	* @hint The action page where forms are submitted upon completion.
	* @type string
	*/
	property action;

	/**
	* @hint A link to the end-user form.
	* @type string
	*/
	property url;

	/**
	* @hint The name of the survey.
	* @type string
	*/
	property title;

	/**
	* @hint An access control list specifying email address or username (or any other token)  that identifies a user.
	* @type array
	*/
	property acl;

	/**
	* @hint A description of the survey.
	* @type string
	*/
	property description;

	/**
	* @hint Indicates whether the survey is public or private
	* @default false
	* @type boolean
	*/
	property private;

	/**
	* @hint An ordered array or questions and answers. Each array element contains a struct with the attributes of the question (as shown in the survey XML file). Answers are contained in a key called answer, which is another ordered array of structs.
	* @type array
	*/
	property questions;


	/**
	* @hint Initialize a survey object.
	**/
	public void function survey(required string xmlfile) output="false" {
		var fileIn = "";
		var fnm = arguments.xmlfile;

		//Clean up the filename for Windows Servers
		if (findnocase(":",left(arguments.xmlfile,2)))
			fnm = right(arguments.xmlfile,len(arguments.xmlfile)-2);
		fnm = replace(replace(fnm,"\","/","ALL"),"/","","ALL");

		//Read the file from RAM if it already exists
		if (FileExists("ram://"&fnm))
			fileIn = FileRead("ram://"&fnm);
		else {
			//Read the file in and save it to RAM for future use
			fileIn = FileRead(arguments.xmlfile);
			FileWrite("ram://"&fnm,fileIn);
		}
		initxml(XmlParse(fileIn).XmlRoot);
	}


	/**
	* @hint Initialize a survey object. This function is here for backward compatibility.
	**/
	public void function init(required string xmlfile) output="false" {
		var fileIn = FileRead(arguments.xmlfile);
		initxml(XmlParse(fileIn).XmlRoot);
	}


	/**
	* @hint This function accepts raw XML to support surveys generated on the fly.
	**/
	public void function initxml(required xml xmlIn) output="false" {
		var head = arguments.xmlIn.XmlAttributes;
		var usr = ArrayNew(1);
		var qa = arguments.xmlIn.qa.XmlChildren;
		var q = "";
		var tmp = "";
		var i = 0;
		var n = 0;

		//Get the general properties of the survey.
		//variables.id = trim(head['id']);
		variables.url = trim(head['url']);
		variables.action = trim(head['actionurl']);
		variables.title = trim(head['ttl']);
		variables.description = trim(arguments.xmlIn.dsc.XmlCData);
		variables.alert = trim(arguments.xmlIn.alrt.XmlCData);
		if (StructKeyExists(head,"private"))
			variables.private = head['private'];
		else
			variables.private = false;
		if (StructKeyExists(head,"bgn"))
			variables.start = dateformat(head['bgn'],"mm/dd/yyyy");
		else
			variables.start = "";
		if (StructKeyExists(head,"end"))
			variables.end = dateformat(head['end'],"mm/dd/yyyy");
		else
			variables.end = "";
		if (StructKeyExists(head,"moddate"))
			variables.moddate = dateformat(head['moddate'],"mm/dd/yyyy");
		else
			variables.moddate = "";
		if (StructKeyExists(head,"pwd"))
			variables.password = trim(head['pwd']);
		else
			variables.password = "";

		//Process the ACL (if any)
		variables.acl = ArrayNew(1);
		if (StructKeyExists(arguments.xmlIn,"acl")) {
			usr = arguments.xmlIn.acl.XmlChildren;
			for (i=1; i lte arraylen(usr); i=i+1)
				arrayappend(variables.acl,trim(usr[i].XmlText));
		}

		//Get the questions
		variables.questions = ArrayNew(1);
		for (i=1; i lte arraylen(qa); i=i+1) {
			q = StructNew();
			tmp = StructKeyArray(qa[i].XmlAttributes);
			for (n=1; n lte arraylen(tmp); n=n+1)
				StructInsert(q,trim(tmp[n]),qa[i].XmlAttributes[tmp[n]]);
			if (not StructKeyExists(q,"default"))
				q['default'] = "";
			if (not StructKeyExists(q,"required"))
				q['required'] = false;
			if (not StructKeyExists(q,"type")) {
				q['type'] = "text";
				q['format'] = "single";
			}

			//Get any answers for selection questions
			if (listcontains("select,matrix",q['type'])) {
				if (arraylen(qa[i].XmlChildren)) {
					if (lcase(q['type']) is "select") {
						StructInsert(q,"answer",ArrayNew(1));
						for (n=1; n lte arraylen(qa[i].XmlChildren); n=n+1) {
							tmp = StructNew();
							tmp = qa[i].XmlChildren[n].XmlAttributes;
							if (not StructKeyExists(tmp,"format"))
								tmp['format'] = "";
							arrayappend(q.answer,tmp);
						}
					} else {
						StructInsert(q,"answer",StructNew());
						StructInsert(q.answer,"columns",ArrayNew(1));
						StructInsert(q.answer,"options",ArrayNew(1));
						for (n=1; n lte arraylen(qa[i].columns.XmlChildren); n=n+1)
							arrayappend(q.answer.columns,trim(qa[i].columns.XmlChildren[n].XmlAttributes['name']));
						for (n=1; n lte arraylen(qa[i].options.XmlChildren); n=n+1)
							arrayappend(q.answer.options,qa[i].options.XmlChildren[n].XmlAttributes);
					}
				}
			}
			arrayappend(variables.questions,q);
		}
	}


	/**
	* @hint Leverages the new built in WriteDump function. This is kind of pointless for this app, but shows how it can be used.
	**/
	public void function dump(required any out,string label,string name,string format) output="true" {
		 if (not StructKeyExists(arguments,'label'))
		 	arguments.label = "Label";
		 if (not StructKeyExists(arguments,'name'))
		 	arguments.label = "Name";
		 if (not StructKeyExists(arguments,'format'))
		 	arguments.label = "text";
		 writedump(var=out, label=label, show=name, format=format);
	}
}