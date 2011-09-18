#!/home/nico/bin/tclsh

# @todo waarsch bug in mysqltcl, waardoor é etc niet goed in mysql db terechtkomen. Wel goed in html, ook goed in log (utf-8), niet goed in DB, zowel in 
# sql explorer als in web2py.

package require ndv
package require http
package require htmlparse
package require struct::tree
package require struct::list
package require Tclx

::ndv::source_once ScheidsSchemaDef.tcl

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]

proc main {argc argv} {
  global db conn log ar_argv
  
  $log debug "argv: $argv"
  set options {
      {seizoen.arg "2011-2012" "Welk seizoen (directory)"}
      {fromsite  "Haal gegevens opnieuw van NeVoBo site"}
      {cleandb "Leeg database voor inlezen"}
      {insert2ndhalf "Voeg wedstrijden van 2e helft in, laat rest staan."}
      {loglevel.arg "" "Set global log level"}
  }
  set usage ": [file tail [info script]] \[options] :"
  array set ar_argv [::cmdline::getoptions argv $options $usage]
  if {$ar_argv(loglevel) != ""} {
    ::ndv::CLogger::set_log_level_all $ar_argv(loglevel)  
  }
  ::ndv::CLogger::set_logfile "insert-input.log"
  set seizoen $ar_argv(seizoen)
  file mkdir $seizoen
  
  set schemadef [ScheidsSchemaDef::new]
  $schemadef set_db_name_user_password scheids nico "pclip01;"
  set db [::ndv::CDatabase::get_database $schemadef]
  set conn [$db get_connection]
  if {$ar_argv(cleandb)} {
    empty_db
  }
  if {$ar_argv(insert2ndhalf)} {
    remove_unassigned_games  
  } else {
    # hele seizoen
    insert_teams
    insert_personen $seizoen
    insert_afwezig
    insert_persoon_team
  }
  insert_team_wedstrijden $seizoen $ar_argv(insert2ndhalf)
  # delete_wedstrijden_2011
  insert_kan_wedstrijd_fluiten
  
  rapportage
}

proc empty_db {} {
  global log
  $log info "Empty_db: leeg alle db tabellen"
  foreach table {kan_wedstrijd_fluiten scheids wedstrijd afwezig kan_team_fluiten zeurfactor persoon_team persoon team} {
    exec_query "delete from $table;" 
  }
}

proc delete_wedstrijden_2011 {} {
  global log
  $log info "Verwijder alle wedstrijden in of na 2011"
  exec_query "delete from wedstrijd where datumtijd > '2011-01-01'" 
}

proc insert_teams {} {
  global db
  foreach hd {H D} {
    foreach nr {1 2 3 4} {
      # @todo hier nieuwe ifelse functie voor gebruiken (18-9-2011)
      if {[lsearch {H1 H2} "$hd$nr"] >= 0} {
        set scheids_nodig 0
      } else {
        set scheids_nodig 1
      }
      $db insert_object team -naam "$hd$nr" -scheids_nodig $scheids_nodig
    }
  }
}

proc insert_personen {seizoen} {
  # global seizoen
  lees_tsv "$seizoen/scheids.tsv" handle_scheids 
}

