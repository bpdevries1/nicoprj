package require Itcl

source [file join $env(CRUISE_DIR) checkout lib perflib.tcl]
source [file join $env(CRUISE_DIR) checkout script lib CLogger.tcl]

# class maar eenmalig definieren
if {[llength [itcl::find classes CLqnTextFile]] > 0} {
	return
}

# vooral bedoeld om input text van Lqn te parsen, om asymptoten te berekenen
# @deprecated: asymptoten niet meer gemakkelijk te bepalen, modellen zijn te complex hiervoor.
itcl::class CLqnTextFile {

	private common log
	set log [CLogger::new_logger lqntextfile debug]

	private variable lqn_filename
	private variable entry_name ; # name of entry to show X and R for.
	
	# calc results
	private variable X
	private variable R
	private variable D_max
	private variable D_sum
	
	# temp instance vars
	private variable state

	# extra vars door splitsing readlqn:
	private variable serv
	private variable avgcalls_list
	private variable mult_proc
	private variable procnames
	private variable entries
	
	public constructor {} {
		init
	}
	
	private method init {} {
		set lqn_file ""
		set X 0
		set R 0
		set D_max 0
		set D_sum 0
	}
	
	public method set_lqn_filename {an_lqn_filename} {
		set lqn_filename $an_lqn_filename
	}

	public method set_entry_name {an_entry_name} {
		set entry_name $an_entry_name
	}

	public method get_X {} {
		return $X
	}

	public method get_R {} {
		return $R
	}

	public method get_D_max {} {
		return $D_max
	}

	public method get_D_sum {} {
		return $D_sum
	}

	# calc_asymp_lqn: based on old/text lqn input format.
	public method calc_asymp {N Z} {
		log "start" debug lqnscontrol
		# set rootname [file rootname [file tail $template_filename]]
		# set lqn_filename "generated/$rootname-${Z}sec-$N.lqn" 
		# set lqn_filename [file join $result_dirname "$rootname-${Z}$tijd_eenheid-$N.lqn"]
		# puts $fo "$N\t$X\t$R\t$Z\t$U"

		read_lqn $lqn_filename D_max D_sum
		set do_calc 1
		if {$D_max == 0} {
			log "D_max = 0" warn lqnscontrol
			set do_calc 0
		}
		if {$D_sum == 0} {
			log "D_sum = 0" warn lqnscontrol
			set do_calc 0
		}
		if {$do_calc} {		
			set X1 [expr 1.0 / $D_max]
			set X2 [expr 1.0 * $N / ($D_sum + $Z)]
			log "D_max: $D_max; D_sum: $D_sum; X1: $X1; X2: $X2" debug lqnscontrol
			if {$X1 < $X2} {
				set X $X1
			} else {
				set X $X2
			}
	
			set R1 $D_sum
			set R2 [expr 1.0 * $N * $D_max - $Z]
			if {$R1 > $R2} {
				set R $R1
			} else {
				set R $R2
			}
		} else {
			set X 0
			set R 0
		}
		# puts $fo "$N\t$X\t$R\t0\t$Z\t$D_max\t$D_sum"
		log "finished" debug lqnscontrol
	}

	private method read_lqn {lqn_filename D_max_name D_sum_name} {
		upvar $D_max_name D_max
		upvar $D_sum_name D_sum
		log "start" debug lqnscontrol
		set f [open $lqn_filename r]

#E 0
#s showcase 1.0E-7 -1
#s showcase_cpu 0.02 -1
#s EBGCpu 0.05 -1
#y showcase showcase_cpu 1.0 -1
#-1
		set avgcalls_list {}
		set procnames {}
		# state: BEGIN, ENTRIES, PROCESSORS, TASKS
		set state BEGIN
		while {![eof $f]} {
			gets $f line
			if {[regexp {^#} $line]} {
				log "comment regel (1): $line, naar volgende" debug lqnscontrol
				continue
			}			
			set state [det_state $state $line]
			if {$state == "BEGIN"} {
				# do nothing
			} elseif {$state == "ENTRIES"} {
				handle_entry_line $line
			} elseif {$state == "PROCESSORS"} {
				handle_processor_line $line
			} elseif {$state == "TASKS"} {
				handle_task_line $line
			} else {
				fail "Unknown state: $state"
			}
		}	
		close $f

		calc_trans_avgcalls $avgcalls_list avgcalls

		# nu de assoc array's verder behandelen.
		foreach e_name [array names serv] {
			# set servdemand($e_name) [calc_servdemand $e_name serv avgcalls]
			set servdemand($e_name) [expr $serv($e_name) * $avgcalls($e_name)]
			log "set servdemand($e_name) = $servdemand($e_name) ($serv($e_name) (S) * $avgcalls($e_name) (#))" debug lqnscontrol
		}

		# entry D's naar processor D's omrekenenen
		# @todo houd rekening met processor multiplicity
		foreach proc_name $procnames {
			log "adding entries for $proc_name" debug lqnscontrol
			set D_proc 0.0
			foreach entryname $entries($proc_name) {
				log "adding D($entryname) to D($proc_name)" debug lqnscontrol
				set D_proc [expr $D_proc + $servdemand($entryname)]
			}
			set proc_servdemand($proc_name) [expr $D_proc / $mult_proc($proc_name)]
			log "set proc_servdemand($proc_name) = $proc_servdemand($proc_name)" debug lqnscontrol
		}

		set D_max 0.0
		set D_sum 0.0
		$log debug "procnames: $procnames"
		foreach proc_name $procnames {
			set D $proc_servdemand($proc_name)
			# set D_sum [expr $D_sum + [include_D_sum $proc_name $D]]
			set D_sum [expr $D_sum + $D]
			# set D [include_D_max $proc_name $D]
			if {$D_max < $D} {
				set D_max $D
			}
		}
		log "finished" debug lqnscontrol		
	}		
		
	private method det_state {old_state line} {
		set result $old_state
		if {[regexp {^E [0-9]+$} $line]} {
			set result "ENTRIES"
		} elseif {[regexp {^P [0-9]+$} $line]} {
			set result "PROCESSORS"
		} elseif {[regexp {^T [0-9]+$} $line]} {
			set result "TASKS"
		} elseif {$line == "-1"} {
			set result "BEGIN"
		} else {
			# don't change state
		}
		return $result	
	}	

	private method handle_entry_line {line} {
		log "line (2): $line" debug lqnscontrol
		set line [string trim $line]
		if {[regexp {^s ([^ ]+) ([-0-9\.E]+) -1$} $line z name S]} {
			set serv($name) $S
		} elseif {[regexp {^y ([^ ]+) ([^ ]+) ([-0-9\.E]+) -1$} $line z caller callee avg]} {
			# set avgcalls($caller,$callee) $avg
			lappend avgcalls_list [list $caller $callee $avg]
		} else {
			# do nothing
		}	
	}
	
	private method handle_processor_line {line} {
		log "line (3): $line" debug lqnscontrol
		set line [string trim $line]
		#p PBrowser f m 90
		#p PHttp f
		#p PWPS f m 1
		set mult 1
		if {[regexp {p ([^ ]+) .( m ([0-9]+))?} $line z procname z mult]} {
			if {$mult != ""} {
				set mult_proc($procname) $mult
			} else {
				# mogelijk regexp wel ok, maar geen mult, kan dan op lege string worden gezet.
				set mult_proc($procname) 1
			}
			lappend procnames $procname
		} else {
			# do nothing
		}
	}

	private method handle_task_line {line} {
		#t TBrKB r EBrKB -1 PBrowser z 60 m 90
		#t THttpKB f EHttpInlog EHttpZoek EHttpSelect -1 PHttp m 30
		#t TWPSKB f EWPSInlog EWPSZoek EWPSSelect -1 PWPS m 20
		#t TDBKB f EDBSettings -1 PDB m 3
		# read tasks and entries for a processor
		log "line (4): $line" debug lqnscontrol
		set line [string trim $line]
		if {[regexp {^t ([^ ]+) (.) (.*)$} $line z taskname tasktype rest]} {
			handle_task $taskname $tasktype $rest entry_list proc_name
			set entries($proc_name) $entry_list
			log "*** set entries($proc_name) to $entries($proc_name)" debug lqnscontrol
		} elseif {$line == "-1"} {
			set continue 0
		} else {
			# do nothing
		}
	}

	# @param: taskname: Txxx
	# @param: tasktype: r (ref), f (fcfs), i (inf)
	# @param: rest: EHttpInlog EHttpZoek EHttpSelect -1 PHttp m 30
	proc handle_task {taskname tasktype rest entry_list_name proc_name_name} {
		upvar $entry_list_name entry_list
		upvar $proc_name_name proc_name
		log "start" debug lqnscontrol
		set entry_list {}
		set proc_name "dummy"
		set next_proc 0
		foreach el $rest {
			if {$next_proc} {
				set proc_name $el
				break
			} else {
				if {$el == "-1"} {
					set next_proc 1
				} else {
					lappend entry_list $el
				}
			}
		}
		if {($tasktype == "r") || ($tasktype == "i")} {
			set entry_list {}
			log "set entry_list to empty, tasktype = $tasktype" debug lqnscontrol
		} else {
			log "entries for processor $proc_name: $entry_list" debug lqnscontrol
		}
		log "finished" debug lqnscontrol
	}

	# calculate transitive closure of calls
	# @pre (for now): the calls are in the correct order, top to bottom
	# @pre each entry is only called once, it's a tree from top to bottom.
	# @post for each entry there is an item in the avgcalls array: avgcalls(entryname) = x, where
	# x is the avg number of calls to the entry from the source/client/reference entry.
	private method calc_trans_avgcalls {avgcalls_list avgcalls_name} {
		upvar $avgcalls_name avgcalls
		set avgcalls($entry_name) 1.0 ; # entry_name is the name of the source entry
		foreach el $avgcalls_list {
			set caller [lindex $el 0]
			set callee [lindex $el 1]
			set avg [lindex $el 2]
			set avgcalls($callee) [expr $avgcalls($caller) * $avg]
		}
	}

	# aan de sum toevoegen als het geen background/BG process is.
	private method include_D_sum {name D} {
		if {[regexp {BG} $name]} {
			return 0.0
		} else {
			return $D
		}
	}

	# voor max bepalen als het geen background en geen netwerk latency is.
	private method include_D_max {name D} {
		log "start (entry_name=$entry_name)" debug lqnscontrol
		set D [include_D_sum $name $D]
		if {[regexp {ltc} $name]} {
			return 0.0
		} elseif {$name == $entry_name} {
			return 0.0
		} else {
			return $D
		}
	}	
	
}	