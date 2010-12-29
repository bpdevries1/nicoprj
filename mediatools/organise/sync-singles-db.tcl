#!/home/nico/bin/tclsh

# 13-03-2010 Deze lijkt oud, werkt nog niet met groepen. Zie sync-music-db voor de goede/nieuwe.

# note: car-player snapt .m4a niet.
package require ndv
package require Tclx

source MusicSchemaDef.tcl

ndv::source_once [file join [file dirname [info script]] .. lib setenv-media.tcl]
ndv::source_once [file join [file dirname [info script]] .. lib libmusic.tcl]

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]

# ::ndv::CLogger::set_log_level_all debug
::ndv::CLogger::set_logfile music.log

proc main {argc argv} {
  global log db conn stderr argv0 log SINGLES_ON_SD
	$log info "Starting"

  set schemadef [MusicSchemaDef::new]
  set db [::ndv::CDatabase::get_database $schemadef]
  set conn [$db get_connection]

  $log debug "encoding: [::mysql::encoding $conn]"
  ::mysql::exec $conn "set names utf8"
  $log debug "set names utf8 gedaan"
  # 2 way check
  handle_filesystem
  handle_db

	$log info "Finished"
}

# check if files on filesystem are also in the database. If not, add them.
proc handle_filesystem {} {
  global db conn log env
  $log info "handle_filesystem"
  for_recursive_glob filename $env(MEDIA_SINGLES) *.mp3 {
    if {[file isdirectory $filename]} {
      continue 
    }
    set path_in_db [det_path_in_db $filename]
    if {[$db find_objects musicfile -path $path_in_db] == {}} {
      $log debug "not found in db: $path_in_db ($filename)" 
      if {[string is ascii $path_in_db]} {
        $log debug "insert in db:  $path_in_db ($filename)"
        $db insert_object musicfile -path $path_in_db -freq 1.0 -play_count 0 -file_exists 1
      } else {
        $log warn "not ascii, don't insert in db: $path_in_db ($filename)"
      }
    } else {
      # $log debug "found: $filename" 
    }
  }
}

# check if files in database are also on the filesystem. If not, delete from database, or warning.
proc handle_db {} {
  global db conn log
  $log info "handle_db"
  $log warn "handle_db: NOT IMPLEMENTED YET!"
}

main $argc $argv
