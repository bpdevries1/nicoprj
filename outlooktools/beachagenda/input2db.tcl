# import html/txt files to sqlite db
# after this, export to tsv/excel and make the planning.

package require tdbc::sqlite3
package require Tclx
package require ndv

proc main {argv} {
  lassign $argv dirname
  set db_name [file join $dirname beachen.db]
  log info "Creating db: $db_name"
  file delete $db_name
  set conn [open_db $db_name]
  set fields [list lokatie datum niveau]
  db_eval $conn "create table beach ([join $fields ", "])"
  set stmt_insert [prepare_insert $conn beach {*}$fields]
  db_eval $conn "begin transaction"
  foreach filename [glob -directory $dirname "*beachcomp*"] {
    read_beachcomp $filename $conn $stmt_insert 
  }
  foreach filename [glob -directory $dirname "*beachvolley*"] {
    read_beachvolley $filename $conn $stmt_insert 
  }
  db_eval $conn "commit"
}

proc read_beachcomp {filename conn stmt_insert} {
  log info "Reading beachcomp file: $filename"
  set f [open $filename r]
  set lokatie "<unknown>"
  while {![eof $f]} {
    gets $f line
    if {[regexp {^((\de divisie)|(Toptoernooi)) \(M\) \(([^\(\)]+)\)} $line z niveau z z datumstr]} {
      set datum [parse_datum $datumstr]
      log info "Inserting event: $lokatie - $niveau - $datum"
      [$stmt_insert execute [vars_to_dict lokatie niveau datum]] close
      log info "Inserted event"
    } elseif {[regexp {divisie} $line]} {
      # sla (V) hier over.
      # breakpoint          
    } elseif {[string trim $line] == ""} {
      # ok, nothing  
    } elseif {[regexp {Inschrijven} $line]} {
      # ok, nothing
    } elseif {[regexp {^([^ ].*)$} $line z lok]} {
      # breakpoint
      set lokatie [string trim $lok]
      log info "Set lokatie: ***$lokatie***"      
    } else {
      log warn $line
      # breakpoint
    }
  }
  close $f
}

proc parse_datum {datumstr} {
  log debug "parse_datum: $datumstr"
  set str [string trim $datumstr]
  if {[regexp {^(\d+) ([a-z]+)$} $str z dagnr maandstr]} {
    # breakpoint
    set maandnr [parse_maand $maandstr]
    return [format "%04d-%02d-%02d" 2013 $maandnr $dagnr]
  } else {
    error "Failed to parse datum: $datumstr" 
  }
}

proc parse_maand {maandstr} {
  set maandnr(mei) 5
  set maandnr(jun) 6
  set maandnr(juni) 6
  set maandnr(jul) 7
  set maandnr(juli) 7
  set maandnr(aug) 8
  set maandnr(augustus) 8
  set maandnr(sep) 9
  set maandnr(september) 9
  return $maandnr($maandstr)
}

proc read_beachvolley {filename conn stmt_insert} {
  log info "Reading beachvolley file: $filename"
  set f [open $filename r]
  set lokatie "<unknown>"
  set niveau "Hoog"
  while {![eof $f]} {
    gets $f line
    if {[regexp {2013$} $line]} {
      set datum [parse_datum_volley $line]
      log info "Inserting event: $lokatie - $niveau - $datum"
      [$stmt_insert execute [vars_to_dict lokatie niveau datum]] close
    } elseif {[string trim $line] == ""} {
      # ok, nothing  
    } else {
      set lokatie [string trim $line]
      puts "Set lokatie: $lokatie"
    }
  }
  close $f  
}

proc parse_datum_volley {str} {
  lassign [split $str " "] z dagnr maandstr jaar
  set maandnr [parse_maand $maandstr]
  format "%04d-%02d-%02d" $jaar $maandnr $dagnr
}

if {0} {
  query of combi van datum/niveau meer dan eens voorkomt
  select count(*), datum, niveau
  from beach
  group by 2,3
  having count(*) > 1
  order by datum;
  
}

main $argv
