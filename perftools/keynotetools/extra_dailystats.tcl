# extra_dailystats.tcl - sourced from scatter2db.tcl

proc extra_update_dailystats {db dargv subdir} {
  set scriptname [file tail $subdir]
  check_do_daily $db "dailystats" aggr_maxitem {
    # date_cet is set for each day to handle.
    log info "Determining dailystats (aggr_run/page) for: $date_cet"
    set nitems(0) 0
    set nitems(1) 0
    foreach row [$db query "select count(*) datacount, task_succeed_calc
                            from scriptrun r
                            where r.date_cet = '$date_cet'
                            group by 2"] {
      set nitems([:task_succeed_calc $row]) [:datacount $row]                          
    }
    set datacount [expr $nitems(0) + $nitems(1)]
    if {$datacount == 0} {
      set avail 0.0 
    } else {
      set avail [expr 1.0 * $nitems(1) / $datacount]
    }
    
    set total_time_sec 0.0
    set total_ttip_sec 0.0
    set run_avg_nkbytes 0.0
    set run_avg_nitems 0.0
    set npages 0
    foreach row [$db query "select 1*p.page_seq page_seq, count(*) datacount, avg(0.001*p.delta_user_msec) page_time_sec, 
                                   avg(0.001*p.time_to_interactive_page) page_ttip_sec, avg(0.001*p.page_bytes) avg_nkbytes,
                                   avg(1*p.element_count) avg_nitems
                            from page p
                              join scriptrun r on r.id = p.scriptrun_id
                            where r.date_cet = '$date_cet'
                            and 1*r.task_succeed_calc = 1
                            group by 1
                            order by 1"] {
       $db insert aggr_page [dict create scriptname $scriptname date_cet $date_cet \
         page_seq [:page_seq $row] avg_time_sec [format %.3f [:page_time_sec $row]] \
         avg_ttip_sec [format %.3f [:page_ttip_sec $row]] datacount [:datacount $row] \
         avg_nkbytes [format %.3f [:avg_nkbytes $row]] avg_nitems [format %.3f [:avg_nitems $row]]]
       set npages [:page_seq $row]
       set total_time_sec [expr $total_time_sec + [:page_time_sec $row]]
       set total_ttip_sec [expr $total_ttip_sec + [:page_ttip_sec $row]]
       set run_avg_nkbytes [expr $run_avg_nkbytes + [:avg_nkbytes $row]]
       set run_avg_nitems [expr $run_avg_nitems + [:avg_nitems $row]]
    }
    if {$npages == 0} {
      # @note no pages, no page stats (divide by 0)
      $db insert aggr_run [dict create scriptname $scriptname date_cet $date_cet \
        avg_time_sec [format %.3f $total_time_sec] \
        npages $npages avail [format %.3f $avail] datacount $datacount avg_ttip_sec [format %.3f $total_ttip_sec]]
    } else {
      $db insert aggr_run [dict create scriptname $scriptname date_cet $date_cet \
        avg_time_sec [format %.3f $total_time_sec] page_time_sec [format %.3f [expr $total_time_sec / $npages]] \
        npages $npages avail [format %.3f $avail] datacount $datacount avg_ttip_sec [format %.3f $total_ttip_sec] \
        page_ttip_sec [format %.3f [expr $total_ttip_sec / $npages]] \
        avg_nkbytes [format %.3f $run_avg_nkbytes] avg_nitems [format %.3f $run_avg_nitems]]
    }
  }
}

