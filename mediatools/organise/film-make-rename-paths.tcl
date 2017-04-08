#!/usr/bin/env tclsh

# goal - rename movie dirs and files to canonical format.

package require ndv

ndv::source_once libfilm.tcl

set_log_global info

proc main {argv} {
  set films_root "/home/media/Films/_tijdelijk"
  
  set move_name [file join $films_root "move-films.txt"]
  file delete $move_name

  # TODO: eerst even alleen de nieuwe, 00_new.
  # deze volgorde net andersom, zou met hernoemen van 2-3-4 naar 1-2-3 beter moeten gaan.
  foreach dir [lsort -decreasing [glob -directory $films_root -type d 01*]] {
    make_move $dir $move_name  
  }
  
  puts "gedit $move_name"
  exec gedit $move_name &
}

# rename dirs with films etc inside.
# also rename single files, and put in dir with same name.
# TODO: keep target-dirs (full path) - if the same would be created, add a sequence number.
proc make_move {root_dir move_name} {
  puts "Handling: $root_dir"
  set fo [open $move_name a]
  foreach path [lsort [glob -directory $root_dir *]] {
    handle_path $root_dir $path $fo
  }
  close $fo
}

# a dir should be renamed.
# a file should not be renamed, but put in a subdir with the renamed name.
# TODO: check if this is idempotent. Expect it to be because of sorting the dir.
proc handle_path {root_dir path fo} {
  set path_type [file type $path]
  set dir_new [det_dir_new [file tail $path]]
  set path_new [file join $root_dir $dir_new]
  set path_new2 [add_suffix $path $path_new]
  if {$path != $path_new2} {
    puts $fo "\n"
    puts $fo "path     : $path"
    puts $fo "root     : $root_dir"
    puts $fo "path_orig: $path"
    puts $fo "path_type: $path_type"
    puts $fo "dir_new  : $dir_new"
    puts $fo "path_new : $path_new2"
    puts $fo "action   : move"
    puts $fo "------------------------------------------"
  }
}

main $argv

