#!/usr/bin/env tclsh

package require ndv
package require tdbc::sqlite3

source configdata-db.tcl

proc main {} {
  # set f [open "agent-status-mdc.txt" r]
  set f [open "agent-status-all.txt" r]
  set db [get_config_db]
  set text [read $f]
  set lines [split $text "\n"]
  read_config $db
  $db in_trans {
    $db exec2 "delete from agentstatus"
    foreach line $lines {
      set l [split [string tolower $line] "\t"]
      puts "#[llength $l]: $line"
      if {[llength $l] == 10} {
        # Active	Collecting Data	Uses Private Properties	fogasglp02.opg.local	ad0-mdc02.resource.intra	ActiveDirectory	ActiveDirectory	5.6.7.1		Delete Agent
        lassign $l z z z agenthostname agentname namespace agenttype agentversion tags
        set agentmachine [det_machine $agenthostname]
        if {[string trim $agenthostname] != ""} {
          if {![db_rec_exists $db $agentname]} {
            set lmonitoredmachines [det_lmonitoredmachines $agentname]
            set monitoredmachines [lmachines_tostring $lmonitoredmachines]
            $db insert agentstatus [vars_to_dict agenthostname agentmachine agentname namespace agenttype agentversion tags monitoredmachines]
            foreach machine $lmonitoredmachines {
              set monitoredmachine [:machine $machine]
              set monmachtype [:configtype $machine]
              $db insert agentstatus_monmachine [vars_to_dict agenthostname agentmachine agentname namespace agenttype agentversion tags monitoredmachine monmachtype]
            }
          }
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
        
proc db_rec_exists {db agentname} {
  set rows [$db query "select agentname from agentstatus where agentname = '$agentname'"]
  if {[llength $rows] > 0} {
    return 1
  } else {
    return 0
  }
}
 
proc read_config {db} {
  global machines
  set machines [$db query "select distinct machine, configtype from configdata"]
}
 
# check for each machine in configdata if it can be found in agentname. If so, add to the result. 
proc det_lmonitoredmachines {agentname} {
  global machines
  set res {}
  foreach machine $machines {
    if {[regexp [:machine $machine] $agentname]} {
      # lappend res "[:machine $machine]:[:configtype $machine]"
      lappend res $machine
    }
  }
  # return [join $res ", "]
  return $res
}

proc lmachines_tostring {lmachines} {
  set res {}
  foreach machine $lmachines {
    lappend res "[:machine $machine]:[:configtype $machine]"
  }
  return [join $res ", "]
}
        
main