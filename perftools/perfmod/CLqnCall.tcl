# Voorlopig kopie + aanpassingen van zelfde file in parent-dir.

package require Itcl

source [file join $env(CRUISE_DIR) checkout lib perflib.tcl]
source [file join $env(CRUISE_DIR) checkout script lib CLogger.tcl]

# class maar eenmalig definieren
if {[llength [itcl::find classes CLqnCall]] > 0} {
	return
}

itcl::class CLqnCall {

	private common log
	set log [CLogger::new_logger [file tail [info script]] debug]

	public proc new_instance_old {a_from_entry a_to_entry a_n_calls} {
		set result [uplevel {namespace which [CLqnCall #auto]}]
		$result init $a_from_entry $a_to_entry $a_n_calls
		return $result
	}

	public proc new_instance {a_from_entry a_to_entry a_n_calls {a_n_calls_name ""}} {
		set result [uplevel {namespace which [CLqnCall #auto]}]
		$result init $a_from_entry $a_to_entry $a_n_calls $a_n_calls_name 
		return $result
	}
	
	private variable from_entry
	private variable to_entry
	private variable n_calls
	private variable n_calls_name
	private variable task_wait
	private variable lst_properties

	private method init {a_from_entry a_to_entry a_n_calls a_n_calls_name} {
		# $log debug "CLqnCall::init: start"
		# $log debug "From entry name: [$a_from_entry get_name]"
		# $log debug "To entry name: [$a_to_entry get_name]"

		set from_entry $a_from_entry
		set to_entry $a_to_entry
		set n_calls $a_n_calls
		set n_calls_name $a_n_calls_name
		set task_wait 0.0
		set lst_properties {}
		if {$n_calls_name != ""} {
			add_property [CLqnProperty::new_instance $n_calls_name $n_calls]
		}
	}
	
	public method set_task_wait {a_task_wait} {
		set task_wait $a_task_wait
	}

	public method get_from_entry {} {
		return $from_entry
	}

	public method get_to_entry {} {
		return $to_entry
	}

	public method get_n_calls {} {
		return $n_calls
	}

	# n_calls en a_n_calls mogelijk floats, dus geen incr gebruiken
	public method add_n_calls {a_n_calls} {
		$log debug "Add_n_calls: n_calls == $n_calls; a_n_calls == $a_n_calls"
		set n_calls [expr $n_calls + $a_n_calls]
		$log debug "Result: n_calls == $n_calls"
	}
	
	public method get_task_wait {} {
		return $task_wait
	}

	public method add_property {a_property} {
		lappend lst_properties $a_property
	}
	
	public method to_string {} {
		return "[$from_entry get_name] -> [$to_entry get_name] (n=$n_calls; task_wait=$task_wait)"
	}

	public method write_file {f} {
		if {$n_calls_name != ""} {
			puts $f "                  <synch-call dest=\"[$to_entry get_name]\" calls-mean=\"\${$n_calls_name}\"/>"
		} else {
			puts $f "                  <synch-call dest=\"[$to_entry get_name]\" calls-mean=\"$n_calls\"/>"
		}
	}
	
	public method write_properties_file {f} {
		puts $f "# Properties van call: [to_string]"
		foreach cprop $lst_properties {
			$cprop write_file $f
		}
	}
		
}
	