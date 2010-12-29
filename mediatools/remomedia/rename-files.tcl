#!/home/nico/bin/tclsh
# #!/usr/bin/env tclsh deze doet raar.
# rename files based on artist and trackname

package require struct::list
package require ndv
# package require mp3info ; # deze is slecht: en geen artist/trackname, en bitrate en length kloppen vaak niet.

# source all C*.tcl files in the same dir
foreach filename [glob -directory [file dirname [info script]] C*.tcl] {
  source $filename 
}

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]

proc main {} {
  global db conn
  set db [CDatabase::get_database]
  set conn [$db get_connection]

  # fill_artist_track
  # rename_from_file
  # rename_to_file
  # rename_m4a
  # add_mp3_info
  # make_playlist
  # add_properties
  # remove_doubles
  remove_double_properties
}

# eenmalig gebruik?
proc rename_m4a {} {
  global db conn log
  set query "select id, path from musicfile where lower(path) like '%m4a'"
  set result [::mysql::sel $conn $query -list]
  foreach row $result {
    foreach {id path} $row break
    set new_name "[file rootname $path].mp3"
    puts "Renaming $path => $new_name"
    $db update_object musicfile $id -path [to_db_string $new_name]
  }
}

# nog een eenmalige?
proc rename_from_file {} {
  global db conn log
  set f [open filenames.txt r]
  while {![eof $f]} {
    gets $f line
    if {[regexp {^id: ([0-9]+)$} $line z val]} {
      set id [string trim $val] 
    } elseif {[regexp {^artist: (.+)$} $line z val]} {
      set artist [string trim $val]        
    } elseif {[regexp {^trackname: (.+)$} $line z val]} {
      set trackname [string trim $val]
      $log debug "Set musicfile $id to $artist - $trackname"
      $db update_object musicfile $id -artist [to_db_string $artist] -trackname [to_db_string $trackname]
      set id -1
      set artist "<bla>"
      set trackname "<bla>"
    }    
  }  
  close $f
}

proc rename_to_file {} {
  global db conn log
  set query "select id, path, artist, trackname from musicfile order by trackname, artist"
  set result [::mysql::sel $conn $query -list]
  set fo [open filenames.txt w]
  foreach row $result {
    foreach {id path artist trackname} $row break
    puts $fo "id: $id"
    puts $fo "path: $path"
    puts $fo "artist: $artist"
    puts $fo "trackname: $trackname"
    puts $fo "------------------"
    
  }  
  close $fo
  
}

proc fill_artist_track {} {
  global db conn log
  set query "select id, path from musicfile where artist is null and trackname is null"
  set result [::mysql::sel $conn $query -list]
  set fo [open filenames2.txt w]
  foreach row $result {
    foreach {id path} $row break
    foreach {artist trackname} [det_artist_track $path] break
    if {($artist != "") && ($trackname != "")} {
      $db update_object musicfile $id -artist [to_db_string $artist] -trackname [to_db_string $trackname]
    } else {
      $log debug "Empty artist/trackname: $artist --- $trackname ($path)"
      # $db update_object musicfile $id -artist "<unknown>" -trackname "<unknown>"
      write_filenames $fo $id $path
    }
  }
  close $fo
}

proc write_filenames {fo id path} {
  puts $fo "id: $id"
  puts $fo "path: $path"
  puts $fo "artist: [file root [file tail $path]]"
  puts $fo "trackname: [file root [file tail $path]]"
  puts $fo "------------------"
}

proc det_artist_track {path} {
  global log
  set basename [file rootname [file tail $path]]
  if {[regexp {^(.+) - (.+)$} $basename z art tit]} {
    if {[regexp {^[0-9]} $art]} {
      if {[regexp {^[0-9]{2}\. (.+)$} $art z art2]} {
        # standard structure of "01. artist - trackname"
        return [list $art2 $tit]
      } elseif {[regexp {^[0-9]{3} - (.+)$} $art z art2]} {
        return [list $art2 $tit]
      } elseif {[regexp {^100 Greatest Guitar Solos - [0-9]{3} - (.+)$} $art z art2]} {
        return [list $art2 $tit]
      } else {
        # possibly non-standard
        $log debug "Possibly non standard: $art --- $tit ($path)"
      }
    } else {
      return [list $art $tit] 
    }
  }
  # use amarok
  return [get_amarok_tags [det_linux_path $path]]
  if {0} {
    if {[string tolower [file extension $path]] == ".mp3"} {
      return [read_id3_tags [det_linux_path $path]]
    }
  }
  $log debug "Cannot determine artist/title for: $path"
  return [list "" ""]  
}

# maybe some timing issues.
proc get_amarok_tags {path} {
  global log
  # nu even niet
  return [list "" ""]
  exec dcop amarok player stop
  exec dcop amarok playlist clearPlaylist
  exec dcop amarok playlist addMedia "$path" 
  exec dcop amarok player play
  after 5000
  set artist [exec dcop amarok player artist]
  set title [exec dcop amarok player title]
  $log debug "Amarok info: $artist --- $title" 
  exec dcop amarok player stop
  exec dcop amarok playlist clearPlaylist
  after 1000
  return [list $artist $title]  
}

proc det_linux_path {db_path} {
  return [file join "/media/nas" $db_path] 
}

proc to_db_string {str} {
  regsub -all "'" $str "''" str
  return $str
}

