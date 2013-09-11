#!/usr/bin/env tclsh86

# check-progress.tcl - check how much of the 6w period is downloaded.

package require tdbc::sqlite3
package require Tclx
package require ndv
package require json

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]
$log set_file "[file tail [info script]].log"

proc main {argv} {
  global dct_argv
  log debug "argv: $argv"
  set options {
    {dir.arg "c:/projecten/Philips/KNDL" "Directory where downloaded keynote files are (in subdirs)"}
    {continuous "Keep running this script, to check progress once in a while"}
    {debug "Run in debug mode, stop when an error occurs"}
  }
  set usage ": [file tail [info script]] \[options] :"
  set dct_argv [::cmdline::getoptions argv $options $usage]

  if {[:continuous $dct_argv]} {
    log info "Running continuously"
    while {1} {
      set res [checkprogress_main $dct_argv]
      log info "CheckProgress main finished with return code: $res"
      wait_until_next_hour_and_half
    }
  } else {
    log info "Running only once"
    set res [checkprogress_main $dct_argv]
    log info "CheckProgress main finished with return code: $res"
  }
}

# wait eg at 17.40 until it's 18.30, and at 17.25 until it's 17.30
# reason is to not start at the same time with the next download-scatter run.
# @note if you want to run at x:45, add 900 (!) to clock seconds: adding 15 minutes to x:45 results in (x+1):00
proc wait_until_next_hour_and_half {} {
  set finished 0
  set start_hour [clock format [expr [clock seconds] + 1800] -format "%H"]
  while {!$finished} {
    set hour [clock format [expr [clock seconds] + 1800] -format "%H"]
    log info "Time: [clock format [clock seconds]]"
    if {$hour != $start_hour} {
      log info "Finished waiting, starting the next batch of reading the downloads"
      set finished 1 
    } else {
      log info "Wait another 5 minutes, until hour != $start_hour" 
    }
    after 300000
    # after 5000
  }
}

proc checkprogress_main {dct_argv} {
  set root_dir [from_cygwin [:dir $dct_argv]]  
  set nexpected [expr 6*7*24]
  set ntotal 0
  set nexpected_total 0
  foreach subdir [lsort [glob -nocomplain -directory $root_dir -type d *]] {
    if {[ignore_subdir $subdir]} {
      log info "Ignore subdir: $subdir (for test!)"
    } else {
      incr ntotal [check_progress_subdir $dct_argv $subdir $nexpected]
      incr nexpected_total $nexpected
    }
  }
  log_stats "All" $ntotal $nexpected_total
  
  # 6-9-2013 also handle current-dir, if script is called with one subdir as param
  set res [check_progress_subdir $dct_argv $root_dir $nexpected]
  
  return $res
}

proc ignore_subdir {subdir} {
  return 0 ; # in production don't ignore anything!
  if {[regexp -nocase {Mobile-landing} $subdir]} {
    return 1 
  }
  if {[regexp -nocase {MyPhilips} $subdir]} {
    return 1 
  }
  return 0
}

# return number of files less than 6w old in subdir
proc check_progress_subdir {dct_argv subdir nexpected} {
  set checkdate [expr [clock seconds] - (6*7*24*3600)]
  set nfound 0
  #log debug "start glob"
  set lst [glob -nocomplain -tails -directory $subdir *.json]
  #log debug "end glob, now loop list"
  foreach filename $lst {
    #if {[file mtime $filename] >= $checkdate} {
    #  incr nfound 
    #}
    if {[regexp -- {-(\d{4}-\d{2}-\d{2}--\d{2}-\d{2}).json$} $filename z dt]} {
      if {[clock scan $dt -format "%Y-%m-%d--%H-%M"] >= $checkdate} {
        incr nfound 
      }
    }
    
  }
  #log debug "end loop list"
  log_stats [file tail $subdir] $nfound $nexpected
  return $nfound
}

proc log_stats {item nfound nexpected} {
  puts [format "%6d/%6d: %3.2f%% - %s" $nfound $nexpected [expr 100.0 * $nfound / $nexpected] $item]  
}

main $argv

