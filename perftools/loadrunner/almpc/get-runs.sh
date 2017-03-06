# one off om result meta data van een aantal runs op te halen, als input voor excel met ovz runs.

/c/PCC/Util/cygwin/bin/curl.exe -c cookies.txt --header "Authorization: Basic dnJlZXplbmI6VnJlZXplTkI=" "http://wsrv5334.rabobank.corp/loadtest/rest/authentication-point/authenticate"

# eerst data van 1 run, hopelijk sneller
/c/PCC/Util/cygwin/bin/curl.exe -b cookies.txt --header "Accept: application/xml" -o printnet-runs-349.xml "http://wsrv5334.rabobank.corp/loadtest/rest/domains/BETALENSPAREN/projects/Printnet/Runs/349"

/c/PCC/Util/cygwin/bin/curl.exe -b cookies.txt --header "Accept: application/xml" -o printnet-runs-349-results.xml "http://wsrv5334.rabobank.corp/loadtest/rest/domains/BETALENSPAREN/projects/Printnet/Runs/349/Results"

# Haal runs op.
# /LoadTest/rest/domains/{domainName}/projects/{projectName}/runs
/c/PCC/Util/cygwin/bin/curl.exe -b cookies.txt --header "Accept: application/xml" -o printnet-runs.xml "http://wsrv5334.rabobank.corp/loadtest/rest/domains/BETALENSPAREN/projects/Printnet/Runs"




# [2017-01-26 20:57:54] logout ook eens doen, je weet maar nooit.
#echo before logout
/c/PCC/Util/cygwin/bin/curl.exe -b cookies.txt "http://wsrv5334.rabobank.corp/loadtest/rest/authentication-point/logout"
#echo after logout
echo " "