proc update_daily_stats_old {db subdir dargv min_date} {
  log info "update_daily_stats: start"
  set sec_min_date [clock scan $min_date -format "%Y-%m-%d"]
  set sec_prev_dateuntil [det_prev_dateuntil $db]
  if {$sec_prev_dateuntil == -1} {
    log info "Emtpy database, return"
    return
  }
  set sec_last_dateuntil [det_last_dateuntil]
  set dateuntil_cet [clock format $sec_last_dateuntil -format "%Y-%m-%d"]
  set sec_date [clock add $sec_prev_dateuntil 1 day]
  $db in_trans {
    if {$sec_min_date < $sec_date} {
      # @note last time updated too soon: remove calculations and do again
      log warn "Need to update stats from $min_date onwards"
      $db exec2 "delete from aggr_page where date_cet >= '$min_date'"
      $db exec2 "delete from aggr_run where date_cet >= '$min_date'"
      set sec_date $sec_min_date
    }
    set datefrom_cet [clock format $sec_date -format "%Y-%m-%d"]
    set ts_start_cet [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]
    set days_done 0
    while {$sec_date <= $sec_last_dateuntil} {
      update_stats_date $db $subdir $sec_date
      set sec_date [clock add $sec_date 1 day]
      set days_done 1
    }
    set ts_end_cet [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]
    if {$days_done} {
      if {[:updatemaxitem $dargv]} {
        # breakpoint
        update_maxitem $db [:maxitem $dargv]
      }
      $db exec2 "delete from dailystatus where actiontype='general'"
      $db insert dailystatus [dict create dateuntil_cet $dateuntil_cet actiontype "general"]
      $db insert dailystatuslog [dict create ts_start_cet $ts_start_cet ts_end_cet $ts_end_cet \
        datefrom_cet $datefrom_cet dateuntil_cet $dateuntil_cet notes "Basic stats"]
    }
  }
  log info "update_daily_stats: finished"
}

proc det_prev_dateuntil_old {db} {
  set res [$db query "select dateuntil_cet from dailystatus where actiontype='general'"]
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
  
proc det_last_dateuntil_old {} {
  # 6*3600: don't start updating the day before too soon: all .json files need to be read.
  # @todo either don't determine daily stats before all 24 json files are read.
  # @todo or redo the calculations when a new file for a date is read.
  set sec_today [clock scan [clock format [expr [clock seconds] - 6*3600] -format "%Y-%m-%d"] -format "%Y-%m-%d"]
  set sec_yesterday [clock add $sec_today -1 days]
  return $sec_yesterday
}

proc update_stats_date_old {db subdir sec_date} {
  set date_cet [clock format $sec_date -format "%Y-%m-%d"]
  log info "Update_stats_date: $date_cet" 
  set scriptname [file tail $subdir]
  set nitems(0) 0
  set nitems(1) 0
  foreach row [$db query "select count(*) datacount, task_succeed_calc
                          from scriptrun r
                          where r.date_cet = '$date_cet'
                          group by 2"] {
    set nitems([:task_succeed_calc $row]) [:datacount $row]                          
  }
  set datacount [expr $nitems(0) + $nitems(1)]
  if {$datacount == 0} {
    set avail 0.0 
  } else {
    set avail [expr 1.0 * $nitems(1) / $datacount]
  }
  
  set total_time_sec 0.0
  set total_ttip_sec 0.0
  set npages 0
  foreach row [$db query "select 1*p.page_seq page_seq, count(*) datacount, avg(0.001*p.delta_user_msec) page_time_sec, 
                                 avg(0.001*p.time_to_interactive_page) page_ttip_sec
                          from page p
                            join scriptrun r on r.id = p.scriptrun_id
                          where p.date_cet = '$date_cet'
                          and 1*r.task_succeed_calc = 1
                          group by 1
                          order by 1"] {
     $db insert aggr_page [dict create scriptname $scriptname date_cet $date_cet \
       page_seq [:page_seq $row] page_time_sec [format %.3f [:page_time_sec $row]] \
       page_ttip_sec [format %.3f [:page_ttip_sec $row]] datacount [:datacount $row]]
     set npages [:page_seq $row]
     set total_time_sec [expr $total_time_sec + [:page_time_sec $row]]
     set total_ttip_sec [expr $total_ttip_sec + [:page_ttip_sec $row]]
  }
  if {$npages == 0} {
    # @note no pages, no page stats (divide by 0)
    $db insert aggr_run [dict create scriptname $scriptname date_cet $date_cet \
      total_time_sec [format %.3f $total_time_sec] \
      npages $npages avail [format %.3f $avail] datacount $datacount total_ttip_sec [format %.3f $total_ttip_sec]]
  } else {
    $db insert aggr_run [dict create scriptname $scriptname date_cet $date_cet \
      total_time_sec [format %.3f $total_time_sec] page_time_sec [format %.3f [expr $total_time_sec / $npages]] \
      npages $npages avail [format %.3f $avail] datacount $datacount total_ttip_sec [format %.3f $total_ttip_sec] \
      page_ttip_sec [format %.3f [expr $total_ttip_sec / $npages]]]
  }
}


