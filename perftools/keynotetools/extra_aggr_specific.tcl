# extra_aggr_specific.tcl - called by libextraprocessing.tcl

# @todo als base-table (pageitem) verandert qua velden, moet deze mee veranderen.
proc extra_update_aggr_specific {db dargv subdir} {
  set scriptname [file tail $subdir]
  if {[regexp {CBF-CN} $scriptname]} {
    # don't let check_do_daily remove records, do it specifically here.
    check_do_daily $db "aggr_specific" {} {
      log info "Determining aggr_specific records for: $date_cet"
      # date_cet is set for each day to handle.
      $db exec2 "delete from aggr_specific where date_cet = '$date_cet' and topic='imagelist-overhead'"
      
      $db exec2 "insert into aggr_specific (scriptname, date_cet, topic, per_page_sec)
                  select '$scriptname', '$date_cet', 'imagelist-overhead', round(0.001*sum(overhead_msec)/(r.datacount*r.npages),3) per_page_sec
                  from 
                  (select io.scriptname scriptname, il.ts_cet ts_cet, il.date_cet date_cet, il.page_seq page_seq, 
                    max(0, min(il.start_msec+il.element_delta-(io.start_msec+io.element_delta))) overhead_msec
                  from pageitem il join pageitem io on il.page_id = io.page_id
                  where il.date_cet = '$date_cet'
                  and 1*io.start_msec < il.start_msec+il.element_delta
                  and io.start_msec+io.element_delta > il.start_msec
                  and io.url not like '%imagelist%'
                  and il.url like '%imagelist%'
                  group by 1,2,3,4) i join aggr_run r on i.scriptname = r.scriptname and i.date_cet = r.date_cet
                  group by 1,2,3" -log
    }
    
    # extra calculations specific for CN as well, just last 6 weeks.
    # don't let check_do_daily remove records, do it specifically here.
    check_do_daily $db "aggr_specific_cn" {} {
      if {$date_cet > "2013-10-15"} {
        log info "Determining aggr_specific records for: $date_cet"
        # date_cet is set for each day to handle.
        $db exec2 "delete from aggr_specific where date_cet = '$date_cet' 
                   and topic in ('ph-non-cacheable', 'ph-jsessionid', 'ph-image-150k', 'ph-mobile', 'ph-idle-ttip')" -log
                   
        $db exec2 "insert into aggr_specific (scriptname, date_cet, topic, per_page_sec)
                   select '$scriptname', '$date_cet', 'ph-non-cacheable',  
                     round(0.001*sum(i.element_delta) / (r.datacount * r.npages), 3)
                   from pageitem i join aggr_run r on r.date_cet = i.date_cet
                   where i.date_cet = '$date_cet'
                   and i.topdomain like '%philips%'
                   and not i.url like '%imagelist%'
                   and (url like '%requestid%' or url like '&_=13')
                   group by 1,2,3" -log

        $db exec2 "insert into aggr_specific (scriptname, date_cet, topic, per_page_sec)
                   select '$scriptname', '$date_cet', 'ph-jsessionid',  
                     round(0.001*sum(i.element_delta) / (r.datacount * r.npages), 3)
                   from pageitem i join aggr_run r on r.date_cet = i.date_cet
                   where i.date_cet = '$date_cet'
                   and i.topdomain like '%philips%'
                   and not i.url like '%imagelist%'
                   and not (url like '%requestid%' or url like '&_=13')
                   and url like '%;jsessionid=%'
                   group by 1,2,3" -log
                   
        $db exec2 "insert into aggr_specific (scriptname, date_cet, topic, per_page_sec)
                   select '$scriptname', '$date_cet', 'ph-mobile',  
                     round(0.001*sum(i.element_delta) / (r.datacount * r.npages), 3)
                   from pageitem i join aggr_run r on r.date_cet = i.date_cet
                   where i.date_cet = '$date_cet'
                   and i.domain = 'm.philips.com.cn'
                   group by 1,2,3" -log
                   
        $db exec2 "insert into aggr_specific (scriptname, date_cet, topic, per_page_sec)
                   select '$scriptname', '$date_cet', 'ph-image-150k',  
                     round(0.001*sum(i.element_delta) / (r.datacount * r.npages), 3)
                   from pageitem i join aggr_run r on r.date_cet = i.date_cet
                   where i.date_cet = '$date_cet'
                   and i.topdomain like '%philips%'
                   and i.extension = 'jpg'
                   and 1*i.content_bytes > 150000
                   group by 1,2,3" -log

        $db exec2 "insert into aggr_specific (scriptname, date_cet, topic, per_page_sec)
                   select '$scriptname', '$date_cet', 'ph-idle-ttip',  
                     round(sum(0.001*i.idle_msec) / (r.datacount * r.npages), 3)
                   from (select p.date_cet date_cet, p.ts_cet ts_cet, 1*p.page_seq page_seq, 
                                 max(0, p.delta_user_msec - p.time_to_interactive_page - sum(i.element_delta)) idle_msec 
                          from page p join pageitem i on p.id = i.page_id
                          where p.date_cet = '$date_cet'
                          and i.date_cet = '$date_cet'
                          and 1*i.start_msec > p.time_to_interactive_page
                          group by 1,2,3) i 
                     join aggr_run r on r.date_cet = i.date_cet
                   where i.date_cet = '$date_cet'
                   group by 1,2,3" -log

        #Not:
        #* Akamai not-cacheable.
        #  - url like akamai dingen.
        # http://www.philips.com.cn/ext_elems/opinionbar/philips_p11026/overlay.js is cacheable.
        # 	Path: /ext_elems/opinionbar/* op 1 day TTL gezet.
        # kleine steekproef gedaan voor HX6921 test (data tot Sep-28), niets gevonden.      
      
      } ; # if date_cet
    } ; # check_do_daily
  } else {
    # nothing to do for non-CBF-CN scripts.
    log debug "No aggr_specific for script: $scriptname"
  }
}


