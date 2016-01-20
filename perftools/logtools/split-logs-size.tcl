package require ndv

# beetje marge.
# set MAX_SIZE [expr 1024*1024*500 - 100]

# met size hierboven begint Splunk bij ongeveer 68% steeds weer overnieuw, dus wat kleiner doen.
set MAX_SIZE [expr 500 * 1000 * 1000]

# use 2 characters for line end to be sure.

proc main {argv} {
  global MAX_SIZE
  
  lassign $argv path
  set target_dir [file join [file dirname $path] split]
  file mkdir $target_dir
  set filename [file tail $path]
  set idx 1
  set partname [file join $target_dir "[file rootname $filename]-$idx[file extension $filename]"]
  set fi [open $path r]
  puts "Opened $partname"
  set fo [open $partname w]
  set cur_size 0
  set linenr 0
  while {[gets $fi line] >= 0} {
    incr linenr
    if {[expr  $linenr % 10000] == 0} {
      puts "lines read: $linenr"
    }
    set line_size [expr  [string length $line] + 2]
    set cur_size [expr $cur_size + $line_size]
    if {$cur_size > $MAX_SIZE} {
      close $fo
      incr idx
      # set partname "[file rootname $filename]-$idx[file extension $filename]"
      set partname [file join $target_dir "[file rootname $filename]-$idx[file extension $filename]"]
      set fo [open $partname w]
      puts "Opened $partname"
      set cur_size $line_size
    }
    puts $fo $line
  }
  close $fo
  close $fi
}

main $argv
