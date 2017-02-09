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
# /c/PCC/Util/cygwin/bin/curl.exe -b cookies.txt -X PUT --header "Content-Type: application/json" --header "Accept: application/json" --upload-file scen77-update.json "http://wsrv5334.rabobank.corp/loadtest/rest/domains/RI/projects/Scrittura/Tests/77"


# zelfde weer met XML:
# /c/PCC/Util/cygwin/bin/curl.exe -b cookies.txt -X PUT --header "Content-Type: application/xml" --header "Accept: application/xml" --upload-file scen77.xml "http://wsrv5334.rabobank.corp/loadtest/rest/domains/RI/projects/Scrittura/Tests/77"


# /c/PCC/Util/cygwin/bin/curl.exe -b cookies.txt -X PUT --header "Content-Type: application/xml" -F "xml=<scen77update.xml" "http://wsrv5334.rabobank.corp/loadtest/rest/domains/RI/projects/Scrittura/Tests/77"


# upload completely new
# /c/PCC/Util/cygwin/bin/curl.exe -b cookies.txt -X POST --header "Content-Type: application/xml" -F "xml=<scen77new.xml" "http://wsrv5334.rabobank.corp/loadtest/rest/domains/RI/projects/Scrittura/Tests"

# [2017-02-05 12:39:16] use XML example in docs, completely new: http://alm-help.saas.hpe.com/en/12.53/api_refs/Performance_Center_REST_API/Performance_Center_REST_API.htm#test_entity_xml.htm
# [2017-02-05 12:58:08] Deze best ok, wordt echt een scenario ingezet nu in ALM, wel met fouten, maar upload/POST voor het eerst goed!
# /c/PCC/Util/cygwin/bin/curl.exe --trace curltrace.out -b cookies.txt -X POST --header "Content-Type: application/xml" --header "Accept: application/xml" --upload-file scen-doc.xml "http://wsrv5334.rabobank.corp/loadtest/rest/domains/RI/projects/Scrittura/Tests"

# [2017-02-05 12:58:43] dan weer even met eigen file, en deze gaat goed!:
# /c/PCC/Util/cygwin/bin/curl.exe --trace curltrace.out -b cookies.txt -X POST --header "Content-Type: application/xml" --header "Accept: application/xml" --upload-file scen77new-v1.xml "http://wsrv5334.rabobank.corp/loadtest/rest/domains/RI/projects/Scrittura/Tests"

# [2017-02-05 13:11:56] en dan een update, deze gaat fout met generieke error, niet nuttig.
# /c/PCC/Util/cygwin/bin/curl.exe --trace curltrace.out -b cookies.txt -X PUT --header "Content-Type: application/xml" --header "Accept: application/xml" --upload-file scen77update-ID97.xml "http://wsrv5334.rabobank.corp/loadtest/rest/domains/RI/projects/Scrittura/Tests/97"

# [2017-02-05 13:20:08] deze ok, maar maakt wel een nieuwe, ondanks de /97
# /c/PCC/Util/cygwin/bin/curl.exe --trace curltrace.out -b cookies.txt -X POST --header "Content-Type: application/xml" --header "Accept: application/xml" --upload-file scen77new-v3.xml "http://wsrv5334.rabobank.corp/loadtest/rest/domains/RI/projects/Scrittura/Tests/97"

# [2017-02-05 13:20:19] dan hier dezelfde, maar PUT ipv POST => dan weer generieke fout.
# /c/PCC/Util/cygwin/bin/curl.exe --trace curltrace-put.out -b cookies.txt -X PUT --header "Content-Type: application/xml" --header "Accept: application/xml" --upload-file scen77new-v3.xml "http://wsrv5334.rabobank.corp/loadtest/rest/domains/RI/projects/Scrittura/Tests/97"

# scen77update-ID97.xml
# /c/PCC/Util/cygwin/bin/curl.exe --trace curltrace-put.out -b cookies.txt -X PUT --header "Content-Type: application/xml" --header "Accept: application/xml" --upload-file scen77update-ID97.xml "http://wsrv5334.rabobank.corp/loadtest/rest/domains/RI/projects/Scrittura/Tests/97"

# test een delete, is ook een soort update, en geen XML body.
# /c/PCC/Util/cygwin/bin/curl.exe --trace curltrace-delete.out -b cookies.txt -X DELETE --header "Content-Type: application/xml" --header "Accept: application/xml"  "http://wsrv5334.rabobank.corp/loadtest/rest/domains/RI/projects/Scrittura/Tests/98"

