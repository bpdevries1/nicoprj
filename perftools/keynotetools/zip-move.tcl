#!/usr/bin/env tclsh86

package require Tclx
package require ndv

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]
$log set_file "[file tail [info script]].log"

proc main {argv} {
  set root_src "c:/projecten/Philips/KNDL"
  set root_target "w:/archief/Ymor/Philips/KNDL"
  file mkdir $root_target
  foreach dir [glob -directory $root_src -type d *] {
    handle_dir [file join $dir] $root_target 
  }
}

# only move from read-dir to target-dir
proc handle_dir {dir root_target} {
  log info "handle_dir: $dir"
  set read_dir [file join $dir read]
  if {[llength [glob -nocomplain -directory $read_dir *.json]] == 0} {
    log info "No files in $read_dir, continue"
    return
  }
  
  set zip_name [zip_files $read_dir]
  set target_dir [file join $root_target [file tail $dir]]
  file mkdir $target_dir
  # breakpoint
  file copy $zip_name $target_dir
  # breakpoint
  file delete $zip_name
  # delete whole dir and then recreate is possibly faster than deleting each file.
  # breakpoint
  file delete -force $read_dir
  file mkdir $read_dir
  
  # exit ; # for test
}

proc zip_files {dir} {
  set name "[file tail [file dirname $dir]]-[clock format [clock seconds] -format "%Y-%m-%d--%H-%M-%S"].zip" 
  cd $dir
  log debug "zipping json files in $dir => $name"
  # breakpoint
  exec zip $name *.json
  return [file join $dir $name]
}

main $argv
