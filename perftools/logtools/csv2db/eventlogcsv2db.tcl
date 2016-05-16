package require Tclx
package require csv
package require sqlite3

# own package
package require ndv

# lines
# <httpSample t="2430" lt="2426" ts="1350721801764" s="true" lb="Behandelaar ophalen" rc="200" rm="OK" tn="Thread Group 1-2" 
# dt="text" de="utf-8" by="555" ng="2" na="2" hn="P3738"/>
set log [::ndv::CLogger::new_logger [file tail [info script]] debug]

proc main {argv} {
  puts "argv: $argv"
  # lassign $argv sourcefile targetdb
  lassign $argv sourcedir targetdb
  make_db $targetdb
  convert_files $sourcedir  
  db close
}
# 28/11/2012,11:36:22,Windows SharePoint Services 3,Error,(807),8214,N/A,VSW-APL-021,"The description for Event ID ( 8214 ) in Source ( Windo

proc convert_files {sourcedir} {
  handle_dir_rec $sourcedir "*eventlog*.csv" convert_file
}

proc handle_dir_rec {dir globpattern actionproc} {
  foreach filename [glob -nocomplain -directory $dir -type f $globpattern] {
    $actionproc $filename 
  }
  foreach dirname [glob -nocomplain -directory $dir -type d *] {
    handle_dir_rec $dirname $globpattern $actionproc 
  }
}

proc convert_file {sourcefile} {
  # make_db $targetdb
  log info "Read eventlog source: $sourcefile"
  # return ; # for test.
  
  set f [open $sourcefile r]
  # @note goal is to only read a newline (with gets) when CRLF is encountered, not just a CR.
  fconfigure $f -translation crlf
  set lines ""
  set nlines 0
  set totallines 0
  db eval "begin transaction"
  while {![eof $f]} {
    gets $f line
    regsub -all {\r} $line "**" line
    set totallines [expr $totallines + 1]
    if {[expr $totallines % 1000] == 0} {
      log info "Lines read: $totallines" 
      db eval "commit"
      db eval "begin transaction"
    }
    append lines "$line\n"
    incr nlines
    if {$nlines > 100} {
      log warn "nlines > 100: $nlines" 
    }
    if {[csv::iscomplete $lines]} {
      lassign [csv::split $lines] date time source type category event user computer details
      set datetime [det_datetime $date $time]
      if {$datetime != ""} {
        set id [insert_eventlog $datetime $sourcefile $type $source $category $event $user $computer $details]
        handle_specific $id $datetime $type $source $category $event $user $computer $details
      } else {
        log warn "Cannot handle lines: $lines" 
      }
      set lines ""
      set nlines 0
    } 
  }
  close $f
  if {$lines != ""} {
    log warn "lines not empty at end-of-file: $lines" 
  }
  db eval "commit"
  
}

proc make_db {dbname} {
  file delete $dbname
  sqlite3 db $dbname
  db eval "create table eventlog (id integer primary key autoincrement, sourcefile, datetime, type, source, category, event, user, computer, details)"
  
  # specific VLOS: only if "timed out" occurs in details
  db eval "create table vlosevent (event_id, datetime, event, computer, thelistid, theviewid, notes, thelistscom, theviewscom, url)"
  
}

# 28/11/2012,11:36:22
proc det_datetime {date time} {
  if {[regexp {^(\d\d)/(\d\d)/(\d\d\d\d)$} $date z day month year]} {
    return "$year-$month-$day $time" 
  } elseif {[string length $date] <= 1} {
    # date can be a single newline.
    return ""
  } else {
    log warn "Could not parse date: =>$date<="
    return ""
  }
}

proc insert_eventlog {datetime sourcefile type source category event user computer details} {
  set query "insert into eventlog (datetime, sourcefile, type, source, category, event, user, computer, details)
             values ('$datetime', '$sourcefile', '$type', '$source', '$category', '$event', '$user', '$computer', '[remove_quotes $details]')"
  # log debug "query: $query"
  db eval $query
  db last_insert_rowid
}

# replace single quote by double single quote, to solve problems in SQL
proc remove_quotes {str} {
  regsub -all {'} $str "''" str
  return $str
}

#       <listName>459f1f84-d9ea-4ea4-b9a2-eb63d50bc4f7</listName>
#       <viewName>d9025eb8-1cdb-4971-a622-ae7d96ba90b2</viewName>
proc handle_specific {event_id datetime type source category event user computer details} {
  # @todo
  # notes, thelistscom, theviewscom
  set notes {}
  set thelistid ""
  set theviewid ""
  set thelistscom ""
  set theviewscom ""
  set url ""
  if {$event == "1309"} {
    update_notes notes $details
    set url [det_url $details]
    if {[regexp {thelist\.ID\.ToString\(\) : ([0-9a-f-]+)\n} $details z id]} {
      set thelistid $id
      if {$thelistid == "459f1f84-d9ea-4ea4-b9a2-eb63d50bc4f7"} {
        set thelistscom "yes" 
      } else {
        set thelistscom "no"
      }
    }
    if {[regexp {theview\.ID\.ToString\(\) : ([0-9a-f-]+)\n} $details z id]} {
      set theviewid $id
      if {$theviewid == "d9025eb8-1cdb-4971-a622-ae7d96ba90b2"} {
        set theviewscom "yes" 
      } else {
        set theviewscom "no"
      }
    }
  } else {
    lappend notes "event != 1309" 
  }
  set query "insert into vlosevent (event_id, datetime, event, computer, thelistid, theviewid, notes, thelistscom, theviewscom, url)
             values ($event_id, '$datetime', '$event', '$computer', '$thelistid', '$theviewid', '[join $notes ";"]', '$thelistscom', '$theviewscom', '$url')"
  # log debug "query: $query"
  try_eval {
    db eval $query
  } {
    log error $errorResult
    log error "query: $query"
    breakpoint
  }
}

proc update_notes {notes_name details} {
  upvar $notes_name notes
  set res [list "timed out" "geblokkeerd voor deze website" "Event code: 3001" "is gewijzigd door" \
                "not registered" "is uitgecheckt of vergrendeld" "Value does not fall within the expected range." \
                "NullReferenceException"]
  foreach re $res {
    if {[regexp $re $details]} {
      lappend notes $re 
    }
  }
  if {[regexp {Event code: 3005} $details]} {
    if {[llength [split $details "\n"]] <= 2} {
      lappend notes "Event code: 3005 no details"
    }
  }
  if {[regexp {Exception type: ([^\n ]+)} $details z exc_type]} {
    lappend notes "Exception type: $exc_type" 
  } else {
    if {$notes == {}} {
      breakpoint 
    }
  }
  
  if {[regexp {Event code: 3001} $details]} {
    log debug "Special characters newlines in details?"
    # breakpoint 
  }
}

proc det_url {details} {
  # Request URL: http://vlos/TK/2019-2020/20200101/Pages/werkverdeling.aspx
  if {[regexp {Request URL: ([^ ]+)} $details z url]} {
    return $url 
  } else {
    return "" 
  }
}

proc log {args} {
  global log
  # variable log
  $log {*}$args
}

main $argv
