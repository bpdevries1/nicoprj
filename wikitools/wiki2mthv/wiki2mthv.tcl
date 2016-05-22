package require Itcl

# class maar eenmalig definieren
if {[llength [itcl::find classes CWikiToMthv]] > 0} {
	return
}

source [file join $env(CRUISE_DIR) checkout lib perflib.tcl]
source [file join $env(CRUISE_DIR) checkout script tool wiki2mthv CMthvFile.tcl]
source [file join $env(CRUISE_DIR) checkout script tool wiki2mthv CMthvMenu.tcl]

addLogger wiki2mthv
setLogLevel wiki2mthv info
# setLogLevel wiki2mthv debug

itcl::class CWikiToMthv {

	private variable src_dir
	private variable target_dir
	private variable mthv_file
	private variable in_table
	private variable in_lijst
	private variable mthv_menu
	
	public constructor {a_src_dir a_target_dir} {
		set src_dir $a_src_dir
		set target_dir $a_target_dir
		set mthv_file ""
		set mthv_menu ""
		set in_table 0
		set in_lijst 0
	}

	public method migrate {} {
		log "start" debug wiki2mthv
		set mthv_menu [CMthvMenu #auto $target_dir]
		foreach filename [glob -directory $src_dir *.txt] {
			if {[must_migrate $filename]} {
				migrate_file $filename
			}
		}
		$mthv_menu finish
		log "finished" debug wiki2mthv
	}

	private method must_migrate {filename} {
		if {[regexp -nocase {perf} $filename]} {
			return 1
		} else {
			return 0
		}
	}

	# @param filename: inclusief hele pad.
	private method migrate_file {filename} {
		log "start" debug wiki2mthv
		set basename [file rootname [file tail $filename]]

		$mthv_menu link $basename $basename

		set mthv_file [CMthvFile #auto $target_dir $basename]
		set f [open $filename r]
		while {![eof $f]} {
			gets $f line
			set line_type [det_line_type $line]

			# eerst oude tabel of lijst afsluiten, indien nodig.
			if {$line_type != "tabel"} {
				check_table_end
			}
			if {$line_type != "lijst"} {
				check_lijst_end
			}

			# dan deze regel behandelen.
			if {$line_type == "tabel"} {
				handle_tabel_row $line
			} elseif {$line_type == "lijst"} {
				handle_list_item $line
			} else {
				if {[regexp {^\!(.+)$} $line z titel]} {
					handle_titel $titel
				} else {
					handle_tekst $line
				}
			}
		}
		$mthv_file finish
		log "finished" debug wiki2mthv
	}

	private method det_line_type {line} {
		if {[regexp {^\|} $line]} {
			return "tabel"
		} elseif {[regexp {^\* } $line]} {
			return "lijst"
		} elseif {[regexp {^\# } $line]} {
			return "lijst"
		} else {
			return "tekst"
		}
	}

	private method handle_titel {titel} {
		set link $titel
		set is_link [is_link $titel link]
		$mthv_file beschrijving_start $link
		# $mthv_file beschrijving_start $titel
		if {$is_link} {
			$mthv_file verwijzing $link
		}
	}

	# @param list_item: [JMeter] of gewoon regel tekst.
	private method handle_list_item {line} {
		if {[regexp {^\* (.*)$} $line z list_item]} {
			$mthv_file lijst_item $list_item
			set in_lijst 1
		} elseif {[regexp {^\# (.*)$} $line z list_item]} {
			$mthv_file lijst_item $list_item
			set in_lijst 1
		} else {
			fail "Stiekem toch geen list-item: $line"
		}
	}

	private method handle_tabel_row {line} {
		if {!$in_table} {
			$mthv_file table_start
			set in_table 1
		}
		if {[regexp {^\|\|} $line]} {
			set is_header 1
		} else {
			set is_header 0
		}
		set l [split $line "|"]
		$mthv_file tag_start tr
		foreach el $l {
			if {$el != ""} {
				if {$is_header} {
					$mthv_file tag_start tekst
					$mthv_file tag_tekst extrasterk $el
					$mthv_file tag_end tekst
				} else {
					$mthv_file tag_tekst tekst $el
				}
			}
		}
		$mthv_file tag_end tr		
		# $mthv_file handle_tabel_row $line
	}

	private method check_table_end {} {
		if {$in_table} {
			$mthv_file table_end
			set in_table 0
		}
	}

	private method check_lijst_end {} {
		if {$in_lijst} {
			$mthv_file tag_end lijst_genummerd
			set in_lijst 0
		}
	}

	private method handle_tekst {line} {
		set line [string trim $line]
		if {$line != ""} {
			$mthv_file alinea $line
		}
	}

	private method is_link {tekst link_name} {
		upvar $link_name link
		set link $tekst
		if {[regexp {^\[(.+)\]$} $tekst z link]} {
			set is_link 1
		} else {
			set is_link 0
		}
		return $is_link		
	}

}

proc main {argc argv} {
  check_params $argc $argv
  set src_dir [lindex $argv 0]
  set target_dir [lindex $argv 1]
	# set testrun_id [lindex $argv 2] ; # bv 'testrun001'
  set wiki_to_mthv [CWikiToMthv #auto $src_dir $target_dir]
  $wiki_to_mthv migrate
}

proc check_params {argc argv} {
  global env argv0
  if {$argc != 2} {
    fail "syntax: $argv0 <src_dir> <target_dir>; got $argv \[#$argc\]"
  }
}

# aanroepen vanuit Ant, maar ook mogelijk om vanuit Tcl te doen.
if {[file tail $argv0] == [file tail [info script]]} {
  main $argc $argv
}

