proc extra_update_aggrsub {db dargv subdir} {
  set scriptname [file tail $subdir]
  check_do_daily $db "aggrsub" aggr_sub {
    # date_cet is set for each day to handle.
    log info "Determining aggrsub (topdomain (extension, party)) for: $date_cet"
    set res [$db query "select count(*) datacount from scriptrun r where r.date_cet = '$date_cet'"]
    if {[llength $res] == 1} {
      set datacount [:datacount [lindex $res 0]]
      log debug "set datacount to $datacount"
      if {$datacount > 0} {
        # @todo add party to list of topdomain and extension (maybe topdomain then not needed anymore)
        foreach keytype {topdomain extension} {
          foreach row [$db query "select 1*i.page_seq page_seq, i.$keytype keyvalue,
                                    sum(0.001*i.element_delta)/$datacount loadtime,
                                    sum(0.001*i.content_bytes)/$datacount nkbytes,
                                    1.0*count(i.id)/$datacount nitems
                                  from pageitem i
                                  where i.date_cet = '$date_cet'
                                  and not i.domain in ('philips.112.2o7.net')
                                  group by 1,2
                                  order by 1,2"] {
           # breakpoint                                
           $db insert aggr_sub [dict create scriptname $scriptname date_cet $date_cet \
             page_seq [:page_seq $row] keytype $keytype keyvalue [:keyvalue $row] \
             avg_time_sec [try_eval {format %.3f [:loadtime $row]} {str ""}] \
             avg_nkbytes [try_eval {format %.3f [:nkbytes $row]} {str ""}] \
             avg_nitems [try_eval {format %.3f [:nitems $row]} {str ""}]]
          }
        }
      } else {
        log warn "datacount = 0, probably no data for $date_cet"
      }
    } else {
      log warn "Could not determine datacount for $subdir/$date_cet"
    }
  }
}

proc extra_update_aggrsub_old {db dargv subdir} {
  set scriptname [file tail $subdir]
  check_do_daily $db "aggrsub" aggr_sub {
    # date_cet is set for each day to handle.
    log info "Determining aggrsub (topdomain (extension, party)) for: $date_cet"
    set res [$db query "select count(*) datacount from scriptrun r where r.date_cet = '$date_cet'"]
    if {[llength $res] == 1} {
      set datacount [:datacount [lindex $res 0]]
      # per topdomain
      foreach row [$db query "select i.page_seq page_seq, i.topdomain topdomain,
                                sum(0.001*i.element_delta)/$datacount loadtime,
                                sum(0.001*i.content_bytes)/$datacount nkbytes,
                                count(i.id)/$datacount nitems
                              from pageitem i
                              where i.date_cet = '$date_cet'
                              and not i.domain in ('philips.112.2o7.net')
                              group by 1,2
                              order by 1,2"] {
       $db insert aggr_sub [dict create scriptname $scriptname date_cet $date_cet \
         page_seq [:page_seq $row] keytype "topdomain" keyvalue [:topdomain $row] \
         avg_time_sec [format %.3f [:loadtime $row]] \
         avg_nkbytes [format %.3f [:nkbytes $row]] \
         avg_nitems [format %.3f [:nitems $row]]]
      }
      # per extension
      foreach row [$db query "select i.page_seq page_seq, i.extension extension,
                                sum(0.001*i.element_delta)/$datacount loadtime,
                                sum(0.001*i.content_bytes)/$datacount nkbytes,
                                count(i.id)/$datacount nitems
                              from pageitem i
                              where i.date_cet = '$date_cet'
                              and not i.domain in ('philips.112.2o7.net')
                              group by 1,2
                              order by 1,2"] {
       $db insert aggr_sub [dict create scriptname $scriptname date_cet $date_cet \
         page_seq [:page_seq $row] keytype "extension" keyvalue [:extension $row] \
         avg_time_sec [format %.3f [:loadtime $row]] \
         avg_nkbytes [format %.3f [:nkbytes $row]] \
         avg_nitems [format %.3f [:nitems $row]]]
      }
    } else {
      log warn "Could not determine datacount for $subdir/$date_cet"
    }
  }
}
