# parse sitescope logfile and produce a csv to be fed into sqlite.
package require ndv

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]

proc log {args} {
  global log
  $log {*}$args
}

proc main {} {
  log info start
  set filename "~/aaa/kg/site-1500.log"
  set outfilename "~/aaa/kg/site-1500.csv"
  set f [open $filename r]
  set fo [open $outfilename w]
  puts $fo [join [list transaction start stop duration] ","]
  log debug "starting while"
  while {![eof $f]} {
    gets $f line
    if {[regexp {QTP_Horizon_SDE	Sentinel} $line]} {
      log debug "handle line"
      handle_line $line $fo 
    }
  }  
  close $f
  close $fo
  log info finished
}

proc handle_line {line fo} {
  if {[regexp {^([^g]+).good.*DateTime: ([^,]+),,(.*),.,Total duration} $line z time1 time2 transactions]} {
    log debug "$time1 *** $time2 *** $transactions"
    set sec1 [clock scan $time1 -format "%H:%M:%S %m/%d/%Y"]
    set sec2 [clock scan $time2 -format "%d/%m/%Y %H:%M:%S"]
    log debug "time1: [clock format $sec1 -format "%Y-%m-%d %H:%M:%S"]"
    log debug "time2: [clock format $sec2 -format "%Y-%m-%d %H:%M:%S"]"
    set l [split $transactions ","]
    foreach el $l {
      if {[regexp {(0([0-9]{1})[^ ]+) \( D: ([0-9.]+) sec} $el z trans nr sec_elapsed]} {
        log debug "$nr - $trans - $sec_elapsed"
        set ar_elapsed($nr) $sec_elapsed
        set ar_trans($nr) $trans
      } else {
        breakpoint 
      }
    }
    # eerste 4 vanaf time2 (beginpunt), laatste 4 terug vanaf time2 + tijd(9,totaal) (eindpunt)
    set start $sec2
    for {set i 1} {$i <= 8} {incr i} {
      if {$i == 5} {
        set start [expr $sec2 + $ar_elapsed(9) - $ar_elapsed(5) - $ar_elapsed(6) - $ar_elapsed(7) - $ar_elapsed(8)] 
      }
      set end [expr $start + $ar_elapsed($i)]
      puts $fo [join [list $ar_trans($i) $start $end $ar_elapsed($i)] ","]
      set start $end
    }
  } else {
    breakpoint 
  }
  
}

main
