# Linux: download script-data for script not investigated currently (or in the past).
# ./download-scatter.tcl -dir ~/Ymor/Philips/KNDL -config config-all-linux.csv

# 3-1-2014 use slotmeta.db now and hostname.
# 10-1-2014 use nanny, because checkdl.db is sometimes locked and process fails, so need to restart. 
./nanny.tcl tclsh86 ./download-scatter.tcl -dir ~/Ymor/Philips/KNDL