proc handle_scheids {line lst_names ar_values_name} {
  global db log
  upvar $ar_values_name ar_values
  if {0} {
    $log debug "line: $line"
    foreach name $lst_names {
      puts -nonewline "$name: $ar_values($name); " 
    }
    puts ""
  }
  if {$ar_values(Naam) != ""} {
    if {$ar_values(team) != ""} {
      set team_id [lindex [$db find_objects team -naam $ar_values(team)] 0]  
    } else {
      set team_id "" 
    }
    if {$team_id == ""} {
      set persoon_id [$db insert_object persoon -naam $ar_values(Naam) -email $ar_values(email) \
        -telnrs $ar_values(telnr) -opmerkingen [$db str_to_db $ar_values(opmerkingen)]]
      
    } else {
      set persoon_id [$db insert_object persoon -naam $ar_values(Naam) -email $ar_values(email) \
        -telnrs $ar_values(telnr) -speelt_in $team_id -opmerkingen [$db str_to_db $ar_values(opmerkingen)]]
    }
    foreach hd {H D} {
      foreach nr {1 2 3 4} {
        set team_naam "$hd$nr"
        set waarde $ar_values($team_naam) 
        # vervang evt , door .
        regsub -all {,} $waarde "." waarde
        if {$waarde > 0} {
           set team_id [lindex [$db find_objects team -naam $team_naam] 0]
           $db insert_object kan_team_fluiten -scheids $persoon_id -team $team_id -waarde $waarde
        }
      }
    }
    # zeurfactoren
    if {$ar_values(zf_andere) != ""} {
      set waarde $ar_values(zf_andere)
      regsub -all {,} $waarde "." waarde
      $db insert_object zeurfactor -persoon $persoon_id -speelt_zelfde_dag 0 -factor $waarde
    }
    if {$ar_values(zf_zelfde) != ""} {
      set waarde $ar_values(zf_zelfde)
      regsub -all {,} $waarde "." waarde
      $db insert_object zeurfactor -persoon $persoon_id -speelt_zelfde_dag 1 -factor $waarde
    }
  }
}

# onderstaande in lib zetten
# vooralsnog handmatig hardcoded in deze proc.
proc insert_afwezig {} {
  insert_afwezig_persoon "Nico de Vreeze" "Bruiloft" "2011-09-30"  
  insert_afwezig_persoon "Nico de Vreeze" "Vakantie" "2011-11-26" "2011-12-17" 

  insert_afwezig_persoon "Margriet Drent" "Bruiloft" "2011-09-30" 

  # Chris is eigenlijk de enige die kan op 13-4, maar wil daar een invaller plaatsen
  insert_afwezig_persoon "Chris Meijer" "Forced afwezig" "2012-04-13"
  
  # regio scheidsen - 1e scheids
  insert_afwezig_persoon "Reza Gharsi" "Regiowedstrijd 1e" "2011-10-14" 
  insert_afwezig_persoon "Reza Gharsi" "Regiowedstrijd 1e" "2011-10-01"
  insert_afwezig_persoon "Gert van de Meent" "Regiowedstrijd 1e" "2011-10-27"
  insert_afwezig_persoon "Jan-Albert Kootstra" "Regiowedstrijd 1e" "2011-10-01"
  insert_afwezig_persoon "Jan-Albert Kootstra" "Regiowedstrijd 1e" "2011-10-08"
  
  # regio scheidsen - 2e scheids
  insert_afwezig_persoon "Reza Gharsi" "Regiowedstrijd 2e" "2011-10-15"
  insert_afwezig_persoon "Jan-Albert Kootstra" "Regiowedstrijd 2e" "2011-09-24"
  insert_afwezig_persoon "Jan-Albert Kootstra" "Regiowedstrijd 2e" "2011-10-15"
  
  # insert_afwezig_persoon "Maarten Wispelwey" "2010-10-08" "2010-10-08" "Coach D1"
  # in 2010 heeft Maarten de kinderen in de oneven weken, dan dus afwezig.
  # bepaal eerste afwezig, dan steeds 14d erbij.
  # 17-9-2010 is week 37, dus oneven, dus afwezig
  
  insert_afwezig_maarten
}

proc insert_afwezig_maarten {} {
  set datum "2011-09-23" ; # week 38, maarten even weken de kinderen.
  while {$datum <= "2012"} {
    insert_afwezig_persoon "Maarten Wispelwey" "Kinderen" $datum
    set sec [clock scan $datum -format "%Y-%m-%d"]
    set sec_2w [expr $sec + (2 * 7 * 24 * 60 * 60)] ; # 2 weken verder zetten.
    set datum [clock format $sec_2w -format "%Y-%m-%d"]
  }  
}

proc insert_afwezig_persoon {persoon opmerkingen eerstedag {laatstedag ""}} {
  global db log
  if {$laatstedag == ""} {
    set laatstedag $eerstedag 
  }
  set p_id [lindex [$db find_objects persoon -naam $persoon] 0]
  $db insert_object afwezig -persoon $p_id -eerstedag $eerstedag -laatstedag $laatstedag -opmerkingen $opmerkingen  
}

