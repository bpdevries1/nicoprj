#!/usr/bin/env tclsh86

# scatter2db.tcl

package require tdbc::sqlite3
package require Tclx
package require ndv
package require json

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]
$log set_file "[file tail [info script]].log"

# @todo move to ndv lib later
source libdb.tcl

proc main {argv} {
  if {[llength $argv] == 0} {
    if {0} {
      set root_dir "c:/aaa/keynote-mobile"
    } else {
      set root_dir "c:/aaa/keynote-mobile/test"
      file delete [file join $root_dir "keynotelogs.db"] 
    }
  } else {
    lassign $argv root_dir 
  }
  set db_name [file join $root_dir "keynotelogs.db"]
  set conn [open_db $db_name]
  db_add_tabledef logfile {id} {path}
  db_add_tabledef scriptrun {id} {logfile_id target_id slot_id scriptname datetime ts_utc agent_id agent_inst \
    profile_id delta_msec hangup_msec wap_connect_msec signal_strength task_succeed \
    network no_of_resources user_string device error_code content_error}
  db_add_tabledef page {id} {scriptrun_id page_seq connect_delta delta_msec \
    dns_lookup_msec first_packet_delta new_connection remain_packets_delta request_delta \
    ssl_handshake_delta start_msec system_delta \
    element_count page_bytes redir_count redir_delta \
    content_errors error_code page_succeed}
  db_add_tabledef pageitem {id} {scriptrun_id page_id content_type resource_id scontent_type url \
    error_code connect_delta dns_delta element_delta first_packet_delta remain_packets_delta request_delta \
    ssl_handshake_delta start_msec system_delta}
    
  db_create_tables $conn 0 ; # 0: don't drop tables first.
  db_make_insert_statements $conn
  # db_insert logfile {path "test.json"}
  
  handle_files $root_dir $conn
  
  post_process $conn
  
  $conn close
  
}

proc handle_files {root_dir conn} {
  handle_dir_rec $root_dir "*.json" [list read_json_file $conn] 
}

proc read_json_file {conn filename root_dir} {
  log info "Reading $filename"
  if {[is_read $conn $filename]} {
    log info "Already read, ignoring: $filename"
    return
  }
  set logfile_id [db_insert logfile [dict create path $filename] 1]
  set json [json::json2dict [read_file $filename]]
  # breakpoint
  db_in_trans $conn {
    # agent_id agent_inst datetime profile_id slot_id target_id wxn_Script wxn_detail_object wxn_page wxn_summary
    foreach l $json {
      foreach run $l {
        # @note only look in part of run that has main items, to be sure that info like delta_msec is not from sub-request.
        set run_main [dict_get_multi -withname $run target_id slot_id datetime agent_id agent_inst \
                                 profile_id wxn_summary wxn_Script]
        # @todo dict_flat anders: gewoon platslaan, alles teruggeven, geen filter. Ook maar 1 level diep, dus alles op level 0 en alles op level1/filter.
        # @todo is niet triviaal, vooral bepalen of item al atom is.
        set dct [dict_flat $run_main {target_id slot_id datetime agent_id agent_inst \
                                 profile_id delta_msec hangup_msec wap_connect_msec signal_strength task_succeed \
                                 network no_of_resources user_string device error_code content_error}] 
        dict set dct logfile_id $logfile_id
        dict set dct scriptname [det_scriptname [:slot_id $dct]]
        dict set dct ts_utc [det_ts_utc [:datetime $dct]]
        set scriptrun_id [db_insert scriptrun $dct 1]
        
        set details [:wxn_detail_object $run]
        foreach detail $details {
          set ar_detail([:resource_id $detail]) $detail
        }
        # breakpoint
        
        set pages [:wxn_page $run]
        foreach page $pages {
          set page_main [dict_get_multi -withname $page page_seq wxn_page_object wxn_page_performance wxn_page_status]
          set dct [dict_flat $page_main {page_seq connect_delta delta_msec dns_lookup_msec first_packet_delta new_connection \
            remain_packets_delta request_delta ssl_handshake_delta start_msec system_delta \
            element_count page_bytes redir_count redir_delta \
            content_errors error_code page_succeed}]
          # @todo find out what page.start_msec means.
          dict set dct scriptrun_id $scriptrun_id
          set page_id [db_insert page $dct 1]
          
          foreach detail [:wxn_page_details $page] {
            foreach elt [:wxn_page_element $detail] {
              # set dct [dict_flat2 $elt wxn_detail_performance wxn_detail_status]
              set dct [dict_flat $elt {resource_id error_code connect_delta dns_delta element_delta \
                first_packet_delta remain_packets_delta request_delta \
                ssl_handshake_delta start_msec system_delta}]
              dict set dct scriptrun_id $scriptrun_id
              dict set dct page_id $page_id
              set dct2 [dict merge $dct $ar_detail([:resource_id $dct])]
              db_insert pageitem $dct2
            }
          }
        }
      }
    }
  }
  # exit ; # for test.
}

proc is_read {conn filename} {
  if {[llength [db_query $conn "select id from logfile where path='$filename'"]] > 0} {
  return 1 
  } else {
  return 0 
  }
}

array set ar_scriptname {1060724 "Mobile_UK" 1060726 "Mobile_US" 1138756 "Mobile_CN"}  
proc det_scriptname {slot_id} {
  global ar_scriptname
  return $ar_scriptname($slot_id)
}


# @param datetime 2013-JUL-18 00:19:12 
proc det_ts_utc {datetime} {
  clock format [clock scan $datetime -format "%Y-%b-%d %H:%M:%S" -gmt 1] -format "%Y-%m-%d %H:%M:%S" -gmt 1
}

# @note keynote API does not handle redirects correctly, gives them both the same resource_id. This one is to correct the 2nd, which gives a normal 200 code.
proc post_process {conn} {
  db_eval $conn "update pageitem
      set url = url || 'm/'
      where 1*resource_id = 1
      and 1*error_code <> 302
      and url like 'http://m.%'"
}

####################################################################################

# library functions
# return a new dictionary with keys/values as in keys. In dct they may be nested, but not in a list.
proc dict_flat {dct keys} {
  foreach key $keys {
    dict set res $key [dict_find_key $dct $key]
  }
  return $res
}

# return a dictionary with all single elements directly in dct, and all single elements directly under keys in args.
proc dict_flat2 {dct args} {
  dict for {k v} $dct {
     
  }
}

# find key and return value, key could be nested. If not found, return "<none>"
proc dict_find_key {dct key} {
  if {![is_dict $dct]} {
    return "<none>" 
  }
  set res [dict_get $dct $key "<none>"]
  if {$res != "<none>"} {
    return $res 
  } else {
    dict for {k v} $dct {
      set res [dict_find_key $v $key] 
      if {$res != "<none>"} {
        return $res 
      }
    }
    return "<none>"
  }
}

# return 1 if dct is really a dict(ionary)
proc is_dict {dct} {
  if {[string is list $dct]} {    # Only [string is] where -strict has no effect
    if {[expr [llength $dct]&1] == 0} {
      return 1
    }
  }
  return 0
}

main $argv

