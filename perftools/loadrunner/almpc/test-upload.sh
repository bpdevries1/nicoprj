/c/PCC/Util/cygwin/bin/curl.exe -c cookies.txt --header "Authorization: Basic dnJlZXplbmI6VnJlZXplTkI=" "http://wsrv5334.rabobank.corp/loadtest/rest/authentication-point/authenticate"

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
 
/c/PCC/Util/cygwin/bin/curl.exe -b cookies.txt -X POST --header "Content-Type: application/xml" --data-binary @RCC_All2.zip --data @upload.xml  "http://wsrv5334.rabobank.corp/loadtest/rest/domains/RI/projects/Scrittura/Scripts"
