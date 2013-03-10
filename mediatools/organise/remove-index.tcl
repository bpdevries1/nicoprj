package require ndv

proc main {argv} {
  lassign $argv dir
  handle_dir_rec $dir * rename_file
}

# @param filename: full path.
proc rename_file {filename rootdir} {
  set dir [file dirname $filename]
  set fn [file tail $filename]
  if {[regexp {^(\d+.? )(.*)$} $fn z ndx fn2]} {
    puts "rename $filename ->  [file join $dir $fn2]"
    file rename $filename [file join $dir $fn2] 
  }
}

main $argv
