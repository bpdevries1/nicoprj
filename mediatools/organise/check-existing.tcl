#!/home/nico/bin/tclsh

# [2013-01-13 13:55:35] dit script even onduidelijk waar het voor is, met show-tijdelijk iig tijdelij en albums te zien.

package require Itcl
# [2013-01-13 13:51:04] use package ndv
package require ndv

source [file join [file dirname [info script]] .. .. lib CLogger.tcl]
source [file join [file dirname [info script]] .. lib libmusic.tcl]

itcl::class CCheckExisting {

	private common log
	set log [CLogger::new_logger [file tail [info script]] debug]
	
	private common ALBUMS_ROOT "/media/nas/media/Music/Albums"
	
	public constructor {} {
		
	}
	
	private variable root_dir
	
	public method check_albums {a_root_dir} {
		set root_dir $a_root_dir
		$log info "root-dir: $root_dir"
		foreach dirname [lsort [glob -directory $root_dir -type d *]] {
			handle_dir $dirname
		}
		$log info "Finished"
	}

	private method handle_dir {dirname} {
		check_artist $dirname
	}
	
	# @param artist_dir: fully qualified directory containing artist's albums
	private method check_artist {artist_dir} {
		# check albums onder artiest
		set lst_albums [glob -nocomplain -directory $artist_dir -type d *]
		
		foreach album $lst_albums {
			check_album $artist_dir $album
		}
	}
	
	private method check_album {artist_dir path_album} {
		# global root_dir f_rename
		# puts "Checking album: $path_album"
		
		# string range: start bij 0, is inclusive
		set artist [file tail $artist_dir]
		set album [file tail $path_album]

		is_existing_album $artist $album
		# @todo should delete here if existing?
	}
	
	private method is_existing_album {artist album} {
		set albums_dir [file join $ALBUMS_ROOT $artist $album]
		if {[file exists $albums_dir]} {
			$log warn "Album directory exists: $albums_dir"
			set result 1
		} else {
			set result 0
		}
		return $result
	}
	
}

proc main {argc argv} {
	global root_dir f_rename
	check_args $argc $argv
	# set root_dir [file normalize .]
	set root_dir [file normalize [lindex $argv 0]]
	set cce [CCheckExisting #auto]
	$cce check_albums $root_dir
}

proc check_args {argc argv} {
	global argv0 stderr
	if {$argc != 1} {
		puts stderr "Syntax: $argv0 <root-dir>; got: $argv"
		exit 1
	}
}




main $argc $argv
