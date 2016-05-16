package require Itcl
package require struct::set

source ../lib/CLogger.tcl
source ../../../lib/tcl/CHtmlHelper.tcl

itcl::class CMaakOvz {
	private common log
	set log [CLogger::new_logger [info script] debug]

	private common SOURCEDEP_DIR "c:/aaa/trace-sourcedep/sourcefiles-publish"
	private common SOURCE_ROOT "C:/vreen00_toolset2/CxR_Toolset/Perf/toolset/cruise/checkout"
	private variable set_all_files
	private variable set_unused_files	
	private variable chh
	
	public method maak_overzicht {} {
		lees_all_files
		lees_unused_files
		
		set chh [CHtmlHelper::new_instance]
		set fo [open "c:/aaa/tcl-overzicht.html" w]
		$chh set_channel $fo
		$chh write_header "Performance toolset file overview"
		# $chh table_start
		# $chh table_header Filename Status Notes
		# puts $fo [join [list filename status notes] "\t"]
		
		handle_files_rec $SOURCE_ROOT
		
		# $chh table_end
		$chh write_footer
		close $fo
	}
	
	private method lees_all_files {} {
		set f [open [file join $SOURCEDEP_DIR allfiles.html] r]
		while {![eof $f]} {
			gets $f line
			# $log debug "read line: $line"
			if {[regexp {<a href=".+/([^/]+)\.file\.html">} $line z filename]} {
				set ar_all_files($filename) $filename
				::struct::set include set_all_files $filename
				# $log debug "Added to all_files: $filename"
			}
		}
		close $f
	}
	
	private method lees_unused_files {} {
		set f [open [file join $SOURCEDEP_DIR index.html] r]
		# eerst de regel met Unused zoeken
		set found 0
		while {(!$found) && (![eof $f])} {
			gets $f line
			if {[regexp {Unused files:} $line]} {
				$log debug "Unused files: found"
				set found 1
			}
		}
		while {![eof $f]} {
			gets $f line
			# $log debug "read line: $line"
			if {[regexp {<a href=".+/([^/]+)\.file\.html">} $line z filename]} {
				# set ar_unused_files($filename) $filename
				::struct::set include set_unused_files $filename
				$log debug "Added to unused_files: $filename"
			}
		}
		close $f
	}

	private method handle_files_rec {dirname} {
		if {![is_ok_dir $dirname]} {
			$log debug "Skipping dir: $dirname"
			return
		}

		$chh heading 2 "$dirname"
		$chh table_start
		$chh table_header Filename Status Notes
		foreach filename [lsort -nocase [glob -nocomplain -type f -directory $dirname *]] {
			handle_file $filename			
		}
		$chh table_end

		foreach subdirname [lsort -nocase [glob -nocomplain -type d -directory $dirname *]] {
			handle_files_rec $subdirname			
		}
	}	

	private method is_ok_dir {dirname} {
		if {[regexp "_archi" $dirname]} {
			return 0
		} elseif {[regexp {\$pfebk} $dirname]} {
			return 0				
		} else {
			return 1
		}
	}

	private method handle_file {filename} {
		set status [det_status $filename]
		set notes [det_notes $filename]
		if {[regexp {(checkout.*)$} $filename z str]} {
			set filename $str
		}
		# puts $fo [join [list $filename $status $notes] "\t"]
		$chh table_row $filename $status $notes
	}

	private method det_status {filename} {
		if {[regexp {(checkout.*)$} $filename z str]} {
			regsub -all "/" $str "-" str
			if {[::struct::set contains $set_all_files $str]} {
				if {[::struct::set contains $set_unused_files $str]} {
					return "Unused"
				} else {
					return "Used"
				}
			} else {
				return "Unknown"
			}
		}
	}
	
	private method det_notes {filename} {
		set lst_notes {}
		set f [open $filename r]
		set comment_chars [det_comment_chars $filename]
		set continue 1
		while {$continue && (![eof $f])} {
			gets $f line
			if {[regexp -nocase "^${comment_chars}(.*)$" $line z note]} {
				if {[is_unix_first_line $line]} {
					# unix first line: which shell.
				} else {
					lappend lst_notes [string trim $note]
				}
			} else {
				set continue 0
			}
		}
		close $f
		return [join $lst_notes "<br/>"]
	}
	
	private method det_comment_chars {filename} {
		set ext [string tolower [file extension $filename]]
		if {$ext == ".bat"} {
			return "rem "
		} elseif {$ext == ".sql"} {
			return "--"
		} else {
			return "#"
		}
	}
	
	private method is_unix_first_line {line} {
		if {[regexp {^\#!} $line]} {
			return 1
		} else {
			return 0
		}
	}
}


proc main {} {
	set cmo [CMaakOvz #auto]
	$cmo maak_overzicht
}

main
