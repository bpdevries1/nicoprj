tclsh split-reportcsv.tcl %1
rem split kan meerdere bron files hebben die meerdere dirs opleveren. excel2db zou dan ook subdirs moeten doen of oplossen in deze batch met FOR.
rem derde en mss beste optie is excel2db te sourcen en proc direct aan te roepen.
tclsh ..\..\dbtools\excel2db.tcl -dir %1\<subdir>
