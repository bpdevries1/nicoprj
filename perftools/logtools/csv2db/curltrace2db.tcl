# curltrace2db.tcl

package require Tclx
package require csv
package require sqlite3

# own package
package require ndv

source file2dblib.tcl

# lines
# <httpSample t="2430" lt="2426" ts="1350721801764" s="true" lb="Behandelaar ophalen" rc="200" rm="OK" tn="Thread Group 1-2" 
# dt="text" de="utf-8" by="555" ng="2" na="2" hn="P3738"/>
set log [::ndv::CLogger::new_logger [file tail [info script]] debug]

proc main {argv} {
  puts "argv: $argv"
  # lassign $argv sourcefile targetdb
  lassign $argv sourcedir targetdb
  make_db $targetdb
  convert_files $sourcedir  
  db close
}
# 28/11/2012,11:36:22,Windows SharePoint Services 3,Error,(807),8214,N/A,VSW-APL-021,"The description for Event ID ( 8214 ) in Source ( Windo

proc make_db {dbname} {
  global ar_columns
  file delete $dbname
  sqlite3 db $dbname
  set ar_columns(curltrace) [list sourcefile dt_start dt_end host url resptime timeout phase result]
  # db eval "create table curltrace (id integer primary key autoincrement, sourcefile, dt_start, dt_end, url, resptime, timeout)"
  db eval "create table curltrace (id integer primary key autoincrement, [join $ar_columns(curltrace) ", "])"
}

proc convert_files {sourcedir} {
  # handle_dir_rec $sourcedir "curl-trace-all.out" convert_file
  handle_dir_rec $sourcedir "curl*.out" convert_file
}

proc convert_file {sourcefile rootdir} {
  set DAY_SECONDS [expr 24*60*60]
  # make_db $targetdb
  log info "Read curl trace source: $sourcefile"
  # return ; # for test.
  
  # set f [open $sourcefile r]
  set lines ""
  set nlines 0
  set totallines 0
  # set date [clock scan "2012-12-05" -format "%Y-%m-%d"]
  set date [det_start_date $sourcefile]
  set prev_time "00:00:00"
  set timeout1 0
  set timeout2 0
  set timeout12 0
  set result 0
  set sourcefile_rel [det_relative_path $sourcefile $rootdir]
  set host "<unknown>"
  set url "<unknown>"
  # GET /default.aspx HTTP/1.1
  # POST /TK/2019-2020/20200101/_vti_bin/lists.asmx?op=GetListAndVie
  # About to connect() to markeer1 port 80 (#0)
  handle_file_lines_db $sourcefile 50000 line {
    if {[regexp {((GET)|(POST)) ([^ ]+)} $line z z z z u]} {
      set url $u 
    }
    if {[regexp {^(\d\d:\d\d:\d\d)(\.\d\d\d\d\d\d) == Info: (.*)$} $line z time msec text]} {
      if {$time < $prev_time} {
        set date [expr $date + $DAY_SECONDS]
      }
      if {[regexp {About to connect\(\) to ([^ ]+) } $text z host]} {
        set timeout 0
        set result 0
        set starttime1_sec [expr $date + [clock scan $time -format "%H:%M:%S"] + $msec]
        set dt_start1 "[clock format $date -format "%Y-%m-%d"] $time$msec"
      } elseif {[regexp {Issue another request to this URL} $text]} {
        set timeout1 $timeout
        set timeout 0
        set endtime1_sec [expr $date + [clock scan $time -format "%H:%M:%S"] + $msec]
        set dt_end1 "[clock format $date -format "%Y-%m-%d"] $time$msec"
        set resptime1 [expr $endtime1_sec - $starttime1_sec]
        insert_record curltrace $sourcefile_rel  $dt_start1 $dt_end1 $host $url $resptime1 $timeout1 1 $result
        set starttime2_sec $endtime1_sec
        set dt_start2 $dt_end1
      } elseif {[regexp {Closing connection} $text]} {
        set timeout2 $timeout
        set timeout12 [expr $timeout1 || $timeout2]
        set timeout 0        
        set endtime2_sec [expr $date + [clock scan $time -format "%H:%M:%S"] + $msec]
        set dt_end2 "[clock format $date -format "%Y-%m-%d"] $time$msec"
        set resptime2 [expr $endtime2_sec - $starttime2_sec]
        insert_record curltrace $sourcefile_rel  $dt_start2 $dt_end2 $host $url $resptime2 $timeout2 2 $result
        set resptime12 [expr $endtime2_sec - $starttime1_sec]
        insert_record curltrace $sourcefile_rel  $dt_start1 $dt_end2 $host $url $resptime12 $timeout12 12 $result
      }
      
      # db eval "create table curltrace (id integer primary key autoincrement, sourcefile, dt_start, dt_end, url, resptime, timeout)"
      set prev_time $time      
    }
    if {[regexp {timed%20out} $line]} {
      set timeout 1 
    }
    if {[good_result $line]} {
      set result 1 
    }    
  }
}

