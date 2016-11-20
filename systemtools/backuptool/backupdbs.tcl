#!/home/nico/bin/tclsh861

# deze vindt 'ie niet:
#!/usr/bin/env tclsh861

package require ndv

# set log [::ndv::CLogger::new_logger [file tail [info script]] debug]
set_log_global info {filename /home/nico/log/backupdbs.log}

proc main {argv} {
  set options {
    {user.arg "postgres" "Postgres DB user"}
    {dbs.arg "scheids;music;media" "DB's to backup"}
    {loglevel.arg "" "Set global log level"}
  }
  set usage ": [file tail [info script]] \[options]"
  set dargv [getoptions argv $options $usage]
  
  backup_dbs $dargv    
}

proc backup_dbs {dargv} {
  foreach db [split [:dbs $dargv] ";"] {
    backup_db $db [:user $dargv]
  }
}

proc backup_db {db user} {
  # set res [exec mysqldump -u $MUSER -h localhost -p$MPASS scheids | gzip -9 > $filename
  # set backup_root "/media/nas/backups/databases"
  # set backup_root "/media/nico/data3tb/backups/databases"
  set backup_root "/media/nico/Iomega HDD/backups/databases/$db"
  set filename "$backup_root/$db-[clock format [clock seconds] -format "%Y-%m-%d--%H-%M-%S"].sql"
  set res [exec pg_dump -d $db -U $user -h localhost -f $filename --blobs --clean --create]
  log info "Result: $res"
  log info "Backup file: $filename"
}

main $argv
    
