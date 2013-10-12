#!/usr/bin/env tclsh86

proc main {} {
  set root_dir "/media/nas/backups/PhilipsLaptop/c/projecten/Philips/KNDL"
  foreach dir [glob -type d -directory $root_dir *] {
    handle_dir $dir 
  }
}

proc handle_dir {dir} {
  puts "handle_dir: $dir"
  # remove all json files directly under the dir (ie not in 'read' subdir)
  foreach filename [glob -nocomplain -directory $dir -type f "*.json"] {
    # puts "delete: $filename"
    file delete $filename 
  }
}

main
