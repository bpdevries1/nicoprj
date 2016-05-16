#!/home/nico/bin/tclsh

proc main {argv} {
  while {![eof stdin]} {
    gets stdin line
    if {$line == "\}"} {
      puts [join [list $trans_name $trans_linenr $trans_it $time $sev $int_error $native_error $msg] ";"] 
    }
    if {[regexp {^ *([^:]+): (.*)$} $line z nm val]} {
      set nm [string trim $nm]
      set val [string trim $val]
      if {$nm == "Transaction"} {
        lassign [split $val ","] trans_name trans_linenr trans_it
      }
      if {$nm == "Time"} {
        set time $val
      }
      if {$nm == "Severity"} {
        set sev $val
      }
      if {$nm == "Internal Error"} {
        set int_error $val
      }
      if {$nm == "Native Error"} {
        set native_error $val 
      }
      if {$nm == "Message"} {
        set msg $val
      }
    }
  }
}

main $argv
