# test database connection with perftoolset like CDatabase etc.

package require ndv
package require Tclx

::ndv::source_once [file join [file dirname [info script]] PerfMeetModSchemaDef.tcl]

set lst_machines {
  u151 A3-Schaduw
  u152 A3-Indis
  V7QYR4032 A3-Siebel
  V7QYR4802 A3-Fabriek
  V7SYL4003 A3-Database 
}

# lijst van regexps op tasks en manier waarop deze in graph getoond moeten worden.
set lst_task_mappings {
  ^CO02$ "2-fabriek"
  ^CO03$ "3-siebel"
  ^CO04$ "4-retourdata"
  ^CO06$ "6-filenet"
  ^CO07$ "7-convdat"
  ^CO08$ "8-stoppen"
  ^CO09$ "9-schonen"
  ^CO10$ "10-logsfout"
  ^CO11$ "11-controlestart"
  ^CO12$ "12-klaar"
  CO02-CO09 "2-9-scheduler"
  CO04-CO11 "4-11-copy/delete"
  CO09-CO03 "9-3-siebel"
  "CO[0-9]{2}-CO[0-9]{2}" "wait" 
}

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]

proc main {argc argv} {
  global log 

  $log debug "argv: $argv"
  set options {
      {db.arg "indmeetmod" "Gebruik andere database"}
      {dbuser.arg "perftest" "Gebruik andere database user"}
      {dbpassword.arg "perftest" "Gebruik ander database password"}
      {loglevel.arg "" "Zet globaal log level"}
  }
  set usage ": [file tail [info script]] \[options] :"
  array set ar_argv [::cmdline::getoptions argv $options $usage]
  
  if {$ar_argv(loglevel) != ""} {
    ::ndv::CLogger::set_log_level_all $ar_argv(loglevel)  
  }
  $log info START
    
  set schemadef [PerfMeetModSchemaDef::new]
  $schemadef set_db_name_user_password $ar_argv(db) $ar_argv(dbuser) $ar_argv(dbpassword)
  set db [::ndv::CDatabase::get_database $schemadef]

  set_machines $db
  set_taskdefs $db
  
  $log info FINISHED
}

proc set_machines {db} {
  global log lst_machines 
  foreach {name type} $lst_machines {
    if {[$db find_objects machine -name $name] == {}} {
      $db insert_object machine -name $name -type $type
    } else {
      $db update_object machine $name -type $type 
    }
  }
}

# als taskdefs met de hand aangepast, dan hier afblijven
proc set_taskdefs {db} {
  global log
  foreach taskname [::mysql::sel [$db get_connection] "select distinct taskname from task" -flatlist] {
    if {[$db find_objects taskdef -taskname $taskname] == {}} {
      make_taskdef $db $taskname
    } else {
      # record bestaat al, hier niet aanpassen. 
    }
  }
}

proc make_taskdef {db taskname} {
  global log lst_task_mappings
  set found 0
  foreach {re graphlabel} $lst_task_mappings {
    if {[regexp -- $re $taskname]} {
      set found 1
      $db insert_object taskdef -taskname $taskname -graphlabel $graphlabel
      break
    }
  }
  if {!$found} {
    # insert default record
    $db insert_object taskdef -taskname $taskname -graphlabel $taskname
  }
}

main $argc $argv
