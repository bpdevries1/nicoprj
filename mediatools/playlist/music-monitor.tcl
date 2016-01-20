#!/usr/bin/env tclsh861

# #!/home/nico/bin/tclsh

package require ndv
package require Tclx
package require struct::list

# ::ndv::source_once ../db/MusicSchemaDef.tcl
::ndv::source_once [file join [file dirname [info script]] .. db MusicSchemaDef.tcl]
::ndv::source_once [file join [file dirname [info script]] .. lib libmusic.tcl]

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]
# set log [::ndv::CLogger::new_logger [file tail [info script]] info]

proc main {argc argv} {
  # 14-1-2012 keep db and conn as global, their values can changes with a reconnect.
  global log db conn stderr argv0 SINGLES_ON_SD
  # global log stderr argv0 SINGLES_ON_SD
	$log info "Starting"

  # 20-6-2015 np is also really used here, as in maak_album_playlist.tcl etc.
  set options {
    {np "Don't mark selected files as played in database"}
    {wait.arg "5000" "Polling interval in msec"}
    {loglevel.arg "info" "Set loglevel for all (debug, info, ...)"}
  }
  set usage ": [file tail [info script]] \[options] :"
  array set ar_argv [::cmdline::getoptions argv $options $usage]

  if {$ar_argv(loglevel) != ""} {
    ::ndv::CLogger::set_log_level_all $ar_argv(loglevel) 
  }
  
  db_connect_with_retry ; # post: db and conn have correct values.
 
  monitor_loop $ar_argv(wait) $ar_argv(np)
  
	$log info "Finished" ; # should never be reached.
}

proc monitor_loop {wait np} {
  global log db conn
  $log info "Entering main loop"
  set prev_path ""
  while {1} {
    if {[det_playing]} {
      set path [det_playing_path]
      if {$path != $prev_path} {
        set prev_path $path
        if {!$np} {
          mark_played $path
        } else {
          $log debug "Don't mark as played in database (-np param): $path" 
        }
      }
    } else {
      $log debug "det_playing: 0" 
    }
    # after $ar_argv(wait)
    after $wait
  }  
}

proc mark_played {path} {
  global log db conn
  if {$path == ""} {
    # possible error in determining playing path.
    return
  }
  $log debug "Mark as played in database: $path" 
  try_eval {
    # set lst_ids [::mysql::sel $conn "select generic from musicfile where path = '[$db str_to_db [det_path_in_db $path]]'" -flatlist]
    set lst_ids [det_ids $db $conn $path] 
  } {
    $log warn "DB error: $errorResult, trying again..."
    # 8-1-2011 possible db connection has timed out after idle, so reconnect
    # lassign [db_connect] db conn
    db_connect_with_retry
    # and try again. If it fails again, something else is wrong.
    set lst_ids [det_ids $db $conn $path]
  }
  if {$lst_ids == {}} {
    $log warn "Not found in DB: $path"
    add_to_logfile $path
  } else {
    ::ndv::music_random_update $db [list [list [lindex $lst_ids 0] "" 0]] "played" "-tablemain generic -tableplayed played"
  }          
}

proc add_to_logfile {path} {
  set f [open "/home/nico/log/music-played.log" a]
  puts $f "Played: [clock format [clock seconds] -format "\[%Y-%m-%d %H:%M:%S\]"] $path"
  close $f
}

# evt onderstaande gebruiken, 2x na elkaar, kijk of position anders is.
# org.freedesktop.MediaPlayer.PositionGet
# GetStatus
# qdbus --literal org.kde.amarok /Player GetStatus
# [Argument: (iiii) 1, 0, 0, 0] -> paused, allemaal 0 is playing.
proc det_playing {} {
  try_eval {  
    set res [exec qdbus --literal org.kde.amarok /Player GetStatus]
    if {[regexp {Argument: \(iiii\) 0, 0, 0, 0} $res]} {
      return 1 
    }
  } {
    # amarok probably not started (yet).
  }
  return 0
}

proc det_playing_old {} {
  try_eval {  
    set res [exec dcop amarok player isPlaying]
    if {$res == "true"} {
      return 1 
    }
  } {
    # amarok probably not started (yet).
  }
  return 0
}

proc det_playing_path {} {
  set res ""  
  try_eval {
    set res [exec qdbus org.kde.amarok /Player org.freedesktop.MediaPlayer.GetMetadata]  
  } {}
  if {[regexp {location: ([^\n]+)} $res z url]} {
    puts "url: $url"
    url_to_filename $url  
  } else {
    return ""
  }
}

proc url_to_filename {url} {
  if {[regexp {^file://(.+)$} $url z filename]} {
    set filename [encoding convertfrom utf-8 [url_decode $filename]]
  } else {
    error "Cannot convert to filename: $url" 
  }
  return $filename
}

# from http://wiki.tcl.tk/14144
proc url_decode str {
    # rewrite "+" back to space
    # protect \ from quoting another '\'
    set str [string map [list + { } "\\" "\\\\"] $str]

    # prepare to process all %-escapes
    regsub -all -- {%([A-Fa-f0-9][A-Fa-f0-9])} $str {\\u00\1} str

    # process \u unicode mapped chars
    return [subst -novar -nocommand $str]
}

proc det_playing_path_old {} {
  return [exec dcop amarok player path] 
}

# 14-1-2012 long runnning app, so db connection may go away; thus a reconnect may be necessary.
proc db_connect_with_retry {{max_try 3}} {
  global log
  set ok 0
  set res "nil"
  set i 0
  while {!$ok && ($i < $max_try)} {
    incr i
    try_eval {
      $log info "Trying to connect to db"
      set res [db_connect]
      set ok 1
    } {
      $log warn "connect failed: $errorResult"
      $log info "trying again after 10 seconds"
      after 10000
    }
  }
  # return $res
}

# return list: [$db $conn]
proc db_connect {} {
  global db conn log
  set db [get_db_from_schemadef]
  $log debug "before get_connection"
  set conn [$db get_connection]
  #$log debug "before set names utf8"
  #::mysql::exec $conn "set names utf8"
  $log debug "finished"
  # list $db $conn 
}

proc det_ids {db conn path} { 
  pg_query_flatlist $conn "select generic from musicfile where path = '[$db str_to_db [det_path_in_db $path]]'"
}

main $argc $argv

