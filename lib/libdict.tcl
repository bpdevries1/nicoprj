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
      if {[dict exists $dict $parname]} {
        lappend res $parname [dict get $dict $parname] 
      } else {
        lappend res $parname ""
      }
    } else {
      if {[dict exists $dict $parname]} {
        lappend res [dict get $dict $parname]
      } else {
        lappend res ""
      }
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

proc dict_get {dct key {default {}}} {
  if {[dict exists $dct $key]} {
    dict get $dct $key
  } else {
    return $default 
  }
}

# experimental: creating :accessor procs for dicts on the fly using unknown statement
# possible alternative is to create these accessors explicity.
# eg dict_make_accessors :bla :att {:lb lb}
# last one to create proc :lb, which used attribute lb (not :lb).
# also split in sub-functions.
# can this be done with interp alias? probably not, as it is not simply a prefix.

proc make_dict_accessors {args} {
  foreach arg $args {
    make_dict_accessor {*}$arg  
  }
}

proc make_dict_accessor {args} {
  if {[llength $args] == 1} {
    set procname $args
    set attname $args
  } elseif {[llength $args] == 2} {
    lassign $args procname attname
  } else {
    error "args does not have length 1 or 2: $args"
  }
  proc $procname {dct} "
    dict get \$dct $attname  
  "
}

# Save the original one so we can chain to it
rename unknown _original_unknown

proc unknown args {
  log warn "WARNING: unknown command: $args"
  if {[llength $args] == 2} {
    lassign $args procname dct
    if {[string range $procname 0 0] == ":"} {
      if {[string is list $dct]} {    # Only [string is] where -strict has no effect
        if {[expr [llength $dct]&1] == 0} {
          # actual entry in dict may be with or without ":", check current and make implementation dependent on the result.
          if {[dict exists $dct $procname]} {
            make_dict_accessor $procname
          } elseif {[dict exists $dct [string range $procname 1 end]]} {
            make_dict_accessor $procname [string range $procname 1 end]
          } else {
            log warn "attribute not found in dictionary: $procname, with or without :" 
          }
          return [$procname $dct]
        }
      }
    }
  }
  # if the above does not apply, call the original.
  log warn "calling original unknown for $args"
  uplevel 1 [list _original_unknown {*}$args]
}

