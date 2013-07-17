#!/usr/bin/env tclsh86

# logls2db - convert output of ls -R within Akamai ftp to a sqlite db.

package require tdbc::sqlite3
package require Tclx
package require ndv

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]
$log set_file "curlgetheader.log"

proc main {argv} {
  lassign $argv ls_filename db_name
  set conn [open_db $db_name]
    
  close_db $conn
}

main $argv
