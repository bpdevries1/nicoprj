# extra-janitor - called by libextraprocessing.tcl (vacuum and analyze)

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

