package require Itcl

source [file join $env(CRUISE_DIR) checkout lib perflib.tcl]
source [file join $env(CRUISE_DIR) checkout script lib CLogger.tcl]


# class maar eenmalig definieren
if {[llength [itcl::find classes CLqnTask]] > 0} {
	return
}

itcl::class CLqnTask {

	private common log
	set log [CLogger::new_logger [file tail [info script]] debug]

	public proc new_instance {name multiplicity_name multiplicity} {
		set result [uplevel {namespace which [CLqnTask #auto]}]
		$result init $name $multiplicity_name $multiplicity
		return $result
	}
	
	private variable name
	private variable lst_entries
	private variable ar_entries
	private variable lst_properties
	private variable multiplicity
	private variable multiplicity_name
	private variable ref_task
	private variable Z_name
	
	public constructor {} {
		set lst_entries {}
		set lst_properties {}
		set ref_task 0
		set Z_name ""
	}

	public method init {a_name a_multiplicity_name a_multiplicity} {
		set name $a_name	
		set multiplicity_name $a_multiplicity_name
		set multiplicity $a_multiplicity
		add_property [CLqnProperty::new_instance $multiplicity_name $multiplicity]   
	}
	
	public method set_ref_task {a_Z_name a_Z} {
		set ref_task 1
		set Z_name $a_Z_name
		# set Z $a_Z
		add_property [CLqnProperty::new_instance $Z_name $a_Z]   
	}
	
	public method get_name {} {
		return $name
	}
	
	public method add_entry {a_centry} {
		lappend lst_entries $a_centry
		set ar_entries([$a_centry get_name]) $a_centry
	}

	public method get_entry {entry_name} {
		set res ""
		catch {set res $ar_entries($entry_name)}
		return $res
	}
	
	public method add_property {a_property} {
		lappend lst_properties $a_property
	}
		
	public method write_file {f} {
		if {$ref_task} {
			puts $f "      <task name=\"$name\" multiplicity=\"\${$multiplicity_name}\" scheduling=\"ref\" think-time=\"\${$Z_name}\">"
		} else {
			puts $f "      <task name=\"$name\" multiplicity=\"\${$multiplicity_name}\" scheduling=\"fcfs\">"
		}
		foreach centry $lst_entries {
			$centry write_file $f
		}
		puts $f "      </task>"
	}
	
	public method write_properties_file {f} {
		puts $f "# Properties van task: $name"
		foreach cprop $lst_properties {
			$cprop write_file $f
		}
		foreach centry $lst_entries {
			$centry write_properties_file $f
		}
	}	
}

