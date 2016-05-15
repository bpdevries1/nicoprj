#!/home/nico/bin/tclsh861

# 18-7-2015 called from root->nico, path is not known to tclsh861, so hardcoded above.
#!/usr/bin/env tclsh861

# #!/home/nico/bin/tclsh86

# 13-03-2010 deze lijkt vooral voor albums. Voor singles toch ook, zie sync_musicfile, regel 155. 

# note: car-player snapt .m4a niet.
package require ndv
package require Tclx
package require struct::list

source ../db/MusicSchemaDef.tcl
source [file join [file dirname [info script]] .. lib setenv-media.tcl]
source [file join [file dirname [info script]] .. lib libmusic.tcl]

#set log [::ndv::CLogger::new_logger [file tail [info script]] info]

# ::ndv::CLogger::set_log_level_all debug
# ::ndv::CLogger::set_logfile music.log
#$log set_file music.log

set_log_global info

proc main {argv} {
  global log db conn stderr argv0 log SINGLES_ON_SD dryrun
	$log info "Starting"

  set options {
    {dir.arg "/media/nas/media/Music/Albums" "Directory with subdirs to synchronise"}
    {dryrun "Don't actually change anything in the DB"}
    {loglevel.arg "" "Set global log level"}
  }
  set usage ": [file tail [info script]] \[options] :"
  set dargv [::cmdline::getoptions argv $options $usage]
  array set ar_argv $dargv
  if {$ar_argv(loglevel) != ""} {
    ::ndv::CLogger::set_log_level_all $ar_argv(loglevel)  
  }
  set dryrun [:dryrun $dargv]
  set schemadef [MusicSchemaDef::new]
  set f [open ~/.config/music/music-settings.json r]
  set text [read $f]
  close $f
  set d [json::json2dict $text]
  $schemadef set_db_name_user_password [:database $d] [:user $d] [:password $d]
  set db [::ndv::CDatabase::get_database $schemadef]
  set conn [$db get_connection]
  # repro_error $db
  # $log debug "encoding: [::mysql::encoding $conn]"
  # TODO vraag of hier ook een utf8 setting nodig is, zou default moeten zijn.
  # ::mysql::exec $conn "set names utf8"
  # $log debug "set names utf8 gedaan"
  
  fill_ar_ids
  
  handle_filesystem [file normalize $ar_argv(dir)] -1

	$log info "Finished"
}

# reproduce an error
proc repro_error {db} {
  global log
  $log info "repro_error: start"

  set path_in_db "media/Music/Albums/Carmen Consoli/Carmen Consoli - Dueparole"
  $db find_objects album -path $path_in_db
  $log info "Carmen done"

  set path_in_db "media/Music/Albums/Banco de Gaia/Banco de Gaia - Maya"
  $db find_objects album -path $path_in_db
  $log info "Banco done"
  
  set path_in_db "media/Music/Albums/Caro Emerald/Caro Emerald - Deleted Scenes From The Cutting Room Floor"
  $db find_objects album -path $path_in_db
  $log info "Caro done"

  exit 3
}

# put 4 items in global ar_ids for Artists, Albums, Singles and Musicfiles,
# which are groups.
proc fill_ar_ids {} {
  global db conn log ar_ids
  upsert_group Artists
  upsert_group Albums
  upsert_group Singles
  upsert_group Musicfiles
}

proc upsert_group {name} {
  global db conn log ar_ids
  set lst_ids [$db find_objects mgroup -name $name]
  if {$lst_ids == {}} {
    set ar_ids($name) [$db insert_object mgroup -name $name]
  } else {
    set ar_ids($name) [lindex $lst_ids 0] 
  }
}

# Also called recursively
# [2016-05-15 14:43] TODO: also check which albums are already in the DB, and if they still exist.
proc handle_filesystem {dir artist_id} {
  global db conn log ar_ids dryrun

  # 20-6-2015 NdV per dir in a DB trans should be possible.
  $db in_trans {
    # this dir
    # it's an artist iff directly under Albums
    if {[regexp {/Albums/[^/]+$} $dir]} {
      set artist_id [upsert_artist $dir] 
    }
    # it's an album if it has 1 or more musicfiles directly in it.
    set lst_files [lsort [glob -nocomplain -directory $dir -type f *]]
    set lst_files [::struct::list filter $lst_files is_music_file]
    if {$lst_files != {}} {
      set album_id [upsert_album $dir $artist_id] 
    }
    
    set lst_dir_db [det_lst_dir_db $dir]
    # $log debug "lst_dir_db: $lst_dir_db"
    # files in this dir
    foreach filename $lst_files {
      sync_musicfile $filename $artist_id $album_id lst_dir_db
    }
    if {[llength $lst_dir_db] > 0} {
      $log warn "db list not empty yet: $lst_dir_db, probably old items in DB. Remove them"
      foreach el $lst_dir_db {
        remove_db_record $el
      }
    }
  }
  
  # subdirs
  foreach subdir [glob -nocomplain -directory $dir -type d *] {
    handle_filesystem $subdir $artist_id
  }
}

