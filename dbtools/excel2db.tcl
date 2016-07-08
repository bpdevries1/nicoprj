#!/usr/bin/env tclsh861

# [2016-03-29 16:37:40] Dit is waarsch nieuwe versie, oude in perftoolset/tools/excel2db.

package require tdbc::sqlite3
package require Tclx
package require ndv
package require csv

# TODO:
# Bug: [2016-07-06 17:07:26 +0200] [excel2db.tcl] [info] Committing after 900000 lines
# unable to realloc 3690464 bytes
# check if 'objects' can be deleted or not created in the first place. Maybe something with dicts or fillblanks.

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

set_log_global info

proc excel2db_main {argv} {
  global fill_blanks
  
  set options {
    {dir.arg "" "Directory with vuserlog files"}
    {db.arg "auto" "SQLite DB location (auto=create in dir)"}
    {table.arg "auto" "Tablename (prefix) to use"}
    {config.arg "" "Config.tcl file"}
    {deletedb "Delete DB before reading (for debugging)"}
    {fillblanks "Fill blank cells with contents of previous row"}
    {singlelines "Each CSV record is on a single line (faster processing)"}
    {commitlines.arg "100000" "Perform commit after reading n lines"}
  }
  set usage ": [file tail [info script]] \[options] \[dirname\]:"
  set dargv [getoptions argv $options $usage]
	
  set fill_blanks [:fillblanks $dargv] 
  set config_tcl [:config $dargv]
  # lassign $argv dirname config_tcl
  if {[:dir $dargv] == ""} {
    # final argument after options
	set dirname [:0 $argv]
  } else {
    set dirname [:dir $dargv]
  }
  log info "Handle dir: $dirname"
  if {$config_tcl != ""} {
    source $config_tcl 
  }
  handle_dir $dirname [:db $dargv] [:table $dargv] [:deletedb $dargv] [:commitlines $dargv] $dargv
}

proc handle_dir {dirname db table deletedb commit_lines dargv} {
  global tcl_platform
  if {$tcl_platform(platform) == "windows"} {
    make_csvs $dirname
  } else {
    log warn "System != windows, cannot extract csv's from Excel" 
  }
  file2sqlite $dirname $db $table $deletedb $commit_lines $dargv
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

proc file2sqlite {dirname db table deletedb commit_lines dargv} {
  if {$db == "auto"} {
    set basename [file join $dirname [file tail $dirname]]
    set dbname "$basename.db"
  } else {
    set dbname $db
    set basename $table
  }
  
  # log info "file2sqlite: $basename"
  if {$deletedb} {
    delete_database $dbname
  }
  # file delete "$basename.db"
  # set conn [open_db "$basename.db"]
  set conn [open_db $dbname]
  #@note begin_trans lijkt alleen voor perf zin te hebben, want als het halverwege fout gaan, wordt er geen rollback gedaan.
  # 2010-10-21 NdV nog omzetter naar nieuwe db lib met $db in_trans
  

  set idx 0
  foreach filespec {*.csv *.tsv} {
    foreach filename [glob -nocomplain -directory $dirname $filespec] {
      # [2016-07-06 17:00:29] sowieso per file een transaction.
      db_eval $conn "begin transaction"      
      incr idx
      try_eval {
        file2sqlite_table $conn $basename $filename $table $idx $commit_lines $dargv
      } {
        log warn "Failed to convert csv: $filename" 
        log warn "Error: $errorResult"
      }
      db_eval $conn "commit"    
    }
  }
  
}

proc file2sqlite_table {conn basename filename table idx commit_lines dargv} {
  if {$table == "auto"} {
    set tablename [det_tablename $basename $filename]
  } else {
    if {$idx == 1} {
      set tablename $table
    } else {
      set tablename "$table$idx"
    }
  }

  log info "file2sqlite_table: basename=$basename, filename=$filename" 
  log info "tablename to create: $tablename"
  set sep_char [det_sep_char $filename]
  set f [open $filename r]
  gets $f headerline
  set fields [det_fields $headerline $sep_char]
  log debug "fields: $fields"
  if {[llength $fields] == 0} {
    log warn "No fields in table $tablename, return"
  } else {
    db_eval $conn "create table $tablename ([join $fields ", "])"
    set stmt_insert [prepare_insert $conn $tablename {*}$fields]

    if {[:singlelines $dargv]} {
      read_single_lines $f $conn $stmt_insert $tablename $fields $sep_char $dargv
    } else {
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
          db_eval $conn "commit"
          db_eval $conn "begin transaction"      
        }
      }
      
    }
  }
  close $f
}

proc read_single_lines {f conn stmt_insert tablename fields sep_char dargv} {
  log info "reading single lines for $tablename"
  set linenr 1;                 # already read header line.
  set commit_lines [:commitlines $dargv]
  while {![eof $f]} {
    gets $f line
    incr linenr
    # string trim gebruiken, want kan 'lege' line zijn met alleen komma's.
    if {[string trim $line] != ""} {
      insert_single_line $conn $stmt_insert $tablename $fields $line $linenr $sep_char
    } else {
      set lines "$lines\n" 
    }
    # breakpoint
    if {$linenr % $commit_lines == 0} {
      log info "Committing after $linenr lines"
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

proc det_fields {headerline sep_char} {
  set res {}
  set fieldindex 0
  foreach el [csv::split $headerline $sep_char] {
    incr fieldindex
    if {$el == ""} {
      lappend res "field$fieldindex"
    } else {
      lappend res [sanitise $el]
    }
  }
  return $res
}

# sanitise string so it can be used as table or column name.
proc sanitise {str} {
  regsub -all {[^a-zA-Z0-9_]} $str "_" str2
  return $str2
}

# @param line can be 'multiline'
proc insert_line {conn stmt_insert tablename fields line linenr dct_prev sep_char} {
  global fill_blanks
  log debug "line $linenr: $line"
  # TODO: should use dict interface, with dict create and dict set.
  set dct {}
  foreach k $fields v [csv::split $line $sep_char] {
    if {$v == ""} {
      if {$fill_blanks} {
        if {[dict exists $dct_prev $k]} {
          lappend dct $k [dict get $dct_prev $k]
        } else {
          lappend dct $k $v
        }
      } else {
        lappend dct $k $v
      }
    } else {
      lappend dct $k $v
    }
  }
  try_eval {
    $stmt_insert execute $dct
  } {
    puts "dct: $dct"
    breakpoint 
  }
  return $dct
}

proc insert_single_line {conn stmt_insert tablename fields line linenr sep_char} {
  # TODO: find other way to create dict with list of keys and list of values
  # or another way to put in DB, using something else besides a dict.
  set dct [dict create]
  foreach k $fields v [csv::split $line $sep_char] {
    dict set dct $k $v
  }
  try_eval {
    $stmt_insert execute $dct
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

if {[this_is_main]} {
  excel2db_main $argv  
}

