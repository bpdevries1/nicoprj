# kn-migrations.tcl - diff-scripts to put keynote db's in right version

package require ndv
ndv::source_once libmigrations.tcl
ndv::source_once libkeynote.tcl

migrate_proc add_fk_indexes "Add foreign key indexes" {
  $db exec2 "create index if not exists ix_page_1 on page (scriptrun_id)"
  $db exec2 "create index if not exists ix_pageitem_1 on pageitem (scriptrun_id)" -try
  $db exec2 "create index if not exists ix_pageitem_2 on pageitem (page_id)" -try
}

migrate_proc add_key_fields "Add key fields: date_cet, ts_cet, scriptname, page_seq" {
  #try should not be necessary, but is here, as fields have already been added in some DB's
  $db exec2 "alter table scriptrun add date_cet" -try
  $db exec2 "alter table page add scriptname" -try
  $db exec2 "alter table page add ts_cet" -try
  $db exec2 "alter table page add date_cet" -try
  $db exec2 "alter table pageitem add scriptname" -try
  $db exec2 "alter table pageitem add ts_cet" -try
  $db exec2 "alter table pageitem add date_cet" -try
  $db exec2 "alter table pageitem add page_seq" -try
}

migrate_proc fill_key_fields "Fill key fields: date_cet, ts_cet, scriptname, page_seq" {
  $db exec2 "update scriptrun set date_cet = strftime('%Y-%m-%d', ts_cet) where date_cet is null" -log
  $db exec2 "update page
              set scriptname = (select r.scriptname from scriptrun r where r.id = page.scriptrun_id),
                  ts_cet = (select r.ts_cet from scriptrun r where r.id = page.scriptrun_id),
                  date_cet = (select r.date_cet from scriptrun r where r.id = page.scriptrun_id)
              where page.scriptname is null" -log
  # pageitem might not exist (maindb)
  $db exec2 "update pageitem
              set scriptname = (select p.scriptname from page p where p.id = pageitem.page_id),
                  ts_cet = (select p.ts_cet from page p where p.id = pageitem.page_id),
                  date_cet = (select p.date_cet from page p where p.id = pageitem.page_id),
                  page_seq = (select p.page_seq from page p where p.id = pageitem.page_id)
              where pageitem.scriptname is null" -try
}

# @note need migrate_kn_create_view_rpi as well as migrate_proc, as first is also called directly for a new DB.
proc migrate_kn_create_view_rpi {db} {
  $db exec2 "create view rpi as
             select r.*, p.*, i.*
             from scriptrun r 
             join page p on p.scriptrun_id = r.id
             join pageitem i on i.page_id = p.id" -try
}

migrate_proc create_view_rpi "Create view rpi" {
  migrate_kn_create_view_rpi $db
}

# copy table script_pages from orig location
# @note maybe only copy rows that are for this script. But would need a way to pass params then.
#       or in this case use $db get_dbname and look at the path.
proc copy_script_pages {db} {
  # set src_name "c:/projecten/Philips/script-pages/script-pages.db"
  set src_name [det_src_script_pages]
  if {![file exists $src_name]} {
    # error "Src db for script_pages does not exist" 
  	# 7-1-2014 no error now, want to have another look at page-names based on slot metadata in.
	  # the file does not exist at the PC/linux location.
	  log warn "Src db for script_pages does not exist: $src_name" 
  } else {
    $db exec "attach database '$src_name' as fromDB"
    set table "script_pages"
    # @note use main.$table, otherwise source might be dropped.
    $db exec "drop table if exists main.$table"
    $db exec_try "create table if not exists $table as select * from fromDB.$table"
    $db exec "detach fromDB"
  }
}

proc det_src_script_pages {} {
  global tcl_platform
  if {$tcl_platform(platform) == "windows"} {
    return "c:/projecten/Philips/script-pages/script-pages.db"
  } else {
    return [file normalize "~/Ymor/Philips/script-pages/script-pages.db"]
  }
}

# @note if orig table script_pages changes, just move this def as the latest to do the
# migration again.
migrate_proc copy_script_pages "copy table script_pages" {
  copy_script_pages $db
}

