rem eerste keer bestaat de backupdatetime-usb2t.txt nog niet, dus wordt alles gedaan.

rem ignoreregexps-programs.txt: hier staan c:\progs etc in, zodat deze niet gebackupped worden, deze door de week gebruiken.
rem maar dan wel weer naar NAS.
rem tclsh backup-files.tcl -t f:\backups\OrdinaHPLaptop -b backupdatetime-usb2t.txt -paths paths.txt -r results.txt -p -ignoreregexps ignoreregexps-programs.txt
tclsh backup-files.tcl -settingsdir "~/.backup2nas/laptop2usb2t" -t e:\backups\YmorHPLaptop -paths paths.txt -r results.txt -p -ignoreregexps ignoreregexps-programs.txt
pause "Check results and press a key"

