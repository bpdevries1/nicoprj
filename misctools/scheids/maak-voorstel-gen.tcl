#!/home/nico/bin/tclsh

# onderstaande doet inderdaad raar, blijft hangen.
#!/usr/bin/env

package require ndv
package require Tclx
package require struct::list
package require math
package require math::statistics ; # voor bepalen std dev.

::ndv::source_once ScheidsSchemaDef.tcl

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]

######### TODO ###########
# solutions met de hand checken: 
##########################

# 17-9-2010 nu gedaan met generatief algorithme, dan in ieder geval iedereen 1 wedstrijd.

# een solution met lijst van wedstrijden en statistieken over deze solution
# max_scheids: maximum van aantal wedstrijden dat een scheids fluit.

# record binnen lst_kan_fluiten van inp_wedstrijd: wie kan de wedstrijd fluiten?

# naming convention, afgekeken van LISP/Clojure:
# *global* globale variabele, kan veranderen.
# *CONSTANT* globale variable, wordt 1 keer bepaald (evt wel uit DB)

proc main {argc argv} {
  global db conn log ar_argv

  $log debug "argv: $argv"
  set options {
      {pop.arg 10 "Population (number of solutions to keep"}
      {iter.arg 0 "Number of *iteration*s to run (0 is infinite)"}
      {fitness.arg 100000 "Fitness level to reach before stopping"}
      {nmutations "2" "Max number of game/ref changes in a mutation"}
      {loglevel.arg "" "Set global log level"}
      {print.arg "better" "What to print (all, minimum, better)"}
  }
  set usage ": [file tail [info script]] \[options] :"
  array set ar_argv [::cmdline::getoptions argv $options $usage]
  if {$ar_argv(loglevel) != ""} {
    ::ndv::CLogger::set_log_level_all $ar_argv(loglevel)  
  }
  ::ndv::CLogger::set_logfile "playing-scheme.log"
  
  set schemadef [ScheidsSchemaDef::new]
  $schemadef set_db_name_user_password scheids nico "pclip01;"
  set db [::ndv::CDatabase::get_database $schemadef]

  set conn [$db get_connection]
  delete_oude_voorstel
  
  maak_voorstel
}

# @post geen records in tabel 'scheids', met status='voorstel'
proc delete_oude_voorstel {} {
  global db log
  $log debug "Verwijder het oude voorstel, ofwel records in scheids-tabel met status voorstel"
  ::mysql::exec [$db get_connection] "delete from scheids where status = 'voorstel'"
}

# @pre geen records in tabel 'scheids', met status='voorstel'
# @post records aangemaakt in tabel 'scheids', met status='voorstel'
proc maak_voorstel {} {
  # global log best_solution MAX_ZEURFACTOR MAX_WEDSTRIJDEN
  global log ar_argv *best_solution* *lst_solutions* *iteration*
  
  set lst_inp_wedstrijden [query_inp_wedstrijden]
  log_inp_wedstrijden $lst_inp_wedstrijden
  
  puts "NA LOG"
  
  set n_wedstrijden [llength $lst_inp_wedstrijden]
  $log info "Aantal input wedstrijden: $n_wedstrijden"
  
  #set START_SOM_ZEURFACTOREN 5000 ; # 167 ; # even testen, was 1e20, toen 500, vrij goed. (130 ook)
  #set MAX_ZEURFACTOR 600 ; # individueel, dus Gerard 4^3 moet dan niet meer kunnen
  #set MAX_WEDSTRIJDEN 3 ; # max aantal wedstrijden per persoon, 2 lijkt nu te kunnen.
  #set best_solution [dict create -lst_aantallen [list 99] -n_versch_scheids 0 \
  #  -max_scheids $n_wedstrijden -std_n_wedstrijden 0.0 -som_zeurfactoren $START_SOM_ZEURFACTOREN] ; # dan is elke volgende solution beter.
  #puts_best_solution

  # signal handler instellen voor als het te lang duurt.
  signal trap SIGINT handle_signal

  init_globals $lst_inp_wedstrijden
  # @todo hier eerst niets mee doen, geen rekening houden met al geplande wedstrijden.
  # lees_geplande_wedstrijden ; # wordt nu in array bijgewerkt, misschien als los 'object' meegeven aan solution? 
  
  srandom [clock seconds]

  set *lst_solutions* [::ndv::times $ar_argv(pop) {make_solution $lst_inp_wedstrijden}]
  puts_solutions ${*lst_solutions*}

  # breakpoint
  
  # exit
  
  set *iteration* 0
  if {$ar_argv(iter) > 0} {  
    $log info "Calculating for $ar_argv(iter) iterations." 
    ::ndv::times $ar_argv(iter) evol_iteration
  } else {
    # use goal for fitness, also stop when max is reached.
    $log info "Calculating until max reached or fitness >= $ar_argv(fitness)." 
    set best_sol [lindex ${*lst_solutions*} 0]
    set fitness [dict get $best_sol -fitness]
    set max_reached 0 
    # Nu op zoek naar maximale 'fitness'
    while {$fitness < $ar_argv(fitness) && !$max_reached} {
      evol_iteration 
      set best_sol [lindex ${*lst_solutions*} 0]
      set fitness [dict get $best_sol -fitness]
    }
    $log info "Finished!"
    $log info "Max reached: $max_reached"
    $log info "Fitness: $fitness (goal: $ar_argv(fitness))"
  }
  puts "The final solutions:"
  puts_solutions ${*lst_solutions*}  
  # calc_voorstel_gen $lst_inp_wedstrijden {}
  # handle_best_solution
}

