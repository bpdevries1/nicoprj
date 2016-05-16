package require Itcl

source [file join $env(CRUISE_DIR) checkout lib perflib.tcl]
source [file join $env(CRUISE_DIR) checkout script lib CLogger.tcl]

itcl::class CJoinItm {
	private common log
	set log [CLogger::new_logger overzicht perf]
	# set log [CLogger::new_logger graph_Itm debug]
	private variable fo
	private variable fo_empty

	
	public method join_data {dir_name filetype} {
		create_output_file $dir_name $filetype
		foreach subdir_name [lsort [glob -directory $dir_name -type d "T*"]] {
			add_data $subdir_name $filetype
		}
		close_output_file		
	}
	
	private method create_output_file {dir_name filetype} {
		set base_name [file join $dir_name $filetype]
		set fo [open "$base_name.all.tsv" w]
		set fo_empty 1
	}
	
	private method close_output_file {} {
		close $fo
	}
	
	private method add_data {dir_name filetype} {
		$log info "Handling dir: $dir_name ..."
		set input_name [file join $dir_name "$filetype.tsv"]
		if {![file exists $input_name]} {
			$log warn "Warning: no input file $input_name"
			return
		}
		set fi [open $input_name r]
		read_header $fi $fo
		while {![eof $fi]} {
			gets $fi line
			if {$line != ""} {
				if {[is_valued_line $line $filetype]} {
					puts $fo $line
				}
			}
		}
		close $fi
	}
	
	# vooral ASND erg groot, dus alleen lijnen opnemen waar ook echt waarden in zitten, dat er iets gebeurd is.
	private method is_valued_line {line filetype} {
		if {$filetype == "KQITASND"} {
			# check of asnd.totc ongelijk aan 0 is. 
			if {[lindex [split $line "\t"] 17] != 0} {
				return 1
			} else {
				return 0
			}
		} else {
			return 1
		}
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
	set filetype [lindex $argv 1]
	set o [CJoinItm #auto]
	$o join_data $dir_name $filetype
}

main $argc $argv
