#!/home/nico/bin/tclsh

# @todo waarsch bug in mysqltcl, waardoor é etc niet goed in mysql db terechtkomen. Wel goed in html, ook goed in log (utf-8), niet goed in DB, zowel in 
# sql explorer als in web2py.

package require ndv
package require Tclx

::ndv::source_once ScheidsSchemaDef.tcl

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]

proc main {argc argv} {
  global db conn log ar_argv
  
  $log debug "argv: $argv"
  set options {
      {seizoen.arg "2011-2012" "Welk seizoen (directory)"}
      {fromdate.arg "2010-01-01" "Vanaf welke datum status bijwerken"}
      {todate.arg "9999-01-01" "Tot welke datum status bijwerken"}
      {status.arg "gemaild" "Status to set"}
      {loglevel.arg "" "Set global log level"}
  }
  set usage ": [file tail [info script]] \[options] :"
  array set ar_argv [::cmdline::getoptions argv $options $usage]
  if {$ar_argv(loglevel) != ""} {
    ::ndv::CLogger::set_log_level_all $ar_argv(loglevel)  
  }
  ::ndv::CLogger::set_logfile "insert-input.log"
  
  set schemadef [ScheidsSchemaDef::new]
  $schemadef set_db_name_user_password scheids nico "pclip01;"
  set db [::ndv::CDatabase::get_database $schemadef]
  set conn [$db get_connection]
  
  set_status $ar_argv(fromdate) $ar_argv(todate) $ar_argv(status)
}

proc set_status {fromdate todate status} {
  global log
  set query "update scheids set status = '$status' where wedstrijd in (select id from wedstrijd where datumtijd between '$fromdate' and '$todate')"
  $log debug "query: $query"
  exec_query $query
}

proc exec_query {query} {
  global db
  set conn [$db get_connection]
  ::mysql::exec $conn $query
}

main $argc $argv