proc insert_afwezig_persoon_old {persoon eerstedag laatstedag opmerkingen} {
  global db log
  set p_id [lindex [$db find_objects persoon -naam $persoon] 0]
  $db insert_object afwezig -persoon $p_id -eerstedag $eerstedag -laatstedag $laatstedag -opmerkingen $opmerkingen  
}

proc insert_persoon_team {} {
  # nieuwe tabel, persoon kan met meer dan 1 team te maken hebben. Eerst vullen obv speelt_in-veld in persoon.
  # queries eerst los uitvoeren
  exec_query "insert into persoon_team (persoon, team, soort)
    select p.id, p.speelt_in, 'speler'
    from persoon p
    where p.speelt_in is not null"

  # handmatig nog een paar
  insert_team_persoon "Maarten Wispelwey" "D1" "coach"  
}

proc insert_team_persoon {persoon team soort} {
  global db log
  set p_id [lindex [$db find_objects persoon -naam $persoon] 0]
  set t_id [lindex [$db find_objects team -naam $team] 0]
  $db insert_object persoon_team -persoon $p_id -team $t_id -soort $soort
}


proc insert_team_wedstrijden {seizoen insert2ndhalf} {
  # global log db seizoen
  global log db ar_argv
  # NdV 14-9-2010.
  # op 1 zetten bij opnieuw van site halen van de wedstrijden, dan ook oude weghalen.
  if {$ar_argv(fromsite)} {
    # verwijder oude bestanden, wildcard lijkt niet te werken.
    foreach hd {H D} {
      foreach filename [glob -nocomplain -directory $seizoen "${hd}*"] {
        file delete $filename 
      }
    }
    foreach hd {H D} {
      foreach nr {1 2 3 4} {
        # 2009-2010
        # set url "http://competitie.nevobo.nl/holland/team/3258${hd}S+${nr}?programma=true" 
        # 2010-2011
        # set url "http://competitie.nevobo.nl/west/team/3258${hd}S+${nr}?programma=true"
        # 2011-2012, ical formaat
        set url "http://www.volleybal.nl/application/handlers/export.php?format=ical&type=team&programma=3258${hd}S+${nr}&iRegionId=3000"
        set filename "$seizoen/${hd}${nr}-[clock format [clock seconds] -format "%Y-%m-%d-%H-%M-%S"].ics"
        http_to_file $url $filename
        # insert_wedstrijden $filename
      }
    }
  }
  
  if {0} {
    # 18-9-2011 date_last_assigned nu even onduidelijk, nog nodig?
    if {$insert2ndhalf} {
      set date_last_assigned [det_date_last_assigned] ; # waarsch string representatie van date. 
    } else {
      set date_last_assigned "2009-01-01" 
    }
    $log debug "date_last_assigned: $date_last_assigned"
    # breakpoint
    set sec_date_last_assigned [clock scan $date_last_assigned -format "%Y-%m-%d %H:%M:%S"]
  }
  foreach hd {H D} {
    # 18-9-2011 bij onderstaande glob wel een fout, als er niets gevonden is.
    foreach filename [glob -directory $seizoen "${hd}*"] {
      # insert_wedstrijden $filename $sec_date_last_assigned
      insert_wedstrijden $filename
    }
  }
  
  if {0} {
    # 28-12-2010 even inhaalwedstrijd van heren 3 tegen Oberon
    set team_id [lindex [$db find_objects team -naam "H3"] 0]
  
    $db insert_object wedstrijd -naam "Wilhelmina HS 3 - Oberon" -team $team_id -lokatie "thuis" \
          -datumtijd "2011-01-10 21:00:00" -scheids_nodig 1 -opmerkingen "Inhaalwedstrijd"
  }  
}

proc det_date_last_assigned {} {
  global db conn
  lindex [mysql::sel $conn "select max(datumtijd) from wedstrijd" -flatlist] 0
}

