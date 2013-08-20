#!/usr/bin/env tclsh86

# setsizes-urls.tcl

package require Tclx
package require ndv
package require tdbc::sqlite3

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]
$log set_file "[file tail [info script]].log"

proc main {argv} {
  global dct_argv
  log debug "argv: $argv"
  set options {
    {dir.arg "c:/projecten/Philips/Mobile-CN/" "Directory where downloaded files are"}
    {db.arg "C:/projecten/Philips/KN-analysis/Mobile-landing-CN/keynotelogs.db" "SQLite DB location"}
    {debug "Run in debug mode, stop when an error occurs"}
  }
  set usage ": [file tail [info script]] \[options] :"
  set dct_argv [::cmdline::getoptions argv $options $usage]
  set db_name [:db $dct_argv]
  set db [dbwrapper new $db_name]
  handle_files [:dir $dct_argv] $db
}

proc handle_files {dir db} {
  log debug "handle_files $dir $db"
  foreach filename [glob -type f -directory $dir *] {
    handle_file $filename $db 
  }
}

proc handle_file {filename db} {
  set size [file size $filename]
  if {[regexp {HEALTHCARE} $filename]} {
    set filename "HEALTHCARE" 
  }
  if {[file tail $filename] == "m.philips.com.cn"} {
    set query "update urlsize set size = $size where url = 'http://m.philips.com.cn/'"
  } else {
    set query "update urlsize set size = $size where url like '%' || '[file tail $filename]' || '%'"
  }
  log debug "query: $query"
  $db exec $query
}

main $argv

