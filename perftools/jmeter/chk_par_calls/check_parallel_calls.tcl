package require Itcl

source [file join $env(CRUISE_DIR) checkout lib perflib.tcl]
source [file join $env(CRUISE_DIR) checkout script lib CLogger.tcl]

# @todo deze nieuwe CTimestamp.tcl op de orig locatie neerzetten.
source CTimestamp.tcl
source [file join $env(CRUISE_DIR) checkout script lib CHtmlHelper.tcl]

# set log [CLogger::new_logger chk_par_call debug]
set log [CLogger::new_logger chk_par_call info]

proc main {argc argv} {
	global log hh linenr

	check_params $argc $argv
	set dirname [lindex $argv 0]

	# set constanten
	set_lab151
	# set_aix148

	set fjtl [open [file join $dirname report.jtl] r]
	set portals_log_name [lindex [glob -directory $dirname *.portals.log] 0]
	# set flog [open [file join $dirname wps1.portals.log] r]
	set flog [open $portals_log_name r]
	set linenr 0 ; # current linenr in flog.
	set fhtml [open [file join $dirname analyse.html] w]
	gets $fjtl line ; # header line

	set hh [CHtmlHelper::new]
	$hh set_channel $fhtml
	$hh write_header "Log analyse"

	set state "START"
	while {![eof $fjtl]} {
		gets $fjtl line
		set l [split $line ","]
		set time [lindex $l 1]
		set label [lindex $l 2]
		# $log debug "label: $label"
		if {$label == "Login"} {
			set state "LOGIN"
		} elseif {$label == "SelectKlant"} {
			handle_selklant $flog $state $time
			set state "LOOP"
		} elseif {$label == "ZoekKlantBSN"} {
			handle_zoekklant $flog
			if {0} {
				# gets $flog line ; # 1 log line voor zoekbsn.
				set el_line [lindex [readlines $flog 1] 0] ; # 1 log line voor zoekbsn.
				set line [lindex $el_line 1] ; # 1e element is linenr, 2e is de line.
				# check dat dit raadplegenNatuurlijkPersoonActueel is, deze ook altijd zonder workthread
				if {![regexp {WebContainer.+raadplegenNatuurlijkPersoonActueel} $line]} {
					# $log error "Expected raadplegenNatuurlijkPersoonActueel, got: $line"
					fail "Expected raadplegenNatuurlijkPersoonActueel, linenr: $linenr; got: $line"
				}
			}
		}
	}

	$hh heading 1 "De rest van wps1.portals.log:"
	while {![eof $flog]} {
		gets $flog line
		$hh line $line
	}
	
	close $flog
	close $fjtl
	$hh write_footer
	close $fhtml
}

proc check_params {argc argv} {
	global stderr argv0
	if {$argc != 1} {
		puts stderr "syntax: $argv0 <dirname>; got: $argv"
		exit 1
	}
}

proc handle_zoekklant {flog} {
	global ZOEKKLANT_NLINES linenr
	# gets $flog line ; # 1 log line voor zoekbsn.
	if {$ZOEKKLANT_NLINES > 0} {
		set line_el [lindex [readlines $flog $ZOEKKLANT_NLINES] 0] ; # 1 log line voor zoekbsn.
		set line [lindex $line_el 1]
		# check dat dit raadplegenNatuurlijkPersoonActueel is, deze ook altijd zonder workthread
		if {![regexp {WebContainer.+raadplegenNatuurlijkPersoonActueel} $line]} {
			# $log error "Expected raadplegenNatuurlijkPersoonActueel, got: $line"
			fail "Expected raadplegenNatuurlijkPersoonActueel, linenr: $linenr; got: $line"
		}
	}
}

