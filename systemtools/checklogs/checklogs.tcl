#! /home/nico/bin/tclsh

# [2016-11-03 21:02] onderstaande werkt blijkbaar niet vanuit gosleep.tcl
#! /usr/bin/env tclsh

# Check all log files in ~/log for errors. Show a popup if any found.

package require ndv

set_log_global debug

use libfp

proc main {argv} {
  global log
  set options {
    {root.arg "~/log" "Root of files to test"}
    {coe "Continue on error"}
    {nopopup "Don't show Tk popup when an error is found."}
    {debug "Set loglevel to debug"}
  }
  set usage ": [file tail [info script]] \[options]:"
  set opt [getoptions argv $options $usage]
  if {[:debug $opt]} {
    $log set_log_level debug
  }
  check_all_logs $opt
}

proc check_all_logs {opt} {
  global warnings
  set warnings [list]
  check_all_logs_dir $opt [file normalize [:root $opt]]
  if {[count $warnings] > 0} {
    set warn_msg "WARNING: check logs: [count $warnings] log files with errors:\n[join $warnings "\n"]"
    log warn $warn_msg
    if {![:nopopup $opt]} {
      popup_warning $warn_msg
    }
  } else {
    log info "Everything ok!"
  }
  exit;                         # to quit from Tk.
}

proc check_all_logs_dir {opt dir} {
  set files [only_latest_files [glob -nocomplain -directory $dir -type f *.log]]
  foreach file $files {
    if {![ignore_path $opt $file]} {
      check_log $opt $file
    }
  }

  foreach subdir [glob -nocomplain -directory $dir -type d *] {
    check_all_logs_dir $opt $subdir
  }
}

# if 2 (or more) logs exist which only vary in timestamp, then only return the latest.
proc only_latest_files {lst_files} {
  set res [list]
  set old_basename ""
  foreach file [lsort -decreasing $lst_files] {
    set basename [det_basename $file]
    if {$basename != $old_basename} {
      lappend res $file
      set old_basename $basename
      log trace "Latest file: $file"
    } else {
      log trace "Have newer file for: $file"
    }
  }
  return $res
}

# music-monitor.tcl-2016-11-16--07-53-49.log
# => music-monitor.tcl-
proc det_basename {file} {
  set tail [file tail $file]
  if {[regexp {(.+)\d{4}-\d\d-\d\d--\d\d-\d\d-\d\d} $tail z base]} {
    return $base
  } else {
    return $tail
  }
}

proc check_log {opt file} {
  global warnings
  log debug "Checking log: $file"
  set treshold 1e6
  if {[file size $file] > $treshold} {
    lappend warnings "File > $treshold: $file"
  }
}

proc ignore_path {opt path} {
  set res 0
  return $res
}

main $argv


