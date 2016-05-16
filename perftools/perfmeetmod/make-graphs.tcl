# test database connection with perftoolset like CDatabase etc.

package require ndv
package require Tclx

::ndv::source_once [file join [file dirname [info script]] PerfMeetModSchemaDef.tcl]
# ::ndv::source_once [file join [file dirname [info script]] lib CDatabase.tcl]
::ndv::source_once [file join [file dirname [info script]] logreader LogReaderFactory.tcl]
::ndv::source_once [file join [file dirname [info script]] graphmaker TaskGraph.tcl]
::ndv::source_once [file join [file dirname [info script]] graphmaker ResourceGraph.tcl]
::ndv::source_once [file join [file dirname [info script]] graphmaker DoHtmlWrapper.tcl]

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]

proc main {argc argv} {
  global log db ar_argv
  # ::ndv::CLogger::set_log_level_all info
  $log set_log_level info

  $log info "START"
  # ::ndv::CLogger::set_log_level_all debug
  
  $log debug "argv: $argv"
  set options {
    {tr.arg "" "Zet testrun prefix"}
    {o.arg "" "Zet output dir"}
    {s.arg "" "start datum-tijd: 2009-10-22-15-00-00"}
    {e.arg "" "eind  datum-tijd: 2009-10-22-15-30-00"}
    {reslogs "Make resource log graphs"}
    {tasks "Make task graphs"}
    {dohtml "Make doHtml graphs"}
    {taskfilter.arg "" "Apply a filter to tasknames (eg. \"task {regexp -- {file} $task}\""}
    {taskregexp.arg ".*" "Apply a regexp to tasknames (eg. file)"}
    {threadnameregexp.arg ".*" "Apply a regexp to thread names (eg. fabriek"}
    {subdir.arg "std" "Set a different subdir (useful with taskfilter/taskregexp and start-end)"}
    {min_duration.arg "0" "Show only tasks with a minimum duration (in seconds)"}
    {maxlines.arg "0" "Don't make graph if there are more lines than maxlines (0=no max)"}
    {dohtmlmaxlines.arg "0" "Don't doHtmlif there are more lines than maxlines (0=no max)"}
    {db.arg "indmeetmod" "Gebruik andere database"}
    {dbuser.arg "perftest" "Gebruik andere database user"}
    {dbpassword.arg "perftest" "Gebruik ander database password"}
    {loglevel.arg "" "Zet globaal log level"}
  }

  set usage ": [file tail [info script]] \[options] :"
  array set ar_argv [::cmdline::getoptions argv $options $usage]
  if {$ar_argv(o) == ""} {
    puts [::cmdline::usage $options $usage]
    exit 1
  }

  # if none of the options tasks,reslogs,dohtml is set, the default is to make all
  if {!$ar_argv(reslogs) && !$ar_argv(tasks) && !$ar_argv(dohtml)} {
    set ar_argv(reslogs) 1
    set ar_argv(tasks) 1
    set ar_argv(dohtml) 1
  }
  
  set testrun_prefix $ar_argv(tr)
  set output_dir $ar_argv(o)

  if {$ar_argv(loglevel) != ""} {
    ::ndv::CLogger::set_log_level_all $ar_argv(loglevel)  
  }
  ::ndv::CLogger::set_logfile "make-graphs.log"
  log_args
  
  set schemadef [PerfMeetModSchemaDef::new]
  $schemadef set_db_name_user_password $ar_argv(db) $ar_argv(dbuser) $ar_argv(dbpassword)
  set db [::ndv::CDatabase::get_database $schemadef]
  
  check_tables
  
  make_graphs $testrun_prefix $output_dir [to_ts $ar_argv(s)] [to_ts $ar_argv(e)]
  $log info "FINISHED"
  
  # old: make_index_html $testrun_prefix $output_dir

  ::ndv::CLogger::close_logfile
}

proc log_args {} {
  global ar_argv log
  foreach el [lsort [array names ar_argv]] {
    $log debug "$el: $ar_argv($el)" 
  }
}

proc check_tables {} {
  global log db ar_argv
  if {[::mysql::sel [$db get_connection] "select * from taskdef" -flatlist] == {}} {
    error "Table taskdef is empty, run set-machines-tasks.tcl" 
  }
  if {[::mysql::sel [$db get_connection] "select * from machine" -flatlist] == {}} {
    error "Table machine is empty, run set-machines-tasks.tcl" 
  }
}

