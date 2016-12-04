# Miscellaneous procs
proc puts_warn {srcfile linenr text} {
  puts "[file tail  $srcfile] \($linenr\) WARN: $text"
}

# One generic place to determine perftools dir. Is close to dir of buildtool, but
# in different branch.
# maybe later set in .bld/config.tcl or better in ~/.config/buildtool/env.tcl
proc perftools_dir {} {
  set res [file normalize [file join [info script] .. .. .. perftools]]
  if {![file exists $res]} {
    puts "WARNING: perftools_dir not found: $res"
  }
  return $res
}

# puts "perftools_dir: [perftools_dir]"

