#!/usr/bin/env tclsh86

package require ndv

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]

proc main {argv} {
  set options {
    {user.arg "nico" "DB user"}
    {pw.arg "" "DB password"}
    {loglevel.arg "" "Set global log level"}
  }
  set usage ": [file tail [info script]] \[options]"
  set dargv [getoptions argv $options $usage]
  
  backup_db $dargv    
}

proc backup_db {dargv} {
  # set res [exec mysqldump -u $MUSER -h localhost -p$MPASS scheids | gzip -9 > $filename
  # set backup_root "/media/nas/backups/databases"
  # set backup_root "/media/nico/data3tb/backups/databases"
  set rootname "media"
  
  set backup_root "/media/nico/Iomega HDD/backups/databases/$rootname"
  file mkdir $backup_root
  set filename "$backup_root/$rootname-[clock format [clock seconds] -format "%Y-%m-%d--%H-%M-%S"].sql"
  # set res [exec mysqldump -h localhost -u [:user $dargv] -p[:pw $dargv] scheids | gzip -9 > $filename]

  set res [exec pg_dump -d $rootname -U [:user $dargv] -h localhost -f $filename --blobs --clean --create]
  log info "Result: $res"
  log info "Backup file: $filename"
}

main $argv

    
    
