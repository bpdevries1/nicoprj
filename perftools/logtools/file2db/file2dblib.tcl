# library functions for reading (text) files into a sqlite db for further analysis.

# @todo possible library functions below:

proc handle_dir_rec {dir globpattern actionproc {rootdir ""}} {
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
proc handle_file_lines_db {filename commit_lines line_name block} {
  # connect line in uplevel stack frame to myline in this stackframe
  upvar $line_name myline
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

proc make_db_table {table columns} {
  global ar_columns
  set ar_columns($table) $columns
  set query "create table $table (id integer primary key autoincrement, [join $ar_columns($table) ", "])" 
  # breakpoint
  db eval $query
}

# db eval "create table curltrace (id integer primary key autoincrement, sourcefile, datetime, url, resptime, timeout)"
proc insert_record {table args} {
  global ar_columns
  set lst_vals {}
  foreach arg $args {
    # @todo: als val als integer/float gezien kan worden, dan geen quotes toevoegen.
    if {[string trim $arg] == ""} {
      lappend lst_vals "'$arg'"
    } elseif {[string is double $arg]} {
      lappend lst_vals $arg
    } else {
      lappend lst_vals "'$arg'"
    }
  }
  set query "insert into $table ([join $ar_columns($table) ", "]) values ([join $lst_vals ", "])"
  # log debug "query: $query"
  db eval $query
  db last_insert_rowid
}

proc det_relative_path {sourcefile rootdir} {
  string range $sourcefile [string length $rootdir]+1 end
}

proc log {args} {
  global log
  # variable log
  $log {*}$args
}

proc sqlite_ts {sec} {
  clock format $sec -format "%Y-%m-%d %H:%M:%S" 
}
