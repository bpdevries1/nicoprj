#!/usr/bin/env tclsh

# read-nagios-data.tcl

package require ndv
package require tdbc::sqlite3
package require Tclx

source configdata-db.tcl

proc main {} {
  # set db [get_config_db "configdata-check.db"]
  set db [get_config_db "configdata.db"]
  set machines [det_machines $db]
  puts "#machines to check: [:# $machines]"
  foreach machine $machines {
    check_machine $db $machine
  }  
  $db close
}

proc det_machines {db} {
  # nu een die RDP zou moeten hebben
  # @todo nog een die SSH zou moeten hebben.
  # set sourcetable "allmachines"
  set sourcetable "mediq_machine"
  set query "select distinct machine from $sourcetable
             where not machine in (
               select machine from host_check
             )
             order by 1"
  set l [listc {[:machine $el]} el <- [$db query $query]]
  # eerst maar een paar:
  # lrange $l 0 20
  return $l
}

proc check_machine {db machine} {
  puts "Check machine: $machine"
  set ts_cet [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]
  # $db add_tabledef host_check {id} {ts_cet machine domain fullname ip {has_ssh int} {has_rdp int} notes}
  lassign [det_domain_ip $machine] domain fullname ip notes
  if {$domain != ""} {
    set has_ssh [det_port_open $ip 22]
    set has_rdp [det_port_open $ip 3389]
  } else {
    # not found, also put in db
    set has_ssh -1
    set has_rdp -1
  }
  
  $db insert host_check [vars_to_dict ts_cet machine domain fullname ip has_ssh has_rdp notes]
}  

# return list: domain fullname ip notes
proc det_domain_ip {machine} {
  foreach domain {opg.local resource.intra} {
    set res [ping_machine $machine $domain]
    if {[lindex $res 3] == "found"} {
      return $res
    }
  }
  return [list "" "" "" "machine not found in domains"]
}
# return list: domain fullname ip notes
proc ping_machine {machine domain} {
  set fullname "$machine.$domain"
  try_eval {
    set res "<Nothing>"
    set res [exec -ignorestderr ping $fullname]
    # Reply from 10.10.252.31: bytes=    
    if {[regexp {Reply from ([0-9\.]+): bytes=} $res z ip]} {
      puts "  -> found: $domain - $ip"
      return [list $domain $fullname $ip "found"]
    } else {
      puts "  -> ping succeeded, but no IP found:"
      puts $res
      return [list $domain $fullname "" $res]
    }
    # breakpoint
  } {
    # return [list $domain $fullname "" "Error, not found"]
    return [list $domain $fullname "" $res]
  }
}

# return 1 if connection can be made, 0 otherwise
proc det_port_open {ip port} {
  puts "Check port open: $ip - $port ..."
  set res -1
  try_eval {
    set s [socket $ip $port]
    close $s
    set res 1
  } {
    set res 0
  }
  puts "... done, res = $res"
  return $res
}

main
