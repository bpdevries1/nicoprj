rem backup2nas.bat - backup c en d drive to external network harddisk.
rem 19-1-08: nu met check dat alleen max 1 week oud wordt gekopieerd, rest al eerder gedaan.
rem 19-1-08: nu zonder drive letter, wel eerst net use, om connectie te maken.

rem set TARGET_DRIVE=W:
rem set TARGET_DRIVE=Y:
rem set TARGET_ROOT=%TARGET_DRIVE%\backups\DellPC
set TARGET_ROOT=\\Iomega-020326\public\backups\DellLaptop

rem details van te voren verwijderen, wordt erg groot (als het goed gaat).
del backupdetails.log
logregel start backup >>backupdetails.log

rem net use %TARGET_DRIVE% /d >>& backupdetails.log
rem 12-1-08: onderstaande werkt blijkbaar zonder opgeven van user/password: is gelijk aan windows gegevens.

rem net use %TARGET_DRIVE% \\Iomega-020326\public >>& backupdetails.log
net use \\Iomega-020326\public >>& backupdetails.log

logregel net use gedaan, starting backup >>backup2nas.log

set TARGET_DIR=%TARGET_ROOT%\c-drive
mkdir /S %TARGET_DIR%
echo R | copy /A: /S /U /V /[d-7]	c:\*.* %TARGET_DIR% >>& backupdetails.log

set TARGET_DIR=%TARGET_ROOT%\d-drive
mkdir /S %TARGET_DIR%
echo R | copy /A: /S /U /V /[d-7]	d:\*.* %TARGET_DIR% >>& backupdetails.log

logregel backup klaar >>backup2nas.log
logregel backup klaar >>backupdetails.log

rem einde
