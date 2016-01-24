#!/usr/bin/env tclsh86

package require ndv

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]

proc main {argv} {
  set options {
    {user.arg "postgres" "Postgres DB user"}
    {loglevel.arg "" "Set global log level"}
  }
  set usage ": [file tail [info script]] \[options]"
  set dargv [getoptions argv $options $usage]
  
  backup_db $dargv    
}

proc backup_db {dargv} {
  set backup_root "/media/nico/Iomega HDD/backups/databases/media"
  file mkdir $backup_root
  set filename [file join $backup_root "media-[clock format [clock seconds] -format "%Y-%m-%d--%H-%M-%S"].sql"]
  set res [exec pg_dump -d media -U [:user $dargv] -h localhost -f $filename --blobs --clean --create]
  log info "Result: $res"
  log info "Backup file: $filename"
}

main $argv

    
    
