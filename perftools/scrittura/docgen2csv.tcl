package require ndv

# 11:13:05,854 INFO  com.interwoven.docgen.engine.DOCXGeneration.generateDocument(175) - Undertaking document generation using template /Utrecht/FX_TEMPLATES/MASTER_TEMPLATES/MT_TRADE_ISDA_FX.docx
# geen datum dus.

proc main {argv} {
	lassign $argv infile outfile
	
	set fi [open $infile r]
	set date [clock format [file mtime $infile] -format "%Y-%m-%d"]
	
	set fo [open $outfile w]
	puts $fo [join {ts_str ts_cet doctemplate} ","]

	while {[gets $fi line] >= 0} {
		if {[regexp {^([^ ]+) .*Undertaking document generation using template (.+)$} $line z ts_str doctemplate]} {
			set ts_cet [det_ts_cet $ts_str $date]
			puts $fo [join [list "\"$ts_str\"" $ts_cet $doctemplate] ","]
		}
	}
	close $fo
	close $fi
}

proc det_ts_cet {ts_str date} {
	if {[regexp {^([^,]+),} $ts_str z ts_cet]} {
		return "$date $ts_cet"
	} else {
		return "<none>"
	}
}

main $argv
