#!/home/nico/bin/tclsh

# 17-8-2011 creating graphs is now split into phases:
# * read the data into a (new or existing) sqlite database
# * plot the data (maybe split into define graph en plot graph)

package require Tclx
package require csv
package require sqlite3

# own package
package require ndv

# NdV 16-9-2011 source outside of namespace?
::ndv::source_once "platform-$tcl_platform(platform).tcl" ; # load platform specific functions. 
::ndv::source_once "graphdata-lib.tcl" "find-overlaps.tcl"


namespace eval ::ndv::graphdata::data2sqlite {
  
  namespace export main ; # see if this could work
  
  variable log [::ndv::CLogger::new_logger [file tail [info script]] debug] \
           R_binary ""

  # array variables separately
  variable ar_argv
  
  # catch {set log [::ndv::CLogger::new_logger [file tail [info script]] debug]} 
  
  # @todo: add paramnames:
  # -db auto|<db>
  # -tablename auto | <tablename>
  # -legendtablename auto | <tablename>
  
  proc main {argv} {
    # global R_binary env ar_argv log
    global env
    variables ar_argv
    # breakpoint
    # @todo 16-9-2011 also accept graphsqlite params, just ignore them.
    set options {
      {path.arg "" "Path to graphdata file: a file."}  
      {clean "Remove the database before filling it again."}
      {db.arg "auto" "Put data in a (possibly new) database with this name (auto, default or explicit)"}
      {table.arg "auto" "Put data in the named table"}
      {loglevel.arg "" "Set global log level"}
    }
    set usage ": [file tail [info script]] \[options] path:"
    set argv_orig $argv
    array set ar_argv [::cmdline::getoptions argv $options $usage]

    # @todo 2-2-2012 NdV foutmelding op onderstaande, nu even negeren.
    catch {file delete "[file rootname [file tail [info script]]].log"}
    # ::ndv::CLogger::set_logfile "[file rootname [file tail [info script]]].log"
    # log set_logfile "[file rootname [file tail [info script]]].log"
    log info "Data2sqlite: start"
    log debug "remaining argv: $argv"
    if {$ar_argv(path) == ""} {
      lassign $argv path 
    } else {
      set path $ar_argv(path) 
    }
    if {$path == ""} {
      error "No filename given: $argv"
    }
    set db_name [det_db_name $path $ar_argv(db)]
    if {$ar_argv(clean)} {
      clean_database $db_name ; # do not clean if the graphdir is the same as the data dir.    
    }
    
    # 8-12-2012 NdV even, zit breakpoint in de weg? blijft hangen?
    register_log_procs
    
    # handle_file $path $db_name [det_table_name $path $ar_argv(table)]
    make_sqlite_db $path $db_name [det_table_name $path $ar_argv(table)]
    
    log info "Data2sqlite: finished"
    # list $db_name $argv2
    # breakpoint
    
    # if all args have been used, return the original cmdline args, otherwise, remove the non-used items/
    list $db_name [lrange $argv_orig 0 end-[llength $argv]]
  }
  
  proc det_db_name {filename db} {
    if {$db == "auto"} {
      return "[file rootname $filename].db" 
    } elseif {$db == "default"} {
      return data.db
    } else {
      if {[file extension $db] == ".db"} {
        return $db 
      } else {
        return "$db.db"
      }
    }  
  }
  
  proc det_table_name {path table} {
    if {$table == "auto"} {
      set base [string tolower [file rootname [file tail $path]]]
      regsub -all {[^a-z0-9_]} $base "" base
      return $base
    } elseif {$table == "default"} {
      return "flatdata"
    } else {
      return $table 
    }
  }
  
  proc clean_database {db_name} {
    log info "Cleaning database: $db_name"
    file delete $db_name 
  }
  
