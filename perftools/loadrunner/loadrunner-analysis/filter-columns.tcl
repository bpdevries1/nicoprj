#!/home/nico/bin/tclsh

package require ndv
package require Tclx
package require struct::list

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]

proc main {argc argv} {
  global log 
	$log info "Starting"

  set options {
    {in.arg "sitescope-graphdata-30sec.txt" "Input file"}
    {out.arg "sitescope-dialogsteps-30sec.txt" "Output file"}
    {re.arg "DialogSteps" "Regular expression for column names"}
    {timecol.arg "Relative Time" "Time column name"}
  }
  set usage ": [file tail [info script]] \[options] :"
  array set ar_argv [::cmdline::getoptions argv $options $usage]

  handle_file $ar_argv(re) $ar_argv(timecol) $ar_argv(in) $ar_argv(out)
	$log info "Finished"
}

# @pre: infile is tab seperated
# @pre: first line contains column headers
proc handle_file {re timecol infilename outfilename} {
  set fi [open $infilename r]
  set fo [open $outfilename w]
  set lst_headers [add_index [split [gets $fi] "\t"]]
  # set lst_headers_filtered [filterfor el $lst_headers {[regexp $re [lindex $el 0]]}]
  # set lst_headers_filtered [filter $lst_headers "filter_header_el $re"]
  set lst_headers_filtered [filter_headers $re $timecol $lst_headers]
  set lst_headers_shortened [shorten_headers $lst_headers_filtered]
  puts $fo [join [mapfor el $lst_headers_shortened {lindex $el 0}] "\t"]
  set lst_indices [mapfor el $lst_headers_shortened {lindex $el 1}]
  while {![eof $fi]} {
    set lst_data [split [gets $fi] "\t"]
    set lst_data_filtered [filter_data $lst_data $lst_indices]
    puts $fo [join $lst_data_filtered "\t"] ; # todo komma's en punten aanpassen.
  }
  close $fi
  close $fo
}

proc filter_headers {re timecol lst} {
  set res {}
  foreach el $lst {
    if {[regexp $re [lindex $el 0]]} {
      lappend res $el 
    } elseif {[lindex $el 0] == $timecol} {
      lappend res $el
    }
  }
  return $res   
}

proc shorten_headers {lst} {
  set res {}
  foreach el $lst {
    if {[regexp {/SAP CCMS/SAP Monitor NdV//SAP CCMS Monitor Templates/Entire System/P14/(.*)} [lindex $el 0] z part]} {
      lappend res [list $part [lindex $el 1]] 
    } else {
      lappend res $el 
    }
  }
  return $res
}

proc filter_data {lst_data lst_indices} {
  set res {}
  foreach idx $lst_indices {
    lappend res [lindex $lst_data $idx] 
  }
  return $res
}

# replace each item in list with a pair: item, index (starting with 0)
proc add_index {lst} {
  set res {}
  set i 0
  foreach el $lst {
    lappend res [list $el $i]
    incr i
  }
  return $res
}

proc filter {args} {
  ::struct::list filter {*}$args 
}

proc filterfor {args} {
  ::struct::list filterfor {*}$args 
}

proc map {args} {
  ::struct::list map {*}$args 
}

proc mapfor {args} {
  ::struct::list mapfor {*}$args 
}

main $argc $argv
  
