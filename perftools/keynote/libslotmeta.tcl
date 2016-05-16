# libslotmeta.tcl - lib functions for accessing slotmeta-domains.db and possibly other functions.
# this database should be used read only from download-scatter.tcl
# and maybe also used from scatter2db.tcl

proc get_slotmeta_db {db_name} {
  set existing_db [file exists $db_name]
  set db [dbwrapper new $db_name]
  slotmeta_define_tables $db
  if {!$existing_db} {
    log info "New db: $db_name, create tables"
    $db create_tables 0 ; # 0: don't drop tables first.
    slotmeta_create_indexes $db
  } else {
    log info "Existing db: $db_name, don't create tables"
  }
  $db prepare_insert_statements
  return $db
}

proc slotmeta_define_tables {db} {
  $db add_tabledef slot_download {id} {slot_id dirname {npages int} download_pc {download_order real} start_date end_date ts_create_cet ts_update_cet}
  $db add_tabledef slot_meta {id} {slot_id url pages {npages int} slot_alias shared_script_id agent_id agent_name target_id trans_type start_date end_date target_or_group target_type index_id ts_create_cet ts_update_cet}
  
  # 28-1-2014 script contents. ts_cet - timestamp of file downloaded, for versioning.
  $db add_tabledef script {id} {filename path slot_id ts_cet {filesize int} contents}

  # 29-1-2014 added some more, to find disabled domains and to-disable domains.
  $db add_tabledef domaindisabled {id} {script_id slot_id script_ts_cet domainspec topdomain domainspectype ipaddress}
  $db add_tabledef domainused {id} {scriptname slot_id domain topdomain date_cet {number real} {sum_nkbytes real} {page_time_sec real}}
  $db add_tabledef domaincontract {id} {domain topdomain contractparty domaintype disable_soll disable_ist notes}
  
  # and aggregates for disabled domains.
  $db add_tabledef domaindisabled_aggr {} {topdomain last_script_ts_cet}
  $db add_tabledef domainused_aggr {} {topdomain date_cet}
  
  # mapping of categories, also for determining #pages wrt daily dashboard
  $db add_tabledef category {id} {linenr ts_cet catgroup category category_full}
  $db add_tabledef slot_cat {id} {category_id countrycode slot_id slot_alias}
}

proc slotmeta_create_indexes {db} {
  $db exec2 "create index if not exists ix_slot_download_1 on slot_download (slot_id)" -log -try
  $db exec2 "create index if not exists ix_slot_meta_1 on slot_meta (slot_id)" -log -try
  $db exec2 "create index if not exists ix_script on script (slot_id)" -log -try
  $db exec2 "create index if not exists ix_domaindisabled_1 on domaindisabled (slot_id)" -log -try
  $db exec2 "create index if not exists ix_domaindisabled_2 on domaindisabled (domainspec)" -log -try  
  $db exec2 "create index if not exists ix_domaindisabled_3 on domaindisabled (topdomain)" -log -try  
  $db exec2 "create index if not exists ix_domainused_1 on domainused (slot_id)" -log -try
  $db exec2 "create index if not exists ix_domainused_2 on domainused (domain)" -log -try
  $db exec2 "create index if not exists ix_domainused_3 on domainused (topdomain)" -log -try
  $db exec2 "create index if not exists ix_domaincontract on domaincontract (domain)" -log -try
}

proc slotmeta_create_views {db} {
  $db exec2 "drop view if exists domaindisabled_view" -log
  $db exec2 "create view domaindisabled_view as
             select m.slot_alias, d.*
             from domaindisabled d join slot_meta m on m.slot_id = d.slot_id" -log

  $db exec2 "drop view if exists domainused_view" -log
  $db exec2 "create view domainused_view as
             select m.slot_alias, u.*
             from domainused u join slot_meta m on m.slot_id = u.slot_id" -log
             
  $db exec2 "drop view if exists script_domain_should_disable" -log

  $db exec2 "create view script_domain_should_disable as
              select u.slot_alias slot_alias, u.slot_id slot_id, u.topdomain topdomain, u.date_cet date_cet, 
                     u.sum_nkbytes sum_nkbytes, u.page_time_sec page_time_sec
              from domainused_view u
              where u.date_cet > date('now', '-5 days')
              and u.page_time_sec > 0.002
              and u.topdomain in (
                select topdomain
                from domaincontract c
                where c.disable_soll = 1
              )
              and not exists (
                select 1
                from domaindisabled d
                where d.slot_id = u.slot_id
                and d.topdomain = u.topdomain
              )
              and not exists (
                select 1
                from domainused u2
                where u2.slot_id = u.slot_id
                and u2.topdomain = u.topdomain
                and u2.date_cet > u.date_cet
                and u2.page_time_sec > 0.002
              )
              order by 1,2,3"

}