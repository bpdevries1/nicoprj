# losse main-file om dynamisch aan te kunnen passen

set debug 0

proc main {argv} {
  global argv0 debug
  lassign $argv config
  if {$config == ""} {
    puts "syntax: $argv0 <config.tcl>"
    exit 1
  }
  source $config

  show_files $target_folder
}

proc show_files {dir} {
  foreach file [glob -directory $dir -type f *] {
	puts "[file_time $file] - [file tail $file]"
  }
}

proc file_time {file} { 
  # set msec [clock milliseconds]
  set sec [file mtime $file]
  # set msec2 [expr $msec % 1000]
  return [clock format $sec -format "%Y-%m-%d %H:%M:%S"]
}

main $argv
