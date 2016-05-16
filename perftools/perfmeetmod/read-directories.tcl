# test database connection with perftoolset like CDatabase etc.

package require ndv
package require Tclx

::ndv::source_once [file join [file dirname [info script]] PerfMeetModSchemaDef.tcl]
# ::ndv::source_once [file join [file dirname [info script]] lib CDatabase.tcl]
::ndv::source_once [file join [file dirname [info script]] logreader LogReaderFactory.tcl]
::ndv::source_once [file join [file dirname [info script]] graphmaker TaskGraph.tcl]

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]

proc main {argc argv} {
  global log

  $log debug "argv: $argv"
  set options {
      {dd.arg "i:/klanten/ind/performance/input/logging-remco-20091221" "Gebruik andere data en results dir"}
      {db.arg "indmeetmod" "Gebruik andere database"}
      {dbuser.arg "perftest" "Gebruik andere database user"}
      {dbpassword.arg "perftest" "Gebruik ander database password"}
      {loglevel.arg "" "Zet globaal log level"}
  }
  set usage ": [file tail [info script]] \[options] :"
  array set ar_argv [::cmdline::getoptions argv $options $usage]
  if {$ar_argv(dd) == ""} {
    puts [::cmdline::usage $options $usage]
    exit 1
  }
  set datadir $ar_argv(dd)

  if {$ar_argv(loglevel) != ""} {
    ::ndv::CLogger::set_log_level_all $ar_argv(loglevel)  
  }
  ::ndv::CLogger::set_logfile "read-directories.log"
  $log info START
    
  $log debug "data dir: $datadir"

  set schemadef [PerfMeetModSchemaDef::new]
  $schemadef set_db_name_user_password $ar_argv(db) $ar_argv(dbuser) $ar_argv(dbpassword)
  set db [::ndv::CDatabase::get_database $schemadef]
    
  set lr_fact [LogReaderFactory::get_instance $db]
  # 27-12-2009 NdV alleen toevoegen als nog niet eerder is ingelezen
  foreach date_subdir [glob -nocomplain -type d -directory $datadir "20*"] {
    $log debug "handle (for-loop) $date_subdir"
    handle_date_subdir $date_subdir $lr_fact $db
    if {0} {
      set testrun_ids [$db find_objects testrun -name $date_subdir]
      if {$testrun_ids == {}} {
        set testrun_id [$db insert_object testrun -name $date_subdir]
        handle_date_subdir $date_subdir $lr_fact $db $testrun_id
      } else {
        $log info "Already (partially) read: $date_subdir, check files also"
        handle_date_subdir $date_subdir $lr_fact $db [lindex $testrun_ids 0]
      }
    }
  } 
  
  # 13-4-2010 NdV ook script kunnen aanroepen op een enkele run. 
  if {[regexp {^20} [file tail $datadir]]} {
    handle_date_subdir $datadir $lr_fact $db
  }
  
  set_filter_resname $db
  
  $log info FINISHED
  ::ndv::CLogger::close_logfile  
}

proc handle_date_subdir {date_subdir lr_fact db} {
  global log
  $log debug "handle_date_subdir: $date_subdir"
  
  # 13-4-2010 NdV testrun_id binnen deze proc bepalen.
  set testrun_ids [$db find_objects testrun -name $date_subdir]
  if {$testrun_ids == {}} {
    set testrun_id [$db insert_object testrun -name $date_subdir]
  } else {
    $log info "Already (partially) read: $date_subdir, check files also"
    set testrun_id [lindex $testrun_ids 0]
  }
  
  # set f [open [file join $date_subdir samenvatting.tsv] w]
  for_recursive_glob filename [list $date_subdir] "*" {
    if {[file isdirectory $filename]} {
      continue 
    }
    set logfile_ids [$db find_objects logfile -path $filename]
    if {$logfile_ids == {}} {
      # $log debug "Reading file: $filename"
      set reader [$lr_fact get_reader $filename]
      if {$reader != ""} {
        # $reader read_log $filename $db $testrun_id
        $log info "read log START   : $filename"
        $reader read_log $filename $testrun_id
        $log info "read log FINISHED: $filename"
      } else {
        $log warn "No reader found for: $filename" 
      }
    } else {
      $log info "Already read: $filename"  
    }
  }
  # close $f
}

proc handle_date_subdir_old {date_subdir lr_fact db testrun_id} {
  global log
  $log debug "handle_date_subdir: $date_subdir"
  # set f [open [file join $date_subdir samenvatting.tsv] w]
  for_recursive_glob filename [list $date_subdir] "*" {
    if {[file isdirectory $filename]} {
      continue 
    }
    set logfile_ids [$db find_objects logfile -path $filename]
    if {$logfile_ids == {}} {
      # $log debug "Reading file: $filename"
      set reader [$lr_fact get_reader $filename]
      if {$reader != ""} {
        # $reader read_log $filename $db $testrun_id
        $log info "read log START   : $filename"
        $reader read_log $filename $testrun_id
        $log info "read log FINISHED: $filename"
      } else {
        $log warn "No reader found for: $filename" 
      }
    } else {
      $log info "Already read: $filename"  
    }
  }
  # close $f
}

proc make_task_graph {testrun_id} {
  # set db [CDatabase::get_database PerfMeetModSchemaDef]
  set output_dir "/media/nas/ITX/input/logtest/output"
  set gm [TaskGraph::get_instance]
  $gm set_database [CDatabase::get_database PerfMeetModSchemaDef]
  $gm make_graph $testrun_id $output_dir
}

# set a default filter on resname, so not all re::ndv::source_onces will be shown in re::ndv::source_once graph
proc set_filter_resname {db} {
  global log
  $log info "set_filter_rename"
  set conn [$db get_connection]
  set query "update resname set tonen = 0"
  ::mysql::exec $conn $query
  set lst_names [list "Available MBytes" "Network Interface" "Time" "usr" "sys" "wio" "freemem"]
  
#6, 'Processor(_Total)\Percentage processortijd', 'Percentage processortijd', 0
#7, 'Geheugen\Beschikbare megabytes (MB)', 'Beschikbare megabytes (MB)', 0
#8, 'Fysieke schijf(_Total)\Percentage schijftijd', 'Percentage schijftijd', 0
#9, 'Netwerkinterface(Realtek RTL8168_8111 PCI-E Gigabit Ethernet NIC - Pakketplanner-minipoort)\Totaal aantal bytes per seconde', 'Totaal aantal bytes per seconde', 0
#10, 'Netwerkinterface(MS TCP Loopback interface)\Totaal aantal bytes per seconde', 'Totaal aantal bytes per seconde', 0

  # 29-1-2010 NdV ook Nederlandse namen, in de DAP.
  lappend lst_names "_Total" "Geheugen" "Netwerkinterface" 
  foreach name $lst_names {
    set query "update resname set tonen = 1
               where fullname like '%$name%'"
    ::mysql::exec $conn $query
  }
}

main $argc $argv
