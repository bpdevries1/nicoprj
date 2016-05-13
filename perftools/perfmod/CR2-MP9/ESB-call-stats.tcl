source [file join $env(CRUISE_DIR) checkout lib perflib.tcl]
source [file join $env(CRUISE_DIR) checkout script lib CLogger.tcl]

proc main {argc argv} {
	global log
	# set log [CLogger::new_logger esbcalls debug]
	set log [CLogger::new_logger esbcalls info]
	
	check_params $argc $argv
	set dirname [lindex $argv 0]
	foreach subdir [lsort [glob -directory $dirname testrun*]] {
		handle_dir $subdir
	}
}

proc handle_dir {dirname} {
	global log
	regexp {testrun(...)} $dirname z runnr
	set f [open [file join $dirname report-ScRel2.html] r]
	set lst_res {}
	while {![eof $f]} {
		gets $f line
		if {0} {
<td >wps1.portals.log,BerichtInformatieServiceImpl</td>
<td >73</td>
<td >0.347</td>
		}		
		set name ""
		set n 0
		set avg 0.0
		# $log debug "found line: $line"
		if {[regexp {^<td >wps1.portals.log,([A-Za-z0-9]+)InformatieServiceImpl</td>$} $line z name]} {
			# $log debug "found esb line: $line"
			gets $f line
			regexp {<td >([0-9]+)</td>} $line z n
			gets $f line
			regexp {<td >([.0-9]+)</td>} $line z avg
			lappend lst_res [list $name $n $avg]
		}	
	}	
	close $f
	puts [join [list $runnr $dirname [to_string $lst_res]] "\t"]
}

proc to_string {lst} {
	global log
	$log debug "start"
	if {[is_filled_list $lst]} {
		set filled 1
		set l {}
		foreach el $lst {
			lappend l [to_string $el]
		}
		set result [join $l "\t"]
	}	else {
		set filled 0
		set result $lst
	}
	$log debug "finished: lst = $lst, result = $result; filled: $filled"
	return $result
}

proc is_filled_list {lst} {
	global log
	$log debug "start"
	if {[llength $lst] > 1} {
		$log debug "length > 1"
		set result 1
	} elseif {[llength $lst] == 0} {
		set result 0
	} else {
		set el [lindex $lst 0]
		if {$lst == $el} {
			set result 0
		} else {
			set result 1
		}
	}
	$log debug "finished, result = $result"
	return $result
}

proc check_params {argc argv} {
	global argv0
	if {$argc != 1} {
		fail "syntax: $argv0 <directory>; got: $argv"
	}
}

main $argc $argv