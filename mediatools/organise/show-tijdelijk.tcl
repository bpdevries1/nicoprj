#!/home/nico/bin/tclsh
package require Itcl
package require Tclx ; # for try_eval

source [file join [file dirname [info script]] .. .. lib CLogger.tcl]
source [file join [file dirname [info script]] .. lib libmusic.tcl]
source [file join [file dirname [info script]] .. .. lib generallib.tcl]

source [file join [file dirname [info script]] .. lib setenv-media.tcl]

proc main {argc argv} {
	global env
	foreach key [array names env] {
	  if {[regexp -nocase media $key]} {
	    # puts "env.$key = $env($key)" 
	  }
	}
  check_params $argc $argv
  set search_strings [string tolower $argv]
  set fres [open "show-results.txt" w]
  set last_idx 0
  set last_idx [search_files $env(MEDIA_COMPLETE) $search_strings $last_idx $fres]
  puts $fres "====================="
  set last_idx [search_files $env(MEDIA_NEW) $search_strings $last_idx $fres]
  set last_idx [search_files [file join $env(MEDIA_TEMP) music] $search_strings $last_idx $fres]
  close $fres
  puts [read_file "show-results.txt"]
}

proc check_params {argc argv} {
  global stderr argv0
  if {$argc < 1} {
   	puts stderr "syntax: $argv0 <search string>+, got: $argv (#$argc)" 
		exit 1
  }
}

# @pre search_string is lowercase.
# @note toon items als alle search_strings gevonden. Descend naar sub-dir als minimaal 1 gevonden.
# @note doel hiervan is zoeken van album-namen binnen artiest directories.
proc search_files {dir search_strings last_idx fres} {
  set lst [lsort [glob -nocomplain -directory $dir *]]
  foreach el $lst {
    set search_found_all 1
    set search_found_one 0
    foreach search_string $search_strings {
      if {[regexp -nocase -- $search_string $el]} {
        set search_found_one 1
      } else {
        set search_found_all 0
      }
    }
    if {$search_found_all} {
      # puts "\[[format %6.0f [det_size_kb $el]]k\] $el"
      # puts "\[[format %7s [commify [det_size_kb $el]]]k\] $el"
      # puts "\[[format %6.0f [det_size_kb $el]]k\] $el"
      # only increase index if it's a directory
      if {[is_music_directory $el]} {
        incr last_idx
        puts $fres "$last_idx => \[[format %7s [commify [format %.0f [det_size_kb $el]]]]k\] $el"        
      } else {
        if {[is_music_file $el] && ![is_trash $el]} {
          puts $fres "\[[format %7s [commify [format %.0f [det_size_kb $el]]]]k\] $el"
        }
      }
    }
    if {$search_found_one} {
      if {[file isdirectory $el]} {
        set last_idx [search_files $el $search_strings $last_idx $fres]
      }
    }
  }
  return $last_idx
}

proc is_music_directory {filename} {
  if {[is_trash $filename]} {
    return 0
  }
  if {[file isdirectory $filename]} {
    foreach el [glob -nocomplain -directory $filename -type f *] {
      if {[is_music_file $el]} {
        return 1
      }
    }
    return 0
  } else {
    return 0
  }
}

proc is_trash {filename} {
  regexp {/_trash/} $filename
}

# determine size in kilobytes of a file or a whole directory including subdirectories.
proc det_size_kb {path} {
  if {[file isfile $path]} {
    return [expr 1.0 * [file size $path] / 1024]  
  } elseif {[file isdirectory $path]} {
    # straks proberen met foldr
    set size 0.0
    foreach el [glob -nocomplain -directory $path *] {
      set size [expr $size + [det_size_kb $el]] 
    }
    return $size
  } else {
    return 0.0 
  }
}

# commify --
#   puts commas into a decimal number
# Arguments:
#   num		number in acceptable decimal format
#   sep		separator char (defaults to English format ",")
# Returns:
#   number with commas in the appropriate place
#
proc commify {num {sep ,}} {
    while {[regsub {^([-+]?\d+)(\d\d\d)} $num "\\1$sep\\2" num]} {}
    return $num
}

main $argc $argv

