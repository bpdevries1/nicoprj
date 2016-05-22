# switch.tcl - switch parts before and after tab
while {![eof stdin]} {
  gets stdin line
  if {[regexp {(.*)\t(.*)} $line z word trans]} {
		puts "$trans\t$word"
  } else {
		puts $line
  }
}
