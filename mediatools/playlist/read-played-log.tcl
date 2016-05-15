#!/usr/bin/env tclsh861

# [2016-05-15 20:52] one off to read music-played logfile in music-db.
# from now on music-monitor handles this directly.

package require ndv
package require Tclx
package require struct::list

# ::ndv::source_once ../db/MusicSchemaDef.tcl
::ndv::source_once [file join [file dirname [info script]] .. db MusicSchemaDef.tcl]
::ndv::source_once [file join [file dirname [info script]] .. lib libmusic.tcl]

# set log [::ndv::CLogger::new_logger [file tail [info script]] debug]
# set log [::ndv::CLogger::new_logger [file tail [info script]] info]
set_log_global info

proc main {argv} {
  set logfile_name {/home/nico/log/music-played.log}
  # set logfile_name {/home/nico/log/music-played-1.log}

  db_connect
  set f [open $logfile_name r]
  while {[gets $f line] >= 0} {
    # Played: [2016-05-14 18:59:28] /media/home.old/nico/media/tijdelijk2/Rihanna - Anti (Deluxe Edition) (2016)/16. Sex With Me.mp3
    if {[regexp {^Played: \[([0-9 :-]+)\] (.+)$} $line z ts_cet path]} {
      mark_played $ts_cet $path
    }
  }
  close $f
}

# bit different from version in music-monitor, as timestamp is a given here, not current time.
proc mark_played {ts_cet path} {
  global db conn
  set lst_generic_ids [det_generic_ids $db $conn $path]
  if {$lst_generic_ids == {}} {
    log warn "Not found in DB: $path, inserting new record"
    lassign [det_realpath $path] realpath is_symlink    
    set generic_id [$db insert_object generic -gentype "musicfile" \
                        -freq 1.0 -play_count 0]
    set musicfile_id [$db insert_object musicfile -generic $generic_id \
                          -realpath $realpath -is_symlink $is_symlink \
                          -file_exists 1]
  } else {
    set generic_id [:0 $lst_generic_ids]
  }
  $db update_object generic $generic_id -play_count "play_count+1"
  $db insert_object played -generic $generic_id -kind "played" -datetime $ts_cet
}

proc det_generic_ids {db conn path} { 
  pg_query_flatlist $conn "select generic from musicfile where path = '[$db str_to_db [det_path_in_db $path]]' or realpath = '[$db str_to_db $path]'"
}

# return list: [$db $conn]
proc db_connect {} {
  global db conn log
  set db [get_db_from_schemadef]
  log debug "before get_connection"
  set conn [$db get_connection]
  #$log debug "before set names utf8"
  #::mysql::exec $conn "set names utf8"
  log debug "finished"
  # list $db $conn 
}

main $argv
