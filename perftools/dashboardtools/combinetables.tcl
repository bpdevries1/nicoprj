#!/usr/bin/env tclsh86

# combine tables from keynotelogs.db in one (dashboard) database

# @note NOT use libpostproclogs.tcl library, separate scripts now.
# @note this one just copies/aggregates the already post-processed origin data
#       to a single DB.

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
    {dir.arg "c:/projecten/Philips/Dashboards-Shop" "Directory where target DB is (dashboards.db)"}
    {srcdir.arg "c:/projecten/Philips/KN-AN-Shop" "Source dir with Keynote API databases (keynotelogs.db)"}
    {srcpattern.arg "*" "Pattern for subdirs in srcdir to use"}
    {tables.arg "page_td2" "Tables to combine (, seperated)"}
    {newdb "Always create a new database (default is to add to current db)"}
    {droptarget "Drop target tables before (re)creating"}
    {debug "Run in debug mode, stop when an error occurs"}
  }
  set usage ": [file tail [info script]] \[options] :"
  # set dargv [::cmdline::getoptions argv $options $usage]
  set dargv [getoptions argv $options $usage]
  set dir [from_cygwin [:dir $dargv]]
  file mkdir $dir
  set db_name [file join $dir "dashboards.db"]
  if {[:newdb $dargv]} {
    set existing_db [file exists $db_name]
    if {$existing_db} {
      file rename $db_name "$db_name.[clock format [file mtime $db_name] -format "%Y-%m-%d--%H-%M"]" 
      set existing_db 0
    }
  }
  set db [dbwrapper new $db_name]
  # prepare_db $db $existing_db
  handle_srcdirroot $db [from_cygwin [:srcdir $dargv]] [:srcpattern $dargv] $dargv
  $db close
  log info "Finished updating: $db_name"
}

proc handle_srcdirroot {db srcdir srcpattern dargv} {
  set ndx 0
  foreach subdir [glob -directory $srcdir -type d $srcpattern] {
    incr ndx
    handle_srcdir $db $subdir $ndx $dargv
    # exit ; # for test
  }
}

proc handle_srcdir {db dir ndx dargv} {
  log info "handle_srcdir: $dir"
  set srcdbname [file join $dir "keynotelogs.db"]
  
  $db exec "attach database '$srcdbname' as fromDB"

  set scriptname [det_scriptname $dir]
  foreach table [:tables $dargv] {
    if {$ndx == 1} {
      if {[:droptarget $dargv]} {
        $db exec2 "drop table if exists $table" -log 
      }
      # @note try options because source table might not exist in all source databases.
      $db exec2 "create table $table as 
         select '$scriptname' scriptname, * from fromDB.$table" -log -try  
    } else {
      $db exec2 "insert into $table 
         select '$scriptname' scriptname, * from fromDB.$table" -log -try
    }
  }
  $db exec "detach fromDB"
  
  log info "handle_srcdir finished: $dir"
}

proc det_scriptname {dir} {
  file tail $dir 
}

main $argv

