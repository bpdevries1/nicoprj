package require Itcl

# class maar eenmalig definieren
if {[llength [itcl::find classes CJspWikiReader]] > 0} {
	return
}

source [file join $env(CRUISE_DIR) checkout lib perflib.tcl]
source [file join $env(CRUISE_DIR) checkout script lib CLogger.tcl]

itcl::class CJspWikiReader {

	private common log
	set log [CLogger::new_logger jspwikireader debug]

	private variable writer

	# state tijdens lezen files
	private variable in_table
	private variable in_lijst

	public constructor {} {
		set writer ""	
		set in_table 0
		set in_lijst 0
	}

	public method set_writer {a_writer} {
		set writer $a_writer
	}

	public method migrate_directory {src_dir} {
		$log debug start
		$writer all_start
		
		foreach filename [glob -directory $src_dir *.txt] {
			if {[must_migrate $filename]} {
				migrate_file $filename
			}
		}

		$writer all_end
		
		$log debug finished
	
	}

	private method must_migrate {filename} {
		return 1
		if {0} {
			if {[regexp -nocase {PerformanceModelleren\.} $filename]} {
				return 1
			} else {
				return 0
			}
		}
		if {[regexp -nocase {AanmakenJSFSourcePortletComplex\.} $filename]} {
			return 1
		} else {
			return 0
		}
	}

	# @param filename: inclusief hele pad.
	private method migrate_file {filename} {
		$log debug "start"
		set basename [file rootname [file tail $filename]]

		$writer page_start $basename
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
					handle_header $line
				} else {
					handle_tekst $line
				}
			}
		}
		$writer page_end
		$log debug "finished" 
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

	private method handle_header {titel} {
		set link $titel
		set is_link [is_link $titel link]

		if {[regexp {^(\!+)(.*)$} $titel z n tekst]} {
			set level [expr 4 - [string length $n]]
			$writer header $level $tekst	
		}
		
		if {0} {
			$writer beschrijving_start $link
			$writer beschrijving_start $titel
			if {$is_link} {
				$writer verwijzing $link
			}
		}
	}

	# @param list_item: [JMeter] of gewoon regel tekst.
	private method handle_list_item {line} {
		if {[regexp {^\* (.*)$} $line z list_item]} {
			$writer lijst_item $line
			set in_lijst 1
		} elseif {[regexp {^\# (.*)$} $line z list_item]} {
			$writer lijst_item $line
			set in_lijst 1
		} else {
			fail "Stiekem toch geen list-item: $line"
		}
	}

	private method handle_tabel_row {line} {
		$log debug start
		if {!$in_table} {
			$writer table_start
			set in_table 1
		}
		if {[regexp {^\|\|} $line]} {
			set is_header 1
		} else {
			set is_header 0
		}
		$log debug "is_header: $is_header (line=$line)"
		set l [split $line "|"]
		set l [lrange $l 1 end] ; # line begint met |, dus eerste element is leeg.
		$writer table_row_start

		if {$is_header} {
			foreach el $l {
				if {$el != ""} {
					$writer table_header_cell $el
				}
			}
		} else {
			set l [join_links $l]
			foreach el $l {
				$writer table_cell $el
			}
		}

		$writer table_row_end
		$log debug finished
	}

	# kan zijn dat cellen zijn gesplitst terwijl het scheidingsteken | bedoeld is in een ref, dan weer samenvoegen.
	private method join_links {lst} {
		set result {}
		set prev_el ""
		foreach el $lst {
			if {$prev_el != ""} {
				set cell "$prev_el|$el"
			} else {
				set cell $el
			}
			# zoek de laatste [ en ]; als [ na ] ligt, is de cell nog niet afgesloten.
			# als karakters niet gevonden, dan -1, gaat goed met de vergelijking.
			set last_left [string last {[} $cell]
			set last_right [string last {]} $cell]
			if {$last_right >= $last_left} {
				# deze cell is klaar
				lappend result $cell
				set prev_el ""
			} else {
				set prev_el $cell
			}
		}
		return $result
	}

	private method check_table_end {} {
		if {$in_table} {
			$writer table_end
			set in_table 0
		}
	}

	private method check_lijst_end {} {
		if {$in_lijst} {
			# $writer tag_end lijst_genummerd
			$writer lijst_end
			set in_lijst 0
		}
	}

	private method handle_tekst {line} {
		set line [string trim $line]
		# ook lege regels doorgeven aan writer.
		$writer alinea $line
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
