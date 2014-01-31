# libslotmeta.tcl - lib functions for accessing slotmeta.db and possibly other functions.
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