# @note if orig table script_pages changes, just move this def as the latest to do the
# migration again.
migrate_proc copy_script_pages_1a "copy table script_pages" {
  copy_script_pages $db
}

migrate_proc add_fill_page_type "Add and fill page type for page and item" {
  $db exec2 "alter table page add page_type" -try
  $db exec2 "alter table pageitem add page_type" -try
  set res [$db query "select sp.page_type from script_pages sp join page p on p.scriptname = sp.scriptname limit 1"]
  if {[llength $res] > 0} {
    log debug "Found scriptname in script_pages: fill page_type"
    # integer-fields remain difficult, need 1* again here.
    foreach table {page pageitem} {
      $db exec2 "update $table
                set page_type = (
                  select sp.page_type
                  from script_pages sp
                  where sp.scriptname = $table.scriptname
                  and 1*sp.page_seq = 1*$table.page_seq
                )
                where $table.page_type is null" -log
    }
  } else {
    log debug "Did not find scriptname in script_pages: skip filling page_type" 
  }
}

proc set_task_succeed_calc {db} {
  $db exec2 "update scriptrun
             set task_succeed_calc = task_succeed
             where task_succeed_calc is null
             and task_succeed in ('0','1', 0, 1)" -log 
  $db exec2 "update scriptrun
                set task_succeed_calc = 0
                where task_succeed_calc is null
                and id in (
                  select scriptrun_id
                  from page p
                  where p.error_code <> ''
                )" -log
  $db exec2 "update scriptrun
                set task_succeed_calc = 1
                where task_succeed_calc is null" -log
}

# @note task_succeed is an existing field.
# @todo still big in determining succeed for new items, so not this one for now.
migrate_proc add_fill_task_succeed "Fill task_succeed field" {
  $db exec2 "alter table scriptrun add task_succeed_calc integer" -log -try
  set_task_succeed_calc $db
}

# add a field topdomain to pageitem, fill it with topdomain based on domain.
# secure.philips.com -> philips.com
# crsc.philips.com.cn -> phlips.com.cn
# crsc.philips.co.uk -> philips.co.uk
# @note this one should only take (a lot of) time if topdomain is null.
# @note only if -clean is in cmdline, field will be cleared first.
# @note also used in migrations and scatter2db.
proc add_topdomain {db clean {checkfirst 1}} {
  [$db get_db_handle] function det_topdomain det_topdomain
  if {$clean} {
    log info "Clean field topdomain first before filling again"
    $db exec "update pageitem set topdomain = null" 
  }
  # @note update where is null still takes quite some time.
  # @note maybe keep list of actions (and time) in the DB, and only update
  #       records after this timestamp
  # @note for now: check if we can find one item with topdomain filled,
  #       if so, assume all are filled (as it is atomic action).
  # @note could also add an index on topdomain.
  if {$checkfirst} {
    set res [$db query "select id from pageitem where topdomain is not null limit 1"]
  } else {
    # don't check, do update directly
    set res {}    
  }
  if {[llength $res] > 0} {
    log info "Already one topdomain field filled, assume all are filled" 
  } else {
    log info "Not one topdomain filled, fill all now"
    set query "update pageitem
               set topdomain = det_topdomain(domain)
               where topdomain is null"
    $db exec2 $query -log
    log info "Filled all topdomains"
  }
}

# @note als je dezen even niet wilt (want ze duren lang), dan gewoon uitcommenten en scatter2db opnieuw starten
#       of "if 0" omheen zetten.
migrate_proc add_fill_topdomain "Add and fill topdomain field" {
  $db exec2 "alter table pageitem add topdomain" -log -try
  add_topdomain $db 0 0 ; # don't clean first, new field. Also don't check first.
}

proc det_urlnoparams {url} {
  # add ; or ? to the returned string.
  if {[regexp {^([^\? \;]*.)} $url z res]} {
    return $res 
  } else {
    return $url 
  }
}

