#!/usr/bin/env tclsh86

# scatter2db.tcl

# @todo also continuously import the data in DB's, with option to not do postprocess always, takes about 7 minutes sometimes.
# first each dir into it's own DB.
# later also everything for a day in a DB.
# @todo could have two DB connections, and insert parsed data into both!

package require tdbc::sqlite3
package require Tclx
package require ndv
package require json

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]
$log set_file "[file tail [info script]].log"

# @todo move to ndv lib later
# source libdb.tcl

proc main {argv} {
  log debug "argv: $argv"
  set options {
    {dir.arg "c:/aaa/keynote-mobile" "Directory to put downloaded keynote files"}
    {test "Test the script, just download a few hours of data"}       
  }
  set usage ": [file tail [info script]] \[options] :"
  set dct_argv [::cmdline::getoptions argv $options $usage]

  set root_dir [:dir $dct_argv]  
  set db_name [file join $root_dir "keynotelogs.db"]
  if {[:test $dct_argv]} {
    file delete $db_name
  }
  # set conn [open_db $db_name]
  # new with TclOO
  # set db [dbwrapper new $conn]
  set db [dbwrapper new $db_name]
  define_tables $db
    
  $db create_tables 0 ; # 0: don't drop tables first.
  $db prepare_insert_statements
  # for test.
  # $db insert logfile {path "test.json"}
  handle_files $root_dir $db
  post_process $db
  # $conn close
  $db close
  log info "Created/updated db $db_name, size is now [file size $db_name]"
}

proc define_tables {db} {
  $db add_tabledef logfile {id} {path}
  $db add_tabledef scriptrun {id} {logfile_id target_id provider slot_id scriptname datetime ts_utc ts_cet agent_id agent_inst agent_instance_id \
    profile_id delta_msec hangup_msec wap_connect_msec signal_strength task_succeed \
    network no_of_resources element_count user_string device error_code content_error content_errors resp_bytes estimated_cache_delta_msec trans_level_comp_msec\
    delta_user_msec bandwidth_kbsec cookie_count domain_count connection_count browser_errors \
    setup_msec attempts speed phone_number}

if {0} {    
Under TxnMeasurement
New <txn__summary>:
<element__count> 
<content__errors> 
<resp_bytes>1059517</resp_bytes>
<estimated_cache_delta_msec>13026</estimated_cache_delta_msec>
<trans_level_comp_msec/>
<delta_user_msec>15309</delta_user_msec>
<bandwidth_kbsec>70.64</bandwidth_kbsec>
<cookie_count/>
<domain_count>10</domain_count>
<connection_count>23</connection_count>
<browser_errors/>

Dialer:
<setup__msec/><attempts/><speed/><phone__number/>    
    }
  $db add_tabledef page {id} {scriptrun_id page_seq connect_delta delta_msec \
    dns_lookup_msec first_packet_delta new_connection remain_packets_delta request_delta \
    ssl_handshake_delta start_msec system_delta \
    element_count page_bytes redir_count redir_delta \
    content_errors error_code page_succeed \
    delta_user_msec first_byte_msec estimated_cache_delta_msec bandwidth_kbsec \
    cookie_count domain_count connection_count browser_errors dom_unload_time \
    dom_interactive_msec dom_content_load_time dom_complete_msec dom_load_time \
    first_paint_msec full_screen_msec time_to_interactive_page custom_component_1_msec \
    custom_component_2_msec custom_component_3_msec}

if {0} {    
<txnPagePerformance>
new:
<delta_user_msec>1631</delta_user_msec>
<first_byte_msec>31</first_byte_msec> - maybe equal to first_packet_delta
<estimated_cache_delta_msec>1097</estimated_cache_delta_msec>
<bandwidth_kbsec>661.23</bandwidth_kbsec>
<cookie_count/>
<domain_count>6</domain_count>
<connection_count>13</connection_count>
<browser_errors/>
<dom_unload_time/>
<dom_interactive_msec>158</dom_interactive_msec>
<dom_content_load_time>22</dom_content_load_time>
<dom_complete_msec>1502</dom_complete_msec>
<dom_load_time>0</dom_load_time>
<first_paint_msec>407</first_paint_msec>
<full_screen_msec/>
<time_to_interactive_page>1504</time_to_interactive_page>
<custom_component_1_msec/>
<custom_component_2_msec/>
<custom_component_3_msec/>
    }
    
    
  $db add_tabledef pageitem {id} {scriptrun_id page_id content_type resource_id scontent_type url \
    extension domain \
    error_code connect_delta dns_delta element_delta first_packet_delta remain_packets_delta request_delta \
    ssl_handshake_delta start_msec system_delta basepage record_seq \
    detail_component_1_msec detail_component_2_msec detail_component_3_msec \
    ip_address element_cached msmt_conn_id conn_string_text request_bytes content_bytes \
    header_bytes object_text header_code custom_object_trend status_code}
# msmt_conn_id: connection id? the TCP Stream, compare wireshark. #of those should be equal to nconnections field.
if {0} {    
Huidig, sorted:    
connect_delta
content_type
dns_delta
domain
element_delta
error_code
extension
first_packet_delta
page_id
remain_packets_delta
request_delta
resource_id
scontent_type
scriptrun_id
ssl_handshake_delta
start_msec
system_delta
url
    
New:
TxnDetailPerformance:
detail_component_1_msec detail_component_2_msec detail_component_3_msec

ip_address
element_cached
msmt_conn_id
conn_string_text
request_bytes
content_bytes
header_bytes
object_text
header_code
custom_object_trend
status_code
url: calc field: concat(conn_string_text, object_text)
}

}

