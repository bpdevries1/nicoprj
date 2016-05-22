# convert output of stopwatch.tcl to trans.tsv for use in wireshark.R script.

# output
#transaction,start,stop,duration
#1,1322040101,1322040102.1438,1.1438

proc main {argv} {
  lassign $argv filename offset
  # output is filename with ext .csv and name added -trans.
  # offset is seconds.milliseconds to add to each timestamp
  set fn_out "[file rootname $filename]-trans.csv"
  set fi [open $filename r]
  set fo [open $fn_out w]
  puts $fo "transaction,start,stop,duration"
  set dt_prev -1
  while {![eof $fi]} {
    gets $fi line
    # [2012-02-10 11:33:20.096] [10] sync na reboot
    if {[regexp {\[([^\.]+)(\....)\] \[([0-9]+)\] (.+)$} $line z str_dt msec nr text]} {
      # set dt [expr [clock scan $str_dt -format "%Y-%m-%d %H:%M:%S" -gmt 1] + $msec + $offset]
      # NdV 14-2-2012 in de sqlite database zijn timestamps met -gmt 0 erin gezet, dus van de NL tijd naar GMT geconverteerd. Dit dus ook hier!
      set dt [expr [clock scan $str_dt -format "%Y-%m-%d %H:%M:%S" -gmt 0] + $msec + $offset]
      if {$dt_prev > 0} {
        puts $fo [join [list "$text: $nr" $dt_prev $dt [expr $dt - $dt_prev]] ","]        
      }
      set dt_prev $dt
    }
  }
  close $fi
  close $fo
}

main $argv
