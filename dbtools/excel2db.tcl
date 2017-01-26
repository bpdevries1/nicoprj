#!/usr/bin/env tclsh

# [2016-03-29 16:37:40] Dit is waarsch nieuwe versie, oude in perftoolset/tools/excel2db.

package require tdbc::sqlite3
package require Tclx
package require ndv
package require csv

# TODO:
# [2016-07-09 14:16] Using sqlite directly instead of tdbc could be faster, using dbcmd eval with $var as named parameter. dbCmd copy also promising, directly import a file, take care of header lines though. dbcmd progress for callbacks on long running commands.

# procs in een namespace zetten, omdat je deze file ook als lib kunt sourcen. Clojure ideeen hierbij te gebruiken?
# * nog iets meer met als je meerdere excel files hebt en/of meerdere tabs: hoe met tabelnamen omgaan?
# * datatype per veld op kunnen geven. Wordt nu wel aardig afgeleid en op int gezet als het kan, maar met userid wil je dit niet altijd.
# * conversie functie voor date/time velden, om ze in het goede formaat te zetten. In certs van Gilbert bv '10/16/2015 19:12:23'.
#   - door de 2015 weet je dat dit het jaar is. En door 16 weet je dat dit de dag is, 10 is dan dus de maand. Wellicht ook iets met filename/date
#     te doen, maar wordt dan wel complex en foutgevoelig. Beter om het expliciet op te kunnen geven.
# * Vraag of je deze in lib-dir neer wilt zetten. Voor beide wat te zeggen.


# set log [::ndv::CLogger::new_logger [file tail [info script]] debug]
#set log [::ndv::CLogger::new_logger [file tail [info script]] info]
#$log set_file "excel2db.log"

# set_log_global info

namespace eval ::excel2db {

