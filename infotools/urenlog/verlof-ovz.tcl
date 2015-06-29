# maak verlof overzicht in html obv ge-exporteerde sqlite db.

package require sqlite3
package require Tclx

# own package
package require ndv

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]

proc main {argv} {
  puts "verlof-ovz: started"
  lassign $argv urendir
  sqlite3 db [file join $urendir uren-saldo_uren.tsv.db]
  puts "opened sqlite connection"
  set f [open [file join $urendir verlof-ovz.html] w]
  puts "opened html file for writing, f=$f"
  set hh [ndv::CHtmlHelper::new]
  puts "created htmlhelper object"
  $hh set_channel $f
  puts "set channel done"
  $hh write_header "Header" 0
  puts "wrote header"
  maak_verlof_ovz $hh
  $hh write_footer  
  close $f
  db close
}

proc maak_verlof_ovz {hh} {
  try_eval {
    $hh heading 1 "Verlof overzicht"
    $hh table_start 
    write_table_header $hh
    # $hh table_header "Vrijdag" "Verlof delta" "Verlof som" "Deeltijd delta" "Deeltijd som" "Totaal som" "Totaal dagen" "Opmerkingen"
    # CREATE TABLE urendag (date, project, hours, comments);
    set query "select date, project, sum(hours) hours
               from urendag
               group by 1,2
               order by 1,2"
    set prev_year 0
    set start_date "2010-01-02" ; # 2010-01-01 is een vrijdag, wil hiervan niets printen. 
    set prev_date $start_date
    set werkdag 0 ; # eerste date (2010-01-01) is geen werkdag bij Ymor
    set verlof 0
    set deeltijd 0
    set delta_verlof 0
    set delta_deeltijd 0
    set lst_notes {}
    # $hh table_row "TODO: doortrekken naar eind van het jaar"
    # set prev_ 0
    db eval $query row {
      # $hh table_row "*" "*" "*" $row(date) $row(project) $row(hours) 
      set date $row(date)
      set project $row(project)
      set hours $row(hours)
      set year [det_year $date]
      if {$date > $prev_date} {
        # check opvolgende dagen
        if {![dates_successive $prev_date $date]} {
          if {$prev_date == $start_date} {
            # ok. 
          } else {
            $hh table_row "LET OP: geen opvolgende dagen: $prev_date - $date"
          }
        }
        # handle prev date
        if {$werkdag} {
          incrnum delta_deeltijd 0.8 ; # 10% of a full workday 
        }
        
        # output prev date if this is a friday
        # or if this date is a monday.
        # if {[is_friday $prev_date]} {}
        if {[is_monday $date]} {
          incrnum verlof $delta_verlof
          incrnum deeltijd $delta_deeltijd
          make_table_row $hh $prev_date $delta_verlof $verlof $delta_deeltijd $deeltijd $lst_notes
          # $hh table_row $prev_date {*}[format_values [list $delta_verlof $verlof $delta_deeltijd $deeltijd [expr $verlof+$deeltijd] [expr ($verlof+$deeltijd)/7.2]]] [notes_to_html $lst_notes]
          # init new week
          set delta_verlof 0
          set delta_deeltijd 0
          set lst_notes {}
        }
        
        # init new date
        set prev_date $date
        set werkdag 1

        # also new year?        
        if {$year > $prev_year} {
          # set delta_verlof [expr $delta_verlof + [det_verlof_year $date]]
          set verlof_year [det_verlof_year $date]
          # incrnum delta_verlof [det_verlof_year $date]
          incrnum delta_verlof $verlof_year
          set prev_year $year
          # $hh table_row "*" $date "Added $delta_verlof hours to verlof ($year)"
          lappend lst_notes "Uren toegevoegd aan verlof: $verlof_year ($year)"
        }
        
      }
      # handle date/worktype row
      if {$project == "Deeltijd"} {
        incrnum delta_deeltijd -$hours
        lappend lst_notes "$date: Deeltijd: -$hours"
      } elseif {$project == "Verlof"} {
        incrnum delta_verlof -$hours
        lappend lst_notes "$date: Verlof: -$hours"
      } elseif {$project == "Feestdag"} {
        lappend lst_notes "$date: Feestdag"
        set werkdag 0
      } else {
        if {[is_weekend $date]} {
          incrnum delta_deeltijd $hours
          set werkdag 0 ; # want niet nog 0.8 uur extra opbouwen.
          lappend lst_notes "$date: Weekend, Deeltijd: +$hours"
        }
        # nothing, normal project. 
      }
      
    }  
    # output prev date
    # handle prev date
    if {$werkdag} {
      incrnum delta_deeltijd 0.8 ; # 10% of a full workday 
    }
    
    # output prev date if this is a friday
    if {[is_friday $prev_date]} {
      incrnum verlof $delta_verlof
      incrnum deeltijd $delta_deeltijd
      make_table_row $hh $prev_date $delta_verlof $verlof $delta_deeltijd $deeltijd $lst_notes
      # $hh table_row $date {*}[format_values [list $delta_verlof $verlof $delta_deeltijd $deeltijd [expr $verlof+$deeltijd] [expr ($verlof+$deeltijd)/7.2]]] [notes_to_html $lst_notes]
    }
    write_table_header $hh
    $hh table_end
  } {
    log error $errorResult
    breakpoint 
  }
}