# @result list of files directly in dir (not in subdirs), according to database
# @note de 'like' geeft ook files in subdirs van deze dir, ongewenst, want ook niet bij filesystem.
# @note de parent dir wordt niet (altijd) opgeslagen, kan niet veld 'album' gebruiken.
# @note dus ofwel in de query, ofwel een nabewerking met filter. Met query/regexp kan misschien, maar lijkt lastig, alle tekens moeten dan escaped worden.
# @note doe eerst maar een tcl filter
# @todo det_lst_dir_db genereert als tussen resultaat bij de root-dir heel veel files, eigenlijk ongewenst. Maar perf valt nu (10-4-2010 NdV) nog reuze mee (2 sec en 2 minuten).
proc det_lst_dir_db {dir} {
  global db conn log ar_ids
  set str_db [$db str_to_db [det_path_in_db $dir]]
  # 10-4-2010 NdV slash toegevoegd aan query, want anders ook files die in parent dir zitten en met dezelfde string beginnen (bv motorcycle).
  set query "select id, path, generic from musicfile
             where path like '$str_db/%'
             and file_exists = 1
             order by path"
  # 10-4-2010 NdV kan er niet op vertrouwen dat order by altijd dezelfde volgorde kiest als tcl lsort, bv met hoofd en kleine letters. Collating misschien ook anders.
  # volgorde is met deze 'balanced line' essentieel.
  # met filter alle files die in subdirs staan, eruit halen.
  set nstrdb [string length $str_db]
  $log debug "before filter, str_db: $str_db (#$nstrdb)"
  
  set result [pg_query_list $conn $query]
  $log debug "[lrange [struct::list mapfor el $result {
    string range [lindex $el 1] $nstrdb+1 end
  }] 0 5]"
  return [lsort -index 1 [::struct::list filterfor el $result {
    [regexp {/} [string range [lindex $el 1] $nstrdb+1 end]] == 0
  }]]
}

proc upsert_artist {dir} {
  global db conn log ar_ids dryrun
  $log debug "Upserting artist: $dir"
  set path_in_db [det_path_in_db $dir]
  set lst_ids [$db find_objects artist -path $path_in_db] 
  if {$lst_ids == {}} {
    # $log debug "not found in db: $path_in_db ($dir)"
    if {$dryrun} {
      $log info "Dryrun, not upserting artist: $dir"
      set gen_id -2
      set artist_id -2
    } else {
      set gen_id [$db insert_object generic -gentype "artist" -freq 1.0 -play_count 0]
      set artist_id [$db insert_object artist -generic $gen_id -path $path_in_db -name [file tail $path_in_db]]
      $db insert_object member -mgroup $ar_ids(Artists) -generic $gen_id
    }
  } else {
    set artist_id [lindex $lst_ids 0]
  }    
  return $artist_id
}

# @param artist_id can be -1, then leave empty in DB.
proc upsert_album {dir artist_id} {
  global db conn log ar_ids dryrun
  $log debug "Upserting album: $dir"
  set path_in_db [det_path_in_db $dir]
  set lst_ids [$db find_objects album -path $path_in_db] 
  if {$lst_ids == {}} {
    # $log debug "not found in db: $path_in_db ($dir)"
    if {$dryrun} {
      $log info "Dryrun, don't upsert_album: $dir ($artist_id)"
      set gen_id -2
      set album_id -2 
    } else {
      set gen_id [$db insert_object generic -gentype "album" -freq 1.0 -play_count 0]
      set artist_part ""
      if {$artist_id != -1} {
        set artist_part [list -artist $artist_id]
      }
      lassign [det_realpath $dir] realpath is_symlink
      set album_id [$db insert_object album -generic $gen_id -path $path_in_db \
                        -name [file tail $path_in_db] {*}$artist_part \
                        -realpath $realpath -is_symlink $is_symlink]
      # TODO: onderstaande weg. [2016-05-15 14:18] 
      if 0 {
        if {$artist_id == -1} {
          set album_id [$db insert_object album -generic $gen_id -path $path_in_db -name [file tail $path_in_db]]
        } else {
          set album_id [$db insert_object album -generic $gen_id -path $path_in_db -name [file tail $path_in_db] -artist $artist_id]
        }
      }
      $db insert_object member -mgroup $ar_ids(Albums) -generic $gen_id
    }
  } else {
    # album already found in DB
    set album_id [lindex $lst_ids 0]
    update_realpath album $album_id $dir
  }    
  return $album_id
}


# [2016-05-15 16:38] TODO: deze zou later niet meer nodig moeten zijn, als het bij insert steeds gevuld wordt.
proc update_realpath {table id path} {
  global db
  lassign [det_realpath $path] realpath is_symlink
  set query "update $table set realpath='[$db str_to_db $realpath]',
             is_symlink=$is_symlink
             where id=$id
             and realpath is null"
  log debug "query: $query"
  $db exec_query $query
}

