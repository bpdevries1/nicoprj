proc main {argv} {
  set prev "NULL"
  puts "#+STARTUP: indent"
  while {![eof stdin]} {
    gets stdin line
    if {[regexp {^=+$} $line]} {
      puts "* $prev"
      set prev "NULL"
    } elseif {[regexp {^\* } $line]} {
      if {$prev != "NULL"} {
        puts $prev
      }
      puts "*$line"
      set prev "NULL"
    } else {
      if {$prev != "NULL"} {
        puts $prev
      }
      set prev $line
    }
  }
  if {$prev != "NULL"} {
    puts $prev
  }
}

main $argv
