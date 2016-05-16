package require ndv
package require tdbc::sqlite3

proc get_output_db {db_name} {
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
  $db add_tabledef logfile {id} {ts_cet path {vuserid int}}
  $db add_tabledef logblock {id} {logfile_id {linestart int} {lineend int} \
                                      sourcefile {sourceline int} {relmsec real} \
                                      {relframeid int} {internalid int} \
                                      url blocktype {proxy int} firstline restlines}
  $db add_tabledef reqresp {id} {logfile_id sourcefile {sourceline int} {linestart int} {lineend int} \
    {relmsecfirst real} {relmseclast real} {durationmsec real} {relframeid int} {internalid int} \
    url {responsecode int} response}
}


