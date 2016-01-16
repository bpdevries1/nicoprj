#!/usr/bin/env wish861

#!/home/nico/bin/wish

# test database connection with perftoolset like CDatabase etc.

package require ndv
package require Tclx
package require snack

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]

proc main {argc argv} {
  global log ar_argv

  $log debug "argv: $argv"
  set options {
    {after.arg "1500" "Sound first alarm after <after> seconds (def 25m)"}
    {repeat.arg "0" "Repeat alarm after <repeat> seconds"}
    {loglevel.arg "" "Zet globaal log level"}
  }
  set usage ": [file tail [info script]] \[options] :"
  array set ar_argv [::cmdline::getoptions argv $options $usage]

  wm withdraw .
  after [expr $ar_argv(after)*1000] alarm
  wm withdraw .
  vwait forever  
  $log info FINISHED
}

proc alarm {} {
  # global s f ar_argv log
  global ar_argv log
  $log info "Alarm!"
  
  # eerst amarok stoppen, anders sound-card gelocked
  # 16-1-2016 dcop doet het niet meer, nu meestal ook amarok stil, zeker tijdens pomodore.
  # exec dcop amarok player stop
  # wel tijdje wachten, 1 sec is niet genoeg.
  # after 10000 
  # $log debug "Amarok gestopt en 10 sec gewacht, nu alarm!"
  # werkt dus ook niet, probeert tcl bij starten al soundcard te claimen?
  # dan een ander process starten of met crontab werken?
  
  set f [snack::filter generator 440.0 30000 0.0 sine 8000]
  snack::sound s
  $f configure 440
  s stop
  s play -filter $f

  set answer [tk_messageBox -message "Alarm!" \
                  -icon info -type ok \
                  -detail "$ar_argv(after) seconds have elapsed."]
  
  if {$ar_argv(repeat) > 0} {
    after [expr $ar_argv(repeat)*1000] alarm  
  } else {
    exit
  }
}

main $argc $argv
