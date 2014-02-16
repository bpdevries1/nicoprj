#!/usr/bin/env tclsh86

# check-errors.tcl - Check if download, scatter2db and graph logfiles have errors/warnings.

package require ndv

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]
$log set_file "[file tail [info script]].log"

proc main {argv} {
  log debug "argv: $argv"
  set options {
    {prjdir.arg "c:/projecten/Philips" "Project directory"}
    {tooldir.arg "c:/nico/nicoprj/perftools/keynotetools" "Tool directory"}
    {test "Test the script"}       
  }
  set usage ": [file tail [info script]] \[options] :"
  # set dargv [::cmdline::getoptions argv $options $usage]
  set dargv [getoptions argv $options $usage]
  check_errors $dargv
}

proc check_errors {dargv} {
  foreach logname {zip-move.tcl*.log download-scatter.tcl*.log nanny2.tcl*.log scatter2db.tcl*.log} {
    check_logs [:tooldir $dargv] $logname
  }
  foreach subdir [glob -directory [file join [:prjdir $dargv] KNDL] -type d *] {
    check_logs $subdir "R-output*.txt"
  }
  foreach subdir [glob -directory [:prjdir $dargv] -type d *] {
    set dailydir [file join $subdir daily]
    if {[file exists $dailydir]} {
      check_logs $dailydir "R-output*.txt"
    }
  }
}

proc check_logs {dir logname_glob} {
  foreach filename [glob -directory $dir -nocomplain -type f $logname_glob] {
    # set filename [file join $tooldir $logname]
    if {![file exists $filename]} {
      log warn "$filename does not exist"
      return
    }
    # log debug "Checking: $filename"
    foreach level {error warn} {
      # set res [exec grep -i \"\[$level\]\" $filename]
      # set cmd [list echo "\"\[$level\\\]\"" $filename]
      set cmd [list grep $level $filename]
      # log debug "cmd: $cmd"
      # set res [exec echo "\"\[$level\\\]\"" $filename]
      try_eval {
        set res ""
        set res [exec -ignorestderr {*}$cmd]
      } {
        # log warn "Exec grep failed: $errorResult"
        # probably nothing found.
      }
      if {[string length $res] > 0} {
        log warn "${level}s found in $filename: $res"
      }
    }
  }
}

main $argv