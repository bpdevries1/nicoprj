# libdb.tcl

# @note/@todo wil TclOO gebruiken, maar conflict met unknown method ivm dict-accessor.
# @note TclOO clash met ndv lib lijkt nu verdwenen... (mss was het het laatste statement in vb (na destroy) die sowieso een fout geeft)

package require TclOO 

oo::class create dbwrapper {
  constructor {a_conn} {
    my variable conn
    set conn $a_conn
  }
  
  method get_conn {} {
    my variable conn
    return $conn
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
  
  method make_insert_statements {} {
    my variable db_tabledefs db_insert_statements conn
    dict for {table td} $db_tabledefs {
      dict set db_insert_statements $table [prepare_insert_td_proc $conn $td]
    }
  }
  
  method insert {table dct args} {
    my variable db_insert_statements
    [dict get $db_insert_statements $table] $dct {*}$args
  }    
}