  # @return list: db_name, ncol: #columns, including time column.
  proc make_sqlite_db {filename db_name table_name} {
    log debug "Database name: $db_name"
    set temp_db_name [file join [get_temp_dir] data.db]
    file delete -force $temp_db_name
    if {[file exists $db_name]} {
      file copy -force $db_name $temp_db_name
    }
    log debug "temp_db: $temp_db_name"
    sqlite3 db $temp_db_name ; # when working on a netwerk share, creating the db is slow, so first create it locally.
    
    lassign [det_sepchar_headers_ncol $filename] sepchar lst_headers ncol
    # set lst [lrange $lst_headers 1 end] ; # remove first element "Relative time"
    set lst $lst_headers ; # 3-9-2011 keep entire list, first column might not be "Relative time"
    lassign [remove_overlaps $lst] lst_shortened mapping
    
    make_legend_table $filename $table_name $mapping $lst_shortened $lst
    lassign [det_timestamp_format $filename] ts_fmt ts_col
    log debug "det_timestamp_format finished, now calling make_flatdata_table"
    #breakpoint
    make_flatdata_table $ncol $ts_fmt $ts_col $filename $sepchar $table_name
    #breakpoint
    log debug "make_flatdata_table finished"
    # from the local file to the network location
    db close ; # close the temp db made for this input file.
  
    file copy -force $temp_db_name $db_name
    file delete $temp_db_name
  
    # don't open again here, graphing is done later.
    # sqlite3 db $db_name ; # open again on network share
  
    list $db_name $ncol
  }
  
  # 3-9-2011 made choice to put timestamp column always as the first, even if it is not the first in the source file.
  proc make_legend_table {filename table_name mapping lst_shortened lst} {
    foreach {ndx orig} $mapping {
      log debug "legend mapping: $ndx -> $orig"
    }
    
    # db eval "drop table if exists legend"
    db eval "create table if not exists columndef (id integer primary key autoincrement, tabname varchar(40), colname varchar(10), legendname varchar(100), fullname varchar(255), isdatetime int, datetimeformat varchar(30))"
    db eval "delete from columndef where tabname = '$table_name'"
    
    lassign [det_timestamp_format $filename] ts_fmt ts_col
    
    db eval "begin transaction"
    
    # db eval "insert into columndef values (null, '$table_name', 'meas_time', 'Measurement time', 'Measurement time', 1, '[det_timestamp_format $filename]')"
    if {$ts_col != -1} {
      db eval "insert into columndef values (null, '$table_name', 'meas_time', 'Measurement time', 'Measurement time', 1, '$ts_fmt')"
    } else {
      # nothing, no timestamp column 
    }
  
    # set ndx 1
    set ndx 0
    foreach el $lst el_short $lst_shortened {
      # if using double quotes around the query, the single quotes around the strings are still needed. If using braces, probably not.
      # db eval "insert into legend values ($ndx, 'val$ndx', '$el_short', '$el')"
      # 3-9-2011 another design decision: name the columns val0, val1, val3 etc, so val2 misses, because it's the timestamp column.
      if {$ndx != $ts_col} {
        db eval "insert into columndef values (null, '$table_name', 'val$ndx', '$el_short', '$el', 0, null)"
      }
      log debug "Inserted record into columndef: $table_name, $ndx, $el"
      incr ndx
    }  
    db eval "commit"
  }
  
  proc make_flatdata_table {ncol ts_fmt ts_col filename sepchar table_name} {
    log info "make_flatdata_table: start"
    # breakpoint
    db eval "drop table if exists $table_name"
    # @todo maybe need a 'create index'. SQLite does support this.
    # would like to use something like -> in Clojure. There are macro solutions, but for now, too much work.
    # @todo maybe need to find out max width of each column. Or just don't set the width, or even the datatype.
    # @todo for now, set as double, so R can read it, determine maximum etc.
    #db eval "create table $table_name (meas_time varchar(30), 
    #  [join [mapfor el [lrange [iota $ncol] 1 end] {id "val$el double"}] ", "])"
  
    if {$ts_col != -1} {
      db eval "create table $table_name (meas_time varchar(30), 
        [join [mapfor el [det_value_indexes $ncol $ts_col] {id "val$el double"}] ", "])"
    } else {
      db eval "create table $table_name ([join [mapfor el [det_value_indexes $ncol $ts_col] {id "val$el double"}] ", "])"
    }
        
    set fi [open $filename r]
    # gets $fi headerline
    set headerline [gets_headerline $fi]
    set nrows_inserted 0
    set linenr 0
    # 19-9-2011 should go faster with start transaction
    db eval "begin transaction"
    
