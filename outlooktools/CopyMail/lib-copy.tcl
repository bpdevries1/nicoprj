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

