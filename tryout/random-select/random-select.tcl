source "~/nicoprj/lib/random.tcl"

proc main {} {
  srandom [clock seconds]

  # set lst_alles [maak_lijst]
  # set lst_alles [maak_lijst_decr]
  set lst_alles [maak_lijst_incr]
  # set lst_alles [maak_lijst_unif]
  set n 5 ; # select 10 van 100
  set N_TEST 100
  set i_test 0
  reset_ar_count ar_count lst_alles
  while {$i_test < $N_TEST} {
    incr i_test
    set lst_history [calc_lst_history lst_alles ar_count $i_test $n]
    # set lst_result [choose_random $lst_alles $n]
    set lst_result [choose_random $lst_history $n]
    foreach el $lst_result {
      incr ar_count($el) 
    }
    puts_diff_perc orig lst_alles ar_count $N_TEST $n
    puts_diff_perc "\thist" lst_history ar_count $N_TEST $n
    puts ""
    # puts $lst_result
  }
  puts_results lst_alles ar_count $N_TEST $n

  # calc one more time for final results.
  set lst_history [calc_lst_history lst_alles ar_count $i_test $n]
  foreach el $lst_history {
    foreach {val Fi} $el break;
    puts "$val: $Fi" 
  }
}

proc reset_ar_count {ar_count_name lst_alles_name} {
  upvar $ar_count_name ar_count
  upvar $lst_alles_name lst_alles
  foreach el $lst_alles {
    foreach {val Fi} $el break;
    set ar_count($val) 0
  }  
}

# calculate chance/frequencies based on original frequencies and choice-history
# i_test: current iteration, base 0.
# chosen_sum: items chosen so far: i_test * n_selection
proc calc_lst_history {lst_alles_name ar_count_name i_test n_selection} {
  upvar $lst_alles_name lst_alles
  upvar $ar_count_name ar_count
  set F_sum [det_F_sum $lst_alles]
  set chosen_sum [expr $i_test * $n_selection]
  set lst {}
  foreach el $lst_alles {
    foreach {val Fi} $el break;
    lappend lst [list $val [expr $chosen_sum * ((1.0 * $Fi / $F_sum) - ((1.0 * $ar_count($val) / ($chosen_sum + $n_selection))))]]  
  }
    
  return $lst  
}

proc choose_random {lst n} {
  set lst [lsort -decreasing -real -index 1 $lst] 
  set N [llength $lst]
  set m 0 ; # aantal gekozen records
  set lst_result {}
  set F_sum [det_F_sum $lst]

  set t 0 ; # aantal behandelde records
  set F_gehad 0.0
  while {($m < $n) && ($t < $N)} {
    set U [random1]
    # puts "U: $U"
    set el [lindex $lst $t]
    foreach {val Fi} $el break;
    if {[expr $U * ($F_sum - $F_gehad)] < [expr ($n - $m) * $Fi]} {  
      lappend lst_result $val
      incr m
    } else {
    }
    incr t
    set F_gehad [expr $F_gehad + $Fi]
  }
  if {$m < $n} {
    puts "Not enough items chosen"
    exit 1
  }
  return $lst_result  
}

proc choose_random_old {lst n} {
  set N [llength $lst]
  set m 0 ; # aantal gekozen records
  set lst_result {}
  set F_sum [det_F_sum $lst]

  # nog lus omheen, als in eerste omloop niet genoeg geselecteerd
  while {$m < $n} {
    set t 0 ; # aantal behandelde records
    set F_gehad 0.0
    while {($m < $n) && ($t < $N)} {
      set U [random1]
      # puts "U: $U"
      set el [lindex $lst $t]
      foreach {val Fi} $el break;
      if {[expr $U * ($F_sum - $F_gehad)] < [expr ($n - $m) * $Fi]} {  
        lappend lst_result $val
        incr m
      } else {
      }
      incr t
      set F_gehad [expr $F_gehad + $Fi]
    }
  }

  return $lst_result  
}

proc det_F_avg {lst} {
  set N [llength $lst]
  set Favg [expr 1.0 * [det_F_sum $lst] / $N]
  return $Favg
}

proc det_F_sum {lst} {
  set sum_F 0.0
  foreach el $lst {
    foreach {val Fi} $el break;
    set sum_F [expr $sum_F + $Fi]
  }
  return $sum_F  
}


proc maak_lijst_decr {} {
  set lst {}
  for {set i 20} {$i >= 1} {incr i -1} {
    # lappend lst [list $i .05] ; # gewone goede verdeling
    lappend lst [list $i $i] ; # grotere kans, dus elementen aan het begin meer gekozen. 
  }
  return $lst
}

proc maak_lijst_incr {} {
  set lst {}
  for {set i 1} {$i <= 20} {incr i} {
    # lappend lst [list $i .05] ; # gewone goede verdeling
    lappend lst [list $i $i] ; # grotere kans, dus elementen aan het begin meer gekozen. 
  }
  return $lst
}

proc maak_lijst_1_20 {} {
  set lst {}
  lappend lst [list 1 5]
  lappend lst [list 20 5]
  for {set i 2} {$i <= 19} {incr i} {
    # lappend lst [list $i .05] ; # gewone goede verdeling
    lappend lst [list $i 1] ; # grotere kans, dus elementen aan het begin meer gekozen. 
  }
  return $lst
}

proc maak_lijst_unif {} {
  set lst {}
  for {set i 1} {$i <= 20} {incr i} {
    # lappend lst [list $i .05] ; # gewone goede verdeling
    lappend lst [list $i 1] ; # gewone goede verdeling
  }
  return $lst
}

proc puts_results {lst_alles_name ar_count_name n_test n_selection} {
  upvar $lst_alles_name lst_alles
  upvar $ar_count_name ar_count
  
  set N [llength $lst_alles]
  set F_avg [det_F_avg $lst_alles]
  set F_sum [expr $F_avg * $N]
  puts "F_sum, F_avg: $F_sum, $F_avg"
  set som 0
  set som_E 0
  foreach el $lst_alles {
    foreach {val Fi} $el break;
    set E [expr 1.0 * $n_test * $n_selection * ($Fi / $F_sum)]
    # incr ar_count($val) 0
    puts "[format "%2d: %3d (%3.2f)" $val $ar_count($val) $E]"
    incr som $ar_count($val)
    set som_E [expr $som_E+ $E]
  }
  puts [format "Totaal: %4d (%4.0f)" $som $som_E]
  puts_diff_perc "Final" lst_alles ar_count $n_test $n_selection
  puts ""
}

proc puts_diff_perc {title lst_alles_name ar_count_name n_test n_selection} {
  upvar $lst_alles_name lst_alles
  upvar $ar_count_name ar_count
  puts -nonewline "$title: [format %.3f [expr [calc_diff_perc lst_alles ar_count [expr $n_test * $n_selection]] * 100]]%" 
}

# calculate based on stdev: higher deviances cost more.
# is this covariance?
proc calc_diff_perc {lst_alles_name ar_count_name n_chosen} {
  upvar $lst_alles_name lst_alles
  upvar $ar_count_name ar_count
  set N [llength $lst_alles]
  set F_avg [det_F_avg $lst_alles]
  set F_sum [expr $F_avg * $N]
  set sum 0.0
  foreach el $lst_alles {
    foreach {val Fi} $el break;
    set expected [expr 1.0 * $n_chosen * ($Fi / $F_sum)]
    set actual [expr 1.0 * $ar_count($val)]
    set sum [expr $sum + (($expected - $actual) * ($expected - $actual))]
  }  
  return [expr sqrt($sum / $N) / $n_chosen]
}

main

