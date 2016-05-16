#!/home/nico/bin/tclsh

package require ndv
package require Tclx
package require struct::list

set log [::ndv::CLogger::new_logger [file tail [info script]] info]

proc main {argc argv} {
  global log 
	$log info "Starting"

  set options {
    {in.arg "raw-trans-eng.tsv" "Input file"}
    {out.arg "per-lg.tsv" "Output file"}
  }
  set usage ": [file tail [info script]] \[options] :"
  array set ar_argv [::cmdline::getoptions argv $options $usage]

  handle_file $ar_argv(in) $ar_argv(out)
	$log info "Finished"
}

# 10.30.23.61, 62, 65 en nog een.
proc handle_file {infilename outfilename} {
  global log ar_lg_idx lst_lgs
  set fi [open $infilename r]
  set fo [open $outfilename w]
  set lst_lgs [list 10.30.23.61 10.30.23.62 10.30.23.64 10.30.23.65]
  puts $fo "elapsed\t[join $lst_lgs "\t"]"
  set idx 0
  foreach el $lst_lgs {
    set ar_lg_idx($el) $idx
    incr idx
  }
  gets $fi headerline
  while {![eof $fi]} {
    set line [gets $fi]
    lassign [split $line "\t"] z z z z z lg_name z elapsed ms transname
    if {[login_trans $transname]} {
      $log debug "login_trans: $transname"
      set elapsed_hm [det_hm $elapsed]
      # breakpoint
      output_time $fo $elapsed_hm $lg_name $ms
    } else {
      $log debug "other_trans: $transname" 
    }
  }
  close $fi
  
  foreach hm [lsort [array names ar_count]] {
    puts $fo [join [list $hm $ar_count($hm)] "\t"] 
  }
  close $fo
}

proc output_time {fo elapsed_hm lg_name ms} {
  global ar_lg_idx lst_lgs
  # fill the right column with the ms resptime, and also the first column with elapsed.
  puts $fo "$elapsed_hm\t[join [lreplace [lrepeat [llength $lst_lgs] ""] $ar_lg_idx($lg_name) $ar_lg_idx($lg_name) $ms] "\t"]" 
}

proc login_trans {trans_name} {
  if {$trans_name != ""} {
    return 1; # nu alles
  } else {
    return 0 
  }
  if {[regexp {00_Inloggen_SAP} $trans_name]} {
    return 1
  } else {
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