# check if a known good result is in text, for webservice and main-page.
proc good_result {line} {
  if {[regexp {GetListAndViewResponse} $line]} {
    return 1         
  } elseif {[regexp {Introductiepagina - VLOS} $line]} {
    return 1    
  } else {
    return 0 
  }   
}

proc det_start_date {sourcefile} {
  # no dates in contents of curl, determine by counting date change and date of file
  set mtime [file mtime $sourcefile]
  set mday [clock scan [clock format $mtime -format "%Y-%m-%d"] -format "%Y-%m-%d"]
  set prev_time "00:00:00"
  set ndates 0
  set f [open $sourcefile r]
  while {![eof $f]} {
    gets $f line
    if {[regexp {^(\d\d:\d\d:\d\d)(\.\d\d\d\d\d\d) == Info: (.*)$} $line z time msec text]} {
      if {$time < $prev_time} {
        incr ndates
      }
      set prev_time $time
    }
  }
  close $f  
  expr $mday - $ndates * (24*60*60)  
}

# @todo possible library functions below:

proc handle_dir_rec_old {dir globpattern actionproc {rootdir ""}} {
  if {$rootdir == ""} {
    set rootdir $dir 
  }
  foreach filename [glob -nocomplain -directory $dir -type f $globpattern] {
    $actionproc $filename $rootdir
  }
  foreach dirname [glob -nocomplain -directory $dir -type d *] {
    handle_dir_rec $dirname $globpattern $actionproc $rootdir
  }
}

# @pre db is open handle to sqlite db. 
proc handle_file_lines_db_old {filename commit_lines block} {
  # connect line in uplevel stack frame to myline in this stackframe
  upvar line myline
  set f [open $filename r]
  set totallines 0
  db eval "begin transaction"
  while {![eof $f]} {
    gets $f myline
    set totallines [expr $totallines + 1]
    if {[expr $totallines % $commit_lines] == 0} {
      log info "Lines read: $totallines" 
      db eval "commit"
      db eval "begin transaction"
    }
    # $proc $line
    # kent 'ie line in uplevel?
    # quoten van line werkt niet goed, als er ook quotes in line zitten, met list gaat het wel goed.
    # zie ook http://wiki.tcl.tk/1507
    # uplevel "set line \"$line\""
    # uplevel [list set line $line]
    uplevel $block
  }
  close $f
  db eval "commit"
}


# db eval "create table curltrace (id integer primary key autoincrement, sourcefile, datetime, url, resptime, timeout)"
proc insert_record_old {table args} {
  global ar_columns
  set lst_vals {}
  foreach arg $args {
    lappend lst_vals "'$arg'" 
  }
  set query "insert into $table ([join $ar_columns($table) ", "]) values ([join $lst_vals ", "])"
  db eval $query
  db last_insert_rowid
}

proc det_relative_path_old {sourcefile rootdir} {
  string range $sourcefile [string length $rootdir]+1 end
}


proc log_old {args} {
  global log
  # variable log
  $log {*}$args
}

main $argv
