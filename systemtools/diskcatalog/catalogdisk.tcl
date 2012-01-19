#!/home/nico/bin/tclsh

package require ndv
package require Tclx
package require struct::list
package require fileutil
package require md5
package require sqlite3

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]

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
    foreach filename [glob -nocomplain -directory $foldername -type f $filepattern] {
      handle_file $filename $table_name
    }
    foreach dirname [glob -nocomplain -directory $foldername -type d $filepattern] {
      set tail [file tail $dirname]
      if {($tail == ".") || ($tail == "..")} {
        continue
      }
      if {[file type $dirname] == "link"} {
        continue 
      }
      catalog_folder $dirname $table_name
    }
  }
}

proc handle_file {filename table_name} {
  # @todo? upsert, not insert?
  db eval "insert into $table_name (folder, filename, filedate, filesize, md5sum, lastchecked)
           values ('[file dirname $filename]', '[file tail $filename]', '[det_datetime $filename]',
                   '[file size $filename]', '[det_md5sum $filename]', '[det_now]')"
}

proc det_datetime {filename} {
  clock format [file mtime $filename] -format "%Y-%m-%d %H:%M:%S" 
}

proc det_md5sum {filename} {
  ::md5::md5 -hex -file $filename 
}

proc det_now {} {
  clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S" 
}

# @todo use transactions:
# wat lastig met recursieve karakter
#db eval "begin transaction"
#db eval "commit"

main $argv