    while {![eof $fi]} {
      set line [gets $fi]
      if {$sepchar == "\t"} {
        set lst_data [split $line $sepchar]
      } elseif {$sepchar == ","} {
        # use csv library
        set lst_data [csv::split $line]
      } else {
        # not used yet, use default split
        set lst_data [split $line $sepchar]
      }
        
      # breakpoint
      set lst_data [ts_to_front $lst_data $ts_col]
      incr linenr
      if {[llength $lst_data] != $ncol} {
        log warn "ncols != $ncol: [llength $lst_data] (linenr: $linenr, line: $line)" 
        continue ; # probably last line with 0 data. 
      }
      if {[lindex $lst_data 0] == ""} {
        log warn "timestamp is empty (linenr: $linenr)"
        continue ; # previous check does not handle everything apparently
      }
      try_eval {
        # 5-9-2011 NdV special handling of timestamp: in correct sqlite format.
        # 15-10-2011 NdV ts_col could be -1, then no conversion
        if {$ts_col != -1} {
          db eval "insert into $table_name values ('[ts_format_sqlite [lindex $lst_data 0] $ts_fmt]', [join [map [lrange $lst_data 1 end] val_or_null] ", "])"
        } else {
          db eval "insert into $table_name values ([join [map [lrange $lst_data 0 end] val_or_null] ", "])"
        }
        # db eval "insert into $table_name values ([join [map $lst_data val_or_null] ", "])"
        incr nrows_inserted
        if {[expr $nrows_inserted % 100] == 0} {
          log debug "rows inserted: $nrows_inserted" 
          db eval "commit"
          db eval "begin transaction"
        }
      } {
        log error "insert flatdata failed: $errorResult"
        breakpoint
      }
    }
    db eval "commit"

