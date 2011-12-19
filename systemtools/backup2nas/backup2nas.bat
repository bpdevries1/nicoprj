rem tclsh ..\newpc\backup-files.tcl -t w:\backups\DellLaptop -p paths.txt -r results.txt -w
rem 13-4-2010 nu rechtstreeks de UNC naam gebruiken, want w: drive niet altijd te benaderen, terwijl UNC wel
rem beschikbaar is. Credentials zijn blijkbaar goed geregeld.
rem tclsh backup-files.tcl -t \\iomega-020326\public\backups\DellLaptop -paths paths.txt -r results.txt -p -ignoreregexps ignoreregexps.txt -use4nt

rem 1-11-2010 nu zonder 4NT.
rem tclsh backup-files.tcl -t \\iomega-020326\public\backups\DellLaptop -paths paths.txt -r results.txt -p -ignoreregexps ignoreregexps.txt

rem 16-1-2011 iomega-020326 werkt niet, 192.168.2.200 werkt wel, is wat vaag.
rem tclsh backup-files.tcl -t \\192.168.2.200\public\backups\DellLaptop -paths paths.txt -r results.txt -p -ignoreregexps ignoreregexps.txt

rem 21-3-2011 NdV gebruik eigen settings dir.
echo deze ook aanpassen, HP van Ymor.

tclsh backup-files.tcl -settingsdir "~/.backup2nas/laptop2nas" -t \\192.168.2.200\public\backups\YmorLaptop -paths paths.txt -r results.txt -p -ignoreregexps ignoreregexps-programs.txt

rem 16-1-2011 even een pauze inzetten, even kijken of het goed gaat. Evt later alleen een pauze als het fout gaat.
pause "Check results and press a key"

