proc main {} {
	while {![eof stdin]} {
		gets stdin line
		if {[regexp {<DT><H3.*>(.+)</H3>$} $line z heading]} {
			puts "\n== $heading =="
		} elseif {[regexp {<A HREF="([^"]+)".*>(.+)</A>$} $line z url tekst]} {
			puts "* \[$url $tekst\]"
		}
	}
}

main