proc define_tables_old {db} {
  $db add_tabledef logfile {id} {path}
  $db add_tabledef scriptrun {id} {logfile_id target_id provider slot_id scriptname datetime ts_utc ts_cet agent_id agent_inst \
    profile_id delta_msec hangup_msec wap_connect_msec signal_strength task_succeed \
    network no_of_resources user_string device error_code content_error}
  $db add_tabledef page {id} {scriptrun_id page_seq connect_delta delta_msec \
    dns_lookup_msec first_packet_delta new_connection remain_packets_delta request_delta \
    ssl_handshake_delta start_msec system_delta \
    element_count page_bytes redir_count redir_delta \
    content_errors error_code page_succeed}
  $db add_tabledef pageitem {id} {scriptrun_id page_id content_type resource_id scontent_type url \
    extension domain \
    error_code connect_delta dns_delta element_delta first_packet_delta remain_packets_delta request_delta \
    ssl_handshake_delta start_msec system_delta}
}

# handle each file in a DB trans, not a huge trans for all files.
proc handle_files {root_dir db} {
  log info "started transaction, now start reading"
  handle_dir_rec $root_dir "*.json" [list warn_error read_json_file $db]
  log info "Finished reading, now committing all data"
}

proc handle_files_old {root_dir db} {
  db_in_trans [$db get_conn] {
    log info "started transaction, now start reading"
    handle_dir_rec $root_dir "*.json" [list warn_error read_json_file $db]
    log info "Finished reading, now committing all data"
  }
}

proc warn_error {proc_name args} {
  try_eval {
    $proc_name {*}$args
  } {
    log warn "$errorResult $errorCode $errorInfo, continuing"
    #error $errorResult $errorCode $errorInfo
    #exit
  }  
}

proc read_json_file {db filename root_dir} {
  log info "Reading $filename"
  if {[is_read $db $filename]} {
    log info "Already read, ignoring: $filename"
    return
  }
  # @todo make $db in_trans function, with max nr of statements to exec in a trans. Goal is speed then, not correct trans boundaries.
  db_in_trans [$db get_conn] {
    set logfile_id [$db insert logfile [dict create path $filename] 1]
    set json [json::json2dict [read_file $filename]]
    # breakpoint
      # agent_id agent_inst datetime profile_id slot_id target_id wxn_Script wxn_detail_object wxn_page wxn_summary
    foreach l $json {
      # this l is either a list of TxnMeasurement(s) or a list of WxnMeasurement(s)
      foreach run $l {
        # @note only look in part of run that has main items, to be sure that info like delta_msec is not from sub-request.
        set run_main [dict_get_multi -withname $run target_id slot_id datetime agent_id agent_inst agent_instance_id \
                                 profile_id wxn_summary wxn_Script txn_summary txn_dialer]
        # @todo dict_flat anders: gewoon platslaan, alles teruggeven, geen filter. Ook maar 1 level diep, dus alles op level 0 en alles op level1/filter.
        # @todo is niet triviaal, vooral bepalen of item al atom is.
  
  # <element__count>111</element__count><content__errors>4</content__errors><resp__bytes>1059517</resp__bytes><estimated__cache__delta__msec>13026</estimated__cache__delta__msec><trans__level__comp__msec/><delta__user__msec>15309</delta__user__msec><bandwidth__kbsec>70.64</bandwidth__kbsec><cookie__count/><domain__count>10</domain__count><connection__count>23</connection__count><browser__errors/></txn__summary>
  
        set dct [dict_flat $run_main {target_id slot_id datetime agent_id agent_inst agent_instance_id \
             profile_id delta_msec hangup_msec wap_connect_msec signal_strength task_succeed \
             network no_of_resources user_string device error_code content_error \
             element_count content_errors resp_bytes estimated_cache_delta_msec \
             trans_level_comp_msec delta_user_msec bandwidth_kbsec cookie_count domain_count connection_count browser_errors \
             setup_msec attempts speed phone_number}] 
        dict set dct logfile_id $logfile_id
        dict set dct scriptname [det_scriptname [:slot_id $dct]]
        dict set dct ts_utc [det_ts_utc [:datetime $dct]]
        dict set dct ts_cet [det_ts_cet [:datetime $dct]]
        dict set dct provider [det_provider [:target_id $dct]]
        set scriptrun_id [$db insert scriptrun $dct 1]
        
        # breakpoint
        set dct_details [get_details $run]
        set pages [concat [:wxn_page $run] [:txnPages $run]]
        # set pages [:txnPages $run]
        foreach page $pages {
          handle_page $db $scriptrun_id $page $dct_details
        }
      }
    }
  }
  # exit ; # for test.
}

