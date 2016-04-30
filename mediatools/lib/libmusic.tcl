::ndv::source_once [file join [file dirname [info script]] .. db MusicSchemaDef.tcl]

proc is_music_file {pathname} {
	set ext [string tolower [file extension $pathname]]
	if {[lsearch -exact {.flac .mp3 .wma .mp4 .m4a .mpc .ogg .wav} $ext] > -1} {
		return 1
	} else {
		return 0
	}	
}

proc det_playlist_name {prefix} {
	global env
	set result [file join $env(MEDIA_PLAYLISTS) "${prefix}.m3u"]
	# OS envvar op linux niet bekend, daarom met catch. 
	catch {
		if {[regexp -nocase "windows" $env(OS)]} {
			# set result "${prefix}-windows.m3u"
			set result [file join $env(MEDIA_PLAYLISTS) "${prefix}-windows.m3u"]
		}
	}
	return $result
}

proc det_path_in_db {fs_path} {
  regsub -all {\\} $fs_path "/" fs_path
  # 17-1-2010 quotes en \ worden nu door database object afgehandeld.
  # regsub -all {'} $fs_path "''" fs_path
  if {[regexp {^/media/nas/(.*)$} $fs_path z path]} {
    set result $path
  } elseif {[regexp {^w:/(.*)$} $fs_path z path]} {
    set result $path
  } elseif {[regexp {^(media.*)$} $fs_path z path]} {
    set result $path   
  } else {
    # error "Could not determine relative path from: $fs_path"
    set result "<not found>"
  }
  return $result
}

proc get_db_from_schemadef {} {
  # $log debug "before MusicSchemaDef::new"  
  set schemadef [MusicSchemaDef::new]
  set f [open ~/.config/music/music-settings.json r]
  set text [read $f]
  close $f
  set d [json::json2dict $text]
  $schemadef set_db_name_user_password [:database $d] [:user $d] [:password $d]
  # $log debug "before get_db"
  # 14-1-2012 param 1=reconnect.
  set db [::ndv::CDatabase::get_database $schemadef 1]
  return $db
}
