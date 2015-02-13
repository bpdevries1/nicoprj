#!/home/nico/bin/tclsh

package require Itcl
package require ndv

source [file join [file dirname [info script]] .. .. lib CLogger.tcl]
source [file join [file dirname [info script]] .. lib libmusic.tcl]

itcl::class CAlbumsChecker {

	private common log
	set log [::ndv::CLogger::new_logger [file tail [info script]] debug]
	
	private common RE_PARTIAL {\(.*partial.*\)} ; # partial somewhere between parenthesis
	private common RE_UNSORTED {\(.*unsorted.*\)} ; # unsorted somewhere between parenthesis
	private common RE_NOCHECK {CHECK-ALBUM: NOCHECK}
	private common RENAME_FILE "_rename-files-all.sh"
  
	public constructor {} {
		
	}
	
	private variable root_dir
	private variable f_rename
	
	public method check_albums {a_root_dir} {
		set root_dir $a_root_dir
		$log info "root-dir: $root_dir"
		set f_rename [open $RENAME_FILE w]
		foreach dirname [lsort [glob -nocomplain -directory $root_dir -type d *]] {
			handle_dir $dirname
		}
		close $f_rename
    make_executable $RENAME_FILE
		$log info "Finished"
	}

	private method handle_dir {dirname} {
		if {[regexp {^([^-]+) - (.+)$} $dirname z artist_dir album]} {
			file mkdir $artist_dir
			set album_dir [file tail $dirname]
			$log info "Moving $dirname => [file join $artist_dir $album_dir]"
			file rename $dirname [file join $artist_dir $album_dir]
			# exit
		} else {
			# puts "Not moving: $dirname"
			check_artist $dirname
		}
	}
	
	# @param artist_dir: fully qualified directory containing artist's albums
	private method check_artist {artist_dir} {
		# onder artist_dir niet direct files, alleen in subdirs
		set l [glob -nocomplain -type f -directory $artist_dir *]
		if {[llength $l] > 0} {
			$log warn "Warning: files directly under artist: $artist_dir"
		}
		
		# check albums onder artiest
		set lst_albums [glob -nocomplain -directory $artist_dir -type d *]
		if {[llength $lst_albums] == 0} {
			# puts "Warning: no albums under artist: $artist_dir"
			# puts "Deleting: $artist_dir"
			file delete $artist_dir
		}
		
		# alle albums onder artist_dir moeten beginnen met naam artist
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
		if {[string range $album 0 [expr [string length $artist] - 1]] != $artist} {
			$log warn "Warning: album doesn't start with artist: $album (artist = $artist)"
			# make it so
			$log info "Moving $path_album => [file join $artist_dir "$artist - $album"]"
			file rename $path_album [file join $artist_dir "$artist - $album"]
		}
		# onder album mogen alleen maar files zitten, niet ook nog subdirs
		set l [glob -nocomplain -type d -directory $path_album *]
		set l [filter_subdirs $l]
		if {[llength $l] > 0} {
			$log warn "Warning: subdirs under album: $path_album"
		}
		
		# onder album moeten wel files zitten
		if {[llength [glob -nocomplain -type f -directory $path_album *]] == 0} {
			$log warn "Warning: album doesn't contain any files: $path_album"
			# $log warn "Removing album: $path_album"
			# file delete $path_album
		} else {
			# det_complete hoeft niet als album RE_PARTIAL in de naam heeft
			if {[should_check_complete $path_album]} {	
				if {[det_complete $path_album ntracks]} {
					# ok, marked as complete and is complete
				} else {
					$log warn "Warning: album seems incomplete, use partial or unsorted: $path_album (ntracks = $ntracks)" 
					puts $f_rename "./rename-files.tcl \"$path_album\""
				}
			} else {
				# ok, duly noted, no extra check necessary
			}
		}
	}
	
	private method should_check_complete {path_album} {
		if {[regexp $RE_PARTIAL $path_album]} {
			return 0
		} 
		if {[regexp $RE_UNSORTED $path_album]} {
			return 0
		} 

		# check if there is a readme with a specific line
		set readme_name [file join $path_album readme.txt]
		if {[file exists $readme_name]} {
			set f [open $readme_name r]
			set found 0
			while {![eof $f]} {
				gets $f line
				if {[regexp $RE_NOCHECK $line]} {
					set found 1
				}
			}
			close $f
			return [expr !$found]
		} else {
			# no such file, return 1
			return 1
		}
	}
	
	# filter Covers-dir uit, deze mag voorkomen als subdir
	private method filter_subdirs {lst} {
		set result {}
		foreach el $lst {
      set ignore 0
      foreach re {Covers$ Lyrics$ art} {
        if {[regexp -nocase $re $el]} {
          set ignore 1
        }
      }
      if {!$ignore} {
        lappend result $el
      }
		}
		return $result
	}
	
	private method det_complete {path_album ntracks_name} {
		upvar $ntracks_name ntracks
		set is_ok 1
		set lst_index {}
		foreach filepath [glob -nocomplain -directory $path_album -type f *] {
			set filename [file tail $filepath]
			# normal track numbers, as well as 1-01 etc.
			if {[is_music_file $filepath]} {
				if {[regexp {^([0-9]+ ?((-|\.) ?[0-9]+)?)} $filename z index]} {
					regsub -all {\.} $index "-" index
					lappend lst_index $index
        } elseif {[regexp {[0-9]{2}} $filename z index]} {
          lappend lst_index $index
				} else {
					if {[regexp {track order unknown} $path_album]} {
						# it's ok, this album already marked.
					} else {
						$log warn "Trackname without index: $filepath"
						set is_ok 0
					}
				}
			} else {
				# geen music-file, niet boeiend.
			}
		}
		set ntracks [llength $lst_index]
		set lst_index [lsort $lst_index]
		set prev_index ""	
		foreach index $lst_index {
			if {$prev_index == ""} {
				# first item, nothing			
			} elseif {[follows $prev_index $index]} {
				# ok, nothing	
			} else {
				$log warn "$index doesn't follow $prev_index"
				set is_ok 0
			}
			set prev_index $index
		}
		return $is_ok
	}
	
	# @todo dit moet gemakkelijker kunnen, nu echt micro programmeren.
	# @param prev_index, index: could be a single index, or with a CD number, like 1-01. But also 1 - 01
	# @todo bug: if trackname starts with a number, it is included in the index here, like 02. 50 Watt.mp3 gives 02- 50 as index.
	# should determine for whole dir if album/cd numbers are used or not.
	private method follows {prev_index index} {
		if {[regexp {^([0-9]+) ?- ?([0-9]+)$} $prev_index z prev_album prev_track]} {
			if {[regexp {^([0-9]+) ?- ?([0-9]+)$} $index z album track]} {
				if {$prev_album == $album} {
					# same album, should be one more
					regsub -all {^0+} $prev_track "" prev_track
					regsub -all {^0+} $track "" track
					if {[expr $prev_track + 1] == $track} {
						return 1
					} else {
						return 0
					}
				} else {
					# next album, track should be 1
					regsub -all {^0} $track "" track
					if {$track == "1"} {
						return 1
					} else {
						return 0
					}
				}
			} else {
				return 0 ; # one with album, one without
			}
		} else {
			if {[regexp {^([0-9]+) ?- ?([0-9]+)$} $index z album track]} {
				return 0 ; # one with album, one without
			} else {
				# no album, should be one more
				regsub -all {^0+} $prev_index "" prev_index
				regsub -all {^0+} $index "" index
				if {[expr $prev_index + 1] == $index} {
					return 1
				} else {
					return 0
				}			
			}
		}
	}
	
  private method make_executable {filename} {
    exec chmod a+x $filename 
  }
  
}

proc main {argc argv} {
	global root_dir f_rename
	check_args $argc $argv
	# set root_dir [file normalize .]
	set root_dir [file normalize [lindex $argv 0]]
	set cac [CAlbumsChecker #auto]
	$cac check_albums $root_dir
}

proc check_args {argc argv} {
	global argv0 stderr
	if {$argc != 1} {
		puts stderr "Syntax: $argv0 <root-dir>; got: $argv"
		exit 1
	}
}




main $argc $argv
