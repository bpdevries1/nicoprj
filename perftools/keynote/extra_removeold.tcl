# extra-removeold.tcl - called by libextraprocessing.tcl (remove pageitem records older than 6 weeks)

proc extra_update_removeold {db dargv subdir} {
  check_do_daily_allinone $db "removeold" {} {
    # datefrom_cet and dateuntil_cet are available.
    # only need dateuntil_cet here, remove all records from pageitem that are older than dateuntil - 6 weeks.
    set date_treshold [det_date_treshold_removeold $dateuntil_cet]
    $db exec2 "delete from pageitem where date_cet < '$date_treshold'" -log -try
    identity "Removeold - $dateuntil_cet"
  }
}

proc det_date_treshold_removeold {dateuntil_cet} {
  clock format [clock add [clock scan $dateuntil_cet -gmt 0 -format "%Y-%m-%d"] -6 weeks] -format "%Y-%m-%d"
}
