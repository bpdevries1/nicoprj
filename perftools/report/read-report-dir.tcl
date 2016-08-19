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
set reader_namespaces [list]
set perftools_dir [file normalize [file join [file dirname [info script]] ..]]
# puts "perftools_dir: $perftools_dir"
ndv::source_once report-run-dir.tcl

lappend reader_namespaces [source [file join $perftools_dir autohotkey \
                                       ahklog read-ahklogs-db.tcl]]
lappend reader_namespaces [source [file join $perftools_dir loadrunner \
                                       vuserlog read-vuserlogs-db.tcl]]

# TODO:
# * ook level dieper kijken, dat je meteen in alle subdirs van testruns kijkt, zowel RCC, Transact, etc.
# * now expect DB in subdir, also put html reports there.
proc main {argv} {
  global argv0 log
  log info "$argv0 called with options: $argv"
  set options {
    {dir.arg "" "Directory with subdirs with vuserlog files and sqlite db's"}
    {all "Create all reports (full and summary)"}
    {full "Create full report"}
    {summary "Create summary report"}
    {ssl "Use SSL lines in log (not used)"}
    {debug "set loglevel debug"}
  }
  set usage ": [file tail [info script]] \[options] :"
  set opt [getoptions argv $options $usage]

  if {[:debug $opt]} {
    $log set_log_level debug  
  }
  
  set logdir [:dir $opt]
  # lassign $argv logdir
  log debug "logdir: $logdir"
  foreach subdir [glob -nocomplain -directory $logdir -type d *] {
    if {[ignore_dir $subdir]} {
      log info "Ignore dir: $subdir"
      continue
    }
    # set dbname "$subdir.db"
    # TODO: check (again) if logs are fully read into db.
    # TODO: use correct logreader (ahk and vugen for now), first only vugen
    read_report_run_dir $subdir $opt
  }
  # also handle root dir, could be just 1 dir
  read_report_run_dir $logdir $opt
}

proc ignore_dir {dir} {
  set dir [file normalize $dir]
  log debug "ignore_dir called: $dir"
  if {[regexp {jmeter} $dir]} {
    return 1
  }
  # [2016-08-17 09:38:41] for now only vugen dirs.
  # [2016-08-19 11:57] both vugen and ahk should work now.
  if {[regexp {ahk} $dir]} {
    return 0
  }
  # [2016-08-19 14:14] for now only ahk.
  if {[regexp {vugen} $dir]} {
    return 0
  }
  if {[regexp {run} $dir]} {
    return 0
  }
  
  return 0
}

# read logs from a single run (ahk/vugen/both) into one DB.
proc read_report_run_dir {rundir opt} {
  set dbname [file join $rundir testrunlog.db]
  if {![file exists $dbname]} {
    log info "New dir: read logfiles: $rundir"
    # file delete $dbname
    # read_logfile_dir $dir $dbname 0 split_transname
    read_run_dir $rundir $dbname $opt
  } else {
    log debug "Already read: $rundir -> $dbname"
  }
  report_run_dir $rundir $dbname $opt; # in ./report-run-dir.tcl
}

proc read_run_dir {rundir dbname opt} {
  # TODO: check if dir already read.
  set db [get_run_db $dbname $opt]
  add_read_status $db "starting"
  set nread 0;      # number of actually read files.
  set nhandled 0;   # All files, for handling with progress calculator
  set logfiles [glob -nocomplain -directory $rundir -type f *]
  set pg [CProgressCalculator::new_instance]
  $pg set_items_total [:# $logfiles]
  $pg start
  foreach filename $logfiles {
    incr nread [read_run_logfile $filename $db $opt]
    incr nhandled
    $pg at_item $nhandled
  }
  add_read_status $db "complete"
  log info "set read_status, closing DB"
  $db close
  log info "closed DB"
  log info "Read $nread logfile(s) in $rundir"
}

proc read_run_logfile {filename db opt} {
  global reader_namespaces
  set nread 0
  foreach ns $reader_namespaces {
    if {[${ns}::can_read? $filename]} {
      log debug "Reading $filename with ns: $ns"
      ${ns}::read_run_logfile $filename $db
      set nread 1
      break
    }
  }
  if {$nread == 0} {
    log debug "Could not read (no ns): $filename"
  }
  return $nread
}

proc add_read_status {db status} {
  $db insert read_status [dict create ts [now] status $status]
}


# TODO: use this proc again.
proc is_dir_fully_read {dbname ssl} {
  set db [get_results_db $dbname $ssl]
  set res [:# [$db query "select 1 from read_status where status='complete'"]]
  $db close
  return $res
}

if {[this_is_main]} {
  main $argv
}
