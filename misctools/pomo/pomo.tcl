#!/usr/bin/env wish861

package require ndv
package require Tclx
package require snack
package require Tk

# set log [::ndv::CLogger::new_logger [file tail [info script]] debug]
set_log_global info {filename ~/log/pomo.log append 1}

proc main {argv} {
  # global log ar_argv
  global dargv task
  
  log debug "argv: $argv"
  set options {
    {after.arg "1500" "Sound first alarm after <after> seconds (default 25m)"}
    {repeat.arg "0" "Repeat alarm after <repeat> seconds"}
    {loglevel.arg "" "Zet globaal log level"}
  }
  set usage ": [file tail [info script]] \[options\] \[note/task\]:"
  # array set ar_argv [::cmdline::getoptions argv $options $usage]
  set dargv [getoptions argv $options $usage]
  set after_sec [:after $dargv]
  set task $argv
  log info "Starting pomodore for $after_sec seconds (task: $task)"
  wm withdraw .
  after [expr $after_sec*1000] alarm
  wm withdraw .
  vwait forever  
  log info FINISHED
}

proc alarm {} {
  # global s f ar_argv log
  global dargv task
  log info "Pomodore finished (task: $task)"
  
  # eerst amarok stoppen, anders sound-card gelocked
  # 16-1-2016 dcop doet het niet meer, nu meestal ook amarok stil, zeker tijdens pomodore.
  # exec dcop amarok player stop
  # wel tijdje wachten, 1 sec is niet genoeg.
  # after 10000 
  # $log debug "Amarok gestopt en 10 sec gewacht, nu alarm!"
  # werkt dus ook niet, probeert tcl bij starten al soundcard te claimen?
  # dan een ander process starten of met crontab werken?
  
  # [2016-05-15 13:21] Amarok stoppen mss niet nodig, meestal bij actieve pomo geen
  # muziek draaiend.
  set f [snack::filter generator 440.0 30000 0.0 sine 8000]
  snack::sound s
  $f configure 440
  s stop
  s play -filter $f

  # tk_messageBox
  set answer [::tk::MessageBox -message "Alarm!" \
                  -icon info -type ok \
                  -detail "[:after $dargv] seconds have elapsed."]
  set repeat_sec [:repeat $dargv]
  if {$repeat_sec > 0} {
    log info "Starting pomo again, now for $repeat_sec seconds."
    after [expr $repeat_sec*1000] alarm  
  } else {
    exit
  }
}

main $argv

