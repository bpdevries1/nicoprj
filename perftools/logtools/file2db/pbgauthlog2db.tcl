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
  
  set tablename auth
  set ar_columns($tablename) [list filename ts msg prc user ip result]
  db eval "drop table if exists $tablename"
  db eval "create table $tablename (id integer primary key autoincrement, [join $ar_columns($tablename) ", "])"
}

proc convert_files {sourcedir} {
  handle_dir_rec $sourcedir "authentication0.log" convert_file_auth
}

proc convert_file_auth {sourcefile rootdir} {
  # make_db $targetdb
  log info "Read: $sourcefile"
  # return ; # for test.
  
  # hier ook geen header line.
  handle_file_lines_db $sourcefile 50000 line {
    # [Sat Oct 20 10:29:59 CEST 2012] - INFO:    A-Select AuthSP Server,LDAPAuthSP,aadie,10.135.20.25,,granted
    if {[regexp {^\[([^\]\[]+)\] - ([A-Z]+): (.*)$} $line z timestamp logtype text]} {
      set ts [sqlite_ts [clock scan $timestamp -format "%a %b %d %H:%M:%S %Z %Y"]]
      lassign [split [string trim $text] ","] msg prc user ip z result
      insert_record auth $sourcefile $ts $msg $prc $user $ip $result
    }
  }
}

main $argv

