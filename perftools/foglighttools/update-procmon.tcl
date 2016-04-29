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
    while {![eof stdin]} {
      set line [gets stdin]
      update_with_line $db $line    
    }
  }
}  

proc update_with_line {db line} {
  if {[regexp {^([^ ]+) - (.+)$} $line z fullname new_status]} {
    set new_status [string trim $new_status]
    lassign [find_machine_status $db $fullname] machine_id curr_status
    if {$machine_id == -1} {
      puts "machine $fullname not found"
      return
    }
    set total_status [det_total_status $curr_status $new_status]
    # if {[string tolower $new_status] == "ok"} {}
    # 28-5: als status met ok begint, is het goed, dan extra info op te nemen.
    if {[regexp {^ok} [string tolower $new_status]]} {
      set ist_mon_process 1
    } else {
      set ist_mon_process 0
    }
    # @todo check of deze update zonder params werkt met newlines in strings.
    puts "new total status for $fullname (ist_mon_process = $ist_mon_process): "
    puts $total_status
    puts "--------"
    $db exec2 "update mediq_machine set ist_mon_process = $ist_mon_process, 
                 ist_mon_process_status = '$total_status'
               where id = $machine_id"
    if {$ist_mon_process} {
      set status "done"
    } else {
      set status "problem"
    }
    $db exec2 "update mediq_machine 
               set status = '$status'
               where id = $machine_id"
    
  } else {
    #puts "line not in correct format (fullname - status): ignoring:"
    #puts $line
  }
}

proc find_machine_status {db fullname} {
  set res [$db query "select id, ist_mon_process_status from mediq_machine where fullname = '$fullname'"]
  if {[:# $res] == 1} {
    set row [:0 $res]
    return [list [:id $row] [:ist_mon_process_status $row]]
  } else {
    return [list -1 "Machine $fullname not found"]
  }
}
  
proc det_total_status {curr_status new_status} {
  set new_line "[clock format [clock seconds] -format "%d-%m %H:%M"] $new_status"
  set lines [split $curr_status "\n"]
  lappend lines $new_line
  join $lines "\n"
}
  
main $argv
