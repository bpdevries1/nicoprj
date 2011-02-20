#!/home/nico/bin/tclsh

# onderstaande doet inderdaad raar, blijft hangen.
#!/usr/bin/env

#package require ndv
package require ndv
package require Tclx
package require struct::list
package require struct::record
package require math
package require math::statistics ; # voor bepalen std dev.

::ndv::source_once ScheidsSchemaDef.tcl

# kan door onderstaande record gebruiken, ipv ::struct::record
namespace import ::struct::record::*

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]

######### TODO ###########
# oplossingen met de hand checken: 
# Astrid niet op niet-speelddag
# Rob van Zonneveld niet tegelijk met Dames 1
##########################

# een oplossing met lijst van wedstrijden en statistieken over deze oplossing
# @todo? ook lijst van scheids en aantal wedstrijden dat 'ie fluit, ook op dezelfde dag. Maar dit ook wel uit DB te query-en.
# max_scheids: maximum van aantal wedstrijden dat een scheids fluit.
record define rec_oplossing {
  lst_opl_scheids
  lst_aantallen
  n_versch_scheids
  std_n_wedstrijden
  max_scheids
  som_zeurfactoren
}

record define opl_scheids {
  wedstrijd_id
  wedstrijd_naam
  scheids_id
  scheids_naam
  zelfde_dag
}

record define inp_wedstrijd {
   wedstrijd_id
   wedstrijd_naam
   datum
   zelfde_dag
   lst_kan_fluiten
}

# record binnen lst_kan_fluiten van inp_wedstrijd: wie kan de wedstrijd fluiten?
# n_kan_fluiten => aantal wedstrijden die scheids totaal kan fluiten voor waarde van zelfde dag!
# @note geen comment achter de field-defs, want dan worden dit ook field-defs....
record define inp_kan_fluiten {
  scheids_id
  scheids_naam
  zelfde_dag
  waarde
  zeurfactor
  n_kan_fluiten
}

proc main {} {
  global db conn log

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
  $log debug "Verwijder het oude voorstel, ofwel records in scheids-tabel"
  ::mysql::exec [$db get_connection] "delete from scheids where status = 'voorstel'"
}

# @pre geen records in tabel 'scheids', met status='voorstel'
# @post records aangemaakt in tabel 'scheids', met status='voorstel'
proc maak_voorstel {} {
  global log beste_oplossing MAX_ZEURFACTOR MAX_WEDSTRIJDEN
  set lst_wedstrijden_input [query_wedstrijden_input]
  log_input_wedstrijden $lst_wedstrijden_input
  set n_wedstrijden [llength $lst_wedstrijden_input]
  $log info "Aantal input wedstrijden: $n_wedstrijden"
  
  set START_SOM_ZEURFACTOREN 5000 ; # 167 ; # even testen, was 1e20, toen 500, vrij goed. (130 ook)
  set MAX_ZEURFACTOR 60 ; # individueel, dus Gerard 4^3 moet dan niet meer kunnen
  set MAX_WEDSTRIJDEN 2 ; # max aantal wedstrijden per persoon, 2 lijkt nu te kunnen.
  set beste_oplossing [rec_oplossing #auto -lst_aantallen [list 99] -n_versch_scheids 0 \
    -max_scheids $n_wedstrijden -std_n_wedstrijden 0.0 -som_zeurfactoren $START_SOM_ZEURFACTOREN] ; # dan is elke volgende oplossing beter.
  puts_beste_oplossing

  # signal handler instellen voor als het te lang duurt.
  signal trap SIGINT handle_signal

  init_arrays
  lees_geplande_wedstrijden
  calc_voorstel_rec $lst_wedstrijden_input {}
  handle_beste_oplossing
}

# scheids_bezet niet zetten.
proc init_arrays {} {
  global db conn log ar_scheids_nfluit ar_zeurfactor
  set query "select p.id from persoon p"
  foreach p_id [::mysql::sel $conn $query -flatlist] {
    set ar_scheids_nfluit($p_id) 0
    set ar_zeurfactor($p_id) 1.0
  }
}

