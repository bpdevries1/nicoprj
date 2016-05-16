# ./extraprocessing.tcl -dir ~/Ymor/Philips/KNDL-test -debug -actions maxitem -loglevel debug
# ./extraprocessing.tcl -dir ~/Ymor/Philips/KNDL-test -debug -actions gt3 -loglevel debug
# ./extraprocessing.tcl -dir ~/Ymor/Philips/KNDL-test -debug -actions dailystats -loglevel debug
# ./extraprocessing.tcl -pattern "Shop*" -actions dailystats,maxitem,gt3,analyze -loglevel debug -debug
./extraprocessing.tcl -actions dailystats,maxitem,gt3,analyze -loglevel debug -debug

