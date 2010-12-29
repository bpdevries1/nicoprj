#!/home/nico/bin/tclsh

# onderstaande doet inderdaad raar, blijft hangen.
#!/usr/bin/env

package require ndv
package require Tclx
package require struct::list

source [file join [file dirname [info script]] .. .. lib database2 CDatabase.tcl]
source ScheidsSchemaDef.tcl

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]

proc main {} {
  global db conn log
  set db [CDatabase::get_database ScheidsSchemaDef]
  set conn [$db get_connection]
  # delete_oude_voorstel
  
  set f [open scheids-planning.tsv w]
  set query "select distinct date(w.datumtijd)
             from wedstrijd w
             where w.scheids_nodig = 1
             order by 1"
  foreach datum [::mysql::sel $conn $query -flatlist] {
    handle_datum $f $datum               
  }
  close $f
}

proc handle_datum {f datum} {
  global conn
  puts $f [format_datum $datum]
  set query "select time(w.datumtijd), w.opmerkingen, sch.naam
             from wedstrijd w
             left join (
               select s.wedstrijd, p.naam
               from scheids s, persoon p
               where s.scheids = p.id
               and s.status = 'voorstel'
             ) as sch on sch.wedstrijd = w.id
             where date(w.datumtijd) = '$datum'
             and w.lokatie = 'thuis'
             order by 1, 2"
  foreach {time opm naam} [::mysql::sel $conn $query -flatlist] {
    puts $f "[format_tijd $time]\t[format_wedstrijd $opm]\t[format_naam $naam]"             
  }
  puts $f ""
}

proc handle_datum_old {f datum} {
  global conn
  puts $f [format_datum $datum]
  set query "select time(w.datumtijd), w.opmerkingen, p.naam
             from wedstrijd w, persoon p, scheids s
             where w.id = s.wedstrijd
             and p.id = s.scheids
             and s.status = 'voorstel'
             and date(w.datumtijd) = '$datum'
             order by 1, 2"
  foreach {time opm naam} [::mysql::sel $conn $query -flatlist] {
    puts $f "[format_tijd $time]\t[format_wedstrijd $opm]\t[format_naam $naam]"             
  }
  puts $f ""
}

proc format_datum {datum} {
  set sec [clock scan $datum -format "%Y-%m-%d"]
  return [clock format $sec -format "%d-%m-%Y"]
}

proc format_tijd {tijd} {
  set sec [clock scan $tijd -format "%H:%M:%S"]
  return [clock format $sec -format "%H:%M"]
}

proc format_naam {naam} {
  if {$naam == ""} {
    return "geen" 
  } else {
    return $naam ; # toch eerst hele naam
  }
}

proc format_wedstrijd {opm} {
  # - Wilhelmina DS 2 Forza Hoogland DS 4
  if {[regexp {^- (.* [DH]S [0-9]) (.*)$} $opm z wij zij]} {
    return "$wij - $zij" 
  } else {
    return $opm 
  }
}

main
