package require struct::list

proc main {} {
  set lst {
    {hij-wil lady tiger}
    {zij-wil lady tiger}
    {hij-wil2 lady princess}
    {zij-wijst lady tiger}
    {hij-kiest same other}
  }
  
  set lst_out [make_combinations [struct::list mapfor el $lst {lrange $el 1 end}]]
  puts "lst_out: $lst_out"

  set f [open tiger-lady.tsv w]
  puts $f [join [struct::list mapfor el $lst {lindex $el 0}] "\t"]
  puts $f [join [struct::list mapfor regel $lst_out {join $regel "\t"}] "\n"]
  close $f
}

proc make_combinations {lst} {
  if {$lst == {}} {
    list [list] 
  } else {
    set lst_sub [make_combinations [lrange $lst 1 end]]
    struct::list fold [struct::list mapfor el0 [lindex $lst 0] {
       struct::list mapfor regel $lst_sub {
         concat [list $el0] $regel 
       }
     }] {} concat
  }
}

main
