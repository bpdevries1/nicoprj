#!/home/nico/bin/tclsh

package require ndv
package require Tclx
package require struct::list
package require sqlite3

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]

proc main {argv} {
  global log ignore_res
  set options {
    {db.arg "c:/aaa/diskcat/hd-all.db" "Catalog database"}
    {minsize.arg "10000000" "Minimum size of files to handle"}
    {limit.arg "50" "Maximum number of records to handle"}
    {out.arg "w:/rm-files.txt" "File to put files to remove in"}
    {loglevel.arg "" "Set global log level"}
  }
  # ignore: default ignore backup and cache locations.
  #  {ignore.arg "backups/YmorLaptop;backups/pcubuntu;/Dropbox;C:/bieb;C:/media;/media/e drive/media;C:/install;/media/f backup-c" "Set of re's of paths to ignore, separated by semicolon"}
  
  set usage ": [file tail [info script]] \[options] path:"
  set argv_orig $argv
  array set ar_argv [::cmdline::getoptions argv $options $usage]
  file delete "[file rootname [file tail [info script]]].log"
  ::ndv::CLogger::set_logfile "[file rootname [file tail [info script]]].log"
  # @todo (see other code) handle loglevel.arg
  parray ar_argv
  
  set db_name $ar_argv(db)
  sqlite3 db $db_name
  
  #set ignore_res [split $ar_argv(ignore) ";"]
  #db function ignorepath ignorepath
  
  make_keep_table
  def_action_functions
  log_action_functions
  
  # remove action file here, maybe filled from more than one function.
  file delete $ar_argv(out)
  
  # handle_doubles $ar_argv(out) $ar_argv(minsize) $ar_argv(limit)



  # Onderstaande 2 gedaan voor files > 10MB (<26-02-2012)
  handle_old_backups $ar_argv(out) $ar_argv(minsize) $ar_argv(limit)
  
  # delete_old duurt soms best lang.
  # delete_old $ar_argv(out) $ar_argv(minsize) $ar_argv(limit)

  # Hulp functies?
  # move_dir in principe altijd hele dir, niet alleen limit aantal of vanaf minsize groot.
  # move_dir $ar_argv(out) $ar_argv(minsize) $ar_argv(limit) "/media/nas/backups/laptop-important/d/util/soapui-2.5" "/media/nas/archief/installed/soapui-2.5"
  
}

# out_filename: everything starting with # is comment, everything with rm\t<id>\t<filename> is a file to be removed.

proc make_keep_table {} {
  db eval "create table if not exists keep_doubles (id1 integer, id2 integer, date_inserted, notes)" 
  db eval "create index if not exists ix_keep_doubles on keep_doubles(id1,id2)"
}

proc def_action_functions {} {
  # ar_functions: assoc array t1,t2=>(determine) action function
  
  # @todo:
  # met uitzoeken in de naam -/- 10
  # blijkbaar .svn files dezelfde als de origs.
  # langere filenames helpen een klein beetje
  # als 1 van de files in aaa zit, en de andere niet, wint de andere.
  
  # oldbackup: backups for laptop etc, can be deleted if available elsewhere.
  # backup: current backup, it's the function of this that it's a double
  # extrabackup: backup on an old drive, keep for now, maybe delete if we're sure there's another backup
  # cache: for better availability when on the road, i.e. dropbox, stuff on laptop. @todo: all files should exist elsewhere, in a source-location (maybe system location)
  # @todo cache: not all cache needs to be kept on cache, eg. Talend stuff on c:\install.
  # cache->other-structure: eg singles, put in a different place for different function, could be replaced by symlinks.
  # source: source-code but also project data, this is the original place
  # @todo: have source for both github locations. If locations differ, don't delete, if in the same repo, make a note.
  # system: OS files, program files, stuff that needs to stay.
  # @todo als het goed is, hoef je van een cache (c:\install) geen backup te maken.
  set all_types {oldbackup backup extrabackup cache source system archive}
  def_action_function oldbackup $all_types delete_oldbackup
  def_action_function extrabackup {archive backup} delete_extrabackup
  # def_action_function extrabackup source keep_both
  def_action_function {system source} {backup extrabackup cache} keep_both
  def_action_function {system source} {system source} keep_both
  def_action_function {backup extrabackup} cache keep_both
  def_action_function backup backup keep_one
  def_action_function cache cache keep_one
  def_action_function extrabackup extrabackup keep_one
  def_action_function archive archive keep_one
  def_action_function archive {system source} delete_archive
  def_action_function archive {backup cache} keep_both
  
  # @todo archive itt active, zoals source en backup. Raar als iets zowel archive als active is.
  # note: waar wil je bron hebben: active (source), dan archief, dan extrabackup
}

