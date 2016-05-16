#!/usr/bin/env tclsh86

# [2016-03-29 16:37:18] Dit is waarschijnlijk oude versie, nieuwe in nicoprj/dbtools.

package require tdbc::sqlite3
package require Tclx
package require ndv
package require csv

# set log [::ndv::CLogger::new_logger [file tail [info script]] debug]
set log [::ndv::CLogger::new_logger [file tail [info script]] info]
$log set_file "excel2db.log"

proc main {argv} {
  global fill_blanks argv0
  set fill_blanks 0 ; # default: don't fill up blank cells from cells above.
  set config_tcl ""
  lassign $argv dirname config_tcl
  if {$config_tcl != ""} {
    source $config_tcl 
  }
  if {$dirname == "-h"} {
    puts "syntax: $argv0 <dirname> \[config_tcl\]"
    exit 1
  }
  handle_dir $dirname
}

proc handle_dir {dirname} {
  global tcl_platform
  if {$tcl_platform(platform) == "windows"} {
    make_csvs $dirname
  } else {
    log warn "System != windows, cannot extract csv's from Excel" 
  }
  csv2sqlite $dirname
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

proc csv2sqlite {dirname} {
  set dirname [file normalize $dirname]
  set basename [file join $dirname [file tail $dirname]]
  log info "csv2sqlite: $basename"
  file delete "$basename.db"
  set conn [open_db "$basename.db"]
  #@note begin_trans lijkt alleen voor perf zin te hebben, want als het halverwege fout gaan, wordt er geen rollback gedaan.
  db_eval $conn "begin transaction"
  foreach csvname [glob -directory [file dirname $basename] "*.csv"] {
    try_eval {
      csv2sqlite_table $conn $basename $csvname
    } {
      log warn "Failed to convert csv: $csvname" 
      log warn "Error: $errorResult"
    }
  }
  db_eval $conn "commit"
}

proc csv2sqlite_table {conn basename csvname} {
  log info "csv2sqlite_table: basename=$basename, csvname=$csvname" 
  set tablename [det_tablename $basename $csvname]
  log info "tablename to create: $tablename"
  set f [open $csvname r]
  gets $f headerline
  set fields [det_fields $headerline]
  log debug "fields: $fields"
  if {[llength $fields] == 0} {
    log warn "No fields in table $tablename, return"
  } else {
    # db_eval $conn "create table $tablename ([join $fields ", "])"
	db_eval $conn "create table $tablename (_id integer primary key autoincrement, [join $fields ", "])"
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

main $argv