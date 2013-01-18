#!/home/nico/bin/tclsh
package require Itcl
package require Tclx ; # for try_eval

source [file join [file dirname [info script]] .. .. lib CLogger.tcl]
source [file join [file dirname [info script]] .. lib libmusic.tcl]
source [file join [file dirname [info script]] .. .. lib generallib.tcl]

source [file join [file dirname [info script]] .. lib setenv-media.tcl]

proc main {argc argv} {
	global env
  check_params $argc $argv
  set search_strings [string tolower $argv]
  search_files $env(MEDIA_COMPLETE) $search_strings
  puts "====================="
  search_files $env(MEDIA_NEW) $search_strings
  search_files $env(MEDIA_TEMP) $search_strings
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
proc search_files {dir search_strings} {
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
      
      puts "\[[format %7s [commify [format %.0f [det_size_kb $el]]]]k\] $el"
      
      
    }
    if {$search_found_one} {
      if {[file isdirectory $el]} {
        search_files $el $search_strings 
      }
    }
  }
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