proc def_action_function {ltp1 ltp2 fn_name} {
  foreach tp1 $ltp1 {
    foreach tp2 $ltp2 {
      set_ar_functions $tp1 $tp2 $fn_name
      set_ar_functions $tp2 $tp1 $fn_name
    }
  }
}

# check if value already set, if new value is the same, ok, if different, error.
proc set_ar_functions {tp1 tp2 fn_name} {
  global ar_functions
  
  set res "none"
  catch {set res $ar_functions($tp1,$tp2)}
  if {$res == "none"} {
    set ar_functions($tp1,$tp2) $fn_name 
  } else {
    if {$res == $fn_name} {
      # ok, set to the same 
    } else {
      error "ar_functions($tp1,$tp2) about to be set to $fn_name, but already has value $res" 
    }
  }
}

proc log_action_functions {} {
  global ar_functions
  # find all types, check if each combination of types has a value
  foreach el [array names ar_functions] {
    foreach el2 [split $el ","] {
      set ar_types($el2) $el2 
    }
  }
  set all_types [lsort [array names ar_types]]
  log debug "all types: $all_types"
  # puts "\t[join $all_types "\t"]"
  foreach row $all_types {
    #puts -nonewline $row
    foreach col $all_types {
      # puts -nonewline "\t$ar_functions($row,$col)"
      try_eval {
        log debug "$row,$col => $ar_functions($row,$col)"
      } {
        log debug "$row,$col => UNKNOWN"
      }
    }
    #puts ""
  }
  
}

proc det_action_function {tp1 tp2} {
  global ar_functions
  set res action_undefined
  catch {set res $ar_functions($tp1,$tp2)}
  return $res  
}

# t: loc_type, d: loc_detail, f: folder, n: filename
proc delete_oldbackup {t1 d1 f1 n1 t2 d2 f2 n2} {
  delete_type oldbackup $t1 $d1 $f1 $n1 $t2 $d2 $f2 $n2
}

proc delete_extrabackup {t1 d1 f1 n1 t2 d2 f2 n2} {
  delete_type extrabackup $t1 $d1 $f1 $n1 $t2 $d2 $f2 $n2
}

proc delete_archive {t1 d1 f1 n1 t2 d2 f2 n2} {
  delete_type archive $t1 $d1 $f1 $n1 $t2 $d2 $f2 $n2
}

proc delete_type {type t1 d1 f1 n1 t2 d2 f2 n2} {
  if {$t1 == $type} {
    return "delete1" 
  } elseif {$t2 == $type} {
    return "delete2"
  } else {
    error "None of files is $type: $t1 $d1 $f1 $n1 $t2 $d2 $f2 $n2"  
  }
}

proc keep_both {t1 d1 f1 n1 t2 d2 f2 n2} {
  return "keepboth"
}  

# keep one if the details are the same, keep both (for now) if they are not the same.
proc keep_one {t1 d1 f1 n1 t2 d2 f2 n2} {
  if {$t1 == $t2} {
    if {$d1 == $d2} {
      # if one or both is .svn (or .git?), keep both
      if {[regexp {/\.svn/} "$f1 $f2"]} {
        return "keepboth" 
      }
      if {[regexp {/\.git/} "$f1 $f2"]} {
        return "keepboth" 
      }
      # keep the longest of the full path names
      if {[string length [file join $f1 $n1]] >= [string length [file join $f2 $n2]]} {
        return "delete2"
      } else {
        return "delete1" 
      }
    } else {
      return "keepboth" 
    }
  } else {
    return "undefined"; # location types should be the same. 
  }
}  


proc action_undefined {t1 d1 f1 n1 t2 d2 f2 n2} {
  return "undefined"
}

proc handle_action {f action id1 f1 n1 id2 f2 n2} {
  if {$action == "delete1"} {
    puts $f "# Delete: [file join $f1 $n1]"
    puts $f [join [list rm $id1 [file join $f1 $n1]] "\t"] 
  } elseif {$action == "delete2"} {
    puts $f "# Delete: [file join $f2 $n2]"
    puts $f [join [list rm $id2 [file join $f2 $n2]] "\t"] 
  } elseif {$action == "keepboth"} {
    puts $f "# Keep both files"
    puts $f [join [list keep $id1 $id2] "\t"]
  } elseif {$action == "move1"} {
    # handle_action $f "move1" $id1 $folder1 $filename1 0 $folder_new $filename1
    puts $f [join [list move $id1 $f1 $f2 $n1] "\t"]
  } else {
    puts $f "# Unknown action: $action, do nothing" 
  }
  # @todo make symlink of a cache file
}

