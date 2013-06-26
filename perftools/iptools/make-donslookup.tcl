#!/usr/bin/env tclsh86

# read list of domains from stdin, make shell script to do nslookup to stdout

proc main {} {
  puts "rm donslookup.out"
  while {![eof stdin]} {
    gets stdin line
    if {$line == ""} {
      continue 
    }
    puts "echo nslookup for: $line >> donslookup.out"
    puts "nslookup $line >> donslookup.out"
  }
}

main
