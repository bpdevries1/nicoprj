#!/usr/bin/env tclsh

package require tdbc::sqlite3
package require Tclx
package require ndv
package require csv

proc main {argv} {
  set db_name "C:/projecten/Philips/KNDL/MyPhilips-BR/keynotelogs.db"
  
  # open db connection
  set db [dbwrapper new $db_name]  
  
  # link det_iprange function
  [$db get_db_handle] function det_iprange det_iprange
  
  # exec query
  $db exec2 "update location set ip_range = det_iprange(ip_address)" -log 
  
  # close
  $db close

}

proc det_iprange {ip} {
  # for now the first 3 parts
  if {[regexp {^(.*\.)[^\.]+$} $ip z range]} {
    return "$range%" 
  } else {
    error "Cannot determine range from: $ip" 
  }
}

main $argv
