# maak overzicht vanuit urenlog met als doel input voor CV.

package require ndv
package require Tclx
# package require csv
package require sqlite3

set log [ndv::CLogger::new_logger [file tail [info script]] debug]

proc log {args} {
  global log
  $log {*}$args
}

# Goal: output html (table) with info of last n runs of all scripts on all sentinels.
proc main {argv} {
  lassign $argv uren_xls_filename
  set basename [file rootname $uren_xls_filename]
  set uren_filename [convert_tsv $uren_xls_filename $basename]
  # set uren_filename [file join [file dirname $uren_xls_filename] uren-saldo_Uren.tsv]
  handle_uren $uren_filename
  handle_mapping [file dirname $uren_xls_filename]
}

# @return filename of tsv file with uren-tab data. 
proc convert_tsv {uren_xls_filename basename} {
  set infile [file nativename [file normalize $uren_xls_filename]]
  set outbase [file nativename [file normalize $basename]]
  # set scriptname [file nativename [file normalize [file join .. excel-export xls2tsv.vbs]]]
  set scriptname [file nativename [file normalize [file join .. .. lib xls2tsv.vbs]]]
  foreach filename [glob -nocomplain -directory [file dirname $basename] "[file tail $basename]_*.tsv"] {
    log info "Delete: $filename"
    file delete $filename
  }
  exec cscript.exe $scriptname $infile $outbase
  set uren_filename "${basename}_uren.tsv"
  return $uren_filename  
}

proc handle_uren {uren_filename} {
  create_db "$uren_filename.db"
  db eval "begin transaction"
  read_uren $uren_filename
  db eval "commit"
}

proc create_db {db_name} {
  file delete $db_name
  sqlite3 db $db_name
  db eval "create table urendag (date, project, hours, comments)"
  db eval "create table target_mapping (project, target, target_project)"
}

proc read_uren {uren_filename} {
  set f [open $uren_filename r]
  gets $f z ; # headerline
  while {![eof $f]} {
    gets $f line
    lassign [split $line "\t"] z date year day week project z z hours comments
    if {$hours > 0} {
      # db eval "insert into urendag values ('$date', '$project', $hours, '$comments')"
      set sqldate [det_sqldate $date]
      log debug "insert into urendag values ('$date', '$project', $hours, '$comments')"
      db eval {insert into urendag values ($sqldate, $project, $hours, $comments)}
    } elseif {$hours == ""} {
      # ok 
    } elseif {$hours == 0} {
      # ok 
    } else {
      log warn "strange line $line" 
    }
  }  
  close $f
}

proc det_sqldate {date} {
  try_eval {
    set sec [clock scan $date -format "%a %d/%m/%Y"]
  } {
    log error "could not parse date: $date"
    breakpoint
  }
  clock format $sec -format "%Y-%m-%d"
}
#   db eval "create table target_mapping (project, target, target_project)"
proc handle_mapping {dirname} {
  set mapping_filename [file join $dirname "uren-saldo_Mapping.tsv"]
  set lst [csv2dictlist $mapping_filename "\t"]
  db eval "begin transaction"
  foreach row $lst {
    set project [dict get $row Project]
    foreach key [dict keys $row] {
      if {$key == "Project"} {continue}
      set target $key
      set target_project [dict get $row $key]
      db eval {insert into target_mapping values ($project, $target, $target_project)}
    }
  }
  db eval "commit"
  # breakpoint
}

main $argv

