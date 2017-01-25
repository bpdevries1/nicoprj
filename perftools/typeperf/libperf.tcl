# generic performance test helper functions.
# [2016-10-04 10:49:41] For now only for RRS.

# Helper for rampup with one thread but increasing load.
# Parameters:
# rampup_sec        - Total time in seconds of rampup period
# items_per_sec     - Items per second after rampup period
# elapsed_start_sec - Elapsed seconds since start of the test.
# start_it_msec     - Time at start of iteration in milliseconds.
# end_it_msec       - Time at end of iteration in milliseconds
proc det_wait_msec {rampup_sec items_per_sec elapsed_start_sec start_it_msec end_it_msec end_test_sec} {
	if {$elapsed_start_sec < $rampup_sec} {
		#T = huidige tijd in sec, tijd bij de start van het item.
		#X = doel tps
		#R = ramup periode in seconden
		set discr [expr (1.0*$elapsed_start_sec*$items_per_sec)**2 + (4.0*$items_per_sec*$rampup_sec)]
		set pacing_msec [expr round(1000.0 * (-$elapsed_start_sec*$items_per_sec + sqrt($discr)) / (2.0*$items_per_sec))]
		#discr = (TX)^2 + 4XR
		#pacing = (-TX + sqrt(discr)) / (2X)
	} else {
		set curr_items_per_sec $items_per_sec
		set pacing_msec [expr round(1000.0 / $curr_items_per_sec)]
	}
	log debug "current pacing msec: $pacing_msec"
	if {$pacing_msec == "Inf"} {
	  breakpoint
	}
	#if {$pacing_msec > $max_pacing_msec} {
	#  set pacing_msec $max_pacing_msec
	#}
	set wait_msec [expr $pacing_msec - ($end_it_msec - $start_it_msec)]
  set wait_msec_end [expr (1000.0 * $end_test_sec) - $end_it_msec]
  # breakpoint
  if {$wait_msec_end < $wait_msec} {
    set wait_msec [expr $wait_msec_end + 100]; # add 1 second to be sure.
    log info "End of test is near: wait $wait_msec msec."
  } else {
    # log info "Wait normal pacing: $wait_msec msec"
  }
  
	log debug "time used for item: [expr ($end_it_msec - $start_it_msec)]"
	log debug "current wait msec: $wait_msec"
	return $wait_msec
}

# Wait a bit so pacing is correct, frequency of doing actions.
# Don't wait until after end_sec, end of the test.
proc wait_pacing {pacing_sec start_msec end_test_sec} {
  set end_msec [clock clicks -milliseconds]
  set wait_msec [expr 1000*$pacing_sec - ($end_msec - $start_msec)]
  set wait_msec_end [expr (1000.0 * $end_test_sec) - $end_msec]
  # breakpoint
  if {$wait_msec_end < $wait_msec} {
    set wait_msec [expr $wait_msec_end + 100]; # add 1 second to be sure.
    log info "End of test is near: wait $wait_msec msec."
  } else {
    log debug "Wait normal pacing: $wait_msec msec"
  }
  if {$wait_msec > 0} {
    # after [expr round($wait_msec)]
    wait_msec $wait_msec
  }
}

# wait msec milliseconds, but do an update every second to handle othe wait/after events.
proc wait_msec {msec} {
  set msec [expr round($msec)]
  set end_msec [expr [clock milliseconds] + $msec]
  while {[clock milliseconds] < $end_msec} {
    set to_wait_msec [expr $end_msec - [clock milliseconds]]
    if {$to_wait_msec > 1000} {
      set to_wait_msec 1000
    }
    after $to_wait_msec
    update
  }
}

# Generic dict helper?
proc dict_to_str {d} {
  # join [map kv {string trim "[:0 $kv]: [:1 $kv]"} [lsort [dict get $d]]] ", "
  set res {}
  foreach k [lsort [dict keys $d]] {
    lappend res "$k: [dict get $d $k]"
  }
  join $res ", "
}

# @param ts - 2015-11-24--14-02-30.168
proc ts_parse_msec {ts} {
  if {[regexp {^([^.]+)(\.\d+)$} $ts z sec msec]} {
    try_eval {
      set res [expr [clock scan $sec -format "%Y-%m-%d--%H-%M-%S"] + $msec]
    } {
      log error "Parsing timestamp failed for: $ts/sec"
      breakpoint
    }
    return $res
  } else {
    log error "Cannot parse timestamp with msec: $ts"
    breakpoint
  }
}

