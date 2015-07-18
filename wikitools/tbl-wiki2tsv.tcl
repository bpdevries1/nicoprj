#!/usr/bin/env tclsh861

# wiki naar tsv toch ook handig, vooral als multiline in een cell.
proc main {} {
	set firstline 1
	set cells {}
	while {![eof stdin]} {
		gets stdin line
		# puts "*** $line"
		if {$line == "\|-"} {
			if {$firstline} {
				set firstline 0
			} else {
				puts [join $cells "\t"]
				set cells {}
			}
		} elseif {$line == "\|\}"} {
			puts [join $cells "\t"]
			return
		} elseif {[regexp {^[\|!](.*)$} $line z cell]} {
			lappend cells $cell
		}
	}
}

main
