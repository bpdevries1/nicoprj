# sort-usage.tcl - sorteer dirsizes

set sizes {}
while {![eof stdin]} {
	gets stdin line
	if {[regexp "(.*)\t(.*)" $line z size dir	]} {
		lappend sizes	[list $size $dir]
	}
}

set sizes [lsort -decreasing -integer -index 0 $sizes]
foreach el $sizes {
	puts "[lindex $el 0]\t[lindex $el 1]"	
}


