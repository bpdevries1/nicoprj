package require Itcl

source [file join $env(CRUISE_DIR) checkout lib perflib.tcl]
source [file join $env(CRUISE_DIR) checkout script lib CLogger.tcl]


# class maar eenmalig definieren
if {[llength [itcl::find classes CLqnProperty]] > 0} {
	return
}

itcl::class CLqnProperty {

	private common log
	set log [CLogger::new_logger [file tail [info script]] debug]

	public proc new_instance {name {value 0}} {
		set result [uplevel {namespace which [CLqnProperty #auto]}]
		$result init $name $value
		return $result
	}

	private variable name
	private variable value
	
	private method init {a_name a_value} {
		set name $a_name
		set value $a_value
	}

	public method write_file {f} {
		puts $f "$name = $value"
	}
		
}

