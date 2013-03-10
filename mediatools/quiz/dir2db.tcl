#!/home/nico/bin/tclsh8.6

# read directory, put all music files in a SQLite database and prepare for (pub)quiz.

# package require sqlite3
package require tdbc::sqlite3
 
package require ndv

source ../lib/libmusic.tcl

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]
 
if {0} {
* sqlite maken + inlezen.
* hoe pad op te slaan, zodat je het aan amarok mee kunt geven.
  - in movetrack net andersom: lees huidige track, vertaal naar filesystem zodat je move kunt doen.
* dir_recursive functie gebruiken.

amarok "$MEDIA_PLAYLISTS/music-r.m3u" &

}

# @todo $conn meegeven aan handle_dir_rec

proc main {argv} {
  global conn stmt
  
  lassign $argv root_dir
  set db_name [file join $root_dir "[file tail $root_dir].db"]
  set conn [create_db $db_name]
  $conn begintransaction
  set stmt [$conn prepare "insert into track (path, nright, nwrong) values (:track, 0, 0)"]
  handle_dir_rec $root_dir "*" handle_file
  $conn commit
  $conn close
}

proc create_db {db_name} {
  file delete $db_name
  set conn [tdbc::sqlite3::connection create db $db_name]
  # tdbc::sqlite3::connection create db "/path/to/mydatabase.sqlite3"
  # sqlite3 db $db_name
  db_eval $conn "create table track (path, seconds, frames, nright, nwrong)"
  # also record which part of the track was played.
  db_eval $conn "create table track_test (path, ts, start_sec, stop_sec, result)"
  db_eval $conn "create table track_value (path, ts, value)"
  # evt nog indexen.
  
  return $conn
}

proc handle_file {path root_dir} {
  global log conn stmt
  if {[is_music_file $path]} {
    #set query "insert into track (path) values ('[file normalize $path]')" 
    #log debug $query
    log debug "inserting $path"
    # db eval $query
    $stmt execute [dict create track [file normalize $path]]
  }
}

proc db_eval {conn query} {
  set stmt [$conn prepare $query]
  $stmt execute
  $stmt close
}

main $argv
