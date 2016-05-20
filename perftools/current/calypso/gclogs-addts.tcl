proc main {} {
	# set dir {C:\PCC\Nico\Projecten\Calypso\taskforce april 2016\Logs-20160513\1line}
	set dir {H:\Disciplines\Trim\99 PCC\Projecten\Calypso\taskforce april 2016\Logs-20160513\1line}
	foreach filename [glob -directory $dir *.gc] {
		handle_file $filename
	}
}

proc handle_file {filename} {
	# puts "Handling: $filename"
	set outfilename "$filename.ts.gc"
	puts "Handling: $filename -> $outfilename"
	set fi [open $filename r]
	set fo [open $outfilename w]
	set sec_start -1
	while {[gets $fi line] >= 0} {
		if {$sec_start <= 0} {
			set sec_start [det_sec_start $line]
		}
		if {[regexp {^(\d+\.\d{3}): } $line z sec]} {
			set line "[det_ts $sec_start $sec]$line"
		}
		puts $fo $line
	}
	close $fi
	close $fo
}

# 2016-05-07 08:57:25 [745
proc det_sec_start {line} {
	if {[regexp {^([0-9-]{10} [0-9:]{8})} $line z str]} {
		clock scan $str -format "%Y-%m-%d %H:%M:%S"
	} else {
		return -1
	}
}

proc det_ts {sec_start sec} {
#	return "\[[clock format [expr $sec_start + round($sec)] -format "%Y-%m-%d %H:%M:%S"]\]"
	return "[clock format [expr $sec_start + round($sec)] -format "%Y-%m-%dT%H:%M:%S.000%z"]: "
}

main