# @note fill_urlnoparams is really slow on DB's (could take 30 minutes+ per DB), so try this one.
# @note add_topdomain is similar, takes 5 minutes (also a bit long).
proc fill_urlnoparams2 {db} {
  [$db get_db_handle] function det_urlnoparams det_urlnoparams

  set query "update pageitem
             set urlnoparams = det_urlnoparams(url)
             where urlnoparams is null"
  $db exec2 $query -log
}

migrate_proc add_fill_urlnoparams "Add and fill urlnoparams field" {
  $db exec2 "alter table pageitem add urlnoparams" -log -try
  fill_urlnoparams2 $db
}

# add checkrun, first define helper procs
proc add_checkrun {db} {
  set has_fields {store_page wrb_jsp results_jsp error_jsp a_png error_code youtube addthis \
                  support_nav_error home_jsp prodreg}
  set db_has_fields [lmap el $has_fields {has_db $el}]
  set dbdef_has_fields [lmap el $has_fields {has_dbdef $el}]
  set query "create table if not exists checkrun (scriptrun_id integer, ts_cet, task_succeed integer, real_succeed integer, [join $dbdef_has_fields ", "])"
  $db exec2 $query -log
  $db exec2 "create index if not exists ix_checkrun_1 on checkrun (scriptrun_id)" -log
  return $db_has_fields
}

# @todo create and filled based on Dealer Locator code, still have to do:
# based on Myphilips and generic
# filling new records as they are being read.
migrate_proc add_fill_checkrun "Add and fill checkrun table" {
  log debug "add_fill_checkrun: start"
  set db_has_fields [add_checkrun $db]
  log debug "add_fill_checkrun: has_fields: $db_has_fields"
  # breakpoint
  set query "insert into checkrun (scriptrun_id, ts_cet, task_succeed, real_succeed, [join $db_has_fields ", "])
            select id, ts_cet, task_succeed_calc, 0, [join [repeat [llength $db_has_fields] "0"] ", "]
            from scriptrun"
  log debug "add_fill_checkrun: insert-query: $query"
  $db exec2 $query -log          
  log debug "add_fill_checkrun: inserted checkrun records"
  # @todo maybe check type of script and which fields need to be filled.
  # check for the existence of the three jsp pages of store locator.
  # if there is something with retail_store_locator in this script, then do the check for A.png.
  update_checkrun_url_like $db has_store_page "%retail_store_locator%"            
            
  update_checkrun_url_like $db has_wrb_jsp "%/wrb_retail_store_locator_results.jsp%"            
  update_checkrun_url_like $db has_results_jsp "%/retail_store_locator_results.jsp%"            
  update_checkrun_url_like $db has_error_jsp "%/retail_store_locator.jsp%"            
  update_checkrun_url_like $db has_a_png "%/A.png%"            

  # for CN, should not contain youtube and addthis
  update_checkrun_url_like $db has_youtube "%youtube%"            
  update_checkrun_url_like $db has_addthis "%addthis%"            
  
  $db exec2 "update checkrun set has_home_jsp = 1 where scriptrun_id in (
              select distinct i.scriptrun_id
              from pageitem i
              where 1*i.page_seq = 2
              and i.url like '%home.jsp%'
              and i.domain != 'philips.112.2o7.net'
            )" -log

  $db exec2 "update checkrun set has_prodreg = 1 where scriptrun_id in (
              select distinct i.scriptrun_id
              from pageitem i
              where i.url like '%prodreg%'
              and i.domain like 'secure.philips%'
            )" -log
            
  # error 4006 is not serious and happens quite a lot: Cannot set WinInet status callback for synchronous sessions. Support for Java Applets download measurements
  # more domains are excluded, ip address is set to 0.0.0.0 or NA.
  # @todo check if runs do have an A.png, but also errors, and marked (real_succeed) as not successful.
  $db exec2 "update checkrun set has_error_code = 1 where scriptrun_id in (
              select distinct i.scriptrun_id
              from pageitem i
              where i.topdomain not in ('2o7.net', 'adoftheyear.com', 'livecom.net') 
              and i.error_code not in ('', '200', '4006')
              and i.ip_address not in ('0.0.0.0', 'NA')
            )" -log
  # nav to support page goes to something else
  if {0} {
    # @todo support_page error goed vullen, 26-9-2013 voor availability/Andre nog niet zo belangrijk
    # lijkt op fout op:                   and not i.url like '%t=support%'
    set support_page_seq [det_support_page_seq $db $dir]
    if {$support_page_seq == 0} {
      log warn "Support page seq not found, don't look for errors on this page" 
    } else {
      log info "Support page seq: $support_page_seq"
      # @todo look for nav error not t=support found in (complete!) URL.
      set query "update checkrun set has_support_nav_error = 1' 
                where scriptrun_id in (
                  select distinct i.scriptrun_id
                  from pageitem i join page p on p.id = i.page_id
                  where i.basepage = 1
                  and p.page_seq = $support_page_seq
                  and not i.url like '%t=support%'
                )"
      log debug "query: $query"              
      $db exec2 $query -log              
      log info "Look for support-page errors finished"
    }
  }
  $db exec2 "update checkrun set real_succeed = 1 
             where task_succeed = 1 and has_a_png = 1" -log
  # if this script has no retail store pages, then don't check for A.png.
  
  # @note onderstaande waarsch te kort door de bocht, dus nu niet.
  $db exec2 "update checkrun set real_succeed = 1 
             where task_succeed = 1 and has_store_page = 0" -log
  
  # @note vanuit MyPhilips:             
  $db exec2 "update checkrun set real_succeed = 1 
             where task_succeed = 1 and has_home_jsp = 1 and 
             has_error_code = 0 and has_prodreg = 0"
  log debug "add_fill_checkrun: finished"
  
} ; # end of migrate_proc add_fill_checkrun

