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
    {legend.arg "Graph Legend - SiteScope.csv" "Legend data file"}
    {out.arg "sitescope-graphdata-60sec-unscaled.tsv" "Output file"}
  }
  set usage ": [file tail [info script]] \[options] :"
  array set ar_argv [::cmdline::getoptions argv $options $usage]

  read_legend $ar_argv(legend)
  handle_file $ar_argv(in) $ar_argv(out)
	$log info "Finished"
}

proc read_legend {legend_filename} {
  global ar_scale
  set f [open $legend_filename r]
  gets $f header
  while {![eof $f]} {
    lassign [split [gets $f] ","] color scale measurement 
    set ar_scale([shorten_header $measurement]) $scale
  }
  close $f
}

proc shorten_headers {lst} {
  # @todo wil dit doen met een map(for), maar doet moeilijk.
  set res {}
  foreach el $lst {
    # /SAP CCMS/SAP Monitor NdV//SAP CCMS Monitor Templates/Entire System/P14/Application Server/P14\sap01257_P14_00/OperatingSystem/CPU/CPU_Utilization:localhost
    # /SAP CCMS/SAP CCMS Performance overview//SAP CCMS Monitor Templates/Performance Overview/P14\sap01257_P14_00/Dialog/P14\sap01257_P14_00\...\Dialog\Load+GenTime:localhost
    # /SAP CCMS/SAP Monitor NdV//SAP CCMS Monitor Templates/Performance Overview/P14\sap01257_P14_00/Operating System/P14\sap01257_P14_00\...\CPU\CPU_Utilization:localhost
    # /SAP CCMS/SAP CCMS DB Performance//SAP CCMS Monitor Templates/Database/P14\DB2 Universal Database for NT/UNIX/Performance/bufferpool IBMDEFAULTBP/overall buffer quality:localhost
    # /SAP CCMS/SAP CCMS Performance overview//SAP CCMS Monitor Templates/Performance Overview/P14\pkgp140d_P14_00/Dialog/P14\pkgp140d_P14_00\...\Dialog\DBRequestTime:localhost
    lappend res [list [shorten_header [lindex $el 0]] [lindex $el 1]]
  }
  return $res
}

proc shorten_header {header} {
  if {[regexp {/P14[/\\](.*)} $header z part]} {
    return $part 
  } else {
    return $header 
  }
}

# @pre: infile is tab seperated
# @pre: first line contains column headers
proc handle_file {infilename outfilename} {
  global ar_fd
  set fi [open $infilename r] 
  # set fo [open $outfilename w]
  set line_headers [gets $fi]
  set lst_headers [split $line_headers "\t"]
  set lst_headers [add_index $lst_headers]
  set lst_headers [shorten_headers $lst_headers]  
  
  set fo [open $outfilename w]
  # puts $fo "[lindex $lst_headers 0 0]\t[lindex $el 0]"
  puts $fo $line_headers
  while {![eof $fi]} {
    set lst_data [split [gets $fi] "\t"]
    # puts_fds $lst_headers $lst_data
    puts -nonewline $fo [lindex $lst_data 0] ; # timestamp
    foreach el [lrange $lst_headers 1 end] {
      # puts $ar_fd([lindex $el 1]) "[lindex $lst_data 0]\t[lindex $lst_data [lindex $el 1]]"
      puts -nonewline $fo "\t[unscale_number [lindex $lst_data [lindex $el 1]] [lindex $el 0]]"
    }    
    puts $fo ""
  }
  close $fi
  close $fo
}

proc unscale_number {scaled_value name} {
  global ar_scale 
  if {$scaled_value == ""} {
    return $scaled_value 
  } else {
    expr 1.0 * $scaled_value / $ar_scale($name)
  }
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
  
