#!/usr/bin/env tclsh86
package require Itcl
package require Tclx ; # for try_eval
package require ndv

source [file join [file dirname [info script]] .. .. lib CLogger.tcl]
source [file join [file dirname [info script]] .. lib libmusic.tcl]
source [file join [file dirname [info script]] .. .. lib generallib.tcl]
source [file join [file dirname [info script]] .. lib setenv-media.tcl]

proc main {argv} {
	global env argv0
  if {[:# $argv] != 0} {
    puts stderr "syntax: $argv0"
    exit 1
  }
  move_albums
}

proc move_albums {} {
  set staging_root "/media/nas/media/Music/_staging"
  set albums_root "/media/nas/media/Music/Albums"
  foreach artist_dir [glob -nocomplain -directory $staging_root -type d *] {
    move_artist $artist_dir $albums_root
  }
}

proc move_artist {artist_dir albums_root} {
  set dest_artist [file join $albums_root [file tail $artist_dir]]
  set dest_artist2 [artist_exists $dest_artist]
  if {$dest_artist2 != ""} {
    # artist-dir exists, so check per album
    set keep_album_dir 0
    foreach album_dir [glob -nocomplain -directory $artist_dir -type d *] {
      if {![move_album $album_dir $dest_artist2]} {
        set keep_album_dir 1
      }
    }
    if {!$keep_album_dir} {
      puts "Removing artist dir after moving all album dirs: $artist_dir"
      file delete $artist_dir
    }
  } else {
    # new artist, so move whole artist directory
    puts "New artist, so move all: $artist_dir => $dest_artist"
    file rename $artist_dir $dest_artist
  }
}

# param artist_full: full destination directory
# @todo make this working: check with/out the in front of artist name. Maybe also 'de' (eg De Dijk)
# @return empty string if artist not found in target dir, or full path of target-directory, with 'the' possibly added or removed.
proc artist_exists {artist_full} {
  if {[file exists $artist_full]} {
    return $artist_full
  }
  set artist [file tail $artist_full]
  if {[regexp -nocase {^the (.+)$} $artist z artist2]} {
    set artist_full2 [file join [file dirname $artist_full] $artist2]
    if {[file exists $artist_full2]} {
      return $artist_full2
    } else {
      return ""
    }
  } else {
    set artist_full2 [file join [file dirname $artist_full] "The $artist"]
    if {[file exists $artist_full2]} {
      return $artist_full2
    } else {
      return ""
    }
  }
}

proc move_album {album_dir dest_artist} {
  # set artist_album [file join [file tail [file dirname $album_dir]] [file tail $album_dir]]
  set album [file tail $album_dir]
  set dest_album [file join $dest_artist $album]
  if {[file exists $dest_album]} {
    puts "WARNING: destination album-dir already exists, so don't move: $dest_album"
    return 0
  } else {
    puts "Move album dir in existing artist dir: $dest_album"
    file rename $album_dir $dest_album
    return 1
  }
}

main $argv

