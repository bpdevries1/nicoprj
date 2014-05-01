# libextra.tcl - called by extra_*.tcl lib-scripts.


# wrapper function to execute body for updating items.
# @param body is executed for each day, with var 'date_cet' set.
# @param tables delete data from these tables before updating data (wrt refreshing of data for new scatter-data loaded in DB)
# @pre dateuntil in dailystatus table is updated to the past when new run-data for a date is loaded.
proc check_do_daily {db actiontype tables body} {
  log info "check_do_daily - $actiontype: start"
  set ts_start_cet [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]
  set sec_prev_dateuntil [det_prev_dateuntil $db $actiontype]
  if {$sec_prev_dateuntil == -1} {
    log info "Emtpy database, return"
    return
  }
  $db in_trans {
    set sec_datefrom [clock add $sec_prev_dateuntil 1 day]
    set datefrom_cet [clock format $sec_datefrom -format "%Y-%m-%d"]
    foreach table $tables {
      $db exec2 "delete from $table where date_cet >= '$datefrom_cet'" 
    }
    set sec_last_dateuntil [det_last_dateuntil $db]
    set dateuntil_cet [clock format $sec_last_dateuntil -format "%Y-%m-%d"]
    if {$datefrom_cet <= $dateuntil_cet} {
      log info "doing actions for dates: $datefrom_cet => $dateuntil_cet"
    } else {
      log info "NOT doing actions for dates: $datefrom_cet => $dateuntil_cet, period empty"
    }
    set days_done 0
    set sec_date $sec_datefrom
    upvar date_cet date_cet ; # make date_cet available in $body
    # breakpoint
    while {$sec_date <= $sec_last_dateuntil} {
      set date_cet [clock format $sec_date -format "%Y-%m-%d"]
      # update_stats_date $db $subdir $sec_date
      # @todo check of dit zo werkt met $body.
      # @todo op level hoger de var date_cet een waarde geven. (wel eerder gedaan, check bv dict_to_vars)
      # mogelijk een keer de link definieren, en vervolgens in de loop steeds waarde updaten.
      uplevel $body
      set sec_date [clock add $sec_date 1 day]
      set days_done 1
    }
    set ts_end_cet [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]
    if {$days_done} {
      $db exec2 "delete from dailystatus where actiontype='$actiontype'"
      $db insert dailystatus [dict create dateuntil_cet $dateuntil_cet actiontype $actiontype]
      $db insert dailystatuslog [dict create ts_start_cet $ts_start_cet ts_end_cet $ts_end_cet \
        datefrom_cet $datefrom_cet dateuntil_cet $dateuntil_cet notes $actiontype]
    }
  }
  log info "check_do_daily - $actiontype: finished"
}

# wrapper function to execute body for updating items.
# @param body is executed for each day, with var 'date_cet' set.
# @param tables delete data from these tables before updating data (wrt refreshing of data for new scatter-data loaded in DB)
# @pre dateuntil in dailystatus table is updated to the past when new run-data for a date is loaded.
# this version doesn't handle actions per day, but all-in-one (eg with vacuum and analyze)
# @todo overlap (not DRY) with proc above, so reorg.
proc check_do_daily_allinone {db actiontype tables body} {
  # upvars for calling body and making vars available.
  upvar datefrom_cet datefrom_cet
  upvar dateuntil_cet dateuntil_cet
  log info "check_do_daily - $actiontype: start"
  # cannot VACUUM from within a transaction. So for now allinone version without transaction.
  set ts_start_cet [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]
  set sec_prev_dateuntil [det_prev_dateuntil $db $actiontype]
  if {$sec_prev_dateuntil == -1} {
    log info "Emtpy database, return"
    return
  }
  set sec_datefrom [clock add $sec_prev_dateuntil 1 day]
  set datefrom_cet [clock format $sec_datefrom -format "%Y-%m-%d"]
  $db in_trans {
    foreach table $tables {
      $db exec2 "delete from $table where date_cet >= '$datefrom_cet'" 
    }
  }
  set sec_last_dateuntil [det_last_dateuntil $db]
  set dateuntil_cet [clock format $sec_last_dateuntil -format "%Y-%m-%d"]
  if {$datefrom_cet <= $dateuntil_cet} {
    log info "doing actions for dates: $datefrom_cet => $dateuntil_cet"
    set notes [uplevel $body]
    if {$notes == ""} {
      set notes "$actiontype - no notes"
    }
    set ts_end_cet [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]
    $db in_trans {
      $db exec2 "delete from dailystatus where actiontype='$actiontype'"
      $db insert dailystatus [dict create dateuntil_cet $dateuntil_cet actiontype $actiontype]
      $db insert dailystatuslog [dict create ts_start_cet $ts_start_cet ts_end_cet $ts_end_cet \
        datefrom_cet $datefrom_cet dateuntil_cet $dateuntil_cet notes $notes]
    }
  } else {
    log info "NOT doing actions for dates: $datefrom_cet => $dateuntil_cet, period is empty"
  }
  log info "check_do_daily - $actiontype: finished"
}

