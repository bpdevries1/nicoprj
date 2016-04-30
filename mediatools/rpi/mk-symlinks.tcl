#!/usr/bin/env tclsh

proc main {argv} {
  global argv0 stderr
  lassign $argv orig_dir link_dir
  if {$orig_dir == ""} {
    puts stderr "syntax: $argv0 <orig_dir> <symlinks_dir>"
    exit 1
  }
  if {$link_dir == ""} {
    # set link_dir .
    set link_dir "/media/shortcuts-links"
  }
  # make_links $orig_dir $link_dir
  make_links [file normalize $orig_dir] [file normalize $link_dir]
}

# @param orig_dir and link_dir are at the same level
# with recursive calls they both go a dir-level deeper.
proc make_links {orig_dir link_dir} {
  file mkdir $link_dir
  if {[llength [glob -nocomplain -directory $link_dir *]] == 0} {
    # ok, empty dir, can be used as target
  } else {
    # already dir with files/dirs, create a subdir based on orig_dir in this one.
    set link_dir [file join $link_dir [file tail $orig_dir]]
    puts "Creating link_dir as sub dir: $link_dir"
    file mkdir $link_dir
  }
  
  foreach filename [glob -nocomplain -directory $orig_dir -type f *] {
    set link_name [file join $link_dir [file tail $filename]]
    file delete $link_name
    file link -symbolic $link_name $filename
  }
  foreach subdir [glob -nocomplain -directory $orig_dir -type d *] {
    make_links $subdir [file join $link_dir [file tail $subdir]]
  }
}

# file link -symbolic linkName ?target? 

main $argv

