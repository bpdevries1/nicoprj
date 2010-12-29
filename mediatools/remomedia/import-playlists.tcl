# test database connection with perftoolset like CDatabase etc.

package require struct::list
package require ndv

# source all C*.tcl files in the same dir
foreach filename [glob -directory [file dirname [info script]] C*.tcl] {
  source $filename 
}

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]

proc main {} {
  global db conn
  set db [CDatabase::get_database]
  set conn [$db get_connection]
  handle_playlists_dir "/media/nas/media/Music/playlists/singles-played"
  if {0} {
    set mf [$db find_objects musicfile -id 1550]
    puts "musicfiles found: $mf"
    set pl [$db find_objects played -kind testje]
    puts "played found: $pl"
  }
}

proc handle_playlists_dir {dir_name} {
  foreach filename [glob -directory $dir_name *.m3u] {
    handle_playlist $filename 
  }
}

proc handle_playlist {filename} {
  global log db conn
  set dt_file [det_dt_file $filename]
  set f [open $filename r]
  while {![eof $f]} {
    gets $f line
    if {$line == ""} {continue}
    set path_in_db [det_path_in_db $line]
    # $log debug "Rel path: $path_in_db"
    set lst_mf_ids [$db find_objects musicfile -path $path_in_db]
    if {[llength $lst_mf_ids] == 0} {
      $log debug "new file: $path_in_db"
      set mf_id [$db insert_object musicfile -path $path_in_db -freq 1.0 -play_count 1 -file_exists 0]
    } else {
      $log debug "existing file: $path_in_db"
      set mf_id [lindex $lst_mf_ids 0]
      $db update_object musicfile $mf_id -play_count "play_count+1"
    }
    $db insert_object played -musicfile $mf_id -kind "sd-auto" -datetime $dt_file
  }
  
  close $f
}

proc det_path_in_db {line} {
  regsub -all {\\} $line "/" line
  regsub -all {'} $line "''" line
  if {[regexp {^/media/nas/(.*)$} $line z path]} {
    set result $path
  } elseif {[regexp {^w:/(.*)$} $line z path]} {
    set result $path
  } elseif {[regexp {^(media.*)$} $line z path]} {
    set result $path   
  } else {
    error "Could not determine relative path from: $line"
  }
  return $result
}

proc det_dt_file {filename} {
  # music-sd-2008-12-31-15-49-2.m3u 
  if {[regexp {music-sd-(.*).m3u} $filename z str]} {
    set lst [split $str "-"]
    # format %02d: minimaal 2 cijfers, bij year blijft het 4.
    set lst [::struct::list mapfor el $lst {format %02d $el}]
    foreach {yr mn day hr min sc} $lst break
    return "$yr-$mn-$day $hr:$min:$sc"
  } else {
    error "Could not determine datetime from: $filename" 
  }
}

main
