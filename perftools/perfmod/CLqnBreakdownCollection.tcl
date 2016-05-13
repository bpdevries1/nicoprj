package require Itcl

source [file join $env(CRUISE_DIR) checkout lib perflib.tcl]
source [file join $env(CRUISE_DIR) checkout script lib CLogger.tcl]

# class maar eenmalig definieren
if {[llength [itcl::find classes CLqnBreakdownCollection]] > 0} {
	return
}

itcl::class CLqnBreakdownCollection {

	private common log
	# set log [CLogger::new_logger [file tail [info script]] debug]
	set log [CLogger::new_logger [file tail [info script]] info]

	public proc new_instance {} {
		set result [uplevel {namespace which [CLqnBreakdownCollection #auto]}]
		$result init
		return $result
	}

	private variable ar_breakdowns ; # key: entryname,value # i.e. EBr,10 (for N=10)
	private variable lst_entry_names
	private variable lst_values
	private variable var_name
	private variable lst_breakdown_labels ; # i.e. <entryname>.D, <entryname>.procwait <entryname>.taskwait
	
	public method init {} {
		catch {array unset ar_breakdowns}
		set lst_values {}
		set lst_entry_names {}
		set var_name "<unknown>"
		set lst_breakdown_labels {}
	}
	
	public method get_entry_names {} {
		return $lst_entry_names
	}
	
	public method get_values {} {
		return $lst_values
	}
	
	public method get_var_name {} {
		return $var_name
	}
	
	public method add_breakdown {breakdown} {
		set entry_name [$breakdown get_entry_name]
		set var_value [$breakdown get_var_value]
		set var_name [$breakdown get_var_name]
		set ar_breakdowns($entry_name,$var_value) $breakdown
		if {[lsearch -exact $lst_entry_names $entry_name] == -1} {
			lappend lst_entry_names $entry_name
		}
		if {[lsearch -exact $lst_values $var_value] == -1} {
			lappend lst_values $var_value
		}
	}
	
	public method to_string {} {
		return "$var_name in \[[join $lst_values ", "]\] entries in \[[join $lst_entry_names ", "]\]"
	}
	
	private method det_breakdown_labels {} {
		if {[llength $lst_breakdown_labels] > 0} {
			return
		}
		foreach entry_name $lst_entry_names {
			foreach value $lst_values {
				foreach label [$ar_breakdowns($entry_name,$value) det_breakdown_labels] {
					if {[lsearch -exact $lst_breakdown_labels $label] < 0} {
						lappend lst_breakdown_labels $label
					}
				}
			}
		}
	}
	
	public method get_breakdown_labels {} {
		det_breakdown_labels
		return $lst_breakdown_labels
	}	
	
	public method get_breakdown {entry_name var_value} {
		return $ar_breakdowns($entry_name,$var_value)
	}
	
	public method det_biggest_breakdown_labels {n_biggest lst_entry_names $lst_values} {
		set lst_labels [get_breakdown_labels]
		foreach label $lst_labels {
			set ar_max_time($label) 0
		}		
		
		foreach entry_name $lst_entry_names {
			foreach value $lst_values {
				foreach label $lst_labels {
					set time [[get_breakdown $entry_name $value] get_breakdown_time $label]
					if {$time > $ar_max_time($label)} {
						set ar_max_time($label) $time
					}
				}
			}
		}
	
		set lst {}
		foreach label $lst_labels {
			lappend lst [list $label $ar_max_time($label)]
		}
		set lst [lsort -real -index 1 -decreasing $lst]
		
		set lst_result {}
		for {set i 0} {$i < $n_biggest} {incr i} {
			lappend lst_result [lindex [lindex $lst $i] 0]
		}
		return $lst_result
	}
	
	
	
}