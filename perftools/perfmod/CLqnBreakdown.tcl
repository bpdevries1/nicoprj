package require Itcl

source [file join $env(CRUISE_DIR) checkout lib perflib.tcl]
source [file join $env(CRUISE_DIR) checkout script lib CLogger.tcl]

# class maar eenmalig definieren
if {[llength [itcl::find classes CLqnBreakdown]] > 0} {
	return
}

itcl::class CLqnBreakdown {

	private common log
	# set log [CLogger::new_logger [file tail [info script]] debug]
	set log [CLogger::new_logger [file tail [info script]] info]

	public proc new_instance {model entry_name} {
		set result [uplevel {namespace which [CLqnBreakdown #auto]}]
		$result init $model $entry_name
		return $result
	}

	private variable model
	private variable entry_name
	private variable lst_items
	private variable ar_items ; # key: entry_name
	private variable service_time ; # R: main service time to break down.
	private variable var_name ; # name of var for which this is a breakdown, i.e. N
	private variable var_value; # value of var for which this is a breakdown, i.e. 10

	public method init {a_model an_entry_name} {
		set model $a_model
		set entry_name $an_entry_name	
		set lst_items {}
		catch {unset ar_items}
	}

	public method set_var {a_var_name a_var_value} {
		set var_name $a_var_name
		set var_value $a_var_value
	}

	public method get_entry_name {} {
		return $entry_name
	}

	public method get_var_name {} {
		return $var_name
	}

	public method get_var_value {} {
		return $var_value
	}

	public method calc {} {
		set main_entry [$model det_entry $entry_name]
		set service_time [$main_entry get_service_time]
		add_items_rec $main_entry 1.0 0.0
	}

	public method get_service_time {} {
		return $service_time
	}

	private method add_items_rec {entry n_calls task_wait} {
		# make item for entry
		set item [CLqnBreakdownItem::new_instance $entry]
		$item set_service_time [expr [$entry get_service_time] * $n_calls]
		$item set_service_demand [expr [$entry get_service_demand] * $n_calls]
		$item set_proc_wait [expr [$entry get_proc_wait] * $n_calls]
		$item set_task_wait [expr $task_wait * $n_calls]
		$item set_n_calls $n_calls
		lappend lst_items $item
		set ar_items([$entry get_name]) $item
		# call rec for calls
		foreach call [$entry get_calls] {
			add_items_rec [$call get_to_entry] [expr $n_calls * [$call get_n_calls]] [$call get_task_wait]
		}
		
	}

	public method log_debug {} {
		$log debug "Breakdown for $entry_name: [format %0.4f $service_time]"
		$log debug [join [list name n_calls R D proc_wait task_wait sum] "\t"]
		set sum_total 0.0
		foreach item $lst_items {
			$log debug "[$item to_string]"
			set sum_total [expr $sum_total + [$item det_sum]]
		}
		$log debug "Sum total: [format %0.4f $sum_total]"
	}

	public method print {f} {
		puts $f "Breakdown for $entry_name: [format %0.4f $service_time]"
		puts $f [join [list name n_calls R D proc_wait task_wait sum] "\t"]
		set sum_total 0.0
		foreach item $lst_items {
			puts $f "[$item to_string]"
			set sum_total [expr $sum_total + [$item det_sum]]
		}
		puts $f "Sum total: [format %0.4f $sum_total]"
	}

	public method det_breakdown_labels {} {
		set lst {}
		foreach item $lst_items {
			set entry_name [$item get_entry_name]
			lappend lst "$entry_name.D"
			lappend lst "$entry_name.proc_wait"
			lappend lst "$entry_name.task_wait"
		}
		return $lst
	}

	public method get_breakdown_time {label} {
		regexp {^(.+)\.([^.]+)$} $label z entry_name time_type
		set result 0
		catch {set result [$ar_items($entry_name) get_breakdown_time $time_type]}
		return $result
	}

}

# values in breakdownitem are already multiplied by n_calls 'cumulative'
itcl::class CLqnBreakdownItem {
	private common log
	set log [CLogger::new_logger [file tail [info script]] debug]

	public proc new_instance {an_entry} {
		set result [uplevel {namespace which [CLqnBreakdownItem #auto]}]
		$result init $an_entry
		return $result
	}

	private variable entry
	private variable service_time
	# private variable service_demand
	# private variable proc_wait
	# private variable task_wait
	private variable n_calls
	private variable ar_times ; # key: time_type: D, proc_wait_task_wait

	public method init {an_entry} {
		set entry $an_entry
		catch {unset ar_times}
		set ar_times(D) 0
		set ar_times(proc_wait) 0
		set ar_times(task_wait) 0
	}

	public method set_service_time {a_service_time} {
		set service_time $a_service_time
	}

	public method set_service_demand {a_service_demand} {
		# set service_demand $a_service_demand
		set ar_times(D) $a_service_demand
	}
	
	public method set_proc_wait {a_proc_wait} {
		set ar_times(proc_wait) $a_proc_wait
	}
	
	public method set_task_wait {a_task_wait} {
		set ar_times(task_wait) $a_task_wait
	}
	
	public method set_n_calls {a_n_calls} {
		set n_calls $a_n_calls
	}
	
	public method det_sum {} {
		set sum [expr $ar_times(D) + $ar_times(proc_wait) + $ar_times(task_wait)]		
		return $sum	
	}
	
	public method to_string {} {
		set sum [det_sum]
		return [join [list [$entry get_name] [format %0.4f $n_calls] [format %0.4f $service_time] [format %0.4f $ar_times(D)] [format %0.4f $ar_times(proc_wait)] [format %0.4f $ar_times(task_wait)] [format %0.4f $sum]] "\t"]
	}
	
	public method get_entry_name {} {
		return [$entry get_name]
	}
	
	public method get_breakdown_time {time_type} {
		return $ar_times($time_type)		
	}
	
}

	