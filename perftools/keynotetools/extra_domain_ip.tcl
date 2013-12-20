# extra_update_domain_ip.tcl - called by libextraprocessing.tcl

# @todo als base-table (pageitem) verandert qua velden, moet deze mee veranderen.
proc extra_update_domain_ip {db dargv subdir} {
  # $db add_tabledef domain_ip_time {id} {scriptname date_cet topdomain domain ip_address {number int} {min_conn_msec real}}
  set scriptname [file tail $subdir]
  check_do_daily $db "domain_ip" domain_ip_time {
    log info "Determining domain_ip_time records for: $date_cet"
    # date_cet is set for each day to handle.
    $db exec2 "delete from domain_ip_time where date_cet = '$date_cet'"    
    $db exec2 "insert into domain_ip_time (scriptname, date_cet, topdomain, domain, ip_address, number, min_conn_msec)
               select '$scriptname', '$date_cet', topdomain, domain, ip_address, count(*), min(1*connect_delta)
               from pageitem
               where date_cet = '$date_cet'
               and 1*connect_delta > 0
               group by 1,2,3,4,5" -log
  }  
}


