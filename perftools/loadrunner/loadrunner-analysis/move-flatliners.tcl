#!/home/nico/bin/tclsh

package require ndv
package require Tclx
package require struct::list

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]

proc main {argc argv} {
  global log 
	$log info "Starting"

  set options {
    {in.arg "split" "Input directory"}
    {out.arg "flat" "Output directory"}
  }
  set usage ": [file tail [info script]] \[options] :"
  array set ar_argv [::cmdline::getoptions argv $options $usage]

  handle_dir $ar_argv(in) $ar_argv(out)
}

# @pre: infile is tab seperated
# @pre: first line contains column headers
proc handle_dir {indirname outdir} {
  file mkdir $outdir
  set f [open [file join $outdir minmax.tsv] w]
  puts $f "name\tmin\tmax"
  foreach filename [glob -directory $indirname -type f "*.tsv"] {
    if {[flatline $filename minvalue maxvalue]} {
      # file rename $filename [file join $outdir [file tail $filename]]
      # breakpoint
      file rename $filename $outdir
    }
    puts $f "$filename\t$minvalue\t$maxvalue"
  }
  close $f  
}

proc flatline {filename minvalue_name maxvalue_name} {
  upvar $minvalue_name min_value
  upvar $maxvalue_name max_value
  set f [open $filename r]
  gets $f line
  lassign [split [gets $f] "\t"] z value
  set min $value ; # can be empty
  set max $value ; # can be empty
  while {![eof $f]} {
    lassign [split [gets $f] "\t"] z value
    if {$value != ""} {
      if {$min == ""} {
        # min/max get value at same time
        set min $value
        set max $value
      } else {
        if {$value < $min} {
          set min $value
        }
        if {$value > $max} {
          set max $value
        }
      }
    } else { 
      # nothing, empty value
    }
  }
  close $f
  set min_value $min
  set max_value $max
  if {$min == ""} {
    return 1 ; # flatline if no values
  } else {
    if {$min == $max} {
      return 1 
    } else {
      return 0 
    }
  }
  
}

main $argc $argv


