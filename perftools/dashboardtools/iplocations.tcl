#!/usr/bin/env tclsh86

# iplocations - put minimum connect times for MyPhilips/Cloudfront in one DB.
# goal: see if there is overlap, eg between BR and US.

package require tdbc::sqlite3
package require Tclx
package require ndv
package require csv

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]
# set log [::ndv::CLogger::new_logger [file tail [info script]] info]
$log set_file "[file tail [info script]].log"

proc main {argv} {
  # lassign $argv dirname
  set options {
    {dir.arg "c:/projecten/Philips/Dashboards-MyPhilips" "Directory where target DB is (dashboards.db)"}
    {srcdir.arg "c:/projecten/Philips/KN-AN-MyPhilips" "Source dir with Keynote API databases (keynotelogs.db)"}
    {srcpattern.arg "*" "Pattern for subdirs in srcdir to use"}
    {debug "Run in debug mode, stop when an error occurs"}
  }
  set usage ": [file tail [info script]] \[options] :"
  # set dargv [::cmdline::getoptions argv $options $usage]
  set dargv [getoptions argv $options $usage]
  set dir [from_cygwin [:dir $dargv]]
  file mkdir $dir
  set db_name [file join $dir "iplocations.db"]
  set existing_db [file exists $db_name]
  if {$existing_db} {
    file rename $db_name "$db_name.[clock format [file mtime $db_name] -format "%Y-%m-%d--%H-%M"]" 
    set existing_db 0
  }
  set db [dbwrapper new $db_name]
  prepare_db $db $existing_db
  handle_srcdirroot $db [from_cygwin [:srcdir $dargv]] [:srcpattern $dargv]
  $db close
  log info "Finished updating: $db_name"
}

proc prepare_db {db existing_db} {
  $db add_tabledef locmintime {} {scriptname scriptloc ip_address topdomain {number integer} {min_msec integer}}
  if {!$existing_db} {
    log info "Create tables"
    $db create_tables 0 ; # 0: don't drop tables first.
    create_indexes $db
  } else {
    log info "Existing DB, don't create tables"
    # existing db, assuming tables/indexes also already exist. 
  }
  # $db prepare_insert_statements
  # $db exec "delete from stat where source in ('API', 'APIuser', 'check')"
}

proc create_indexes {db} {
  $db exec_try "create index ix_1 on locmintime (ip_address)"
} 

proc handle_srcdirroot {db srcdir srcpattern} {
  foreach subdir [glob -directory $srcdir -type d $srcpattern] {
    handle_srcdir $db $subdir
    # exit ; # for test
  }
}

proc handle_srcdir {db dir} {
  log info "handle_srcdir: $dir"
  set srcdbname [file join $dir "keynotelogs.db"]
  
  $db exec "attach database '$srcdbname' as fromDB"

  $db exec2 "insert into locmintime (scriptname, scriptloc, ip_address, topdomain, number, min_msec)
             select '[file tail $dir]', '[det_location $dir]', ip_address, topdomain, count(*), min(1*connect_delta)
             from fromDB.pageitem
             where topdomain = 'cloudfront.net'
             and 1*connect_delta > 0
             group by 1,2,3,4" -log
  
  $db exec "detach fromDB"
  
  log info "handle_srcdir finished: $dir"
}

set locations [dict create CN Beijing BR "Sao Paulo" DE Berlin FR Paris RU Moscow UK London US "New York"]
proc det_location {dir} {
  global locations
  if {[regexp -- {-([A-Z]+)$} $dir z country]} {
    dict get $locations $country 
  } else {
    error "Could not determine country from $dir" 
  }
}

main $argv

