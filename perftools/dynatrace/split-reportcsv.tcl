# convert generated report csv by dynatrace to one csv per table
# goal is to import to sqlite for further analysis and graphs.

package require ndv

set_log_global info

proc main {argv} {
  # lassign $argv report_file
  lassign $argv dir
  foreach filename [glob -nocomplain -directory $dir -type f *.csv] {
    split_file $filename
  }
}

# @post: a subdir with the same basename as report_file, and csv files with name of tables

proc split_file {report_file} {
  set dirname [file rootname $report_file]
  file mkdir $dirname

  set fi [open $report_file r]
  set fo ""
  set in_csv 0
  while {[gets $fi line] >= 0} {
    switch [det_line_type $line] {
      empty {
        if {$in_csv} {
          if {$fo != ""} {
            close $fo  
          }
          set fo ""
          set in_csv 0
        }
      }
      csv {
        if {$in_csv} {
          puts $fo $line
        } else {
          log warn "csv line in unexpected place"
          breakpont
        }
      }
      table {
        # possible new file, need the following 3 lines:
        # 1. non empty, without comma's: filename, name of table
        # 2. en empty line
        # 3. a line with comma's, the header line.
        if {$fo != ""} {
          close $fo
        }
        set fo [open_csv $dirname $line $fi]
        if {$fo != ""} {
          set in_csv 1  
        } else {
          set in_csv 0
        }
      }
      default {
        log warn "unknown line type: [det_line_type $line]"
        log warn "line: $line"
        breakpoint
      }
    }
  }
  close $fi
  if {$fo != ""} {
    close $fo
  }
}

# @pre: line contains possible name of file/table; fi is at next (possibly empty) line
# @post: either: structure found is correct, last line read and written is header line, new outfile (fo) is opened and returned.
#        or    : struct is different: warning and breakpoint
# @return - file descriptor of the opened output file.
# @note: possbly first several 'empty' tables are found, skip those until next 'real' table.
proc open_csv {dirname line fi} {
  set state read_tablename
  set table_name $line
  set fo ""
  while {$state != "finished"} {
    gets $fi line
    set line_type [det_line_type $line]
    switch $state-$line_type {
      read_tablename-empty {
        set state read_empty
      }
      read_tablename-table {
        set table_name $line
        set state read_tablename
      }
      read_empty-csv {
        set fo [open [det_csv_filename $dirname $table_name] w]
        puts $fo $line
        set state finished
      }
      read_empty-table {
        set table_name $line
        set state read_tablename
      }
      default {
        log error "Unknown combination of state ($state) and linetype ($linetype)"
        breakpoint
      }
    }
  }
  return $fo
}

proc det_csv_filename {dirname table_name} {
  regsub -all {[ ]} $table_name "_" table_name
  file join $dirname "$table_name.csv"
}

proc det_line_type {line} {
  if {[is_csv_line $line]} {
    return csv
  } elseif {[is_empty $line]} {
    return empty
  } else {
    return table
  }
}

proc is_csv_line {line} {
  set ncomma [regsub -all {,} $line ";" z]
  if {$ncomma > 0} {
    return 1
  } else {
    return 0
  }
}

proc is_empty {line} {
  if {[string length [string trim $line]] == 0} {
    return 1
  } else {
    return 0
  }
}

main $argv
