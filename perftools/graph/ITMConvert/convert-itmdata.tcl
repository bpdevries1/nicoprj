package require Itcl

source [file join $env(PERF_DIR) lib tcl perflib.tcl] 

source CItmConvertor.tcl

proc main {argc argv} {
	set dir_name [lindex $argv 0]
	handle_dir $dir_name
}

proc handle_dir {dir_name} {
	# puts "dir_name: $dir_name"
	# puts "glob all: [glob -directory $dir_name *]"
	foreach filename [glob -directory $dir_name "*.D"] {
		handle_datafile $filename
	}
}

proc handle_datafile {filename} {
	set convertor [CItmConvertor::new_instance]
	$convertor convert_file $filename
	
}

main $argc $argv