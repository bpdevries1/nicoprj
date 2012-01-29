#!/home/nico/bin/tclsh

package require ndv
package require Tclx
package require struct::list
package require sqlite3

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]

proc main {argv} {
  set options {
    {db.arg "hd-all.db" "Catalog database"}
    {minsize.arg "10000000" "Minimum size of files to handle"}
    {limit.arg "10" "Maximum number of records to handle"}
    {out.arg "rm-files.txt" "File to put files to remove in"}
    {loglevel.arg "" "Set global log level"}
  }
  set usage ": [file tail [info script]] \[options] path:"
  set argv_orig $argv
  array set ar_argv [::cmdline::getoptions argv $options $usage]
  file delete "[file rootname [file tail [info script]]].log"
  ::ndv::CLogger::set_logfile "[file rootname [file tail [info script]]].log"
  # @todo (see other code) handle loglevel.arg
  
  set db_name $ar_argv(db)
  sqlite3 db $db_name
  
  handle_doubles $ar_argv(out) $ar_argv(minsize) $ar_argv(limit)
}

# out_filename: everything starting with # is comment, everything with rm\t<id>\t<filename> is a file to be removed.

proc handle_doubles {out_filename minsize limit} {
  global log

  set f [open $out_filename w]             

  set query "select f1.id id1, f1.folder folder1, f1.filename filename1, f1.filesize filesize1, f1.md5sum md5sum1, 
                    f2.id id2, f2.folder folder2, f2.filename filename2, f2.filesize filesize2, f2.md5sum md5sum2 
             from files f1, files f2
             where cast(f1.filesize as integer) > $minsize 
             and cast(f1.filesize as integer) = cast(f2.filesize as integer)
             and f1.id < f2.id limit $limit"
             
             
  $log debug "query: $query"

  #set res [db eval $query]
  #$log debug "res: $res"
  
  db eval $query {
    $log debug "handling query result: $filename1"
    # resultaten per rij in vars $id1 etc.
    puts $f "# File1: [file join $folder1 $filename1]: $filesize1: $md5sum1"
    puts $f "# File2: [file join $folder2 $filename2]: $filesize2: $md5sum2"
    set kv1 [keep_value $folder1 $filename1]
    set kv2 [keep_value $folder2 $filename2]
    puts $f "# Keep value 1: $kv1"
    puts $f "# Keep value 2: $kv2"
    if {$filename1 != $filename2} {
      puts $f "# Filenames differ, don't delete anything" 
    } else {
      if {$kv1 > $kv2} {
        puts $f "# Delete: [file join $folder2 $filename2]"
        puts $f [join [list rm $id2 [file join $folder2 $filename2]] "\t"] 
      } elseif {$kv1 < $kv2} {
        puts $f "# Delete: [file join $folder1 $filename1]"
        puts $f [join [list rm $id1 [file join $folder1 $filename1]] "\t"] 
      } else {
        puts $f "# Keep values are the same, don't delete anything"        
      }
    }
    puts $f "" ; # always a new line between entries.
  }
  close $f
}

proc keep_value {folder filename} {
  if {[is_old_backup $folder]} {
    return 0 ; # old backups have the least value. 
  }
  
  # if type not determined, keep file, so set value high
  return 1000
}

proc is_old_backup {folder} {
  #DellLaptop  hardware          leesmij.txt      Ordina-SPE-wiki  YmorLaptop
  #DellPC      laptop-important  nicodevreeze.nl  pcubuntu

  if {[regexp {media/nas/backups/([^/]+)} $folder z src]} {
    if {[lsearch -exact {DellLaptop DellPC laptop-important} $src] >= 0} {
      return 1 
    }
  }
  return 0
}

main $argv

