#!/home/nico/bin/tclsh

catch {package require tclodbc}
catch {package require mysqltcl}
catch {package require sqlite3}

package require ndv
package require Tclx

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]

proc main {argc argv} {
  global log db stderr

  $log debug "argv: $argv"
  set options {
    {q.arg "" "Query"}
    {f.arg "result.tsv" "Result file"}
    {conntype.arg "mysql" "Connection type (mysql, sqlite or odbc)"}
    {db.arg "ForceDB" "Gebruik database"}
    {user.arg "sql_perf" "Gebruik database user"}
    {pw.arg "Welkom01" "Gebruik database password"}
    {loglevel.arg "" "Zet globaal log level"}
  }
  set usage ": [file tail [info script]] \[options] :"
  array set ar_argv [::cmdline::getoptions argv $options $usage]

  if {$ar_argv(q) == ""} {
    puts stderr "Query is empty, quitting"
    exit 1
  }
  
  if {$ar_argv(loglevel) != ""} {
    ::ndv::CLogger::set_log_level_all $ar_argv(loglevel)  
  }
  ::ndv::CLogger::set_logfile "[file rootname [file tail [info script]]].log"
  $log info START

  set f [open $ar_argv(f) w]
  if {$ar_argv(conntype) == "odbc"} {
    do_odbc $ar_argv(db) $ar_argv(user) $ar_argv(pw) $f $ar_argv(q)  
  } elseif {$ar_argv(conntype) == "mysql"} {
    do_mysql $ar_argv(db) $ar_argv(user) $ar_argv(pw) $f $ar_argv(q)
  } elseif {$ar_argv(conntype) == "sqlite"} {
    do_sqlite $ar_argv(db) $f $ar_argv(q)
  }
  
  close $f
  $log info FINISHED
}

proc do_odbc {db user pw f query} {
  database connect conn $db $dbuser $pw
  # todo header info?
  # puts $f [join [list tablename nrecords] ,]
  foreach row [conn $query] {
    puts $f [join $row "\t"]
  }
  database disconnect conn
}

proc do_mysql {db user pw f query} {
  set conn [::mysql::connect -host localhost -user $user -password $pw -db $db]  
  # todo header info?
  # puts $f [join [list tablename nrecords] ,]
  foreach row [::mysql::sel $conn $query -list] {
    puts $f [join $row "\t"]
  }
  ::mysql::close $conn
}

proc do_sqlite {db f query} {
  sqlite3 db $db
  db eval $query values {
    set row {}
    foreach el $values(*) {
      lappend row $values($el)
    }
    puts $f [join $row "\t"]
  }
  db close
}

main $argc $argv
