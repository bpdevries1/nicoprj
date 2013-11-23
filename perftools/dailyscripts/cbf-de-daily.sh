# @pre current-dir is this script-dir
# # ../keynotetools/extraprocessing.tcl -dir /cygdrive/c/projecten/Philips/KNDL -updatemaxitem -pattern "Shop*"
# ../keynotetools/extraprocessing.tcl -dir /cygdrive/c/projecten/Philips/KNDL -actions maxitem,gt3 -pattern "Shop*"
# @todo maybe want convention thttps://secure.philips.com.sg/myphilips/landing.jsp?country=SG&language=en&catalogType=CONSUMERo combine all aggr* tables.
../dashboardtools/combinetables.tcl -dir c:/projecten/Philips/CBF-DE/daily -db daily.db -srcdir c:/projecten/Philips/KNDL -srcpattern "CBF-DE-*" -tables "aggr_run,aggr_page,aggr_maxitem,aggr_sub,pageitem_gt3" -droptarget 
# ../dashboardtools/combinetables.tcl -dir c:/projecten/Philips/CBF-DE/daily -db daily.db -srcdir c:/projecten/Philips/KNDL -srcpattern "CBF-DE-*" -tables "aggr_run,aggr_page,aggr_maxitem,aggr_sub" -droptarget 
../graphtools/graph-daily-cbf-de.tcl -outformat png 


