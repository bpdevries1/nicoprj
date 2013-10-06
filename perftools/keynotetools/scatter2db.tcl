#!/usr/bin/env tclsh86

# scatter2db.tcl

# later also everything for a day in a DB.
# @todo could have two DB connections, and insert parsed data into both!
# @todo and one main DB with has everything except the details, but includes scriptrun and page, see how big this gets.
# en in DB kijken of je deze al gedaan hebt.
# @todo possibly remove main-db: not used until now and have to take into account with db migrations etc.

package require tdbc::sqlite3
package require Tclx
package require ndv
package require json

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]
$log set_file "[file tail [info script]].log"

# libpostproclogs: set_task_succeed (and maybe others)
set script_dir [file dirname [info script]]
source [file join $script_dir libpostproclogs.tcl]
source [file join $script_dir libmigrations.tcl]
source [file join $script_dir kn-migrations.tcl]
source [file join $script_dir checkrun-handler.tcl]

proc main {argv} {
  global dargv
  log debug "argv: $argv"
  set options {
    {dir.arg "c:/projecten/Philips/KNDL" "Directory where downloaded keynote files are (in subdirs) and where DB's (in subdirs) will be created."}
    {justdir "Just read this directory, not subdirectories. If this is set, dir should not contain subdirs besides 'read'"}
    {dropdb "Drop the (old) database first"}
    {nopost "Do not post process the data (Only for Mobile now)"}
    {nomain2 "Do not put data in a main db"}
    {moveread "Move read files to subdirectory 'read'"}
    {continuous "Keep running this script, to automatically put new items downloaded in DB's"}
    {debug "Run in debug mode, stop when an error occurs"}
  }
  set usage ": [file tail [info script]] \[options] :"
  # set dargv [::cmdline::getoptions argv $options $usage]
  set dargv [getoptions argv $options $usage]
  
  # 28-9-2013 don't support maindb anymore for now, don't use it now.
  dict set dargv nomain 1
  if {[:dropdb $dargv] && [:continuous $dargv]} {
    log error "Both dropdb and continuous are set, this does not make sense: exiting"
    exit
  }
  
  if {[:continuous $dargv]} {
    log info "Running continuously"
    while {1} {
      set res [scatter2db_main $dargv]
      log info "Scatter2db main finished with return code: $res"
      wait_until_next_hour_and_half
    }
  } else {
    log info "Running only once"
    set res [scatter2db_main $dargv]
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

proc scatter2db_main {dargv} {
  global cr_handler
  set root_dir [from_cygwin [:dir $dargv]]  
  
  if {[:nomain $dargv]} {
    log info "Don't use main DB"
    set dbmain ""
  } else {
#    log info "Use main DB"
#    set db_name [file join $root_dir "keynotelogsmain.db"]
#    if {[:dropdb $dargv]} {
#      file delete $db_name
#    }
#    set existing_db [file exists $db_name]
#    set dbmain [dbwrapper new $db_name]
#    define_tables $dbmain 0
#    if {!$existing_db} {
#      $dbmain create_tables 0 ; # 0: don't drop tables first.
#      create_indexes $dbmain
#    } else {
#      # existing db, assuming tables/indexes also already exist. 
#    }
#    migrate_db $dbmain $existing_db    
#    $dbmain prepare_insert_statements
  }  
  set cr_handler [checkrun_handler new]
  if {[:justdir $dargv]} {
    # 6-9-2013 also handle current-dir, if script is called with one subdir as param
    # 16-9-2013 not correct, this would create huge keynotelogs.db file in the root when called normally.
    # so use cmdline param if we want this.
    # wel checken dat deze dir geen subdirs heeft (of alleen een 'read' subdir)
    if {[llength [glob -nocomplain -directory $root_dir -type d *]] > 1} {
      log error "Cannot use -justdir when dir has subdirs, exiting.."
      exit 1
    }
    set res [scatter2db_subdir $dargv $root_dir $dbmain]
  } else {
    foreach subdir [lsort [glob -nocomplain -directory $root_dir -type d *]] {
      if {[ignore_subdir $subdir]} {
        log info "Ignore subdir: $subdir (for test!)"
      } else {
        set res [scatter2db_subdir $dargv $subdir $dbmain]
      }
    }
  }
  $cr_handler destroy
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

proc scatter2db_subdir {dargv subdir dbmain} {
  global cr_handler
  set db_name [file join $subdir "keynotelogs.db"]
  if {[:dropdb $dargv]} {
    file delete $db_name
  }
  # set conn [open_db $db_name]
  # new with TclOO
  # set db [dbwrapper new $conn]
  
  set existing_db [file exists $db_name]
  set db [dbwrapper new $db_name]
  define_tables $db
  if {!$existing_db} {
    log info "New db: $db_name, create tables"
    $db create_tables 0 ; # 0: don't drop tables first.
    create_indexes $db
    migrate_kn_create_view_rpi $db
    copy_script_pages $db
    # set initial db version
  } else {
    log info "Existing db: $db_name, don't create tables"
  }
  migrate_db $db $existing_db
  # @todo nog even if 0, want niet in 'productie'
  if {1} {
    set has_fields [add_checkrun $db]
    $cr_handler set_has_fields $has_fields
    # [2013-10-06 12:36:27] added {}, so fields are not key fields.
    $db add_tabledef checkrun {}  \
      [concat {scriptrun_id ts_cet task_succeed real_succeed} $has_fields]
  }

  $db prepare_insert_statements
  # for test.
  # $db insert logfile {path "test.json"}
  read_script_pages $db ; # into global dict, should perform better.
  handle_files $subdir $db $dbmain
  if {![:nopost $dargv]} {
    post_process $db
  }
  # $conn close
  $db close
  log info "Created/updated db $db_name, size is now [file size $db_name]"
  return "ok"
}

proc define_tables {db {pageitem 1}} {
  $db add_tabledef logfile {id} {path filename filesize}
  $db add_tabledef scriptrun {id} {logfile_id target_id provider slot_id scriptname \
    datetime ts_utc ts_cet date_cet agent_id agent_inst agent_instance_id \
    profile_id delta_msec hangup_msec wap_connect_msec signal_strength task_succeed \
    task_succeed_calc \
    network no_of_resources element_count user_string device error_code content_error \
    content_errors resp_bytes estimated_cache_delta_msec trans_level_comp_msec\
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
  $db add_tabledef page {id} {scriptname ts_cet date_cet scriptrun_id page_seq page_type connect_delta delta_msec \
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
    $db add_tabledef pageitem {id} {scriptname ts_cet date_cet scriptrun_id page_seq page_type page_id content_type resource_id \
      scontent_type url \
      extension domain topdomain urlnoparams \
      error_code connect_delta dns_delta element_delta first_packet_delta \
      remain_packets_delta request_delta \
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
  $db exec2 "create index if not exists ix_page_1 on page (scriptrun_id)"
  # use -try for pageitem, as pageitem might not exist (in main-db) 
  $db exec2 "create index if not exists ix_pageitem_1 on pageitem (scriptrun_id)" -try
  $db exec2 "create index if not exists ix_pageitem_2 on pageitem (page_id)" -try
  $db exec2 "create unique index if not exists ix_scriptrun_1 on scriptrun(slot_id,datetime)"
}

proc read_script_pages {db} {
  global dct_page_type
  foreach row [$db query "select scriptname, page_seq, page_type from script_pages"] {
    dict set dct_page_type [:scriptname $row] [:page_seq $row] [:page_type $row]        
  }
}

proc det_page_type {scriptname page_seq} {
  global dct_page_type
  if {[dict exists $dct_page_type $scriptname $page_seq]} {
    dict get $dct_page_type $scriptname $page_seq
  } else {
    return "<none>" 
  }
}


# handle each file in a DB trans, not a huge trans for all files.
proc handle_files {root_dir db dbmain} {
  log info "Start reading"
  handle_dir_rec $root_dir "*.json" [list warn_error read_json_file $db $dbmain]
  log info "Finished reading"
}

proc read_json_file {db dbmain filename root_dir} {
  if {[file tail [file dirname $filename]] == "read"} {
    # log info "ALready read with check on dirname/tail"
    # breakpoint
    # already in 'read' subdir, don't read again.
    return 
  }
  if {[regexp {/read/} $filename]} {
    log info "Already read with check on regexp (should not happen)"
    breakpoint
    # already in 'read' subdir, don't read again.
    return 
  }
  read_json_file_db $db $filename $root_dir 1
  if {$dbmain != ""} {
    read_json_file_db $dbmain $filename $root_dir 0
  }
  move_read $filename
}

proc move_read {filename} {
  global dargv 
  if {[:moveread $dargv]} {
    set to_file [file join [file dirname $filename] read [file tail $filename]]
    log debug "Move $filename => $to_file"
    file mkdir [file dirname $to_file]
    if {[file exists $to_file]} {
      log warn "Target file already exists, should not happen (anymore), deleting duplicate"
      file delete $filename
    } else {
      file rename $filename $to_file
    }
  }
}

proc read_json_file_db {db filename root_dir {pageitem 1}} {
  global cr_handler
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
    # @todo possibly add check if json just contains error message like invalid slotid list.
    
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
        dict set dct date_cet [det_date_cet [:datetime $dct]]
        dict set dct provider [det_provider [:target_id $dct]]
        set pages [concat [:wxn_page $run] [:txnPages $run]]
        
        # @todo param pages as name here, to prevent copying large objects, also do in other places?
        # @todo det_task_succeed has a bug: does not set to 0 when it should, for CBF-CN-HX6921-2013-09-02--13-00.json
        dict set dct task_succeed_calc [det_task_succeed_calc [:task_succeed $dct] pages]
        set scriptrun_id [$db insert scriptrun $dct 1]
        $cr_handler init
        $cr_handler set_scriptrun dct $scriptrun_id
        set dct_details [get_details $run]
        foreach page $pages {
          handle_page $db $scriptrun_id $page $dct_details $pageitem [:scriptname $dct] [:datetime $dct]
        }
        set dct_checkrun [$cr_handler get_record]
        # @todo nog even niet in productie.
        if {1} {
          $db insert checkrun $dct_checkrun
        }
      }
    }
  }
}

proc det_task_succeed_calc {task_succeed pages_name} {
  upvar $pages_name pages
  # breakpoint
  # @note tested with values of task_succeed like 0, 1, 2, "", "abc" and {}, this works.
  if {($task_succeed == 0) || ($task_succeed == 1)} {
    return $task_succeed
  } else {
    set found_error 0
    foreach p $pages {
      if {[:error_code [:txnPageStatus $p]] != ""} {
        set found_error 1 
      }
      if {[:error_code [:wxn_page_status $p]] != ""} {
        set found_error 1 
      }
    }
    if {$found_error} {
      return 0
    } else {
      return 1
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

proc handle_page {db scriptrun_id page dct_details pageitem scriptname datetime} {
  global dargv cr_handler
  set page_main [dict_get_multi -withname $page page_seq wxn_page_object wxn_page_performance wxn_page_status \
    txnPagePerformance txnPageObject txnPageStatus]
  set dctp [dict_flat $page_main {page_seq connect_delta delta_msec dns_lookup_msec first_packet_delta new_connection \
    remain_packets_delta request_delta ssl_handshake_delta start_msec system_delta \
    element_count page_bytes redir_count redir_delta \
    content_errors error_code page_succeed \
    bandwidth_kbsec browser_errors connection_count cookie_count custom_component_1_msec 
    custom_component_2_msec custom_component_3_msec delta_user_msec dom_complete_msec 
    dom_content_load_time dom_interactive_msec dom_load_time dom_unload_time domain_count 
    estimated_cache_delta_msec first_byte_msec first_paint_msec full_screen_msec time_to_interactive_page}]
  # @todo find out what page.start_msec means.
  dict set dctp scriptrun_id $scriptrun_id
  dict set dctp scriptname $scriptname
  dict set dctp ts_cet [det_ts_cet $datetime]
  dict set dctp date_cet [det_date_cet $datetime]
  set page_type [det_page_type $scriptname [:page_seq $dctp]]
  dict set dctp page_type $page_type
  
  set page_id [$db insert page $dctp 1]
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
      # set dcti [dict_flat2 $elt wxn_detail_performance wxn_detail_status]
      set dcti [dict_flat $elt {resource_id error_code connect_delta dns_delta element_delta \
        first_packet_delta remain_packets_delta request_delta \
        ssl_handshake_delta start_msec system_delta}]
      dict set dcti scriptrun_id $scriptrun_id
      dict set dcti page_id $page_id
      # set dcti2 [dict merge $dcti $ar_detail([:resource_id $dcti])]
      # set dcti_detail [dict get $dcti_details [:resource_id $dcti]]
      if {$prev_id == [:resource_id $dcti]} {
        incr given_id
      } else {
        set prev_id [:resource_id $dcti]
        set given_id [:resource_id $dcti]
      }
      set dcti_detail [dict get $dct_details $given_id]
      set dcti2 [dict merge $dcti $dcti_detail]
      dict set dcti2 extension [det_extension [:url $dcti2]]
      set domain [det_domain [:url $dcti2]]
      dict set dcti2 domain $domain
      dict set dcti2 topdomain [det_topdomain $domain]
      dict set dcti2 scriptname $scriptname
      dict set dcti2 ts_cet [det_ts_cet $datetime]
      dict set dcti2 date_cet [det_date_cet $datetime]
      dict set dcti2 page_seq [:page_seq $dctp]
      dict set dcti2 page_type $page_type
      dict set dcti2 urlnoparams [det_urlnoparams [:url $dcti2]]
      
      # breakpoint ; # page_seq not yet filled.
      $db insert pageitem $dcti2
      $cr_handler add_pageitem dcti2
    }
  }
  # MyPhilips structure with txnPageDetails looks a bit different, first handle seperately.
  if {0} {
    try_eval {
      set details [:txnPageDetails $page]
      if {$details != "null"} {
        handle_element $db $scriptrun_id $page_id [:txnBasePage $details] 1 $scriptname $datetime [:page_seq $dct]
        foreach elt [:txnPageElement $details] {
          handle_element $db $scriptrun_id $page_id $elt 0 $scriptname $datetime [:page_seq $dct]
        }
      }
    } {
      if {[:debug $dargv]} {
        log warn "$errorResult $errorCode $errorInfo, debug/breakpoint"
        breakpoint  
      } else {
        log warn "$errorResult $errorCode $errorInfo, continuing"
      }
    }
  }
  # 28-9-2013 If below fails 'in production', it should also stop.
  # @todo nanny.tcl process: read exit-code, based on this determine whether to continue/restart.
  set details [:txnPageDetails $page]
  if {$details != "null"} {
    handle_element $db $scriptrun_id $page_id [:txnBasePage $details] 1 $scriptname $datetime [:page_seq $dctp] $page_type
    foreach elt [:txnPageElement $details] {
      handle_element $db $scriptrun_id $page_id $elt 0 $scriptname $datetime [:page_seq $dctp] $page_type
    }
  }
  
}

proc handle_element {db scriptrun_id page_id elt basepage scriptname datetime page_seq page_type} {
  global cr_handler
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
  # dict set dct domain [det_domain $url]
  set domain [det_domain $url]
  dict set dct domain $domain
  dict set dct topdomain [det_topdomain $domain]
  dict set dct scriptname $scriptname
  dict set dct ts_cet [det_ts_cet $datetime]
  dict set dct date_cet [det_date_cet $datetime]
  dict set dct page_seq $page_seq
  dict set dct page_type $page_type
  dict set dct urlnoparams [det_urlnoparams $url]
  $db insert pageitem $dct
  $cr_handler add_pageitem dct
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

# @param datetime 2013-JUL-18 00:19:12 
proc det_date_cet {datetime} {
  clock format [clock scan $datetime -format "%Y-%b-%d %H:%M:%S" -gmt 1] -format "%Y-%m-%d"
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
proc warn_error {proc_name args} {
  global dargv
  try_eval {
    $proc_name {*}$args
  } {
    # log warn "$errorResult $errorCode $errorInfo, continuing"
    log_error "continuing..."
    if {[:debug $dargv]} {
      # development mode.
      error $errorResult $errorCode $errorInfo
      breakpoint
      exit
    } else {
      # production, vooral-doorgaan mode 
    }
  }  
}

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

