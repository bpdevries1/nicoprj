#!/usr/bin/env tclsh86

package require tdbc::sqlite3
package require Tclx
package require ndv
package require tdom
package require struct::list

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]

proc main {argv} {
  set conn [open_db "c:/aaa/akamai.db"]
  set dir "C:/nico/Dropbox/Philips/Akamai/configs-orig"
  db_eval_try $conn "drop table configfile"
  db_eval $conn "create table configfile (ts, configfile, domain, configtype)"
  db_eval $conn "begin transaction"
  set stmt_insert [prepare_insert $conn configfile ts configfile domain configtype]
  set ts [det_now]
  foreach configfile [glob -tails -directory $dir "*.xml"] {
    log info "configfile: $configfile"
    set xml [read_file [file join $dir $configfile]]
    set doc [dom parse $xml]
    set root [$doc documentElement]

    # comments
    # set nodes [$root selectNodes {/configs/akamai:edge-config/comment:hoits}]
    set nodes [$root selectNodes {//comment:hoits}]
    set configtype "comment:hoits"
    log debug "#nodes: [llength $nodes]"
    foreach node $nodes {
      set value [$node getAttribute value]
      log debug "value: $value"
      foreach domain [split $value " "] {
        log debug "domain: $domain"
        
        $stmt_insert execute [vars_to_dict ts configfile domain configtype]
      }
    }
    
    # match:hoit host="www.poland.philips.com"> <forward:origin-server.host>%(AK_HOSTHEADER
    # set nodes [$root selectNodes {/configs/akamai:edge-config/match:hoit}]
    set nodes [$root selectNodes {//match:hoit}]
    set configtype "match:hoit"
    log debug "match-#nodes: [llength $nodes]"
    foreach node $nodes {
      set host [$node getAttribute host]
      log debug "match-host: $host"
      foreach domain [split $host " "] {
        log debug "match-domain: $domain"
        $stmt_insert execute [vars_to_dict ts configfile domain configtype]
      }
    }
    
  }
  db_eval $conn "commit"
  $conn close  
}

proc det_now {} {
  clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S" 
}


main $argv
