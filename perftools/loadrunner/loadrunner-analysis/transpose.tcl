#!/home/nico/bin/tclsh

package require ndv
package require Tclx
package require struct::list

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]

proc main {argc argv} {
  global log 
	$log info "Starting"

  set options {
    {in.arg "sitescope-graphdata-60sec.txt" "Input file"}
    {nlines.arg "5" "Number of lines to transpose."}
    {out.arg "sitescope-graphdata-60sec-unscaled.tsv" "Output file"}
  }
  set usage ": [file tail [info script]] \[options] :"
  array set ar_argv [::cmdline::getoptions argv $options $usage]

  handle_file $ar_argv(in) $ar_argv(out) $ar_argv(nlines)
	$log info "Finished"
}

# @pre: infile is tab seperated
# @pre: first line contains column headers
# @pre: sepchar is tab.
proc handle_file {infilename outfilename nlines} {
  global ar_fd
  set fi [open $infilename r] 
  set fo [open $outfilename w]
  set lst_headers [split [gets $fi] "\t"]
  set ncols [llength $lst_headers]
  # ar_values(row,col) in input, change in output
  set col 0
  foreach el $lst_headers {
    set ar_values(0,$col) $el
    incr col
  }
  set row 1
  while {$row < $nlines} {
    set lst_vals [split [gets $fi] "\t"]
    set col 0
    foreach el $lst_vals {
      set ar_values($row,$col) $el
      incr col
    }
    incr row 
  }

  for {set col 0} {$col < $ncols} {incr col} {
    for {set row 0} {$row < $nlines} {incr row} {
      if {$row == 0} {
        puts -nonewline $fo $ar_values($row,$col)
      } else {
        puts -nonewline $fo "\t$ar_values($row,$col)"
      }
    }
    puts $fo ""     
  }
  
  close $fi
  close $fo
}

main $argc $argv
  
