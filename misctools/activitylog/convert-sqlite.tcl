# convert activitylog tsv files to sqlite db format.

package require ndv
package require Tclx
package require sqlite3

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]

proc main {argc argv} {
  set tsv_filename [lindex $argv 0]
  set db_filename "[file rootname $tsv_filename].db"
  handle_logfile $tsv_filename $db_filename
}

proc handle_logfile {tsv_filename db_filename} {
	global log
  set fin [open $tsv_filename r]
  create_db $db_filename	
  while {![eof $fin]} {
		gets $fin line
		# log $line
		set lst [split $line "\t"]
		if {[llength $lst] != 4} {
			$log warn "Not 4 items in line (#[llength $lst]): $line" 
			continue
		}
		lassign $lst ts_start ts_end duration title
		regsub -all {_} $ts_start " " ts_start
		regsub -all {_} $ts_end " " ts_end
		# db eval "insert into event (ts_start, ts_end, time, title) values ('$ts_start', '$ts_end', $duration, '$title')"
		# set query "insert into event (ts_start, ts_end, time, title) values ('$ts_start', '$ts_end', $duration, '$title')"
		set query {insert into event (ts_start, ts_end, time, title) values ($ts_start, $ts_end, $duration, $title)}
		$log debug "query: $query"
		db eval $query
	}
	close $fin
	db close
}

proc create_db {db_name} {
  sqlite3 db $db_name
  db eval "drop table if exists event"
  db eval "create table if not exists event (id integer primary key autoincrement, ts_start, ts_end, time, title)"  
}

main $argc $argv
