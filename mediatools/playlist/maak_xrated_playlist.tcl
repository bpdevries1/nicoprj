#!/usr/bin/env tclsh861

# #!/home/nico/bin/tclsh

package require ndv
package require Tclx
package require struct::list

::ndv::source_once ../db/MusicSchemaDef.tcl
::ndv::source_once [file join [file dirname [info script]] .. lib libmusic.tcl]

# set SINGLES_ON_SD 150

# set log [::ndv::CLogger::new_logger [file tail [info script]] debug]
set_log_global info

proc main {argc argv} {
  global log db conn stderr argv0 dargv
	log info "Starting"

  set options {
    {n.arg "1" "Number of albums to select"}
    {pl.arg "music-r.m3u" "Filename of playlist"}
    {np "Don't mark selected files as played in database"}
  }
  set usage ": [file tail [info script]] \[options] :"
  # array set ar_argv [getoptions argv $options $usage]
  set dargv [getoptions argv $options $usage]
  
  set schemadef [MusicSchemaDef::new]

  set f [open ~/.config/music/music-settings.json r]
  set text [read $f]
  close $f
  set d [json::json2dict $text]
  $schemadef set_db_name_user_password [:database $d] [:user $d] [:password $d]
  
  set db [::ndv::CDatabase::get_database $schemadef]
  set conn [$db get_connection]

  # ::mysql::exec $conn "set names utf8"
  make_xrated_playlist [:pl $dargv]
  
	log info "Finished"
}

proc make_xrated_playlist {filename} {
  global dargv db conn
  log info "Opening $filename for writing"
  set f [open $filename w]
  set n [:n $dargv]
  set i 0
  set query "select a.generic, a.path, a.realpath
             from album a
             where (a.path like '%XRated%'
                     or a.realpath like '%XRated%')
             and (a.file_exists = 1 or a.file_exists is null)
             and not a.id in (
                 select m.album
                 FROM musicfile m
                 join played p on p.generic = m.generic
                 where m.path like '%XRated%'
                 )
             order by a.id desc"
  set res [pg_query_dicts $conn $query]
  foreach el $res {
    set nput [puts_album $f [:generic $el] [:path $el] [:realpath $el]]
    incr i $nput
    if {$i >= $n} {
      break
    }
    # break ; # sowieso nu voor test
  }
  close $f
}

# @return 1 is album found and at least 1 musicfile put in playlist, 0 otherwise.
proc puts_album {f generic_id db_path realpath} {
  global db conn dargv
  set res 0
  if {$realpath != ""} {
    if {[file exists $realpath]} {
      set path $realpath
    } else {
      set path [det_linux_path $db_path]
    }
  } else {
    set path [det_linux_path $db_path]    
  }

  log debug "path to play: $path"
  set lst [glob -nocomplain -directory $path -type f *]
  set lst2 [lsort [::struct::list filter $lst is_music_file]]
  foreach el $lst2 {
    puts $f $el 
  }
  if {$lst2 == {}} {
    if {[file exists $path]} {
      log warn "No music files found in dir. Other files:"
      log warn $lst
    } else {
      log warn "Directory $path does not exist in file system. Mark as not existing in DB."
      mark_exists album $generic_id 0
    }
  } else {
    log debug "At least one music file"
    mark_exists album $generic_id 1
    if {![:np $dargv]} {
      $db update_object generic $generic_id -play_count "play_count+1"
      $db insert_object played -generic $generic_id -kind "playlist" -datetime [now]
    }
    set res 1
  }
  return $res
}

proc mark_exists {table generic_id exists} {
  global db
  # table is album here.
  set query "update $table set file_exists = $exists where generic = $generic_id"
  $db exec_query $query
}

proc det_linux_path {db_path} {
  return [file join "/media/nas" $db_path] 
}

main $argc $argv

