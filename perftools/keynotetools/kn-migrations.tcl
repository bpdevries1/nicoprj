# kn-migrations.tcl - diff-scripts to put keynote db's in right version

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
  set src_name "c:/projecten/Philips/script-pages/script-pages.db"
  if {![file exists $src_name]} {
    error "Src db for script_pages does not exist" 
  }
  $db exec "attach database '$src_name' as fromDB"
  set table "script_pages"
  # @note use main.$table, otherwise source might be dropped.
  $db exec "drop table if exists main.$table"
  $db exec_try "create table if not exists $table as select * from fromDB.$table"
  $db exec "detach fromDB"
}

# @note if orig table script_pages changes, just move this def as the latest to do the
# migration again.
migrate_proc copy_script_pages "copy table script_pages" {
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

# @note task_succeed is an existing field.
# @todo still big in determining succeed for new items, so not this one for now.
migrate_proc add_fill_task_succeed "Fill task_succeed field" {
  $db exec2 "alter table scriptrun add task_succeed_calc integer" -log -try
  set_task_succeed_calc $db
}

# @note als je dezen even niet wilt (want ze duren lang), dan gewoon uitcommenten en scatter2db opnieuw starten
#       of "if 0" omheen zetten.
migrate_proc add_fill_topdomain "Add and fill topdomain field" {
  $db exec2 "alter table pageitem add topdomain" -log -try
  add_topdomain $db 0 0 ; # don't clean first, new field. Also don't check first.
}

migrate_proc add_fill_urlnoparams "Add and fill urlnoparams field" {
  $db exec2 "alter table pageitem add urlnoparams" -log -try
  fill_urlnoparams2 $db
}

# @todo nog even if 0, want niet in 'productie'
if {1} {
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

} ; # end of if 0
