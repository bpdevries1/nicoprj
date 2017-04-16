# maak uren maand overzicht in html obv ge-exporteerde sqlite db.

package require sqlite3
package require Tclx

# own package
package require ndv

ndv::source_once liburen.tcl

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]

# TODO: merge with uren-week-ovz.tcl. Use this one as basis, has Total as second column.

proc main_old {argv} {
  lassign $argv urendir
  sqlite3 db [file join $urendir uren-saldo_uren.tsv.db]
  set f [open [file join $urendir uren-maand-ovz.html] w]
  set hh [ndv::CHtmlHelper::new]
  $hh set_channel $f
  $hh write_header "Uren Maand Overzicht" 0
  maak_uren_maand_ovz $hh
  $hh write_footer  
  close $f
  db close
}

proc main {argv} {
  lassign $argv urendir
  maak_overzichten $urendir
}

proc maak_overzichten {urendir} {
  sqlite3 db [file join $urendir uren-saldo_uren.tsv.db]

  maak_overzicht $urendir "uren-maand-ovz.html" ""
  set sql "select distinct target from target_mapping"
  foreach target [db eval $sql] {
    maak_overzicht $urendir "uren-maand-ovz-$target.html" $target
  }
  show_warnings
  db close
}

proc maak_overzicht {urendir html_name target} {
  set f [open [file join $urendir $html_name] w]
  set hh [ndv::CHtmlHelper::new]
  $hh set_channel $f
  $hh write_header "Uren Maand Overzicht $target" 0
  maak_uren_maand_ovz $hh $target
  $hh write_footer  
  close $f
  
}



proc maak_uren_maand_ovz {hh target} {
  try_eval {
    set query [det_maand_query $target]
    set prev_year 0
    set start_date "2010-01-02" ; # 2010-01-01 is een vrijdag, wil hiervan niets printen. 
    set prev_date $start_date
    set werkdag 0 ; # eerste date (2010-01-01) is geen werkdag bij Ymor
    init_maand ar_projects ar_days ar_prj_day
    # $hh table_row "TODO: doortrekken naar eind van het jaar"
    # set prev_ 0
    db eval $query row {
      # $hh table_row "*" "*" "*" $row(date) $row(project) $row(hours) 
      set date $row(date)
      set project $row(project)
      set hours $row(hours)
      if {$date > $prev_date} {
        # check opvolgende dagen
        if {![dates_successive $prev_date $date]} {
          if {$prev_date == $start_date} {
            # ok. 
          } else {
            $hh table_row "LET OP: geen opvolgende dagen: $prev_date - $date"
          }
        }
        
        # output prev month if new month
        if {[is_new_month $prev_date $date]} {
          # make_table_row $hh $prev_date $delta_verlof $verlof $delta_deeltijd $deeltijd $lst_notes
          make_maand_report $hh $prev_date ar_projects ar_days ar_prj_day
          # $hh table_row $prev_date {*}[format_values [list $delta_verlof $verlof $delta_deeltijd $deeltijd [expr $verlof+$deeltijd] [expr ($verlof+$deeltijd)/7.2]]] [notes_to_html $lst_notes]
          # init new maand
          init_maand ar_projects ar_days ar_prj_day 
        }
        
        # init new date
        set prev_date $date
        set werkdag 1

      }
      # handle date/worktype row
      set ar_projects($project) 1
      set ar_days($date) 1
      set ar_prj_day($project,$date) $hours
      #breakpoint      
    }  
    # handle last maand.    
    # output prev date if this is a friday
	if 0 {
		if {[is_new_month $prev_date $date]} {
		  make_maand_report $hh $prev_date ar_projects ar_days ar_prj_day
		  # make_table_row $hh $prev_date $delta_verlof $verlof $delta_deeltijd $deeltijd $lst_notes
		  # $hh table_row $date {*}[format_values [list $delta_verlof $verlof $delta_deeltijd $deeltijd [expr $verlof+$deeltijd] [expr ($verlof+$deeltijd)/7.2]]] [notes_to_html $lst_notes]
		} else {
		  log info "Geen nieuwe maand aan het einde."
		  breakpoint
		}
	}
	# [2016-10-02 17:48:58] sowieso aan het einde de laatste maand nog doen, ook al is het een halve.
	make_maand_report $hh $prev_date ar_projects ar_days ar_prj_day
    
    # $hh table_end
  } {
    log error $errorResult
    breakpoint 
  }
}

