package require Itcl

# class maar eenmalig definieren
if {[llength [itcl::find classes CConnection]] > 0} {
	return
}

source [file join $env(CRUISE_DIR) checkout lib perflib.tcl]
source [file join $env(CRUISE_DIR) checkout script lib CLogger.tcl]

itcl::class CConnection {

	private common log
	set log [CLogger::new_logger cconnection info]
	# set log [CLogger::new_logger cconnection debug]

	public proc new_instance {from_proc from_port to_proc to_port conntype} {
		set inst [uplevel {namespace which [CConnection #auto]}]
		$inst init $from_proc $from_port $to_proc $to_port $conntype
		return $inst
	}
	
	# instance
	private variable from_proc
	private variable from_port
	private variable to_proc
	private variable to_port
	private variable conntype ; # ESTABLISHED etc.
	private variable is_group
	private variable cconn_reverse ; # handle to reverse connection.
	private variable lst_from_ports ; # used when grouping connections
	private variable lst_to_ports ; # used when grouping connections
	
	public method init {a_from_proc a_from_port a_to_proc a_to_port a_conntype} {
		set from_proc $a_from_proc
		set from_port $a_from_port
		set to_proc $a_to_proc
		set to_port $a_to_port
		set conntype $a_conntype
		set is_group 0
		set cconn_reverse 0
		set lst_from_ports [list $from_port]
		set lst_to_ports [list $to_port]
	}

	public method set_is_group {a_is_group} {
		set is_group $a_is_group
	}
	
	public method get_is_group {} {
		return $is_group
	}
	
	# @return a new CConnection with from and to reversed.
	# @invariant: proc1.conn[i].from_proc == proc1
	public method reverse {} {
		set conn_rev [new_instance $to_proc $to_port $from_proc $from_port $conntype]
		set_reverse $conn_rev
		$conn_rev set_reverse $this
		return $conn_rev
	}
	
	public method set_reverse {cconn} {
		set cconn_reverse $cconn	
	}
	
	public method get_reverse {} {
		return $cconn_reverse	
	}
	
	
	# @return 1 if the to_proc is the listening one, return 0 if the from_proc is the listening one
	public method is_to_listening {} {
		set to_list [$to_proc listens_to $to_port]
		if {$to_list == 1} {
			return 1
		} elseif {$to_list == 0} {
			# to luistert zeker niet, moet dan wel from zijn, toch checken.
			set from_list [$from_proc listens_to $from_port]
			if {$from_list == 1} {
				# ok, from listens
				return 0
			} elseif {$from_list == 0} {
				puts "from_proc: [$from_proc to_string]" 
				puts "to_proc: [$to_proc to_string]"
				# check if ports are used by another process
				puts "from port process exists?: [[$from_proc get_machine] has_process -1 $from_port]"
				set exists_to_port [[$to_proc get_machine] has_process -1 $to_port]
				puts "to port process exists?: $exists_to_port"
				if {$exists_to_port} {
					puts "port_process: [[[$to_proc get_machine] det_process -1 $to_port] to_string]"
				}
				fail "Error, from and to don't listen: $from_port ([$from_proc to_short_string]) -> $to_port ([$to_proc to_short_string])"
			} elseif {$from_list == -1} {
				# to doesn't listen, from unknown, so return 0 (from is listening)
				return 0
			}
		} elseif {$to_list == -1} {
			set from_list [$from_proc listens_to $from_port]
			if {$from_list == 1} {
				# ok, from listens
				return 0
			} elseif {$from_list == 0} {
				# from doesn't listen, to unknown, so return 1 (to is listening)
				return 1

				fail "Error, from and to don't listen: $from_port -> $to_port"
			} elseif {$from_list == -1} {
				# both unknown (shouldn't happen)
				fail "Error, from and to both unknown: $from_port -> $to_port"
			}
		}
	}

	public method to_string {} {
		if {$is_group} {
			if {[llength $lst_from_ports] == 1} {
				set str_from_ports $from_port	
			} else {
				set str_from_ports "[llength $lst_from_ports] ports"
			}
			if {[llength $lst_to_ports] == 1} {
				set str_to_ports $to_port	
			} else {
				set str_to_ports "[llength $lst_to_ports] ports"
			}
			set result "[$from_proc to_short_string]:$str_from_ports -> [$to_proc to_short_string]:$str_to_ports ($conntype)"
		} else {
			set result "[$from_proc to_short_string]:$from_port -> [$to_proc to_short_string]:$to_port ($conntype)"
		}
		return $result
	}

	public method to_short_string {} {
		if {$is_group} {
			if {[llength $lst_from_ports] == 1} {
				set str_from_ports $from_port	
			} else {
				set str_from_ports "[llength $lst_from_ports] ports"
				# set str_from_ports "[join $lst_from_ports ","]"
			}
			if {[llength $lst_to_ports] == 1} {
				set str_to_ports $to_port	
			} else {
				set str_to_ports "[llength $lst_to_ports] ports"
				# set str_to_ports "[join $lst_to_ports ","]"
			}
			set result "$str_from_ports -> $str_to_ports"
		} else {
			set result "$from_port -> $to_port"
		}
		return $result
	}

	
	# 2 methods for merging processes and contained connections
	public method set_from_proc {a_proc} {
		set from_proc $a_proc
	}
	
	public method set_to_proc {a_proc} {
		set to_proc $a_proc
	}
	
	public method get_from_proc {} {
		return $from_proc
	}
	
	public method get_to_proc {} {
		return $to_proc	
	}
	
	public method get_from_port {} {
		return $from_port	
	}
	
	public method get_to_port {} {
		return $to_port	
	}
	
	public method get_conntype {} {
		return $conntype	
	}
	
	# @pre: cconn1.to_proc == cconn2.to_proc
	# @pre: cconn1.to_port == cconn2.to_port
	public method merge_with {cconn2} {
		$log debug "Merging [to_string] with [$cconn2 to_string]"
		set port [$cconn2 get_from_port]
		$log debug "adding port $port to this and reverse connection"
		add_from_port $port
		$cconn_reverse add_to_port $port
	}
	
	public method add_from_port {a_port} {
		set_is_group 1
		if {[lsearch -exact $lst_from_ports $a_port] >= 0} {
			fail "Error: port $a_port already exists in lst_from_ports: $lst_from_ports"
		}
		
		lappend lst_from_ports $a_port	
	}
	
	public method add_to_port {a_port} {
		set_is_group 1
		if {[lsearch -exact $lst_to_ports $a_port] >= 0} {
			fail "Error: port $a_port already exists in lst_to_ports: $lst_to_ports"
		}
		lappend lst_to_ports $a_port	
	}
	
	
}