# add checkrun, first define helper procs
# @todo dailystatus table also defined in extraprocessing.tcl
# @note old version, now use add_daily_stats2
proc add_daily_stats1 {db {create_tables 1}} {
  $db add_tabledef dailystatus {} {actiontype dateuntil_cet}
  $db add_tabledef dailystatuslog {} {ts_start_cet ts_end_cet datefrom_cet dateuntil_cet notes}
  $db add_tabledef aggr_run {id} {scriptname date_cet {total_time_sec real} {page_time_sec real} \
    {npages int} {avail real} {datacount int} {total_ttip_sec real} {page_ttip_sec real}}
  $db add_tabledef aggr_page {id} {scriptname date_cet {page_seq int} {avail real} \
    {page_time_sec real} {page_ttip_sec real} {datacount int}}
    
  if {$create_tables} {
    $db create_tables 0
  }
}

migrate_proc add_daily_status "No-op" {
  log info "No-op to continue with next, as some DB's have this status"  
}

# @todo create and filled based on Dealer Locator code, still have to do:
# based on Myphilips and generic
# filling new records as they are being read.
migrate_proc add_daily_stats "Add daily stats tables" {
  log debug "add_daily_stats: start"
  # set db_has_fields [add_checkrun $db]
  add_daily_stats1 $db 1
  log debug "add_daily_stats: finished"
  # breakpoint
}

migrate_proc add_indexes_date_cet "Add indexes for date_cet fields" {
  log info "Add indexes for date_cet fields"
  # set db_has_fields [add_checkrun $db]
  $db exec2 "create index if not exists ix_run_datecet on scriptrun(date_cet)" -log -try
  $db exec2 "create index if not exists ix_page_datecet on page(date_cet)" -log -try
}

migrate_proc dailystatus_add_column "Add column to dailystatus" {
  $db exec2 "alter table dailystatus add column actiontype" -try
  $db exec2 "update dailystatus set actiontype = 'general' where actiontype is null"
}

migrate_proc add_indexes_ts_cet "Add indexes for ts_cet fields" {
  log info "Add indexes for ts_cet fields"
  # set db_has_fields [add_checkrun $db]
  $db exec2 "create index if not exists ix_item_datecet on pageitem(date_cet)" -log -try
  
  $db exec2 "create index if not exists ix_run_tscet on scriptrun(ts_cet)" -log -try
  $db exec2 "create index if not exists ix_page_tscet on page(ts_cet)" -log -try
  $db exec2 "create index if not exists ix_item_tscet on pageitem(ts_cet)" -log -try
}

