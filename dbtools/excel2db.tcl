#!/usr/bin/env tclsh86

package require tdbc::sqlite3
package require Tclx
package require ndv
package require csv

# TODO
# * nog iets meer met als je meerdere excel files hebt en/of meerdere tabs: hoe met tabelnamen omgaan?
# * datatype per veld op kunnen geven. Wordt nu wel aardig afgeleid en op int gezet als het kan, maar met userid wil je dit niet altijd.
# * conversie functie voor date/time velden, om ze in het goede formaat te zetten. In certs van Gilbert bv '10/16/2015 19:12:23'.
#   - door de 2015 weet je dat dit het jaar is. En door 16 weet je dat dit de dag is, 10 is dan dus de maand. Wellicht ook iets met filename/date
#     te doen, maar wordt dan wel complex en foutgevoelig. Beter om het expliciet op te kunnen geven.

# set log [::ndv::CLogger::new_logger [file tail [info script]] debug]
set log [::ndv::CLogger::new_logger [file tail [info script]] info]
$log set_file "excel2db.log"

proc main {argv} {
  global fill_blanks
  
  set options {
    {dir.arg "" "Directory with vuserlog files"}
    {db.arg "auto" "SQLite DB location (auto=create in dir)"}
    {table.arg "auto" "Tablename (prefix) to use"}
    {config.arg "" "Config.tcl file"}
    {deletedb "Delete DB before reading (for debugging)"}
    {fillblanks "Fill blank cells with contents of previous row"}
  }
  set usage ": [file tail [info script]] \[options] :"
  set dargv [getoptions argv $options $usage]

  
  set fill_blanks [:fillblanks $dargv] 
  set config_tcl [:config $dargv]
  # lassign $argv dirname config_tcl
  set dirname [:dir $dargv]
  if {$config_tcl != ""} {
    source $config_tcl 
  }
  handle_dir $dirname [:db $dargv] [:table $dargv] [:deletedb $dargv]
}

proc handle_dir {dirname db table deletedb} {
  global tcl_platform
  if {$tcl_platform(platform) == "windows"} {
    make_csvs $dirname
  } else {
    log warn "System != windows, cannot extract csv's from Excel" 
  }
  csv2sqlite $dirname $db $table $deletedb
}

proc make_csvs {dirname} {
  foreach filename [glob -directory $dirname "*.xls*"] {
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

proc csv2sqlite {dirname db table deletedb} {
  if {$db == "auto"} {
    set basename [file join $dirname [file tail $dirname]]
    set dbname "$basename.db"
  } else {
    set dbname $db
    set basename $table
  }
  
  # log info "csv2sqlite: $basename"
  if {$deletedb} {
    delete_database $dbname
  }
  # file delete "$basename.db"
  # set conn [open_db "$basename.db"]
  set conn [open_db $dbname]
  #@note begin_trans lijkt alleen voor perf zin te hebben, want als het halverwege fout gaan, wordt er geen rollback gedaan.
  # 2010-10-21 NdV nog omzetter naar nieuwe db lib met $db in_trans
  
  db_eval $conn "begin transaction"
  set idx 0
  foreach csvname [glob -directory $dirname "*.csv"] {
    incr idx
    try_eval {
      csv2sqlite_table $conn $basename $csvname $table $idx
    } {
      log warn "Failed to convert csv: $csvname" 
      log warn "Error: $errorResult"
    }
  }
  db_eval $conn "commit"
}

proc csv2sqlite_table {conn basename csvname table idx} {
  if {$table == "auto"} {
    set tablename [det_tablename $basename $csvname]
  } else {
    if {$idx == 1} {
      set tablename $table
    } else {
      set tablename "$table$idx"
    }
  }

  log info "csv2sqlite_table: basename=$basename, csvname=$csvname" 
  log info "tablename to create: $tablename"
  set f [open $csvname r]
  gets $f headerline
  set fields [det_fields $headerline]
  log debug "fields: $fields"
  if {[llength $fields] == 0} {
    log warn "No fields in table $tablename, return"
  } else {
    db_eval $conn "create table $tablename ([join $fields ", "])"
    set stmt_insert [prepare_insert $conn $tablename {*}$fields]
    set linenr 1
    set lines ""
    set dct_prev {}
    while {![eof $f]} {
      gets $f line
      incr linenr
      # string trim gebruiken, want kan 'lege' line zijn met alleen komma's.
      if {[string trim $line] != ""} {
        set lines "$lines$line"
        if {[csv::iscomplete $lines]} {
          set dct_prev [insert_line $conn $stmt_insert $tablename $fields $lines $linenr $dct_prev]
          set lines ""
        } else {
          set lines "$lines\n" 
        }
      }
    }
  }
  close $f
}

# @pre csvname starts with basename
proc det_tablename {basename csvname} {
  sanitise [file root [file tail $csvname]] 
}

proc det_fields {headerline} {
  set res {}
  set fieldindex 0
  foreach el [csv::split $headerline] {
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
proc insert_line {conn stmt_insert tablename fields line linenr dct_prev} {
  global fill_blanks
  log debug "line $linenr: $line"
  set dct {}
  foreach k $fields v [csv::split $line] {
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
    puts "dct: $dct_zipped"
    breakpoint 
  }
  return $dct
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


main $argv