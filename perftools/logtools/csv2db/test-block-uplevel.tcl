proc main {} {
  test_uplevel {
    puts "line: $line" 
  }
  test_uplevel_var {
    puts "line: $line" 
  }
  
}

proc test_uplevel {block} {
  set i 1
  while {$i <= 10} {
    set line "This is line $i"
    # uplevel "set line \"$line\""
    uplevel [list set line $line]
    uplevel $block
    incr i 
  }
}

proc test_uplevel_var {block} {
  upvar line line2
  set i 1
  while {$i <= 10} {
    set line2 "This is (var)line $i"
    # uplevel "set line \"$line\""
    # uplevel [list set line $line]
    # upvar line line2
    uplevel $block
    incr i 
  }
}

main
