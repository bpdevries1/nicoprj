# maak overzicht vanuit urenlog met als doel input voor CV.

package require ndv
package require Tclx
# package require csv
package require sqlite3

set log [ndv::CLogger::new_logger [file tail [info script]] debug]

# Goal: output html (table) with info of last n runs of all scripts on all sentinels.
proc main {argv} {
  lassign $argv xls_filename
  set basename [file rootname $xls_filename]
  excel2tsv $xls_filename $basename
  tsv2sqlite $basename
}

# @return filename of tsv file with uren-tab data. 
proc excel2tsv {xls_filename basename} {
  set infile [file nativename [file normalize $xls_filename]]
  set outbase [file nativename [file normalize $basename]]
  set scriptname [file nativename [file normalize xls2tsv.vbs]]
  foreach filename [glob -nocomplain -directory [file dirname $basename] "[file tail $basename]_*.tsv"] {
    log info "Delete: $filename"
    file delete $filename
  }
  exec cscript.exe $scriptname $infile $outbase
}

proc tsv2sqlite {basename} {
  log info "tsv2sqlite: $basename"
  create_db "$basename.db"
  db eval "begin transaction"
  # read_uren $uren_filename
  foreach tsvname [glob -directory [file dirname $basename] "[file tail $basename]*.tsv"] {
    try_eval {
      tsv2sqlite_table $basename $tsvname
    } {
      log warn "Failed to convert tsv: $tsvname" 
      log warn "Error: $errorResult"
    }
  }
  db eval "commit"
}

proc create_db {db_name} {
  file delete $db_name
  sqlite3 db $db_name
  # db eval "create table urendag (date, project, hours, comments)"
}

proc tsv2sqlite_table {basename tsvname} {
  log info "tsv2sqlite_table: basename=$basename, tsvname=$tsvname" 
  set tablename [det_tablename $basename $tsvname]
  log info "tablename to create: $tablename"
  set f [open $tsvname r]
  gets $f headerline
  set fields [det_fields $headerline]
  log debug "fields: $fields"
  if {[llength $fields] == 0} {
    log warn "No fields in table $tablename, return"
  } else {
    db eval "create table $tablename ([join $fields ", "])"
    while {![eof $f]} {
      gets $f line
      # string trim gebruiken, want kan 'lege' line zijn met alleen tabs.
      if {[string trim $line] != ""} {
        insert_line $tablename $fields $line 
      }
    }
  }
  close $f
}

# @pre tsvname starts with basename
proc det_tablename {basename tsvname} {
  # +1 omdat na basename eerst een _ komt, en dan de rest.
  # @todo? rare tekens uit tablename halen, als nodig.
  sanitise [file root [string range $tsvname [string length $basename]+1 end]] 
}

proc det_fields {headerline} {
  # @todo? clean fieldsnames.
  set res {}
  set fieldindex 0
  foreach el [split $headerline "\t"] {
    incr fieldindex
    #regsub -all {[^a-zA-Z0-9_]} $el "_" el2
    #lappend res $el2
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

proc insert_line {tablename fields line} {
  set vals {}
  foreach val [split $line "\t"] {
    if {$val == ""} {
      lappend vals "''" 
    } elseif {[string is double $val]} {
      lappend vals $val 
    } else {
      lappend vals "'$val'" 
    }
  }
  set query "insert into $tablename ([join $fields ", "]) values ([join $vals ", "])"
  log debug "query: $query"
  log debug "line : $line"
  db eval $query
  
  # db eval {insert into urendag values ($sqldate, $project, $hours, $comments)}
}

proc det_sqldate {date} {
  try_eval {
    set sec [clock scan $date -format "%a %d/%m/%Y"]
  } {
    log error "could not parse date: $date"
    breakpoint
  }
  clock format $sec -format "%Y-%m-%d"
}

main $argv

