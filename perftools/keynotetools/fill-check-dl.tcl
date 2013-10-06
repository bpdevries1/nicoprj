#!/usr/bin/env tclsh86

# fill-check-dl.tcl - fill check-dl.db with filenames from keynotelogs.db
# goal: not to download all files again.

package require tdbc::sqlite3
package require Tclx
package require ndv

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]
$log set_file "[file tail [info script]].log"

set script_dir [file dirname [info script]]
source [file join $script_dir download-check.tcl]

proc main {argv} {
  set root_dir "c:/projecten/Philips/KNDL"
  set dl_check [DownloadCheck new $root_dir]
  set i 0
  # $dl_check set_read $filename ok
  foreach subdir [lsort [glob -nocomplain -directory $root_dir -type d *]] {
    log info "handle dir: $subdir"
    $dl_check trans_start
    
    set db_name [file join $subdir "keynotelogs.db"] 
    set db [dbwrapper new $db_name]
    set query "select path from logfile"
    foreach row [$db query $query] {
      $dl_check set_read [:path $row] ok 
    }
    
    $db close
    $dl_check trans_commit  
  }

  $dl_check close
  $dl_check destroy
}

main $argv

