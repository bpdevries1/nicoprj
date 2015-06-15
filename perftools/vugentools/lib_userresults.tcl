package require ndv
package require tdbc::sqlite3

proc get_results_db {db_name} {
  set existing_db [file exists $db_name]
  set db [dbwrapper new $db_name]
  define_tables $db
  $db create_tables 0 ; # 0: don't drop tables first. Always do create, eg for new table defs.
  if {!$existing_db} {
    log info "New db: $db_name, create tables"
    # create_indexes $db
  } else {
    log info "Existing db: $db_name, don't create tables"
  }
  $db prepare_insert_statements
  return $db
}

proc define_tables {db} {
  # status: ok of error
  # reason: reden waarom error
  # notes: verdere info.
  $db add_tabledef user_result {id} {user status reason iteration nacts {R_getaccts real} notes logfilename ts_cet}
  $db add_tabledef user_naccounts {id} {user nacts filename ts_cet}
}


