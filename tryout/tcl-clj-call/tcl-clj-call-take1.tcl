#! /usr/bin/env tclsh

package require ndv

set_log_global debug

# nostart optie toevoegen.
proc main {argv} {
  global nprompt
  set options {
    {nostart "Don't start a new REPL"}
    {restart "Stop current REPL and start a new one."}
  }
  set opt [getoptions argv $options ""]
  set nprompt 0
  set host localhost
  set port 5555
  if {[:restart $opt]} {
    kill_repl
    start_repl
  }

  set cmdstr [join $argv " "] 
  if {[string trim $cmdstr] == ""} {
    puts "No command given, exiting"
    exit
  } else {
    log debug "About to exec: <<$cmdstr>>"
  }
  set cmd "($cmdstr)"  
  if {[catch {set sock [socket $host $port]}]} {
    if {[:nostart $opt]} {
      puts "Repl not started and -nostart given, so exit"
      exit
    }
    if {![:restart $opt]} {
      start_repl  
    } else {
      # already restarted, don't try again, now just wait for connection.
    }
    
    set connected 0
    while {!$connected} {
      log debug "Wait 1 second and try to connect..."
      after 1000
      catch {
        set sock [socket $host $port]
        set connected 1
      }
    }
    log debug "Got connection, waiting another 5 seconds"
    after 5000
  }
  fconfigure $sock -blocking 0 -buffering none
  log debug "Created socket connection: $sock"
  puts $sock "$cmd"
  fileevent $sock readable [list print_text $sock]
  vwait forever
}

proc kill_repl {} {
  set res ""
  catch {
    set res [exec -ignorestderr netstat -anp | grep 5555]  
  }
  log debug "res: $res"
  if {[regexp {LISTEN\s+(\d+)/java} $res z pid]} {
    puts "Killing proces with id: $pid"
    exec kill -9 $pid
    puts "Now sleeping for 10 seconds..."
    after 10000
    puts "And restart..."
  } else {
    puts "REPL was not started, so just starting a new one."
  }

  # breakpoint
}

proc start_repl {} {
  # start lein repl in the background.
  set old_pwd [pwd]
  # TODO: different on windows.

  # TODO: scrabble doet het wel even, maar stopt daarna weer, nrepl foutmelding.
  # testrepl lijkt het wat beter te doen, maar ook wat langer wachten tussen aanroepen.
  # cd ~/nicoprjbb/sporttools/scrabble
  cd ~/nicoprjbb/sporttools/testrepl
  log debug "Starting Repl (1)"
  # exec -ignorestderr ~/bin/lein repl :headless &
  # met nohup moet je wel ~ uitklappen.
  exec -ignorestderr nohup [file normalize ~/bin/lein] repl :headless &
  log debug "Starting Repl (2)"
  # exit
  cd $old_pwd
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
    # now exit the nice way
    puts $sock ":repl/quit"
    #close $sock
    #exit
  }
}

main $argv

