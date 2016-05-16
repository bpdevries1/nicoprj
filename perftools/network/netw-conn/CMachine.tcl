package require Itcl

# class maar eenmalig definieren
if {[llength [itcl::find classes CMachine]] > 0} {
	return
}

source [file join $env(CRUISE_DIR) checkout lib perflib.tcl]
source [file join $env(CRUISE_DIR) checkout script lib CLogger.tcl]

itcl::class CMachine {

	private common log
	set log [CLogger::new_logger cmachine info]
	# set log [CLogger::new_logger cmachine debug]

	public proc new_instance {a_csystem a_name an_ipname an_ipnr a_is_known} {
		set inst [uplevel {namespace which [CMachine #auto]}]
		$inst init $a_csystem $a_name $an_ipname $an_ipnr $a_is_known
		return $inst
	}


	# instance
	private variable csystem
	private variable name
	private variable ipname
	private variable ipnr
	private variable process_factory
	private variable is_known ; # 1 if lsof and ps of this machine are known.
	private variable cmd_startpos
	
	public method init {a_csystem a_name an_ipname an_ipnr a_is_known} {
		set csystem $a_csystem
		set name $a_name
		set ipname $an_ipname
		set ipnr $an_ipnr
		set process_factory [CProcessFactory::new_instance $this]
		set is_known $a_is_known
	}

	public method get_system {} {
		return $csystem
	}

#     UID     PID    PPID   C    STIME    TTY  TIME CMD
# root  176310       1   0   Jul 13      -  0:00 /usr/local/sbin/syslog-ng -f /usr/local/etc/syslog-ng.conf 
	public method make_ps_process {line} {
		if {$line != ""} {
			if {[regexp {PID.*CMD} $line]} {
				set cmd_startpos [string first "CMD" $line]
				return ""			
			} else {
				set pid [lindex $line 1]
				# set cmdline [string range $line 51 end] ; # checken of 51 altijd goed is. Anders uit header-regel positie van CMD halen.
				set cmdline [string range $line $cmd_startpos end] ; # checken of 51 altijd goed is. Anders uit header-regel positie van CMD halen.
				set cmd [det_cmd $cmdline]
	
				# set inst [new_instance $cmachine $pid $cmdline $cmd]
				set inst [$process_factory det_process $pid -1]
				$inst set_cmdline $cmdline
				$inst set_cmd $cmd
	
				# lappend lst_processes $inst
				return $inst
			}
		}

	}
	
	private method det_cmd {cmdline} {
		set cmd [lindex $cmdline 0]
		set cmd [file tail $cmd]
		if {$cmd == "java"} {
			set cmd [lindex $cmdline end]
		}
		return $cmd	
	}

	public method puts_processes {} {
		puts "\nMachine: $name ($ipname)"
		puts "-----------------------"
		set lst_processes [$process_factory get_processes]
		foreach inst $lst_processes {
			# $log debug "Process instance: [$inst to_string]"
			puts "Process: [$inst to_string]"
		}
	}
	
# snmpdv3ne  110686   root    7u  IPv4 0xf100060001366390                0t0                 TCP *:32768 (LISTEN)
	
	public method handle_lsof_line {line} {
		$process_factory handle_lsof_line $line
	}
		
	public method get_name {} {
		return $name	
	}		
		
	public method get_ipname {} {
		return $ipname
	}
		
	public method get_ipnr {} {
		$log debug "start"
		return $ipnr
	}	

	public method to_string {} {
		return $name
	}

	public method set_listen_port {a_port a_cprocess} {
		$process_factory set_listen_port $a_port $a_cprocess
	}

	# determine if a process with the given pid or port exists yet.
	# @param pid: the pid, if known, else -1
	# @param port: the port, if known, else -1
	# either pid or port or both may be known.
	public method has_process {pid port} {
		return [$process_factory has_process $pid $port]
	}

	# @param pid: the pid, if known, else -1
	# @param port: the port, if known, else -1
	# either pid or port or both may be known.
	public method det_process {pid port} {
		return [$process_factory det_process $pid $port]
	}

		
	# @param a_cmd : name of the process(es) to find.
	# @return list of the found processes, can be empty
	public method find_processes {a_cmd} {
		return [$process_factory find_processes $a_cmd]
	}
		
	public method handle_wait_lines {} {
		$process_factory handle_wait_lines
	}	
	
	public method is_known {} {
		return $is_known
	}
		
	public method listens_to {port} {
		return [$process_factory listens_to $port]
	}	
	
	public method merge_processes {} {
		$process_factory merge_processes
	}
	
	public method merge_connections {} {
		$process_factory merge_connections
	}
	
}
	
	
