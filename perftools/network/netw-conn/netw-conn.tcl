package require Itcl

# class maar eenmalig definieren
if {[llength [itcl::find classes CNetwConn]] > 0} {
	return
}

source [file join $env(CRUISE_DIR) checkout lib perflib.tcl]
source [file join $env(CRUISE_DIR) checkout script lib CLogger.tcl]

foreach filename [glob -directory [file join $env(CRUISE_DIR) checkout script tool netw-conn] C*.tcl] {
	source $filename
}

#source [file join $env(CRUISE_DIR) checkout script tool netw-conn CSystem.tcl]
#source [file join $env(CRUISE_DIR) checkout script tool netw-conn CMachine.tcl]
#source [file join $env(CRUISE_DIR) checkout script tool netw-conn CProcess.tcl]
#source [file join $env(CRUISE_DIR) checkout script tool netw-conn CConnection.tcl]

itcl::class CNetwConn {

	private common log
	set log [CLogger::new_logger netw_conn info]

	private variable dirname
	private variable csystem
	# private variable cmachine

	public constructor {a_dirname} {
		set dirname $a_dirname
	}

	public method make_graph {} {
		$log debug "start"
		
		read_system
		
		# $cmachine puts_processes ; # straks weg
		$csystem puts_processes ; # straks weg
		
		if {0} {
			set lst_processes [$csystem find_processes WebSphere_Portal]
			foreach el [$csystem find_processes snmpd] {
				lappend lst_processes $el
			}
			foreach el [$csystem find_processes db2sysc] {
				lappend lst_processes $el
			}
		}
		set lst_processes {}
		add_processes lst_processes WebSphere_Portal
		add_processes lst_processes server1
		# add_processes lst_processes snmpd
		# add_processes lst_processes db2sysc
		
		# $csystem make_graph $lst_processes
		set cgraphmaker [CGraphMaker::new_instance $dirname]
		$cgraphmaker make_graph $lst_processes
		$log debug "finished"
	
	}

	private method add_processes {lst_name process_name} {
		upvar $lst_name lst
		foreach el [$csystem find_processes $process_name] {
			lappend lst $el
		}
	}
	

	private method read_system {} {
		set csystem [CSystem::new_instance "test148"]

		set f [open [file join $dirname "system.txt"] r]
		while {![eof $f]} {
			gets $f line
			set line [string trim $line]
			if {$line != ""} {
				set l [split $line ","]
				set name [lindex $l 0]
				set ipname [lindex $l 1]
				set ipnr [lindex $l 2]
				set cmachine [CMachine::new_instance $csystem $name $ipname $ipnr 1]
				$csystem add_machine $cmachine
			}			
		}		
		close $f

		read_processes
		read_connections
		
	}
	

	private method read_processes {} {
		foreach cmachine [$csystem get_machines] {
			set f [open [file join $dirname "ps-[$cmachine get_name].txt"] r]
			while {![eof $f]} {
				gets $f line
				# $cmachine add_process [CProcess::make_ps_process $cmachine $line]
				$cmachine make_ps_process $line
			}
			close $f
		}
	}

	private method read_connections {} {
		foreach cmachine [$csystem get_machines] {
			set f [open [file join $dirname "lsof-[$cmachine get_name].txt"] r]
			while {![eof $f]} {
				gets $f line
				$cmachine handle_lsof_line $line
			}
			close $f
		}
		
		# handle wait lines
		foreach cmachine [$csystem get_machines] {
			$cmachine handle_wait_lines
		}		
		
		# merge processes and connections
		foreach cmachine [$csystem get_machines] {
			$cmachine merge_processes
		}		

		foreach cmachine [$csystem get_machines] {
			$cmachine merge_connections
		}		
		
	}

}

proc main {argc argv} {
  check_params $argc $argv
  set dirname [lindex $argv 0]
	# set testrun_id [lindex $argv 2] ; # bv 'testrun001'
  set netw_conn [CNetwConn #auto $dirname]
  $netw_conn make_graph
}

proc check_params {argc argv} {
  global env argv0
  if {$argc != 1} {
    fail "syntax: $argv0 <dirname>; got $argv \[#$argc\]"
  }
}

# aanroepen vanuit Ant, maar ook mogelijk om vanuit Tcl te doen.
if {[file tail $argv0] == [file tail [info script]]} {
  main $argc $argv
}