# [2017-04-16 14:17] same as det_week_query
proc det_maand_query {target} {
  if {$target == ""} {
    set query "select date, project, sum(hours) hours
               from urendag
               group by 1,2
               order by 1,2"
  } else {
    # left join will result in empty project field, show as 'Unmapped'
    # left join does not seem to work in SQLiteSpy
    # expect 1 empty field (in a row) for combination of unmapped and explicitly (-) mapped projects.
    set query "select date, m.target_project project, sum(hours) hours
               from urendag u
               left join target_mapping m on m.project = u.project
               and m.target = '$target'
               and m.target_project <> '-'               
               group by 1,2
               order by 1,2"
  }
  return $query
}



# determine maandnumber and add.
proc format_maand {date} {
  # %U %V %W leveren voor 2011 en 2012 hetzelfde op, uit docs nu %V kiezen, is ISO nummer.
  set sec [clock scan $date -format "%Y-%m-%d"]
  # clock format $sec -format "Week %V - %Y-%m-%d"
  clock format $sec -format "Maand %m - %Y-%m-%d"
}

proc dates_successive {date1 date2} {
  set sec1 [clock scan $date1 -format "%Y-%m-%d"]
  set sec2 [clock scan $date2 -format "%Y-%m-%d"]
  set diff_days [expr ($sec2 - $sec1) / (3600 * 24)]
  # breakpoint
  if {[is_friday $date1]} {
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

proc is_new_month {date1 date2} {
  set ym1 [clock format [clock scan $date1 -format "%Y-%m-%d"] -format "%Y-%m"]
  set ym2 [clock format [clock scan $date2 -format "%Y-%m-%d"] -format "%Y-%m"]
  if {$ym2 > $ym1} {
    return 1
  } else {
    return 0
  }
}

proc init_maand {ar_projects_name ar_days_name ar_prj_day_name} {
  upvar $ar_projects_name ar_projects 
  upvar $ar_days_name ar_days 
  upvar $ar_prj_day_name ar_prj_day
  array unset ar_projects
  array unset ar_days
  array unset ar_prj_day
}

proc make_maand_report {hh date ar_projects_name ar_days_name ar_prj_day_name} {
  upvar $ar_projects_name ar_projects 
  upvar $ar_days_name ar_days 
  upvar $ar_prj_day_name ar_prj_day
  #breakpoint
  $hh heading 1 [format_maand $date]
  $hh table_start
  set lst_days [lsort [array names ar_days]]
  # $hh table_header "Day" {*}$lst_days "Total"
  $hh table_header "Day" "Total" {*}$lst_days "Total"
  foreach prj [lsort [array names ar_projects]] {
    $hh table_row_start
    if {$prj == ""} {
      $hh table_data "Other"
    } else {
      $hh table_data $prj      
    }
    set total 0
    foreach day $lst_days {
      incrnum ar_prj_day($prj,$day) 0
      incrnum total $ar_prj_day($prj,$day)
      incrnum total_day($day) $ar_prj_day($prj,$day)
      # $hh table_data $ar_prj_day($prj,$day)
    }
    
    $hh table_data $total
    foreach day $lst_days {
      #incrnum ar_prj_day($prj,$day) 0
      #incrnum total $ar_prj_day($prj,$day)
      #incrnum total_day($day) $ar_prj_day($prj,$day)
      $hh table_data $ar_prj_day($prj,$day)
    }
    $hh table_data $total
    $hh table_row_end
  }
  $hh table_row_start
  $hh table_data Total
  set maand_total 0
  foreach day $lst_days {
    incrnum maand_total $total_day($day)
  }
  $hh table_data $maand_total
  foreach day $lst_days {
    # incrnum maand_total $total_day($day)
    $hh table_data $total_day($day)
  }
  $hh table_data $maand_total
  $hh table_row_end
  $hh table_end  
}

main $argv
