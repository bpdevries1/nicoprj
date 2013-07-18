# libdb.tcl

# @note wil TclOO gebruiken, maar conflict met unknown method ivm dict-accessor.

proc db_add_tabledef {table args} {
  global db_tabledefs
  dict set db_tabledefs $table [make_table_def_keys $table {*}$args]  
}

proc db_create_tables {conn args} {
  global db_tabledefs
  dict for {table td} $db_tabledefs {
    create_table $conn $td {*}$args
  }
}

proc db_make_insert_statements {conn} {
  global db_tabledefs db_insert_statements
  dict for {table td} $db_tabledefs {
    dict set db_insert_statements $table [prepare_insert_td_proc $conn $td]
  }
}

proc db_insert {table dct args} {
  global db_insert_statements
  [dict get $db_insert_statements $table] $dct {*}$args
}


