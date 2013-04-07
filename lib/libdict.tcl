# params: [-withname] dict <lijst van attr names>
# -withname geef attr-naam mee in de result
# in tcl toch maar - gebruiken als symbol qualifier, ipv :
proc dict_get_multi {args} {
  if {[lindex $args 0] == "-withname"} {
    set withname 1
    set args [lrange $args 1 end]
  } else {
    set withname 0 
  }
  set dict [lindex $args 0]
  set res {}
  foreach parname [lrange $args 1 end] {
    if {$withname} {
      lappend res $parname [dict get $dict $parname] 
    } else {
      lappend res [dict get $dict $parname] 
    }
  }
  return $res
}

# create a dict with each arg from args. args contains var-names, dict will contain names+values
proc vars_to_dict {args} {
  set res {}
  foreach arg $args {
    upvar $arg val
    # puts "$arg = $val"
    lappend res $arg $val
  }
  return $res
}

# @param dct dictionary object
# @result var-names with values in calling stackframe based on dct.
proc dict_to_vars {dct} {
  foreach {nm val} $dct {
    upvar $nm val2
    set val2 $val
  }
}



