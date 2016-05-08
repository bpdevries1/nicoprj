# ones below look generic enough to put in ndv lib.

proc dict_lappend {d_name key val} {
  upvar $d_name d
  set vals [dict_get $d $key]
  if {($val != "") && ([lsearch $vals $val] == -1)} {
    lappend vals $val
    dict set d $key $vals
  }
  return $vals
}

proc setvars {lst val} {
  foreach el $lst {
    upvar $el $el
    set $el $val
  }
}

# merge dicts as in dict merge, but don't let later values replace older ones, but lappend those.
proc dict_merge_append_old {d1 d2 args} {
  # first combine d1 and d2
  set res [dict create]
  dict for {k v} $d1 {
    if {[dict exists $d2 $k]} {
      dict set res $k [concat $v [dict get $d2 $k]]
    } else {
      dict set res $k $v
    }
  }
  dict for {k v} $d2 {
    if {[dict exists $d1 $k]} {
      # nothing, already done
    } else {
      dict set res $k $v
    }
  }
  # if args != {}, combine result of d1/d2 with the rest
  if {$args != {}} {
    # tail call, oh well.
    dict_merge_append $res {*}$args
  } else {
    return $res
  }
}

proc dict_merge_append {d1 d2 args} {
  # soort curry/partial dit:
  dict_merge_fn concat $d1 $d2 {*}$args
}

# merge dicts as in dict merge, but don't let later values replace older ones, but apply fn to values
proc dict_merge_fn {fn d1 d2 args} {
  # first combine d1 and d2
  set res [dict create]
  dict for {k v} $d1 {
    if {[dict exists $d2 $k]} {
      # dict set res $k [concat $v [dict get $d2 $k]]
      dict set res $k [$fn $v [dict get $d2 $k]]
    } else {
      dict set res $k $v
    }
  }
  dict for {k v} $d2 {
    if {[dict exists $d1 $k]} {
      # nothing, already done
    } else {
      dict set res $k $v
    }
  }
  # if args != {}, combine result of d1/d2 with the rest
  if {$args != {}} {
    # tail call, oh well.
    dict_merge_fn $fn $res {*}$args
  } else {
    return $res
  }
}

# 8-5-2016 from tclhelp
proc lremove {listVariable value} {
  upvar 1 $listVariable var
  set idx [lsearch -exact $var $value]
  set var [lreplace $var $idx $idx]
}
