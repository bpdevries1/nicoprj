#!/usr/bin/env tclsh86

package require Tclx
package require ndv

set log [::ndv::CLogger::new_logger [file tail [info script]] info]
$log set_file "[file tail [info script]].log"

set script_dir [file dirname [info script]]
ndv::source_once [file join $script_dir R-wrapper.tcl]
foreach libname [glob -nocomplain -directory $script_dir lib*.tcl] {
  ndv::source_once $libname
}

proc main {argv} {
  log debug "argv: $argv"
  set options {
    {rootdir.arg "c:/projecten/Philips/KNDL" "Directory that contains db"}
    {outrootdir.arg "c:/projecten/Philips/Shop/daily/graphs" "Directory for output graphs"}
    {pattern.arg "Shop-*" "Pattern of scripts to handle"}
    {outformat.arg "png" "Output format (all, png or svg)"}
    {loglevel.arg "info" "Log level (debug, info, warn)"}
    {combineddb.arg "c:/projecten/Philips/Shop/daily/daily.db" "DB with combined data from all shops"}
    {actions.arg "all" "List of actions to execute (comma separated)"}
    {combinedactions.arg "all" "List of actions to execute on combined DB (comma separated)"}
    {periods.arg "all" "Periods to make graphs for (2w, 6w, 2d, 1y, all=1y,6w,2d)"}
    {keepcmd "Keep R command file with timestamp"}
    {incr "Incremental: only create graphs if they do not exist yet"}
  }
  set usage ": [file tail [info script]] \[options] :"
  set dargv [getoptions argv $options $usage]
  log set_log_level [:loglevel $dargv]
  make_graphs $dargv
  # make_graphs_myphilips $dargv
}

main $argv
