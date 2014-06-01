#!/usr/bin/env tclsh

# check-hosts-prtg.tcl

package require ndv
package require tdbc::sqlite3
package require Tclx

source configdata-db.tcl

proc main {} {
  # set db [get_config_db "configdata-check.db"]
  set db [get_config_db "configdata.db"]
  # @note not db_trans: ping/nslookup takes longer, able to kill process and not lose all results.
  set query "select distinct lower(infovalue) ipnr from prtginfo
             where infotype = 'ipnr'
             and not infovalue in (
               select ipnr
               from mediq_machine
               where ipnr <> ''
             ) and not infovalue in (
               select ip
               from host_check
               where ip <> ''
             )"
  foreach row [$db query $query] {
    handle_ipnr $db [:ipnr $row]
  }
  set query "select distinct lower(infovalue) ipname from prtginfo
             where infotype = 'ipname'
             and not infovalue in (
               select fullname
               from mediq_machine
               where fullname <> ''
             ) and not infovalue in (
               select fullname
               from host_check
               where fullname <> ''
             )"
  foreach row [$db query $query] {
    handle_ipname $db [:ipname $row]
  }
  $db close
}

# $db add_tabledef host_check {id} {ts_cet machine domain fullname ip {has_ssh int} {has_rdp int} {ping_ok int} notes}
proc handle_ipnr {db ip} {
  set ts_cet [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]
  set fullname [det_ipname $ip]
  lassign [split_ipname $fullname] domain machine
  set has_ssh [det_port_open $ip 22]
  set has_rdp [det_port_open $ip 3389]
  lassign [do_ping $ip] _ ping_ok
  if {$fullname == ""} {
    set notes "nslookup did not give results for: $ip"
  } else {
    set notes ""
  }
  $db insert host_check [vars_to_dict ts_cet machine domain fullname ip has_ssh has_rdp ping_ok notes]
}

proc handle_ipname {db fullname} {
  set ts_cet [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]
  lassign [split_ipname $fullname] domain machine
  lassign [do_ping $fullname] ip ping_ok
  if {$ip != ""} {
    set has_ssh [det_port_open $ip 22]
    set has_rdp [det_port_open $ip 3389]
    set notes ""
  } else {
    set has_ssh -1
    set has_rdp -1
    set notes "No ipnr found for: $fullname"
  }
  $db insert host_check [vars_to_dict ts_cet machine domain fullname ip has_ssh has_rdp ping_ok notes]
}

proc det_ipname {ip} {
  # use nslookup
  try_eval {
    set res "<Nothing>"
    set dnsserver "ipam.opg.local"
    set res [exec -ignorestderr nslookup $ip $dnsserver]
    # breakpoint
    if {[regexp {Name:[ \t]+([^\n]+)} $res z name]} {
      return $name
    } else {
      return ""
    }
  } {
    return ""
  }  
}

proc split_ipname_old {fullname} {
  if {[regexp {^(.+)\.([^\.]+)$} $fullname z machine domain]} {
    list $domain $machine
  } else {
    list "" $fullname
  }
}

proc split_ipname {fullname} {
  if {[regexp {^([^\.]+)\.(.+)$} $fullname z machine domain]} {
    list $domain $machine
  } else {
    list "" $fullname
  }
}

# @return list ipnr ping_ok
proc do_ping {ip_addr} {
  try_eval {
    set res "<Nothing>"
    set res [exec -ignorestderr ping $ip_addr]
    # Pinging catdbprd.opg.local [10.10.25.34] with
    # Pinging 10.10.25.34 with 32 bytes of data
    if {[regexp {Pinging [^ ]+ \[([0-9\.]+)\] with} $res z ipnr]} {
      # ok ipnr set
    } elseif {[regexp {Pinging ([0-9\.]+) with} $res z ipnr]} {
      # ok ipnr set
    } else {
      set ipnr "<none>"
    }
    set ping_ok [regexp {Reply from } $res]
  } {
    set ipnr ""
    set ping_ok -1
  }  
  return [list $ipnr $ping_ok]
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
