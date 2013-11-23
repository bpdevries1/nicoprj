# extra_gt3.tcl - called by libextraprocessing.tcl

# @todo als base-table (pageitem) verandert qua velden, moet deze mee veranderen.
proc extra_update_gt3 {db dargv subdir} {
  set conn [$db get_conn]
  set columns [dict keys [$conn columns pageitem]]
  check_do_daily $db "gt3" pageitem_gt3 {
    # date_cet is set for each day to handle.
    # bepaal fields van pageitem en maak expliciet in queries, omdat volgorde anders kan zijn.
    $db exec2 "delete from pageitem_gt3 where date_cet = '$date_cet'"    
    $db exec2 "insert into pageitem_gt3 ([join $columns ", "])
               select [join $columns ", "]
               from pageitem
               where date_cet = '$date_cet'
               and 1*element_delta > 3000" -log
  }  
}