#@param start/end: "" or "2009-10-22 12:00:00"
proc make_graphs {testrun_prefix output_dir start end} {
  global log db ar_argv
  set query "select id, name from testrun where name like '$testrun_prefix%' order by name"
  set qresult [::mysql::sel [$db get_connection] $query -flatlist]
  if {$qresult == {}} {
    $log warn "query returned no results: $query" 
  }
  set hh [::ndv::CHtmlHelper::new]
  foreach {testrun_id testrun_name} $qresult {
    if {$ar_argv(tasks)} {
      # determine new start and end based on task graph
      foreach {start1 end1} [make_task_graph $testrun_id $testrun_name [file join $output_dir [file tail $testrun_name]] $start $end] break
      # @return of make_task_graph: list with 2 elements: start and end, in format 2009-11-23 12:23:45
      # so datetime format should remain the same.
    } else {
      set start1 $start
      set end1 $end
    }
    if {$ar_argv(reslogs)} {
      # if no task graph is made, start and end will not be changed.
      $log debug "calling make_resource_graph with start1-end1: $start1-$end1"
      make_resource_graph $testrun_id $testrun_name [file join $output_dir [file tail $testrun_name]] $start1 $end1
    }
    if {$ar_argv(dohtml)} {
      # if no task graph is made, start and end will not be changed.
      make_dohtml $testrun_id $testrun_name [file join $output_dir [file tail $testrun_name]] $start1 $end1
    }
    
    make_index_html [file join $output_dir [file tail $testrun_name] $ar_argv(subdir)] $testrun_name
    # $hh copy_files_to_output [file join $output_dir [file tail $testrun_name]] ; # copy collapse.js.
  }
  ::itcl::delete object $hh
}

#@param start/end: "" or "2009-10-22 12:00:00"
proc make_task_graph {testrun_id testrun_name output_dir start end} {
  global log db ar_argv
  # set db [CDatabase::get_database PerfMeetModSchemaDef]
  # set output_dir "/media/nas/ITX/input/logtest/output"
  set tg [TaskGraph::get_instance]
  # $tg set_database [CDatabase::get_database PerfMeetModSchemaDef]
  $tg set_database $db
  $tg set_taskfilter $ar_argv(taskfilter)
  $tg set_taskregexp $ar_argv(taskregexp)
  $tg set_threadnameregexp $ar_argv(threadnameregexp)
  # $tg set_taskgraphname $ar_argv(taskgraphname)
  $tg set_subdir $ar_argv(subdir)
  $tg set_min_duration $ar_argv(min_duration)
  $tg set_maxlines $ar_argv(maxlines)
  $tg make_graph $testrun_id $testrun_name $output_dir $start $end
}

#@param start/end: "" or "2009-10-22 12:00:00"
proc make_resource_graph {testrun_id testrun_name output_dir start end} {
  global log db ar_argv
  # set db [CDatabase::get_database PerfMeetModSchemaDef]
  # set output_dir "/media/nas/ITX/input/logtest/output"
  set rg [ResourceGraph::get_instance]
  $rg set_database $db
  
  set query "select distinct machine 
    from resusage r, logfile l
    where r.logfile_id = l.id
    and l.testrun_id = $testrun_id
    order by machine"
  set lst_machines [::mysql::sel [$db get_connection] $query -flatlist]
  foreach machine $lst_machines {
    # $rg make_graph $testrun_id $testrun_name $output_dir $machine $start $end
    $rg make_graph $testrun_id $testrun_name [file join $output_dir $ar_argv(subdir)] $machine $start $end
  }
}

proc make_dohtml {testrun_id testrun_name output_dir start end} {
  global log db ar_argv
  # set db [CDatabase::get_database PerfMeetModSchemaDef]
  # set output_dir "/media/nas/ITX/input/logtest/output"
  set dw [DoHtmlWrapper::get_instance]
  # $tg set_database [CDatabase::get_database PerfMeetModSchemaDef]
  $dw set_database $db
  $dw set_taskfilter $ar_argv(taskfilter)
  $dw set_taskregexp $ar_argv(taskregexp)
  $dw set_threadnameregexp $ar_argv(threadnameregexp)
  # $dw set_taskgraphname $ar_argv(taskgraphname)
  $dw set_subdir $ar_argv(subdir)
  $dw set_min_duration $ar_argv(min_duration)
  $dw set_maxlines $ar_argv(dohtmlmaxlines)
  $dw make_graph $testrun_id $testrun_name $output_dir $start $end
}

# @param str: 2009-10-22-15-00-00
# @result "2009-10-22 15:00:00"
proc to_ts {str} {
  if {$str == ""} {
    return $str 
  } else {
    set sec [clock scan $str -format "%Y-%m-%d-%H-%M-%S"]
    return [clock format $sec -format "%Y-%m-%d %H:%M:%S"]
  }
}

proc make_index_html {output_dir testrun_name} {
  # 21-1-2010 NdV voor de zekerheid eerst output-dir maken, kan mogelijk nog niet bestaan.
  file mkdir $output_dir
  set f [open [file join $output_dir index.html] w] 
  set hh [::ndv::CHtmlHelper::new]
  $hh set_channel $f
  $hh write_header $testrun_name
  foreach filename [glob -nocomplain -directory $output_dir -type f *.png] {
    make_index_filename $hh $filename 
  }
  
  $hh write_footer
  close $f
  $hh copy_files_to_output $output_dir ; # copy collapse.js.
}

proc make_index_filename {hh filename} {
  $hh text "<div class='collapsable'>[file tail $filename]<p>"
  # $hh text "Collapsable text" 
  $hh text [$hh get_img [file tail $filename]]
  $hh text "</p></div>"
}

proc make_index_subdir_old {hh subdir} {
  # @note <p> is nodig, als placeholder om dingen te vervangen met [+] etc. 
  $hh text "<div class='collapsable'><H2>$subdir</H2><p>"
  $hh text "Collapsable text" 
  
  $hh text "</div>"
}

main $argc $argv

