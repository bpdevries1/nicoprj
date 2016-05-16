echo testje >c:\testje-ndv.txt
rem tclsh get-analyse-logs.tcl %1 %2 %3 %4 %5 %6 %7 %8 %9
tclsh get-analyse-logs.tcl -ts1 "2011-03-23 14:28:00" -ts2 "2011-03-23 14:38:00" -sla -name test267
pause


