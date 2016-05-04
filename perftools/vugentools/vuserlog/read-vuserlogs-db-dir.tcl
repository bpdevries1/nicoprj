#!/usr/bin/env tclsh861

package require ndv

set_log_global info

source read-vuserlogs-db.tcl

# TODO:
# ook level dieper kijken, dat je meteen in alle subdirs van testruns kijkt, zowel RCC, Transact, etc.

proc main {argv} {
  set options {
    {dir.arg "" "Directory with vuserlog files"}
    {all "Do all subdirs, regardless of whether DB already exists"}
    {ssl "Read SSL log data, provided logs are 'always'"}
  }
  set usage ": [file tail [info script]] \[options] :"
  set dargv [getoptions argv $options $usage]

  set logdir [:dir $dargv]
  # lassign $argv logdir
  log debug "logdir: $logdir"
  set ssl [:ssl $dargv]
  foreach subdir [glob -directory $logdir -type d *] {
    set dbname "$subdir.db"
    if {![file exists $dbname] || [:all $dargv]} {
      log info "New dir: read logfiles: $subdir"
      file delete $dbname
      read_logfile_dir $subdir $dbname $ssl
    } else {
      if {[is_dir_fully_read $dbname $ssl]} {
        log debug "DB already exists, so ignore: $subdir"  
      } else {
        # not read in completely yet, possibly because of an error.
        read_logfile_dir $subdir $dbname $ssl
      }
    }
  }
}

proc is_dir_fully_read {dbname ssl} {
  set db [get_results_db $dbname $ssl]
  set res [:# [$db query "select 1 from readstatus where status='complete'"]]
  $db close
  return $res
}

if {[this_is_main]} {
  main $argv
}
