




======== LATER DOEN HIERONDER =========

# @return 1 als vanuit sol in 1 stap een betere sol gevonden kan worden.
proc kan_naar_betere {sol} {
  global *AR_INP_WEDSTRIJDEN*
  set fitness [dict get $sol -fitness]
  set lst_opl_scheids [dict get $sol -lst_opl_scheids]
  for {set i 0} {$i < [llength $lst_opl_scheids]} {incr i} {
    # vervang in wedstrijd i de scheids door een andere
    set opl_scheids [lindex $lst_opl_scheids $i]
    set wedstrijd_id [dict get $opl_scheids -wedstrijd_id]
    set inp_wedstrijd [set *AR_INP_WEDSTRIJDEN*($wedstrijd_id)]
    set lst_kan_fluiten [dict get $inp_wedstrijd -lst_kan_fluiten]
    for {set j 0} {$j < [llength $lst_kan_fluiten]} {incr j} {
      set inp_kan_fluiten [lindex $lst_kan_fluiten $j]
      set new_opl_scheids [dict create {*}[dict_get_multi -withname $inp_wedstrijd -wedstrijd_id -wedstrijd_naam -datum] \
        {*}[dict_get_multi -withname $inp_kan_fluiten -scheids_id -scheids_naam -zeurfactor -waarde -zelfde_dag]]
      set new_lst_opl_scheids [lreplace $lst_opl_scheids $i $i $new_opl_scheids]
      set new_opl [add_statistics $new_lst_opl_scheids "Check beter" [dict get $sol -solnr]]
      if {[dict get $new_opl -fitness] > $fitness} {
        return 1 
      }
    }
  }
  return 0 ; # geen betere gevonden.
}

proc handle_best_solution {} {
  global *lst_solutions* db log 
  puts "Tot nu toe is onderstaande de best solution:"
  puts_best_solution 
  # eerst alleen printen, later ook in DB bijwerken

  # @note 15-9-2010 voor de zekerheid een DB reconnect, kan te lang geleden zijn. 
  $db reconnect
  
  delete_oude_voorstel
  set best_solution [lindex ${*lst_solutions*} 0]  
  foreach opl_scheids [dict get $best_solution -lst_opl_scheids] {
     $db insert_object scheids -scheids [dict get $opl_scheids -scheids_id] -wedstrijd [dict get $opl_scheids -wedstrijd_id] \
       -speelt_zelfde_dag [dict get $opl_scheids -zelfde_dag] -status "voorstel"
  }
  
}

# deze eigenlijk niet zo nodig in clojure versie: bij nieuwe oplossing wordt deze
# meteen bewaard in DB, hoeft dus niet nogmaals bij ctrl-c.
proc handle_signal {} {
  puts "ctrl-c detected, saving and exiting..."
  handle_best_solution
  exit 1 ; # wel nodig, anders blijft 'ie erin.
}

main $argc $argv


proc log_inp_wedstrijden {lst_inp_wedstrijden} {
  foreach w $lst_inp_wedstrijden {
    puts [dict get $w -wedstrijd_id]
    puts [dict get $w -wedstrijd_naam]
    puts [dict get $w -datum ]
    # puts [dict get $w -zelfde_dag]
    foreach kw [dict get $w -lst_kan_fluiten] {
      puts "  [dict get $kw]" 
    }
    puts "------------------"
  }  
}

