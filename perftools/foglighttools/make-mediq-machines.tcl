#!/usr/bin/env tclsh

# make-mediq-machines.tcl

package require ndv
package require tdbc::sqlite3

source configdata-db.tcl

proc main {} {
  set db [get_config_db]
  $db in_trans {
    #   $db add_tabledef mediq_machine {id} {machine fullname vmtype ostype machine_function agents}
    $db exec2 "delete from mediq_machine"
    # @todo? machines uit Nagios hier nog aan toevoegen.
    foreach row [$db query "select distinct machine from allmachines order by 1"] {
      set machine [:machine $row]
      set fullname [det_fullname $db $machine]
      set vmtype [det_vmtype $db $machine]
      set ostype [det_ostype $db $machine]
      set machine_function [det_machine_function $db $machine]
      set agents [det_agents $db $machine]
      lassign [det_in_scope $db $machine] in_scope in_scope_notes
#    {ist_this_agenthost int} {soll_this_agenthost int} {ist_agenthost int} \
#    {soll_agenthost int} {ist_mon_cpu int} {ist_mon_mem int} {ist_mon_disk int} {ist_mon_network int} {ist_mon_process int} \
#    actions status
      set ist_credentials [get_table_column $db $machine process_actions credentials monitoredmachine]
      set soll_credentials 1
      set d [dict create ist_mon_cpu cpu_curr ist_mon_mem memory ist_mon_disk disk ist_mon_network network]
      foreach var {ist_mon_cpu ist_mon_mem ist_mon_disk ist_mon_network} {
        set val [get_table_column $db $machine hostsummary [dict get $d $var]]
        set $var [regexp {%} $val]
      }
      
      foreach var {soll_mon_cpu soll_mon_mem soll_mon_disk soll_mon_network soll_mon_process} {
        set $var 1
      }
      set ist_this_agenthost [in_table $db agenthost $machine]
      set ist_agenthost [det_ist_agenthost $db $machine]
      lassign [det_soll_agenthost $db $machine $machine_function] soll_this_agenthost soll_agenthost
      # IST_agenthost	machine naam	agentstatus_monmachine: agentmachine
      
      lassign [det_mon_process $db $machine] ist_mon_process ist_mon_process_status
      $db insert mediq_machine [vars_to_dict machine fullname vmtype ostype machine_function agents \
        in_scope in_scope_notes ist_credentials soll_credentials soll_mon_cpu soll_mon_mem soll_mon_disk \
        soll_mon_network soll_mon_process ist_mon_process ist_mon_process_status \
        ist_mon_cpu ist_mon_mem ist_mon_disk ist_mon_network ist_this_agenthost ist_agenthost soll_this_agenthost soll_agenthost]
    }
  }
  # mss nog wat algemene queries hierbij: alleen soll_qqq als in_scope=1 bv en ook soll_credentials.
  
  $db close
}       
       
proc det_fullname {db machine} {
  set res [$db query "select fullname from allmachines where machine='$machine' order by length(fullname) desc limit 1"]
  if {[:# $res] == 1} {
    return [:fullname [:0 $res]]
  } else {
    return $machine
  }
}       
       
proc det_vmtype {db machine} {
  # hostsummary: type
  set res [$db query "select type type0 from hostsummary where machine='$machine' order by length(type) desc limit 1"]
  if {[:# $res] == 1} {
    return [:type0 [:0 $res]]
  } else {
    return "?"
  }
}

proc det_ostype {db machine} {
  # hostsummary: os
  set res [$db query "select os os0 from hostsummary where machine='$machine' order by length(os) desc limit 1"]
  if {[:# $res] == 1} {
    return [:os0 [:0 $res]]
  } else {
    return "?"
  }
}

proc det_machine_function {db machine} {
  # configdata: configtype
  # function_prio
  set res [$db query "select c.configtype from configdata c join function_prio fp on fp.configtype = c.configtype \
     where machine='$machine' order by fp.prio limit 1"]
  if {[:# $res] == 1} {
    return [:configtype [:0 $res]]
  } else {
    return "?"
  }
}

proc det_agents {db machine} {
  # agentstatus_monmachine: namespace, agenttype
  set res [$db query "select distinct namespace || '/' || agenttype value from agentstatus_monmachine \
     where monitoredmachine='$machine' order by 1"]
  join [listc {[:value $el]} el <- $res] "; "  
}
       
# lassign [det_in_scope $db $machine] in_scope in_scope_notes       
proc det_in_scope {db machine} {
  set pdfoverview [in_table $db pdfoverview $machine]
  set nagios [in_table $db nagios_machine $machine]
  set in_scope [expr $pdfoverview || $nagios]
  set res {}
  if {$pdfoverview} {
    lappend res "PDF-overview"
  }
  if {$nagios} {
    lappend res "Nagios"
  }
  return [list $in_scope [join $res "; "]]
}

proc det_mon_process {db machine} {
  # return: ist_mon_process ist_mon_process_status
  set res [$db query "select process_monitor, status from process_actions where monitoredmachine = '$machine'"]
  if {[:# $res] == 0} {
    return [list 0 "no info"]
  } else {
    dict_to_vars [:0 $res]
    if {$process_monitor == "yes"} {
      return [list 1 "yes, was already done"]
    } elseif {[regexp {added} $process_monitor]} {
      if {$status == "ok"} {
        return [list 1 "yes, done NdV"]
      } else {
        return [list 0 $status]
      }
    } else {
      # return [list 0 "no info"]
      return [list 0 $status]
    }
  }
}

proc det_ist_agenthost {db machine } {
  join [listc {[:agentmachine $el]} el <- [$db query "select distinct agentmachine from agentstatus_monmachine where monitoredmachine='$machine'"]] "; "
}

set function_agent [dict create "vmware virtual machine" fogasglp02 "oracle instance" fogasglp04 host fogasglp02 \
  "sql server instance" fogasglp01 "vmware esx host" fogasglp02]

# lassign [det_soll_agenthost $db $machine] soll_this_agenthost soll_agenthost
proc det_soll_agenthost {db machine machine_function} {
  global function_agent
  set agenthost [get_table_column $db $machine pdfoverview monitormachine]
  if {$agenthost != "?"} {
    if {$agenthost == $machine} {
      return [list 1 $agenthost]
    } else {
      return [list 0 $agenthost]
    }
  } else {
    # niet bestaande, staat in ist_agenthost, wel erbij pakken, maar kan fout zijn.
    # maar wel het type.
    set val [dict_get $function_agent $machine_function]
    if {$val != ""} {
      return [list 0 $val]
    } else {
      return [list 0 "<to determine>"]
    }
  }
}

# library functions?    
proc in_table {db table machine} {
  set res [$db query "select 1 from $table where machine='$machine'"]
  if {[:# $res] > 0} {
    return 1
  } else {
    return 0
  }
}
    
proc get_table_column {db machine table column {machinefield machine}} {
  # hostsummary: type
  set res [$db query "select $column val from $table where $machinefield='$machine' order by length($column) desc limit 1"]
  if {[:# $res] == 1} {
    return [:val [:0 $res]]
  } else {
    return "?"
  }
}
    
main