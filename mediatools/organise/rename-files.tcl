#!/home/nico/bin/tclsh

source [file join [file dirname [info script]] .. lib libmusic.tcl]

set PREFIX_TRESHOLD 6

proc main {argc argv} {
	set dirname [lindex $argv 0]
	remove_prefix $dirname
	remove_parenthesis $dirname
}

proc remove_prefix {dirname} {
	global PREFIX_TRESHOLD
	set lst_files {}
	foreach filename [glob -nocomplain -directory $dirname -type f -tails *] {
		if {[is_music_file $filename]} {
			lappend lst_files $filename
		}
	}
	
	set common_prefix [det_common_prefix $lst_files]
	if {[string length $common_prefix] >= $PREFIX_TRESHOLD} {
		puts "Removing common prefix: $common_prefix"
		set lst_files_to [remove_common_prefix $lst_files $common_prefix]
		for {set i 0} {$i < [llength $lst_files]} {incr i} {
			set from_file [lindex $lst_files $i]
			set to_file [lindex $lst_files_to $i]
			puts "Renaming: $from_file => $to_file"
			file rename [file join $dirname $from_file] [file join $dirname $to_file]
		}
	} else {
		puts "Common prefix too short (< $PREFIX_TRESHOLD): $common_prefix"
	}
}

proc det_common_prefix {lst_files} {
	if {[llength $lst_files] < 2} {
		puts "Warning: less than 2 files: $lst_files, returning"
		return ""
	}
	set lst_files [lsort $lst_files]
	set first_file [string tolower [lindex $lst_files 0]]
	set last_file [string tolower [lindex $lst_files end]]
	set first_len [string length $first_file]
	set last_len [string length $last_file]
	if {$first_len < $last_len} {
		set len $first_len
	} else {
		set len $last_len
	}

	set i 0
	set same 1
	while {$same && ($i < $len)} {
		if {[string range $first_file $i $i] == [string range $last_file $i $i]} {
			incr i
		} else {
			set same 0
		}
	}
	set result [string range $first_file 0 [expr $i - 1]]
	# verwijder cijfers op het einde
	regsub {[0-9]+$} $result "" result
	return $result
}

proc remove_common_prefix {lst_files common_prefix} {
	set result {}
	# als common prefix 2 tekens lang, dan bij teken 2 beginnen (en 0 en 1 overslaan)
	set start_index [string length $common_prefix]
	foreach el $lst_files {
		lappend result [string trim [string range $el $start_index end]]
	}
	return $result
}

# zet vorm (01) liedje om in 01. liedje
proc remove_parenthesis {dirname} {
	foreach filename [glob -nocomplain -directory $dirname -type f -tails *] {
		if {[regexp {\(([0-9]+)\) (.+)$} $filename z track title]} {
			set to_file "$track. $title"
			file rename [file join $dirname $filename] [file join $dirname $to_file]
		}
	}
}

main $argc $argv
