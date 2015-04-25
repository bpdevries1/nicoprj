#!/usr/bin/expect

# deze heeft Tcl8.6, mooi.

# goal: answer . to all unison questions about props.
# all other questions must be answered by user.

set LOG_STDOUT 0 ; # log all stuff to stdout? If 0, only log to files.

proc main {argv} {
  # strange things happen with global vars.
  # global interact_out expect_out
  
  file delete "expect.log"
  file delete "expect.stdout"
  
  spawn unison $argv

  set timeout 300 ; # 5 minutes should be enough, even for NAS 1TB.
  set timeout 60 ; # for testing
  
  log "Beginning of while"
  
  set i 0
  set found_eof 0
  while {1} {
    log "Expecting line... ($i)"

    # don't start a match with a newline, just end with it possibly.
    expect {
      eof    {
        log "Found eof, so break"
        set found_eof 1
        break
      }
      -re "props    <-\\?-> props \[^\r\n\]* \\\[\\\] " {
        log_array "Found props, sending ." expect_out
        send "."
      }
      {\? \[\] } {
        # question mark at the end
        log_array "Found a question1" expect_out
        interact_1key $spawn_id
      }
      { <-\?-> } {
        # also question mark
        log_array "Found a question2" expect_out
        interact_1key $spawn_id
      }
      {  \[f\] } {
        # question with suggestion
        log_array "Found a question3 (with suggestion)" expect_out
        interact_1key $spawn_id
      }
      {\[<spc>\] } {
        # question with suggestion
        log_array "Found a question4 (with suggestion)" expect_out
        interact_1key $spawn_id
      }
      
      # could also check for [] at the end, but this could be part of a filename.
      # something else is a whole line: start with newline, everything but a newline, finish with newline.
      # just look for the CR (\r), newline (\n) is not always given, eg with unison which replacing lines on stdout using \r.
      -re "\[^\r\n\]*\r" {
        log_array "Found something else, continuing..." expect_out
      }
      timeout {
        log_array "Timeout" expect_out
        # should check user if (s)he wants to wait some more.
        # break
        if {[check_continue $spawn_id]} {
          log "User chooses to wait some more"
          send_user "<<<Waiting some more>>>"
        } else {
          log "User chooses to quit"
          break
        }
      }
    }
    incr i
  }
  if {$found_eof} {
    # log "Found eof, so finished"    
  } else {
    send_user "<<<Didn't end correctly, maybe a timeout>>>"
    log "sleeping for 5 seconds..."
    # sleep 5 seconds for now, so unison can process.
    sleep 5;                    

    log "Loop ended, getting all text until now"
    expect "*" {log_array "everything" expect_out}
  }

  # log "script ended"
}

proc interact_1key {spawn_id} {
  # global interact_out expect_out
  # [] have special meaning in glob patterns as well.
  
  log "sending question mark to get a list of options"
  send_user "\n  c                     Continue (don't send anything to Unison)\n"
  send "?"
  # interact steeds 1 teken. Want hierna zou weer een props regel kunnen komen.
  # vraag of deze ook een timeout krijgt, zou niet moeten.
  interact {
    c {
      log_array "User typed a c, don't send to app, continue" interact_out
      send_user "<<<continuing>>>"
      return
    }
    -re "." {
      log_array "User typed 1 key, sending to app" interact_out
      send $interact_out(0,string)
      # return from interact
      return
    }
  }
  log "end of interact_1key"
}

# return 1 if user chooses to continue (waiting), 0 otherwise.
proc check_continue {spawn_id} {
  set res 0
  send_user "\nTimed out waiting, do you want to wait some more? [] "
  interact {
    y {
      log "User typed y"
      send_user "<<<ok, waiting some more>>>"
      set res 1
      return
    }
    n {
      log "User typed n"
      send_user "<<<ok, quitting>>>"
      set res 0
      return
    }
  }
  return $res
}

proc log {str} {
  global LOG_STDOUT
  set f [open "expect.log" a]
  puts $f "\[[clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]\] $str"
  close $f
  if {$LOG_STDOUT} {
    puts "\n***$str***"
  }
}

proc log_array {prefix array_name} {
  upvar $array_name ar
  log $prefix
  log "Contents of array $array_name:"
  foreach el [lsort [array names ar]] {
    log "      <<<$el = $ar($el)>>>"
  }
  log "End of array"

  if {$array_name == "expect_out"} {
    set fs [open "expect.stdout" a]
    puts -nonewline $fs $ar(buffer)
    close $fs
  }
}

main $argv
