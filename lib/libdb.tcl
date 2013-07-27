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
  package require tdbc::mysql
} else {
  puts "Don't load sqlite, tcl version too low: $tcl_version"
}


oo::class create dbwrapper {

  # @doc usage: set conn [dbwrapper new <sqlitefile.db]
  # @doc usage: set conn [dbwrapper new -db <mysqldbname> -user <user> -password <pw>]
  constructor {args} {
    my variable conn dbtype
    if {[llength $args] == 1} {
      # assume sqlite
      set dbtype "sqlite3"
      set conn [tdbc::sqlite3::connection new [lindex $args 0]] 
    } else {
      # assume mysql
      set dbtype "mysql"
      set conn [tdbc::mysql::connection new {*}$args]
    }
  }
  
  destructor {
    log info "TODO"
    # close prepared statements and db connection. Or just db connection.
  }
  
  # @param conn: a tdbc connection.
# constructor {a_conn} {
#   my variable conn
#   set conn $a_conn
# }
  
  method get_conn {} {
    my variable conn
    return $conn
  }
  
  method get_db_handle {} {
    my variable conn dbtype
    if {$dbtype == "sqlite3"} {
      $conn getDBhandle
    } elseif {$dbtype == "mysql"} {
      
    } else {
      error "Unknown dbtype: $dbtype" 
    }
  }
  
  method exec {query {return_id 0}} {
    my variable conn
    set stmt [$conn prepare $query]
    $stmt execute
    $stmt close
    if {$return_id} {
      return [[$conn getDBhandle] last_insert_rowid]   
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
   
  method add_tabledef {table args} {
    my variable db_tabledefs
    dict set db_tabledefs $table [make_table_def_keys $table {*}$args]  
  }
  
  method create_tables {args} {
    my variable db_tabledefs conn
    dict for {table td} $db_tabledefs {
      create_table $conn $td {*}$args
    }
  }
  
  # @todo don't use libsqlite anymore, wrt namespace clashes.
  method prepare_insert_statements {} {
    my variable db_tabledefs db_insert_statements conn
    dict for {table td} $db_tabledefs {
      dict set db_insert_statements $table [prepare_insert_td_proc $conn $td]
    }
  }
  
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
}

proc breakpoint_dummy {} {
  breakpoint 
}

