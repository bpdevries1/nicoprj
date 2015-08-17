proc main {argv} {
  lassign $argv filename
  set f [file_open $filename]
  while {1} {
    gets $f line
    if {$line == ""} {
      after 10
    } else {
      set t [clock milliseconds]
      set msec [format %03d [expr $t % 1000]]
      set sec [expr $t / 1000]
      puts "\[[clock format $sec -format "%Y-%m-%d %H:%M:%S"].$msec\] $line"
    }
  }
}

# open a file for non-blocking reading.
# wait until the file is available.
proc file_open {filename} {
  set done 0
  while {1} {
    catch {
      set f [open $filename r]
      set done 1
    }
    if {$done} {
      break
    } else {
      after 50
    }
  }
  # not sure if fconfigure is needed and working.
  #fconfigure $f -blocking 0
  return $f
}

main $argv
