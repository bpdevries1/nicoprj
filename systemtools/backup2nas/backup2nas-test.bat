rem tclsh ..\newpc\backup-files.tcl -t w:\backups\DellLaptop -p paths.txt -r results.txt -w
rem 13-4-2010 nu rechtstreeks de UNC naam gebruiken, want w: drive niet altijd te benaderen, terwijl UNC wel
rem beschikbaar is. Credentials zijn blijkbaar goed geregeld.
tclsh backup-files.tcl -t \\iomega-020326\public\backups\DellLaptopTest -p paths-test.txt -ignoreregexps ignoreregexps.txt -r results.txt -w




