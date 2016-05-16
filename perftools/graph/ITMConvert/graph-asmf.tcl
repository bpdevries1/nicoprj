package require Itcl

source [file join $env(CRUISE_DIR) checkout lib perflib.tcl]
source [file join $env(CRUISE_DIR) checkout script lib CLogger.tcl]

itcl::class CGraphAsmf {
	private common log
	set log [CLogger::new_logger overzicht perf]
	# set log [CLogger::new_logger graph_asmf debug]
	private variable lst_header_in
	private variable lst_header_out
	private variable ar_values
	private variable ar_calc
	private variable curr_ts_start
	private variable curr_ts_end
	private variable curr_ts_writetime
	private variable totc
	private variable tote
	private variable totm
	private variable fo
	private variable fo_empty
	private common p232 4294967296 ; # 2 to the power of 32.

	
	public method make_graph {dir_name} {
		create_output_file $dir_name
		foreach subdir_name [lsort [glob -directory $dir_name -type d "T*"]] {
			add_graph_data $subdir_name
		}
		close_output_file		
	}
	
	private method create_output_file {dir_name} {
		set base_name [file join $dir_name "KQITASMF"]
		set fo [open "$base_name.graphdata" w]
		set fo_empty 1
	}
	
	private method close_output_file {} {
		close $fo
	}
	
	private method add_graph_data {dir_name} {
		$log info "Handling dir: $dir_name ..."
		set input_name [file join $dir_name "KQITASMF.tsv"]
		if {![file exists $input_name]} {
			$log warn "Warning: no input file $input_name"
			return
		}
		set fi [open $input_name r]
		read_header $fi $fo
		set curr_ts_start "<unknown>"
		set curr_ts_end "<unknown>"
		set curr_ts_writetime "<unknown>"
		while {![eof $fi]} {
			if {[read_line $fi]} {
				calc_line
				if {$curr_ts_writetime != $ar_calc(TIMESTAMP_WRITETIME)} {
					if {$curr_ts_writetime != "<unknown>"} {
						print_line $fo
					}
					set curr_ts_writetime $ar_calc(TIMESTAMP_WRITETIME)
					set curr_ts_start $ar_calc(TIMESTAMP_START)
					set curr_ts_end $ar_calc(TIMESTAMP_END)
					set totc $ar_calc(TOTC)
					set tote $ar_calc(TOTE)
					set totm $ar_calc(TOTM)
				} else {
					set totc [expr $totc + $ar_calc(TOTC)]
					set tote [expr $tote + $ar_calc(TOTE)]
					set totm [expr $totm + $ar_calc(TOTM)]
				}
			}
		}
		print_line $fo
		close $fi
	}
	
	private method read_header {fi fo} {
		gets $fi line
		set lst_header_in [split $line "\t"]
		set lst_header_in [map [lambda str {regexp {^([^\( ]+)} $str z str2; return $str2}] $lst_header_in]
		$log debug "lst_header_in: $lst_header_in"
		if {$fo_empty} {
			set lst_header_out [list TIMESTAMP_WRITETIME TIMESTAMP_START TIMESTAMP_END TOTC TOTE TOTM]
			puts $fo [join $lst_header_out "\t"]
			set fo_empty 0
		}
	}
	
	# @post: one line read, contents in ar_values(<col>), 
	private method read_line {fi} {
		gets $fi line
		set l [split $line "\t"]
		if {[llength $l] > 5} {
			set i 0
			foreach el $lst_header_in {
				set ar_values($el) [lindex $l $i]
				incr i
			}
			return 1
		} else {
			return 0
		}
	}
	
	# @pre: values in ar_values(<col>)
	# @post: one line handled, with values in ar_calc(<col>) 
	# with col: timestamp (20081110-164023), TOTC, TOTE (both in seconds) and TOTM
	private method calc_line {} {
		# WRITETIME: 1081105130050000
		# vreen00, 27-11-08: gebruik EDTTM ipv WRITETIME
		if {[regexp {^([0-9]{3})([0-9]{4})([0-9]{6})} $ar_values(EDTTM) z yr date tm]} {
			set ar_calc(TIMESTAMP_END) "[expr 1900 + $yr]$date-$tm"
		}
		# vreen00, 27-11-08: starttime ook opnemen, zodat looptijd van deze meting bepaald kan worden.
		if {[regexp {^([0-9]{3})([0-9]{4})([0-9]{6})} $ar_values(SDTTM) z yr date tm]} {
			set ar_calc(TIMESTAMP_START) "[expr 1900 + $yr]$date-$tm"
		}

		if {[regexp {^([0-9]{3})([0-9]{4})([0-9]{6})} $ar_values(WRITETIME) z yr date tm]} {
			set ar_calc(TIMESTAMP_WRITETIME) "[expr 1900 + $yr]$date-$tm"
		}
		
		set ar_calc(TOTC) [expr 0.000001 * $ar_values(TOTC)]
		if {$ar_values(TOTE) < 0} {
			$log warn "TOTE < 0, adding 2^32: $ar_values(TOTE)"
			set ar_values(TOTE) [expr $ar_values(TOTE) + $p232]
		}

		set ar_calc(TOTE) [expr 0.000001 * $ar_values(TOTE)]
		set ar_calc(TOTM) $ar_values(TOTM)
	}
	
	private method print_line {fo} {
		puts $fo [join [list $curr_ts_writetime $curr_ts_start $curr_ts_end [format "%.3f" $totc] [format "%.3f" $tote] $totm] "\t"]
	}
	
}

proc main {argc argv} {
	set dir_name [lindex $argv 0]
	set o [CGraphAsmf #auto]
	$o make_graph $dir_name
}

main $argc $argv
