# First download most important items: myPhilips and Mobile
# 29-8-2013 now everything for dealer locator.
# ./download-scatter.tcl -config config-dl.csv -exitatok -untildate "2013-08-23"
# Mobile now more important 31-8-2013, myphilips also included
# 10-9-2013 config.csv now includes CBF flows all for CN and DE
#./download-scatter.tcl -config config.csv -exitatok

# 10-9-2013 and this one downloads all CBF flows.
#./download-scatter.tcl -config config-cbf.csv -exitatok

# then dealer locator (dl)
#./download-scatter.tcl -config config-dl.csv -exitatok
# then the orig with myphilips and mobile
# ./download-scatter.tcl -config config.csv -exitatok

# just mobile
# ./download-scatter.tcl -config config-mobile.csv -exitatok

# when finished, download everything.
# ./download-scatter.tcl -config config-all-noandroid.csv
# [2013-11-03 11:48:40] all 75 dirs left have basically the same importance.
# ./download-scatter.tcl -config config-all-win.csv

# don't use config file anymore, use slotmeta-domains.db
# ./download-scatter.tcl

# 7-2 use nanny2.tcl, check logfile if it's updated recently
# ./nanny.tcl tclsh ./scatter2db.tcl -nopost -moveread -continuous -actions all
# ./nanny2.tcl -checkfile download-scatter.tcl.log -timeout 1800 tclsh ./download-scatter.tcl >&@ stdout
# ./nanny2.tcl -checkfile download-scatter.tcl.log -timeout 1800 tclsh ./download-scatter.tcl

# 8-2 logfile nu dynamisch, dus andere checkfile.
./nanny2.tcl -checkfile download-scatter-check.log -timeout 1800 tclsh ./download-scatter.tcl -checkfile download-scatter-check.log

