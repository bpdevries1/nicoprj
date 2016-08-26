# first delete db/html in order to create again and check diffs.

rm /home/ymor/RABO/testruns/MCPv3/uat-extra-fields/*.db
rm /home/ymor/RABO/testruns/MCPv3/uat-extra-fields/*.html

# for all subdirs in dir: read logs into sqlite db and create html reports.
# just read one dir now:
tclsh read-report-dir.tcl -all -dir /home/ymor/RABO/testruns/MCPv3/uat-extra-fields

echo ================================
echo === Check diffs below ==========
echo ================================

# [2016-08-18 23:05] for now no AHK, is ignored for now.
diff /home/ymor/RABO/testruns/MCPv3/uat-extra-fields/report-summary.html /home/ymor/RABO/testruns/MCPv3/uat-extra-fields/report-summary.html.orig

echo === end of diffs ===
