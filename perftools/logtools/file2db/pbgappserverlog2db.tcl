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

proc make_db {dbname} {
  global ar_columns
  file delete $dbname
  sqlite3 db $dbname
  
  set tablename logline
  set ar_columns($tablename) [list filename ts name value]
  db eval "create table $tablename (id integer primary key autoincrement, [join $ar_columns($tablename) ", "])"

  set tablename processline
  set ar_columns($tablename) [list filename ts pid name value]
  db eval "create table $tablename (id integer primary key autoincrement, [join $ar_columns($tablename) ", "])"
  
}

proc convert_files {sourcedir} {
  handle_dir_rec $sourcedir "appserver.txt" convert_file_appserver
}

proc convert_file_appserver {sourcefile rootdir} {
  set DAY_SECONDS [expr 24*60*60]
  # make_db $targetdb
  log info "Read appserver.txt: $sourcefile"
  # return ; # for test.
  
  handle_file_lines_db $sourcefile 50000 line {
    if {[regexp {^[A-Za-z]{3} .* METDST} $line]} {
      # Sat Oct 20 13:08:00 METDST 2012
      # METDST nog recognised by Tcl as a timezone.
      set ts_sec [clock scan $line -format "%a %b %d %H:%M:%S METDST %Y"]
      set ts [sqlite_ts $ts_sec]
    } elseif {[regexp {^\d\d:\d\d ([^:]+): (.+)$} $line z names values]} {
      # @todo splitsen van dingen als: Rq Duration (max, avg)         : (26686 ms, 31 ms)
      set names [string trim $names]
      set values [string trim $values]
      if {[regexp {\(.+\)} $names]} {
        handle_multiple_values $sourcefile $ts $names $values 
      } else {
        insert_record logline $sourcefile $ts $names $values
      }
    } elseif {[regexp {\d\d:\d\d (\d+) (.+)$} $line z pid values]} {
      lassign $values state port nrq nrcvd nsent
      foreach nm [list state port nrq nrcvd nsent] {
        insert_record processline $sourcefile $ts $pid $nm [set $nm]
      }
    }
  }
}

# @param names: Rq Duration (max, avg)
# @param values: (0 ms, 0 ms)
# remove ms from values, add to names
proc handle_multiple_values {sourcefile ts names values} {
  if {[regexp {^([^\(\)]+)\(([^\(\)]+)\)$} $names z prefix partnames]} {
    set prefix [string trim $prefix]
    set partnames [string trim $partnames]
    if {[regexp  {^\(([^\(\)]+)\)$} $values z partvalues]} {
      set partvalues [string trim $partvalues]
      foreach nm [split $partnames ","] val [split $partvalues ","] {
        set nm [string trim $nm]
        set val [string trim $val]
        if {[regexp {^(.+) ([a-zA-Z]+)$} $val z realval unity]} {
          insert_record logline $sourcefile $ts "${prefix}_${nm}_$unity" $realval 
        } else {
          insert_record logline $sourcefile $ts "${prefix}_${nm}" $val
        }
      }
    } else {
      error "Could not parse multiple values; $values"
    }
  } else {
    error "Could not parse multiple names: $names" 
  }
}

main $argv

