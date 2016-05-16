package require ndv

# PDFServer.log

#2016-03-22 16:37:26,702  INFO [1737079097@qtp-1289931605-5] com.autonomy.gcm.pdf.engine.PDFGeneration - Generating pdf using source file E:\PDFServer\input\pdf_gen_source_4167658400705834227.docx
#2016-03-22 16:37:26,702  INFO [1737079097@qtp-1289931605-5] com.autonomy.gcm.pdf.engine.PDFServerAction - Running command: cscript.exe //B //NoLogo "E:/PDFServer/VBScripts/print.vbs" "E:\PDFServer\input\pdf_gen_source_4167658400705834227.docx" "E:\PDFServer\output\pdf_gen_target_4167658400705834227.pdf" "" 1 0 "Built-In Building Blocks.dotx" ""
#2016-03-22 16:37:27,890  INFO [539124954@qtp-1289931605-3] com.autonomy.gcm.pdf.service.impl.advice.PerformanceAdvice - PDF generation request completed successfully in 2,219ms; Average time: 2,296ms (count: 35)
#016-03-22 16:37:28,530  INFO [320803739@qtp-1289931605-4] com.autonomy.gcm.pdf.service.impl.advice.PerformanceAdvice - PDF generation request completed successfully in 2,187ms; Average time: 2,293ms (count: 36)
#2016-03-22 16:37:28,733  INFO [539124954@qtp-1289931605-3] com.autonomy.gcm.pdf.service.impl.advice.PerformanceAdvice - Received PDF generation request from client
#2016-03-22 16:37:28,733  INFO [539124954@qtp-1289931605-3] com.autonomy.gcm.pdf.engine.PDFGeneration - Generating pdf using source file E:\PDFServer\input\pdf_gen_source_6387392928042542775.docx

# 2 losse tabellen maken:pdfgensrc, pdfgenok
# 2,187ms; Average time: 2,293ms (count: 36)

proc main {argv} {
	lassign $argv infile outfile1 outfile2
	
	set fi [open $infile r]

	set fo1 [open $outfile1 w]
	puts $fo1 [join {ts_str ts_cet srcfile} ","]
	set fo2 [open $outfile2 w]
	puts $fo2 [join {ts_str ts_cet Rsec Ravgsec cnt} ","]

	while {[gets $fi line] >= 0} {
		if {[regexp {^([^ ]+ [^ ]+).*Generating pdf using source file (.+)$} $line z ts_str srcfile]} {
			set ts_cet [det_ts_cet $ts_str]
			puts $fo1 [join [list "\"$ts_str\"" $ts_cet $srcfile] ","]
		} elseif {[regexp {^([^ ]+ [^ ]+).*successfully in ([0-9,]+)ms; Average time: ([0-9,]+)ms \(count: (\d+)\)} $line z ts_str Rsec Ravgsec cnt]} {
			set ts_cet [det_ts_cet $ts_str]
			puts $fo2 [join [list "\"$ts_str\"" $ts_cet [comma2dot $Rsec] [comma2dot $Ravgsec] $cnt] ","]
		}
	}
	close $fo1
	close $fo2
	close $fi
}

proc det_ts_cet {ts_str} {
	if {[regexp {^([^,]+),} $ts_str z ts_cet]} {
		return $ts_cet
	} else {
		return "<none>"
	}
}

proc comma2dot {str} {
	regsub -all "," $str "." str
	return $str
}

main $argv
