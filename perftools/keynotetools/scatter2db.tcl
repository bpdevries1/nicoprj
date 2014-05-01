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

set log [::ndv::CLogger::new_logger [file tail [info script]] info]
$log set_file "[file tail [info script]]-[clock format [clock seconds] -format "%Y-%m-%d--%H-%M-%S"].log"

# if downloaded file has errors, move it to error-dir and mark in database so it can be downloaded again.
ndv::source_once download-check.tcl
ndv::source_once libkeynote.tcl

ndv::source_once libpostproclogs.tcl libmigrations.tcl kn-migrations.tcl checkrun-handler.tcl libextraprocessing.tcl libextra.tcl physloc_finder.tcl akheader_finder.tcl

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
    {actions.arg "" "List of actions to do in post processing (comma separated: dailystats,gt3,maxitem,slowitem,topic,aggr_specific,aggrsub,domain_ip,removeold,combinereport,analyze,vacuum)"}
    {maxitem.arg "20" "Number of maxitems to determine"}
    {minsec.arg "0.2" "Only put items > minsec in slowitem table"}
    {pattern.arg "*" "Just handle subdirs that have pattern"}
    {checkfile.arg "" "Checkfile for nanny process"}
    {loglevel.arg "info" "Log level (debug, info, warn)"}
    {debug "Run in debug mode, stop when an error occurs"}
  }
  set usage ": [file tail [info script]] \[options] :"
  # set dargv [::cmdline::getoptions argv $options $usage]
  set dargv [getoptions argv $options $usage]
  log set_log_level [:loglevel $dargv]
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
      wait_until_next_hour_and_half [:checkfile $dargv]
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
proc wait_until_next_hour_and_half {checkfile} {
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
    update_checkfile $checkfile
    # after 5000
  }
}

