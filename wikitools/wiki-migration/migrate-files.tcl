proc main {} {
	global target_dir
	set src_dir "Z:\\Data\\Wiki\\web\\www-data\\jspwiki"
	set target_dir "c:\\aaa\\wiki-upload"
	
	handle_dir $src_dir

}

proc handle_dir {src_dir} {
	foreach filename [glob -nocomplain -directory $src_dir *] {
		if {[file isdirectory $filename]} {
			handle_dir $filename
		} elseif {[file isfile $filename]} {
			handle_file $filename
		}
	}
}

proc handle_file {pathname} {
	global target_dir
	# puts "file: $filename"
	if {[regexp {jspwiki/([^/]+)-att/([^/]+)-dir/} $pathname z pagename filename]} {
		if {![regexp {attachment.properties} $pathname]} {
			set tofile [file join $target_dir "Portals-$pagename-$filename"]
			puts "$pathname => $tofile"
			file copy -force $pathname $tofile
		}
	}
}

main
