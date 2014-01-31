#!/usr/bin/env tclsh86

# scripts2metadb.tcl - import Keynote download config.csv into slotmeta.db

package require tdbc::sqlite3
package require Tclx
package require ndv
package require json

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]
$log set_file "[file tail [info script]].log"

# ndv::source_once libslotmeta.tcl download-metadata.tcl
ndv::source_once libslotmeta.tcl

proc main {argv} {
  log debug "argv: $argv"
  set options {
    {db.arg "c:/projecten/Philips/KNDL/slotmeta-scripts.db" "Directory to put downloaded keynote files and also slotmeta.db"}
    {dir.arg "c:/projecten/Philips/Keynote-scripts" "Directory with script files to read"}
    {test "Test the script, just download a few hours of data"}       
  }
  set usage ": [file tail [info script]] \[options] :"
  # set dargv [::cmdline::getoptions argv $options $usage]
  set dargv [getoptions argv $options $usage]
  scripts2metadb $dargv
}

proc scripts2metadb {dargv} {
  set db [get_slotmeta_db [:db $dargv]]
  $db create_tables 0 ; # because added a def
  # $db add_tabledef script {id} {filename path slot_id ts_cet {filesize int} contents}
  $db in_trans {
    foreach path [glob -directory [:dir $dargv] -type f "*.krs"] {
      set filename [file tail $path]
      set slot_id [det_slot_id $filename]
      set ts_cet [clock format [file mtime $path] -format "%Y-%m-%d %H:%M:%S"]
      set filesize [file size $path]
      set contents [read_file $path]
      $db insert script [vars_to_dict filename path slot_id ts_cet filesize contents]
    }
  }
  $db close
}

proc det_slot_id {filename} {
  if {[regexp {KN-(\d+)\.krs} $filename z slot_id]} {
    return $slot_id
  } else {
    error "Could not determine slot_id from: $filename"
  }
}

main $argv

