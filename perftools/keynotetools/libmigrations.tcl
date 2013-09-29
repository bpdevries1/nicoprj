# libmigrations.tcl - helper functions for diff-scripts to put db's in right version

# @todo put in separate namespace (compare clojure?)

# @param db a dbwrapper object
# @param procprefix prefix of proc to do actual migrations.
proc migrate_db {db existing_db} {
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

# interp alias {} migrate_db {} migrate_db_new
# interp alias {} migrate_db {} migrate_db_old

proc migrate_db_step {db version} {
  global migrate_db_procs
  try_eval {
    set procname [dict get $migrate_db_procs $version]
    return [$procname $db]
  } {
    log warn "no proc for $version found, returning version so it stops"
    return $version
  }
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
  # @note db object will check if table already exists.
  $db create_tables 0 ; # don't drop tables first.    
  $db prepare_insert_statements
}

proc migrate_create_tables_old {db} {
  $db add_tabledef db_version {version_current} {}
  $db add_tabledef db_migration {id} {start_utc stop_utc \
    version_from version_to description}
  if {[$db table_exists db_version]} {
    # tables already exist 
  } else {
    $db create_tables 0 ; # don't drop tables first.
  }
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
