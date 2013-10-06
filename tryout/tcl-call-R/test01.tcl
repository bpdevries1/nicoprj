#!/usr/bin/env tclsh86

package require Expect

# met deze niet hele output gelezen, na eerste regel vaak al klaar.
proc main {} {
  spawn bash
  expect "\$ "
  set command "ls -l"
  send   "$command\r" ;# send command
  expect "$command\r" ;# discard command echo
  expect -re "(.*)\r" ;# match and save the result
  set res0 $expect_out(0,string)
  set res1 $expect_out(1,string)
  set resb $expect_out(buffer)
  
  puts "res0: $res0"
  puts "res1: $res1"
  puts "resb: $resb"
  # exit
}

main
