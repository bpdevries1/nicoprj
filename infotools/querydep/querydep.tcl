package require ndv
package require Tclx
package require textutil 
package require struct::list

# 28-5-2010: bij verwerking regelnummers aan tekst toevoegen, zodat gebruikers de queries beter kunnen vinden.
#            vraag is ook hoe dit met bv XML in DTSX te doen?
# dcf.* en sys.* tabellen negeren. dcf zijn temp-tables, sys.* zijn systeem tabellen.
# nathist: old_values en new_values zonder dcf qualificatie: waarschijnlijk een update doen.
# delete from skippen.

::ndv::source_once QueryDepSchemaDef.tcl

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]

proc main {argc argv} {
  global log db

  $log debug "argv: $argv"
  set options {
      {d.arg "D:\\ITX\\Remote\\svn\\ind\\trunk\\src\\FEM" "Source root directory"}
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
  ::ndv::CLogger::set_logfile "querydep.log"
  $log info START
  
  init_db $ar_argv(db) $ar_argv(dbuser) $ar_argv(dbpassword)
  
  clean_db
  
  $log info "Reading source directory: $ar_argv(d)"
  handle_directory $ar_argv(d)
  
  log_unknown_extensions
  
  $log info FINISHED
  ::ndv::CLogger::close_logfile   
}

proc init_db {dbname user password} {
  global log db
  set schemadef [QueryDepSchemaDef::new]
  $schemadef set_db_name_user_password $dbname $user $password
  set db [::ndv::CDatabase::get_database $schemadef]   
  
}

proc log_unknown_extensions {} {
  global ar_unknown_ext log
  $log debug "Unknown extensions: [lsort [array names ar_unknown_ext]]"
}

proc handle_directory {dirname} {
  for_recursive_glob filename [list $dirname] "*" {
    if {[file isdirectory $filename]} {
      continue 
    }
    handle_file $filename 
  }
}

proc handle_file {filename} {
  global log ar_unknown_ext
  # $log debug "file: $filename"
  if {[is_query_file $filename]} {
    handle_query_file $filename 
  } elseif {[is_ignore_file $filename]} {
    # nothing 
  } else {
    $log warn "Don't know whether to handle: $filename"
    set ar_unknown_ext([file extension $filename]) 1
  }
}

proc is_query_file {filename} {
  return [has_extension $filename [list .acb .dtsx .sql]]
}


proc is_ignore_file {filename} {
	return [has_extension $filename [list .1 .bat .config .cs .csproj .cmd .css .dll .doc .exe \
    .ico .jar .ldf .msi .pl .resx .scc .settings .sln .tcl .txt .vb .vssscc .xml \
    .cache .cd .class .csv .database .dbml .dtproj .fmt .java .layout .log .myapp \
    .pdb .properties .rpt .user .vbproj .vspscc .xls .xsc .xsd .xss .xsx .zip]]
}

proc has_extension {filename lst_extensions} {
	set ext [string tolower [file extension $filename]]
	if {[lsearch -exact $lst_extensions $ext] > -1} {
		return 1
	} else {
		return 0
	} 
}

proc handle_query_file {filename} {
  global log
  $log debug "handle_query_file: $filename"
  handle_file_[det_file_type $filename] $filename
}

proc det_file_type {filename} {
 	set ext [string tolower [file extension $filename]]
  return [string range $ext 1 end]
}

proc handle_file_sql {filename} {
  global log
  $log debug "Handling SQL file: $filename"
  set text [string tolower [read_file $filename]]
  # splitsen op 'go' enkel op een regel en op ';' op einde van een regel. 
  # en verder zoeken naar meerdere voorkomens van insert, into, delete, update: dan verder splitsen.  
  set lst_sql_ln [struct::list map [split_sqltext [filter_comments [add_linenumbers $text]]] {string trim}]
  foreach sql_ln $lst_sql_ln volgnr [struct::list iota [llength $lst_sql_ln]] {
    handle_sql $filename $sql_ln [expr $volgnr + 1]
  }
  
}

# add a char(4) with a linenr add the end of each line, start with linenr 1
proc add_linenumbers {text} {
  set i 0
  return [join [struct::list mapfor line [split $text "\n"] {ndv::iden "$line\004[incr i]"}] "\n"]
}

proc remove_linenumbers {text_ln} {
  regsub -all {\004[0-9]+} $text_ln "" text_ln
  return $text_ln
}

proc get_start_linenumber {text_ln} {
  regexp {^[^\n]*\004([0-9]+)} $text_ln z linenr
  return $linenr
}

proc filter_comments {text_ln} {
  global log
  # set text [text_line_filter $text {x {![regexp -- {^--} [string trim $el]]}}]
  # set text [text_line_filter $text {x {![regexp -- {^\s*--} $el]}}]
  $log debug "text before filter: $text_ln"
  regsub -all {/\*.*?\*/} $text_ln "" text_ln ; # multiline comment met /* en */

  set text_ln [text_line_filter $text_ln [ndv::lambda_negate [ndv::regexp_lambda {^\s*--}]]] 
  set text_ln [text_line_filter $text_ln [ndv::lambda_negate [ndv::regexp_lambda {^\s*begin transaction}]]] 
  set text_ln [text_line_filter $text_ln [ndv::lambda_negate [ndv::regexp_lambda {^\s*commit transaction}]]] 

  # lege regels er ook uit, met alleen char(4) en regelnr.
  set text_ln [text_line_filter $text_ln [ndv::lambda_negate [ndv::regexp_lambda {^\s*\004}]]] 

  $log debug "text after filter: $text_ln"
  return $text_ln
}


# @param filter: lambda: [param expr]
proc text_line_filter {text filter} {
  return [join [struct::list filterfor [lindex $filter 0] [split $text "\n"] [lindex $filter 1]] "\n"]
}

# @todo Moet helaas toch rekening houden met linenr aan het einde van een regel. Kan dit anders?
# @return list with single SQL statements
# @param sql_ln is al lowercase, dus met zoeken op 'go' geen rekening mee houden.
proc split_sqltext {sql_ln} {
  # 12-7-2010 NdV voorheen met haakjes in de regexp: dan wordt tekst hierin ook opgenomen als result element, niet gewenst.
  set lst [struct::list flatten [struct::list mapfor el [textutil::splitx $sql_ln {\n\s*go\s*\004[0-9]+}] {
    textutil::splitx $el {;\s*\004[0-9]+\n}
  }]]
  # split_sql_keywords levert voor elk sql statement een list op, dus {{sql1 sql2} {sql3} {sql4 sql5}}
  # met flatten weer een simpele list.
  struct::list flatten [struct::list map $lst split_sql_keywords]
}

# @param sql_in: 1 string met 1 of meer sql statements
# @result lijst met sql statements.
# @note een enkel sql statement wordt dus ook in een list (met 1 element) gezet.
# @note delete en update markeren het begin van een statement; bij into moet hiervoor een select of insert worden gevonden.
proc split_sql_keywords {sql_ln} {
  global log
  set lst_kw [det_dml_keywords $sql_ln]
  if {[llength $lst_kw] <= 1} {
    return [list $sql_ln]
  } else {
    lassign $lst_kw kw1 kw2 ; # rest nu niet nodig
    # keywords aan begin van de string of omgeven met whitespaces: \s+, door quotes met \\\s+
    if {[string tolower $kw1] == "into"} {
      regexp "^(.*?\\\s+)${kw1}(\\\s+.*?\\\s+)${kw2}(\\\s+.*)$" $sql_ln z pre middle post
    } else {
      # bij update/delete zit kw1 aan begin van de string, dan een * ipv +
      regexp "^(.*?\\\s*)${kw1}(\\\s+.*?\\\s+)${kw2}(\\\s+.*)$" $sql_ln z pre middle post
    }
    regexp "^(.*?)${kw1}(.*?)${kw2}(.*)$" $sql_ln z pre middle post
    if {[string tolower $kw2] == "into"} {
      # nog stuk voor de into erbij zoeken in middle, vanaf select of insert
      # stuk voor de insert/select zo groot mogelijk, stuk tussen insert/select en de into zo klein mogelijk.
      regexp -nocase {^(.*)(((insert)|(select))(.*?)$)} $middle z pre2 rest2
      $log debug "kw2=into, nu verdeeld in 1) $pre$kw1$pre2 en 2) $rest2$kw2$post" 
      return [list "$pre$kw1$pre2" {*}[split_sql_keywords "$rest2$kw2$post"]]
    } else {
      $log debug "kw2!=into, nu verdeeld in 1) $pre$kw1$middle en 2) $kw2$post" 
      return [list "$pre$kw1$middle" {*}[split_sql_keywords "$kw2$post"]]
    }
  }
}

# @return list of the found keywords into, update and delete
proc det_dml_keywords {sql_ln} {
  set lst {}
  # into ipv insert
  foreach keyword {into update delete} {
    # lappend lst {*}[regexp -inline -all -nocase $keyword $sql_ln] 
    # alleen losse keywords, niet bv tm_delete
    lappend lst {*}[regexp -inline -all -nocase "(^|(\\\s+))$keyword\\\s+" $sql_ln] 
  }
  # lst bevat nu steeds 3 elementen voor een match: de hele regexp en 2 whitespaces
  set lst2 {}
  foreach {el z1 z2} $lst {
    lappend lst2 [string trim $el] 
  }
  return $lst2  
}

# @todo bij create table statement de link tussen bestand en tabel leggen.
proc handle_sql {filename sql_ln volgnr} {
  global log
  set soort [det_soort $filename]
  # set sql [filter_sql_comments $sql]
  # statement ignoren als er bv 'create nonclustered index' in staat.
  if {[is_ignore_sql $sql_ln]} {
    return 
  }

  $log debug "Handling sql statement in $filename: \n$sql_ln\n"
  # d.dt_from		as ingangsdatum niet als from clause beschouwen, dus space voor de from.
  set lst_from [find_regexp $sql_ln {\sfrom\s+([a-zA-Z0-9._\[\]]+)}]
  set lst_join [find_regexp $sql_ln {\sjoin\s+([a-zA-Z0-9._\[\]]+)}]
  
  # verwijder blokhaken, dan weer ontdubbelen.
  set lst_from [lsort -unique [::struct::list mapfor el [concat $lst_from $lst_join] {
    regsub -all {[\[\]]} $el ""
  }]]

  # filter sys.* en dcf.* tabellen.
  # set lst_from [::struct::list filter $lst_from {![regexp -nocase {(sys\.)|)dcf\.)}}]
  set lst_from [filter_sys_tables $lst_from]
  $log debug "Found from/join-tables: $lst_from"
  
  set lst_into [find_regexp $sql_ln {into\s+([a-zA-Z0-9._\[\]]+)}]
  # verwijder blokhaken, dan weer ontdubbelen.
  set lst_to [lsort -unique [::struct::list mapfor el $lst_into {
    regsub -all {[\[\]]} $el ""
  }]]
  
  # filter sys.* en dcf.* tabellen.
  # set lst_to [::struct::list filter $lst_to {![regexp -nocase {(sys\.)|)dcf\.)}}]
  set lst_to [filter_sys_tables $lst_to]
  
  $log debug "Found into tables: $lst_to"
  if {[llength $lst_to] > 1} {
    $log warn "More than 1 target table: $lst_to"
    # exit 2
    # 27-5-2010 geen exit hier: scheiding tussen statements wat onduidelijk, niet perse een ; of GO nodig.
  }
  # alleen toevoegen als er echt iets in staat
  if {([llength $lst_from] > 0) || ([llength $lst_to] > 0)} {
    insert_db $filename $soort $sql_ln $lst_from $lst_to $volgnr
  }
}

proc det_soort {filename} {
  if {[regexp -nocase {FEM} $filename]} {
    return FEM 
  } else {
    return Onbekend 
  }
}

proc filter_sys_tables {lst} {
  global log
  $log debug "lst: $lst"
  # ::struct::list filter $lst {![regexp -nocase {(sys\.)|(dcf\.)}]}
  # ::struct::list filterfor el $lst {![regexp -nocase {(sys\.)|(dcf\.)} $el]}
  # 30-6-2010 NdV toch wel temp tables in DCF, alleen niet 
  ::struct::list filterfor el $lst {![regexp -nocase {(sys\.)|(dcf\.converter_results)} $el]}
}

proc insert_db {filename soort sql_ln lst_from lst_to volgnr} {
  global log db
  set bestand_id [get_cache bestand $filename]
  if {$bestand_id == -1} {
    set bestand_id [$db insert_object bestand -path $filename] 
    put_cache bestand $filename $bestand_id
  }
  check_multiple_queries $bestand_id [get_start_linenumber $sql_ln] $sql_ln
  set query_id [$db insert_object query -naam [det_query_naam [remove_linenumbers $sql_ln]] -soort $soort \
    -sqltekst [string range [remove_linenumbers $sql_ln] 0 1022] -bestand_id $bestand_id -volgnr $volgnr \
    -regelnr [get_start_linenumber $sql_ln]]
  insert_db_query_tabellen $query_id $lst_from van
  insert_db_query_tabellen $query_id $lst_to naar
}

# @param sql: text zonder line numbers.
proc det_query_naam {sql} {
  # voorlopig de eerste niet-lege regel van de query
  set lst_sql [::struct::list filterfor line [split $sql "\n"] {
    [string trim $line] != {}
  }]
  return [lindex $lst_sql 0]
}

proc insert_db_query_tabellen {query_id lst_tabellen soort} {
  global db
  foreach tabel $lst_tabellen {
    set tabel_id [get_cache tabel $tabel]
    if {$tabel_id == -1} {
      set tabel_id [$db insert_object tabel -naam $tabel] 
      put_cache tabel $tabel $tabel_id
    }
    $db insert_object query_tabel -soort $soort -query_id $query_id -tabel_id $tabel_id
  }
  
}

proc get_cache {table_name record_name} {
  global ar_cache
  if {[array get ar_cache "$table_name:$record_name"] != {}} {
    return $ar_cache($table_name:$record_name) 
  } else {
    return -1 ; # @todo insert record here? 
  }
}

proc put_cache {table_name record_name id} {
  global ar_cache
  set ar_cache($table_name:$record_name) $id
}

# alle create statements uitfilteren?
proc is_ignore_sql {sql_ln} {
  if {[regexp {create nonclustered index} $sql_ln]} {
    return 1
  } 
  if {[regexp {create statistics} $sql_ln]} {
    return 1
  }
  if {[regexp {create table} $sql_ln]} {
    return 1
  }
  return 0
}

# return a list of all instances of regexp found in string
# return only the parts within the first parens
# @pre only one set of parens is allowed in the re.
proc find_regexp {string re} {
  set lst [regexp -inline -all -- $re $string]
  set lst_res {}
  foreach {z el} $lst {
    lappend lst_res $el 
  }
  return [lsort -unique $lst_res]
}

proc handle_file_unknown {filename} {
  global log
  $log warn "Unknown file type: $filename" 
}

proc handle_file_dtsx {filename} {
  global log
  $log debug "TODO: dtsx (xml): $filename" 
}

# @todo in ACB ook een target table genoemd.
proc handle_file_acb {filename} {
  global log
  $log debug "TODO: acb (xml): $filename" 
}

proc clean_db {} {
  global log db
  $log info "Cleaning database contents"
  foreach table {bestand query tabel query_tabel} {
    ::mysql::exec [$db get_connection] "delete from $table" 
  }
}

# check if multiple INSERT, UPDATE or DELETE keywords exist in sql_ln
proc check_multiple_queries {bestand_id regelnr sql_ln} {
  global log
  set lst [det_dml_keywords $sql_ln]
  if {[llength $lst] > 1} {
     $log warn "More than one ([join $lst]) insert/update/delete found in query: $bestand_id, $regelnr, $sql_ln"
  }
}

main $argc $argv