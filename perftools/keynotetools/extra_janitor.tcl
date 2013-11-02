# extra-janitor - called by libextraprocessing.tcl (vacuum and analyze)

# @todo iets om vacuum maar eens in de week/maand te doen, mss vgl maxitem. Bv datum na actie week in de toekomst zetten.
# iig niet elke dag de datum vooruit schuiven, dan kom je er niet meer aan toe.
proc extra_update_vacuum {db dargv subdir} {
  check_do_daily_allinone $db "vacuum" {} {
    $db exec2 "vacuum" -log    
  }
}

proc extra_update_analyze {db dargv subdir} {
  check_do_daily_allinone $db "analyze" {} {
    $db exec2 "analyze" -log
  }
}

