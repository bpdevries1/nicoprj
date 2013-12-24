#!/usr/bin/env tclsh86

# combinereport-adddef.tcl add a combine/report definition to the DB.

package require tdbc::sqlite3
package require Tclx
package require ndv

set log [::ndv::CLogger::new_logger [file tail [info script]] info]
$log set_file "[file tail [info script]].log"

ndv::source_once libcombinereport.tcl 

proc main {argv} {
  global dargv
  log debug "argv: $argv"
  set options {
    {srcdir.arg "c:/projecten/Philips/KNDL" "Directory where downloaded keynote files are (in subdirs) and where DB's (in subdirs) will be created."}
    {db.arg "combinereport.db" "DB name to use for combined reports"}
    {targetdir.arg "" "Name of target directory"}
    {pattern.arg "*" "Add subdirs that have pattern"}
    {cmdfile.arg "" "(Shell) file with commands to execute when a combined reports must be made."} 
    {loglevel.arg "info" "Log level (debug, info, warn)"}
    {debug "Run in debug mode, stop when an error occurs"}
  }
  set usage ": [file tail [info script]] \[options] :"
  # set dargv [::cmdline::getoptions argv $options $usage]
  set dargv [getoptions argv $options $usage]
  
  set db [get_combine_report_db $dargv]
  set dct [dict create cmds [file normalize [from_cygwin [:cmdfile $dargv]]] srcdir [from_cygwin [:srcdir $dargv]] \
    active 1 srcpattern [:pattern $dargv] \
    targetdir [from_cygwin [:targetdir $dargv]]]
  set cd_id [$db insert combinedef $dct 1]
  set ndirs 0
  foreach subdir [glob -directory [from_cygwin [:srcdir $dargv]] -type d [:pattern $dargv]] {
    $db insert combinedefdir [dict create combinedef_id $cd_id dir $subdir]
    incr ndirs
  }
  $db exec2 "update combinedef set ndirs = $ndirs where id = $cd_id"
  # set page_id [$db insert page $dctp 1]
  $db close
}

main $argv