migrate_proc add_pageitem_gt3 "Add pageitem_gt3 table" {
  log info "Add pageitem_gt3 table"
  $db add_tabledef pageitem_gt3 {id} {scriptname ts_cet date_cet scriptrun_id page_seq page_type page_id content_type resource_id \
      scontent_type url \
      extension domain topdomain urlnoparams \
      error_code connect_delta dns_delta element_delta first_packet_delta \
      remain_packets_delta request_delta \
      ssl_handshake_delta start_msec system_delta basepage record_seq \
      detail_component_1_msec detail_component_2_msec detail_component_3_msec \
      ip_address element_cached msmt_conn_id conn_string_text request_bytes content_bytes \
      header_bytes object_text header_code custom_object_trend status_code aptimized}
  $db create_tables 0
}

proc add_daily_status {db {create_tables 0}} {
  $db add_tabledef dailystatus {} {actiontype dateuntil_cet}
  $db add_tabledef dailystatuslog {} {ts_start_cet ts_end_cet datefrom_cet dateuntil_cet notes}
  if {$create_tables} {
    $db create_tables 0
  }
}

proc add_daily_stats2 {db {create_tables 1}} {
  # @todo update field defs.
  $db add_tabledef aggr_run {id} {date_cet scriptname {avg_time_sec real} {avg_nkbytes real}
    {avg_nitems real} {datacount int} {avg_ttip_sec real} {avail real} {npages int}
    {page_time_sec real} {page_ttip_sec real}}
    
  $db add_tabledef aggr_page {id} {date_cet scriptname {page_seq int}   
    {avg_time_sec real} {avg_nkbytes real} {avg_nitems real} {datacount int}
    {avg_ttip_sec real} {avail real} page_type}
  
  # 24-12-2013 add 4 other tables for new databases: aggr_slowitem, pageitem_topic, domain_ip_time, aggr_specific
  $db add_tabledef aggr_slowitem {id} {date_cet scriptname {page_seq int} keytype keyvalue {seqnr int} \
    {avg_page_sec real} {avg_loadtime_sec real} {nitems int}} 
  
  # 4-2-2014 maak deze defs DRY, dus fielddefs 1x noemen, en opnemen bij 3 tabellen: pageitem, _topic en _gt3. _topic heeft extra veld 'topic'  
  $db add_tabledef pageitem_topic {id} {scriptname topic ts_cet date_cet scriptrun_id page_seq page_type page_id content_type resource_id \
      scontent_type url \
      extension domain topdomain urlnoparams \
      error_code connect_delta dns_delta element_delta first_packet_delta \
      remain_packets_delta request_delta \
      ssl_handshake_delta start_msec system_delta basepage record_seq \
      detail_component_1_msec detail_component_2_msec detail_component_3_msec \
      ip_address element_cached msmt_conn_id conn_string_text request_bytes content_bytes \
      header_bytes object_text header_code custom_object_trend status_code aptimized}

  # 26-1-2014 BUGFIX: added here for new DB's.
  $db add_tabledef pageitem_gt3 {id} {scriptname ts_cet date_cet scriptrun_id page_seq page_type page_id content_type resource_id \
      scontent_type url \
      extension domain topdomain urlnoparams \
      error_code connect_delta dns_delta element_delta first_packet_delta \
      remain_packets_delta request_delta \
      ssl_handshake_delta start_msec system_delta basepage record_seq \
      detail_component_1_msec detail_component_2_msec detail_component_3_msec \
      ip_address element_cached msmt_conn_id conn_string_text request_bytes content_bytes \
      header_bytes object_text header_code custom_object_trend status_code aptimized}
      
  $db add_tabledef domain_ip_time {id} {scriptname date_cet topdomain domain ip_address {number int} {min_conn_msec real}}
  $db add_tabledef aggr_specific {id} {scriptname date_cet topic {per_page_sec real}}
  
  # 19-2-2014 determine minimum (and max, avg to check) connection times to servers to determine physical locations.
  $db add_tabledef aggr_connect_time {id} {scriptname date_cet domain topdomain ip_address {min_conn_msec real} \
    {max_conn_msec real} {avg_conn_msec real} {number int}}
  
  if {$create_tables} {
    $db create_tables 0
  }
}