    log debug "Inserted $nrows_inserted rows into flatdata table"
    close $fi
    log info "make_flatdata_table: finished"
  }
  
  # format a timestamp format in the default (and only workable) format in sqlite: 2011-09-05 11:59:33 (so lose subseconds)
  proc ts_format_sqlite {value ts_fmt} {
    # value kan nog ".MMM" voor milliseconds bevatten, deze verwijderen.
    if {[regexp {^(.*)\.[0-9]{3}$} $value z val]} {
      set value $val 
    }
    clock format [clock scan $value -format $ts_fmt] -format "%Y-%m-%d %H:%M:%S"  
  }
  
  # return a list of all numbers from 0 to $ncol-1, except ts_col
  proc det_value_indexes {ncol ts_col} {
    lreplace [iota $ncol] $ts_col $ts_col
  }
  
  proc ts_to_front {lst_data ts_col} {
    if {$ts_col <= 0} {
      return $lst_data ; # eerste kolom is ts column, of -1, dus helemaal geen ts column 
    } else {
      concat [list [lindex $lst_data $ts_col]] [lreplace $lst_data $ts_col $ts_col]
    }
  }
  
  proc val_or_null {val} {
    # val can be a single space, so use string trim
    if {[string trim $val] == ""} {
      return NULL 
    } else {
      if {[string is double $val]} {
        return $val
      } else {
        return "'$val'" 
      }
    }
  }
  
  proc det_sepchar_headers_ncol {filename} {
    set sepchar [det_sepchar $filename]
    set f [open $filename r]
    # set lst_headers [split [gets $f] $sepchar]
    set line [gets_headerline $f]
    # 7-9-2011 ook csv::split gebruiken.
    if {$sepchar == ","} {
      set lst_headers [csv::split $line]
    } else {
      set lst_headers [split $line $sepchar]
    }
    close $f
    set ncol [llength $lst_headers]
    list $sepchar $lst_headers $ncol 
  }
  
  # @todo if .ext == .txt, then look into the file.
  proc det_sepchar {filename} {
    if {[file extension $filename] == ".tsv"} {
      return "\t" 
    } elseif {[file extension $filename] == ".tab"} {
      return "\t"
    } elseif {[file extension $filename] == ".csv"} {
      return ","
    } else {
      error "Cannot determine sepchar from filename: $filename" 
    }
  }
  
  # @return [list {timestamp format in R syntax} {timestamp_column (base 0)}
  # @example: Loadrunner: %H:%M
  # @example: %d-%m-%y %H:%M:%S
  # @todo determine input and output format seperately, i.e. add a newline between date and time?
  proc det_timestamp_format {filename} {
    # @todo: for now, base on first column of the second row. Later, check all values, to distinguish months from days and years.
    set f [open $filename r]
    gets_headerline $f
    gets $f line
    # lassign [split $line [det_sepchar $filename]] timeval
    # 7-9-2011 ook csv split gebruiken!
    set sepchar [det_sepchar $filename]
    if {$sepchar == ","} {
      set lst [csv::split $line]
    } else {
      set lst [split $line $sepchar]
    }
    close $f
    set timecol -1
    set col 0
    log debug "Finding timestamp column and format. Searching #columns: [llength $lst]"
    foreach val $lst {
      set fmt [det_timestamp_format_value $val]
      if {$fmt != ""} {
        set timecol $col
        break 
      }
      incr col
    }
    log debug "Found timestamp column and format: $col, $fmt"
    # log @TODO: blijft hierin hangen? 
    if {$timecol == -1} {
      # 15-10-2011 NdV not all datafiles have a timestamp column, is this a problem?
      # error "No timestamps found in line: $line"
      list "" -1
    } else {
      list $fmt $timecol 
    }
  }
  
  proc gets_headerline {fi} {
    gets $fi line
    if {[string trim $line] == ""} {
      # possibly a typeperf file, first line is blank, second contains header.
      gets $fi line
    }
    return $line
  }
  
  # todo by xx/yy/jaar kan zowel xx als yy de maand en/of de dag zijn. Als een van beide >12, dan duidelijk, anders op zoek naar eerstvolgende afwijkende, en kijken wat
  # er afwijkt.
  proc det_timestamp_format_value {timeval} {
    log debug "det_timestamp_format_value: $timeval"
    if {[regexp {^[0-9]{1,2}:[0-9]{2}(:[0-9]{2})?$} $timeval z sec]} {
      if {$sec == ""} {
        return "%H:%M"
      } else {
        return "%H:%M:%S"  
      }
    # @todo als jaar 2 tekens heeft, is het nog moeilijker om de goede volgorde van d,m,y te bepalen.
    } elseif {[regexp {^[0-9]{1,2}([-/])[0-9]{1,2}([-/])([0-9]{2,4}) [0-9]{1,2}:[0-9]{2}(:[0-9]{2})?$} $timeval z sep1 sep2 year sec]} {
      if {$sec == ""} {
        # return "%d-%m-%[det_year_char $year] %H:%M"
        return "%d$sep1%m$sep2%[det_year_char $year] %H:%M"
      } else {
        return "%d$sep1%m$sep2%[det_year_char $year] %H:%M:%S"
      }
    } elseif {[regexp {^([0-9]{2,4})([-/])[0-9]{1,2}([-/])[0-9]{1,2} [0-9]{1,2}:[0-9]{2}(:[0-9]{2})?$} $timeval z year sep1 sep2 sec]} {
      if {$sec == ""} {
        # return "%d-%m-%[det_year_char $year] %H:%M"
        return "%[det_year_char $year]$sep1%m$sep2%d %H:%M"
      } else {
        # return "%d$sep1%m$sep2%[det_year_char $year] %H:%M:%S"
        return "%[det_year_char $year]$sep1%m$sep2%d %H:%M:%S"
      }
    } elseif {[regexp {^[0-9]{2}/[0-9]{2}/[0-9]{4} [0-9]{1,2}:[0-9]{2}:[0-9]{2}\.[0-9]{3}$} $timeval]} {
      # tcl kan de msec niet parsen met clock scan, keuze om altijd voor de clock scan al te verwijderen.
      return "%m/%d/%Y %H:%M:%S"
    } else {
      return "" ; # signal: no time value 
    }
  }
  
  proc det_year_char {year} {
    if {[string length $year] == 2} {
      return "y" 
    } elseif {[string length $year] == 4} {
      return "Y" 
    } else {
      error "Unable to determine year char: $year" 
    }
  }
  
  # with this proc no need to 'global log' in every proc, just do 'log XXX' instead of '$log XXX'
  proc log {args} {
    # global log
    variable log
    $log {*}$args
  }
  
  proc register_log_procs {} {
    foreach proc_name {make_sqlite_db det_sepchar_headers_ncol remove_overlaps 
                       make_legend_table det_timestamp_format det_timestamp_format_value 
                       make_flatdata_table} {
      register_log_proc $proc_name 
    }
  }
  
  proc register_log_proc {proc_name} {
    # 3-9-2011 leavestep doet nog wat meer dan verwacht, ook steps van onderliggende procs?
    # trace add execution $proc_name {enter leave leavestep} trace_proc
    log debug "Register log proc: $proc_name"
    trace add execution $proc_name {enter leave} trace_proc
  }
  
  proc trace_proc {args} {
    set op [lindex $args end]
    log debug "Trace: [join $args " *** "]"
  }

  # wrapper around variable, to define more than 1 variable without settings its value
  proc variables {args} {
    foreach arg $args {
      uplevel variable $arg 
    }
  }
  
} ; # namespace eval

# main $argc $argv
if {[file tail $argv0] == [file tail [info script]]} {
  ndv::graphdata::data2sqlite::main $argv
}

