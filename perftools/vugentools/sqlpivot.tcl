package require ndv
package require tdbc::sqlite3

proc main {argv} {
  puts "argv: $argv"
  lassign $argv dbname tablename rows columns values value_format
  set db [get_results_db $dbname]
  set query [det_query $db $tablename $rows $columns $values $value_format]
  puts "query:"
  puts $query
  set res [$db query $query]
  puts [join [dict keys [:0 $res]] "\t"]
  foreach el $res {
    puts [join [dict values $el] "\t"]
  }
  
  $db close
}

proc det_query {db tablename rows columns values value_format} {
  set col_values [det_col_values $db $tablename $columns]
  puts "col_values: $col_values"
  
  if 0 {
select t1.trans, printf('%.3f', t1.avg_resptime) newuser, printf('%.3f', t2.avg_resptime) revisit
from uc3_cmp t1 left join uc3_cmp t2 on t1.trans = t2.trans
where t1.revisit = 'newuser'
and t2.revisit = 'revisit'
  
  }

  set query "select t1.$rows, [det_result_fields $values $value_format $col_values]
[det_from_clause $tablename $rows $col_values]
where 1=1
[det_and_clauses $columns $col_values]"
  
  return $query
  
}

# for now, assume columns only is one column
proc det_col_values {db tablename columns} {
  set query "select distinct $columns colvalue from $tablename"
  set res [$db query $query]
  set colvalues {}
  foreach row $res {
    lappend colvalues [:colvalue $row]
  }
  return $colvalues
}

# select t1.trans, printf('%.3f', t1.avg_resptime) newuser, printf('%.3f', t2.avg_resptime) revisit

proc det_result_fields {values value_format col_values} {
  # return "<result_fields>"
  set res {}
  set id 0
  foreach el $col_values {
    incr id
    lappend res "printf('$value_format', t$id.$values) $el"
  }
  
  join $res ", "
}

# from uc3_cmp t1 left join uc3_cmp t2 on t1.trans = t2.trans
proc det_from_clause {tablename rows col_values} {
  set res "from $tablename t1"
  set id 1
  foreach el [lrange $col_values 1 end] {
    incr id
    append res " left join $tablename t$id on t1.$rows = t$id.$rows"
  }
  return $res
}

#t1.revisit = 'newuser'
#and t2.revisit = 'revisit'
proc det_and_clauses {columns col_values} {
  set res ""
  set id 0
  foreach col_value $col_values {
    incr id
    append res "and t$id.$columns = '$col_value'\n"
  }
  return $res
}


proc get_results_db {db_name} {
  set existing_db [file exists $db_name]
  set db [dbwrapper new $db_name]
  # define_tables $db
  if {!$existing_db} {
    error "DB not found: $db_name"
    # create_indexes $db
  } else {
    log info "Existing db: $db_name, don't create tables"
  }
  return $db
}

main $argv
