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
  handle_tables $db
  $db close
}

proc handle_tables {db} {
  log info "Handle tables"

  set tables [$db tables]
  # breakpoint
  foreach table [dict keys $tables] {
    handle_table $db $table
  }
}

proc handle_table {db table} {
  # breakpoint
  set fieldnames [dict keys [$db fields $table]]
  log info "Handle table: $table (nfields: [count $fieldnames])"
  # breakpoint
  if {![regexp -nocase {_pdh_csv_} [first $fieldnames]]} {
    log debug "Not a typeperf table, return: $table"
    return
  }
  set tsfield "ts_localtz"
  if {[lsearch -exact $fieldnames $tsfield] >= 0} {
    log debug "Extra timestamp field already exists, return: $table.$tsfield"
    return
  }
  # ok, source field exists, target field does not.
  $db exec "alter table $table add $tsfield"
  set src [first $fieldnames]
  set expression "substr($src, 7, 4) || '-' || substr($src, 1, 2) || '-' || substr($src, 4, 2) || substr($src, 11)"
  $db exec "update $table set $tsfield = $expression"
}

main $argc $argv


