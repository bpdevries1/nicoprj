# extra_dailystats.tcl - sourced from scatter2db.tcl

proc extra_update_dailystats {db dargv subdir} {
  set scriptname [file tail $subdir]
  # 23-11-2013 Bugfix: clear aggr_run and aggr_page before handling.
  check_do_daily $db "dailystats" {aggr_run aggr_page} {
    # date_cet is set for each day to handle.
    log info "Determining dailystats (aggr_run/page) for: $date_cet"
    # 23-11-2013 two statements below should not be necessary.
    #$db exec2 "delete from aggr_run where date_cet = '$date_cet'"
    #$db exec2 "delete from aggr_page where date_cet = '$date_cet'"
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
    # @note 23-11-2013 zou eigenlijk geen avg moeten gebruiken, maar sum()/#runs, maar maakt hier weinig uit.
    # 21-2-2014 also query items where task_succeed = 0, occurs for US-test CQ5 script in CN that all day there are no good results, but do want some stats, like #npages.
    foreach row [$db query "select 1*p.page_seq page_seq, p.page_type page_type, r.task_succeed_calc task_succeed, count(*) datacount, 
                                   avg(0.001*p.delta_user_msec) page_time_sec, 
                                   avg(0.001*p.time_to_interactive_page) page_ttip_sec, avg(0.001*p.page_bytes) avg_nkbytes,
                                   avg(1*p.element_count) avg_nitems
                            from page p
                              join scriptrun r on r.id = p.scriptrun_id
                            where r.date_cet = '$date_cet'
                            group by 1,2,3
                            order by 1,2,3"] {
      set npages [:page_seq $row]
      if {[:task_succeed $row] == 1} {
        $db insert aggr_page [dict create scriptname $scriptname date_cet $date_cet \
           page_seq [:page_seq $row] page_type [:page_type $row] avg_time_sec [format %.3f [:page_time_sec $row]] \
           avg_ttip_sec [format %.3f [:page_ttip_sec $row]] datacount [:datacount $row] \
           avg_nkbytes [format %.3f [:avg_nkbytes $row]] avg_nitems [format %.3f [:avg_nitems $row]]]
        
        set total_time_sec [expr $total_time_sec + [:page_time_sec $row]]
        set total_ttip_sec [expr $total_ttip_sec + [:page_ttip_sec $row]]
        set run_avg_nkbytes [expr $run_avg_nkbytes + [:avg_nkbytes $row]]
        set run_avg_nitems [expr $run_avg_nitems + [:avg_nitems $row]]
      } else {
        # nothing for now
      }
    }
    if {$npages == 0} {
      # @note no pages, no page stats (divide by 0)
      # 21-2-2014 should not occur anymore.
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
    identity "dailystats - $date_cet"                 
  }
}

proc extra_update_dailystats_old {db dargv subdir} {
  set scriptname [file tail $subdir]
  # 23-11-2013 Bugfix: clear aggr_run and aggr_page before handling.
  check_do_daily $db "dailystats" {aggr_run aggr_page} {
    # date_cet is set for each day to handle.
    log info "Determining dailystats (aggr_run/page) for: $date_cet"
    # 23-11-2013 two statements below should not be necessary.
    #$db exec2 "delete from aggr_run where date_cet = '$date_cet'"
    #$db exec2 "delete from aggr_page where date_cet = '$date_cet'"
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
    # @note 23-11-2013 zou eigenlijk geen avg moeten gebruiken, maar sum()/#runs, maar maakt hier weinig uit.
    foreach row [$db query "select 1*p.page_seq page_seq, p.page_type page_type, count(*) datacount, 
                                   avg(0.001*p.delta_user_msec) page_time_sec, 
                                   avg(0.001*p.time_to_interactive_page) page_ttip_sec, avg(0.001*p.page_bytes) avg_nkbytes,
                                   avg(1*p.element_count) avg_nitems
                            from page p
                              join scriptrun r on r.id = p.scriptrun_id
                            where r.date_cet = '$date_cet'
                            and 1*r.task_succeed_calc = 1
                            group by 1,2
                            order by 1,2"] {
       $db insert aggr_page [dict create scriptname $scriptname date_cet $date_cet \
         page_seq [:page_seq $row] page_type [:page_type $row] avg_time_sec [format %.3f [:page_time_sec $row]] \
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
    identity "dailystats - $date_cet"                 
  }
}
