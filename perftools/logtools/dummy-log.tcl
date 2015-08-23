proc main {argv} {
  global stdout
  lassign $argv logfile
  # set f [open c:/PCC/SQL-dummy.log w]
  set f [open $logfile w]
  for {set x 0} {$x<20} {incr x} {    
    set msec [expr round(1000*rand())] 
    set ts1 [get_ts]
    after $msec
    set ts2 [get_ts]
    set tsd [timediff $ts1 $ts2]
    puts $f "Waited $msec msec ($ts1 => $ts2 (diff=$tsd))"
    puts $f ""
    flush $f
    puts "Waited $msec msec ($ts1 => $ts2 (diff=$tsd))"
    flush stdout
  }
  close $f
}

proc get_ts {} {
  set msec [format %03d [expr [clock milliseconds] % 1000]]
  return "[clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"].$msec"
}

proc timediff {t1 t2} {
  format %.3f [expr [to_sec $t2] - [to_sec $t1]]
}

# ts: timestamp including milliseconds
proc to_sec {ts} {
  regexp {^([^.]+)(\.\d+)$} $ts z ts_sec msec
  return "[clock scan $ts_sec -format "%Y-%m-%d %H:%M:%S"]$msec"
}

main $argv