#!/usr/bin/env tclsh86

# @todo: nu eerst alleen MyPhilips (wel zowel resp als avail)
# @todo: nu eerst alleen eerste tab met page-avg's.
# @todo: alleen gegevens nieuwste dag opnemen. (Eerst checken of er wel steeds hetzelfde instaat).
#        ivm weekend soms >1 dag.

# van 19-8, datums als hieronder, wel 15-8 t/m 12-8 hidden.
# als een dag rechts een nieuwere dag is dan een dag er links van, kun je alles links negeren.
# 15-Aug-13,,,,,,,,,,,14-Aug-13,,,,,,,,,,,13-Aug-13,,,,,,,,,,,12-Aug-13,,,,,,,,,,,18-Aug-13,,,,,,,,,,,17-Aug-13,,,,,,,,,,,16-Aug-13
# kijken of het zo lukt, of dat je ook de info nodig hebt welke columns hidden zijn. Dan iets met ironpython wellicht.

package require tdbc::sqlite3
package require Tclx
package require ndv
package require csv

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]
# set log [::ndv::CLogger::new_logger [file tail [info script]] info]
$log set_file "[file tail [info script]].log"

proc main {argv} {
  # lassign $argv dirname
  set options {
    {dir.arg "c:/projecten/Philips/Dashboards" "Directory where Excel dashboard files are and DB will be put."}
    {dropdb "Drop the (old) database first"}
    {debug "Run in debug mode, stop when an error occurs"}
  }
  set usage ": [file tail [info script]] \[options] :"
  set dargv [::cmdline::getoptions argv $options $usage]   
  set dir [:dir $dargv]
  set db_name [file join $dir "dashboards.db"]
  if {[:dropdb $dargv]} {
    file delete $db_name
  }
  set existing_db [file exists $db_name]
  set db [dbwrapper new $db_name]
  prepare_db $db $existing_db
  handle_dir_rec $dir "*.xlsx" [list handle_excel $db]
}

proc prepare_db {db existing_db} {
  $db add_tabledef logfile {id} {path date}
  # set source to keynote for data directly from there, as daily average from the keynote raw/API data.
  $db add_tabledef stat {id} {logfile_id source date scriptname country totalpageavg respavail {value float}}
  # $db insert logfile_date [dict create logfile_id $logfile_id date $date]
  $db add_tabledef logfile_date {id} {logfile_id date}
  
  if {!$existing_db} {
    log info "Create tables"
    $db create_tables 0 ; # 0: don't drop tables first.
    create_indexes $db
  } else {
    log info "Existing DB, don't create tables"
    # existing db, assuming tables/indexes also already exist. 
  }
  $db prepare_insert_statements
}

proc create_indexes {db} {
  $db exec_try "create index ix_stat_1 on stat(logfile_id)"
} 

proc handle_excel {db filename rootdir} {
  log info "Handle_excel: $filename"
  if {[is_read $db $filename]} {
    log info "Already read, ignoring: $filename"
    return
  }
  excel2csv $filename
  set filedate [det_date $filename]
  $db in_trans {
    set logfile_id [$db insert logfile [dict create path $filename date $filedate] 1]
    # todo convert to csv's here.
    # dummy/test
    # Daily com dashboard (14-August-2013)_Dashboard_(BMC).csv
    set tab1_name "[file rootname $filename]_Dashboard_(BMC).csv"
    set f [open $tab1_name r]
    set dheader [get_header $db $logfile_id $f $filedate]
    
    # pas hier de items toevoegen aan logfile_date
    dict for {date vals} $dheader {
      # extra check
      if {$filedate <= $date} {
        error "File date <= date: $filedate <= $date" 
      }
      $db insert logfile_date [dict create logfile_id $logfile_id date $date]
    }
    
    # $db insert stat [dict create logfile_id $logfile_id date "2013-08-15" scriptname "MyPhilips" country "DE" totalpageavg "pageavg" respavail "resp" value 3.65]
    set totalpageavg "pageavg"
    set scriptname "MyPhilips"
    while {![eof $f]} {
      set lline [csv::split [gets $f]]
      # note nu eerst alleen MyPhilips
      if {[lindex $lline 2] == "MyPhilips"} {
        set respavail [det_respavail $lline] 
        # alleen invoegen als: er een getal/perc in staat, en de datum niet te nieuw is.
        dict for {date vals} $dheader {
          if {$date >= $filedate} {
            # log debug "too new, continue"
            continue
          }
          # log debug "Handle date: $date"
          dict for {country colnr} $vals {
            set val [lindex $lline $colnr]
            if {[string trim $val] != ""} {
              $db insert stat [dict create logfile_id $logfile_id source "dashboard" date $date scriptname $scriptname \
                  country $country totalpageavg $totalpageavg respavail $respavail value [val2float $val]]
            }
          }
        }
      }
    }
  }
  close $f
}

