# parse sitescope logfile and produce a csv to be fed into sqlite.
package require ndv

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]

proc log {args} {
  global log
  $log {*}$args
}

proc main {} {
  handle_file "C:/projecten/KennmerGasthuis/wireshark/tijden-lognoord.txt" "C:/projecten/KennmerGasthuis/wireshark/tijden-lognoord.csv"
  handle_file "C:/projecten/KennmerGasthuis/wireshark/tijden-logzuid.txt" "C:/projecten/KennmerGasthuis/wireshark/tijden-logzuid.csv"
  handle_file "C:/projecten/KennmerGasthuis/wireshark/tijden-logzuidrc.txt" "C:/projecten/KennmerGasthuis/wireshark/tijden-logzuidrc.csv"
}

proc handle_file {filename outfilename} {
  global ar_start ar_einde ar_dur ar_name
  log info start
  #set filename "C:/projecten/KennmerGasthuis/wireshark/tijden-logzuidrc.txt"
  #set outfilename "C:/projecten/KennmerGasthuis/wireshark/tijden-logzuidrc.csv"
  set f [open $filename r]
  set fo [open $outfilename w]
  puts $fo [join [list transaction start stop duration] ","]
  log debug "starting while"
  while {![eof $f]} {
    gets $f line
    if {[regexp {Total Duration} $line]} {
      log debug "handle line"
      handle_line $line $fo 
    }
    if {[regexp {^[0-9][be]} $line]} {
      handle_line_be $line $fo 
    }
  }  
  close $f
  
  for {set i 1} {$i <= 8} {incr i} {
    # puts $fo [join [list $ar_name($i) $ar_start($i) $ar_einde($i) $ar_dur($i)] ","]
    # alleen nr, anders grafiek te vol.
    # puts $fo [join [list $i $ar_start($i) $ar_einde($i) $ar_dur($i)] ","]
    puts $fo [join [list $i {*}[calc_se $ar_start($i) $ar_einde($i) $ar_dur($i)] $ar_dur($i)] ","]
  }
  
  close $fo
  log info finished
}

# verschuif start- en eindtijd adhv start en eind in seconden en dur in sec.msec
proc calc_se {start einde dur} {
  #set s [expr $start + 0.5*(($einde + 1 - $start) - $dur)]
  # toch even zo vroeg mogelijke tijd, anders pijltjes van http transacties niet op goede plek.
  set s $start
  set e [expr $s + $dur]
  list $s $e
}

proc handle_line {line fo} {
  global ar_dur ar_name
  if {[regexp {Transaction "([0-9_A-Za-z]+)".*Total Duration: ([0-9.]+)} $line z trans sec]} {
    #puts $fo "$trans\t$sec" 
    if {[regexp {^.(.)} $trans z transnr]} {
      set ar_dur($transnr) $sec
      set ar_name($transnr) $trans
    }
  }
  
}

set start 0
proc handle_line_be {line fo} {
  global start ar_start ar_einde
  if {[regexp {begin:(.*)$} $line z tijd]} {
    set start $tijd 
  }
  if {[regexp {^(.)einde:(.*)$} $line z trans tijd]} {
    #puts $fo "$trans\t$start\t$tijd" 
    set ar_start($trans) [parse_time $start]
    set ar_einde($trans) [parse_time $tijd]
  }
}

proc parse_time {str} {
  clock scan $str -format "%d-%m-%Y %H:%M:%S" 
}

proc handle_line_old {line fo} {
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
