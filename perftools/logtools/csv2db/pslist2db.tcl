# curltrace2db.tcl

package require Tclx
# package require csv
package require sqlite3

# own package
package require ndv

source file2dblib.tcl

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]

proc main {argv} {
  puts "argv: $argv"
  # lassign $argv sourcefile targetdb
  lassign $argv sourcedir targetdb
  make_db $targetdb
  convert_files $sourcedir  
  db close
}

proc make_db {dbname} {
  # global ar_columns
  file delete $dbname
  sqlite3 db $dbname
  make_db_table pslist [list sourcefile datetime computer pname pid cpu thd hnd priv cputime elapsedtime]
}

proc convert_files {sourcedir} {
  handle_dir_rec $sourcedir "pslist*.out" convert_file
}

# 13:51:00 28-11-2012 Process information for VSW-APL-022:
# Name                Pid CPU Thd  Hnd   Priv        CPU Time    Elapsed Time => ignore
# Idle                  0 100   2    0      0  1255:27:18.281   630:46:01.693
proc convert_file {sourcefile rootdir} {
  log info "Read pslist file: $sourcefile"
  handle_file_lines_db $sourcefile 50000 line {
    if {[regexp {^([^ ]+) ([^ ]+) Process information for ([^:]+):} $line z tm dt comp]} {
      set datetime [det_datetime $dt $tm]
      set computer $comp
    } elseif {[regexp {^Name +Pid +CPU} $line]} {
      # header line, ignore 
    } else {
      set l [as_list $line]
      if {[llength $l] == 8} {
        # lassign $l pname pid cpu thd hnd priv cputime elapsedtime
        insert_record pslist [det_relative_path $sourcefile $rootdir] $datetime $computer {*}$l
      }
    }
  }
}

proc det_datetime {dt tm} {
  #set tm2 [clock format [clock scan $tm -format "%H:%M:%S"] -format "%H:%M:%S"]
  #return "[clock format [clock scan $dt -format "%d-%m-%Y"] -format "%Y-%m-%d"] $tm2" 
  
  # format van time lijkt niet nodig, maar uren kunnen enkele digit zijn, moeten altijd 2 worden, ivm sorteren etc.
  clock format [clock scan "$dt $tm" -format "%d-%m-%Y %H:%M:%S"] -format "%Y-%m-%d %H:%M:%S" 
}

# convert line with fixed columns to a list, assume space as separation character (could be just one space)
proc as_list {line} {
  set str $line
  while {[regsub -all {  } $str " " str] > 0} {}
  return $str
}

main $argv
