# libuserinfo.tcl

# deze mogelijk in libdb:
proc get_info_db {db_name} {
  #breakpoint
  set existing_db [file exists $db_name]
  set db [dbwrapper new $db_name]
  define_tables $db
  $db create_tables 0 ; # 0: don't drop tables first. Always do create, eg for new table defs. 1: drop tables first.
  if {!$existing_db} {
    log info "New db: $db_name, create indexes"
    # create_indexes $db
  } else {
    log info "Existing db: $db_name, don't create indexes"
  }
  $db prepare_insert_statements
  #breakpoint
  return $db
}

proc define_tables {db} {
  $db add_tabledef userdat {id} {directory project filepath filename file_ts userid line}
  $db add_tabledef runresult {id} {directory project filepath filename file_ts userid errortype}
  $db add_tabledef runresulttrans {id} {directory project filepath filename file_ts userid transname {transstatus int}}
  $db add_tabledef file_ts {id} {filepath file_ts}
}

proc is_file_read {db filepath} {
  if {[file exists $filepath]} {
    set file_ts [clock format [file mtime $filepath] -format "%Y-%m-%d %H:%M:%S"]
	set res [$db query "select count(*) nr from file_ts where filepath='$filepath' and file_ts = '$file_ts'"]
	return [:nr [:0 $res]]
  } else {
    return 0
  }
}

proc set_file_read {db filepath} {
  set file_ts [clock format [file mtime $filepath] -format "%Y-%m-%d %H:%M:%S"]
  $db insert file_ts [vars_to_dict filepath file_ts]
}
