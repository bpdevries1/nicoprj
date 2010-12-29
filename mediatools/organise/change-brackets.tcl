#!/home/nico/bin/tclsh

package require Itcl

source [file join [file dirname [info script]] .. .. lib CLogger.tcl]
source [file join [file dirname [info script]] .. lib libmusic.tcl]

itcl::class CChangeBrackets {

	private common log
	set log [CLogger::new_logger [file tail [info script]] debug]
	
	private common ALBUMS_ROOT "/media/nas/media/Music/Albums"
	
	public constructor {} {
		
	}
	
	private variable root_dir
	
	public method change_brackets {a_root_dir} {
		set root_dir $a_root_dir
		$log info "root-dir: $root_dir"
		handle_dir_rec $a_root_dir
		$log info "Finished"
	}

	private method handle_dir_rec {dirname} {
		# eerst deze dir zelf!
		set new_name [det_new_name $dirname]
		if {$new_name != $dirname} {
			$log info "Renaming: $dirname => $new_name"
			file rename $dirname $new_name
			set dirname $new_name
		}

		# eerst zowel dirs als files checken op brackets: []
		foreach sub_el [glob -nocomplain -directory $dirname *] {
			set new_name [det_new_name $sub_el]
			if {$new_name != $sub_el} {
				$log info "Renaming: $sub_el => $new_name"
				file rename $sub_el $new_name
			}

		}

		# dan naar evt subdirs
		foreach subdir [glob -nocomplain -type d -directory $dirname *] {
			handle_dir_rec $subdir
		}

	}
	
	private method det_new_name {str} {
		set result $str
		regsub -all {\[} $str "(" str
		regsub -all {\]} $str ")" str
		regsub -all {\&} $str " and " str
		regsub -all {  } $str " " str
		return $str
	}
	
}

proc main {argc argv} {
	global root_dir f_rename
	check_args $argc $argv
	# set root_dir [file normalize .]
	set root_dir [file normalize [lindex $argv 0]]
	set ccb [CChangeBrackets #auto]
	$ccb change_brackets $root_dir
}

proc check_args {argc argv} {
	global argv0 stderr
	if {$argc != 1} {
		puts stderr "Syntax: $argv0 <root-dir>; got: $argv"
		exit 1
	}
}




main $argc $argv
