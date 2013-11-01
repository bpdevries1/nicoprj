# libextraprocessing.tcl - called by scatter2db.tcl and extraprocessing.tcl

# ndv::source_once dailystats.tcl updatemaxitem.tcl extra_gt3.tcl
ndv::source_once extra_dailystats.tcl extra_maxitem.tcl extra_gt3.tcl

proc extraproc_subdir {dargv subdir} {
  global cr_handler min_date
  log info "Handle subdir: $subdir"
  set db_name [file join $subdir "keynotelogs.db"]
  set existing_db [file exists $db_name]
  if {!$existing_db} {
    log warn "No database in $subdir, returning"
    return "nodb"
  }
  
  # @todo migrations call moet hier ergens in.
  # source_once weer gebruiken.
  
  set db [dbwrapper new $db_name]
  define_tables $db
  migrate_db $db $existing_db
  
  $db prepare_insert_statements
  
  if {[:actions $dargv] == "all"} {
    set actions [list maxitem gt3] 
  } else {
    set actions [split [:actions $dargv] ","] 
  }
  foreach action $actions {
    # graph_$action $r $dir
    check_do_daily $db $action {
      # update_maxitem $db [:maxitem $dargv]
      extra_update_$action $db $dargv $subdir
    }
    
  }  
  
  if {0} {
    # update_maxitem $db [:maxitem $dargv]
    if {[:updatemaxitem $dargv]} {
      check_do_daily $db "maxitem" {
        update_maxitem $db [:maxitem $dargv]
      }
    }
  }
  $db close
  log info "Created/updated db $db_name, size is now [file size $db_name]"
  return "ok"
}

# @todo dailystatus table also defined in kn-migrations.tcl
proc define_tables {db} {
  $db add_tabledef dailystatus {} {actiontype dateuntil_cet}
  $db add_tabledef dailystatuslog {} {ts_start_cet ts_end_cet datefrom_cet dateuntil_cet notes}
}

