# Usage:
# Perf Center report for a testrun; summary; copy/paste response times (including header) in a text file.
# tclsh weighted-avg.tcl c:\pcc\Nico\Projecten\dotcom\resptimes-run447.txt
# Weighted average for c:\pcc\Nico\Projecten\dotcom\resptimes-run447.txt: 0.373

proc main {argv} {
  lassign $argv infilename
  set f [open $infilename r]
  gets $f header
  set n_total 0
  set w_avg 0.0
  while {[gets $f line] >= 0} {
	set n [remove_dot [lindex $line end-2]]
	set R_avg [comma2dot [lindex $line 5]]
	set n_total [expr $n_total + $n]
	set w_avg [expr $w_avg + ($n * $R_avg)]
  }
  close $f
  set w_avg_total [expr $w_avg / $n_total]
  puts "Weighted average for $infilename: [format %.3f $w_avg_total]"
}

proc comma2dot {str} {
  regsub -all {,} $str "." str
  return $str
}

proc remove_dot {str} {
  regsub -all {\.} $str "" str
  return $str
}

main $argv
