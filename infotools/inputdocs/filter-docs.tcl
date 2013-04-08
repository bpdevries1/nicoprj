proc main {} {
  global notes doc
  set notes {}
  set doc {}
  while {![eof stdin]} {
    gets stdin line
    set l [split $line "\t"]
    if {[llength $l] == 2} {
      # nieuwe regel
      handle_prev
      lassign $l doc note
      set notes [list $note]
    } elseif {[llength $l] == 1} {
      # extra note bij vorige
      lappend notes [lindex $l 0]
    } else {
      if {[string trim $line] == ""} {
        # ok, empty line (at end). 
      } else {
        error "#l = [llength $l] : $line"
      }
    }
  }
  handle_prev
}

proc handle_prev {} {
  global notes doc
  if {$doc != ""} {
    set str_notes [join $notes "; "]
    if {[regsub {<todo>} $str_notes "" str_notes]} {
      set status "todo" 
    } else {
      set status "handled" 
    }
    puts "$doc\t$str_notes\t$status"
  }
}

main
