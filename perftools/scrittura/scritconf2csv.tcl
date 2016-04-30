#Action.c(18): [2016-04-01 12:47:24] [1459507644] iter: {iteration} start of showing confirmations screen [1-4-2016 12:47:24]
#Action.c(36):     true" title="Signing Review" >Review\r\n
#Action.c(36):                                             style="text-align:right">1\r\n

package require ndv

proc main {argv} {
	lassign $argv infile outfile

	set fo [open $outfile w]
	puts $fo [join {ts_cet queue cnt} ","]
	set fi [open $infile r]

	set ts_cet "<none>"
	set queue "<none>"
	while {[gets $fi line] >= 0} {
		if {[regexp {\[([^ ]+ [^ ]+)\].*start of showing confirmations} $line z ts]} {
			set ts_cet $ts
		}
		if {[regexp {title="[^""]+" >(.+)\\r\\n$} $line z q]} {
			set queue $q
		}
		if {[regexp {style="text-align:right">(\d+)\\r\\n$} $line z cnt]} {
			if {$queue != "<none>"} {
				puts $fo [join [list $ts_cet $queue $cnt] ","]
				set queue "<none>"
			}
		}
	}
	close $fi
	close $fo
}

main $argv
