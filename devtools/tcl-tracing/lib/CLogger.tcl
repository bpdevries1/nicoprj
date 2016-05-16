package require Itcl

# source [file join $env(CRUISE_DIR) checkout lib perflib.tcl]

# class maar eenmalig definieren
if {[llength [itcl::find classes CLogger]] > 0} {
	return
}

itcl::class CLogger {

	private common int_level
	set int_level(trace) 14
	set int_level(debug) 12
	set int_level(perf) 10
	set int_level(info) 8
	set int_level(notice) 6
	set int_level(warn) 4
	set int_level(error) 2
	set int_level(critical) 0

	public proc new_logger {a_name a_log_level} {
		set result [uplevel {namespace which [CLogger #auto]}]
		$result set_name $a_name
		$result set_log_level $a_log_level
		return $result
	}

	private variable name
	private variable log_level
				private variable filename
				private variable f_log

	private constructor {} {
		set name ""
		set log_level critical
			set filename ""
			set f_log -1
	}
	
	public method set_name {a_name} {
		set name $a_name
	}	
	
	public method set_log_level {a_log_level} {
		set log_level $int_level($a_log_level)
	}

	public method get_log_level {} {
		return $log_level
	}
	
				public method set_file {a_filename} {
						set filename $a_filename
						set f_log [open $filename a]
				}

				public method close_file {} {
						set filename ""
						if {$f_log != -1} {
								close $f_log
								set f_log -1
						}
				}


	public method trace {str} {
		log_intern $str trace
	}

	public method debug {str} {
		log_intern $str debug
	}
	
	public method perf {str} {
		log_intern $str perf
	}
	
	public method info {str} {
		log_intern $str info
	}
	
	public method notice {str} {
		log_intern $str notice
	}

	public method warn {str} {
		log_intern $str warn
	}

	public method error {str} {
		log_intern $str error
	}

	public method critical {str} {
		log_intern $str critical
	}
	
	public method log {str {level critical}} {
		log_intern $str $level
	}
	
	public method log_start_finished {script {loglevel -1}} {
		perf "start"
		uplevel $script
		perf "finished"
	}
	
	public method log_intern {str {level critical} {pref_stacklevel -2}} {
		global stderr
		# puts stderr "int_level($level) = $int_level($level) ; log_level = $log_level"
		if {$int_level($level) <= $log_level} {
			# puts stderr "info level: [info level]"
			set stacklevel [::info level]
			if {$stacklevel > 1} {
	    	# puts stderr "\[[clock format [clock seconds] -format "%d-%m-%y %H:%M:%S"]\] \[$service\] \[$level\] $str *** \[[info level -1]\]"
	    	# puts stderr "\[[clock format [clock seconds] -format "%d-%m-%y %H:%M:%S"]\] \[$name\] \[$level\] $str *** \[[::info level $pref_stacklevel]\]"
					set str_log "\[[clock format [clock seconds] -format "%d-%m-%y %H:%M:%S"]\] \[$name\] \[$level\] $str" 
					if {$f_log != -1} {
							puts $f_log $str_log
					} else {
							puts stderr $str_log
					}
	    } else {
					set str_log "\[[clock format [clock seconds] -format "%d-%m-%y %H:%M:%S"]\] \[$name\] \[$level\] $str" 
					if {$f_log != -1} {
							puts $f_log $str_log
					} else {
							puts stderr $str_log
					}
			}
			flush stderr
		}
	}

}
