package require Tclx
package require csv
package require sqlite3

# own package
package require ndv

source file2dblib.tcl

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]

proc main {argv} {
  puts "argv: $argv"
  lassign $argv sourcedir targetdb
  make_db $targetdb
  convert_files $sourcedir  
  db close
}

# make db, reuse existing, just delete table before creating.
proc make_db {dbname} {
  global ar_columns
  # file delete $dbname
  sqlite3 db $dbname
  
  set tablename qperfline
  set ar_columns($tablename) [list filename ts name value]
  db eval "drop table if exists $tablename"
  db eval "create table $tablename (id integer primary key autoincrement, [join $ar_columns($tablename) ", "])"
}

proc convert_files {sourcedir} {
  handle_dir_rec $sourcedir "qperf.txt" convert_file_qperf
}

proc convert_file_qperf {sourcefile rootdir} {
  # make_db $targetdb
  log info "Read qperf.txt: $sourcefile"
  # return ; # for test.
  set date [clock format [file mtime $sourcefile] -format "%Y-%m-%d"]
  handle_file_lines_db $sourcefile 50000 line {
    if {[llength $line] > 4} {
      set ts "$date [lindex $line 0]"
      set ndx 0
      foreach val [lrange $line 1 end] {
        incr ndx
        set name "val$ndx"
        if {[regexp {^([0-9.]+)([a-zA-Z]+)$} $val z val2 unity]} {
          insert_record qperfline $sourcefile $ts "${name}_$unity" $val2 
        } else {
          insert_record qperfline $sourcefile $ts $name $val
        }
      }
    }
  }
}

main $argv

