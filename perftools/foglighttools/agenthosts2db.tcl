#!/usr/bin/env tclsh

package require ndv
package require tdbc::sqlite3

source configdata-db.tcl

proc main {} {
  set f [open "agent-hosts.txt" r]
  set db [dbwrapper new "configdata.db"]
  $db add_tabledef agenthost {id} {hostname machine agenttype agentversion osname osversion osarch} 
  $db create_tables 0
  $db prepare_insert_statements
  set text [read $f]
  set lines [split $text "\n"]
  $db in_trans {
    $db exec2 "delete from agenthost"
    foreach line $lines {
      set l [split [string tolower $line] "\t"]
      puts "#[llength $l]: $line"
      if {[llength $l] == 6} {
        lassign $l hostname agenttype agentversion osname osversion osarch
        set machine [det_machine $hostname]
        if {[string trim $hostname] != ""} {
          $db insert agenthost [vars_to_dict hostname machine agenttype agentversion osname osversion osarch]
        }
      }
    }
  }	
  close $f
  $db close
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