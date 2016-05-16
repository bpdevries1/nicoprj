package require ndv

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]

proc main {argc argv} {
  global log db

  $log debug "argv: $argv"
  set options {
    {loglevel.arg "" "Zet globaal log level"}
  }
  set usage ": [file tail [info script]] \[options] :"
  array set ar_argv [::cmdline::getoptions argv $options $usage]

  if {$ar_argv(loglevel) != ""} {
    ::ndv::CLogger::set_log_level_all $ar_argv(loglevel)  
  }
  ::ndv::CLogger::set_logfile "[file rootname [file tail [info script]]].log"
  $log info START
  $log info "Write current date time to start-test.txt"
  set f [open start-test.txt w]
  puts $f [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]
  close $f

  $log info FINISHED
}

if {[file tail $argv0] == [file tail [info script]]} {
  main $argc $argv
}  