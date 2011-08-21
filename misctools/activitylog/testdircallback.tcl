package require twapi

proc change_cb {args} {
  puts "something changed: $args" 
}

proc main {} {
  set mon_id [twapi::begin_filesystem_monitor "c:/aaa" change_cb -access 1 -size 1 -subtree 1 -write 1 -create 1 -dirname 1 -filename 1]
  # set mon_id [twapi::begin_filesystem_monitor "c:/aaa" change_cb -write true]
  # vwait forever
  while {1} {
    after 5000
    puts "waited 5 seconds"
    update ; # handle events, such as the filesystem monitor. This works better than vwait, as the other tasks in the main script can still be done.   
  }
}

main