# scheids_bezet niet zetten.
proc init_globals {lst_inp_wedstrijden} {
  # @todo ook aantallen, zeurfactoren etc van al echt geplande wedstrijden bijhouden.
  # @todo evt deze proc combineren met lees_geplande_wedstrijden
  # global db conn log ar_scheids_nfluit ar_zeurfactor
  global db conn log *LST_INP_PERSONEN* *AR_INP_WEDSTRIJDEN*
  set query "select p.id, p.naam from persoon p order by p.naam"
  set *LST_INP_PERSONEN* [::struct::list mapfor el [::mysql::sel $conn $query -list] {
    lassign $el scheids_id scheids_naam
    lassign [det_gepland_scheids $scheids_id] nfluit zeurfactor
    # dict create -scheids_id $scheids_id -scheids_naam $scheids_naam -zeurfactor 1.0 -nfluit 0
    dict create -scheids_id $scheids_id -scheids_naam $scheids_naam -zeurfactor $zeurfactor -nfluit $nfluit
  }]
  # breakpoint
  foreach el $lst_inp_wedstrijden {
    set *AR_INP_WEDSTRIJDEN*([dict get $el -wedstrijd_id]) $el 
  }
}

proc query_inp_wedstrijden {} {
  global db conn log 
  # NdV 19-9-2010 queries samenvoegen, want bij alle wedstrijden alle pot. scheidsen ophalen.
  # NdV 14-9-2010 clause kw.waarde > 0.2 toegevoegd, zodat Gert, J.A. en Reza helemaal buiten schot blijven.
  set query "select w.id, w.naam w_naam, date(w.datumtijd) datum
             from wedstrijd w
             where w.scheids_nodig = 1
             and not exists (
                select 1
                from scheids s
                where s.wedstrijd = w.id
                and s.status = 'gemaild'
             )
             order by w.datumtijd"
  set qresult [::mysql::sel $conn $query -list]
  ::struct::list mapfor el $qresult {
    lassign $el w_id w_naam datum 
    dict create -wedstrijd_id $w_id -wedstrijd_naam $w_naam -datum $datum \
       -lst_kan_fluiten [query_lst_kan_fluiten $w_id]
  }
}

