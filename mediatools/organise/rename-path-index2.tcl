#!/usr/bin/env tclsh861

# rename files and directories in current dir and subdirs.
# replace every single digit (not connected to other digits) with a zero and the digit.
#
# eg s1e7_text => s01e07_text

proc main {argv} {
  lassign $argv root
  handle_dir $root
}

# first handle files and subdirs, then possibly dir itself.
# this is better for a dry run
proc handle_dir {dir} {
  foreach subdir [glob -nocomplain -directory $dir -type d *] {
    handle_dir $subdir
  }
  foreach filename [glob -nocomplain -directory $dir -type f *] {
    rename_path $filename
  }
  rename_path $dir
}

proc rename_path {path} {
  set path2 [add_zeroes $path]
  if {$path2 != $path} {
    puts "Rename:
$path =>
$path2
==="
    file rename $path $path2
  }
}

# other script do cleanup:
# "UNCENSORED xvid mp03 NIT158 " => nothing

# only add zeroes to last part of path
# add zero if a digit has a non-digit on both sides
# so this won't work for single digits and the start or end, shouldn't be a problem.
proc add_zeroes {path} {
  set parent [file dirname $path]
  set last [file tail $path]
  # only handle base, not the extension
  set rootname [file rootname $last]
  set extension [file extension $last]
  regsub -all {([^0-9])(\d)([^0-9])} $rootname {\10\2\3} rootname
  # have digits and start and end too, so check too.
  regsub {^(\d)([^0-9])} $rootname {0\1\2} rootname
  regsub {([^0-9])(\d)$} $rootname {\10\2} rootname
  file join $parent "$rootname$extension"
}

main $argv
