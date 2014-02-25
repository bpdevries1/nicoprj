# libdnsip.tcl - lib functions for accessing dnsip.db and possibly other functions.

proc get_dnsip_db {db_name} {
  set existing_db [file exists $db_name]
  set db [dbwrapper new $db_name]
  dnsip_define_tables $db
  if {!$existing_db} {
    log info "New db: $db_name, create tables"
    $db create_tables 0 ; # 0: don't drop tables first.
    dnsip_create_indexes $db
  } else {
    log info "Existing db: $db_name, don't create tables"
  }
  $db prepare_insert_statements
  return $db
}

proc dnsip_define_tables {db} {
  #domain: id, domain
  #curldnsout: id, ts_cet (van file), path, domain, contents (als backup).
  #id, curldnsout_id, ts_cet, domain, dnsserver, ip_address (mogelijk >1 record per file)

  $db add_tabledef domain {id} {domain}
  $db add_tabledef curldnsout {id} {ts_cet path domain contents}
  $db add_tabledef domainip {id} {curldnsout_id ts_cet domain dnsserver dnsname ip_address}
}

proc dnsip_create_indexes {db} {
  # $db exec2 "create index if not exists ix_slot_download_1 on slot_download (slot_id)" -log -try
}

proc dnsip_create_views {db} {
 
}