# @param artist_id can be -1, then leave empty in DB.
# @todo fill trackname and artistname, based on filename? Or keep this in separate script?
# @note 10-4-2010 use a 'balanced line', compare db-list with filesystem-list.
# @return id of musicfile, either just inserted or existing one.
proc sync_musicfile {filename artist_id album_id lst_dir_db_name} {
  global db conn log ar_ids dryrun
  upvar $lst_dir_db_name lst_dir_db
  $log debug "Upserting musicfile: $filename"
  set path_in_db [det_path_in_db $filename]
  $log debug "Comparing fs: $path_in_db <=> db: [lindex $lst_dir_db 0 1]" 
  if {$path_in_db == [lindex $lst_dir_db 0 1]} {
    # db en filesys komen overeen, shift db lijst
    set el [::struct::list shift lst_dir_db] ; # remove (pop) first element.
    update_realpath musicfile [lindex $el 0] $filename
    return [lindex $el 0]
  } else {
    # 2 mogelijkheden: ofwel extra record in db, ofwel nieuwe file in filesystem
    if {([llength $lst_dir_db] == 0) || ($path_in_db < [lindex $lst_dir_db 0 1])} {
      # nieuwe file
      $log info "New file, add to database: $filename (path_in_db: $path_in_db)"
      if {1} {
        if {$dryrun} {
          $log info "Dryrun, don't upsert musicfile: $filename"
          set gen_id -2
          set musicfile_id -2
        } else {
          # TODO: toch eerst check of de realpath mss al bestaat, dan deze gebruiken.
          set musicfile_id [upsert_musicfile $artist_id $album_id $filename]
        }
        # lst_dir_db nu niet aanpassen
      } else {
        $log warn "Don't do anything now"
        set musicfile_id -1 
        exit 1
      }
    } else {
      # extra element in database, zou weg mogen
      $log warn "Record in db does not exist in filesystem, remove from db: [lindex $lst_dir_db 0]"
      remove_db_record [lindex $lst_dir_db 0]
      # exit 2
      # db lijst aanpassen en opnieuw proberen.
      ::struct::list shift lst_dir_db
      # 29-9-2010 blijkbaar recursief opnieuw proberen.
      return [sync_musicfile $filename $artist_id $album_id lst_dir_db]
      # return $musicfile_id      
    }
  }
  return $musicfile_id
}

# @pre filename does not occur as such in db.
# @return musicfile_id, either a new one or a found one.
# check if it exists under realpath. If so, update, otherwise, insert.
proc upsert_musicfile {artist_id album_id filename} {
  global db conn ar_ids
  set path_in_db [det_path_in_db $filename]
  lassign [det_realpath $filename] realpath is_symlink

  set lst_ids [$db find_objects musicfile -realpath $realpath]
  set query "select id,generic from musicfile where realpath = '[$db str_to_db $realpath]'"
  log info "query: $query"
  set res [pg_query_dicts $conn $query]

  if {$artist_id != -1} {
    set artist_part "-artist $artist_id"
  } else {
    set artist_part ""
  }

  if {[:# $res] > 0} {
    # found existing musicfile: generic ready should already exist, update fields
    # in musicfile
    log debug "res: $res"
    set musicfile_id [:id [:0 $res]]
    set generic_id [:generic [:0 $res]]
    log debug "musicfile_id: $musicfile_id"
    
    $db update_object musicfile $musicfile_id {*}$artist_part -album $album_id \
        -path $path_in_db -file_exists 1
  } else {
    # completely new file
    set generic_id [$db insert_object generic -gentype "musicfile" \
                        -freq 1.0 -play_count 0]
    log debug "Insert new musicfile with $realpath and $is_symlink"
    set musicfile_id [$db insert_object musicfile -generic $generic_id \
                          -path $path_in_db -album $album_id {*}$artist_part \
                          -realpath $realpath -is_symlink $is_symlink]
  }
  $db insert_object member -mgroup $ar_ids(Musicfiles) -generic $generic_id
  if {[regexp "/Music/Singles/" $filename]} {
    $db insert_object member -mgroup $ar_ids(Singles) -generic $generic_id
  }
  return $musicfile_id
}

# [2016-05-15 14:49] Only mark record as deleted, don't delete.
# reason: file might be moved, and played info is still interesting.
# this one still specific for musicfile now.
proc remove_db_record {db_record} {
  global conn log dryrun
  lassign $db_record id path generic
  set query "update musicfile set file_exists = 0 where id = $id"
  $log debug "remove_db_record: $db_record"
  if {$dryrun} {
    $log info "Dryrun, don't exec: $query"
  } else {
    pg_query $conn $query
  }
}

main $argv

