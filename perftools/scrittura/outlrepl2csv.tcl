package require ndv

proc main {argv} {
	lassign $argv infile outfile
	
	set fi [open $infile r]
	if {[file exists $outfile]} {
		set fo [open $outfile a]
	} else {
		set fo [open $outfile w]
		puts $fo [join {ts_cet subject msgid changed_att} ","]
	}

	set changed_att 0
	
	while {[gets $fi line] >= 0} {
		if {[regexp {Changing attachment} $line]} {
			set changed_att 1
		}
		if {[regexp {^\[([^ ]+ [^ ]+) \+..00\] .perf. Replied to mail: subject=(.+)$} $line z ts_cet subject]} {
			if {[regexp {Rabobank Ref. ([0-9_]{17,})} $subject z m]} {
			  set msgid $m
			} else {
			  set msgid "<none>"
			}
			puts $fo [join [list $ts_cet "\"$subject\"" $msgid $changed_att] ","]
			set changed_att 0
		}
	}
	close $fo
	close $fi
}

main $argv
