# show projects that don't have a mapping. Only recent projects (max 3 months old)
proc show_warnings {} {
  set check_date [clock format [clock add [clock seconds] -3 months] -format "%Y-%m-%d"]
  set sql "select distinct u.project project
           from urendag u
           where date  > '$check_date'
           and not project in (
                    select project from target_mapping
                    )
           order by 1;"
  set unmapped 0
  db eval $sql row {
    #puts "WARN: Unmapped project: $row(project)"
    puts "$row(project)"
    set unmapped 1
  }
  if {$unmapped} {
    puts "WARN: Unmapped projects!"
  }
}

proc notes_to_html {lst_notes} {
  join $lst_notes "<br/>" 
}

proc format_values {lst} {
  set res {}
  foreach el $lst {
    lappend res [format %.1f $el] 
  }
  return $res
}

# increase (possibly) float value in var with value (incr only works with integers)
proc incrnum {var value} {
  upvar $var var1
  if {[info exists var1]} {
    set var1 [expr $var1 + $value]
  } else {
    set var1 $value
  }
}

proc log {args} {
  # global log
  variable log
  $log {*}$args
}

