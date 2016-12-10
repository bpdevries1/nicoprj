#! /usr/bin/env tclsh

package require ndv

set_log_global info

# nostart optie toevoegen.
proc main {argv} {
  global nprompt WINDOWS tcl_platform
  set options {
    {nostart "Don't start a new REPL"}
    {restart "Stop current REPL and start a new one."}
    {timeout.arg "60" "Timeout in seconds"}
  }
  set opt [getoptions argv $options ""]
  set nprompt 0
  set host localhost
  set port 5555
  if {$tcl_platform(platform) == "windows"} {
    set WINDOWS 1
  } else {
    set WINDOWS 0
  }
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
  global WINDOWS
  if {$WINDOWS} {
    kill_repl_windows
  } else {
    kill_repl_unix
  }
}

# ook eerst proberen het proces netjes te stoppen: connecten en exit command? Of ctrl-D doorgeven?
proc kill_repl_windows {} {
  set res ""
  catch {
    set res [exec -ignorestderr netstat -ano | grep 5555]  
  }
  log debug "res: $res"
  # breakpoint
  if {[regexp {LISTENING\s+(\d+)} $res z pid]} {
    puts "Killing proces with id: $pid"
    # exec kill -9 $pid
    # [2016-12-10 20:59:13] note that /F(orce) is needed
    exec TASKKILL /PID $pid /T /F
    puts "Now sleeping for 10 seconds..."
    after 10000
    puts "And restart..."
  } else {
    puts "REPL was not started, so just starting a new one."
  }

  # breakpoint
}

proc kill_repl_unix {} {
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
  global WINDOWS
  if {$WINDOWS} {
    start_repl_windows
  } else {
    start_repl_unix
  }
}

proc start_repl_windows {} {
  global env
  # start lein repl in the background.
  set old_pwd [pwd]
  # TODO: different on windows.

  # TODO: scrabble doet het wel even, maar stopt daarna weer, nrepl foutmelding.
  # testrepl lijkt het wat beter te doen, maar ook wat langer wachten tussen aanroepen.
  # cd ~/nicoprjbb/sporttools/scrabble
  # this info should be set in a config file. For buildtool in .bld dir, for generic scripting maybe an ENV var.
  cd c:/nico/nicoprjbb/sporttools/testrepl
  log debug "Starting Repl (1)"
  # exec -ignorestderr ~/bin/lein repl :headless &
  # met nohup moet je wel ~ uitklappen.
  # c:\util\cygwin\bin\nohup.exe cmd.exe /c c:\users\ndvreeze\.lein\bin\lein.bat repl :headless
  set env(LEIN_JAVA_CMD) {C:\develop\Java\jdk1.8.0_05\bin\java.exe}
  exec -ignorestderr {c:\util\cygwin\bin\nohup.exe} {c:\windows\system32\cmd.exe} /c {c:\users\ndvreeze\.lein\bin\lein.bat} repl :headless &
  
  # onder cygwin:
  # env(JAVA_CMD)                = /c/develop/Java/jdk1.8.0_05/bin/java.exe
  # env(JAVA_HOME)               = /c/develop/java/jdk1.6.0_14
  # env(LEIN_JAVA_CMD)           = /c/develop/Java/jdk1.8.0_05/bin/java.exe
  
  # onder 4NT:
  # env(JAVA_HOME)               = c:\develop\java\jdk1.6.0_14
  # env(JAVA_ROOT)               = c:\develop\java
  # env(LEIN_JAVA_CMD)           = C:\develop\Java\jdk1.8.0_05\bin\java.exe
  # wat dingen proberen.
  #set lein_bat {c:\users\ndvreeze\.lein\bin\lein.bat}
  #exec -ignorestderr {c:\windows\system32\cmd.exe} /c {c:\Users\ndvreeze\.lein\bin\lein.bat} repl :headless
  # -> 2x path not found.
  # cmd.exe kan 'ie wel vinden.
  #exec -ignorestderr {c:\windows\system32\cmd.exe} /c $lein_bat repl :headless
  
  log debug "Starting Repl (2)"
  # exit
  cd $old_pwd
}

proc start_repl_unix {} {
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
    if {[regexp {user} $text2]} {
      puts "Still user found: $text2"
      breakpoint
    }
    puts -nonewline "$text2"
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

