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
  
  set tablename prgperf
  set ar_columns($tablename) [list filename ts name value]
  db eval "drop table if exists $tablename"
  db eval "create table $tablename (id integer primary key autoincrement, [join $ar_columns($tablename) ", "])"
}

proc convert_files {sourcedir} {
  handle_dir_rec $sourcedir "*.txt" convert_file_prgperf
}

proc convert_file_prgperf {sourcefile rootdir} {
  # make_db $targetdb
  log info "Read: $sourcefile"
  # return ; # for test.
  set date [clock format [file mtime $sourcefile] -format "%Y-%m-%d"]
  # hier ook geen header line.
  set prefix ""
  handle_file_lines_db $sourcefile 50000 line {
    if {[regexp {^(\d\d:\d\d) ([^:]+): (.+)$} $line z time name value]} {
      set name [string trim $name]
      set value [string trim $value]
      if {[string is double $value]} {
        set ts "$date $time:00"
        # breakpoint
        insert_record prgperf $sourcefile $ts $name $value
      }
    }
  }
}

main $argv

