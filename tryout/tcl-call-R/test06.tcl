#!/usr/bin/env tclsh86

package require Expect

proc main {} {
  spawn /usr/bin/R
  set prompt "> " 
  expect $prompt
  set command "print(1:100000)"
  send   "$command\r" ;# send command
  expect "$command\r" ;# discard command echo
  set output ""
  set lineterminationChar "\r"
  expect {
    $lineterminationChar   { append output $expect_out(buffer);exp_continue}
    $prompt                { append output $expect_out(buffer)} 
    eof                    { append output $expect_out(buffer)}
  }
  set res $output
  puts "res: \n===\n$res\n==="
}

main

