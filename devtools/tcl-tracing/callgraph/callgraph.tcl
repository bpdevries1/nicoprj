#!/usr/bin/env tclsh

# puts stderr "App started"

package require Itcl

source CLineHandler.tcl
source CTextOutputter.tcl
source CDatabaseOutputter.tcl
source CClassLib.tcl


proc main {argc argv} {
	set source_dir [file normalize [lindex $argv 0]]
	set traces_dir [file normalize [lindex $argv 1]]
	set clinehandler [CLineHandler #auto]
	set coutputter [CTextOutputter::new_instance]
	$clinehandler add_outputter $coutputter

	set cdboutputter [CDatabaseOutputter::new_instance]
	$clinehandler add_outputter $cdboutputter
	
	set cclasslib [CClassLib::new_instance]
	$clinehandler set_classlib $cclasslib
	# also output calls to classlib
	$clinehandler add_outputter $cclasslib
	
	# tijdens lezen source-tree ook info naar db
	$cclasslib set_db_outputter $cdboutputter
	$cclasslib read_source_tree $source_dir
	
	# # even alleen source inlezen, niet de trace.
	readfiles $traces_dir $clinehandler
	$cclasslib report
}

proc readfiles {traces_dir clinehandler} {
	foreach trace_file [glob -directory $traces_dir -type f *.trace] {
		puts "Reading file: $trace_file"
		readfile $trace_file $clinehandler
	}
}

proc readfile {trace_file clinehandler} {
	$clinehandler new_file [file tail $trace_file]
	set f [open $trace_file r]
	while {![eof $f]} {
		gets $f line
		$clinehandler handle_line $line
	}
	close $f
}

main $argc $argv