proc handle_doubles {out_filename minsize limit} {
  global log

  set f [open $out_filename a]             
  set query "select f1.id id1, f1.folder folder1, f1.filename filename1, f1.filesize_int filesize1, f1.md5sum md5sum1, f1.loc_type lt1, f1.loc_detail ld1,
                    f2.id id2, f2.folder folder2, f2.filename filename2, f2.filesize_int filesize2, f2.md5sum md5sum2, f2.loc_type lt2, f2.loc_detail ld2 
             from files f1, files f2
             where f1.filesize_int > $minsize 
             and f1.filesize_int = f2.filesize_int
             and f1.md5sum = f2.md5sum
             and f1.id < f2.id
             and not exists (
               select 1
               from keep_doubles k
               where k.id1 = f1.id
               and   k.id2 = f2.id
             )
             limit $limit"
             
  $log debug "query: $query"

  #set res [db eval $query]
  #$log debug "res: $res"
  
  db eval $query {
    $log debug "handling query result: $filename1"
    # resultaten per rij in vars $id1 etc.
    puts $f "# File1: ($lt1/$ld1) [file join $folder1 $filename1]: $filesize1: $md5sum1"
    puts $f "# File2: ($lt2/$ld2) [file join $folder2 $filename2]: $filesize2: $md5sum2"

    if {$filename1 != $filename2} {
      puts $f "# WATCH OUT: Filenames differ, check if they are really the same!" 
    }
    if {[file join $folder1 $filename1] == [file join $folder2 $filename2]} {
      puts $f "# WATCH OUT: 2 entries pointing to the same file, deleting one from DB!\n"
      db eval "delete from files where id = $id2" 
      continue; # hier wel continue, al een newline toegevoegd.
    }

    set fn [det_action_function $lt1 $lt2]
    set action [$fn $lt1 $ld1 $folder1 $filename1 $lt2 $ld2 $folder2 $filename2]
    $log debug "function: $fn, action: $action"
    handle_action $f $action $id1 $folder1 $filename1 $id2 $folder2 $filename2
    puts $f "" ; # always a new line between entries.
  }
  close $f
}

proc handle_old_backups {out_filename minsize limit} {
  global log

  set f [open $out_filename a]             

  # distinct werkt vertragend, toch lijkt het beter dit in de DB op te lossen...
  set query "select distinct f1.id id1, f1.folder folder1, f1.filename filename1, f1.filesize_int filesize1, f1.md5sum md5sum1, f1.loc_type lt1, f1.loc_detail ld1
             from files f1, files f2
             where f1.filesize_int > $minsize 
             and f1.filesize_int = f2.filesize_int
             and f1.md5sum = f2.md5sum
             and f1.loc_type = 'oldbackup'
             and (f2.loc_type is null or f2.loc_type <> 'oldbackup') 
             limit $limit"
             
  $log debug "query: $query"

  #set res [db eval $query]
  #$log debug "res: $res"
  
  db eval $query {
    $log debug "handling query result: $filename1"
    # resultaten per rij in vars $id1 etc.
    puts $f "# File1: ($lt1/$ld1) [file join $folder1 $filename1]: $filesize1: $md5sum1"
    # puts $f "# File2: ($lt2/$ld2) [file join $folder2 $filename2]: $filesize2: $md5sum2"

    #set fn [det_action_function $lt1 $lt2]
    #set action [$fn $lt1 $ld1 $folder1 $filename1 $lt2 $ld2 $folder2 $filename2]
    # $log debug "function: $fn, action: $action"
    # handle_action $f $action $id1 $folder1 $filename1 $id2 $folder2 $filename2
    handle_action $f delete1 $id1 $folder1 $filename1 0 "" ""
    puts $f "" ; # always a new line between entries.
  }
  close $f
}

