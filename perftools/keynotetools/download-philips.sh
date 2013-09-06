# First download most important items: myPhilips and Mobile
# 29-8-2013 now everything for dealer locator.
# ./download-scatter.tcl -config config-dl.csv -exitatok -untildate "2013-08-23"
# Mobile now more important 31-8-2013, myphilips also included
./download-scatter.tcl -config config.csv -exitatok

# then dealer locator (dl)
./download-scatter.tcl -config config-dl.csv -exitatok
# then the orig with myphilips and mobile
# ./download-scatter.tcl -config config.csv -exitatok

# just mobile
# ./download-scatter.tcl -config config-mobile.csv -exitatok

# when finished, download everything.
./download-scatter.tcl -config config-all-noandroid.csv
