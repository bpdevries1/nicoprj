#!/usr/bin/env tclsh86

# tablecopy.tcl - copy table(s) from one sqlite DB to another.

package require tdbc::sqlite3
package require Tclx
package require ndv

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]
$log set_file "[file tail [info script]].log"

proc main {argv} {
  global dct_argv
  log debug "argv: $argv"
  set options {
    {fromdb.arg "" "DB to copy table(s) from"}
    {todb.arg "" "DB to copy table(s) to"}
    {tables.arg "" "Tables to copy (comma seperated)"}
    {debug "Run in debug mode, stop when an error occurs"}
  }
  set usage ": [file tail [info script]] \[options] :"
  set dargv [::cmdline::getoptions argv $options $usage]

  copy_tables [from_cygwin [:fromdb $dargv]] [from_cygwin [:todb $dargv]] [:tables $dargv]
}

proc copy_tables {fromdbname todbname tables} {
  #ATTACH DATABASE "myother.db" AS aDB;
  # CREATE TABLE newTableInDB1 AS SELECT * FROM aDB.oldTableInMyOtherDB;
  log info "Copying tables from $fromdbname => $todbname"
  set db [dbwrapper new $todbname]
  $db exec "attach database '$fromdbname' as fromDB"
  foreach table [split $tables ","] {
    log info "Copying table $table"
    $db exec "create table $table as select * from fromDB.$table"
  }
  $db close
}

main $argv

# example:
# ./tablecopy.tcl -fromdb c:/projecten/philips/kn-analysis/Mobile-landing-CN/keynotelogs.db -todb c:/projecten/philips/kn-analysis/Mobile-landing-CN-20130813/keynotelogs.db -tables urlsize

