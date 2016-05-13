package require Itcl

source [file join $env(CRUISE_DIR) checkout lib perflib.tcl]
source [file join $env(CRUISE_DIR) checkout script lib CLogger.tcl]


# class maar eenmalig definieren
if {[llength [itcl::find classes CLqnProcessor]] > 0} {
	return
}

itcl::class CLqnProcessor {

	private common log
	# set log [CLogger::new_logger [file tail [info script]] debug]
	set log [CLogger::new_logger [file tail [info script]] info]

	public proc new_instance {name multiplicity_name multiplicity} {
		set result [uplevel {namespace which [CLqnProcessor #auto]}]
		$result init $name $multiplicity_name $multiplicity
		return $result
	}

	private variable name
	private variable lst_tasks
	private variable ar_tasks
	private variable lst_properties
	private variable multiplicity
	private variable multiplicity_name
	
	private constructor {} {
		set lst_tasks {}
		set lst_properties {}
		# set multiplicity 1
	}
	
	public method init {a_name a_multiplicity_name a_multiplicity} {
		set name $a_name
		set multiplicity_name $a_multiplicity_name
		set multiplicity $a_multiplicity
		add_property [CLqnProperty::new_instance $multiplicity_name $multiplicity]   
	}
	
	public method get_name {} {
		return $name
	}
	
	public method add_property {a_property} {
		lappend lst_properties $a_property
	}
	
	public method add_task {a_ctask} {
		lappend lst_tasks $a_ctask
		set ar_tasks([$a_ctask get_name]) $a_ctask
		log_tasks "added task: [$a_ctask get_name]"
	}
	
	public method get_task {task_name} {
		log_tasks "get task: $task_name"
		set res ""
		catch {set res $ar_tasks($task_name)}
		$log debug "${name}::get_task: $task_name => $res ***"
		return $res
	}	
	
	private method log_tasks {str} {
		$log debug $str
		foreach task_name [lsort [array names ar_tasks]] {
			$log debug "task_name: $task_name"
		}
		$log debug "--------------------------------"
	}
	
	public method write_file {f} {
		puts $f "   <processor name=\"$name\" multiplicity=\"\${$multiplicity_name}\" scheduling=\"fcfs\">"
		foreach ctask $lst_tasks {
			$ctask write_file $f
		}
		puts $f "   </processor>"
	}
	
	public method write_properties_file {f} {
		puts $f "# Properties van processor: $name"
		foreach cprop $lst_properties {
			$cprop write_file $f
		}
		foreach ctask $lst_tasks {
			$ctask write_properties_file $f
		}
	}
	
}

