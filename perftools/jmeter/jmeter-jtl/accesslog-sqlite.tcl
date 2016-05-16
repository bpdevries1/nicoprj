# convert an access log file to sqlite db.

package require sqlite3
package require Tclx

# own package
package require ndv

# lines
# <httpSample t="2430" lt="2426" ts="1350721801764" s="true" lb="Behandelaar ophalen" rc="200" rm="OK" tn="Thread Group 1-2" 
# dt="text" de="utf-8" by="555" ng="2" na="2" hn="P3738"/>
set log [::ndv::CLogger::new_logger [file tail [info script]] debug]

proc main {argv} {
  puts "argv: $argv"
  lassign $argv acclogfile dbfile
  puts "acclogfile: $acclogfile"
  puts "dbfile: $dbfile"
  create_db $dbfile
  handle_acclog $acclogfile
  finish_db
}

proc create_db {dbfile} {
  file delete -force $dbfile
  sqlite3 db $dbfile
  
  # set fields [list t lt ts s lb rc rm tn dt de by ng na hn]
  set fields [list ts ip method url rc t]
  db eval "create table logline ([join $fields ", "])"
  db close
  sqlite3 db $dbfile
  puts "Created db: $dbfile"
}

proc finish_db {} {
  puts "Create index on ts:"
  db eval "create index ix_ts on logline (ts)"
  puts "Creating indexes finished, closing db"
  db close
}

proc handle_acclog {acclogfile} {
  db eval "begin transaction"
  set f [open $acclogfile r]
  set cnt 0
  while {![eof $f]} {
    gets $f line
    if {[regexp {^([0-9\.]+) - - \[([^\]]+)\] \x22([^ ]+) ([^ ]+) HTTP/1.1\x22 (\d+) (\d+)$} $line z ip datetime method url rc t]} {
      incr cnt
      if {[expr $cnt % 1000] == 0} {
        puts "Handled $cnt loglines"
        db eval "commit"
        db eval "begin transaction"
      }
      logline $ip $datetime $method $url $rc $t      
    } elseif {[regexp POST $line]} {
      puts "wrong post RE?"
      breakpoint      
    } else {
      # nothing for now
    }
  }
  db eval "commit"
}

proc logline {ip datetime method url rc t} {
  set ts [det_ts $datetime]
  set query "insert into logline (ts, ip, method, url, rc, t) values ('$ts', '$ip', '$method', '$url', $rc, $t)"
  db eval $query  
}

proc det_ts {dt} {
  set t [clock scan $dt -format "%d/%b/%Y:%H:%M:%S +0200"]
  clock format $t -format "%Y-%m-%d %H:%M:%S"  
}

proc log {args} {
  # global log
  variable log
  $log {*}$args
}

main $argv
