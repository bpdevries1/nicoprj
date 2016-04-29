proc main {} {
  set dirname {c:\pcc\nico\vugen\rcc_cashbalancingwidget}
  set filein1 [file join $dirname user200.dat]
  set filein2 [file join $dirname user200avg.dat]
  set fileout [file join $dirname user200mix.dat]
  combine_dat_files $filein1 $filein2 $fileout
}

# @pre assume both input have the same number of lines.
# @post output will have the same number of lines as both input files
proc combine_dat_files {filein1 filein2 fileout} {
  set fi1 [open $filein1 r]
  set fi2 [open $filein2 r]
  set fo [open $fileout w]
  # assume first line is header line, copy to output
  gets $fi1 header
  gets $fi2 z
  puts $fo $header
  set out {}
  while {![eof $fi1] && ![eof $fi2]} {
    set line1 [gets_save $fi1]
    gets_save $fi1
    set line2 [gets_save $fi2]
    gets_save $fi2
    #puts $fo $line1
    #puts $fo $line2
    lappend out $line1
    lappend out $line2
  }
  set out [randomize_list $out]
  foreach line $out {
    if {$line != ""} {
      puts $fo $line   
    }
  }
  close $fo
  close $fi1
  close $fi2
}

# check if not eof, if so, read a line, if not, return ""
proc gets_save {f} {
  if {[eof $f]} {
    return ""
  } else {
    gets $f line
    return $line
  }
}

proc randomize_list {lst} {
  set lst2 {}
  foreach el $lst {
    lappend lst2 [list $el [expr rand()]]
  }
  set res {}
  foreach el [lsort -index 1 $lst2] {
    lappend res [lindex $el 0]
  }
  return $res
}

main