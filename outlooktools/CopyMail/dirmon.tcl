proc main {argv} {
  set config [lindex $argv 0]
  set include_subdirs 0
  set freq_sec 60
  set dirs {}
  set outfile "dirmon.tsv"
  
  source $config

  monitor $freq_sec $dirs $include_subdirs $outfile
}

proc monitor {freq_sec dirs include_subdirs outfile} {
  set f [open $outfile w]
  puts $f [join [list ts dir nfiles] "\t"]
  close $f

  while {1} {
	set start_msec [clock milliseconds]
	foreach dir $dirs {
	  set ts [current_time]
	  set n [det_nfiles $dir $include_subdirs]
	  set f [open $outfile a]
	  puts $f [join [list $ts $dir $n] "\t"]
	  close $f
	}
	set end_msec [clock milliseconds]
	set wait_msec [expr round(1000*$freq_sec - ($end_msec - $start_msec))]
	puts "waiting msec: $wait_msec"
	after $wait_msec
  }
}

# determine number of files (not dirs) in subdir, possibly including subdirs.
proc det_nfiles {dir include_subdirs} {
  if {![file exists $dir]} {
    error "Not found: $dir"
  }
  if {$include_subdirs} {
	set nfiles 0
	set dirs_to_check [list $dir]
	while {$dirs_to_check != {}} {
	  set dir1 [lindex $dirs_to_check 0]
	  set dirs_to_check [lrange $dirs_to_check 1 end]
	  foreach subdir [glob -nocomplain -directory $dir1 -type d *] {
	    lappend dirs_to_check $subdir
	  }
	  incr nfiles [llength [glob -nocomplain -directory $dir1 -type f *]]
	}
	return $nfiles
  } else {
    return [llength [glob -nocomplain -directory $dir -type f *]]
  }
}

proc current_time {} { 
  set msec [clock milliseconds]
  set sec [expr $msec / 1000]
  set msec2 [expr $msec % 1000]
  return "[clock format $sec -format "%Y-%m-%d %H:%M:%S.[format %03d $msec2] %z"]"
}

main $argv
