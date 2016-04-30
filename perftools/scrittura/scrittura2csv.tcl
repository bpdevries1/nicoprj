package require ndv

proc main {argv} {
	lassign $argv indir outfile

	set fo [open $outfile w]
	puts $fo [join {logfile ts_str ts_cet msgid baseline line} ","]
	
	foreach infile [glob -directory $indir -type f *] {
		if {[file extension $infile] != ".gz"} {
			handle_file $infile $fo
		}
	}

	close $fo
}

proc handle_file {infile fo} {
	puts "Handle file: $infile"
	set fi [open $infile r]
	set baseline "<none>"
	set ts_str "<none>"
	set ts_cet $ts_str
	set linenr 0
	while {[gets $fi line] >= 0} {
		incr linenr
		if {[expr $linenr % 10000] == 0} {
			puts $linenr
		}
		if {[regexp {^([0-9 :,-]+) } $line z ts]} {
			set ts_str $ts
			set ts_cet [det_ts_cet $ts_str]
			set baseline [sanitise $line]
		} elseif {[regexp {(\d{8}_\d{6}_\d{1,})} $line z msgid]} {
			if {$ts_str != "<none>"} {
				set line [sanitise $line]
				puts $fo [join [list [file tail $infile] "\"$ts_str\"" $ts_cet $msgid "\"$baseline\"" "\"$line\""] ","]
			}
			set baseline "<none>"
			set ts_str "<none>"
			set ts_cet $ts_str
		}
	}
	close $fi
}

proc det_ts_cet {ts_str} {
	if {[regexp {^([^,]+),} $ts_str z ts_cet]} {
		return $ts_cet
	} else {
		return "<none>"
	}
}

proc sanitise {str} {
	regsub -all {[,""']} $str "_" str
	return $str
}

main $argv
