package require ndv

proc main {argv} {
	lassign $argv infile outfile
	
	set fi [open $infile r]
	set fo [open $outfile w]
	puts $fo [join {ts_str ts_cet msgid uuid subject} ","]
	set msgid "<none>"
# 03/23/16 15:41:05	f3d1299e67557badd9b2274046e89af1	Found 'Subject' FX FORWARD Confirmation (Rabobank Ref. 20160323_153428_454 / 20160323_153428_454)
	
	while {[gets $fi line] >= 0} {
		if {[regexp {^([^ \t]+ [^ \t]+)\t([^ ]+)\t+Found 'Subject' (.+)$} $line z ts_str uuid subject]} {
			set ts_sec [clock scan $ts_str -format "%m/%d/%y %H:%M:%S"]
			set ts_cet [clock format $ts_sec -format "%Y-%m-%d %H:%M:%S"]
			if {[regexp {Rabobank Ref. ([0-9_]{17,})} $subject z m]} {
			  set msgid $m
			} else {
			  set msgid "<none>"
			}
			puts $fo [join [list $ts_str $ts_cet $msgid $uuid $subject] ","]
		} elseif {[regexp {FX FORWARD} $line]} {
			breakpoint
		}
	}
	close $fo
	close $fi
}

main $argv
