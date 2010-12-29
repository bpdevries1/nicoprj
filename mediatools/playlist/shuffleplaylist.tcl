#!/home/nico/bin/tclsh
# shuffleplaylist.tcl - shuffle all items in a M3U playlist, but do this
# on a per album basis.
#
# 26-12-2007 bij sommige artiesten veel meer albums, deze komen dan vaker aan de
# beurt. Wil nu eerst de artiest bepalen, dan een album hierbij, zodat artiesten met
# maar 1 album ook aan de beurt komen, en niet continu muziek van Neil Young, Gieco etc.

# maximum aantal dirs in playlist (voor performance winamp)
# ar_dirs(<rnd-artist>,<rnd-album>) => lst_files

package require Itcl

source [file join [file dirname [info script]] .. .. lib CLogger.tcl]
source [file join [file dirname [info script]] .. .. lib random.tcl]
source [file join [file dirname [info script]] .. lib libmusic.tcl]

set TRESHOLD 20 ; # 20 albums in playlist or on SD is enough
set TRESHOLD_SINGLES 200 ; # 200 singles in playlist or on SD is enough

proc main {argc argv} {
	if {$argc == 0}  {
		shuffle_playlist_albums		
	} else {
		set what [lindex $argv 0]
		if {$what == "singles"} {
			shuffle_playlist $what
		}
	}
}

proc shuffle_playlist_albums {} {
	global ar_dirs TRESHOLD
	
	set prev_dir "<unknown>"
	set prev_artist "<unknown>"
	set rnd_artist "<unknown>"
	set lst_files {}
	while {![eof stdin]} {
		gets stdin line
		set dir [file dirname $line]
		if {$dir != $prev_dir}	{
			# handle previous dir
			putdir $rnd_artist $lst_files
			set lst_files {}
			set prev_dir $dir

			# and then determine artist of the new dir.
			set artist [det_artist $dir]
			if {$artist != $prev_artist} {
				set rnd_artist [get_random]
				log "nieuwe artist: $artist, rnd = $rnd_artist"
				set prev_artist $artist
			} else {
				log "dezelfde artist: $artist, rnd = $rnd_artist"
			}
		} 
		lappend lst_files $line
	}

	puts_list $TRESHOLD

}

proc puts_list {treshold} {
	global ar_dirs
	
	set n 1
	set prev_rnd_artist "<unknown>"
	foreach el [lsort [array names ar_dirs]] {
		regexp {^([^,]+)} $el z rnd_artist
		if {$rnd_artist != $prev_rnd_artist} {
			set lst_files $ar_dirs($el)
			foreach filename $lst_files {
				puts $filename	
			}
			incr n
			if {$n > $treshold} {
				break
			}
			set prev_rnd_artist $rnd_artist
		} else {
			# still the same artist, don't use this album/dir
		}
	}
	
}

proc det_artist {dirname} {
	global stderr
	if {[regexp {^([^-]+)} [file tail $dirname] z artist]} {
		return $artist
	} else {
		puts stderr "something very wrong here: $dirname"
		exit 1
	}
}

# lst_files: list of filenames (lines in M3U list)
proc putdir {rnd_artist lst_files} {
	global ar_dirs
	set rnd_album [get_random]
	set ar_dirs($rnd_artist,$rnd_album) $lst_files
	log "putdir: $rnd_artist,$rnd_album => [lindex $lst_files 0]"
}

set LOG 0
proc log {str} {
	global stderr LOG
	if {$LOG} {
		puts stderr $str
	}
}

# @param what: points to input-file: /media/nas/media/Music/playlists/what.m3u or what-windows.m3u
# @todo determine if shuffle should be done on a per album or a per track basis. Now always per track.
proc shuffle_playlist {what} {
	global TRESHOLD_SINGLES
	
	set playlist_name [det_playlist_name $what]
	set fi [open $playlist_name r]
	while {![eof $fi]} {
		gets $fi line
		putdir [get_random] [list $line]
	}
	close $fi
	puts_list $TRESHOLD_SINGLES
}

# use another random number generator.
srandom [clock seconds]
proc get_random {} {
  global RANDOM_MAX
  # return [expr 1.0 * [random] / $RANDOM_MAX]
  return [random] ; # no need to make it between 0 and 1 here
  # return [expr rand()]
}

main $argc $argv
