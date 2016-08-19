# first delete db/html in order to create again and check diffs.

rm /home/ymor/RABO/testruns/MCPv3/ahk-2016-08-11--12-13-00/*.db
rm /home/ymor/RABO/testruns/MCPv3/ahk-2016-08-11--12-13-00/*.html
rm /home/ymor/RABO/testruns/MCPv3/vugen-2016-08-06--11-17-09/*.db
rm /home/ymor/RABO/testruns/MCPv3/vugen-2016-08-06--11-17-09/*.html

# for all subdirs in dir: read logs into sqlite db and create html reports.
tclsh read-report-dir.tcl -all -dir /home/ymor/RABO/testruns/MCPv3

# do a few diffs with orig reports to see if nothing has changed.
echo ================================
echo === Check diffs below ==========
echo ================================

# [2016-08-18 23:05] for now no AHK, is ignored for now.
diff /home/ymor/RABO/testruns/MCPv3/ahk-2016-08-11--12-13-00/report-summary.html /home/ymor/RABO/testruns/MCPv3/ahk-2016-08-11--12-13-00/report-summary.html.orig

diff /home/ymor/RABO/testruns/MCPv3/vugen-2016-08-06--11-17-09/report-summary.html /home/ymor/RABO/testruns/MCPv3/vugen-2016-08-06--11-17-09/report-summary.html.orig

echo === end of diffs ===

