#!/home/nico/bin/tclsh

package require ndv
package require Tclx
package require struct::list
package require fileutil
# package require md5
package require sqlite3

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]

set env(CYGWIN) nodosfilewarning

proc main {argv} {
  set options {
    {root.arg "" "Root path to make catalog of."}  
    {db.arg "" "Put data in a (possibly new) catalog database with this name"}
    {table.arg "files" "Put data in the named table"}
    {loglevel.arg "" "Set global log level"}
  }
  set usage ": [file tail [info script]] \[options] path:"
  set argv_orig $argv
  array set ar_argv [::cmdline::getoptions argv $options $usage]
  file delete "[file rootname [file tail [info script]]].log"
  ::ndv::CLogger::set_logfile "[file rootname [file tail [info script]]].log"
  # @todo (see other code) handle loglevel.arg
  
  set db_name $ar_argv(db)
  set table_name $ar_argv(table)
  make_sqlite_db $db_name $table_name
  catalog_folder [file normalize $ar_argv(root)] $table_name
  
  db close
}

proc make_sqlite_db {db_name table_name} {
  sqlite3 db $db_name
  db eval "create table if not exists $table_name ( 
          id integer primary key autoincrement, 
          folder varchar(300),
          filename varchar(300),
          filedate varchar(20),
          filesize varchar(15), 
          md5sum varchar(40),
          lastchecked varchar(20))"

  # @todo add index here also, or better after the inserting.
  
  # @todo process-table: cataloging may take a long time, so we could interrupt it and move on at a later time.
}

proc catalog_folder {foldername table_name} {
  global log
  $log debug "handling: $foldername"
  foreach filepattern {* .*} {
    # set filelist [try {glob -nocomplain -directory $foldername -type f $filepattern} {}]
    # foreach filename [glob -nocomplain -directory $foldername -type f $filepattern] {}
    foreach filename [try {glob -nocomplain -directory $foldername -type f $filepattern} {}] {
    # foreach filename $filelist {}
      handle_file $filename $table_name
    }
    foreach dirname [try {glob -nocomplain -directory $foldername -type d $filepattern} {}] {
      set tail [file tail $dirname]
      if {($tail == ".") || ($tail == "..")} {
        continue
      }
      if {[try {file type $dirname} "link"] == "link"} {
        continue 
      }
      catalog_folder $dirname $table_name
    }
  }
}

proc handle_file {filename table_name} {
  # @todo? upsert, not insert?
  global log
  # $log debug "filename: $filename"
  db eval "insert into $table_name (folder, filename, filedate, filesize, md5sum, lastchecked)
           values ('[str_to_db [file dirname $filename]]', '[str_to_db [file tail $filename]]', '[det_datetime $filename]',
                   '[try {file size $filename} -1]', '[det_md5sum $filename]', '[det_now]')"
}

proc det_datetime {filename} {
  try {clock format [file mtime $filename] -format "%Y-%m-%d %H:%M:%S"} "error" 
}

proc det_md5sum {filename} {
  # try {::md5::md5 -hex -file $filename} "error"
  # 21-1-2012 interne heel traag, exec md5sum veel sneller.
  # vb met /home/nico/app.source.221663266939.tar (5.5 MB)
  # tcl: 33-34 sec
  # exec: 0.6 sec.
  set res [try {exec md5sum $filename} "error"]
  string range $res 0 31
}

proc det_now {} {
  clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S" 
}

# @todo use transactions:
# wat lastig met recursieve karakter
#db eval "begin transaction"
#db eval "commit"

# @todo potential library function, maybe should rename.
proc try {cmd exc_res} {
  global log
  set res $exc_res
  try_eval {
    set res [uplevel $cmd]
  } {
    $log warn "Error with: $cmd: $errorResult" 
  }
  return $res
}

proc str_to_db {str} {
  regsub -all {'} $str "''" str
  regsub -all {\\} $str {\\\\} str
  return $str
}
 

main $argv
