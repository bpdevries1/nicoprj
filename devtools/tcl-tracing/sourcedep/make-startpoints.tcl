proc main {} {
	set TRACES_DIR "C:\\aaa\\traces"
	set SOURCEFILES_DIR "C:\\aaa\\trace-sourcedep\\sourcefiles" 
	
	set lst_sourcefiles [lees_sourcefiles $SOURCEFILES_DIR]
	# puts $lst_sourcefiles
	
	foreach tracefile [glob -tails -directory $TRACES_DIR *.trace] {
		if {[regexp {^(.*.tcl)} $tracefile z trace_filename]} {
			# trace_filename:process.killnew.tcl 
			foreach sourcefile $lst_sourcefiles {
				# puts "Compare $trace_filename with $sourcefile"
				if {[regexp $trace_filename $sourcefile]} {
					puts "				<include name=\"$sourcefile\"/>"
				}				
			}
		}
	}
}

proc lees_sourcefiles {sourcefiles_dir} {
	set lst_result [glob -tails -directory $sourcefiles_dir *.file]
	return $lst_result
}

main
