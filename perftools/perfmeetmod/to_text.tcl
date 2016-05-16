package require Tclx

proc main {} {
  for_recursive_glob filename . "*" {
    puts_file $filename 
  }
}

proc puts_file {filename} {
  puts "*** start filename: $filename ***" 
  if {[file isfile $filename]} {
    set f [open $filename r]
    set text [read $f]
    close $f
    puts $text
    puts "*** end filename: $filename ***"
  }
}

main
