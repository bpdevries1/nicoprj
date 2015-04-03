#!/usr/bin/env tclsh86

package require ndv

proc main {argv} {
  global argv0
  if {[:# $argv] != 2} {
    puts stderr "Syntax: $argv0 <dir> <#seasons>"
    exit 1
  }
  lassign $argv dir nseasons
  if {$nseasons >= 10} {
    set fmt "%02d"
  } else {
    set fmt "%01d"
  }
  for {set i 1} {$i <= $nseasons} {incr i} {
    file mkdir [file join $dir [format "Season $fmt" $i]]
  }
}

main $argv
