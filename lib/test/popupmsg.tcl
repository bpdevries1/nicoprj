#! /home/nico/bin/tclsh

# [2016-11-03 21:02] onderstaande werkt blijkbaar niet vanuit gosleep.tcl
#! /usr/bin/env tclsh

package require Tk
wm withdraw .
lassign $argv text
set answer [::tk::MessageBox -message "Warning!" \
                -icon info -type ok \
                -detail $text]
exit

