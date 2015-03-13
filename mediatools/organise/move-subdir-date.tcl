#!/usr/bin/env tclsh86

# move media files to a subdir with name = date
# only move files bigger than treshold of 1MB.
# also only move if date can be found in the filename (YYYY-MM-DD)

set SIZE_TRESHOLD 1e6
proc main {argv} {
  global SIZE_TRESHOLD
  lassign $argv root_dir
  foreach filename [glob -directory $root_dir *] {
    if {[regexp {(\d{4}-\d{2}-\d{2})} [file tail $filename] z date]} {
      if {[file size $filename] >= $SIZE_TRESHOLD} {
        move_file $root_dir $filename $date
      }
    }
  }
}

proc move_file {root_dir filename date} {
  set subdir [file join $root_dir $date]
  file mkdir $subdir
  file rename $filename [file join $subdir [file tail $filename]]
}

main $argv
