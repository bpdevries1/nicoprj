package require TclOO 

# det_urlnoparams is defined in kn-migrations.tcl, also loaded in scatter2db, so should be available here.

oo::class create akheader_finder {

  # @doc usage: set conn [dbwrapper new <sqlitefile.db]
  # @doc usage: set conn [dbwrapper new -db <mysqldbname> -user <user> -password <pw>]
  constructor {} {
    my variable ar_akh noinfo nocn
    set db [dbwrapper new "c:/projecten/Philips/akamai-headers/akamai-headers.db"]
    $db function det_urlnoparams
    set prev "<none>"
    foreach row [$db query "select det_urlnoparams(param) urlnoparams, maxage, cacheable, cachetype, expiry
                        from curlgetheader
                        where 1*iter = 1
                        order by 1"] {
      dict_to_vars $row
      if {$urlnoparams != $prev} {
        set ar_akh($urlnoparams) [dict create akh_cache_control [my det_cache_control $maxage] \
                           akh_x_check_cacheable $cacheable \
                           akh_x_cache $cachetype \
                           akh_expiry $expiry]
      }      
      set prev $urlnoparams
    }
    $db close
    set noinfo [dict create akh_x_check_cacheable noinfo]
    set nocn [dict create akh_x_check_cacheable nocn]
  }

  # destructor?
  
  # return tuple/list: phys_loc phys_loc_type
  method find {scriptname urlnoparams} {
    my variable ar_akh noinfo nocn
    if {[regexp {CN} $scriptname]} {
      # clj if-let would be nice here.
      set el [array get ar_akh $urlnoparams]
      if {[:# $el] > 0} {
        return [:1 $el] ; # value of element
      } else {
        return $noinfo
      }
    } else {
      return $nocn
    }
  }

  method det_cache_control {maxage} {
    if {[string is integer $maxage]} {
      return "nseconds"
    } else {
      return $maxage
    }
  }
  
}

