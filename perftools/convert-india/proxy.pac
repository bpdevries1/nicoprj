var Pt;
var Pc;
function FindProxyForURL(url,host)
{
	/* Version .rel2013.3*/
	/* Remote Address 130.144.84.100*/
	/* Country NL*/
	var Mip;
	GetComponents(host,url);
	Mip = "130.144.84.100";
	// Start of insert top code for region 00 :: SERIAL-LBOEXTENDER-20017-OCT-28-2011-15:10-PM
	if (
	 (isPlainHostName(host) )
	|| (localHostOrDomainIs(host,"127.0.0.1") )
	|| (localHostOrDomainIs(host,"localhost") )
	|| (localHostOrDomainIs(host,"www.mail.philips.com") )
	|| (shExpMatch(host,"intranet.philips.com") )
	|| (shExpMatch(host,"pww*") )
	|| (shExpMatch(host,"mail.philips.com") )
	|| (shExpMatch(host,"meet.philips.com") )
	|| (shExpMatch(host,"dialin.philips.com") )
	|| (shExpMatch(host,"*webmeeting*.philips.com") )
	|| (shExpMatch(host,"fs.pamtst.philips.com") )
	) {
		return "DIRECT";
		}
	if (
	 (shExpMatch(host,"130.138.*") )
	|| (shExpMatch(host,"130.139.*") )
	|| (shExpMatch(host,"130.140.*") )
	|| (shExpMatch(host,"130.141.*") )
	|| (shExpMatch(host,"130.142.*") )
	|| (shExpMatch(host,"130.143.*") )
	|| (shExpMatch(host,"130.144.*") )
	|| (shExpMatch(host,"130.145.*") )
	|| (shExpMatch(host,"130.146.*") )
	|| (shExpMatch(host,"130.147.*") )
	|| (shExpMatch(host,"134.27.*") )
	|| (shExpMatch(host,"137.55.*") )
	|| (shExpMatch(host,"144.54.*") )
	|| (shExpMatch(host,"149.59.*") )
	|| (shExpMatch(host,"161.83.*") )
	|| (shExpMatch(host,"161.84.*") )
	|| (shExpMatch(host,"161.85.*") )
	|| (shExpMatch(host,"161.86.*") )
	|| (shExpMatch(host,"161.87.*") )
	|| (shExpMatch(host,"161.88.*") )
	|| (shExpMatch(host,"161.91.*") )
	|| (shExpMatch(host,"161.92.*") )
	|| (shExpMatch(host,"165.114.*") )
	|| (shExpMatch(host,"167.81.*") )
	|| (shExpMatch(host,"192.168.*") )
	|| (shExpMatch(host,"10.*") )
	) {
		return "DIRECT";
		}
	// End of insert
	// Start of insert top code for region NL :: SERIAL-NL-PROD-1234-NOV-14-2009-1:25-PM
	if (
	 (shExpMatch(host,"sjh.amec.philips.com") )
	|| (shExpMatch(host,"www.servicemanager.philips.com") )
	|| (shExpMatch(host,"192.68.48.*") )
	|| (shExpMatch(host,"192.68.49.*") )
	|| (shExpMatch(host,"*.sfohi.philips.com") )
	) {
		return "DIRECT";
		}
	// End of insert
	if (((dnsDomainIs(host,".ao-srv.com"))
	||(dnsDomainIs(host,".cian.nl"))
	||(dnsDomainIs(host,"hrn.philips.com"))
	||(localHostOrDomainIs(host,"gbrcrotpc2ms007.puk.philips.com"))
	||(localHostOrDomainIs(host,"incenter.medical.philips.com"))
	||(localHostOrDomainIs(host,"windchill-test.medical.philips.com"))
	||(localHostOrDomainIs(host,"windchill.medical.philips.com"))
	||(localHostOrDomainIs(host,"www.icp.lighting.philips.com"))
	||(shExpMatch(host,"*.cemafore.philips.com"))
	||(shExpMatch(host,"*.ditv.ce.philips.com"))
	||(shExpMatch(host,"*.ehv.bnl.philips.com"))
	||(shExpMatch(host,"*.ehv.corp.philips.com"))
	||(shExpMatch(host,"*.ehv.pnl.philips.com"))
	||(shExpMatch(host,"*.lep.research.philips.com"))
	||(shExpMatch(host,"*.rservices.com"))
	||(shExpMatch(host,"*.sv.philips.com"))
	||(shExpMatch(host,"*.wan.philips.com"))
	||(shExpMatch(host,"edw-fe-ce-europe.fil-eu.sv.philips.com"))
	||(shExpMatch(host,"eu1.ccc.p3c.philips.com"))
	||(shExpMatch(host,"nlannpr?.ehv.npr.philips.com"))
	||(shExpMatch(host,"nlroo*.*philips.com"))
	||(shExpMatch(host,"pcena-*.*.*.com"))
	||(shExpMatch(host,"sfo.amec.philips.com"))
	||(shExpMatch(host,"www.ba.lighting.philips.com"))))
	{
		return "DIRECT";
		}
	// Start of insert bottom code for NL :: SERIAL-NL-PROD-1234-NOV-14-2009-1:25-PM
	if (
	 (localHostOrDomainIs(host,"localhost") )
	|| (shExpMatch(host,"192.68.48.*") )
	|| (shExpMatch(host,"192.68.49.*") )
	) {
		return "DIRECT";
		}
	// End of insert
	// Start of insert bottom code for region 00 :: SERIAL-LBOEXTENDER-20017-OCT-28-2011-15:10-PM
	if (
	 (dnsDomainIs(host,".cemafore.ce.philips.com") )
	|| (dnsDomainIs(host,".servicemanager.philips.com") )
	|| (dnsDomainIs(host,"cle.amec.philips.com") )
	|| (dnsDomainIs(host,".hrn.philips.com") )
	|| (dnsDomainIs(host,".cemafore.philips.com") )
	|| (dnsDomainIs(host,".diamond.philips.com") )
	|| (dnsDomainIs(host,".ehv.ce.philips.com") )
	|| (dnsDomainIs(host,".ao-srv.com") )
	|| (dnsDomainIs(host,".emi.philips.com") )
	|| (dnsDomainIs(host,".evh-s.nl.philips.com") )
	|| (dnsDomainIs(host,".gdc1.philips.com") )
	|| (dnsDomainIs(host,".gdc1.ce.philips.com") )
	|| (dnsDomainIs(host,".ms.philips.com") )
	|| (dnsDomainIs(host,".nl.dap.philips.com") )
	|| (dnsDomainIs(host,".sharepoint.philips.com") )
	|| (dnsDomainIs(host,".solutioncenter.philips.com") )
	|| (dnsDomainIs(host,".sap-eu.lighting.philips.com") )
	|| (dnsDomainIs(host,".emeadc.lighting.philips.com") )
	|| (dnsDomainIs(host,".tradelink.philips.com") )
	|| (dnsDomainIs(host,".ocsweb.philips.com") )
	|| (dnsDomainIs(host,".im.philips.com") )
	|| (dnsDomainIs(host,".sip.philips.com") )
	|| (dnsDomainIs(host,".sipexternal.philips.com") )
	|| (localHostOrDomainIs(host,"pms1020onecomm1.medical.philips.com") )
	|| (localHostOrDomainIs(host,"softfab.ehv.apptech.philips.com") )
	|| (localHostOrDomainIs(host,"www.chat.philips.com") )
	|| (localHostOrDomainIs(host,"share-intra.philips.com") )
	|| (shExpMatch(host,"meetings.philips.com") )
	|| (shExpMatch(host,"pb.ipass.com") )
	|| (shExpMatch(host,"share.philips.com") )
	|| (shExpMatch(host,"mysite.philips.com") )
	|| (shExpMatch(host,"ppeshare-intra.philips.com") )
	|| (shExpMatch(host,"ppeintranet.philips.com") )
	|| (shExpMatch(host,"ppemysite.philips.com") )
	|| (shExpMatch(host,"ppeshare.philips.com") )
	|| (shExpMatch(host,"www.ourbrand.philips.com") )
	|| (shExpMatch(host,"www.teamcalendar.gcs.philips.com") )
	|| (shExpMatch(host,"philipsna-*.*philips.com") )
	|| (shExpMatch(host,"pms1020onewww1.medical.philips.com") )
	|| (shExpMatch(host,"incenter.medical.philips.com") )
	|| (shExpMatch(host,"*.solutions.philips.com") )
	|| (shExpMatch(host,"review.lighting.philips.com") )
	|| (shExpMatch(host,"review.newscenter.philips.com") )
	|| (shExpMatch(host,"review.healthcare.philips.com") )
	|| (shExpMatch(host,"review.medical.philips.com") )
	|| (shExpMatch(host,"*.pim.philips.com") )
	|| (shExpMatch(host,"*.pim-acc.philips.com") )
	|| (shExpMatch(host,"*.icp.lighting.philips.com") )
	|| (shExpMatch(host,"www.mobileportal.philips.com") )
	|| (shExpMatch(host,"www.trackwise*.amec.philips.com") )
	|| (shExpMatch(host,"*windchill*.philips.com") && !shExpMatch(host,"*windchill.plm.philips.com") )
	|| (shExpMatch(host,"pdmlink.respironics.com") )
	|| (shExpMatch(host,"*.livemeeting.com") )
	|| (shExpMatch(host,"*.placeware.com") )
	|| (shExpMatch(host,"*.microdose.se") )
	|| (shExpMatch(host,"*.microdose.philips.com") )
	|| (shExpMatch(host,"*.assetlibrary.philips.com") )
	|| (shExpMatch(host,"*.sso.philips.com") )
	|| (shExpMatch(host,"*ta.philips.com*") )
	|| (shExpMatch(host,"mail-*.philips.com") )
	) {
		return "DIRECT";
		}
	// End of insert
	return "PROXY nl184-cips2.piap.philips.net:8080; PROXY nl141-cips2.piap.philips.net:8080"
	}
function GetComponents(host,url)
{
	var ur;
	var dm;
	var i;
	Pt = "80";
	Pc = "http";
	i = url.indexOf(':');
	if (i > -1)
	{
		if (i < 7)
		{
			Pc = url.substring(0,i);
			if (url.length > i+3)
				i = i + 3;
			}
		ur = url.substring(i,url.length);
		i = ur.indexOf('/');
		if (i > -1)
			dm = ur.substring(0,i);
		else
			dm = ur;
		i = dm.indexOf(':');
		if (i > -1)
			Pt = dm.substring(i+1,ur.length);
		else
		{
			if (Pc == "https")
				Pt = "443";
			}
		}
	}
