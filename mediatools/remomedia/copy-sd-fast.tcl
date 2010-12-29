#copy-sd.tcl - split an .mp3 file, move the pieces to SD and move the original to a subdir.

set SPLITSIZE [expr 5 * 1024 * 1024] ; # 5MB.

proc copysd_main {argc argv} {
	global SPLITSIZE
	check_params $argc $argv
	set source_path [file normalize [lindex $argv 0]]
	set target_root_dir [file normalize [lindex $argv 1]]
	if {$argc == 2} {
		set split_size $SPLITSIZE 
	} else {
		set split_size [lindex $argv 2]
	}

	copy_file $source_path $target_root_dir $split_size
}

proc check_params {argc argv} {
	global argv0 stderr SPLITSIZE
	if {($argc < 2) || ($argc > 3)} {
		puts stderr "syntax: $argv0 <file.mp3> <SD-target-dir> \[splitsize, default $SPLITSIZE\]"
		exit 1
	}
}

# @return 1 if ok, 0 if not.
proc copy_file {source_path target_root_dir {split_size 5000000}} {
	global stderr
	
	puts "source: $source_path; target: $target_root_dir"

	set source_dir [file dirname $source_path]
	set source_filename [file tail $source_path]
	set temp_dir [file join $source_dir "__temp"]
	file mkdir $temp_dir
	split_file $source_path $temp_dir $split_size

	set target_dir [file join $target_root_dir [file rootname $source_filename]]
	file mkdir $target_dir
	set ok 0
	catch {
		foreach filename [glob -directory $temp_dir *] {
			puts "Moving file: $filename"
			file rename $filename [file join $target_dir [file tail $filename]]
		}
		set ok 1
	}
	# tempdir sowieso weer leegmaken.
	file delete -force $temp_dir
	# alleen moven als gehele file gekopieerd kon worden.
	if {$ok} {
		puts stderr "File copied ok, moving to archive dir ($source_filename)"
		file mkdir [file join $source_dir "onSD"]
		file rename $source_path [file join $source_dir "onSD" $source_filename]
	} else {
		puts stderr "File NOT copied ok ($source_filename), removing target dir."
		# remove target dir if empty
		if {[llength [glob -nocomplain -directory $target_dir *]] == 0} {
			file delete $target_dir
		}
	}
	return $ok
}

# @param source_path: 2007-03-24T19-02-08.mp3
# 2007-03-31T22-59-48.mp3 -> t23
proc split_file {source_path dirname split_size} {
	# global SPLITSIZE
	# return
	set basename [file root [file tail $source_path]]
	set ext [file extension [file tail $source_path]]
	set fi [open $source_path r]
	fconfigure $fi -translation binary
	set index 0
	while {![eof $fi]} {
		# set bytes [read $fi $SPLITSIZE]
		set bytes [read $fi $split_size]
		incr index
		set to_filename "[format %02d $index]-$basename$ext"
		puts "Making file: $to_filename"
		set fo [open [file join $dirname $to_filename] w]
		fconfigure $fo -translation binary
		# note evt -nonewline doen.
		puts $fo $bytes
		close $fo
	}
	close $fi
}

# @todo worden deze door haal-kinkfm gebruikt?
proc set_gehaald {source_path} {
	set source_dirname [file dirname $source_path]
	set f [open [file join $source_dirname gehaald.txt] a]
	puts $f $source_path
	close $f
}

# @todo worden deze door haal-kinkfm gebruikt?
proc strip0 {x} {
	regsub {^0} $x "" x
	if {$x == ""} {
		set x 0
	}
	return $x
}

# aanroepen vanuit cmd-line, maar ook mogelijk om vanuit Tcl te doen.
if {[file tail $argv0] == [file tail [info script]]} {
  copysd_main $argc $argv
}

