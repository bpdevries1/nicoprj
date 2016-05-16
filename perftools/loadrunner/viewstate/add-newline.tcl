package require ndv
package require Tclx

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]

proc main {argc argv} {
  global log

  $log debug "argv: $argv"
  set options {
    {f.arg "" "Filename to add line breaks to."}
    {col.arg "80" "Break line at column"}
    {loglevel.arg "" "Zet globaal log level"}
  }
  set usage ": [file tail [info script]] \[options] :"
  array set ar_argv [::cmdline::getoptions argv $options $usage]

  $log debug "ar_argv: [array get ar_argv]"
  if {$ar_argv(loglevel) != ""} {
    ::ndv::CLogger::set_log_level_all $ar_argv(loglevel)  
  }
  ::ndv::CLogger::set_logfile "[file rootname [file tail [info script]]].log"
  $log info START

  set text [read_file $ar_argv(f)]
  # $log debug "text: $text"
  regsub -all "(.{$ar_argv(col)})" $text "\\1\n" text
  # regsub -all {(.{80})} $text "\\1\n" text
  set f [open "$ar_argv(f).newlines" w]
  puts $f $text
  close $f
  
  $log info FINISHED
  
}

main $argc $argv
