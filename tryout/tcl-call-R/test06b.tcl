#!/usr/bin/env tclsh86

package require Expect

proc main {} {
  # spawn /usr/bin/R
  spawn c:/develop/R/R-2.15.3/bin/R.exe
  set prompt "> " 
  expect $prompt
  set command "print(1:100000)"
  send   "$command\r" ;# send command
  after 1000
  send "flush(stdout)\r"
  send "flush(stderr)\r"
  after 1000
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