# old param: sec_from_date
proc insert_wedstrijden {filename} {
  global log
  
  set f [open $filename r]
  while {![eof $f]} {
    gets $f line 
    # DTSTART:20110923T214500
    # SUMMARY:Oberon DS 1 - Wilhelmina DS 1
    if {[regexp {^DTSTART:(.+)$} $line z ts]} {
      set sec_timestamp [clock scan $ts -format "%Y%m%dT%H%M%S"]
    } elseif {[regexp {^SUMMARY:(.+)$} $line z summary]} {
      set wedstrijd_naam "[clock format $sec_timestamp -format "%Y-%m-%d %H:%M:%S"] $summary"
      set team_naam [det_team_naam $summary]
      set opmerkingen $summary
    } elseif {[regexp {^LOCATION:(.+)$} $line z loc]} {
      set lokatie [det_lokatie $loc]
    } elseif {[regexp {^BEGIN:VEVENT$} $line z summary]} {
      set sec_timestamp ""
      set wedstrijd_naam ""
      set team_naam ""
      set lokatie ""
      set opmerkingen ""
    } elseif {[regexp {^END:VEVENT$} $line z summary]} {
      upsert_db $wedstrijd_naam $team_naam $lokatie $sec_timestamp $opmerkingen
    }      
  }  
  close $f
}

