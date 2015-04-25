#!/bin/sh

cd /home/nico/nicoprj/systemtools/backup2nas
# met onderstaande ndv niet gevonden
# tclsh backup-files.tcl -t /media/nas/backups/pcubuntu -paths paths-pcubuntu.txt -r results.txt -p -ignoreregexps ignoreregexps.txt >/tmp/backuptonas.log 2>&1

# met onderstaande wel gevonden
# ./backup-files.tcl -t /media/nas/backups/pcubuntu -paths paths-pcubuntu.txt -r results.txt -p -ignoreregexps ignoreregexps.txt >/tmp/backuptonas.log 2>&1
# ./backup-files.tcl -t /media/nas/backups/pcubuntu -paths paths.txt -r results.txt -p -ignoreregexps ignoreregexps.txt >/tmp/backuptonas.log 2>&1

# 18-1-2012 nu glasvezel, maakt voor deze niet uit, wil log in ~/log hebben.
# ./backup-files.tcl -t /media/nas/backups/pcubuntu -paths paths.txt -r results.txt -p -ignoreregexps ignoreregexps.txt >/home/nico/log/backuptonas.log 2>&1

# 2014-12-13 nu naar nieuwe 3TB interne schijf
# deze alles van /home/nico naar (nieuwe 2014) data3tb
# Mail staat in ~/.thunderbird/Mail/Local Folders/Beachvolley.sbd:

# TODO nog andere met bv dingen uit /etc, zoals mtab.
# ./backup-files.tcl -t /media/nico/data3tb/backups/pcubuntu -paths paths.txt -r results.txt -p -ignoreregexps ignoreregexps.txt >/home/nico/log/backuptonas.log 2>&1
/home/nico/bin/unison -auto -batch homenico2data3tb >/dev/null 2>&1


# gebruik onderstaande voor backup van alle bestanden, niet alleen sinds vorige keer, dus zonder -p
# tclsh backup-files.tcl -t /media/nas/backups/pcubuntu -paths paths-pcubuntu.txt -r results.txt -ignoreregexps ignoreregexps.txt >/tmp/backuptonas.log 2>&1

# 05-06-2014 nu ook van NAS naar usb2tb (al eens eenmalig gedaan).
# in zelfde configdir, maar de files starten met 'nas-'
# deze was gemakkelijk qua keuze, omdat er al een backup stond.
# Music staat hier ook grotendeels is, dus dan toch een backup.

# [2015-03-24 Tue 21:00] Nu met Unison doen, dan ook voordeel dat backup niet groter wordt dan origin.
# ./backup-files.tcl -t "/media/nico/Iomega HDD/backups/nas" -paths nas-paths.txt -r nas-results.txt -b nas-backupdatetime.txt -p -ignoreregexps ignoreregexps.txt >/home/nico/log/nas-backuptonas.log 2>&1
/home/nico/bin/unison -auto -batch nas2iomega2tb >/dev/null 2>&1


# 05-06-2014 en ook nog wat van /media/nico/Iomega HDD backuppen (archief)
# [2014-06-05 23:39:21] init-run nog bezig, maar best ver al, idd ruim 300.000 files.
# ./backup-files.tcl -t /home/nico/backups/usb2tb -paths usb2tb-paths.txt -r usb2tb-results.txt -b usb2tb-backupdatetime.txt -p -ignoreregexps ignoreregexps.txt >/home/nico/log/usb2tb-backuptonas.log 2>&1
/home/nico/bin/unison -auto -batch iomega2homenico >/dev/null 2>&1

# TODO 29-3-2015 Nu dus alle met Unison, behalve laptop. Laptop mogelijk ook initieren vanuit PC.
# en daarna via profiles checken wat je nog mist in de sync: dingen als /etc en /opt, maar ook /home/<anders-dan-nico>.
