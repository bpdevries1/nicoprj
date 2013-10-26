#!/usr/bin/env tclsh86

package require tdbc::sqlite3
package require Tclx
package require ndv

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]
$log set_file "[file tail [info script]].log"

proc main {argv} {
  global conn stmt_insert
  set root_dir "."
  set db_name [file join $root_dir "atglogs.db"]
  set conn [open_db $db_name]
  set table_def [make_table_def atglogs filename linenr ts level class message]
  create_table $conn $table_def 1
  set stmt_insert [prepare_insert_td $conn $table_def]
  set filename "testje.log"
  set linenr 12
  set ts "2013-10-12"
  set level "INFO"
  set class "ab.c.d"
  set message "stukje bericht"
  set dct_msg [vars_to_dict filename linenr ts level class message]
  stmt_exec $conn $stmt_insert $dct_msg
  $conn close
  log info "Closed, exiting"
  # @todo vraag of 'ie zonder de exit ook stopt...
  exit
}

main $argv

