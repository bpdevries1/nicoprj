#!/usr/bin/env tclsh86

# scatter2db.tcl

# later also everything for a day in a DB.
# @todo could have two DB connections, and insert parsed data into both!
# @todo and one main DB with has everything except the details, but includes scriptrun and page, see how big this gets.
# en in DB kijken of je deze al gedaan hebt.

package require tdbc::sqlite3
package require Tclx
package require ndv
package require json

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]
$log set_file "[file tail [info script]].log"

proc main {argv} {
  global dct_argv
  log debug "argv: $argv"
  set options {
    {dir.arg "c:/projecten/Philips/KNDL" "Directory where downloaded keynote files are (in subdirs) and where DB's (in subdirs) will be created."}
    {dropdb "Drop the (old) database first"}
    {nopost "Do not post process the data (Only for Mobile now)"}
    {continuous "Keep running this script, to automatically put new items downloaded in DB's"}
    {debug "Run in debug mode, stop when an error occurs"}
  }
  set usage ": [file tail [info script]] \[options] :"
  set dct_argv [::cmdline::getoptions argv $options $usage]

  if {[:dropdb $dct_argv] && [:continuous $dct_argv]} {
    log error "Both dropdb and continuous are set, this does not make sense: exiting"
    exit
  }
  
  if {[:continuous $dct_argv]} {
    log info "Running continuously"
    while {1} {
      set res [scatter2db_main $dct_argv]
      log info "Scatter2db main finished with return code: $res"
      wait_until_next_hour_and_half
    }
  } else {
    log info "Running only once"
    set res [scatter2db_main $dct_argv]
      log info "Scatter2db main finished with return code: $res"
  }
}

# wait eg at 17.40 until it's 18.30, and at 17.25 until it's 17.30
# reason is to not start at the same time with the next download-scatter run.
# @note if you want to run at x:45, add 900 (!) to clock seconds: adding 15 minutes to x:45 results in (x+1):00
proc wait_until_next_hour_and_half {} {
  set finished 0
  set start_hour [clock format [expr [clock seconds] + 1800] -format "%H"]
  while {!$finished} {
    set hour [clock format [expr [clock seconds] + 1800] -format "%H"]
    log info "Time: [clock format [clock seconds]]"
    if {$hour != $start_hour} {
      log info "Finished waiting, starting the next batch of reading the downloads"
      set finished 1 
    } else {
      log info "Wait another 5 minutes, until hour != $start_hour" 
    }
    after 300000
    # after 5000
  }
}

proc scatter2db_main {dct_argv} {
  set root_dir [:dir $dct_argv]  
  
  set db_name [file join $root_dir "keynotelogsmain.db"]
  if {[:dropdb $dct_argv]} {
    file delete $db_name
  }
  # set conn [open_db $db_name]
  # new with TclOO
  # set db [dbwrapper new $conn]
  set existing_db [file exists $db_name]
  # log debug "existing_db: $existing_db"
  set dbmain [dbwrapper new $db_name]
  define_tables $dbmain 0
  if {!$existing_db} {
    $dbmain create_tables 0 ; # 0: don't drop tables first.
    create_indexes $dbmain
  } else {
    # existing db, assuming tables/indexes also already exist. 
  }
  $dbmain prepare_insert_statements

  # @todo create a main db with all info, but possible without page items
  foreach subdir [lsort [glob -nocomplain -directory $root_dir -type d *]] {
    if {[ignore_subdir $subdir]} {
      log info "Ignore subdir: $subdir (for test!)"
    } else {
      set res [scatter2db_subdir $dct_argv $subdir $dbmain]
    }
  }
  
  # 6-9-2013 also handle current-dir, if script is called with one subdir as param
  set res [scatter2db_subdir $dct_argv $root_dir $dbmain]
  
  return $res
}

proc ignore_subdir {subdir} {
  return 0 ; # in production don't ignore anything!
  if {[regexp -nocase {Mobile-landing} $subdir]} {
    return 1 
  }
  if {[regexp -nocase {MyPhilips} $subdir]} {
    return 1 
  }
  return 0
}

