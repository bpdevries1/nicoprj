package require ndv
package require Tclx
package require textutil 

::ndv::source_once QueryDepSchemaDef.tcl

set DOT_DIR "d:\\util\\Graphviz2.26.3\\bin"

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]

proc main {argc argv} {
  global log db ar_argv

  $log debug "argv: $argv"
  set options {
      {o.arg "c:\\aaa\\indquerydep" "Output root directory"}
      {db.arg "indquerydep" "Gebruik andere database"}
      {dbuser.arg "itx" "Gebruik andere database user"}
      {dbpassword.arg "itx42" "Gebruik ander database password"}
      {loglevel.arg "" "Zet globaal log level"}
  }
  set usage ": [file tail [info script]] \[options] :"
  array set ar_argv [::cmdline::getoptions argv $options $usage]

  if {$ar_argv(loglevel) != ""} {
    ::ndv::CLogger::set_log_level_all $ar_argv(loglevel)  
  }
  ::ndv::CLogger::set_logfile "makehtml.log"
  $log info START
  
  set schemadef [QueryDepSchemaDef::new]
  $schemadef set_db_name_user_password $ar_argv(db) $ar_argv(dbuser) $ar_argv(dbpassword)
  set db [::ndv::CDatabase::get_database $schemadef]   
  
  make_dot $ar_argv(o)
  make_graphs $ar_argv(o)
  
  $log info FINISHED
  ::ndv::CLogger::close_logfile   
}

# make dot graph for table
proc make_html_tabel_graph {root_dir table id tabel_naam} {
  global log db ar_argv hhg DOT_DIR
  set conn [$db get_connection]
  
  set dot_filename [file join $root_dir $table "$table-$id.dot"]
  set png_filename [file join $root_dir $table "$table-$id.png"]
  set map_filename [file join $root_dir $table "$table-$id.map"]
  
  set f [open $dot_filename w]
  write_dot_header $f

  #puts_queries_bestand_only $f
  #puts_tables $f
  #puts_query_tables_bestand_only $f
  
  lassign [det_dependencies beide [list [list $id $tabel_naam]] {} {} {}] lst_tabellen lst_queries lst_tab2query lst_query2tab
  foreach el $lst_tabellen {
    lassign $el t_id t_naam
    set url "tabel-$t_id.html"
    puts $f "  t$t_id \[shape=rectangle,style=filled,fillcolor=darkolivegreen2,label=\"$t_naam\",URL=\"$url\"\];"
  }
  
  foreach el $lst_queries {
    lassign $el q_id q_regelnr b_id b_path
    # puts $f "  b$b_id \[shape=ellipse,style=filled,fillcolor=salmon,label=\"[file tail $b_path]\"\];"
    set url "../bestand/bestand-$b_id.html"
    puts $f "  q$q_id \[shape=ellipse,style=filled,fillcolor=salmon,label=\"[file tail $b_path]:$q_regelnr\",URL=\"$url\"\];"
  }
  
  # pijlen, beide kanten op.
  # q_ids er uit, unique sorten
  if {0} {
    foreach el [lsort -unique [struct::list mapfor el $lst_tab2query {ndv::lindices $el 0 2}]] {
      # lassign $el t_id q_id b_id
      lassign $el t_id b_id
      puts $f "t$t_id -> b$b_id;"
    }
  }
  if {1} {
    # toch per query
    foreach el $lst_tab2query {
      lassign $el t_id q_id b_id
      puts $f "t$t_id -> q$q_id;"
    }
  }
  
  
  if {0} {
    foreach el [lsort -unique [struct::list mapfor el $lst_query2tab {ndv::lindices $el 1 2}]] {
      lassign $el b_id t_id
      puts $f "b$b_id -> t$t_id;"
    }
  }
  if {1} {
    foreach el $lst_query2tab {
      lassign $el q_id b_id t_id
      puts $f "q$q_id -> t$t_id;"
    }
  }
  
  
  write_dot_footer $f
  
  close $f
  
  # breakpoint
  exec [file join $DOT_DIR dot.exe] -Tpng $dot_filename -o $png_filename
  exec [file join $DOT_DIR dot.exe] -Tcmap $dot_filename -o $map_filename
  
}

