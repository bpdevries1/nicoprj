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
    {dir.arg "c:/projecten/Philips/Shop-KN-longterm" "Directory with source files"}
  }
  set usage ": [file tail [info script]] \[options] :"
  # set dargv [::cmdline::getoptions argv $options $usage]
  set dargv [getoptions argv $options $usage]
  set dir [from_cygwin [:dir $dargv]]
  file mkdir $dir
  set db_name [file join $dir "history.db"]
  set db [dbwrapper new $db_name]
  prepare_db $db 
  $db in_trans {
    read_total $db $dargv
    read_pages $db $dargv
  }
  $db close
  log info "Finished: $db_name"
}

proc prepare_db {db} {
  # $db add_tabledef logfile {id} {path filename}
  $db add_tabledef runstat {id} {logfile_id country date target_id {run_sec real} {number integer} {avail real} alias}
  $db add_tabledef pagestat {id} {logfile_id country date target_id {page_seq integer} {page_sec real} {number integer} {avail real} alias}
  $db create_tables 1
  $db prepare_insert_statements
#TIME	TARGET_ID	Performance	COUNT	AVAIL%	ALIAS
#2013-APR-17	1376285	21.578	51	100	Shop Browsing Flow DE (SensoTouch3D) (TxP)[IE]-Total Time (s  
}

proc read_total {db dargv} {
  set filename [lindex [glob -directory [:dir $dargv] "*total*"] 0]
  log info "Read total from: $filename"
  set f [open $filename r]
  gets $f header
  while {![eof $f]} {
    gets $f line
    if {[string trim $line] == ""} {
      continue 
    }
    set alias [lassign $line dt target_id run_sec number av]
    set date [det_date $dt]
    set avail [det_avail $av]
    set country [det_country $alias]
    $db insert runstat [dict create country $country date $date target_id $target_id \
      run_sec $run_sec number $number avail $avail alias $alias]
  }
  close $f
}

proc det_date {dt} {
  clock format [clock scan $dt -format "%Y-%b-%d"] -format "%Y-%m-%d"
}

proc det_avail {av} {
  if {[string is double $av]} {
    expr 0.01 * $av 
  } else {
    return 0.0 
  }
}

proc det_country {alias} {
  if {[regexp {Flow ([A-Z][A-Z]) } $alias z country]} {
    return $country 
  } else {
    error "Could not determine country from: $alias" 
  }
}

proc read_pages {db dargv} {
  log info "TODO" 
  foreach filename [glob -directory [:dir $dargv] *allpages*] {
    read_pages_country $db $dargv $filename 
  }
}

# TIME	TARGET_ID	Performance	COUNT	AVAIL%	ALIAS
# 2013-APR-17	1376286	3.008	49	100	Shop Browsing Flow FR (SensoTouch3D) (TxP)[IE]- Philips Fran
proc read_pages_country {db dargv filename} {
  set f [open $filename r]
  gets $f header
  set prev_date "9999-12-31"
  set page_seq 0
  while {![eof $f]} {
    gets $f line
    if {[string trim $line] == ""} {
      continue 
    }
    set alias [lassign $line dt target_id page_sec number av]
    set date [det_date $dt]
    if {$date < $prev_date} {
      incr page_seq
      log info "Set page_seq to: $page_seq"
    }
    set avail [det_avail $av]
    set country [det_country $alias]
    $db insert pagestat [dict create country $country date $date target_id $target_id \
      page_seq $page_seq page_sec $page_sec number $number avail $avail alias $alias]
    set prev_date $date
  }
  close $f
}

main $argv

