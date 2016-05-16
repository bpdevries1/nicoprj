#!/home/nico/bin/tclsh86

package require tdbc::sqlite3
package require Tclx
package require ndv

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]
$log set_file "dnsinfo.log"

proc main {argv} {
  set wait_after 1000
  set conn [open_db "~/aaa/akamai.db"]
  create_tables $conn
  lookup_entries $conn "Digital_Property" $wait_after
  lookup_entries $conn "Origin_Hostname" $wait_after
  lookup_entries $conn "NSLookup_Result" $wait_after
}

proc create_tables {conn} {
  db_eval_try $conn "create table nslookup (ts, fieldvalue, param, exitcode, resulttext)"
}

proc lookup_entries {conn field_name wait_after} {
  set res 1
  set totalcount 0
  while {$res > 0} {
    set res [lookup_entries_iter $conn $field_name $wait_after]
    incr totalcount $res
    log info "Items handled for $field_name: $totalcount"
  }
}

proc lookup_entries_iter {conn fieldname wait_after} {
  # decision: don't use explicit transaction, so every insert will be committed at once.
  set max_rows 100
  log info "Lookup max $max_rows entries (nslookup) for $fieldname"
  set stmt_insert [prepare_insert $conn nslookup ts fieldvalue param exitcode resulttext]
  set query "select distinct p.$fieldname 
             from philips_origin_hostnames_complete_philips_origin_hostnames_comple p 
             where not exists (
               select 1
               from nslookup n
               where n.fieldvalue = p.$fieldname
             )
             limit $max_rows"
  set i 0
  foreach dct [db_query $conn $query] {
    incr i
    # set param [dict get $dct Digital_Property]
    # @todo mss nog extra veld, omdat sanitised value anders kan zijn dan oorspronkelijke value
    # evt ook in result welk veld je getest hebt.
    # anders geeft nslookup tabel aan voor welke waarde je getest hebt, onafhankelijk wat de bron was.
    # set param [sanitise [dict get $dct $fieldname]]
    set fieldvalue [dict get $dct $fieldname]
    set param [sanitise $fieldvalue]
    set ts [det_now]
    if {$param != ""} {
      # return dict with exitcode and resulttext
      set dct_res [do_nslookup $param]
      dict_to_vars $dct_res
      set dct_insert [vars_to_dict ts fieldvalue param exitcode resulttext]
      stmt_exec $conn $stmt_insert $dct_insert
      log info "wait msec (iter=$i): $wait_after"
      after $wait_after
    } else {
      set exitcode -1
      set resulttext "Not executed, param is not IP Address"
      set dct_insert [vars_to_dict ts fieldvalue param exitcode resulttext]
      stmt_exec $conn $stmt_insert $dct_insert
    }
  }
  return $i
}

proc do_nslookup {param} {
  set resulttext ""
  set exitcode -1
  log info "exec nslookup $param"
  try {
    set resulttext [exec nslookup $param]
    set exitcode 0
  } trap CHILDSTATUS {results options} {
    set exitcode [lindex [dict get $options -errorcode] 2]
  }
  log info "result (exitcode=$exitcode): $resulttext"
  dict create exitcode $exitcode resulttext $resulttext
}

proc db_eval_try {conn query {return_id 0}} {
  set res -2
  try_eval {
    set res [db_eval $conn $query $return_id]    
  } {
    log warn "Error during SQL Execute: $errorResult"
    if {$return_id} {
      return -1
    }
  }
  return $res
}

proc sanitise {name} {
  regsub {^s: +} $name "" name
  if {[regexp {^[0-9.]+$} $name]} {
    set ndot [llength [split $name "."]]
    if {$ndot == 4} {
      return $name 
    }
  }
  return ""
}

proc det_now {} {
  clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S" 
}

main $argv

