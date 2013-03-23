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

rem tclsh backup-files.tcl -settingsdir "~/.backup2nas/laptop2nas" -t \\192.168.2.200\public\backups\YmorLaptop -paths paths.txt -r results.txt -p -ignoreregexps ignoreregexps-programs.txt
rem sinds 18-1-2012 glasvezel, met ander subnet.
rem tclsh backup-files.tcl -settingsdir "~/.backup2nas/laptop2nas" -t \\192.168.178.200\public\backups\YmorLaptop -paths paths.txt -r results.txt -p -ignoreregexps ignoreregexps-programs.txt
rem 10-2-2013 install-dir nu niet gebackupped, wel quest dingen in, sommige moeilijk te downloaden. Dus wil deze toch ook, verwijderd uit ignoreregexps-programs.txt

echo closing Outlook in 30 seconds, ctrl-c to abort...
delay 30
echo closing Outlook now
pskill outlook
delay 5
pskill outlook
delay 5
pskill outlook
delay 5
echo closed outlook (3 times), now continue with backup.
pslist outlook
echo There should be no outlook now in list above.
delay 5

tclsh backup-files.tcl -settingsdir "~/.backup2nas/laptop2nas" -t \\192.168.178.200\public\backups\YmorLaptop -paths paths.txt -r results.txt -p -ignoreregexps ignoreregexps-programs.txt

rem 16-1-2011 even een pauze inzetten, even kijken of het goed gaat. Evt later alleen een pauze als het fout gaat.
pause "Check results and press a key"

