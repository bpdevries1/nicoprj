#!/usr/bin/env tclsh86

# nanny2-test.tcl - test scripts for nanny2.tcl

proc main {} {
  # notepad starten met testfile.txt, deze testfile ook voor check gebruiken.
  # zolang je typt, gaat het goed, anders wordt 'ie herstart.
  set f [open nanny2-test.txt w]
  puts $f "Test of nanny2.tcl, type and stop typing."
  close $f
  exec tclsh86 nanny2.tcl -checkfile nanny2-test.txt -timeout 30 c:/Windows/system32/notepad nanny2-test.txt >&@ stdout
}

main
