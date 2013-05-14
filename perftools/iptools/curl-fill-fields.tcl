#!/usr/bin/env tclsh86

# curl-get-headers.tcl

# @todo add fields cachekey and akamaiserver and fill them.

package require tdbc::sqlite3
package require Tclx
package require ndv

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]
$log set_file "curlgetheader.log"

proc main {argv} {
  # set conn [open_db "~/aaa/akamai.db"]
  set root_folder [det_root_folder] ; # based on OS.
  set db_name [file join $root_folder "aaa/akamai.db"]

  # set conn [open_db "~/Dropbox/Philips/Akamai/akamai.db"]
  # @note 6-5-2013 NdV even curlgetheader2, want loopt thuis ook nog, weer mergen morgen.
  # set table_def [make_table_def curlgetheader ts_start ts fieldvalue param exitcode resulttext msec cacheheaders akamai_env iter cacheable expires expiry cachetype maxage cachekey akamaiserver]
  set table_def [make_table_def_keys curlgetheader {ts_start ts fieldvalue param iter} {exitcode resulttext msec cacheheaders akamai_env cacheable expires expiry cachetype maxage cachekey akamaiserver}]
            
  if {0} {
    lassign $argv settingsfile
    if {$settingsfile != ""} {
      log info "Source settings from $settingsfile"
      source $settingsfile
    } else {
      log warn "No settings file: using defaults" 
    }
  }
  
  log info "Opening database: $db_name"
  set conn [open_db $db_name]

  create_key_index $conn $table_def ; # eenmalig doen.
  # exit
  update_fields $conn $table_def
}

proc update_fields {conn table_def} {
  # in brokjes doen totdat je klaar bent, wel met transactie, want geen externe tools.
  # 2 nieuwe velden later als params doen.
  set res 1
  set total_count 0
  set total_todo [det_total_todo $conn $table_def "cachekey"]
  log info "Total to do for $table_def: $total_todo"
  dict_to_vars $table_def
  # set stmt_update [prepare_update $conn $table $key_fields $value_fields]
  set stmt_update [prepare_update $conn $table_def]
  set ts_start [det_now]
  while {$res > 0} {
    set res [update_fields_iter $conn $table_def "cachekey" $stmt_update] 
    incr total_count $res
    log info "Items handled: $total_count"
    log info "total so far=$total_count/$total_todo, [format %.2f [expr 100.0 * $total_count / $total_todo]]% done"
    log info "ETA: [det_eta $ts_start $total_count $total_todo]"
  }
}

proc update_fields_iter {conn table_def check_fieldname stmt_update} {
  # set max_rows 1000
  set max_rows 1000
  dict_to_vars $table_def
  set query "select *  
             from $table t
             where $check_fieldname is null
             limit $max_rows"
  db_eval $conn "begin transaction"
  set i 0
  foreach dct [db_query $conn $query] {
    incr i
    # set fieldvalue [dict get $dct embedded_url]
    set dct_new [add_values $dct]
    stmt_exec $conn $stmt_update $dct_new
    # log debug "updated fields, i=$i"
  }
  db_eval $conn "commit"
  return $i
}

# add values for cachekey and akamaiserver, based on resulttext
#X-Cache: TCP_MISS from a82-96-58-13.deploy.akamaitechnologies.com (AkamaiGHost/6.11.2.2-10593690) (-)
#X-Cache-Key: /L/1177/96775/1d/www.philips.nl/c/
proc add_values {dct} {
  set resulttext [dict get $dct resulttext]
  if {[regexp { from ([^ ]+)} $resulttext z aksrv]} {
    set akamaiserver $aksrv    
  } else {
    set akamaiserver "<none>" 
  }
  if {[regexp {X-Cache-Key: ([^\n]+)} $resulttext z ck]} {
    set cachekey $ck 
  } else {
    set cachekey "<none>" 
  }
  dict replace $dct akamaiserver $akamaiserver cachekey $cachekey
}

proc det_total_todo {conn table_def check_fieldname} {
  dict_to_vars $table_def
  set query "select count(*) aantal
             from $table t
             where $check_fieldname is null"
  set dct [lindex [db_query $conn $query] 0]
  dict get $dct aantal
}

# library functions?

# @param ts_start sqlite formatted
proc det_eta {ts_start ndone total_todo} {
  set sec_start [clock scan $ts_start -format "%Y-%m-%d %H:%M:%S"]
  set npersec [expr 1.0 * $ndone / ([clock seconds] - $sec_start)]
  set sec_end [expr round($sec_start + ($total_todo / $npersec))]
  clock format $sec_end -format "%Y-%m-%d %H:%M:%S"
}

# c:/aaa on windows, ~/aaa on linux
proc det_root_folder {} {
  global tcl_platform
  if {$tcl_platform(platform) == "windows"} {
    return "c:/" 
  } else {
    return "~/" 
  }
}

#  set table_def [make_table_def_keys curlgetheader {ts_start ts fieldvalue param iter} {exitcode resulttext msec cacheheaders akamai_env cacheable expires expiry cachetype maxage cachekey akamaiserver}]
proc make_table_def_keys {tablename keyfields valuefields} {
  dict create table $tablename keyfields $keyfields valuefields $valuefields fields [concat $keyfields $valuefields] 
}

#  set stmt_update [prepare_update $conn $table_def]
  # @param args: field names
proc prepare_update {conn table_def} {
  $conn prepare [create_update_sql $table_def]
}

proc create_key_index {conn table_def} {
  db_eval_try $conn [create_index_sql $table_def] 
}

proc create_index_sql {table_def} {
  dict_to_vars $table_def
  set sql "create index ix_key_$table on $table ([join $keyfields ", "])"
  log info "create index sql: $sql"
  return $sql
}

proc create_update_sql {table_def} {
  dict_to_vars $table_def
  set sql "update $table
          set [join [lmap par $valuefields {fld_eq_par $par}] ", "]
          where [join [lmap par $keyfields {fld_eq_par $par}] " and "]"
  log debug "update sql: $sql"          
  return $sql          
}

proc fld_eq_par {fieldname} {
  return "$fieldname = [symbol $fieldname]" 
}

main $argv

