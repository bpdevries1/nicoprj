#!/home/nico/bin/tclsh

package require ndv
package require Tclx
package require struct::list
package require sqlite3

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]

proc main {argv} {
  global log ignore_res
  set options {
    {db.arg "hd-all.db" "Catalog database"}
    {minsize.arg "10000000" "Minimum size of files to handle"}
    {limit.arg "50" "Maximum number of records to handle"}
    {out.arg "rm-files.txt" "File to put files to remove in"}
    {ignore.arg "backups/YmorLaptop;backups/pcubuntu;/Dropbox;C:/bieb;C:/media;/media/e drive/media;C:/install;/media/f backup-c" "Set of re's of paths to ignore, separated by semicolon"}
    {loglevel.arg "" "Set global log level"}
  }
  # ignore: default ignore backup and cache locations.
  
  set usage ": [file tail [info script]] \[options] path:"
  set argv_orig $argv
  array set ar_argv [::cmdline::getoptions argv $options $usage]
  file delete "[file rootname [file tail [info script]]].log"
  ::ndv::CLogger::set_logfile "[file rootname [file tail [info script]]].log"
  # @todo (see other code) handle loglevel.arg
  parray ar_argv
  
  set db_name $ar_argv(db)
  sqlite3 db $db_name
  
  set ignore_res [split $ar_argv(ignore) ";"]
  db function ignorepath ignorepath
  
  handle_doubles $ar_argv(out) $ar_argv(minsize) $ar_argv(limit)
}

# out_filename: everything starting with # is comment, everything with rm\t<id>\t<filename> is a file to be removed.

proc handle_doubles {out_filename minsize limit} {
  global log

  set f [open $out_filename w]             
  if {0} {
    set query "select f1.id id1, f1.folder folder1, f1.filename filename1, f1.filesize filesize1, f1.md5sum md5sum1, 
                      f2.id id2, f2.folder folder2, f2.filename filename2, f2.filesize filesize2, f2.md5sum md5sum2 
               from files f1, files f2
               where cast(f1.filesize as integer) > $minsize 
               and cast(f1.filesize as integer) = cast(f2.filesize as integer)
               and f1.md5sum = f2.md5sum
               and f1.id < f2.id
               and ignorepath(folder1) = 0
               and ignorepath(folder2) = 0
               limit $limit"
  }
  
  set query "select f1.id id1, f1.folder folder1, f1.filename filename1, f1.filesize_int filesize1, f1.md5sum md5sum1, f1.loc_type lt1, f1.loc_detail ld1,
                    f2.id id2, f2.folder folder2, f2.filename filename2, f2.filesize_int filesize2, f2.md5sum md5sum2, f2.loc_type lt2, f2.loc_detail ld2 
             from files f1, files f2
             where f1.filesize_int > $minsize 
             and f1.filesize_int = f2.filesize_int
             and f1.md5sum = f2.md5sum
             and f1.id < f2.id
             and (f1.loc_type is null or f1.loc_type = 'source')
             and (f2.loc_type is null or f2.loc_type = 'source')
             limit $limit"
             
  $log debug "query: $query"

  #set res [db eval $query]
  #$log debug "res: $res"
  
  db eval $query {
    $log debug "handling query result: $filename1"
    # resultaten per rij in vars $id1 etc.
    puts $f "# File1: [file join $folder1 $filename1]: $filesize1: $md5sum1"
    puts $f "# File2: [file join $folder2 $filename2]: $filesize2: $md5sum2"
    set kv1 [keep_value $folder1 $filename1 $lt1 $ld1]
    set kv2 [keep_value $folder2 $filename2 $lt2 $ld2]
    puts $f "# Keep value 1: $kv1"
    puts $f "# Keep value 2: $kv2"
    if {$filename1 != $filename2} {
      puts $f "# WATCH OUT: Filenames differ, check if they are really the same!" 
    }
    if {[file join $folder1 $filename1] == [file join $folder2 $filename2]} {
      puts $f "# WATCH OUT: 2 entries pointing to the same file!\n"
      continue; # hier wel continue, al een newline toegevoegd.
    }
    
    if {($kv1 == 1000) || ($kv2 == 1000)} {
      if {$kv1 == 0} {
        puts $f "# Delete: [file join $folder1 $filename1]"
        puts $f [join [list rm $id1 [file join $folder1 $filename1]] "\t"] 
      } elseif {$kv2 == 0} {
        puts $f "# Delete: [file join $folder2 $filename2]"
        puts $f [join [list rm $id2 [file join $folder2 $filename2]] "\t"] 
      } else {
        puts $f "# one of values equals 1000, don't delete anything, determine what should happen"
      }
    } else {
      if {$kv1 > $kv2} {
        puts $f "# Delete: [file join $folder2 $filename2]"
        puts $f [join [list rm $id2 [file join $folder2 $filename2]] "\t"] 
      } elseif {$kv1 < $kv2} {
        puts $f "# Delete: [file join $folder1 $filename1]"
        puts $f [join [list rm $id1 [file join $folder1 $filename1]] "\t"] 
      } else {
        # delete arbitrary one, as long as it's the same always: eg 3 files are the same 1<2<3: now 1 surely stays, otherwise 2 or 3 would be removed!
        puts $f "# Keep values are the same, delete the second one: [file join $folder2 $filename2]"
        puts $f [join [list rm $id2 [file join $folder2 $filename2]] "\t"]
      }
    }
    puts $f "" ; # always a new line between entries.
  }
  close $f
}

proc keep_value {folder filename loc_type loc_detail} {
  set rel_value 0
  
  if {[is_old_backup $folder]} {
    return 0 ; # old backups have the least value. 
  }
  
  # met uitzoeken in de naam -/- 10
  if {[regexp {itzoeken} $folder]} {
    set rel_value [expr $rel_value -10] 
  }

  # blijkbaar .svn files dezelfde als de origs.
  if {[regexp {/\.svn/} $folder]} {
    set rel_value [expr $rel_value -20] 
  }
  
  # langere filenames helpen een klein beetje
  set rel_value [expr $rel_value + 0.01 * [string length $filename]]
  
  # als 1 van de files in aaa zit, en de andere niet, wint de andere.
  if {[regexp {/aaa/} $folder]} {
    set rel_value [expr $rel_value - 100] 
  }
  
  if {$loc_type == "source"} {
    # deeper folder is better
    return [expr 500 + [llength [file split $folder]] + $rel_value]
  }
  
  # if type not determined, keep file, so set value high
  return 1000 ; # hier geen rel.value bij, check op 1000 hierboven.
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

proc ignorepath {path} {
  global ignore_res
  set res 0
  foreach re $ignore_res {
    if {[regexp $re $path]} {
      set res 1 
    }
  }  
  return $res
}

main $argv

