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
    lassign [split $line "\t"] cmd id path
    if {$cmd == "rm"} {
      remove_file $id $path 
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
  catch {file delete $path}
  db eval "delete from files where id=$id"
}

main $argv

