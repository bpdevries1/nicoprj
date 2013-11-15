# @pre current-dir is this script-dir
# # ../keynotetools/extraprocessing.tcl -dir /cygdrive/c/projecten/Philips/KNDL -updatemaxitem -pattern "Shop*"
# ../keynotetools/extraprocessing.tcl -dir /cygdrive/c/projecten/Philips/KNDL -actions maxitem,gt3 -pattern "Shop*"
../dashboardtools/combinetables.tcl -dir c:/projecten/Philips/Shop/daily -db daily.db -srcdir c:/projecten/Philips/KNDL -srcpattern "Shop*" -tables "aggr_run,aggr_page" -droptarget 
../graphtools/graph-shop-kn.tcl -outformat png 

