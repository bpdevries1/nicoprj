#!/usr/bin/env tclsh

# read-stefan-machines.tcl

package require ndv
package require tdbc::sqlite3

source configdata-db.tcl

proc main {} {
  set db [get_config_db]
  $db exec2 "delete from stefan_machine"
  set filename "stefan-machines.txt"
  $db in_trans {
    set nmachines 0
    set f [open $filename r]
    set srcfile [file tail $filename]
    while {![eof $f]} {
      gets $f line
      if {[string trim $line] != ""} {
        # $db add_tabledef stefan_machine {id} {machine fullname}
        set fullname [string tolower $line]
        set machine [det_machine $fullname]
        $db insert stefan_machine [vars_to_dict machine fullname]
        incr nmachines
      }
    }      
    close $f    
    puts "#machines in $filename: $nmachines"
    # exit ; # test, only file 1
    # $db add_tabledef nagios_machine {id} {machine srcfile}
  }
}
 
proc det_machine {value} {
  if {[regexp {^([^\.]+)\.} $value z m]} {
    set machine $m
  } else {
    set machine $value
  }
  return $machine
}

main