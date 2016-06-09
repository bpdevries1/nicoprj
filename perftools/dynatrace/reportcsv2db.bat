rem param 1: input csv dir.
rem param 2: nothing, could be config_tcl.
tclsh reportcsv2csv.tcl %1
tclsh ..\logtools\excel2db\excel2db.tcl %1 %2

