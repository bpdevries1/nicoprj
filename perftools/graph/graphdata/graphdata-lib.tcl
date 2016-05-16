# graphdata-lib.tcl - candidates to put in ::ndv lib.
# 26-12-2011 NdV copied functions to ~/nicoprj/lib/generallib and fp.tcl.

package require struct::list

interp alias {} map {} ::struct::list map
interp alias {} mapfor {} ::struct::list mapfor

interp alias {} filter {} ::struct::list filter
interp alias {} filterfor {} ::struct::list filterfor

interp alias {} iota {} ::struct::list iota

# helper proc for use in map (and filter?)
proc id {val} {
  return $val
}

# apply procname to each corresponding member in lst_lsts
# return (single) list with results
# procname should expect the same number of arguments as there are lists in lst_lsts
# @todo deze al in ndv-lib?
proc multimap {procname lst_lsts} {
  set res {}
  set n [llength [lindex $lst_lsts 0]]
  for {set i 0} {$i < $n} {incr i} {
    lappend res [$procname {*}[mapfor lst $lst_lsts {
      lindex $lst $i
    }]]
  }
  return $res
}

# ook transpose, hier niet nodig, verder wel handig, zie ook clojure
proc transpose {lst_lsts} {
  multimap list $lst_lsts 
}

proc catch_call {catch_result args} {
  try_eval {
    set result [eval {*}$args]
  } {
    set result $catch_result
  }
  return $result
}

