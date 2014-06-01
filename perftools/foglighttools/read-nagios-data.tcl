#!/usr/bin/env tclsh

# read-nagios-data.tcl

package require ndv
package require tdbc::sqlite3

source configdata-db.tcl

proc main {} {
  set db [get_config_db]
  $db exec2 "delete from nagios_machine"
  set ntotal 0
  foreach filename [glob "nagios-network-status-*.txt"] {
    $db in_trans {
      set nmachines 0
      set f [open $filename r]
      set srcfile [file tail $filename]
      while {![eof $f]} {
        gets $f line
        # server names alleen kleine letters en cijfers.
        # if {[regexp {^[a-z][a-z0-9]+} $line]} {}
        if {[regexp {^[^ \t]+$} $line]} {
          if {![ignore_line $line]} {
            puts "host: $line"
            incr nmachines
            incr ntotal
            set machine [string tolower $line]
            $db insert nagios_machine [vars_to_dict machine srcfile]
          }
        } else {
          if {[regexp {cdmaspd} $line]} {
            breakpoint
          }
        }
      }      
      close $f    
      puts "#machines in $filename: $nmachines"
      # exit ; # test, only file 1
    }
    # $db add_tabledef nagios_machine {id} {machine srcfile}
  }
  puts "#machines total: $ntotal"
}
 
set ignore_res [list {^Up$} {^Down$} {^Unreachable$} {^Pending$} {^Ok$} {^Warning$} {^Unknown$} {^Critical$} {^Pending$} {^$} {^$}] 
proc ignore_line {line} {
  global ignore_res
  foreach re $ignore_res {
    if {[regexp $re $line]} {
      return 1
    }
  }
  return 0
}  
  
main