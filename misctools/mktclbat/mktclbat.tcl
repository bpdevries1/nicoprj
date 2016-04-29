# make a bat file of a tcl script in the same directory, for use in Windows.
proc main {argv} {
  if {[llength $argv] != 1} {
    error "Not exactly one argument: $argv" 
  }
  set tclfile [lindex $argv 0]
  set batfile "[file rootname $tclfile].bat"
  set f [open $batfile w]
  puts $f "tclsh $tclfile %$"
  close $f
}

main $argv
