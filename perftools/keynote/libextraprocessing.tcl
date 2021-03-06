# libextraprocessing.tcl - called by scatter2db.tcl and extraprocessing.tcl

# ndv::source_once dailystats.tcl updatemaxitem.tcl extra_gt3.tcl
# @todo use glob to get all 'extra' scripts and source them in a loop.
ndv::source_once extra_dailystats.tcl extra_slowitem.tcl extra_gt3.tcl extra_topic.tcl extra_aggr_specific.tcl extra_domain_ip.tcl extra_janitor.tcl extra_aggrsub.tcl extra_removeold.tcl extra_combinereport.tcl extra_aggr_connect.tcl

# @note 24-12-2013 op het moment dat deze proc wordt aangeroepen, gaat 'ie aan de slag voor de dagen dat het de bedoeling is.
# dus check wanneer wordt elders/eerder gedaan.
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
  add_daily_status $db 0
  add_daily_stats2 $db 0
  $db add_tabledef aggr_sub {id} {date_cet scriptname {page_seq int} {npages int} keytype keyvalue \
    {avg_time_sec real} {avg_nkbytes real} {avg_nitems real}}
  $db prepare_insert_statements
  
  if {[:actions $dargv] == "all"} {
    # set actions [list dailystats gt3 aggrsub slowitem topic domain_ip aggr_specific vacuum analyze] 
    # set actions [list dailystats gt3 aggrsub slowitem topic domain_ip aggr_specific removeold vacuum analyze] 
    # 23-12-2013 add combinereport to standard actions when this works ok.
    # 19-2-2014 added aggrconnect
    set actions [list dailystats gt3 aggrsub slowitem topic domain_ip aggr_specific aggrconnect removeold combinereport analyze vacuum] 
  } else {
    set actions [split [:actions $dargv] ","] 
  }
  foreach action $actions {
    extra_update_$action $db $dargv $subdir
    update_checkfile [:checkfile $dargv]
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