# @result date (in sec) for which last updates were applied. 
proc det_prev_dateuntil {db actiontype} {
  set res [$db query "select dateuntil_cet from dailystatus where actiontype='$actiontype'"]
  if {[llength $res] == 1} {
    clock scan [:dateuntil_cet [lindex $res 0]] -format "%Y-%m-%d" 
  } else {
    # set res [$db query "select min(date_cet) date from scriptrun"]
    # 7-2-2014 select min(date) minus one day, so first (partial) day will also be handled.
    set res [$db query "select date(min(date_cet), '-1 day') date from scriptrun"]
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

# @result date (in sec) of last date to apply updates for (inclusive)
# @result (in sec) can be transformed to string with just clock format, not -gmt 1 needed, so basically in current timezone.
proc det_last_dateuntil {db} {
  # NOT: 24-12-2013 just determine last scriptrun read, with the newest date/time. 
  # 24-12-2013 don't use scriptrun, because with unknown run-frequency and periods of no testing (eg Mobile-CN) this might be off.
  # 24-12-2013 do use logfile, and when the last of a day has been read, it can be processed further.
  set qres [$db query "select max(filename) filename from logfile"]
  if {[llength $qres] == 1} {
    set filename [:filename [lindex $qres 0]]  
    # Mobile-landing-2013-12-24--10-00.json - in deze runs met datetime tussen 10 en 11 UTC, dus tussen 11 en 12 CET.
    if {[regexp -- {-(\d\d\d\d-\d\d-\d\d--\d\d-\d\d).json$} $filename z str_dt]} {
      return [det_dateuntil_from_strdt $str_dt]
    } else {
      # for now an error, while creating/debugging
      error "Cannot determine date/time from filename: $filename"
    }
  } else {
    # probably an empty DB, return an early date
    return [clock scan "2012-01-01" -format "%Y-%m-%d"]
  }
}

# pure functional, so easier to test.
# testcases:
# clock format [det_dateuntil_from_strdt "2013-12-23--21-00"] -format "%Y-%m-%d" => 2013-12-22
# clock format [det_dateuntil_from_strdt "2013-12-23--22-00"] -format "%Y-%m-%d" => 2013-12-23
# clock format [det_dateuntil_from_strdt "2013-12-23--23-00"] -format "%Y-%m-%d" => 2013-12-23
proc det_dateuntil_from_strdt {str_dt} {
  set sec_utc [clock scan $str_dt -gmt 1 -format "%Y-%m-%d--%H-%M"]
  # clock scan [clock format [clock add $sec_utc 1 hour -1 day] -format "%Y-%m-%d"] -format "%Y-%m-%d"
  # the same, because both scan and format use the same TZ:
  # add 1 hour to get the end time of the period, substract a day so the possible day 'fall-over' will be corrected.
  clock add $sec_utc 1 hour -1 day
}

# @result date (in sec) of last date to apply updates for (inclusive)
proc det_last_dateuntil_old {} {
  # 6*3600: don't start updating the day before too soon: all .json files need to be read.
  # @todo either don't determine daily stats before all 24 json files are read.
  # @todo or redo the calculations when a new file for a date is read.
  set sec_today [clock scan [clock format [expr [clock seconds] - 6*3600] -format "%Y-%m-%d"] -format "%Y-%m-%d"]
  set sec_yesterday [clock add $sec_today -1 days]
  return $sec_yesterday
}

# update dailystatus table with results of latest update
proc update_daily_status_db {db actiontype datefrom_cet dateuntil_cet ts_start_cet ts_end_cet} {
  $db exec2 "delete from dailystatus where actiontype='$actiontype'"
  $db insert dailystatus [dict create dateuntil_cet $dateuntil_cet actiontype $actiontype]
  $db insert dailystatuslog [dict create ts_start_cet $ts_start_cet ts_end_cet $ts_end_cet \
    datefrom_cet $datefrom_cet dateuntil_cet $dateuntil_cet notes $actiontype]
}

# possible that nothing is read, so last_read_date is today. Only update records which have date > last_read_date
proc reset_daily_status_db {db last_read_date} {
  log info "reset daily status db to day before $last_read_date: start"
  set date_before [clock format [clock add [clock scan $last_read_date -format "%Y-%m-%d"] -1 day] -format "%Y-%m-%d"]
  $db exec2 "update dailystatus set dateuntil_cet = '$date_before' where dateuntil_cet > '$date_before'" -log  
  log info "reset daily status db to day before $last_read_date: finished"
}
