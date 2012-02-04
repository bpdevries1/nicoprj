#!/bin/sh

cd /home/nico/nicoprj/systemtools/backup2nas
# met onderstaande ndv niet gevonden
# tclsh backup-files.tcl -t /media/nas/backups/pcubuntu -paths paths-pcubuntu.txt -r results.txt -p -ignoreregexps ignoreregexps.txt >/tmp/backuptonas.log 2>&1

# met onderstaande wel gevonden
# ./backup-files.tcl -t /media/nas/backups/pcubuntu -paths paths-pcubuntu.txt -r results.txt -p -ignoreregexps ignoreregexps.txt >/tmp/backuptonas.log 2>&1
# ./backup-files.tcl -t /media/nas/backups/pcubuntu -paths paths.txt -r results.txt -p -ignoreregexps ignoreregexps.txt >/tmp/backuptonas.log 2>&1

# 18-1-2012 nu glasvezel, maakt voor deze niet uit, wil log in ~/log hebben.
./backup-files.tcl -t /media/nas/backups/pcubuntu -paths paths.txt -r results.txt -p -ignoreregexps ignoreregexps.txt >/home/nico/log/backuptonas.log 2>&1

# gebruik onderstaande voor backup van alle bestanden, niet alleen sinds vorige keer.
# tclsh backup-files.tcl -t /media/nas/backups/pcubuntu -paths paths-pcubuntu.txt -r results.txt -ignoreregexps ignoreregexps.txt >/tmp/backuptonas.log 2>&1