proc det_respavail {lline} {
  if {[regexp {%} [lindex $lline 5]]} {
    return "avail" 
  } else {
    return "resp"
  }
}

proc val2float {val} {
  if {[regexp {^(.+)%$} $val z percval]} {
    format "%.2f" [expr 0.01 * $percval] 
  } else {
    return $val 
  }
}

proc is_read {db filename} {
  if {[llength [db_query [$db get_conn] "select id from logfile where path='$filename'"]] > 0} {
    return 1 
  } else {
    return 0 
  }
}

proc excel2csv {filename} {
  log info "excel2csv: $filename"
  set nativename [file nativename [file normalize $filename]]
  set targetroot [file nativename [file normalize [file rootname $filename]]]
  log debug "nativename: $nativename"
  log debug "targetroot: $targetroot"
  delete_old_csv $targetroot
  exec cscript xls2csv.vbs $nativename $targetroot
} 

proc delete_old_csv {targetroot} {
  foreach filename [glob -nocomplain -directory [file dirname $targetroot] "[file tail $targetroot]*.csv"] {
    file delete $filename 
  }
}

# ex: Daily com dashboard (14-August-2013).xlsx
# ex: Daily com dashboard (02-August-2013).xlsx
proc det_date {path} {
  if {[regexp {Daily com dashboard \(([^ ]+)\).xlsx$} $path z str]} {
    # puts "str: $str"
    clock format [clock scan $str -format "%d-%b-%Y"] -format "%Y-%m-%d" 
  } else {
    error "Could not determine date from: $path" 
  }
}

# @note was probleem hier dat ik ook al deels de DB vul (tabel logfile_date), zou pas later moeten.
# nu alleen lezen hier, en pas aan het einde schrijven.
proc get_header {db logfile_id f filedate} {
  set h1 [csv::split [gets $f]]
  set h2 [csv::split [gets $f]]
  set prev_date "9999-12-31"
  set res [dict create]
  for {set daycol 11} {$daycol <= 77} {incr daycol 11} {
    set datestr [lindex $h1 $daycol] ; # 15-Aug-13
    log debug "datestr: $datestr"
    if {$datestr == ""} {
      # date not filled in yet, assume no data yet for this column.
      continue 
    }
    set date [clock format [clock scan $datestr -format "%d-%b-%y"] -format "%Y-%m-%d"]
    if {$date > $prev_date} {
      # vorige date nog oude data (wel vaag dat dit dan blijkbaar ook andere data is)
      # reset result en deze wel afhandelen.
      set res [dict create]
    }
    if {$date >= $filedate} {
      # Nog niet ingevulde kolommen.
      # reset result en meteen door met volgende.
      set res [dict create]
    } elseif {[is_read_date $db $date]} {
      log debug "Already read data from $date before, ignore here" 
    } else {
      # set logfile_id [$db insert logfile [dict create path $filename date $filedate] 1]
      # $db insert logfile_date [dict create logfile_id $logfile_id date $date]
      for {set i 0} {$i < 11} {incr i} {
        set countrycol [expr $daycol + $i]
        set country [lindex $h2 $countrycol]
        dict set res $date $country $countrycol
      }
    }
    set prev_date $date
  }
  # breakpoint
  return $res
}

proc is_read_date {db date} {
  if {[llength [db_query [$db get_conn] "select id from logfile_date where date='$date'"]] > 0} {
    return 1 
  } else {
    return 0 
  }
}

main $argv
