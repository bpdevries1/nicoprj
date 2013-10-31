##########################
# to libdaily.tcl
proc check_do_daily {db actiontype body} {
  $db in_trans {
    set sec_prev_dateuntil [det_prev_dateuntil $db $actiontype]
    if {$sec_prev_dateuntil == -1} {
      log info "Emtpy database, return"
      return
    }
    set sec_datefrom_cet [clock add $sec_prev_dateuntil 1 day]
    set datefrom_cet [clock format $sec_datefrom_cet -format "%Y-%m-%d"]
    
    set sec_last_dateuntil [det_last_dateuntil]
    set dateuntil_cet [clock format $sec_last_dateuntil -format "%Y-%m-%d"]
  
    # datefrom_cet and dateuntil_cet are both inclusive.
    if {$datefrom_cet <= $dateuntil_cet} {
      set ts_start_cet [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]
      uplevel $body
      set ts_end_cet [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]
      update_daily_status_db $db $actiontype $datefrom_cet $dateuntil_cet $ts_start_cet $ts_end_cet
    }
  }
}

proc det_prev_dateuntil {db actiontype} {
  set res [$db query "select dateuntil_cet from dailystatus where actiontype='$actiontype'"]
  if {[llength $res] == 1} {
    clock scan [:dateuntil_cet [lindex $res 0]] -format "%Y-%m-%d" 
  } else {
    set res [$db query "select min(date_cet) date from scriptrun"]
    log info "res: $res"
    if {[llength $res] == 1} {
      try_eval {
        set res2 -1
        set res2 [clock scan [:date [lindex $res 0]] -format "%Y-%m-%d"]
      } {
        log warn "det_prev_dateuntil: Error while parsing date: $res" 
      }
      return $res2
    } else {
      return -1
      # error "Empty scriptrun table" 
    }    
  }  
}

proc det_last_dateuntil {} {
  # 6*3600: don't start updating the day before too soon: all .json files need to be read.
  # @todo either don't determine daily stats before all 24 json files are read.
  # @todo or redo the calculations when a new file for a date is read.
  set sec_today [clock scan [clock format [expr [clock seconds] - 6*3600] -format "%Y-%m-%d"] -format "%Y-%m-%d"]
  set sec_yesterday [clock add $sec_today -1 days]
  return $sec_yesterday
}

proc update_daily_status_db {db actiontype datefrom_cet dateuntil_cet ts_start_cet ts_end_cet} {
  $db exec2 "delete from dailystatus where actiontype='$actiontype'"
  $db insert dailystatus [dict create dateuntil_cet $dateuntil_cet actiontype $actiontype]
  $db insert dailystatuslog [dict create ts_start_cet $ts_start_cet ts_end_cet $ts_end_cet \
    datefrom_cet $datefrom_cet dateuntil_cet $dateuntil_cet notes $actiontype]
}

