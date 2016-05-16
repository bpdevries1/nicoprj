#!/usr/bin/env tclsh86

# extraprocessing.tcl
# goal: post processing for selected databases.
# for now update_maxitem

package require tdbc::sqlite3
package require Tclx
package require ndv
package require json

set log [::ndv::CLogger::new_logger [file tail [info script]] info]
$log set_file "[file tail [info script]].log"

# libpostproclogs: set_task_succeed (and maybe others)
# set script_dir [file dirname [info script]]
#source [file join $script_dir libpostproclogs.tcl]
#source [file join $script_dir libmigrations.tcl]
#source [file join $script_dir kn-migrations.tcl]
#source [file join $script_dir checkrun-handler.tcl]
#source [file join $script_dir dailystats.tcl]
# source [file join $script_dir libdaily.tcl]
ndv::source_once kn-migrations.tcl libextraprocessing.tcl libextra.tcl

proc main {argv} {
  global dargv
  log debug "argv: $argv"
  set options {
    {dir.arg "c:/projecten/Philips/KNDL" "Directory where downloaded keynote files are (in subdirs) and where DB's (in subdirs) will be created."}
    {justdir "Just read this directory, not subdirectories. If this is set, dir should not contain subdirs besides 'read'"}
    {actions.arg "all" "List of actions to do (comma separated: dailystats,gt3,maxitem,slowitem,topic,aggr_specific,domain_ip,removeold,combinereport,analyze,vacuum)"}
    {maxitem.arg "20" "Number of maxitems to determine"}
    {minsec.arg "0.2" "Only put items > minsec in slowitem table"}
    {pattern.arg "*" "Just handle subdirs that have pattern"}
    {loglevel.arg "info" "Log level (debug, info, warn)"}
    {debug "Run in debug mode, stop when an error occurs"}
  }
  set usage ": [file tail [info script]] \[options] :"
  # set dargv [::cmdline::getoptions argv $options $usage]
  set dargv [getoptions argv $options $usage]
  log set_log_level [:loglevel $dargv]
  set res [extraproc_main $dargv]
  log info "Extraproc main finished with return code: $res"
}

# @todo rekening houden met config-file met subdirs, ipv pattern (ook elders al gedaan).
#       kan ook door bij pattern = @config.txt de file config.txt te lezen, en elke regel als pattern te zien.
#       bv functie om op basis van de pattern en een root-dir een lijst met subdirs terug te geven.
proc extraproc_main {dargv} {
  global cr_handler
  set root_dir [from_cygwin [:dir $dargv]]  
  set res "Ok"
  foreach subdir [lsort [glob -nocomplain -directory $root_dir -type d [:pattern $dargv]]] {
    set res [extraproc_subdir $dargv $subdir]
  }
  return $res
}

main $argv

