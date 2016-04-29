# input: stdin
# output: stdout
proc main {} {
  gets stdin line
  puts "^[string map {"\t" "^"} $line]^"
  while {![eof stdin]} {
    gets stdin line
    set line2 "|[string map {"\t" "|"} $line]|"
    while {[regsub {\|\|} $line2 "|  |" line2]} {}
    puts $line2
  }
}

main
