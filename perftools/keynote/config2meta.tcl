#!/usr/bin/env tclsh86

# config2meta.tcl - import Keynote download config.csv into slotmeta.db

package require tdbc::sqlite3
package require Tclx
package require ndv
package require json

set log [::ndv::CLogger::new_logger [file tail [info script]] info]
$log set_file "[file tail [info script]].log"

ndv::source_once libslotmeta.tcl

proc main {argv} {
  log debug "argv: $argv"
  set options {
    {dir.arg "c:/projecten/Philips/KNDL" "Directory to put downloaded keynote files and also slotmeta.db"}
    {config.arg "config.csv" "Config file name to read"}
    {test "Test the script, just download a few hours of data"}       
  }
  set usage ": [file tail [info script]] \[options] :"
  # set dargv [::cmdline::getoptions argv $options $usage]
  set dargv [getoptions argv $options $usage]
  read_config $dargv
}

# @todo? check if slot_id already exists?
proc read_config {dargv} {
  set db [get_slotmeta_db [file join [:dir $dargv] slotmeta.db]]
  set dctl_config [csv2dictlist [file join [:dir $dargv] [:config $dargv]] ";"]
  set download_pc [det_download_pc [:config $dargv]]
  set download_order 1
  set start_date "2013-01-01"
  set end_date "9999-12-31"
  set ts_create_cet [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]
  set ts_update_cet $ts_create_cet
  foreach el $dctl_config {
    # elements: dirname;slotids;npages
    set dct [vars_to_dict download_pc download_order start_date end_date ts_create_cet ts_update_cet]
    dict set dct dirname [:dirname $el]
    dict set dct slot_id [:slotids $el]
    dict set dct npages [:npages $el]
    $db insert slot_download $dct
    incr download_order
  }  
  $db close
}

proc det_download_pc {config_name} {
  if {[regexp -- {-win.csv} $config_name]} {
    return "NLYEHVSCE1NBZPZ"
  }
  if {[regexp -- {-linux.csv} $config_name]} {
    return "nico-MS-7760"
  }
  error "Cannot determine PC name from config name: $config_name"
}

main $argv
