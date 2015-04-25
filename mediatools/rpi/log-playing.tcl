#!/usr/bin/env tclsh

proc main {} {
  set res {}
  catch {set res [exec ps -ef | grep omxplayer.bin | grep -v grep]}
  # set res [exec ps -ef | grep emacs | grep -v grep]
  if {$res != ""} {
    set f [open "/home/pi/log/omxplayer.log" a]
    # set f [open "/home/nico/log/omxplayer.log" a]
    set ts [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]
    puts $f "$ts $res"
    close $f
  } else {
    # puts "nothing playing"
  }
}

main

# */5 * * * * /home/pi/bin/log-playing.tcl
