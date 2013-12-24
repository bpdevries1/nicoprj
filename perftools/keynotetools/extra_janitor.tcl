# extra-janitor - called by libextraprocessing.tcl (vacuum and analyze)

# @todo iets om vacuum maar eens in de week/maand te doen, mss vgl maxitem. Bv datum na actie week in de toekomst zetten.
# iig niet elke dag de datum vooruit schuiven, dan kom je er niet meer aan toe.
proc extra_update_vacuum {db dargv subdir} {
  check_do_daily_allinone $db "vacuum" {} {
    # datefrom_cet and dateuntil_cet are available.
    # @todo if vacuum-ing all databases in weekend takes too long, then only do it for some, based on random-var.
    # @todo and possibly also based on the last time it was really done (check in log-table?)
    if {[in_weekend? $dateuntil_cet]} {
      $db exec2 "vacuum" -log
      identity "Vacuum - really done in weekend - $dateuntil_cet"
    } else {
      identity "Vacuum - not really done during week - $dateuntil_cet"
    }
  }
}

proc in_weekend? {date} {
  # when run early saturday morning, the date_until is set to friday.
  # and on sunday it's set to saturday.
  # so the weekday has to be friday or saturday.
  set dow [clock format [clock scan $date -format "%Y-%m-%d"] -format "%u"]
  if {($dow == 5) || ($dow == 6)} {
    return 1
  } else {
    return 0
  }
}

proc extra_update_analyze {db dargv subdir} {
  check_do_daily_allinone $db "analyze" {} {
    $db exec2 "analyze" -log
  }
  identity "Analyse - $dateuntil_cet"
}

