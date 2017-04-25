#! /usr/bin/env wish861

# TODO: replace by just wish.

package require ndv
package require Tclx
package require snack
package require Tk

require libdatetime dt

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
  # [2017-04-24 11:13] apparently log info here does not put anything to the screen/stdout.
  puts "[dt/now]: Starting pomodore for $after_sec seconds (task: $task)"
  wm withdraw .
  after [expr $after_sec*1000] alarm
  wm withdraw .
  vwait forever  
  log info FINISHED
}

# https://groups.google.com/forum/#!topic/comp.lang.tcl/jCyx9cupdvw
# So there are two solutions:
# * use a newer snack package that is build with alsa support
# * enable the oss emulation layer for alsa with 'sudo modprobe snd-pcm-oss' 
# $ sudo modprobe snd-pcm-oss modprobe: FATAL: Module snd-pcm-oss not found in directory /lib/modules/4.8.0-27-generic
# [2016-11-13 16:20] werkt ook niet, niet zo belangrijk nu.

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
  # [2016-11-13 16:20] Op Lubuntu 16.10 doet Snack het niet, zie ook hierboven. Nu niet zo belangrijk.
  catch {play_sound}
  
  # tk_messageBox
  set elapsed [clock format [:after $dargv] -format "%Mm%Ss"]
  set answer [::tk::MessageBox -message "Alarm!" \
                  -icon info -type ok \
                  -detail "$elapsed have elapsed."]
  set repeat_sec [:repeat $dargv]
  if {$repeat_sec > 0} {
    log info "Starting pomo again, now for $repeat_sec seconds."
    after [expr $repeat_sec*1000] alarm  
  } else {
    exit
  }
}

proc play_sound {} {
  set f [snack::filter generator 440.0 30000 0.0 sine 8000]
  snack::sound s
  $f configure 440
  s stop
  s play -filter $f
}

main $argv

