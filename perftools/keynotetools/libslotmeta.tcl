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
}

proc slotmeta_create_indexes {db} {
  $db exec2 "create index ix_slot_download_1 on slot_download (slot_id)"
  $db exec2 "create index ix_slot_meta_1 on slot_meta (slot_id)"
}
