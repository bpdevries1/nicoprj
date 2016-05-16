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
    {out.arg "split" "Output directory"}
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

# @pre: infile is tab seperated
# @pre: first line contains column headers
proc handle_file {infilename outdir} {
  global ar_fd
  set fi [open $infilename r] 
  file mkdir $outdir
  # set fo [open $outfilename w]
  set lst_headers [add_index [split [gets $fi] "\t"]]
  # set lst_headers_filtered [filterfor el $lst_headers {[regexp $re [lindex $el 0]]}]
  # set lst_headers_filtered [filter $lst_headers "filter_header_el $re"]
  # set lst_headers_filtered [filter_headers $re $lst_headers]
  set lst_headers [shorten_headers $lst_headers]
  open_fds $lst_headers $outdir; # including write header
  # puts $fo [join [mapfor el $lst_headers_shortened {lindex $el 0}] "\t"]
  # set lst_indices [mapfor el $lst_headers_shortened {lindex $el 1}]
  while {![eof $fi]} {
    set lst_data [split [gets $fi] "\t"]
    puts_fds $lst_headers $lst_data
  }
  close $fi
  close_fds $lst_headers
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

proc shorten_headers_old2 {lst} {
  set res {}
  foreach el $lst {
    # /SAP CCMS/SAP Monitor NdV//SAP CCMS Monitor Templates/Entire System/P14/Application Server/P14\sap01257_P14_00/OperatingSystem/CPU/CPU_Utilization:localhost
    # /SAP CCMS/SAP CCMS Performance overview//SAP CCMS Monitor Templates/Performance Overview/P14\sap01257_P14_00/Dialog/P14\sap01257_P14_00\...\Dialog\Load+GenTime:localhost
    # /SAP CCMS/SAP Monitor NdV//SAP CCMS Monitor Templates/Performance Overview/P14\sap01257_P14_00/Operating System/P14\sap01257_P14_00\...\CPU\CPU_Utilization:localhost
    # /SAP CCMS/SAP CCMS DB Performance//SAP CCMS Monitor Templates/Database/P14\DB2 Universal Database for NT/UNIX/Performance/bufferpool IBMDEFAULTBP/overall buffer quality:localhost
    # /SAP CCMS/SAP CCMS Performance overview//SAP CCMS Monitor Templates/Performance Overview/P14\pkgp140d_P14_00/Dialog/P14\pkgp140d_P14_00\...\Dialog\DBRequestTime:localhost
    if {[regexp {/P14[/\\](.*)} [lindex $el 0] z part]} {
      lappend res [list $part [lindex $el 1]] 
    } else {
      lappend res $el 
    }
  }
  return $res
}

proc shorten_headers_old {lst} {
  set res {}
  foreach el $lst {
    # /SAP CCMS/SAP Monitor NdV//SAP CCMS Monitor Templates/Entire System/P14/Application Server/P14\sap01257_P14_00/OperatingSystem/CPU/CPU_Utilization:localhost
    # /SAP CCMS/SAP CCMS Performance overview//SAP CCMS Monitor Templates/Performance Overview/P14\sap01257_P14_00/Dialog/P14\sap01257_P14_00\...\Dialog\Load+GenTime:localhost
    # /SAP CCMS/SAP Monitor NdV//SAP CCMS Monitor Templates/Performance Overview/P14\sap01257_P14_00/Operating System/P14\sap01257_P14_00\...\CPU\CPU_Utilization:localhost
    # /SAP CCMS/SAP CCMS DB Performance//SAP CCMS Monitor Templates/Database/P14\DB2 Universal Database for NT/UNIX/Performance/bufferpool IBMDEFAULTBP/overall buffer quality:localhost
    # /SAP CCMS/SAP CCMS Performance overview//SAP CCMS Monitor Templates/Performance Overview/P14\pkgp140d_P14_00/Dialog/P14\pkgp140d_P14_00\...\Dialog\DBRequestTime:localhost
    if {[regexp {/SAP CCMS/SAP Monitor NdV//SAP CCMS Monitor Templates/Entire System/P14/(.*)} [lindex $el 0] z part]} {
      lappend res [list $part [lindex $el 1]] 
    } elseif {[regexp {/SAP CCMS/SAP CCMS Performance overview//SAP CCMS Monitor Templates/Performance Overview/P14/(.*)} [lindex $el 0] z part]} {
      lappend res [list $part [lindex $el 1]]
    } elseif {[regexp {/SAP CCMS/SAP Monitor NdV//SAP CCMS Monitor Templates/Performance Overview/P14/(.*)} [lindex $el 0] z part]} {
      lappend res [list $part [lindex $el 1]]
    } elseif {[regexp {/SAP CCMS/SAP CCMS DB Performance//SAP CCMS Monitor Templates/Database/P14/(.*)} [lindex $el 0] z part]} {
      lappend res [list $part [lindex $el 1]]
    } elseif {[regexp {/SAP CCMS/SAP CCMS DB Performance//SAP CCMS Monitor Templates/Database/P14/(.*)} [lindex $el 0] z part]} {
      lappend res [list $part [lindex $el 1]]
    } else {
      lappend res $el 
    }
  }
  return $res
}

proc open_fds {lst_headers outdir} {
  global ar_fd
  foreach el [lrange $lst_headers 1 end] {
    set fd [open [file join $outdir [to_filename $el]] w]
    set ar_fd([lindex $el 1]) $fd
    puts $fd "[lindex $lst_headers 0 0]\t[lindex $el 0]"
  }
}

proc to_filename {el} {
  lassign $el name idx
  regsub -all {[ \\/:\|]} $name "_" name
  return "[format %04d $idx]-$name.tsv"
}

proc close_fds {lst_headers} {
  global ar_fd
  foreach el [lrange $lst_headers 1 end] {
    close $ar_fd([lindex $el 1]) 
  }
}

proc puts_fds {lst_headers lst_data} {
  global ar_fd
  foreach el [lrange $lst_headers 1 end] {
    # puts $ar_fd([lindex $el 1]) "[lindex $lst_data 0]\t[lindex $lst_data [lindex $el 1]]"
    puts $ar_fd([lindex $el 1]) "[lindex $lst_data 0]\t[unscale_number [lindex $lst_data [lindex $el 1]] [lindex $el 0]]"
  }
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
  
