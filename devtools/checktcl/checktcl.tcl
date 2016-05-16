# checktcl.tcl - tool om sources te checken op conformantie aan ontwerpbeslissingen.

package require Itcl
package require fileutil
package require cmdline

source [file join $env(CRUISE_DIR) checkout lib perflib.tcl]

addLogger checktcl
setLogLevel checktcl info

itcl::class CCheckTcl {

	private variable fco
	private variable ar_opts

	public method check_tcl {root_dir list_opts} {
		global env
		array set ar_opts $list_opts
		
		log "Starting" debug checktcl
		# set fco [open "co-files.bat" w]
		set fco [open [file join $env(TMP) "co-files.bat"] w]
		set filename_list [::fileutil::find $root_dir]
		foreach filename $filename_list {
			if {!$ar_opts(checktcl)} {
				if {[file tail $filename] == "checktcl.tcl"} {
					continue
				}
			}
			
			set messages {}
			if {[is_file_to_check $filename]} {
				set filetype [det_filetype $filename]
				if {$filetype == "tcl"} {
					set messages [check_file_tcl $filename]
				} elseif {$filetype == "xml"} {
					if {!$ar_opts(noxml)} {
						set messages [check_file_xml $filename]
					}
				}
			}
			if {[llength $messages] > 0} {
				puts_co_line $filename $messages
			}
		}
		close $fco
		log "Finished" debug checktcl
	}

	private method det_filetype {filename} {
		set ext "<unknown>"
		regexp {\.([^.]+)$} $filename z ext
		return $ext
	}

	private method check_file_tcl {filename} {
		log "checking $filename" debug checktcl
		set found_classdef 0
		set found_check_class 0
		set messages {}
		::fileutil::foreachLine line $filename {
			set line [string trim $line]
			if {[regexp {^#} $line]} {
				continue
			}
			if {[regexp {^source (.*)$} $line z rest]} {
				if {[regexp {CRUISE_DIR} $rest]} {
					# ok
				} elseif {[regexp {\.\.} $rest]} {
					lappend messages [list warn "Wrong way to source, use CRUISE_DIR, don't use ../" $line]
				} elseif {[regexp {\$} $rest]} {
					# ok, var used.
				} else {
					lappend messages [list warn "Wrong way to source, use CRUISE_DIR or " $line]
				}
			}
			lconcat messages [check_todo $line]
			lconcat messages [check_regexp $line {^setLogLevel .* ((debug)|(error))} warn "debug/error loglevel set, use info"]
			lconcat messages [check_regexp $line {^set_log_level .* ((debug)|(error))} warn "debug/error loglevel set, use info"]
			lconcat messages [check_regexp $line {reslogsdir} warn "Don't use reslogsdir, but reslogs_dir"]
			lconcat messages [check_regexp $line {log.*\y((start)|(finished))\y.*info} warn "Don't use log info with start and finished, use debug."]
			lconcat messages [check_regexp $line {\ygetPropertyFromFile\y} warn "Don't use this, use CAnalysePropFile."]
			lconcat messages [check_regexp $line {_old\y} warn "Remove old method def."]

			# tijdelijk checken op gebruiken analyse.prop
			# lconcat messages [check_regexp $line {analyse\.prop} warn "Check gebruik analyse.prop"]
			
			if {!([file tail $filename] == "CTimestamp.tcl")} {
				lconcat messages [check_regexp $line {CTimestamp #auto} warn "Don't use timestamp contructor, use \[CTimestamp::new_timestamp\]"]
			}
			
			check_set_regexp $line {itcl::class} found_classdef
			check_set_regexp $line {itcl::find classes} found_check_class
		}
		if {$found_classdef} {
			if {!$found_check_class} {
				lappend messages [list warn "Class def'ed, but no check" "<file>"]
			}
		}
		puts_messages $filename $messages
		return $messages
	}

	private method check_file_xml {filename} {
		log "checking $filename" debug checktcl
		set messages {}
		::fileutil::foreachLine line $filename {
			if {[regexp -nocase {basedir} $line]} {
				lappend messages [list warn "Don't use basedir" $line]
			}
			lconcat messages [check_todo $line]
		}
		puts_messages $filename $messages
		return $messages
	}

	private method check_todo {line} {
		set messages {}
		if {!$ar_opts(notodo)} {
			return [check_regexp $line todo todo "Todo item"]
		}
		return $messages
	}

	private method check_regexp {line re loglevel msg} {
		set messages {}
		if {[regexp -nocase $re $line]} {
			lappend messages [list $loglevel $msg $line]
		}
		return $messages
	}

	private method check_set_regexp {line re var_name} {
		upvar $var_name var
		if {[regexp -nocase $re $line]} {
			set var 1
		}		
	}


	private method puts_messages {filename messages} {
		if {[llength $messages] > 0} {
			puts "-------\nMessages (#[llength $messages]) for file: $filename:"
			foreach message $messages {
				# puts "log: $message"
				foreach {loglevel msg line} $message {
					# log toch teveel op 1 regel
					# log "$msg: $line" $loglevel checktcl
					puts "\[$loglevel\] $msg: [string trim $line]"
				}
			}
		}
	}

	private method is_file_to_check {filename} {
		set result 0
		if {[regexp {\.tcl$} $filename]} {
			set result 1
		}
		if {[regexp {\.xml$} $filename]} {
			set result 1
		}
		if {[regexp {_archive} $filename]} {
			set result 0
		}
		if {[regexp {_archief} $filename]} {
			set result 0
		}
		if {[regexp {\$pfebk} $filename]} {
			set result 0
		}
		return $result
	}

	private method puts_co_line {filename messages} {
		set message1 [lindex $messages 0]
		set str [lindex $message1 1]
		puts $fco "co -c \"resolve checktcl message: $str\" [to_dos_path $filename]"
	}

	private method to_dos_path {filename} {
		regsub -all {/} $filename "\\" filename
		return $filename
	}

	private method lconcat {list_name other_list} {
		upvar $list_name this_list
		foreach el $other_list {
			lappend this_list $el
		}
	}

}

proc main {argc argv} {
	
	get_params $argc $argv list_params list_opts
	# check_params $argc $argv $argv_orig

	set root_dir [lindex $list_params 0]
	set ct [CCheckTcl #auto]
	$ct check_tcl $root_dir $list_opts
}

proc get_params {argc argv list_params_name list_opts_name} {
	global argv0 stderr

	upvar $list_params_name list_params
	upvar $list_opts_name list_opts
	
	set opts [list [list notodo 0 "Don't show todo items"] \
								 [list noxml 0 "Don't handle xml files"] \
								 [list checktcl 0 "Check checktcl.tcl also"]]
	set argv_orig $argv
	set fouten 0
	set res ""
	set list_opts {}
	if {[catch {set list_opts [::cmdline::getoptions argv $opts]} res]} {
		set fouten 1
	}
	
	if {!$fouten} {
		if {[llength $argv] != 1} {
			set fouten 1
		}
	}

	if {$fouten} {
		puts stderr "syntax: $argv0 \[options\] <root_dir>"
		puts stderr "$res"
		puts stderr "got: $argv_orig"
		exit 1
	}

	set list_params $argv
	
}


proc check_params {argc argv argv_orig} {
	global argv0 stderr

	if {$argc != 1} {
		puts stderr "syntax: $argv0 \[options\] <root_dir>; got: $argv_orig"
		exit 1
	}

}

if {[file tail $argv0] == [file tail [info script]]} {
  main $argc $argv
} 