proc write_table_header {hh} {
  $hh table_header "Vrijdag" "Verlof delta" "Verlof som" "Deeltijd delta" "Deeltijd som" "Totaal som" "Totaal dagen" "Opmerkingen"
}

proc make_table_row {hh prev_date delta_verlof verlof delta_deeltijd deeltijd lst_notes} {
  $hh table_row [format_week $prev_date] {*}[format_values [list $delta_verlof $verlof $delta_deeltijd $deeltijd [expr $verlof+$deeltijd] [expr ($verlof+$deeltijd)/7.2]]] [notes_to_html $lst_notes]
}

proc det_year {date} {
  if {[regexp {^(\d+)-} $date z year]} {
    return $year
  } else {
    error "Unable to parse year from: $date" 
  }
}

proc det_verlof_year {date} {
  if {[regexp {^\d+-0?(\d+)-} $date z month]} {
    set nmonth [expr 12 - $month + 1] ; # aantal maanden waarover je verlof krijgt
    # par maand 2 dagen a factor 0.9 (per werkdag bouw ik ook 0.1 deeltijd dag op, vandaar)
    expr 0.9 * $nmonth * 2 * 8
  } else {
    error "Unable to parse month from: $date"
  }
}

# determine weeknumber and add.
proc format_week {date} {
  # %U %V %W leveren voor 2011 en 2012 hetzelfde op, uit docs nu %V kiezen, is ISO nummer.
  set sec [clock scan $date -format "%Y-%m-%d"]
  clock format $sec -format "Week %V - %Y-%m-%d"
}

proc dates_successive {date1 date2} {
  set sec1 [clock scan $date1 -format "%Y-%m-%d"]
  set sec2 [clock scan $date2 -format "%Y-%m-%d"]
  set diff_days [expr ($sec2 - $sec1) / (3600 * 24)]
  # breakpoint
  if {[is_monday $date2]} {
    if {$diff_days <= 3} {
      return 1 
    } else {
      return 0 
    }
  } else {
    if {$diff_days <= 1} {
      return 1 
    } else {
      return 0 
    }
  }
}

proc is_friday {date} {
  set dow [clock format [clock scan $date -format "%Y-%m-%d"] -format "%u"]
  if {$dow == 5} {
    return 1 
  } else {
    return 0
  }
}

proc is_monday {date} {
  set dow [clock format [clock scan $date -format "%Y-%m-%d"] -format "%u"]
  if {$dow == 1} {
    return 1 
  } else {
    return 0
  }
}

# sat=6, sun=7
proc is_weekend {date} {
  set dow [clock format [clock scan $date -format "%Y-%m-%d"] -format "%u"]
  if {$dow >= 6} {
    return 1 
  } else {
    return 0
  }
}

proc notes_to_html {lst_notes} {
  join $lst_notes "<br/>" 
}

proc format_values {lst} {
  set res {}
  foreach el $lst {
    lappend res [format %.1f $el] 
  }
  return $res
}

# increase (possibly) float value in var with value (incr only works with integers)
proc incrnum {var value} {
   upvar $var var1
   set var1 [expr $var1 + $value]  
}

proc log {args} {
  # global log
  variable log
  $log {*}$args
}

main $argv
