# library with log functions for logging the items played.

set DEBUG 0
set LOGROOT "/home/pi/log"
# set LOGROOT .
set LOGNAMES {"wrapomxplayer.log" "wrapomxplayer-temp.log" "wrapomxplayer-films-move.log"}

# log to general log file and also a temp file, to handle deleting symlinks after playing.
proc log {str} {
  global LOGROOT LOGNAMES
  foreach logname $LOGNAMES {
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

