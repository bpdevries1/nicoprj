# libmigrations.tcl - helper functions for diff-scripts to put db's in right version

# @todo put in separate namespace (compare clojure?)

# @param db result of 'dbwrapper new'
# @param procprefix prefix of proc to do actual migrations.
proc migrate_db_old {db procprefix existing_db} {
  migrate_create_tables $db
  if {$existing_db} {
    set version [migrate_det_current_version $db]
  } else {
    set version "new"
  }    
  while {1} {
    # set new_version [$procprefix $db $version]
    set sec_start [clock seconds]
    lassign [$procprefix $db $version] new_version description
    if {$version == $new_version} {
      break
    } else {
      migrate_add_version $db $version $new_version $description $sec_start [clock seconds]
    }
    set version $new_version
  }
}

# @param db result of 'dbwrapper new'
# @param procprefix prefix of proc to do actual migrations.
proc migrate_db_new {db procprefix existing_db} {
  log debug "procprefix: $procprefix not used in new version"
  migrate_create_tables $db
  if {$existing_db} {
    set version [migrate_det_current_version $db]
  } else {
    set version "new"
  }    
  while {1} {
    # set new_version [$procprefix $db $version]
    set sec_start [clock seconds]
    lassign [migrate_db_step $db $version] new_version description
    if {$version == $new_version} {
      break
    } else {
      migrate_add_version $db $version $new_version $description $sec_start [clock seconds]
    }
    set version $new_version
  }
}

interp alias {} migrate_db {} migrate_db_new
# interp alias {} migrate_db {} migrate_db_old

proc migrate_db_step {db version} {
  global migrate_db_procs
  set procname [dict get $migrate_db_procs $version]
  $procname $db  
}

# @todo mocht het zo niet werken, dan evt in 2 stappen: proc def-en gewoon, en hierna registreren.
set migrate_last_version "<none>"
proc migrate_proc {version description body} {
  global migrate_last_version migrate_db_procs
  set proc_name "migrate_db_proc_$version"
  dict set migrate_db_procs $migrate_last_version $proc_name
  
  proc $proc_name {db} "
    log debug \"$description for: \[\$db get_dbname\]\"
    $body
    list \"$version\" \"$description\"
  "
  
  # (re)define default/new/last procs
  proc migrate_noop {db} "
    list \"$version\" \"No change/new\"
  "
  
  dict set migrate_db_procs $version migrate_noop
  dict set migrate_db_procs "new" migrate_noop
  
  set migrate_last_version $version
}

proc migrate_create_tables {db} {
  $db add_tabledef db_version {version_current} {}
  $db add_tabledef db_migration {id} {start_utc stop_utc \
    version_from version_to description}
  $db create_tables 0 ; # don't drop tables first.  
  $db prepare_insert_statements
}

proc migrate_det_current_version {db} {
  set res [$db query "select version_current from db_version"]
  if {[llength $res] == 1} {
    :version_current [lindex $res 0] 
  } else {
    return "<none>" 
  }
}

proc migrate_add_version {db old_version new_version description sec_start sec_stop} {
  if {($old_version == "<none>") || ($old_version == "new")} {
    $db insert db_version [dict create version_current $new_version] 
  } else {
    $db exec "update db_version set version_current = '$new_version'"  
  }
  set start_utc [clock format $sec_start -format "%Y-%m-%d %H:%M:%S" -gmt 1]
  set stop_utc [clock format $sec_stop -format "%Y-%m-%d %H:%M:%S" -gmt 1]
  $db insert db_migration [dict create start_utc $start_utc \
    stop_utc $stop_utc \
    version_from $old_version \
    version_to $new_version \
    description $description]
}
