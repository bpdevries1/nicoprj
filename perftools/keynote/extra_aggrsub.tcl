proc extra_update_aggrsub {db dargv subdir} {
  set scriptname [file tail $subdir]
  check_do_daily $db "aggrsub" aggr_sub {
    # date_cet is set for each day to handle.
    log info "Determining aggrsub (topdomain, extension, others)) for: $date_cet"
    set res [$db query "select count(*) datacount from scriptrun r where r.date_cet = '$date_cet'"]
    if {[llength $res] == 1} {
      set datacount [:datacount [lindex $res 0]]
      log debug "set datacount to $datacount"
      if {($datacount != "") && ($datacount > 0)} {
        # @note 18-2-2014 added domain next to topdomain.
        # @note twijfel over basepage, ip_address, domain:ip_address, aptimized, content_type:aptimized
        # @note 'when in doubt, do' hierzo.
        # @note als je deze dingen in graph wil tonen, dan mogelijk ook alleen de top-zoveel.
        # foreach keytype {topdomain extension domain content_type} {}
        # @todo kan dit niet gewoon met insert-select? 
        # @todo pageitem i ook niet nodig, maar 1 tabel. Is voor colselect ook weer gemakkelijker.
        # @todo formattering kan ook in sql, door round(val,3) te gebruiken.
        # @note 2014-02-22 IP gerelateerde dingen nu toch eerst weg, want erg veel, AllScripts.db is groot (1.7G) en kopieren naar deze DB is traag (kan zo 3 minuten zijn).        
        # @note 2014-02-22 verwijderd: ip_address {dom_ip domain ip_address} 
        # @note 2014-04-18 add aggregates for extra fields: phys_loc and akamai headers
        foreach keytypespec {topdomain extension domain content_type basepage aptimized {cntype_apt content_type aptimized} phys_loc phys_loc_type is_dynamic_url status_code_type disable_domain akh_cache_control akh_x_check_cacheable akh_x_cache akh_expiry {domain_is_dynamic domain is_dynamic_url} {domain_result domain status_code_type} {domain_disable_domain domain disable_domain} {domain_cacheable domain akh_x_check_cacheable} {domain_phys_loc_type domain phys_loc_type}} {
          lassign [det_keytype_colselect $keytypespec] keytype colselect
          aggrsub_keytype $db $datacount $date_cet $scriptname $keytype $colselect
        }
        aggrsub_keytype $db $datacount $date_cet $scriptname "domain_gt_100k" "i.domain" "and 1*i.content_bytes > 100000"
        
        # 27-2-2014 ivm scene7 (images.philips.com) kijken naar wel/niet dynamische items.
        # liefst een dynamic-veld toevoegen, dan vgl aptimized doen.
        # nu even alleen een 'and url like '%&_=%'
        # \ in Tcl ook escape char, daarom hier andere.
        aggrsub_keytype $db $datacount $date_cet $scriptname "domain_dynamic" "i.domain" "and i.url like '%&^_=%' escape '^' "
      } else {
        log warn "datacount = 0, probably no data for $date_cet"
      }
    } else {
      log warn "Could not determine datacount for $subdir/$date_cet"
    }
    identity "aggrsub - $date_cet"                     
  }
}

proc aggrsub_keytype {db datacount date_cet scriptname keytype colselect {extrawhere ""}} {
  foreach row [$db query "select 1*i.page_seq page_seq, $colselect keyvalue,
                            sum(0.001*i.element_delta)/$datacount loadtime,
                            sum(0.001*i.content_bytes)/$datacount nkbytes,
                            1.0*count(i.id)/$datacount nitems
                          from pageitem i
                          where i.date_cet = '$date_cet'
                          $extrawhere
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

proc det_keytype_colselect {keytypespec} {
  if {[llength $keytypespec] > 1} {
    set keytype [lindex $keytypespec 0]
    set colselect [join [listc {"i.$el"} el -> [lrange $keytypespec 1 end]] " || ':' || "]
  } else {
    set keytype $keytypespec
    set colselect "i.$keytype"
  }
  list $keytype $colselect
}

proc extra_update_aggrsub_orig {db dargv subdir} {
  set scriptname [file tail $subdir]
  check_do_daily $db "aggrsub" aggr_sub {
    # date_cet is set for each day to handle.
    log info "Determining aggrsub (topdomain, extension, others)) for: $date_cet"
    set res [$db query "select count(*) datacount from scriptrun r where r.date_cet = '$date_cet'"]
    if {[llength $res] == 1} {
      set datacount [:datacount [lindex $res 0]]
      log debug "set datacount to $datacount"
      if {($datacount != "") && ($datacount > 0)} {
        # @todo add party to list of topdomain and extension (maybe topdomain then not needed anymore)
        # @note content_type maybe better than extension.
        # @note 18-2-2014 added domain next to topdomain.
        # @note twijfel over basepage, ip_address, domain:ip_address, aptimized, content_type:aptimized
        # @note 'when in doubt, do' hierzo.
        # @note als je deze dingen in graph wil tonen, dan mogelijk ook alleen de top-zoveel.
        # foreach keytype {topdomain extension domain content_type} {}
        # @todo kan dit niet gewoon met insert-select? 
        # @todo pageitem i ook niet nodig, maar 1 tabel. Is voor colselect ook weer gemakkelijker.
        # @todo formattering kan ook in sql, door round(val,3) te gebruiken.
        foreach keytypespec {topdomain extension domain content_type basepage ip_address aptimized {dom_ip domain ip_address} {cntype_apt content_type aptimized}} {
          lassign [det_keytype_colselect $keytypespec] keytype colselect
          foreach row [$db query "select 1*i.page_seq page_seq, $colselect keyvalue,
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
    identity "aggrsub - $date_cet"                     
  }
}


