# Functional Programming functions
# Also look in ::struct::list

package require struct::list

package provide ndv 0.1.1

namespace eval ::ndv {

	namespace export times times_old lindices iden lambda_negate lambda_and regexp_lambda lst_partition proc_to_lambda lambda_to_proc iden
	
  proc times_old {ntimes pr args} {
    set result {}
    for {set i 0} {$i < $ntimes} {incr i} {
      lappend result [$pr {*}$args] 
    }
    return $result
  }
  
  proc times {ntimes block} {
    set result {}
    for {set i 0} {$i < $ntimes} {incr i} {
      # lappend result [$pr {*}$args]
      lappend result [uplevel $block]
    }
    return $result
  }   

  # multiple of lindex: return multiple elements of a list
  # example: lindices $lst 0 2 4
  proc lindices {lst args} {
    return [struct::list mapfor el $args {lindex $lst $el}] 
  }

  proc iden {param} {
    return $param 
  }
  
  proc lambda_negate {lambda} {
    list [lindex $lambda 0] "![lindex $lambda 1]"
  }
  
  # niet zeker of deze werkt.
  proc lambda_and {lambda1 lambda2} {
    if {[lindex $lambda1 0] != [lindex $lambda2 0]} {
      error "Lambda1 en 2 should have the same param name"
    }
    # list [lindex $lambda1 0] "([lindex $lambda1 1]) && ([lindex $lambda2 1])"
    list [lindex $lambda1 0] "[lindex $lambda1 1] && [lindex $lambda2 1]"
  }
  
  # 6-7-2010 dingen met list geprobeerd, maar dan teveel braces. Mis hier echte closure en/of macro.
  # verder wat vogelen met quotes en braces om te zorgen dat de list 2 elementen heeft.
  proc regexp_lambda {re} {
    return "x {\[regexp -nocase -- {$re} \$x\]}"
  }

  # divide list in sublists based on a lambda function. The result of the function determines the element in the partition.
  # @todo? also put the function result in the partition?
  # onderstaande een library function.
  proc lst_partition {lst lambda} {
    array set ar {} ; # empty array
    foreach el $lst {
      lappend ar([apply $lambda $el]) $el
    }
    # array get ar: geeft ook element name, wil ik niet.
    struct::list mapfor el [array names ar] {set ar($el)} 
  }

  # @todo functies om een lambda naar een proc om te zetten en vice versa
  # deze ook functioneel kunnen inzetten, ofwel return value moet direct bruikbaar zijn.
  proc proc_to_lambda {procname} {
    list args "$procname {*}\$args"
  }

  # resultaat van lambda_to_proc mee te geven aan struct::list map en filter bv.
  # eerst even simpel met een counter
  # vb: struct::list map {1 2 3 4} [lambda_to_proc {x {expr $x * 3}}] => {3 6 9 12}
  # vb: struct::list filter {1 2 3 4} [lambda_to_proc {x {expr $x >= 3}}]
  set proc_counter 0
  proc lambda_to_proc {lambda} {
    global proc_counter
    incr proc_counter
    set procname "zzlambda$proc_counter"
    proc $procname {*}$lambda ; # combi van args en body
    return $procname
  }

  # sometimes need in FP functions
  proc iden {arg} {
    return $arg 
  }
  
}
