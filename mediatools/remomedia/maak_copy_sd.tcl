# note: car-player snapt .m4a niet.

set MAX_SINGLES 150


proc main {argc argv} {
	global stderr argv0 MAX_SINGLES curr_index
	
	set to_drive [lindex $argv 0]
	if {$argc == 2} {
		set what [lindex $argv 1]
	} else {
		set what ""
	}
	if {$to_drive == ""} {
		puts stderr "syntax: $argv0 <to_drive:\\> [<what>], got: $argv" 
		exit 1
	}
	set curr_index 0
	while {(![eof stdin]) && ($curr_index < $MAX_SINGLES)} {
		gets stdin line
		if {[is_ok $line]} {
			make_copy_line $line $to_drive $what
			incr curr_index
		}
	}
}

proc is_ok {filename} {
	if {$filename == ""} {
		return 0
	}
	set ext [file extension $filename]
	if {$ext == ".m4a"} {
		return 0
	} else {
		return 1
	}
}

set prev_dir ""

proc make_copy_line {pathname to_drive what} {
	global prev_dir

	set to_dir [det_to_dir $pathname $what]
	set to_file [file tail $pathname]
	
	if {$to_dir != $prev_dir} {
		puts "mkdir \"[sub_slash [file join $to_drive $to_dir]]\""
		set prev_dir $to_dir
	}
	puts [sub_slash "copy \"$pathname\" \"[file join $to_drive $to_dir $to_file]\""] 
}

proc det_to_dir {pathname what} {
	global curr_index
	if {$what == "singles"} {
		# generatie dir<xxx> names, vanaf 001, door met 10 te beginnen.
		set to_dir [format "dir%03d" [expr 1 + $curr_index / 10]]
	} else {
		set l [file split $pathname]
		set to_dir [lindex $l end-1]
	}
	return $to_dir
}

proc sub_slash {str} {
	regsub -all "/" $str "\\" str
	return $str
}

main $argc $argv