# richting: naar: van bron naar doeltabel
# richting: van: van doel naar brontabel
proc det_dependencies {richting lst_tabellen lst_queries lst_tab2query lst_query2tab} {
  global db log
  if {$richting == "beide"} {
    # zou met map/zip moeten kunnen
    lassign [det_dependencies van $lst_tabellen {} {} {}] lst_tabellen_van lst_queries_van lst_tab2query_van lst_query2tab_van  
    lassign [det_dependencies naar $lst_tabellen {} {} {}] lst_tabellen_naar lst_queries_naar lst_tab2query_naar lst_query2tab_naar
    return [list [::struct::set union $lst_tabellen_van $lst_tabellen_naar] \
                 [::struct::set union $lst_queries_van $lst_queries_naar] \
                 [::struct::set union $lst_tab2query_van $lst_tab2query_naar] \
                 [::struct::set union $lst_query2tab_van $lst_query2tab_naar]]
  } else {
    # recursief het resultaat uitbreiden, zolang er iets uit te breiden valt
    set sql_str_tabel_ids [det_sql_str_tabel_ids $lst_tabellen]
    set sql "select qt1.tabel_id, t1.naam, q.id, q.regelnr, b.id, b.path, qt2.tabel_id, t2.naam
             from query_tabel qt1, query_tabel qt2, tabel t1, tabel t2, query q, bestand b
             where qt1.query_id = qt2.query_id
             and t1.id = qt1.tabel_id
             and t2.id = qt2.tabel_id
             and qt1.query_id = q.id
             and q.bestand_id = b.id
             and qt1.soort <> '$richting'
             and qt2.soort = '$richting'
             and qt1.tabel_id in $sql_str_tabel_ids
             and qt2.tabel_id not in $sql_str_tabel_ids
             "
    $log debug "sql: $sql"
    set aangevuld 0
    foreach {t1_id t1_naam q_id q_regelnr b_id b_path t2_id t2_naam} [::mysql::sel [$db get_connection] $sql -flatlist] {
      set aangevuld 1
      lappend lst_tabellen [list $t2_id $t2_naam]
      lappend lst_queries [list $q_id $q_regelnr $b_id $b_path]
      if {$richting == "naar"} {
        lappend lst_tab2query [list $t1_id $q_id $b_id]
        lappend lst_query2tab [list $q_id $b_id $t2_id]
      } else {
        lappend lst_tab2query [list $t2_id $q_id $b_id]
        lappend lst_query2tab [list $q_id $b_id $t1_id]
      }
    }
    if {$aangevuld} {
      # verder zoeken.
      return [det_dependencies $richting $lst_tabellen $lst_queries $lst_tab2query $lst_query2tab]
    } else {
      # klaar.
      return [list $lst_tabellen $lst_queries $lst_tab2query $lst_query2tab]
    }
  }  
}

proc det_sql_str_tabel_ids {lst_tabellen} {
  return "([join [::struct::list mapfor el $lst_tabellen {lindex $el 0}] ,])" 
}

proc make_dot {dirname} {
  set f [open [file join $dirname alles.dot] w]
  write_dot_header $f
  puts_queries_bestand_only $f
  puts_tables $f
  puts_query_tables_bestand_only $f
  write_dot_footer $f
  close $f  
}

# bestanden en queries in een dot-record structuur
# de naam (voor refs) is b<b_id>:q<q_id>
proc puts_queries_bestand_only {f} {
  global log db
  puts $f "# queries"
  set conn [$db get_connection]
  set sql "select b.id, b.path from bestand b order by path"
  #   init [shape=record, label="{<f0> 0|<f1> 1|<f2> 2}"];
  foreach {b_id b_path} [::mysql::sel $conn $sql -flatlist] {
    puts $f "  b$b_id \[shape=rectangle,label=\"[file tail $b_path]\"\];"
  }
}

