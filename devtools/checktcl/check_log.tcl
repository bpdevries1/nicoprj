# check of nieuwe logging manier goed is doorgekomen.
# is niet goed als de file niet OO is.
# pas logging statements aan naar OO gebruik.
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
	set fi [open $filename r]
	set text [read $fi]
	close $fi
	if {[regexp {itcl::class.+proc main .+\$log} $text]} {
		# al nagekeken, wil niet meer zien.
		# puts stderr "Warn: $filename: \$log usage after proc main"		
	}
	
	set fi [open $filename r]
	set nr 0
	while {![eof $fi]} {
		gets $fi line
		incr nr
		if {[regexp {^[ \t]*log } $line]} {
			puts stderr "Warn: $filename ($nr): old log usage: $line"
		}
		if {[regexp {set log .* debug} $line]} {
			puts stderr "Warn: $filename ($nr): set debug level: $line"
			puts "jedit $filename"
		}
		if {[regexp {set log .* trace} $line]} {
			puts stderr "Warn: $filename ($nr): set trace level: $line"
			puts "jedit $filename"
		}
	}
	close $fi
}

proc handle_file1 {filename} {
	global stderr
	# set service_name "<unknown>"
	set level info
	set continue 1
	set fi [open $filename r]
	set orig_name "$filename._orig2"
	set temp_name "$filename._temp"
	set fo [open $temp_name w]
	set has_log_decl 0
	set has_log_use 0
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
		} elseif {[regexp "CLogger::new_logger" $line]} {
			# already has new logging, abort
			set has_log_decl 1
			set continue 0
		} elseif {[regexp {\$log} $line]} {
			set has_log_use 1
		} else {
			puts $fo $line
		}
	}
	close $fi
	close $fo
	
	if {$has_log_use} {
		if {$has_log_decl} {
			# ok, goed zo
		} else {
			puts stderr "warn: missing log decl: $filename"
		}
	}
	
	set continue 0
	if {$continue} {
		file rename $filename $orig_name
		file rename $temp_name $filename
	} else {
		file delete $temp_name
	}
	
}

main
