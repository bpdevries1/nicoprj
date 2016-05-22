# pdml-range: filter part out of a (big) pdml file.
proc main {argv} {
  lassign $argv filename start end
  set fi [open $filename r]
  set fo [open "$filename.$start-$end" w]
  
  # to be sure we have all
  set realstart [expr $start - 1]
  set realend [expr $end + 1]
  set in_range 0
  while {![eof $fi]} {
    gets $fi line
    if {[regexp {field name=.num. pos=.0. show=.([0-9]+).} $line z packetnum]} {
      if {$in_range} {
        if {$packetnum >= $realend} {
          break 
        } else {
          puts $fo $line 
        }
      } else {
        if {$packetnum >= $realstart} {
          set in_range 1
          puts $fo $line
        } else {
          # not there yet. 
        }
      }
    } else {
      if {$in_range} {
        puts $fo $line 
      } else {
        # nothing, not there yet. 
      }
    }
  }
  
  close $fi
  close $fo

}

main $argv