proc scatter2db_main {dargv} {
  global cr_handler dl_check phloc_finder akh_finder
  set root_dir [from_cygwin [:dir $dargv]]  
  set res "Ok"
  set cr_handler [checkrun_handler new]
  set dl_check [DownloadCheck new $root_dir]
  set phloc_finder [physloc_finder new]
  set akh_finder [akheader_finder new]
  set checkfile [:checkfile $dargv]
  if {[:justdir $dargv]} {
    # 6-9-2013 also handle current-dir, if script is called with one subdir as param
    # 16-9-2013 not correct, this would create huge keynotelogs.db file in the root when called normally.
    # so use cmdline param if we want this.
    # wel checken dat deze dir geen subdirs heeft (of alleen een 'read' subdir)
    if {[llength [glob -nocomplain -directory $root_dir -type d *]] > 1} {
      log error "Cannot use -justdir when dir has subdirs, exiting.."
      exit 1
    }
    set res [scatter2db_subdir $dargv $root_dir]
  } else {
    foreach subdir [lsort [glob -nocomplain -directory $root_dir -type d [:pattern $dargv]]] {
      if {[ignore_subdir $subdir]} {
        log info "Ignore subdir: $subdir (for test!)"
      } else {
        set res [scatter2db_subdir $dargv $subdir]
      }
      update_checkfile $checkfile
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

proc scatter2db_subdir {dargv subdir} {
  global cr_handler last_read_date
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
    add_daily_stats2 $db 1
    # set initial db version
  } else {
    log info "Existing db: $db_name, don't create tables"
    add_daily_stats2 $db 0 ; # to define tables for insert-statements.
  }
  migrate_db $db $existing_db
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
  
  # @note [global] last_read_date contains minimum date of currently read json files. Give this one to update_daily_stats.
  set last_read_date [clock format [clock seconds] -format "%Y-%m-%d"]
  handle_files $subdir $db
  update_checkfile [:checkfile $dargv]
  reset_daily_status_db $db $last_read_date
  $db close
  log info "Created/updated db $db_name, size is now [file size $db_name]"
  extraproc_subdir $dargv $subdir
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

  if {$pageitem} {
    $db add_tabledef pageitem {id} {scriptname ts_cet date_cet scriptrun_id page_seq page_type page_id content_type resource_id \
      scontent_type url \
      extension domain topdomain urlnoparams \
      error_code connect_delta dns_delta element_delta first_packet_delta \
      remain_packets_delta request_delta \
      ssl_handshake_delta start_msec system_delta basepage record_seq \
      detail_component_1_msec detail_component_2_msec detail_component_3_msec \
      ip_address element_cached msmt_conn_id conn_string_text request_bytes content_bytes \
      header_bytes object_text header_code custom_object_trend status_code aptimized \
      ip_oct3 phys_loc phys_loc_type {is_dynamic_url int} status_code_type {disable_domain int} akh_cache_control akh_pragma akh_x_check_cacheable ahk_x_cache ahk_expiry akh_x_cache akh_expiry}
  }
  
  # [2013-11-04 12:31:24] add new tables also for new databases
  add_daily_status $db
  $db add_tabledef aggr_sub {id} {date_cet scriptname {page_seq int} {npages int} keytype keyvalue \
    {avg_time_sec real} {avg_nkbytes real} {avg_nitems real}}

  # note 12-11-2013 if tables are added here, they should possibly also be added in libextraprocessing.    
}

proc create_indexes {db} {
  $db exec2 "create index if not exists ix_page_1 on page (scriptrun_id)"
  # use -try for pageitem, as pageitem might not exist (in main-db) 
  $db exec2 "create index if not exists ix_pageitem_1 on pageitem (scriptrun_id)" -try
  $db exec2 "create index if not exists ix_pageitem_2 on pageitem (page_id)" -try
  $db exec2 "create unique index if not exists ix_scriptrun_1 on scriptrun(slot_id,datetime)"

  # [2013-10-29 17:03:08] added for daily stats:
  $db exec2 "create index if not exists ix_run_datecet on scriptrun(date_cet)" -log -try
  $db exec2 "create index if not exists ix_page_datecet on page(date_cet)" -log -try
  
  # 24-12-2013 used for determining latest date read and earliest possible daily aggregate/combine processing.
  $db exec2 "create index if not exists ix_logfile_1 on logfile (filename)" -log -try
}

proc read_script_pages {db} {
  global dct_page_type
  foreach row [$db query "select scriptname, page_seq, page_type from script_pages"] {
    dict set dct_page_type [:scriptname $row] [:page_seq $row] [:page_type $row]        
  }
}

# @todo new way to determine page_type, based on basepage_url
# so try new way, by finding the basepage items. Should be only one.
proc det_page_type {scriptname page_seq page_name} {
  global dct_page_type ; # 27-1-2014 keep this var for now, for fallback scenario.
  # use upvar, so call by ref can be used, should be quicker.
  upvar $page_name page
  
  set t [lindex [:txnDetailObject [:txnBasePage [:txnPageDetails $page]]] 0]
  set url "[:conn_string_text $t][:object_text $t]"
  
  # would like clojure threading operator:
  # set obj_txt [-> $page :txnPageDetails :txnBasePage :txnDetailObject :0 :object_text]
  # where :0 == [lindex $x 0]
  # set res [objtxt2pagetype $obj_txt]
  set res [url2pagetype $url]
  return $res
}

# /c/catalog_selector.jsp wordt mss nooit gebruikt, maar wel zo ingetypt, dus even laten staan.
# @todo onderscheid tussen ATG en CQ5 pages maken. Ofwel in de pagetype, ofwel een los veld, eigenlijk beter.
set pagetype_regexps {{/c/$} landing 
                      {/cat/$} category 
                      {/prd/$} detail 
                      {\?t=support$} support 
                      {/c/locators} dealerloc 
                      {featureselector} decision 
                      {wtb_widget} wheretobuy 
                      {\.livecom.net/} livecom 
                      {/5g/hdl/} livecom 
                      {ace3\.adoftheyear\.com} adoftheyear 
                      {/philips_p11026/cookie.php} adoftheyear 
                      {/c/catalog_selector.jsp} catalogselector
                      {/c/catalog/catalog_selector.jsp} catalogselector}

# also possible to use this one within SQLite queries.
proc objtxt2pagetype {obj_txt} {
  global pagetype_regexps
  foreach {re pagetype} $pagetype_regexps {
    if {[regexp -nocase -- $re $obj_txt]} {
      return $pagetype
    }
  }
  return ""
}

# @note should use whole URL to determine pagetype, also for errors.
proc url2pagetype {url} {
  global pagetype_regexps
  foreach {re pagetype} $pagetype_regexps {
    if {[regexp -nocase -- $re $url]} {
      return $pagetype
    }
  }
  return ""
}

# handle each file in a DB trans, not a huge trans for all files.
proc handle_files {sub_dir db} {
  log info "Start reading"
  # @note 27-12-2013 handle_dir_rec sorts files before handling, so this should be ok, that oldest files will be read first.
  # handle_dir_rec $root_dir "*.json" [list warn_error read_json_file $db]
  # 7-1-2014 handle_dir_rec handles dir recursive, as designed. Just because read and error dirs are subdirs, this is not so good here, just need 1 level.
  foreach filename [glob -nocomplain -directory $sub_dir -type f *.json] {
    warn_error read_json_file $db $filename $sub_dir
  }
  log info "Finished reading"
}

proc read_json_file {db filename root_dir} {
  global dl_check
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
  try_eval {
    read_json_file_db $db $filename $root_dir 1
    move_read $filename
  } {
    log warn "Something went wrong while reading: $filename, moving to error-dir and mark so it can be downloaded again"
    move_read_error $filename
    $dl_check set_read $filename "error"    
  }
  
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

proc move_read_error {filename} {
  set to_file [file join [file dirname $filename] error [file tail $filename]]
  log debug "Move $filename => $to_file"
  file mkdir [file dirname $to_file]
  if {[file exists $to_file]} {
    set to_file "$to_file.[expr rand()]"
    log warn "Target file already exists, add random number to filename: $to_file"
  } 
  file rename $filename $to_file
}

proc read_json_file_db {db filename root_dir {pageitem 1}} {
  global cr_handler last_read_date
  if {[is_read $db $filename]} {
    # log info "Already read, ignoring: $filename"
    return
  }
  log info "Reading $filename"
  $db in_trans {    
    set logfile_id [$db insert logfile [dict create path $filename filename [file tail $filename] filesize [file size $filename]] 1]
    set text [read_file $filename]
    if {[regexp {Bad Request} $text]} {
      log warn "Bad Request in result json, continue"
    } elseif {[string length $text] < 500} {
      log debug "Json file too small, continue"
    } else {
      set json [json::json2dict $text]
      # @todo possibly add check if json just contains error message like invalid slotid list.
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
          # 24-12-2013 set delta_user_msec if empty, used in a lot of places.
          if {[:delta_user_msec $dct] == "<none>"} {
            dict set dct delta_user_msec [:delta_msec $dct]
          }
          dict set dct logfile_id $logfile_id
          dict set dct scriptname [det_scriptname [:slot_id $dct] $filename]
          dict set dct ts_utc [det_ts_utc [:datetime $dct]]
          dict set dct ts_cet [det_ts_cet [:datetime $dct]]
          set date_cet [det_date_cet [:datetime $dct]]
          dict set dct date_cet $date_cet
          if {$date_cet < $last_read_date} {
            set last_read_date $date_cet 
          }
          dict set dct provider [det_provider [:target_id $dct]]
          set pages [concat [:wxn_page $run] [:txnPages $run]]
          
          # @todo param pages as name here, to prevent copying large objects, also do in other places?
          # @todo det_task_succeed has a bug: does not set to 0 when it should, for CBF-CN-HX6921-2013-09-02--13-00.json
          dict set dct task_succeed_calc [det_task_succeed_calc [:task_succeed $dct] pages]
          # breakpoint
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
  global dargv cr_handler phloc_finder akh_finder
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
  # 24-12-2013 set delta_user_msec if empty, used in a lot of places.
  if {[:delta_user_msec $dctp] == "<none>"} {
    dict set dctp delta_user_msec [:delta_msec $dctp]
  }

  dict set dctp scriptrun_id $scriptrun_id
  dict set dctp scriptname $scriptname
  dict set dctp ts_cet [det_ts_cet $datetime]
  dict set dctp date_cet [det_date_cet $datetime]
  set page_type [det_page_type $scriptname [:page_seq $dctp] page]
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
      try_eval {
        set dcti_detail [dict get $dct_details $given_id]
      } {
        set dcti_detail [dict create] 
      }
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
      dict set dcti2 aptimized [det_aptimized [:url $dcti2]]
      dict set dcti2 ip_oct3 [det_ip_oct3 [:ip_address $dcti2]]
      dict set dcti2 status_code_type [det_status_code_type [:status_code $dcti2] [:error_code $dcti2]]
      dict set dcti2 disable_domain [det_disable_domain $domain]
      dict set dcti2 is_dynamic_url [det_is_dynamic_url [:url $dcti2]]
      set phloc_res [$phloc_finder find $scriptname [:ip_oct3 $dcti2]]
      dict set dcti2 phys_loc [:0 $phloc_res]
      dict set dcti2 phys_loc_type [:1 $phloc_res]
      
      set akh_res [$akh_finder find $scriptname [:urlnoparams $dcti2]]
      dict for {k v} $akh_res {
        dict set dcti2 $k $v
      }  
      
      # breakpoint ; # page_seq not yet filled.
      $db insert pageitem $dcti2
      $cr_handler add_pageitem dcti2
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
    # 4-2-2014 redirects can also occur, in seperate element:
    # @todo 4-2-2014 maybe mark those elements as basepage (too), but this occurs mainly when there is an error.
    foreach elt [:txnRedirect $details] {
      handle_element $db $scriptrun_id $page_id $elt 0 $scriptname $datetime [:page_seq $dctp] $page_type
    }
    
  }
  
}

proc handle_element {db scriptrun_id page_id elt basepage scriptname datetime page_seq page_type} {
  global cr_handler phloc_finder akh_finder
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
  dict set dct aptimized [det_aptimized $url]
  dict set dct ip_oct3 [det_ip_oct3 [:ip_address $dct]]
  dict set dct status_code_type [det_status_code_type [:status_code $dct] [:error_code $dct]]
  dict set dct disable_domain [det_disable_domain $domain]
  dict set dct is_dynamic_url [det_is_dynamic_url $url]
  set phloc_res [$phloc_finder find $scriptname [:ip_oct3 $dct]]
  dict set dct phys_loc [:0 $phloc_res]
  dict set dct phys_loc_type [:1 $phloc_res]
  set akh_res [$akh_finder find $scriptname [:urlnoparams $dct]]
  dict for {k v} $akh_res {
    dict set dct $k $v
  }  
  $db insert pageitem $dct
  $cr_handler add_pageitem dct ; # give dct_name, not dct contents (should save memory, not copying data)
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
# @todo deze denk ik al tijd niet meer laten lopen, hoeft nu ook niet meer vanwege Akamai redirect change.
proc post_process_old {db} {
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

proc det_aptimized {url} {
  regexp {aptimized} $url
}

proc det_ip_oct3 {ip_address} {
  join [lrange [split $ip_address "."] 0 2] "."
}

proc det_status_code_type {status_code error_code} {
  if {$status_code == ""} {
    set status_code $error_code
  }
  if {$status_code == ""} {
    return "empty"
  }
  if {[regexp {^2..$} $status_code]} {
    return "ok"
  }
  if {[regexp {^3..$} $status_code]} {
    if {$status_code == "304"} {
      return "notmodified"
    } else {
      # especially those are important, could/should be optimised.
      return "redirect"
    }
  }
  if {[regexp {^4..$} $status_code]} {
    return "clienterror"
  }
  if {[regexp {^5..$} $status_code]} {
    return "servererror"
  }
  return "other"
}

proc det_disable_domain {domain} {
  set regexps {.*\.en25\.com$ .*\.eloqua\.com$ .*\.livecom.net$ metrixlab.*\.customers.luna.net$ ^r.turn.com$  \.adnxs.com$ ^ace3.adoftheyear.com$ ^philips.112.2o7.net$}
  foreach re $regexps {
    if {[regexp $re $domain]} {
      # puts "Matched: $re"
      return 1
    }
  }
  return 0
}

proc det_is_dynamic_url {url} {
  # if omniture, set to 0, should be disabled anyway.
  if {[regexp {philips.112.2o7.net} $url]} {
    return 0
  }
  if {[regexp {jsessionid} $url]} {
    # jsessionid is part of the X-Cache-Key (in Akamai) and X-True-Cache-Key.
    return 1
  }
  if {[regexp {\?(.*)$} $url z params]} {
    foreach param [split $params "&"] {
      if {[regexp {^([^=]+)=(.*)$} $param z nm val]} {
        if {[lsearch {_ accessToken _requestid} $nm] >= 0} {
          return 1
        }
        if {[regexp {1[3-9]\d{8}} $val]} {
          return 1
        }
      }
    }
  }
  return 0
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

# memoize function. Use by calling memoize as first statement in function.
# source: http://wiki.tcl.tk/10779
# @note maybe would prefer clojure way: first define function, then do: (def f-mem (memoize f)), but this would need 2 functions.
proc memoize {args} {
  global memo
  set cmd [info level -1]
  set d [info level]
  if {$d > 2} {
    set u2 [info level -2]
    if {[lindex $u2 0] == "memoize"} {
            return
    }
  }
  if {[info exists memo($cmd)]} {
    set val $memo($cmd)
  } else {
    set val [eval $cmd]
    set memo($cmd) $val
  }
  return -code return $val
}

# example:
proc fibonacci-memo {x} {
  memoize
  if {$x < 3} {return 1}
  return [expr [fibonacci-memo [expr $x - 1]] + [fibonacci-memo [expr $x - 2]]]
}
  

main $argv

