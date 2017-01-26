/c/PCC/Util/cygwin/bin/curl.exe -c cookies.txt --header "Authorization: Basic dnJlZXplbmI6VnJlZXplTkI=" "http://wsrv5334.rabobank.corp/loadtest/rest/authentication-point/authenticate"

# [2017-01-22 19:52:52] paar herkansingen met meer info gevonden vorige week.
#/c/PCC/Util/cygwin/bin/curl.exe --trace curltrace.out -b cookies.txt -X POST --header "Content-Type: multipart/form-data" -F Demo=@RCC_All2.zip -F name=@upload.xml "http://wsrv5334.rabobank.corp/loadtest/rest/domains/RI/projects/Scrittura/Scripts"

# /c/PCC/Util/cygwin/bin/curl.exe --trace curltrace.out -b cookies.txt -X POST --header "Content-Type: multipart/form-data" -F Demo=@RCC_All2.zip -F xml=<upload.xml "http://wsrv5334.rabobank.corp/loadtest/rest/domains/RI/projects/Scrittura/Scripts"

# "web=@index.html;type=text/html"

#/c/PCC/Util/cygwin/bin/curl.exe --trace curltrace.out -b cookies.txt -X POST --header "Content-Type: multipart/form-data" -F "Demo=@RCC_All2.zip;type=application/x-zip-compressed" -F name=@upload.xml "http://wsrv5334.rabobank.corp/loadtest/rest/domains/RI/projects/Scrittura/Scripts"

# [2017-01-22 20:34:27] met deze geeft upload goede melding, maar hierna toch fout in ALM UI:
# /c/PCC/Util/cygwin/bin/curl.exe --trace curltrace.out -b cookies.txt -X POST --header "Content-Type: multipart/form-data" -F "Demo=@RCC_All2.zip;type=application/x-zip-compressed" -F "a=<upload.xml" "http://wsrv5334.rabobank.corp/loadtest/rest/domains/RI/projects/Scrittura/Scripts"

# [2017-01-26 20:02:22] sort-of werkende voor RCC:
# /c/PCC/Util/cygwin/bin/curl.exe --trace curltrace.out -b cookies.txt -X POST --header "Content-Type: multipart/form-data" -F "Demo=@RCC_All2.zip;type=application/x-zip-compressed" -F "xml=<upload.xml" "http://wsrv5334.rabobank.corp/loadtest/rest/domains/RI/projects/Scrittura/Scripts"

# [2017-01-26 20:02:29] nu wat testen met Inspire_DMS
# /c/PCC/Util/cygwin/bin/curl.exe --trace curltrace.out -b cookies.txt -X POST --header "Content-Type: multipart/form-data" -F "Demo=@Inspire_DMS.zip;type=application/x-zip-compressed" -F "xml=<upload.xml" "http://wsrv5334.rabobank.corp/loadtest/rest/domains/RI/projects/Scrittura/Scripts"

# [2017-01-26 20:30:12] en nu FAR, want Inspire-DMS is toch wat raar.
/c/PCC/Util/cygwin/bin/curl.exe --trace curltrace.out -b cookies.txt -X POST --header "Content-Type: multipart/form-data" -F "FAR=@FAR.zip;type=application/x-zip-compressed" -F "xml=<upload.xml" "http://wsrv5334.rabobank.corp/loadtest/rest/domains/RI/projects/Scrittura/Scripts"

# [2017-01-26 20:40:40] test/script metadata verder?
# /c/PCC/Util/cygwin/bin/curl.exe -b cookies.txt -o tests.xml "http://wsrv5334.rabobank.corp/loadtest/rest/domains/RI/projects/Scrittura/tests?page-size=200" 

# [2017-01-26 20:44:32] en specifiek scenario. Deze doet het niet.
# /c/PCC/Util/cygwin/bin/curl.exe -b cookies.txt -o test66.xml "http://wsrv5334.rabobank.corp/loadtest/rest/domains/RI/projects/Scrittura/tests/66" 

# [2017-01-26 20:51:24] deze doet het wel, mogelijk vorige niet omdat onderliggende script er niet meer is.
# /c/PCC/Util/cygwin/bin/curl.exe -b cookies.txt -o test54.xml "http://wsrv5334.rabobank.corp/loadtest/rest/domains/RI/projects/Scrittura/tests/54" 


# [2017-01-26 20:46:18] alle scripts? Ja, deze doet het wel.
# /c/PCC/Util/cygwin/bin/curl.exe -b cookies.txt -o scripts.xml "http://wsrv5334.rabobank.corp/loadtest/rest/domains/RI/projects/Scrittura/scripts" 

