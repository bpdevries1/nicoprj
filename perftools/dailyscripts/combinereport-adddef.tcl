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
  set cmds [det_cmds $dargv]
  set targetdir [from_cygwin [:targetdir $dargv]]
  # make possible old definition inactive.
  $db exec2 "update combinedef set active = 0 where targetdir = '$targetdir'" -log
  set dct [dict create cmds $cmds srcdir [from_cygwin [:srcdir $dargv]] \
    active 1 srcpattern [:pattern $dargv] \
    targetdir $targetdir]
  set cd_id [$db insert combinedef $dct 1]
  set ndirs 0
  foreach subdir [glob -directory [from_cygwin [:srcdir $dargv]] -type d [:pattern $dargv]] {
    $db insert combinedefdir [dict create combinedef_id $cd_id dir $subdir]
    delete_dailystatus_combinereport $subdir
    incr ndirs
  }
  $db exec2 "update combinedef set ndirs = $ndirs where id = $cd_id"
  $db close
}

proc det_cmds {dargv} {
  set cmds [file normalize [from_cygwin [:cmdfile $dargv]]]
  if {$cmds == ""} {
    set outrootdir [file join [:targetdir $dargv] daily graphs]
    set combineddb [file join [:targetdir $dargv] daily daily.db]
    # note newlines added explicitly for now, seems necessary.
    set cmds "set script_dir \[file join \[info script\] .. .. graphtools\]\r\n
ndv::source_once \[file join \$script_dir R-wrapper.tcl\]\r\n
foreach libname \[glob -nocomplain -directory \$script_dir lib*.tcl\] {\r\n
  ndv::source_once \$libname\r\n
}\r\n
set dct \[dict create rootdir \"c:/projecten/Philips/KNDL\" outrootdir \"$outrootdir\" pattern \"XX\" outformat \"png\" loglevel \"info\" combineddb \"$combineddb\" actions \"\" periods \"all\" keepcmd 0 incr 0\]\r\n
make_graphs \[dict merge \$dct \[dict create combinedactions \"all\"\]\]\r\n"
  }
  # check newlines.
  return $cmds
}

# delete dailystatus record from src-db where actiontype = 'combinereport', so data will be copied to new aggr location.
proc delete_dailystatus_combinereport {subdir} {
  set db [dbwrapper new [file join $subdir keynotelogs.db]]
  $db exec2 "delete from dailystatus where actiontype = 'combinereport'" -try -log
  $db close
}

main $argv
