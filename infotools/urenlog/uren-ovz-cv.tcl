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
  lassign $argv uren_filename
  handle_uren $uren_filename
}

proc handle_uren {uren_filename} {
  create_db "$uren_filename.db"
  db eval "begin transaction"
  read_uren $uren_filename
  db eval "commit"
  #process_uren
  #write_html "$uren_filename.html"
}

proc create_db {db_name} {
  file delete $db_name
  sqlite3 db $db_name
  db eval "create table urendag (date, project, hours, comments)"
}

proc read_uren {uren_filename} {
  set f [open $uren_filename r]
  gets $f z ; # headerline
  while {![eof $f]} {
    gets $f line
    lassign [split $line "\t"] z date year day week project z z hours comments
    log debug "insert into urendag values ('$date', '$project', $hours, '$comments')"  
    if {$hours > 0} {
      # db eval "insert into urendag values ('$date', '$project', $hours, '$comments')"
      set sqldate [det_sqldate $date]
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

main $argv

