#!/usr/bin/env tclsh86

package require Tclx
package require ndv
package require fileutil
package require textutil

set log [::ndv::CLogger::new_logger [file tail [info script]] info]
$log set_file "[file tail [info script]].log"

proc main {argv} {
  log debug "argv: $argv"
  set options {
    {dir.arg "~/Ymor/Philips/Shop/dbconns" "Dir with logs"}
    {loglevel.arg "info" "Log level (debug, info, warn)"}
  }
  set usage ": [file tail [info script]] \[options] :"
  # set dargv [::cmdline::getoptions argv $options $usage]
  set dargv [getoptions argv $options $usage]
  log set_log_level [:loglevel $dargv]
  readlogs $dargv
}

proc readlogs {dargv} {
  set dir [:dir $dargv] 
  set dbname [file join $dir "dbcon.db"]
  set db [dbwrapper new $dbname]
  prepare_db $db
  $db in_trans {
    foreach dirname [glob -directory $dir -type d *] {
      readdir $db $dirname 
    }
  }
}

proc readdir {db dirname} {
  set ts_cet [det_ts_cet $dirname]
  set filename [file join $dirname STATUS.csv] 
  set f [open $filename r]
  set prev_machine "<none>"
  set linenr 0
  set curr_total 0
  while {![eof $f]} {
    gets $f line
    incr linenr
    set l [split $line "|"]
    if {[llength $l] == 3} {
      lassign $l machine username number
      if {$machine != $prev_machine} {
        set curr_total 0 
      }
      if {$machine == ""} {
        set machine "<total>"
        set username "<total>"
      }
      if {$username == ""} {
        if {$machine != $prev_machine} {
          # first one, empty user
          set username "<empty>"
          incr curr_total $number
        } else {
          if {$number == $curr_total} {
            set username "<total>" 
          } else {
            set username "<unknown>" 
          }
        }
      } else {
        incr curr_total $number 
      }
      # {filename ts_cet linenr machine username number}
      set machinegroup [det_machinegroup $machine]
      $db insert dbcon [dict create filename $filename ts_cet $ts_cet \
        linenr $linenr machine $machine machinegroup $machinegroup username $username number $number]
    }
    set prev_machine $machine
  }
  close $f
}

proc prepare_db {db} {
  $db add_tabledef dbcon {id} {filename ts_cet {linenr integer} machine machinegroup username {number integer}}
  $db create_tables 1
  $db prepare_insert_statements  
}

proc det_ts_cet {dirname} {
  if {[regexp {QUERIE-(.+)$} [file tail $dirname] z str_time]} {
    # QUERIE-21102013_15-58
    clock format [clock scan $str_time -format "%d%m%Y_%H-%M"] -format "%Y-%m-%d %H:%M:%S"  
  } else {
    error "Cannot determine ts_cet from dirname: $dirname" 
  }
}

proc det_machinegroup {machine} {
  if {[regexp {^p4c} $machine]} {
    return p4c 
  } elseif {[regexp -- {-app\d\d} $machine]} {
    return appserver 
  } elseif {[regexp -- {-db\d\d} $machine]} {
    return db 
  } else {
    return misc 
  }
}

main $argv
