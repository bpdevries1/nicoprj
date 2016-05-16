package require Itcl

source [file join $env(CRUISE_DIR) checkout lib perflib.tcl]
source [file join $env(CRUISE_DIR) checkout script lib CLogger.tcl]

itcl::class CEnhanceWorkloadData {
	private common log
	set log [CLogger::new_logger overzicht perf]
	# set log [CLogger::new_logger graph_asmf debug]
	private variable lst_header_in
	private variable lst_header_out
	private variable ar_values
	private variable ar_calc
	private variable cur_date
	private variable fo_empty
	private variable prev_time
	
	# @param start_date: 20-10-2008
	public method enhance {file_name str_start_date} {
		# start date om 12:00 uur 's middags zetten, ivm wintertijd/zomertijd.
		set cur_date [clock scan "$str_start_date-12:00" -format "%d-%m-%Y-%H:%M"]
		set fi [open $file_name r]
		set fo [open [det_file_name_enhanced $file_name] w]
		set fo_empty 1
		set prev_time "" ; # zodat bij eerste vergelijking de datum niet meteen wordt opgehoogd.
		# read_header $fi $fo
		while {![eof $fi]} {
			if {[read_line $fi $fo]} {
				calc_line
				print_line $fo
			}			
		}
		close $fo
		close $fi
	}
	
	private method det_file_name_enhanced {file_name} {
		return "[file rootname $file_name]-enhanced[file extension $file_name]"
	}
	
	# @return: 0 if non-data line, 1 if a data-line read.
	# @post: if one data-line read, contents in ar_values(<col>), 
	private method read_line {fi fo} {
		gets $fi line
		$log debug "read line: $line"
		if {[regexp {SYSTEM} $line]} {
			read_header $line $fo
			return 0
		}
		set l [split $line "\t"]
		if {[llength $l] > 5} {
			set i 0
			foreach el $lst_header_in {
				set val [lindex $l $i]
				regsub "," $val "." val
				if {[regexp {none} $val]}  {
					set val 0.0
				}
				if {($el == "TIME") && ([string length $val] == 4)} {
					set val "0$val"
				}
				set ar_values($el) $val
				incr i
			}
			return 1
		} else {
			return 0
		}
	}

	private method read_header {line fo} {
		# gets $fi line
		set lst_header_in [split $line "\t"]
		set lst_header_in [lreplace $lst_header_in 0 1 "DATE" "TIME"]
		$log debug "lst_header_in: $lst_header_in"
		if {$fo_empty} {
			set lst_header_out $lst_header_in
			lappend lst_header_out DATETIME TOTAL MONITOR BROKER TOTAL_R
			puts $fo [join $lst_header_out "\t"]
			set fo_empty 0
		}
	}
	
	# @pre: values in ar_values(<col>)
	# @post: one line handled, with values in ar_calc(<col>) 
	# with col: timestamp (20081110-164023), TOTC, TOTE (both in seconds) and TOTM
	private method calc_line {} {
		if {[string length $ar_values(DATE)] > 0 } {
			set cur_date [clock scan "$ar_values(DATE)-0:00" -format "%d-%m-%Y-%H:%M"]
		} elseif {$ar_values(TIME) < $prev_time} {
			set cur_date [expr $cur_date + (24 * 60 * 60)]
		}
		set prev_time $ar_values(TIME)
		set ar_values(DATE) [clock format $cur_date -format "%d-%m-%Y"]
		set time $ar_values(TIME)
		set ar_values(DATETIME) "[clock format $cur_date -format "%d-%m-%Y"]-$time"
		set ar_values(TOTAL) [calc_total]
		# set ar_values(MONITOR) [expr $ar_values(SYSTEM) + $ar_values(STCDEF_R) + $ar_values(SYSSTC) + $ar_values(NONCLASS_R)]
		# set ar_values(BROKER) [expr $ar_values(MQ_R) + $ar_values(STCHIGH)]
		set ar_values(MONITOR) [expr $ar_values(SYSTEM) + $ar_values(SYSSTC)]
		set ar_values(BROKER) $ar_values(STCHIGH)
		set ar_values(TOTAL_R) [calc_total_R]
	}

	# vreen00, 27-11-08: alleen kolommen zonder _R, anders dubbeltellingen.
	private method calc_total {} {
		set total 0.0
		foreach el [lrange $lst_header_in 2 end] {
			if {![regexp {_R$} $el]} {
				set total [expr $total + $ar_values($el)]
			}
		}
		return $total		
	}

	private method calc_total_R {} {
		set total 0.0
		foreach el [lrange $lst_header_in 2 end] {
			if {[regexp {_R$} $el]} {
				set total [expr $total + $ar_values($el)]
			}
		}
		return $total		
	}
	
	private method print_line {fo} {
		set lst {}
		foreach el $lst_header_out {
			set val $ar_values($el)
			catch {set val [format "%.4f" $val]}
			lappend lst $val
		}
		puts $fo [join $lst "\t"]
	}
	
}

proc main {argc argv} {
	set file_name [lindex $argv 0]
	set str_start_date [lindex $argv 1]
	set o [CEnhanceWorkloadData #auto]
	$o enhance $file_name $str_start_date
}

main $argc $argv
