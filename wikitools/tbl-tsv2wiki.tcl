#!/usr/bin/env tclsh861

package require Tclx

proc main {} {
	puts "\{| border=\"1\" cellspacing=\"0\""
	set state BEGIN
	set n_cols 0
	while {![eof stdin]} {
		gets stdin line
		# set line [string trim $line] ; # kan zijn dat lijn met tabs begint of eindigt, wil je houden.
		if {$line != ""} {
			set l [split $line "\t"]
			puts "|-"
			set n_row_cols 0
			foreach el $l {
				if {[regexp "^-" $el]} {
					set el " $el"
				}
				if {$state == "BEGIN"} {
					puts "!$el"
					incr n_cols
					incr n_row_cols
				} else {
					puts "|$el"
					incr n_row_cols
				}
			}
			set state "IN_TABEL"
			for {set i $n_row_cols} {$i < $n_cols} {incr i} {
				puts "| -"
			}
		}
	}
	puts "|\}"
}

cmdtrace on [open cmd.log w]
main
