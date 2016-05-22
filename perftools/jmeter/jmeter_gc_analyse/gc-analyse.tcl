proc main {} {
 set first 1
 set ts_last "<unknown>"
 set gc_sec 0.0
 set ts_unload_last "<unknown>"
 while {![eof stdin]} {
  gets stdin line
  if {[regexp {^\[([^\]]+)\] \[jmeter_wrap\] \[info\] +[0-9]+K->[0-9]+K\([0-9]+K\), ([0-9.]+) secs]} $line z ts sec]} {
   if {$first} {
    puts "First timestamp: $ts"
    set first 0
   }
   set ts_last $ts
   set gc_sec [expr $gc_sec + $sec]
  } elseif {[regexp {^\[([^\]]+)\] \[jmeter_wrap\] \[debug\] \[Unloading class org.mozilla.javascript} $line z ts]} {
   if {$ts != $ts_unload_last} {
    puts "$line"
    set ts_unload_last $ts
   }
  }
 

 }
 puts "Last timestamp: $ts_last"
 puts "Time spent GC-ing: [format %10.3f $gc_sec]"
}
 
main
