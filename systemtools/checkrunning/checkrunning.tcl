# write a logline each minute to see if the PC gets rebooted and an what time.
proc main {} {
  set f [open "running.txt" a]
  while {1} {
    puts $f "Still active at: [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]"
	flush $f
	after 60000
  }
  close $f
}

main