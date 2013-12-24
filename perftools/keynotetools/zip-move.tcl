#!/usr/bin/env tclsh86

# @todo also make this script working on PC/linux: config-file and/or cmdline params.

package require Tclx
package require ndv

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]
$log set_file "[file tail [info script]].log"

proc main {argv} {
  set root_src "c:/projecten/Philips/KNDL"
  set root_target "w:/archief/Ymor/Philips/KNDL-loadPC"
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
  # 16-10-2013 if file copy fails (w: not available or disk full), the script should stop here.
  #            next time a new zip will be made and copied to w:, then dir will be completely deleted.
  #            so the old zip will be deleted as well (good) and the old zip will not be included
  #            in the new zip (good as well).
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
  set zip_exe "c:/util/cygwin/bin/zip.exe"
  exec $zip_exe $name *.json
  return [file join $dir $name]
}

main $argv