# @todo create and filled based on Dealer Locator code, still have to do:
# based on Myphilips and generic
# filling new records as they are being read.
migrate_proc add_daily_stats2 "Add daily stats tables (take 2)" {
  log debug "add_daily_stats2: start"
  $db exec2 "drop table if exists aggr_run"
  $db exec2 "drop table if exists aggr_page"
  add_daily_stats2 $db 1
  log debug "add_daily_stats2: finished"
  # breakpoint
}

migrate_proc add_aggr_sub "Add daily stats aggr_sub table" {
  $db add_tabledef aggr_sub {id} {date_cet scriptname {page_seq int} {npages int} keytype keyvalue \
    {avg_time_sec real} {avg_nkbytes real} {avg_nitems real}}
  $db create_tables 0
  log debug "add_daily_stats2: finished"
}

migrate_proc add_aggr_sub2 "Add daily stats aggr_sub table (take 2)" {
  $db exec2 "drop table if exists aggr_sub" -log -try
  $db exec2 "delete from dailystatus where actiontype = 'aggrsub'"
  $db add_tabledef aggr_sub {id} {date_cet scriptname {page_seq int} {npages int} keytype keyvalue \
    {avg_time_sec real} {avg_nkbytes real} {avg_nitems real}}
  $db create_tables 0
  log debug "add_daily_stats2: finished"
}

migrate_proc add_aggr_slowitem "Add table aggr_slowitem" {
  log info "Add table aggr_slowitem"
  # avg_page_sec: tijd van dit item op deze page. Bij alle pages optellen dus nog door aantal pages delen.
  # uitgangspunt: page_seq zit in het record, is dan ook onderdeel van de p.key.
  $db add_tabledef aggr_slowitem {id} {date_cet scriptname {page_seq int} keytype keyvalue {seqnr int} \
    {avg_page_sec real} {avg_loadtime_sec real} {nitems int}} 
  $db create_tables 0
}

migrate_proc redo_aggrrunpage_20131125 "Redo all aggr-run-page-slowitem records" {
  # slowitem is afhankelijk van #runs op een dag, dus deze ook doen. Rest niet, check gedaan op voorkomen aggr_run en aggr_page.
  # @note zou trouwens verwachten dat aggr_sub ook het #runs nodig heeft, dus nog checken. => deze gebruikt direct het aantal scriptruns, dus goed!
  $db exec2 "delete from dailystatus where actiontype in ('dailystats', 'slowitem')"
  $db exec2 "delete from aggr_slowitem"
  $db exec2 "delete from aggr_page"
  $db exec2 "delete from aggr_run"
}

migrate_proc add_pageitem_topic "Add pageitem_topic table" {
  log info "Add pageitem_topic table"
  $db add_tabledef pageitem_topic {id} {scriptname topic ts_cet date_cet scriptrun_id page_seq page_type page_id content_type resource_id \
      scontent_type url \
      extension domain topdomain urlnoparams \
      error_code connect_delta dns_delta element_delta first_packet_delta \
      remain_packets_delta request_delta \
      ssl_handshake_delta start_msec system_delta basepage record_seq \
      detail_component_1_msec detail_component_2_msec detail_component_3_msec \
      ip_address element_cached msmt_conn_id conn_string_text request_bytes content_bytes \
      header_bytes object_text header_code custom_object_trend status_code}
  $db create_tables 0
}

migrate_proc add_domain_ip_time "Add domain_ip_time table" {
  log info "Add domain_ip_time table"
  $db add_tabledef domain_ip_time {id} {scriptname date_cet topdomain domain ip_address {number int} {min_conn_msec real}}
  $db create_tables 0
}