proc query_lst_kan_fluiten {w_id} {
  # NdV 14-9-2010 ook hier checken op waarde > 0.2; vraag is waarom beide queries nodig zijn...
  # NdV 19-9-2010 query stuk versimpeld, totaal dan persoon kan fluiten niet zo relevant en zorgde voor fout in query.
  # NdV 19-9-2010 zelfdedag weg, toch alle potentiele scheidsen bij een wedstrijd, anders mogelijk niet genoeg (vroeg 3 wedstr, laat spelen maar 2 scheidsen)
  global db conn log
  set query "select kw.scheids, kw.waarde, p.naam p_naam, zf.factor, kw.speelt_zelfde_dag 
             from kan_wedstrijd_fluiten kw, persoon p, zeurfactor zf
             where p.id = kw.scheids
             and kw.wedstrijd = $w_id
             and kw.waarde > 0.2
             and zf.persoon = p.id
             and zf.speelt_zelfde_dag = kw.speelt_zelfde_dag"
             
  set qresult [::mysql::sel $conn $query -list]
  return [::struct::list mapfor el $qresult {
    lassign $el p_id waarde p_naam zeurfactor zelfde_dag
    dict create -scheids_id $p_id -scheids_naam $p_naam -zelfde_dag $zelfde_dag \
       -waarde $waarde -zeurfactor $zeurfactor 
  }]
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

proc det_gepland_scheids {scheids_id} {
  global db conn log 
  global db conn log ar_scheids_nfluit ar_zeurfactor
  set query "select s.scheids, zf.factor
             from scheids s, zeurfactor zf
             where s.scheids = zf.persoon
             and s.speelt_zelfde_dag = zf.speelt_zelfde_dag
             and s.status = 'gemaild'
             and s.scheids = $scheids_id"
  set qresult [::mysql::sel $conn $query -list]
  set aantal 0
  set factor 1.0
  foreach el $qresult {
    foreach {p_id zeurfactor} $el break
    incr aantal
    set factor [expr $factor * $zeurfactor]
    #incr ar_scheids_nfluit($p_id)
    #set ar_zeurfactor($p_id) [expr $ar_zeurfactor($p_id) * $zeurfactor]
  }
  $log debug "al gepland voor persoon $scheids_id: aantal=$aantal; factor=$factor"
  list $aantal $factor
}

# @todo dit weer meenemen, in global array/list?
# 5 (in dit geval) door Ilse geplande wedstrijden ook meenemen
proc lees_geplande_wedstrijden_old {} {
  global db conn log ar_scheids_nfluit ar_zeurfactor
  set query "select s.scheids, zf.factor
             from scheids s, zeurfactor zf
             where s.scheids = zf.persoon
             and s.speelt_zelfde_dag = zf.speelt_zelfde_dag
             and s.status = 'gemaild'"
  set qresult [::mysql::sel $conn $query -list]
  foreach el $qresult {
    foreach {p_id zeurfactor} $el break
    incr ar_scheids_nfluit($p_id)
    set ar_zeurfactor($p_id) [expr $ar_zeurfactor($p_id) * $zeurfactor]
  }
}

proc compare_solution {a b} {
  if {[dict get $a -fitness] < [dict get $b -fitness]} {
    return -1 
  } elseif {[dict get $a -fitness] > [dict get $b -fitness]} {
    return 1 
  } else {
    return 0 
  }
}

# maak een random solution, wel een valide (?)
# eerste go is zo simpel en random mogelijk: per wedstrijd een willekeurige scheids kiezen
# wel kijken of er zelfdedag mogelijkheden zijn?
proc make_solution {lst_inp_wedstrijden} {
  # set lst_opl_scheids [::ndv::times $nrounds {make_round $ngroups $lst_persons $ncourts}]
  # set lst_opl_scheids [::struct::list map $lst_inp_wedstrijden choose_random_scheids]

  set lst_opl_scheids [::struct::list mapfor el $lst_inp_wedstrijden {
    choose_random_scheids [dict get $el -wedstrijd_id]
  }]

  add_statistics $lst_opl_scheids "Initial solution" 0
}

# klinkt hier ook goed: eerst solution maken, dan bepalen wat de stats zijn en of 'ie goed is.
# @todo in eerste instantie dus alles steeds overnieuw uitrekenen. Lijkt ook mogelijk om bij een delta de waarden sneller uit te rekenen.
proc add_statistics {lst_opl_scheids note solnr_parent} {
  global *LST_INP_PERSONEN*
  # @todo of iets doen als: array set ar_zeurfactor [array get global_ar_zeurfactor]
  foreach p ${*LST_INP_PERSONEN*} {
    set ar_scheids_nfluit([dict get $p -scheids_id]) [dict get $p -nfluit]
    set ar_zeurfactor([dict get $p -scheids_id]) [dict get $p -zeurfactor]
  }
  
  # houd per persoon en datum het aantal wedstrijden bij. Als max hiervan groter dan 1 is, dan ongeldige solution, en fitness + 10000 (bv)  
  foreach opls $lst_opl_scheids {
    set scheids_id [dict get $opls -scheids_id]
    # @note deze arrays beginnen 'gewoon' op 0.
    incr ar_scheids_bezet($scheids_id,[dict get $opls -datum])
    incr ar_scheids_nfluit($scheids_id)
    set ar_zeurfactor($scheids_id) [expr $ar_zeurfactor($scheids_id) * [dict get $opls -zeurfactor] / \
      [dict get $opls -waarde]]
  }
  # set max_wedstrijden_persoon_dag [::math::max {*}[array_values ar_scheids_bezet]]
  # bepaal product van fouten: als geen fouten, dan 1, bij elke fout meer wordt het product groter.
  set prod_wedstrijden_persoon_dag [::math::product {*}[array_values ar_scheids_bezet]]
  set lst_aantallen [lsort -integer -decreasing [array_values ar_scheids_nfluit]]
  set max_scheids [lindex $lst_aantallen 0]
  set n_versch_scheids [llength [::struct::list filterfor el $lst_aantallen {$el > 0}]]
  set lst_zeurfactoren [lsort -real [array_values ar_zeurfactor]]
  set som_zeurfactoren [::math::sum {*}$lst_zeurfactoren]
  set max_zeurfactoren [::math::max {*}$lst_zeurfactoren]
  
  set lst_opl_persoon_info [struct::list mapfor el ${*LST_INP_PERSONEN*} {
    set p_id [dict get $el -scheids_id]
    dict create -scheids_id $p_id -scheids_naam [dict get $el -scheids_naam] \
      -nfluit $ar_scheids_nfluit($p_id) -zeurfactor $ar_zeurfactor($p_id)
  }]
  
  set fitness [calc_fitness $prod_wedstrijden_persoon_dag $max_scheids $n_versch_scheids $som_zeurfactoren $max_zeurfactoren]
  # @todo misschien met uplevel/macro nog iets te doen.
  set sol [dict create -lst_opl_scheids $lst_opl_scheids -note $note \
    -solnr_parent $solnr_parent \
    -fitness $fitness -solnr [new_sol_nr] \
    -prod_wedstrijden_persoon_dag $prod_wedstrijden_persoon_dag \
    -lst_aantallen $lst_aantallen \
    -max_scheids $max_scheids \
    -n_versch_scheids $n_versch_scheids \
    -lst_zeurfactoren $lst_zeurfactoren \
    -som_zeurfactoren $som_zeurfactoren \
    -max_zeurfactoren $som_zeurfactoren \
    -lst_opl_persoon_info $lst_opl_persoon_info
  ]
  return $sol  
}

proc calc_fitness {prod_wedstrijden_persoon_dag max_scheids n_versch_scheids som_zeurfactoren max_zeurfactoren} {
  # max_scheids is het belangrijkst, dan n_versch_scheids, dan som_zeurfactoren
  # breng dus 4 dimensies in 1 dimensie!
  # prod_wedstrijden_persoon_dag: 1..veel minder is beter, alles meer dan 1 is gewoon fout.
  # wel bepalen hoe fout het is, zodat het beter kan worden, als bv 2 personen elk 2x op een dag moeten fluiten.
  # max_scheids: 1..10 minder is beter
  # n_versch_scheids: 1..20 meer is beter
  # som_zeurfactoren: 0..10000 minder is beter
  # door 1-maxwedstrperdag wordt dit deel 0 als het gewoon goed is, en negatief bij fouten.
  # 19-9-2010 NdV max_scheids toch niet zo belangrijk, zelfdedag telt minder dan andere dag, en in zf al rekening mee gehouden.
  # 19-9-2010 NdV zelfde geldt eigenlijk ook voor aantal verschillende scheidsen.
  # 19-9-2010 NdV maar wel de lasten goed verdelen, dus max_zeurfactoren wel belangrijk.
  # expr (1-$prod_wedstrijden_persoon_dag) * 100000 + (10-$max_scheids)*100 + $n_versch_scheids - (0.0001 * $som_zeurfactoren)
  expr (1-$prod_wedstrijden_persoon_dag) * 100000 - $max_zeurfactoren - (0.0001 * $som_zeurfactoren)
}

proc evol_iteration {} {
  global log *lst_solutions* ar_argv *iteration*
  incr *iteration*
  set old_fitness [dict get [lindex ${*lst_solutions*} 0] -fitness]
  set new_solutions [::struct::list map ${*lst_solutions*} mutate_solution]
  # set sorted_solutions [lsort -decreasing -command compare_solution [concat ${*lst_solutions*} $new_solutions]]
  # NdV 27-3-2010 put new solutions first, so that with the same fitness the new ones will survice.
  # $log debug "old solutions: ${*lst_solutions*}"
  set sorted_solutions [lsort -decreasing -command compare_solution [concat $new_solutions ${*lst_solutions*}]]
  if {$ar_argv(print) == "all"} {
    puts "*iteration* ${*iteration*}"
    puts_solutions ${*lst_solutions*}
  } elseif {$ar_argv(print) == "minimum"} {
    # don't print anything 
  } else {
    if {[expr ${*iteration*} % 100] == 0} {
      $log debug "*iteration* ${*iteration*}"
      puts_dot
    }
    if {[dict get [lindex $sorted_solutions 0] -fitness] > $old_fitness} {
      $log info "Found better solution in *iteration* ${*iteration*}, fitness = [dict get [lindex $sorted_solutions 0] -fitness]"
      puts "*iteration* ${*iteration*}"
      puts_solutions ${*lst_solutions*}
    }
  }
  # Alleen de besten overlaten.
  set *lst_solutions* [lrange $sorted_solutions 0 [expr $ar_argv(pop) - 1]]
  set new_fitness [dict get [lindex ${*lst_solutions*} 0] -fitness]
  if {$new_fitness > $old_fitness} {
    handle_best_solution 
  }
}

proc puts_dot {} {
  global stderr
  puts -nonewline stderr "."
  flush stderr
}

# @result: new solution
proc mutate_solution {sol} {
  global ar_argv
  # 19-9-2010 ook meer dan 1 aanpassing doen.
  set lst_opl_scheids [dict get $sol -lst_opl_scheids]
  set nchanges [expr [random_int $ar_argv(nmutations)] + 1]
  for {set i 0} {$i < $nchanges} {incr i} {
    set rnd [random_int [llength $lst_opl_scheids]]
    set wedstrijd_rnd [lindex $lst_opl_scheids $rnd]
    set lst_opl_scheids [lreplace $lst_opl_scheids $rnd $rnd \
      [mutate_wedstrijd $wedstrijd_rnd]]
  }
  add_statistics $lst_opl_scheids "Mutated game [dict get $wedstrijd_rnd -wedstrijd_naam]" [dict get $sol -solnr]
}

# @result: new solution
proc mutate_solution_old {sol} {
  set lst_opl_scheids [dict get $sol -lst_opl_scheids]
  set rnd [random_int [llength $lst_opl_scheids]]
  set wedstrijd_rnd [lindex $lst_opl_scheids $rnd]
  set new_lst_opl_scheids [lreplace $lst_opl_scheids $rnd $rnd \
    [mutate_wedstrijd $wedstrijd_rnd]]
  add_statistics $new_lst_opl_scheids "Mutated game [dict get $wedstrijd_rnd -wedstrijd_naam]" [dict get $sol -solnr]
}

# @return opl_scheids
proc mutate_wedstrijd {opl_scheids} {
  choose_random_scheids [dict get $opl_scheids -wedstrijd_id]
}

# @return opl_scheids
proc choose_random_scheids {wedstrijd_id} {
  global *AR_INP_WEDSTRIJDEN*
  # @note gebruik dubbele $ met {} werkt niet, met set als get werkt het wel
  set inp_wedstrijd [set *AR_INP_WEDSTRIJDEN*($wedstrijd_id)]
  set inp_kan_fluiten [random_list [dict get $inp_wedstrijd -lst_kan_fluiten]]
  
  # 19-9-2010 NdV zelfde_dag waarde nu uit inp_kan_fluiten, niet meer uit inp_wedstrijd.
  dict create {*}[dict_get_multi -withname $inp_wedstrijd -wedstrijd_id -wedstrijd_naam -datum] \
    {*}[dict_get_multi -withname $inp_kan_fluiten -scheids_id -scheids_naam -zeurfactor -waarde -zelfde_dag]
}


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

proc puts_solutions {*lst_solutions*} {
  foreach sol ${*lst_solutions*} {
    puts_solution $sol 
  }
  puts_best_solution
}

proc puts_best_solution {} {
  # global *best_solution* log
  global *lst_solutions* log
  puts "Beste oplossing tot nu toe:"
  puts_solution [lindex ${*lst_solutions*} 0]
}

proc puts_solution {opl} {
  global log
  puts "Oplossing [dict get $opl -solnr] (parent: [dict get $opl -solnr_parent])"
  puts "Fitness: [dict get $opl -fitness]"
  puts "Maximum aantal wedstrijden voor een scheidsrechter op een dag: [dict get $opl -prod_wedstrijden_persoon_dag]"
  puts "Som van zeurfactoren: [dict get $opl -som_zeurfactoren]"
  puts "Lijst van zeurfactoren: [dict get $opl -lst_zeurfactoren]"
  puts "Aantal wedstrijden per scheidsrechter: [dict get $opl -lst_aantallen]"
  puts "Maximum aantal wedstrijden voor een scheidsrechter: [dict get $opl -max_scheids]"
  puts "Aantal verschillende scheidsrechters: [dict get $opl -n_versch_scheids]"
  # puts "Standaard deviatie van aantal wedstrijden per scheids: [format %.3f [dict get $opl -std_n_wedstrijden]]"
  puts "Wedstrijden:"
  foreach opl_scheids [dict get $opl -lst_opl_scheids] {
    # puts [join [dict get $opl_scheids] "\t"]
    puts [opl_scheids_to_string $opl_scheids]
  }
  puts "-----------"
  puts "Info per scheids:"
  foreach el [dict get $opl -lst_opl_persoon_info] {
    puts "#[dict get $el -nfluit] zf=[format %6.1f [dict get $el -zeurfactor]] : [dict get $el -scheids_naam]" 
  }
  if {[kan_naar_betere $opl]} {
    puts "Vanuit deze oplossing is een BETERE te vinden met 1 change..." 
  } else {
    puts "Vanuit deze oplossing is GEEN betere te vinden met 1 change..."
  }
  puts "\n============\n"
}

proc opl_scheids_to_string {opl_scheids} {
  set o $opl_scheids
  return "[dict get $o -wedstrijd_naam] (zd=[dict get $o -zelfde_dag]) \
    [dict get $o -scheids_naam] ([scheids_afko [dict get $o -scheids_naam]]) (zf=[dict get $o -zeurfactor]/[dict get $o -waarde]) \
    ([join [kan_scheidsen [dict get $o -wedstrijd_id]] ", "])"
}

# @return lijst van afko's van scheidsen die een wedstrijd kunnen fluiten, gesorteerd.
proc kan_scheidsen {wedstrijd_id} {
  global *AR_INP_WEDSTRIJDEN*
  struct::list mapfor el [dict get [set *AR_INP_WEDSTRIJDEN*($wedstrijd_id)] -lst_kan_fluiten] {
    scheids_afko [dict get $el -scheids_naam] 
  }
}

proc scheids_afko {scheids_naam} {
  join [::struct::list mapfor el [split $scheids_naam " "] {string range $el 0 0}] "" 
}

proc handle_signal {} {
  puts "ctrl-c detected, saving and exiting..."
  handle_best_solution
  exit 1 ; # wel nodig, anders blijft 'ie erin.
}

set sol_nr 0
proc new_sol_nr {} {
  global sol_nr
  incr sol_nr
  return $sol_nr
}

main $argc $argv
