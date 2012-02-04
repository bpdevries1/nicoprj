#!/home/nico/bin/tclsh

package require ndv
package require Tclx
package require struct::list
package require sqlite3

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]

proc main {argv} {
  set options {
    {db.arg "hd-all.db" "Catalog database"}
    {in.arg "rm-files.txt" "File to put files to remove in"}
    {loglevel.arg "" "Set global log level"}
  }
  set usage ": [file tail [info script]] \[options] path:"
  set argv_orig $argv
  array set ar_argv [::cmdline::getoptions argv $options $usage]
  parray ar_argv
  
  file delete "[file rootname [file tail [info script]]].log"
  ::ndv::CLogger::set_logfile "[file rootname [file tail [info script]]].log"
  # @todo (see other code) handle loglevel.arg
  
  set db_name $ar_argv(db)
  sqlite3 db $db_name
  
  delete_files $ar_argv(in)
}

proc delete_files {infilename} {
  global log
  set f [open $infilename r]
  while {![eof $f]} {
    gets $f line
    if {[regexp {^#} $line]} {
      continue 
    }
    if {$line == ""} {
      continue 
    }
    # lassign [split $line "\t"] cmd id path
    set lline [split $line "\t"]
    set cmd [lindex $lline 0]
    if {$cmd == "rm"} {
      remove_file [lindex $lline 1] [lindex $lline 2] ; # id and path of file to remove 
    } elseif {$cmd == "keep"} {
      keep_files [lindex $lline 1] [lindex $lline 2] ; # id's of both files to keep
    } else {
      $log warn "Don't know how to handle: $line" 
    }
  }
  close $f
}

proc remove_file {id path} {
  # either of the following commands may do nothing, if the file or record is already deleted
  # this should not give an error
  global log
  $log info "Deleting: $path"
  # catch {file delete $path}
  try_eval {
    if {![file exists $path]} {
      $log warn "File does not exist before delete: $path" 
    }
    file delete $path
    if {[file exists $path]} {
      $log warn "File still exists after delete: $path" 
    }
  } {
    $log warn "Delete failed: $errorResult"
  }
  db eval "delete from files where id=$id"
}

proc keep_files {id1 id2} {
  global log
  $log info "Keeping both files: $id1 $id2"
  db eval "insert into keep_doubles (id1, id2, date_inserted) values ($id1, $id2, '[sqlite_now]')" 
}

proc sqlite_now {} {
  clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S" 
}

main $argv

