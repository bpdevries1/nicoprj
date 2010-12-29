# du-filter.tcl: vgl. du.exe, maar dan één die niet struikelt over hidden/system dirs.
# extra: toont alleen dirs met size groter dan treshold (van 100MB)
#
# syntax: tclsh du.tcl <dirnaam>
# size wordt altijd in kb gegeven, zonder 1000-separators.

#set TRESHOLD 10000
#alleen alles groter dan 100MB
set TRESHOLD 100000
set PRINTPARENT 1 ; # if true, also print parent dir if only subdir is big.

proc main {argc argv} {
	global TRESHOLD
	
	if {($argc < 1) || ($argc > 2)} {
	  puts "syntax: tclsh du.tcl <dirnaam> \[treshold in kB\]"
	  puts "got: $argv"
	  exit
	}

	if {$argc == 2} {
		set TRESHOLD [lindex $argv 1]	
	}
	set root_dir [lindex $argv 0] 
	puts_cmdline_args $root_dir $TRESHOLD
	handledir $root_dir
}

proc puts_cmdline_args {root_dir treshold} {
	puts "# root_dir: [file normalize $root_dir]"
	puts "# treshold (kB): $treshold"
}


# retourneert size van deze dir in kb (incl. subdirs en files) en print uit
proc handledir dirname {
	global TRESHOLD

  set size 0
  set maxsub 0
  foreach subdir [glob -directory $dirname -nocomplain -types d *] {
		set subsize [handledir $subdir]
		incr size $subsize
		if {$subsize > $maxsub} {
			set maxsub $subsize
		}
  }
  foreach file [glob -directory $dirname -nocomplain -types f *] {
		incr size [expr int(ceil(1.0 * [file_size $file] / 1024))]
  }

	printsize $size $maxsub $dirname

  return $size
}

# @note door beveiliging is filesize niet altijd te bepalen.
proc file_size {filename} {
  set result 0
  catch {set result [file size $filename]}
  return $result  
}

proc printsize {size maxsub dirname} {
  global TRESHOLD PRINTPARENT
  
	if {$PRINTPARENT} {
	  # alleen afdrukken als size > 10 MB
	  if {$size > $TRESHOLD} {
		  puts "$size\t$dirname"
		}
	} else {
	  # alleen afdrukken als size - maxsub > 10 MB
	  if {[expr $size - $maxsub] > $TRESHOLD} {
		  puts "$size\t$dirname"
		}
	}
}

main $argc $argv
