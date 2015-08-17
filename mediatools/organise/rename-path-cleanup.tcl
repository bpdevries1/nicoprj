#!/usr/bin/env tclsh861

# rename files and directories in current dir and subdirs.
# replace every 'cleanup' string with an empty string

set regexps {
  "\.720p.HDTV.x264-maximersk"
  "\.720p.BluRay.x264.anoXmous_"
  ".720p.HDTV.*"
  ".HDTV.x264.*"
}

set todo {

  
}

proc main {argv} {
  lassign $argv root really
  handle_dir $root $really
}

# first handle files and subdirs, then possibly dir itself.
# this is better for a really run
proc handle_dir {dir really} {
  foreach subdir [glob -nocomplain -directory $dir -type d *] {
    handle_dir $subdir $really
  }
  foreach filename [glob -nocomplain -directory $dir -type f *] {
    rename_path $filename $really
  }
  rename_path $dir $really
}

proc rename_path {path really} {
  set path2 [cleanup $path]
  if {$path2 != $path} {
    puts "Rename:
$path =>
$path2
==="
    if {$really == "-r"} {
      file rename $path $path2
    }
  }
}

proc cleanup {path} {
  global regexps
  set parent [file dirname $path]
  set last [file tail $path]
  # only handle base, not the extension
  set rootname [file rootname $last]
  set extension [file extension $last]
  foreach re $regexps {
    regsub -all $re $rootname "" rootname
  }
  file join $parent "$rootname$extension"
}

main $argv
