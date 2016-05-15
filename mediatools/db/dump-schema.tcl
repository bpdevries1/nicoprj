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
  
  backup_db $dargv . music
}

proc backup_db {dargv backup_root dbname} {
  # set backup_root "."
  file mkdir $backup_root
  set filename [file join $backup_root "create-$dbname.sql"]
  set res [exec pg_dump -d $dbname -U [:user $dargv] -h localhost -f $filename --clean --create --schema-only]
  log info "Result: $res"
  log info "Schema file: $filename"
}

main $argv

    
    
