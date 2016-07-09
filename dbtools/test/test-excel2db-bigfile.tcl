#!/usr/bin/env tclsh861

# test some options of excel2db.tcl
package require ndv
require libdatetime dt

source ../excel2db.tcl

proc test_main {} {
  set dir "/tmp/test-excel2db"
  create_big_file $dir
  from_tsv $dir
  # TODO: voor urenlog wordt deze ook gebruikt, dus is ook een test case, wel alleen windows.  
}

proc create_big_file {dir} {
  file mkdir $dir  
  set tsv_name [file join $dir "testbig.tsv"]
  if {[file exists $tsv_name]} {
    # should be at least 100MiB. Size nog bijwerken na eerste keer aanmaken.
    if {[file size $tsv_name] >= 50e6} {
      puts "Big file already exists"
      return
    }
  }
  set f [open $tsv_name w]
  puts $f "ts\tvalue"
  set value 1
  # [2016-07-09 11:20] On linux no failure for 1M lines, have more memory, do see it increasing.
  set nlines 1e7
  for {set i 0} {$i < $nlines} {incr i} {
    puts $f "[dt/now]\t$i"
    if {$i % 100000 == 0} {
      puts "[dt/now] - Written $i lines"
    }
  }
  close $f
}

# [2016-07-09 11:28] reproduced sort-of, system becomes unresponsive:
#[2016-07-09 11:26:14 +0200] [excel2db.tcl] [info] Committing after 2000000 lines
#[2016-07-09 11:26:21 +0200] [excel2db.tcl] [info] Committing after 2100000 lines
#[2016-07-09 11:26:28 +0200] [excel2db.tcl] [info] Committing after 2200000 lines
#[2016-07-09 11:26:39 +0200] [excel2db.tcl] [info] Committing after 2300000 lines

# [2016-07-09 11:42] and again, after similar number of items:
#[2016-07-09 11:40:48 +0200] [excel2db.tcl] [info] Committing after 2000000 lines
#[2016-07-09 11:40:55 +0200] [excel2db.tcl] [info] Committing after 2100000 lines
#[2016-07-09 11:41:03 +0200] [excel2db.tcl] [info] Committing after 2200000 lines

# insert-single-line helemaal niet aanroepen:
# [2016-07-09 13:10] Dan gaat wel goed en snel, dus probleem zit binnen de insert-single-line.
# zonder stmt_insert:
# [2016-07-09 13:18] ook goed, geheugen blijft keurig op 211 000 KB.


proc from_tsv {dir} {
  # handle_dir $dir auto auto 1 100000 {singlelines 0}
  # [2016-07-09 11:29] singlelines=1 should work better, but does not.
  # handle_dir $dir auto auto 1 100000 {singlelines 0}
  set deletedb 1
  handle_dir $dir auto auto $deletedb {singlelines 1 commitlines 100000}

  # TODO: code om te testen of DB is gemaakt, en evt ook een query uitvoeren.


}

test_main