proc query_wedstrijden_input {} {
  global db conn log
  
  set lst_result {}
  
  # 1. kandidaten die op dezelfde dag spelen.
  set query "select w.id, w.naam w_naam, date(w.datumtijd) datum, count(kw.id)
             from wedstrijd w, kan_wedstrijd_fluiten kw
             where w.id = kw.wedstrijd
             and w.scheids_nodig = 1
             and kw.speelt_zelfde_dag = 1
             and not exists (
                select 1
                from scheids s
                where s.wedstrijd = w.id
                and s.status = 'gemaild'
             )  
             group by 1,2,3
             having count(kw.id) > 0
             order by 4, 3, 1"
  set qresult [::mysql::sel $conn $query -list]
  set lst_res1 [::struct::list mapfor el $qresult {
    foreach {w_id w_naam datum aantal} $el break
    inp_wedstrijd #auto -wedstrijd_id $w_id -wedstrijd_naam $w_naam -datum $datum -zelfde_dag 1 \
       -lst_kan_fluiten [query_lst_kan_fluiten $w_id 1]
  }]


  # 2. moeilijke wedstrijden, zonder kandidaat voor zelfde dag.
  set query "select w.id, w.naam w_naam, date(w.datumtijd) datum, count(kw.id)
             from wedstrijd w, kan_wedstrijd_fluiten kw
             where w.id = kw.wedstrijd
             and w.scheids_nodig = 1
             and kw.speelt_zelfde_dag = 0
             and not exists (
                select 1
                from scheids s
                where s.wedstrijd = w.id
                and s.status = 'gemaild'
             )
             and not exists (
                select 1
                from kan_wedstrijd_fluiten kw2
                where kw2.wedstrijd = w.id
                and kw2.speelt_zelfde_dag = 1
             )
             group by 1,2,3
             having count(kw.id) > 0
             order by 4, 3, 1"
  set qresult [::mysql::sel $conn $query -list]
  # foreach-append kan ook met struct::list mapfor, maar dit is nog wel overzichtelijk.
  set lst_res2 [::struct::list mapfor el $qresult {
    foreach {w_id w_naam datum aantal} $el break
    inp_wedstrijd #auto -wedstrijd_id $w_id -wedstrijd_naam $w_naam -datum $datum -zelfde_dag 0 \
       -lst_kan_fluiten [query_lst_kan_fluiten $w_id 0] 
  }]
  
  # normale volgorde
  return [concat $lst_res1 $lst_res2]
  # eens gek doen, toch eerst de moeilijke wedstrijden...
  # return [concat $lst_res2 $lst_res1]
}

proc query_lst_kan_fluiten {w_id zelfde_dag} {
  global db conn log
  set query "select kw.scheids, kw.waarde, count(kw2.scheids), p.naam p_naam, zf.factor
             from kan_wedstrijd_fluiten kw, kan_wedstrijd_fluiten kw2, persoon p, zeurfactor zf
             where kw.scheids = kw2.scheids
             and p.id = kw.scheids
             and kw.wedstrijd = $w_id
             and kw2.speelt_zelfde_dag = $zelfde_dag
             and zf.persoon = p.id
             and zf.speelt_zelfde_dag = $zelfde_dag
             group by 1,2,4,5
             order by 2 desc, 5, 3, 1"
  set qresult [::mysql::sel $conn $query -list]
  return [::struct::list mapfor el $qresult {
    foreach {p_id waarde aantal p_naam zeurfactor} $el break
    inp_kan_fluiten #auto -scheids_id $p_id -scheids_naam $p_naam -zelfde_dag $zelfde_dag \
       -waarde $waarde -n_kan_fluiten $aantal -zeurfactor $zeurfactor 
  }]
}

