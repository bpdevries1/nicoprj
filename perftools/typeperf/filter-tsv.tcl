proc main {} {
  gets stdin line
  set header [split $line "\t"]
  # \\ABAPRD1NOD2\Processor(_Total)\% Processor Time
  set ndx [lsearch -regexp $header {Processor\(_Total\)\\% Processor Time}]
  puts "[lindex $header 0],[lindex $header $ndx]"
  while {![eof stdin]} {
    set l [split [gets stdin] "\t"]
    puts "[lindex $l 0],[lindex $l $ndx]"
  } 
}

main
