Action()
{


	return 0;
}
Action2()
{
	web_set_user("TWEEDEKAMER.STATENGENERAAL.LOCAL\janr1503", 
		lr_decrypt("4e1ff745b4c1d6e9d23a"), 
		"parlisweb2:80");

	web_set_max_html_param_len("1588");

	web_url("parlis", 
		"URL=http://parlisweb2/parlis/", 
		"Resource=0", 
		"RecContentType=text/html", 
		"Referer=", 
		"Snapshot=t16.inf", 
		"Mode=HTML", 
		EXTRARES, 
		"Url=../Parlis/WebResource.axd?d=je-hpLE8UOPSCfNC4ZEwvw2&t=634177233518778271", ENDITEM, 
		"Url=masterscript.js", ENDITEM, 
		"Url=../Parlis/ScriptResource.axd?d=_VBNzic2PC1_N8wveEocpkVTFEqm3F0CxV6rZ0cgBoA7f9QjJD9-x2ZDpJopaShvsLCC5h-sqCzyCjo2AoF8UfGB0q_tRoT6GFaiaMV_XOw1&t=ffffffffc4ab22a4", ENDITEM, 
		"Url=../Parlis/ScriptResource.axd?d=_VBNzic2PC1_N8wveEocpkVTFEqm3F0CxV6rZ0cgBoA7f9QjJD9-x2ZDpJopaShvKIGY4gDlti6fdeiq8FlczhyccBm5e4SiuLe9M3QmGWGcFsLCA8JewppLUDRR6mbh0&t=ffffffffc4ab22a4", ENDITEM, 
		"Url=AjaxServices.asmx/jsdebug", ENDITEM, 
		"Url=../RESOURCES/PRINTER.GIF", ENDITEM, 
		"Url=../RESOURCES/HELPICON.GIF", ENDITEM, 
		"Url=../RESOURCES/SETTINGS.GIF", ENDITEM, 
		"Url=../resources/gradbtn.gif", ENDITEM, 
		"Url=../resources/navarea.jpg", ENDITEM, 
		"Url=../resources/gradblue.gif", ENDITEM, 
		"Url=../resources/gradgreen.gif", ENDITEM, 
		LAST);

	lr_think_time(12);

	web_link("Plenair debat", 
		"Text=Plenair debat", 
		"Ordinal=2", 
		"Snapshot=t17.inf", 
		EXTRARES, 
		"Url=../Parlis/ScriptResource.axd?d=wPVh1ZPmv0FqFUiBckWIdzr1QsFwIG9YfnwnRtweKxYUbxlEFSUJ9Ah9ANvPDmBB0&t=70496eef", "Referer=http://parlisweb2/parlis/activiteit.aspx?id=4c2b9ec6-3c6c-4c4c-ad05-b2b661d75697", ENDITEM, 
		"Url=../RESOURCES/EDITITEM.GIF", "Referer=http://parlisweb2/parlis/activiteit.aspx?id=4c2b9ec6-3c6c-4c4c-ad05-b2b661d75697", ENDITEM, 
		"Url=../resources/status.gif", "Referer=http://parlisweb2/parlis/activiteit.aspx?id=4c2b9ec6-3c6c-4c4c-ad05-b2b661d75697", ENDITEM, 
		"Url=../RESOURCES/STATUSVRIJGEGEVEN.GIF", "Referer=http://parlisweb2/parlis/activiteit.aspx?id=4c2b9ec6-3c6c-4c4c-ad05-b2b661d75697", ENDITEM, 
		"Url=../RESOURCES/STATUSGEANNULEERD.GIF", "Referer=http://parlisweb2/parlis/activiteit.aspx?id=4c2b9ec6-3c6c-4c4c-ad05-b2b661d75697", ENDITEM, 
		"Url=../RESOURCES/ITEVENT.GIF", "Referer=http://parlisweb2/parlis/activiteit.aspx?id=4c2b9ec6-3c6c-4c4c-ad05-b2b661d75697", ENDITEM, 
		"Url=../RESOURCES/COPY_16.GIF", "Referer=http://parlisweb2/parlis/activiteit.aspx?id=4c2b9ec6-3c6c-4c4c-ad05-b2b661d75697", ENDITEM, 
		"Url=../RESOURCES/DELITEM.GIF", "Referer=http://parlisweb2/parlis/activiteit.aspx?id=4c2b9ec6-3c6c-4c4c-ad05-b2b661d75697", ENDITEM, 
		"Url=../resources/menuexpand.gif", "Referer=http://parlisweb2/parlis/activiteit.aspx?id=4c2b9ec6-3c6c-4c4c-ad05-b2b661d75697", ENDITEM, 
		"Url=../RESOURCES/STATUSCONCEPT.GIF", "Referer=http://parlisweb2/parlis/activiteit.aspx?id=4c2b9ec6-3c6c-4c4c-ad05-b2b661d75697", ENDITEM, 
		"Url=../resources/selectedtabmiddle.gif", "Referer=http://parlisweb2/parlis/activiteit.aspx?id=4c2b9ec6-3c6c-4c4c-ad05-b2b661d75697", ENDITEM, 
		"Url=../resources/unselectedtabmiddle.gif", "Referer=http://parlisweb2/parlis/activiteit.aspx?id=4c2b9ec6-3c6c-4c4c-ad05-b2b661d75697", ENDITEM, 
		"Url=../RESOURCES/STATUSUITGEVOERD.GIF", "Referer=http://parlisweb2/parlis/activiteit.aspx?id=4c2b9ec6-3c6c-4c4c-ad05-b2b661d75697", ENDITEM, 
		"Url=../Parlis/WebResource.axd?d=usUytLUP8ZDak2_pZ3JhtjXjN3fQWTIjb125Imjg6ic1&t=634177233518778271", "Referer=http://parlisweb2/parlis/activiteit.aspx?id=4c2b9ec6-3c6c-4c4c-ad05-b2b661d75697", ENDITEM, 
		"Url=../Parlis/WebResource.axd?d=Sd7eCTpzE2VxYJWsaTvZUTFRsXSLhYbdGoC_EzTuxVw1&t=634177233518778271", "Referer=http://parlisweb2/parlis/activiteit.aspx?id=4c2b9ec6-3c6c-4c4c-ad05-b2b661d75697", ENDITEM, 
		"Url=../RESOURCES/OUTLLOGO.GIF", "Referer=http://parlisweb2/parlis/activiteit.aspx?id=4c2b9ec6-3c6c-4c4c-ad05-b2b661d75697", ENDITEM, 
		LAST);

	web_submit_data("activiteit.aspx", 
		"<viewstate added to list re=2>", ENDITEM, 
		"Name=__SCROLLPOSITIONX", "Value=0", ENDITEM, 
		"Name=__SCROLLPOSITIONY", "Value=0", ENDITEM, 
		"Name=ctl00$mainBody$TabStrip1$hidCurrentTabIndex", "Value=0", ENDITEM, 
		"Name=ctl00$mainBody$ActiviteitAttributen1$hidObjId", "Value=4c2b9ec6-3c6c-4c4c-ad05-b2b661d75697", ENDITEM, 
		"Name=ctl00$hidPageState", "Value=Read", ENDITEM, 
		"Name=ctl00$hidNavigateUrl", "Value=http://parlisweb2/parlis/", ENDITEM, 
		"Name=ctl00$hidHelpId", "Value=activiteitupdate", ENDITEM, 
		LAST);

	web_submit_data("activiteit.aspx_2", 
		"<viewstate added to list re=2>", ENDITEM, 
		"Name=__SCROLLPOSITIONX", "Value=0", ENDITEM, 
		"Name=__SCROLLPOSITIONY", "Value=0", ENDITEM, 
		"Name=ctl00$mainBody$TabStrip1$hidCurrentTabIndex", "Value=0", ENDITEM, 
		"Name=ctl00$mainBody$ActiviteitAttributen1$hidObjId", "Value=4c2b9ec6-3c6c-4c4c-ad05-b2b661d75697", ENDITEM, 
		"Name=ctl00$hidPageState", "Value=Read", ENDITEM, 
		"Name=ctl00$hidNavigateUrl", "Value=http://parlisweb2/parlis/", ENDITEM, 
		"Name=ctl00$hidHelpId", "Value=activiteitupdate", ENDITEM, 
		EXTRARES, 
		"Url=../RESOURCES/NEWITEM.GIF", "Referer=http://parlisweb2/parlis/activiteit.aspx?id=4c2b9ec6-3c6c-4c4c-ad05-b2b661d75697", ENDITEM, 
		"Url=../RESOURCES/VOLGORDE.GIF", "Referer=http://parlisweb2/parlis/activiteit.aspx?id=4c2b9ec6-3c6c-4c4c-ad05-b2b661d75697", ENDITEM, 
		"Url=../RESOURCES/BESL.GIF", "Referer=http://parlisweb2/parlis/activiteit.aspx?id=4c2b9ec6-3c6c-4c4c-ad05-b2b661d75697", ENDITEM, 
		"Url=../RESOURCES/AGENDA.GIF", "Referer=http://parlisweb2/parlis/activiteit.aspx?id=4c2b9ec6-3c6c-4c4c-ad05-b2b661d75697", ENDITEM, 
		LAST);

	web_url("DialogStarter.aspx", 
		"URL=http://parlisweb2/parlis/DialogStarter.aspx?dialog=Verwerken.aspx%3Factiviteit%3D4c2b9ec6-3c6c-4c4c-ad05-b2b661d75697", 
		"Resource=0", 
		"RecContentType=text/html", 
		"Referer=", 
		"Snapshot=t20.inf", 
		"Mode=HTML", 
		LAST);

	/* Registering parameter(s) from source task id 227
	// {Siebel_Analytic_ViewState3} = "/wEPDwUJNTAyNjUwMzA0D2QWAmYPZBYCAgMPZBYIAgUPDxYCHg1PbkNsaWVudENsaWNrBR9qYXZhc2NyaXB0OnJldHVybiBkaXNwbGF5SGVscCgpZGQCBw9kFgJmD2QWAmYPZBYCZg8PFgIeBFRleHQFCVZlcndlcmtlbmRkAgsPZBYCAgEPZBYEAgEPDxYCHwEFJUdlc2VsZWN0ZWVyZGUgaXRlbXMgd29yZGVuIGdlbGFkZW4uLi5kZAIDD2QWAgIFDzwrAAoAZAIPDxYCHwEFnQE8c2NyaXB0PkhFTFBQQVRIPSdodHRwOi8vcGFybGlzYWNjZXB0d3NzMi9oZWxwJztIRUxQQ09OVFJPTD0nY3RsMDAkaGlkSGVscElkJztQQVJMSVNVUkw9J2h0dHA6Ly9wYXJsaXN3ZWIyL3Bhcmxpcyc7V1NTVVJMPSdodHRwOi8vcGFybGlzYWNjZXB0d3NzMic7PC9zY3JpcHQ+ZBgDBR5fX0NvbnRyb2xzUmVxdWlyZVBvc3RCYWNrS2V5X18WBAUgY3RsMDAkbWFpbkJvZHkkcmRWb2xnZW5zVm9vcnN0ZWwFGmN0bDAwJG1haW5Cb2R5JHJkQWZ3aWprZW5kBRpjdGwwMCRtYWluQm9keSRyZEFmd2lqa2VuZAUZY3RsMDAkbWFpbkJvZHkkY2hWZXJ3ZXJrdAUGX19QYWdlDxQrAAJkMokCAAEAAAD/////AQAAAAAAAAAMAgAAAEdBcHBfV2ViX2NhZzh5bm1zLCBWZXJzaW9uPTAuMC4wLjAsIEN1bHR1cmU9bmV1dHJhbCwgUHVibGljS2V5VG9rZW49bnVsbAUBAAAAK0VQLlBhcmxpcy5XZWJDb250cm9scy5WZXJ3ZXJrZW5Db250cm9sU3RhdGUBAAAAB2FjdGd1aWQDC1N5c3RlbS5HdWlkAgAAAAT9////C1N5c3RlbS5HdWlkCwAAAAJfYQJfYgJfYwJfZAJfZQJfZgJfZwJfaAJfaQJfagJfawAAAAAAAAAAAAAACAcHAgICAgICAgIAAAAAAAAAAAAAAAAAAAAAC2QFIGN0bDAwJG1haW5Cb2R5JGZ2Vm9vcnN0ZWxEaXNwbGF5D2dkZN+myAfapvZkW1HsBHahvIWu3Ek="
	// */

	web_reg_save_param("Siebel_Analytic_ViewState3", 
		"LB/IC=ViewState" value="", 
		"RB/IC="", 
		"Ord=1", 
		"Search=Body", 
		"RelFrameId=1", 
		LAST);

	web_url("Verwerken.aspx", 
		"URL=http://parlisweb2/parlis/Verwerken.aspx?activiteit=4c2b9ec6-3c6c-4c4c-ad05-b2b661d75697", 
		"Resource=0", 
		"RecContentType=text/html", 
		"Referer=http://parlisweb2/parlis/DialogStarter.aspx?dialog=Verwerken.aspx%3Factiviteit%3D4c2b9ec6-3c6c-4c4c-ad05-b2b661d75697", 
		"Snapshot=t21.inf", 
		"Mode=HTML", 
		EXTRARES, 
		"Url=../RESOURCES/SAVE.GIF", "Referer=http://parlisweb2/parlis/Verwerken.aspx?activiteit=4c2b9ec6-3c6c-4c4c-ad05-b2b661d75697", ENDITEM, 
		"Url=../RESOURCES/CANCEL.GIF", "Referer=http://parlisweb2/parlis/Verwerken.aspx?activiteit=4c2b9ec6-3c6c-4c4c-ad05-b2b661d75697", ENDITEM, 
		LAST);

	/* Registering parameter(s) from source task id 231
	// {Siebel_Analytic_ViewState5} = "/wEPDwUJNTAyNjUwMzA0D2QWAmYPZBYCAgMPZBYIAgUPDxYEHg1PbkNsaWVudENsaWNrBR9qYXZhc2NyaXB0OnJldHVybiBkaXNwbGF5SGVscCgpHgRUZXh0BQRIZWxwZGQCBw9kFgJmD2QWAmYPZBYCZg8PFgIfAQUJVmVyd2Vya2VuZGQCCw9kFgICAQ9kFgQCAQ8PFgIfAWVkZAIDD2QWBAIBD2QWAgIBDxYCHgtfIUl0ZW1Db3VudAIBFgJmD2QWAgIBDw8WAh8BBckBPGRpdj4zMjQ2NiZuYnNwOy0mbmJzcDs8c3Bhbj5CcmllZiBkZXJkZW48L3NwYW4+Jm5ic3A7LSZuYnNwOzxzcGFuPjAxLTAzLTIwMTE8L3NwYW4+PC9kaXY+PGRpdj48c3Bhbj5UZXN0IFBhbHJpcy1JQ1RVIEludGVyZmFjZSAtIDAwMjwvc3Bhbj48L2Rpdj48ZGl2PlZvb3JzdGVsOiZuYnNwOzxzcGFuPkJlaGFuZGVsZW48L3NwYW4+PC9kaXY+PGJyIC8+ZGQCBQ88KwAKAQAPFgIeB1Zpc2libGVoZGQCDw8WAh8BBZ0BPHNjcmlwdD5IRUxQUEFUSD0naHR0cDovL3Bhcmxpc2FjY2VwdHdzczIvaGVscCc7SEVMUENPTlRST0w9J2N0bDAwJGhpZEhlbHBJZCc7UEFSTElTVVJMPSdodHRwOi8vcGFybGlzd2ViMi9wYXJsaXMnO1dTU1VSTD0naHR0cDovL3Bhcmxpc2FjY2VwdHdzczInOzwvc2NyaXB0PmQYAwUeX19Db250cm9sc1JlcXVpcmVQb3N0QmFja0tleV9fFgQFIGN0bDAwJG1haW5Cb2R5JHJkVm9sZ2Vuc1Zvb3JzdGVsBRpjdGwwMCRtYWluQm9keSRyZEFmd2lqa2VuZAUaY3RsMDAkbWFpbkJvZHkkcmRBZndpamtlbmQFGWN0bDAwJG1haW5Cb2R5JGNoVmVyd2Vya3QFBl9fUGFnZQ8UKwACZDKJAgABAAAA/////wEAAAAAAAAADAIAAABHQXBwX1dlYl9jYWc4eW5tcywgVmVyc2lvbj0wLjAuMC4wLCBDdWx0dXJlPW5ldXRyYWwsIFB1YmxpY0tleVRva2VuPW51bGwFAQAAACtFUC5QYXJsaXMuV2ViQ29udHJvbHMuVmVyd2Vya2VuQ29udHJvbFN0YXRlAQAAAAdhY3RndWlkAwtTeXN0ZW0uR3VpZAIAAAAE/f///wtTeXN0ZW0uR3VpZAsAAAACX2ECX2ICX2MCX2QCX2UCX2YCX2cCX2gCX2kCX2oCX2sAAAAAAAAAAAAAAAgHBwICAgICAgICxp4rTGw8TEytBbK2YddWlwtkBSBjdGwwMCRtYWluQm9keSRmdlZvb3JzdGVsRGlzcGxheQ9nZGF4biHEDBgl6nemohzFxCI5AXY8"
	// */

	web_reg_save_param("Siebel_Analytic_ViewState5", 
		"LB/IC=ViewState" value="", 
		"RB/IC="", 
		"Ord=1", 
		"Search=Body", 
		"RelFrameId=1", 
		LAST);

	web_submit_data("Verwerken.aspx_2", 
		"<viewstate added to list re=2>", ENDITEM, 
		"Name=__SCROLLPOSITIONX", "Value=0", ENDITEM, 
		"Name=__SCROLLPOSITIONY", "Value=0", ENDITEM, 
		"Name=ctl00$mainBody$Besluit", "Value=rdVolgensVoorstel", ENDITEM, 
		"Name=ctl00$mainBody$GetDialogArgumentsControl", "Value=true", ENDITEM, 
		"Name=ctl00$hidPageState", "Value=Read", ENDITEM, 
		"Name=ctl00$hidNavigateUrl", "Value=http://parlisweb2/parlis/DialogStarter.aspx?dialog=Verwerken.aspx%3Factiviteit%3D4c2b9ec6-3c6c-4c4c-ad05-b2b661d75697", ENDITEM, 
		"Name=ctl00$hidHelpId", "Value=Verwerken", ENDITEM, 
		LAST);

	web_submit_data("Verwerken.aspx_3", 
		"<viewstate added to list re=2>", ENDITEM, 
		"Name=__SCROLLPOSITIONX", "Value=0", ENDITEM, 
		"Name=__SCROLLPOSITIONY", "Value=0", ENDITEM, 
		"Name=ctl00$mainBody$Besluit", "Value=rdVolgensVoorstel", ENDITEM, 
		"Name=ctl00$mainBody$chVerwerkt", "Value=on", ENDITEM, 
		"Name=ctl00$mainBody$GetDialogArgumentsControl", "Value=false", ENDITEM, 
		"Name=ctl00$hidPageState", "Value=Read", ENDITEM, 
		"Name=ctl00$hidNavigateUrl", "Value=http://parlisweb2/parlis/DialogStarter.aspx?dialog=Verwerken.aspx%3Factiviteit%3D4c2b9ec6-3c6c-4c4c-ad05-b2b661d75697", ENDITEM, 
		"Name=ctl00$hidHelpId", "Value=Verwerken", ENDITEM, 
		LAST);

	web_submit_data("activiteit.aspx_3", 
		"Action=http://parlisweb2/parlis/activiteit.aspx?id=4c2b9ec6-3c6c-4c4c-ad05-b2b661d75697", 
		"Method=POST", 
		"RecContentType=text/html", 
		"Referer=http://parlisweb2/parlis/activiteit.aspx?id=4c2b9ec6-3c6c-4c4c-ad05-b2b661d75697", 
		"Snapshot=t24.inf", 
		"Mode=HTML", 
		ITEMDATA, 
		"Name=ctl00_ScriptManager_HiddenField", "Value=", ENDITEM, 
		"Name=__EVENTTARGET", "Value=ctl00$toolBar$btnVerwerken", ENDITEM, 
		"Name=__EVENTARGUMENT", "Value=", ENDITEM, 
		"Name=__VIEWSTATE", "Value=", ENDITEM, 
		"Name=__SCROLLPOSITIONX", "Value=0", ENDITEM, 
		"Name=__SCROLLPOSITIONY", "Value=0", ENDITEM, 
		"Name=ctl00$mainBody$TabStrip1$hidCurrentTabIndex", "Value=1", ENDITEM, 
		"Name=ctl00$mainBody$Agenda1$GridViewRubrieken$ctl02$hidRubriek", "Value=all", ENDITEM, 
		"Name=ctl00$mainBody$Agenda1$GridViewRubrieken$ctl02$hidRubriekInvalid", "Value=False", ENDITEM, 
		"Name=ctl00$mainBody$Agenda1$GridViewRubrieken$ctl02$GridViewAgendapunten$ctl02$ddlVolgorde", "Value=1", ENDITEM, 
		"Name=ctl00$mainBody$Agenda1$GridViewRubrieken$ctl02$GridViewAgendapunten$ctl02$gvZakenBesluiten$ctl02$chkSelect", "Value=399833f6-ef45-42a4-8fe3-66c1d2ee7b7a", ENDITEM, 
		"Name=ctl00$mainBody$Agenda1$hidAgendaPuntId", "Value=", ENDITEM, 
		"Name=ctl00$mainBody$Agenda1$hidCurrentSelect", "Value=", ENDITEM, 
		"Name=ctl00$mainBody$Agenda1$hidIsUitgevoerd", "Value=True", ENDITEM, 
		"Name=ctl00$mainBody$Agenda1$hidCie", "Value=XXX", ENDITEM, 
		"Name=ctl00$hidPageState", "Value=Read", ENDITEM, 
		"Name=ctl00$hidNavigateUrl", "Value=http://parlisweb2/parlis/", ENDITEM, 
		"Name=ctl00$hidHelpId", "Value=activiteitupdate", ENDITEM, 
		LAST);


	return 0;
}

vuser_end()
{
	return 0;
}

vuser_init()
{
	return 0;
}

