#!/usr/bin/env tclsh

# Main entry point to read/report a whole dir of performance results, for different
# types of tools (eg AHK and Vugen/Loadrunner)

package require ndv

set_log_global perf {showfilename 0}
# set_log_global debug {showfilename 0}

# source read-vuserlogs-db.tcl
# ndv::source_once vuser-report.tcl

# this scripts knows the readers:
# first in global namespace:
set perftools_dir [file normalize [file join [file dirname [info script]] ..]]
# puts "perftools_dir: $perftools_dir"
ndv::source_once report-run-dir.tcl

proc main {argv} {
  global argv0 log
  log info "$argv0 called with options: $argv"
  set options {
    {rootdir.arg "" "Directory with subdirs with vuserlog files and sqlite db's"}
    {dirs.arg "" "List of subdirs (separated by :) to compare, relative to rootdir"}
    {todir.arg "" "Result/compare subdirectory, relative to rootdir"}
    {debug "set loglevel debug"}
  }
  set usage ": [file tail [info script]] \[options] :"
  set opt [getoptions argv $options $usage]

  if {[:debug $opt]} {
    $log set_log_level debug  
  }

  compare_dirs $opt
}

proc compare_dirs {opt} {
  set rootdir [:rootdir $opt]
  set todir [file join $rootdir [:todir $opt]]
  file mkdir $todir
  set db [get_compare_db [file join $todir "run-compare.db"] $opt]
  foreach dir [split [:dirs $opt] ":"] {
    copy_run_data $db [file join $rootdir $dir]
  }
  # TODO: make summary html with all results.
}

proc copy_run_data {db fromdir} {
  # attach other db.
  set fromdbname [file join $fromdir testrunlog.db]
  $db exec "attach database '$fromdbname' as fromDB"
  set table summary
  set run [file tail $fromdir]
  log info "Copying table $table"
  # TODO: fields afleiden uit tabledef van todb.
  set fields "usecase, resulttype, transshort, min_ts, resptime_min, resptime_avg, resptime_max, resptime_p95, npass, nfail"
  $db exec "insert into $table (run, $fields) select '$run' run, $fields from fromDB.$table"
  $db exec "detach database fromDB"
}

proc get_compare_db {db_name opt} {
  set existing_db [file exists $db_name]
  set db [dbwrapper new $db_name]
  define_tables_compare $db $opt
  $db create_tables 0 ; # 0: don't drop tables first. Always do create, eg for new table defs. 1: drop tables first.
  if {!$existing_db} {
    log info "New db: $db_name, create tables"
  } else {
    log info "Existing db: $db_name, don't create tables"
  }
  $db prepare_insert_statements
  $db load_percentile
  return $db
}

proc define_tables_compare {db opt} {
  # [2016-07-31 12:01] sec_ts is a representation of a timestamp in seconds since the epoch, no timezone influence.
  $db def_datatype {sec_ts resptime} real
  $db def_datatype {.*id filesize .*linenr.* trans_status iteration.*} integer
  # default is text, no need to define, just check if it's consistent
  # [2016-07-31 12:01] do want to define that everything starting with ts is a timestamp/text:
  $db def_datatype {status ts.*} text
  
  # summary table, per usecase and transaction. resptime fields already defined als real.
  $db def_datatype {npass nfail} integer
  $db add_tabledef summary {id} {run usecase resulttype transshort min_ts resptime_min resptime_avg resptime_max resptime_p95 npass nfail}
}

if {[this_is_main]} {
  main $argv
}
