package require Itcl

source [file join $env(CRUISE_DIR) checkout lib perflib.tcl]
source [file join $env(CRUISE_DIR) checkout script lib CLogger.tcl]

itcl::class CJoinAsmf {
	private common log
	set log [CLogger::new_logger overzicht perf]
	# set log [CLogger::new_logger graph_asmf debug]
	private variable fo
	private variable fo_empty

	
	public method join_data {dir_name} {
		create_output_file $dir_name
		foreach subdir_name [lsort [glob -directory $dir_name -type d "T*"]] {
			add_data $subdir_name
		}
		close_output_file		
	}
	
	private method create_output_file {dir_name} {
		set base_name [file join $dir_name "KQITASMF"]
		set fo [open "$base_name.all.tsv" w]
		set fo_empty 1
	}
	
	private method close_output_file {} {
		close $fo
	}
	
	private method add_data {dir_name} {
		$log info "Handling dir: $dir_name ..."
		set input_name [file join $dir_name "KQITASMF.tsv"]
		if {![file exists $input_name]} {
			$log warn "Warning: no input file $input_name"
			return
		}
		set fi [open $input_name r]
		read_header $fi $fo
		while {![eof $fi]} {
			gets $fi line
			if {$line != ""} {
				puts $fo $line
			}
		}
		close $fi
	}
	
	private method read_header {fi fo} {
		gets $fi line
		if {$fo_empty} {
			puts $fo $line
			set fo_empty 0
		}
	}
	
}

proc main {argc argv} {
	set dir_name [lindex $argv 0]
	set o [CJoinAsmf #auto]
	$o join_data $dir_name
}

main $argc $argv
