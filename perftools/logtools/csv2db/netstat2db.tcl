# netstat2db.tcl

# @todo bij laatste meer tijden en datums in bestand toegevoegd, deze gebruiken.
# ook in file van 4-6. toen het serieus misging.

package require Tclx
package require sqlite3

# own package
package require ndv

source file2dblib.tcl
source runtime-stats.tcl

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]

set DT_FORMAT "%Y-%m-%d %H:%M:%S"

proc main {argv} {
  puts "argv: $argv"
  # lassign $argv sourcefile targetdb
  lassign $argv sourcedir targetdb
  make_db $targetdb
  convert_files $sourcedir  
  db close
}

proc make_db {dbname} {
  # global ar_columns
  file delete $dbname
  sqlite3 db $dbname
  # foreign (key) is a keyword in sqlite, so use foreignad (and localad)
  make_db_table netstat [list sourcefile datetime computer proto localad localport foreignad foreignport state vport]
  make_db_table ns_runtime [list sourcefile dt_first dt_last computer proto localad localport foreignad foreignport vport]
}

proc convert_files {sourcedir} {
  handle_dir_rec $sourcedir "*netstat*.txt" convert_file
}

# Active Connections
# Proto  Local Address          Foreign Address        State
#  TCP    0.0.0.0:21             0.0.0.0:0              LISTENING
#  TCP    0.0.0.0:80             0.0.0.0:0              LISTENING
# ook UDP, deze negeren.
proc convert_file {sourcefile rootdir} {
  global DT_FORMAT
  set DAY_SECONDS [expr 24*60*60]
  log info "Read netstat file: $sourcefile"
  set startdt [det_startdt $sourcefile]
  if {$startdt == 0} {
    set startdt [file atime $sourcefile] ; # this is the creation time strangely enough, as is file mtime.
    set datetime [expr $startdt - 60] ; # at the first 'Active Connection' the 60 seconds will be added again.
    set dt_mode "implied"
    log info "Implied date time mode"
  } else {
    set dt_mode "real" 
    set date $startdt
    set prev_time "00:00"
    log info "Real date time mode"
  }
  set computer [det_computer $sourcefile $rootdir]
  # set runtime_stats [..]
  RuntimeStats create stats -cb_item cb_item -cb_runtime cb_runtime
  # should be given 2 callbacks: one for a line, where vport is added. And one for the runtime of a process or network connection.
  handle_file_lines_db $sourcefile 50000 line {
    if {[regexp {Active Connections} $line]} {
      # a block of connections at the same time is finished here, so update ns_runtime
      stats end_time_block
      if {$dt_mode == "implied"} {
        set datetime [expr $datetime + 60]
        set dt_fmt [clock format $datetime -format $DT_FORMAT]
        stats start_time_block $dt_fmt
      } else {
        # nothing, read time-lines. dt_fmt has just been set (one line before) 
      }
      stats start_time_block $dt_fmt 
    } elseif {[regexp {^(\d\d:\d\d)$} $line z time]} {
      if {$dt_mode == "real"} {
        if {$time < $prev_time} {
          set date [expr $date + $DAY_SECONDS]
        }
        # set dt_fmt [clock format [expr $date + [clock scan $time -format "%H:%M"]] -format "%Y-%m-%d %H:%M:%S"]
        set dt_fmt [clock format [expr $date + [time_seconds $time]] -format $DT_FORMAT]
        # stats start_time_block $dt_fmt
        set prev_time $time
      } else {
        # nothing, implied mode. 
      }
      # breakpoint
    } elseif {[regexp {Proto +Local Address} $line]} {
      # header line, ignore      
    } else {
      set l [as_list $line]
      if {[llength $l] == 4} {
        # lassign $l pname pid cpu thd hnd priv cputime elapsedtime
        lassign $l proto localadport foreignadport state
        lassign [split $localadport ":"] localad localport
        lassign [split $foreignadport ":"] foreignad foreignport
        # insert_record netstat [det_relative_path $sourcefile $rootdir] $dt_fmt $computer {*}$l
        
        # don't call insert_record from here, should be called by runtime_stats
        # insert_record netstat [det_relative_path $sourcefile $rootdir] $dt_fmt $computer $proto $localad $localport $foreignad $foreignport $state
        # item function params: time, key, value. Key can be multi-valued, value as well.
        stats itemline [list [det_relative_path $sourcefile $rootdir] $computer $proto $localad $localport $foreignad $foreignport] [list $state]
      } else {
        # UDP has 3 items, so automatically ignored here. 
      }
    }
  }
  stats end_time_block
  stats end_file  
}

proc cb_item {vkey dt_fmt key value} {
  # puts "callback called"
  lassign $key path computer proto localad localport foreignad foreignport
  lassign $value state
  insert_record netstat $path $dt_fmt $computer $proto $localad $localport $foreignad $foreignport $state $vkey
  # puts "callback finished"
}

proc cb_runtime {vkey dt1 dt2 key} {
  lassign $key path computer proto localad localport foreignad foreignport
  insert_record ns_runtime $path $dt1 $dt2 $computer $proto $localad $localport $foreignad $foreignport $vkey
  
  # TODO: een NOTHING item toevoegen aan netstat op moment dt2+1 (sec?, min?)
  set dt2a [add_seconds_fmt $dt2 30]
  insert_record netstat $path $dt2a $computer $proto $localad $localport $foreignad $foreignport "-" $vkey
}

proc add_seconds_fmt {dt sec} {
  global DT_FORMAT
  clock format [expr [clock scan $dt -format $DT_FORMAT] + $sec] -format $DT_FORMAT 
}

proc det_startdt {sourcefile} {
  set f [open $sourcefile r]
  gets $f dateline
  if {[regexp {^[a-z]{2} (\d\d-\d\d-\d\d\d\d)} $dateline z dt]} {
    set res [clock scan $dt -format "%d-%m-%Y"] 
  } else {
    set res 0
  }
  close $f
  # breakpoint
  return $res
}

proc time_seconds {time} {
  # clock scan with only a time gives seconds of time on current date, we only want the seconds in the day part.
  expr [clock scan $time -format "%H:%M"] - [clock scan "00:00" -format "%H:%M"] 
}

proc det_computer {filename rootdir} {
  if {[regexp {netstatlog-(.+).txt} $filename z pc]} {
    return $pc 
  } else {
    det_relative_path $filename $rootdir 
  }  
}

# convert line with fixed columns to a list, assume space as separation character (could be just one space)
proc as_list {line} {
  set str $line
  while {[regsub -all {  } $str " " str] > 0} {}
  string trim $str
}

main $argv
