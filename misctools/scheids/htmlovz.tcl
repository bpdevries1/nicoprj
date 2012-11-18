#!/home/nico/bin/tclsh

# maak html overzicht van scheids schema met hyperlinks.

package require ndv
package require http
package require htmlparse
package require struct::tree
package require struct::list
package require Tclx

::ndv::source_once ScheidsSchemaDef.tcl

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]

proc main {argv} {
  global db conn log ar_argv
  lassign $argv outdir
  file mkdir $outdir
  
  set schemadef [ScheidsSchemaDef::new]
  $schemadef set_db_name_user_password scheids nico "pclip01;"
  set db [::ndv::CDatabase::get_database $schemadef]
  set conn [$db get_connection]

  # [::mysql::sel [$db get_connection] "select count(*) from wedstrijd" -flatlist]
  # [::mysql::sel [$db get_connection] "select count(*) from wedstrijd" -list]
  
  maak_ovz_wedstrijden $conn $outdir
  maak_wedstrijden $conn $outdir
}

proc maak_ovz_wedstrijden {conn outdir} {
  #set f [open [file join $outdir "overzicht.html"] w]
  #set hh [ndv::CHtmlHelper::new]
  #$hh set_channel $f
  #$hh write_header "Wedstrijden overzicht"
  
  lassign [open_html [file join $outdir "overzicht.html"] "Wedstrijden overzicht"] f hh 
  
  $hh table_start 
  $hh table_header Datum Tijd Lokatie Naam Scheids ZelfdeDag
  # @todo scheids left joinen, dan ook wedstrijden zonder scheids te zien, vooral D1/H1.
  set lst [sqlsel "select date(w.datumtijd), time(w.datumtijd), w.lokatie, w.naam, p.naam, w.id, s.speelt_zelfde_dag
                   from wedstrijd w, persoon p, scheids s
                   where w.id = s.wedstrijd
                   and s.scheids = p.id
                   order by w.datumtijd, w.naam"]
  foreach row $lst {
    lassign $row datum tijd lokatie w_naam p_naam w_id zd
    set w [$hh get_anchor $w_naam "wedstrijd-${w_id}.html"]
    $hh table_row $datum $tijd $lokatie $w $p_naam $zd
  }
  $hh table_end
  close_html $f $hh
}

proc maak_wedstrijden {conn outdir} {
  foreach row [sqlsel "select id, naam from wedstrijd where lokatie = 'thuis' and scheids_nodig = 1"] {
    maak_wedstrijd $conn $outdir {*}$row
  }
}

proc maak_wedstrijd {conn outdir w_id w_naam} {
  lassign [open_html [file join $outdir "wedstrijd-${w_id}.html"] $w_naam] f hh 
  $hh heading 1 "Alternatieve scheidsrechters"
  $hh table_start
  $hh table_header Persoon ZelfdeDag 
  set lst [sqlsel "select p.naam, k.speelt_zelfde_dag
                   from persoon p, kan_wedstrijd_fluiten k
                   where p.id = k.scheids
                   and k.wedstrijd = $w_id
                   order by p.naam"]
  foreach row $lst {
    $hh table_row {*}$row
  }
  $hh table_end
  close_html $f $hh
}

proc open_html {filename title} {
  set f [open $filename w]
  set hh [ndv::CHtmlHelper::new]
  $hh set_channel $f
  $hh write_header $title
  list $f $hh  
}

proc close_html {f hh} {
  $hh write_footer
  close $f
}

# gebruik -list
proc sqlsel {query} {
  global conn
  ::mysql::sel $conn $query -list
}

proc exec_query {query} {
  global db
  set conn [$db get_connection]
  ::mysql::exec $conn $query
}


main $argv
