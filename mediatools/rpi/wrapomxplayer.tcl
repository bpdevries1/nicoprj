#!/usr/bin/env tclsh

# wrap omxplayer, to log cmdline args for deleting symlinks after playing.

set DEBUG 0
set LOGROOT "/home/pi/log"
# set LOGROOT .

proc main {argv} {
  logd "Calling omxplayer: $argv"
  set filenames {}
  foreach el $argv {
    logd "  arg: $el"
    if {[regexp {^/media} $el]} {
      lappend filenames $el
    }
  }
  if {[llength $filenames] == 2} {
    # subtitles used
    set subs [lindex $filenames 0]
    set video [lindex $filenames 1]
  } else {
    # no subs
    set subs ""
    set video [lindex $filenames 0]
  }
  log "Start: $video (subs: $subs)"
  # cannot start in background using &, then omxremote will think it's finished.
  # also commands like pause are also given correctly now.
  exec omxplayer {*}$argv
  log "Finished: $video (subs: $subs)"
  logd "exit wrapper, omxplayer should have finished playing"
}

# log to general log file and also a temp file, to handle deleting symlinks after playing.
proc log {str} {
  global LOGROOT
  set lognames {"wrapomxplayer.log" "wrapomxplayer-temp.log" "wrapomxplayer-films-move.log"}
  foreach logname $lognames {
    # set f [open [file join $LOGROOT "wrapomxplayer.log"] a]
    set f [open [file join $LOGROOT $logname] a]
    set ts [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S %z"]
    puts $f "\[$ts\] $str"
    close $f
  }
}

proc logd {str} {
  global DEBUG
  if {$DEBUG} {
    log $str
  }
}

main $argv
