#!/home/nico/bin/tclsh

# [2016-11-11 22:50] tclsh861 not yet in env when @reboot in crontab.
#!/usr/bin/env tclsh861

# #!/home/nico/bin/tclsh

package require ndv
package require Tclx
package require struct::list

# ::ndv::source_once ../db/MusicSchemaDef.tcl
::ndv::source_once [file join [file dirname [info script]] .. db MusicSchemaDef.tcl]
::ndv::source_once [file join [file dirname [info script]] .. lib libmusic.tcl]

# set log [::ndv::CLogger::new_logger [file tail [info script]] debug]
# set log [::ndv::CLogger::new_logger [file tail [info script]] info]

# [2016-11-17 21:25] wil bij deze geen subdir logs: dus ofwel expliciet aangeven, ofwel geen log.
set_log_global warn {filename /home/nico/log/music-monitor-tcl.log append 1}

proc main {argv} {
  # 14-1-2012 keep db and conn as global, their values can changes with a reconnect.
  global db conn stderr argv0 SINGLES_ON_SD
  # global log stderr argv0 SINGLES_ON_SD


  # 20-6-2015 np is also really used here, as in maak_album_playlist.tcl etc.
  set options {
    {np "Don't mark selected files as played in database"}
    {wait.arg "5000" "Polling interval in msec"}
    {debug "Show debug output"}
    {loglevel.arg "info" "Set loglevel for all (debug, info, ...)"}
  }
  set usage ": [file tail [info script]] \[options] :"
  set opt [getoptions argv $options $usage]
  array set ar_argv $opt 

  if {$ar_argv(loglevel) != ""} {
    ::ndv::CLogger::set_log_level_all $ar_argv(loglevel) 
  }
  
  db_connect_with_retry ; # post: db and conn have correct values.
 
  # monitor_loop $ar_argv(wait) $ar_argv(np)

  show_latest $opt
  

}

# show everything from today.
proc show_latest {opt} {
  global conn
  set today [clock format [clock seconds] -format "%Y-%m-%d"]
  set query "
select kind, datetime, path
from played p
join album a on a.generic = p.generic
where datetime >= '$today'

union

select kind, datetime, path
from played p
join musicfile m on m.generic = p.generic
where datetime >= '$today'

order by datetime
"
  set res [pg_query_dicts $conn $query]
  puts "Played today: $today"
  # puts "res: $res"
  foreach row $res {
    puts "[:kind $row]: [:datetime $row]: [:path $row]"
  }
}

proc monitor_loop {wait np} {
  global log db conn
  log info "Entering main loop"
  set prev_path ""
  while {1} {
    set_env_dbus;               # set env(DBUS_SESSION_BUS_ADDRESS) iff not set.
    if {[det_playing]} {
      set path [det_playing_path]
      if {$path != $prev_path} {
        set prev_path $path
        if {!$np} {
          mark_played $path
        } else {
          log debug "Don't mark as played in database (-np param): $path" 
        }
      }
    } else {
      log debug "det_playing: 0" 
    }
    # after $ar_argv(wait)
    after $wait
  }  
}

# [2016-11-17 22:25] Deze truc obv http://redmine.audacious-media-player.org/boards/1/topics/1581
# werkt bij gestarte sessie, en dan hierbinnen via crontab, wat eerder niet werkte.
# nog testen via @reboot. Deze zou als eerst sessie niet gezet is, of audacious niet gestart, nog niets moeten doen, en pas aan de slag nadat audacious gestart is.
proc set_env_dbus {} {
  global env
  set dbus_name DBUS_SESSION_BUS_ADDRESS
  if {[array names env $dbus_name] == ""} {
    set pid ""
    catch {set pid [exec pidof audacious]} msg
    log_once info "result of pidof audacious: $msg"
    log_once info "pid of audacious: $pid"
    if {$pid != ""} {
      # [2016-11-19 11:10] verwacht niet dat strings en grep fout gaan, dus deze voorlopig niet in catch.
      set res [exec strings /proc/$pid/environ | grep $dbus_name]
      if {[regexp {^(.+)=(.+)$} $res z nm val]} {
        set env($nm) $val
        log info "set env($nm) to $val"
      }
    }
  } else {
    log_once info "env already set: env($dbus_name) = $env($dbus_name)"
    # env already set, do nothing.
  }
}

