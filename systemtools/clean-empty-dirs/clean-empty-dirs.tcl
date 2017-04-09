#! /usr/bin/env tclsh

# Delete empty directories within given directories
# A directory is empty if there are no files somewhere within directory.
# They could be empty directories within directory.

package require ndv

require libio io

use libfp

set_log_global info

proc main {argv} {
  global size_handle_treshold
  set options {
    {dir.arg "" "Dir to check"}
    {debug "Set loglevel to debug"}
    {n "Do nothing, just show what would be done"}
  }
  set usage ": [file tail [info script]] \[options]:"
  set opt [getoptions argv $options $usage]
  if {[:debug $opt]} {
    $log set_log_level debug
  }
  empty_dirs [:dir $opt] $opt
}

# recursively called.
# depth-first, return number of files (not dirs) remaining in dir.
# this is used to determine if dir should be deleted.
proc empty_dirs {dir opt} {
  set nfiles 0
  foreach subdir [glob -nocomplain -directory $dir -type d *] {
    incr nfiles [empty_dirs $subdir $opt]
  }
  foreach subdir [glob -nocomplain -directory $dir -type d .*] {
    set dir2 [file tail $subdir]
    if {($dir2 != ".") && ($dir2 != "..")} {
      incr nfiles [empty_dirs $subdir $opt]  
    }
    
  }
  
  incr nfiles [count [glob -nocomplain -directory $dir -type f *]]
  incr nfiles [count [glob -nocomplain -directory $dir -type f .*]]

  if {$nfiles <= 0} {
    log info "Empty dir, delete: $dir"
    if {[:n $opt]} {
      log info "-n given, do nothing"
    } else {
      file delete $dir;         # should work without force, dir should already be empty here.
    }
  }
  return $nfiles
}

main $argv

