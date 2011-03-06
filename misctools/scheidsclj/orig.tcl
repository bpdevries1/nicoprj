======== LATER DOEN HIERONDER =========

# deze eigenlijk niet zo nodig in clojure versie: bij nieuwe oplossing wordt deze
# meteen bewaard in DB, hoeft dus niet nogmaals bij ctrl-c.
proc handle_signal {} {
  puts "ctrl-c detected, saving and exiting..."
  handle_best_solution
  exit 1 ; # wel nodig, anders blijft 'ie erin.
}

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

