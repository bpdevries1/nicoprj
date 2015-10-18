#!/usr/bin/env tclsh

proc main {argv} {
  global argv0 stderr
  lassign $argv orig_dir link_dir
  if {$orig_dir == ""} {
    puts stderr "syntax: $argv0 <orig_dir> <symlinks_dir>"
    exit 1
  }
  if {$link_dir == ""} {
    set link_dir .
  }
  # make_links $orig_dir $link_dir
  make_links [file normalize $orig_dir] [file normalize $link_dir]
}

# @param orig_dir and link_dir are at the same level
# with recursive calls they both go a dir-level deeper.
proc make_links {orig_dir link_dir} {
  file mkdir $link_dir
  foreach filename [glob -nocomplain -directory $orig_dir -type f *] {
    file delete [file join $link_dir [file tail $filename]]
    file link -symbolic [file join $link_dir [file tail $filename]] $filename
  }
  foreach subdir [glob -nocomplain -directory $orig_dir -type d *] {
    make_links $subdir [file join $link_dir [file tail $subdir]]
  }
}

# file link -symbolic linkName ?target? 

main $argv

