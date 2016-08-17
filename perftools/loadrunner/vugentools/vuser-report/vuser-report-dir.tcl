#!/usr/bin/env tclsh861

package require ndv

set_log_global perf {showfilename 0}

# source read-vuserlogs-db.tcl
ndv::source_once vuser-report.tcl

# TODO:
# * ook level dieper kijken, dat je meteen in alle subdirs van testruns kijkt, zowel RCC, Transact, etc.
# * now expect DB in subdir, also put html reports there.
proc main {argv} {
  global argv0
  log info "$argv0 called with options: $argv"
  set options {
    {dir.arg "" "Directory with subdirs with vuserlog files and sqlite db's"}
    {all "Create all reports (full and summary)"}
    {full "Create full report"}
    {summary "Create summary report"}
    {ssl "Use SSL lines in log (not used)"}
  }
  set usage ": [file tail [info script]] \[options] :"
  set opt [getoptions argv $options $usage]

  set logdir [:dir $opt]
  # lassign $argv logdir
  log debug "logdir: $logdir"
  foreach subdir [glob -directory $logdir -type d *] {
    if {[ignore_dir $subdir]} {
      log info "Ignore dir: $subdir"
      continue
    }
    # set dbname "$subdir.db"
    # TODO: check (again) if logs are fully read into db.
    # TODO: use correct logreader (ahk and vugen for now), first only vugen
    report_dir $subdir $opt
  }
}

proc ignore_dir {dir} {
  log debug "ignore_dir called: $dir"
  if {[regexp {jmeter} $dir]} {
    return 1
  }
  # [2016-08-17 09:38:41] for now only vugen dirs.
  if {[regexp {ahk} $dir]} {
    return 1
  }
  
  return 0
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
