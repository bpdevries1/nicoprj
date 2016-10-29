#!/usr/bin/env tclsh861

# test some options of excel2db.tcl
source ../excel2db.tcl

proc test_main {} {
  from_tsv
  # TODO: voor urenlog wordt deze ook gebruikt, dus is ook een test case, wel alleen windows.  
}

proc from_tsv {} {
  set dir "/tmp/test-excel2db"
  file mkdir $dir
  set tsv_name [file join $dir "test.tsv"]
  set f [open $tsv_name w]
  puts $f "name\tvalue\tstring"
  puts $f "bean\t12.12\tbin, met komma."
  puts $f "java\t3.14\tthat's pi"
  close $f

  excel2db::handle_dir $dir auto auto 1 {}

  # TODO: code om te testen of DB is gemaakt, en evt ook een query uitvoeren.


}

test_main

