#! /home/nico/bin/tclsh

# [2016-11-03 21:02] onderstaande werkt blijkbaar niet vanuit gosleep.tcl
#! /usr/bin/env tclsh

package require ndv

proc main_popupmsg {argv} {
  lassign $argv text
  if {$text == "-"} {
    # read stdin
    # puts stderr "Reading stdin"
    set text [read stdin]
  } else {
    # puts stderr "text: ***$text***"
  }
  popup_warning $text
  exit
  
}

proc popup_warning {text} {
  package require Tk
  wm withdraw .

  set answer [::tk::MessageBox -message "Warning!" \
                  -icon info -type ok \
                  -detail $text]
}

if {[this_is_main]} {
  main_popupmsg $argv
}

