# compare to 'du -m' outputs.
 
source [file join $env(CRUISE_DIR) checkout lib perflib.tcl]
source [file join $env(CRUISE_DIR) checkout script lib CLogger.tcl]

set log [CLogger::new_logger dudiff info]
set TRESHOLD 10.0 ; # treshold in megabytes to record.

proc main {argc argv} {
	check_params $argc $argv

	set filename_prev [lindex $argv 0]
	set filename_curr [lindex $argv 1]
	
	lees_du $filename_prev ar_prev lst_prev
	lees_du $filename_curr ar_curr lst_curr
	det_diff ar_prev lst_curr ar_diff lst_diff
	puts_sorted $lst_diff "\n==================\nDiff with previous:"
	puts_sorted $lst_curr "\n==================\nCurrent sizes:"
}

proc check_params {argc argv} {
	global argv0
	if {$argc != 2} {
		fail "syntax: tclsh $argv0 <du-previous> <du-current>"
	}
}

proc lees_du {filename ar_name lst_name} {
	global TRESHOLD
	
	upvar $ar_name ar
	upvar $lst_name lst
	
	set lst {}
	set f [open $filename r]
	while {![eof $f]} {
		gets $f line
		if {[regexp {^([^\t]+)\t(.*)$} $line z size path]} {
			if {$size >= $TRESHOLD} {
				if {![ignore_path $path]} {
					set ar($path) $size
					lappend lst [list $path $size]		
				}
			}
		}
	}
	close $f	
}

proc ignore_path {path} {
	# soms begint 'ie met 2 slashes, als du -m / wordt gedaan (?)
	if {[regexp {/prj/depot} $path]} {
		return 1
	}	else {
		return 0
	}
}

proc det_diff {ar_prev_name lst_curr_name ar_diff_name lst_diff_name} {
	upvar $ar_prev_name ar_prev
	upvar $lst_curr_name lst_curr
	upvar $ar_diff_name ar_diff
	upvar $lst_diff_name lst_diff
	
	set lst_diff {}
	foreach el $lst_curr {
		set path [lindex $el 0]
		set size [lindex $el 1]
		set prev_size 0.0
		catch {set prev_size $ar_prev($path)}
		set diff [expr $size - $prev_size]
		set ar_diff($path) $diff
		lappend lst_diff [list $path $diff]
	}
}

proc puts_sorted {lst msg} {
	puts $msg
	foreach el [lsort -decreasing -index 1 -real $lst] {
		set path [lindex $el 0]
		set size [lindex $el 1]
		if {$size != 0.0} {
			puts "$size\t$path"		
		}
	}
}

main $argc $argv