proc get_details {run} {
  set details [:wxn_detail_object $run]
  set dct_details [dict create] 
  foreach detail $details {
    dict set dct_details [:resource_id $detail] $detail 
  }
  set dct_details  
}

proc handle_page {db scriptrun_id page dct_details} {
  set page_main [dict_get_multi -withname $page page_seq wxn_page_object wxn_page_performance wxn_page_status \
    txnPagePerformance txnPageObject txnPageStatus]
  set dct [dict_flat $page_main {page_seq connect_delta delta_msec dns_lookup_msec first_packet_delta new_connection \
    remain_packets_delta request_delta ssl_handshake_delta start_msec system_delta \
    element_count page_bytes redir_count redir_delta \
    content_errors error_code page_succeed \
    bandwidth_kbsec browser_errors connection_count cookie_count custom_component_1_msec 
    custom_component_2_msec custom_component_3_msec delta_user_msec dom_complete_msec 
    dom_content_load_time dom_interactive_msec dom_load_time dom_unload_time domain_count 
    estimated_cache_delta_msec first_byte_msec first_paint_msec full_screen_msec time_to_interactive_page}]
  # @todo find out what page.start_msec means.
  dict set dct scriptrun_id $scriptrun_id
  set page_id [$db insert page $dct 1]
  # breakpoint
  # structure for mobile (and other Keynote scripts?)
  foreach detail [:wxn_page_details $page] {
    foreach elt [:wxn_page_element $detail] {
      # set dct [dict_flat2 $elt wxn_detail_performance wxn_detail_status]
      set dct [dict_flat $elt {resource_id error_code connect_delta dns_delta element_delta \
        first_packet_delta remain_packets_delta request_delta \
        ssl_handshake_delta start_msec system_delta}]
      dict set dct scriptrun_id $scriptrun_id
      dict set dct page_id $page_id
      set dct2 [dict merge $dct $ar_detail([:resource_id $dct])]
      dict set dct2 extension [det_extension [:url $dct2]]
      dict set dct2 domain [det_domain [:url $dct2]]
      $db insert pageitem $dct2
    }
  }
  # MyPhilips structure with txnPageDetails looks a bit different, first handle seperately.
  try_eval {
    set details [:txnPageDetails $page]
    if {$details != "null"} {
      handle_element $db $scriptrun_id $page_id [:txnBasePage $details] 1
      foreach elt [:txnPageElement $details] {
        handle_element $db $scriptrun_id $page_id $elt 0
      }
    }
  } {
    log warn "$errorResult $errorCode $errorInfo, continuing"
    breakpoint
  }
}

proc handle_element {db scriptrun_id page_id elt basepage} {
  if {($elt == "null") || ($elt == "")} {
    return 
  }
  if {[llength [:txnDetailObject $elt]] > 1} {
    log warn "More than one txnDetailObject in elt: $elt" 
  }
  # breakpoint
  set dct [dict merge [dict_get_multi -withname $elt record_seq] \
                      [:txnDetailPerformance $elt] \
                      [lindex [:txnDetailObject $elt] 0] \
                      [:txnDetailStatus $elt]]
  dict set dct scriptrun_id $scriptrun_id
  dict set dct page_id $page_id
  dict set dct basepage $basepage
  set url "[:conn_string_text $dct][:object_text $dct]"
  dict set dct url $url
  dict set dct extension [det_extension $url]
  dict set dct domain [det_domain $url]
  $db insert pageitem $dct
}

