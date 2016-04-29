package require TclOO 

package require struct::set
interp alias {} contains {} struct::set contains
# @todo door bovenstaande is contains direct te gebruiken, zonder struct::set
# vgl clj require/use waarmee je dit in een regel kan doen.
# of bv met alias zodat je dan set/contains of s/contains of s.contains kan doen.
# kan ook tcl namespace met :: gebruiken, dan bv set::contains, maar is alweer wat lang.
# / typt gemakkelijker dan ::

oo::class create checkrun_handler {

  # @doc usage: set conn [dbwrapper new <sqlitefile.db]
  # @doc usage: set conn [dbwrapper new -db <mysqldbname> -user <user> -password <pw>]
  constructor {} {
    # my variable conn dbtype dbname
    my variable has_fields
    # set has_fields {}
    # @todo default now, while code is not completely active.
    set has_fields1 {store_page wrb_jsp results_jsp error_jsp a_png error_code youtube addthis \
                    support_nav_error home_jsp prodreg}
    set has_fields [lmap el $has_fields1 {has_db $el}]
  }

  method set_has_fields {a_has_fields} {
     my variable has_fields
     set has_fields $a_has_fields
  }
  
  # @note init so object can be reused.
  method init {} {
    my variable has_fields dct_cr
    set dct_cr [dict create]
    foreach field $has_fields {
      dict set dct_cr $field 0 
    }
  }
  
  # @note cr.task_succeed == scriptrun.task_succeed_calc
  method set_scriptrun {scriptrun_name a_scriptrun_id} {
    upvar $scriptrun_name scriptrun
    my variable dct_cr 
    dict set dct_cr scriptrun_id $a_scriptrun_id
    dict set dct_cr task_succeed [:task_succeed_calc $scriptrun]
    dict set dct_cr ts_cet [:ts_cet $scriptrun]
  }
  
  method add_pageitem {pageitem_name} {
    upvar $pageitem_name pageitem
    my variable dct_cr 
    set url [:url $pageitem]
    my check_url_re has_store_page "retail_store_locator" $url
    my check_url_re has_wrb_jsp "/wrb_retail_store_locator_results.jsp" $url
    my check_url_re has_results_jsp "/retail_store_locator_results.jsp" $url
    my check_url_re has_error_jsp "/retail_store_locator.jsp" $url
    my check_url_re has_a_png "/A.png" $url
    my check_url_re has_youtube "youtube"   $url
    my check_url_re has_addthis "addthis" $url
    my check_has_home_jsp $url [:page_seq $pageitem] [:domain $pageitem]
    my check_has_prodreg $url [:domain $pageitem]
    my check_has_error_code $url [:topdomain $pageitem] [:error_code $pageitem] \
      [:ip_address $pageitem]
  }

  method check_url_re {field re url} {
    my variable dct_cr
    if {[regexp $re $url]} {
      dict set dct_cr $field 1 
    }
  }
  
  method check_has_home_jsp {url page_seq domain} {
    if {$page_seq == 2} {
      if {$domain != "philips.112.2o7.net"} {
        my check_url_re has_home_jsp "home.jsp" $url
      }
    }
  }
  
  method check_has_prodreg {url domain} {
    if {[regexp {^secure.philips} $domain]} {
      my check_url_re has_prodreg "prodreg" $url 
    }
  }
  
  method check_has_error_code {url topdomain error_code ip_address} {
    my variable dct_cr
    if {[my ignore_topdomain? $topdomain]} {
      return 
    }
    if {[my ignore_error_code? $error_code]} {
      return
    }
    if {($ip_address == "0.0.0.0") || ($ip_address == "NA")} {
      return 
    }
    dict set dct_cr has_error_code 1  
  }
  
  method ignore_topdomain? {topdomain} {
    contains {"2o7.net" "adoftheyear.com" "livecom.net"} $topdomain 
  }

  method ignore_error_code? {error_code} {
    contains {"" "200" "4006"} $error_code 
  }
  
  # @return dict to be inserted with $db insert  
  method get_record {} {
    my variable dct_cr
    dict set dct_cr real_succeed [my det_real_succeed]
    # log debug "in get_record, breakpoint not possible in TclOO"
    # log debug "dct_cr: $dct_cr"
    # breakpoint
    return $dct_cr
  }
 
  method det_real_succeed {} {
    my variable dct_cr
    if {![:task_succeed $dct_cr]} {
      return 0
    }
    if {[:has_error_code $dct_cr]} {
      return 0 
    }
    if {[:has_store_page $dct_cr]} {
      # dealer locator, check for a.png
      return [:has_a_png $dct_cr]
    }
    if {[:has_home_jsp $dct_cr]} {
      # myphilips, don't want to see prodreg
      return [expr 1 - [:has_prodreg $dct_cr]]
    }
    # else assume for now it is ok, until proven differently    
    return 1
  }
}

