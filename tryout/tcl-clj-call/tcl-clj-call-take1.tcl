#! /usr/bin/env tclsh

package require ndv

set_log_global info

proc main {argv} {
  global nprompt
  set nprompt 0
  set host localhost
  set port 5555
  set sock [socket $host $port]
  fconfigure $sock -blocking 0 -buffering none
  log debug "Created socket connection: $sock"
  set cmd "([join $argv " "])"
  puts $sock "$cmd"
  fileevent $sock readable [list print_text $sock]
  vwait forever
}

proc print_text {sock} {
  global nprompt
  set text [read $sock]
  if {[eof $sock]} {
    log debug "finishing connection"
    close $sock
    exit
  } else {
    # puts "\[#[string length $line], eof=[eof $sock]\]partial line: <<$line>>"
    # puts "\[#[string length $text], eof=[eof $sock]\]full text: <<$text>>"
    regsub {user=> } $text "" text2
    puts -nonewline $text2
    if {[regexp {(^|\n)user=> $} $text]} {
      incr nprompt
      log debug "Increased nprompt: $nprompt"
    } elseif {[regexp {user=>} $text]} {
      log debug "Found sort-of prompt"
      breakpoint
    }
  }
  if {$nprompt >= 2} {
    log debug "Found 2 prompts, exiting"
    close $sock
    exit
  }
}

main $argv

