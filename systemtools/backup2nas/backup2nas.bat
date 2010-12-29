rem tclsh ..\newpc\backup-files.tcl -t w:\backups\DellLaptop -p paths.txt -r results.txt -w
rem 13-4-2010 nu rechtstreeks de UNC naam gebruiken, want w: drive niet altijd te benaderen, terwijl UNC wel
rem beschikbaar is. Credentials zijn blijkbaar goed geregeld.
rem tclsh backup-files.tcl -t \\iomega-020326\public\backups\DellLaptop -paths paths.txt -r results.txt -p -ignoreregexps ignoreregexps.txt -use4nt

rem 1-11-2010 nu zonder 4NT.
tclsh backup-files.tcl -t \\iomega-020326\public\backups\DellLaptop -paths paths.txt -r results.txt -p -ignoreregexps ignoreregexps.txt