proc scatter2db_subdir {dct_argv subdir dbmain} {
  set db_name [file join $subdir "keynotelogs.db"]
  if {[:dropdb $dct_argv]} {
    file delete $db_name
  }
  # set conn [open_db $db_name]
  # new with TclOO
  # set db [dbwrapper new $conn]
  
  set existing_db [file exists $db_name]
  set db [dbwrapper new $db_name]
  define_tables $db
  if {!$existing_db} {
    $db create_tables 0 ; # 0: don't drop tables first.
    create_indexes $db
  } else {
    # existing db, assuming tables/indexes also already exist.
  }
  $db prepare_insert_statements
  # for test.
  # $db insert logfile {path "test.json"}
  handle_files $subdir $db $dbmain
  if {![:nopost $dct_argv]} {
    post_process $db
  }
  # $conn close
  $db close
  log info "Created/updated db $db_name, size is now [file size $db_name]"
  return "ok"
}


proc define_tables {db {pageitem 1}} {
  $db add_tabledef logfile {id} {path filename filesize}
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
    
  if {$pageitem} {
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
}

proc create_indexes {db} {
  $db exec_try "create unique index ix_scriptrun_1 on scriptrun(slot_id,datetime)"
}

# handle each file in a DB trans, not a huge trans for all files.
proc handle_files {root_dir db dbmain} {
  log info "Start reading"
  handle_dir_rec $root_dir "*.json" [list warn_error read_json_file $db $dbmain]
  log info "Finished reading"
}

proc warn_error {proc_name args} {
  global dct_argv
  try_eval {
    $proc_name {*}$args
  } {
    # log warn "$errorResult $errorCode $errorInfo, continuing"
    log_error "continuing..."
    if {[:debug $dct_argv]} {
      # development mode.
      error $errorResult $errorCode $errorInfo
      exit
    } else {
      # production, vooral-doorgaan mode 
    }
  }  
}

proc read_json_file {db dbmain filename root_dir} {
  read_json_file_db $db $filename $root_dir 1
  read_json_file_db $dbmain $filename $root_dir 0
}

proc read_json_file_db {db filename root_dir {pageitem 1}} {
  if {[is_read $db $filename]} {
    # log info "Already read, ignoring: $filename"
    return
  }
  log info "Reading $filename"
  # @todo make $db in_trans function, with max nr of statements to exec in a trans. Goal is speed then, not correct trans boundaries.
  # db_in_trans [$db get_conn] {}
  $db in_trans {    
    set logfile_id [$db insert logfile [dict create path $filename filename [file tail $filename] filesize [file size $filename]] 1]
    set json [json::json2dict [read_file $filename]]
    # breakpoint
      # agent_id agent_inst datetime profile_id slot_id target_id wxn_Script wxn_detail_object wxn_page wxn_summary
    foreach l $json {
      # this l is either a list of TxnMeasurement(s) or a list of WxnMeasurement(s)
      foreach run $l {
        # @note only look in part of run that has main items, to be sure that info like delta_msec is not from sub-request.
        set run_main [dict_get_multi -withname $run target_id slot_id datetime agent_id agent_inst agent_instance_id \
                                 profile_id wxn_summary wxn_Script txn_summary txn_dialer]
        if {[is_read_scriptrun $db $run_main]} {
          log warn "Scriptrun has already been read, possibly double in Keynote json file: $filename, [:slot_id $run_main], [:datetime $run_main]"
          continue
        }
        # @todo dict_flat anders: gewoon platslaan, alles teruggeven, geen filter. Ook maar 1 level diep, dus alles op level 0 en alles op level1/filter.
        # @todo is niet triviaal, vooral bepalen of item al atom is.
        # @todo of op dit niveau een functie die alle directe waarden geeft (geen sub-dict of list), deze kun je dan mergen met alle waarden van specifieke sub-items
  # <element__count>111</element__count><content__errors>4</content__errors><resp__bytes>1059517</resp__bytes><estimated__cache__delta__msec>13026</estimated__cache__delta__msec><trans__level__comp__msec/><delta__user__msec>15309</delta__user__msec><bandwidth__kbsec>70.64</bandwidth__kbsec><cookie__count/><domain__count>10</domain__count><connection__count>23</connection__count><browser__errors/></txn__summary>
  
        set dct [dict_flat $run_main {target_id slot_id datetime agent_id agent_inst agent_instance_id \
             profile_id delta_msec hangup_msec wap_connect_msec signal_strength task_succeed \
             network no_of_resources user_string device error_code content_error \
             element_count content_errors resp_bytes estimated_cache_delta_msec \
             trans_level_comp_msec delta_user_msec bandwidth_kbsec cookie_count domain_count connection_count browser_errors \
             setup_msec attempts speed phone_number}] 
        dict set dct logfile_id $logfile_id
        dict set dct scriptname [det_scriptname [:slot_id $dct] $filename]
        dict set dct ts_utc [det_ts_utc [:datetime $dct]]
        dict set dct ts_cet [det_ts_cet [:datetime $dct]]
        dict set dct provider [det_provider [:target_id $dct]]
        set scriptrun_id [$db insert scriptrun $dct 1]
        
        set dct_details [get_details $run]
        set pages [concat [:wxn_page $run] [:txnPages $run]]
        foreach page $pages {
          handle_page $db $scriptrun_id $page $dct_details $pageitem
        }
      }
    }
  }
}

proc get_details {run} {
  set details [:wxn_detail_object $run]
  set dct_details [dict create] 
  set prev_id 0
  set given_id 0
  foreach detail [lreverse $details] {
    # don't use the resource id when it's not one less than the previous, unless it's the first.
    # dict set dct_details [:resource_id $detail] $detail
    if {$prev_id == [:resource_id $detail]} {
      incr given_id
    } else {
      set prev_id [:resource_id $detail]
      set given_id [:resource_id $detail]
    }
    dict set dct_details $given_id $detail
    incr cur_id -1
  }
  set dct_details  
}

proc get_details_old {run} {
  set details [:wxn_detail_object $run]
  set dct_details [dict create] 
  set cur_id [:resource_id [lindex $details 0]]
  foreach detail $details {
    # don't use the resource id when it's not one less than the previous, unless it's the first.
    # dict set dct_details [:resource_id $detail] $detail
    dict set dct_details $cur_id $detail
    incr cur_id -1
  }
  set dct_details  
}

proc handle_page {db scriptrun_id page dct_details pageitem} {
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
  if {!$pageitem} {
    # in maindb we only keep data without pageitems, otherwise db would grow too big probably.
    return 
  }
  # breakpoint
  # structure for mobile (and other Keynote scripts?)
  foreach detail [:wxn_page_details $page] {
    set prev_id 0
    set given_id 0
    foreach elt [:wxn_page_element $detail] {
      # set dct [dict_flat2 $elt wxn_detail_performance wxn_detail_status]
      set dct [dict_flat $elt {resource_id error_code connect_delta dns_delta element_delta \
        first_packet_delta remain_packets_delta request_delta \
        ssl_handshake_delta start_msec system_delta}]
      dict set dct scriptrun_id $scriptrun_id
      dict set dct page_id $page_id
      # set dct2 [dict merge $dct $ar_detail([:resource_id $dct])]
      # set dct_detail [dict get $dct_details [:resource_id $dct]]
      if {$prev_id == [:resource_id $dct]} {
        incr given_id
      } else {
        set prev_id [:resource_id $dct]
        set given_id [:resource_id $dct]
      }
      set dct_detail [dict get $dct_details $given_id]
      set dct2 [dict merge $dct $dct_detail]
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
    # breakpoint
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
  if {[llength [db_query [$db get_conn] "select id from logfile where filename='[file tail $filename]'"]] > 0} {
    return 1 
  } else {
    return 0 
  }
}

proc is_read_scriptrun {db run_main} {
  if {[llength [db_query [$db get_conn] "select id from scriptrun where slot_id = '[:slot_id $run_main]' and datetime = '[:datetime $run_main]'"]] > 0} {
    return 1 
  } else {
    return 0 
  }
}

proc is_read_old {db filename} {
  if {[llength [db_query [$db get_conn] "select id from logfile where path='$filename'"]] > 0} {
    return 1 
  } else {
    return 0 
  }
}

# @todo read this info from slotmetadata.json
# array set ar_scriptname {1060724 "Mobile_UK" 1060726 "Mobile_US" 1138756 "Mobile_CN" 1129227 "MyPhilips_DE"}
set dct_scriptname [dict create 1060724 "Mobile_UK" 1060726 "Mobile_US" 1138756 "Mobile_CN" 1129227 "MyPhilips_DE"] 
proc det_scriptname {slot_id filename} {
  # global ar_scriptname
  global dct_scriptname
  if {[dict exists $dct_scriptname $slot_id]} {
    return [dict get $dct_scriptname $slot_id]
  } else {
    # determine from filename: MyPhilips-CN-2013-08-03--08-00-10pages.json => MyPhilips-CN
    if {[regexp {^(.+)-\d{4}-\d{2}-\d{2}--} [file tail $filename] z scriptname]} {
      return $scriptname 
    } else {
      error "Cannot determine scriptname from filename: $filename" 
    }
  }
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
# @todo don't use these functions, use the merge solution in 'new/myphilips' way of reading.
proc dict_flat {dct keys} {
  foreach key $keys {
    dict set res $key [dict_find_key $dct $key]
  }
  return $res
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

