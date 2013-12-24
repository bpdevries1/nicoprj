# libcombinereport.tcl - lib functions for accessing combinereport.db and possibly other functions.

proc get_combine_report_db {dargv} {
  set db_name [file join [from_cygwin [:srcdir $dargv]] [:db $dargv]]
  set existing_db [file exists $db_name]
  set db [dbwrapper new $db_name]
  cr_define_tables $db
  if {!$existing_db} {
    log info "New db: $db_name, create tables"
    $db create_tables 0 ; # 0: don't drop tables first.
    cr_create_indexes $db
  } else {
    log info "Existing db: $db_name, don't create tables"
  }
  $db prepare_insert_statements
  return $db
}

proc cr_define_tables {db} {
  # active: should reports be made for this def currently, are we doing anything with it currently?
  $db add_tabledef combinedef {id} {cmds srcdir srcpattern targetdir {active int} {ndirs int}}
  $db add_tabledef combinedefdir {id} {combinedef_id dir}
  $db add_tabledef combinedate {id} {combinedef_id date_cet status ts_start_cet ts_end_cet}
  $db add_tabledef combinedatedir {id} {combinedefdir_id combinedate_id date_cet dir status ts_ready_cet}
}

proc cr_create_indexes {db} {
  $db exec2 "create index ix_combinedate_1 on combinedate (combinedef_id, date_cet)"
  $db exec2 "create index ix_combinedatedir_1 on combinedatedir (date_cet, dir)"
}
