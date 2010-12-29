#!/home/nico/bin/tclsh
# Itcl en CLogger hier even niet, want kan package vanuit crontab niet vinden, en nu
# ook niet echt nodig.
# package require Itcl

# source [file join [file dirname [info script]] .. .. lib CLogger.tcl]
source [file join [file dirname [info script]] .. lib libmusic.tcl]

proc main {} {
	make_album_playlist
	make_singles_playlist
}

proc make_album_playlist {} {
	global env
	# set f [open [file join $env(MEDIA_PLAYLISTS) music.m3u] w]
	set playlist_filename [file join $env(MEDIA_PLAYLISTS) [det_playlist_name music]] 
  # eerst naar nieuw temp bestand schrijven
  set f [open "${playlist_filename}.temp" w]
	set nfiles [add_files $env(MEDIA_NEW) $f]
	# add_files $env(MEDIA_PARTIAL) $f
	set nfiles [expr $nfiles + [add_files $env(MEDIA_COMPLETE) $f]]
	close $f
  # dan met een bijna atomaire operatie naar de uiteindelijke file. Voorkomt halve files bij bv system shutdown.
  file delete $playlist_filename
  file rename "${playlist_filename}.temp" $playlist_filename
  
  set flog [open [file join $env(MEDIA_PLAYLISTS) maakm3u.log] a]
  puts $flog "[clock format [clock seconds]] Added $nfiles files"
  close $flog
}

proc make_singles_playlist {} {
	global env
	# set f [open [file join $env(MEDIA_PLAYLISTS) music.m3u] w]
	set f [open [file join $env(MEDIA_PLAYLISTS) [det_playlist_name singles]] w]
	add_files $env(MEDIA_SINGLES) $f
	close $f
}

# 8-11-2009 lsort toegevoegd: tracks in goede volgorde.
proc add_files {dir_name f} {
	set n 0
  foreach filename [lsort [glob -nocomplain -directory $dir_name -type f *]] {
		if {[include_file $filename]} {
			puts $f $filename
      incr n
		} elseif {[exclude_file $filename]} {
			# ignore file
		} else {
			puts stderr "Don't know what to do with: $filename (ext=[file extension $filename])"
		}
	}
	
	foreach subdir_name [glob -nocomplain -directory $dir_name -type d *] {
		incr n [add_files $subdir_name $f]
	}
  return $n
}

proc include_file {filename} {
	set ext [string tolower [file extension $filename]]
	if {[lsearch -exact {.mp3 .wma .mp4 .m4a .mpc .ogg .wav} $ext] > -1} {
		return 1
	} else {
		return 0
	}
}

proc exclude_file {filename} {
	set ext [string tolower [file extension $filename]]
	if {[lsearch -exact {.txt .jpg .mpg .mpeg .wmv .rar .doc .avi .zip 
											.qt .m3u .nfo .sfv .db .ini .out .pdf .htm .html .log
											.xls .tcl {} .swf .nra .x32 .bmp .url .exe .dat .cue 
											.gif .cda .inf .alb .wpl .asx .lnk .bkp .pls .bat .cmd .sh} $ext] > -1} {
		return 1
	} else {
		if {[string length $ext] > 5} {
			# lange extensie is eigenlijk geen extensie, dan ook niet opnemen.
			return 1
		} else {
			return 0
		}
	}
}

main


