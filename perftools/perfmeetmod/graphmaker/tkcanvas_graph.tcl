package require ndv
package require mysqltcl
package require Tclx

::ndv::source_once [file join [file dirname [info script]] .. PerfMeetModSchemaDef.tcl]

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]

#@todo canvas groter maken.
#@todo gnuplot weer aanroepen bij een resize van de canvas.

proc main {argc argv} {
  global graph_id db log
  
  set options {
    {g.arg "" "Graphfile.tcl"}
    {db.arg "testmeetmod" "Gebruik andere database"}
    {dbuser.arg "perftest" "Gebruik andere database user"}
    {dbpassword.arg "perftest" "Gebruik ander database password"}
    {loglevel.arg "" "Zet globaal log level"}
  }

  set usage ": [file tail [info script]] \[options] :"
  array set ar_argv [::cmdline::getoptions argv $options $usage]
  if {$ar_argv(g) == ""} {
    puts [::cmdline::usage $options $usage]
    exit 1
  }

  if {$ar_argv(loglevel) != ""} {
    ::ndv::CLogger::set_log_level_all $ar_argv(loglevel)  
  }

  ::ndv::CLogger::set_logfile "tkcanvas.log"
  
  set schemadef [PerfMeetModSchemaDef::new]
  $schemadef set_db_name_user_password $ar_argv(db) $ar_argv(dbuser) $ar_argv(dbpassword)
  set db [::ndv::CDatabase::get_database $schemadef]
  
  set graph_filename $ar_argv(g)
  set graph_id [det_graph_id $graph_filename]
  source $graph_filename
  canvas .c -width 1000 -height 200
  text .t -wrap word -height 10
  pack .c -fill both -expand 1
  pack .t -fill x -expand 0
  bind .c <Configure> {gnuplot .c}
  gnuplot .c
}

proc det_graph_id {graph_filename} {
  global db log
  set sql "select id from graph where path = '[file normalize $graph_filename]'"
  $log debug "sql: $sql"
  lassign [::mysql::sel [$db get_connection] $sql -flatlist] res
  if {$res == ""} {
    $log warn "Cannot determine graph_id from $graph_filename" 
  }
  return $res   
}

proc user_gnuplot_coordinates {win id args} {
  global db log graph_id
  puts "win: $win, id: $id"
  set tag [det_tag [.c itemcget $id -width]]
  lassign [::mysql::sel [$db get_connection] "select l.path, t.threadname, t.threadnr, t.taskname, t.dt_start, t.dt_end, t.sec_duration, t.details \
                                              from logfile l, task t, task_graph tg
                                              where l.id = t.logfile_id
                                              and tg.task_id = t.id
                                              and tg.graph_id = $graph_id
                                              and tg.tag = $tag" -flatlist] path threadname threadnr taskname dt_start dt_end sec_duration details
  foreach el {tag path threadname threadnr taskname dt_start dt_end sec_duration details} {
    puts "$el: [set $el]"
    puts "-------------"
    $log debug "$el: [set $el]"
  }
  
  # set text "[clock format [clock seconds]]\n"
  set text [join [::struct::list mapfor el {path threadname threadnr taskname dt_start dt_end sec_duration details} {string trim "$el: [set $el]"}] "\n"]
  .t replace 1.0 end $text
}

proc det_tag {width} {
  return [expr round(($width - int($width)) * 1000000)] 
}

main $argc $argv
