# ./nanny.tcl tclsh ./scatter2db.tcl -nopost -moveread -continuous
# ./nanny.tcl tclsh ./scatter2db.tcl -nopost -moveread -continuous -updatedaily -updatemaxitem
# ./nanny.tcl tclsh ./scatter2db.tcl -nopost -moveread -continuous -updatedaily

# 1-11-2013 nu even zonder -updatedaily, staat in de steigers.
# ./nanny.tcl tclsh ./scatter2db.tcl -nopost -moveread -continuous -actions dailystats,gt3,maxitem,analyze
# ./nanny.tcl tclsh ./scatter2db.tcl -nopost -moveread -continuous -actions dailystats,gt3,aggrsub,maxitem,slowitem,topic,domain_ip,analyze
./nanny.tcl tclsh ./scatter2db.tcl -nopost -moveread -continuous -actions dailystats,gt3,aggrsub,maxitem,slowitem,topic,domain_ip,aggr_specific,analyze
# ./nanny.tcl tclsh ./scatter2db.tcl -nopost -moveread -continuous

