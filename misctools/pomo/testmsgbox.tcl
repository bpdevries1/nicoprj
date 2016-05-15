#!/usr/bin/env wish861

package require ndv
#package require Tclx
#package require snack
#package require Tk

proc main {argv} {
  # global log ar_argv
  wm withdraw .
  after [expr 1000] alarm
  wm withdraw .
  vwait forever  
}

proc alarm {} {
  set answer [::tk::MessageBox -message "Alarm!" \
                  -icon info -type ok \
                  -detail "some seconds have elapsed."]
  exit
}

main $argv

