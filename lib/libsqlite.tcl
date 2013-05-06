# sqlite helper procs
# in Tcl 8.5, use sqlite directly
# in Tcl 8.6, use tdbc::sqlite, for named parameters in queries.

if {$tcl_version == "8.5"} {

  puts stderr "Creating tcl 8.5 sqlite helper procs (none for now)"
  
} elseif {$tcl_version == "8.6"} {

  puts stderr "Creating tcl 8.6 tdbc::sqlite helper procs" 
  
  proc open_db {db_name} {
    set conn [tdbc::sqlite3::connection create db $db_name]
    return $conn
  }

  proc db_eval {conn query {return_id 0}} {
    set stmt [$conn prepare $query]
    $stmt execute
    $stmt close
    if {$return_id} {
      return [[$conn getDBhandle] last_insert_rowid]   
    }
  }
  
  proc db_eval_try {conn query {return_id 0}} {
    try_eval {
      db_eval $conn $query $return_id
    } {
      log warn "db_eval failed: $query"
      log warn "errorResult: $errorResult"
      # nothing 
    }
  }
  
  proc stmt_exec {conn stmt dct {return_id 0}} {
    $stmt execute $dct
    if {$return_id} {
      return [[$conn getDBhandle] last_insert_rowid]   
    }
  }

  # @return resultset as list of dicts
  proc db_query {conn query} {
    set stmt [$conn prepare $query]
    set rs [$stmt execute]
    set res [$rs allrows -as dicts]
    $rs close
    $stmt close
    return $res
  }
  
  # @param args: field names
  proc prepare_insert {conn tablename args} {
    # $conn prepare "insert into $tablename ([join $args ", "]) values ([join [map {par {return ":$par"}} $args] ", "])"
    $conn prepare [create_insert_sql $tablename {*}$args]
  }
  
  proc create_insert_sql {tablename args} {
    return "insert into $tablename ([join $args ", "]) values ([join [lmap par $args {symbol $par}] ", "])"
  }
  
  proc make_table_def {tablename args} {
    dict create table $tablename fields $args 
  }
  
  proc create_table {conn table_def {dropfirst 0}} {
    # drop table straks weer weg.
    #db_eval_try $conn "drop table curlgetheader"
    #db_eval_try $conn "create table curlgetheader (ts, fieldvalue, param, exitcode, resulttext, msec, cacheheaders, akamai_env, cacheable, expires, expiry, cachetype, maxage)"
    if {$dropfirst} {
      db_eval_try $conn [drop_table_sql $table_def]
    }
    db_eval_try $conn [create_table_sql $table_def]
  }
  
  proc drop_table_sql {table_def} {
    return "drop table [dict get $table_def table]" 
  }
  
  proc create_table_sql {table_def} {
    return "create table [dict get $table_def table] ([join [dict get $table_def fields] ", "])" 
  }
  
  
  proc symbol {name} {
    return ":$name" 
  }

  proc det_now {} {
    clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S" 
  }
  
} else {
  puts stderr "Unknown tcl_version ($tcl_version), don't create sqlite helper procs" 
}
