# convert generated report csv by dynatrace to just csv with purepath data (the top screen)
# goal is to import to sqlite for further analysis and graphs.

proc main {argv} {
  # lassign $argv report_file
  lassign $argv dir
  foreach filename [glob -nocomplain -directory $dir -type f *.csv] {
	convert_file $filename
  }
}

proc convert_file {report_file} {
  set temp_name "$report_file.temp"
  set fi [open $report_file r]
  set fo [open $temp_name w]
  # skip_lines $fi 4
  set in_csv 0
  while {[gets $fi line] >= 0} {
    if {$in_csv} {
      if {[is_empty $line]} {
        break
      } else {
        puts $fo $line        
      }
    } else {
      if {[is_csv_header $line]} {
        set in_csv 1
        puts $fo $line
      }
    }
  }
  close $fi
  close $fo
  file rename $report_file "$report_file.orig"
  # file rename $temp_name $report_file
  # bij meer dan 1 csv in de dir gaat het fout, dan bv een '2' toevoegen...
  file rename $temp_name [file join [file dirname $report_file] "report.csv"]
}

proc skip_lines {fi n} {
  for {set i 0} {$i < $n} {incr i} {
    gets $fi
  }
}

proc is_csv_header {line} {
  set ncomma [regsub -all {,} $line ";" z]
  if {$ncomma > 5} {
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
