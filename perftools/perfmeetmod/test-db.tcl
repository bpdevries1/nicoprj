# test database connection with perftoolset like CDatabase etc.

package require ndv
package require Tclx

::ndv::source_once [file join [file dirname [info script]] PerfMeetModSchemaDef.tcl]
::ndv::source_once [file join [file dirname [info script]] lib CDatabase.tcl]
::ndv::source_once [file join [file dirname [info script]] logreader LogReaderFactory.tcl]
::ndv::source_once [file join [file dirname [info script]] graphmaker TaskGraph.tcl]

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]

proc main {} {
  #test_db
  #set testrun_id [test_readlog]
  #make_task_graph $testrun_id
  make_task_graph 12
}

proc test_db {} {
  # set db [CDatabase::get_database]
  set db [CDatabase::get_database PerfMeetModSchemaDef]
  if {1} {
    # add test records 
    set id [$db insert_object logfile -path "/test/pad" -kind "testje"]
  }
  set lf [$db find_objects logfile -id $id]
  puts "logfiles found for $id: $lf"
  set lf [$db find_objects logfile -kind testje]
  puts "logfiles found: $lf"
  $db delete_object logfile $id
}

proc test_readlog {} {
  global log
  # set datadir "i:/klanten/ind/performance/input/logtest"
  set datadir "/media/nas/ITX/input/logtest"
  $log debug "data dir: $datadir"

  set db [CDatabase::get_database PerfMeetModSchemaDef]
  set testrun_id [$db insert_object testrun -name "testje"]
  
  set lr_fact [LogReaderFactory::get_instance]
  foreach date_subdir [glob -type d -directory $datadir "20*"] {
     handle_date_subdir $date_subdir $lr_fact $db $testrun_id
  }   
  return $testrun_id
}

proc handle_date_subdir {date_subdir lr_fact db testrun_id} {
  global log
  # set f [open [file join $date_subdir samenvatting.tsv] w]
  for_recursive_glob filename [list $date_subdir] "*" {
    # alleen log en csv
    # $log debug "Reading file: $filename"
    set reader [$lr_fact get_reader $filename]
    if {$reader != ""} {
      $reader read_log $filename $db $testrun_id
    }
    if {0} {
      set ext [file extension $filename]
      if {$ext == ".log" || $ext == ".csv"} {
        handle_log_file $filename $f 
      }
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

main
