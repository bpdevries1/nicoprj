/c/PCC/Util/cygwin/bin/curl.exe -c cookies.txt --header "Authorization: Basic dnJlZXplbmI6VnJlZXplTkI=" "http://wsrv5334.rabobank.corp/loadtest/rest/authentication-point/authenticate"

# [2017-01-26 20:30:12] en nu FAR, want Inspire-DMS is toch wat raar.
# /c/PCC/Util/cygwin/bin/curl.exe --trace curltrace.out -b cookies.txt -X POST --header "Content-Type: multipart/form-data" -F "FAR=@FAR.zip;type=application/x-zip-compressed" -F "xml=<upload.xml" "http://wsrv5334.rabobank.corp/loadtest/rest/domains/RI/projects/Scrittura/Scripts"

# tests/{ID}/validity
#/c/PCC/Util/cygwin/bin/curl.exe -b cookies.txt -o scen77-valid.xml "http://wsrv5334.rabobank.corp/loadtest/rest/domains/RI/projects/Scrittura/Tests/77/validity"
# /c/PCC/Util/cygwin/bin/curl.exe -b cookies.txt -o scen52-valid.xml "http://wsrv5334.rabobank.corp/loadtest/rest/domains/RI/projects/Scrittura/Tests/52/validity"

# tests/{ID}
#/c/PCC/Util/cygwin/bin/curl.exe -b cookies.txt -o scen77.xml "http://wsrv5334.rabobank.corp/loadtest/rest/domains/RI/projects/Scrittura/Tests/77"
# /c/PCC/Util/cygwin/bin/curl.exe -b cookies.txt -o scen52.xml "http://wsrv5334.rabobank.corp/loadtest/rest/domains/RI/projects/Scrittura/Tests/52"

# als json
# /c/PCC/Util/cygwin/bin/curl.exe -b cookies.txt --header "Accept: application/json" -o scen77.json "http://wsrv5334.rabobank.corp/loadtest/rest/domains/RI/projects/Scrittura/Tests/77"


# upload new for ID=77
# /c/PCC/Util/cygwin/bin/curl.exe --trace curltrace-scen77-upload.out -b cookies.txt -X PUT --header "Content-Type: application/xml" -F "xml=<scen77.xml" "http://wsrv5334.rabobank.corp/loadtest/rest/domains/RI/projects/Scrittura/Tests/77"


# upload new JSON for ID=77
# /c/PCC/Util/cygwin/bin/curl.exe -b cookies.txt -X PUT --header "Content-Type: application/json" --header "Accept: application/json" -F "xml=<scen77.json" "http://wsrv5334.rabobank.corp/loadtest/rest/domains/RI/projects/Scrittura/Tests/77"

# /c/PCC/Util/cygwin/bin/curl.exe -b cookies.txt -X PUT --header "Content-Type: application/json" --header "Accept: application/json" -F "@scen77.json;type=application/json" "http://wsrv5334.rabobank.corp/loadtest/rest/domains/RI/projects/Scrittura/Tests/77"

# met --upload-file (josn)
# /c/PCC/Util/cygwin/bin/curl.exe -b cookies.txt -X PUT --header "Content-Type: application/json" --header "Accept: application/json" --upload-file scen77.json "http://wsrv5334.rabobank.corp/loadtest/rest/domains/RI/projects/Scrittura/Tests/77"

# deel van de json content:
/c/PCC/Util/cygwin/bin/curl.exe -b cookies.txt -X PUT --header "Content-Type: application/json" --header "Accept: application/json" --upload-file scen77-update.json "http://wsrv5334.rabobank.corp/loadtest/rest/domains/RI/projects/Scrittura/Tests/77"


# zelfde weer met XML:
# /c/PCC/Util/cygwin/bin/curl.exe -b cookies.txt -X PUT --header "Content-Type: application/xml" --header "Accept: application/xml" --upload-file scen77.xml "http://wsrv5334.rabobank.corp/loadtest/rest/domains/RI/projects/Scrittura/Tests/77"


# /c/PCC/Util/cygwin/bin/curl.exe -b cookies.txt -X PUT --header "Content-Type: application/xml" -F "xml=<scen77update.xml" "http://wsrv5334.rabobank.corp/loadtest/rest/domains/RI/projects/Scrittura/Tests/77"


# upload completely new
# /c/PCC/Util/cygwin/bin/curl.exe -b cookies.txt -X POST --header "Content-Type: application/xml" -F "xml=<scen77new.xml" "http://wsrv5334.rabobank.corp/loadtest/rest/domains/RI/projects/Scrittura/Tests"


# [2017-01-26 20:57:54] logout ook eens doen, je weet maar nooit.
#echo before logout
/c/PCC/Util/cygwin/bin/curl.exe -b cookies.txt "http://wsrv5334.rabobank.corp/loadtest/rest/authentication-point/logout"
#echo after logout
echo " "


