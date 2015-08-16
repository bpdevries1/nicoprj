proc main {} {
  while {![eof stdin]} {
    gets stdin line
    if {[regexp {^\[.{20,25}\] (.*)$} $line z txt]} {
      puts $txt
    } else {
      puts $line
    }
  }
}

main