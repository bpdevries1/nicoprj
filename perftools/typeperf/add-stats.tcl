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
  set config_file [file join $root_dir [:config $opt]]
  if {[file exists $config_file]} {
    source $config_file
  } else {
    log warn "Config file not found: $config_file"
    return
  }
  make_counternames $db
  make_stats $db $segments
  $db close
}

proc make_counternames {db} {
  $db add_tabledef countername {id} {tablename fieldname csvfield computer object instance counter}
  $db create_tables
  $db prepare_insert_statements
  $db exec "delete from countername"
  foreach row [$db query "select tablename, fieldname, csvfield from _csvdbmap"] {
    set parts [det_counter_parts [:csvfield $row]]
    $db insert countername [dict merge $row $parts]
  }
}

# return dict with perfmon counter parts: computer, object, instance, counter
# \\WSRV4275\SQLServer:General Statistics\Non-atomic yield rate
# \\WSRV4275\Process(cmd)\% Processor Time
proc det_counter_parts {csvfield} {
  # field can either start with double backslash (computer included) or not
  if {![regexp {^\\\\([^\\]+)(.*)$} $csvfield z computer rest]} {
    set computer "unknown"
    set rest $csvfield
  }
  set lst [split $rest "\\"]
  # only take last 2 items
  set lst2 [lrange $lst end-1 end]
  lassign $lst2 object counter
  # object could have instance between parens
  if {[regexp {^([^()]+)\(([^()]+)\)} $object z obj2 inst]} {
    set object $obj2
    set instance $inst
  } else {
    set instance ""
  }
  vars_to_dict computer object instance counter
}

proc make_stats {db segments} {
  catch {$db exec "drop table stats"}
  $db def_datatype {.*_val} float
  $db add_tabledef stats {id} {segm_start segm_end segm_name tablename fieldname min_val avg_val max_val p95_val}
  $db create_tables
  # $db exec "delete from stats"
  # $db prepare_insert_statements
  set tables [$db tables]
  # breakpoint
  foreach table [dict keys $tables] {
    handle_table $db $table $segments
  }
  set query "delete from stats
             where fieldname like '%process\\_%' escape '\\'
             and (fieldname like '%total%' or fieldname like '%idle%')"
  $db exec $query
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
  lassign $segment segm_start segm_end segm_name
  set query "insert into stats (segm_start, segm_end, segm_name, tablename, fieldname, min_val, avg_val, max_val, p95_val)
  select '$segm_start', '$segm_end', '$segm_name', '$table', '$field', min($field), avg($field), max($field), percentile($field, 95)
  from $table
  where ts_localtz between '$segm_start' and '$segm_end'
  and $field is not null
  and trim($field) <> ''
  group by 1,2,3,4"

  log debug "query: $query"
  $db exec $query
}

main $argc $argv