proc handle_selklant {flog state time} {
	global log hh SELKLANT_NLINES_1 SELKLANT_NLINES_2
	if {$state == "LOGIN"} {
		# set lst_lines [readlines $flog 5] ; #excl parallel rendering
		set lst_lines [readlines $flog $SELKLANT_NLINES_1] ; #excl parallel rendering
	} else {
		# set lst_lines [readlines $flog 7] ; #incl parallel rendering
		set lst_lines [readlines $flog $SELKLANT_NLINES_2] ; #excl parallel rendering
	}

	$hh heading 2 "Gebruikers actie"
	$hh line "SelectKlant: $time ms"
	$hh line "Log runtime: [det_log_runtime $lst_lines]"
	puts_threads $lst_lines
	
	$hh heading 3 "Lines uit logfile"
	foreach line_el $lst_lines {
		set linenr [lindex $line_el 0]
		set line [lindex $line_el 1]
		$hh line "$linenr: [add_start_time $line]"
	}
	# puts [join $lst_lines "\n"]
	$hh hr
}

# @return lst with lines, where each element is a list containing a linenr and the line-contents.
proc readlines {flog nlines} {
	global log linenr LOG_PARALLEL_RENDERING
	$log debug "Linenr before reading: $linenr"
	set lst {}
	for {set i 0} {$i < $nlines} {incr i} {
		set is_perfline 0
		while {!$is_perfline} {
			incr linenr
			gets $flog line
			if {[regexp { PERF +\(} $line]} {
				# parallel rendering logregels alleen meenemen als constante is 1, wordt niet gelogd bij exception, niet in finally clause blijkbaar.
				if {[regexp {arallel rendering} $line]} {
					set is_perfline $LOG_PARALLEL_RENDERING
				} else {
					set is_perfline 1
				}
			}
		}
		# lappend lst $line
		lappend lst [list $linenr $line]
	}
	$log debug "Linenr after reading: $linenr"
	return $lst
}

# if ELAPSED time exists in line, calculate the starttime and prepend to the line.
proc add_start_time {line} {
	set str_start_time [det_str_start_time $line]
	if {$str_start_time == ""} {
		return $line
	} else {
		return "$str_start_time -> $line"
	}
}

proc det_str_start_time {line} {
	set lower_line [string tolower $line]
	if {[regexp {^(.+) perf .* elapsed( time)?: ?([0-9]+)$} $lower_line z endtime z msec]} {
		set cts [CTimestamp::new_timestamp]
		$cts set_portals_log_timestamp $endtime
		$cts add_milliseconds -$msec
		set str_start_time [$cts format_milliseconds]
		set result "$str_start_time"
	} else {
		set result ""
	}
	return $result
}

# @return [lst cts_start cts_end elapsed]
proc det_times {line} {
	set lower_line [string tolower $line]
	if {[regexp {^(.+) perf .* elapsed( time)?: ?([0-9]+)$} $lower_line z endtime z msec]} {
		set cts_end [CTimestamp::new_timestamp]
		$cts_end set_portals_log_timestamp $endtime
		set cts_start [CTimestamp::new_timestamp $cts_end]
		$cts_start add_milliseconds -$msec
		set elapsed $msec
		set result [list $cts_start $cts_end $elapsed]
	} else {
		set result {}
	}
	return $result
}

# 2007-09-12 10:10:49,902 PERF  (WebContainer : 2:) [RelatieInformatieServiceImpl] raadplegenNatuurlijkPersoonActueel succes:true - ELAPSED TIME: 1897
# 2007-09-12 10:10:52,340 PERF  (WebContainer : 0:) [ToonKlantController] /portals-sc-inzienrelaties-klant/  [perf00001638] Parallel rendering (toon klant) elapsed:1558
# @return [list cts_start cts_end elapsed thread_name action_name]
proc parse_line {line} {
	set lower_line [string tolower $line]
	if {[regexp {^(.+) perf +\(([^\)]+)\) +[^\]]+\] +(.*) elapsed( time)?: ?([0-9]+)$} $lower_line z endtime thr act z msec]} {
		set cts_end [CTimestamp::new_timestamp]
		$cts_end set_portals_log_timestamp $endtime
		set cts_start [CTimestamp::new_timestamp $cts_end]
		$cts_start add_milliseconds -$msec
		set elapsed $msec
		set result [list $cts_start $cts_end $elapsed $thr $act]
	} else {
		set result {}
	}
	return $result
}

