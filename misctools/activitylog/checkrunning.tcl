# check if activity log is running, and if not, show a message
package require Tclx

proc main {} {
  set res "error"
  try_eval {
    set res [exec c:\\bin\\pslist.exe tclsh]
    set nfound 0
    foreach line [split $res "\n"] {
      if {[regexp {tclsh} $line]} {
        incr nfound 
      }
    }
  } {
    set nfound -1
  }
  if {$nfound >= 2} {
    # ok, this tclsh process and another found, should check if it is activity log
  } else {
    # show a message, repeatedly, fail with lots of cpu usage.
    while {1} {
      puts "Activity log not found!"
    }
  }
}

main
