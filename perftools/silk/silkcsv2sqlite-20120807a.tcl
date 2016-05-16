#!/home/nico/bin/tclsh

# import csv export data to sqlite db
# 2 forms:
# * minimal: only Transaction and Timer records.
# * full: everything.
#
# goal: determine if recorded Timers (response times) belong to failed or succeeded transactions.

package require Tclx
package require csv
package require sqlite3
package require ndv

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]

proc main {argv} {
  set complete 0
  lassign $argv csv_filename db_filename complete
  if {$complete == ""} {
    set complete 0 
  }
  file delete $db_filename
  create_db $db_filename  
  read_file $csv_filename $complete 
  db close
}

proc create_db {filename} {
  sqlite3 db $filename
}

proc read_file {csv_filename complete} {
  set fi [open $csv_filename r]
  set in_ts_data 0
  while {![eof $fi]} {
    gets $fi line
    set lst [csv::split $line]
    lassign $lst tp z z z tm
    if {($tp == "C") && ($tm == "Time")} {
      make_table tsdata $lst
      set in_ts_data 1
      set nrecords 0
      db eval "begin transaction"
    } elseif {$in_ts_data} {
      if {$complete} {
        insert_data tsdata $lst
        incr necords
      } else {
        if {[should_insert $lst]} {
          insert_data tsdata $lst
          incr necords
        }
      }
      if {$nrecords > 1000} {
        db eval "commit"
        db eval "start transaction"
        log info "Handled another 1000 records"
        set nrecords 0
      }
    }
  }  
  close $fi
  db eval "commit"
}

proc make_table {tablename lst} {
  # now should use map, but do imperative
  log debug "lst: $lst"
  set res {}
  foreach el [lrange $lst 1 end] {
    regsub -all " " $el "_" el2
    lappend res $el2
  }
  set sql "create table $tablename ([join $res ", "])"
  log debug "sql: $sql"
  db eval $sql  
}

proc should_insert {lst} {
  set tp [lindex $lst 1]
  if {($tp == "Transaction") || ($tp == "Timer")} {
    return 1 
  } else {
    return 0 
  }
}

proc insert_data {tablename lst} {
  set res {}
  foreach el [lrange $lst 1 end] {
    # all values between single quotes.
    lappend res "'$el'"
  }
  set sql "insert into $tablename values ([join $res ", "])"
  # log debug "sql: $sql"
  db eval $sql  
}

# format a timestamp format in the default (and only workable) format in sqlite: 2011-09-05 11:59:33 (so lose subseconds)
# time here with dots, check if this works.
proc ts_format_sqlite_old {value ts_fmt} {
  # value kan nog ".MMM" voor milliseconds bevatten, deze verwijderen.
  if {[regexp {^(.*)\.[0-9]{3}$} $value z val]} {
    set value $val 
  }
  clock format [clock scan $value -format $ts_fmt] -format "%Y-%m-%d %H:%M:%S"  
}
  
proc log {args} {
  global log
  $log {*}$args
}

main $argv

