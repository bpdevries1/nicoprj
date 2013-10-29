# dailystats.tcl - sourced from scatter2db.tcl

proc update_daily_stats {db subdir} {
  log info "update_daily_stats: start"
  set sec_prev_dateuntil [det_prev_dateuntil $db]
  set sec_last_dateuntil [det_last_dateuntil]
  set dateuntil_cet [clock format $sec_last_dateuntil -format "%Y-%m-%d"]
  set sec_date [clock add $sec_prev_dateuntil 1 day]
  set datefrom_cet [clock format $sec_date -format "%Y-%m-%d"]
  set ts_start_cet [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]
  $db in_trans {
    set days_done 0
    while {$sec_date <= $sec_last_dateuntil} {
      update_stats_date $db $subdir $sec_date
      set sec_date [clock add $sec_date 1 day]
      set days_done 1
    }
    set ts_end_cet [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]
    if {$days_done} {
      $db exec2 "delete from dailystatus"
      $db insert dailystatus [dict create dateuntil_cet $dateuntil_cet]
      $db insert dailystatuslog [dict create ts_start_cet $ts_start_cet ts_end_cet $ts_end_cet \
        datefrom_cet $datefrom_cet dateuntil_cet $dateuntil_cet notes "Basic stats"]
    }
  }
  log info "update_daily_stats: finished"
}

proc det_prev_dateuntil {db} {
  set res [$db query "select dateuntil_cet from dailystatus"]
  if {[llength $res] == 1} {
    clock scan [:dateuntil_cet [lindex $res 0]] -format "%Y-%m-%d" 
  } else {
    set res [$db query "select min(date_cet) date from scriptrun"]
    if {[llength $res] == 1} {
      clock scan [:date [lindex $res 0]] -format "%Y-%m-%d"
    } else {
      error "Empty scriptrun table" 
    }    
  }  
}

proc det_last_dateuntil {} {
  set sec_today [clock scan [clock format [clock seconds] -format "%Y-%m-%d"] -format "%Y-%m-%d"]
  set sec_yesterday [clock add $sec_today -1 days]
  return $sec_yesterday
}

proc update_stats_date {db subdir sec_date} {
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
  set avail [expr 1.0 * $nitems(1) / $datacount]
  
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

