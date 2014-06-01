#!/usr/bin/env tclsh

# read-nagios-v2.tcl
# version 2 of data, also read services

package require ndv
package require tdbc::sqlite3

source configdata-db.tcl

proc main {} {
  set db [get_config_db]
  # $db add_tabledef nagios2_host {id} {srcfile host machine os}
  # $db add_tabledef nagios2_service  {id} {srcfile host machine os service}

  $db exec2 "delete from nagios2_host"
  $db exec2 "delete from nagios2_service"
  
  foreach srcfile {nagios-export-v2-file1.txt nagios-export-v2-file2.txt} {
    read_host_service $db $srcfile
  }
  read_hostonly $db nagios-export-v2-hostonly.txt
}

proc read_host_service {db srcfile} {
  set f [open $srcfile r]
  gets $f headerline
  set prev_host "<unknown>"
  $db in_trans {
    while {![eof $f]} {
      set l [split [gets $f] "\t"]
      if {[:# $l] == 3} {
        lassign $l host os service
        if {$service == ""} {
          continue
        }
        if {$host != ""} {
          set host [string tolower $host]
          set machine [det_machine $host]
          $db insert nagios2_host [vars_to_dict srcfile host machine os]
          set prev_host $host
        } else {
          set host $prev_host
        }
        $db insert nagios2_service [vars_to_dict srcfile host machine service]
      }
    }
  }  
  close $f
}

proc det_machine {value} {
  if {[regexp {^([^\.]+)\.} $value z m]} {
    set machine $m
  } else {
    set machine $value
  }
  return $machine
}  

proc read_hostonly {db srcfilename} {
  set f [open $srcfilename r]
  gets $f headerline
  set os ""
  $db in_trans {
    while {![eof $f]} {
      set l [split [gets $f] "\t"]
      if {[:# $l] == 2} {
        # breakpoint
        lassign $l srcfile host
        set host [string tolower $host]
        if {[regexp {^(.+)Â$} $host z host2]} {
          set host $host2
        }
        # breakpoint
        set machine [det_machine $host]
        $db insert nagios2_host [vars_to_dict srcfile host machine os]
      }
    }
  }  
  close $f
}
  
main