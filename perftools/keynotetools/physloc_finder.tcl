package require TclOO 

package require struct::set
interp alias {} contains {} struct::set contains
# @todo door bovenstaande is contains direct te gebruiken, zonder struct::set
# vgl clj require/use waarmee je dit in een regel kan doen.
# of bv met alias zodat je dan set/contains of s/contains of s.contains kan doen.
# kan ook tcl namespace met :: gebruiken, dan bv set::contains, maar is alweer wat lang.
# / typt gemakkelijker dan ::

oo::class create physloc_finder {

  # @doc usage: set conn [dbwrapper new <sqlitefile.db]
  # @doc usage: set conn [dbwrapper new -db <mysqldbname> -user <user> -password <pw>]
  constructor {} {
    my variable ar_physloc
    set db [dbwrapper new "c:/projecten/Philips/CQ5-CN/cq5-cn-domains.db"]
    set prev "<none>"
    foreach row [$db query "select ip_oct3, phys_loc, phys_loc_type
                        from cq5_domain_ip_oct3
                        order by 1"] {
      dict_to_vars $row
      if {$ip_oct3 != $prev} {
        set ar_physloc($ip_oct3) [list $phys_loc $phys_loc_type]
      }      
      set prev $ip_oct3
    }
    $db close
  }

  # destructor?
  
  # return tuple/list: phys_loc phys_loc_type
  method find {scriptname ip_oct3} {
    my variable ar_physloc
    if {[regexp {CN} $scriptname]} {
      # clj if-let would be nice here.
      set el [array get ar_physloc $ip_oct3]
      if {[:# $el] > 0} {
        return [:1 $el]
      } else {
        list "noinfo" "noinfo"
      }
    } else {
      list "notCN" "notCN"
    }
  }

}

