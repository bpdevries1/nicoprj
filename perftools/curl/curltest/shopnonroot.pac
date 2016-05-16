function FindProxyForURL(url, host) {
var ip=host;
 if(ip.indexOf("127.0")==0) {
   return "DIRECT";
 }
 if(shExpMatch(url,"http://pww*")) {
   return "DIRECT";
 }
 if(shExpMatch(url,"http://local*")) {
   return "DIRECT";
 }

 if(shExpMatch(url,"http://review.*")) {
   return "DIRECT";
 }

 if(shExpMatch(url,"http://bcc.*")) {
   return "PROXY 130.144.20.85:8081";
 }

 if(shExpMatch(url,"http://csc.*")) {
   return "PROXY 130.144.20.85:8081";
 }

 if(shExpMatch(url,"http://bcc-emergency.*")) {
   return "PROXY 130.144.20.85:8081";
 }

// Added this but sounds like Harald meant agent instead of acc
 if(shExpMatch(url,"http://acc.*")) {
   return "PROXY 130.144.20.85:8081";
 }

 if(shExpMatch(url,"http://agent.*")) {
   return "PROXY 130.144.20.85:8081";
 }

 if(shExpMatch(url,"http://loader.*")) {
   return "PROXY 130.144.20.85:8081";
 }

// BCC to QAF
 if(shExpMatch(url,"http://10.128.41.54/*")) {
   return "DIRECT";
 }

 if(shExpMatch(url,"http://dev.*") || shExpMatch(url,"https://dev.*")) {
   return "PROXY 130.144.20.85:8081";
 }
// As we have more DEV environments now, reconfigured the resolving from "dev.*" to "dev1.*"
// When sure the above "dev.*" entry can be removed.
 if(shExpMatch(url,"http://dev1.*") || shExpMatch(url,"https://dev1.*")) {
   return "PROXY 130.144.20.85:8081";
 }
 if(shExpMatch(url,"http://dev2.*") || shExpMatch(url,"https://dev2.*")) {
   return "PROXY 130.144.20.85:8081";
 }
 if(shExpMatch(url,"http://dev3.*") || shExpMatch(url,"https://dev3.*")) {
   return "PROXY 130.144.20.85:8081";
 }
 if(shExpMatch(url,"http://www.dev.*") || shExpMatch(url,"https://www.dev.*")) {
   return "PROXY 130.144.20.85:8081";
 }
 if(shExpMatch(url,"http://www.dev2.*") || shExpMatch(url,"https://www.dev2.*")) {
   return "PROXY 130.144.20.85:8081";
 }
 if(shExpMatch(url,"http://www.dev3.*") || shExpMatch(url,"https://www.dev3.*")) {
   return "PROXY 130.144.20.85:8081";
 }


 if(shExpMatch(url,"http://qafi.*") || shExpMatch(url,"https://qafi.*")) {
   return "PROXY 130.144.20.85:8081";
 }
 if(shExpMatch(url,"http://qati.*") || shExpMatch(url,"https://qati.*")) {
   return "PROXY 130.144.20.85:8081";
 }
 if(shExpMatch(url,"http://qaf.*") || shExpMatch(url,"https://qaf.*")) {
   return "PROXY 130.144.20.85:8081";
 }
 if(shExpMatch(url,"http://qat.*") || shExpMatch(url,"https://qat.*")) {
   return "PROXY 130.144.20.85:8081";
 }
 if(shExpMatch(url,"http://www.qafi.*") || shExpMatch(url,"https://www.qafi.*")) {
   return "PROXY 130.144.20.85:8081";
 }
 if(shExpMatch(url,"http://www.qati.*") || shExpMatch(url,"https://www.qati.*")) {
   return "PROXY 130.144.20.85:8081";
 }
 if(shExpMatch(url,"http://www.qaf.*") || shExpMatch(url,"https://www.qaf.*")) {
   return "PROXY 130.144.20.85:8081";
 }
 if(shExpMatch(url,"http://www.qat.*") || shExpMatch(url,"https://www.qat.*")) {
   return "PROXY 130.144.20.85:8081";
 }

 if(shExpMatch(url,"http://qas.*") || shExpMatch(url,"https://qas.*")) {
   return "PROXY 130.144.20.85:8081";
 }

 if(shExpMatch(url,"http://www.qas.*") || shExpMatch(url,"https://www.qas.*")) {
   return "PROXY 130.144.20.85:8081";
 }

 if(shExpMatch(url,"http://eshop.qas.*") || shExpMatch(url,"https://eshop.qas.*")) {
   return "PROXY 130.144.20.85:8081";
 }

 if(shExpMatch(url,"http://myshop.qas.*") || shExpMatch(url,"https://myshop.qas.*")) {
   return "PROXY 130.144.20.85:8081";
 }

 if(shExpMatch(url,"http://experience.qas.*") || shExpMatch(url,"https://experience.qas.*")) {
   return "PROXY 130.144.20.85:8081";
 }

 if(shExpMatch(url,"http://partner.qas.*") || shExpMatch(url,"https://partner.qas.*")) {
   return "PROXY 130.144.20.85:8081";
 }

 if(shExpMatch(url,"http://www.partner.qas.*") || shExpMatch(url,"https://www.partner.qas.*")) {
   return "PROXY 130.144.20.85:8081";
 }

 if(shExpMatch(url,"http://qal.*") || shExpMatch(url,"https://qal.*")) {
   return "PROXY 130.144.20.85:8081";
 }

 if(shExpMatch(url,"http://www.qal.*") || shExpMatch(url,"https://www.qal.*")) {
   return "PROXY 130.144.20.85:8081";
 }

 if(shExpMatch(url,"http://eshop.qal.*") || shExpMatch(url,"https://eshop.qal.*")) {
   return "PROXY 130.144.20.85:8081";
 }

 if(shExpMatch(url,"http://myshop.qal.*") || shExpMatch(url,"https://myshop.qal.*")) {
   return "PROXY 130.144.20.85:8081";
 }

 if(shExpMatch(url,"http://experience.qal.*") || shExpMatch(url,"https://experience.qal.*")) {
   return "PROXY 130.144.20.85:8081";
 }

 if(shExpMatch(url,"http://partner.qal.*") || shExpMatch(url,"https://partner.qal.*")) {
   return "PROXY 130.144.20.85:8081";
 }

 if(shExpMatch(url,"http://www.partner.qal.*") || shExpMatch(url,"https://www.partner.qal.*")) {
   return "PROXY 130.144.20.85:8081";
 }

 if(shExpMatch(url,"http://prods.*") || shExpMatch(url,"https://prods.*")) {
   return "PROXY 130.144.20.85:8081";
 }

 if(shExpMatch(url,"http://www.prods.*") || shExpMatch(url,"https://www.prods.*")) {
   return "PROXY 130.144.20.85:8081";
 }

 if(shExpMatch(url,"http://eshop.prods.*") || shExpMatch(url,"https://eshop.prods.*")) {
   return "PROXY 130.144.20.85:8081";
 }

 if(shExpMatch(url,"http://myshop.prods.*") || shExpMatch(url,"https://myshop.prods.*")) {
   return "PROXY 130.144.20.85:8081";
 }

 if(shExpMatch(url,"http://experience.prods.*") || shExpMatch(url,"https://experience.prods.*")) {
   return "PROXY 130.144.20.85:8081";
 }

 if(shExpMatch(url,"http://partner.prods.*") || shExpMatch(url,"https://partner.prods.*")) {
   return "PROXY 130.144.20.85:8081";
 }

 if(shExpMatch(url,"http://www.partner.prods.*") || shExpMatch(url,"https://www.partner.prods.*")) {
   return "PROXY 130.144.20.85:8081";
 }

 if(shExpMatch(url,"http://prodl.*") || shExpMatch(url,"https://prodl.*")) {
   return "PROXY 130.144.20.85:8081";
 }

 // Lookup in own hostfile 
 if(shExpMatch(url,"http://nlvu???/*") || shExpMatch(url,"http://nlvu???:*") || shExpMatch(url,"http://nlyehvgdc1?????:*") || shExpMatch(url,"http://nlyehvgdc1?????/*")) {
 //if(shExpMatch(url,"http://nlvu???/*") || shExpMatch(url,"http://nlvu???:*")) {
   return "DIRECT";
 }

  // Local Domains (pure .com domains)
  if(shExpMatch(url,"http://nlvu*ce.philips.com:*") || shExpMatch(url,"http://nlvu*ce.philips.com/*") || shExpMatch(url,"http://nlyehvgdc1*.gdc1.philips.com:*") || shExpMatch(url,"http://nlyehv*.gdc1.philips.com/*")) {
   return "DIRECT";
  }

 // SEO Domains  (rest)
 if(shExpMatch(url,"http://nlvu*philips*") || shExpMatch(url,"https://secure-nlvu*philips*") || shExpMatch(url,"http://nlyehvgdc1*.gdc1*philips.*") || shExpMatch(url,"https://secure-nlyehvgdc1*.gdc1.philips.*")) {
   return "PROXY 130.144.20.90:8080";
 }
 // SEO domains for local developers
 if(shExpMatch(url,"http://nly*philips*") || shExpMatch(url,"https://secure-nly*philips*") || shExpMatch(url,"http://*ddns.htc.nl.philips*") || shExpMatch(url,"http://*devatgPC*")) {
   return "DIRECT";
 }

 // SEO domains for local developer VM
 if(shExpMatch(url,"http://*devatgPC*") || shExpMatch(url,"http://*devatgPC*")) {
   return "PROXY 130.144.20.90:8080";
 }

  // SEO for QAT environments
 if(shExpMatch(url,"http://www.qat*consumer*philips.*") || shExpMatch(url,"https://secure.qat*consumer*philips.*")) {
   return "PROXY 130.144.20.90:8080";
 }

 // For mobile site
 if(shExpMatch(url,"http://m.qat*consumer*philips.*")) {
   return "PROXY 130.144.20.90:8080";
 }

  // SEO for BAT environments
 if(shExpMatch(url,"http://www.bat*consumer*philips.*") || shExpMatch(url,"https://secure.bat*consumer*philips.*")) {
   return "PROXY 130.144.20.90:8080";
 }

  // SEO for Stagency environment
 if(shExpMatch(url,"http://www.stagency*consumer*philips.*") || shExpMatch(url,"https://secure.stagency*consumer*philips.*")) {
   return "PROXY 130.144.20.90:8080";
 }

  // SEO for ECDUAT environment
 if(shExpMatch(url,"http://www.ecduat*consumer*philips.*") || shExpMatch(url,"https://secure.ecduat*consumer*philips.*")) {
   return "PROXY 130.144.20.90:8080";
 }

  // SEO for PRD3 environment
 if(shExpMatch(url,"http://www.prd*consumer*philips.*") || shExpMatch(url,"https://secure.prd*consumer*philips.*")) {
   return "PROXY 130.144.20.90:8080";
 }

  // SEO for pcstestx environment
 if(shExpMatch(url,"http://www.pcstest*") || shExpMatch(url,"https://secure.pcstest*")) {
   return "PROXY 130.144.20.90:8080";
 }

  // Akamai rules
 if(shExpMatch(url,"http://www.philips.*") || shExpMatch(url,"https://secure.philips.*")) {
    return "DIRECT";
 }

 // local machine
 if(ip.indexOf("130.")==0) {
  return "DIRECT";
 }

 // Admin pages
 if(ip.indexOf("167.81.127")==0 || ip.indexOf("192.168")==0) {
   return "PROXY 130.144.20.80:3128";
 }

 // nino andover and logfiles
 if(shExpMatch(url,"http://pce-1012man*")) {
   return "PROXY 130.144.20.80:3128";
 }
 //
 
 // the rest of the world, no more proxies!
 //return "PROXY 130.144.19.49:8080; PROXY 130.144.124.100:8080";  // BT BlueCoat SK
 return "PROXY nl184-cips1.piap.philips.net:8080; PROXY nl184-cips2.piap.philips.net:8080; PROXY nl141-cips1.piap.philips.net:8080; PROXY nl141-cips2.piap.philips.net:8080";
// return "PROXY nl141-cips2.piap.philips.net:8080; PROXY nl042-cips2.piap.philips.net:8080";  // BT BlueCoat SK
}