proc is_read {db filename} {
  if {[llength [db_query [$db get_conn] "select id from logfile where path='$filename'"]] > 0} {
    return 1 
  } else {
    return 0 
  }
}

# @todo read this info from slotmetadata.json
array set ar_scriptname {1060724 "Mobile_UK" 1060726 "Mobile_US" 1138756 "Mobile_CN" 1129227 "MyPhilips_DE"}  
proc det_scriptname {slot_id} {
  global ar_scriptname
  return $ar_scriptname($slot_id)
}


# @param datetime 2013-JUL-18 00:19:12 
proc det_ts_utc {datetime} {
  clock format [clock scan $datetime -format "%Y-%b-%d %H:%M:%S" -gmt 1] -format "%Y-%m-%d %H:%M:%S" -gmt 1
}

# @param datetime 2013-JUL-18 00:19:12 
proc det_ts_cet {datetime} {
  clock format [clock scan $datetime -format "%Y-%b-%d %H:%M:%S" -gmt 1] -format "%Y-%m-%d %H:%M:%S"
}

# @note keynote API does not handle redirects correctly, gives them both the same resource_id. This one is to correct the 2nd, which gives a normal 200 code.
proc post_process {db} {
  log info "Post process: start"
  db_eval [$db get_conn] "update pageitem
      set url = url || 'm/'
      where 1*resource_id = 1
      and 1*error_code <> 302
      and url like 'http://m.%'"
  log info "Post process: finished"      
}

proc det_domain {url} {
  # remove T-Mobile UMTS specific cache-part like '1.2.3.9/bmi'
  # http://1.2.3.9/bmi/m.philips.co.uk/consumerfiles/mobile/img/rec-apps/stores/icon_apple.png =>
  # http://m.philips.co.uk/consumerfiles/mobile/img/rec-apps/stores/icon_apple.png
  regsub {1.2.3.[0-9]+/bmi/} $url "" url
  if {[regexp {https?://([^/]+)} $url z domain]} {
    return $domain 
  } else {
    return "<none>" 
  }
}

# @todo maybe should use url lib to handle this
# @note by adding checks for webservice and logout it becomes Philips specific
proc det_extension {lb} {
  if {[regexp {^([^?;]+)} $lb z prefix]} {
    # ext max 10 chars
    if {[regexp {\.([^/.]+)$} [string range $prefix end-10 end] z ext]} {
      return $ext 
    } else {
      return "<none>" 
    }
  } else {
    return "<unknown>" 
  }
}

set dct_provider [dict create 1545005 Vodafone 1545000 o2 1544995 3 1545010 "T-mobile" \
  1544985 Verizon 1544990 Sprint 1544975 "AT&T" 1544980 "T-mobile" 1497245 "china-unicom"]
proc det_provider {target_id} {
  global dct_provider
  dict_get $dct_provider $target_id "Unknown"
  # return $ar_provider($target_id)
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

# ook iets met pretty print?

# the functions below feel quite shaky, not stable. Any better way to determine the 'data' type?
# some options while parsing the json, but makes rest handling trickier, some metadata would be useful (clj again!).
# only use these functions while investigating the structure, not in production code to read the data, then know and assume the types.

# is dct a dictionary with atom keys, ie keys that are not lists/dicts?
proc is_dict_atom_keys {dct} {
  if {[is_dict $dct]} {
    # @todo do with filter/every or something like this
    set all_atom 1
    foreach el [dict keys $dct] {
      if {![is_atom $el]} {
        puts "not atom: $el (in $dct)"
        set all_atom 0 
      }
    }
    return $all_atom
  } else {
    return 0 
  }
}

# @todo how is the clj equiv function called?
proc is_atom {el} {
  if {[string is graph $el]} {    # Only [string is] where -strict has no effect
    return 1
  } else {
    return 0 ; # try out. 
  }
}

# @todo how is the clj equiv function called?
# @todo result could be opposite of is_atom, but maybe there will be another option
proc is_list {el} {
  if {[string is list $el]} {    # Only [string is] where -strict has no effect
    if {[is_atom $el]} {
      return 0 
    } else {
      return 1
    }
  } else {
    return 0 ; # try out. 
  }
}

proc det_type2 {el} {
  if {[is_atom $el]} {
    return atom 
  } elseif {[is_dict_atom_keys $el]} {
    return dict 
  } elseif {[is_list $el]} {
    return list 
  } else {
    return unknown 
  }
}

proc det_type {value} {
  if {[regexp {^value is a (.*?) with a refcount} \
        [::tcl::unsupported::representation $value] -> type]} {
    return $type
  } else {
    return "type2: [det_type2 $value]" 
  }
}          

main $argv

