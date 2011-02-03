cd /home/nico/nicoprj/systemtools/backup2nas
tclsh backup-files.tcl -t /media/nas/backups/pcubuntu -paths paths-pcubuntu.txt -r results.txt -p -ignoreregexps ignoreregexps.txt >/tmp/backuptonas.log 2>&1

# gebruik onderstaande voor backup van alle bestanden, niet alleen sinds vorige keer.
# tclsh backup-files.tcl -t /media/nas/backups/pcubuntu -paths paths-pcubuntu.txt -r results.txt -ignoreregexps ignoreregexps.txt >/tmp/backuptonas.log 2>&1

