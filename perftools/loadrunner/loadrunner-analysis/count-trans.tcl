#!/home/nico/bin/tclsh

package require ndv
package require Tclx
package require struct::list

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]

proc main {argc argv} {
  global log 
	$log info "Starting"

  set options {
    {in.arg "raw-trans-eng.tsv" "Input file"}
    {out.arg "raw-trans-count.tsv" "Output file"}
  }
  set usage ": [file tail [info script]] \[options] :"
  array set ar_argv [::cmdline::getoptions argv $options $usage]

  handle_file $ar_argv(in) $ar_argv(out)
	$log info "Finished"
}

proc handle_file {infilename outfilename} {
  global log
  set fi [open $infilename r]
  gets $fi headerline
  while {![eof $fi]} {
    lassign [split [gets $fi] "\t"] z z z z z z z elapsed ms transname
    if {[head_trans $transname]} {
      $log debug "head_trans: $transname"
      set elapsed_hm [det_hm $elapsed]
      incr ar_count($elapsed_hm)
    } else {
      $log debug "other_trans: $transname" 
    }
  }
  close $fi
  
  set fo [open $outfilename w]
  puts $fo [join [list elapsed count_trans_minute] "\t"]
  foreach hm [lsort [array names ar_count]] {
    puts $fo [join [list $hm $ar_count($hm)] "\t"] 
  }
  close $fo
}

proc head_trans {trans_name} {
  if {[regexp {^\d\d_} $trans_name]} {
    if {[regexp {_\d\d$} $trans_name]} {
      # sub_trans
      return 0
    } else {
      # head trans
      return 1
    }
  } else {
    # other trans
    return 0
  }
}

# @param elapsed: 1,127.41
# % clock format 12030 -format "%H:%M" -gmt 1
# 03:20
proc det_hm {elapsed} {
  regsub -all "," $elapsed "" elapsed
  clock format [expr int($elapsed)] -format "%H:%M" -gmt 1
}

main $argc $argv

