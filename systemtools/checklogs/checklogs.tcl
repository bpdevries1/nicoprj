#! /home/nico/bin/tclsh

# [2016-11-03 21:02] onderstaande werkt blijkbaar niet vanuit gosleep.tcl
#! /usr/bin/env tclsh

# Check all log files in ~/log for errors. Show a popup if any found.

package require ndv

set_log_global info

use libfp
use libio

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
    set warn_msg "WARNING: check logs: [count $warnings] log file(s) with errors:\n[join $warnings "\n"]"
    log warn $warn_msg
    log warn "The warnings:"
    foreach warn $warnings {
      log warn $warn
    }
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

# TODO: possibly delete old log, if older than 90 days. But only if newer log exists.
proc check_log {opt file} {
  global warnings
  log debug "Checking log: $file"
  set treshold_size 1e6
  if {[file size $file] > $treshold_size} {
    add_warning "File > $treshold_size" $file
  }
  set treshold_age_days 90
  if {[expr [clock seconds] - [file mtime $file]] > [expr $treshold_age_days * 24 * 3600]} {
    add_warning "File is older than $treshold_age_days day" $file
  }
  check_log_contents $opt $file
}

# pre: file is not too big (>1MB) and not too old (>90 days)
# TODO: for now only generic checks, maybe add type specific checks.
set re_generic {
  {while executing}
  {invoked from within}
}

set re_log_procs {
  {/log/unison/.*\.log} check_unison_log
}
proc check_log_contents {opt file} {
  global re_generic warnings re_log_procs
  if {![file_readable $file]} {
    log debug "Cannot read file: $file"
    return 
  }
  set text [read_file $file]
  foreach re $re_generic {
    if {[regexp $re $text]} {
      # lappend warnings "'$re' found in file: $file"
      add_warning "'$re' found" $file
    }
  }
  foreach {re logproc} $re_log_procs {
    if {[regexp $re $file]} {
      $logproc $file
    }
  }
}

proc file_readable {file} {
  set readable 0
  catch {
    set f [open $file r]
    close $f
    set readable 1
  }
  return $readable
}

proc check_unison_log {file} {
  # first keep list of files that changed during sync, not really an error.
  # then with failed items, check if reason is a change, or not.
  log debug "check_unison_log: $file"
  if {![file_readable $file]} {
    log debug "Cannot read file: $file"
    return 
  }
  set changed [dict create]  
  with_file f [open $file r] {
    while {[gets $f line] >= 0} {
      if {[regexp {^\s*failed: (.+)$} $line z filename]} {
        if {[dict exists $changed "/home/nico/$filename"]} {
          log debug "failed, but changed: $filename"
        } else {
          # breakpoint
          add_warning $line $file
        }
      } elseif {[regexp {Failed: The source file (.+?)$} $line z filename]} {
        set line2 [gets $f]
        if {[regexp {has been modified during synchronization} $line2]} {
          dict set changed $filename 1
          log debug "changed: $filename"
        } else {
          log debug "Failed on file, but not a change: $line/$line2"
        }
      } elseif {[regexp {Failed:} $line]} {
        breakpoint
      }
    }
  }
}

proc add_warning {msg file} {
  global warnings
  lappend warnings "$msg; file: $file"
}

proc ignore_path {opt path} {
  set res 0
  if {[regexp {checklogs} $path]} {
    set res 1
  }
  return $res
}

main $argv


