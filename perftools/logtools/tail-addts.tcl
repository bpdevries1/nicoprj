proc main {argv} {
  global argv0
  lassign $argv filename freq_msec tsformat
  # 18-8-2015 freq of 1 msec proved to be too much on Rahul's PC, about 30% CPU and apparently a lot slower queries.
  if {$filename == ""} {
    puts "syntax: $argv0 logfile.log \[freq_msec\] >logfile-with-ts"
    exit 1
  }
  if {$freq_msec == ""} {
    set freq_msec 10
  }
  if {$tsformat == ""} {
    set tsformat "msec"
  }
  set f [file_open $filename]
  # puts "File open done, f=$f"
  set prevline "none"
  # 18-8-2015 NdV using eof does not work here, it basically always returns true.
  # 20-8-2015 NdV just put msecs now, takes less CPU time, factor 2.5-3 difference. When loading in DB, convert back to timestamps.
  
  # [2016-05-22 11:36:48] if tsformat==msec, do the least amount of checking in the loop.
  if {$tsformat == "msec"} {
    while {1} {
      gets $f line
      if {($line == "") && ($prevline == "")} {
        after $freq_msec
      } else {
        puts "\[[clock milliseconds]\] $line"
      }
      set prevline $line
    }
  } else {
    # used for human readable timestamp, on second frequency, less time critical
    set fmt [det_clock_format $tsformat]
    while {1} {
      gets $f line
      if {($line == "") && ($prevline == "")} {
        after $freq_msec
      } else {
        puts "\[[clock format [clock seconds] -format $fmt]\] $line"
      }
      set prevline $line
    }
  }
}

proc det_clock_format {tsformat} {
  if {$tsformat == "human"} {
    return "%Y-%m-%d %H:%M:%S %z"
  } else {
    return $tsformat
  }
}

proc main_orig {argv} {
  global argv0
  lassign $argv filename freq_msec
  # 18-8-2015 freq of 1 msec proved to be too much on Rahul's PC, about 30% CPU and apparently a lot slower queries.
  if {$filename == ""} {
    puts "syntax: $argv0 logfile.log \[freq_msec\] >logfile-with-ts"
    exit 1
  }
  if {$freq_msec == ""} {
    set freq_msec 10
  }
  set f [file_open $filename]
  # puts "File open done, f=$f"
  set prevline "none"
  # 18-8-2015 NdV using eof does not work here, it basically always returns true.
  while {1} {
    gets $f line
    if {($line == "") && ($prevline == "")} {
      # puts "eof, wait a bit"
      # puts "empty string, wait a bit"
      after $freq_msec
    } else {
      set t [clock milliseconds]
      set msec [format %03d [expr $t % 1000]]
      set sec [expr $t / 1000]
      puts "\[[clock format $sec -format "%Y-%m-%d %H:%M:%S"].$msec\] $line"
    }
    set prevline $line
  }
}


proc main2 {argv} {
  lassign $argv filename
  set f [file_open $filename]
  while {1} {
    if {[eof $f]} {
      after 1
    } else {
      gets $f line
      set t [clock milliseconds]
      set msec [format %03d [expr $t % 1000]]
      set sec [expr $t / 1000]
      puts "\[[clock format $sec -format "%Y-%m-%d %H:%M:%S"].$msec\] $line"
    }
  }
}

# open a file for reading.
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
  return $f
}

main $argv