  namespace export excel2db_main handle_dir files2sqlite file2sqlite_table
  
proc excel2db_main {argv} {
  global fill_blanks
  
  set options {
    {dir.arg "" "Directory with log files"}
    {filespecs.arg "*.csv:*.tsv" "File specs of files to import"}
    {db.arg "auto" "Relative SQLite DB location (auto=create in dir)"}
    {table.arg "auto" "Tablename (prefix) to use"}
    {config.arg "" "Config.tcl file"}
    {deletedb "Delete DB before reading (for debugging)"}
    {fillblanks "Fill blank cells with contents of previous row"}
    {singlelines "Each CSV record is on a single line (faster processing)"}
    {commitlines.arg "100000" "Perform commit after reading n lines"}
    {loglevel.arg "info" "Loglevel to use (info, debug, ...)"}
  }
  set usage ": [file tail [info script]] \[options] \[dirname\]:"
  set opt [getoptions argv $options $usage]
	# log_set_level $opt
  # $log set_log_level debug
  set_log_global [:loglevel $opt]
  
  set fill_blanks [:fillblanks $opt] 
  set config_tcl [:config $opt]
  # lassign $argv dirname config_tcl
  if {[:dir $opt] == ""} {
    # final argument after options
	set dirname [:0 $argv]
  } else {
    set dirname [:dir $opt]
  }
  log info "Handle dir: $dirname"
  if {$config_tcl != ""} {
    source $config_tcl 
  }
  handle_dir $dirname [:db $opt] [:table $opt] [:deletedb $opt] $opt
}

proc handle_dir {dirname db table deletedb opt} {
  global tcl_platform
  if {$tcl_platform(platform) == "windows"} {
    make_csvs $dirname
  } else {
    log warn "System != windows, cannot extract csv's from Excel" 
  }
  files2sqlite $dirname $db $table $deletedb $opt
}

proc make_csvs {dirname} {
  foreach filename [glob -nocomplain -directory $dirname "*.xls*"] {
    excel2csv $filename 
  }
}

proc excel2csv {filename} {
  log info "excel2csv: $filename"
  set nativename [file nativename [file normalize $filename]]
  set targetroot [file nativename [file normalize [file rootname $filename]]]
  log debug "nativename: $nativename"
  log debug "targetroot: $targetroot"
  delete_old_csv $targetroot
  exec cscript xls2csv.vbs $nativename $targetroot
}

proc delete_old_csv {targetroot} {
  foreach filename [glob -nocomplain -directory [file dirname $targetroot] "[file tail $targetroot]*.csv"] {
    file delete $filename 
  }
}

# TODO: dbwrapepr gebruiken.
proc files2sqlite {dirname pdbname table deletedb opt} {
  if {$pdbname == "auto"} {
    set basename [file join $dirname [file tail $dirname]]
    set dbname "$basename.db"
  } else {
    # [2017-01-26 12:39:12] dname relative to dirname. If absolute name, should still work.
    set basename $table
    set dbname [file join $dirname $pdbname]
  }
  
  # log info "files2sqlite: $basename"
  if {$deletedb} {
    delete_database $dbname
  }
  # file delete "$basename.db"
  # set conn [open_db "$basename.db"]
  set db [dbwrapper new $dbname]
  $db add_tabledef _csvdbmap {id} {tablename fieldname csvfilename csvfield csvfieldnr}
  $db create_tables
  $db prepare_insert_statements
  set conn [$db get_conn]
  # set conn [open_db $dbname]
  #@note begin_trans lijkt alleen voor perf zin te hebben, want als het halverwege fout gaan, wordt er geen rollback gedaan.
  # 2010-10-21 NdV nog omzetter naar nieuwe db lib met $db in_trans
  

  set idx 0
  set filespecs [split [:filespecs $opt] ":"]
  foreach filespec $filespecs {
    foreach filename [glob -nocomplain -directory $dirname $filespec] {
      # [2016-07-06 17:00:29] sowieso per file een transaction.
      db_eval $conn "begin transaction"      
      incr idx
      try_eval {
        file2sqlite_table $db $basename $filename $table $idx $opt
      } {
        log warn "Failed to convert: $filename" 
        log warn "Error: $errorResult"
      }
      db_eval $conn "commit"    
    }
  }
  
}

proc file2sqlite_table {db basename filename table idx opt} {
  set conn [$db get_conn]
  if {$table == "auto"} {
    set tablename [det_tablename $basename $filename]
  } else {
    if {$idx == 1} {
      set tablename $table
    } else {
      set tablename "$table$idx"
    }
  }
  if {[$db table_exists $tablename]} {
    log info "Table already exists, return: $tablename"
    return
  }
  set commit_lines [:commitlines $opt]
  log info "file2sqlite_table: basename=$basename, filename=$filename" 
  log info "tablename to create: $tablename"
  set sep_char [det_sep_char $filename]
  set f [open $filename r]
  gets $f headerline
  set fields [det_fields $db $filename $tablename $headerline $sep_char]
  log debug "fields: $fields"
  if {[llength $fields] == 0} {
    log warn "No fields in table $tablename, return"
  } else {
    set create_sql "create table $tablename ([join $fields ", "])"
    log_fields $fields
    log debug "Creating table $tablename - $create_sql"    
    db_eval $conn $create_sql
    log debug "Created table: $tablename"
    set stmt_insert [prepare_insert $conn $tablename {*}$fields]
    log info "stmt_insert: $stmt_insert"
    if {[:singlelines $opt]} {
      read_single_lines $f $conn $stmt_insert $tablename $fields $sep_char $opt
    } else {
      # TODO: factor out in read_multi_lines
      set lines ""
      set dct_prev {}
      set linenr 1
      while {![eof $f]} {
        gets $f line
        incr linenr
        # string trim gebruiken, want kan 'lege' line zijn met alleen komma's.
        if {[string trim $line] != ""} {
          set lines "$lines$line"
          # [2016-07-01 10:38] note - iscomplete should work both for csv and tsv, just count number of double quotes.
          if {[csv::iscomplete $lines]} {
            set dct_prev [insert_line $conn $stmt_insert $tablename $fields $lines $linenr $dct_prev $sep_char]
            set lines ""
          } else {
            set lines "$lines\n" 
          }
        }
        if {$linenr % $commit_lines == 0} {
          log info "Committing after $linenr lines"
          close_resultsets $stmt_insert
          db_eval $conn "commit"
          db_eval $conn "begin transaction"      
        }
      }
    }
  }
  close $f
}

proc log_fields {fields} {
  log debug "All fields in table: "
  set prev ""
  foreach el [lsort $fields] {
    log debug $el
    if {$el == $prev} {
      log debug "--> Same as previous!"
    }
    set prev $el
  }
}

proc close_resultsets {stmt} {
  # The resultsets method returns a list of all the result sets that have been returned by executing the statement and have not yet been closed.
  set warnings 0
  foreach rs [$stmt resultsets] {
    $rs close
    incr warnings
  }
  if {$warnings > 0} {
    log warn "$warnings Resultsets had to be closed in a sweep run, should be done directly after finishing with it."
  }
}

proc read_single_lines {f conn stmt_insert tablename fields sep_char opt} {
  log info "reading single lines for $tablename"
  set linenr 1;                 # already read header line.
  set commit_lines [:commitlines $opt]
  while {![eof $f]} {
    gets $f line
    incr linenr
    # string trim gebruiken, want kan 'lege' line zijn met alleen komma's.
    if {[string trim $line] != ""} {
      #insert_line $conn $stmt_insert $tablename $fields $line $linenr {} $sep_char
      insert_single_line $conn $stmt_insert $tablename $fields $line $linenr $sep_char
      
      #return;                   # for test.
    }
    # breakpoint
    if {$linenr % $commit_lines == 0} {
      log info "Committing after $linenr lines"
      close_resultsets $stmt_insert
      db_eval $conn "commit"
      db_eval $conn "begin transaction"      
    }
  }
  log info "Finished reading single lines for $tablename"
}

proc det_sep_char {filename} {
  set ext [file extension $filename]
  if {$ext == ".csv"} {
    return ","
  } elseif {$ext == ".tsv"} {
    return "\t"
  } else {
    return "<none>"
  }
}

# @pre filename starts with basename
proc det_tablename {basename filename} {
  sanitise [file root [file tail $filename]] 
}

proc det_fields {db filename tablename headerline sep_char} {
  set res {}
  set fieldindex 0
  set filename_tail [file tail $filename]
  foreach el [csv::split $headerline $sep_char] {
    incr fieldindex
    if {$el == ""} {
      # lappend res "field$fieldindex"
      set dbfieldname_unique "field$fieldindex"
    } else {
      set dbfieldname [sanitise $el]
      set dbfieldname_unique [make_unique $dbfieldname $res]
    
    }
    lappend res $dbfieldname_unique
    #   $db define_table _csvdbmap {id} {tablename fieldname csvfilename csvfield csvfieldnr}
    $db insert _csvdbmap [dict create tablename $tablename fieldname $dbfieldname_unique csvfilename $filename_tail csvfield $el csvfieldnr $fieldindex]
  }
  return $res
}

# sanitise string so it can be used as table or column name.
proc sanitise {str} {
  regsub -all {[^a-zA-Z0-9_]} $str "_" str2
  return $str2
}

# if fieldname does not occur in lst, just return it.
# if it does occur, add an index so it becomes unique.
proc make_unique {fieldname lst} {
  if {[list_contains? $lst $fieldname]} {
    set ndx 2
    while {1} {
      set fieldname2 "${fieldname}$ndx"
      if {![list_contains? $lst $fieldname2]} {
        return $fieldname2
      }
      incr ndx
    }
  } else {
    return $fieldname
  }
}

proc list_contains? {lst el} {
  if {[lsearch -exact $lst $el] >= 0} {
    return 1
  } else {
    return 0
  }
}

# @param line can be 'multiline'
proc insert_line {conn stmt_insert tablename fields line linenr dct_prev sep_char} {
  global fill_blanks
  log debug "line $linenr: $line"
  log debug "fill_blanks: $fill_blanks"
  # TODO: should use dict interface, with dict create and dict set.
  # set dct {}
  set dct [dict create]
  foreach k $fields v [csv::split $line $sep_char] {
    if {$v == ""} {
      if {$fill_blanks} {
        if {[dict exists $dct_prev $k]} {
          #lappend dct $k [dict get $dct_prev $k]
          dict set dct $k [dict get $dct_prev $k]
        } else {
          #lappend dct $k $v
          dict set dct $k $v
        }
      } else {
        #lappend dct $k $v
        dict set dct $k $v
      }
    } else {
      #lappend dct $k $v
      dict set dct $k $v
    }
  }
  try_eval {
    #set dct [lrange $dct 0 9]
    #log debug "insert_line: $dct"
    [$stmt_insert execute $dct] close
  } {
    puts "dct: $dct"
    breakpoint 
  }
  return $dct
}

proc insert_single_line {conn stmt_insert tablename fields line linenr sep_char} {
  # TODO: find other way to create dict with list of keys and list of values (zipper?)
  # or another way to put in DB, using something else besides a dict.
  #set dct {}
  set dct [dict create]
  foreach k $fields v [csv::split $line $sep_char] {
    # dict set dct $k $v
    # [2017-01-26 10:54:05] Strange construction here, but apparantly necessary:
    # by checking the value of $v, something happens inside it, maybe the type is being
    # set, which is next used by the prepared statement to set int/float when possible.
    # So leave like this for now.
    if {$v == ""} {
      dict set dct $k $v
      #lappend dct $k $v      
    } else {
      dict set dct $k $v
      #lappend dct $k $v
    }

  }
  try_eval {
    # [2016-07-09 13:44] should catch result and close/free it.
    #set dct [lrange $dct 0 9]
    #log debug "insert_single_line: $dct"
    [$stmt_insert execute $dct] close
    # nog even test zonder, kijken of vangnet 'em pakt
    # $stmt_insert execute $dct
  } {
    puts "dct: $dct"
    breakpoint 
  }
}

proc delete_database {dbname} {
  set ok 0
  catch {
    file delete $dbname
    set ok 1
  }
  if {!$ok} {
    # TODO: huidige tabellen bepalen en deleten?
    if 0 {
      set db [dbwrapper new $dbname]
      foreach table {error trans retraccts logfile} {
        # $db exec "delete from $table"
        $db exec "drop table $table"
      }
      $db close    
    }
    error "Could not delete database: $dbname"
  }
}

};                              # namespace eval

if {[this_is_main]} {
  # excel2db_main $argv
  excel2db::excel2db_main $argv  
}