proc mark_played {path} {
  global log db conn
  if {$path == ""} {
    # possible error in determining playing path.
    return
  }
  log debug "Mark as played in database: $path" 
  try_eval {
    # set lst_generic_ids [::mysql::sel $conn "select generic from musicfile where path = '[$db str_to_db [det_path_in_db $path]]'" -flatlist]
    set lst_generic_ids [det_generic_ids $db $conn $path] 
  } {
    log warn "DB error: $errorResult, trying again..."
    # 8-1-2011 possible db connection has timed out after idle, so reconnect
    # lassign [db_connect] db conn
    db_connect_with_retry
    # and try again. If it fails again, something else is wrong.
    set lst_generic_ids [det_generic_ids $db $conn $path]
  }

  if {$lst_generic_ids == {}} {
    log warn "Not found in DB: $path, inserting new record"
    lassign [det_realpath $path] realpath is_symlink    
    set generic_id [$db insert_object generic -gentype "musicfile" -freq 1.0 -play_count 0]
    set musicfile_id [$db insert_object musicfile -generic $generic_id \
                          -realpath $realpath -is_symlink $is_symlink \
                          -file_exists 1]
    
    set lst_generic_ids [list $generic_id]
  }
  ::ndv::music_random_update $db [list [list [lindex $lst_generic_ids 0] "" 0]] "played" "-tablemain generic -tableplayed played"
  
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
proc det_playing_old {} {
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

# audtool returns some strange exitcodes: only when playing returns 0 and paused
# returns 1 it is actually playing. Other options:
# Status        playing    paused
# -------------------------------
# not started   1          1
# playing       0          1
# paused        0          0
# stopped       1          1
#
proc det_playing {} {
  if {[exec_cmd_exitcode audtool --playback-playing] == 0} {
    if {[exec_cmd_exitcode audtool --playback-paused] == 1} {
      return 1
    }
  }
  return 0
}


proc exec_cmd_exitcode {args} {
  # [2016-11-17 21:35] don't puts to stdout, will end up in music-monitor.log, way too big then.
  try {
    set results [exec {*}$args]
    set status 0
    log_once info "No errors, exitcode=0"
  } trap CHILDSTATUS {results options} {
    log_once warn "results: $results"
    log_once warn "options: [clean_exec_options $options]"
    set status [lindex [dict get $options -errorcode] 2]
  }
  return $status
}

# [2016-11-17 21:54] remove pid from child process, after CHILDSTATUS
proc clean_exec_options {msg} {
  regsub {CHILDSTATUS \d+} $msg {CHILDSTATUS xxxxx} msg
  return $msg
}

# [2016-11-17 21:46] log a specific message only once, to prevent large log files.
set logged [dict create]
proc log_once {level msg} {
  global logged
  if {[dict exists $logged $msg]} {
    # nothing
  } else {
    log $level $msg
    dict set logged $msg 1
  }
}

proc det_playing_path_old {} {
  set res ""  
  try_eval {
    set res [exec qdbus org.kde.amarok /Player org.freedesktop.MediaPlayer.GetMetadata]  
  } {}
  if {[regexp {location: ([^\n]+)} $res z url]} {
    log debug "url: $url"
    url_to_filename $url  
  } else {
    return ""
  }
}

# pre - actually playing, so don't expect an error.
proc det_playing_path {} {
  set res ""  
  try_eval {
    # set res [exec qdbus org.kde.amarok /Player org.freedesktop.MediaPlayer.GetMetadata]
    set res [exec audtool --current-song-filename]
  } {}
  if {$res != ""} {
    if {[file exists $res]} {
      return $res
    } else {
      error "Got current-playing file, but does not exist: $res"
      
    }
  }
  return ""
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
      log info "Trying to connect to db"
      set res [db_connect]
      set ok 1
    } {
      log warn "connect failed: $errorResult"
      log info "trying again after 10 seconds"
      after 10000
    }
  }
  # return $res
}

# return list: [$db $conn]
proc db_connect {} {
  global db conn log
  set db [get_db_from_schemadef]
  log debug "before get_connection"
  set conn [$db get_connection]
  #log debug "before set names utf8"
  #::mysql::exec $conn "set names utf8"
  log debug "finished"
  # list $db $conn 
}

proc det_generic_ids {db conn path} { 
  pg_query_flatlist $conn "select generic from musicfile where path = '[$db str_to_db [det_path_in_db $path]]' or realpath = '[$db str_to_db $path]'"
}

main $argv

