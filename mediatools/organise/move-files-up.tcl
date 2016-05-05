#!/usr/bin/env tclsh86

proc main {} {
  foreach dir [glob -directory . -type d *] {
    if {[regexp {^_} [file tail $dir]]} {
       puts "ignore dir: $dir" 
    } else {
      handle_dir . $dir 
    }
  }
}

proc handle_dir {root dir} {
  puts "handle dir: $dir" 
  foreach filename [glob -nocomplain -directory $dir -type f *] {
     puts "move $filename => .." 
     file rename -force $filename $root
  }
  foreach subdir [glob -nocomplain -directory $dir -type d *] {
    if {[regexp {^_} [file tail $subdir]]} {
      puts "ignore dir: $subdir" 
    } else {
      handle_dir $root $subdir 
    }
    
  }
  if {[llength [glob -nocomplain -directory $dir *]] == 0} {
     puts "Empty, remove: $dir"
     file delete $dir
  }
}

main
