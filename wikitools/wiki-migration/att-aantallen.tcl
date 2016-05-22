proc main {} {
	global counts
  while {![eof stdin]} {
		gets stdin line
		if {[regexp -- {-dir\\1\.([^.]+)$} $line z ext]} {
			set ext [string tolower $ext]
			incr_count $ext
		}
  }
  foreach el [lsort [array names counts]] {
		puts "$el: $counts($el)"
  }
}

proc incr_count {ext} {
	global counts
	set c 0
	catch {set c $counts($ext)}
	set counts($ext) [expr $c + 1]
}

main
