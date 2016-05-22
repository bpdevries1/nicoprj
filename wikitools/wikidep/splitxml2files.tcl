proc main {argc argv} {
	set dir_name [lindex $argv 0]
	set export_filename [lindex $argv 1]
	
	set in_page 0
	# set fin [open "perf-export.xml" r]
	set fin [open [file join $dir_name $export_filename] r]
	while {![eof $fin]} {
		gets $fin line
		if {$in_page} {
			if {[regexp {</page>} $line]} {
				puts $fout $line
				close $fout
				set in_page 0
			} else {
				puts $fout $line
			}
		} else {
			if {[regexp {<page>} $line]} {
				gets $fin line2
				if {[regexp {<title>(.+)</title>} $line2 z title]} {
					# set fout [open "${title}.wiki" w]
					set fout [open [file join $dir_name "pages" "${title}.wiki"] w]
					set in_page 1
					puts $fout $line
					puts $fout $line2
				} else {
					puts stderr "Expected title-line after page-line: $line *** $line2"
					exit 1
				}
			} else {
				# doe niets
			}
		}
		
	}
	close $fin
}

main $argc $argv
