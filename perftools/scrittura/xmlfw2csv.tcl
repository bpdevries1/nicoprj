package require ndv

proc main {argv} {
	lassign $argv infile outfile
	
	set fi [open $infile r]
	set fo [open $outfile w]
	puts $fo [join {ts_cet uuid xmlfile} ","]

# [2016-03-24 16:36:10 +0100] [perf] Moved file: /appl/scritturadropbox/tmp/lj4c4wte.xml, subject: , ts_subject: , sec_subject: 0, ts_xmlfile: 2016-03-24 16:36:10 +0100, sec_xmlfile: 1458833770, sec_diff: 0, uuid: d02408b68d5865cde3b9419afc89adcb
	
	while {[gets $fi line] >= 0} {
		if {[regexp {^\[([^ ]+ [^ ]+) \+..00\] .perf. Moved file: ([^,]+), .+, uuid: ([^ ]+)$} $line z ts_cet xmlfile uuid]} {
			puts $fo [join [list $ts_cet $uuid $xmlfile] ","]
		} elseif {[regexp {Moved file} $line]} {
			breakpoint
		}
	
	}
	close $fo
	close $fi
}

main $argv