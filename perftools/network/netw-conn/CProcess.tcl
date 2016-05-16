package require Itcl

# class maar eenmalig definieren
if {[llength [itcl::find classes CProcess]] > 0} {
	return
}

source [file join $env(CRUISE_DIR) checkout lib perflib.tcl]
source [file join $env(CRUISE_DIR) checkout script lib CLogger.tcl]

itcl::class CProcess {

	private common log
	set log [CLogger::new_logger cprocess info]
	# set log [CLogger::new_logger cprocess debug]

	# common
	# private common lst_processes {}
	private common lst_default_listen_ports [list 21 22 23 80 389 443]
	public proc new_instance {a_cmachine a_pid a_cmdline a_cmd} {
		set inst [uplevel {namespace which [CProcess #auto]}]
		$inst init $a_cmachine $a_pid $a_cmdline $a_cmd	
		return $inst
	}

	# instance
	private variable cmachine
	private variable pid
	private variable cmdline
	private variable cmd
	private variable lst_listen_ports
	private variable lst_connections

	# instance, as group
	private variable is_group
	private variable lst_pids

	private constructor {} {
	
	}
	
	private method init {a_cmachine a_pid a_cmdline a_cmd} {
		set cmachine $a_cmachine
		set pid $a_pid
		set cmdline $a_cmdline
		set cmd $a_cmd	
		set lst_listen_ports {}
		set lst_connections {}
		set is_group 0
		set lst_pids [list $a_pid]
	}
	
	public method get_pid {} {
		return $pid
	}
	
	public method get_cmd {} {
		return $cmd	
	}
	
	public method set_cmdline {a_cmdline} {
		set cmdline $a_cmdline
	}

	public method set_cmd {a_cmd} {
		set cmd $a_cmd
	}
	
	public method get_machine {} {
		return $cmachine
	}
	
	public method set_is_group {a_is_group} {
		set is_group $a_is_group
	}
	
	public method get_is_group {} {
		return $is_group
	}
	
	public method add_listen_port {port} {
		$log debug "start"
		lappend lst_listen_ports $port
		$cmachine set_listen_port $port $this
	}
	
	public method listens_to {port} {
		if {[$cmachine is_known]} {
			if {[lsearch -exact $lst_listen_ports $port] > -1} {
				if {$port == 32769} {
					$log warn "32769 appears to be listening (process)"
				}
				return 1
			} else {
				# maybe another process on this machine listens to the port (this can happen!)
				return [$cmachine listens_to $port]
			}
		} else {
			# unknown machine, if port is default listening, return 1
			if {[lsearch -exact $lst_default_listen_ports $port] > -1} {
				return 1
			} else {
				return -1 ; # unknown
			}
		}
	}
	
	public method add_connection {a_cconn} {
		lappend lst_connections $a_cconn
	}
	
	public method get_connections {} {
		return $lst_connections	
	}
	
	public method get_listen_ports {} {
		return $lst_listen_ports	
	}
	
	public method to_string {} {
		set result "\[$this\] $cmd ($pid)"
		if {[llength $lst_listen_ports] > 0} {
			set result "$result \[listen_ports: [join $lst_listen_ports ","]\]"
		}
		if {[llength $lst_connections] > 0} {
			foreach cconn $lst_connections {
				set result "$result\n  [$cconn to_string]"
			}
		}
		return $result
	}
	
	public method to_short_string {} {
		$log debug "start"
		if {$is_group} {
			set result "$cmd ([$cmachine get_ipnr]:[llength $lst_pids] procs)"
		} else {
			set result "$cmd ([$cmachine get_ipnr]:$pid)"
		}
		
		$log debug "finished"
		return $result		
	}
	
	# merge this process with another, this process will be used as the merge result.
	public method merge_with {cproc2} {
		set_is_group 1
		lappend lst_pids [$cproc2 get_pid]
		foreach port [$cproc2 get_listen_ports] {
			if {[lsearch -exact $lst_listen_ports $port] < 0} {
				lappend lst_listen_ports $port	
			}
		}
		foreach cconn [$cproc2 get_connections] {
			$cconn set_from_proc $this
			[$cconn get_reverse] set_to_proc $this
			lappend lst_connections $cconn
		}
	}

	public method merge_connections {} {
		foreach cconn1 $lst_connections {
			foreach cconn2 $lst_connections {
				if {$cconn1 != $cconn2} {
					if {[$cconn1 get_to_proc] == [$cconn2	get_to_proc]} {
						if {[$cconn1 get_to_port] == [$cconn2	get_to_port]} {	
							merge_2_connections $cconn1 $cconn2
						}
					}
				}
			}			
		}
	}

	# @pre: cconn1.to_proc == cconn2.to_proc
	# @pre: cconn1.to_port == cconn2.to_port
	private method merge_2_connections {cconn1 cconn2} {
		if {[lsearch -exact $lst_connections $cconn1] < 0} {
			return
		}
		if {[lsearch -exact $lst_connections $cconn2] < 0} {
			return
		}
		# @post: both connections still exist, not merged already.
		$log debug start

		if {[$cconn1 get_from_port] != [$cconn2 get_from_port]} {
			$cconn1 merge_with $cconn2
		} else {
			# it seems possible that connections also have the same from_port, and so are basically the same.
			# in this case, just remove the second connection.
		}
		
		remove_connection $cconn2
		[$cconn2 get_to_proc] remove_connection [$cconn2 get_reverse]
		$log debug finished
	}
	
	public method remove_connection {a_cconn} {
		set pos [lsearch -exact $lst_connections $a_cconn]
		if {$pos >= 0} {
			set lst_connections [lreplace $lst_connections $pos $pos] ; # remove a_cconn from lst_connections
		}
	}
	
	
	
}
