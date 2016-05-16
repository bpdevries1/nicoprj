#!/usr/bin/env tclsh86

# TODO
# protocol/host vervangen door {host} of evt hostx als er meerdere zijn. Hosts ook 'printen' op het eind.
# generieke stukken van URL's vervangen door {urlpartx} en ook deze op het eind noemen.

package require textutil::split
package require Tclx
package require ndv

interp alias {} splitx {} ::textutil::split::splitx

set DEBUG 0

proc main {argv} {
  global prj_dir
  lassign $argv prj_dir
  
  set report_dir [file join $prj_dir report]
  file mkdir $report_dir
  set f [open [file join $report_dir domains.org] w]
  foreach c_filename [lsort -nocase [glob -directory $prj_dir *.c]] {
    handle_c_file $f $c_filename
  }
  
  close $f 
}

proc handle_c_file {f c_filename} {
  global DEBUG
  puts $f "* [file tail $c_filename]"
  set text [read_file $c_filename]
  set lines [split $text "\n"]
  set d [dict create]
  foreach line $lines {
    if {[regexp {https?://([^/]+)} $line z dom]} {
      dict set d $dom 1
    }
  }
  foreach dom [lsort [dict keys $d]] {
    puts $f "** $dom"
  }
}

main $argv
