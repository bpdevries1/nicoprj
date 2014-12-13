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
  srandom [clock seconds]
	foreach key [array names env] {
	  if {[regexp -nocase media $key]} {
	    # puts "env.$key = $env($key)" 
	  }
	}
  if {[:# $argv] < 1} {
    puts stderr "syntax: $argv0 <idx> \[<track-idx>\]"
  }
  set idx [:0 $argv]
  set filenames [det_filenames $idx]
  if {$filenames == {}} {
    puts stderr "Index $idx not found in last search results (show-results.txt)"
    exit
  }
  play_random $filenames [:1 $argv]
}

proc det_filenames {idx} {
  set f [open show-results.txt r]
  set res {}
  while {![eof $f]} {
    gets $f line
    if {[regexp {^(\d+) => } $line z idx1]} {
      if {$idx == $idx1} {
        # found dir, now read files.
        set cnt 1
        while {$cnt && ![eof $f]} {
          gets $f line
          if {[regexp {^\[[0-9 ,]+k\] (.+)$} $line z pathname]} {
            if {[is_music_file $pathname]} {
              lappend res $pathname
            } else {
              # other type of file, ignore.              
            }
          } else {
            # eof or new directory, so stop.
            set cnt 0
          }
        }
        break
      }     
    }
  }
  close $f
  return $res
}

proc play_random {lst_files {track_idx ""}} {
  puts "Choose one of the following:"
  foreach el $lst_files {
    puts $el    
  }
  if {$track_idx != ""} {
    set file [lindex $lst_files $track_idx-1]
  } else {
    set file [random_list $lst_files]  
  }
  
  puts "\n*** playing file: $file\n"; # 
  # met -q optie?
  exec -ignorestderr mpg321 $file
}

# library function
proc is_musicfile_old {filename} {
  set ext [string tolower [file extension $filename]]
  if {[lsearch -exact {.mp3 .wma .mp4 .m4a .mpc .ogg .wav} $ext] > -1} {
    return 1
  } else {
    return 0
  }
}

main $argv