# dan test scenario 77 verwijderen, kijken of bestaande 4 runs blijven bestaan.
# /c/PCC/Util/cygwin/bin/curl.exe --trace curltrace-delete.out -b cookies.txt -X DELETE --header "Content-Type: application/xml" --header "Accept: application/xml"  "http://wsrv5334.rabobank.corp/loadtest/rest/domains/RI/projects/Scrittura/Tests/77"

# ook even script deleten, kijken of dit wil, empty script.
# /c/PCC/Util/cygwin/bin/curl.exe --trace curltrace-delete.out -b cookies.txt -X DELETE --header "Content-Type: application/xml" --header "Accept: application/xml"  "http://wsrv5334.rabobank.corp/loadtest/rest/domains/RI/projects/Scrittura/Scripts/95"

# POST en PUT met andere CURL opties:
# /c/PCC/Util/cygwin/bin/curl.exe --trace curltrace-put.out -b cookies.txt -X POST --header "Content-Type: application/xml" --header "Accept: application/xml" --upload-file scen77new-v1.xml "http://wsrv5334.rabobank.corp/loadtest/rest/domains/RI/projects/Scrittura/Tests"

# /c/PCC/Util/cygwin/bin/curl.exe --trace curltrace-put.out -b cookies.txt -X POST --header "Content-Type: application/xml" --header "Accept: application/xml" --data-urlencode @scen77new-v1.xml "http://wsrv5334.rabobank.corp/loadtest/rest/domains/RI/projects/Scrittura/Tests"

# en PUT
# /c/PCC/Util/cygwin/bin/curl.exe --trace curltrace-put.out -b cookies.txt -X PUT --header "Content-Type: application/xml" --header "Accept: application/xml" --data-urlencode @scen77new-v3.xml "http://wsrv5334.rabobank.corp/loadtest/rest/domains/RI/projects/Scrittura/Tests/97"

# met --upload-file sowieso een PUT? checken met trace. [2017-02-05 16:23:36] idd een PUT, gaat nog steeds fout.
# /c/PCC/Util/cygwin/bin/curl.exe --trace curltrace-put.out -b cookies.txt --header "Content-Type: application/xml" --header "Accept: application/xml" --upload-file scen77new-v3.xml "http://wsrv5334.rabobank.corp/loadtest/rest/domains/RI/projects/Scrittura/Tests/97"

# iets met groups, eerst een GET:
# /LoadTest/rest/domains/{domainName}/projects/{projectName}/tests/{ID}/Groups/{group name}
# /c/PCC/Util/cygwin/bin/curl.exe -b cookies.txt --header "Content-Type: application/xml" --header "Accept: application/xml" -o scen97-group "http://wsrv5334.rabobank.corp/loadtest/rest/domains/RI/projects/Scrittura/Tests/97/Groups/far"

# [2017-02-05 16:48:03] ok, dan een PUT of POST, eerst een PUT:
# /c/PCC/Util/cygwin/bin/curl.exe -b cookies.txt --header "Content-Type: application/xml" --header "Accept: application/xml" --upload-file scen97-group.xml "http://wsrv5334.rabobank.corp/loadtest/rest/domains/RI/projects/Scrittura/Tests/97/Groups/far"

# en een nieuwe group erbij
# generieke fout weer: niet op de XML, maar 1001-operation failed, dus onduidelijk. Eerder wel melding als group name in URL en XML niet overeenkomen.
# /c/PCC/Util/cygwin/bin/curl.exe -b cookies.txt --header "Content-Type: application/xml" --header "Accept: application/xml" --upload-file scen97-group.xml "http://wsrv5334.rabobank.corp/loadtest/rest/domains/RI/projects/Scrittura/Tests/97/Groups/dms"


# hierna nog: met -X PUT, met -X POST, met andere group name, zowel in URL als in de XML.

# add en delete van group is ook nog een optie, dan blijft test mogelijk bestaan!


# [2017-01-26 20:57:54] logout ook eens doen, je weet maar nooit.
#echo before logout
/c/PCC/Util/cygwin/bin/curl.exe -b cookies.txt "http://wsrv5334.rabobank.corp/loadtest/rest/authentication-point/logout"
#echo after logout
echo " "


