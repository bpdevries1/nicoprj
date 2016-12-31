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
	return 0;
}

