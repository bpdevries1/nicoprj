package require ndv

proc main {argv} {
	lassign $argv indir outfile
	if {[file exists $outfile]} {
		set fo [open $outfile a]
	} else {
		set fo [open $outfile w]
		puts $fo [join {ts_cet timediff_sec msgid status getfilename} ","]
	}
	foreach infile [glob -directory $indir *GET] {
		set getfilename [file tail $infile]
		set text [read_file $infile]
		set tms [get_tag $text Tms]
		set ts_cet [det_ts_cet $tms]
		set msgid [get_tag $text MessageId]
		set status [get_tag $text Status]
		set timediff_sec [det_timediff_sec $tms $msgid]
		puts $fo [join [list $ts_cet $timediff_sec $msgid $status $getfilename] ","]
	}
	close $fo
}

proc get_tag {text tag} {
  if {[regexp "<$tag>(.+)</$tag>" $text z v]} {
	return $v
  } else {
	return "<none>"
  }
}

proc det_ts_cet {tms} {
  set sec [expr round(0.001*$tms)]
  clock format $sec -format "%Y-%m-%d %H:%M:%S"
}

proc det_timediff_sec {tms msgid} {
  set sec_end [expr round(0.001*$tms)]
  if {[regexp {^(\d+_\d+)_\d+} $msgid z ts]} {
	set sec_start [clock scan $ts -format "%Y%m%d_%H%M%S"]
	return [expr $sec_end - $sec_start]
  } else {
	return -1
  }
}

main $argv
