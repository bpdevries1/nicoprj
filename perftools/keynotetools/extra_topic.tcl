# extra_topic.tcl - called by libextraprocessing.tcl

# @todo als base-table (pageitem) verandert qua velden, moet deze mee veranderen.
proc extra_update_topic {db dargv subdir} {
  set scriptname [file tail $subdir]
  if {[regexp {CBF-CN} $scriptname]} {
    set conn [$db get_conn]
    set columns [dict keys [$conn columns pageitem]]
    check_do_daily $db "topic" pageitem_topic {
      log info "Determining pagitem-topic records for: $date_cet"
      # date_cet is set for each day to handle.
      # bepaal fields van pageitem en maak expliciet in queries, omdat volgorde anders kan zijn.
      $db exec2 "delete from pageitem_topic where date_cet = '$date_cet' and topic='CN-imagelist'"    
      $db exec2 "insert into pageitem_topic (topic, [join $columns ", "])
                 select 'CN-imagelist', [join $columns ", "]
                 from pageitem
                 where date_cet = '$date_cet'
                 and url like '%promotionchina/imagelist%'" -log
    }  
    # catalog selector as separate loop/action for now.
    # 28-11-2013 not now, included in extra_aggr_specific, part of ph-non-cacheable, check for 'requestid'
    if {0} {
      check_do_daily $db "topic-cs" pageitem_topic {
        log info "Determining pagitem-topic records for: $date_cet"
        # date_cet is set for each day to handle.
        # bepaal fields van pageitem en maak expliciet in queries, omdat volgorde anders kan zijn.
        $db exec2 "delete from pageitem_topic where date_cet = '$date_cet' and topic='CN-catsel'"    
        $db exec2 "insert into pageitem_topic (topic, [join $columns ", "])
                   select 'CN-catsel', [join $columns ", "]
                   from pageitem
                   where date_cet = '$date_cet'
                   and url like '%promotionchina/imagelist%'" -log
      }                   
    }  
  } else {
    # nothing to do for non-CBF-CN scripts.
  }
}


