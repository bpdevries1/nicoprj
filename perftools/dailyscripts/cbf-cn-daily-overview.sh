# @pre current-dir is this script-dir
# # ../keynotetools/extraprocessing.tcl -dir /cygdrive/c/projecten/Philips/KNDL -updatemaxitem -pattern "Shop*"
# ../keynotetools/extraprocessing.tcl -dir /cygdrive/c/projecten/Philips/KNDL -actions maxitem,gt3 -pattern "Shop*"
# @todo maybe want convention thttps://secure.philips.com.sg/myphilips/landing.jsp?country=SG&language=en&catalogType=CONSUMERo combine all aggr* tables.
# ../dashboardtools/combinetables.tcl -dir c:/projecten/Philips/CBF-CN/daily -db daily.db -srcdir c:/projecten/Philips/KNDL -srcpattern "CBF-CN-*" -tables "aggr_run,aggr_page,aggr_slowitem,aggr_sub,pageitem_gt3,pageitem_topic,domain_ip_time,aggr_specific" -droptarget 
../graphtools/graph-daily-cbf-cn.tcl -outformat png -actions "" -combinedactions "all" -pattern "XX"
../graphtools/graph-daily-cbf-cn.tcl -outformat png -actions "" -combinedactions "imagelist" -pattern "XX"

