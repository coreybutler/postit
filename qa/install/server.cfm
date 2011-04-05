<cfscript>

	//Environment
	server.type = "dev";

	//City Locations
	server.city = ArrayNew(1);
	tmp = StructNew();
	tmp.city="Sarasota";
	tmp.lat=27.3364347;
	tmp.long=-82.5306527;
	arrayappend(server.city,tmp);
	tmp = StructNew();
	tmp.city="Tampa";
	tmp.lat=27.9475216;
	tmp.long=-82.4584279;
	arrayappend(server.city,tmp);
	tmp = StructNew();
	tmp.city="Baltimore";
	tmp.lat=39.2903848;
	tmp.long=-76.6121893;
	arrayappend(server.city,tmp);
	tmp = StructNew();
	tmp.city="Austin";
	tmp.lat=30.267153;
	tmp.long=-97.7430608;
	arrayappend(server.city,tmp);
	tmp = StructNew();
	tmp.city="Chicago";
	tmp.lat=41.850033;
	tmp.long=-87.6500523;
	arrayappend(server.city,tmp);
	tmp = StructNew();
	tmp.city="Peoria";
	tmp.lat=40.6936488;
	tmp.long=-89.5889864;
	arrayappend(server.city,tmp);
	tmp = StructNew();
	tmp.city="Boston";
	tmp.lat=42.3584308;
	tmp.long=-71.0597732;
	arrayappend(server.city,tmp);
	tmp = StructNew();
	tmp.city="Omaha";
	tmp.lat=41.2586096;
	tmp.long=-95.937792;
	arrayappend(server.city,tmp);
	tmp = StructNew();
	tmp.city="San Diego";
	tmp.lat=32.7153292;
	tmp.long=-117.1572551;
	arrayappend(server.city,tmp);
	tmp = StructNew();
	tmp.city="Seattle";
	tmp.lat=47.6062095;
	tmp.long=-122.3320708;
	arrayappend(server.city,tmp);
</cfscript>