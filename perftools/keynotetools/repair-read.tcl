#!/usr/bin/env tclsh86

# repair-read.tcl - repair chains of 'read' subdirectories within KNDL

# later also everything for a day in a DB.
# @todo could have two DB connections, and insert parsed data into both!
# @todo and one main DB with has everything except the details, but includes scriptrun and page, see how big this gets.
# en in DB kijken of je deze al gedaan hebt.

package require tdbc::sqlite3
package require Tclx
package require ndv
package require json

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]
$log set_file "[file tail [info script]].log"

proc main {argv} {
  set root_dir "c:/projecten/Philips/KNDL"
  foreach dir [glob -directory $root_dir -type d *] {
    handle_dir $dir 
  }
}

proc handle_dir {dir} {
  # first check and report on how many dirs the problem exists
  if {[file exists [file join $dir read read]]} {
    log warn "read/read dir found in: $dir" 
  }
}

main $argv