proc log_input_wedstrijden {lst_wedstrijden_input} {
  foreach w $lst_wedstrijden_input {
    puts [$w cget -wedstrijd_id -wedstrijd_naam -datum -zelfde_dag]
    foreach kw [$w cget -lst_kan_fluiten] {
      puts "  [$kw cget]" 
    }
    puts "------------------"
  }  
}

# 5 (in dit geval) door Ilse geplande wedstrijden ook meenemen
proc lees_geplande_wedstrijden {} {
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

# pre: lst_wedstrijden_to_place kan al leeg zijn.
# @todo: ook deel-oplossing checken, of zeurfactor al niet te hoog is.
proc calc_voorstel_rec {lst_wedstrijden_to_place lst_opl_scheids} {
  # ar_scheids_bezet(scheids_id,datum) = 1
  # ar_scheids_nfluit(scheids_id) = 0..max
  global ar_scheids_bezet ar_scheids_nfluit ar_zeurfactor
  
  # ook de deeloplossing checken op som van zeurfactoren: als al te groot, dan hoef je niet verder te zoeken.
  if {[som_zeurfactoren_te_groot]} {
    return 
  }
  
  if {[llength $lst_wedstrijden_to_place] == 0} {
    handle_oplossing $lst_opl_scheids
    return
  }
  set inp_wedstrijd [lindex $lst_wedstrijden_to_place 0]
  set datum [$inp_wedstrijd cget -datum]
  foreach inp_kan_fluiten [$inp_wedstrijd cget -lst_kan_fluiten] {
    set scheids_id [$inp_kan_fluiten cget -scheids_id]
    incr ar_scheids_bezet($scheids_id,$datum)
    if {$ar_scheids_bezet($scheids_id,$datum) == 1} {
      incr ar_scheids_nfluit($scheids_id)
      set ar_zeurfactor($scheids_id) [expr $ar_zeurfactor($scheids_id) * [$inp_kan_fluiten cget -zeurfactor]] 
      set lst_opl_scheids_plus1 $lst_opl_scheids
      set opl_scheids_nw [opl_scheids #auto -wedstrijd_id [$inp_wedstrijd cget -wedstrijd_id] \
        -scheids_id $scheids_id -zelfde_dag [$inp_kan_fluiten cget -zelfde_dag] \
        -wedstrijd_naam [$inp_wedstrijd cget -wedstrijd_naam] -scheids_naam [$inp_kan_fluiten cget -scheids_naam]]
      lappend lst_opl_scheids_plus1 $opl_scheids_nw
      calc_voorstel_rec [lrange $lst_wedstrijden_to_place 1 end] $lst_opl_scheids_plus1 
      $opl_scheids_nw destroy
      incr ar_scheids_nfluit($scheids_id) -1  
      set ar_zeurfactor($scheids_id) [expr $ar_zeurfactor($scheids_id) / [$inp_kan_fluiten cget -zeurfactor]] 
    } else {
      # waarde in array is 2, ofwel scheids/datum combi is al bezet. 
    }
    incr ar_scheids_bezet($scheids_id,$datum) -1
  }
}

proc som_zeurfactoren_te_groot {} { 
  global log beste_oplossing MAX_ZEURFACTOR ar_scheids_nfluit MAX_WEDSTRIJDEN
  if {[det_som_zeurfactoren] >= [$beste_oplossing cget -som_zeurfactoren]} {
    return 1 
  } else {
    # ook kijken of individuele factoren niet te groot zijn.
    if {[::math::max {*}[det_list_zeurfactoren]] > $MAX_ZEURFACTOR} {
      return 1 
    } else {
      # ook nog kijken naar max wedstrijden per persoon
      set lst_aantallen [::struct::list mapfor scheids_id [array names ar_scheids_nfluit] {
        expr $ar_scheids_nfluit($scheids_id)    
      }]
      set max_scheids [::math::max {*}$lst_aantallen] ; # kan niet een list meegeven, moet als losse parameters, dus {*}
      # $log debug "max_scheids: $max_scheids"
      if {$max_scheids > $MAX_WEDSTRIJDEN} {
        return 1 
      } else {      
        return 0
      }
    }
  }
}

proc det_som_zeurfactoren {} {
  global log
  set lst_zeurfactoren [det_list_zeurfactoren]
  return [::math::sum {*}$lst_zeurfactoren]
}

proc det_list_zeurfactoren {} {
  global log ar_zeurfactor 
  return [::struct::list mapfor scheids_id [array names ar_zeurfactor] {
    expr $ar_zeurfactor($scheids_id)    
  }]
  
}

proc handle_oplossing {lst_opl_scheids} {
  global log beste_oplossing ar_scheids_bezet ar_scheids_nfluit ar_zeurfactor MAX_WEDSTRIJDEN 

  if {0} {
    set lst_zeurfactoren [::struct::list mapfor scheids_id [array names ar_zeurfactor] {
      expr $ar_zeurfactor($scheids_id)    
    }]
    set som_zeurfactoren [::math::sum {*}$lst_zeurfactoren]
  }
  set som_zeurfactoren [det_som_zeurfactoren]
  set lst_aantallen [::struct::list mapfor scheids_id [array names ar_scheids_nfluit] {
    expr $ar_scheids_nfluit($scheids_id)    
  }]
  set lst_aantallen [lsort  -integer -decreasing [::struct::list filterfor el $lst_aantallen {$el > 0}]]
  if {$som_zeurfactoren < [$beste_oplossing cget -som_zeurfactoren]} {
    set max_scheids [::math::max {*}$lst_aantallen] ; # kan niet een list meegeven, moet als losse parameters, dus {*}
    if {$max_scheids > 9} {
      # kan ook iets doen dat deze oplossing dan stiekem toch niet de beter is
      $log critical "Max groter dan 9, lijst compare niet meer goed, doe bugfix!"
      exit
    }
    set stdev [::math::statistics::pstdev $lst_aantallen]
    $log debug "Nieuwe beste oplossing"
    set lst_zeurfactoren [::struct::list mapfor scheids_id [array names ar_zeurfactor] {
      expr $ar_zeurfactor($scheids_id)    
    }]
    $log debug "Lijst van product van zeurfactoren: $lst_zeurfactoren"
    $beste_oplossing configure -lst_aantallen $lst_aantallen -max_scheids $max_scheids -n_versch_scheids [llength $lst_aantallen] \
      -std_n_wedstrijden $stdev -lst_opl_scheids $lst_opl_scheids -som_zeurfactoren $som_zeurfactoren
    puts_beste_oplossing
  } else {
    # $log debug "slechtere oplossing"
    # $log debug "lst_nw: $lst_aantallen"
    # $log debug "lst_oud: [$beste_oplossing cget -lst_aantallen]"
    # exit 1
  }
}

proc handle_oplossing_old {lst_opl_scheids} {
  global beste_oplossing ar_scheids_bezet ar_scheids_nfluit log
  set lst_aantallen [::struct::list mapfor scheids_id [array names ar_scheids_nfluit] {
    expr $ar_scheids_nfluit($scheids_id)    
  }]
  set lst_aantallen [lsort  -integer -decreasing [::struct::list filterfor el $lst_aantallen {$el > 0}]]
  if {$lst_aantallen < [$beste_oplossing cget -lst_aantallen]} {
    # meteen duidelijk dat dit een beter is
    set max_scheids [::math::max {*}$lst_aantallen] ; # kan niet een list meegeven, moet als losse parameters, dus {*}
    if {$max_scheids > 9} {
      # kan ook iets doen dat deze oplossing dan stiekem toch niet de beter is
      $log fatal "Max groter dan 9, lijst compare niet meer goed, doe bugfix!"
      exit
    }
    set stdev [::math::statistics::pstdev $lst_aantallen]
    $beste_oplossing configure -lst_aantallen $lst_aantallen -max_scheids $max_scheids -n_versch_scheids [llength $lst_aantallen] \
      -std_n_wedstrijden $stdev -lst_opl_scheids $lst_opl_scheids
    puts_beste_oplossing
  } else {
    # $log debug "slechtere oplossing"
    # $log debug "lst_nw: $lst_aantallen"
    # $log debug "lst_oud: [$beste_oplossing cget -lst_aantallen]"
    # exit 1
  }
}

proc handle_oplossing_old2 {lst_opl_scheids} {
  global beste_oplossing ar_scheids_bezet ar_scheids_nfluit log
  set lst_aantallen [::struct::list mapfor scheids_id [array names ar_scheids_nfluit] {
    expr $ar_scheids_nfluit($scheids_id)    
  }]
  set lst_aantallen [::struct::list filterfor el $lst_aantallen {$el > 0}]
  set max_scheids [::math::max {*}$lst_aantallen] ; # kan niet een list meegeven, moet als losse parameters, dus {*}
  # $log debug "max_scheids: $max_scheids"
  set beter 0
  if {$max_scheids < [$beste_oplossing cget -max_scheids]} {
    set beter 1 
    set stdev [::math::statistics::pstdev $lst_aantallen]
  } elseif {$max_scheids == [$beste_oplossing cget -max_scheids]} {
    if {[llength $lst_aantallen] > [$beste_oplossing cget -n_versch_scheids]} {
      $log debug "#verschillende is meer, sowieso beter"
      set stdev [::math::statistics::pstdev $lst_aantallen]
      set beter 1
    } elseif {[llength $lst_aantallen] == [$beste_oplossing cget -n_versch_scheids]} {
      set stdev [::math::statistics::pstdev $lst_aantallen]
      # $log debug "#verschillende is goed, nu stdev = $stdev"
      if {$stdev < [$beste_oplossing cget -std_n_wedstrijden]} {
        # deze nieuwe is beter
        set beter 1
      }
    }
  }
  if {$beter} {
    $log debug "lst_aantallen: $lst_aantallen"
    $beste_oplossing configure -max_scheids $max_scheids -n_versch_scheids [llength $lst_aantallen] \
      -std_n_wedstrijden $stdev -lst_opl_scheids $lst_opl_scheids
    puts_beste_oplossing
    
  }
  
}


proc handle_beste_oplossing {} {
  global beste_oplossing db log 
  puts "Uiteindelijk is onderstaande de beste oplossing:"
  puts_beste_oplossing 
  # eerst alleen printen, later ook in DB bijwerken

  delete_oude_voorstel
  
  foreach opl_scheids [$beste_oplossing cget -lst_opl_scheids] {
     $db insert_object scheids -scheids [$opl_scheids cget -scheids_id] -wedstrijd [$opl_scheids cget -wedstrijd_id] \
       -speelt_zelfde_dag [$opl_scheids cget -zelfde_dag] -status "voorstel"
  }
  
}

proc puts_beste_oplossing {} {
  global beste_oplossing log
  $log info "Oplossing"
  puts "Som van zeurfactoren: [$beste_oplossing cget -som_zeurfactoren]"
  puts "Aantal wedstrijden per scheidsrechter: [$beste_oplossing cget -lst_aantallen]"
  puts "Maximum aantal wedstrijden voor een scheidsrechter: [$beste_oplossing cget -max_scheids]"
  puts "Aantal verschillende scheidsrechters: [$beste_oplossing cget -n_versch_scheids]"
  puts "Standaard deviatie van aantal wedstrijden per scheids: [format %.3f [$beste_oplossing cget -std_n_wedstrijden]]"
  puts "Wedstrijden:"
  foreach opl_scheids [$beste_oplossing cget -lst_opl_scheids] {
    puts [join [$opl_scheids cget] "\t"] 
  }
  puts "-----------"
  puts "\n============\n"
}

proc handle_signal {} {
  puts "ctrl-c detected, saving and exiting..."
  handle_beste_oplossing
  exit 1 ; # wel nodig, anders blijft 'ie erin.
}




main