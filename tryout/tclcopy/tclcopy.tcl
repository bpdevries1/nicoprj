#!/usr/bin/env tclsh86

package require ndv

proc main {argv} {
  global argv0
  if {[llength $argv] != 2} {
    puts stderr "syntax: $argv0 <src> <target>"
  }
  lassign $argv src target
  # set ts_start [clock seconds]
  set ts_start_usec [clock microseconds]
  set bytes [file size $src]
  puts "Copying $src => $target"
  # file copy $src $target
  exec cp $src $target
  # set ts_end [clock seconds]
  set ts_end_usec [clock microseconds]
  # set sec [expr $ts_end - $ts_start]
  set sec [expr 0.000001 * ($ts_end_usec - $ts_start_usec)]
  set mbytes [expr 1.0 * $bytes / (1024*1024)]
  if {$sec == 0} {
    puts "Finished copying [format %.3f $mbytes] Mbytes in $sec seconds with fast speed."
  } else {
    set speed_mb_sec [expr $mbytes / $sec]
    puts "Finished copying [format %.3f $mbytes] Mbytes in [format %.6f $sec] seconds with a speed of [format %.3f $speed_mb_sec] MBytes/sec"    
  }
}

main $argv
