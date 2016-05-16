# change_log.tcl: pas logging statements aan naar OO gebruik.
# via stdin en stdout.

source [file join $env(CRUISE_DIR) checkout lib perflib.tcl]

proc main {} {
	set root_dir [file normalize .]
	handle_dir $root_dir
}

proc handle_dir {dir} {
	foreach filename [glob -nocomplain -directory $dir -type f *.tcl] {
		handle_file $filename
	}
	foreach subdir [glob -nocomplain -directory $dir -type d *] {
		if {![regexp {_archi} $subdir]} {
			if {![regexp {\.svn} $subdir]} {
				handle_dir $subdir
			}
		}
	}	
}

proc handle_file {filename} {
	global stderr
	# set service_name "<unknown>"
	set level info
	set continue 1
	set fi [open $filename r]
	set orig_name "$filename._orig"
	set temp_name "$filename._temp"
	set fo [open $temp_name w]
	while {$continue && (![eof $fi])} {
		gets $fi line
		# puts stderr "line: $line"
		if {[regexp {^itcl::class ([^ ]+)} $line z classname]} {
			puts $fo "source \[file join \$env(CRUISE_DIR) checkout script lib CLogger.tcl\]"
			puts $fo ""
			puts $fo $line
			puts $fo "	private common log"
			# puts $fo "	set log \[CLogger::new_logger $service_name $level\]"
			puts $fo "	set log \[CLogger::new_logger \[file tail \[info script\]\] $level\]"
			puts $fo ""
		} elseif {[regexp {^([ \t]*)log (.+) ([0-9]+)$} $line z prefix str lvl]} {
			# nog oudere manier, komt blijkbaar ook nog voor.
			# log "CNmonTimestamp.setMemValues: $aRealFree $aVirtFree" 2
			puts $fo "${prefix}\$log debug $str"
		} elseif {[regexp {^([ \t]*)log (.+) ([^ ]+) ([^ ]+)$} $line z prefix str lvl service]} {
			# standaard oude manier: log "te loggen tekst" debug service
			puts $fo "${prefix}\$log $lvl $str"
		} elseif {[regexp {addLogger ([^ ]+)$} $line z service]} {
			set service_name $service
		} elseif {[regexp {setLogLevel ([^ ]+) ([^ ]+)$} $line z z lvl]} {
			set level $lvl
		} elseif {[regexp "private common log" $line]} {
			# already has new logging, abort
			set continue 0
		} else {
			puts $fo $line
		}
	}
	close $fi
	close $fo
	
	if {$continue} {
		file rename $filename $orig_name
		file rename $temp_name $filename
	} else {
		file delete $temp_name
	}
	
}

main
