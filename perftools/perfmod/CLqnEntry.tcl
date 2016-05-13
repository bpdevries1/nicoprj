# Voorlopig kopie + aanpassingen van zelfde file in parent-dir.

package require Itcl

source [file join $env(CRUISE_DIR) checkout lib perflib.tcl]
source [file join $env(CRUISE_DIR) checkout script lib CLogger.tcl]

# class maar eenmalig definieren
if {[llength [itcl::find classes CLqnEntry]] > 0} {
	return
}

itcl::class CLqnEntry {

	private common log
	set log [CLogger::new_logger [file tail [info script]] debug]

	public proc new_instance {a_name} {
		set result [uplevel {namespace which [CLqnEntry #auto]}]
		$result init $a_name
		return $result
	}

	public proc new_template_instance {a_name a_service_demand_name a_service_demand} {
		set result [uplevel {namespace which [CLqnEntry #auto]}]
		$result init $a_name
		$result set_service_demand_name $a_service_demand_name
		$result set_service_demand $a_service_demand
		$result add_property [CLqnProperty::new_instance $a_service_demand_name $a_service_demand]
		return $result
	}
	
	private variable name
	private variable service_demand
	private variable service_demand_name
	private variable service_time
	private variable proc_wait
	private variable lst_calls
	private variable lst_properties
	
	public method init {a_name} {
		set name $a_name
		set service_demand -1
		set service_time -1
		set proc_wait -1
		set lst_calls {}
		set lst_properties {}
		
	}

	public method set_service_demand_name {a_service_demand_name} {
		set service_demand_name $a_service_demand_name
	}
	
	public method set_service_demand {a_service_demand} {
		set service_demand $a_service_demand
	}

	public method set_service_time {a_service_time} {
		set service_time $a_service_time
	}

	public method set_proc_wait {a_proc_wait} {
		set proc_wait $a_proc_wait
	}

	# bestaande methode, voor analyse van modellen.
	public method add_call {a_call} {
		lappend lst_calls $a_call
	}

	# nieuwe methode, voor genereren van (template) modellen.
	public method add_template_call {entry_to n_calls_name n_calls} {
		set lqn_call [CLqnCall::new_instance $this $entry_to $n_calls $n_calls_name]
		add_call $lqn_call
		return $lqn_call
	}
	
	public method get_call {to_entry} {
		set res ""
		foreach call $lst_calls {
			if {[$call get_to_entry] == $to_entry} {
				set res $call
			}	
		}
		$log debug "Zoek call van $name => [$to_entry get_name]: $res ***"
		return $res
	}
	
	public method get_name {} {
		return $name
	}
	
	public method get_service_time {} {
		return $service_time
	}

	public method get_service_demand {} {
		return $service_demand
	}
		
	public method get_proc_wait {} {
		return $proc_wait
	}

	public method get_calls {} {
		return $lst_calls
	}

	public method add_property {a_property} {
		lappend lst_properties $a_property
	}
	
	public method to_string {} {
		set str "$name (D=$service_demand; R=$service_time; proc_wait=$proc_wait"
		foreach call $lst_calls {
			set str "$str\n  [$call to_string]"
		}
		return $str
	}

	public method write_file {f} {
		puts $f "         <entry name=\"$name\" type=\"PH1PH2\">
            <entry-phase-activities>
              <activity name=\"${name}_ph1\" phase=\"1\" host-demand-mean=\"\${$service_demand_name}\">"

		foreach call $lst_calls {
			$call write_file $f
		}
									
	  puts $f "             </activity>
            </entry-phase-activities>
         </entry>"
		
	}
	
	public method write_properties_file {f} {
		puts $f "# Properties van entry: $name"
		foreach cprop $lst_properties {
			$cprop write_file $f
		}
		foreach ccall $lst_calls {
			$ccall write_properties_file $f
		}
	}
		
	
}
	