proc handle_old_backups_old {out_filename minsize limit} {
  global log

  set f [open $out_filename a]             

  set query "select f1.id id1, f1.folder folder1, f1.filename filename1, f1.filesize_int filesize1, f1.md5sum md5sum1, f1.loc_type lt1, f1.loc_detail ld1,
                    f2.id id2, f2.folder folder2, f2.filename filename2, f2.filesize_int filesize2, f2.md5sum md5sum2, f2.loc_type lt2, f2.loc_detail ld2 
             from files f1, files f2
             where f1.filesize_int > $minsize 
             and f1.filesize_int = f2.filesize_int
             and f1.md5sum = f2.md5sum
             and f1.loc_type = 'oldbackup'
             and (f2.loc_type is null or f2.loc_type <> 'oldbackup') 
             limit $limit"
             
  $log debug "query: $query"

  #set res [db eval $query]
  #$log debug "res: $res"
  
  db eval $query {
    $log debug "handling query result: $filename1"
    # resultaten per rij in vars $id1 etc.
    puts $f "# File1: ($lt1/$ld1) [file join $folder1 $filename1]: $filesize1: $md5sum1"
    # puts $f "# File2: ($lt2/$ld2) [file join $folder2 $filename2]: $filesize2: $md5sum2"

    if {$filename1 != $filename2} {
      puts $f "# WATCH OUT: Filenames differ, check if they are really the same!" 
    }

    set fn [det_action_function $lt1 $lt2]
    set action [$fn $lt1 $ld1 $folder1 $filename1 $lt2 $ld2 $folder2 $filename2]
    $log debug "function: $fn, action: $action"
    handle_action $f $action $id1 $folder1 $filename1 $id2 $folder2 $filename2
    puts $f "" ; # always a new line between entries.
  }
  close $f
}

# Heel specifiek bepaalde folders deleten.
proc delete_old {out_filename minsize limit} {
  set old_folders {
    "/media/nas/backups/DellPC/c-drive/Program Files/Common Files/Java"
    "/media/nas/backups/DellPC/c-drive/WINDOWS/Temp"   
    "/media/nas/backups/laptop-important/d/util"
    "/media/nas/backups/DellPC/c-drive/Program Files"
    "/media/nas/backups/laptop-important/d/MySQL"
    "/media/nas/backups/DellLaptop/d/Mijn documenten"
    "/media/nas/backups/laptop-important/d/perftoolset"
  }  
  foreach old_folder $old_folders {  
    delete_from_old_backups $old_folder $out_filename $minsize $limit
  }
}

proc delete_from_old_backups {folder_start out_filename minsize limit} {
  # global log
  set f [open $out_filename a]
  # set query [make_query_select1 "/media/nas/backups/DellPC/c-drive/Program Files/Common Files/Java" $minsize $limit]
  set query [make_query_select1 $folder_start $minsize $limit]
  db eval $query {
    log debug "handling query result: $filename1"
    # resultaten per rij in vars $id1 etc.
    puts $f "# File1: ($lt1/$ld1) [file join $folder1 $filename1]: $filesize1: $md5sum1"
    handle_action $f "delete1" $id1 $folder1 $filename1 0 "" ""
    puts $f "" ; # always a new line between entries.
  }  
  close $f
}

# limit of -1 means (to sqlite) no limit.
proc make_query_select1 {folder_start minsize limit} {
  return "select f1.id id1, f1.folder folder1, f1.filename filename1, f1.filesize_int filesize1, f1.md5sum md5sum1, f1.loc_type lt1, f1.loc_detail ld1
           from files f1
           where f1.filesize_int > $minsize 
           and f1.folder like '${folder_start}%'
           limit $limit" 
}

# ooutfile "/media/nas/backups/laptop-important/d/util/soapui-2.5" "/media/nas/archief/installed/soapui-2.5"
proc move_dir {out_filename minsize limit old_loc new_loc} {
  set f [open $out_filename a]
  set query [make_query_select1 $old_loc $minsize $limit]
  db eval $query {
    set folder_new "${new_loc}[string range $folder1 [string length $old_loc] end]"
    handle_action $f "move1" $id1 $folder1 $filename1 0 $folder_new $filename1
  }
  close $f
}  

proc log {args} {
  global log
  $log {*}$args
}

main $argv

# 1:move	673870	/media/nas/backups/laptop-important/d/util/soapui-2.5/source/soapui-2.5/src/test-resources/test3	/media/nas/archief/installed/soapui-2.5/source/soapui-2.5/src/test-resources/test3	readme.txt
# 1000: move	673638	/media/nas/backups/laptop-important/d/util/soapui-2.5/source/soapui-2.5/src/java/com/eviware/soapui/support/swing	/media/nas/archief/installed/soapui-2.5/source/soapui-2.5/src/java/com/eviware/soapui/support/swing	AbstractModelItemTableMouseListener.java

