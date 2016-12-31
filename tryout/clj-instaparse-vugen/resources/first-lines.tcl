#! /usr/bin/env tclsh

package require ndv

proc main {argv} {
  lassign $argv nlines
  set srcfile "landing.c"
  set targetfile "landing-$nlines.c"
  set lines [split [read_file $srcfile] "\n"]
  set lines2 [lrange $lines 0 $nlines-1]
  lappend lines2 {*}[lrange $lines end-3 end]
  write_file $targetfile [join $lines2 "\n"]
}

main $argv
