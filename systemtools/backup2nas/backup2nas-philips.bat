rem 21-3-2011 NdV gebruik eigen settings dir.
echo HP van Philips.

goto startnow

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

:startnow

tclsh backup-files.tcl -settingsdir "c:/users/310118637/.backup2nas/philips2nas" -t \\192.168.178.200\public\backups\PhilipsLaptop -paths paths.txt -r results.txt -p -ignoreregexps ignoreregexps-programs.txt

rem 16-1-2011 even een pauze inzetten, even kijken of het goed gaat. Evt later alleen een pauze als het fout gaat.
pause "Check results and press a key"

