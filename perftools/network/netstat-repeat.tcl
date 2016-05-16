package require ndv

proc main {argv} {
  lassign $argv filename
  # filename to log to, is appended.
  
  while 1 {
    set f [open $filename a]
	puts $f "\[[get_timestamp_msec]\]"
	close $f
	exec netstat -n >>$filename
  }
}

# get timestamp in milliseconds
proc get_timestamp_msec {} {
	set t [clock milliseconds]
	set msec [format %03d [expr $t % 1000]]
	set sec [expr $t / 1000]
	return "[clock format $sec -format "%Y-%m-%d %H:%M:%S"].$msec [clock format $sec -format "%z"]" 
}

main $argv