migrate_proc add_aggr_specific "Add aggr_specific table" {
  log info "Add aggr_specific table"
  $db add_tabledef aggr_specific {id} {scriptname date_cet topic {per_page_sec real}}
  $db create_tables 0
}

# @todo dropping the table does not seem to work.
migrate_proc remove_maxitem "Remove maxitem table" {
  log info "Remove maxitem table"
  $db exec2 "drop table aggr_maxitem" -log -try
  log info "Removed maxitem table"
}

migrate_proc add_logfile_indexes "Add logfile indexes" {
  $db exec2 "create index if not exists ix_logfile_1 on logfile (filename)" -log -try
}

# @note if orig table script_pages changes, just move this def as the latest to do the
# migration again.
# 7-1-2014 ignored copying the table on Linux, but still needed, so do copy.
migrate_proc copy_script_pages2 "copy table script_pages" {
  copy_script_pages $db
}

migrate_proc add_fill_aptimized "add fill aptimized column" {
  $db exec2 "alter table pageitem add aptimized integer" -log -try
  $db exec2 "alter table pageitem_gt3 add aptimized integer" -log -try
  $db exec2 "alter table pageitem_topic add aptimized integer" -log -try
  $db exec2 "update pageitem set aptimized = 1 where url like '%aptimized%' and aptimized is null" -log
  $db exec2 "update pageitem set aptimized = 0 where aptimized is null" -log
  $db exec2 "update pageitem_gt3 set aptimized = 1 where url like '%aptimized%' and aptimized is null" -log
  $db exec2 "update pageitem_gt3 set aptimized = 0 where aptimized is null" -log
  $db exec2 "update pageitem_topic set aptimized = 1 where url like '%aptimized%' and aptimized is null" -log
  $db exec2 "update pageitem_topic set aptimized = 0 where aptimized is null" -log
}

proc refill_pagetype {db} {
  $db function objtxt2pagetype
  log info "About to update page for pagetype"

  if {0} {
    $db exec2 "update page
               set page_type = (select objtxt2pagetype(i.object_text) from pageitem i where i.page_id = page.id and i.basepage = 1)
               where page_type is null or page_type = '' or page_type = '<none>' or page_type like '%-%'" -log 
  }

  $db exec2 "drop table if exists temp_page_type" -log
  
  $db exec2 "create table temp_page_type as
             select p.id page_id, objtxt2pagetype(i.object_text) page_type
             from page p join pageitem i on i.page_id = p.id
             where i.basepage = 1
             and (p.page_type is null or p.page_type = '' or p.page_type = '<none>' or p.page_type like '%-%')" -log

  $db exec2 "create index ix_temp_page_type on temp_page_type(page_id)" -log

  $db exec2 "update page
             set page_type = (select page_type from temp_page_type t where t.page_id = page.id)
             where (page_type is null or page_type = '' or page_type = '<none>' or page_type like '%-%')" -log
  
  # $db exec2 "drop table temp_page_type" -log

  log info "Updated page for pagetype, now pageitems"
  
  #breakpoint
  $db exec2 "update pageitem set page_type = (select page_type from page p where p.id = pageitem.page_id)
             where page_type is null or page_type = '' or page_type = '<none>' or page_type like '%-%'" -log 
  log info "Updated pageitem for pagetype, done"
  #breakpoint

}

# pagetype will become empty for items older than 6 weeks, because pageitems are no longer available. Oh well.
migrate_proc refill_pagetype "Refill pagetype fields" {
  # objtxt2pagetype should be available here.
  #breakpoint
  refill_pagetype $db  
}

migrate_proc add_aggr_page_pagetype "Add page_type field to aggr_page" {
  $db exec2 "alter table aggr_page add page_type" -try -log
}

migrate_proc redo_aggrrunpage_20140128 "Redo all aggr-run-page records" {
  # 28-1-2014 don't redo all items, just the ones max 6 weeks ago, with a little bit less, so no gaps are introduced.
  # with redo-action, the field 'page_type' will get filled.
  $db exec2 "update dailystatus set dateuntil_cet = '2013-12-19' where actiontype in ('dailystats')"
}