# @return <from_time> -> <to_time> ELAPSED: <ms>
proc det_log_runtime {lst_lines} {
	global log
	$log debug start
	set result ""
	set first_line 1
	set all_cts_start 0
	set all_cts_end 0
	foreach line_el $lst_lines {
		set line [lindex $line_el 1]
		$log debug "line: $line"
		set times [det_times $line]
		if {[llength $times] == 3} {
			foreach {cts_start cts_end elapsed} $times {
				$log debug "cts_start: $cts_start"
				if {$first_line} {
					set all_cts_start $cts_start
					set all_cts_end $cts_end
				} else {
					if {[$cts_start is_before $all_cts_start]} {
						set all_cts_start $cts_start
					}
					if {[$all_cts_end is_before $cts_end]} {
						set all_cts_end $cts_end
					}
				}
				set first_line 0
			}
		}
	}
	if {($all_cts_start) != 0 && ($all_cts_end != 0)} {
		set elapsed [$all_cts_end det_msec_diff $all_cts_start]
		set result "[$all_cts_start format_milliseconds] -> [$all_cts_end format_milliseconds] ELAPSED: $elapsed"
	} else {
		set result "Unable to determine log_runtime"
	}
	$log debug finished
	return $result
}

proc puts_threads {lst_lines} {
	global hh
	foreach line_el $lst_lines {
		set line [lindex $line_el 1]
		foreach {cts_start cts_end elapsed thread_name action_name} [parse_line $line] {
			# kan zijn dat op hetzelfde tijdstip in dezelfde thread 2 acties zijn.
			append_actions ar_actions $thread_name $cts_start $elapsed "$action_name.start"
			append_actions ar_actions $thread_name $cts_end $elapsed "$action_name.end"

			# set ar_actions($thread_name,[$cts_start det_sec_abs]) "\[[format %03d $elapsed]\] $action_name.start"
			# set ar_actions($thread_name,[$cts_end det_sec_abs]) "\[[format %03d $elapsed]\] $action_name.end"

			set ar_threads($thread_name) 1
			set ar_timestamps([$cts_start det_sec_abs]) $cts_start
			set ar_timestamps([$cts_end det_sec_abs]) $cts_end
		}
	}
	$hh table_start
	$hh table_row_start
	$hh table_data "Timestamp" 1
	set lst_threads [lsort [array names ar_threads]]
	foreach el $lst_threads {
		$hh table_data $el 1
	}
	$hh table_row_end

	foreach ts_sec [lsort -real [array names ar_timestamps]] {
		$hh table_row_start
		$hh table_data [$ar_timestamps($ts_sec) format_milliseconds]
		foreach thread_name $lst_threads {
			set data "-"
			catch {set data $ar_actions($thread_name,$ts_sec)}
			$hh table_data $data
		}
		$hh table_row_end
	}
	$hh table_row_end
	$hh table_end
}

proc append_actions {ar_actions_name thread_name cts elapsed action} {
	upvar $ar_actions_name ar_actions
	set el ""
	catch {set el $ar_actions($thread_name,[$cts det_sec_abs])}
	if {$el != ""} {
		set el "$el<br/>"
	}
	set ar_actions($thread_name,[$cts det_sec_abs]) "$el\[[format %03d $elapsed]\] $action"
}

# settings voor 148 op 19-9-2007
proc set_aix148 {} {
	global LOG_PARALLEL_RENDERING ZOEKKLANT_NLINES SELKLANT_NLINES_1 SELKLANT_NLINES_2

	set LOG_PARALLEL_RENDERING 1
	set ZOEKKLANT_NLINES 0
	set SELKLANT_NLINES_1 4 ; # aantal regels in log na inloggen, eerste keer zoeken/selecteren.
	set SELKLANT_NLINES_2 5 ; # aantal regels in log hierna
}

# settings voor 151 per 18-9-2007
proc set_lab151 {} {
	global LOG_PARALLEL_RENDERING ZOEKKLANT_NLINES SELKLANT_NLINES_1 SELKLANT_NLINES_2

	set LOG_PARALLEL_RENDERING 0
	set ZOEKKLANT_NLINES 1
	set SELKLANT_NLINES_1 5 ; # aantal regels in log na inloggen, eerste keer zoeken/selecteren.
	set SELKLANT_NLINES_2 5 ; # aantal regels in log hierna
}


main $argc $argv