# bestanden en queries in een dot-record structuur
# de naam (voor refs) is b<b_id>:q<q_id>
proc puts_queries_details {f} {
  global log db
  puts $f "# queries"
  set conn [$db get_connection]
  set sql "select b.id, b.path from bestand b order by path"
  #   init [shape=record, label="{<f0> 0|<f1> 1|<f2> 2}"];
  foreach {b_id b_path} [::mysql::sel $conn $sql -flatlist] {
    set sql "select q.id, q.naam from query q where q.bestand_id = $b_id order by q.id"
    puts $f "  b$b_id \[shape=record, label=\"\{[file tail $b_path]|[join [struct::list mapfor el [::mysql::sel $conn $sql -list] {
      lassign $el q_id q_naam  
      id "<q$q_id>[qnaam2dot $q_naam]"
    }] "|"]\}\"\];"
  }
}

proc puts_tables {f} {
  global log db
  set conn [$db get_connection]
  set sql "select t.id, t.naam from tabel t order by naam"
  puts $f "# tabellen"
  foreach {t_id t_naam} [::mysql::sel $conn $sql -flatlist] {
    puts $f "  t$t_id \[shape=rectangle, label=\"$t_naam\"\];"
  }
}

proc puts_query_tables_bestand_only {f} {
  global log db
  set conn [$db get_connection]
  puts $f "# query naar tabellen"
  set sql "select distinct qt.tabel_id, q.bestand_id, qt.soort
           from query_tabel qt, query q
           where qt.query_id = q.id"
  foreach {t_id b_id soort} [::mysql::sel $conn $sql -flatlist] {
    # puts $f "  t$t_id \[shape=rectangle, label=\"$t_naam\"\];"
    if {$soort == "van"} {
      # van tabel naar query
      puts $f "t$t_id -> b$b_id;"
    } else {
      # naar: van query naar tabel
      puts $f "b$b_id -> t$t_id;"
    }
  }
}

proc puts_query_tables {f} {
  global log db
  set conn [$db get_connection]
  puts $f "# query naar tabellen"
  set sql "select qt.tabel_id, q.id, q.bestand_id, qt.soort
           from query_tabel qt, query q
           where qt.query_id = q.id"
  foreach {t_id q_id b_id soort} [::mysql::sel $conn $sql -flatlist] {
    # puts $f "  t$t_id \[shape=rectangle, label=\"$t_naam\"\];"
    if {$soort == "van"} {
      # van tabel naar query
      puts $f "t$t_id -> b$b_id:q$q_id;"
    } else {
      # naar: van query naar tabel
      puts $f "b$b_id:q$q_id -> t$t_id;"
    }
  }
}


proc write_dot_header {f} {
		puts $f "digraph G \{
		rankdir = LR
/*
		size=\"40,40\";
		ratio=fill;
		node \[fontname=Arial,fontsize=20\];
		edge \[fontname=Arial,fontsize=16\];
*/
    "
}

proc write_dot_footer {f} {
  puts $f "\}" 
}

proc make_graphs {dirname} {
  global DOT_DIR
  foreach dot_filename [glob -directory $dirname *.dot] {
    set png_filename [file join $dirname "[file rootname [file tail $dot_filename]].png"]
		# breakpoint
    exec [file join $DOT_DIR dot.exe] -Tpng $dot_filename -o $png_filename
  }
}

proc id {var} {
  return $var 
}

# vervang tekens die dot niet snapt
proc qnaam2dot {q_naam} {
  string map {| "" ; "" < "" > "" \{ "" \} "" \[ "" \] "" = "" \" "" } $q_naam
}

# main $argc $argv
