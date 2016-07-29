#!/usr/bin/env tclsh

package require ndv

proc main {argv} {
  global argv0
  set options {
    {line "Put all items for a row on a single line using ||"}
  }
  set usage "$argv0 \[options]"
  set opt [getoptions argv $options $usage]
  set oneline [:line $opt]
	# puts "\{| border=\"1\" cellspacing=\"0\""
  puts "\{| class=\"wikitable\""
  set lines [split [read stdin] "\n"]
  #set header [:0 $lines]
  #set ncols [puts_header $header]
  set rowchar "!"
  foreach line $lines {
    if {[string trim $line] == ""} {continue}
    set cells [split $line "\t"]
    # | aspect1 || a || b || c
    # TODO: anders als geen -line
    # [2016-07-29 22:12] Aanvullen van lege cellen lijkt niet meer nodig.
    if {$oneline} {
      puts "$rowchar [join $cells " || "]"      
    } else {
      # |Orange
      # |Apple
      puts "$rowchar [join $cells "\n$rowchar "]"      
    }

    set rowchar "|"
    puts "|-"
  }
	puts "|\}"
}

# [2016-07-29 21:48] Deze hieronder onduidelijk
# cmdtrace on [open cmd.log w]
main $argv
