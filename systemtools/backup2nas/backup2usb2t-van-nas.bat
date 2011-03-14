rem eerste keer bestaat de backupdatetime-usb2t.txt nog niet, dus wordt alles gedaan.

rem ignoreregexps-programs.txt: hier staan c:\progs etc in, zodat deze niet gebackupped worden, deze door de week gebruiken.
rem maar dan wel weer naar NAS.
rem f:\backups\OrdinaHPLaptop nog vervangen door NAS.
tclsh backup-files.tcl -t f:\backups\nas -b backupdatetime-usb2t-van-nas.txt -paths paths-nas.txt -p -ignoreregexps ignoreregexps.txt

pause "Check results and press a key"