proc add_mp3_info {} {
  global log db conn
  set query "select id, path from musicfile where bitrate is null"
  set result [::mysql::sel $conn $query -list]
  set fo [open file-info.txt w]
  foreach row $result {
    foreach {id db_path} $row break
    set path [det_linux_path $db_path]
    puts $fo $path
    if {[catch {set lst_info [get_musicfile_info $path]} res]} {
      puts $fo "error: $res"
      # $db update_object musicfile $id -seconds -1 -bitrate -1
      
    } else {
      puts $fo "=> $lst_info"
      array set ar_info $lst_info
      $db update_object musicfile $id -seconds $ar_info(seconds) -bitrate $ar_info(bitrate)
    }
    puts $fo "---------"
    flush $fo
  }
  close $fo
}

proc get_musicfile_info {path} {
  global log
  # nu even niet
  # return [list "" ""]
  exec dcop amarok player stop
  exec dcop amarok playlist clearPlaylist
  exec dcop amarok playlist addMedia "$path" 
  exec dcop amarok player play
  after 5000
  set seconds [exec dcop amarok player trackTotalTime]
  set bitrate [exec dcop amarok player bitrate]
  exec dcop amarok player stop
  exec dcop amarok playlist clearPlaylist
  after 1000
  $log debug "seconds: $seconds, bitrate: $bitrate"
  if {($seconds == 0) || ($bitrate == "?")} {
    error "seconds: $seconds, bitrate: $bitrate"
  } else {
    return [list seconds $seconds bitrate $bitrate]
  }
}

proc make_playlist {} {
  make_playlist_query "select m1.path, m2.path  
from musicfile m1, musicfile m2
where m1.artist = m2.artist
and m1.trackname = m2.trackname
and m1.bitrate > m2.bitrate
and m1.filesize < m2.filesize
order by m1.artist, m1.trackname, m1.bitrate"
}

proc make_playlist_query {query} {
  global log db conn
  set result [::mysql::sel $conn $query -list]
  set fo [open doubles.m3u w]
  foreach row $result {
    # foreach {db_path1 db_path2} $row break
    set db_path1 [lindex $row 0]
    set db_path2 [lindex $row 1]
    set path1 [det_linux_path $db_path1]
    set path2 [det_linux_path $db_path2]
    puts $fo $path1
    puts $fo $path2
  }
  close $fo 
}

proc add_properties {} {
  global log db conn
  set query "select id, path  
             from musicfile 
             order by path"
  set result [::mysql::sel $conn $query -list]
  foreach row $result {
    foreach {id db_path} $row break
    $log debug "path: $db_path"
    set lst_props [det_props_from_filename $db_path] ; # returns list: name1 value1 name2 value2 etc.
    foreach {name value} $lst_props {
      $log debug "=> $name = $value"
      $db insert_object property -musicfile $id -name [to_db_string $name] -value [to_db_string $value]
    }
  }
}

proc det_props_from_filename {db_path} {
  set result {}
  if {[regexp {[^0-9]([0-9]{4})[^0-9]} $db_path z year]} {
    if {($year >= 1950) && ($year <= 2020)} {
      lappend result year $year 
    }
  }
  if {[regexp {/Genres/([^/]+)/} $db_path z genre]} {
    lappend result genre $genre 
  }
  return $result
}

proc remove_doubles {} {
#   remove_doubles_query "select m1.id, m1.play_count, m2.id, m2.play_count, m2.path  
# from musicfile m1, musicfile m2
# where m1.artist = m2.artist
# and m1.trackname = m2.trackname
# and m1.filesize = m2.filesize
# and m1.path < m2.path"
  
  set query "select m1.path, m2.path, m1.id, m1.play_count, m2.id, m2.play_count  
from musicfile m1, musicfile m2
where upper(m1.artist) = upper(m2.artist)
and upper(m1.trackname) = upper(m2.trackname)
and m1.filesize >= m2.filesize
and m1.id <> m2.id
order by m1.artist, m1.trackname, m1.filesize, m2.filesize
"
  if {1} {
      make_playlist_query $query
  } else {
    remove_doubles_query $query
    recalc_play_count
  }
}

proc remove_doubles_query {query} {
  global log db conn
  set result [::mysql::sel $conn $query -list]
  foreach row $result {
    foreach {path1 path2 id1 pc1 id2 pc2} $row break
    combine_musicfiles $id1 $pc1 $id2 $pc2 [det_linux_path $path2] 
  }
}

proc combine_musicfiles {id_keep pc_keep id_del pc_del linux_path_del} {
  global db conn log
  $db update_object musicfile $id_keep -play_count [expr $pc_keep + $pc_del]
  set query "update played set musicfile = $id_keep where musicfile = $id_del"
  ::mysql::exec $conn $query
  set query "update property set musicfile = $id_keep where musicfile = $id_del"
  ::mysql::exec $conn $query
  set query "delete from musicfile where id = $id_del"
  ::mysql::exec $conn $query
  $log debug "deleting $linux_path_del"
  if {[file exists $linux_path_del]} {
    # file nog niet eerder verwijderd.
    set target_name [file join "/media/nas/_deleted" [file tail $linux_path_del]]
    if {[file exists $target_name]} {
      set target_name "$target_name.[expr rand()]" 
    }
    file rename $linux_path_del $target_name
  }
}

proc recalc_play_count {} {
  global db conn log
  set query "update musicfile
set play_count = (select count(*) from played where musicfile=musicfile.id)"
  ::mysql::exec $conn $query  
  
}

proc remove_double_properties {} {
  global db conn log
  set query "select p1.id, p2.id
             from property p1, property p2
             where p1.musicfile = p2.musicfile
             and p1.name = p2.name
             and p1.value = p2.value
             and p1.id < p2.id"
  set result [::mysql::sel $conn $query -list]
  foreach row $result {
    foreach {p1 p2} $row break
    set query "delete from property where id = $p2"
    ::mysql::exec $conn $query  
  }
             
}

main