migrate_proc redo_combinereport_20140128 "Redo combinereport" {
  # 28-1-2014 don't redo all items, just the ones max 6 weeks ago, with a little bit less, so no gaps are introduced.
  # with redo-action, the field 'page_type' will get filled.
  $db exec2 "update dailystatus set dateuntil_cet = '2013-12-19' where actiontype in ('combinereport')"
}

migrate_proc redo_aggrrunpage_20140128_2 "Redo all aggr-run-page records take 2" {
  # 28-1-2014 don't redo all items, just the ones max 6 weeks ago, with a little bit less, so no gaps are introduced.
  # with redo-action, the field 'page_type' will get filled.
  $db exec2 "update dailystatus set dateuntil_cet = '2013-12-19' where actiontype in ('dailystats')"
  $db exec2 "update dailystatus set dateuntil_cet = '2013-12-19' where actiontype in ('combinereport')"
}

migrate_proc redo_aggrrunpage_20140129_1 "Redo all aggr-run-page records" {
  # 28-1-2014 don't redo all items, just the ones max 6 weeks ago, with a little bit less, so no gaps are introduced.
  # with redo-action, the field 'page_type' will get filled.
  # 29-1-2014 All this is quite a lot of work, but is necessary: src needs to be changed, then aggregate tables, then aggregate DB.
  refill_pagetype $db
  $db exec2 "update dailystatus set dateuntil_cet = '2013-12-19' where actiontype in ('dailystats')"
  $db exec2 "update dailystatus set dateuntil_cet = '2013-12-19' where actiontype in ('combinereport')"
}

migrate_proc redo_aggrrunpage_20140129_2 "Redo all aggr-run-page records" {
  # 28-1-2014 don't redo all items, just the ones max 6 weeks ago, with a little bit less, so no gaps are introduced.
  # with redo-action, the field 'page_type' will get filled.
  # 29-1-2014 All this is quite a lot of work, but is necessary: src needs to be changed, then aggregate tables, then aggregate DB.
  refill_pagetype $db
  $db exec2 "update dailystatus set dateuntil_cet = '2013-12-19' where actiontype in ('dailystats')"
  $db exec2 "update dailystatus set dateuntil_cet = '2013-12-19' where actiontype in ('combinereport')"
}

# @note redo aggrsub because some things are added: domain, ipaddress, content_type, aptimized, and some combinations.
migrate_proc redo_aggrsub_20140218 "Redo all aggr-sub records" {
  $db exec2 "update dailystatus set dateuntil_cet = date('now', '-42 days') where actiontype in ('aggrsub', 'combinereport')"
}

# @note redo aggrsub because some things are added: domain, ipaddress, content_type, aptimized, and some combinations.
migrate_proc add_aggr_connect_time "Add aggr_connect_time table" {
  add_daily_stats2 $db 1
}

migrate_proc redo_combinereport_20140219 "Redo all aggr-sub records" {
  $db exec2 "update dailystatus set dateuntil_cet = date('now', '-42 days') where actiontype in ('combinereport')"
}

migrate_proc redo_aggrsub_20140222 "Redo aggrsub wrt gt100k" {
  $db exec2 "update dailystatus set dateuntil_cet = date('now', '-42 days') where actiontype in ('aggrsub', 'combinereport')"
}

migrate_proc redo_aggrsub_no_ip_20140222 "Remove IP related stuff from aggr-sub" {
  $db exec2 "delete from aggr_sub where keytype in ('ip_address', 'dom_ip')"
}

migrate_proc redo_aggrsub_20140227 "Redo aggrsub wrt dynamic" {
  $db exec2 "update dailystatus set dateuntil_cet = date('now', '-42 days') where actiontype in ('aggrsub', 'combinereport')"
}


# LET OP: als pageitem tabel verandert, moet pageitem_gt3 en pageitem_topic mee veranderen!
# LET OP: als je een table toevoegt, dan ook toevoegen bij add_daily_stats2, deze wordt aangeroepen voor nieuwe DB's.
