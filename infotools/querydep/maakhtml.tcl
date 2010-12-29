package require ndv
package require Tclx
package require textutil 

::ndv::source_once QueryDepSchemaDef.tcl
::ndv::source_once maakpng.tcl

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
  
  make_html
  
  $log info FINISHED
  ::ndv::CLogger::close_logfile   
}

proc make_html {} {
  global log db ar_argv hhg
  set hhg [ndv::CHtmlHelper::new]
  set root_dir $ar_argv(o)
  foreach tablename {bestand query tabel} {
    $log debug "making dir: [file join $root_dir $tablename]"
    file mkdir [file join $root_dir $tablename]
    make_html_$tablename
  }
}

proc make_html_bestand {} {
  global log db ar_argv
  set root_dir $ar_argv(o)
  regexp {make_html_(.+)$} [current_proc] z table
  set hh [ndv::CHtmlHelper::new]
  set f [open [file join $root_dir "$table.html"] w]
  $hh set_channel $f
  $hh write_header "$table"
  set sql "select * from $table order by path"  
  foreach record [::mysql::sel [$db get_connection] $sql -list] {
    lassign $record id path
    # breakpoint
    $hh line [$hh get_anchor $path "$table/$table-$id.html"]
    make_html_bestand_detail $root_dir $table $id $path
  }
  
  $hh write_footer
  
  close $f
}

proc make_html_bestand_detail {root_dir table id path} {
  global log db ar_argv
  set f [open [file join $root_dir $table "$table-$id.html"] w]
  set hh [ndv::CHtmlHelper::new]
  $hh set_channel $f
  $hh write_header "$table - $path"
  $hh line [$hh get_anchor $path "file://[file nativename $path]"]
  $hh table_start 
  $hh table_header "volgnr" "regelnr" "query" "soort" "tabellen"
  set conn [$db get_connection]
  foreach {q_id naam q_soort sqltekst volgnr regelnr} [::mysql::sel $conn "select id, naam, soort, sqltekst, volgnr, regelnr from query where bestand_id = $id" -flatlist] {
    $hh table_row $volgnr $regelnr $naam $q_soort [join [::struct::list map [::mysql::sel $conn "select t.id, qt.soort, t.naam from query_tabel qt, tabel t \
       where qt.tabel_id = t.id and qt.query_id = $q_id" -list] make_tabel_href] "<br/>"]  
  }
  $hh table_end
  $hh line [$hh get_anchor "Alle bestanden" "../bestand.html"]
  $hh write_footer
  close $f
}

proc make_tabel_href {el_tabel} {
  global hhg ar_argv log
  lassign $el_tabel id soort naam
  return [$hhg get_anchor "$soort: $naam" [file join .. tabel "tabel-$id.html"]]
}

proc make_html_query {} {
  global log db ar_argv
  
}

proc make_html_tabel {} {
  global log db ar_argv
  set root_dir $ar_argv(o)
  regexp {make_html_(.+)$} [current_proc] z table
  set hh [ndv::CHtmlHelper::new]
  set f [open [file join $root_dir "$table.html"] w]
  $hh set_channel $f
  $hh write_header "$table"
  set sql "select * from $table order by naam"  
  foreach record [::mysql::sel [$db get_connection] $sql -list] {
    lassign $record id naam bestand_id
    # breakpoint
    $hh line [$hh get_anchor $naam "$table/$table-$id.html"]
    # 30-6-2010 eerst graph maken, dan html. Bij html de map-info lezen en in html stoppen.
    make_html_tabel_graph $root_dir $table $id $naam
    make_html_tabel_detail $root_dir $table $id $naam
  }
  
  $hh write_footer
  
  close $f
}
  
proc make_html_tabel_detail {root_dir table id naam} {
  global log db ar_argv hhg
  set f [open [file join $root_dir $table "$table-$id.html"] w]
  set hh [ndv::CHtmlHelper::new]
  $hh set_channel $f
  $hh write_header "$table - $naam"
  $hh table_start 
  $hh table_header "bestand" "query"
  set conn [$db get_connection]
  foreach {q_id q_naam b_id b_path qt_soort} [::mysql::sel $conn "select q.id, q.naam, b.id, b.path,qt.soort \
      from query q, bestand b, query_tabel qt where q.bestand_id = b.id and q.id = qt.query_id \
      and qt.tabel_id = $id order by b.path, q.id" -flatlist] {
    $hh table_row [$hhg get_anchor $b_path [file join .. bestand "bestand-$b_id.html"]] "$qt_soort: $q_naam" 
  }
  $hh table_end
  $hh line [$hh get_anchor "Alle tabellen" "../tabel.html"]
  $hh line [$hh get_img "$table-$id.png" "USEMAP=\"#map\""]
  puts $f "<MAP NAME=\"map\">"
  set map_filename [file join $root_dir $table "$table-$id.map"] 
  if {[file exists $map_filename]} {
    set fi [open $map_filename r]
    set text [read $fi]
    close $fi
    puts $f $text
  } else {
    $log warn "Mapfile not found: $map_filename"
  } 
  puts $f "</MAP>"
  
  $hh write_footer
  close $f
}


proc current_proc {} {
  puts "[info level]"
  return [info level [expr [info level] -1]]
}

main $argc $argv