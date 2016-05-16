package require ndv

proc main {argv} {
	lassign $argv infile outfile
	
	set fi [open $infile r]
	if {[file exists $outfile]} {
		set fo [open $outfile a]
	} else {
		set fo [open $outfile w	]
		puts $fo [join {ts_str ts_cet subject msgid} ","]
	}

# 24/03/2016 16:14:10 [10] 10-Full: FXCONFIRMATIONS: Processing Item FX SPOT Confirmation (Rabobank Ref. 20160324_161111_1077 / 20160324_161111_1077) of type Microsoft.Exchange.WebServices.Data.EmailMessage 
	
	while {[gets $fi line] >= 0} {
		if {[regexp {^([^ ]+ [^ ]+).+Processing Item (.*)$} $line z ts_str subject]} {
			set ts_sec [clock scan $ts_str -format "%d/%m/%Y %H:%M:%S"]
			set ts_cet [clock format $ts_sec -format "%Y-%m-%d %H:%M:%S"]
			if {[regexp {Rabobank Ref. ([0-9_]{17,})} $subject z m]} {
			  set msgid $m
			} else {
			  set msgid "<none>"
			}
			puts $fo [join [list $ts_str $ts_cet $subject $msgid] ","]
		}
	}
	close $fo
	close $fi
}

main $argv
