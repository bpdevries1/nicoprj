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
  lassign $argv logdir dbfile
  puts "logdir: $logdir"
  puts "dbfile: $dbfile"
  create_db $dbfile
  handle_logdir $logdir
  finish_db
}

proc create_db {dbfile} {
  file delete -force $dbfile
  sqlite3 db $dbfile
  
  # set fields [list t lt ts s lb rc rm tn dt de by ng na hn]
  set fields [list ts ip pcname testname logfilename threadname startstop]
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

proc handle_logdir {logdir} {
  foreach ip [lsort [glob -tails -type d -directory $logdir *]] {
    foreach testname [lsort [glob -tails -type d -directory [file join $logdir $ip] *]] {
      foreach logfilename [lsort [glob -tails -type f -directory [file join $logdir $ip $testname] *.log]] { 
        handle_logfile $logdir $ip $testname $logfilename
      }
    }
  }
}

proc handle_logfile {logdir ip testname logfilename} {
  puts "handle logfile: $ip-$testname-$logfilename"
  set f [open [file join $logdir $ip $testname $logfilename] r]
  set pcname "<unknown>"
# 2012/10/20 10:30:01 INFO  - jmeter.threads.JMeterThread: Thread started: Thread Group 1-2
# 2012/10/20 14:01:40 INFO  - jmeter.threads.JMeterThread: Thread finished: Thread Group 1-38
  db eval "begin transaction"
  while {![eof $f]} {
    gets $f line
    # log debug $line
    if {[regexp {INFO  - jmeter.JMeter: IP: [^ ]+ Name: ([^ ]+) FullName:} $line z pc]} {
      set pcname $pc 
    } elseif {[regexp {^([0-9 /:]+) INFO  - jmeter.threads.JMeterThread: Thread ([^ ]+): (.+)$} $line z dt startstop threadname]} {
      set ts [det_ts $dt]
      set query "insert into logline (ts, ip, pcname, testname, logfilename, threadname, startstop) values ('$ts', '$ip', '$pcname', '$testname', '$logfilename', '[string trim $threadname]', '$startstop')"
      db eval $query
    }
  }
  db eval "commit"
  close $f  
  puts "finished logfile: $ip-$testname-$logfilename"
}

proc det_ts {dt} {
  # 2012/10/20 10:30:01
  set t [clock scan $dt -format "%Y/%m/%d %H:%M:%S"]
  clock format $t -format "%Y-%m-%d %H:%M:%S"  
}

proc log {args} {
  # global log
  variable log
  $log {*}$args
}

main $argv
