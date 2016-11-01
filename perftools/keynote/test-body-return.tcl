package require ndv

# when uplevel body is used, a return in this body will return 'too much', so use identity as a 'return-function'

use libfp

proc main {} {
  puts "start-of-main"
  run_body "note1" {
    puts "In body"
    # return "Returned notes"
    # expr 123
    identity "string with 123"
  }
  puts "end-of-main"
}

proc run_body {note body} {
  puts "run_body: start"
  set notes [uplevel $body]
  puts "notes returned from body: $notes" 
  puts "run_body: finished"
}

main
