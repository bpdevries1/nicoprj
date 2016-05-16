package require Itcl

# class maar eenmalig definieren
if {[llength [itcl::find classes CProcessFactory]] > 0} {
	return
}

source [file join $env(CRUISE_DIR) checkout lib perflib.tcl]
source [file join $env(CRUISE_DIR) checkout script lib CLogger.tcl]

# the only place to create and maintaint CProcess objects, one factory per machine.
itcl::class CProcessFactory {

	private common log
	set log [CLogger::new_logger cprocessfactory info]
	# set log [CLogger::new_logger cprocessfactory debug]

	# new process factory instance.
	public proc new_instance {a_cmachine} {
		set inst [uplevel {namespace which [CProcessFactory #auto]}]
		$inst init $a_cmachine
		return $inst
	}


	# instance
	private variable cmachine
	private variable lst_processes
	private variable ar_pid_process
	private variable ar_port_process
	private variable ar_listen_port
	private variable csystem
	private variable lst_wait_lines
	
	private constructor {} {
	
	}
	
	private method init {a_cmachine} {
		set cmachine $a_cmachine
		set lst_processes {}
		set csystem [$cmachine get_system]
		set lst_wait_lines {}
	}


#     UID     PID    PPID   C    STIME    TTY  TIME CMD
# root  176310       1   0   Jul 13      -  0:00 /usr/local/sbin/syslog-ng -f /usr/local/etc/syslog-ng.conf 
	# @TODO Machine niet nodig hier???
	public method make_ps_process_old2 {cmachine line} {
		if {$line != ""} {
			set pid [lindex $line 1]
			set cmdline [string range $line 51 end] ; # checken of 51 altijd goed is. Anders uit header-regel positie van CMD halen.
			set cmd [det_cmd $cmdline]
			set inst [new_instance $cmachine $pid $cmdline $cmd]
			# lappend lst_processes $inst
			return $inst
		}

	}
	
	private method det_cmd_old2 {cmdline} {
		set cmd [lindex $cmdline 0]
		set cmd [file tail $cmd]
		if {$cmd == "java"} {
			set cmd [lindex $cmdline end]
		}
		return $cmd	
	}
	
	
	# TODO moet deze door de factory geregeld worden? Eigenlijk wel, mogelijk 2 samenvoegen.
	public method add_listen_port_old {port} {
		$log debug "start"
		lappend lst_listen_ports $port
		$cmachine set_listen_port $port $this
	}
	
	# TODO moet deze door de factory geregeld worden? Eigenlijk wel, mogelijk 2 samenvoegen.
	public method add_connection {a_cconn} {
		lappend lst_connections $a_cconn
	}
	
	# @param put_in_wait: if 1, the line is put in the lst_wait_lines if it can't be correctly handled now.
	# @param put_in_wait: if 0, the line is handled anyway.
	public method handle_lsof_line {line {put_in_wait 1}} {
		$log trace "start"
		if {[regexp {^([^ ]+) +([0-9]+).* TCP \*:([0-9]+) \(LISTEN\)$} $line z cmd pid port]} {
			set cprocess $ar_pid_process($pid)
			$cprocess add_listen_port $port
			set ar_port_process($port) $cprocess
			$log debug "Added listening port $port to process [$cprocess to_string]"
		} elseif {[regexp {TCP ([a-zA-Z0-9.]+):([0-9]+)->([a-zA-Z0-9.]+):([0-9]+) \(([A-Z]+)\)$} $line z from_ip from_port to_ip to_port conntype]} {
			$log debug "connection-line: $line"
			set from_pid [lindex $line 1]
			set from_proc $ar_pid_process($from_pid)
			set ar_port_process($from_port) $from_proc
			# set to_machine [$csystem det_machine $to_ip $this]
			set to_machine [$csystem det_machine $to_ip $cmachine]
			if {[$to_machine has_process -1 $to_port]} {
				add_lsof_process_connection $from_proc $from_port $to_machine $to_port $conntype
			} else {
				if {$put_in_wait} {
					# process not known yet, put the lsof line on the waitlist
					lappend lst_wait_lines $line
				} else {
					# handle anyway
					if {[$to_machine is_known]} {
						$log warn "Process still not known: from_proc: [$from_proc to_short_string] -> [$to_machine to_string]:$to_port"
					}
					add_lsof_process_connection $from_proc $from_port $to_machine $to_port $conntype
				}
			}
		}
		$log trace "finished"
	}
	
	public method handle_wait_lines {} {
		foreach line $lst_wait_lines {
			handle_lsof_line $line 0
		}
	}
	
	private method add_lsof_process_connection {from_proc from_port to_machine to_port conntype} {
		set to_proc [$to_machine det_process -1 $to_port]
		set cconn [CConnection::new_instance $from_proc $from_port $to_proc $to_port $conntype]		
		$log debug "before add_connection"
		$from_proc add_connection $cconn
		$to_proc add_connection [$cconn reverse]
	}
	
	public method set_listen_port {a_port a_cprocess} {
		set ar_listen_port($a_port) $a_cprocess
		set ar_port_process($a_port) $a_cprocess
	}

	public method listens_to {a_port} {
		set cprocess 0
		catch {set cprocess $ar_listen_port($a_port)}
		if {$cprocess != 0} {
			if {$a_port == 32769} {
				$log warn "32769 appears to be listening (machine)"
			}
			return 1
		} else {
			return 0
		}
	}

	# determine if a process with the given pid or port exists yet.
	# @param pid: the pid, if known, else -1
	# @param port: the port, if known, else -1
	# either pid or port or both may be known.
	# @TODO zorgen dat als 2x met -1 <port> wordt aangeroepen, hetzelfde process wordt teruggegeven.
	public method has_process {pid port} {
		set cprocess ""
		catch {set cprocess $ar_port_process($port)}
		catch {set cprocess $ar_pid_process($pid)}
		if {$cprocess != ""} {
			set result 1
		}	else {
			set result 0
		}
		return $result
	}

	# @param pid: the pid, if known, else -1
	# @param port: the port, if known, else -1
	# either pid or port or both may be known.
	# @TODO zorgen dat als 2x met -1 <port> wordt aangeroepen, hetzelfde process wordt teruggegeven.
	public method det_process {pid port} {
		set result ""
		catch {set result $ar_port_process($port)}
		catch {set result $ar_pid_process($pid)}
		if {$result == ""} {
			set result [CProcess::new_instance $cmachine $pid "cmdline?" "cmd?"]
			# @todo? ports ook meteen toevoegen?
			add_process $result
		}		
		return $result
	}

	# @deprecated, caller should should call a factory method in CProcessFactory and not create process itself.
	private method add_process {a_cprocess} {
		if {$a_cprocess != ""} {
			lappend lst_processes $a_cprocess
			set ar_pid_process([$a_cprocess get_pid]) $a_cprocess
		}
	}
	
	public method det_process_old {port} {
		set result ""
		catch {set result $ar_port_process($port)}
		if {$result == ""} {
			set result [CProcess::new_instance $cmachine "pid?" "cmdline?" "cmd?"]
			add_process $result
		}		
		return $result
	}

	public method get_processes {} {
		return $lst_processes
	}

	# @param a_cmd : name of the process(es) to find.
	# @return list of the found processes, can be empty
	public method find_processes {a_cmd} {
		# $log debug start
		set result {}
		foreach cprocess $lst_processes {
			if {[$cprocess get_cmd] == $a_cmd} {
				lappend result $cprocess	
			}
		}
		return $result
	}

	public method merge_processes {} {
		if {1} {
			foreach cprocess $lst_processes {
				set cmd [$cprocess get_cmd]
				set lst_same [find_processes $cmd]
				foreach cproc2 $lst_same {
					if {$cprocess != $cproc2} {
						merge_2_processes $cprocess $cproc2
					}
				}
			}
		}
	}

	# check if both procs still exist in lst_processes, if not, return immediately
	# @post: procs are merged in cproc1, is_group is set to true; cproc2 is removed from lst_processes
	public method merge_2_processes {cproc1 cproc2} {
		if {[lsearch -exact $lst_processes $cproc1] < 0} {
			return
		}
		set pos2 [lsearch -exact $lst_processes $cproc2]
		if {$pos2 < 0} {
			return
		}
		$cproc1 merge_with $cproc2		
		
		set lst_processes [lreplace $lst_processes $pos2 $pos2] ; # remove cproc2 from lst_processes
	
		set ar_pid_process([$cproc2 get_pid]) $cproc1
	
		foreach port [$cproc2 get_listen_ports] {
			set ar_listen_port($port) $cproc1	
		}
		
		foreach cconn [$cproc2 get_connections] {
			set ar_port_process([$cconn get_from_port]) $cproc1	
		}
		
	}
	
	public method merge_connections {} {
		foreach cprocess $lst_processes {
			$cprocess merge_connections
		}	
	}

		
}
