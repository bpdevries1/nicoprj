# extra_aggr_connect.tcl - determine minimum/max/avg connection times to servers in order to determine physical locations.

proc extra_update_aggrconnect {db dargv subdir} {
  set scriptname [file tail $subdir]
  check_do_daily $db "aggrconnect" aggr_connect_time {
    # date_cet is set for each day to handle.
    log info "Determining aggr connect for: $date_cet"
    $db exec2 "insert into aggr_connect_time (scriptname, date_cet, domain, topdomain, ip_address, min_conn_msec, max_conn_msec, avg_conn_msec, number)
              select '$scriptname', date_cet, domain, topdomain, ip_address, 
                     min(1*connect_delta) min_conn_msec,
                     max(1*connect_delta) max_conn_msec,
                     round(avg(1*connect_delta),1) avg_conn_msec,
                     count(connect_delta) number
              from pageitem
              where date_cet = '$date_cet'
              and 1*connect_delta > 0
              group by 1,2,3,4,5
              order by 1,2,3,4,5" -log
    identity "aggrconnect - $date_cet"                     
  }
}
