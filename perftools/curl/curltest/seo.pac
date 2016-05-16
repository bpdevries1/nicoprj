function FindProxyForURL(url, host) {
var ip=host;
 if(ip.indexOf("127.0")==0) {
   return "DIRECT";
 }
 if(shExpMatch(url,"http://pww*")) {
   return "DIRECT";
 }

if(shExpMatch(url,"http://lighting.*")) {
   return "DIRECT";
}

 if(shExpMatch(url,"https://share-intra.philips.com*")) {
   return "DIRECT";
 }

 if(shExpMatch(url,"http://review.*")) {
   return "DIRECT";
 }

 if((shExpMatch(url,"http://dev.*")) || (shExpMatch(url,"https://dev.*"))){
   return "DIRECT";
 }
 if(shExpMatch(url,"http://local*")) {
   return "DIRECT";
 }
 if((shExpMatch(url,"http://qaf.*")) || (shExpMatch(url,"https://qaf.*"))){
   return "DIRECT";
 }

 // Lookup in own hostfile 
 if(shExpMatch(url,"http://nlvu???/*") || shExpMatch(url,"http://nlvu???:*")) { 
//|| shExpMatch(url,"http://nlyehvgdc1?????:*") || shExpMatch(url,"http://nlyehvgdc1?????/*")) {
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

 if(shExpMatch(url,"http://www.qat*lighting*philips.*") || shExpMatch(url,"https://secure.qat*lighting*philips.*")) {
   return "PROXY 130.144.20.90:8080";
 }

 if(shExpMatch(url,"http://www.qat*ecat*lighting.*")) {
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
 //if(shExpMatch(url,"http://www.prd*consumer*philips.*") || shExpMatch(url,"https://secure.prd*consumer*philips.*")) {
 //  return "PROXY 130.144.20.90:8080";
 //}

 // Rackspace ecd environments
  if((shExpMatch(url,"http://*.cpp.philips.com*")) || (shExpMatch(url,"https://*.cpp.philips.com*"))){
   return "DIRECT";
 }

  // SEO for pcstestx environment
 if(shExpMatch(url,"http://www.pcstest*") || shExpMatch(url,"https://secure-pcstest*") || shExpMatch(url,"https://secure.pcstest*")) {
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

 // VirtualBox Host-only
 if(ip.indexOf("192.168.56")==0) {
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
 
// local machine (added on behalf of Malik Sundeep)
if(ip.indexOf("10.")==0) {
  return "DIRECT";
}

 // the rest of the world, no more proxies!
 //return "PROXY 130.144.19.49:8080; PROXY 130.144.124.100:8080";  // BT BlueCoat SK
 return "PROXY nl184-cips1.piap.philips.net:8080; PROXY nl184-cips2.piap.philips.net:8080; PROXY nl141-cips1.piap.philips.net:8080; PROXY nl141-cips2.piap.philips.net:8080";
// return "PROXY nl141-cips2.piap.philips.net:8080; PROXY nl042-cips2.piap.philips.net:8080";  // BT BlueCoat SK
}
