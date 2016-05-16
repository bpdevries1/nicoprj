package require Itcl

# class maar eenmalig definieren
if {[llength [itcl::find classes CGraphMaker]] > 0} {
	return
}

source [file join $env(CRUISE_DIR) checkout lib perflib.tcl]
source [file join $env(CRUISE_DIR) checkout script lib CLogger.tcl]

itcl::class CGraphMaker {

	private common log
	# set log [CLogger::new_logger cgraphmaker debug]
	set log [CLogger::new_logger cgraphmaker info]

	private common DOT_EXE "c:/util/ATT/graphviz/bin/dot.exe"

	public proc new_instance {a_dirname} {
		set inst [uplevel {namespace which [CGraphMaker #auto]}]
		$inst init $a_dirname
		return $inst
	}


	# instance
	private variable f ; # file object for .dot file
	private variable ar_process_handled
	private variable dirname
	
	public method init {a_dirname} {
		set dirname $a_dirname
	}

	# @param lst_processes_start : list of processes to start the graph with (roots)
	public method make_graph {lst_processes_start} {
		global env
		
		$log info "start making the graph"
		set f [open [file join $dirname "system.dot"] w]
		puts $f "digraph G {" 
  	# puts $f "rankdir = \"LR\""
  	# puts $f "size = \"50,12\""
		foreach cprocess $lst_processes_start {
			puts_process $cprocess
		}
		
		puts $f "}"
		close $f
		
		catch {set DOT_EXE $env(DOT_EXE)}
		exec $DOT_EXE -Tpng -o [file join $dirname "system.png"] [file join $dirname "system.dot"]

		$log info "finished making the graph"
	}

	private method puts_process {cprocess} {
		set handled 0
		catch {set handled $ar_process_handled($cprocess)}
		if {!$handled} {
			set ar_process_handled($cprocess) 1
			set process_uid [det_dot_id $cprocess]
			# use process object as unique id
			puts $f "$process_uid \[label=\"[$cprocess to_short_string]\", style=solid\];"
			if {[$cprocess get_pid] != "pid?"} {
				foreach cconn [$cprocess get_connections] {
					set to_list [$cconn is_to_listening]
					# @invariant: cconn.from_proc == cprocess
					set to_proc [$cconn get_to_proc]
					set to_proc_uid [det_dot_id $to_proc]
					# set conn_label "[$cconn get_from_port] -> [$cconn get_to_port]"
					set conn_label [$cconn to_short_string]
					if {$to_list == 1} {
						# normal path: from is client, to is listening server.
						# _build_suite_xml -> ___extrabuildfile_ [label="", fontsize=8];
						$log debug "Sure that to is listening: label=$conn_label"
						puts $f "$process_uid -> $to_proc_uid \[label=\"$conn_label\", fontsize=8\];"
						puts_process $to_proc
					} elseif {$to_list == 0} {
						# # nothing, this is the return-connection	
						# don't print, this is the return-connection	
						# but do traverse
						puts_process $to_proc
					} elseif {$to_list == -1} {
						# for now, puts the connection, maybe we get both now.
						$log warn "Unknown if to is listening: label=$conn_label"
						puts $f "$process_uid -> $to_proc_uid \[label=\"$conn_label\", fontsize=8\];"
						puts_process $to_proc
					}
				}
			} else {
				# pid is unknown, so this is an external process, we have no further info	on this one.
			}
		}		
	}
	
	private method det_dot_id {cprocess} {
		regsub -all ":" $cprocess "_" process_uid
		return $process_uid		
	}
	
	
}