#/c/PCC/Util/cygwin/bin/curl.exe --trace curltrace-meta.out -b cookies.txt -o script-meta.xml "http://wsrv5334.rabobank.corp/loadtest/rest/domains/RI/projects/Scrittura/scripts/74"

# curl -F profile=@portrait.jpg https://example.com/upload.cgi

# exec_curl -c cookies.txt --header "Authorization: Basic [:auth_base64 $config]" "[:alm_url $config]/authentication-point/authenticate"

# /c/PCC/Util/cygwin/bin/curl.exe -b cookies.txt -X POST --header "Content-Type:application/xml" --data @upload.xml --data-binary @scrit-conf.zip  "http://wsrv5334.rabobank.corp/loadtest/rest/domains/RI/projects/Scrittura/Scripts"
# Content-Type: multipart/form-data

# /c/PCC/Util/cygwin/bin/curl.exe -b cookies.txt -X POST --header "Content-Type: application/xml" --data @upload.xml --data-binary @scrit-conf.zip  "http://wsrv5334.rabobank.corp/loadtest/rest/domains/RI/projects/Scrittura/Scripts"

# /c/PCC/Util/cygwin/bin/curl.exe -b cookies.txt -X POST --header "Content-Type: multipart/form-data" --data @upload.xml --data-binary @scrit-conf.zip  "http://wsrv5334.rabobank.corp/loadtest/rest/domains/RI/projects/Scrittura/Scripts"

# /c/PCC/Util/cygwin/bin/curl.exe -b cookies.txt -X POST --header "Content-Type:multipart/form-data" --data @upload.xml --data-binary @scrit-conf.zip -o output.html  "http://wsrv5334.rabobank.corp/loadtest/rest/domains/RI/projects/Scrittura/Scripts"

# /c/PCC/Util/cygwin/bin/curl.exe -b cookies.txt -X POST --header "Content-Type: multipart/form-data" --data @upload.xml --data-binary @scrit-conf.zip  "http://wsrv5334.rabobank.corp/loadtest/rest/domains/RI/projects/Scrittura/Scripts"

# /c/PCC/Util/cygwin/bin/curl.exe -b cookies.txt -X POST --header "Content-Type: application/xml" --data @upload.xml --data-binary @scrit-conf.zip  "http://wsrv5334.rabobank.corp/loadtest/rest/domains/RI/projects/Scrittura/Scripts"

# /c/PCC/Util/cygwin/bin/curl.exe -b cookies.txt -X POST --header "Content-Type: application/xml" --data-binary @scrit-conf.zip --data @upload.xml  "http://wsrv5334.rabobank.corp/loadtest/rest/domains/RI/projects/Scrittura/Scripts"

# /c/PCC/Util/cygwin/bin/curl.exe -b cookies.txt -X POST --header "Content-Type: text/text" --data-binary @scrit-conf.zip --data @upload.xml  "http://wsrv5334.rabobank.corp/loadtest/rest/domains/RI/projects/Scrittura/Scripts"

# /c/PCC/Util/cygwin/bin/curl.exe -b cookies.txt -X POST --data-binary @scrit-conf.zip --data @upload.xml  "http://wsrv5334.rabobank.corp/loadtest/rest/domains/RI/projects/Scrittura/Scripts"

# /c/PCC/Util/cygwin/bin/curl.exe -b cookies.txt -X POST --header "Content-Type: */*" --data-binary @scrit-conf.zip --data @upload.xml  "http://wsrv5334.rabobank.corp/loadtest/rest/domains/RI/projects/Scrittura/Scripts"

# /c/PCC/Util/cygwin/bin/curl.exe -b cookies.txt -X POST --header "Content-Type: multipart/form-data" --data-binary @scrit-conf.zip --data @upload.xml  "http://wsrv5334.rabobank.corp/loadtest/rest/domains/RI/projects/Scrittura/Scripts"

# /c/PCC/Util/cygwin/bin/curl.exe -b cookies.txt -X POST --header "Content-Type: application/xml" --data-binary @scrit-conf.zip --data @upload.xml  "http://wsrv5334.rabobank.corp/loadtest/rest/domains/RI/projects/Scrittura/Scripts"
 
# /c/PCC/Util/cygwin/bin/curl.exe -b cookies.txt -X POST --header "Content-Type: application/xml" --data-binary @RCC_All2.zip --data @upload.xml  "http://wsrv5334.rabobank.corp/loadtest/rest/domains/RI/projects/Scrittura/Scripts"


# [2017-01-26 20:57:54] logout ook eens doen, je weet maar nooit.
echo before logout
/c/PCC/Util/cygwin/bin/curl.exe -b cookies.txt "http://wsrv5334.rabobank.corp/loadtest/rest/authentication-point/logout"
echo after logout

