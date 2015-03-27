#!/usr/bin/expect

# deze heeft Tcl8.6, mooi.

# goal: answer . to all unison questions about props.

# TODO interact mode werkend:
# ofwel je blijft erin tot het einde.
# ofwel je kunt (bv met een + weer terug naar automatische verwerking, nu niet echt nodig)

proc main {argv} {

  file delete "expect.log"
  file delete "expect.stdout"
  # test_array_log

  
  log "Spawning $argv"
  spawn unison $argv
  log "Spawned $argv"
  
  log "Phase 1"
  # phase 1 - start and finding changes
  while 1 {
    log "Expecting line..."
    expect {
      eof    {break}
      "Press return to continue." {log_array "=> sending newline" expect_out; send "\n"}
      "Reconciling changes" {log_array "Found Reconciling changes => next phase" expect_out; break}
    }
  }

  #log "waiting 5 secs"
  #after 5000
  #log "waited enough"

  log_array "Phase 2 now" expect_out
  # phase 2 - interactively handle changes

  # test
  # send "."

  set timeout 3
  log_array "Beginning of while" expect_out
  
  set i 0
  set found_eof 0
  while {1} {
    #log "expect_out:"
    
    #log "end of expect_out"
    log "Expecting line... ($i)"
    # interact +
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
        # [] have special meaning in glob patterns as well.
        log_array "1. Found question mark at the end" expect_out
        log "sending question mark to get a list of options"
        send "?"
        log "Should go into interactive mode now..."
        set spawn_id $expect_out(spawn_id)
        log "spawn_id: $spawn_id"
        log "start of interact"
        # interact steeds 1 teken. Want hierna zou weer een props regel kunnen komen.
        interact {
          -re "." {
            log_array "User typed 1 key, sending to app" interact_out
            send $interact_out(0,string)
            #log "sending y"
            #send "y"
            # send -i $spawn_id "y"
            # TODO als dit niet werkt, dan interact in de expect struct zetten.
            # lijkt wel iets anders te doen, mogelijk toch in andere scope.
            
            # send this character and continue with loop.
            # cannot do break, this is not a loop.
            # break ; # needed because stays in a loop.
            log "Just before interact/return"
            return ; # does this return from interact, or from main function? YES: from interact only, as expected and wanted.
          }
        }
        log "Just after interact/return" ; # this one is logged, so return works ok.
        # wil eigenlijk geen break hier, nu nog even wel.
        # break
      }
      # something else is a whole line: start with newline, everything but a newline, finish with newline.
      -re "\[^\r\n\]*\r\n" {
        # log_array "Found something else, so interactive, end with +" expect_out
        log_array "Found something else, continuing..." expect_out
      }
      timeout {
        log_array "Timeout, break" expect_out
        # interact "+"
        break
      }
    }
    incr i
  }
  # check_question_marks
  if {$found_eof} {
    log "Found eof, so finished"    
  } else {
    log "sleeping for 5 seconds..."
    # sleep 5 seconds for now, so unison can process.
    sleep 5;                    

    log "Loop ended, getting all text until now"
    expect "*" {log_array "everything" expect_out}
  }

  if {0} {
    set spawn_id $expect_out(spawn_id)
    log "spawn_id: $spawn_id"
    log "start of interact"
    # interact steeds 1 teken. Want hierna zou weer een props regel kunnen komen.
    interact {                   
      -re "." {                  
        log_array "User typed 1 key, sending to app" interact_out
        # send $interact_out(0,string)
        log "sending y"
        send "y";                
        # send -i $spawn_id "y"
        # TODO als dit niet werkt, dan interact in de expect struct zetten.

        # send this character and continue with loop.
        # cannot do break, this is not a loop.
        # break ; # needed because stays in a loop.
        return ; # does this return from interact, or from main function?
      };          
    };            

    log "sleeping for 5 seconds..."
    # sleep 5 seconds for now, so unison can process.
    sleep 5;                    
    
    log "end of interact, getting all text"
    # 
    expect "*" {log_array "everything2" expect_out}
  }  
  # log "No interactive now, just end"
  #log "Loop ended, going into interactive mode"
  #interact +
  log "script ended"
}

proc check_question_marks {} {
  log "Checking question marks"
  # test hier of je alsnog een vraagteken vindt.
  expect {
    "\\?" {
      log_array "Found question mark (Glob) somewhere" expect_out
      # break
    }
    -re "\[?\]" {
      log_array "Found question mark (RE) somewhere" expect_out
      # break
    }
  }

  log "end of checking question marks"
}

proc log {str} {
  set f [open "expect.log" a]
  puts $f $str
  close $f
  puts "\n***$str***"
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

proc send_not {args} {
  log "send_not: $args"
}

proc test_array_log {} {
  set ta(1) 2
  set ta(2) 42
  log_array ta
  exit
}

main $argv
