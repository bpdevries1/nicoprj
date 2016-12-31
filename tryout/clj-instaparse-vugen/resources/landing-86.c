landing() {
	char * transactie;
	
	set_trans_prefix("RRS");
	
    transactie = trans_name("landing");
    rb_start_transaction(transactie);

	web_add_auto_header("Accept", 
		"application/x-ms-application, image/jpeg, application/xaml+xml, image/gif, image/pjpeg, application/x-ms-xbap, application/vnd.ms-excel, application/vnd.ms-powerpoint, application/msword, */*");

	web_add_auto_header("Accept-Language", 
		"nl-NL");

	web_add_auto_header("User-Agent", 
		"Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 6.1; WOW64; Trident/7.0; SLCC2; .NET CLR 2.0.50727; .NET CLR 3.5.30729; .NET CLR 3.0.30729; .NET4.0C; .NET4.0E; InfoPath.3)");

	web_add_auto_header("Accept-Encoding", 
		"gzip, deflate");

	web_add_auto_header("DNT", 
		"1");

	web_add_header("Accept-Language", 
		"nl-NL");

	web_reg_save_param_regexp(
		"ParamName=FromDate_all",
		"RegExp=FromDate=(.*?)&amp",
		SEARCH_FILTERS,
		"Scope=Body",
		"IgnoreRedirections=No",
		"RequestUrl=*/RRS2/*",
		LAST);

	web_reg_save_param_regexp(
		"ParamName=ToDate_all",
		"RegExp=ToDate=(.*?)\"\\ target",
		SEARCH_FILTERS,
		"Scope=Body",
		"IgnoreRedirections=No",
		"RequestUrl=*/RRS2/*",
		LAST);

	web_reg_save_param_regexp(
		"ParamName=FromDate_month",
		"RegExp=FromDate=(.*?)&amp",
		"Ordinal=2",
		SEARCH_FILTERS,
		"Scope=Body",
		"IgnoreRedirections=No",
		"RequestUrl=*/RRS2/*",
		LAST);

	web_reg_save_param_regexp(
		"ParamName=ToDate_month",
		"RegExp=ToDate=(.*?)\"\\ target",
		"Ordinal=2",
		SEARCH_FILTERS,
		"Scope=Body",
		"IgnoreRedirections=No",
		"RequestUrl=*/RRS2/*",
		LAST);
		
    web_reg_find("Text=Regulatory Reporting Solution 2.0", "Fail=NotFound", LAST);
    
	web_url("RRS2", 
		"URL=https://{domain}/RRS2/", 
		"TargetFrame=", 
		"Resource=0", 
		"RecContentType=text/html", 
		"Referer=", 
		"Snapshot=t2.inf", 
		"Mode=HTML", 
		LAST);

	web_revert_auto_header("Accept-Language");

	web_url("menubar_m.gif", 
		"URL=https://{domain}/RRS2/Content/Images/menubar_m.gif", 
		"TargetFrame=", 
		"Resource=1", 
		"RecContentType=image/gif", 
		"Referer=https://{domain}/RRS2/", 
		"Snapshot=t3.inf", 
		LAST);
	return 0;
}


