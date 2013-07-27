#!/usr/bin/env tclsh86

# make-symlinks-car.tcl

package require ndv
source ../lib/libmusic.tcl

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]
$log set_file "[file tail [info script]].log"

proc main {argv} {
  if {[llength $argv] == 0} {
    set src_dir "/media/nas/media/Music/Singles"
    set target_dir "/media/nas/media/Music/singles-auto"
  } else {
    lassign $argv src_dir target_dir
  }
  log info "Creating symlinks in $target_dir pointing to $src_dir"
  file mkdir $target_dir
  handle_dir_rec $src_dir "*" [list make_symlink $target_dir]
}

proc make_symlink {target_dir filename root_dir} {
  log debug "make_symlink: $target_dir $filename $root_dir"
  if {[is_music_file $filename]} {
    log debug "Music file: making symlink for: $filename" 
    set target_name [file join $target_dir [string range $filename [string length $root_dir]+1 end]]
    log debug "Target name: $target_name"
    file mkdir [file dirname $target_name]
    # @note tcl manual uses different descriptions.
    file link -symbolic $target_name $filename
  } else {
    log debug "Ignore file: $filename" 
  }
  # exit
}

main $argv
