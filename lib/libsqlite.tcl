# sqlite helper procs
# in Tcl 8.5, use sqlite directly
# in Tcl 8.6, use tdbc::sqlite, for named parameters in queries.

if {$tcl_version == "8.5"} {

  # puts stderr "Creating tcl 8.5 sqlite helper procs (none for now)"
  
} elseif {$tcl_version == "8.6"} {

  # 18-6-2013 NdV don't put message anymore, is irritating.
  # puts stderr "Creating tcl 8.6 tdbc::sqlite helper procs" 
  
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

  # @todo what if something fails, rollback, exec except/finally clause?
  proc db_in_trans {conn block} {
    db_eval $conn "begin transaction"
    uplevel $block  
    db_eval $conn "commit"
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
  
  proc make_table_def {tablename args} {
    dict create table $tablename fields $args 
  }

  #  set table_def [make_table_def_keys curlgetheader {ts_start ts fieldvalue param iter} {exitcode resulttext msec cacheheaders akamai_env cacheable expires expiry cachetype maxage cachekey akamaiserver}]
  proc make_table_def_keys {tablename keyfields valuefields} {
    dict create table $tablename keyfields $keyfields valuefields $valuefields fields [concat $keyfields $valuefields] 
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
    # return "create table [dict get $table_def table] ([join [dict get $table_def fields] ", "])" 
    set fields [lmap x [dict get $table_def fields] {expr {
        ($x != "id") ? $x : "id integer primary key autoincrement"
    }}]
    return "create table [dict get $table_def table] ([join $fields ", "])"
  }

  proc create_table_sql_old {table_def} {
    return "create table [dict get $table_def table] ([join [dict get $table_def fields] ", "])" 
  }

  
  # @param args: field names
  proc prepare_insert {conn tablename args} {
    # $conn prepare "insert into $tablename ([join $args ", "]) values ([join [map {par {return ":$par"}} $args] ", "])"
    $conn prepare [create_insert_sql $tablename {*}$args]
  }

  # @param args: field names
  proc prepare_insert_td {conn table_def} {
    # $conn prepare "insert into $tablename ([join $args ", "]) values ([join [map {par {return ":$par"}} $args] ", "])"
    $conn prepare [create_insert_sql_td $table_def]
  }
  
  proc create_insert_sql {tablename args} {
    return "insert into $tablename ([join $args ", "]) values ([join [lmap par $args {symbol $par}] ", "])"
  }

  proc create_insert_sql_td {table_def} {
    # return "insert into $tablename ([join $args ", "]) values ([join [lmap par $args {symbol $par}] ", "])"
    dict_to_vars $table_def
    set insert_fields [lmap x $fields {expr {
        ($x != "id") ? $x : [continue]
    }}]
    return "insert into $table ([join $insert_fields ", "]) values ([join [lmap par $insert_fields {symbol $par}] ", "])"
  }
  
  #  set stmt_update [prepare_update $conn $table_def]
  # @param args: field names
  proc prepare_update {conn table_def} {
    $conn prepare [create_update_sql $table_def]
  }
  
  proc create_key_index {conn table_def} {
    db_eval_try $conn [create_index_sql $table_def] 
  }
  
  proc create_index_sql {table_def} {
    dict_to_vars $table_def
    set sql "create index ix_key_$table on $table ([join $keyfields ", "])"
    log info "create index sql: $sql"
    return $sql
  }
  
  proc create_update_sql {table_def} {
    dict_to_vars $table_def
    set sql "update $table
            set [join [lmap par $valuefields {fld_eq_par $par}] ", "]
            where [join [lmap par $keyfields {fld_eq_par $par}] " and "]"
    log debug "update sql: $sql"          
    return $sql          
  }
  
  proc fld_eq_par {fieldname} {
    return "$fieldname = [symbol $fieldname]" 
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
