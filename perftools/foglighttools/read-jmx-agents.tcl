#!/usr/bin/env tclsh

# read-nagios-data.tcl

package require ndv
package require tdbc::sqlite3
package require Tclx

source configdata-db.tcl

proc main {argv} {
  global argv0 stdin
  set db [get_config_db]

  $db in_trans {
    $db exec2 "delete from jmxagent"
    set f [open "jmx-agents.txt" r]
    while {![eof $f]} {
      set line [gets $f]
      if {[regexp {agentId=(\d+),([^,]+),namespace=([^ ]+)} $line z agentid agentname namespace]} {
        if {[regexp {^([^#]+)#([^@]+)@([^#]+)#} $agentname z agenttype agentdetail fullname]} {
          set fullname [string tolower $fullname]
          set machine [det_machine $fullname]
        } else {
          # puts "Line not parsed 1: $line"
          if {[regexp -nocase {([^ #@=]+.opg.local)} $agentname z fullname]} {
            set fullname [string tolower $fullname]
            set machine [det_machine $fullname]
            set agenttype ""
            set agentdetail ""
          } elseif {[regexp -nocase {([^ #@=]+.resource.intra)} $agentname z fullname]} {
            set fullname [string tolower $fullname]
            set machine [det_machine $fullname]
            set agenttype ""
            set agentdetail ""
          } else {
            set agenttype ""
            set agentdetail ""
            set fullname ""
            set machine ""
          }
        }
        $db insert jmxagent [vars_to_dict line agentid agentname namespace agenttype agentdetail machine fullname]
      } else {
        # puts "Line not parsed 2: $line"
      }
    }    
    close $f
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

main $argv
