package require Itcl

# class maar eenmalig definieren
if {[llength [itcl::find classes CSystem]] > 0} {
	return
}

source [file join $env(CRUISE_DIR) checkout lib perflib.tcl]
source [file join $env(CRUISE_DIR) checkout script lib CLogger.tcl]

itcl::class CSystem {

	private common log
	# set log [CLogger::new_logger csystem debug]
	set log [CLogger::new_logger csystem info]

	public proc new_instance {a_name} {
		set inst [uplevel {namespace which [CSystem #auto]}]
		$inst init $a_name
		return $inst
	}


	# instance
	private variable name
	private variable lst_machines
	private variable ar_machines
	
	public method init {a_name} {
		set name $a_name
		set lst_machines {}		
	}

	public method add_machine {a_cmachine} {
		lappend lst_machines $a_cmachine
		set ar_machines([$a_cmachine get_ipname]) $a_cmachine
		set ar_machines([$a_cmachine get_ipnr]) $a_cmachine
	}

	public method get_machines {} {
		return $lst_machines	
	}

	# @param ip: ip name or number.
	# cmachine: machine to return if ip == localhost
	public method det_machine {ip cmachine} {
		if {($ip == "localhost") || ($ip == "127.0.0.1")} {
			return $cmachine	
		}
		set result ""
		catch {set result $ar_machines($ip)}
		if {$result == ""} {
			set result [CMachine::new_instance $this $ip $ip $ip 0]
			add_machine $result
		}		
		return $result
	}

	public method puts_processes {} {
		puts "System: $name"
		puts "==============="
		foreach cmachine $lst_machines {
			$cmachine puts_processes	
		}
	}

	# @param a_cmd : name of the process(es) to find.
	# @return list of the found processes, can be empty
	public method find_processes {a_cmd} {
		# $log debug start
		set result {}
		foreach cmachine $lst_machines {
			foreach el [$cmachine find_processes $a_cmd] {
				lappend result $el	
			}
		}
		return $result
	}
	
}
