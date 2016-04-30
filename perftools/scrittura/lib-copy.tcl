# helper functions to be used both by copymail.tcl and copyfile.tcl

proc det_wait_msec {rampup_sec mails_per_sec elapsed_start_sec start_it_msec end_it_msec} {
	if {$elapsed_start_sec < $rampup_sec} {
		#T = huidige tijd in sec, tijd bij de start van het mail aanmaken.
		#X = doel tps
		#R = ramup periode in seconden
		set discr [expr (1.0*$elapsed_start_sec*$mails_per_sec)**2 + (4.0*$mails_per_sec*$rampup_sec)]
		set pacing_msec [expr round(1000.0 * (-$elapsed_start_sec*$mails_per_sec + sqrt($discr)) / (2.0*$mails_per_sec))]
		#discr = (TX)^2 + 4XR
		#pacing = (-TX + sqrt(discr)) / (2X)
	} else {
		set curr_mails_per_sec $mails_per_sec
		set pacing_msec [expr round(1000.0 / $curr_mails_per_sec)]
	}
	log debug "current pacing msec: $pacing_msec"
	if {$pacing_msec == "Inf"} {
	  breakpoint
	}
	#if {$pacing_msec > $max_pacing_msec} {
	#  set pacing_msec $max_pacing_msec
	#}
	set wait_msec [expr $pacing_msec - ($end_it_msec - $start_it_msec)]
	log debug "time used to copy mail: [expr ($end_it_msec - $start_it_msec)]"
	log debug "current wait msec: $wait_msec"
	return $wait_msec
}

# TODO deze mogelijk zo niet bruikbaar voor copy-files, per mail_type 3 items nodig: subject, freq, msg_type.
proc det_sum_freq {mail_types} {
  set sum 0.0
  foreach {_ freq _} $mail_types {
    set sum [expr $sum + $freq]
  }
  return $sum
}

proc wait_pacing {pacing_sec start_msec} {
  set end_msec [clock clicks -milliseconds]
  set wait_msec [expr 1000*$pacing_sec - ($end_msec - $start_msec)]
  if {$wait_msec > 0} {
    after [expr round($wait_msec)]
  }
}

proc dict_to_str {d} {
  # join [map kv {string trim "[:0 $kv]: [:1 $kv]"} [lsort [dict get $d]]] ", "
  set res {}
  foreach k [lsort [dict keys $d]] {
    lappend res "$k: [dict get $d $k]"
  }
  join $res ", "
}

proc list_to_str {l} {
  set res {}
  foreach {k v} $l {
    lappend res "$k: $v"
  }
  join $res ", "
}

proc log {level str} {
	global logname debug
	if {$debug || ($level != "debug")} {
		set f [open $logname a]
		set logstring "\[[current_time]\] \[$level\] $str"
		puts $f $logstring
		close $f
		puts $logstring
	}
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

proc find_folder_path {ns pad} {
  # set folders [$ns : Folders]
  log debug "namespace: $ns"
  set f $ns
  # breakpoint
  set parts [split $pad "/"]
  foreach part $parts {
	 set folders [$f Folders]
     set f [find_folder $folders $part]
  }
  log info "Found folder path: [$f Name]"
  return $f
}

# zoek folder 1 niveau diep
proc find_folder {folders naam} {
  log debug "find_folder: $naam (folders: $folders)"
  # set i [$folders : count]
  tcom::foreach folder $folders {
    log debug "found folder: [$folder Name]"
  	if {[$folder Name] == $naam} {
	  	return $folder
	  }
  }
  log warn "niet gevonden: $naam"
  return 0
}

proc log {level str} {
	global logname debug
	if {$debug || ($level != "debug")} {
		set f [open $logname a]
		set logstring "\[[current_time]\] \[$level\] $str"
		puts $f $logstring
		close $f
		puts $logstring
	}
}

# Tcl 8.4 - no milliseconds.
proc current_time {} { 
  set sec [clock seconds]
  return "[clock format $sec -format "%Y-%m-%d %H:%M:%S %z"]"
}

proc read_file {filename} {
  set fi [open $filename r]
  set text [read $fi]
  close $fi
  return $text
}
