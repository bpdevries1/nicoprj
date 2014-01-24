# libdb.tcl

# @note/@todo wil TclOO gebruiken, maar conflict met unknown method ivm dict-accessor.
# @note TclOO clash met ndv lib lijkt nu verdwenen... (mss was het het laatste statement in vb (na destroy) die sowieso een fout geeft)

# @todo verder invullen, ook met MySQL.
# doel is libsqlite.tcl overbodig te maken, en alles via dit db wrapper object uit te voeren, dan geen namespace/name clash problemen.

package require TclOO 

# SQlite apparently requires Tcl8.6, so check before.
# Probably because of tdbc.
# So also tdbc::mysql
if {$tcl_version >= 8.6} {
  package require tdbc::sqlite3
  catch {package require tdbc::mysql} ; # mysql not available on (philips) laptop.
} else {
  puts "Don't load sqlite, tcl version too low: $tcl_version"
}

oo::class create dbwrapper {

  # @doc usage: set conn [dbwrapper new <sqlitefile.db]
  # @doc usage: set conn [dbwrapper new -db <mysqldbname> -user <user> -password <pw>]
  constructor {args} {
    my variable conn dbtype dbname
    if {[llength $args] == 1} {
      # assume sqlite
      set dbtype "sqlite3"
      log debug "connect to: [lindex $args 0]"
      set conn [tdbc::sqlite3::connection new [lindex $args 0]]
      log debug "connected"
    } else {
      # assume mysql
      set dbtype "mysql"
      set conn [tdbc::mysql::connection new {*}$args]
    }
    set dbname [lindex $args 0]
  }
  
  # @todo destructor gets called in beginning?
  #destructor {
  #  log info "destructor: TODO"
    # close prepared statements and db connection. Or just db connection.
  #}
  
  # @param conn: a tdbc connection.
# constructor {a_conn} {
#   my variable conn
#   set conn $a_conn
# }
  
  method close {} {
    my variable conn
    $conn close
  }

  method get_conn {} {
    my variable conn
    return $conn
  }
  
  method get_db_handle {} {
    my variable conn dbtype
    if {$dbtype == "sqlite3"} {
      $conn getDBhandle
    } elseif {$dbtype == "mysql"} {
      error "Not implemented (yet)"
    } else {
      error "Unknown dbtype: $dbtype" 
    }
  }
  
  method get_dbname {} {
    my variable dbname
    return $dbname
  }
  
  # @todo what if something fails, rollback, exec except/finally clause?
  method in_trans {block} {
    my variable conn
    my exec "begin transaction"
    try_eval {
      uplevel $block
    } {
      log_error "Rolling back transaction and raising error"
      my exec "rollback"
      error "Rolled back transaction"
    }
    my exec "commit"
  }
  
  # @todo getDBhandle does (probably) not work with MySQL.
  method exec {query {return_id 0}} {
    my variable conn
    set stmt [$conn prepare $query]
    $stmt execute
    $stmt close
    if {$return_id} {
      return [[$conn getDBhandle] last_insert_rowid]   
    }
  } 

  # @note 27-9-2013 new method signature (rename to exec in due time)
  # @note replaces exec and exec_try
  # @param args possible list of args: -log -try -returnid
  method exec2 {query args} {
    my variable conn
    set options {
      {log "Log the query before exec"}
      {try "Don't throw error if query fails"}
      {returnid "Return last_insert_rowid (SQLite only?)"}
    }
    set dargv [getoptions args $options ""]
    if {[:log $dargv]} {
      log debug $query 
    }
    try_eval {
      set stmt [$conn prepare $query]
      $stmt execute
      $stmt close
      if {[:returnid $dargv]} {
        return [[$conn getDBhandle] last_insert_rowid]   
      }
    } {
      log warn "db exec failed: $query"
      log warn "errorResult: $errorResult"
      if {[:try $dargv]} {
        # nothing, just log error and continue.
      } else {
        error "db exec failed: $query"
      }
    }
  } 
  
  method exec_try {query {return_id 0}} {
    try_eval {
      my exec $query $return_id
    } {
      log warn "db exec failed: $query"
      log warn "errorResult: $errorResult"
    }
  }

  method prepare_stmt {stmt_name query} {
    my variable db_statements conn
    dict set db_statements $stmt_name [$conn prepare $query]
  }
  
  # @note exec a previously prepared statement
  method exec_stmt {stmt_name dct {return_id 0}} {
    my variable db_statements conn
    set stmt [dict get $db_statements $stmt_name]
    set rs [$stmt execute $dct]
    if {$return_id} {
      $rs close
      return [[$conn getDBhandle] last_insert_rowid]   
    } else {
      set res [$rs allrows -as dicts]
      $rs close
      return $res 
    }
  } 
  
  # @return resultset as list of dicts
  method query {query} {
    my variable conn
    set stmt [$conn prepare $query]
    set rs [$stmt execute]
    set res [$rs allrows -as dicts]
    $rs close
    $stmt close
    return $res
  }
  
  # @todo idea determine tabledef's from actual table definitions in the (sqlite) db.
  method add_tabledef {table args} {
    my variable db_tabledefs
    dict set db_tabledefs $table [make_table_def_keys $table {*}$args]  
  }
  
  method create_tables {args} {
    my variable db_tabledefs conn
    set drop_first [lindex $args 0]
    if {$drop_first == ""} {
      set drop_first 0 
    }
    dict for {table td} $db_tabledefs {
      if {(![my table_exists $table]) || $drop_first} {
        create_table $conn $td {*}$args
      }
    }
  }
  
  # @todo don't use libsqlite anymore, wrt namespace clashes.
  method prepare_insert_statements {} {
    my variable db_tabledefs db_insert_statements conn
    dict for {table td} $db_tabledefs {
      dict set db_insert_statements $table [prepare_insert_td_proc $conn $td]
    }
  }
  
  # @todo multiline fields probably problematic, as newlines seem to be removed (shown in SqliteSpy).
  #       check if select from Tcl also shows this, and if \n or \r\n should be added or some setting in the lib can be done.
  method insert {table dct args} {
    my variable db_insert_statements dbtype conn
    [dict get $db_insert_statements $table] $dct {*}$args
    if {$dbtype == "sqlite3"} {
      return [[$conn getDBhandle] last_insert_rowid]
    } elseif {$dbtype == "mysql"} {
      set res [my query "select last_insert_id() last"]
      # log info "Returned id from MySQL: $res"
      return [dict get [lindex $res 0] last]
    } else {
      # unknown database type, return nothing.
      return
    }
  }  

  # some helpers/info
  # @note this one works only for the main DB, not for attached DB's.
  method table_exists {tablename} {
    my variable conn
    if {[$conn tables $tablename] == {}} {
      return 0 
    } else {
      return 1
    }
  }

  method function {fn_name}   {
    [my get_db_handle] function $fn_name $fn_name
  }
}

# proc breakpoint_dummy {} {
#   breakpoint 
# }
