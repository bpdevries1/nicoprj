# std packages
package require Tclx
package require csv
package require struct::list
package require struct::matrix
package require math

# eigen package
package require ndv

use libfp

proc main {argc argv} {
  global env ar_argv

  set options {
    {dir.arg "" "Directory with SQLite DB with read typeperf files."}
    {db.arg "perfmon.db" "Database name"}
    {config.arg "stats.tcl" "Config file with time segments to use etc."}
    {loglevel.arg "info" "Set global log level"}
  }
  set usage ": [file tail [info script]] \[options] :"
  # array set ar_argv [::cmdline::getoptions argv $options $usage]
  set opt [getoptions argv $options $usage]
  # array set ar_argv $opt
  set_log_global [:loglevel $opt]
  
  # check_params $argc $argv
  # set root_dir [lindex $argv 0]
  set root_dir [:dir $opt]
  # regsub -all {\\} $root_dir "/" root_dir
  set root_dir [file normalize $root_dir]
  # puts "root_dir: $root_dir"
  # for_recursive_glob filename $root_dir "*typeperf*.csv" {}
  set dbname [file join $root_dir [:db $opt]]
  set db [dbwrapper new $dbname]
  $db load_percentile
  source [file join $root_dir [:config $opt]]
  make_stats $db $segments
  $db close
}

proc make_stats {db segments} {
  $db def_datatype {.*_val} float
  $db add_tabledef stats {id} {segm_start segm_end tablename fieldname min_val avg_val max_val p95_val}
  $db create_tables
  $db exec "delete from stats"
  # $db prepare_insert_statements
  set tables [$db tables]
  # breakpoint
  foreach table [dict keys $tables] {
    handle_table $db $table $segments
  }
  
}

proc handle_table {db table segments} {
  # breakpoint
  set fieldnames [dict keys [$db fields $table]]
  log info "Handle table: $table (nfields: [count $fieldnames])"

  if {![regexp -nocase {_pdh_csv_} [first $fieldnames]]} {
    log debug "Not a typeperf table, return: $table"
    return
  }

  # remove first and last fields (timestamps)
  set fieldnames [lrange $fieldnames 1 end-1]
  $db in_trans {
    foreach field $fieldnames {
      handle_table_field $db $table $field $segments
    }
  }
}

# insert records into stats table with stats for <field> in <table> and all segments
proc handle_table_field {db table field segments} {
  foreach segment $segments {
    handle_table_field_segment $db $table $field $segment
  }
}

# insert records into stats table with stats for <field> in <table> for <segment>
proc handle_table_field_segment {db table field segment} {
  # $db add_tabledef stats {id} {segm_start segm_end tablename fieldname min_val avg_val max_val p95_val}
  lassign $segment segm_start segm_end
  set query "insert into stats (segm_start, segm_end, tablename, fieldname, min_val, avg_val, max_val, p95_val)
  select '$segm_start', '$segm_end', '$table', '$field', min($field), avg($field), max($field), percentile($field, 95)
  from $table
  where ts_localtz between '$segm_start' and '$segm_end'
  and $field is not null
  and trim($field) <> ''
  group by 1,2,3,4"

  log debug "query: $query"
  $db exec $query
}

main $argc $argv