proc upsert_db {wedstrijd_naam team_naam lokatie sec_timestamp opmerkingen} {
  global db
  set team_id [lindex [$db find_objects team -naam $team_naam] 0]
  set scheids_nodig [det_scheids_nodig $team_id $lokatie]
  set lst_ids [$db find_objects wedstrijd -naam $wedstrijd_naam]
  if {$lst_ids != {}} {
    $db update_object wedstrijd [lindex $lst_ids 0] -date_checked [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"] 
  } else {
    # -opmerkingen [$db str_to_db [format_wedstrijd $ar_val(Wedstrijd)]]
    $db insert_object wedstrijd -naam $wedstrijd_naam -team $team_id -lokatie $lokatie \
      -datumtijd [clock format $sec_timestamp -format "%Y-%m-%d %H:%M:%S"] -scheids_nodig $scheids_nodig -opmerkingen $opmerkingen
  }
}

proc insert_wedstrijden_old {filename sec_from_date} {
  global log db
  
  # http_to_file $url $filename
  set text [read_file $filename]
  set tree [::struct::tree]
  ::htmlparse::2tree $text $tree
  ::htmlparse::removeVisualFluff $tree
  ::htmlparse::removeFormDefs $tree

  if {0} {
    set str_tree [$tree serialize]
    set fo [open treeSer.txt w]
    puts $fo $str_tree
    close $fo
  }
  
  if {0} {  
    set fo [open treeWalk.txt w]
    $tree walk root node {
      puts $fo "node: $node"
      puts $fo "  getall: [$tree getall $node]"
      puts $fo "  keys: [$tree keys $node]"
      puts $fo "  parent: [$tree parent $node]"
      puts $fo "  children: [$tree children $node]"
    }
    close $fo
  }
  
  $log debug "table nodes: [$tree children -all root filter node_is_table]"
  set lst_matrices [htmltree_to_matrices $tree]
  foreach matrix $lst_matrices {
    # puts "matrix: $matrix" 
    # puts [$matrix format 2string]
    handle_matrix $matrix $sec_from_date
  }
}


# @todo bepalen of zelfde proc ook voor uit-wedstrijden gebruikt kan worden.
# @pre m kan any matrix zijn, niet per se met nog komende wedstrijden
proc handle_matrix_old {m sec_from_date} {
  # eerste cell weg, bevat nbsp; value-rijden bevatten deze niet.
  set lst_header [lrange [$m get row 0] 1 end]
  if {![regexp {Veld} $lst_header]} {
    return 
  }
  for {set i 1} {$i < [$m rows]} {incr i} {
    set lst_values [$m get row $i]
    handle_wedstrijd $lst_header $lst_values $sec_from_date
  }
}

proc handle_wedstrijd_old {lst_header lst_values sec_from_date} {
  global db log
  if {[llength $lst_values] <= 5} {
    return 
  }
  array unset ar_val 
  foreach name $lst_header value $lst_values {
    # set ar_val($name) $value
    # zorgen dat dingen als Touché goedkomen.
    set ar_val([::htmlparse::mapEscapes $name]) [::htmlparse::mapEscapes $value]
  }
  
  try_eval {
    set str_dt "[string range $ar_val(Datum) 3 end] $ar_val(Tijd)"
    $log debug "str_dt:***[string trim $str_dt]***"
    if {[string length [string trim $str_dt]] < 10} {
      return 
    }
    set dt [clock scan $str_dt -format "%d-%m-%Y %H:%M"]
    if {$dt <= $sec_from_date} {
      $log debug "Game is not newer than from_date, returning. $ar_val(Datum) <= [clock format $sec_from_date -format "%Y-%m-%d"]" 
      return
    }
    set team_naam [det_team_naam $ar_val(Wedstrijd)] 
    set team_id [lindex [$db find_objects team -naam $team_naam] 0]
    # naam: <datum> <tijd> <team> (=unieke identificatie)
    set naam "[clock format $dt -format "%d-%m-%Y %H:%M"] $team_naam"
    set lokatie [det_lokatie $ar_val(Wedstrijd)]
    set scheids_nodig [det_scheids_nodig $team_id $lokatie]
    # mogelijk bestaat wedstrijd al, als eerst al thuis wedstrijden gelezen zijn, of na een tijdje script opnieuw wordt gedraaid.
    set lst_ids [$db find_objects wedstrijd -naam $naam]
    if {$lst_ids != {}} {
      $db update_object wedstrijd [lindex $lst_ids 0] -date_checked [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"] 
    } else {
      $db insert_object wedstrijd -naam $naam -team $team_id -lokatie $lokatie \
        -datumtijd [clock format $dt -format "%Y-%m-%d %H:%M:%S"] -scheids_nodig $scheids_nodig -opmerkingen [$db str_to_db [format_wedstrijd $ar_val(Wedstrijd)]]
    }
  } {
    $log error "insert wedstrijd failed ($lst_values): $errorResult"
    $log error "Exiting..."
    exit 1
  }
}

# @param wedstrijd: Oberon DS 1 - Wilhelmina DS 1
# @param wedstrijd: Wilhelmina DS 1 - SVU DS 2
# @result: H1, D4, etc.
proc det_team_naam {wedstrijd} {
  global log
  if {[regexp {Wilhelmina (.)S ([0-9]+)} $wedstrijd z dh nr]} {
    return "$dh$nr" 
  } else {
    $log debug "Failed to determine team_naam from wedstrijd: $wedstrijd"
    return "<unknown>"
  }
}

# @return: als Schuilenburg, dan thuis, anders uit
proc det_lokatie {location} {
  if {[regexp {Schuilenburg} $location]} {
    return "thuis" 
  } else {
    return "uit" 
  }
}


# @return: als Wilhelmina eerst genoemd, dan thuis, anders uit
# @note: wedstrijd begint vaak met "- " dit streepje moet eigenlijk tussen de teams staan. Waarschijnlijk met ophalen diverse PCdata dingen foutgegaan.
proc det_lokatie_old {wedstrijd} {
  if {[regexp {^(- )?Wilhelmina} [string trim $wedstrijd]]} {
    return "thuis" 
  } else {
    return "uit" 
  }
}

proc det_scheids_nodig {team_id lokatie} {
  global log db
  if {$lokatie == "uit"} {
    return 0
  } else {
    set query "select scheids_nodig from team where id = $team_id"
    return [lindex [::mysql::sel [$db get_connection] $query -flatlist] 0]
  }
}

proc read_file {filename} {
  set f [open $filename r]
  set text [read $f]
  close $f
  return $text
}

proc htmltree_to_matrices {tree} {
  return [::struct::list mapfor node [$tree children -all root filter node_is_table] {
    tablenode_to_matrix $tree $node
  }]
}

proc tablenode_to_matrix {tree node} {
  global log
  set m [::struct::matrix]
  foreach tr_node [$tree children -all $node filter node_is_tablerow] {
    set lst [tabledata_from_tr_node $tree $tr_node]
    $log debug "list of tabledata for tr_node $tr_node: $lst (#[llength $lst])"
    if {[llength $lst] > [$m columns]} {
      $m add columns [expr [llength $lst] - [$m columns]]  
    }
    $m add row $lst
  }
  return $m
}

# @todo kan hier misschien wel lambda_to_proc voor gebruiken, nu in ndv-lib.
proc tabledata_from_tr_node {tree tr_node} {
  ::struct::list mapfor td_node [$tree children -all $tr_node filter node_is_tabledata] {
    join [::struct::list mapfor pcdata_node [$tree children -all $td_node filter node_is_pcdata] {
      $tree get $pcdata_node data
    }] " "
  }
}  
  
proc node_is_table {t n} {
  return [node_is_type $t $n "table"]
}

proc node_is_tablerow {t n} {
  return [node_is_type $t $n "tr"]
}

proc node_is_tabledata {t n} {
  return [node_is_type $t $n "td"]
}

proc node_is_pcdata {t n} {
  return [node_is_type $t $n "pcdata"]
}

proc node_is_type {t n type} {
  if {[string tolower [$t get $n type]] == $type} {
    return 1 
  } else {
    return 0
  }
}


proc http_to_file {url filename} {  
  global log
  set r [http::geturl $url]
  set fo [open $filename w]
  # fconfigure $fo -translation binary
  puts -nonewline $fo [http::data $r]
  close $fo
  ::http::cleanup $r
  $log debug "Got $url -> $filename"  
}

# @return: 0 if not found, or the contents of the line if found
# @side effect: file pointer is below the found line.
# @note not used in this file.
proc find_in_file {f re} {
  set found 0
  while {![eof $f]} {
    gets $f line
    if {[regexp -- $re $line]} {
      set found 1
      break 
    }
  }
  if {$found} {
    return $line 
  } else {
    return 0 
  }
}

# @note: beide onderstaande queries eerst met de hand uitgevoerd.
# @todo? kan_wedstrijd_fluiten alleen nodig voor nieuwe wedstrijden, dus eigenlijk checken dat 'gemaild' niet voorkomt.
proc insert_kan_wedstrijd_fluiten {} {
  # verdelen in 2 stukken:
  # 1. persoon kan team fluiten en heeft helemaal geen wedstrijd op die dag.
  # 2. persoon kan team fluiten en heeft ook thuiswedstrijd die dag op ander tijdstip.
  global db log
  $log info "insert_kan_wedstrijd_fluiten"
  
  # deel 1: persoon kan team fluiten en heeft helemaal geen wedstrijd op die dag.
  # afwezig: between is inclusive aan beide kanten, dus eerstedag en laatstedag zijn goed.
  set query "
    insert into kan_wedstrijd_fluiten (scheids, wedstrijd, waarde, speelt_zelfde_dag)
    select kt.scheids, w.id, kt.waarde, 0
    from kan_team_fluiten kt, wedstrijd w, persoon p
    where w.team = kt.team
    and kt.scheids = p.id
    and w.lokatie = 'thuis'
    and not exists (
      select 1
      from wedstrijd w2, persoon_team pt
      where w2.team = pt.team
      and pt.persoon = p.id
      and date(w.datumtijd) = date(w2.datumtijd)
    )
    and not exists (
      select 1
      from afwezig a
      where a.persoon = p.id
      and date(w.datumtijd) between a.eerstedag and a.laatstedag
    )
"
  exec_query $query
  
  # deel 2 persoon kan team fluiten en heeft ook thuiswedstrijd die dag (als speler of coach) op ander tijdstip.
  set query "
    insert into kan_wedstrijd_fluiten (scheids, wedstrijd, waarde, speelt_zelfde_dag)
    select kt.scheids, w.id, kt.waarde, 1
    from kan_team_fluiten kt, wedstrijd w, persoon p
    where w.team = kt.team
    and kt.scheids = p.id
    and w.lokatie = 'thuis'
    and exists (
      select 1
      from wedstrijd w2, persoon_team pt
      where w2.team = pt.team
      and pt.persoon = p.id
      and w2.lokatie = 'thuis'
      and date(w.datumtijd) = date(w2.datumtijd)
      and time(w.datumtijd) <> time(w2.datumtijd)
    )
    and not exists (
      select 1
      from afwezig a
      where a.persoon = p.id
      and date(w.datumtijd) between a.eerstedag and a.laatstedag
    )
"

  exec_query $query

}


proc exec_query {query} {
  global db
  set conn [$db get_connection]
  ::mysql::exec $conn $query
}

# afwezig ook een nieuwe tabel, voorlopig alleen eigen wintersport 2010 ingevoerd.
# wel kan_fluiten hierop aanpassen.
# @todo NdV 15-9-2010 is deze nog nodig, volgens mij wordt nu in de select-queries hiermee rekening gehouden.
proc delete_kan_wedstrijd_fluiten {} {
  delete from kan_wedstrijd_fluiten
  select * from kan_wedstrijd_fluiten
  where exists (
    select 1
    from afwezig a, wedstrijd w
    where a.persoon = kan_wedstrijd_fluiten.scheids
    and kan_wedstrijd_fluiten.wedstrijd = w.id
    and date(w.datumtijd) between a.eerstedag and a.laatstedag
  )
  
  # ook verwijderen als er een team_persoon combi is die in de weg zit.
      delete from kan_wedstrijd_fluiten
      where exists (
      select 1
      from wedstrijd w, wedstrijd w2, persoon_team pt, persoon p
      where kan_wedstrijd_fluiten.wedstrijd = w.id
      and w2.team = pt.team
      and pt.persoon = kan_wedstrijd_fluiten.scheids
      and p.id = pt.persoon
      and w.datumtijd = w2.datumtijd
      and kan_wedstrijd_fluiten.speelt_zelfde_dag = 1
      )
      
      delete from kan_wedstrijd_fluiten
      where exists (
      select 1
      from wedstrijd w, wedstrijd w2, persoon_team pt, persoon p
      where kan_wedstrijd_fluiten.wedstrijd = w.id
      and w2.team = pt.team
      and pt.persoon = kan_wedstrijd_fluiten.scheids
      and pt.persoon = p.id
      and date(w.datumtijd) = date(w2.datumtijd)
      and kan_wedstrijd_fluiten.speelt_zelfde_dag = 0
      )
      
      
  
  
}


# fluiten op niet-speeldag is irritanter dan als je wel speelt, voor sommigen net iets anders
# hoe hoger de factor, hoe vervelender het is.
proc insert_zeurfactor {} {
  insert into zeurfactor (persoon, speelt_zelfde_dag, factor)
  select p.id, 1, 2
  from persoon p;
  
  insert into zeurfactor (persoon, speelt_zelfde_dag, factor)
  select p.id, 0, 8
  from persoon p;
  
  # handmatig: voor Rob v Zonneveld, Reza, Gerard, Lisette is het minder erg, want spelen zelf niet. Voor Gert ook iets minder erg, voor mezelf ook niet zo.
  # voor Chris extra erg. Voor Astrid nog erger.

  # handmatig: voor 
  #Rob v Zonneveld : 6 
  #Reza, : 4
  #Gerard, : 4
  #Lisette is het minder erg, want spelen zelf niet. : 4
  #Voor Gert ook iets minder erg, : 6
  #voor mezelf ook niet zo. : 6
  
  #voor Chris extra erg. : 12
  #Voor Astrid nog erger. : 50

  
}

# uit deze tabel verwijderen op moment dat een keuze is gemaakt.
proc delete_kan_wedstrijd_fluiten_na_keuze {} {
  # 346 voor delete
  select * 
  from kan_wedstrijd_fluiten kw
  where exists (
    select 1
    from scheids s
    where s.wedstrijd = kw.wedstrijd
    and s.status = 'gemaild'
  )
  # 58 rows
  delete from kan_wedstrijd_fluiten
  where exists (
    select 1
    from scheids s
    where s.wedstrijd = kan_wedstrijd_fluiten.wedstrijd
    and s.status = 'gemaild'
  )
  # hierna nog 288 over. 346 - 58 = 288, mooi.
  
}

proc doe_checks {} {
  # wedstrijden waarbij geen scheids te vinden is
  select * from wedstrijd w
  where w.scheids_nodig = 1
  and not exists (
    select 1 
    from scheids s
    where s.wedstrijd = w.id 
  )
  and not exists (
    select 1
    from kan_wedstrijd_fluiten kw
    where kw.wedstrijd = w.id
  )
  # => geen
  
  # wedstrijden waarbij geen scheids te vinden is die ook speelt op dezelfde dag.
  select * from wedstrijd w
  where w.scheids_nodig = 1
  and not exists (
    select 1 
    from scheids s
    where s.wedstrijd = w.id 
  )
  and not exists (
    select 1
    from kan_wedstrijd_fluiten kw
    where kw.wedstrijd = w.id
    and kw.speelt_zelfde_dag = 1
  )
  # dit zijn er nog 12, alleen van dames 3, heren 3 en heren 4. ook alle late wedstrijden. 
  
  # vanuit persoon: hoeveel wedstrijden kunnen ze fluiten, en hoeveel op eigen speeldag.
  select p.naam, kw.speelt_zelfde_dag, count(kw.speelt_zelfde_dag)
  from persoon p, kan_wedstrijd_fluiten kw
  where kw.scheids = p.id
  group by 1,2
  order by 2, 3, 1
  
  # Ester Hilhost, id 10, niet inplannen voor wedstrijd die gelijk met D1 wordt gespeeld, zijn deze er?
  select *
  from wedstrijd wx, wedstrijd w1
  where wx.team <> 7
  and w1.team = 7
  and w1.datumtijd = wx.datumtijd
  and wx.scheids_nodig = 1
  => gaat om 2 wedstrijden van heren 4: 81, 136
  
  select * from kan_wedstrijd_fluiten kw
  where kw.wedstrijd in (81,136)
  => genoeg alternatieven, zelfs paar op dezelfde dag voor 81. Is op 26-3, dan idd 5 wedstrijden.  
  
}

proc format_wedstrijd {opm} {
  # - Wilhelmina DS 2 Forza Hoogland DS 4
  if {[regexp {^- (.* [DH]S [0-9]) (.*)$} $opm z wij zij]} {
    return "$wij - $zij" 
  } else {
    return $opm 
  }
}

proc remove_unassigned_games {} {
  global db conn
  mysql::exec $conn "delete from kan_wedstrijd_fluiten"
  mysql::exec $conn "delete from scheids where status <> 'gemaild'"
  mysql::exec $conn "delete from wedstrijd where not exists (
    select 1
    from scheids s
    where s.wedstrijd = wedstrijd.id
    and s.status = 'gemaild'
  )"
  
}

proc rapportage {} {
  global db
  
  puts "#wedstrijden: [::mysql::sel [$db get_connection] "select count(*) from wedstrijd" -flatlist]"
  puts "#wedstrijden met scheids: [::mysql::sel [$db get_connection] "select count(*) from wedstrijd where scheids_nodig = 1" -flatlist]"
  puts "#wedstrijden met scheids die op dezelfde dag speelt: [::mysql::sel [$db get_connection] \
    "select count(*) from wedstrijd w where scheids_nodig = 1 and exists (select 1 from kan_wedstrijd_fluiten k where k.wedstrijd = w.id and k.speelt_zelfde_dag = 1)" -flatlist]"    
  puts "#wedstrijden zonder scheids die op dezelfde dag speelt: [::mysql::sel [$db get_connection] \
    "select count(*) from wedstrijd w where scheids_nodig = 1 and not exists (select 1 from kan_wedstrijd_fluiten k where k.wedstrijd = w.id and k.speelt_zelfde_dag = 1)" -flatlist]"

  puts "#wedstrijden waar niemand voor te vinden is: [::mysql::sel [$db get_connection] \
    "select count(*) from wedstrijd w where scheids_nodig = 1 and not exists (select 1 from kan_wedstrijd_fluiten k where k.wedstrijd = w.id)" -flatlist]"

  # @todo als er wedstrijden zijn waar niemand voor te vinden is, deze wedstrijden printen.
    
}

main $argc $argv

